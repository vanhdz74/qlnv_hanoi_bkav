SELECT
    b.task_id,
    b.ben_giao_id,

    /* 1. LẤY TÊN BÊN GIAO (SO SÁNH BẰNG CHAR ĐỂ TRÁNH ÉP KIỂU SỐ) */
    (
        SELECT d.name 
        FROM db_theodoinv_hn.department d 
        WHERE CAST(d.id AS CHAR) = SUBSTRING_INDEX(b.ben_giao_id, '.', -1)
          AND d.IsDelete = 0 
        LIMIT 1
    ) AS ben_giao_name,

    b.final_ben_nhan_id AS ben_nhan_id,

    /* 2. LẤY TÊN BÊN NHẬN (SO SÁNH BẰNG CHAR) */
    (
        SELECT d.name 
        FROM db_theodoinv_hn.department d 
        WHERE CAST(d.id AS CHAR) = SUBSTRING_INDEX(b.final_ben_nhan_id, '.', -1)
          AND d.IsDelete = 0 
        LIMIT 1
    ) AS ben_nhan_name,

    b.loai_nhiem_vu,
    b.hinh_thuc_giao,
    rv.cap_giao_nhiem_vu,
    CAST(NULL AS CHAR(255)) AS lanh_dao_giao,
    b.ngay_bat_dau,
    b.ngay_het_han,
    b.ngay_hoan_thanh,
    b.nam_het_han,
    b.thang_het_han,
    b.tinh_trang

FROM (
    SELECT
        t.TaskId AS task_id,
        t.AssignDepartment AS ben_giao_id,

        /* PHÂN LOẠI NHIỆM VỤ */
        CASE
            WHEN (t.AssignDepartment = '490.695.1558.1814' OR t.AssignDepartment = '490.695.1558.1814.1815')
                 AND t.OriginalTargetDepartment LIKE '490.698%'
                 AND t.AssignDepartment <> t.OriginalTargetDepartment
            THEN 'Nhiệm vụ giao'

            WHEN t.AssignDepartment LIKE '490.695%' 
                 AND (t.OriginalTargetDepartment IN ('490.695.1558.1814', '490.695.1558.1814.1815') OR t.OriginalTargetDepartment LIKE '490.698%')
            THEN 'Nhiệm vụ nhận'

            ELSE NULL
        END AS loai_nhiem_vu,

        /* HÌNH THỨC GIAO */
        CASE
            WHEN t.AssignDepartment LIKE '490.695%' THEN
                CASE
                    WHEN t.OriginalTargetDepartment IN ('490.695.1558.1814', '490.695.1558.1814.1815') 
                    THEN 'Giao qua Đảng ủy UBND'

                    WHEN t.OriginalTargetDepartment LIKE '490.698%' THEN
                        CASE 
                            WHEN tu_check.has_user_dept = 1 THEN 'Giao qua Đảng ủy UBND'
                            ELSE 'Không qua Đảng ủy UBND'
                        END
                    ELSE NULL
                END
            ELSE NULL
        END AS hinh_thuc_giao,

        /* CHUẨN HÓA BÊN NHẬN ID */
        CASE 
            WHEN (t.AssignDepartment = '490.695.1558.1814' OR t.AssignDepartment = '490.695.1558.1814.1815')
                 AND t.OriginalTargetDepartment LIKE '490.698%'
                 AND t.AssignDepartment <> t.OriginalTargetDepartment THEN
                CASE
                    WHEN (CHAR_LENGTH(t.OriginalTargetDepartment) - CHAR_LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)

                    WHEN t.OriginalTargetDepartment NOT LIKE '490.698.1307%' 
                         AND t.OriginalTargetDepartment NOT LIKE '490.698.1310%'
                         AND t.OriginalTargetDepartment NOT LIKE '490.698.1841%'
                         AND (CHAR_LENGTH(t.OriginalTargetDepartment) - CHAR_LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) = 3
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 3)

                    ELSE t.OriginalTargetDepartment
                END
            ELSE t.OriginalTargetDepartment
        END AS final_ben_nhan_id,

        t.StartedDate AS ngay_bat_dau,
        t.ExpireDate AS ngay_het_han,
        t.CompletedDate AS ngay_hoan_thanh,
        YEAR(t.ExpireDate) AS nam_het_han,
        MONTH(t.ExpireDate) AS thang_het_han,

        /* TÌNH TRẠNG */
        CASE
            WHEN COALESCE(t.IsRecurring, 0) = 1 AND t.Status IN (3, 4) 
                THEN 'Thường xuyên - Đã báo cáo'
            WHEN COALESCE(t.IsRecurring, 0) = 1 AND t.Status IN (-1, 0, 1, 2) 
                THEN 'Thường xuyên - Chưa báo cáo'

            WHEN COALESCE(t.IsRecurring, 0) = 0 AND t.Status IN (3, 4)
                 AND (
                     t.ExpireDate IS NULL 
                     OR DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
                 )
                THEN 'Hoàn thành đúng hạn'

            WHEN COALESCE(t.IsRecurring, 0) = 0 AND t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL 
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) > DATE(t.ExpireDate)
                THEN 'Hoàn thành quá hạn'

            WHEN COALESCE(t.IsRecurring, 0) = 0 AND t.Status IN (-1, 0, 1, 2)
                 AND (t.ExpireDate IS NULL OR DATE(t.ExpireDate) >= CURDATE())
                THEN 'Đang thực hiện trong hạn'

            WHEN COALESCE(t.IsRecurring, 0) = 0 AND t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL 
                 AND DATE(t.ExpireDate) < CURDATE()
                THEN 'Đang thực hiện quá hạn'

            ELSE 'Chưa xác định'
        END AS tinh_trang

    FROM db_theodoinv_hn.qlnv_task t

    /* CHECK LOG TASK_USER */
    LEFT JOIN (
        SELECT tu.TaskId, 1 AS has_user_dept
        FROM db_theodoinv_hn.qlnv_task_user tu
        WHERE tu.DepartmentId IN ('490.695.1558.1814', '490.695.1558.1814.1815')
        GROUP BY tu.TaskId
    ) tu_check 
        ON tu_check.TaskId = t.TaskId

    WHERE t.DeletedDate IS NULL
      AND (t.Status IS NULL OR t.Status <> 5)
      AND t.OriginalTargetDepartment NOT IN ('490.698.1307', '490.698.1310', '490.698.1841')
      AND (
          /* Luồng Giao: từ 1814/1815 sang 490.698% */
          (
              (t.AssignDepartment = '490.695.1558.1814' OR t.AssignDepartment = '490.695.1558.1814.1815')
              AND t.OriginalTargetDepartment LIKE '490.698%'
              AND t.AssignDepartment <> t.OriginalTargetDepartment
          )
          OR
          /* Luồng Nhận: từ 490.695% về 1814/1815 hoặc sang 490.698% */
          (
              t.AssignDepartment LIKE '490.695%' 
              AND (t.OriginalTargetDepartment IN ('490.695.1558.1814', '490.695.1558.1814.1815') OR t.OriginalTargetDepartment LIKE '490.698%')
          )
      )
) b

/* CẤP GIAO NHIỆM VỤ */
LEFT JOIN (
    SELECT
        tr.TaskId,
        GROUP_CONCAT(
            DISTINCT NULLIF(r.AssignOrganizationName, '') 
            ORDER BY r.ResolutionId 
            SEPARATOR ' | '
        ) AS cap_giao_nhiem_vu
    FROM db_theodoinv_hn.qlnv_task_resolution tr
    INNER JOIN db_theodoinv_hn.qlnv_resolution r 
        ON r.ResolutionId = tr.ResolutionId
    WHERE r.DeletedDate IS NULL
    GROUP BY tr.TaskId
) rv 
    ON rv.TaskId = b.task_id

WHERE b.loai_nhiem_vu IS NOT NULL
  AND b.tinh_trang <> 'Chưa xác định';