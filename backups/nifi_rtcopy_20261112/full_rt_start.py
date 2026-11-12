"""Bật hạ nguồn đã copy + nhánh th_tongquan_donvi trong lõi. Bỏ qua DISABLED/INVALID, port không có kết nối ra."""
import json, time
from rtlib import *
groups = json.load(open('full/copied_groups.json'))

def run(kind, p):
    path = {'proc': 'processors', 'in': 'input-ports', 'out': 'output-ports'}[kind]
    q = G(f'/{path}/{p["id"]}')
    P('PUT', f'/{path}/{p["id"]}/run-status', {'revision': q['revision'], 'state': 'RUNNING'})

def start_group(gid, only=None):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
    srcs = {c['component']['source']['id'] for c in f['connections']}
    n = 0
    for p in f['processors']:
        c = p['component']
        if c['state'] != 'STOPPED': continue
        if only and not only(c): continue
        if c.get('validationErrors'):
            if not c['type'].endswith('LogAttribute'): print('  BỎ INVALID', c['name'], c['validationErrors'][0][:100])
            continue
        run('proc', p); n += 1
    for k, lst in (('in', f['inputPorts']), ('out', f['outputPorts'])):
        for pt in lst:
            if only or pt['component']['state'] != 'STOPPED' or pt['id'] not in srcs: continue
            run(k, pt); n += 1
    return n

for name, gid in groups.items():
    print('BẬT', name, start_group(gid))
for sub in ('142f3e8c', '142f3eae'):
    gid = [g['id'] for g in G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']['processGroups'] if g['id'].startswith(sub)][0]
    print('BẬT th_tongquan', sub, start_group(gid, only=lambda c: 'th_tongquan_donvi' in c['name'] or c['name'] == '15 PHÚT / 1 LẦN'))
print(time.strftime('%T'))
