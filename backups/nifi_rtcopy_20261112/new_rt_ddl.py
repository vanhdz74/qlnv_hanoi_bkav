"""Bước 2: kiểm SQL đã PUT, chạy '0. DDL tạo bảng _new_rt' một lần, kiểm 13 bảng _new_rt."""
import re, time
from rtlib import *
SUF = '_new_rt'
PAT = re.compile(r'(?<![\w])(' + '|'.join(TABLES) + r')(?![\w])')
bad = []
for p in allprocs(NEW):
    c = p['component']
    if c['state'] == 'DISABLED' or not re.search(r'\[(upsert|stg)\]', c['name']): continue
    for k, v in c['config']['properties'].items():
        if isinstance(v, str) and PAT.search(v): bad.append((c['name'], k))
print('processor còn trỏ bảng thật:', bad)
assert not bad

ddl = [p for p in procs(NEW) if p['component']['name'].startswith('0. DDL')][0]
print('DDL proc:', ddl['component']['name'], ddl['component']['state'], ddl['status']['aggregateSnapshot']['runStatus'])
setstate(ddl, 'RUN_ONCE')
t0 = time.time()
want = [t + SUF for t in TABLES] + ['qlnv_tongquan' + SUF + '__stg']
inl = ','.join("'%s'" % t for t in want)
while time.time() - t0 < 90:
    time.sleep(5)
    rows = Q(f"SELECT table_name t FROM information_schema.tables WHERE table_schema='datamart_hanoi' AND table_name IN ({inl})")
    st = G(f"/processors/{ddl['id']}")['status']['aggregateSnapshot']
    if len(rows) == len(want) and st['activeThreadCount'] == 0: break
print('bảng có:', len(rows), '/', len(want), 'sau', round(time.time() - t0), 's')
ks = Q("SELECT table_name, index_name FROM information_schema.statistics WHERE table_schema='datamart_hanoi' "
       "AND index_name IN ('uk_rt_ma_nhom','uk_rt_ma') AND table_name LIKE '%\\_new\\_rt' GROUP BY 1,2")
print('khóa uk_rt:', ks)
cs = Q("SELECT table_name FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND column_name='syncdate' "
       "AND table_name LIKE 'qlnv_tonghop_chitiet_nhom_%\\_new\\_rt'")
print('syncdate trên nhom_*:', cs)
for b in G(f"/flow/bulletin-board?sourceId={ddl['id']}&limit=5")['bulletinBoard']['bulletins']:
    print('BULLETIN', b['bulletin']['timestamp'], b['bulletin']['message'][:300])
