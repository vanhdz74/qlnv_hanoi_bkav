SELECT *
FROM (
    SELECT DISTINCT
        r.ResolutionGroupId AS resolution_group_id,
        r.ResolutionId      AS resolution_id,
        t.TaskId            AS task_id,

        /* 1. Nhóm nhiệm vụ */
        t.NameGroup AS nhom_nhiem_vu,

        /* 2. STT nhiệm vụ theo dõi */
        t.Code AS stt_nhiem_vu_theo_doi,

        /* 3. Văn bản giao */
        t.DocCode AS van_ban_giao,

        /* Title task */
        t.Title AS task_title,

        /* 4. Nội dung nhiệm vụ */
        t.Compendium AS noi_dung_nhiem_vu,

        /* 5. Đơn vị giao */
        assign_dept.name AS don_vi_giao,
        t.AssignDepartment AS don_vi_giao_path,

        /* 6. Đơn vị chủ trì */
        target_dept.name AS don_vi_chu_tri,
        t.TargetDepartment AS don_vi_chu_tri_path,

        /* 7. Lãnh đạo đơn vị + chuyên viên */
        NULL AS lanh_dao_don_vi_va_chuyen_vien_sdt,

        /* ID user đối chiếu */
        t.AssignUser AS assign_user_id,
        t.TargetUser AS target_user_id,
        t.ChargeUser AS charge_user_id,
        t.FollowUser AS follow_user_id,

        /* 8. Ngày bắt đầu */
        t.StartedDate AS ngay_bat_dau,

        /* 9. Ngày hết hạn */
        t.ExpireDate AS ngay_het_han,

        /* Status gốc */
        t.Status AS status,

        /* 10. Tình trạng */
        CASE
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate))
                     <= DATE(t.ExpireDate)
            THEN 'Đã hoàn thành đúng hạn'

            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate))
                     > DATE(t.ExpireDate)
            THEN 'Đã hoàn thành quá hạn'

            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NULL
            THEN 'Đã hoàn thành - không có hạn'

            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) >= CURDATE()
            THEN 'Chưa hoàn thành trong hạn'

            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Chưa hoàn thành quá hạn'

            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NULL
            THEN 'Chưa hoàn thành - không có hạn'

            ELSE 'Chưa xác định'
        END AS tinh_trang,

        /* Tiến độ */
        t.Progress AS tien_do,

        /* Ngày hoàn thành */
        t.CompletedDate AS ngay_hoan_thanh,

        /* Ngày phê duyệt */
        t.ApprovedDate AS ngay_phe_duyet,

        /* 11. Tình hình, kết quả thực hiện */
        rp.Content AS tinh_hinh_ket_qua_thuc_hien,

        /* Report gần nhất */
        rp.ReportId    AS report_id,
        rp.Progress    AS report_progress,
        rp.Status      AS report_status,
        rp.UpdatedDate AS report_updated_date,

        /* 4 cột cuối */
        NULL AS ld_ubnd_tp,
        NULL AS ld_van_phong,
        NULL AS phong_chuyen_mon,
        NULL AS chuyen_vp_theo_doi

    FROM db_theodoinv_hn.qlnv_resolution r

    INNER JOIN db_theodoinv_hn.qlnv_task_resolution tr
        ON tr.ResolutionId = r.ResolutionId

    INNER JOIN (
        SELECT
            q.*,

            /* =====================================================
               CHUẨN HÓA TARGET DEPARTMENT

               490.698.1307.5638.323
               -> 490.698.1307.5638

               Chỉ áp dụng nhánh 1307 / 1310 và đúng 5 cấp
               ===================================================== */
            CASE
                WHEN (
                        q.TargetDepartment LIKE '490.698.1307.%'
                        OR q.TargetDepartment LIKE '490.698.1310.%'
                     )
                     AND (
                        LENGTH(q.TargetDepartment)
                        - LENGTH(REPLACE(q.TargetDepartment, '.', ''))
                     ) = 4
                THEN SUBSTRING_INDEX(
                    q.TargetDepartment,
                    '.',
                    4
                )

                ELSE q.TargetDepartment
            END AS TargetDepartmentXuLy

        FROM db_theodoinv_hn.qlnv_task q

        WHERE q.Status <> 5
          AND q.DeletedDate IS NULL
    ) t
        ON t.TaskId = tr.TaskId

    /* Đơn vị giao */
    LEFT JOIN db_theodoinv_hn.department assign_dept
        ON assign_dept.id = SUBSTRING_INDEX(
            t.AssignDepartment,
            '.',
            -1
        )

    /* Đơn vị chủ trì */
    LEFT JOIN db_theodoinv_hn.department target_dept
        ON target_dept.id = SUBSTRING_INDEX(
            t.TargetDepartment,
            '.',
            -1
        )

    /* =============================================================
       BÁO CÁO GẦN NHẤT
       ============================================================= */
    LEFT JOIN db_theodoinv_hn.qlnv_report rp
        ON rp.ReportId = (
            SELECT rp2.ReportId
            FROM db_theodoinv_hn.qlnv_report rp2
            WHERE rp2.TaskId = t.TaskId
              AND rp2.DeletedDate IS NULL
            ORDER BY
                COALESCE(
                    rp2.UpdatedDate,
                    rp2.CreatedDate
                ) DESC,
                rp2.ReportId DESC
            LIMIT 1
        )

    WHERE r.ResolutionGroupId = 55

      /* Resolution còn hiệu lực */
      AND r.DeletedDate IS NULL

      /* ==========================================================
         LOGIC LẤY TASK THEO LUỒNG 490.698
         ========================================================== */
      AND (
          /* ======================================================
             TH1:
             AssignDepartment thuộc 490.698
             -> LẤY LUÔN
             ====================================================== */
          t.AssignDepartment LIKE '490.698%'

          OR

          (
              /* Assign không thuộc 490.698 */
              COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

              AND (
                  /* ==================================================
                     TH2:
                     TargetDepartment đúng bằng 490.698
                     -> LẤY LUÔN, KHÔNG CHECK REPORT/USER
                     ================================================== */
                  t.TargetDepartment = '490.698'

                  OR

                  /* ==================================================
                     TH3:
                     TargetDepartment là cấp con của 490.698
                     VD: 490.698.1307, 490.698.1310....
                     -> phải kiểm tra lịch sử report
                     -> report phải có CreateUser hoặc UserId
                        thuộc DepartmentPath = 490.468
                     ================================================== */
                  (
                      t.TargetDepartment LIKE '490.698.%'

                      AND EXISTS (
                          SELECT 1
                          FROM db_theodoinv_hn.qlnv_report rp_history

                          LEFT JOIN db_theodoinv_hn.qlnv_user u_create
                              ON u_create.eGovUserId = rp_history.CreateUser

                          LEFT JOIN db_theodoinv_hn.qlnv_user u_report
                              ON u_report.eGovUserId = rp_history.UserId

                          WHERE rp_history.TaskId = t.TaskId
                            AND rp_history.DeletedDate IS NULL

                            AND (
                                u_create.DepartmentPath = '490.468'
                                OR u_report.DepartmentPath = '490.468'
                            )
                      )
                  )
              )
          )
      )

) x

/* Không insert task không xác định được tình trạng */
WHERE x.tinh_trang <> 'Chưa xác định';