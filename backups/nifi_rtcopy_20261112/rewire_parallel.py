"""Tiếp nhận ∥ Giao (Giao NV không đọc bảng tiepnhan*), MergeContent theo sync_ts chờ đủ 2 nhánh → Giao + Nhận.
SQL không đổi. Chỉ sửa trong group 142f3e8a. python3 rewire_parallel.py [deploy|undo]"""
import sys, json, time
from rtlib import *
ids = json.load(open('rt_copy_ids.json'))['copies']
TN, GV, GN = ids['Tiếp nhận NV'], ids['Giao NV'], ids['Giao + Nhận NV']
GFF = '142f3f00-6ef6-1fc2-88e9-5f49f8a9cc5a'
REV0 = {'version': 0}
flow = G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']
conns = flow['connections']
def port(gid, kind): return G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow'][kind][0]
tn_out, gv_in, gv_out, gn_in, tn_in = port(TN, 'outputPorts'), port(GV, 'inputPorts'), port(GV, 'outputPorts'), port(GN, 'inputPorts'), port(TN, 'inputPorts')
def find(src, dst): return [c for c in conns if c['component']['source']['id'] == src and c['component']['destination']['id'] == dst]
def conn(s, st, d, dt, rels=None, bp=None):
    comp = {'source': {'id': s['id'], 'groupId': s['_g'], 'type': st}, 'destination': {'id': d['id'], 'groupId': d['_g'], 'type': dt}}
    if rels: comp['selectedRelationships'] = rels
    if bp: comp['backPressureObjectThreshold'] = bp
    return P('POST', f'/process-groups/{NEW}/connections', {'revision': REV0, 'component': comp})
def delconn(c):
    c = G(f'/connections/{c["id"]}')
    s.delete(API + f'/connections/{c["id"]}', params={'version': c['revision']['version']}).raise_for_status()
def portstate(p, kind, st):
    q = G(f'/{kind}/{p["id"]}')
    P('PUT', f'/{kind}/{p["id"]}/run-status', {'revision': q['revision'], 'state': st})
for p, g in [(tn_out, TN), (gv_in, GV), (gv_out, GV), (gn_in, GN), (tn_in, TN)]: p['_g'] = g
gffp = {'id': GFF, '_g': NEW}

if 'deploy' not in sys.argv and 'undo' not in sys.argv:
    print('TN→GV', len(find(tn_out['id'], gv_in['id'])), 'GV→GN', len(find(gv_out['id'], gn_in['id'])), 'GFF→GV', len(find(GFF, gv_in['id'])))
    sys.exit()

# dừng GFF, đợi rỗng
assert G(f'/processors/{GFF}')['component']['state'] == 'STOPPED', 'stop GFF trước'
while G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount']: time.sleep(2)
json.dump(conns, open(f'backup_rt_conns_{int(time.time())}.json', 'w'), ensure_ascii=False, indent=1)
for p, k in [(tn_out, 'output-ports'), (gv_in, 'input-ports'), (gv_out, 'output-ports'), (gn_in, 'input-ports')]: portstate(p, k, 'STOPPED')

if 'deploy' in sys.argv:
    m = P('POST', f'/process-groups/{NEW}/processors', {'revision': REV0, 'component': {
        'type': 'org.apache.nifi.processors.standard.MergeContent', 'name': 'Chờ đủ Tiếp nhận + Giao (theo sync_ts)',
        'position': {'x': 600.0, 'y': 700.0},
        'config': {'autoTerminatedRelationships': ['original'],
                   'properties': {'Merge Strategy': 'Bin-Packing Algorithm', 'Merge Format': 'Binary Concatenation',
                                  'Attribute Strategy': 'Keep Only Common Attributes',
                                  'Correlation Attribute Name': 'sync_ts', 'Minimum Number of Entries': '2',
                                  'Maximum Number of Entries': '2', 'Maximum number of Bins': '10', 'Max Bin Age': '5 min'}}}})
    m['_g'] = NEW
    for c in find(tn_out['id'], gv_in['id']): delconn(c)
    for c in find(gv_out['id'], gn_in['id']): delconn(c)
    conn(gffp, 'PROCESSOR', gv_in, 'INPUT_PORT', ['success'], bp=1)
    conn(tn_out, 'OUTPUT_PORT', m, 'PROCESSOR')
    conn(gv_out, 'OUTPUT_PORT', m, 'PROCESSOR')
    conn(m, 'PROCESSOR', gn_in, 'INPUT_PORT', ['merged'])
    f = P('POST', f'/process-groups/{NEW}/processors', {'revision': REV0, 'component': {
        'type': 'org.apache.nifi.processors.standard.LogAttribute', 'name': 'Merge failure', 'position': {'x': 1000.0, 'y': 700.0}}})
    f['_g'] = NEW
    conn(m, 'PROCESSOR', f, 'PROCESSOR', ['failure'])
    setstate(m, 'RUNNING')
    print('merge', m['id'], 'logfail', f['id'])
else:
    ms = [p for p in flow['processors'] if p['component']['type'].endswith('MergeContent') or p['component']['name'] == 'Merge failure']
    for p in ms:
        if p['component']['state'] == 'RUNNING': setstate(p, 'STOPPED')
    for c in conns:
        if c['component']['destination']['id'] in [p['id'] for p in ms] or c['component']['source']['id'] in [p['id'] for p in ms]: delconn(c)
    for c in find(GFF, gv_in['id']): delconn(c)
    for p in ms:
        q = G(f'/processors/{p["id"]}'); s.delete(API + f'/processors/{p["id"]}', params={'version': q['revision']['version']}).raise_for_status()
    conn(tn_out, 'OUTPUT_PORT', gv_in, 'INPUT_PORT')
    conn(gv_out, 'OUTPUT_PORT', gn_in, 'INPUT_PORT')
    print('undo xong')
for p, k in [(tn_out, 'output-ports'), (gv_in, 'input-ports'), (gv_out, 'output-ports'), (gn_in, 'input-ports')]: portstate(p, k, 'RUNNING')
print('ports RUNNING')
