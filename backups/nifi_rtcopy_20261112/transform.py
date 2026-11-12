"""Chuyển SQL TRUNCATE+INSERT sang staging (__stg) + RENAME swap. Không đổi logic SELECT."""
import re

DB = 'datamart_hanoi'
HEADER = '/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */\n'


def swap_sql(t):
    return (f"\n/* Đổi chỗ nguyên tử; chờ khóa tối đa 10s để không chặn dashboard */\n"
            f"SET SESSION lock_wait_timeout = 10;\n"
            f"RENAME TABLE {DB}.{t} TO {DB}.{t}__old, {DB}.{t}__stg TO {DB}.{t}, {DB}.{t}__old TO {DB}.{t}__stg;\n"
            f"SET SESSION lock_wait_timeout = 31536000;")


def writer(sql, t, swap=True):
    """TRUNCATE+INSERT vào t → ghi vào t__stg (+ swap nếu swap=True)."""
    n_tr = len(re.findall(rf'TRUNCATE\s+TABLE\s+{DB}\.{t}\s*;', sql))
    n_in = len(re.findall(rf'INSERT\s+INTO\s+{DB}\.{t}(?!\w)', sql))
    assert n_tr == 1 and n_in == 1, (t, n_tr, n_in)
    sql = re.sub(rf'TRUNCATE\s+TABLE\s+{DB}\.{t}\s*;',
                 f'CREATE TABLE IF NOT EXISTS {DB}.{t}__stg LIKE {DB}.{t};\nTRUNCATE TABLE {DB}.{t}__stg;', sql)
    sql = re.sub(rf'INSERT\s+INTO\s+{DB}\.{t}(?!\w)',
                 f'SET TRANSACTION ISOLATION LEVEL READ COMMITTED;\nINSERT INTO {DB}.{t}__stg', sql)
    sql = sql.rstrip()
    if not sql.endswith(';'):
        sql += ';'
    return HEADER + sql + (swap_sql(t) if swap else '')


def updater(sql, t, swap=False):
    """UPDATE trên t → trên t__stg (+ swap ở bước cuối)."""
    n = len(re.findall(rf'{DB}\.{t}(?!\w)', sql))
    assert n >= 1, t
    sql = re.sub(rf'{DB}\.{t}(?!\w)', f'{DB}.{t}__stg', sql).rstrip()
    if not sql.endswith(';'):
        sql += ';'
    return HEADER + sql + (swap_sql(t) if swap else '')


# (group cũ, tên processor, prop, hàm, bảng, swap)
TP = 'qlnv_tonghop_chitiet_tiepnhan'
GV = 'qlnv_tonghop_chitiet_giaonv'
PLAN = {
    'Tiếp nhận NV': [
        ('qlnv_tonghop_chitiet_tiepnhan', 'putsql-sql-statement', writer, TP, False),
        ('Update NhomCauTrucNhiemVu Nhan', 'putsql-sql-statement', updater, TP, False),
        ('Update DonViChuTri', 'putsql-sql-statement', updater, TP, True),
        ('qlnv_tonghop_chitiet_tiepnhan_don_le', 'putsql-sql-statement', writer, TP + '_don_le', True),
        ('qlnv_tonghop_chitiet_tiepnhan_theo_chuoi', 'putsql-sql-statement', writer, TP + '_theo_chuoi', True),
        ('qlnv_tonghop_chitiet_nhom_tiepnhan', 'putsql-sql-statement', writer, 'qlnv_tonghop_chitiet_nhom_tiepnhan', True),
    ],
    'Giao NV': [
        ('qlnv_tonghop_chitiet_giaonv', 'putsql-sql-statement', writer, GV, False),
        ('Update NhomCauTrucNhiemVu Giao', 'putsql-sql-statement', updater, GV, False),
        ('Update DonViChuTri', 'putsql-sql-statement', updater, GV, True),
        ('qlnv_tonghop_chitiet_giaonv_theo_chuoi', 'SQL select query', writer, GV + '_theo_chuoi', True),
        ('qlnv_tonghop_chitiet_giaonv_don_le', 'SQL select query', writer, GV + '_don_le', True),
        ('qlnv_tonghop_chitiet_nhom_giaonv', 'SQL select query', writer, 'qlnv_tonghop_chitiet_nhom_giaonv', True),
    ],
    'Giao + Nhận NV': [
        ('qlnv_tonghop_chitiet', 'SQL select query', writer, 'qlnv_tonghop_chitiet', True),
        ('qlnv_tonghop_chitiet_nhom', 'SQL select query', writer, 'qlnv_tonghop_chitiet_nhom', True),
        ('qlnv_tonghop_chitiet_khoi', 'SQL select query', writer, 'qlnv_tonghop_chitiet_khoi', True),
        ('qlnv_tongquan', 'SQL select query', writer, 'qlnv_tongquan', True),
    ],
}
