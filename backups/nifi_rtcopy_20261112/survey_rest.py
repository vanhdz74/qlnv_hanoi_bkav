"""Chỉ đọc: khảo sát processor đang bật (không DISABLED) của BTH - Đơn vị ngoài chuỗi lõi.
Ghi new_rt/survey_rest.json: nhóm, tên, trạng thái, GFF lịch, bảng ghi, kiểu (TRUNCATE/upsert/...), bảng đọc, thời gian chạy TB (status history), số dòng & khóa của bảng đích."""
import re, json, statistics
from rtlib import *
CORE = {'8a2122ac', '8a2122af', 'bee43621', '142f3e8a'}
W = re.compile(r'(INSERT\s+(?:IGNORE\s+)?INTO|TRUNCATE\s+TABLE|DELETE\s+(?:\w+\s+)?FROM|REPLACE\s+INTO|UPDATE)\s+`?(?:datamart_hanoi`?\.)?`?(\w+)', re.I)
R = re.compile(r'(?:FROM|JOIN)\s+`?(?:(\w+)`?\.)?`?(\w+)', re.I)

def walk(gid, path):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']
    fl = f['flow']
    for p in fl['processors']:
        yield path, gid, p, fl
    for g in fl['processGroups']:
        if g['id'][:8] in CORE: continue
        yield from walk(g['id'], path + '/' + g['component']['name'])

out = []
for path, gid, p, fl in walk(OLD, ''):
    c = p['component']
    if c['state'] == 'DISABLED': continue
    t = c['type'].split('.')[-1]
    sql = '\n'.join(v for v in c['config']['properties'].values() if isinstance(v, str) and re.search(r'\b(SELECT|INSERT|UPDATE|DELETE|TRUNCATE)\b', v, re.I))
    item = {'grp': path or '/', 'gid': gid, 'id': p['id'], 'name': c['name'], 'type': t, 'state': c['state'],
            'sched': c['config']['schedulingPeriod']}
    if sql:
        ws = [(k.split()[0].upper(), tb) for k, tb in W.findall(sql)]
        item['writes'] = sorted({tb for _, tb in ws})
        item['kinds'] = sorted({k for k, _ in ws})
        item['upsert'] = 'ON DUPLICATE' in sql.upper()
        item['reads'] = sorted({(db + '.' if db else '') + tb for db, tb in R.findall(sql)} - set(item['writes']))
        item['sql_len'] = len(sql)
        try:
            h = G(f"/flow/processors/{p['id']}/status/history")['statusHistory']['aggregateSnapshots']
            durs = [s['statusMetrics'].get('taskMillis', 0) / s['statusMetrics']['taskCount']
                    for s in h if s['statusMetrics'].get('taskCount')]
            item['avg_s'] = round(statistics.mean(durs) / 1000, 1) if durs else None
            item['max_s'] = round(max(durs) / 1000, 1) if durs else None
        except Exception as e:
            item['avg_s'] = 'ERR ' + str(e)[:60]
    out.append(item)

tables = sorted({tb for i in out for tb in i.get('writes', [])})
if tables:
    inl = ','.join("'%s'" % t for t in tables)
    info = {r['t']: r for r in Q(f"SELECT table_name t, table_rows n, ROUND((data_length+index_length)/1048576) mb FROM information_schema.tables WHERE table_schema='datamart_hanoi' AND table_name IN ({inl})")}
    keys = {}
    for r in Q(f"SELECT table_name t, index_name k, GROUP_CONCAT(column_name ORDER BY seq_in_index) c FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name IN ({inl}) AND non_unique=0 GROUP BY 1,2"):
        keys.setdefault(r['t'], []).append(f"{r['k']}({r['c']})")
    for i in out:
        i['targets'] = {tb: {'rows': info.get(tb, {}).get('n'), 'mb': info.get(tb, {}).get('mb'), 'uniq': keys.get(tb, [])} for tb in i.get('writes', [])}
json.dump(out, open('new_rt/survey_rest.json', 'w'), ensure_ascii=False, indent=1, default=str)

for i in out:
    if i['type'] in ('LogAttribute',): continue
    if i['type'] == 'GenerateFlowFile':
        print(f"GFF  {i['state']:8} {i['sched']:10} {i['grp'][:40]:40} {i['name'][:30]}"); continue
    if 'writes' not in i: continue
    tg = '; '.join(f"{t}[{v['rows']}r {v['mb']}MB uk={v['uniq'][:1]}]" for t, v in i['targets'].items())
    print(f"SQL  {i['state']:8} {str(i.get('avg_s')):>5}s/{str(i.get('max_s')):>5} {i['grp'][:32]:32} {i['name'][:38]:38} {','.join(i['kinds'])} ups={int(i['upsert'])} -> {tg[:160]}")
