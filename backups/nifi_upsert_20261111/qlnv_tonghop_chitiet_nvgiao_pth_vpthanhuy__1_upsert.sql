/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_vpthanhuy` (
    `id_truc_giao`,
    `truc_giao`,
    `nhom_nhiem_vu`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `van_ban_giao`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `id_lanh_dao`,
    `ten_lanh_dao`,
    `id_chuyen_vien`,
    `chuyen_vien`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_xoa`,
    `tinh_trang`,
    `tinh_hinh_ket_qua`,
    `ld_ubnd`,
    `ld_van_phong`,
    `phong_chuyen_mon_theo_doi`,
    `chuyen_vien_vp_theo_doi`,
    `task_id`,
    `status`,
    `sync_date`
)

SELECT
    /* 1. NHÓM NHIỆM VỤ / TRỤC GIAO */
    t.AssignDepartment                                     AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.NameGroup                                            AS nhom_nhiem_vu,

    /* 2. MÃ NHIỆM VỤ & TÊN NHIỆM VỤ */
    t.Code                                                 AS ma_nhiem_vu,
    t.Title                                                AS ten_nhiem_vu,

    /* 3. VĂN BẢN GIAO */
    t.DocCode                                              AS van_ban_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (CHUẨN HÓA CẤP) */
    CASE
        WHEN t.TargetDepartment LIKE '490.698.1307%'
          OR t.TargetDepartment LIKE '490.698.1310%'
          OR t.TargetDepartment LIKE '490.698.1841%'
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
    END                                                    AS id_don_vi_chu_tri,

    COALESCE(MAX(d_chutri.name))                           AS ten_don_vi_chu_tri,

    /* 5. LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN */
    CASE 
        WHEN t.TargetUser REGEXP '^[0-9]+$' 
        THEN CAST(t.TargetUser AS SIGNED) 
        ELSE NULL 
    END                                                    AS id_lanh_dao,
    MAX(u_target.eGovUserFullname)                         AS ten_lanh_dao,
    NULL                                                   AS id_chuyen_vien,
    NULL                                                   AS chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                 AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                  AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')               AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                 AS ngay_xoa,

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
    END                                                    AS tinh_trang,

    /* 8. TÌNH HÌNH, KẾT QUẢ THỰC HIỆN */
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
    )                                                      AS tinh_hinh_ket_qua,

    /* 9. BỔ SUNG 4 CỘT THEO DÕI */
    CAST(NULL AS CHAR(255))                                AS ld_ubnd,
    CAST(NULL AS CHAR(255))                                AS ld_van_phong,
    NULLIF(MAX(d_create.name), '')                         AS phong_chuyen_mon_theo_doi,
    NULLIF(MAX(u_create.eGovUserFullname), '')             AS chuyen_vien_vp_theo_doi,

    /* 10. KHÓA HỆ THỐNG & ĐỒNG BỘ */
    t.TaskId                                               AS task_id,
    t.Status                                               AS status,
    '${sync_ts}' AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN TRỤC GIAO CẤP 2 (Giữ nguyên d_assign_cap2.id để dùng Index) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE 
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL 
          END 
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ CHỦ TRÌ (Giữ nguyên d_chutri.id để dùng Index) */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = CASE 
            WHEN SUBSTRING_INDEX(
                CASE
                    WHEN t.TargetDepartment LIKE '490.698.1307%'
                      OR t.TargetDepartment LIKE '490.698.1310%'
                      OR t.TargetDepartment LIKE '490.698.1841%'
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                END, '.', -1
            ) REGEXP '^[0-9]+$'
            THEN CAST(
                SUBSTRING_INDEX(
                    CASE
                        WHEN t.TargetDepartment LIKE '490.698.1307%'
                          OR t.TargetDepartment LIKE '490.698.1310%'
                          OR t.TargetDepartment LIKE '490.698.1841%'
                        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                    END, '.', -1
                ) AS UNSIGNED
            )
            ELSE NULL 
          END 
      AND d_chutri.IsDelete = 0

/* JOIN USER NHẬN: Giữ bare u_target.eGovUserId để MySQL sử dụng Index B-Tree */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = CASE 
            WHEN t.TargetUser REGEXP '^[0-9]+$' 
            THEN CAST(t.TargetUser AS UNSIGNED) 
            ELSE NULL 
          END

/* JOIN USER TẠO: Giữ bare u_create.eGovUserId để MySQL sử dụng Index B-Tree */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = CASE 
            WHEN t.CreateUser REGEXP '^[0-9]+$' 
            THEN CAST(t.CreateUser AS UNSIGNED) 
            ELSE NULL 
          END

/* JOIN PHÒNG BAN NGƯỜI TẠO */
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = CASE 
            WHEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED)
            ELSE NULL 
          END 
      AND d_create.IsDelete = 0

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
    AND t.AssignDepartment LIKE '490.695%'
    AND COALESCE(t.TargetDepartment, '') NOT IN (
        '490.698.1307',
        '490.698.1310',
        '490.698.1841'
    )

GROUP BY t.TaskId
ON DUPLICATE KEY UPDATE
    `id_truc_giao` = VALUES(`id_truc_giao`),
    `truc_giao` = VALUES(`truc_giao`),
    `nhom_nhiem_vu` = VALUES(`nhom_nhiem_vu`),
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `ten_nhiem_vu` = VALUES(`ten_nhiem_vu`),
    `van_ban_giao` = VALUES(`van_ban_giao`),
    `id_don_vi_chu_tri` = VALUES(`id_don_vi_chu_tri`),
    `ten_don_vi_chu_tri` = VALUES(`ten_don_vi_chu_tri`),
    `id_lanh_dao` = VALUES(`id_lanh_dao`),
    `ten_lanh_dao` = VALUES(`ten_lanh_dao`),
    `id_chuyen_vien` = VALUES(`id_chuyen_vien`),
    `chuyen_vien` = VALUES(`chuyen_vien`),
    `ngay_giao` = VALUES(`ngay_giao`),
    `han_xu_ly` = VALUES(`han_xu_ly`),
    `ngay_hoan_thanh` = VALUES(`ngay_hoan_thanh`),
    `ngay_xoa` = VALUES(`ngay_xoa`),
    `tinh_trang` = VALUES(`tinh_trang`),
    `tinh_hinh_ket_qua` = VALUES(`tinh_hinh_ket_qua`),
    `ld_ubnd` = VALUES(`ld_ubnd`),
    `ld_van_phong` = VALUES(`ld_van_phong`),
    `phong_chuyen_mon_theo_doi` = VALUES(`phong_chuyen_mon_theo_doi`),
    `chuyen_vien_vp_theo_doi` = VALUES(`chuyen_vien_vp_theo_doi`),
    `status` = VALUES(`status`),
    `sync_date` = VALUES(`sync_date`);
