SET SESSION group_concat_max_len = 1048576;

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_ubndtp` (
    id_truc_giao,
    truc_giao,
    nhom_van_ban,
    ma_nhiem_vu,
    ten_nhiem_vu,
    van_ban_giao,
    id_don_vi_chu_tri,
    ten_don_vi_chu_tri,
    lanh_dao_don_vi_va_chuyen_vien,
    ngay_giao,
    han_xu_ly,
    ngay_hoan_thanh,
    ngay_xoa,
    tinh_trang,
    tinh_hinh_ket_qua,
    ld_ubnd,
    ld_van_phong,
    phong_chuyen_mon_theo_doi,
    chuyen_vien_vp_theo_doi,
    task_id,
    status,
    sync_date
)



SELECT
    /* 1. NHÓM NHIỆM VỤ / TRỤC GIAO */
    t.AssignDepartment                                                     AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name)         AS truc_giao,
    /* Nhóm nhiệm vụ: lấy tên nhóm từ qlnv_resolution_group của resolution gắn với task */
    rg.Name                                                                AS nhom_van_ban,

    /* 2. MÃ NHIỆM VỤ & TÊN NHIỆM VỤ */
    t.Code                                                                 AS ma_nhiem_vu,
    t.Title                                                                AS ten_nhiem_vu,

    /* 3. VĂN BẢN GIAO */
    t.DocCode                                                              AS van_ban_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (CHUẨN HÓA CẤP) */
    CASE
        /* Nhánh 1841 / 1307 / 1310: lấy về cấp 4 */
        WHEN t.TargetDepartment LIKE '490.698.1841%'
          OR t.TargetDepartment LIKE '490.698.1307%'
          OR t.TargetDepartment LIKE '490.698.1310%'
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        /* Còn lại: lấy về cấp 3 */
        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
    END                                                                    AS id_don_vi_chu_tri,

    d_chutri.name                                                          AS ten_don_vi_chu_tri,

    /* 5. LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN (GỘP THÀNH 1 CỘT TỪ qlnv_task_user THUỘC 490.698%) */
    ldcv.lanh_dao_don_vi_va_chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                                 AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                                  AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                               AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                                 AS ngay_xoa,

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
    END                                                                    AS tinh_trang,

    /* 8. TÌNH HÌNH, KẾT QUẢ THỰC HIỆN */
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
    )                                                                      AS tinh_hinh_ket_qua,

    /* 9. LÃNH ĐẠO UBND: Đúng đích danh cấp '490.698', chức vụ Lãnh đạo, Level = 2
       Chức vụ hiển thị: ông Vũ Đại Thắng = 'Chủ tịch', còn lại = 'Phó Chủ tịch' */
    (
        SELECT 
            NULLIF(
                TRIM(
                    CONCAT_WS(' - ',
                        CASE
                            WHEN TRIM(u.eGovUserFullname) LIKE '%Vũ Đại Thắng%'
                            THEN 'Chủ tịch'
                            ELSE 'Phó Chủ tịch'
                        END,
                        NULLIF(TRIM(u.eGovUserFullname), '')
                    )
                ), ''
            )
        FROM db_theodoinv_hn.qlnv_task_user tu
        INNER JOIN db_theodoinv_hn.qlnv_user u 
            ON u.eGovUserId = tu.UserId
        WHERE tu.TaskId = t.TaskId
          AND COALESCE(NULLIF(tu.DepartmentId, ''), u.DepartmentPath) = '490.698'
          AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
          AND u.eGovUserPositionLevel = 2
        ORDER BY tu.Role DESC, tu.Id DESC
        LIMIT 1
    ) AS ld_ubnd,

    /* LÃNH ĐẠO VĂN PHÒNG:
       - Check qlnv_task_user của nhiệm vụ, nếu có user thuộc ban LIKE '490.698.752%' thì lấy user đó
       - Ưu tiên phòng ban thật của user (u.DepartmentPath), fallback tu.DepartmentId
       - eGovUserPositionLevel = 2 (lãnh đạo) */
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
        FROM db_theodoinv_hn.qlnv_task_user tu
        INNER JOIN db_theodoinv_hn.qlnv_user u 
            ON u.eGovUserId = tu.UserId
        WHERE tu.TaskId = t.TaskId
          AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.752'
        ORDER BY tu.Role DESC, tu.Id DESC
        LIMIT 1
    ) AS ld_van_phong,

    /* PHÒNG CHUYÊN MÔN THEO DÕI: Phòng của chuyen_vien_vp_theo_doi (CreateUser thuộc '490.698.752%') */
    CASE
        WHEN  u_create.DepartmentPath LIKE '490.698.752%'
        THEN NULLIF(d_create.name, '')
    END                                                                    AS phong_chuyen_mon_theo_doi,

    /* CHUYÊN VIÊN VP THEO DÕI: Lấy theo CreateUser, chỉ lấy khi CreateUser thuộc '490.698.752%' */
    CASE
        WHEN u_create.DepartmentPath LIKE '490.698.752%'
        THEN NULLIF(u_create.eGovUserFullname, '')
    END                                                                    AS chuyen_vien_vp_theo_doi,

    /* 10. KHÓA HỆ THỐNG & ĐỒNG BỘ */
    t.TaskId                                                               AS task_id,
    t.Status                                                               AS status,
    NOW()                                                                  AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN NHÓM NHIỆM VỤ: LỌC TRỰC TIẾP ID NHÓM '55', 132 */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL
       AND r.ResolutionGroupId IN (55, 132)

INNER JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
        ON rg.ResolutionGroupId = r.ResolutionGroupId
       AND rg.DeletedDate IS NULL

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ CHỦ TRÌ (theo id cấp đã chuẩn hóa) */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = CASE
            WHEN SUBSTRING_INDEX(
                CASE
                    WHEN t.TargetDepartment LIKE '490.698.1841%'
                      OR t.TargetDepartment LIKE '490.698.1307%'
                      OR t.TargetDepartment LIKE '490.698.1310%'
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                END,
                '.',
                -1
            ) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(
                CASE
                    WHEN t.TargetDepartment LIKE '490.698.1841%'
                      OR t.TargetDepartment LIKE '490.698.1307%'
                      OR t.TargetDepartment LIKE '490.698.1310%'
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                END,
                '.',
                -1
            ) AS UNSIGNED)
            ELSE NULL
          END
      AND d_chutri.IsDelete = 0

/* JOIN NGƯỜI TẠO NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser

/* JOIN PHÒNG/ĐƠN VỊ CỦA NGƯỜI TẠO (từ DepartmentPath của u_create) */
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = CASE
            WHEN SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_create.IsDelete = 0

/* GOM DANH SÁCH LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN CỦA ĐƠN VỊ CHỦ TRÌ */
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
        FROM db_theodoinv_hn.qlnv_task_user tu
        INNER JOIN db_theodoinv_hn.qlnv_user u
            ON u.eGovUserId = tu.UserId
        INNER JOIN db_theodoinv_hn.qlnv_task t_sub
            ON t_sub.TaskId = tu.TaskId

        /* ĐỒNG BỘ BỘ LỌC VĂN BẢN VÀO T_SUB ĐỂ TRÁNH QUÉT DƯ THỪA BẢNG TASK_USER */
        INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r_sub
            ON r_sub.ResolutionId = t_sub.ResolutionId
           AND r_sub.DeletedDate IS NULL
           AND r_sub.ResolutionGroupId IN (55, 132)

        WHERE COALESCE(NULLIF(t_sub.TargetDepartment, ''), '') <> ''
          AND t_sub.DeletedDate IS NULL
          AND t_sub.Status <> 5
          AND t_sub.AssignDepartment = '490.698'
          AND t_sub.TargetDepartment LIKE '490.698%'
          AND t_sub.TargetDepartment NOT IN ('490.698', '490.698.1307', '490.698.1841', '490.698.1310')

          AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE CONCAT(
                  CASE
                      WHEN t_sub.TargetDepartment LIKE '490.698.1841%'
                        OR t_sub.TargetDepartment LIKE '490.698.1307%'
                        OR t_sub.TargetDepartment LIKE '490.698.1310%'
                      THEN SUBSTRING_INDEX(t_sub.TargetDepartment, '.', 4)

                      WHEN t_sub.TargetDepartment LIKE '490.698%'
                      THEN SUBSTRING_INDEX(t_sub.TargetDepartment, '.', 3)

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

    /* ĐIỀU KIỆN ĐƠN VỊ GIAO CHÍNH XÁC 490.698 */
    AND t.AssignDepartment = '490.698'
    AND t.TargetDepartment LIKE '490.698%'

    /* LOẠI TRỪ ĐƠN VỊ NHẬN THUỘC 1307, 1841 VÀ 1310 */
    AND COALESCE(t.TargetDepartment, '') NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')

    /* BỎ TASK KHÔNG CÓ ĐƠN VỊ NHẬN, VÀ TASK MÀ ĐƠN VỊ NHẬN CHÍNH LÀ UBND (490.698) */
    AND COALESCE(t.TargetDepartment, '') <> ''
    AND COALESCE(t.TargetDepartment, '') <> '490.698'

    /* CHẶN ĐIỀU KIỆN NHÓM VĂN BẢN 55, 132 */
    AND r.ResolutionGroupId IN (55, 132)

GROUP BY t.TaskId;