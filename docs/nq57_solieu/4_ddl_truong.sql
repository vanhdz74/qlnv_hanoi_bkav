/* NQ57 bộ biểu mới (bốn tầng) – số liệu theo TRƯỜNG (từng ô của biểu). 16/11/2026
   Nguồn: bao_cao.dashboard.so_lieu_truong_nq57 + bieu_mau.dashboard.truong_nq57 (PG 10.120.33.33:15432)
   Đích : datamart_hanoi.nq57_solieu_truong, nq57_truong, view v_nq57_solieu_truong
   Luồng NiFi "Chuyên đề lớn" (142f3c52), chung GFF 30' với nq57_solieu. Upsert + DELETE sync_date < sync_ts.
   Mỗi câu chạy riêng (PutSQL không bật multi-statement). */

-- [1]
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`nq57_solieu_truong` (
    ma_bieu       VARCHAR(100)   NOT NULL,
    ma_phan       VARCHAR(100)   NOT NULL,
    ma_truong     VARCHAR(100)   NOT NULL,
    so_dong       INT            NOT NULL DEFAULT 0 COMMENT '0 = phần một dòng; 1,2.. = dòng của bảng nhiều dòng',
    ky            VARCHAR(20)    NOT NULL,
    ma_don_vi     VARCHAR(50)    NOT NULL DEFAULT '',
    don_vi        VARCHAR(500)   NULL,
    gia_tri_so    DECIMAL(24,6)  NULL,
    gia_tri_chu   TEXT           NULL,
    cap_nhat_luc  DATETIME       NULL COMMENT 'giờ Việt Nam',
    sync_date     DATETIME       NOT NULL,
    PRIMARY KEY (ma_bieu, ma_phan, ma_truong, so_dong, ky, ma_don_vi),
    KEY idx_sync_date (sync_date),
    KEY idx_ky (ky)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [2]
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`nq57_truong` (
    ma_bieu       VARCHAR(100)   NOT NULL,
    ten_bieu      VARCHAR(1000)  NULL,
    ma_phan       VARCHAR(100)   NOT NULL,
    ten_phan      VARCHAR(1000)  NULL,
    nhieu_dong    TINYINT        NULL,
    thu_tu        INT            NULL,
    ma_truong     VARCHAR(100)   NOT NULL,
    ten_truong    TEXT           NULL,
    stt_dong      VARCHAR(100)   NULL,
    dong          TEXT           NULL,
    cot           TEXT           NULL,
    kieu          VARCHAR(50)    NULL,
    don_vi_tinh   VARCHAR(100)   NULL,
    ma_chi_tieu   VARCHAR(100)   NULL,
    tu_tinh       TINYINT        NULL,
    sync_date     DATETIME       NOT NULL,
    PRIMARY KEY (ma_bieu, ma_phan, ma_truong),
    KEY idx_sync_date (sync_date),
    KEY idx_ma_chi_tieu (ma_chi_tieu)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [3]
CREATE OR REPLACE VIEW `datamart_hanoi`.`v_nq57_solieu_truong` AS
SELECT
    s.ma_bieu, t.ten_bieu, s.ma_phan, t.ten_phan, t.nhieu_dong, t.thu_tu,
    s.ma_truong, t.ten_truong, t.stt_dong, t.dong, t.cot, t.kieu, t.don_vi_tinh, t.ma_chi_tieu, t.tu_tinh,
    s.so_dong, s.ky, s.ma_don_vi, s.don_vi, s.gia_tri_so, s.gia_tri_chu, s.cap_nhat_luc, s.sync_date
FROM `datamart_hanoi`.`nq57_solieu_truong` s
LEFT JOIN `datamart_hanoi`.`nq57_truong` t
       ON t.ma_bieu = s.ma_bieu AND t.ma_phan = s.ma_phan AND t.ma_truong = s.ma_truong;
