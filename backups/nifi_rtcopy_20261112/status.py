"""Chỉ đọc. python3 status.py [counts]  — trạng thái GFF cũ/mới, processor đang chạy, hàng đợi, processlist; 'counts' thêm số dòng."""
import sys, json, time
from rtlib import *

def gffs(gid):
    return [p for p in allprocs(gid) if p['component']['type'].endswith('GenerateFlowFile')]

out = {'t': time.strftime('%H:%M:%S')}
for name, gid in [('old', OLD), ('new', NEW)]:
    out[name] = [{'id': p['id'], 'name': p['component']['name'], 'state': p['component']['state'],
                  'sched': p['component']['config']['schedulingPeriod'], 'g': p['_g'][:8]} for p in gffs(gid)]
    st = G(f'/flow/process-groups/{gid}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
    out[name + '_agg'] = {k: st[k] for k in ('activeThreadCount', 'queued', 'flowFilesIn', 'flowFilesOut')}
c = G('/flow/status')['controllerStatus']
out['nifi'] = {k: c[k] for k in ('activeThreadCount', 'queued')}
pl = Q("SELECT id, time, state, LEFT(info,80) info FROM information_schema.processlist "
       "WHERE command <> 'Sleep' AND (info LIKE '%tonghop_chitiet%' OR info LIKE '%tongquan%' OR state LIKE '%lock%') "
       "AND info NOT LIKE '%processlist%' ORDER BY time DESC LIMIT 20")
out['mysql_running'] = pl
out['uptime'] = Q("SHOW GLOBAL STATUS LIKE 'Uptime'")
if 'counts' in sys.argv:
    out['counts'] = {}
    for t in TABLES:
        r = Q(f"SELECT COUNT(*) n, MAX(syncdate) mx FROM datamart_hanoi.{t}") if t not in (
            P_ + '_nhom_tiepnhan', P_ + '_nhom_giaonv') else Q(f"SELECT COUNT(*) n FROM datamart_hanoi.{t}")
        out['counts'][t] = r[0]
print(json.dumps(out, ensure_ascii=False, indent=1, default=str))
