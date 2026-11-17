/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM datamart_hanoi.qlnv_lichsutiendo_thongkenhanh_nv WHERE sync_date < '${sync_ts}' OR sync_date IS NULL;
