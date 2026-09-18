/* ===========================================================================
   DDL — qlnv_tonghop_chitiet_nvnhan_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).

   Ghi chú task_id:
   - Nhánh 1: GROUP BY t.TaskId (chống nhân dòng do LEFT JOIN qlnv_user & department).
   - Nhánh 2: JOIN MAX(khóa sắp xếp) theo row_id -> giữ dòng ngày giao mới nhất.
   - task_id nhánh 2 (row_id/CRC32) có thể đụng TaskId nhánh 1 -> để KEY, KHÔNG để PRIMARY KEY.
   - task_id BIGINT vì CRC32 tối đa 4294967295.
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_tonghop_chitiet_nvnhan_pth_vpthanhuy` (
    task_id                  BIGINT        NOT NULL,   -- BIGINT vì nhánh 2 dùng CRC32 (tối đa 4294967295)
    status                   TINYINT       NULL,

    id_truc_giao             VARCHAR(50)   NULL,      -- AssignDepartment cắt về cấp 2
    truc_giao                VARCHAR(500)  NULL,
    van_ban_giao             VARCHAR(50)   NULL,      -- task.DocCode

    ma_nhiem_vu              VARCHAR(255)  NULL,      -- task.Code
    ten_nhiem_vu             TEXT          NULL,      -- task.Title varchar(6000)

    id_lanh_dao              INT           NULL,      -- eGovUserId (task.TargetUser)
    ten_lanh_dao             VARCHAR(255)  NULL,

    id_don_vi_chu_tri        VARCHAR(50)   NULL,      -- task.TargetDepartment (mã Part)
    ten_don_vi_chu_tri       VARCHAR(500)  NULL,
    ten_phong_theo_doi       VARCHAR(500)  NULL,      -- hiện SELECT trả NULL

    id_chuyen_vien           INT           NULL,      -- hiện SELECT trả NULL
    chuyen_vien              VARCHAR(255)  NULL,      -- hiện SELECT trả NULL

    ngay_giao                VARCHAR(10)   NULL,      -- dd/mm/yyyy (DATE_FORMAT)
    han_xu_ly                VARCHAR(10)   NULL,      -- dd/mm/yyyy
    ngay_hoan_thanh          VARCHAR(10)   NULL,      -- dd/mm/yyyy
    ngay_xoa                 VARCHAR(10)   NULL,      -- dd/mm/yyyy

    tinh_trang               VARCHAR(32)   NULL,
    tinh_hinh_ket_qua        LONGTEXT      NULL,      -- report.Content / task.Content
    sync_date                DATETIME      NULL,
    KEY idx_task       (task_id),                       -- ⚠ KHÔNG phải PK: xem ghi chú đầu file
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_tonghop_chitiet_nvnhan_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvnhan_pth_vpthanhuy` (
    `task_id`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `van_ban_giao`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `id_lanh_dao`,
    `ten_lanh_dao`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `ten_phong_theo_doi`,
    `id_chuyen_vien`,
    `chuyen_vien`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_xoa`,
    `tinh_trang`,
    `tinh_hinh_ket_qua`,
    `sync_date`
)


/* =======================================================================
   NHÁNH 1: NHIỆM VỤ NHẬN TỪ HỆ THỐNG QLNV (qlnv_task)
   ======================================================================= */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    CAST(t.TaskId AS SIGNED)                                AS task_id,
    CAST(t.Status AS SIGNED)                                AS status,

    /* 2. TRỤC GIAO CẤP 2 (ID & TÊN CẤP 2) */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ & LÃNH ĐẠO */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    CAST(t.TargetUser AS SIGNED)                            AS id_lanh_dao,
    MAX(u_target.eGovUserFullname)                          AS ten_lanh_dao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & PHÒNG THEO DÕI */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    COALESCE(
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS ten_don_vi_chu_tri,
    NULL                                                    AS ten_phong_theo_doi,

    /* 5. CHUYÊN VIÊN THỰC HIỆN */
    CAST(NULL AS SIGNED)                                    AS id_chuyen_vien,
    NULL                                                    AS chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                  AS ngay_xoa,

    /* 7. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
    CASE
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'

        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    /* 8. KẾT QUẢ & ĐỒNG BỘ */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        t.Content
    )                                                       AS tinh_hinh_ket_qua,
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) 
            AS UNSIGNED
          ) AND d_assign_cap2.IsDelete = 0

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

LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )
    AND t.TargetDepartment LIKE '490.695%'
    AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.1775%'
    AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

/* Gom 1 dòng / 1 TaskId: chống nhân dòng do LEFT JOIN qlnv_user & department */
GROUP BY t.TaskId

UNION ALL

/* -----------------------------------------------------------------------
   NHÁNH 2: BẢNG datamart_hanoi.api_theodoinq_danh_sach_nhiem_vu_chi_tiet
   ----------------------------------------------------------------------- */
SELECT
    /* 1. KHÓA HỆ THỐNG */
    CAST(
        COALESCE(
            NULLIF(nq.row_id, ''), 
            NULLIF(nq.source_row_id, ''),
            CRC32(CONCAT(COALESCE(nq.ma_nhiem_vu, ''), COALESCE(nq.ten_nhiem_vu, '')))
        ) AS SIGNED
    )                                                       AS task_id,
    CAST(NULL AS SIGNED)                                    AS status,

    /* 2. TRỤC GIAO */
    NULL                                                    AS id_truc_giao,
     'Trung ương'									          AS truc_giao,
    nq.van_ban_giao_nhiem_vu                                AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ & LÃNH ĐẠO */
    nq.ma_nhiem_vu                                          AS ma_nhiem_vu,
    nq.ten_nhiem_vu                                         AS ten_nhiem_vu,
    CAST(NULL AS SIGNED)                                    AS id_lanh_dao,
    NULL                                                    AS ten_lanh_dao,

    /* 4. ĐƠN VỊ CHỦ TRÌ & PHÒNG THEO DÕI */
    NULL                                                    AS id_don_vi_chu_tri,
    nq.don_vi_chu_tri                                       AS ten_don_vi_chu_tri,
    NULL                                                    AS ten_phong_theo_doi,

    /* 5. CHUYÊN VIÊN */
    CAST(NULL AS SIGNED)                                    AS id_chuyen_vien,
    NULL                                                    AS chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN: PHÂN LOẠI RÕ TỪNG DẠNG CHUỖI */
    CASE 
        WHEN nq.thoi_gian_giao_nhiem_vu IS NULL 
             OR TRIM(nq.thoi_gian_giao_nhiem_vu) = '' 
             OR nq.thoi_gian_giao_nhiem_vu LIKE '1970%' 
             OR nq.thoi_gian_giao_nhiem_vu LIKE '0000%'
        THEN NULL

        -- Dạng dd/mm/yyyy -> Giữ nguyên
        WHEN nq.thoi_gian_giao_nhiem_vu LIKE '%/%'
        THEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10)

        -- Dạng dd-mm-yyyy (ví dụ '05-01-2026', dấu gạch ngang ở vị trí thứ 3)
        WHEN SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 3, 1) = '-'
        THEN REPLACE(SUBSTRING(TRIM(nq.thoi_gian_giao_nhiem_vu), 1, 10), '-', '/')

        -- Dạng yyyy-mm-dd (ví dụ '2026-01-05', dấu gạch ngang ở vị trí thứ 5)
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

        -- Dạng dd-mm-yyyy (ví dụ '05-01-2026', dấu gạch ngang ở vị trí thứ 3)
        WHEN SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 3, 1) = '-'
        THEN REPLACE(SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10), '-', '/')

        -- Dạng yyyy-mm-dd (ví dụ '2026-01-05', dấu gạch ngang ở vị trí thứ 5)
        WHEN SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 5, 1) = '-'
        THEN DATE_FORMAT(
            STR_TO_DATE(SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10), '%Y-%m-%d'), 
            '%d/%m/%Y'
        )

        ELSE SUBSTRING(TRIM(nq.thoi_han_hoan_thanh), 1, 10)
    END                                                     AS han_xu_ly,

    NULL                                                    AS ngay_hoan_thanh,
    NULL                                                    AS ngay_xoa,

    /* 7. TÌNH TRẠNG LẤY TỪ TRANG_THAI */
    nq.trang_thai                                           AS tinh_trang,

    /* 8. KẾT QUẢ THỰC HIỆN */
    COALESCE(NULLIF(nq.ket_qua_thuc_hien, ''), '—')         AS tinh_hinh_ket_qua,
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
