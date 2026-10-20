/* Bảng đích cho qlnv_chitiet_bcd57_xaphuong.sql (chạy 1 lần, KHÔNG dán vào NiFi)
   task_id KHÔNG để PK: nhánh 2 (API) dùng row_id/CRC32, có thể đụng TaskId nhánh 1 */
CREATE TABLE IF NOT EXISTS `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong` (
    `task_id`                 BIGINT        NOT NULL,
    `status`                  INT           NULL,
    `id_truc_giao`            VARCHAR(100)  NULL,
    `truc_giao`               VARCHAR(500)  NULL,
    `nguon_giao`              VARCHAR(50)   NULL,
    `van_ban_giao`            VARCHAR(500)  NULL,
    `loai_van_ban`            VARCHAR(100)  NULL,
    `ma_nhiem_vu`             VARCHAR(255)  NULL,
    `ten_xa_phuong`           VARCHAR(255)  NULL,
    `ten_nhiem_vu`            TEXT          NULL,
    `chu_de`                  VARCHAR(500)  NULL,
    `nhom_nhiem_vu`           VARCHAR(500)  NULL,
    `id_don_vi_giao`          VARCHAR(100)  NULL,
    `don_vi_giao`             VARCHAR(500)  NULL,
    `id_nguoi_giao`           VARCHAR(100)  NULL,
    `nguoi_giao`              VARCHAR(255)  NULL,
    `id_don_vi_chu_tri`       VARCHAR(100)  NULL,
    `ten_don_vi_chu_tri`      VARCHAR(500)  NULL,
    `ten_don_vi_thuc_hien`    VARCHAR(500)  NULL,
    `id_nguoi_thuc_hien`      VARCHAR(100)  NULL,
    `nguoi_thuc_hien`         VARCHAR(255)  NULL,
    `lanh_dao_ban_phu_trach`  VARCHAR(500)  NULL,
    `ngay_giao`               VARCHAR(10)   NULL,
    `han_xu_ly`               VARCHAR(10)   NULL,
    `ngay_hoan_thanh`         VARCHAR(10)   NULL,
    `ngay_chap_nhan`          VARCHAR(10)   NULL,
    `ngay_xoa`                VARCHAR(10)   NULL,
    `tinh_trang`              VARCHAR(50)   NULL,
    `tien_do`                 INT           NULL,
    `ket_qua_thuc_hien`       LONGTEXT      NULL,
    `kho_khan_vuong_mac`      LONGTEXT      NULL,
    `de_xuat_kien_nghi`       LONGTEXT      NULL,
    `sync_date`               DATETIME      NULL,
    KEY `idx_task`       (`task_id`),
    KEY `idx_nguon_giao` (`nguon_giao`),
    KEY `idx_truc_giao`  (`id_truc_giao`),
    KEY `idx_tinh_trang` (`tinh_trang`),
    KEY `idx_xa`         (`ten_xa_phuong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* Bảng đã tạo từ trước -> chạy tay 1 lần để thêm cột:
   ALTER TABLE `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong`
       ADD COLUMN `ten_xa_phuong` VARCHAR(255) NULL AFTER `ma_nhiem_vu`,
       ADD KEY `idx_xa` (`ten_xa_phuong`);
*/
