/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_kdnv_sontay (
    /* 1. Khóa & Nhiệm vụ */
    task_id,
    ma_nhiem_vu,
    ten_nhiem_vu,
    status,

    /* 2. Văn bản & Nhóm nhiệm vụ */
    resolution_group_id,
    ten_nhom_nhiem_vu,
    resolution_id,
    so_van_ban,
    ten_van_ban,
    ngay_ban_hanh,
    thang_ban_hanh,
    nam_ban_hanh,

    /* 3. Nguồn giao & Vai trò */
    id_nguon_nhiem_vu,
    nguon_giao_nhiem_vu,
    nguon_nhiem_vu,
    vai_tro_don_vi,

    /* 4. Đơn vị và Cán bộ */
    id_don_vi_giao,
    ten_don_vi_giao,
    id_can_bo_giao,
    ten_can_bo_giao,
    id_don_vi_thuc_hien,
    ten_don_vi_thuc_hien,
    id_chuyen_vien,
    ten_chuyen_vien,

    /* 5. Tiến độ & Mốc thời gian */
    ngay_giao,
    han_xu_ly,
    ngay_hoan_thanh,
    ngay_phe_duyet,
    ngay_tao,
    ngay_xoa,

    /* 6. Tình trạng & Kết quả */
    tinh_trang,
    so_ngay_qua_han,
    tinh_hinh_ket_qua,
    sync_date
)


SELECT 
    /* 1. THÔNG TIN KHÓA & NHIỆM VỤ (TASK) */
    t.TaskId                                                AS task_id,
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    t.Status                                                AS status,

    /* 2. THÔNG TIN VĂN BẢN & NHÓM NHIỆM VỤ */
    rg.ResolutionGroupId                                    AS resolution_group_id,
    COALESCE(NULLIF(rg.Name, ''))                           AS ten_nhom_nhiem_vu,
    r.ResolutionId                                          AS resolution_id,
    COALESCE(r.DocCode, '—')         AS so_van_ban,
    COALESCE(NULLIF(r.Compendium, ''))                      AS ten_van_ban,
    DATE_FORMAT(r.StartDate, '%Y-%m-%d %H:%i:%s')       AS ngay_ban_hanh,
    DATE_FORMAT(r.StartDate, 'T%c')                     AS thang_ban_hanh,
    YEAR(r.StartDate)                                       AS nam_ban_hanh,

    /* 3. NGUỒN GIAO & VAI TRÒ ĐƠN VỊ */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_nguon_nhiem_vu,
    COALESCE(d_assign_cap2.name)           AS nguon_giao_nhiem_vu,
    NULL                                                    AS nguon_nhiem_vu,
    CASE 
        WHEN t.ParentId IS NULL OR t.ParentId = 0     THEN 'Chủ trì'
        ELSE 'Phối hợp'
    END                                                     AS vai_tro_don_vi,

    /* 4. ĐƠN VỊ VÀ CÁN BỘ GIAO / NHẬN */
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign.name) AS ten_don_vi_giao,
    t.AssignUser                                            AS id_can_bo_giao,
    u_assign.eGovUserFullname                               AS ten_can_bo_giao,

    t.TargetDepartment                                      AS id_don_vi_thuc_hien,
    COALESCE(
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        d_target.name
    )                                                       AS ten_don_vi_thuc_hien,
    t.TargetUser                                            AS id_chuyen_vien,
    u_target.eGovUserFullname                               AS ten_chuyen_vien,

    /* 5. TIẾN ĐỘ & CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%Y-%m-%d %H:%i:%s')     AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%Y-%m-%d %H:%i:%s')      AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%Y-%m-%d %H:%i:%s')   AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%Y-%m-%d %H:%i:%s')    AS ngay_phe_duyet,
    DATE_FORMAT(t.CreatedDate, '%Y-%m-%d %H:%i:%s')     AS ngay_tao,
    DATE_FORMAT(t.DeletedDate, '%Y-%m-%d %H:%i:%s')     AS ngay_xoa,

    /* 6. PHÂN LOẠI TÌNH TRẠNG & SỐ NGÀY QUÁ HẠN */
    CASE
        WHEN t.ExpireDate IS NULL 
        THEN 'Thường xuyên'

        WHEN t.Status IN (3, 4) 
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL 
        THEN 'Đã hoàn thành'

        WHEN t.Status IN (-1, 0, 1, 2) 
             AND t.ExpireDate IS NOT NULL 
             AND DATE(t.ExpireDate) >= CURDATE() 
        THEN 'Đang TH trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2) 
             AND t.ExpireDate IS NOT NULL 
             AND DATE(t.ExpireDate) < CURDATE() 
        THEN 'Đang TH quá hạn'

        ELSE 'Chưa xác định'
    END                                                     AS tinh_trang,

    CASE 
        WHEN t.Status IN (-1, 0, 1, 2) 
             AND t.ExpireDate IS NOT NULL 
             AND DATE(t.ExpireDate) < CURDATE() 
        THEN DATEDIFF(CURDATE(), DATE(t.ExpireDate))
        ELSE 0 
    END                                                     AS so_ngay_qua_han,

    COALESCE(
        (
            SELECT rp.Content 
            FROM db_theodoinv_hn.qlnv_report rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC 
            LIMIT 1
        ),
        t.Content
    )                                                       AS tinh_hinh_ket_qua,

    '${sync_ts}' AS sync_date

FROM db_theodoinv_hn.qlnv_task t

/* Ghép văn bản / nghị quyết */
LEFT JOIN db_theodoinv_hn.qlnv_resolution r
       ON r.ResolutionId = t.ResolutionId
      AND r.DeletedDate IS NULL

/* Ghép nhóm văn bản */
LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

/* Tên đơn vị cấp 2 trục giao */
LEFT JOIN db_theodoinv_hn.department d_assign_cap2
       ON d_assign_cap2.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) 
            AS UNSIGNED
          )
      AND d_assign_cap2.IsDelete = 0

/* Tên phòng ban giao */
LEFT JOIN db_theodoinv_hn.department d_assign
       ON d_assign.id = CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
      AND d_assign.IsDelete = 0

/* Tên phòng ban nhận */
LEFT JOIN db_theodoinv_hn.department d_target
       ON d_target.id = CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
      AND d_target.IsDelete = 0

/* Ghép user */
LEFT JOIN db_theodoinv_hn.qlnv_user u_assign 
       ON u_assign.eGovUserId = t.AssignUser

LEFT JOIN db_theodoinv_hn.qlnv_user u_target 
       ON u_target.eGovUserId = t.TargetUser

WHERE 
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        /* TH1: AssignDepartment = '490.698.1310.1496' giao đi */
        t.AssignDepartment = '490.698.1310.1496'

        OR

        /* TH2: Trục khác giao sang (Nhận) */
        (
            /* Giao trực tiếp */
            t.TargetDepartment = '490.698.1310.1496'

            OR

            /* Giao cấp con -> check log trong qlnv_task_user */
            (
                t.TargetDepartment LIKE '490.698.1310.1496.%'
                AND EXISTS (
                    SELECT 1
                    FROM db_theodoinv_hn.qlnv_task_user tu
                    WHERE tu.TaskId = t.TaskId
                      AND tu.DepartmentId = '490.698.1310.1496'
                )
            )
        )
    )
ON DUPLICATE KEY UPDATE
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `ten_nhiem_vu` = VALUES(`ten_nhiem_vu`),
    `status` = VALUES(`status`),
    `resolution_group_id` = VALUES(`resolution_group_id`),
    `ten_nhom_nhiem_vu` = VALUES(`ten_nhom_nhiem_vu`),
    `resolution_id` = VALUES(`resolution_id`),
    `so_van_ban` = VALUES(`so_van_ban`),
    `ten_van_ban` = VALUES(`ten_van_ban`),
    `ngay_ban_hanh` = VALUES(`ngay_ban_hanh`),
    `thang_ban_hanh` = VALUES(`thang_ban_hanh`),
    `nam_ban_hanh` = VALUES(`nam_ban_hanh`),
    `id_nguon_nhiem_vu` = VALUES(`id_nguon_nhiem_vu`),
    `nguon_giao_nhiem_vu` = VALUES(`nguon_giao_nhiem_vu`),
    `nguon_nhiem_vu` = VALUES(`nguon_nhiem_vu`),
    `vai_tro_don_vi` = VALUES(`vai_tro_don_vi`),
    `id_don_vi_giao` = VALUES(`id_don_vi_giao`),
    `ten_don_vi_giao` = VALUES(`ten_don_vi_giao`),
    `id_can_bo_giao` = VALUES(`id_can_bo_giao`),
    `ten_can_bo_giao` = VALUES(`ten_can_bo_giao`),
    `id_don_vi_thuc_hien` = VALUES(`id_don_vi_thuc_hien`),
    `ten_don_vi_thuc_hien` = VALUES(`ten_don_vi_thuc_hien`),
    `id_chuyen_vien` = VALUES(`id_chuyen_vien`),
    `ten_chuyen_vien` = VALUES(`ten_chuyen_vien`),
    `ngay_giao` = VALUES(`ngay_giao`),
    `han_xu_ly` = VALUES(`han_xu_ly`),
    `ngay_hoan_thanh` = VALUES(`ngay_hoan_thanh`),
    `ngay_phe_duyet` = VALUES(`ngay_phe_duyet`),
    `ngay_tao` = VALUES(`ngay_tao`),
    `ngay_xoa` = VALUES(`ngay_xoa`),
    `tinh_trang` = VALUES(`tinh_trang`),
    `so_ngay_qua_han` = VALUES(`so_ngay_qua_han`),
    `tinh_hinh_ket_qua` = VALUES(`tinh_hinh_ket_qua`),
    `sync_date` = VALUES(`sync_date`);
