"""Sửa 'Update DonViChuTri [upsert]' nhánh Giao (142f3eae) về đúng logic cũ (dùng *_dvthuchien). Backup trước khi PUT."""
import json, time
from rtlib import *
T = 'datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt'
ID_ = "CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.iddv_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv_dvthuchien, g.iddv_dvthuchien) ELSE g.iddv END"
DV_ = "CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.donvi_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi_dvthuchien, g.donvi_dvthuchien) ELSE g.donvi END"
SQL = (f"/* [RT 12/11 v4] Giao: logic như luồng cũ (đơn lẻ/chuỗi lấy đơn vị thực hiện); chỉ ghi dòng đổi; giữ syncdate */\n"
       f"UPDATE {T} g\nLEFT JOIN {T} g_cha ON g.ma_nv_cha = g_cha.Ma\n"
       f"SET g.iddv_dvchutri = {ID_},\n    g.DonViChuTri = {DV_},\n    g.syncdate = g.syncdate\n"
       f"WHERE NOT (g.iddv_dvchutri <=> {ID_}) OR NOT (g.DonViChuTri <=> {DV_});")
open('new_rt/v4_142f3eae_Update_DonViChuTri.sql', 'w').write(SQL)

gid = [g['id'] for g in G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']['processGroups'] if g['id'].startswith('142f3eae')][0]
p = [p for p in procs(gid) if p['component']['name'] == 'Update DonViChuTri [upsert]'][0]
json.dump(p, open('new_rt/backup_giao_dvchutri_before_v4.json', 'w'), ensure_ascii=False, indent=1)
assert 'g_cha.iddv,' in p['component']['config']['properties']['putsql-sql-statement']
setstate(p, 'STOPPED')
while G(f"/processors/{p['id']}")['status']['aggregateSnapshot']['activeThreadCount']: time.sleep(1)
cur = G(f"/processors/{p['id']}")
P('PUT', f"/processors/{p['id']}", {'revision': cur['revision'], 'component': {'id': p['id'], 'config': {'properties': {'putsql-sql-statement': SQL}}}})
setstate(p, 'RUNNING')
print('đã sửa + chạy lại', time.strftime('%T'))
