/* [RT 12/11 v2] DDL upsert, idempotent. Chạy SAU KHI dừng chuỗi cũ. Bảng lớn trước, nhom_* sau cùng */
SET SESSION lock_wait_timeout = 10;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet' AND index_name='uk_rt_ma_nhom')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan), ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom' AND index_name='uk_rt_ma_nhom')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan), ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_khoi' AND index_name='uk_rt_ma_nhom')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan), ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_tiepnhan' AND index_name='uk_rt_ma')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan ADD UNIQUE KEY uk_rt_ma (Ma), ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_tiepnhan' AND column_name='syncdate')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan ADD COLUMN syncdate DATETIME NULL, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_giaonv' AND index_name='uk_rt_ma')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv ADD UNIQUE KEY uk_rt_ma (Ma), ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((1 - (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_giaonv' AND column_name='syncdate')) > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv ADD COLUMN syncdate DATETIME NULL, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET SESSION lock_wait_timeout = 31536000;