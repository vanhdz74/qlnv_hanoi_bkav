/* Xóa người dùng không còn trong qlnv_user (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_phanquyen_user` WHERE sync_date < '${sync_ts}';
