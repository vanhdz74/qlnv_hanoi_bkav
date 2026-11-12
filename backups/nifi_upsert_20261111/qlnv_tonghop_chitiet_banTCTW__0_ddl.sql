ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitiet_banTCTW` ADD COLUMN `sync_date` DATETIME NULL;
ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitiet_banTCTW` ADD UNIQUE KEY `uk_upsert` (`task_id`);
