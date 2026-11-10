DELETE FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_phongban_ubndtp`
WHERE sync_date < '${sync_ts}' OR sync_date IS NULL;