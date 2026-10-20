USE db_theodoinv_hn;

SELECT
    /* =====================================================
       CHIỀU THỜI GIAN
       ===================================================== */
    YEAR(r.StartDate) AS yearkey,

    /* =====================================================
       CẤP ĐƠN VỊ TỪ DepartmentPath CỦA NGƯỜI TẠO
       ===================================================== */
    d_capcha.name AS loaicapcha,
    d_cap.name    AS loaicap,

    /* ID Đơn vị cấp trên (phần kế cuối của Path) */
    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(u.DepartmentPath, '.', -2),
            '.',
            1
        ) AS UNSIGNED
    ) AS iddv_captren,

    /* ID Đơn vị trực tiếp (phần cuối cùng của Path) */
    CAST(
        SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED
    ) AS iddv,

    /* Tên đơn vị và tên viết tắt */
    d_donvi.name AS donvi,
    COALESCE(NULLIF(d_donvi.shortname, ''), d_donvi.name) AS tenviettat,

    /* =====================================================
       NGƯỜI TẠO VĂN BẢN
       ===================================================== */
    r.CreateUser        AS nguoitao_id,
    u.eGovUserFullname  AS nguoitao_ten,

    /* =====================================================
       PHÂN LOẠI VĂN BẢN & LĨNH VỰC
       ===================================================== */
    COALESCE(rg.Name, 'Khác')       AS Kieu,
    COALESCE(NULLIF(s.SectorName, ''), 'Khác')  AS LinhVuc,

    /* =====================================================
       CÁC CHỈ SỐ THỐNG KÊ VĂN BẢN
       ===================================================== */
    COUNT(DISTINCT r.ResolutionId) AS vb_tongso,

    COUNT(DISTINCT CASE 
        WHEN COALESCE(tc.so_nhiem_vu, 0) > 0 THEN r.ResolutionId 
    END) AS vb_da_giao,

    COUNT(DISTINCT CASE 
        WHEN COALESCE(tc.so_nhiem_vu, 0) = 0 THEN r.ResolutionId 
    END) AS vb_chua_giao,

    /* Thời gian đồng bộ / chạy dữ liệu */
    NOW() AS syncdate

FROM db_theodoinv_hn.qlnv_resolution r

/* Nhóm / Kiểu văn bản */
LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

/* Lĩnh vực */
LEFT JOIN db_theodoinv_hn.qlnv_sector s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

/* Người tạo văn bản */
LEFT JOIN db_theodoinv_hn.qlnv_user u
       ON u.eGovUserId = r.CreateUser

/* Cấp cha (segment 2) */
LEFT JOIN db_theodoinv_hn.department d_capcha
       ON d_capcha.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(u.DepartmentPath, '.', 2), '.', -1) 
            AS UNSIGNED
          )
      AND d_capcha.IsDelete = 0

/* Cấp (segment 3) */
LEFT JOIN db_theodoinv_hn.department d_cap
       ON d_cap.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(u.DepartmentPath, '.', 3), '.', -1) 
            AS UNSIGNED
          )
      AND d_cap.IsDelete = 0

/* Đơn vị trực tiếp (segment cuối) */
LEFT JOIN db_theodoinv_hn.department d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(u.DepartmentPath, '.', -1) 
            AS UNSIGNED
          )
      AND d_donvi.IsDelete = 0

/* =========================================================
   SUBQUERY: ĐẾM SỐ NHIỆM VỤ GẮN VỚI TỪNG VĂN BẢN
   ========================================================= */
LEFT JOIN
(
    SELECT
        tr.ResolutionId,
        COUNT(DISTINCT t.TaskId) AS so_nhiem_vu
    FROM db_theodoinv_hn.qlnv_task_resolution tr
    INNER JOIN db_theodoinv_hn.qlnv_task t
            ON t.TaskId = tr.TaskId
           AND t.DeletedDate IS NULL
           AND t.Status != 5  /* Bỏ qua nhiệm vụ bị thu hồi */
    GROUP BY
        tr.ResolutionId
) tc
    ON tc.ResolutionId = r.ResolutionId

WHERE
    r.DeletedDate IS NULL
    AND u.DepartmentPath LIKE '490.698.752%'

GROUP BY
    YEAR(r.StartDate),
    d_capcha.name,
    d_cap.name,
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(u.DepartmentPath, '.', -2), '.', 1) AS UNSIGNED),
    CAST(SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED),
    d_donvi.name,
    COALESCE(NULLIF(d_donvi.shortname, ''), d_donvi.name),
    r.CreateUser,
    u.eGovUserFullname,
    COALESCE(rg.Name, 'Khác'),
    COALESCE(NULLIF(s.SectorName, ''), 'Khác')

ORDER BY
    yearkey DESC,
    vb_tongso DESC;