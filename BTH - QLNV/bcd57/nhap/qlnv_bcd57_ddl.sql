-- BCĐ 57 — DDL 2 bảng đích
-- Chỉ chạy SAU khi 2 câu SELECT đã cho số liệu đúng:
--   qlnv_bcd57_nhiemvu_select.sql  ·  qlnv_bcd57_dondoc_select.sql
-- Chạy MỘT LẦN bằng tay. Không dán vào NiFi.
-- Ghi chú: qlnv_bcd57_note.md


-- === bảng 1 · chi tiết nhiệm vụ =============================================

CREATE TABLE IF NOT EXISTS qlnv_bcd57_nhiemvu (
    ma_nhiem_vu        INT          NOT NULL,
    ma_hien_thi        VARCHAR(255) NULL,

    nhom_nhiem_vu      VARCHAR(255) NULL,
    stt_theo_doi       VARCHAR(255) NULL,
    van_ban_giao       VARCHAR(320) NULL,
    noi_dung           TEXT         NULL,
    don_vi_thuc_hien   VARCHAR(256) NULL,
    lanh_dao_dv_cv     VARCHAR(255) NULL,
    han_hoan_thanh     DATETIME     NULL,
    ten_trang_thai     VARCHAR(64)  NOT NULL,
    ket_qua_thuc_hien  TEXT         NULL,
    lanh_dao_ubnd      VARCHAR(500) NULL,
    lanh_dao_vp        VARCHAR(255) NULL,
    phong_chuyen_mon   VARCHAR(256) NULL,
    chuyen_vien_vp     VARCHAR(255) NULL,

    lanh_dao_chi_dao   VARCHAR(500) NOT NULL,
    trang_thai         VARCHAR(16)  NOT NULL,
    ma_don_vi          VARCHAR(64)  NOT NULL,
    so_van_ban         VARCHAR(255) NULL,
    ngay_van_ban       DATETIME     NULL,
    ngay_hoan_thanh    DATETIME     NULL,
    nam_han            SMALLINT     NULL,
    thang_han          TINYINT      NULL,
    monthkey           CHAR(6)      NULL,
    nhan_thang         VARCHAR(8)   NULL,
    ky_han             DATE         NULL,

    ten_ngan           VARCHAR(32)  NOT NULL,
    nhom_ht            VARCHAR(4)   NOT NULL,
    nhom_han           VARCHAR(12)  NOT NULL,
    mau_trang_thai     CHAR(7)      NOT NULL,
    thu_tu_trang_thai  TINYINT      NOT NULL,

    la_hoan_thanh      TINYINT(1)   NOT NULL DEFAULT 0,
    la_qua_han         TINYINT(1)   NOT NULL DEFAULT 0,
    khong_co_han       TINYINT(1)   NOT NULL DEFAULT 0,
    da_gia_han         TINYINT(1)   NOT NULL DEFAULT 0,
    la_dinh_ky         TINYINT(1)   NOT NULL DEFAULT 0,
    cap_nhiem_vu       INT          NULL,
    so_dv_phoi_hop     INT          NOT NULL DEFAULT 0,
    tien_do            INT          NULL,

    can_don_doc        TINYINT(1)   NOT NULL DEFAULT 0,
    muc_do_canh_bao    VARCHAR(16)  NULL,
    so_ngay            INT          NULL,
    nhan_canh_bao      VARCHAR(64)  NULL,
    han_hien_thi       VARCHAR(10)  NULL,

    syncdate           DATETIME     NULL,
    PRIMARY KEY (ma_nhiem_vu),
    KEY idx_tt  (trang_thai),
    KEY idx_dv  (ma_don_vi),
    KEY idx_ld  (lanh_dao_chi_dao),
    KEY idx_han (han_hoan_thanh),
    KEY idx_dd  (can_don_doc, so_ngay)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- === bảng 2 · cần đôn đốc ===================================================

CREATE TABLE IF NOT EXISTS qlnv_bcd57_dondoc (
    ma_nhiem_vu       INT          NOT NULL,
    noi_dung          TEXT         NULL,
    lanh_dao_chi_dao  VARCHAR(500) NOT NULL,
    don_vi_thuc_hien  VARCHAR(256) NULL,
    so_van_ban        VARCHAR(255) NULL,
    han_hoan_thanh    DATETIME     NULL,
    han_hien_thi      VARCHAR(10)  NULL,
    trang_thai        VARCHAR(16)  NOT NULL,
    ten_trang_thai    VARCHAR(64)  NOT NULL,
    muc_do_canh_bao   VARCHAR(16)  NOT NULL,
    so_ngay           INT          NOT NULL,
    nhan_canh_bao     VARCHAR(64)  NOT NULL,
    mau_vien          CHAR(7)      NOT NULL,
    mau_chu_nhan      CHAR(7)      NOT NULL,
    mau_nen_nhan      CHAR(7)      NOT NULL,
    la_qua_han        TINYINT(1)   NOT NULL,
    la_gan_han        TINYINT(1)   NOT NULL,
    syncdate          DATETIME     NULL,
    PRIMARY KEY (ma_nhiem_vu),
    KEY idx_sort (so_ngay),
    KEY idx_vb   (so_van_ban)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- === dòng truncate cho NiFi =================================================
-- Dán ĐỨNG TRƯỚC câu SELECT tương ứng trong ExecuteSQLRecord
-- (JDBC bật allowMultiQueries=true), không chạy ở đây.

-- truncate table qlnv_bcd57_nhiemvu;
-- truncate table qlnv_bcd57_dondoc;
