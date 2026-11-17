
SELECT
    /* =====================================================
       TASK ID
       ===================================================== */
    t.TaskId AS task_id,
    t.ParentId AS ParentId,

    /* =====================================================
       MÃ NHIỆM VỤ
       ===================================================== */
    t.Code AS ma_nhiem_vu,

    /* =====================================================
       CẤP TRÌNH
       ===================================================== */
    CASE
        WHEN t.Code LIKE '%BTCTW%'
          OR t.Code LIKE '%TX%'
            THEN 'Trình Ban tổ chức Trung ương'

        WHEN t.Code LIKE '%BCT%'
            THEN 'Trình Bộ Chính trị'

        WHEN t.Code LIKE '%BBT%'
            THEN 'Trình Ban Bí thư'

        WHEN t.Code LIKE '%TW%'
            THEN 'Trình Ban chấp hành Trung ương'

        ELSE NULL
    END AS ten_cap_trinh,

    /* =====================================================
       TÊN NHIỆM VỤ
       ===================================================== */
    NULLIF(t.Title, '') AS ten_nhiem_vu,

    /* =====================================================
       ĐƠN VỊ CHỦ TRÌ
       ===================================================== */
    t.TargetDepartment AS don_vi_chu_tri_id,
    target_dept.name   AS don_vi_chu_tri_name,

    /* =====================================================
       PHÒNG BAN
       ===================================================== */
    t.TargetDepartment AS phong_ban_id,
    target_dept.name   AS phong_ban_name,

    /* =====================================================
       LÃNH ĐẠO ĐƠN VỊ
       ===================================================== */
    t.AssignDepartment AS lanh_dao_don_vi_id,
    assign_dept.name   AS lanh_dao_don_vi_name,

    /* =====================================================
       ĐỀ ÁN
       ===================================================== */
    t.NameGroup AS de_an,

    /* =====================================================
       CHỦ ĐỀ
       ===================================================== */
    t.TopicId AS chu_de_id,
    t.Sector  AS chu_de_name,

    /* =====================================================
       LÃNH ĐẠO PHỤ TRÁCH
       ===================================================== */
    t.AssignUser AS ld_phu_trach_id,

    COALESCE(
        NULLIF(assign_user.eGovUserFullname, ''),
        CAST(t.AssignUser AS CHAR)
    ) AS ld_phu_trach_name,

    /* =====================================================
       LOẠI VĂN BẢN
       ===================================================== */
    file_info.loai_van_ban_id,
    file_info.loai_van_ban_name,

    /* =====================================================
       VĂN BẢN GIAO
       ===================================================== */
    COALESCE(
        NULLIF(t.DocCode, ''),
        NULLIF(r.DocCode, '')
    ) AS van_ban_giao,

    /* =====================================================
       ĐƠN VỊ PHỐI HỢP
       ===================================================== */
    t.ResponsibleUnit AS don_vi_phoi_hop,

    /* =====================================================
       NGƯỜI THỰC HIỆN
       ===================================================== */
    t.TargetUser AS nguoi_thuc_hien_id,

    COALESCE(
        NULLIF(target_user.eGovUserFullname, ''),
        CAST(t.TargetUser AS CHAR)
    ) AS nguoi_thuc_hien_name,

    /* =====================================================
       NỘI DUNG BÁO CÁO MỚI NHẤT
       ===================================================== */
    COALESCE(
        NULLIF(rp.CompletedProduct, ''),
        NULLIF(rp.Content, '')
    ) AS ket_qua,

    rp.Difficulty AS kho_khan,
    rp.Suggestion AS kien_nghi,

    /* =====================================================
       HẠN HOÀN THÀNH
       ===================================================== */
    t.ExpireDate AS han_hoan_thanh,

    /* =====================================================
       TRẠNG THÁI NHIỆM VỤ
       (trường hợp 'Chưa xác định' đã bị loại ở WHERE)
       ===================================================== */
    CASE
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NULL
        THEN 'Đã hoàn thành - không có hạn'

        WHEN t.Status IN (3, 4)
             AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
        THEN 'Đã hoàn thành đúng hạn'

        WHEN t.Status IN (3, 4)
        THEN 'Đã hoàn thành quá hạn'

        WHEN t.ExpireDate IS NULL
        THEN 'Chưa hoàn thành - không có hạn'

        WHEN DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        ELSE 'Chưa hoàn thành quá hạn'
    END AS trang_thai,

    /* =====================================================
       SỐ REPORT THEO STATUS (0 = Chờ duyệt, 1 = Đã duyệt, 2 = Từ chối)
       ===================================================== */
    COALESCE(report_stats.so_bao_cao_cho_duyet, 0) AS so_bao_cao_cho_duyet,
    COALESCE(report_stats.so_bao_cao_da_duyet, 0)  AS so_bao_cao_da_duyet,
    COALESCE(report_stats.so_bao_cao_tu_choi, 0)   AS so_bao_cao_tu_choi,

    /* =====================================================
       NỘI DUNG / NGÀY YÊU CẦU BÁO CÁO STATUS = 0 GẦN NHẤT
       ===================================================== */
    NULLIF(latest_pending_report.Content, '') AS bao_cao_cho_duyet_gan_nhat,
    latest_pending_report.CreatedDate         AS ngay_yeu_cau_bao_cao_gan_nhat

FROM db_theodoinv_hn.qlnv_task t

/* =========================================================
   ASSIGN DEPARTMENT
   ========================================================= */
LEFT JOIN db_theodoinv_hn.department assign_dept
    ON assign_dept.id = SUBSTRING_INDEX(t.AssignDepartment, '.', -1)

/* =========================================================
   TARGET DEPARTMENT
   ========================================================= */
LEFT JOIN db_theodoinv_hn.department target_dept
    ON target_dept.id = SUBSTRING_INDEX(t.TargetDepartment, '.', -1)

/* =========================================================
   ASSIGN USER / TARGET USER
   Danh bạ user đã khử trùng eGovUserId -> không nhân dòng.
   So sánh int = int trực tiếp (bỏ CAST AS CHAR để dùng được index)
   ========================================================= */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname) AS eGovUserFullname
    FROM db_theodoinv_hn.qlnv_user
    GROUP BY eGovUserId
) assign_user
    ON assign_user.eGovUserId = t.AssignUser

LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname) AS eGovUserFullname
    FROM db_theodoinv_hn.qlnv_user
    GROUP BY eGovUserId
) target_user
    ON target_user.eGovUserId = t.TargetUser

/* =========================================================
   TASK -> RESOLUTION (TaskResolutionId lớn nhất của task)
   ========================================================= */
LEFT JOIN (
    SELECT
        tr2.TaskId,
        MAX(tr2.TaskResolutionId) AS TaskResolutionId
    FROM db_theodoinv_hn.qlnv_task_resolution tr2
    GROUP BY tr2.TaskId
) last_tr
    ON last_tr.TaskId = t.TaskId

LEFT JOIN db_theodoinv_hn.qlnv_task_resolution tr
    ON tr.TaskResolutionId = last_tr.TaskResolutionId

LEFT JOIN db_theodoinv_hn.qlnv_resolution r
    ON r.ResolutionId = COALESCE(tr.ResolutionId, t.ResolutionId)

/* =========================================================
   THỐNG KÊ REPORT THEO TASK - QUÉT qlnv_report 1 LẦN, lấy luôn:
   - số báo cáo theo Status (0 = Chờ duyệt, 1 = Đã duyệt, 2 = Từ chối)
   - báo cáo mới nhất: COALESCE(UpdatedDate, CreatedDate) mới nhất,
     trùng -> ReportId lớn hơn (dùng cho ket_qua, kho_khan, kien_nghi)
   - báo cáo Status = 0 gần nhất: CreatedDate mới nhất, trùng -> ReportId lớn hơn

   MySQL 5.7 không có ROW_NUMBER(): dựng khóa <yyyymmddhhmmss><ReportId 20 số>,
   MAX(khóa) rồi cắt lại ReportId từ ký tự thứ 15
   ========================================================= */
LEFT JOIN (
    SELECT
        rp_count.TaskId,

        SUM(rp_count.Status = 0) AS so_bao_cao_cho_duyet,
        SUM(rp_count.Status = 1) AS so_bao_cao_da_duyet,
        SUM(rp_count.Status = 2) AS so_bao_cao_tu_choi,

        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(COALESCE(rp_count.UpdatedDate, rp_count.CreatedDate), '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(rp_count.ReportId, 20, '0')
            )), 15) AS UNSIGNED) AS latest_report_id,

        CAST(SUBSTRING(
            MAX(CASE
                WHEN rp_count.Status = 0
                THEN CONCAT(
                    COALESCE(DATE_FORMAT(rp_count.CreatedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                    LPAD(rp_count.ReportId, 20, '0')
                )
            END), 15) AS UNSIGNED) AS latest_pending_report_id

    FROM db_theodoinv_hn.qlnv_report rp_count

    WHERE rp_count.DeletedDate IS NULL

    GROUP BY rp_count.TaskId

) report_stats
    ON report_stats.TaskId = t.TaskId

LEFT JOIN db_theodoinv_hn.qlnv_report rp
    ON rp.ReportId = report_stats.latest_report_id

LEFT JOIN db_theodoinv_hn.qlnv_report latest_pending_report
    ON latest_pending_report.ReportId = report_stats.latest_pending_report_id

/* =========================================================
   LOẠI VĂN BẢN
   ========================================================= */
LEFT JOIN (
    SELECT
        file_task.TaskId,

        GROUP_CONCAT(
            DISTINCT file_task.Type
            ORDER BY file_task.Type
            SEPARATOR ', '
        ) AS loai_van_ban_id,

        GROUP_CONCAT(
            DISTINCT
            CASE
                WHEN file_task.Type = 2
                    THEN 'Văn bản chỉ đạo thực hiện'

                WHEN file_task.Type = 3
                    THEN 'KH/HĐ chỉ đạo'

                WHEN file_task.Type = 4
                    THEN 'CTHĐ thực hiện'

                ELSE CONCAT(
                    'Loại ',
                    file_task.Type
                )
            END
            ORDER BY file_task.Type
            SEPARATOR ' | '
        ) AS loai_van_ban_name

    FROM (
        /* =================================================
           FILE GẮN TASK
           ================================================= */
        SELECT
            f.TaskId,
            f.Type
        FROM db_theodoinv_hn.qlnv_file f
        WHERE f.TaskId IS NOT NULL
          AND f.DeletedDate IS NULL
          AND f.Type IS NOT NULL

        UNION ALL

        /* =================================================
           FILE GẮN REPORT
           ================================================= */
        SELECT
            rp_file.TaskId,
            f.Type
        FROM db_theodoinv_hn.qlnv_file f

        INNER JOIN db_theodoinv_hn.qlnv_report rp_file
            ON rp_file.ReportId = f.ReportId

        WHERE f.ReportId IS NOT NULL
          AND f.DeletedDate IS NULL
          AND f.Type IS NOT NULL

        UNION ALL

        /* =================================================
           FILE GẮN RESOLUTION
           ================================================= */
        SELECT
            tr_file.TaskId,
            f.Type
        FROM db_theodoinv_hn.qlnv_file f

        INNER JOIN db_theodoinv_hn.qlnv_task_resolution tr_file
            ON tr_file.ResolutionId = f.ResolutionId

        WHERE f.ResolutionId IS NOT NULL
          AND f.DeletedDate IS NULL
          AND f.Type IS NOT NULL

    ) file_task

    GROUP BY file_task.TaskId

) file_info
    ON file_info.TaskId = t.TaskId

WHERE
    t.AssignDepartment LIKE '900000%'
    AND t.DeletedDate IS NULL

    /* KHÔNG LẤY TRẠNG THÁI 'Chưa xác định'
       (lọc thẳng trên qlnv_task thay cho bọc SELECT ngoài rồi lọc x.trang_thai;
        đồng thời đã loại Status = 5) */
    AND (   t.Status IN (-1, 0, 1, 2)
         OR (t.Status IN (3, 4)
             AND (   t.ExpireDate IS NULL
                  OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)));
