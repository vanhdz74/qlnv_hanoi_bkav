USE db_theodoinv_hn;

SELECT *
FROM (
    SELECT
        /* =====================================================
           1. TRƯỜNG PHỤC VỤ BIỂU ĐỒ / TỔNG QUAN (DASHBOARD)
           ===================================================== */
        YEAR(t.CreatedDate)                                  AS yearkey,
        t.TaskId                                             AS task_id,
        t.Status                                             AS status,
        
        -- Phân cấp đơn vị nhận (Target)
        d_capcha.name                                        AS loaicapcha,
        d_cap.name                                           AS loaicap,
        COALESCE(NULLIF(d_donvi.shortname, ''), d_donvi.name) AS donvi,

        /* =====================================================
           2. CÁC CỘT CHI TIẾT THEO YÊU CẦU GIAO DIỆN
           ===================================================== */
        -- Trục giao
        COALESCE(NULLIF(t.AssignOrganization, ''), d_assign.name) AS TrucGiao,

        -- Mã nhiệm vụ & Tên nhiệm vụ
        t.Code                                               AS MaNhiemVu,
        t.Title                                              AS TenNhiemVu,

        -- Văn bản giao
        COALESCE(r.DocCode, t.DocCode, t.DocCode)       AS VanBanGiao,

        -- Lãnh đạo UBND TP chỉ đạo
        COALESCE(t.ChargeUser, u_assign.eGovUserFullname)     AS LanhDaoUBNDTPChiDao,

        -- Đơn vị chủ trì
        COALESCE(
            NULLIF(t.ResponsibleUnit, ''), 
            NULLIF(t.TargetOrganization, ''), 
            d_donvi.name
        )                                                    AS DonViChuTri,

        -- Phòng theo dõi
        COALESCE(NULLIF(t.CreateUserDepartment, ''), d_assign.name) AS PhongTheoDoi,

        -- Chuyên viên
        u_target.eGovUserFullname                            AS ChuyenVien,

        -- Ngày giao & Hạn xử lý
        DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                AS NgayGiao,
        DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                 AS HanXuLy,

        -- Tình trạng (6 trạng thái chuẩn)
        CASE
            /* 1. Đã hoàn thành đúng hạn */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
            THEN 'Đã hoàn thành đúng hạn'

            /* 2. Đã hoàn thành quá hạn */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
                 AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) > DATE(t.ExpireDate)
            THEN 'Đã hoàn thành quá hạn'

            /* 3. Đã hoàn thành không có hạn */
            WHEN t.Status IN (3, 4)
                 AND t.ExpireDate IS NULL
            THEN 'Đã hoàn thành - không có hạn'

            /* 4. Chưa hoàn thành trong hạn */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) >= CURDATE()
            THEN 'Chưa hoàn thành trong hạn'

            /* 5. Chưa hoàn thành quá hạn */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Chưa hoàn thành quá hạn'

            /* 6. Chưa hoàn thành không có hạn */
            WHEN t.Status IN (-1, 0, 1, 2)
                 AND t.ExpireDate IS NULL
            THEN 'Chưa hoàn thành - không có hạn'

            ELSE 'Chưa xác định'
        END AS TinhTrang,

        -- Tình hình, kết quả: Lấy báo cáo mới nhất (Tương thích MySQL 5.7 / không dùng ROW_NUMBER)
        COALESCE(
            (
                SELECT rp.Content 
                FROM `db_theodoinv_hn`.`qlnv_report` rp 
                WHERE rp.TaskId = t.TaskId 
                  AND rp.DeletedDate IS NULL 
                ORDER BY rp.CreatedDate DESC 
                LIMIT 1
            ),
            t.Content
        )                                                    AS TinhHinhKetQua,

        NOW()                                                AS sync_date

    FROM `db_theodoinv_hn`.`qlnv_task` t

    /* JOIN VĂN BẢN / NGHỊ QUYẾT */
    LEFT JOIN `db_theodoinv_hn`.`qlnv_task_resolution` tr 
           ON tr.TaskId = t.TaskId
    LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution` r 
           ON r.ResolutionId = COALESCE(tr.ResolutionId, t.ResolutionId) 
          AND r.DeletedDate IS NULL

    /* JOIN PHÂN CẤP ĐƠN VỊ THỤ LÝ (TARGET) */
    LEFT JOIN `db_theodoinv_hn`.`department` d_capcha
           ON d_capcha.id = CAST(
                SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1) 
                AS UNSIGNED
              ) AND d_capcha.IsDelete = 0

    LEFT JOIN `db_theodoinv_hn`.`department` d_cap
           ON d_cap.id = CAST(
                SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) 
                AS UNSIGNED
              ) AND d_cap.IsDelete = 0

    LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
           ON d_donvi.id = CAST(
                SUBSTRING_INDEX(t.TargetDepartment, '.', -1) 
                AS UNSIGNED
              ) AND d_donvi.IsDelete = 0

    /* JOIN ĐƠN VỊ GIAO (ASSIGN) */
    LEFT JOIN `db_theodoinv_hn`.`department` d_assign
           ON d_assign.id = CAST(
                SUBSTRING_INDEX(t.AssignDepartment, '.', -1) 
                AS UNSIGNED
              ) AND d_assign.IsDelete = 0

    /* JOIN USER (GIAO & NHẬN) */
    LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_assign 
           ON u_assign.eGovUserId = t.AssignUser
    LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
           ON u_target.eGovUserId = t.TargetUser

    WHERE
        t.DeletedDate IS NULL
        AND t.Status <> 5
        AND t.TargetDepartment LIKE '490.698.752%'

        /* =====================================================
           BẮT ĐỦ 3 TRƯỜNG HỢP LUỒNG NHIỆM VỤ
           ===================================================== */
        AND (
            /* TH1: Đơn vị giao thuộc 490.698 -> Lấy luôn */
            t.AssignDepartment LIKE '490.698%'

            OR

            (
                /* TH2 + TH3: Assign không thuộc 490.698 */
                COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'
                AND (
                    /* TH2: Target đúng cấp 490.698 -> Lấy luôn */
                    t.TargetDepartment = '490.698'

                    OR

                    /* TH3: Target là đơn vị con thuộc 490.698 -> Check user trong lịch sử report */
                    (
                        t.TargetDepartment LIKE '490.698.%'
                        AND EXISTS (
                            SELECT 1
                            FROM `db_theodoinv_hn`.`qlnv_report` rp_history
                            LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
                                   ON u_create.eGovUserId = rp_history.CreateUser
                            LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_report
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