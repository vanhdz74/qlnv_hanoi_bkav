/* ===========================================================================
   DDL — qlnv_chitiet_nvnhan_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).

   Ghi chú task_id:
   - Nhánh 1: GROUP BY t.TaskId (chống nhân dòng do LEFT JOIN qlnv_user & department).
   - Nhánh 2: JOIN MAX(khóa sắp xếp) theo row_id -> giữ dòng ngày giao mới nhất.
   - task_id nhánh 2 (row_id/CRC32) có thể đụng TaskId nhánh 1 -> để KEY, KHÔNG để PRIMARY KEY.
   - task_id BIGINT vì CRC32 tối đa 4294967295.
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chitiet_nvnhan_pth_vpthanhuy` (
    task_id                  BIGINT        NOT NULL,   -- BIGINT vì nhánh 2 dùng CRC32 (tối đa 4294967295)
    status                   TINYINT       NULL,

    id_truc_giao             VARCHAR(255)  NULL,      -- task.AssignDepartment / user.DepartmentPath
    truc_giao                VARCHAR(500)  NULL,
    van_ban_giao             VARCHAR(255)  NULL,      -- task.DocCode / resolution.DocCode

    ma_nhiem_vu              VARCHAR(255)  NULL,      -- task.Code
    ten_nhiem_vu             TEXT          NULL,      -- task.Title varchar(6000)
    chu_de                   VARCHAR(255)  NULL,      -- task.NameGroup

    id_don_vi_chu_tri        VARCHAR(50)   NULL,      -- mã Part, KHÔNG phải số
    ten_don_vi_chu_tri       VARCHAR(500)  NULL,
    ten_don_vi_thuc_hien     VARCHAR(500)  NULL,

    id_nguoi_thuc_hien       INT           NULL,      -- eGovUserId
    nguoi_thuc_hien          VARCHAR(255)  NULL,
    lanh_dao_ban_phu_trach   VARCHAR(500)  NULL,

    ngay_giao                VARCHAR(10)   NULL,      -- dd/mm/yyyy (DATE_FORMAT)
    han_xu_ly                VARCHAR(10)   NULL,      -- dd/mm/yyyy
    ngay_hoan_thanh          VARCHAR(10)   NULL,      -- dd/mm/yyyy
    ngay_chap_nhan           VARCHAR(10)   NULL,      -- dd/mm/yyyy
    ngay_xoa                 VARCHAR(10)   NULL,      -- dd/mm/yyyy

    tinh_trang               VARCHAR(32)   NULL,
    ket_qua_thuc_hien        LONGTEXT      NULL,      -- task.Content / report.Content
    kho_khan_vuong_mac       TEXT          NULL,      -- report.Difficulty
    de_xuat_kien_nghi        TEXT          NULL,      -- report.Suggestion

    sync_date                DATETIME      NULL,
    KEY idx_task       (task_id),                       -- ⚠ KHÔNG phải PK: xem ghi chú đầu file
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_chitiet_nvnhan_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_chitiet_nvnhan_pth_vpthanhuy` (
    `task_id`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `van_ban_giao`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `chu_de`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `ten_don_vi_thuc_hien`,
    `id_nguoi_thuc_hien`,
    `nguoi_thuc_hien`,
    `lanh_dao_ban_phu_trach`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_chap_nhan`,
    `ngay_xoa`,
    `tinh_trang`,
    `ket_qua_thuc_hien`,
    `kho_khan_vuong_mac`,
    `de_xuat_kien_nghi`,
    `sync_date`
)



/* =======================================================================
   NHÁNH 1: NHIỆM VỤ NHẬN TỪ HỆ THỐNG QLNV (qlnv_task)
   ======================================================================= */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    CAST(t.TaskId AS SIGNED)                                AS task_id,
    CAST(t.Status AS SIGNED)                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    MAX(d_assign_cap2.name)                                 AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(NULLIF(t.NameGroup, ''))     AS chu_de,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    COALESCE(
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS ten_don_vi_chu_tri,
    
    COALESCE(
        MAX(d_donvi.name),
        /* FALLBACK: task này không xác định được đơn vị thực hiện
           -> lấy đơn vị thực hiện từ nhiệm vụ GẦN NHẤT khác của cùng TargetUser */
        (
            SELECT COALESCE(
                       d_fb.name
                   )
            FROM `db_theodoinv_hn`.`qlnv_task` t_fb
            LEFT JOIN `db_theodoinv_hn`.`department` d_fb
                   ON d_fb.id = CAST(
                        SUBSTRING_INDEX(t_fb.TargetDepartment, '.', -1) AS UNSIGNED
                      )
                  AND d_fb.IsDelete = 0
            WHERE t.TargetUser > 0                    /* chặn TargetUser = 0 (hệ thống) */
              AND t_fb.TargetUser = t.TargetUser
              AND t_fb.TaskId <> t.TaskId
              AND t_fb.DeletedDate IS NULL
              AND COALESCE(
                      d_fb.name,
                      NULLIF(t_fb.ResponsibleUnit, ''),
                      NULLIF(t_fb.TargetOrganization, '')
                  ) IS NOT NULL
            ORDER BY t_fb.CreatedDate DESC, t_fb.TaskId DESC
            LIMIT 1
        )
    )                                                       AS ten_don_vi_thuc_hien,

    CAST(t.TargetUser AS SIGNED)                            AS id_nguoi_thuc_hien,
    MAX(u_target.eGovUserFullname)                          AS nguoi_thuc_hien,

    /* Lãnh đạo ban phụ trách */
    CONCAT_WS(' · ',
        COALESCE(MAX(u_target.eGovUserPositionName), NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 5. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%d/%m/%Y')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                  AS ngay_xoa,

    /* 6. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
    CASE
        /* 1. Đã hoàn thành (đúng hạn hoặc quá hạn) */
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'

        /* 2. Thường xuyên (nhiệm vụ không có hạn) */
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        /* 3. Chưa hoàn thành trong hạn */
        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        /* 4. Chưa hoàn thành quá hạn */
        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND DATE(t.ExpireDate) < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Lấy bản ghi mới nhất) */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        t.Content,
        '—'
    )                                                       AS ket_qua_thuc_hien,

    COALESCE(
        (
            SELECT NULLIF(rp.Difficulty, '') 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        '—'
    )                                                       AS kho_khan_vuong_mac,

    COALESCE(
        (
            SELECT NULLIF(rp.Suggestion, '') 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        '—'
    )                                                       AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) 
            AS UNSIGNED
          ) AND d_assign_cap2.IsDelete = 0

/* JOIN DANH MỤC PHÒNG BAN ĐƠN VỊ NHẬN */
LEFT JOIN `db_theodoinv_hn`.`department` d_cap
       ON d_cap.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) 
            AS UNSIGNED
          ) AND d_cap.IsDelete = 0

LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(t.TargetDepartment, '.', -1) 
            AS UNSIGNED
          ) AND d_donvi.IsDelete = 0

/* JOIN USER NHẬN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    
    /* LOẠI BỎ CÁC TASK CHƯA XÁC ĐỊNH TÌNH TRẠNG */
    AND (
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )

    /* LỌC THEO DẢI ĐƠN VỊ NHẬN 490.695 (VĂN PHÒNG THÀNH ỦY) */
    AND t.TargetDepartment LIKE '490.695%'

    /* LOẠI TRỪ 2 TRỤC GIAO KHÔNG TÍNH LÀ GIAO QUA: 490.1775 VÀ 490.698 */
    AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.1775%'
    AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

/* Gom 1 dòng / 1 TaskId: chống nhân dòng do LEFT JOIN qlnv_user & department */
GROUP BY t.TaskId

UNION ALL

/* -----------------------------------------------------------------------
   NHÁNH 2: BẢNG datamart_hanoi.api_theodoinq_danh_sach_nhiem_vu_chi_tiet
   ----------------------------------------------------------------------- */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    CAST(
        COALESCE(
            NULLIF(nq.row_id, ''), 
            NULLIF(nq.source_row_id, ''),
            CRC32(CONCAT(COALESCE(nq.ma_nhiem_vu, ''), COALESCE(nq.ten_nhiem_vu, '')))
        ) AS SIGNED
    )                                                       AS task_id,
    CAST(NULL AS SIGNED)                                    AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    NULL                                                    AS id_truc_giao,
    'Trung ương'           AS truc_giao,
    nq.van_ban_giao_nhiem_vu                                AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    nq.ma_nhiem_vu                                          AS ma_nhiem_vu,
    nq.ten_nhiem_vu                                         AS ten_nhiem_vu,
    'Chưa phân loại'                                        AS chu_de,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
    NULL                                                    AS id_don_vi_chu_tri,
    nq.don_vi_chu_tri                                       AS ten_don_vi_chu_tri,
    nq.don_vi_chu_tri                                       AS ten_don_vi_thuc_hien,

    CAST(NULL AS SIGNED)                                    AS id_nguoi_thuc_hien,
    NULL                                                    AS nguoi_thuc_hien,
    NULL                                                    AS lanh_dao_ban_phu_trach,

    /* 5. CÁC MỐC THỜI GIAN: PHÂN LOẠI RÕ TỪNG DẠNG CHUỖI */
    CASE 
        WHEN nq.thoi_gian_giao_nhiem_vu IS NULL 
             OR TRIM(nq.thoi_gian_giao_nhiem_vu) = '' 
             OR nq.thoi_gian_giao_nhiem_vu LIKE '1970%' 
             OR nq.thoi_gian_giao_nhiem_vu LIKE '0000%'
        THEN NULL

        -- Dạng dd/mm/yyyy -> Giữ nguyên
        WHEN nq.thoi_gian_giao_nhiem_vu LIKE '%/%'
        THEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10)

        -- Dạng dd-mm-yyyy (dấu gạch ngang ở vị trí thứ 3)
        WHEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 3, 1) = '-'
        THEN REPLACE(SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10), '-', '/')

        -- Dạng yyyy-mm-dd (dấu gạch ngang ở vị trí thứ 5)
        WHEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 5, 1) = '-'
        THEN DATE_FORMAT(
            STR_TO_DATE(SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10), '%Y-%m-%d'), 
            '%d/%m/%Y'
        )

        ELSE SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10)
    END                                                     AS ngay_giao,

    CASE 
        WHEN nq.thoi_han_hoan_thanh IS NULL 
             OR TRIM(nq.thoi_han_hoan_thanh) = '' 
             OR nq.thoi_han_hoan_thanh LIKE '1970%' 
             OR nq.thoi_han_hoan_thanh LIKE '0000%'
        THEN NULL

        -- Dạng dd/mm/yyyy -> Giữ nguyên
        WHEN nq.thoi_han_hoan_thanh LIKE '%/%'
        THEN SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10)

        -- Dạng dd-mm-yyyy (dấu gạch ngang ở vị trí thứ 3)
        WHEN SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 3, 1) = '-'
        THEN REPLACE(SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10), '-', '/')

        -- Dạng yyyy-mm-dd (dấu gạch ngang ở vị trí thứ 5)
        WHEN SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 5, 1) = '-'
        THEN DATE_FORMAT(
            STR_TO_DATE(SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10), '%Y-%m-%d'), 
            '%d/%m/%Y'
        )

        ELSE SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10)
    END                                                     AS han_xu_ly,

    NULL                                                    AS ngay_hoan_thanh,
    NULL                                                    AS ngay_chap_nhan,
    NULL                                                    AS ngay_xoa,

    /* 6. TÌNH TRẠNG LẤY TỪ TRANG_THAI */
    nq.trang_thai                                           AS tinh_trang,

    /* 7. KẾT QUẢ THỰC HIỆN (bảng nguồn không có khó khăn / đề xuất) */
    COALESCE(NULLIF(nq.ket_qua_thuc_hien, ''), '—')         AS ket_qua_thuc_hien,
    '—'                                                     AS kho_khan_vuong_mac,
    '—'                                                     AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

/* Mỗi row_id giữ 1 dòng = dòng có NGÀY GIAO MỚI NHẤT.
   MySQL 5.7 không có ROW_NUMBER(), nên dựng "khóa sắp xếp" <yyyymmdd><source_row_id>
   rồi JOIN với MAX(khóa) theo row_id -> chỉ dòng mới nhất khớp. */
FROM `datamart_hanoi`.`api_theodoinq_danh_sach_nhiem_vu_chi_tiet` nq

INNER JOIN (
    SELECT nq0.row_id                                       AS row_id,
           MAX(CONCAT(
                   CASE                                                 -- ngày giao -> yyyymmdd để so sánh chuỗi đúng thứ tự
                       WHEN SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 5, 1) = '-'                  -- yyyy-mm-dd
                       THEN REPLACE(SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 1, 10), '-', '')
                       WHEN SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 3, 1) IN ('/', '-')          -- dd/mm/yyyy hoặc dd-mm-yyyy
                       THEN CONCAT(SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 7, 4), SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 4, 2), SUBSTRING(TRIM(nq0.thoi_gian_giao_nhiem_vu), 1, 2))
                       ELSE '00000000'                                  -- NULL/rỗng/hỏng -> xếp cuối
                   END,
                   LPAD(COALESCE(nq0.source_row_id, 0), 20, '0')        -- tie-break khi trùng ngày giao
               ))                            AS sort_key
    FROM `datamart_hanoi`.`api_theodoinq_danh_sach_nhiem_vu_chi_tiet` nq0
    WHERE nq0.ten_nhiem_vu IS NOT NULL
    GROUP BY nq0.row_id
) pick
    ON  pick.row_id   = nq.row_id
    AND pick.sort_key = CONCAT(
                            CASE                                                 -- ngày giao -> yyyymmdd để so sánh chuỗi đúng thứ tự
                                WHEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 5, 1) = '-'                  -- yyyy-mm-dd
                                THEN REPLACE(SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10), '-', '')
                                WHEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 3, 1) IN ('/', '-')          -- dd/mm/yyyy hoặc dd-mm-yyyy
                                THEN CONCAT(SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 7, 4), SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 4, 2), SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 2))
                                ELSE '00000000'                                  -- NULL/rỗng/hỏng -> xếp cuối
                            END,
                            LPAD(COALESCE(nq.source_row_id, 0), 20, '0')        -- tie-break khi trùng ngày giao
                        )

WHERE nq.ten_nhiem_vu IS NOT NULL;
