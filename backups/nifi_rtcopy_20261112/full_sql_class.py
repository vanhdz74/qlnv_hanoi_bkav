"""Chỉ đọc. Phân loại khác biệt SQL mới/cũ: bỏ phần vỏ (CREATE IF NOT EXISTS, SET ..., RENAME, TRUNCATE, DROP, DELETE theo sync,
ON DUPLICATE KEY UPDATE), so phần thân SELECT/UPDATE. In: VỎ (chỉ khác cách ghi) / LOGIC (thân SELECT khác)."""
import re, difflib
from full_sql_diff import new, old, oldk, norm
WRAP = re.compile(r'^(create table if not exists|set |rename table|truncate|drop table|delete from|analyze|select sleep)')
def body(q):
    st = [x.strip() for x in norm(q).replace(';;', ';').split(';') if x.strip()]
    st = [re.sub(r' on duplicate key update .*$', '', x) for x in st if not WRAP.match(x)]
    st = [re.sub(r'^insert into [\w.`]+\s*(\([^)]*\))?\s*', 'insert ', x) for x in st]
    st = [re.sub(r"'?\$\{sync_ts\}'?( as \w+)?|now\(\)( as \w+)?", '', x) for x in st]
    return st
for k, (sql, strat, per, typ) in sorted(new.items()):
    c = oldk.get(k[:2], [])
    if not c: print(f"{k[0][:20]:20} | {k[1][:40]:40} | không có ở cũ"); continue
    o = max(c, key=lambda o: difflib.SequenceMatcher(None, norm(old[o][0]), norm(sql)).ratio())
    a, b = body(old[o][0]), body(sql)
    tag = 'GIỐNG' if norm(old[o][0]) == norm(sql) else ('VỎ' if ' '.join(a) == ' '.join(b) else 'LOGIC')
    extra = ''
    if tag == 'LOGIC':
        ta, tb = ' '.join(a).split(), ' '.join(b).split()
        sm = difflib.SequenceMatcher(None, ta, tb, autojunk=False)
        ch = [(' '.join(ta[i1:i2])[:50], ' '.join(tb[j1:j2])[:90]) for op, i1, i2, j1, j2 in sm.get_opcodes() if op != 'equal']
        extra = f" {len(ch)} chỗ: " + ' | '.join(f"«{x}»→«{y}»" for x, y in ch[:2])
    print(f"{k[0][:20]:20} | {k[1][:40]:40} | {tag}{extra}"[:330])
