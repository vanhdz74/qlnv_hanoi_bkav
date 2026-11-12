/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__stg LIKE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi;
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__stg;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__stg
SELECT *
FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
WHERE
    -- là nhiệm vụ con
    t.ma_nv_cha IS NOT NULL

    -- hoặc là nhiệm vụ cha
    OR EXISTS (
        SELECT 1
        FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv c
        WHERE c.ma_nv_cha = t.Ma
    );
/* Đổi chỗ nguyên tử; chờ khóa tối đa 10s để không chặn dashboard */
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi TO datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__old, datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__stg TO datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi, datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__old TO datamart_hanoi.qlnv_tonghop_chitiet_giaonv_theo_chuoi__stg;
SET SESSION lock_wait_timeout = 31536000;