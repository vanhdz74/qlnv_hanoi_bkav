/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
LEFT JOIN (SELECT DISTINCT ma_nv_cha FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv WHERE ma_nv_cha IS NOT NULL) c ON c.ma_nv_cha = t.Ma
LEFT JOIN (SELECT tennv_viettat, COUNT(DISTINCT Ma) cnt FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv WHERE tennv_viettat IS NOT NULL GROUP BY tennv_viettat) g
       ON g.tennv_viettat = t.tennv_viettat
SET t.NhomCauTrucNhiemVu = CASE
    WHEN t.ma_nv_cha IS NOT NULL OR c.ma_nv_cha IS NOT NULL THEN 'Nhiệm vụ theo chuỗi'
    WHEN g.tennv_viettat IS NULL OR g.cnt <= 1 THEN 'Nhiệm vụ đơn lẻ'   -- không có NV khác cùng tên viết tắt
    ELSE 'Chưa xác định'
END;