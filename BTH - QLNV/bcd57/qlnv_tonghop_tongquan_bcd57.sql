INSERT INTO datamart_hanoi.qlnv_tonghop_tongquan_bcd57
(
    resolution_group_id,
    resolution_id,
    resolution_doc_code,
    resolution_name,
    task_resolution_id,
    task_id,
    parent_id,
    task_code,
    task_title,
    task_content,
    status,
    state,
    progress,
    priority,
    assign_organization,
    assign_department,
    assign_user,
    target_organization,
    target_department,
    target_user,
    started_date,
    expire_date,
    completed_date,
    approved_date,
    created_date,
    updated_date,
    tinh_trang
)

SELECT *
FROM (
    SELECT
        r.ResolutionGroupId AS resolution_group_id,
        r.ResolutionId AS resolution_id,
        r.DocCode AS resolution_doc_code,
        r.Compendium AS resolution_name,

        tr.TaskResolutionId AS task_resolution_id,

        t.TaskId AS task_id,
        t.ParentId AS parent_id,
        t.Code AS task_code,
        t.Title AS task_title,
        t.Content AS task_content,

        t.Status AS status,
        t.State AS state,
        t.Progress AS progress,
        t.Priority AS priority,

        t.AssignOrganization AS assign_organization,
        t.AssignDepartment AS assign_department,
        t.AssignUser AS assign_user,

        t.TargetOrganization AS target_organization,

        /* =====================================================
           CHUẨN HÓA TARGET DEPARTMENT:
           - Nhánh 490.698.752.%: 5 cấp -> cấp 4; 4 cấp -> cấp 3 (490.698.752)
           - Nhánh khác: 5 cấp -> cấp 4
           ===================================================== */
        CASE
            WHEN t.TargetDepartment LIKE '490.698.752.%' THEN
                CASE
                    -- 5 cấp (4 dấu chấm) -> Đẩy lên cấp 4
                    WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    -- 4 cấp (3 dấu chấm) -> Đẩy lên cấp 3 (490.698.752)
                    WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) = 3
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                    ELSE t.TargetDepartment
                END

            -- Các nhánh khác: 5 cấp lùi về cấp 4
            WHEN (LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', ''))) >= 4
            THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)

            ELSE t.TargetDepartment
        END AS target_department,

        t.TargetUser AS target_user,

        t.StartedDate AS started_date,
        t.ExpireDate AS expire_date,
        t.CompletedDate AS completed_date,
        t.ApprovedDate AS approved_date,
        t.CreatedDate AS created_date,
        t.UpdatedDate AS updated_date,

        /* =====================================================
           TÌNH TRẠNG
           ===================================================== */
        CASE
            /* =======================================================================
               NHÓM 1: NHIỆM VỤ THƯỜNG XUYÊN / ĐỊNH KỲ (IsRecurring = 1)
               ======================================================================= */
            -- 1.1 Thường xuyên - Đã báo cáo (Status 3, 4)
            WHEN COALESCE(t.IsRecurring, 0) = 1 
                 AND t.Status IN (3, 4)
            THEN 'Thường xuyên - Đã báo cáo'

            -- 1.2 Thường xuyên - Chưa báo cáo (Status -1, 0, 1, 2)
            WHEN COALESCE(t.IsRecurring, 0) = 1 
                 AND t.Status IN (-1, 0, 1, 2)
            THEN 'Thường xuyên - Chưa báo cáo'

            /* =======================================================================
               NHÓM 2: NHIỆM VỤ THƯỜNG (IsRecurring = 0)
               ======================================================================= */
            -- 2.1 Đã hoàn thành đúng hạn[cite: 1, 3]
            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (3, 4)
                 AND (
                     t.ExpireDate IS NULL
                     OR (
                         COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                         AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
                     )
                 )
            THEN 'Hoàn thành đúng hạn'

            -- 2.2 Đã hoàn thành quá hạn[cite: 1, 3]
            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) > DATE(t.ExpireDate)
            THEN 'Hoàn thành quá hạn'

            -- 2.3 Đang thực hiện trong hạn[cite: 1, 3]
            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (-1, 0, 1, 2)
                 AND (
                     t.ExpireDate IS NULL
                     OR DATE(t.ExpireDate) >= CURDATE()
                 )
            THEN 'Đang thực hiện trong hạn'

            -- 2.4 Chưa hoàn thành quá hạn[cite: 1, 3]
            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Đang thực hiện quá hạn'

            ELSE 'Chưa xác định'
        END AS tinh_trang        

    FROM db_theodoinv_hn.qlnv_resolution r

    INNER JOIN db_theodoinv_hn.qlnv_task_resolution tr
        ON tr.ResolutionId = r.ResolutionId

    INNER JOIN db_theodoinv_hn.qlnv_task t
        ON t.TaskId = tr.TaskId

    WHERE
        r.ResolutionGroupId = 55
        AND r.DeletedDate IS NULL
        AND t.DeletedDate IS NULL
        AND t.Status <> 5

        /* =====================================================
           LOGIC XÁC ĐỊNH TASK CÓ QUA LUỒNG CẦN LẤY HAY KHÔNG
           ===================================================== */
        AND (
            /* TH1: Đơn vị giao thuộc 490.698 -> lấy luôn */
            t.AssignDepartment LIKE '490.698%'

            OR

            (
                /* Assign không thuộc 490.698 thì mới xét Target */
                COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

                AND (
                    /* TH2: Target đúng cấp 490.698 -> lấy luôn */
                    t.TargetDepartment = '490.698'

                    OR

                    /* TH3.1: Nhận tại phòng ban Văn phòng (490.698.752.%) -> Check task_user có 490.698.752 */
                    (
                        t.TargetDepartment LIKE '490.698.752.%'
                        AND EXISTS (
                            SELECT 1
                            FROM db_theodoinv_hn.qlnv_task_user tu_chk
                            WHERE tu_chk.TaskId = t.TaskId
                              AND tu_chk.DepartmentId = '490.698.752'
                        )
                    )

                    OR

                    /* TH3.2: Nhận tại đơn vị con khác của 490.698 -> Check task_user có 490.698 */
                    (
                        t.TargetDepartment LIKE '490.698.%'
                        AND t.TargetDepartment NOT LIKE '490.698.752.%'
                        AND EXISTS (
                            SELECT 1
                            FROM db_theodoinv_hn.qlnv_task_user tu_chk
                            WHERE tu_chk.TaskId = t.TaskId
                              AND tu_chk.DepartmentId = '490.698'
                        )
                    )
                )
            )
        )

) x

/* Không lấy task chưa xác định tình trạng */
WHERE x.tinh_trang <> 'Chưa xác định';