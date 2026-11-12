"""Đưa toàn bộ hạ nguồn của BTH - Đơn vị vào group RT 142f3e8a, ghi *_new_rt.
python3 full_rt.py          -> CHẠY KHÔ: tính đổi tên + swap trên SQL gốc, ghi full/diff.txt, full/DDL_full.sql, full/plan.json
python3 full_rt.py deploy   -> backup, copy 11 group con vào NEW, sửa SQL, nối cổng, KHÔNG bật gì
"""
import sys, os, re, json, difflib, time
from rtlib import *

OUT = 'full'; os.makedirs(OUT, exist_ok=True)
SUF = '_new_rt'
# group con cần chuyển (đang bật) → (cổng nối, kiểu cổng)
COPY = {
    'acf5120d': ('Cổng 15 phút (sau Tiếp nhận)', 'moi_phut'),    # Dashboard Lãnh đạo
    'bee45b54': ('Cổng 15 phút (sau Tiếp nhận)', 'moi_phut'),    # Đánh giá cán bộ (cbcc_danhgia giữ GFF 60')
    'bee43e21': ('Cổng 15 phút (sau Giao)', 'moi_phut'),         # Mốc thời gian
    'bee45689': ('Cổng 15 phút (sau Giao+Nhận)', 'moi_phut'),    # NV theo NQ57
    'f80d911d': ('Cổng 15 phút (sau Giao+Nhận)', 'moi_phut'),    # Khối
    'f80bb6cb': ('Cổng 15 phút (sau Giao+Nhận)', 'qua_15phut'),  # Văn bản giao NV (vanban_chitiet 8,5s)
    '916211c3': ('Cổng 15 phút (sau Giao+Nhận)', 'qua_15phut'),  # Chi tiết đơn vị → Kiểm đếm, Chi tiết HĐND → Copy HĐND
    'bee45b79': (None, None), 'bee45bfc': (None, None), 'bee45c1b': (None, None),
    'f230cfc3': (None, None),                                     # kl_ctpct giữ GFF 30'
}
CORE_SUB = ['142f3e8c', '142f3eae']  # Tiếp nhận, Giao trong NEW: th_tongquan_donvi_* (giữ GFF 15')
SQLK = ('SQL select query', 'putsql-sql-statement', 'sql-pre-query', 'sql-post-query')

# ---------- quét
oldsubs = {g['id'][:8]: g for g in G(f'/flow/process-groups/{OLD}')['processGroupFlow']['flow']['processGroups']}
def allp(gid):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
    out = [dict(p, _g=gid) for p in f['processors']]
    for g in f['processGroups']: out += allp(g['id'])
    return out

W = re.compile(r'(?<!KEY )(?<!KEY\s\s)\b(?:INSERT\s+(?:IGNORE\s+)?INTO|TRUNCATE\s+TABLE|DELETE\s+FROM|REPLACE\s+INTO|UPDATE)\s+`?(\w+)`?\.`?(\w+)', re.I)

def written(procs_):
    s = set()
    for p in procs_:
        c = p['component']
        if c['state'] == 'DISABLED': continue
        pr = c['config']['properties']
        for k in SQLK:
            if pr.get(k): s |= {(db, t) for db, t in W.findall(pr[k])}
        if pr.get('put-db-record-table-name'):
            s.add(('datamart_hanoi', pr['put-db-record-table-name']))
    return s

src = []
for k in COPY: src += allp(oldsubs[k]['id'])
core_th = [p for g in CORE_SUB for p in allp([x['id'] for x in G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']['processGroups'] if x['id'].startswith(g)][0])
           if 'th_tongquan_donvi' in p['component']['name']]
WR = written(src) | written(core_th)
WR = {(db, t) for db, t in WR if not t.endswith(SUF) and not t.endswith('__stg')}
NAMES = sorted({t for _, t in WR} | set(TABLES), key=len, reverse=True)
PAT = re.compile(r'(?<![\w$])(' + '|'.join(map(re.escape, NAMES)) + r')(?![\w$])')

def rename(sql):
    return PAT.sub(lambda m: m.group(1) + SUF, sql)

HEADER = '/* [RT 12/11 full] ghi *_new_rt; TRUNCATE+INSERT → staging + RENAME swap */\n'
def to_swap(sql):
    """Nếu đúng mẫu 1 TRUNCATE db.t; + 1 INSERT INTO db.t (cùng bảng) → ghi db.t__stg rồi RENAME swap. Trả (sql, ok)."""
    tr = re.findall(r'TRUNCATE\s+TABLE\s+`?(\w+)`?\.`?(\w+)`?\s*;', sql, re.I)
    ins = re.findall(r'INSERT\s+INTO\s+`?(\w+)`?\.`?(\w+)`?', sql, re.I)
    if len(tr) != 1 or len(ins) != 1 or tr[0] != ins[0] or re.search(r'\bUPDATE\b(?!\s*=)', sql.replace('ON DUPLICATE KEY UPDATE', ''), re.I):
        return sql, False
    db, t = tr[0]
    s = re.sub(r'TRUNCATE\s+TABLE\s+`?' + db + r'`?\.`?' + t + r'`?\s*;',
               f'CREATE TABLE IF NOT EXISTS {db}.{t}__stg LIKE {db}.{t};\nTRUNCATE TABLE {db}.{t}__stg;', sql, flags=re.I)
    s = re.sub(r'INSERT\s+INTO\s+`?' + db + r'`?\.`?' + t + r'`?(?!\w)',
               f'SET TRANSACTION ISOLATION LEVEL READ COMMITTED;\nINSERT INTO {db}.{t}__stg', s, flags=re.I).rstrip()
    if not s.endswith(';'): s += ';'
    s += (f"\n/* đổi chỗ nguyên tử, chờ khóa tối đa 10s */\nSET SESSION lock_wait_timeout = 10;\n"
          f"RENAME TABLE {db}.{t} TO {db}.{t}__old, {db}.{t}__stg TO {db}.{t}, {db}.{t}__old TO {db}.{t}__stg;\n"
          f"SET SESSION lock_wait_timeout = 31536000;")
    return HEADER + s, True

def transform(p):
    """→ {prop: (cũ, mới)}, ghi chú"""
    c = p['component']; pr = c['config']['properties']; ch = {}; note = []
    if c['state'] == 'DISABLED': return ch, note
    for k in SQLK:
        v = pr.get(k)
        if not v: continue
        n = rename(v)
        if re.search(r'\bTRUNCATE\b', n, re.I):
            n2, ok = to_swap(n)
            if ok: n = n2; note.append('swap')
            else: note.append('TRUNCATE-giữ')
        if n != v: ch[k] = (v, n)
    # pre-query chỉ TRUNCATE đúng bảng mà câu chính đã chuyển sang swap → bỏ (nếu không bảng vẫn bị xóa trắng)
    pq = ch.get('sql-pre-query', (None, None))[1]
    main = ch.get('SQL select query', (None, ''))[1] or ''
    if pq and 'RENAME TABLE' in main:
        m = re.fullmatch(r'\s*TRUNCATE\s+TABLE\s+(\S+?)\s*;?\s*', pq, re.I)
        if m and f'RENAME TABLE {m.group(1)} TO' in main:
            ch['sql-pre-query'] = (pr['sql-pre-query'], None); note.remove('TRUNCATE-giữ'); note.append('bỏ pre-TRUNCATE')
    t = pr.get('put-db-record-table-name')
    if t and not t.endswith(SUF):
        ch['put-db-record-table-name'] = (t, t + SUF); note.append('PDR')
    return ch, note

plan, diff = [], []
for p in src + core_th:
    ch, note = transform(p)
    c = p['component']
    plan.append({'g': p['_g'][:8], 'name': c['name'], 'type': c['type'].split('.')[-1], 'state': c['state'], 'props': list(ch), 'note': note})
    for k, (a, b) in ch.items():
        diff += list(difflib.unified_diff(a.splitlines(), (b or "").splitlines(), f"{c['name']}::{k}", f"{c['name']}::{k} (mới)", n=0, lineterm=''))
open(f'{OUT}/diff.txt', 'w').write('\n'.join(diff))
json.dump(plan, open(f'{OUT}/plan.json', 'w'), ensure_ascii=False, indent=1)

DDL = "/* [RT 12/11 full] tạo bảng *_new_rt cho hạ nguồn, không đụng bảng thật */\n" + ''.join(
    f"CREATE TABLE IF NOT EXISTS {db}.{t}{SUF} LIKE {db}.{t};\n" for db, t in sorted(WR) if t not in TABLES)
DROP = ''.join(f"DROP TABLE IF EXISTS {db}.{t}{SUF};\nDROP TABLE IF EXISTS {db}.{t}{SUF}__stg;\n" for db, t in sorted(WR) if t not in TABLES)
open(f'{OUT}/DDL_full.sql', 'w').write(DDL); open(f'{OUT}/DROP_full.sql', 'w').write(DROP)

print('bảng ghi mới:', len([1 for _, t in WR if t not in TABLES]), sorted(f'{d}.{t}' for d, t in WR if t not in TABLES))
for x in plan:
    if x['props'] or x['note']: print(f"  {x['g']} {x['state'][:4]} {x['type'][:14]:14} {x['name'][:42]:42} {x['note']}")
print('diff', len(diff), 'dòng')
if 'deploy' not in sys.argv: sys.exit()

# ================= DEPLOY =================
stamp = time.strftime('%H%M%S')
r = s.get(API + f'/process-groups/{NEW}/download'); r.raise_for_status()
open(f'{OUT}/backup_NEW_flowdef_{stamp}.json', 'w').write(r.text)

# 1) copy group con (kèm kết nối giữa chúng) vào NEW
oc = G(f'/flow/process-groups/{OLD}')['processGroupFlow']['flow']
ids = {oldsubs[k]['id'] for k in COPY}
conns = [c for c in oc['connections'] if c['component']['source']['groupId'] in ids and c['component']['destination']['groupId'] in ids]
snip = P('POST', '/snippets', {'snippet': {'parentGroupId': OLD,
         'processGroups': {i: {'version': oldsubs[i[:8]]['revision']['version']} for i in ids},
         'connections': {c['id']: {'version': c['revision']['version']} for c in conns}}})
inst = P('POST', f'/process-groups/{NEW}/snippet-instance',
         {'snippetId': snip['snippet']['id'], 'originX': 0.0, 'originY': 1400.0, 'disconnectedNodeAcknowledged': False})
newgroups = {g['component']['name']: g['id'] for g in inst['flow']['processGroups']}
json.dump(newgroups, open(f'{OUT}/copied_groups.json', 'w'), ensure_ascii=False, indent=1)
print('đã copy', newgroups)

# 2) sửa SQL trong bản sao + th_tongquan
targets = [p for gid in newgroups.values() for p in allp(gid)] + core_th
for p in targets:
    ch, note = transform(p)
    if not ch: continue
    cur = G(f"/processors/{p['id']}")
    assert cur['component']['state'] != 'RUNNING', cur['component']['name']
    P('PUT', f"/processors/{p['id']}", {'revision': cur['revision'], 'component': {
        'id': p['id'], 'config': {'properties': {k: b for k, (a, b) in ch.items()}}}})
print('đã sửa SQL', sum(1 for p in targets if transform(p)[0]))

# 3) cổng: thêm thuộc tính moi_phut (luôn đúng) và nối tới input port các group
nf = G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']
gates = {p['component']['name']: p for p in nf['processors'] if p['component']['name'].startswith('Cổng 15 phút')}
for name, p in gates.items():
    cur = G(f"/processors/{p['id']}")
    P('PUT', f"/processors/{p['id']}", {'revision': cur['revision'], 'component': {'id': p['id'],
        'config': {'properties': {'moi_phut': "${sync_ts:isEmpty():not()}"}}}})
old_name = {v['component']['name']: k for k, v in oldsubs.items()}
for gname, gid in newgroups.items():
    k = old_name.get(gname)
    gate, rel = COPY.get(k, (None, None))
    if not gate: continue
    ip = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']['inputPorts']
    assert len(ip) == 1, (gname, len(ip))
    P('POST', f'/process-groups/{NEW}/connections', {'revision': {'version': 0}, 'component': {
        'source': {'id': gates[gate]['id'], 'groupId': NEW, 'type': 'PROCESSOR'},
        'destination': {'id': ip[0]['id'], 'groupId': gid, 'type': 'INPUT_PORT'},
        'selectedRelationships': [rel], 'backPressureObjectThreshold': 5, 'flowFileExpiration': '10 min'}})
    print('NỐI', gate, f'[{rel}] →', gname)
print('XONG deploy (chưa bật gì)')
