/* Xóa nhóm không còn tồn tại (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_chitiet_gop_bcd57_cap_tp` WHERE sync_date < '${sync_ts}';
