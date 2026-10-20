INSERT INTO `datamart_hanoi`.`qlnv_tonghop_tongquan_pth_ubndtp` (
    `year_key`,
    `loai_cap_cha`,
    `loai_cap`,
    `id_don_vi_cap_tren`,
    `id_don_vi`,
    `don_vi`,
    `ten_viet_tat`,
    `nguoi_tao_id`,
    `nguoi_tao_ten`,
    `kieu_van_ban`,
    `linh_vuc`,
    `vb_tong_so`,
    `vb_da_giao`,
    `vb_chua_giao`,
    `sync_date`
)
SELECT
    /* =====================================================
       CHIỀU THỜI GIAN
       ===================================================== */
    YEAR(r.StartDate)                                   AS year_key,

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

    /* ID Đơn vị trực tiếp (segment cuối cùng của path người tạo) */
    CAST(
        SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED
    )                                                   AS id_don_vi,

    /* Tên đơn vị và tên viết tắt */
    d_donvi.name                                        AS don_vi,
    COALESCE(NULLIF(d_donvi.shortname, ''), d_donvi.name) AS ten_viet_tat,

    /* =====================================================
       NGƯỜI TẠO VĂN BẢN (Từ qlnv_user theo r.CreateUser)
       ===================================================== */
    r.CreateUser                                        AS nguoi_tao_id,
    u.eGovUserFullname                                  AS nguoi_tao_ten,

    /* =====================================================
       PHÂN LOẠI VĂN BẢN & LĨNH VỰC
       ===================================================== */
    COALESCE(NULLIF(rg.Name, ''), 'Khác')               AS kieu_van_ban,
    COALESCE(NULLIF(s.SectorName, ''), 'Khác')          AS linh_vuc,

    /* =====================================================
       CÁC CHỈ SỐ THỐNG KÊ VĂN BẢN (THEO DOCCODE)
       ===================================================== */
    /* Tổng số văn bản */
    COUNT(DISTINCT r.ResolutionId)                      AS vb_tong_so,

    /* Văn bản đã giao (có DocCode khớp với Task hợp lệ) */
    COUNT(DISTINCT CASE 
        WHEN tc.doc_code IS NOT NULL THEN r.ResolutionId 
    END)                                                AS vb_da_giao,

    /* Văn bản chưa giao */
    COUNT(DISTINCT CASE 
        WHEN tc.doc_code IS NULL THEN r.ResolutionId 
    END)                                                AS vb_chua_giao,

    /* Thời điểm đồng bộ */
    NOW()                                               AS sync_date

FROM `db_theodoinv_hn`.`qlnv_resolution` r

/* Thông tin tài khoản người tạo văn bản */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
       ON u.eGovUserId = r.CreateUser

/* Nhóm / Kiểu văn bản */
LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

/* Lĩnh vực (đã chuẩn hóa kiểm tra DATETIME) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_sector` s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

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

/* Đơn vị trực tiếp (segment cuối cùng từ DepartmentPath của người tạo) */
LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(u.DepartmentPath, '.', -1) 
            AS UNSIGNED
          )
      AND d_donvi.IsDelete = 0

/* =========================================================
   SUBQUERY: TẬP HỢP CÁC DOCCODE ĐÃ PHÁT SINH NHIỆM VỤ HỢP LỆ
   ========================================================= */
LEFT JOIN
(
    SELECT DISTINCT
        TRIM(t.DocCode) AS doc_code
    FROM `db_theodoinv_hn`.`qlnv_task` t
    WHERE t.DocCode IS NOT NULL 
      AND TRIM(t.DocCode) != ''
      AND t.DeletedDate IS NULL
      AND t.Status != 5  /* Loại bỏ nhiệm vụ bị thu hồi */
      /* Bỏ qua các nhiệm vụ có tình trạng không xác định */
      AND (
          t.Status IN (-1, 0, 1, 2)
          OR (
              t.Status IN (3, 4) 
              AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
          )
      )
) tc
    ON tc.doc_code = TRIM(r.DocCode)

WHERE
    r.DeletedDate IS NULL
    /* Lọc theo cây phân cấp đơn vị của người tạo văn bản */
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
    COALESCE(NULLIF(rg.Name, ''), 'Khác'),
    COALESCE(NULLIF(s.SectorName, ''), 'Khác');