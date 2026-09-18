/* ===========================================================================
   DDL — qlnv_chitiet_nvchoduyet_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chitiet_nvchoduyet_pth_vpthanhuy` (
    task_id                  INT           NOT NULL,
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
    PRIMARY KEY (task_id),                              -- SELECT có GROUP BY t.TaskId
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_don_vi     (id_don_vi_chu_tri),
    KEY idx_truc_giao  (id_truc_giao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_chitiet_nvchoduyet_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_chitiet_nvchoduyet_pth_vpthanhuy` (
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


SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    t.Status                                                AS status,

    /* 2. NHÓM NHIỆM VỤ / TRỤC GIAO & VĂN BẢN GIAO 
       - TH1: Giao trực tiếp từ 490.695% -> lấy AssignDepartment
       - TH2: Bên khác giao qua -> lấy DepartmentPath của CreateUser */
    CASE 
        WHEN t.AssignDepartment LIKE '490.695%' THEN t.AssignDepartment
        ELSE MAX(u_create.DepartmentPath)
    END                                                     AS id_truc_giao,

    CASE 
        WHEN t.AssignDepartment LIKE '490.695%' THEN COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign.name))
        ELSE MAX(d_create_dept.name)
    END                                                     AS truc_giao,

    COALESCE(t.DocCode, MAX(r.DocCode))                     AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS chu_de,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (LÙI VỀ CẤP 4 NẾU CÓ >= 4 DẤU CHẤM) */
    CASE 
        WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4 
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        ELSE t.TargetDepartment 
    END                                                     AS id_don_vi_chu_tri,

    COALESCE(
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS ten_don_vi_chu_tri,

    /* LẤY DỮ LIỆU GIỐNG DON_VI_CHU_TRI */
    COALESCE(
        MAX(d_cap.name),
        MAX(d_donvi.name)
    )                                                       AS ten_don_vi_thuc_hien,

    /* 5. NGƯỜI THỰC HIỆN & LÃNH ĐẠO BAN PHỤ TRÁCH */
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    MAX(u_target.eGovUserFullname)                          AS nguoi_thuc_hien,

    MAX(u_assign.eGovUserFullname)                          AS lanh_dao_ban_phu_trach,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%d/%m/%Y')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                  AS ngay_xoa,

    /* 7. PHÂN LOẠI 3 TRẠNG THÁI CHỜ DUYỆT */
    CASE
        WHEN t.ExpireDate IS NOT NULL AND DATE(t.ExpireDate) < CURDATE() 
        THEN 'Chờ duyệt quá hạn'
        WHEN t.ExpireDate IS NOT NULL AND DATE(t.ExpireDate) >= CURDATE() 
        THEN 'Chờ duyệt trong hạn'
        ELSE 'Chờ duyệt - không có hạn'
    END                                                     AS tinh_trang,

    /* 8. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Lấy bản ghi báo cáo mới nhất) */
    COALESCE(
        MAX(rp_last.Content), 
        t.Content,
        '—'
    )                                                       AS ket_qua_thuc_hien,

    COALESCE(
        MAX(rp_last.Difficulty), 
        '—'
    )                                                       AS kho_khan_vuong_mac,

    COALESCE(
        MAX(rp_last.Suggestion), 
        '—'
    )                                                       AS de_xuat_kien_nghi,

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

/* NỘI DUNG BÁO CÁO GẦN NHẤT (Content, Difficulty, Suggestion) */
LEFT JOIN (
    SELECT 
        rp.TaskId, 
        rp.Content,
        NULLIF(rp.Difficulty, '') AS Difficulty,
        NULLIF(rp.Suggestion, '') AS Suggestion
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

/* JOIN USER LẤY TÊN (CÁN BỘ GIAO VÀ NGƯỜI THỰC HIỆN) */
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