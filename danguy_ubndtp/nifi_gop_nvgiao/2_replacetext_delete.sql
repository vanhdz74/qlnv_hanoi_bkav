/* Xóa nhóm không còn tồn tại (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_ubndtp` WHERE sync_date < '${sync_ts}';
