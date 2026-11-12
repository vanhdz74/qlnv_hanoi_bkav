"""TRUNCATE+INSERT → INSERT … ON DUPLICATE KEY UPDATE + DELETE theo syncdate = '${sync_ts}' (giờ NiFi).
Logic SELECT giữ nguyên. Các bảng con chép SELECT * → đổi thành danh sách cột + '${sync_ts}' (syncdate là
TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, giờ MySQL chậm 4'40" → không được chép syncdate từ bảng nguồn)."""
import re, json

DB = 'datamart_hanoi'
COLS = {r['t']: r['c'].split(',') for r in json.load(open('cols.json'))}
TS = "'${sync_ts}'"
HEADER = '/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */\n'
# cột tính lại bằng UPDATE tại chỗ sau INSERT → không ghi đè khi trùng khóa (giữ giá trị cũ tới khi UPDATE chạy)
RECALC = {'NhomCauTrucNhiemVu', 'iddv_dvchutri', 'DonViChuTri'}
P = 'qlnv_tonghop_chitiet'
KEY = {P + '_tiepnhan': ['Ma'], P + '_tiepnhan_don_le': ['Ma'], P + '_tiepnhan_theo_chuoi': ['Ma'],
       P + '_giaonv': ['Ma'], P + '_giaonv_don_le': ['Ma'], P + '_giaonv_theo_chuoi': ['Ma'],
       P + '_nhom_tiepnhan': ['Ma'], P + '_nhom_giaonv': ['Ma'],
       P: ['Ma', 'NhomGiaoNhan'], P + '_nhom': ['Ma', 'NhomGiaoNhan'], P + '_khoi': ['Ma', 'NhomGiaoNhan']}


def cols(t):
    c = list(COLS[t])
    if 'syncdate' not in c:
        c.append('syncdate')          # nhom_tiepnhan / nhom_giaonv: thêm cột bằng DDL
    return c


def tail(t, keep_recalc=False):
    upd = [c for c in cols(t) if c not in KEY[t] and not (keep_recalc and c in RECALC)]
    return ("\nON DUPLICATE KEY UPDATE\n    " + ",\n    ".join(f"`{c}` = VALUES(`{c}`)" for c in upd) + ";\n"
            f"/* Xóa bản ghi không còn trong nguồn ở chu kỳ này */\n"
            f"DELETE FROM {DB}.{t} WHERE syncdate < {TS} OR syncdate IS NULL;")


def _strip(sql, t):
    """Bỏ TRUNCATE t; trả về (phần trước INSERT, phần từ INSERT tới trước ';' cuối)."""
    assert len(re.findall(rf'TRUNCATE\s+TABLE\s+{DB}\.{t}\s*;', sql)) == 1, t
    sql = re.sub(rf'TRUNCATE\s+TABLE\s+{DB}\.{t}\s*;\s*', '', sql)
    m = list(re.finditer(rf'INSERT\s+INTO\s+{DB}\.{t}(?!\w)', sql))
    assert len(m) == 1, t
    pre, body = sql[:m[0].start()], sql[m[0].start():].rstrip()
    assert body.endswith(';'), t
    return pre, body[:-1].rstrip()


def rc(body):
    return 'SET TRANSACTION ISOLATION LEVEL READ COMMITTED;\n' + body


def explicit(sql, t, keep_recalc=False):
    """INSERT đã có biểu thức NOW() AS syncdate (tiepnhan, giaonv, chitiet, nhom)."""
    pre, body = _strip(sql, t)
    n = len(re.findall(r'NOW\(\)\s+AS\s+syncdate', body, re.I))
    assert n >= 1, t
    body = re.sub(r'NOW\(\)(\s+)AS\s+syncdate', TS + r'\1AS syncdate', body, flags=re.I)
    return HEADER + pre + rc(body) + tail(t, keep_recalc)


def star(sql, t):
    """INSERT INTO t SELECT * FROM <nguồn> t … → cột tường minh, syncdate = sync_ts."""
    pre, body = _strip(sql, t)
    assert len(re.findall(r'SELECT\s+\*', body)) == 1, t
    c = cols(t)
    sel = ',\n    '.join(f't.`{x}`' if x != 'syncdate' else f'{TS} AS syncdate' for x in c)
    body = re.sub(rf'INSERT\s+INTO\s+{DB}\.{t}(?!\w)', f'INSERT INTO {DB}.{t} (' + ', '.join(f'`{x}`' for x in c) + ')', body)
    body = re.sub(r'SELECT\s+\*', 'SELECT\n    ' + sel, body, count=1)
    return HEADER + pre + rc(body) + tail(t)


def positional_add(sql, t):
    """nhom_tiepnhan / nhom_giaonv: INSERT không có danh sách cột → thêm danh sách + cột syncdate cuối."""
    pre, body = _strip(sql, t)
    i = re.search(r'\n\s*FROM\s*\(', body)
    assert i and 'FROM' not in body[:i.start()].upper().replace('FROM (', ''), t
    c = cols(t)
    body = body[:i.start()] + f',\n    {TS} AS syncdate' + body[i.start():]
    body = re.sub(rf'INSERT\s+INTO\s+{DB}\.{t}(?!\w)', f'INSERT INTO {DB}.{t} (' + ', '.join(f'`{x}`' for x in c) + ')', body)
    return HEADER + pre + rc(body) + tail(t)


def nhom_update(t):
    """Thay 3 câu UPDATE (mặc định NULL rồi lấp dần) bằng 1 câu tính lại toàn bộ — cùng kết quả,
    vì upsert không còn đặt NhomCauTrucNhiemVu về NULL trước mỗi lượt."""
    T = f'{DB}.{t}'
    return (HEADER +
            f"UPDATE {T} t\n"
            f"LEFT JOIN (SELECT DISTINCT ma_nv_cha FROM {T} WHERE ma_nv_cha IS NOT NULL) c ON c.ma_nv_cha = t.Ma\n"
            f"LEFT JOIN (SELECT tennv_viettat, COUNT(DISTINCT Ma) cnt FROM {T} WHERE tennv_viettat IS NOT NULL GROUP BY tennv_viettat) g\n"
            f"       ON g.tennv_viettat = t.tennv_viettat\n"
            f"SET t.NhomCauTrucNhiemVu = CASE\n"
            f"    WHEN t.ma_nv_cha IS NOT NULL OR c.ma_nv_cha IS NOT NULL THEN 'Nhiệm vụ theo chuỗi'\n"
            f"    WHEN g.tennv_viettat IS NULL OR g.cnt <= 1 THEN 'Nhiệm vụ đơn lẻ'   -- không có NV khác cùng tên viết tắt\n"
            f"    ELSE 'Chưa xác định'\n"
            f"END;")


def keep(sql, t):  # Update DonViChuTri: đã tính lại toàn bộ (CASE … ELSE), giữ nguyên
    return HEADER + sql


TP, GV = P + '_tiepnhan', P + '_giaonv'
PLAN = {
    'Tiếp nhận NV': [
        ('qlnv_tonghop_chitiet_tiepnhan', 'putsql-sql-statement', lambda s: explicit(s, TP, True)),
        ('Update NhomCauTrucNhiemVu Nhan', 'putsql-sql-statement', lambda s: nhom_update(TP)),
        ('Update DonViChuTri', 'putsql-sql-statement', lambda s: keep(s, TP)),
        ('qlnv_tonghop_chitiet_tiepnhan_don_le', 'putsql-sql-statement', lambda s: star(s, TP + '_don_le')),
        ('qlnv_tonghop_chitiet_tiepnhan_theo_chuoi', 'putsql-sql-statement', lambda s: star(s, TP + '_theo_chuoi')),
        ('qlnv_tonghop_chitiet_nhom_tiepnhan', 'putsql-sql-statement', lambda s: positional_add(s, P + '_nhom_tiepnhan')),
    ],
    'Giao NV': [
        ('qlnv_tonghop_chitiet_giaonv', 'putsql-sql-statement', lambda s: explicit(s, GV, True)),
        ('Update NhomCauTrucNhiemVu Giao', 'putsql-sql-statement', lambda s: nhom_update(GV)),
        ('Update DonViChuTri', 'putsql-sql-statement', lambda s: keep(s, GV)),
        ('qlnv_tonghop_chitiet_giaonv_theo_chuoi', 'SQL select query', lambda s: star(s, GV + '_theo_chuoi')),
        ('qlnv_tonghop_chitiet_giaonv_don_le', 'SQL select query', lambda s: star(s, GV + '_don_le')),
        ('qlnv_tonghop_chitiet_nhom_giaonv', 'SQL select query', lambda s: positional_add(s, P + '_nhom_giaonv')),
    ],
    'Giao + Nhận NV': [
        ('qlnv_tonghop_chitiet', 'SQL select query', lambda s: explicit(s, P)),
        ('qlnv_tonghop_chitiet_nhom', 'SQL select query', lambda s: explicit(s, P + '_nhom')),
        ('qlnv_tonghop_chitiet_khoi', 'SQL select query', lambda s: star(s, P + '_khoi')),
        # qlnv_tongquan: bảng tổng hợp GROUP BY 11 cột có NULL, phần NQ57 lấy syncdate từ tla → giữ bản staging swap
    ],
}

DDL = (
    "/* [RT 12/11] DDL cho upsert — chạy 1 lần SAU KHI đã dừng chuỗi cũ (INSERT cũ của nhom_* không có danh sách cột) */\n"
    "SET SESSION lock_wait_timeout = 10;\n"
    f"ALTER TABLE {DB}.{P}_nhom_tiepnhan ADD COLUMN syncdate DATETIME NULL, ADD UNIQUE KEY uk_rt_ma (Ma);\n"
    f"ALTER TABLE {DB}.{P}_nhom_giaonv ADD COLUMN syncdate DATETIME NULL, ADD UNIQUE KEY uk_rt_ma (Ma);\n"
    f"ALTER TABLE {DB}.{P} ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);\n"
    f"ALTER TABLE {DB}.{P}_nhom ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);\n"
    f"ALTER TABLE {DB}.{P}_khoi ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);\n"
    "SET SESSION lock_wait_timeout = 31536000;")
DDL_ROLLBACK = (
    "/* [RT 12/11] ROLLBACK DDL — chạy trước khi bật lại chuỗi cũ (INSERT cũ của nhom_* sẽ lỗi nếu còn cột syncdate) */\n"
    "SET SESSION lock_wait_timeout = 10;\n"
    f"ALTER TABLE {DB}.{P}_nhom_tiepnhan DROP COLUMN syncdate, DROP KEY uk_rt_ma;\n"
    f"ALTER TABLE {DB}.{P}_nhom_giaonv DROP COLUMN syncdate, DROP KEY uk_rt_ma;\n"
    f"ALTER TABLE {DB}.{P} DROP KEY uk_rt_ma_nhom;\n"
    f"ALTER TABLE {DB}.{P}_nhom DROP KEY uk_rt_ma_nhom;\n"
    f"ALTER TABLE {DB}.{P}_khoi DROP KEY uk_rt_ma_nhom;\n"
    "SET SESSION lock_wait_timeout = 31536000;")
