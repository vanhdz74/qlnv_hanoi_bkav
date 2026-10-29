SELECT
    b.task_id,
    b.loai_nhiem_vu,
    b.hinh_thuc_giao,

    b.ben_giao_id,
    (
        SELECT d.name 
        FROM db_theodoinv_hn.department d 
        WHERE d.id = CAST(SUBSTRING_INDEX(b.ben_giao_id, '.', -1) AS UNSIGNED)
          AND d.IsDelete = 0 
        LIMIT 1
    ) AS ben_giao_name,

    b.final_ben_nhan_id AS ben_nhan_id,
    (
        SELECT d.name 
        FROM db_theodoinv_hn.department d 
        WHERE d.id = CAST(
            CASE 
                /* Nếu thuộc 490.695.1558.% thì lấy ID của cấp 4 */
                WHEN b.final_ben_nhan_id LIKE '490.695.1558.%'
                THEN SUBSTRING_INDEX(SUBSTRING_INDEX(b.final_ben_nhan_id, '.', 4), '.', -1)
                ELSE SUBSTRING_INDEX(b.final_ben_nhan_id, '.', -1)
            END AS UNSIGNED
        )
          AND d.IsDelete = 0 
        LIMIT 1
    ) AS ben_nhan_name,

    b.ten_task,
    b.nhom_nhiem_vu,
    b.stt_nhiem_vu_theo_doi,
    rv.van_ban_giao,
    b.noi_dung_nhiem_vu,

    /* 1. TỔ CHỨC ĐẢNG CHỦ TRÌ */
    (
        SELECT d.name 
        FROM db_theodoinv_hn.department d 
        WHERE d.id = CAST(SUBSTRING_INDEX(b.dept_to_chuc_dang, '.', -1) AS UNSIGNED)
          AND d.IsDelete = 0 
        LIMIT 1
    ) AS to_chuc_dang_chu_tri,

    /* 2. LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN (THUỘC 490.698%) */
    ldcv.lanh_dao_don_vi_va_chuyen_vien,

    b.ngay_bat_dau,
    b.thoi_han,
    b.ngay_hoan_thanh,

    b.tinh_trang,
    rp.Content AS tinh_hinh_ket_qua_thuc_hien,

    /* 3. LÃNH ĐẠO UBND: đúng đích danh cấp '490.698', chức danh Lãnh đạo, Level = 2
       Chức vụ hiển thị: JobTitlesName (user_department_position_jobtitle + jobtitles)
       - Nối tất cả user thỏa điều kiện trong qlnv_task_user
       - Cộng thêm TargetUser nếu thỏa cùng điều kiện (đơn vị: TargetDepartment thay cho tu.DepartmentId),
         bỏ qua nếu TargetUser đã khớp trong qlnv_task_user để tránh trùng */
    NULLIF(
        CONCAT_WS(', ',
            (
                SELECT
                    GROUP_CONCAT(
                        DISTINCT NULLIF(
                            TRIM(
                                CONCAT_WS(' - ',
                                    /* VAI TRÒ: JobTitlesName (ưu tiên chức danh đúng phòng ban hiện tại của user, rồi bản ghi chính) */
                                    (
                                        SELECT NULLIF(TRIM(jt.JobTitlesName), '')
                                        FROM db_theodoinv_hn.user_department_position_jobtitle udpj
                                        INNER JOIN db_theodoinv_hn.jobtitles jt
                                            ON jt.JobTitlesId = udpj.jobtitle_id
                                        WHERE udpj.user_id = u.eGovUserId
                                          AND COALESCE(udpj.status, 1) = 1
                                        ORDER BY (CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(u.DepartmentPath, '.', -1)) DESC,
                                                 udpj.is_primary DESC,
                                                 udpj.id DESC
                                        LIMIT 1
                                    ),
                                    NULLIF(TRIM(u.eGovUserFullname), '')
                                )
                            ), ''
                        )
                        ORDER BY tu.Role DESC, tu.Id DESC
                        SEPARATOR ', '
                    )
                FROM db_theodoinv_hn.qlnv_task_user tu
                INNER JOIN db_theodoinv_hn.qlnv_user u
                    ON u.eGovUserId = tu.UserId
                WHERE tu.TaskId = b.task_id
                  AND COALESCE(NULLIF(tu.DepartmentId, ''), u.DepartmentPath) = '490.698'
                  AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
                  AND u.eGovUserPositionLevel = 2
            ),
            (
                SELECT
                    NULLIF(
                        TRIM(
                            CONCAT_WS(' - ',
                                /* VAI TRÒ: JobTitlesName (ưu tiên chức danh đúng phòng ban hiện tại của user, rồi bản ghi chính) */
                                (
                                    SELECT NULLIF(TRIM(jt.JobTitlesName), '')
                                    FROM db_theodoinv_hn.user_department_position_jobtitle udpj
                                    INNER JOIN db_theodoinv_hn.jobtitles jt
                                        ON jt.JobTitlesId = udpj.jobtitle_id
                                    WHERE udpj.user_id = u.eGovUserId
                                      AND COALESCE(udpj.status, 1) = 1
                                    ORDER BY (CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(u.DepartmentPath, '.', -1)) DESC,
                                             udpj.is_primary DESC,
                                             udpj.id DESC
                                    LIMIT 1
                                ),
                                NULLIF(TRIM(u.eGovUserFullname), '')
                            )
                        ), ''
                    )
                FROM db_theodoinv_hn.qlnv_user u
                WHERE u.eGovUserId = b.TargetUser
                  AND COALESCE(NULLIF(b.TargetDepartment_Goc, ''), u.DepartmentPath) = '490.698'
                  AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
                  AND u.eGovUserPositionLevel = 2
                  AND NOT EXISTS (
                      SELECT 1
                      FROM db_theodoinv_hn.qlnv_task_user tu_dup
                      WHERE tu_dup.TaskId = b.task_id
                        AND tu_dup.UserId = b.TargetUser
                        AND COALESCE(NULLIF(tu_dup.DepartmentId, ''), u.DepartmentPath) = '490.698'
                  )
                LIMIT 1
            )
        ), ''
    ) AS ld_ubnd,

    /* LÃNH ĐẠO VĂN PHÒNG: user thuộc ban LIKE '490.698.752'
       - Ưu tiên phòng ban thật của user (u.DepartmentPath), fallback tu.DepartmentId
       - Nối tất cả user thỏa điều kiện trong qlnv_task_user
       - Cộng thêm TargetUser nếu thỏa cùng điều kiện (đơn vị: TargetDepartment thay cho tu.DepartmentId),
         bỏ qua nếu TargetUser đã khớp trong qlnv_task_user để tránh trùng */
    NULLIF(
        CONCAT_WS(', ',
            (
                SELECT
                    GROUP_CONCAT(
                        DISTINCT NULLIF(
                            TRIM(
                                CONCAT_WS(' - ',
                                    /* VAI TRÒ: JobTitlesName (ưu tiên chức danh đúng phòng ban hiện tại của user, rồi bản ghi chính) */
                                    (
                                        SELECT NULLIF(TRIM(jt.JobTitlesName), '')
                                        FROM db_theodoinv_hn.user_department_position_jobtitle udpj
                                        INNER JOIN db_theodoinv_hn.jobtitles jt
                                            ON jt.JobTitlesId = udpj.jobtitle_id
                                        WHERE udpj.user_id = u.eGovUserId
                                          AND COALESCE(udpj.status, 1) = 1
                                        ORDER BY (CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(u.DepartmentPath, '.', -1)) DESC,
                                                 udpj.is_primary DESC,
                                                 udpj.id DESC
                                        LIMIT 1
                                    ),
                                    NULLIF(TRIM(u.eGovUserFullname), '')
                                )
                            ), ''
                        )
                        ORDER BY tu.Role DESC, tu.Id DESC
                        SEPARATOR ', '
                    )
                FROM db_theodoinv_hn.qlnv_task_user tu
                INNER JOIN db_theodoinv_hn.qlnv_user u
                    ON u.eGovUserId = tu.UserId
                WHERE tu.TaskId = b.task_id
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.752'
            ),
            (
                SELECT
                    NULLIF(
                        TRIM(
                            CONCAT_WS(' - ',
                                /* VAI TRÒ: JobTitlesName (ưu tiên chức danh đúng phòng ban hiện tại của user, rồi bản ghi chính) */
                                (
                                    SELECT NULLIF(TRIM(jt.JobTitlesName), '')
                                    FROM db_theodoinv_hn.user_department_position_jobtitle udpj
                                    INNER JOIN db_theodoinv_hn.jobtitles jt
                                        ON jt.JobTitlesId = udpj.jobtitle_id
                                    WHERE udpj.user_id = u.eGovUserId
                                      AND COALESCE(udpj.status, 1) = 1
                                    ORDER BY (CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(u.DepartmentPath, '.', -1)) DESC,
                                             udpj.is_primary DESC,
                                             udpj.id DESC
                                    LIMIT 1
                                ),
                                NULLIF(TRIM(u.eGovUserFullname), '')
                            )
                        ), ''
                    )
                FROM db_theodoinv_hn.qlnv_user u
                WHERE u.eGovUserId = b.TargetUser
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(b.TargetDepartment_Goc, '')) LIKE '490.698.752'
                  AND NOT EXISTS (
                      SELECT 1
                      FROM db_theodoinv_hn.qlnv_task_user tu_dup
                      WHERE tu_dup.TaskId = b.task_id
                        AND tu_dup.UserId = b.TargetUser
                        AND COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu_dup.DepartmentId, '')) LIKE '490.698.752'
                  )
                LIMIT 1
            )
        ), ''
    ) AS ld_van_phong_ubnd,

    /* 4. BAN CHUYÊN MÔN: Phòng của chuyên viên theo dõi.
       Chỉ lấy khi là Nhiệm vụ giao VÀ người tạo thuộc Văn phòng UBND '490.698.752%' */
    CASE 
        WHEN b.loai_nhiem_vu = 'Nhiệm vụ giao'
             AND b.dept_ban_chuyen_mon LIKE '490.698.752%'
        THEN COALESCE(
                 NULLIF((
                     SELECT d.name 
                     FROM db_theodoinv_hn.department d 
                     WHERE d.id = CASE
                             WHEN SUBSTRING_INDEX(b.dept_ban_chuyen_mon, '.', -1) REGEXP '^[0-9]+$'
                             THEN CAST(SUBSTRING_INDEX(b.dept_ban_chuyen_mon, '.', -1) AS UNSIGNED)
                             ELSE NULL
                           END
                       AND d.IsDelete = 0 
                     LIMIT 1
                 ), ''),
                 NULLIF(b.dept_ban_chuyen_mon, '')
             )
        ELSE NULL 
    END AS ban_chuyen_mon,

    /* 5. CHUYÊN VIÊN THEO DÕI: Lấy theo CreateUser.
       Chỉ lấy khi là Nhiệm vụ giao VÀ người tạo thuộc Văn phòng UBND '490.698.752%' */
    CASE 
        WHEN b.loai_nhiem_vu = 'Nhiệm vụ giao'
             AND b.dept_ban_chuyen_mon LIKE '490.698.752%'
        THEN NULLIF((
            SELECT u.eGovUserFullname 
            FROM db_theodoinv_hn.qlnv_user u 
            WHERE u.eGovUserId = b.CreateUser 
            ORDER BY u.Id DESC 
            LIMIT 1
        ), '')
        ELSE NULL 
    END AS chuyen_vien_theo_doi

FROM (
    SELECT
        t.TaskId AS task_id,
        t.AssignDepartment AS ben_giao_id,
        t.AssignUser,
        t.CreateUser,
        t.TargetUser,
        t.OriginalTargetDepartment AS TargetDepartment_Goc,

        /* LOẠI NHIỆM VỤ */
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
            WHEN t.AssignDepartment LIKE '490.695%'
                 AND t.OriginalTargetDepartment IN ('490.695.1558.1814', '490.695.1558.1814.1815') 
            THEN 'Giao qua Đảng ủy UBND'

            WHEN t.AssignDepartment LIKE '490.695%'
                 AND t.AssignDepartment NOT IN ('490.695.1558.1814', '490.695.1558.1814.1815')
                 AND t.OriginalTargetDepartment LIKE '490.698%' THEN
                CASE 
                    WHEN tu_check.has_user_dept = 1 THEN 'Giao qua Đảng ủy UBND'
                    ELSE 'Không qua Đảng ủy UBND'
                END

            ELSE NULL
        END AS hinh_thuc_giao,

        /* ID BÊN NHẬN */
        CASE 
            /* Nhánh 490.695.1558.% chuẩn hóa về cấp 4 */
            WHEN t.OriginalTargetDepartment LIKE '490.695.1558.%'
            THEN SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4)

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

        /* TỔ CHỨC ĐẢNG CHỦ TRÌ PATH */
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
        END AS dept_to_chuc_dang,

        /* BAN CHUYÊN MÔN PATH */
        COALESCE(
            NULLIF(t.CreateUserDepartment, ''),
            (
                SELECT u.DepartmentPath 
                FROM db_theodoinv_hn.qlnv_user u 
                WHERE u.eGovUserId = t.CreateUser 
                ORDER BY u.Id DESC 
                LIMIT 1
            )
        ) AS dept_ban_chuyen_mon,

        t.Title AS ten_task,
        t.NameGroup AS nhom_nhiem_vu,
        COALESCE(NULLIF(t.Code, ''), CAST(t.TaskId AS CHAR)) AS stt_nhiem_vu_theo_doi,
        COALESCE(NULLIF(t.Title, ''), t.Content) AS noi_dung_nhiem_vu,

        t.StartedDate AS ngay_bat_dau,
        t.ExpireDate AS thoi_han,
        t.CompletedDate AS ngay_hoan_thanh,

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

    /* CHECK LOG */
    LEFT JOIN (
        SELECT tu.TaskId, 1 AS has_user_dept
        FROM db_theodoinv_hn.qlnv_task_user tu
        WHERE tu.DepartmentId IN ('490.695.1558.1814', '490.695.1558.1814.1815')
        GROUP BY tu.TaskId
    ) tu_check 
        ON tu_check.TaskId = t.TaskId

    WHERE
        t.DeletedDate IS NULL
        AND (t.Status IS NULL OR t.Status <> 5)
        AND t.OriginalTargetDepartment NOT IN ('490.698.1307', '490.698.1310', '490.698.1841')
        AND (
            (
                (t.AssignDepartment = '490.695.1558.1814' OR t.AssignDepartment = '490.695.1558.1814.1815')
                AND t.OriginalTargetDepartment LIKE '490.698%'
                AND t.AssignDepartment <> t.OriginalTargetDepartment
            )
            OR
            (
                t.AssignDepartment LIKE '490.695%' 
                AND (t.OriginalTargetDepartment IN ('490.695.1558.1814', '490.695.1558.1814.1815') OR t.OriginalTargetDepartment LIKE '490.698%')
            )
        )
) b

/* VĂN BẢN GIAO */
LEFT JOIN (
    SELECT
        tr.TaskId,
        GROUP_CONCAT(
            DISTINCT NULLIF(r.DocCode, '')
            ORDER BY r.ResolutionId
            SEPARATOR ' | '
        ) AS van_ban_giao
    FROM db_theodoinv_hn.qlnv_task_resolution tr
    INNER JOIN db_theodoinv_hn.qlnv_resolution r
        ON r.ResolutionId = tr.ResolutionId
       AND r.DeletedDate IS NULL
    GROUP BY tr.TaskId
) rv
    ON rv.TaskId = b.task_id

/* LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN */
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
                        /* VAI TRÒ: JobTitlesName (ưu tiên chức danh đúng phòng ban hiện tại của user, rồi bản ghi chính) */
                        (
                            SELECT NULLIF(TRIM(jt.JobTitlesName), '')
                            FROM db_theodoinv_hn.user_department_position_jobtitle udpj
                            INNER JOIN db_theodoinv_hn.jobtitles jt
                                ON jt.JobTitlesId = udpj.jobtitle_id
                            WHERE udpj.user_id = u.eGovUserId
                              AND COALESCE(udpj.status, 1) = 1
                            ORDER BY (CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(u.DepartmentPath, '.', -1)) DESC,
                                     udpj.is_primary DESC,
                                     udpj.id DESC
                            LIMIT 1
                        ),
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
        WHERE (
                  COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) = '490.698'
               OR COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE '490.698.%'
              )
          AND (
                  t_sub.OriginalTargetDepartment NOT LIKE '490.698%'
               OR COALESCE(NULLIF(u.DepartmentPath, ''), NULLIF(tu.DepartmentId, '')) LIKE CONCAT(
                      CASE
                          WHEN t_sub.OriginalTargetDepartment LIKE '490.698.1841%'
                            OR t_sub.OriginalTargetDepartment LIKE '490.698.1307%'
                            OR t_sub.OriginalTargetDepartment LIKE '490.698.1310%'
                          THEN SUBSTRING_INDEX(t_sub.OriginalTargetDepartment, '.', 4)
                          ELSE SUBSTRING_INDEX(t_sub.OriginalTargetDepartment, '.', 3)
                      END,
                      '%'
                  )
              )
    ) x
    WHERE x.thong_tin IS NOT NULL
    GROUP BY x.TaskId
) ldcv
    ON ldcv.TaskId = b.task_id

/* BÁO CÁO GẦN NHẤT */
LEFT JOIN (
    SELECT 
        rp1.TaskId,
        rp1.Content
    FROM db_theodoinv_hn.qlnv_report rp1
    INNER JOIN (
        SELECT 
            TaskId, 
            MAX(ReportId) AS MaxId
        FROM db_theodoinv_hn.qlnv_report
        WHERE DeletedDate IS NULL
        GROUP BY TaskId
    ) rp_max 
        ON rp1.TaskId = rp_max.TaskId 
       AND rp1.ReportId = rp_max.MaxId
    WHERE rp1.DeletedDate IS NULL
) rp
    ON rp.TaskId = b.task_id

WHERE b.loai_nhiem_vu IS NOT NULL
  AND b.tinh_trang <> 'Chưa xác định';