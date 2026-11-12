"""Thay SQL 2 processor '0. DDL upsert' / '0. ROLLBACK DDL' bằng bản idempotent (chỉ ALTER khi cần),
3 bảng lớn (có thể trùng khóa) chạy trước, nhom_* (làm hỏng INSERT cũ) chạy sau cùng. Backup trước khi PUT."""
import json, sys
from rtlib import *
DB = 'datamart_hanoi'
T = 'qlnv_tonghop_chitiet'

def cond(table, check_sql, alter):
    """Chạy ALTER chỉ khi check_sql (đếm trong information_schema) > 0."""
    return (f"SET @s = (SELECT IF(({check_sql}) > 0, '{alter}', 'DO 0'));\n"
            "PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;\n")
def has_key(t, k): return (f"SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='{DB}' "
                           f"AND table_name='{t}' AND index_name='{k}'")
def has_col(t, c): return (f"SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='{DB}' "
                           f"AND table_name='{t}' AND column_name='{c}'")
def no(x): return f"1 - ({x})"
OL = ', ALGORITHM=INPLACE, LOCK=NONE'

DDL = "/* [RT 12/11 v2] DDL upsert, idempotent. Chạy SAU KHI dừng chuỗi cũ. Bảng lớn trước, nhom_* sau cùng */\n" \
      "SET SESSION lock_wait_timeout = 10;\n"
for t in [T, T + '_nhom', T + '_khoi']:
    DDL += cond(t, no(has_key(t, 'uk_rt_ma_nhom')), f"ALTER TABLE {DB}.{t} ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan){OL}")
for t in [T + '_nhom_tiepnhan', T + '_nhom_giaonv']:
    DDL += cond(t, no(has_key(t, 'uk_rt_ma')), f"ALTER TABLE {DB}.{t} ADD UNIQUE KEY uk_rt_ma (Ma){OL}")
    DDL += cond(t, no(has_col(t, 'syncdate')), f"ALTER TABLE {DB}.{t} ADD COLUMN syncdate DATETIME NULL{OL}")
DDL += "SET SESSION lock_wait_timeout = 31536000;"

RB = "/* [RT 12/11 v2] ROLLBACK DDL, idempotent. Chạy TRƯỚC KHI bật lại chuỗi cũ. nhom_* (cột syncdate) trước */\n" \
     "SET SESSION lock_wait_timeout = 10;\n"
for t in [T + '_nhom_tiepnhan', T + '_nhom_giaonv']:
    RB += cond(t, has_col(t, 'syncdate'), f"ALTER TABLE {DB}.{t} DROP COLUMN syncdate{OL}")
    RB += cond(t, has_key(t, 'uk_rt_ma'), f"ALTER TABLE {DB}.{t} DROP KEY uk_rt_ma{OL}")
for t in [T, T + '_nhom', T + '_khoi']:
    RB += cond(t, has_key(t, 'uk_rt_ma_nhom'), f"ALTER TABLE {DB}.{t} DROP KEY uk_rt_ma_nhom{OL}")
RB += "SET SESSION lock_wait_timeout = 31536000;"

open('upsert/0_DDL_v2.sql', 'w').write(DDL)
open('upsert/0_DDL_ROLLBACK_v2.sql', 'w').write(RB)
if 'deploy' not in sys.argv:
    print(DDL); print(RB); sys.exit()

ps = {p['component']['name']: p for p in procs(NEW) if p['component']['name'].startswith('0. ')}
json.dump(ps, open('backup_ddl_procs_before_v2.json', 'w'), ensure_ascii=False, indent=1)
for name, sql in [(n, DDL if 'ROLLBACK' not in n else RB) for n in ps]:
    p = ps[name]
    assert p['component']['state'] in ('STOPPED', 'DISABLED'), (name, p['component']['state'])
    P('PUT', f'/processors/{p["id"]}', {'revision': p['revision'], 'component': {
        'id': p['id'], 'config': {'properties': {'SQL select query': sql}}}})
    print('PUT', name)
