/* [RT 12/11] ROLLBACK DDL — chạy trước khi bật lại chuỗi cũ (INSERT cũ của nhom_* sẽ lỗi nếu còn cột syncdate) */
SET SESSION lock_wait_timeout = 10;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan DROP COLUMN syncdate, DROP KEY uk_rt_ma;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv DROP COLUMN syncdate, DROP KEY uk_rt_ma;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet DROP KEY uk_rt_ma_nhom;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom DROP KEY uk_rt_ma_nhom;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi DROP KEY uk_rt_ma_nhom;
SET SESSION lock_wait_timeout = 31536000;