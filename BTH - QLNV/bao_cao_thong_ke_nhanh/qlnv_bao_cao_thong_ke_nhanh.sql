
SELECT
    CAST(t.TaskId AS SIGNED)                                        AS task_id,
    t.Code                                                          AS ma_nhiem_vu,

    /* 1. CÂY PHÂN CẤP ĐƠN VỊ NHẬN & ĐƠN VỊ GIAO */
    t.TargetDepartment                                              AS ma_don_vi,
    NULLIF(d_nhan.name, '')                                         AS ten_don_vi,
    NULLIF(
        SUBSTRING_INDEX(t.TargetDepartment, '.', 
        LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))), 
        ''
    )                                                               AS ma_don_vi_cha,
    CONCAT(t.TargetDepartment, '.')                                 AS path_don_vi,
    COALESCE(NULLIF(d_nhan.DeptFullName, ''), d_nhan.name)          AS path_ten_don_vi,
    (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', '')) + 1) AS cap_don_vi,
    COALESCE(d_nhan.sort_order, d_nhan.id, 0)                       AS thu_tu_don_vi,

    IF(d_truc.id IS NULL, NULL, SUBSTRING_INDEX(t.TargetDepartment, '.', 2)) AS id_truc,
    NULLIF(d_truc.name, '')                                         AS ten_truc,

    t.AssignDepartment                                              AS ma_doi_tac,
    NULLIF(d_giao.name, '')                                         AS ten_doi_tac,
    CONCAT(t.AssignDepartment, '.')                                 AS path_doi_tac,

    /* 2. NỘI DUNG & PHÂN LOẠI */
    t.Title                                                         AS ten_nhiem_vu,
    CAST(LEFT(t.Content, 500) AS CHAR(500))                         AS trich_yeu_nhiem_vu,
    COALESCE(NULLIF(TRIM(t.Sector), ''), 'Khác')                    AS linh_vuc,
    CASE t.Priority
        WHEN 3 THEN 'Hỏa tốc'
        WHEN 2 THEN 'Thượng khẩn'
        WHEN 1 THEN 'Khẩn'
        ELSE 'Thường'
    END                                                             AS do_khan,
    CASE t.SourceId
        WHEN 0 THEN 'Chỉ đạo bằng văn bản'
        WHEN 1 THEN 'Chỉ đạo trực tiếp'
        ELSE 'Khác'
    END                                                             AS loai_chi_dao,

    /* 3. VĂN BẢN GIAO */
    COALESCE(NULLIF(t.DocCode, ''), NULLIF(r.DocCode, ''))          AS vb_so_hieu,
    NULLIF(
        SUBSTRING_INDEX(COALESCE(NULLIF(t.DocCode, ''), NULLIF(r.DocCode, '')), '/', -1),
        COALESCE(NULLIF(t.DocCode, ''), NULLIF(r.DocCode, ''))
    )                                                               AS vb_ky_hieu,
    COALESCE(NULLIF(t.Compendium, ''), NULLIF(r.Compendium, ''))    AS vb_trich_yeu,
    DATE(r.StartDate)                                               AS vb_ngay_ban_hanh,
    null 				                                            AS vb_phan_loai,
    NULLIF(r.AssignOrganization, '')                                AS vb_ma_co_quan_ban_hanh,
    NULLIF(r.AssignOrganizationName, '')                            AS vb_ten_co_quan_ban_hanh,

    /* 4. CON NGƯỜI & ĐƠN VỊ THỰC HIỆN */
    t.AssignDepartment                                              AS ma_dv_giao,
    NULLIF(d_giao.name, '')                                         AS ten_dv_giao,
    CONCAT(t.AssignDepartment, '.')                                 AS path_dv_giao,
    (
        SELECT NULLIF(u.eGovUserFullname, '') 
        FROM `db_theodoinv_hn`.`qlnv_user` u
        WHERE u.eGovUserId = t.AssignUser 
        LIMIT 1
    )                                                               AS nguoi_giao,

    t.TargetDepartment                                              AS ma_dv_nhan,
    NULLIF(d_nhan.name, '')                                         AS ten_dv_nhan,
    t.TargetDepartment                                              AS ma_dv_chu_tri,
    NULLIF(d_nhan.name, '')                                         AS ten_dv_chu_tri,
    CONCAT(t.TargetDepartment, '.')                                 AS path_dv_chu_tri,

    COALESCE(
        (SELECT NULLIF(u.eGovUserFullname, '') FROM `db_theodoinv_hn`.`qlnv_user` u WHERE u.eGovUserId = t.TargetUser LIMIT 1),
        NULLIF(t.ChargeUser, '')
    )                                                               AS nguoi_nhan,

    COALESCE(
        (
            SELECT GROUP_CONCAT(DISTINCT NULLIF(TRIM(tu_u.eGovUserFullname), '') SEPARATOR '; ')
            FROM `db_theodoinv_hn`.`qlnv_task_user` tu
            INNER JOIN `db_theodoinv_hn`.`qlnv_user` tu_u ON tu_u.eGovUserId = tu.UserId
            WHERE tu.TaskId = t.TaskId AND tu.Role = 1
        ),
        NULLIF(t.ChargeUser, ''),
        (SELECT NULLIF(u.eGovUserFullname, '') FROM `db_theodoinv_hn`.`qlnv_user` u WHERE u.eGovUserId = t.TargetUser LIMIT 1)
    )                                                               AS nguoi_chu_tri,

    (
        SELECT GROUP_CONCAT(DISTINCT NULLIF(d.name, '') SEPARATOR '; ')
        FROM `db_theodoinv_hn`.`qlnv_combination` c2
        INNER JOIN `db_theodoinv_hn`.`department` d
               ON d.id = CASE 
                            WHEN SUBSTRING_INDEX(c2.TargetDepartment, '.', -1) REGEXP '^[0-9]+$' 
                            THEN CAST(SUBSTRING_INDEX(c2.TargetDepartment, '.', -1) AS UNSIGNED) 
                            ELSE NULL 
                         END
              AND COALESCE(d.IsDelete, 0) <> 1
        WHERE c2.TaskId = t.TaskId
          AND c2.DeletedDate IS NULL
          AND NULLIF(c2.TargetDepartment, '') IS NOT NULL
    )                                                               AS ds_ten_dv_phoi_hop,

    CASE
        WHEN t.Status IN (3, 4) THEN NULL
        WHEN (t.Status < 3 AND EXISTS (
            SELECT 1
            FROM `db_theodoinv_hn`.`qlnv_report` rp
            WHERE rp.TaskId = t.TaskId
              AND rp.DeletedDate IS NULL
              AND rp.Type IN (1, 2, 3, 4)
              AND rp.Status = 0
              AND (rp.ApprovedUser = t.CreateUser OR rp.ApprovedUser = t.AssignUser)
        )) THEN NULLIF(d_giao.name, '')
        ELSE NULLIF(d_nhan.name, '')
    END                                                             AS ten_dv_dang_xu_ly,

    (
        SELECT NULLIF(u.DepartmentPath, '')
        FROM `db_theodoinv_hn`.`qlnv_user` u
        INNER JOIN `db_theodoinv_hn`.`department` d
               ON d.id = CASE 
                            WHEN SUBSTRING_INDEX(u.DepartmentPath, '.', -1) REGEXP '^[0-9]+$' 
                            THEN CAST(SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED) 
                            ELSE NULL 
                         END
              AND COALESCE(d.IsDelete, 0) <> 1
        WHERE u.eGovUserId = t.CreateUser 
        LIMIT 1
    )                                                               AS ma_phong_theo_doi,
    (
        SELECT NULLIF(d.name, '')
        FROM `db_theodoinv_hn`.`qlnv_user` u
        INNER JOIN `db_theodoinv_hn`.`department` d
               ON d.id = CASE 
                            WHEN SUBSTRING_INDEX(u.DepartmentPath, '.', -1) REGEXP '^[0-9]+$' 
                            THEN CAST(SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED) 
                            ELSE NULL 
                         END
              AND COALESCE(d.IsDelete, 0) <> 1
        WHERE u.eGovUserId = t.CreateUser 
        LIMIT 1
    )                                                               AS ten_phong_theo_doi,

    /* 5. THỜI GIAN, TIẾN ĐỘ & TRẠNG THÁI */
    DATE(t.CreatedDate)                                             AS ngay_tao,
    DATE(t.ExpireDate)                                              AS han_xu_ly,
    DATE(COALESCE(t.CompletedDate, t.ApprovedDate))                 AS ngay_hoan_thanh,

    CASE
        WHEN t.ExpireDate IS NULL THEN 'thuong_xuyen'
        WHEN t.Status IN (3, 4)
             AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate) THEN 'ht_dung_han'
        WHEN t.Status IN (3, 4)                                                          THEN 'ht_qua_han'
        WHEN DATE(t.ExpireDate) >= CURDATE()                                             THEN 'dth_trong_han'
        ELSE                                                                                  'dth_qua_han'
    END                                                             AS trang_thai,
    CASE
        WHEN t.ExpireDate IS NULL THEN 'Thường xuyên'
        WHEN t.Status IN (3, 4)
             AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate) THEN 'HT đúng hạn'
        WHEN t.Status IN (3, 4)                                                          THEN 'HT quá hạn'
        WHEN DATE(t.ExpireDate) >= CURDATE()                                             THEN 'ĐTH trong hạn'
        ELSE                                                                                  'ĐTH quá hạn'
    END                                                             AS ten_trang_thai,

    IF(t.Status IN (3, 4), 1, 0)                                    AS la_hoan_thanh,
    IF(
        t.ExpireDate IS NOT NULL AND (
            (t.Status IN (3, 4) AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) > DATE(t.ExpireDate))
            OR (t.Status NOT IN (3, 4) AND DATE(t.ExpireDate) < CURDATE())
        ), 1, 0
    )                                                               AS la_qua_han,
    IF(t.ExpireDate IS NULL, 1, 0)                                  AS la_thuong_xuyen,
    CASE
        WHEN t.ExpireDate IS NULL THEN 0
        WHEN t.Status IN (3, 4)
        THEN GREATEST(DATEDIFF(COALESCE(t.CompletedDate, t.ApprovedDate), t.ExpireDate), 0)
        ELSE GREATEST(DATEDIFF(CURDATE(), t.ExpireDate), 0)
    END                                                             AS so_ngay_qua_han,
    IF(t.Status IN (3, 4), 100, COALESCE(t.Progress, 0))             AS tien_do_pct,

    IF((
        t.Status < 3 AND EXISTS (
            SELECT 1
            FROM `db_theodoinv_hn`.`qlnv_report` rp
            WHERE rp.TaskId = t.TaskId
              AND rp.DeletedDate IS NULL
              AND rp.Type IN (1, 2, 3, 4)
              AND rp.Status = 0
              AND (rp.ApprovedUser = t.CreateUser OR rp.ApprovedUser = t.AssignUser)
        )
    ), 1, 0)                                                        AS la_cho_duyet,
    IF(COALESCE(t.isFocus, 0) > 0, 1, 0)                            AS la_quan_tam,
    IF(COALESCE(NULLIF(t.DocCode, ''), r.DocCode, '') LIKE '%BCĐ%', 1, 0) AS la_ban_chi_dao,

    /* 6. BÁO CÁO TIẾN ĐỘ GẦN NHẤT: KẾT QUẢ, KHÓ KHĂN & ĐỀ XUẤT KIẾN NGHỊ */
    COALESCE(rp_last.Content, t.Content, '—')                       AS tinh_hinh_ket_qua,
    COALESCE(NULLIF(rp_last.Difficulty, ''), '—')                   AS kho_khan_vuong_mac,
    COALESCE(NULLIF(rp_last.Suggestion, ''), '—')                   AS de_xuat_kien_nghi,

    /* 7. KIỂM SOÁT ĐỒNG BỘ */
    CURDATE()                                                       AS ngay_chot_so_lieu,
    NOW()                                                           AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN BÁO CÁO MỚI NHẤT CỦA MỖI TASK QUA MAX(ReportId) */
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

/* JOIN ĐƠN VỊ GIAO (AssignDepartment) */
LEFT JOIN `db_theodoinv_hn`.`department` d_giao
       ON d_giao.id = CASE 
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$' 
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED) 
            ELSE NULL 
          END
      AND COALESCE(d_giao.IsDelete, 0) <> 1

/* JOIN ĐƠN VỊ NHẬN (TargetDepartment) */
LEFT JOIN `db_theodoinv_hn`.`department` d_nhan
       ON d_nhan.id = CASE 
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$' 
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED) 
            ELSE NULL 
          END
      AND COALESCE(d_nhan.IsDelete, 0) <> 1

/* JOIN TRỤC CẤP 2 CỦA ĐƠN VỊ NHẬN */
LEFT JOIN `db_theodoinv_hn`.`department` d_truc
       ON d_truc.id = CASE 
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL 
          END
      AND COALESCE(d_truc.IsDelete, 0) <> 1

/* JOIN VĂN BẢN THEO ResolutionId CỦA TASK */
LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution` r
       ON r.ResolutionId = t.ResolutionId
      AND r.DeletedDate IS NULL

LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

WHERE t.DeletedDate IS NULL
  /* Chỉ tính task có đơn vị nhận & đơn vị giao còn tồn tại, IsDelete <> 1 */
  AND d_nhan.id IS NOT NULL
  AND d_giao.id IS NOT NULL
  AND t.Status <> 5
  AND (
      t.Status IN (-1, 0, 1, 2)
      OR (
          t.Status IN (3, 4)
          AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
      )
  );