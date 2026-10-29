/* Chạy 1 lần (2026-10-27) cho bảng đã tạo trước đó: thêm level chức vụ, đổi quyen -> permission */
ALTER TABLE `datamart_hanoi`.`qlnv_phanquyen_user`
    ADD COLUMN chuc_vu_level INT NULL AFTER chuc_vu,
    CHANGE COLUMN quyen permission TEXT NULL;
