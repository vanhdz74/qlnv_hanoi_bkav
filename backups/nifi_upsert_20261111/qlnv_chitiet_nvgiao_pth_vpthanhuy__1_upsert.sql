/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO `datamart_hanoi`.`qlnv_chitiet_nvgiao_pth_vpthanhuy` (
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

    /* 2. NHÓM NHIỆM VỤ / TRỤC GIAO & VĂN BẢN GIAO */
    t.AssignDepartment                                      AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS chu_de,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (CHUẨN HÓA CẤP) */
    CASE
        WHEN t.TargetDepartment LIKE '490.698.1307%'
          OR t.TargetDepartment LIKE '490.698.1310%'
          OR t.TargetDepartment LIKE '490.698.1841%'
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
    END                                                     AS id_don_vi_chu_tri,

    COALESCE(MAX(d_chutri.name))                            AS ten_don_vi_chu_tri,
    COALESCE(MAX(d_donvi.name))                             AS ten_don_vi_thuc_hien,

    /* 5. NGƯỜI THỰC HIỆN & LÃNH ĐẠO BAN PHỤ TRÁCH */
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    MAX(u_target.eGovUserFullname)                          AS nguoi_thuc_hien,

    CONCAT_WS(' · ',
        COALESCE(MAX(u_target.eGovUserPositionName), NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%d/%m/%Y')                 AS ngay_chap_nhan,
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
             AND DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND DATE(t.ExpireDate) < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    /* 8. BÁO CÁO MỚI NHẤT (LẤY TỪ 1 LẦN JOIN THAY VÌ 3 SUBQUERY LẶP) */
    COALESCE(rp_last.Content, t.Content, '—')               AS ket_qua_thuc_hien,
    COALESCE(NULLIF(rp_last.Difficulty, ''), '—')           AS kho_khan_vuong_mac,
    COALESCE(NULLIF(rp_last.Suggestion, ''), '—')           AS de_xuat_kien_nghi,

    '${sync_ts}' AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* 1. LẤY BÁO CÁO GẦN NHẤT: Thu hẹp phạm vi theo TaskId trước khi lấy nội dung */
LEFT JOIN (
    SELECT 
        rp.TaskId,
        rp.Content,
        rp.Difficulty,
        rp.Suggestion
    FROM `db_theodoinv_hn`.`qlnv_report` rp
    INNER JOIN (
        SELECT 
            TaskId,
            MAX(ReportId) AS MaxReportId
        FROM `db_theodoinv_hn`.`qlnv_report`
        WHERE DeletedDate IS NULL
        GROUP BY TaskId
    ) rp_max ON rp.TaskId = rp_max.TaskId AND rp.ReportId = rp_max.MaxReportId
    WHERE rp.DeletedDate IS NULL
) rp_last ON rp_last.TaskId = t.TaskId

/* 2. JOIN TRỤC GIAO CẤP 2 (Kiểm tra chuỗi số an toàn trước khi ép kiểu) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE 
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL 
          END 
      AND d_assign_cap2.IsDelete = 0

/* 3. JOIN ĐƠN VỊ CHỦ TRÌ (Đã chuẩn hóa cấp) */
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

/* 4. JOIN ĐƠN VỊ THỰC HIỆN TRỰC TIẾP */
LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CASE 
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL 
          END 
      AND d_donvi.IsDelete = 0

/* 5. JOIN USER NHẬN: Giữ bare u_target.eGovUserId để tối ưu Index */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = CASE 
            WHEN t.TargetUser REGEXP '^[0-9]+$' 
            THEN CAST(t.TargetUser AS UNSIGNED) 
            ELSE NULL 
          END

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
    `status` = VALUES(`status`),
    `id_truc_giao` = VALUES(`id_truc_giao`),
    `truc_giao` = VALUES(`truc_giao`),
    `van_ban_giao` = VALUES(`van_ban_giao`),
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `ten_nhiem_vu` = VALUES(`ten_nhiem_vu`),
    `chu_de` = VALUES(`chu_de`),
    `id_don_vi_chu_tri` = VALUES(`id_don_vi_chu_tri`),
    `ten_don_vi_chu_tri` = VALUES(`ten_don_vi_chu_tri`),
    `ten_don_vi_thuc_hien` = VALUES(`ten_don_vi_thuc_hien`),
    `id_nguoi_thuc_hien` = VALUES(`id_nguoi_thuc_hien`),
    `nguoi_thuc_hien` = VALUES(`nguoi_thuc_hien`),
    `lanh_dao_ban_phu_trach` = VALUES(`lanh_dao_ban_phu_trach`),
    `ngay_giao` = VALUES(`ngay_giao`),
    `han_xu_ly` = VALUES(`han_xu_ly`),
    `ngay_hoan_thanh` = VALUES(`ngay_hoan_thanh`),
    `ngay_chap_nhan` = VALUES(`ngay_chap_nhan`),
    `ngay_xoa` = VALUES(`ngay_xoa`),
    `tinh_trang` = VALUES(`tinh_trang`),
    `ket_qua_thuc_hien` = VALUES(`ket_qua_thuc_hien`),
    `kho_khan_vuong_mac` = VALUES(`kho_khan_vuong_mac`),
    `de_xuat_kien_nghi` = VALUES(`de_xuat_kien_nghi`),
    `sync_date` = VALUES(`sync_date`);
