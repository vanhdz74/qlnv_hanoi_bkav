import sys, json, time; sys.path.insert(0, '.')
from rtlib import G, P, Q
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
print('RT threads', G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount'])
plan = json.load(open('cutover/plan_cutover.json'))
f = G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']
ddl = [p for p in f['processors'] if p['component']['name'].startswith('0. DDL')][0]
rb = [p for p in f['processors'] if p['component']['name'].startswith('0. ROLLBACK')][0]
# đổi SQL processor DDL
p = G(f"/processors/{ddl['id']}")
P('PUT', f"/processors/{ddl['id']}", {'revision': p['revision'], 'component': {'id': ddl['id'], 'name': '0. DDL upsert bảng thật (v2, idempotent)', 'config': {'properties': {'SQL select query': plan['ddl']}}}})
# ROLLBACK: về STOPPED rồi đổi SQL
p = G(f"/processors/{rb['id']}")
if p['component']['state'] != 'STOPPED':
    P('PUT', f"/processors/{rb['id']}/run-status", {'revision': p['revision'], 'state': 'STOPPED'}); time.sleep(1); p = G(f"/processors/{rb['id']}")
P('PUT', f"/processors/{rb['id']}", {'revision': p['revision'], 'component': {'id': rb['id'], 'config': {'properties': {'SQL select query': plan['rollback']}}}})
print('đã cập nhật SQL DDL + ROLLBACK')
# Run once DDL
for _ in range(20):
    p = G(f"/processors/{ddl['id']}")
    if p['component']['validationStatus'] == 'VALID': break
    time.sleep(1)
t0 = time.time()
P('PUT', f"/processors/{ddl['id']}/run-status", {'revision': p['revision'], 'state': 'RUN_ONCE'})
for _ in range(60):
    time.sleep(2)
    s = G(f"/processors/{ddl['id']}/status")['processorStatus']['aggregateSnapshot']
    if s['activeThreadCount'] == 0 and time.time() - t0 > 4: break
print('DDL xong sau %.0fs' % (time.time() - t0))
b = G(f"/flow/bulletin-board?sourceId={ddl['id']}&limit=5")['bulletinBoard']['bulletins']
for x in b: print('BULLETIN', x['bulletin']['timestamp'], x['bulletin']['message'][:300])
for r in Q("SELECT TABLE_NAME t, INDEX_NAME i, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) c FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='datamart_hanoi' AND INDEX_NAME LIKE 'uk_rt%' AND TABLE_NAME NOT LIKE '%new_rt%' GROUP BY 1,2"): print(r)
print(Q("SELECT TABLE_NAME t FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='datamart_hanoi' AND TABLE_NAME IN ('qlnv_tonghop_chitiet_nhom_tiepnhan','qlnv_tonghop_chitiet_nhom_giaonv') AND COLUMN_NAME='syncdate'"))
