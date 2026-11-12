/* [RT 12/11 v3] tính lại toàn bộ, chỉ ghi dòng đổi giá trị; giữ syncdate */
DROP TEMPORARY TABLE IF EXISTS rt_cha, rt_ten;
CREATE TEMPORARY TABLE rt_cha (Ma INT NOT NULL PRIMARY KEY) ENGINE=InnoDB;
INSERT INTO rt_cha SELECT DISTINCT ma_nv_cha FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt WHERE ma_nv_cha IS NOT NULL;
CREATE TEMPORARY TABLE rt_ten (tennv_viettat VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL PRIMARY KEY, cnt INT NOT NULL) ENGINE=InnoDB;
INSERT INTO rt_ten SELECT tennv_viettat, COUNT(DISTINCT Ma) FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt WHERE tennv_viettat IS NOT NULL GROUP BY tennv_viettat;
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt t
LEFT JOIN rt_cha c ON c.Ma = t.Ma
LEFT JOIN rt_ten g ON g.tennv_viettat = t.tennv_viettat
SET t.NhomCauTrucNhiemVu = CASE WHEN t.ma_nv_cha IS NOT NULL OR c.Ma IS NOT NULL THEN 'Nhiệm vụ theo chuỗi'
          WHEN g.tennv_viettat IS NULL OR g.cnt <= 1 THEN 'Nhiệm vụ đơn lẻ'
          ELSE 'Chưa xác định' END,
    t.syncdate = t.syncdate
WHERE NOT (t.NhomCauTrucNhiemVu <=> CASE WHEN t.ma_nv_cha IS NOT NULL OR c.Ma IS NOT NULL THEN 'Nhiệm vụ theo chuỗi'
          WHEN g.tennv_viettat IS NULL OR g.cnt <= 1 THEN 'Nhiệm vụ đơn lẻ'
          ELSE 'Chưa xác định' END);
DROP TEMPORARY TABLE IF EXISTS rt_cha, rt_ten;