"""Bước 3 của full_rt (chạy riêng vì cổng đang RUNNING): thêm moi_phut, nối cổng → input port các group đã copy."""
import json, time
from rtlib import *
COPY = {  # tên group → (cổng, quan hệ)
    'Dashboard Lãnh đạo các phòng, sở ngành, xã phường': ('Cổng 15 phút (sau Tiếp nhận)', 'moi_phut'),
    'Đánh giá cán bộ': ('Cổng 15 phút (sau Tiếp nhận)', 'moi_phut'),
    'Mốc thời gian': ('Cổng 15 phút (sau Giao)', 'moi_phut'),
    'NV theo NQ57': ('Cổng 15 phút (sau Giao+Nhận)', 'moi_phut'),
    'Khối': ('Cổng 15 phút (sau Giao+Nhận)', 'moi_phut'),
    'Văn bản giao nhiệm vụ': ('Cổng 15 phút (sau Giao+Nhận)', 'qua_15phut'),
    'Chi tiết đơn vị': ('Cổng 15 phút (sau Giao+Nhận)', 'qua_15phut'),
}
groups = json.load(open('full/copied_groups.json'))
nf = G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']
gates = {p['component']['name']: p for p in nf['processors'] if p['component']['name'].startswith('Cổng 15 phút')}
existing = {(c['component']['source']['id'], c['component']['destination']['id']) for c in nf['connections']}
for name, p in gates.items():
    cur = G(f"/processors/{p['id']}")
    was = cur['component']['state']
    if 'moi_phut' not in cur['component']['config']['properties']:
        if was == 'RUNNING':
            setstate(p, 'STOPPED')
            while G(f"/processors/{p['id']}")['status']['aggregateSnapshot']['activeThreadCount']: time.sleep(0.5)
        cur = G(f"/processors/{p['id']}")
        P('PUT', f"/processors/{p['id']}", {'revision': cur['revision'], 'component': {'id': p['id'],
            'config': {'properties': {'moi_phut': "${sync_ts:isEmpty():not()}"}}}})
        print('moi_phut +', name)
    for gname, (gate, rel) in COPY.items():
        if gate != name: continue
        gid = groups[gname]
        ip = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']['inputPorts']
        assert len(ip) == 1, (gname, len(ip))
        if (p['id'], ip[0]['id']) in existing: continue
        P('POST', f'/process-groups/{NEW}/connections', {'revision': {'version': 0}, 'component': {
            'source': {'id': p['id'], 'groupId': NEW, 'type': 'PROCESSOR'},
            'destination': {'id': ip[0]['id'], 'groupId': gid, 'type': 'INPUT_PORT'},
            'selectedRelationships': [rel], 'backPressureObjectThreshold': 5, 'flowFileExpiration': '10 min'}})
        print('NỐI', name, f'[{rel}] →', gname)
    if was == 'RUNNING' and G(f"/processors/{p['id']}")['component']['state'] != 'RUNNING':
        setstate(p, 'RUNNING'); print('bật lại', name)
