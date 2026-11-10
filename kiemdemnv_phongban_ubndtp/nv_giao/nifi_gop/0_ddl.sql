/* Bảng gom nhóm nhiệm vụ 'Giao' - Phòng ban thuộc UBND TP (tương tự qlnv_tonghop_gop_nvgiao_pth_ubndtp).
   Nguồn: qlnv_tonghop_chitiet_nvgiao_phongban_ubndtp (1 dòng/task).
   Khóa nhóm: (ten_nhiem_vu, van_ban_giao, id_truc_giao, id_phong_ban); id_cha = MIN(task_id) + '_GR'.
   PK id_cha để upsert (không tốn AUTO_INCREMENT mỗi chu kỳ).
   Chạy kèm đầu mỗi chu kỳ trong ReplaceText upsert (IF NOT EXISTS => vô hại). */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_phongban_ubndtp` (
    id_cha                         VARCHAR(50)  NOT NULL,
    id_truc_giao                   VARCHAR(255),
    truc_giao                      TEXT,
    nhom_van_ban                   TEXT,
    linh_vuc                       TEXT,
    chu_de                         TEXT,
    muc_do_uu_tien                 VARCHAR(255),
    nv_quantam                     TINYINT,
    ma_nhiem_vu                    MEDIUMTEXT,
    ten_nhiem_vu                   TEXT,
    van_ban_giao                   TEXT,
    hinh_thuc_giao                 VARCHAR(100),
    id_don_vi_chu_tri              MEDIUMTEXT,
    ten_don_vi_chu_tri             MEDIUMTEXT,
    lanh_dao_don_vi_va_chuyen_vien MEDIUMTEXT,
    ngay_giao                      MEDIUMTEXT,
    han_xu_ly                      MEDIUMTEXT,
    ngay_hoan_thanh                MEDIUMTEXT,
    ngay_xoa                       MEDIUMTEXT,
    tinh_trang                     VARCHAR(64),
    tinh_hinh_ket_qua              LONGTEXT,
    ld_ubnd                        TEXT,
    ld_van_phong                   TEXT,
    phong_chuyen_mon_theo_doi      TEXT,
    chuyen_vien_vp_theo_doi        TEXT,
    task_id                        MEDIUMTEXT,
    status                         MEDIUMTEXT,
    so_luong_task                  INT,
    id_phong_ban                   VARCHAR(255),
    sync_date                      DATETIME,
    PRIMARY KEY (id_cha),
    KEY idx_id_truc_giao (id_truc_giao),
    KEY idx_id_phong_ban (id_phong_ban),
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_sync_date (sync_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
