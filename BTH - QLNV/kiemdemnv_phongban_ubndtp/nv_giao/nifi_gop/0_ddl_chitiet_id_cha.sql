/* Chạy 1 lần: cột id_cha cho bảng chi tiết phòng ban (khớp id_cha bảng gộp qlnv_tonghop_gop_nvgiao_phongban_ubndtp) */
ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_phongban_ubndtp`
    ADD COLUMN id_cha VARCHAR(50) NULL AFTER task_id,
    ADD KEY idx_id_cha (id_cha);
