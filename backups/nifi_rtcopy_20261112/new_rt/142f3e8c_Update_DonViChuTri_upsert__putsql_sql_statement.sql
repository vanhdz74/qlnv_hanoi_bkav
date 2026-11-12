/* [RT 12/11 v3] tính lại toàn bộ, chỉ ghi dòng đổi giá trị; giữ syncdate */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_new_rt g
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_new_rt g_cha ON g.ma_nv_cha = g_cha.Ma
SET g.iddv_dvchutri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv, g.iddv) ELSE g.iddv END,
    g.DonViChuTri = CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi, g.donvi) ELSE g.donvi END,
    g.syncdate = g.syncdate
WHERE NOT (g.iddv_dvchutri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.iddv, g.iddv) ELSE g.iddv END) OR NOT (g.DonViChuTri <=> CASE WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' THEN COALESCE(g_cha.donvi, g.donvi) ELSE g.donvi END);