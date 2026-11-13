import sys, json, time; sys.path.insert(0, '.')
from rtlib import G, P, s, API
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
def drop(cid):
    r = P('POST', f'/flowfile-queues/{cid}/drop-requests', {})['dropRequest']
    for _ in range(20):
        r = G(f"/flowfile-queues/{cid}/drop-requests/{r['id']}")['dropRequest']
        if r['finished']: break
        time.sleep(0.5)
    s.delete(API + f"/flowfile-queues/{cid}/drop-requests/{r['id']}")
f = G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']
# 1) 3 connection cổng → output port + 3 port
ports = {pt['id']: pt for pt in f['outputPorts'] if pt['component']['name'].startswith('ra downstream')}
for c in f['connections']:
    if c['component']['destination']['id'] in ports:
        drop(c['id']); cc = G(f"/connections/{c['id']}")
        r = s.delete(API + f"/connections/{c['id']}", params={'version': cc['revision']['version'], 'clientId': cc['revision'].get('clientId', 'cutover')})
        print('xóa connection', c['component']['source']['name'], '->', c['component']['destination']['name'], r.status_code)
for pid, pt in ports.items():
    pp = G(f'/output-ports/{pid}')
    r = s.delete(API + f'/output-ports/{pid}', params={'version': pp['revision']['version'], 'clientId': pp['revision'].get('clientId', 'cutover')})
    print('xóa port', pt['component']['name'], r.status_code)
# 2) Merge failure: auto-terminate success
for p in f['processors']:
    n = p['component']['name']
    if n == 'Merge failure':
        q = G(f"/processors/{p['id']}")
        P('PUT', f"/processors/{p['id']}", {'revision': q['revision'], 'component': {'id': p['id'], 'config': {'autoTerminatedRelationships': ['success']}}})
        print('Merge failure ->', G(f"/processors/{p['id']}")['component']['validationStatus'])
    if n.startswith('0.'):
        q = G(f"/processors/{p['id']}")
        if q['component']['state'] != 'DISABLED':
            P('PUT', f"/processors/{p['id']}/run-status", {'revision': q['revision'], 'state': 'DISABLED'})
        print('DISABLED:', n)
# 3) xóa flowfile lỗi cũ trong các hàng đợi failure/retry
def walk(g):
    ff = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for c in ff['connections']:
        rel = c['component'].get('selectedRelationships') or []
        if c['status']['aggregateSnapshot']['flowFilesQueued'] > 0 and (set(rel) & {'failure', 'retry'}):
            print('  drop', c['component']['source']['name'], c['status']['aggregateSnapshot']['flowFilesQueued']); drop(c['id'])
    for sg in ff['processGroups']: walk(sg['id'])
walk(NEW)
print('còn trong group:', G(f'/flow/process-groups/{NEW}/status')['processGroupStatus']['aggregateSnapshot']['queued'])
