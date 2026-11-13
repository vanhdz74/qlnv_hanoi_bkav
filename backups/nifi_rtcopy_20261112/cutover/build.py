"""Chỉ đọc + ghi file cục bộ: sinh thuộc tính mới (bỏ _new_rt) cho processor RT, diff để duyệt."""
import json, re, difflib
new = json.load(open('cutover/survey.json'))
plan, diff = [], []
for p in new:
    if not p['props_new_rt'] or p['name'].startswith('0.'): continue
    ch = {}
    for k, v in p['props_new_rt'].items():
        nv = re.sub(r'_new_rt\b', '', v)
        nv = nv.replace('_new_rt__stg', '__stg').replace('_new_rt__old', '__old')
        assert '_new_rt' not in nv, (p['name'], k)
        ch[k] = nv
        d = [l for l in difflib.unified_diff(v.splitlines(), nv.splitlines(), lineterm='', n=0) if l[:1] in '+-' and l[:3] not in ('+++', '---')]
        diff.append(f"### {p['path'] or '/'} / {p['name']}  [{k}]  id={p['id']}  ({len(d)//2} dòng đổi)")
        diff += ['    ' + l[:220] for l in d]
    plan.append(dict(id=p['id'], path=p['path'], name=p['name'], state=p['state'], set=ch))
# processor DDL: thay bằng DDL v2 cho bảng thật
ddl = open('upsert/0_DDL_v2.sql').read(); rb = open('upsert/0_DDL_ROLLBACK_v2.sql').read()
json.dump(dict(procs=plan, ddl=ddl, rollback=rb), open('cutover/plan_cutover.json', 'w'), ensure_ascii=False, indent=1)
open('cutover/diff.txt', 'w').write('\n'.join(diff))
print('processor sửa:', len(plan), '| thuộc tính:', sum(len(x['set']) for x in plan))
import collections; print(collections.Counter(x['path'] or '/' for x in plan))
