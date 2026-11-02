/* =====================================================================
   BCĐ 57 · Chỉ số theo 10 nhóm chuyên đề (cd01-cd10) · chạy 1 lần là tạo bảng + nạp đủ 1 kỳ
   - Bước 0: tạo bảng (IF NOT EXISTS)
   - Bước 1: TU_DONG  - đếm nhiệm vụ từ qlnv_chitiet_captp_xp_bcd57 theo nhan_chuyen_de
             (trạng thái chụp tại lúc chạy -> nên chạy đúng ngày chốt, sau luồng đồng bộ bảng chi tiết)
   - Bước 2: NHAP_TAY - số liệu chuyên môn từ báo cáo CQTT
   - Bước 3: điền gia_tri_ky_truoc còn trống từ kỳ trước
   - Kỳ mới: sửa @ky, @ngay_chot và số liệu ở Bước 2 rồi chạy lại cả file
   ===================================================================== */
SET @ky        = '2026-10';
SET @ngay_chot = '2026-10-14 17:00:00';
SET @ky_truoc  = DATE_FORMAT(STR_TO_DATE(CONCAT(@ky, '-01'), '%Y-%m-%d') - INTERVAL 1 MONTH, '%Y-%m');

/* ===== BƯỚC 0 · TẠO BẢNG ===== */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` (
  `ky_bao_cao` varchar(7) NOT NULL,              -- 'YYYY-MM'
  `ngay_chot` datetime DEFAULT NULL,             -- thời điểm chốt số liệu
  `ma_chuyen_de` varchar(10) NOT NULL,           -- cd01..cd10
  `ten_chuyen_de` varchar(255) DEFAULT NULL,
  `thu_tu_chuyen_de` int(11) DEFAULT NULL,
  `ten_chi_so` varchar(500) DEFAULT NULL,
  `thu_tu_chi_so` int(11) NOT NULL,
  `gia_tri` decimal(20,3) DEFAULT NULL,          -- tử số / giá trị chính
  `mau_so` decimal(20,3) DEFAULT NULL,           -- mẫu số nếu chỉ số dạng X/Y
  `ty_le` decimal(7,2) DEFAULT NULL,             -- %
  `chi_tieu` decimal(20,3) DEFAULT NULL,         -- mục tiêu (cùng đơn vị với ty_le nếu là %)
  `gia_tri_ky_truoc` decimal(20,3) DEFAULT NULL,
  `don_vi_tinh` varchar(50) DEFAULT NULL,
  `nguon` varchar(20) NOT NULL,                  -- TU_DONG | NHAP_TAY
  `don_vi_cung_cap` varchar(255) DEFAULT NULL,
  `ghi_chu` text,
  `sync_date` datetime DEFAULT NULL,
  PRIMARY KEY (`ky_bao_cao`, `ma_chuyen_de`, `thu_tu_chi_so`),
  KEY `idx_chuyen_de` (`ma_chuyen_de`),
  KEY `idx_nguon` (`nguon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* ===== BƯỚC 1 · CHỈ SỐ TỰ ĐỘNG (thu_tu_chi_so 1-5, 1 nhiệm vụ nhiều nhãn được đếm ở mỗi chuyên đề) ===== */
INSERT INTO `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` (
    `ky_bao_cao`, `ngay_chot`, `ma_chuyen_de`, `ten_chuyen_de`, `thu_tu_chuyen_de`,
    `ten_chi_so`, `thu_tu_chi_so`,
    `gia_tri`, `mau_so`, `ty_le`, `chi_tieu`, `gia_tri_ky_truoc`,
    `don_vi_tinh`, `nguon`, `don_vi_cung_cap`, `ghi_chu`, `sync_date`
)
SELECT u.* FROM (
    SELECT
        @ky                                                     AS ky_bao_cao,
        NOW()                                                   AS ngay_chot,
        a.ma_chuyen_de,
        a.ten_chuyen_de,
        a.thu_tu_chuyen_de,
        m.ten_chi_so,
        m.thu_tu_chi_so,
        CASE m.thu_tu_chi_so
            WHEN 1 THEN a.nv_tong
            WHEN 2 THEN a.nv_hoan_thanh
            WHEN 3 THEN a.nv_dang_thuc_hien
            WHEN 4 THEN a.nv_qua_han
            WHEN 5 THEN a.nv_den_han_trong_ky
        END                                                     AS gia_tri,
        IF(m.thu_tu_chi_so = 1, NULL, a.nv_tong)                AS mau_so,
        IF(m.thu_tu_chi_so = 1 OR a.nv_tong = 0, NULL,
           ROUND(100 * CASE m.thu_tu_chi_so
                           WHEN 2 THEN a.nv_hoan_thanh
                           WHEN 3 THEN a.nv_dang_thuc_hien
                           WHEN 4 THEN a.nv_qua_han
                           WHEN 5 THEN a.nv_den_han_trong_ky
                       END / a.nv_tong, 2))                     AS ty_le,
        NULL                                                    AS chi_tieu,
        p.gia_tri                                               AS gia_tri_ky_truoc,
        'nhiệm vụ'                                              AS don_vi_tinh,
        'TU_DONG'                                               AS nguon,
        NULL                                                    AS don_vi_cung_cap,
        NULL                                                    AS ghi_chu,
        NOW()                                                   AS sync_date
    FROM (
        /* Đếm nhiệm vụ theo từng chuyên đề */
        SELECT
            cd.ma_chuyen_de,
            cd.ten_chuyen_de,
            cd.thu_tu_chuyen_de,
            COUNT(nv.task_id)                                                    AS nv_tong,
            COALESCE(SUM(nv.tinh_trang = 'Đã hoàn thành'), 0)                    AS nv_hoan_thanh,
            COALESCE(SUM(nv.tinh_trang IN ('Chưa hoàn thành trong hạn',
                                           'Chưa hoàn thành quá hạn',
                                           'Thường xuyên')), 0)                  AS nv_dang_thuc_hien,
            COALESCE(SUM(nv.tinh_trang = 'Chưa hoàn thành quá hạn'), 0)          AS nv_qua_han,
            COALESCE(SUM(DATE_FORMAT(nv.han_xu_ly, '%Y-%m')
                         = @ky), 0)                                              AS nv_den_han_trong_ky
        FROM (
                      SELECT 'cd01' AS ma_chuyen_de, 'Nhóm thể chế, chỉ đạo' AS ten_chuyen_de, 1 AS thu_tu_chuyen_de
            UNION ALL SELECT 'cd02', 'Nhóm hạ tầng',      2
            UNION ALL SELECT 'cd03', 'Nhóm dữ liệu',      3
            UNION ALL SELECT 'cd04', 'Nhóm nền tảng',     4
            UNION ALL SELECT 'cd05', 'Dịch vụ công',      5
            UNION ALL SELECT 'cd06', 'Giải ngân',         6
            UNION ALL SELECT 'cd07', 'An ninh an toàn',   7
            UNION ALL SELECT 'cd08', 'ĐTTM',              8
            UNION ALL SELECT 'cd09', 'Chỉ đạo nóng',      9
            UNION ALL SELECT 'cd10', 'Sản phẩm',          10
        ) cd
        LEFT JOIN `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57` nv
               ON FIND_IN_SET(cd.ma_chuyen_de, nv.nhan_chuyen_de) > 0
              AND nv.ngay_xoa IS NULL
        GROUP BY cd.ma_chuyen_de, cd.ten_chuyen_de, cd.thu_tu_chuyen_de
    ) a
    CROSS JOIN (
                  SELECT 1 AS thu_tu_chi_so, 'Tổng số nhiệm vụ' AS ten_chi_so
        UNION ALL SELECT 2, 'Nhiệm vụ đã hoàn thành'
        UNION ALL SELECT 3, 'Nhiệm vụ đang thực hiện'
        UNION ALL SELECT 4, 'Nhiệm vụ quá hạn'
        UNION ALL SELECT 5, 'Nhiệm vụ có hạn trong kỳ'
    ) m
    /* Giá trị kỳ trước cùng chuyên đề, cùng chỉ số */
    LEFT JOIN `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` p
           ON p.ky_bao_cao   = @ky_truoc
          AND p.ma_chuyen_de = a.ma_chuyen_de
          AND p.thu_tu_chi_so = m.thu_tu_chi_so
) u
ON DUPLICATE KEY UPDATE
    ngay_chot        = VALUES(ngay_chot),
    ten_chuyen_de    = VALUES(ten_chuyen_de),
    thu_tu_chuyen_de = VALUES(thu_tu_chuyen_de),
    ten_chi_so       = VALUES(ten_chi_so),
    gia_tri          = VALUES(gia_tri),
    mau_so           = VALUES(mau_so),
    ty_le            = VALUES(ty_le),
    gia_tri_ky_truoc = VALUES(gia_tri_ky_truoc),
    don_vi_tinh      = VALUES(don_vi_tinh),
    nguon            = VALUES(nguon),
    sync_date        = VALUES(sync_date);

/* ===== BƯỚC 2 · CHỈ SỐ NHẬP TAY từ báo cáo (thu_tu_chi_so từ 11; cd01, cd08 kỳ này chưa có số liệu) ===== */
INSERT INTO `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` (
    `ky_bao_cao`, `ngay_chot`, `ma_chuyen_de`, `ten_chuyen_de`, `thu_tu_chuyen_de`,
    `ten_chi_so`, `thu_tu_chi_so`,
    `gia_tri`, `mau_so`, `ty_le`, `chi_tieu`, `gia_tri_ky_truoc`,
    `don_vi_tinh`, `nguon`, `don_vi_cung_cap`, `ghi_chu`, `sync_date`
) VALUES
/* cd02 · Hạ tầng */
(@ky, @ngay_chot, 'cd02', 'Nhóm hạ tầng', 2, 'Máy tính được cài đặt giám sát',  11, 19505, NULL, NULL, NULL, NULL, 'máy',      'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),
(@ky, @ngay_chot, 'cd02', 'Nhóm hạ tầng', 2, 'Máy chủ Internet được giám sát',  12, 182,   NULL, NULL, NULL, NULL, 'máy',      'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),

/* cd03 · Dữ liệu */
(@ky, @ngay_chot, 'cd03', 'Nhóm dữ liệu', 3, 'Nguồn dữ liệu ưu tiên đã kết nối, thu thập', 11, 13,      13,      100.00, NULL, NULL,    'nguồn', 'NHAP_TAY', 'Sở Khoa học và Công nghệ', 'Kế hoạch 220/KH-UBND, Kho dữ liệu dùng chung', NOW()),
(@ky, @ngay_chot, 'cd03', 'Nhóm dữ liệu', 3, 'CSDL đã kết nối đang khai thác trực tiếp',   12, 3,       13,      23.08,  NULL, NULL,    'CSDL',  'NHAP_TAY', 'Sở Khoa học và Công nghệ', '13/13 CSDL kết nối kỹ thuật, mới khai thác trực tiếp 03', NOW()),
(@ky, @ngay_chot, 'cd03', 'Nhóm dữ liệu', 3, 'Thửa đất đã xây dựng CSDL',                  13, 4781746, 4827135, 99.06,  NULL, 3771021, 'thửa',  'NHAP_TAY', 'Sở Nông nghiệp và Môi trường', 'Báo cáo ghi 99,1%; tăng 1.010.725 thửa so với tháng 9', NOW()),
(@ky, @ngay_chot, 'cd03', 'Nhóm dữ liệu', 3, 'Thửa đất đạt tiêu chí Đúng - Đủ - Sạch - Sống', 14, 2782633, 4827135, 57.65, NULL, 2553383, 'thửa',  'NHAP_TAY', 'Sở Nông nghiệp và Môi trường', 'Tăng 229.250 thửa so với tháng 9', NOW()),

/* cd04 · Nền tảng */
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Chỉ số đã cấu hình trên IOC Thành ủy', 11, 84,      NULL, NULL, NULL, NULL, 'chỉ số',    'NHAP_TAY', 'Văn phòng Thành ủy', NULL, NOW()),
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Tài khoản IOC Thành ủy',               12, 28000,   NULL, NULL, NULL, NULL, 'tài khoản', 'NHAP_TAY', 'Văn phòng Thành ủy', 'Khoảng 28.000 tài khoản tại 134 cơ quan, đơn vị', NOW()),
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Không gian làm việc số HanoiWork',     13, 183,     NULL, NULL, NULL, NULL, 'không gian','NHAP_TAY', 'Sở Khoa học và Công nghệ', NULL, NOW()),
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Tài khoản HanoiWork',                  14, 85500,   NULL, NULL, NULL, NULL, 'tài khoản', 'NHAP_TAY', 'Sở Khoa học và Công nghệ', 'Khoảng 85.500 tài khoản', NOW()),
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Tài khoản định danh iHanoi',           15, 6200000, NULL, NULL, NULL, NULL, 'tài khoản', 'NHAP_TAY', 'Sở Khoa học và Công nghệ', 'Trên 6,2 triệu tài khoản', NOW()),
(@ky, @ngay_chot, 'cd04', 'Nhóm nền tảng', 4, 'Trường học có dữ liệu trên HanoiCheck',16, 2960,    NULL, NULL, NULL, NULL, 'trường',    'NHAP_TAY', 'Sở Giáo dục và Đào tạo', 'Hơn 2,37 triệu học sinh, 401 nhà cung cấp', NOW()),

/* cd05 · Dịch vụ công */
(@ky, @ngay_chot, 'cd05', 'Dịch vụ công', 5, 'TTHC đã phê duyệt phương án tái cấu trúc', 11, 1557,    1721,    90.47, 95,   NULL, 'thủ tục',  'NHAP_TAY', 'Văn phòng UBND Thành phố', 'Mục tiêu tối thiểu 95% trước 31/12/2026', NOW()),
(@ky, @ngay_chot, 'cd05', 'Dịch vụ công', 5, 'Chi phí tuân thủ tiết kiệm/năm (25 TTHC trọng điểm)', 12, 1731.48, NULL, 72.40, NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Văn phòng UBND Thành phố', 'ty_le = mức cắt giảm bình quân', NOW()),
(@ky, @ngay_chot, 'cd05', 'Dịch vụ công', 5, 'Học sinh có học bạ số ký số đầy đủ',       13, 1659846, 1775604, 93.48, 80,   NULL, 'học sinh', 'NHAP_TAY', 'Sở Giáo dục và Đào tạo', 'Chỉ tiêu Trung ương giao 80%; số liệu chốt 08/9/2026', NOW()),

/* cd06 · Giải ngân */
(@ky, @ngay_chot, 'cd06', 'Giải ngân', 6, 'Kinh phí bố trí năm 2026 cho KHCN, ĐMST, CĐS', 11, 9090.399, NULL,     NULL,  NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Sở Tài chính', NULL, NOW()),
(@ky, @ngay_chot, 'cd06', 'Giải ngân', 6, 'Kinh phí đã phân bổ',                          12, 8881.969, 9090.399, 97.71, NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Sở Tài chính', NULL, NOW()),
(@ky, @ngay_chot, 'cd06', 'Giải ngân', 6, 'Giải ngân chi thường xuyên khối cơ quan Thành phố', 13, 937.467, 4147.157, 22.61, NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Sở Tài chính', 'Điểm nghẽn: mua sắm, lựa chọn nhà thầu, nghiệm thu, thanh toán', NOW()),
(@ky, @ngay_chot, 'cd06', 'Giải ngân', 6, 'Giải ngân chi thường xuyên khối xã, phường',     14, 200.553,  333.565,  60.12, NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Sở Tài chính', NULL, NOW()),
(@ky, @ngay_chot, 'cd06', 'Giải ngân', 6, 'Giải ngân chi đầu tư',                         15, 3078.641, 5452.042, 56.47, NULL, NULL, 'tỷ đồng', 'NHAP_TAY', 'Sở Tài chính', NULL, NOW()),

/* cd07 · An ninh an toàn */
(@ky, @ngay_chot, 'cd07', 'An ninh an toàn', 7, 'Hệ thống thông tin đã phê duyệt cấp độ', 11, 263, NULL, NULL, NULL, NULL, 'hệ thống', 'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),
(@ky, @ngay_chot, 'cd07', 'An ninh an toàn', 7, 'Hồ sơ cấp độ phê duyệt mới trong kỳ',    12, 18,  NULL, NULL, NULL, NULL, 'hồ sơ',    'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),
(@ky, @ngay_chot, 'cd07', 'An ninh an toàn', 7, 'Hồ sơ cấp độ đang thẩm định',         13, 4,   NULL, NULL, NULL, NULL, 'hồ sơ',    'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),
(@ky, @ngay_chot, 'cd07', 'An ninh an toàn', 7, 'Cảnh báo nguy cơ mất an ninh mạng',      14, 423, NULL, NULL, NULL, NULL, 'cảnh báo', 'NHAP_TAY', 'Công an Thành phố', NULL, NOW()),

/* cd09 · Chỉ đạo nóng */
(@ky, @ngay_chot, 'cd09', 'Chỉ đạo nóng', 9, 'Nhiệm vụ Kế hoạch cao điểm 100 ngày đã hoàn thành', 11, 6, 7,  85.71, NULL, NULL, 'nhiệm vụ', 'NHAP_TAY', 'Công an Thành phố', 'QĐ 88/QĐ-BCĐCP; Hà Nội chủ trì 07 nhiệm vụ', NOW()),
(@ky, @ngay_chot, 'cd09', 'Chỉ đạo nóng', 9, 'Nhiệm vụ trọng tâm, cấp bách đã hoàn thành',        12, 3, 9,  33.33, NULL, NULL, 'nhiệm vụ', 'NHAP_TAY', 'Công an Thành phố', 'Phụ lục 01, nguồn giao số 6', NOW()),
(@ky, @ngay_chot, 'cd09', 'Chỉ đạo nóng', 9, 'Nhiệm vụ quá hạn cần tiếp tục xử lý',               13, 9, 10, NULL,  NULL, 14,   'nhiệm vụ', 'NHAP_TAY', 'Công an Thành phố', '10 quá hạn, 01 chờ Sổ tay hướng dẫn của BCĐ Trung ương; giảm 05 so với tháng 9', NOW()),

/* cd10 · Sản phẩm */
(@ky, @ngay_chot, 'cd10', 'Sản phẩm', 10, 'Nhiệm vụ đến hạn trong kỳ đã hoàn thành sản phẩm', 11, 2, 3, 66.67, NULL, NULL, 'nhiệm vụ', 'NHAP_TAY', 'Công an Thành phố', '01 nhiệm vụ chuyển hạn đến 31/12/2026', NOW())
ON DUPLICATE KEY UPDATE
    ngay_chot        = VALUES(ngay_chot),
    ten_chuyen_de    = VALUES(ten_chuyen_de),
    thu_tu_chuyen_de = VALUES(thu_tu_chuyen_de),
    ten_chi_so       = VALUES(ten_chi_so),
    gia_tri          = VALUES(gia_tri),
    mau_so           = VALUES(mau_so),
    ty_le            = VALUES(ty_le),
    chi_tieu         = VALUES(chi_tieu),
    gia_tri_ky_truoc = VALUES(gia_tri_ky_truoc),
    don_vi_tinh      = VALUES(don_vi_tinh),
    nguon            = VALUES(nguon),
    don_vi_cung_cap  = VALUES(don_vi_cung_cap),
    ghi_chu          = VALUES(ghi_chu),
    sync_date        = VALUES(sync_date);

/* ===== BƯỚC 3 · Điền gia_tri_ky_truoc còn trống từ kỳ trước (nếu kỳ trước đã nhập) */
UPDATE `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` c
JOIN `datamart_hanoi`.`qlnv_chiso_chuyende_bcd57` p
  ON p.ky_bao_cao   = @ky_truoc
 AND p.ma_chuyen_de = c.ma_chuyen_de
 AND p.thu_tu_chi_so = c.thu_tu_chi_so
SET c.gia_tri_ky_truoc = p.gia_tri
WHERE c.ky_bao_cao = @ky
  AND c.nguon = 'NHAP_TAY'
  AND c.gia_tri_ky_truoc IS NULL;
