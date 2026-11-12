"""Chuyển group RT 142f3e8a cùng label ghi chú 142f3f10 từ "BTH - Đơn vị" sang group mới "BTH _ Đơn vị _ Realtime (1p)" (142f43a6).
Không đổi trạng thái run/stop, không đổi processor nào. Trước khi chuyển: lưu flow definition và trạng thái processor của group RT.
Nếu NiFi không cho chuyển khi đang chạy: dừng group RT, chuyển, rồi bật lại đúng các component trước đó đang RUNNING."""
import json, time, sys
from rtlib import G, P, s, API
OLD = 'f8207212-019b-1000-fcc5-817989167c53'
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
LABEL = '142f3f10-6ef6-1fc2-a987-62beae4ceaa2'
DST = '142f43a6-6ef6-1fc2-f91f-c96e6dc0d2fb'
ts = time.strftime('%H%M%S')

# 1. Backup
fd = s.get(f'{API}/process-groups/{NEW}/download').text
open(f'full/backup_RT_before_move_{ts}.json', 'w').write(fd)
states = {}
def walk(g):
    f = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for k in ('processors', 'inputPorts', 'outputPorts'):
        for x in f[k]: states[x['id']] = (k, x['component']['state'], x['component']['name'])
    for c in f['processGroups']: walk(c['id'])
walk(NEW)
json.dump(states, open(f'full/backup_RT_states_{ts}.json', 'w'), ensure_ascii=False, indent=0)
running = sum(1 for v in states.values() if v[1] == 'RUNNING')
print('backup xong:', len(fd), 'byte flowdef,', len(states), 'component,', running, 'RUNNING')

# 2. Kiểm tra đích trống và RT không có kết nối ra ngoài
d = G(f'/flow/process-groups/{DST}')['processGroupFlow']['flow']
assert not (d['processors'] or d['processGroups'] or d['connections']), 'group đích không trống'
pf = G(f'/flow/process-groups/{OLD}')['processGroupFlow']['flow']
assert not [c for c in pf['connections'] if NEW in (c['component']['source']['groupId'], c['component']['destination']['groupId'])]

def move():
    rg = G(f'/process-groups/{NEW}')['revision']; rl = G(f'/labels/{LABEL}')['revision']
    sn = P('POST', '/snippets', {'snippet': {'parentGroupId': OLD, 'processGroups': {NEW: rg}, 'labels': {LABEL: rl}}})
    sid = sn['snippet']['id']
    r = s.put(f'{API}/snippets/{sid}', json={'snippet': {'id': sid, 'parentGroupId': DST}})
    return r

r = move()
if r.status_code >= 300:
    print('chuyển khi đang chạy bị từ chối:', r.status_code, r.text[:300])
    rg = G(f'/process-groups/{NEW}')
    P('PUT', f'/flow/process-groups/{NEW}', {'id': NEW, 'state': 'STOPPED'})
    for _ in range(60):
        if G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount'] == 0: break
        time.sleep(2)
    r = move()
    if r.status_code >= 300: sys.exit(f'vẫn lỗi: {r.status_code} {r.text[:500]}  (group RT đang STOPPED, bật lại theo backup_RT_states_{ts}.json)')
    # bật lại đúng các component trước đó RUNNING
    for cid, (k, st, nm) in states.items():
        if st != 'RUNNING': continue
        path = {'processors': 'processors', 'inputPorts': 'input-ports', 'outputPorts': 'output-ports'}[k]
        e = G(f'/{path}/{cid}')
        if e['component']['state'] != 'RUNNING':
            P('PUT', f'/{path}/{cid}/run-status', {'revision': e['revision'], 'state': 'RUNNING'})
print('ĐÃ CHUYỂN. Cha mới của RT:', G(f'/process-groups/{NEW}')['component']['parentGroupId'])
after = {}
states_before = dict(states); states.clear(); walk(NEW)
diff = [(v[2], states_before[k][1], v[1]) for k, v in states.items() if states_before.get(k, (0, v[1]))[1] != v[1]]
print('component đổi trạng thái:', diff or 'không có')
