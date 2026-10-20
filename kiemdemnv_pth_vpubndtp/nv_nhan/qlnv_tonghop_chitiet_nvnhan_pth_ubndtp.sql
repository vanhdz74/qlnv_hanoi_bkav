SET SESSION group_concat_max_len = 1048576;

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvnhan_pth_ubndtp` (
    `task_id`, `status`, `luong_giao`, `nhom_van_ban`, `linh_vuc`,
    `id_truc_giao`, `truc_giao`, `van_ban_giao`, `ma_nhiem_vu`, `ten_nhiem_vu`,
    `id_don_vi_giao`, `don_vi_giao`, `id_nguoi_giao`, `nguoi_giao`,
    `id_don_vi_chu_tri`, `ten_don_vi_chu_tri`, `lanh_dao_don_vi_va_chuyen_vien`,
    `ngay_giao`, `han_xu_ly`, `ngay_hoan_thanh`, `ngay_xoa`,
    `tinh_trang`, `tinh_hinh_ket_qua`,
    `ld_ubnd`, `ld_van_phong`, `phong_chuyen_mon_theo_doi`, `chuyen_vien_vp_theo_doi`,
    `sync_date`
)

SELECT
    /* 1. KHÓA & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    t.Status                                                AS status,

    /* LUỒNG GIAO: đơn vị nhận = 490.698, hoặc qlnv_task_user có user thuộc đúng 490.698 */
    IF(t.TargetDepartment = '490.698' OR MAX(ppl.co_user_ubnd) = 1,
       'Qua UBND', 'Không qua UBND')                        AS luong_giao,

    /* NHÓM VĂN BẢN: gắn tên theo số ký hiệu văn bản giao (DocCode) */
    CASE
        WHEN t.DocCode REGEXP 'TB/(KL|TU|VPTU)' THEN 'TBKL Thành ủy'
        WHEN t.DocCode REGEXP 'CV/(TU|VPTU)'    THEN 'CV Thành ủy'
        WHEN t.DocCode LIKE '%BCĐ%'             THEN 'Triển khai thực hiện Nghị quyết số 57-NQ/TW'
        ELSE 'Khác'
    END                                                     AS nhom_van_ban,
    /* LĨNH VỰC: lĩnh vực văn bản (qlnv_sector qua resolution.SectorId); rỗng thì 'Khác' */
    COALESCE(NULLIF(MAX(s.SectorName), ''), 'Khác')        AS linh_vuc,

    /* 2. TRỤC GIAO CẤP 2 & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. NHIỆM VỤ & THÔNG TIN GIAO */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(MAX(d_assign.name), NULLIF(t.AssignOrganization, '')) AS don_vi_giao,
    t.AssignUser                                            AS id_nguoi_giao,
    MAX(u_assign.eGovUserFullname)                          AS nguoi_giao,

    /* 4. ĐƠN VỊ CHỦ TRÌ & LÃNH ĐẠO ĐƠN VỊ / CHUYÊN VIÊN */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    MAX(d_chutri.name)                                      AS ten_don_vi_chu_tri,
    MAX(ppl.lanh_dao_don_vi_va_chuyen_vien)                 AS lanh_dao_don_vi_va_chuyen_vien,

    /* 5. MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                  AS ngay_xoa,

    /* 6. 4 TÌNH TRẠNG CHUẨN */
    CASE
        WHEN t.Status IN (3, 4) AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL THEN 'Đã hoàn thành'
        WHEN t.ExpireDate IS NULL                                      THEN 'Thường xuyên'
        WHEN t.Status IN (-1, 0, 1, 2)
        THEN IF(t.ExpireDate >= CURDATE(), 'Chưa hoàn thành trong hạn', 'Chưa hoàn thành quá hạn')
    END                                                     AS tinh_trang,

    /* 7. TÌNH HÌNH, KẾT QUẢ: báo cáo mới nhất, fallback nội dung task */
    COALESCE(
        (SELECT rp.Content
         FROM `db_theodoinv_hn`.`qlnv_report` rp
         WHERE rp.TaskId = t.TaskId AND rp.DeletedDate IS NULL
         ORDER BY rp.CreatedDate DESC, rp.ReportId DESC
         LIMIT 1),
        t.Content
    )                                                       AS tinh_hinh_ket_qua,

    /* 8. LÃNH ĐẠO UBND / VĂN PHÒNG (tính sẵn trong ppl) & CHUYÊN VIÊN VP THEO DÕI (người tạo thuộc 490.698.752) */
    MAX(ppl.ld_ubnd)                                        AS ld_ubnd,
    MAX(ppl.ld_van_phong)                                   AS ld_van_phong,
    IF(MAX(u_create.DepartmentPath) LIKE '490.698.752%', NULLIF(MAX(d_create.name), ''), NULL)             AS phong_chuyen_mon_theo_doi,
    IF(MAX(u_create.DepartmentPath) LIKE '490.698.752%', NULLIF(MAX(u_create.eGovUserFullname), ''), NULL) AS chuyen_vien_vp_theo_doi,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* LỌC NHÓM VĂN BẢN 55, 111, 132, 129 */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL
       AND r.ResolutionGroupId IN (55, 111, 132, 129)

/* LĨNH VỰC VĂN BẢN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_sector` s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

/* Không dùng nữa: nhom_van_ban lấy theo DocCode
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution_group` rg
        ON rg.ResolutionGroupId = r.ResolutionGroupId
       AND rg.DeletedDate IS NULL
*/

/* Các JOIN department: chỉ CAST khi id là số (INSERT ... SELECT ở strict mode sẽ lỗi nếu CAST chuỗi rỗng/không phải số) */

/* TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = IF(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$',
                                CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED), NULL)
      AND d_assign_cap2.IsDelete = 0

/* ĐƠN VỊ GIAO & NGƯỜI GIAO */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign
       ON d_assign.id = IF(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$',
                           CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED), NULL)
      AND d_assign.IsDelete = 0
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* ĐƠN VỊ CHỦ TRÌ: nhánh 1841/1307/1310 lấy cấp 4, còn lại lấy id cuối của TargetDepartment */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = IF(
              SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                 SUBSTRING_INDEX(t.TargetDepartment, '.', 4), t.TargetDepartment), '.', -1) REGEXP '^[0-9]+$',
              CAST(SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                      SUBSTRING_INDEX(t.TargetDepartment, '.', 4), t.TargetDepartment), '.', -1) AS UNSIGNED),
              NULL)
      AND d_chutri.IsDelete = 0

/* NGƯỜI TẠO & PHÒNG BAN NGƯỜI TẠO */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = IF(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$',
                           CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED), NULL)
      AND d_create.IsDelete = 0

/* NGƯỜI LIÊN QUAN THEO TASK: tính 1 lần cho mọi task (thay cho subquery tương quan từng dòng)
   Nguồn p.src: 0 = qlnv_task_user (đơn vị tu.DepartmentId), 1 = TargetUser (đơn vị TargetDepartment)
   - co_user_ubnd : có user qlnv_task_user thuộc đúng 490.698 (cho luong_giao)
   - ld_ubnd      : đơn vị = 490.698 (ưu tiên đơn vị của nguồn), chức danh Lãnh đạo, Level = 2
   - ld_van_phong : đơn vị = 490.698.752 (ưu tiên u.DepartmentPath)
   - lanh_dao_don_vi_va_chuyen_vien: chỉ qlnv_task_user, user thuộc đơn vị chủ trì
   - Trùng user giữa 2 nguồn loại bằng GROUP_CONCAT(DISTINCT ...) */
LEFT JOIN (
    SELECT
        p.TaskId,
        MAX(p.src = 0 AND COALESCE(NULLIF(u.DepartmentPath, ''), p.dept) = '490.698') AS co_user_ubnd,

        GROUP_CONCAT(DISTINCT
            CASE WHEN COALESCE(p.dept, u.DepartmentPath) = '490.698'
                  AND LOWER(u.eGovUserPositionName) LIKE '%lãnh đạo%'
                  AND u.eGovUserPositionLevel = 2
                 THEN NULLIF(TRIM(CONCAT_WS(' - ', ujt.job_title, NULLIF(TRIM(u.eGovUserFullname), ''))), '')
            END
            ORDER BY p.src, p.Role DESC, p.Id DESC SEPARATOR ', ') AS ld_ubnd,

        GROUP_CONCAT(DISTINCT
            CASE WHEN COALESCE(NULLIF(u.DepartmentPath, ''), p.dept) = '490.698.752'
                 THEN NULLIF(TRIM(CONCAT_WS(' - ', ujt.job_title, NULLIF(TRIM(u.eGovUserFullname), ''))), '')
            END
            ORDER BY p.src, p.Role DESC, p.Id DESC SEPARATOR ', ') AS ld_van_phong,

        GROUP_CONCAT(DISTINCT
            CASE WHEN p.src = 0
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), p.dept) LIKE '490.698%'
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), p.dept) LIKE CONCAT(
                          IF(p.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                             SUBSTRING_INDEX(p.TargetDepartment, '.', 4), p.TargetDepartment), '%')
                 THEN NULLIF(TRIM(CONCAT_WS(' - ', ujt.job_title,
                                            NULLIF(TRIM(u.eGovUserFullname), ''),
                                            NULLIF(TRIM(u.PhoneNumber), ''))), '')
            END
            ORDER BY p.Role, ujt.job_title, u.eGovUserFullname SEPARATOR ', ') AS lanh_dao_don_vi_va_chuyen_vien

    FROM (
        SELECT tu.TaskId, 0 AS src, tu.Role, tu.Id, tu.UserId,
               NULLIF(tu.DepartmentId, '') AS dept, t2.TargetDepartment
        FROM `db_theodoinv_hn`.`qlnv_task_user` tu
        INNER JOIN `db_theodoinv_hn`.`qlnv_task` t2 ON t2.TaskId = tu.TaskId
        WHERE t2.DeletedDate IS NULL
          AND t2.TargetDepartment LIKE '490.698%'
          AND COALESCE(t2.AssignDepartment, '') NOT LIKE '490.698%'
        UNION ALL
        SELECT t2.TaskId, 1, NULL, NULL, t2.TargetUser,
               NULLIF(t2.TargetDepartment, ''), t2.TargetDepartment
        FROM `db_theodoinv_hn`.`qlnv_task` t2
        WHERE t2.DeletedDate IS NULL
          AND t2.TargetDepartment LIKE '490.698%'
          AND COALESCE(t2.AssignDepartment, '') NOT LIKE '490.698%'
          AND t2.TargetUser IS NOT NULL
    ) p
    /* LEFT JOIN: giữ dòng task_user không có user (co_user_ubnd vẫn xét tu.DepartmentId) */
    LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
           ON u.eGovUserId = p.UserId

    /* CHỨC DANH MỖI USER (tính 1 lần): đúng phòng ban hiện tại > is_primary > id mới nhất.
       MySQL 5.7 không có ROW_NUMBER -> ghép khóa sắp xếp cố định 14 ký tự rồi lấy MAX */
    LEFT JOIN (
        SELECT udpj.user_id,
               NULLIF(TRIM(SUBSTRING(MAX(CONCAT(
                   IF(CAST(udpj.department_id AS CHAR) = SUBSTRING_INDEX(uu.DepartmentPath, '.', -1), 1, 0),
                   IF(udpj.is_primary > 0, 1, 0),
                   LPAD(udpj.id, 12, '0'),
                   COALESCE(jt.JobTitlesName, '')
               )), 15)), '') AS job_title
        FROM `db_theodoinv_hn`.`user_department_position_jobtitle` udpj
        INNER JOIN `db_theodoinv_hn`.`jobtitles` jt ON jt.JobTitlesId = udpj.jobtitle_id
        INNER JOIN `db_theodoinv_hn`.`qlnv_user` uu ON uu.eGovUserId = udpj.user_id
        WHERE COALESCE(udpj.status, 1) = 1
        GROUP BY udpj.user_id
    ) ujt
           ON ujt.user_id = u.eGovUserId

    GROUP BY p.TaskId
) ppl
    ON ppl.TaskId = t.TaskId

WHERE t.DeletedDate IS NULL
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4) AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))
  AND t.TargetDepartment LIKE '490.698%'
  AND t.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')
  AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'
  /* NHIỆM VỤ THÀNH ỦY GIAO (490.695%): chỉ lấy khi DocCode là TBKL / CV Thành ủy / NQ 57-NQ/TW */
  AND (   COALESCE(t.AssignDepartment, '') NOT LIKE '490.695%'
       OR t.DocCode REGEXP 'TB/(KL|TU|VPTU)|CV/(TU|VPTU)|BCĐ')

GROUP BY t.TaskId;
