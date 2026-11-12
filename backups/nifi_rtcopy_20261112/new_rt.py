"""Chạy thử song song: chuỗi 142f3e8a ghi vào bảng *_new_rt thay vì bảng thật.
python3 new_rt.py            -> chỉ đọc: backup, sinh SQL mới + diff + DDL vào new_rt/
python3 new_rt.py deploy     -> PUT SQL đổi tên vào 16 processor + DDL vào '0. DDL upsert' (không bật gì)
"""
import sys, os, re, json, difflib, time
from rtlib import *

OUT = 'new_rt'; os.makedirs(OUT, exist_ok=True)
SUF = '_new_rt'
# bảng chuỗi ghi + đọc lại; tên dài trước
REN = sorted(TABLES, key=len, reverse=True)
STG_OLD, STG_NEW = 'qlnv_tongquan__stg', 'qlnv_tongquan' + SUF + '__stg'
PAT = re.compile(r'(?<![\w])(' + '|'.join(REN) + r')(?![\w])')

def rename(sql):
    sql = sql.replace(STG_OLD, '\0STG\0').replace('qlnv_tongquan__old', '\0OLD\0')
    sql = PAT.sub(lambda m: m.group(1) + SUF, sql)
    return sql.replace('\0STG\0', STG_NEW).replace('\0OLD\0', 'qlnv_tongquan' + SUF + '__old')

SQL_KEYS = ('SQL select query', 'putsql-sql-statement', 'sql-pre-query', 'sql-post-query', 'Replacement Value')

# --- chọn processor: thuộc chuỗi (tên có [upsert]/[stg]), không DISABLED
targets = []
for p in allprocs(NEW):
    c = p['component']
    if c['state'] == 'DISABLED' or not re.search(r'\[(upsert|stg)\]', c['name']):
        continue
    changes = {}
    for k in SQL_KEYS:
        v = c['config']['properties'].get(k)
        if v and PAT.search(v.replace(STG_OLD, '')) or (v and STG_OLD in v):
            changes[k] = (v, rename(v))
    targets.append((p, changes))

stamp = time.strftime('%H%M%S')
if not os.path.exists(f'{OUT}/backup_procs_before.json'):
    json.dump([p for p, _ in targets], open(f'{OUT}/backup_procs_before.json', 'w'), ensure_ascii=False, indent=1)

diff_all = []
for p, ch in targets:
    c = p['component']
    for k, (a, b) in ch.items():
        fn = re.sub(r'\W+', '_', f"{p['_g'][:8]}_{c['name']}_{k}")
        open(f'{OUT}/{fn}.sql', 'w').write(b)
        diff_all += list(difflib.unified_diff(a.splitlines(), b.splitlines(), f"{c['name']} :: {k} (cũ)", f"{c['name']} :: {k} (mới)", n=0, lineterm=''))
open(f'{OUT}/diff.txt', 'w').write('\n'.join(diff_all))

# --- DDL: tạo bảng _new_rt LIKE bảng thật, áp khóa/cột như DDL v2 (idempotent)
DB = 'datamart_hanoi'
def cond(check, stmt):
    return f"SET @s = (SELECT IF(({check}) > 0, '{stmt}', 'DO 0'));\nPREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;\n"
def has_key(t, k): return f"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='{DB}' AND table_name='{t}' AND index_name='{k}'"
def has_col(t, c): return f"SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='{DB}' AND table_name='{t}' AND column_name='{c}'"
T = 'qlnv_tonghop_chitiet'
DDL = "/* [RT 12/11 new_rt] Tạo bảng *_new_rt cho chạy thử song song. Không đụng bảng thật. Idempotent. */\n"
for t in TABLES:
    DDL += f"CREATE TABLE IF NOT EXISTS {DB}.{t}{SUF} LIKE {DB}.{t};\n"
DDL += f"CREATE TABLE IF NOT EXISTS {DB}.{STG_NEW} LIKE {DB}.qlnv_tongquan;\n"
for t in [T, T + '_nhom', T + '_khoi']:
    n = t + SUF
    DDL += cond('1 - (' + has_key(n, 'uk_rt_ma_nhom') + ')', f"ALTER TABLE {DB}.{n} ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan)")
for t in [T + '_nhom_tiepnhan', T + '_nhom_giaonv']:
    n = t + SUF
    DDL += cond('1 - (' + has_key(n, 'uk_rt_ma') + ')', f"ALTER TABLE {DB}.{n} ADD UNIQUE KEY uk_rt_ma (Ma)")
    DDL += cond('1 - (' + has_col(n, 'syncdate') + ')', f"ALTER TABLE {DB}.{n} ADD COLUMN syncdate DATETIME NULL")
open(f'{OUT}/DDL_new_rt.sql', 'w').write(DDL)
DROP = "/* Dọn chạy thử: xóa bảng *_new_rt */\n" + ''.join(
    f"DROP TABLE IF EXISTS {DB}.{t}{SUF};\n" for t in TABLES) + f"DROP TABLE IF EXISTS {DB}.{STG_NEW};\n"
open(f'{OUT}/DROP_new_rt.sql', 'w').write(DROP)

print('processor chuỗi:', len(targets), '| có đổi SQL:', sum(1 for _, ch in targets if ch))
for p, ch in targets:
    c = p['component']
    left = [m for k, (a, b) in ch.items() for m in re.findall(r'\bqlnv_\w+', b) if m in TABLES]
    print(f"  {c['state']:8} {c['name'][:50]:50} keys={list(ch)} còn_tên_cũ={sorted(set(left))}")
print('diff:', f'{OUT}/diff.txt', len(diff_all), 'dòng')

if 'deploy' not in sys.argv:
    sys.exit()

# ---------------- DEPLOY (chỉ PUT cấu hình, không bật processor)
for p, ch in targets:
    if not ch: continue
    cur = G(f"/processors/{p['id']}")
    assert cur['component']['state'] == 'STOPPED', (cur['component']['name'], cur['component']['state'])
    P('PUT', f"/processors/{p['id']}", {'revision': cur['revision'], 'component': {
        'id': p['id'], 'config': {'properties': {k: b for k, (a, b) in ch.items()}}}})
    print('PUT', cur['component']['name'])
ddlp = [p for p in procs(NEW) if p['component']['name'].startswith('0. DDL')][0]
json.dump(ddlp, open(f'{OUT}/backup_ddl_proc_before.json', 'w'), ensure_ascii=False, indent=1)
cur = G(f"/processors/{ddlp['id']}")
P('PUT', f"/processors/{ddlp['id']}", {'revision': cur['revision'], 'component': {
    'id': ddlp['id'], 'name': '0. DDL tạo bảng _new_rt (chạy thử song song)',
    'config': {'properties': {'SQL select query': DDL}}}})
print('PUT DDL processor')
