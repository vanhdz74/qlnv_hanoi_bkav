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
    t.DocCode                                               AS van_ban_giao,
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
       4. PHÒNG BAN GIAO & CÁN BỘ GIAO
       ===================================================== */
    COALESCE(
        NULLIF(t.AssignOrganization, ''),
        d_assign.name
    )                                                       AS phong_ban_giao,
    u_assign.eGovUserFullname                               AS can_bo_giao,

    /* =====================================================
       5. ĐƠN VỊ CHỦ TRÌ & ĐƠN VỊ THỰC HIỆN
       ===================================================== */
    COALESCE(
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        d_cap.name,
        d_donvi.name
    )                                                       AS don_vi_chu_tri,
    d_donvi.name                                            AS don_vi_thuc_hien,

    /* =====================================================
       6. NGƯỜI THỰC HIỆN
       ===================================================== */
    u_target.eGovUserFullname                               AS nguoi_thuc_hien,

    /* Thời điểm đồng bộ */
    NOW()                                                   AS sync_date

FROM db_theodoinv_hn.qlnv_task t

/* =========================================================
   SUBQUERY LỌC NHIỆM VỤ CÓ BÁO CÁO CHỜ DUYỆT TỪ qlnv_report
   ========================================================= */
INNER JOIN (
    SELECT 
        rp.TaskId
    FROM db_theodoinv_hn.qlnv_report rp
    INNER JOIN db_theodoinv_hn.qlnv_task t_sub 
            ON rp.TaskId = t_sub.TaskId
    WHERE rp.DeletedDate IS NULL
      AND rp.Type IN (1, 2, 3, 4)
      AND rp.Status = 0
      AND t_sub.Status < 3
      AND t_sub.CreateUser = rp.ApprovedUser
    GROUP BY rp.TaskId
) rp_wait 
    ON rp_wait.TaskId = t.TaskId

/* JOIN DANH MỤC PHÒNG BAN GIAO */
LEFT JOIN db_theodoinv_hn.department d_assign
       ON d_assign.id = CAST(
            SUBSTRING_INDEX(t.AssignDepartment, '.', -1) 
            AS UNSIGNED
          ) AND d_assign.IsDelete = 0

/* JOIN CẤP ĐƠN VỊ THỤ LÝ (CẤP 3/4) */
LEFT JOIN db_theodoinv_hn.department d_cap
       ON d_cap.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) 
            AS UNSIGNED
          ) AND d_cap.IsDelete = 0

/* JOIN ĐƠN VỊ/PHÒNG BAN THỰC HIỆN TRỰC TIẾP */
LEFT JOIN db_theodoinv_hn.department d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(t.TargetDepartment, '.', -1) 
            AS UNSIGNED
          ) AND d_donvi.IsDelete = 0

/* JOIN USER LẤY TÊN CÁN BỘ GIAO VÀ NGƯỜI THỰC HIỆN */
LEFT JOIN db_theodoinv_hn.qlnv_user u_assign
       ON u_assign.eGovUserId = t.AssignUser

LEFT JOIN db_theodoinv_hn.qlnv_user u_target
       ON u_target.eGovUserId = t.TargetUser

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5;