SET SESSION group_concat_max_len = 1048576;

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvnhan_pth_ubndtp` (
    `task_id`,
    `status`,
    `luong_giao`,
	`nhom_van_ban`,
    `id_truc_giao`,
    `truc_giao`,
    `van_ban_giao`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `lanh_dao_don_vi_va_chuyen_vien`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_xoa`,
    `tinh_trang`,
    `tinh_hinh_ket_qua`,
    `ld_ubnd`,
    `ld_van_phong`,
    `phong_chuyen_mon_theo_doi`,
    `chuyen_vien_vp_theo_doi`,
    `sync_date`
)


SELECT
    /* 1. THÔNG TIN KHÓA & TRẠNG THÁI */
    t.TaskId                                               AS task_id,
    t.Status                                               AS status,

    /* LUỒNG GIAO:
       - Đơn vị nhận đúng bằng 490.698 -> hiển nhiên Qua UBND, không cần dò qlnv_task_user
       - Còn lại: check qlnv_task_user có user thuộc UBND (490.698) hay không */
    CASE
        WHEN t.TargetDepartment = '490.698'
        THEN 'Qua UBND'

        WHEN EXISTS (
            SELECT 1
            FROM `db_theodoinv_hn`.`qlnv_task_user` tu_ub
            LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_ub
                   ON u_ub.eGovUserId = tu_ub.UserId
            WHERE tu_ub.TaskId = t.TaskId
              AND (
                     COALESCE(NULLIF(u_ub.DepartmentPath, ''), NULLIF(tu_ub.DepartmentId, '')) = '490.698'
              )
        )
        THEN 'Qua UBND'
        ELSE 'Không qua UBND'
    END                                                    AS luong_giao,

    /* NHÓM NHIỆM VỤ: lấy tên nhóm từ qlnv_resolution_group của resolution gắn với task */
    MAX(rg.Name)                                           AS nhom_van_ban,

    /* 2. TRỤC GIAO CẤP 2 (ID & TÊN CẤP 2) */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)            AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                              AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ */
    t.Code                                                 AS ma_nhiem_vu,
    t.Title                                                AS ten_nhiem_vu,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ */
    t.TargetDepartment                                     AS id_don_vi_chu_tri,
    MAX(d_chutri.name)                                     AS ten_don_vi_chu_tri,

    /* 5. LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN (GỘP THÀNH 1 CỘT TỪ ldcv) */
    MAX(ldcv.lanh_dao_don_vi_va_chuyen_vien)               AS lanh_dao_don_vi_va_chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                 AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                  AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')               AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                 AS ngay_xoa,

    /* 7. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
    CASE
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'

        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                    AS tinh_trang,

    /* 8. TÌNH HÌNH, KẾT QUẢ */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        t.Content
    )                                                      AS tinh_hinh_ket_qua,

    /* 9.1. LÃNH ĐẠO UBND */
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
        FROM `db_theodoinv_hn`.`qlnv_task_user` tu
        INNER JOIN `db_theodoinv_hn`.`qlnv_user` u 
            ON u.eGovUserId = tu.UserId
        WHERE tu.TaskId = t.TaskId
          AND COALESCE(NULLIF(tu.DepartmentId, ''), u.DepartmentPath) = '490.698'
          AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
          AND u.eGovUserPositionLevel = 2
        ORDER BY tu.Role DESC, tu.Id DESC
        LIMIT 1
    ) AS ld_ubnd,

    /* 9.2. LÃNH ĐẠO VĂN PHÒNG */
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
        FROM `db_theodoinv_hn`.`qlnv_task_user` tu
        INNER JOIN `db_theodoinv_hn`.`qlnv_user` u 
            ON u.eGovUserId = tu.UserId
        WHERE tu.TaskId = t.TaskId
          AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.752'
        ORDER BY tu.Role DESC, tu.Id DESC
        LIMIT 1
    ) AS ld_van_phong,

    /* 9.3. PHÒNG CHUYÊN MÔN THEO DÕI */
    CASE
        WHEN MAX(u_create.DepartmentPath) LIKE '490.698.752%'
        THEN NULLIF(MAX(d_create.name), '')
        ELSE NULL
    END AS phong_chuyen_mon_theo_doi,

    /* 9.4. CHUYÊN VIÊN VP THEO DÕI */
    CASE
        WHEN MAX(u_create.DepartmentPath) LIKE '490.698.752%'
        THEN NULLIF(MAX(u_create.eGovUserFullname), '')
        ELSE NULL
    END AS chuyen_vien_vp_theo_doi,

    NOW() AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN NHÓM NHIỆM VỤ: LỌC TRỰC TIẾP ID NHÓM '55', '111', 132, 129 */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL
       AND r.ResolutionGroupId IN (55, 111, 132, 129)

INNER JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
        ON rg.ResolutionGroupId = r.ResolutionGroupId
       AND rg.DeletedDate IS NULL

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 (CHỐNG CAST CHUỖI RỖNG) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ CHỦ TRÌ (CHỐNG CAST CHUỖI RỖNG) */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = CASE
            WHEN SUBSTRING_INDEX(
                CASE
                    WHEN t.TargetDepartment LIKE '490.698.1841%'
                      OR t.TargetDepartment LIKE '490.698.1307%'
                      OR t.TargetDepartment LIKE '490.698.1310%'
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE t.TargetDepartment
                END,
                '.',
                -1
            ) REGEXP '^[0-9]+$'
            THEN CAST(
                SUBSTRING_INDEX(
                    CASE
                        WHEN t.TargetDepartment LIKE '490.698.1841%'
                          OR t.TargetDepartment LIKE '490.698.1307%'
                          OR t.TargetDepartment LIKE '490.698.1310%'
                        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                        ELSE t.TargetDepartment
                    END,
                    '.',
                    -1
                ) AS UNSIGNED
            )
            ELSE NULL
          END
      AND d_chutri.IsDelete = 0

/* JOIN NGƯỜI TẠO NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser

/* JOIN PHÒNG BAN CỦA NGƯỜI TẠO (CHỐNG CAST CHUỖI RỖNG) */
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = CASE
            WHEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_create.IsDelete = 0

/* JOIN LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN */
LEFT JOIN (
    SELECT
        x.TaskId,
        GROUP_CONCAT(
            DISTINCT x.thong_tin
            ORDER BY x.Role, x.thong_tin
            SEPARATOR ', '
        ) AS lanh_dao_don_vi_va_chuyen_vien
    FROM (
        SELECT
            tu.TaskId,
            tu.Role,
            NULLIF(
                TRIM(
                    CONCAT_WS(' - ',
                        NULLIF(TRIM(u.eGovUserPositionName), ''),
                        NULLIF(TRIM(u.eGovUserFullname), ''),
                        NULLIF(TRIM(u.PhoneNumber), '')
                    )
                ), ''
            ) AS thong_tin
        FROM `db_theodoinv_hn`.`qlnv_task_user` tu
        INNER JOIN `db_theodoinv_hn`.`qlnv_user` u
            ON u.eGovUserId = tu.UserId
        INNER JOIN `db_theodoinv_hn`.`qlnv_task` t_sub
            ON t_sub.TaskId = tu.TaskId

        /* ĐỒNG BỘ BỘ LỌC VĂN BẢN VÀO T_SUB ĐỂ KHÔNG QUÉT THỪA TASK_USER */
        INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r_sub
            ON r_sub.ResolutionId = t_sub.ResolutionId
           AND r_sub.DeletedDate IS NULL
           AND r_sub.ResolutionGroupId IN (55, 111, 132, 129)

        WHERE t_sub.DeletedDate IS NULL
          AND t_sub.Status <> 5
          AND t_sub.TargetDepartment LIKE '490.698%'
          AND t_sub.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')
          AND COALESCE(t_sub.AssignDepartment, '') NOT LIKE '490.698%'

          AND (
                  COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) = '490.698'
               OR COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.%'
              )
          AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE CONCAT(
                  CASE
                      WHEN t_sub.TargetDepartment LIKE '490.698.1841%'
                        OR t_sub.TargetDepartment LIKE '490.698.1307%'
                        OR t_sub.TargetDepartment LIKE '490.698.1310%'
                      THEN SUBSTRING_INDEX(t_sub.TargetDepartment, '.', 4)
                      ELSE t_sub.TargetDepartment
                  END,
                  '%'
              )
    ) x
    WHERE x.thong_tin IS NOT NULL
    GROUP BY x.TaskId
) ldcv
    ON ldcv.TaskId = t.TaskId

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )
    AND t.TargetDepartment LIKE '490.698%'
    AND COALESCE(t.TargetDepartment, '') NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')
    AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'
    AND r.ResolutionGroupId IN (55, 111, 132, 129)

GROUP BY t.TaskId;