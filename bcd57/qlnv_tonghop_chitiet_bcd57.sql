SET SESSION group_concat_max_len = 1048576;

INSERT INTO db_theodoinv_hn_test_data.qlnv_tonghop_chitiet_bcd57 (
    resolution_group_id,
    resolution_id,
    task_id,

    nhom_nhiem_vu,
    stt_nhiem_vu_theo_doi,
    van_ban_giao,
    task_title,
    noi_dung_nhiem_vu,

    don_vi_giao,
    don_vi_giao_path,

    don_vi_chu_tri,
    don_vi_chu_tri_path,

    lanh_dao_don_vi_va_chuyen_vien_sdt,

    assign_user_id,
    target_user_id,
    charge_user_id,
    follow_user_id,

    ngay_bat_dau,
    ngay_het_han,

    status,
    tinh_trang,

    tien_do,
    ngay_hoan_thanh,
    ngay_phe_duyet,

    tinh_hinh_ket_qua_thuc_hien,

    report_id,
    report_progress,
    report_status,
    report_updated_date,

    ld_ubnd_tp,
    ld_van_phong,
    phong_chuyen_mon,
    chuyen_vien_vp_theo_doi
)


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
        assign_dept.name   AS don_vi_giao,
        t.AssignDepartment AS don_vi_giao_path,

        /* =====================================================
           6. ĐƠN VỊ CHỦ TRÌ (ĐẨY LÊN 1 CẤP CHO NHÁNH 490.698.752.%)
           ===================================================== */
        target_dept.name AS don_vi_chu_tri,
        
        -- Path đơn vị chủ trì sau khi đẩy cấp
        CASE 
            WHEN t.OriginalTargetDepartment LIKE '490.698.752.%' THEN
                CASE 
                    -- 5 cấp (4 dấu chấm) -> Đẩy lên cấp 4
                    WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
                    -- 4 cấp (3 dấu chấm) -> Đẩy lên cấp 3 (490.698.752)
                    WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) = 3 
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 3)
                    ELSE t.OriginalTargetDepartment
                END
            -- Các nhánh khác: 5 cấp thì lấy cấp 4
            WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
            ELSE t.OriginalTargetDepartment 
        END AS don_vi_chu_tri_path,

        /* =====================================================
           7. LÃNH ĐẠO ĐƠN VỊ + CHUYÊN VIÊN
           ===================================================== */
        /* Gom lãnh đạo đơn vị + chuyên viên thuộc UBND (490.698), giới hạn trong
           đơn vị chủ trì hoặc cấp dưới của nó. Ưu tiên phòng ban THẬT của user. */
        COALESCE(
            (
                SELECT GROUP_CONCAT(
                           DISTINCT NULLIF(
                               TRIM(
                                   CONCAT_WS(' - ',
                                       NULLIF(TRIM(u.eGovUserPositionName), ''),
                                       NULLIF(TRIM(u.eGovUserFullname), ''),
                                       NULLIF(TRIM(u.PhoneNumber), '')
                                   )
                               ), ''
                           )
                           ORDER BY tu.Role, u.eGovUserFullname
                           SEPARATOR ', '
                       )
                FROM db_theodoinv_hn_test_data.qlnv_task_user tu
                INNER JOIN db_theodoinv_hn_test_data.qlnv_user u
                    ON u.eGovUserId = tu.UserId
                WHERE tu.TaskId = t.TaskId
                  AND (
                         COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) = '490.698'
                      OR COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.%'
                      )
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE CONCAT(
                          CASE 
                    WHEN t.OriginalTargetDepartment LIKE '490.698.752.%' THEN
                        CASE 
                            WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
                            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
                            WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) = 3 
                            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 3)
                            ELSE t.OriginalTargetDepartment
                        END
                    WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
                    ELSE t.OriginalTargetDepartment 
                END,
                          '%'
                      )
            ),
            NULLIF(COALESCE(u_charge.eGovUserFullname, t.ChargeUser), ''),
            NULLIF(COALESCE(u_target.eGovUserFullname, t.OriginalTargetUser), '')
        ) AS lanh_dao_don_vi_va_chuyen_vien_sdt,

        /* ID user đối chiếu */
        t.AssignUser AS assign_user_id,
        t.OriginalTargetUser AS target_user_id,
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
            /* =======================================================================
               NHÓM 1: NHIỆM VỤ THƯỜNG XUYÊN / ĐỊNH KỲ (IsRecurring = 1)
               ======================================================================= */
            WHEN COALESCE(t.IsRecurring, 0) = 1 
                 AND t.Status IN (3, 4)
            THEN 'Thường xuyên - Đã báo cáo'

            WHEN COALESCE(t.IsRecurring, 0) = 1 
                 AND t.Status IN (-1, 0, 1, 2)
            THEN 'Thường xuyên - Chưa báo cáo'

            /* =======================================================================
               NHÓM 2: NHIỆM VỤ THƯỜNG (IsRecurring = 0)
               ======================================================================= */
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

            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) > DATE(t.ExpireDate)
            THEN 'Hoàn thành quá hạn'

            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (-1, 0, 1, 2)
                 AND (
                     t.ExpireDate IS NULL
                     OR DATE(t.ExpireDate) >= CURDATE()
                 )
            THEN 'Đang thực hiện trong hạn'

            WHEN COALESCE(t.IsRecurring, 0) = 0
                 AND t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Đang thực hiện quá hạn'

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

        /* =====================================================
           4 CỘT LÃNH ĐẠO / THEO DÕI VĂN PHÒNG & PHÒNG CHUYÊN MÔN
           ===================================================== */
        /* LÃNH ĐẠO UBND TP: đúng đích danh cấp '490.698', chức danh Lãnh đạo, Level = 2.
           Chức vụ hiển thị: ông Vũ Đại Thắng = 'Chủ tịch', còn lại = 'Phó Chủ tịch' */
        (
            SELECT
                NULLIF(
                    TRIM(
                        CONCAT_WS(' - ',
                            CASE
                                WHEN TRIM(u.eGovUserFullname) LIKE '%Vũ Đại Thắng%' THEN 'Chủ tịch'
                                ELSE 'Phó Chủ tịch'
                            END,
                            NULLIF(TRIM(u.eGovUserFullname), '')
                        )
                    ), ''
                )
            FROM db_theodoinv_hn_test_data.qlnv_task_user tu
            INNER JOIN db_theodoinv_hn_test_data.qlnv_user u
                ON u.eGovUserId = tu.UserId
            WHERE tu.TaskId = t.TaskId
              AND COALESCE(NULLIF(tu.DepartmentId, ''), u.DepartmentPath) = '490.698'
              AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
              AND u.eGovUserPositionLevel = 2
            ORDER BY tu.Role DESC, tu.Id DESC
            LIMIT 1
        ) AS ld_ubnd_tp,

        /* LÃNH ĐẠO VĂN PHÒNG:
           - Check qlnv_task_user của nhiệm vụ, nếu có user thuộc ban LIKE '490.698.752%' thì lấy user đó
           - Ưu tiên phòng ban thật của user (u.DepartmentPath), fallback tu.DepartmentId */
        (
            SELECT
                NULLIF(
                    TRIM(
                        CONCAT_WS(' - ',
                            NULLIF(TRIM(u.eGovUserPositionName), ''),
                            NULLIF(TRIM(u.eGovUserFullname), '')
                        )
                    ), ''
                )
            FROM db_theodoinv_hn_test_data.qlnv_task_user tu
            INNER JOIN db_theodoinv_hn_test_data.qlnv_user u
                ON u.eGovUserId = tu.UserId
            WHERE tu.TaskId = t.TaskId
              AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.752'
            ORDER BY tu.Role DESC, tu.Id DESC
            LIMIT 1
        ) AS ld_van_phong,

        /* PHÒNG CHUYÊN MÔN THEO DÕI: phòng của chuyên viên VP theo dõi (CreateUser thuộc '490.698.752%') */
        CASE
            WHEN COALESCE(NULLIF(t.CreateUserDepartment, ''), u_create.DepartmentPath) LIKE '490.698.752%'
            THEN COALESCE(
                     NULLIF(d_create.name, ''),
                     NULLIF(t.CreateUserDepartment, '')
                 )
        END AS phong_chuyen_mon,

        /* CHUYÊN VIÊN VP THEO DÕI: lấy theo CreateUser, chỉ lấy khi thuộc '490.698.752%' */
        CASE
            WHEN COALESCE(NULLIF(t.CreateUserDepartment, ''), u_create.DepartmentPath) LIKE '490.698.752%'
            THEN NULLIF(u_create.eGovUserFullname, '')
        END AS chuyen_vien_vp_theo_doi

    FROM db_theodoinv_hn_test_data.qlnv_resolution r

    INNER JOIN db_theodoinv_hn_test_data.qlnv_task_resolution tr
        ON tr.ResolutionId = r.ResolutionId

    /* JOIN BẢNG TASK */
    INNER JOIN db_theodoinv_hn_test_data.qlnv_task t
        ON t.TaskId = tr.TaskId
       AND t.Status <> 5
       AND t.DeletedDate IS NULL

    /* NGƯỜI TẠO NHIỆM VỤ (dùng cho phòng chuyên môn & chuyên viên VP theo dõi) */
    LEFT JOIN db_theodoinv_hn_test_data.qlnv_user u_create
        ON u_create.eGovUserId = t.CreateUser

    /* PHÒNG BAN CỦA NGƯỜI TẠO (chống CAST chuỗi rỗng) */
    LEFT JOIN db_theodoinv_hn_test_data.department d_create
        ON d_create.id = CASE
             WHEN SUBSTRING_INDEX(
                      COALESCE(NULLIF(t.CreateUserDepartment, ''), u_create.DepartmentPath),
                      '.', -1
                  ) REGEXP '^[0-9]+$'
             THEN CAST(
                      SUBSTRING_INDEX(
                          COALESCE(NULLIF(t.CreateUserDepartment, ''), u_create.DepartmentPath),
                          '.', -1
                      ) AS UNSIGNED
                  )
             ELSE NULL
           END
       AND d_create.IsDelete = 0

    /* Join User dự phòng */
    LEFT JOIN db_theodoinv_hn_test_data.qlnv_user u_charge
        ON u_charge.eGovUserId = t.ChargeUser
    LEFT JOIN db_theodoinv_hn_test_data.qlnv_user u_target
        ON u_target.eGovUserId = t.OriginalTargetUser

    /* Đơn vị giao */
    LEFT JOIN db_theodoinv_hn_test_data.department assign_dept
        ON assign_dept.id = CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)

    /* =============================================================
       ĐƠN VỊ CHỦ TRÌ: MAP THEO ID CỦA PATH ĐÃ ĐẨY CẤP
       ============================================================= */
    LEFT JOIN db_theodoinv_hn_test_data.department target_dept
        ON target_dept.id = CAST(
            SUBSTRING_INDEX(
                CASE 
                    WHEN t.OriginalTargetDepartment LIKE '490.698.752.%' THEN
                        CASE 
                            WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
                            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
                            WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) = 3 
                            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 3)
                            ELSE t.OriginalTargetDepartment
                        END
                    WHEN (LENGTH(t.OriginalTargetDepartment) - LENGTH(REPLACE(t.OriginalTargetDepartment, '.', ''))) >= 4 
                    THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)
                    ELSE t.OriginalTargetDepartment 
                END,
                '.',
                -1
            ) AS UNSIGNED
        )

    /* Báo cáo gần nhất */
    LEFT JOIN db_theodoinv_hn_test_data.qlnv_report rp
        ON rp.ReportId = (
            SELECT rp2.ReportId
            FROM db_theodoinv_hn_test_data.qlnv_report rp2
            WHERE rp2.TaskId = t.TaskId
              AND rp2.DeletedDate IS NULL
            ORDER BY
                COALESCE(rp2.UpdatedDate, rp2.CreatedDate) DESC,
                rp2.ReportId DESC
            LIMIT 1
        )

    WHERE r.ResolutionGroupId = 55
      AND r.DeletedDate IS NULL

      /* ==========================================================
          LOGIC LẤY TASK: CHECK ORIGINALTARGETDEPARTMENT LIKE '490.698.752.%'
          VÀ BẮT BUỘC PHẢI CÓ LOG DepartmentId = '490.698.752'
          ========================================================== */
      AND (
          /* Nhánh giao */
          t.AssignDepartment LIKE '490.698%'
          
          OR 
          
          /* Nhánh nhận trực tiếp của UBND TP */
          t.OriginalTargetDepartment = '490.698'
          
          OR
          
          /* Nhánh nhận thuộc các phòng ban của Văn phòng (490.698.752.%) */
          (
              t.OriginalTargetDepartment LIKE '490.698.752.%'
              AND EXISTS (
                  SELECT 1
                  FROM db_theodoinv_hn_test_data.qlnv_task_user tu_chk
                  WHERE tu_chk.TaskId = t.TaskId
                    AND tu_chk.DepartmentId = '490.698.752'
              )
          )
          
          OR
          
          /* Nhánh nhận qua UBND TP chung */
          (
              t.OriginalTargetDepartment LIKE '490.698.%'
              AND t.OriginalTargetDepartment NOT LIKE '490.698.752.%'
              AND EXISTS (
                  SELECT 1
                  FROM db_theodoinv_hn_test_data.qlnv_task_user tu_chk
                  WHERE tu_chk.TaskId = t.TaskId
                    AND tu_chk.DepartmentId = '490.698'
              )
          )
      )
) x
WHERE x.tinh_trang <> 'Chưa xác định';