/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__stg LIKE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le;
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__stg;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__stg
SELECT *
FROM qlnv_tonghop_chitiet_tiepnhan t
WHERE t.ma_nv_cha IS NULL
AND NOT EXISTS (
    SELECT 1
    FROM qlnv_tonghop_chitiet_tiepnhan c
    WHERE c.ma_nv_cha = t.Ma
);
/* Đổi chỗ nguyên tử; chờ khóa tối đa 10s để không chặn dashboard */
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__old, datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__stg TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le, datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__old TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le__stg;
SET SESSION lock_wait_timeout = 31536000;