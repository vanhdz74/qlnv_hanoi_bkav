"""Bước 1 CDC thử (17/11): dựng luồng trong group thử (mọi thứ STOPPED). Chỉ tạo mới, không sửa component cũ.
CDC binlog → EvaluateJsonPath → ReplaceText(INSERT rt_cdc_log) → PutSQL(HaNoi_Datamart)
GFF(DDL, chạy 1 lần) → cùng PutSQL."""
import sys, json, os
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P
HERE = os.path.dirname(os.path.abspath(__file__))
ids = json.load(open(f'{HERE}/ids.json'))
GID = ids['group']
POOL = '0bfb327e-8a21-1e6a-776c-e17610335bef'  # HaNoi_Datamart

DDL = """CREATE TABLE IF NOT EXISTS datamart_hanoi.rt_cdc_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  db_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'giờ MySQL lúc ghi log (MySQL chậm ~4p40s)',
  nifi_at DATETIME(3) COMMENT 'giờ NiFi nhận sự kiện',
  event_at DATETIME(3) COMMENT 'giờ sự kiện trong binlog (đồng hồ MySQL nguồn)',
  seq_id BIGINT, db VARCHAR(64), tbl VARCHAR(128), op VARCHAR(16),
  pk VARCHAR(255) COMMENT 'giá trị cột đầu tiên', task_id VARCHAR(64) COMMENT 'cột TaskId nếu bảng có',
  binlog_file VARCHAR(64), binlog_pos BIGINT,
  payload TEXT COMMENT 'JSON columns (value / last_value), cắt 4000 ký tự',
  KEY k_tbl (db, tbl), KEY k_task (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"""

def esc(a):  # chuỗi an toàn trong SQL
    return "${" + a + ":replace('\\\\','\\\\\\\\'):replace(\"'\",\"''\")}"

INSERT = ("INSERT INTO datamart_hanoi.rt_cdc_log(nifi_at,event_at,seq_id,db,tbl,op,pk,task_id,binlog_file,binlog_pos,payload) VALUES ("
          "'${now():format(\"yyyy-MM-dd HH:mm:ss.SSS\")}',"
          "FROM_UNIXTIME(${cdc_ts:toDecimal():divide(1000):replaceEmpty(\"NULL\")}),"
          "'${cdc.sequence.id}',"
          f"'{esc('cdc_db')}','{esc('cdc_tbl')}','{esc('cdc_type')}',"
          f"LEFT('{esc('cdc_pk')}',255),LEFT('{esc('cdc_taskid')}',64),"
          "'${cdc_file}', NULLIF('${cdc_pos}','')+0,"
          "LEFT('${'$1':substring(0,4000):replace('\\\\','\\\\\\\\'):replace(\"'\",\"''\")}',4000))")

def mk(name, typ, x, y, props, sched=None, auto=()):
    k = 'p_' + name
    if k in ids: return ids[k]
    comp = {'name': name, 'type': typ, 'position': {'x': x, 'y': y},
            'config': {'properties': props, 'autoTerminatedRelationships': list(auto)}}
    if sched: comp['config'].update(sched)
    p = P('POST', f'/process-groups/{GID}/processors', {'revision': {'version': 0}, 'component': comp})
    ids[k] = p['id']; json.dump(ids, open(f'{HERE}/ids.json', 'w'), indent=1); return p['id']

def conn(a, b, rels, name=''):
    k = f'c_{a[:8]}_{b[:8]}_{"_".join(rels)}'
    if k in ids: return
    c = P('POST', f'/process-groups/{GID}/connections', {'revision': {'version': 0}, 'component': {
        'name': name, 'source': {'id': a, 'groupId': GID, 'type': 'PROCESSOR'},
        'destination': {'id': b, 'groupId': GID, 'type': 'PROCESSOR'}, 'selectedRelationships': rels,
        'backPressureObjectThreshold': 20000, 'flowFileExpiration': '1 hour'}})
    ids[k] = c['id']; json.dump(ids, open(f'{HERE}/ids.json', 'w'), indent=1)

# 1. CDC (đã tạo ở bước trước) — cấu hình, chưa có mật khẩu
cdc = G(f'/processors/{ids["cdc"]}')
P('PUT', f'/processors/{ids["cdc"]}', {'revision': cdc['revision'], 'component': {'id': ids['cdc'], 'config': {
    'properties': {
        'capture-change-mysql-hosts': '10.120.33.92:3306',
        'capture-change-mysql-driver-locations': '/opt/driver/mysql-connector-java-5.1.49.jar',
        'capture-change-mysql-username': 'bkav',
        'capture-change-mysql-server-id': '6511',
        'capture-change-mysql-db-name-pattern': '.*',
        'capture-change-mysql-name-pattern': '.*',
        'capture-change-mysql-retrieve-all-records': 'false',   # bắt đầu từ vị trí hiện tại, không đọc lại binlog cũ
        'capture-change-mysql-include-ddl-events': 'true',
        'capture-change-mysql-include-begin-commit': 'false',
        'capture-change-mysql-state-update-interval': '10 seconds'},
    'schedulingPeriod': '0 sec', 'concurrentlySchedulableTaskCount': 1},
    'position': {'x': 0, 'y': 0}}})

ev = mk('Tách trường sự kiện', 'org.apache.nifi.processors.standard.EvaluateJsonPath', 0, 220, {
    'Destination': 'flowfile-attribute', 'Return Type': 'auto-detect', 'Path Not Found Behavior': 'ignore',
    'cdc_db': '$.database', 'cdc_tbl': '$.table_name', 'cdc_type': '$.type', 'cdc_ts': '$.timestamp',
    'cdc_file': '$.binlog_filename', 'cdc_pos': '$.binlog_position', 'cdc_pk': '$.columns[0].value',
    'cdc_taskid': "$.columns[?(@.name=='TaskId')].value"}, auto=('failure', 'unmatched'))
rt = mk('Tạo INSERT rt_cdc_log', 'org.apache.nifi.processors.standard.ReplaceText', 0, 440, {
    'Replacement Strategy': 'Regex Replace', 'Evaluation Mode': 'Entire text',
    'Regular Expression': '(?s)(^.*$)', 'Replacement Value': INSERT,
    'Maximum Buffer Size': '10 MB'}, auto=('failure',))
gff = mk('DDL rt_cdc_log (chạy 1 lần)', 'org.apache.nifi.processors.standard.GenerateFlowFile', 480, 440, {
    'generate-ff-custom-text': DDL}, sched={'schedulingPeriod': '1 day'})
ps = mk('Ghi rt_cdc_log', 'org.apache.nifi.processors.standard.PutSQL', 0, 660, {
    'JDBC Connection Pool': POOL, 'Batch Size': '200', 'Support Fragmented Transactions': 'false',
    'database-session-autocommit': 'false'}, auto=('success', 'failure', 'retry'))
conn(ids['cdc'], ev, ['success'])
conn(ev, rt, ['matched'])
conn(rt, ps, ['success'])
conn(gff, ps, ['success'])

for k, v in ids.items():
    if k.startswith('p_') or k == 'cdc':
        c = G(f'/processors/{v}')['component']
        print(c['name'], c['state'], c.get('validationStatus'), c.get('validationErrors'))
