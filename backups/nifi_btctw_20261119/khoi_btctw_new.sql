/* [RT 19/11 BTCTW] mỗi phút sau nhom; TRUNCATE+INSERT → staging + RENAME swap */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__stg LIKE datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw;
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__stg;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__stg
SELECT * 
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom t

WHERE t.don_vi_cap_01 = 'BAN TỔ CHỨC TRUNG ƯƠNG' 
;
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw TO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__old, datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__stg TO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw, datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__old TO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw__stg;
SET SESSION lock_wait_timeout = 31536000;