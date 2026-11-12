/* [RT 12/11] DDL cho upsert — chạy 1 lần SAU KHI đã dừng chuỗi cũ (INSERT cũ của nhom_* không có danh sách cột) */
SET SESSION lock_wait_timeout = 10;
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan ADD COLUMN syncdate DATETIME NULL, ADD UNIQUE KEY uk_rt_ma (Ma);
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv ADD COLUMN syncdate DATETIME NULL, ADD UNIQUE KEY uk_rt_ma (Ma);
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);
ALTER TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi ADD UNIQUE KEY uk_rt_ma_nhom (Ma, NhomGiaoNhan);
SET SESSION lock_wait_timeout = 31536000;