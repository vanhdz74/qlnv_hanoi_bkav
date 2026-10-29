/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM datamart_hanoi.qlnv_tonghop_tongquan_ubndtp WHERE sync_date < '${sync_ts}';
