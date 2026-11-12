"""Bước 3–4: xóa flowfile tồn ở group mới, bật chuỗi (giống run_trial start, bỏ qua processor INVALID)."""
import time
from rtlib import *
import run_trial as rt  # chỉ dùng hằng số; run_trial chạy theo argv nên import an toàn khi argv khác lệnh

DDL_PREFIX = [p['id'] for p in procs(NEW) if p['component']['name'].startswith('0. DDL')][0][:8]
SKIP = set(rt.SKIP) | {DDL_PREFIX}

# 3. xóa hàng đợi
def conns(gid):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
    out = list(f['connections'])
    for g in f['processGroups']: out += conns(g['id'])
    return out
for c in conns(NEW):
    if c['status']['aggregateSnapshot']['queuedCount'] != '0':
        r = P('POST', f"/flowfile-queues/{c['id']}/drop-requests", {})
        print('DROP', c['status']['aggregateSnapshot']['queuedCount'], c['component']['source']['name'][:40], '->', c['component']['destination']['name'][:40])
time.sleep(3)
print('queued sau xóa:', G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['queued'])

# 4. bật
srcs = {c['component']['source']['id'] for c in conns(NEW)}
for k, p in rt.walk(NEW):
    if p['id'][:8] in SKIP or p['id'] == rt.GFF_NEW or p['component']['state'] != 'STOPPED': continue
    if k != 'proc' and p['id'] not in srcs: continue
    if k == 'proc' and p['component'].get('validationErrors'):
        print('BỎ (INVALID)', p['component']['name']); continue
    path = {'proc': 'processors', 'in': 'input-ports', 'out': 'output-ports'}[k]
    q = G(f'/{path}/{p["id"]}')
    P('PUT', f'/{path}/{p["id"]}/run-status', {'revision': q['revision'], 'state': 'RUNNING'})
    print('RUN', k, p['component']['name'][:60])
setstate({'id': rt.GFF_NEW}, 'RUNNING'); print('RUN GFF 1 phút', time.strftime('%T'))
