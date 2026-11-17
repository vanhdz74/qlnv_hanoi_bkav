-- [1]
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`nq57_chi_so_anh_xa` (
    ma_chi_so          VARCHAR(30)    NOT NULL,
    thu_tu_chi_so      INT            NULL,
    stt_chuyen_de      INT            NULL,
    chuyen_de          VARCHAR(255)   NULL,
    ten_chi_so         VARCHAR(500)   NULL,
    ten_ngan           VARCHAR(255)   NULL,
    don_vi_tinh        VARCHAR(50)    NULL,
    loai_chi_so        VARCHAR(30)    NULL,
    giam_la_tot        TINYINT        NOT NULL DEFAULT 0,
    nguong             DECIMAL(10,4)  NULL,
    ten_nguong         VARCHAR(100)   NULL,
    dau_moi            VARCHAR(255)   NULL,
    luu_y              TEXT           NULL,
    cach_tinh          VARCHAR(20)    NOT NULL DEFAULT 'KHONG_CO' COMMENT 'TONG | KHONG_CO',
    tu_ma              VARCHAR(1000)  NULL COMMENT 'mã trường/chỉ tiêu NQ57, phân cách bằng dấu phẩy; -MA = trừ',
    mau_ma             VARCHAR(1000)  NULL,
    mau_hang_so        DECIMAL(24,6)  NULL COMMENT 'mẫu cố định, vd 126 xã',
    he_so              DECIMAL(12,6)  NOT NULL DEFAULT 1,
    can_ty_le          TINYINT        NOT NULL DEFAULT 0 COMMENT '1 = thiếu mẫu thì gia_tri NULL',
    chi_khi_mau_duong  TINYINT        NOT NULL DEFAULT 0 COMMENT '1 = mẫu <= 0 thì bỏ cả tử',
    mo_ta_nguon        VARCHAR(500)   NULL,
    ghi_chu            TEXT           NULL,
    cap_nhat           DATETIME       NULL,
    PRIMARY KEY (ma_chi_so)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [2]
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` LIKE `datamart_hanoi`.`chuyen_de_chi_tiet_nq57`;
