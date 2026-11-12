"""Tạo group mới (STOPPED) phía dưới canvas 'BTH - Đơn vị': bản sao chuỗi Tiếp nhận → Giao → Giao+Nhận
dùng staging + RENAME swap, GFF CRON 3 phút, cổng 15 phút cho downstream. Không sửa component cũ nào."""
import re, json, sys, time, requests, urllib3
from transform import PLAN
urllib3.disable_warnings()
env = {}
for l in open('/home/truongnbn/Documents/Superset,/QLNV/.env'):
    m = re.match(r'\s*([A-Z_]+)\s*=\s*(.*)', l)
    if m: env[m[1]] = m[2].strip().strip('"\'')
B = env['NIFI_URL'].rstrip('/')
s = requests.Session(); s.verify = False
tok = s.post(B + '/nifi-api/access/token', data={'username': env['NIFI_USERNAME'], 'password': env['NIFI_PASSWORD']}).text
s.headers.update({'Authorization': 'Bearer ' + tok, 'Origin': B, 'Referer': B + '/nifi/',
                  'Request-Token': s.cookies.get('__Secure-Request-Token') or ''})
API = B + '/nifi-api'
def G(p): r = s.get(API + p); r.raise_for_status(); return r.json()
def P(m, p, body):
    r = s.request(m, API + p, json=body)
    if r.status_code >= 300: raise SystemExit(f'{m} {p} -> {r.status_code} {r.text[:500]}')
    return r.json()
REV0 = {'version': 0}

ROOT = 'f8207212-019b-1000-fcc5-817989167c53'
SRC = {'Tiếp nhận NV': '8a2122ac', 'Giao NV': '8a2122af', 'Giao + Nhận NV': 'bee43621'}
rootflow = G(f'/flow/process-groups/{ROOT}')['processGroupFlow']['flow']
src = {}
for g in rootflow['processGroups']:
    for n, pre in SRC.items():
        if g['id'].startswith(pre) and g['component']['name'] == n: src[n] = g
assert len(src) == 3, src.keys()

# backup root trước khi thêm
json.dump(G(f'/process-groups/{ROOT}/download') if False else rootflow,
          open('/home/truongnbn/Documents/Superset,/QLNV/backups/backup_nifi_bth_donvi_20261112_before_rtcopy.json', 'w'), ensure_ascii=False)

NAME = '[RT CHỜ DUYỆT 12/11] Chuỗi Tiếp nhận → Giao → Giao+Nhận (3 phút, staging swap)'
assert not any(g['component']['name'] == NAME for g in rootflow['processGroups']), 'group đã tồn tại'

# 1) group mới phía dưới
new = P('POST', f'/process-groups/{ROOT}/process-groups',
        {'revision': REV0, 'component': {'name': NAME, 'position': {'x': 2184.0, 'y': 1750.0}}})
NG = new['id']; print('new group', NG)

# 2) copy 3 group qua snippet
snip = P('POST', '/snippets', {'snippet': {'parentGroupId': ROOT,
         'processGroups': {g['id']: {'version': g['revision']['version']} for g in src.values()}}})
inst = P('POST', f'/process-groups/{NG}/snippet-instance',
         {'snippetId': snip['snippet']['id'], 'originX': 600.0, 'originY': 0.0, 'disconnectedNodeAcknowledged': False})
copies = {g['component']['name']: g for g in inst['flow']['processGroups']}
assert set(copies) == set(SRC), copies.keys()
for n, g in copies.items(): print('copy', n, g['id'])

# 3) sửa SQL trong bản sao (khớp processor theo tên + vị trí với bản gốc)
for gname, items in PLAN.items():
    orig = G(f'/flow/process-groups/{src[gname]["id"]}')['processGroupFlow']['flow']['processors']
    cp = G(f'/flow/process-groups/{copies[gname]["id"]}')['processGroupFlow']['flow']['processors']
    for pname, prop, fn, t, sw in items:
        o = [p for p in orig if p['component']['name'] == pname and p['component']['state'] != 'DISABLED']
        assert len(o) == 1, (gname, pname)
        pos = o[0]['component']['position']
        c = [p for p in cp if p['component']['name'] == pname and p['component']['position'] == pos]
        assert len(c) == 1, (gname, pname, 'copy')
        c = c[0]
        newsql = fn(o[0]['component']['config']['properties'][prop], t, sw)
        P('PUT', f'/processors/{c["id"]}', {'revision': c['revision'], 'component': {
            'id': c['id'], 'name': pname + ' [stg]', 'config': {'properties': {prop: newsql}}}})
        print('  sql', gname, '|', pname)

# helpers
def proc(typ, name, pos, cfg):
    return P('POST', f'/process-groups/{NG}/processors', {'revision': REV0, 'component': {
        'type': typ, 'name': name, 'position': pos, 'config': cfg}})
def port(name, pos):
    return P('POST', f'/process-groups/{NG}/output-ports', {'revision': REV0, 'component': {'name': name, 'position': pos}})
def ports(gid, kind):
    return {p['component']['name']: p['id'] for p in G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow'][kind]}
def conn(sid, sgid, stype, did, dgid, dtype, rels=None, bp=None):
    comp = {'source': {'id': sid, 'groupId': sgid, 'type': stype},
            'destination': {'id': did, 'groupId': dgid, 'type': dtype}}
    if rels: comp['selectedRelationships'] = rels
    if bp: comp['backPressureObjectThreshold'] = bp
    return P('POST', f'/process-groups/{NG}/connections', {'revision': REV0, 'component': comp})

# 4) GFF 3 phút (CRON lệch giây 17), gắn sync_ts + gate15
gff = proc('org.apache.nifi.processors.standard.GenerateFlowFile', '3 PHÚT / 1 LẦN (CRON :17)',
           {'x': 0.0, 'y': -300.0},
           {'schedulingStrategy': 'CRON_DRIVEN', 'schedulingPeriod': '17 */3 * * * ?',
            'properties': {'File Size': '0B', 'Batch Size': '1', 'Data Format': 'Text', 'Unique FlowFiles': 'false',
                           'sync_ts': "${now():format('yyyy-MM-dd HH:mm:ss')}",
                           'gate15': '${now():toNumber():divide(180000):mod(5):equals(0)}'}})
# 5) cổng 15 phút + output port cho downstream (chưa nối ra ngoài)
gates = {}
for i, (label, after) in enumerate([('sau Tiếp nhận', 'Tiếp nhận NV'), ('sau Giao', 'Giao NV'), ('sau Giao+Nhận', 'Giao + Nhận NV')]):
    r = proc('org.apache.nifi.processors.standard.RouteOnAttribute', f'Cổng 15 phút ({label})',
             {'x': 1300.0, 'y': -100.0 + i * 260}, {'autoTerminatedRelationships': ['unmatched'],
              'properties': {'qua_15phut': "${gate15:equals('true')}"}})
    o = port(f'ra downstream {label} (15 phút)', {'x': 1800.0, 'y': -60.0 + i * 260})
    conn(r['id'], NG, 'PROCESSOR', o['id'], NG, 'OUTPUT_PORT', ['qua_15phut'])
    gates[after] = r['id']

# 6) nối chuỗi
ins = {n: ports(g['id'], 'inputPorts') for n, g in copies.items()}
outs = {n: ports(g['id'], 'outputPorts') for n, g in copies.items()}
def gin(n): return list(ins[n].values())[0], copies[n]['id']
def gout(n): return list(outs[n].values())[0], copies[n]['id']
i, gid = gin('Tiếp nhận NV'); conn(gff['id'], NG, 'PROCESSOR', i, gid, 'INPUT_PORT', ['success'], bp=1)
for a, b in [('Tiếp nhận NV', 'Giao NV'), ('Giao NV', 'Giao + Nhận NV')]:
    o, og = gout(a); i, ig = gin(b); conn(o, og, 'OUTPUT_PORT', i, ig, 'INPUT_PORT')
for a in ['Tiếp nhận NV', 'Giao NV', 'Giao + Nhận NV']:
    o, og = gout(a); conn(o, og, 'OUTPUT_PORT', gates[a], NG, 'PROCESSOR')

# 7) label giải thích
TXT = ("[RT CHỜ DUYỆT 12/11] Bản sao chuỗi Tiếp nhận NV → Giao NV → Giao + Nhận NV. Toàn bộ đang STOPPED.\n"
       "• SQL: ghi vào bảng X__stg (TRUNCATE/INSERT/UPDATE trên __stg) rồi RENAME TABLE đổi chỗ nguyên tử → IOC không thấy bảng rỗng.\n"
       "  Phần SELECT giữ nguyên 100%. lock_wait_timeout=10s quanh RENAME (mặc định MySQL là 1 năm). Thêm READ COMMITTED trước INSERT.\n"
       "  Bảng __stg tự tạo lần đầu (CREATE TABLE IF NOT EXISTS … LIKE), ~1,65 GB.\n"
       "• Lịch: CRON 17 */3 * * * ? (3 phút), back pressure GFF→chuỗi = 1. Chuỗi cũ mất ~2 phút.\n"
       "• Cổng 15 phút: chỉ lượt :00/:15/:30/:45 đi ra 3 output port → downstream (vẫn TRUNCATE) giữ chu kỳ 15 phút.\n"
       "• Processor đã tắt / luồng th_tongquan_donvi_* (GFF 15' riêng) giữ nguyên như bản gốc.\n"
       "CUTOVER (sau khi duyệt): 1) Stop GFF '15 PHÚT / 1 LẦN' gốc + 3 group cũ. 2) Nối 3 output port vào input của\n"
       "  Dashboard LĐ + Đánh giá CB (sau Tiếp nhận), Mốc thời gian (sau Giao), Chi tiết đơn vị / NV NQ57 / Khối / Văn bản (sau Giao+Nhận).\n"
       "  3) Start group này. KHÔNG chạy song song với chuỗi cũ (TRUNCATE cũ sẽ làm rỗng bảng).")
P('POST', f'/process-groups/{ROOT}/labels', {'revision': REV0, 'component': {
    'label': TXT, 'position': {'x': 2184.0, 'y': 1480.0}, 'width': 1250.0, 'height': 250.0,
    'style': {'font-size': '13px', 'background-color': '#fff3b0'}}})
P('POST', f'/process-groups/{NG}/labels', {'revision': REV0, 'component': {
    'label': TXT, 'position': {'x': 0.0, 'y': -620.0}, 'width': 1250.0, 'height': 250.0,
    'style': {'font-size': '13px', 'background-color': '#fff3b0'}}})

# 8) kiểm tra: không có gì RUNNING trong group mới
st = G(f'/flow/process-groups/{NG}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
print('RUNNING trong group mới:', st.get('activeThreadCount'), '| group:', NG)
json.dump({'group': NG, 'copies': {n: g['id'] for n, g in copies.items()}},
          open('rt_copy_ids.json', 'w'), ensure_ascii=False)
