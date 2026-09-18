INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitietvb_pth_ubndtp` (
    `year_key`,
    `resolution_id`,
    `resolution_group_id`,
    `compendium`,
    `doc_code`,
    `kieu_van_ban`,
    `linh_vuc`,
    `ngay_van_ban`,
    `co_quan_ban_hanh`,
    `loai_cap_cha`,
    `loai_cap`,
    `id_don_vi_cap_tren`,
    `id_don_vi`,
    `don_vi`,
    `ten_viet_tat`,
    `nguoi_tao_id`,
    `nguoi_tao_tai_khoan`,
    `nguoi_tao_ten`,
    `so_nhiem_vu`,
    `sync_date`
)

SELECT
    /* =====================================================
       CHIỀU THỜI GIAN
       ===================================================== */
    YEAR(r.StartDate)                                   AS year_key,

    /* =====================================================
       VĂN BẢN / NGHỊ QUYẾT
       ===================================================== */
    r.ResolutionId                                      AS resolution_id,
    r.ResolutionGroupId                                 AS resolution_group_id,
    r.Compendium                                        AS compendium,
    r.DocCode                                           AS doc_code,

    /* =====================================================
       KIỂU VĂN BẢN / LĨNH VỰC
       ===================================================== */
    COALESCE(NULLIF(rg.Name, ''), 'Khác')               AS kieu_van_ban,
    COALESCE(NULLIF(s.SectorName, ''), 'Khác')          AS linh_vuc,

    /* =====================================================
       NGÀY VĂN BẢN (dd/mm/yyyy)
       ===================================================== */
    DATE_FORMAT(r.StartDate, '%d/%m/%Y')                AS ngay_van_ban,

    /* =====================================================
       CƠ QUAN BAN HÀNH
       ===================================================== */
    COALESCE(
        NULLIF(r.AssignOrganizationName, ''),
        NULLIF(r.AssignOrganization, '')
    )                                                   AS co_quan_ban_hanh,

    /* =====================================================
       CẤP ĐƠN VỊ TỪ DepartmentPath CỦA NGƯỜI TẠO (u.DepartmentPath)
       ===================================================== */
    d_capcha.name                                       AS loai_cap_cha,
    d_cap.name                                          AS loai_cap,

    /* ID Đơn vị cấp trên (segment kế cuối của path người tạo) */
    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(u.DepartmentPath, '.', -2),
            '.',
            1
        ) AS UNSIGNED
    )                                                   AS id_don_vi_cap_tren,

    /* ID Đơn vị trực tiếp: Cấp 5 lùi về lấy ID cấp 4, còn lại lấy cấp cuối */
    CAST(
        SUBSTRING_INDEX(
            CASE 
                WHEN (LENGTH(u.DepartmentPath) - LENGTH(REPLACE(u.DepartmentPath, '.', ''))) >= 4 
                THEN SUBSTRING_INDEX(u.DepartmentPath, '.', 4)
                ELSE u.DepartmentPath 
            END,
            '.',
            -1
        ) AS UNSIGNED
    )                                                   AS id_don_vi,

    /* Tên đơn vị và tên viết tắt (Tự động ăn theo cấp 4 khi là cấp 5) */
    d_donvi.name                                        AS don_vi,
    COALESCE(NULLIF(d_donvi.shortname, ''), d_donvi.name) AS ten_viet_tat,

    /* =====================================================
       NGƯỜI TẠO VĂN BẢN (Từ qlnv_user theo r.CreateUser)
       ===================================================== */
    r.CreateUser                                        AS nguoi_tao_id,
    u.UserName                                          AS nguoi_tao_tai_khoan,
    u.eGovUserFullname                                  AS nguoi_tao_ten,

    /* =====================================================
       SỐ NHIỆM VỤ GẮN VỚI VĂN BẢN (ĐẾM TRỰC TIẾP TỪ qlnv_task)
       ===================================================== */
    COALESCE(tc.so_nhiem_vu, 0)                         AS so_nhiem_vu,

    /* Thời điểm đồng bộ */
    NOW()                                               AS sync_date

FROM `db_theodoinv_hn`.`qlnv_resolution` r

/* Nhóm / Kiểu văn bản */
LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

/* Lĩnh vực (Chỉ cần IS NULL vì DeletedDate là kiểu DATETIME) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_sector` s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL

/* Thông tin tài khoản người tạo văn bản */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
       ON u.eGovUserId = r.CreateUser

/* Cấp cha (segment 2 từ DepartmentPath của người tạo) */
LEFT JOIN `db_theodoinv_hn`.`department` d_capcha
       ON d_capcha.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(u.DepartmentPath, '.', 2), '.', -1) 
            AS UNSIGNED
          )
      AND d_capcha.IsDelete = 0

/* Cấp (segment 3 từ DepartmentPath của người tạo) */
LEFT JOIN `db_theodoinv_hn`.`department` d_cap
       ON d_cap.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(u.DepartmentPath, '.', 3), '.', -1) 
            AS UNSIGNED
          )
      AND d_cap.IsDelete = 0

/* Đơn vị trực tiếp: Cấp 5 lùi về Map với danh mục Cấp 4 */
LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(
                CASE 
                    WHEN (LENGTH(u.DepartmentPath) - LENGTH(REPLACE(u.DepartmentPath, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(u.DepartmentPath, '.', 4)
                    ELSE u.DepartmentPath 
                END,
                '.',
                -1
            ) AS UNSIGNED
          )
      AND d_donvi.IsDelete = 0

/* =========================================================
   SUBQUERY: ĐẾM NHIỆM VỤ THEO ResolutionId VÀ LỌC TÌNH TRẠNG XÁC ĐỊNH
   ========================================================= */
LEFT JOIN
(
    SELECT
        t.ResolutionId,
        COUNT(DISTINCT t.TaskId) AS so_nhiem_vu
    FROM `db_theodoinv_hn`.`qlnv_task` t
    WHERE t.ResolutionId IS NOT NULL 
      AND t.ResolutionId > 0
      AND t.DeletedDate IS NULL
      AND t.Status != 5  /* Bỏ qua nhiệm vụ thu hồi */
      /* Chỉ lấy nhiệm vụ có tình trạng xác định rõ ràng */
      AND (
          t.Status IN (-1, 0, 1, 2)
          OR (
              t.Status IN (3, 4) 
              AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
          )
      )
    GROUP BY
        t.ResolutionId
) tc
    ON tc.ResolutionId = r.ResolutionId

WHERE
    r.DeletedDate IS NULL
    /* Lọc theo cây phân cấp đơn vị của người tạo văn bản */
    AND u.DepartmentPath LIKE '490.698.752%';