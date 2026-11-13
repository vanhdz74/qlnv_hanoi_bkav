import sys, json; sys.path.insert(0, '.')
from rtlib import G, P
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
print('RT threads', G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount'])
plan = json.load(open('cutover/plan_cutover.json'))
ok = 0
for x in plan['procs']:
    p = G(f"/processors/{x['id']}")
    assert p['component']['state'] != 'RUNNING', x['name']
    cur = p['component']['config']['properties']
    for k in x['set']: assert '_new_rt' in (cur.get(k) or ''), ('đã đổi?', x['name'], k)
    P('PUT', f"/processors/{x['id']}", {'revision': p['revision'], 'component': {'id': x['id'], 'config': {'properties': x['set']}}})
    q = G(f"/processors/{x['id']}")['component']['config']['properties']
    assert all(q[k] == v for k, v in x['set'].items()), x['name']
    ok += 1
print('đã sửa', ok, '/', len(plan['procs']))
