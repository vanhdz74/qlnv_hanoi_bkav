"""CDC thử phương án kết hợp (17/11): ExecuteGroovyScript đọc binlog qua SQL (6033) mỗi 5s. Chỉ tạo mới trong group thử 142f4500.
Chạy DDL rt_cdc_state qua GFF+PutSQL sẵn có trong group. Processor poll để STOPPED."""
import sys, json, os, time
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P, Q, setstate
HERE = os.path.dirname(os.path.abspath(__file__))
ids = json.load(open(f'{HERE}/ids.json'))
GID, POOL = ids['group'], '0bfb327e-8a21-1e6a-776c-e17610335bef'

# 1. DDL rt_cdc_state
DDL = """CREATE TABLE IF NOT EXISTS datamart_hanoi.rt_cdc_state (
  k VARCHAR(100) PRIMARY KEY, v VARCHAR(500), updated_at TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"""
gff, ps = ids['p_DDL rt_cdc_log (chạy 1 lần)'], ids['p_Ghi rt_cdc_log']
g = G(f'/processors/{gff}')
P('PUT', f'/processors/{gff}', {'revision': g['revision'], 'component': {'id': gff, 'name': 'DDL (chạy 1 lần)',
    'config': {'properties': {'generate-ff-custom-text': DDL}}}})
setstate({'id': ps}, 'RUNNING'); setstate({'id': gff}, 'RUN_ONCE'); time.sleep(8); setstate({'id': ps}, 'STOPPED')
print('rt_cdc_state cols:', Q("SELECT COUNT(*) n FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='rt_cdc_state'"))

# 2. ExecuteGroovyScript
body = open(f'{HERE}/binlog_poll.groovy').read()
k = 'p_poll'
if k not in ids:
    p = P('POST', f'/process-groups/{GID}/processors', {'revision': {'version': 0}, 'component': {
        'name': 'Đọc binlog qua SQL mỗi 5s (THỬ)', 'type': 'org.apache.nifi.processors.groovyx.ExecuteGroovyScript',
        'position': {'x': 480, 'y': 0}}})
    ids[k] = p['id']; json.dump(ids, open(f'{HERE}/ids.json', 'w'), indent=1)
p = G(f'/processors/{ids[k]}')
desc = p['component']['config']['descriptors']
bodykey = next(x for x, d in desc.items() if d['displayName'] == 'Script Body')
P('PUT', f'/processors/{ids[k]}', {'revision': p['revision'], 'component': {'id': ids[k], 'config': {
    'properties': {bodykey: body, 'SQL.db': POOL},
    'schedulingStrategy': 'TIMER_DRIVEN', 'schedulingPeriod': '5 sec', 'concurrentlySchedulableTaskCount': 1,
    'autoTerminatedRelationships': ['success', 'failure']}}})
c = G(f'/processors/{ids[k]}')['component']
print(c['name'], c['state'], c['validationStatus'], c.get('validationErrors'))
