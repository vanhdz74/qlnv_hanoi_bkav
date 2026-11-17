-- NiFi processor: Update DonViChuTri [upsert]
-- id: 142f3e91-6ef6-1fc2-ad40-a22f80b6989e  group: Tiếp nhận NV (142f3e8c-6ef6-1fc2-ede8-4c1172022351)
-- state: RUNNING  schedule: TIMER_DRIVEN 0 sec

-- ===== putsql-sql-statement =====
/* [RT 12/11 v3] tính lại toàn bộ, chỉ ghi dòng đổi giá trị; giữ syncdate */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan g
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan g_cha ON g.ma_nv_cha = g_cha.Ma
SET g.iddv_dvchutri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv, g.iddv) ELSE g.iddv END,
    g.DonViChuTri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi, g.donvi) ELSE g.donvi END,
    g.syncdate = g.syncdate
WHERE NOT (g.iddv_dvchutri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv, g.iddv) ELSE g.iddv END) OR NOT (g.DonViChuTri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi, g.donvi) ELSE g.donvi END);
