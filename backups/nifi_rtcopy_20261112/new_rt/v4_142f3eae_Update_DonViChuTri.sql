/* [RT 12/11 v4] Giao: logic như luồng cũ (đơn lẻ/chuỗi lấy đơn vị thực hiện); chỉ ghi dòng đổi; giữ syncdate */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt g
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt g_cha ON g.ma_nv_cha = g_cha.Ma
SET g.iddv_dvchutri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.iddv_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv_dvthuchien, g.iddv_dvthuchien) ELSE g.iddv END,
    g.DonViChuTri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.donvi_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi_dvthuchien, g.donvi_dvthuchien) ELSE g.donvi END,
    g.syncdate = g.syncdate
WHERE NOT (g.iddv_dvchutri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.iddv_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv_dvthuchien, g.iddv_dvthuchien) ELSE g.iddv END) OR NOT (g.DonViChuTri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' THEN g.donvi_dvthuchien WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi_dvthuchien, g.donvi_dvthuchien) ELSE g.donvi END);