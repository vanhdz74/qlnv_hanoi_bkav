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
def walk(g):
    ff = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for c in ff['connections']:
        rel = c['component'].get('selectedRelationships') or []
        n = c['status']['aggregateSnapshot']['flowFilesQueued']
        if n and (set(rel) & {'failure', 'retry'}): drop(c['id']); print('  drop lỗi cũ', c['component']['source']['name'], n)
        elif n: print('  còn (giữ)', c['component']['source']['name'], '->', c['component']['destination']['name'], n)
    for sg in ff['processGroups']: walk(sg['id'])
walk(NEW)
ids = json.load(open('cutover/running_ids.json'))['new_running']
bad = 0
for i in ids:
    p = G(f'/processors/{i}')
    if p['component']['state'] == 'STOPPED':
        try: P('PUT', f'/processors/{i}/run-status', {'revision': p['revision'], 'state': 'RUNNING'})
        except SystemExit as e: bad += 1; print('LỖI start', p['component']['name'], str(e)[:200])
print('đã START', len(ids) - bad, '/', len(ids), time.strftime('%H:%M:%S'))
