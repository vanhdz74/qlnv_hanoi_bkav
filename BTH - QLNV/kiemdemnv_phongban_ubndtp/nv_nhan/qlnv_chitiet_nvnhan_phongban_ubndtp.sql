CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chitiet_nvnhan_phongban_ubndtp` (
    task_id                   INT           NOT NULL,
    status                    TINYINT       NULL,

    id_truc_giao              VARCHAR(255)  NULL,     -- mã Part
    truc_giao                 VARCHAR(500)  NULL,
    van_ban_giao              VARCHAR(255)  NULL,     -- task.DocCode

    ma_nhiem_vu               VARCHAR(255)  NULL,     -- task.Code
    ten_nhiem_vu              TEXT          NULL,     -- task.Title varchar(6000)
    chu_de                    VARCHAR(255)  NULL,     -- task.NameGroup

    id_don_vi_giao            VARCHAR(255)  NULL,     -- task.AssignDepartment (mã Part)
    don_vi_giao               VARCHAR(500)  NULL,
    id_nguoi_giao             INT           NULL,     -- eGovUserId
    nguoi_giao                VARCHAR(255)  NULL,

    id_don_vi_chu_tri         VARCHAR(255)  NULL,     -- mã Part, KHÔNG phải số
    ten_don_vi_chu_tri        VARCHAR(500)  NULL,
    ten_don_vi_thuc_hien      VARCHAR(500)  NULL,
    id_nguoi_thuc_hien        INT           NULL,     -- eGovUserId (task.TargetUser)
    nguoi_thuc_hien           VARCHAR(255)  NULL,
    lanh_dao_ban_phu_trach    VARCHAR(500)  NULL,

    ngay_giao                 VARCHAR(10)   NULL,     -- dd/mm/yyyy (DATE_FORMAT)
    han_xu_ly                 VARCHAR(10)   NULL,
    ngay_hoan_thanh           VARCHAR(10)   NULL,
    ngay_chap_nhan            VARCHAR(10)   NULL,
    ngay_xoa                  VARCHAR(10)   NULL,

    tinh_trang                VARCHAR(64)   NULL,
    ket_qua_thuc_hien         LONGTEXT      NULL,     -- report.Content / task.Content
    kho_khan_vuong_mac        LONGTEXT      NULL,     -- report.Difficulty
    de_xuat_kien_nghi         LONGTEXT      NULL,     -- report.Suggestion
    id_phong_ban              VARCHAR(255)  NULL,     -- cấp cuối DepartmentPath của phòng ban
    sync_date                 DATETIME      NULL,
    PRIMARY KEY (task_id),                              -- SELECT có GROUP BY t.TaskId
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_chitiet_nvnhan_phongban_ubndtp`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_chitiet_nvnhan_phongban_ubndtp` (
    `task_id`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `van_ban_giao`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `chu_de`,
    `id_don_vi_giao`,
    `don_vi_giao`,
    `id_nguoi_giao`,
    `nguoi_giao`,
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
    `id_phong_ban`,
    `sync_date`
)

SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    t.Status                                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS chu_de,

    /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(MAX(d_assign.name), NULLIF(t.AssignOrganization, '')) AS don_vi_giao,
    t.AssignUser                                            AS id_nguoi_giao,
    MAX(u_assign.eGovUserFullname)                          AS nguoi_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    /* Cùng logic tonghop: nhánh 1841/1307/1310 lấy cấp 4, còn lại lấy id cuối */
    MAX(d_chutri.name)                                      AS ten_don_vi_chu_tri,

    COALESCE(
        MAX(d_donvi.name),
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, '')
    )                                                       AS ten_don_vi_thuc_hien,

    t.TargetUser                                            AS id_nguoi_thuc_hien,
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

    /* PHÒNG BAN: cấp cuối của đơn vị thực hiện (thuộc phòng ban 490.698.752.x) */
    SUBSTRING_INDEX(t.TargetDepartment, '.', -1)                                             AS id_phong_ban,
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* VĂN BẢN GIAO: không lọc ResolutionGroupId (giống tonghop, nhóm văn bản lấy theo DocCode) */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ GIAO (BÓC TÁCH ID TỪ T.ASSIGNDEPARTMENT ĐỂ LẤY TÊN) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign
       ON d_assign.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign.IsDelete = 0

/* JOIN NGƯỜI GIAO NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* ĐƠN VỊ CHỦ TRÌ: nhánh 1841/1307/1310 lấy cấp 4, còn lại lấy id cuối của TargetDepartment */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = IF(
              SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                 SUBSTRING_INDEX(t.TargetDepartment, '.', 4), t.TargetDepartment), '.', -1) REGEXP '^[0-9]+$',
              CAST(SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                      SUBSTRING_INDEX(t.TargetDepartment, '.', 4), t.TargetDepartment), '.', -1) AS UNSIGNED),
              NULL)
      AND d_chutri.IsDelete = 0

/* ĐƠN VỊ THỰC HIỆN: id cuối của TargetDepartment */

LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_donvi.IsDelete = 0

/* JOIN USER NHẬN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

WHERE
    t.DeletedDate IS NULL
    AND (
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )
    /* PHÒNG BAN NHẬN: chỉ lấy đơn vị thực hiện thuộc phòng ban 490.698.752.x */
    AND t.TargetDepartment LIKE '490.698.752.%'

GROUP BY t.TaskId;