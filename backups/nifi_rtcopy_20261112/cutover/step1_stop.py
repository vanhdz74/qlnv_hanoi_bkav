import sys, json, time; sys.path.insert(0, '.')
from rtlib import G, P
OLD = 'f8207212-019b-1000-fcc5-817989167c53'; NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
def allp(g, skip=()):
    f = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']; out = list(f['processors'])
    for sg in f['processGroups']:
        if sg['id'] not in skip: out += allp(sg['id'], skip)
    return out
ts = time.strftime('%H%M%S')
old = allp(OLD, {NEW}); new = allp(NEW)
json.dump(old, open(f'cutover/backup_old_procs_{ts}.json', 'w'), ensure_ascii=False)
json.dump(new, open(f'cutover/backup_new_procs_{ts}.json', 'w'), ensure_ascii=False)
old_run = [p['id'] for p in old if p['component']['state'] == 'RUNNING']
new_run = [p['id'] for p in new if p['component']['state'] == 'RUNNING' and not p['component']['name'].startswith('0.')]
json.dump({'old_running': old_run, 'new_running': new_run}, open('cutover/running_ids.json', 'w'))
print('backup', ts, '| old running', len(old_run), '| new running', len(new_run))
def stop(ids):
    for i in ids:
        p = G(f'/processors/{i}')
        if p['component']['state'] == 'RUNNING':
            P('PUT', f'/processors/{i}/run-status', {'revision': p['revision'], 'state': 'STOPPED'})
stop(old_run); print('đã STOP cũ')
stop(new_run)
# DDL processor cũng dừng
for p in new:
    if p['component']['name'].startswith('0. DDL') and p['component']['state'] == 'RUNNING': stop([p['id']])
print('đã STOP RT')
for k in range(60):
    a = G(f'/flow/process-groups/{OLD}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount']
    print('threads', a); 
    if a == 0: break
    time.sleep(3)
