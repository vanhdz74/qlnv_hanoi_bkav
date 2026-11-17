/* ===========================================================================
   DDL — qlnv_tonghop_cho_duyet_phongban_ubndtp
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (NiFi chỉ nhận "truncate + câu lệnh" bên dưới).
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_tonghop_cho_duyet_phongban_ubndtp` (
    task_id                  INT           NOT NULL,

    ma_nhiem_vu              VARCHAR(255)  NULL,      -- task.Code
    ten_nhiem_vu             TEXT          NULL,      -- task.Title varchar(6000)

    id_van_ban_giao          INT           NULL,      -- ResolutionId
    van_ban_giao             VARCHAR(255)  NULL,      -- task.DocCode / resolution.DocCode
    han_hoan_thanh           VARCHAR(10)   NULL,      -- dd/mm/yyyy (DATE_FORMAT)

    trang_thai               VARCHAR(64)   NULL,

    id_phong_ban_giao        VARCHAR(255)  NULL,      -- AssignDepartment / user.DepartmentPath
    phong_ban_giao           VARCHAR(500)  NULL,
    id_can_bo_giao           INT           NULL,      -- eGovUserId (task.CreateUser)
    can_bo_giao              VARCHAR(255)  NULL,

    id_don_vi_chu_tri        VARCHAR(255)  NULL,      -- mã Part, KHÔNG phải số
    don_vi_chu_tri           VARCHAR(500)  NULL,
    id_don_vi_thuc_hien      VARCHAR(255)  NULL,      -- mã Part
    don_vi                   VARCHAR(500)  NULL,      -- SELECT alias don_vi_thuc_hien, INSERT theo vị trí

    id_nguoi_thuc_hien       INT           NULL,      -- eGovUserId
    nguoi_thuc_hien          VARCHAR(255)  NULL,

    tinh_hinh_ket_qua        LONGTEXT      NULL,      -- report.Content / task.Content
    id_phong_ban              VARCHAR(255)  NULL,     -- cấp cuối DepartmentPath của phòng ban
    sync_date                DATETIME      NULL,
    PRIMARY KEY (task_id),                              -- SELECT có GROUP BY t.TaskId
    KEY idx_trang_thai (trang_thai),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_tonghop_cho_duyet_phongban_ubndtp`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_tonghop_cho_duyet_phongban_ubndtp` (
    `task_id`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `id_van_ban_giao`,
    `van_ban_giao`,
    `han_hoan_thanh`,
    `trang_thai`,
    `id_phong_ban_giao`,
    `phong_ban_giao`,
    `id_can_bo_giao`,
    `can_bo_giao`,
    `id_don_vi_chu_tri`,
    `don_vi_chu_tri`,
    `id_don_vi_thuc_hien`,
    `don_vi`,
    `id_nguoi_thuc_hien`,
    `nguoi_thuc_hien`,
    `tinh_hinh_ket_qua`,
    `id_phong_ban`,
    `sync_date`
)


SELECT
    /* =====================================================
       1. THÔNG TIN KHÓA & MÃ / TÊN NHIỆM VỤ
       ===================================================== */
    t.TaskId                                                AS task_id,
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,

    /* =====================================================
       2. VĂN BẢN GIAO & THỜI HẠN
       ===================================================== */
    COALESCE(t.ResolutionId, MAX(r.ResolutionId))           AS id_van_ban_giao,
    COALESCE(t.DocCode, MAX(r.DocCode))                     AS van_ban_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_hoan_thanh,

    /* =====================================================
       3. TRẠNG THÁI CHỜ PHÊ DUYỆT (TRONG HẠN / QUÁ HẠN)
       ===================================================== */
    CASE
        WHEN t.ExpireDate IS NOT NULL AND DATE(t.ExpireDate) < CURDATE() 
        THEN 'Chờ duyệt quá hạn'
        WHEN t.ExpireDate IS NOT NULL AND DATE(t.ExpireDate) >= CURDATE() 
        THEN 'Chờ duyệt trong hạn'
        ELSE 'Chờ duyệt - không có hạn'
    END                                                     AS trang_thai,

    /* =====================================================
       4. PHÒNG BAN GIAO & CÁN BỘ GIAO (ID TRƯỚC TÊN)
       ===================================================== */
    -- TH1: Giao trực tiếp từ 490.698.752% -> lấy AssignDepartment (5 cấp thì lùi về cấp 4)
    -- TH2: Bên khác giao qua -> lấy DepartmentPath của CreateUser (5 cấp thì lùi về cấp 4)
    CASE 
        WHEN t.AssignDepartment LIKE '490.698.752.%' THEN
            CASE 
                WHEN (LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', ''))) >= 4 
                THEN SUBSTRING_INDEX(t.AssignDepartment, '.', 4)
                ELSE t.AssignDepartment 
            END
        ELSE 
            CASE 
                WHEN (LENGTH(MAX(u_create.DepartmentPath)) - LENGTH(REPLACE(MAX(u_create.DepartmentPath), '.', ''))) >= 4 
                THEN SUBSTRING_INDEX(MAX(u_create.DepartmentPath), '.', 4)
                ELSE MAX(u_create.DepartmentPath)
            END
    END                                                     AS id_phong_ban_giao,

    CASE 
        WHEN t.AssignDepartment LIKE '490.698.752.%' THEN 
            CASE
                WHEN (LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', ''))) >= 4 
                THEN COALESCE(MAX(d_assign.name), NULLIF(t.AssignOrganization, ''))
                ELSE COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign.name))
            END
        ELSE MAX(d_create_dept.name)
    END                                                     AS phong_ban_giao,

    t.CreateUser                                            AS id_can_bo_giao,
    MAX(u_assign.eGovUserFullname)                          AS can_bo_giao,

    /* =====================================================
       5. ĐƠN VỊ CHỦ TRÌ & ĐƠN VỊ THỰC HIỆN (ID TRƯỚC TÊN)
       ===================================================== */
    CASE 
        WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4 
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        ELSE t.TargetDepartment 
    END                                                     AS id_don_vi_chu_tri,
    COALESCE(
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS don_vi_chu_tri,

    t.TargetDepartment                                      AS id_don_vi_thuc_hien,
    MAX(d_donvi.name)                                       AS don_vi_thuc_hien,

    /* =====================================================
       6. NGƯỜI THỰC HIỆN (ID TRƯỚC TÊN)
       ===================================================== */
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    MAX(u_target.eGovUserFullname)                          AS nguoi_thuc_hien,

    /* =====================================================
       7. TÌNH HÌNH, KẾT QUẢ
       ===================================================== */
    COALESCE(
        MAX(rp_last.Content), 
        t.Content
    )                                                       AS tinh_hinh_ket_qua,

    /* PHÒNG BAN: cấp cuối của đơn vị giao, không thuộc phòng ban thì lấy từ người duyệt báo cáo */
    SUBSTRING_INDEX(COALESCE(
        IF(t.AssignDepartment LIKE '490.698.752.%', t.AssignDepartment, NULL),
        (SELECT MIN(u_app.DepartmentPath)
         FROM `db_theodoinv_hn`.`qlnv_report` rp_check
         INNER JOIN `db_theodoinv_hn`.`qlnv_user` u_app
                 ON u_app.eGovUserId = rp_check.ApprovedUser
         WHERE rp_check.TaskId = t.TaskId
           AND rp_check.DeletedDate IS NULL
           AND u_app.DepartmentPath LIKE '490.698.752.%')
    ), '.', -1)                                             AS id_phong_ban,
    /* Thời điểm đồng bộ */
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* SUBQUERY LỌC NHIỆM VỤ CÓ BÁO CÁO CHỜ DUYỆT TỪ qlnv_report */
INNER JOIN (
    SELECT 
        rp.TaskId
    FROM `db_theodoinv_hn`.`qlnv_report` rp
    INNER JOIN `db_theodoinv_hn`.`qlnv_task` t_sub 
            ON rp.TaskId = t_sub.TaskId
    WHERE rp.DeletedDate IS NULL
      AND rp.Type IN (1, 2, 3, 4)
      AND rp.Status = 0
      AND t_sub.Status < 3
      AND t_sub.CreateUser = rp.ApprovedUser
    GROUP BY rp.TaskId
) rp_wait 
    ON rp_wait.TaskId = t.TaskId

/* NỘI DUNG BÁO CÁO GẦN NHẤT */
LEFT JOIN (
    SELECT 
        rp.TaskId, 
        rp.Content
    FROM `db_theodoinv_hn`.`qlnv_report` rp
    INNER JOIN (
        SELECT 
            TaskId, 
            MAX(CreatedDate) AS MaxCreatedDate
        FROM `db_theodoinv_hn`.`qlnv_report`
        WHERE DeletedDate IS NULL
        GROUP BY TaskId
    ) rp_max ON rp.TaskId = rp_max.TaskId AND rp.CreatedDate = rp_max.MaxCreatedDate
    WHERE rp.DeletedDate IS NULL
) rp_last ON rp_last.TaskId = t.TaskId

/* JOIN THÔNG TIN VĂN BẢN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution` r
       ON r.ResolutionId = t.ResolutionId
      AND r.DeletedDate IS NULL

/* JOIN PHÒNG BAN GIAO (TH1: NẾU CÓ 5 CẤP THÌ LẤY ID CẤP 4) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign
       ON d_assign.id = CASE 
            WHEN SUBSTRING_INDEX(
                CASE 
                    WHEN (LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(t.AssignDepartment, '.', 4)
                    ELSE t.AssignDepartment 
                END, '.', -1
            ) REGEXP '^[0-9]+$' 
            THEN CAST(
                SUBSTRING_INDEX(
                    CASE 
                        WHEN (LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', ''))) >= 4 
                        THEN SUBSTRING_INDEX(t.AssignDepartment, '.', 4)
                        ELSE t.AssignDepartment 
                    END, '.', -1
                ) AS UNSIGNED
            ) 
            ELSE NULL 
          END
      AND d_assign.IsDelete = 0

/* JOIN CÁN BỘ TẠO TASK (TH2) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser

/* JOIN PHÒNG BAN CỦA CÁN BỘ TẠO TASK (TH2: NẾU CÓ 5 CẤP THÌ LẤY ID CẤP 4) */
LEFT JOIN `db_theodoinv_hn`.`department` d_create_dept
       ON d_create_dept.id = CASE 
            WHEN SUBSTRING_INDEX(
                CASE 
                    WHEN (LENGTH(u_create.DepartmentPath) - LENGTH(REPLACE(u_create.DepartmentPath, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', 4)
                    ELSE u_create.DepartmentPath 
                END, '.', -1
            ) REGEXP '^[0-9]+$' 
            THEN CAST(
                SUBSTRING_INDEX(
                    CASE 
                        WHEN (LENGTH(u_create.DepartmentPath) - LENGTH(REPLACE(u_create.DepartmentPath, '.', ''))) >= 4 
                        THEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', 4)
                        ELSE u_create.DepartmentPath 
                    END, '.', -1
                ) AS UNSIGNED
            ) 
            ELSE NULL 
          END
      AND d_create_dept.IsDelete = 0

/* JOIN CẤP ĐƠN VỊ CHỦ TRÌ (CẤP 3/4) */
LEFT JOIN `db_theodoinv_hn`.`department` d_cap
       ON d_cap.id = CASE 
            WHEN SUBSTRING_INDEX(
                CASE 
                    WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE t.TargetDepartment 
                END, '.', -1
            ) REGEXP '^[0-9]+$' 
            THEN CAST(
                SUBSTRING_INDEX(
                    CASE 
                        WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4 
                        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                        ELSE t.TargetDepartment 
                    END, '.', -1
                ) AS UNSIGNED
            )
            ELSE NULL 
          END
      AND d_cap.IsDelete = 0

/* JOIN ĐƠN VỊ THỰC HIỆN */
LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CASE 
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$' 
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED) 
            ELSE NULL 
          END
      AND d_donvi.IsDelete = 0

/* JOIN USER LẤY TÊN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_assign
       ON u_assign.eGovUserId = t.CreateUser

LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target
       ON u_target.eGovUserId = t.TargetUser

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        /* TRƯỜNG HỢP 1: GIAO TRỰC TIẾP TỪ PHÒNG BAN 490.698.752% */
        t.AssignDepartment LIKE '490.698.752.%'

        OR

        /* TRƯỜNG HỢP 2: BÊN KHÁC GIAO QUA NHƯNG NGƯỜI DUYỆT BÁO CÁO THUỘC 490.698.752% */
        EXISTS (
            SELECT 1
            FROM `db_theodoinv_hn`.`qlnv_report` rp_check
            INNER JOIN `db_theodoinv_hn`.`qlnv_user` u_app
                    ON u_app.eGovUserId = rp_check.ApprovedUser
            WHERE rp_check.TaskId = t.TaskId
              AND rp_check.DeletedDate IS NULL
              AND u_app.DepartmentPath LIKE '490.698.752.%'
        ) 
    )

GROUP BY t.TaskId;