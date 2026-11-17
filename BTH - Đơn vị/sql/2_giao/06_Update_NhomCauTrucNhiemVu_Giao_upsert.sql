-- NiFi processor: Update NhomCauTrucNhiemVu Giao [upsert]
-- id: 142f3eba-6ef6-1fc2-2785-99c369802767  group: Giao NV (142f3eae-6ef6-1fc2-8831-69d392c2e111)
-- state: RUNNING  schedule: TIMER_DRIVEN 0 sec

-- ===== putsql-sql-statement =====
/* [RT 12/11 v3] tính lại toàn bộ, chỉ ghi dòng đổi giá trị; giữ syncdate */
DROP TEMPORARY TABLE IF EXISTS rt_cha, rt_ten;
CREATE TEMPORARY TABLE rt_cha (Ma INT NOT NULL PRIMARY KEY) ENGINE=InnoDB;
INSERT INTO rt_cha SELECT DISTINCT ma_nv_cha FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv WHERE ma_nv_cha IS NOT NULL;
CREATE TEMPORARY TABLE rt_ten (tennv_viettat VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL PRIMARY KEY, cnt INT NOT NULL) ENGINE=InnoDB;
INSERT INTO rt_ten SELECT tennv_viettat, COUNT(DISTINCT Ma) FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv WHERE tennv_viettat IS NOT NULL GROUP BY tennv_viettat;
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
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
