"""Chỉ đọc: so bảng thật (luồng cũ) với *_new_rt. Mỗi bảng: số dòng, chỉ-cũ, chỉ-mới, lệch nội dung (CRC32 các cột trừ syncdate).
Join theo khóa, từng bảng một, không COUNT DISTINCT. python3 new_rt_compare.py [bảng ...]"""
import sys, time
from rtlib import *
DB = 'datamart_hanoi'
KEY = {t: ['Ma'] for t in TABLES}
for t in ['qlnv_tonghop_chitiet', 'qlnv_tonghop_chitiet_nhom', 'qlnv_tonghop_chitiet_khoi']:
    KEY[t] = ['Ma', 'NhomGiaoNhan']
SKIPCOL = {'syncdate', 'sync_date'}
only = sys.argv[1:] or TABLES
print(time.strftime('%T'), 'mốc luồng cũ:', Q(f"SELECT MAX(syncdate) m FROM {DB}.qlnv_tonghop_chitiet_tiepnhan")[0]['m'],
      '| mới:', Q(f"SELECT MAX(syncdate) m FROM {DB}.qlnv_tonghop_chitiet_tiepnhan_new_rt")[0]['m'])
for t in only:
    n = t + '_new_rt'
    c_old = Q(f"SELECT COUNT(*) n FROM {DB}.{t}")[0]['n']
    c_new = Q(f"SELECT COUNT(*) n FROM {DB}.{n}")[0]['n']
    if t == 'qlnv_tongquan':
        print(f"{t:45} cũ={c_old:7} mới={c_new:7}  (không khóa, chỉ đếm)"); continue
    cols = [r['c'] for r in Q(f"SELECT column_name c FROM information_schema.columns WHERE table_schema='{DB}' AND table_name='{t}' ORDER BY ordinal_position")]
    cols = [c for c in cols if c not in SKIPCOL]
    k = KEY[t]
    on = ' AND '.join(f"a.`{c}` = b.`{c}`" for c in k)
    crc = lambda x: "CRC32(CONCAT_WS('|'," + ','.join(f"IFNULL({x}.`{c}`,'∅')" for c in cols) + "))"
    r = Q(f"SELECT SUM(b.`{k[0]}` IS NULL) chi_cu, SUM(b.`{k[0]}` IS NOT NULL AND {crc('a')} <> {crc('b')}) lech "
          f"FROM {DB}.{t} a LEFT JOIN {DB}.{n} b ON {on}")[0]
    # KHÔNG join ngược vào bảng cũ: qlnv_tonghop_chitiet cũ không có index Ma → quét chéo (đã phải KILL 12/11).
    # Bảng mới có UNIQUE trên khóa → số dòng chỉ-mới = mới − số dòng cũ khớp được.
    r2 = {'chi_moi': c_new - (c_old - int(r['chi_cu'] or 0))}
    print(f"{t:45} cũ={c_old:7} mới={c_new:7} chỉ_cũ={r['chi_cu']} chỉ_mới={r2['chi_moi']} lệch_nội_dung={r['lech']}")
