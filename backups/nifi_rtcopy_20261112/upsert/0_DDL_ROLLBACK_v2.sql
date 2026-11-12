/* [RT 12/11 v2] ROLLBACK DDL, idempotent. Chạy TRƯỚC KHI bật lại chuỗi cũ. nhom_* (cột syncdate) trước */
SET SESSION lock_wait_timeout = 10;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_tiepnhan' AND column_name='syncdate') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan DROP COLUMN syncdate, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_tiepnhan' AND index_name='uk_rt_ma') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan DROP KEY uk_rt_ma, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_giaonv' AND column_name='syncdate') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv DROP COLUMN syncdate, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom_giaonv' AND index_name='uk_rt_ma') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv DROP KEY uk_rt_ma, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet' AND index_name='uk_rt_ma_nhom') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet DROP KEY uk_rt_ma_nhom, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_nhom' AND index_name='uk_rt_ma_nhom') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom DROP KEY uk_rt_ma_nhom, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET @s = (SELECT IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_khoi' AND index_name='uk_rt_ma_nhom') > 0, 'ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi DROP KEY uk_rt_ma_nhom, ALGORITHM=INPLACE, LOCK=NONE', 'DO 0'));
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;
SET SESSION lock_wait_timeout = 31536000;