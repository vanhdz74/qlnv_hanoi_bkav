"""Chỉ đọc. So SQL từng processor: luồng mới (RT 142f3e8a) và luồng cũ (BTH - Đơn vị), ghép theo (group con, tên processor).
Chuẩn hóa: bỏ comment, bỏ _new_rt/__stg, gộp khoảng trắng, chữ thường. Phân loại: GIỐNG / KHÁC (ghi các khác biệt chính)."""
import re, difflib, json
from rtlib import G
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'; OLD = 'f8207212-019b-1000-fcc5-817989167c53'
KEYS = ('SQL select query', 'putsql-sql-statement', 'sql-pre-query', 'sql-post-query', 'Replacement Value', 'generate-ff-custom-text')
def norm(q):
    q = re.sub(r'/\*.*?\*/', ' ', q, flags=re.S); q = re.sub(r'--[^\n]*', ' ', q)
    q = q.replace('_new_rt', '').replace('__stg', '')
    return re.sub(r'\s+', ' ', q).strip().lower()
def collect(root, skip=()):
    out = {}
    for sg in G(f'/flow/process-groups/{root}')['processGroupFlow']['flow']['processGroups']:
        if sg['id'] in skip: continue
        for p in G(f"/process-groups/{sg['id']}/processors")['processors']:
            c = p['component']
            if c['state'] == 'DISABLED': continue
            pr = c['config']['properties']
            sql = '\n;;\n'.join(pr[k] for k in KEYS if pr.get(k))
            if not sql and not c['type'].endswith('PutDatabaseRecord'): continue
            nm = re.sub(r'\s*\[(upsert|stg)\]', '', c['name'])
            out[(sg['component']['name'], nm, c['id'][:4])] = (sql, c['config']['schedulingStrategy'], c['config']['schedulingPeriod'], c['type'].split('.')[-1])
    return out
new, old = collect(NEW), collect(OLD, skip={NEW})
oldk = {}
for k in old: oldk.setdefault(k[:2], []).append(k)
res = []
for k, (sql, *_ ) in sorted(new.items()):
    cands = oldk.get(k[:2], [])
    if not cands: res.append((k, 'KHÔNG CÓ Ở CŨ', '')); continue
    best = max(cands, key=lambda o: difflib.SequenceMatcher(None, norm(old[o][0]), norm(sql)).ratio())
    a, b = norm(old[best][0]), norm(sql)
    if a == b: res.append((k, 'GIỐNG', '')); continue
    ta, tb = re.findall(r"[\w.]+|'[^']*'|\S", a), re.findall(r"[\w.]+|'[^']*'|\S", b)
    sm = difflib.SequenceMatcher(None, ta, tb, autojunk=False)
    ch = [(op, ' '.join(ta[i1:i2])[:70], ' '.join(tb[j1:j2])[:110]) for op, i1, i2, j1, j2 in sm.get_opcodes() if op != 'equal']
    res.append((k, f'KHÁC ({sm.ratio():.2f})', ch[:6]))
for k, st, ch in res:
    print(f"{k[0][:22]:22} | {k[1][:42]:42} | {st}")
    for op, x, y in (ch or [])[:4]: print(f"      {op}: «{x}» → «{y}»")
json.dump([[list(k), st, ch] for k, st, ch in res], open('full/sql_diff.json', 'w'), ensure_ascii=False, indent=1)
