ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitietnv_banTCTW` ADD COLUMN `sync_date` DATETIME NULL;
ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitietnv_banTCTW` ADD COLUMN `roadmap_key` BIGINT AS (IFNULL(`roadmap_id`, 0)) STORED;
ALTER TABLE `datamart_hanoi`.`qlnv_tonghop_chitietnv_banTCTW` ADD UNIQUE KEY `uk_upsert` (`task_id`, `roadmap_key`);
