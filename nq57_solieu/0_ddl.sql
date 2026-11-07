/* Chạy 1 lần (NiFi PutSQL, HN-Datamart-NEW). Đích của luồng "Chuyên đề lớn" (group 142f3c52-6ef6-1fc2-a385-be4d090930e0).
   Nguồn: PostgreSQL 10.120.33.33:15432 (dashboard_ro, chỉ đọc)
     - bao_cao.dashboard.so_lieu_nq57   -> nq57_solieu  (số liệu đã chấp nhận)
     - bieu_mau.dashboard.chi_tieu_nq57 -> nq57_chitieu (tên chỉ tiêu, phụ lục, phân tổ)
   Khóa chính đã kiểm tra trên nguồn (2026-11-04): duy nhất, không NULL. */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`nq57_solieu` (
    ma_bieu       VARCHAR(100)   NULL,
    ma_chi_tieu   VARCHAR(100)   NOT NULL,
    ma_phan_to    VARCHAR(100)   NOT NULL,
    loai_so       VARCHAR(10)    NOT NULL COMMENT 'ACTUAL | PLAN',
    ky            VARCHAR(10)    NOT NULL COMMENT 'vd 2026M10',
    ma_don_vi     VARCHAR(50)    NOT NULL,
    don_vi        VARCHAR(500)   NULL,
    gia_tri       DECIMAL(24,6)  NULL,
    cap_nhat_luc  DATETIME       NULL COMMENT 'giờ Việt Nam',
    sync_date     DATETIME       NOT NULL,
    PRIMARY KEY (ma_chi_tieu, ma_phan_to, loai_so, ky, ma_don_vi),
    KEY idx_sync_date (sync_date)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`nq57_chitieu` (
    ma_chi_tieu   VARCHAR(100)   NOT NULL,
    chi_tieu      VARCHAR(1000)  NULL,
    ma_phu_luc    VARCHAR(50)    NULL,
    phu_luc       VARCHAR(300)   NULL,
    don_vi_tinh   VARCHAR(100)   NULL,
    ma_phan_to    VARCHAR(100)   NOT NULL,
    phan_to       VARCHAR(500)   NULL,
    sync_date     DATETIME       NOT NULL,
    PRIMARY KEY (ma_chi_tieu, ma_phan_to),
    KEY idx_sync_date (sync_date)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* View cho Superset: số liệu + tên chỉ tiêu/phụ lục/phân tổ */
CREATE OR REPLACE VIEW `datamart_hanoi`.`v_nq57_solieu` AS
SELECT
    s.ma_bieu, c.ma_phu_luc, c.phu_luc,
    s.ma_chi_tieu, c.chi_tieu, c.don_vi_tinh,
    s.ma_phan_to, c.phan_to,
    s.loai_so, s.ky, s.ma_don_vi, s.don_vi,
    s.gia_tri, s.cap_nhat_luc, s.sync_date
FROM `datamart_hanoi`.`nq57_solieu` s
LEFT JOIN `datamart_hanoi`.`nq57_chitieu` c
       ON c.ma_chi_tieu = s.ma_chi_tieu
      AND c.ma_phan_to  = s.ma_phan_to;
