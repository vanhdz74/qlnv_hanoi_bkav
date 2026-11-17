"""Bước 1 CDC thử (17/11): tạo group mới + DBCP tạm (DISABLED) để kiểm NiFi có tới được MySQL 10.120.33.92:3306 trực tiếp không.
Không sửa component nào đang có. Ghi ID ra ids.json."""
import sys, json, time, os
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P
HERE = os.path.dirname(os.path.abspath(__file__))
PARENT = '142f43a6-6ef6-1fc2-f91f-c96e6dc0d2fb'   # BTH _ Đơn vị _ Realtime (1p)
ids = json.load(open(f'{HERE}/ids.json')) if os.path.exists(f'{HERE}/ids.json') else {}

if 'group' not in ids:
    g = P('POST', f'/process-groups/{PARENT}/process-groups', {'revision': {'version': 0}, 'component': {
        'name': '[CDC THỬ 17/11] binlog → datamart_hanoi.rt_cdc_log (theo dõi 10 phút)',
        'position': {'x': 1232.0, 'y': 700.0}}})
    ids['group'] = g['id']
if 'probe' not in ids:
    c = P('POST', f'/process-groups/{ids["group"]}/controller-services', {'revision': {'version': 0}, 'component': {
        'name': 'CDC_probe_3306 (tạm)', 'type': 'org.apache.nifi.dbcp.DBCPConnectionPool',
        'properties': {'Database Connection URL': 'jdbc:mysql://10.120.33.92:3306/?useSSL=false&connectTimeout=5000',
                       'Database Driver Class Name': 'com.mysql.jdbc.Driver',
                       'database-driver-locations': '/opt/driver/mysql-connector-java-5.1.49.jar',
                       'Database User': 'bkav'}}})
    ids['probe'] = c['id']
json.dump(ids, open(f'{HERE}/ids.json', 'w'), indent=1)

# verification với mật khẩu giả: "Access denied" = cổng tới được; "Communications link failure" = không tới được
cid = ids['probe']
r = P('POST', f'/controller-services/{cid}/config/verification-requests', {'request': {
    'componentId': cid, 'properties': {'Password': 'sai_co_y'}, 'attributes': {}}})
rid = r['request']['requestId']
for _ in range(30):
    r = G(f'/controller-services/{cid}/config/verification-requests/{rid}')
    if r['request']['complete']: break
    time.sleep(1)
for x in r['request'].get('results', []):
    print(x['outcome'], x['verificationStepName'], '|', (x.get('explanation') or '')[:400])
P('DELETE', f'/controller-services/{cid}/config/verification-requests/{rid}', None) if False else None
print(ids)
