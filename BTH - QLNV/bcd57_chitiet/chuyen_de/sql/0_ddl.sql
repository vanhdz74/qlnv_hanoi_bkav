/* Bảng số liệu chuyên đề chi tiết NQ57 - nhập từ báo cáo tháng (tai_lieu/BC tháng 2-10).
   Dạng dọc: mỗi dòng = 1 chỉ số x 1 kỳ (x 1 phân tổ với dữ liệu phụ).
   nhom_du_lieu: CHI_SO (145 chỉ số x 11 kỳ, kỳ chưa có số -> gia_tri NULL, co_so_lieu = 0)
                 NGUON_GIAO | XA_QUAN_TAM | DIEM_NGHEN_XA | NOI_DUNG_XA | QUA_HAN (dữ liệu phụ cho dashboard)
   Đơn vị %: gia_tri lưu tỷ lệ 0..1. Chạy qua NiFi PutSQL (HN-Datamart-NEW). */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` (
    nhom_du_lieu    VARCHAR(30)    NOT NULL,
    ma_chi_so       VARCHAR(30)    NOT NULL,
    ky              VARCHAR(20)    NOT NULL COMMENT 'T2/2026..T10/2026, TB 20/10',
    phan_to         VARCHAR(255)   NOT NULL DEFAULT '' COMMENT 'nguồn giao / xã / nhóm, rỗng với CHI_SO',
    thu_tu_ky       INT            NULL,
    thu_tu_chi_so   INT            NULL,
    stt_chuyen_de   INT            NULL,
    chuyen_de       VARCHAR(255)   NULL,
    ten_chi_so      VARCHAR(500)   NULL,
    ten_ngan        VARCHAR(255)   NULL,
    don_vi_tinh     VARCHAR(50)    NULL,
    loai_chi_so     VARCHAR(30)    NULL COMMENT 'Đầu vào | Đầu ra | Kết quả',
    giam_la_tot     TINYINT        NOT NULL DEFAULT 0,
    nguong          DECIMAL(10,4)  NULL,
    ten_nguong      VARCHAR(100)   NULL,
    tu_so           DECIMAL(24,6)  NULL,
    mau_so          DECIMAL(24,6)  NULL,
    gia_tri         DECIMAL(24,6)  NULL,
    co_so_lieu      TINYINT        NOT NULL DEFAULT 0 COMMENT '0 = chưa có số -> dashboard hiện cảnh báo !',
    nguon_so_lieu   VARCHAR(255)   NULL,
    vi_tri          VARCHAR(500)   NULL,
    trich_dan       TEXT           NULL,
    dau_moi         VARCHAR(255)   NULL,
    luu_y           TEXT           NULL,
    ghi_chu         TEXT           NULL,
    thong_tin_them  TEXT           NULL COMMENT 'JSON, dùng cho QUA_HAN',
    sync_date       DATETIME       NOT NULL,
    PRIMARY KEY (nhom_du_lieu, ma_chi_so, ky, phan_to),
    KEY idx_ky (thu_tu_ky),
    KEY idx_chuyen_de (stt_chuyen_de)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
