/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_lichsutiendo_captp_xp_bcd57` WHERE sync_date < '${sync_ts}';
