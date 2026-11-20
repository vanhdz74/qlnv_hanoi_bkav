/* [RT 19/11 cách B] DDL 1 lần, idempotent */
SET @c := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_donvi' AND index_name='uk_rt_donvi');
SET @s := IF(@c=0,'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_donvi ADD UNIQUE KEY uk_rt_donvi (NhomGiaoNhan, Ma), ALGORITHM=INPLACE, LOCK=NONE','SELECT 1');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;