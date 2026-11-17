-- NiFi processor: Update DonViChuTri [upsert]
-- id: 142f3ebd-6ef6-1fc2-8845-213daa109af3  group: Giao NV (142f3eae-6ef6-1fc2-8831-69d392c2e111)
-- state: RUNNING  schedule: TIMER_DRIVEN 0 sec

-- ===== putsql-sql-statement =====
/* [RT 12/11 v4] Giao: logic như luồng cũ (đơn lẻ/chuỗi lấy đơn vị thực hiện); chỉ ghi dòng đổi; giữ syncdate */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv g
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_giaonv g_cha ON g.ma_nv_cha = g_cha.Ma
SET g.iddv_dvchutri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.iddv_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv_dvthuchien, g.iddv_dvthuchien) ELSE g.iddv END,
    g.DonViChuTri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.donvi_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi_dvthuchien, g.donvi_dvthuchien) ELSE g.donvi END,
    g.syncdate = g.syncdate
WHERE NOT (g.iddv_dvchutri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.iddv_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv_dvthuchien, g.iddv_dvthuchien) ELSE g.iddv END) OR NOT (g.DonViChuTri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.donvi_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi_dvthuchien, g.donvi_dvthuchien) ELSE g.donvi END);
