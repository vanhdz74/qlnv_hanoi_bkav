"""KILL câu so sánh mồ côi (chi_moi) (chỉ id truyền vào, chỉ khi info là câu RT 12/11). Dùng tạm processor '0. DDL upsert', trả lại SQL sau."""
import sys, time
from rtlib import *
qid = int(sys.argv[1])
r = Q(f"SELECT id, time, LEFT(info,60) i FROM information_schema.processlist WHERE id = {qid}")
assert r and 'chi_moi' in r[0]['i'], r
p = [p for p in procs(NEW) if p['id'].startswith('142f3f25')][0]
orig = p['component']['config']['properties']['SQL select query']
assert p['component']['state'] == 'STOPPED'
def setsql(sql):
    q = G(f'/processors/{p["id"]}')
    P('PUT', f'/processors/{p["id"]}', {'revision': q['revision'], 'component': {'id': p['id'], 'config': {'properties': {'SQL select query': sql}}}})
setsql(f'KILL {qid}')
try:
    setstate(p, 'RUN_ONCE'); time.sleep(8)
    while G(f'/flow/processors/{p["id"]}/status')['processorStatus']['aggregateSnapshot']['activeThreadCount']: time.sleep(2)
finally:
    setsql(orig)
print('SQL processor đã trả lại:', G(f'/processors/{p["id"]}')['component']['config']['properties']['SQL select query'][:60])
for _ in range(30):
    r = Q(f"SELECT id, time, state, command FROM information_schema.processlist WHERE id = {qid}")
    print(time.strftime('%T'), r)
    if not r: break
    time.sleep(10)
print('innodb_trx', Q("SELECT trx_mysql_thread_id, trx_state, trx_rows_modified, TIMESTAMPDIFF(SECOND, trx_started, NOW()) s FROM information_schema.innodb_trx"))
