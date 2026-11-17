/* Chạy 1 lần: khóa duy nhất id_cha để upsert; id BIGINT vì upsert tiêu tốn số tự tăng mỗi chu kỳ */
ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_pth_ubndtp`
    MODIFY id BIGINT NOT NULL AUTO_INCREMENT,
    ADD UNIQUE KEY uk_id_cha (id_cha);
