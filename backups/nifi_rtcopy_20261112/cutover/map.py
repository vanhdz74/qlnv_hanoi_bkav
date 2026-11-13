"""Chỉ đọc: ghép bảng ↔ processor ghi cũ/mới, trạng thái, số dòng."""
import sys, json, re; sys.path.insert(0, '.')
from rtlib import G, Q
OLD = 'f8207212-019b-1000-fcc5-817989167c53'; NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
def walk(g, path, acc, skip=()):
    f = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for p in f['processors']:
        c = p['component']
        acc.append(dict(id=c['id'], g=g, path=path, name=c['name'], type=c['type'].split('.')[-1], state=c['state'],
                        props={k: v for k, v in c['config']['properties'].items() if v and k in ('SQL select query', 'sql-pre-query', 'sql-post-query', 'putsql-sql-statement', 'Table Name', 'put-db-record-table-name')}))
    for sg in f['processGroups']:
        if sg['id'] in skip: continue
        walk(sg['id'], path + '/' + sg['component']['name'], acc, skip)
    return acc
old = walk(OLD, '', [], skip={NEW})
json.dump(old, open('cutover/old_procs.json', 'w'), ensure_ascii=False, indent=1)
new = json.load(open('cutover/survey.json'))
W = r'(?:TRUNCATE\s+TABLE|INSERT\s+(?:IGNORE\s+)?INTO|REPLACE\s+INTO|UPDATE|DELETE\s+FROM|RENAME\s+TABLE)\s+(?:datamart_hanoi\.)?`?(\w+)'
def writes(p):
    s = ' '.join(p['props'].values()) if 'props' in p else ' '.join(p['props_new_rt'].values())
    t = set(x.lower() for x in re.findall(W, s, re.I))
    for k in ('Table Name', 'put-db-record-table-name'):
        if p.get('props', {}).get(k): t.add(p['props'][k].split('.')[-1].lower())
    return t
rows = {}
for p in new:
    if p['name'].startswith('0.'): continue
    for t in writes(p):
        if t.endswith('_new_rt'): rows.setdefault(t[:-7], {'new': [], 'old': []})['new'].append(f"{p['state'][:3]} {p['path']}/{p['name']}")
for p in old:
    for t in writes(p):
        if t in rows: rows[t]['old'].append(f"{p['state'][:3]} {p['path']}/{p['name']}")
for t in sorted(rows):
    try:
        a = Q(f"SELECT (SELECT COUNT(*) FROM {t}) o, (SELECT COUNT(*) FROM {t}_new_rt) n, (SELECT MAX(syncdate) FROM {t}_new_rt) mx")[0]
    except Exception as e: a = {'err': str(e)[:80]}
    rows[t]['cnt'] = a
    print(t, a); print('   MỚI:', rows[t]['new']); print('   CŨ :', rows[t]['old'])
json.dump(rows, open('cutover/map.json', 'w'), ensure_ascii=False, indent=1)
