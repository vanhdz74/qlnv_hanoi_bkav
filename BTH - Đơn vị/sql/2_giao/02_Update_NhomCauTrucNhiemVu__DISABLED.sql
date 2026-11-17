-- NiFi processor: Update NhomCauTrucNhiemVu
-- id: 142f3ec1-6ef6-1fc2-ed59-4499c35f5dad  group: Giao NV (142f3eae-6ef6-1fc2-8831-69d392c2e111)
-- state: DISABLED  schedule: TIMER_DRIVEN 0 sec

-- ===== putsql-sql-statement =====
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv t

LEFT JOIN (
    -- Danh sách nhiệm vụ có con
    SELECT DISTINCT ma_nv_cha
    FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv
    WHERE ma_nv_cha IS NOT NULL
) c ON c.ma_nv_cha = t.Ma

LEFT JOIN (
    -- Đếm số bản ghi theo tennv_viettat
    SELECT tennv_viettat, COUNT(*) cnt
    FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv
    GROUP BY tennv_viettat
) g ON g.tennv_viettat = t.tennv_viettat

SET t.NhomCauTrucNhiemVu =
CASE
    WHEN t.ma_nv_cha IS NOT NULL 
         OR c.ma_nv_cha IS NOT NULL
        THEN 'Nhiệm vụ theo chuỗi'

    WHEN g.cnt = 1
        THEN 'Nhiệm vụ đơn lẻ'

    ELSE 'Chưa xác định'
END;
