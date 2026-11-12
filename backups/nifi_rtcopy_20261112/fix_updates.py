"""v3: 4 câu UPDATE tại chỗ (NhomCauTrucNhiemVu + DonViChuTri × tiepnhan/giaonv).
- Nhóm: bảng dẫn xuất không có index trong 5.7 → BNL 82k×41k. Thay bằng 2 bảng TEMPORARY có PK.
- Chỉ UPDATE dòng có giá trị đổi (NOT <=>), giữ syncdate = syncdate (cột TIMESTAMP ON UPDATE, giờ MySQL lệch).
Kết quả cột giữ nguyên như bản cũ. python3 fix_updates.py [deploy]"""
import sys, json
from rtlib import *
DB = 'datamart_hanoi'
H = '/* [RT 12/11 v3] tính lại toàn bộ, chỉ ghi dòng đổi giá trị; giữ syncdate */\n'

def nhom(t):
    T = f'{DB}.{t}'
    case = ("CASE WHEN t.ma_nv_cha IS NOT NULL OR c.Ma IS NOT NULL THEN 'Nhiệm vụ theo chuỗi'\n"
            "          WHEN g.tennv_viettat IS NULL OR g.cnt <= 1 THEN 'Nhiệm vụ đơn lẻ'\n"
            "          ELSE 'Chưa xác định' END")
    return (H +
        "DROP TEMPORARY TABLE IF EXISTS rt_cha, rt_ten;\n"
        "CREATE TEMPORARY TABLE rt_cha (Ma INT NOT NULL PRIMARY KEY) ENGINE=InnoDB;\n"
        f"INSERT INTO rt_cha SELECT DISTINCT ma_nv_cha FROM {T} WHERE ma_nv_cha IS NOT NULL;\n"
        "CREATE TEMPORARY TABLE rt_ten (tennv_viettat VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL PRIMARY KEY,"
        " cnt INT NOT NULL) ENGINE=InnoDB;\n"
        f"INSERT INTO rt_ten SELECT tennv_viettat, COUNT(DISTINCT Ma) FROM {T} WHERE tennv_viettat IS NOT NULL GROUP BY tennv_viettat;\n"
        f"UPDATE {T} t\n"
        "LEFT JOIN rt_cha c ON c.Ma = t.Ma\n"
        "LEFT JOIN rt_ten g ON g.tennv_viettat = t.tennv_viettat\n"
        f"SET t.NhomCauTrucNhiemVu = {case},\n    t.syncdate = t.syncdate\n"
        f"WHERE NOT (t.NhomCauTrucNhiemVu <=> {case});\n"
        "DROP TEMPORARY TABLE IF EXISTS rt_cha, rt_ten;")

def dvct(t):
    T = f'{DB}.{t}'
    iddv = ("CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv, g.iddv) ELSE g.iddv END")
    dv = ("CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi, g.donvi) ELSE g.donvi END")
    return (H +
        f"UPDATE {T} g\nLEFT JOIN {T} g_cha ON g.ma_nv_cha = g_cha.Ma\n"
        f"SET g.iddv_dvchutri = {iddv},\n    g.DonViChuTri = {dv},\n    g.syncdate = g.syncdate\n"
        f"WHERE NOT (g.iddv_dvchutri <=> {iddv}) OR NOT (g.DonViChuTri <=> {dv});")

TP, GV = 'qlnv_tonghop_chitiet_tiepnhan', 'qlnv_tonghop_chitiet_giaonv'
TARGET = {('142f3e8c', 'Update NhomCauTrucNhiemVu Nhan [upsert]'): nhom(TP),
          ('142f3e8c', 'Update DonViChuTri [upsert]'): dvct(TP),
          ('142f3eae', 'Update NhomCauTrucNhiemVu Giao [upsert]'): nhom(GV),
          ('142f3eae', 'Update DonViChuTri [upsert]'): dvct(GV)}
for (g, n), sql in TARGET.items():
    open(f'upsert/v3_{g}_{n.split(" [")[0].replace(" ", "_")}.sql', 'w').write(sql)
if 'deploy' not in sys.argv:
    print(nhom(TP)); print(dvct(TP)); sys.exit()

ids = json.load(open('rt_copy_ids.json'))['copies']
bk = {}
for (g, n), sql in TARGET.items():
    gid = [v for v in ids.values() if v.startswith(g)][0]
    p = [p for p in procs(gid) if p['component']['name'] == n]; assert len(p) == 1, n; p = p[0]
    bk[f'{g}|{n}'] = p
    was = p['component']['state']
    if was == 'RUNNING':
        setstate(p, 'STOPPED')
    import time
    while G(f'/flow/processors/{p["id"]}/status')['processorStatus']['aggregateSnapshot']['activeThreadCount']: time.sleep(2)
    q = G(f'/processors/{p["id"]}')
    P('PUT', f'/processors/{p["id"]}', {'revision': q['revision'], 'component': {
        'id': p['id'], 'config': {'properties': {'putsql-sql-statement': sql}}}})
    if was == 'RUNNING': setstate(p, 'RUNNING')
    print('PUT', g, n, was)
json.dump(bk, open('backup_updates_before_v3.json', 'w'), ensure_ascii=False, indent=1)
