/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitietnv_banTCTW (
    task_id,
    ma_nhiem_vu,

    roadmap_id,
    thu_tu_moc,
    ten_moc,
    step_key,
    han_moc,
    han_moc_text,

    nguoi_duyet_moc_id,
    nguoi_duyet_moc_name,

    roadmap_status,
    last_report_id,
    roadmap_note,
    roadmap_created_date,
    roadmap_updated_date,

    tinh_trang_moc,
    da_bao_cao,
    tinh_trang_han_moc,

    report_id,
    report_type,
    report_status,
    report_progress,
    report_content,
    report_ket_qua,
    report_kho_khan,
    report_kien_nghi,
    report_created_date,
    report_updated_date,

    trang_thai
,
    `sync_date`)

SELECT
    x.task_id,
    x.ma_nhiem_vu,

    x.roadmap_id,
    x.thu_tu_moc,
    x.ten_moc,
    x.step_key,
    x.han_moc,
    x.han_moc_text,

    x.nguoi_duyet_moc_id,
    x.nguoi_duyet_moc_name,

    x.roadmap_status,
    x.last_report_id,
    x.roadmap_note,
    x.roadmap_created_date,
    x.roadmap_updated_date,

    x.tinh_trang_moc,
    x.da_bao_cao,
    x.tinh_trang_han_moc,

    x.report_id,
    x.report_type,
    x.report_status,
    x.report_progress,
    x.report_content,
    x.report_ket_qua,
    x.report_kho_khan,
    x.report_kien_nghi,
    x.report_created_date,
    x.report_updated_date,

    x.trang_thai

,
    '${sync_ts}' AS sync_date
FROM (
    SELECT
        /* =====================================================
           A. NHIỆM VỤ
           ===================================================== */
        t.TaskId AS task_id,
        t.Code   AS ma_nhiem_vu,

        /* =====================================================
           B. LỘ TRÌNH TRIỂN KHAI
           ===================================================== */
        roadmap.RoadmapId AS roadmap_id,
        roadmap.StepOrder AS thu_tu_moc,
        roadmap.StepName AS ten_moc,
        roadmap.StepKey AS step_key,
        roadmap.DueDate AS han_moc,
        roadmap.DueDateText AS han_moc_text,

        /* =====================================================
           C. NGƯỜI DUYỆT / PHỤ TRÁCH MỐC
           ===================================================== */
        roadmap.ApproverUserId AS nguoi_duyet_moc_id,

        COALESCE(
            NULLIF(roadmap_approver.eGovUserFullname, ''),
            CAST(roadmap.ApproverUserId AS CHAR)
        ) AS nguoi_duyet_moc_name,

        /* =====================================================
           D. ROADMAP
           ===================================================== */
        roadmap.Status AS roadmap_status,
        roadmap.LastReportId AS last_report_id,
        roadmap.Note AS roadmap_note,
        roadmap.CreatedDate AS roadmap_created_date,
        roadmap.UpdatedDate AS roadmap_updated_date,

        /* =====================================================
           E. ĐÃ BÁO CÁO / CHƯA BÁO CÁO
           ===================================================== */
        CASE
            WHEN roadmap.RoadmapId IS NULL
            THEN NULL

            WHEN roadmap.LastReportId IS NOT NULL
            THEN 'Đã báo cáo'

            ELSE 'Chưa báo cáo'
        END AS tinh_trang_moc,

        CASE
            WHEN roadmap.LastReportId IS NOT NULL
            THEN 1
            ELSE 0
        END AS da_bao_cao,

        /* =====================================================
           F. TÌNH TRẠNG HẠN MỐC
           ===================================================== */
        CASE
            WHEN roadmap.DueDate IS NULL
            THEN NULL

            WHEN roadmap.LastReportId IS NULL
                 AND DATE(roadmap.DueDate) >= CURDATE()
            THEN CONCAT(
                'Còn ',
                DATEDIFF(
                    DATE(roadmap.DueDate),
                    CURDATE()
                ),
                ' ngày'
            )

            WHEN roadmap.LastReportId IS NULL
                 AND DATE(roadmap.DueDate) < CURDATE()
            THEN CONCAT(
                'Quá hạn ',
                ABS(
                    DATEDIFF(
                        DATE(roadmap.DueDate),
                        CURDATE()
                    )
                ),
                ' ngày'
            )

            ELSE 'Đã báo cáo'
        END AS tinh_trang_han_moc,

        /* =====================================================
           G. REPORT CUỐI CÙNG CỦA MỐC
           ===================================================== */
        roadmap_report.ReportId AS report_id,
        roadmap_report.Type AS report_type,
        roadmap_report.Status AS report_status,
        roadmap_report.Progress AS report_progress,
        roadmap_report.Content AS report_content,
        roadmap_report.CompletedProduct AS report_ket_qua,
        roadmap_report.Difficulty AS report_kho_khan,
        roadmap_report.Suggestion AS report_kien_nghi,
        roadmap_report.CreatedDate AS report_created_date,
        roadmap_report.UpdatedDate AS report_updated_date,

        /* =====================================================
           H. TRẠNG THÁI NHIỆM VỤ
           ===================================================== */
        CASE
            /* ĐÃ HOÀN THÀNH ĐÚNG HẠN */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(
                        t.CompletedDate,
                        t.ApprovedDate
                     ) IS NOT NULL
                 AND DATE(
                        COALESCE(
                            t.CompletedDate,
                            t.ApprovedDate
                        )
                     ) <= DATE(t.ExpireDate)
            THEN 'Đã hoàn thành đúng hạn'

            /* ĐÃ HOÀN THÀNH QUÁ HẠN */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(
                        t.CompletedDate,
                        t.ApprovedDate
                     ) IS NOT NULL
                 AND DATE(
                        COALESCE(
                            t.CompletedDate,
                            t.ApprovedDate
                        )
                     ) > DATE(t.ExpireDate)
            THEN 'Đã hoàn thành quá hạn'

            /* ĐÃ HOÀN THÀNH KHÔNG CÓ HẠN */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NULL
            THEN 'Đã hoàn thành - không có hạn'

            /* CHƯA HOÀN THÀNH TRONG HẠN */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) >= CURDATE()
            THEN 'Chưa hoàn thành trong hạn'

            /* CHƯA HOÀN THÀNH QUÁ HẠN */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Chưa hoàn thành quá hạn'

            /* CHƯA HOÀN THÀNH KHÔNG CÓ HẠN */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NULL
            THEN 'Chưa hoàn thành - không có hạn'

            ELSE 'Chưa xác định'
        END AS trang_thai


    FROM db_theodoinv_hn.qlnv_task t


    /* =========================================================
       TASK -> ROADMAP
       ========================================================= */
    LEFT JOIN db_theodoinv_hn.qlnv_task_roadmap roadmap
        ON roadmap.TaskId = t.TaskId
       AND roadmap.DeletedDate IS NULL


    /* =========================================================
       NGƯỜI DUYỆT / PHỤ TRÁCH MỐC
       ========================================================= */
    LEFT JOIN db_theodoinv_hn.qlnv_user roadmap_approver
        ON CAST(roadmap_approver.eGovUserId AS CHAR)
         = CAST(roadmap.ApproverUserId AS CHAR)


    /* =========================================================
       REPORT CUỐI CÙNG CỦA MỐC
       ========================================================= */
    LEFT JOIN db_theodoinv_hn.qlnv_report roadmap_report
        ON roadmap_report.ReportId = roadmap.LastReportId
       AND roadmap_report.DeletedDate IS NULL


    /* =========================================================
       TASK DO 900000 GIAO
       ========================================================= */
    WHERE
        t.AssignDepartment LIKE '900000%'
        AND t.DeletedDate IS NULL
        AND t.Status <> 5

) x

/* =========================================================
   KHÔNG INSERT NHIỆM VỤ "CHƯA XÁC ĐỊNH"
   ========================================================= */
WHERE x.trang_thai <> 'Chưa xác định'
ON DUPLICATE KEY UPDATE
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `roadmap_id` = VALUES(`roadmap_id`),
    `thu_tu_moc` = VALUES(`thu_tu_moc`),
    `ten_moc` = VALUES(`ten_moc`),
    `step_key` = VALUES(`step_key`),
    `han_moc` = VALUES(`han_moc`),
    `han_moc_text` = VALUES(`han_moc_text`),
    `nguoi_duyet_moc_id` = VALUES(`nguoi_duyet_moc_id`),
    `nguoi_duyet_moc_name` = VALUES(`nguoi_duyet_moc_name`),
    `roadmap_status` = VALUES(`roadmap_status`),
    `last_report_id` = VALUES(`last_report_id`),
    `roadmap_note` = VALUES(`roadmap_note`),
    `roadmap_created_date` = VALUES(`roadmap_created_date`),
    `roadmap_updated_date` = VALUES(`roadmap_updated_date`),
    `tinh_trang_moc` = VALUES(`tinh_trang_moc`),
    `da_bao_cao` = VALUES(`da_bao_cao`),
    `tinh_trang_han_moc` = VALUES(`tinh_trang_han_moc`),
    `report_id` = VALUES(`report_id`),
    `report_type` = VALUES(`report_type`),
    `report_status` = VALUES(`report_status`),
    `report_progress` = VALUES(`report_progress`),
    `report_content` = VALUES(`report_content`),
    `report_ket_qua` = VALUES(`report_ket_qua`),
    `report_kho_khan` = VALUES(`report_kho_khan`),
    `report_kien_nghi` = VALUES(`report_kien_nghi`),
    `report_created_date` = VALUES(`report_created_date`),
    `report_updated_date` = VALUES(`report_updated_date`),
    `trang_thai` = VALUES(`trang_thai`),
    `sync_date` = VALUES(`sync_date`);
