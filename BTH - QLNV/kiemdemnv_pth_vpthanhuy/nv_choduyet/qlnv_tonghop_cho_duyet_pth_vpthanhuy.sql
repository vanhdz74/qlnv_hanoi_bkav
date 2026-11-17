/* ===========================================================================
   DDL — qlnv_tonghop_cho_duyet_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_tonghop_cho_duyet_pth_vpthanhuy` (
    task_id                  INT           NOT NULL,

    ma_nhiem_vu              VARCHAR(255)  NULL,      -- task.Code
    ten_nhiem_vu             TEXT          NULL,      -- task.Title varchar(6000)

    id_van_ban_giao          INT           NULL,      -- ResolutionId
    van_ban_giao             VARCHAR(255)  NULL,      -- task.DocCode / resolution.DocCode
    han_hoan_thanh           VARCHAR(10)   NULL,      -- dd/mm/yyyy (DATE_FORMAT)

    trang_thai               VARCHAR(32)   NULL,

    id_phong_ban_giao        VARCHAR(255)  NULL,      -- AssignDepartment / user.DepartmentPath
    phong_ban_giao           VARCHAR(500)  NULL,
    id_can_bo_giao           INT           NULL,      -- eGovUserId (task.CreateUser)
    can_bo_giao              VARCHAR(255)  NULL,

    id_don_vi_chu_tri        VARCHAR(50)   NULL,      -- mã Part, KHÔNG phải số
    don_vi_chu_tri           VARCHAR(500)  NULL,
    id_don_vi_thuc_hien      VARCHAR(50)   NULL,      -- mã Part
    don_vi_thuc_hien         VARCHAR(500)  NULL,

    id_nguoi_thuc_hien       INT           NULL,      -- eGovUserId
    nguoi_thuc_hien          VARCHAR(255)  NULL,

    tinh_hinh_ket_qua        LONGTEXT      NULL,      -- report.Content / task.Content
    sync_date                DATETIME      NULL,
    PRIMARY KEY (task_id),                              -- SELECT có GROUP BY t.TaskId
    KEY idx_trang_thai (trang_thai),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_tonghop_cho_duyet_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_tonghop_cho_duyet_pth_vpthanhuy` (
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
    `don_vi_thuc_hien`,
    `id_nguoi_thuc_hien`,
    `nguoi_thuc_hien`,
    `tinh_hinh_ket_qua`,
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
    -- TH1: Giao trực tiếp từ 490.695% -> lấy AssignDepartment
    -- TH2: Bên khác giao qua -> lấy DepartmentPath của CreateUser
    CASE 
        WHEN t.AssignDepartment LIKE '490.695%' THEN t.AssignDepartment
        ELSE MAX(u_create.DepartmentPath)
    END                                                     AS id_phong_ban_giao,

    CASE 
        WHEN t.AssignDepartment LIKE '490.695%' THEN COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign.name))
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
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS don_vi_chu_tri,

    t.TargetDepartment                                      AS id_don_vi_thuc_hien,
    NULL                                                    AS don_vi_thuc_hien,

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

/* JOIN PHÒNG BAN GIAO (TH1) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign
       ON d_assign.id = CASE 
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$' 
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED) 
            ELSE NULL 
          END
      AND d_assign.IsDelete = 0

/* JOIN CÁN BỘ TẠO TASK (TH2) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser

/* JOIN PHÒNG BAN CỦA CÁN BỘ TẠO TASK (TH2) */
LEFT JOIN `db_theodoinv_hn`.`department` d_create_dept
       ON d_create_dept.id = CASE 
            WHEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$' 
            THEN CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED) 
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
        /* TRƯỜNG HỢP 1: GIAO TRỰC TIẾP TỪ VĂN PHÒNG THÀNH ỦY 490.695% */
        t.AssignDepartment LIKE '490.695%'

        OR

        /* TRƯỜNG HỢP 2: BÊN KHÁC GIAO QUA NHƯNG NGƯỜI DUYỆT BÁO CÁO THUỘC 490.695% */
        EXISTS (
            SELECT 1
            FROM `db_theodoinv_hn`.`qlnv_report` rp_check
            INNER JOIN `db_theodoinv_hn`.`qlnv_user` u_app
                    ON u_app.eGovUserId = rp_check.ApprovedUser
            WHERE rp_check.TaskId = t.TaskId
              AND rp_check.DeletedDate IS NULL
              AND u_app.DepartmentPath LIKE '490.695%'
        ) 
    )

GROUP BY t.TaskId;