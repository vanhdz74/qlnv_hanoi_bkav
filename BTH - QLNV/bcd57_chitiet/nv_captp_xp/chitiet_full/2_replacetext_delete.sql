/* 13/11: bỏ UPDATE id_cha = MIN(task_id)+'_GR' (gom theo tên/đơn vị giao/văn bản giao).
   id_cha giờ = qlnv_task.AssignBatchId, ghi trực tiếp trong upsert. */
/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57_full` WHERE sync_date < '${sync_ts}';
