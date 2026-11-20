"""[OPT 19/11] tiepnhan/giaonv: chỉ ghi dòng đổi (bảng tạm → upsert dòng khác → xóa anti-join), bỏ 9 JOIN không dùng, bỏ ORDER BY.
Chạy: python3 deploy.py --dry | python3 deploy.py [tiepnhan giaonv] | python3 deploy.py --rollback [tiepnhan giaonv]
"""
import sys, re, json, time, os
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P, Q
D = os.path.dirname(os.path.abspath(__file__))
PROCS = {'tiepnhan': ('142f3e95', 'qlnv_tonghop_chitiet_tiepnhan'),
         'giaonv':   ('142f3eb5', 'qlnv_tonghop_chitiet_giaonv')}
RT = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
PROP = 'putsql-sql-statement'
STR = {'varchar', 'char', 'text', 'longtext', 'mediumtext', 'tinytext'}

def full_id(pre):
    return [p['id'] for p in G(f'/process-groups/{RT}/processors?includeDescendantGroups=true')['processors'] if p['id'].startswith(pre)][0]

def strip_joins(s):
    s2 = re.sub(r'\n[ \t]*/\* Đơn vị tạo nhiệm vụ \*/\s*LEFT JOIN datamart_hanoi\.department dv_taonv\b.*?ON dv_taonv4\.DepartmentId = dv_taonv3\.ParentId', '', s, flags=re.S)
    s2 = re.sub(r'\n[ \t]*LEFT JOIN db_theodoinv_hn\.qlnv_resolution_group rg1 .*?rg4\.IsRoot = 0', '', s2, flags=re.S)
    body = re.sub(r'/\*.*?\*/', '', s2, flags=re.S)
    assert not re.search(r'\bdv_taonv\d?\.|\brg[1-4]\.', re.sub(r'--[^\n]*', '', body)), 'còn tham chiếu alias đã bỏ'
    return s2

def build(k, old):
    _, tb = PROCS[k]
    T = f'datamart_hanoi.{tb}'
    m = re.search(r'INSERT INTO\s+' + re.escape(T) + r'\s*(SELECT.*?)ON DUPLICATE KEY UPDATE(.*?);\s*(/\*[^*]*\*/\s*)?DELETE FROM', old, re.S)
    assert m, 'không tách được SQL'
    sel, odku = m.group(1), m.group(2).strip()
    sel = strip_joins(sel)
    sel2 = re.sub(r'\n\s*ORDER BY\s+main\.`year`.*$', '\n', sel.rstrip(), flags=re.S)
    assert sel2 != sel.rstrip() and 'ORDER BY' not in sel2[-400:], 'không bỏ được ORDER BY'
    cols = {r['c']: r['d'] for r in Q(f"SELECT column_name c, data_type d FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='{tb}'")}
    oc = re.findall(r'`(\w+)` = VALUES', odku)
    assert oc and all(c in cols for c in oc)
    cmp = [c for c in oc if c != 'syncdate']
    eq = lambda c: (f"BINARY n.`{c}` <=> BINARY o.`{c}`" if cols[c] in STR else f"n.`{c}` <=> o.`{c}`")
    tmp = f'opt_{k}'
    return f"""/* [OPT 19/11] chỉ ghi dòng đổi: tính vào bảng tạm (PK Ma) → upsert dòng khác bảng thật → xóa dòng không còn trong nguồn.
   Bỏ 9 JOIN không dùng (dv_taonv*, rg1-4) và ORDER BY. syncdate = lần dòng đổi gần nhất. Bản cũ: backups/nifi_opt_ghi_20261119/ */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DROP TEMPORARY TABLE IF EXISTS {tmp};
CREATE TEMPORARY TABLE {tmp} ENGINE=InnoDB AS SELECT * FROM {T} LIMIT 0;
ALTER TABLE {tmp} ADD PRIMARY KEY (Ma);
INSERT INTO {tmp}
{sel2.strip()}
ON DUPLICATE KEY UPDATE
    {odku};
INSERT INTO {T}
SELECT d.* FROM (
    SELECT n.* FROM {tmp} n LEFT JOIN {T} o ON o.Ma = n.Ma
    WHERE o.Ma IS NULL OR NOT (
        {(chr(10) + '        AND ').join(eq(c) for c in cmp)}
    )
) d
ON DUPLICATE KEY UPDATE
    {odku};
DELETE o FROM {T} o LEFT JOIN {tmp} n ON n.Ma = o.Ma WHERE n.Ma IS NULL;
DROP TEMPORARY TABLE IF EXISTS {tmp};"""

def setstate(pid, st):
    p = G(f'/processors/{pid}')
    P('PUT', f'/processors/{pid}/run-status', {'revision': p['revision'], 'state': st})
    for _ in range(90):
        s = G(f'/flow/processors/{pid}/status')['processorStatus']['aggregateSnapshot']
        if st == 'RUNNING' or s.get('activeThreadCount', 0) == 0: return
        time.sleep(1)
    raise SystemExit(f'{pid} còn thread chạy')

def put_sql(pid, sql):
    setstate(pid, 'STOPPED')
    p = G(f'/processors/{pid}')
    P('PUT', f'/processors/{pid}', {'revision': p['revision'], 'component': {'id': pid, 'config': {'properties': {PROP: sql}}}})
    for _ in range(20):
        p = G(f'/processors/{pid}')
        if p['component']['validationStatus'] == 'VALID': break
        time.sleep(1)
    assert p['component']['validationStatus'] == 'VALID', p['component'].get('validationErrors')
    setstate(pid, 'RUNNING')

args = [a for a in sys.argv[1:] if not a.startswith('--')]
keys = args or list(PROCS)
for k in keys:
    pid = full_id(PROCS[k][0])
    bk = f'{D}/backup_{k}_before.json'
    if '--rollback' in sys.argv:
        old = json.load(open(bk))['component']['config']['properties'][PROP]
        put_sql(pid, old); print(time.strftime('%T'), k, 'ĐÃ ROLLBACK'); continue
    p = G(f'/processors/{pid}')
    old = p['component']['config']['properties'][PROP]
    if old.startswith('/* [OPT 19/11]'):
        print(k, 'đã là bản OPT, bỏ qua'); continue
    new = build(k, old)
    open(f'{D}/{k}_new.sql', 'w').write(new)
    if '--dry' in sys.argv:
        print(k, 'dry ok', len(old), '->', len(new), 'ký tự'); continue
    if not os.path.exists(bk):
        json.dump(p, open(bk, 'w'), ensure_ascii=False, indent=1)
    put_sql(pid, new)
    print(time.strftime('%T'), k, 'đã đẩy bản OPT', pid)
