"""Hoàn tác lần Start nhầm cả group BTH - Đơn vị lúc 16:28:19 ngày 12/11.
Đưa về STOPPED đúng 8 component trước đó đang STOPPED: processor DDL của group RT, 2 output port trong RT, 5 processor Nhiệm vụ chờ duyệt.
Ghi trạng thái trước khi sửa vào full/undo_1628_before.json."""
import json
from rtlib import G, P
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'; OLD = 'f8207212-019b-1000-fcc5-817989167c53'
targets = []  # (kind, entity)
for p in G(f'/process-groups/{NEW}/processors')['processors']:
    if p['component']['name'].startswith('0. DDL'): targets.append(('processors', p))
for sg in G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']['processGroups']:
    if sg['component']['name'] in ('Chi tiết đơn vị', 'Chi tiết HĐND'):
        for op in G(f"/process-groups/{sg['id']}/output-ports")['outputPorts']: targets.append(('output-ports', op))
for sg in G(f'/flow/process-groups/{OLD}')['processGroupFlow']['flow']['processGroups']:
    if sg['component']['name'] == 'Nhiệm vụ chờ duyệt':
        for p in G(f"/process-groups/{sg['id']}/processors")['processors']:
            if p['component']['state'] == 'RUNNING': targets.append(('processors', p))
json.dump([{'kind': k, 'id': e['id'], 'name': e['component']['name'], 'state': e['component']['state']} for k, e in targets],
          open('full/undo_1628_before.json', 'w'), ensure_ascii=False, indent=1)
assert len(targets) == 8, [e['component']['name'] for _, e in targets]
for k, e in targets:
    if e['component']['state'] != 'RUNNING': print('bỏ qua', e['component']['name'], e['component']['state']); continue
    r = P('PUT', f"/{k}/{e['id']}/run-status", {'revision': e['revision'], 'state': 'STOPPED'})
    print('STOPPED', k, e['component']['name'], '→', r.get('component', {}).get('state') if isinstance(r, dict) else r)
