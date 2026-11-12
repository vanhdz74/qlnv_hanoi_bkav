"""Kết thúc chạy thử: stop group mới (run_trial.py stop) → ROLLBACK DDL (v2 idempotent) → kiểm information_schema → start GFF cũ."""
import time, subprocess, sys
from rtlib import *
OLD_GFF = 'bee43592-c2d0-1c10-f125-4abd0acb46fa'
DB, T = 'datamart_hanoi', 'qlnv_tonghop_chitiet'
subprocess.run([sys.executable, 'run_trial.py', 'stop'], check=True)
a = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
assert a['activeThreadCount'] == 0, a
assert not Q("SELECT id FROM information_schema.processlist WHERE info LIKE '%RT 12/11%' AND info NOT LIKE '%processlist%'")
rb = [p for p in procs(NEW) if p['component']['name'].startswith('0. ROLLBACK')][0]
q = G(f'/processors/{rb["id"]}')
if q['component']['state'] == 'DISABLED':
    P('PUT', f'/processors/{rb["id"]}/run-status', {'revision': q['revision'], 'state': 'STOPPED'}); time.sleep(3)
setstate(rb, 'RUN_ONCE'); time.sleep(5)
while G(f'/flow/processors/{rb["id"]}/status')['processorStatus']['aggregateSnapshot']['activeThreadCount']: time.sleep(2)
q = G(f'/processors/{rb["id"]}')
P('PUT', f'/processors/{rb["id"]}/run-status', {'revision': q['revision'], 'state': 'DISABLED'})
k = Q(f"SELECT table_name t, index_name k FROM information_schema.statistics WHERE table_schema='{DB}' AND index_name LIKE 'uk_rt_%' AND table_name LIKE '{T}%'")
c = Q(f"SELECT table_name t FROM information_schema.columns WHERE table_schema='{DB}' AND column_name='syncdate' AND table_name IN ('{T}_nhom_tiepnhan','{T}_nhom_giaonv')")
print('sau ROLLBACK: keys', k, 'cols', c)
assert not k and not c, 'ROLLBACK chưa sạch — KHÔNG bật GFF cũ'
setstate({'id': OLD_GFF}, 'RUNNING')
print('GFF cũ RUNNING', time.strftime('%T'), G(f'/processors/{OLD_GFF}')['component']['state'])
