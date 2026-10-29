SET SESSION group_concat_max_len = 1048576;

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_ubndtp` (
    id_truc_giao, truc_giao, nhom_van_ban, linh_vuc, chu_de, muc_do_uu_tien, nv_quantam,
    ma_nhiem_vu, ten_nhiem_vu, van_ban_giao,
    id_don_vi_chu_tri, ten_don_vi_chu_tri, lanh_dao_don_vi_va_chuyen_vien,
    ngay_giao, han_xu_ly, ngay_hoan_thanh, ngay_xoa,
    tinh_trang, tinh_hinh_ket_qua,
    ld_ubnd, ld_van_phong, phong_chuyen_mon_theo_doi, chuyen_vien_vp_theo_doi,
    task_id, id_cha, status, sync_date
)

SELECT
    /* 1. TRỤC GIAO & NHÓM VĂN BẢN */
    t.AssignDepartment                                                      AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name)          AS truc_giao,
    /* Nhóm văn bản: gắn tên theo số ký hiệu văn bản giao (DocCode), xét theo thứ tự từ trên xuống.
       Chỉ dùng để phân nhóm, KHÔNG dùng để lọc task */
    CASE
        WHEN t.DocCode LIKE '%CTr%'                 THEN 'Chương trình'
        WHEN t.DocCode LIKE '%KH%'                  THEN 'Kế hoạch'
        WHEN t.DocCode REGEXP 'TB-(VP|UBND)'        THEN 'TBKL UBND Thành phố'
        WHEN t.DocCode LIKE '%BCĐ%'                 THEN 'Triển khai thực hiện Nghị quyết số 57-NQ/TW'
        WHEN t.DocCode REGEXP '/(UBND|VP)-'         THEN 'Văn bản chỉ đạo'
        ELSE 'Chưa xác định'
    END                                                                     AS nhom_van_ban,
    /* LĨNH VỰC: lĩnh vực văn bản (qlnv_sector qua resolution.SectorId); rỗng thì 'Khác' */
    COALESCE(NULLIF(s.SectorName, ''), 'Khác')                              AS linh_vuc,

    /* CHỦ ĐỀ, MỨC ĐỘ ƯU TIÊN, NHIỆM VỤ QUAN TÂM */
    tp.TopicName                                                            AS chu_de,
    CASE t.Priority
        WHEN 3 THEN 'Hỏa tốc'
        WHEN 2 THEN 'Thượng khẩn'
        WHEN 1 THEN 'Khẩn'
        ELSE 'Thường'
    END                                                                     AS muc_do_uu_tien,
    t.isFocus                                                               AS nv_quantam,

    /* 2. NHIỆM VỤ & VĂN BẢN GIAO */
    t.Code                                                                  AS ma_nhiem_vu,
    t.Title                                                                 AS ten_nhiem_vu,
    t.DocCode                                                               AS van_ban_giao,

    /* 3. ĐƠN VỊ CHỦ TRÌ: nhánh 1841/1307/1310 lấy cấp 4, còn lại cấp 3 */
    IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
       SUBSTRING_INDEX(t.TargetDepartment, '.', 4),
       SUBSTRING_INDEX(t.TargetDepartment, '.', 3))                         AS id_don_vi_chu_tri,
    d_chutri.name                                                           AS ten_don_vi_chu_tri,
    ppl.lanh_dao_don_vi_va_chuyen_vien,

    /* 4. MỐC THỜI GIAN: Định dạng chuẩn ISO yyyy-mm-dd */
    DATE_FORMAT(t.StartedDate, '%Y-%m-%d')                                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%Y-%m-%d')                                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%Y-%m-%d')                                AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%Y-%m-%d')                                  AS ngay_xoa,

    /* 5. 4 TÌNH TRẠNG CHUẨN */
    CASE
        WHEN t.Status IN (3, 4) AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL THEN 'Đã hoàn thành'
        WHEN t.ExpireDate IS NULL                                       THEN 'Thường xuyên'
        WHEN t.Status IN (-1, 0, 1, 2)
        THEN IF(t.ExpireDate >= CURDATE(), 'Chưa hoàn thành trong hạn', 'Chưa hoàn thành quá hạn')
    END                                                                     AS tinh_trang,

    /* 6. TÌNH HÌNH, KẾT QUẢ: báo cáo mới nhất, fallback nội dung task */
    COALESCE(
        (SELECT rp.Content
         FROM `db_theodoinv_hn`.`qlnv_report` rp
         WHERE rp.TaskId = t.TaskId AND rp.DeletedDate IS NULL
         ORDER BY rp.CreatedDate DESC, rp.ReportId DESC
         LIMIT 1),
        t.Content
    )                                                                       AS tinh_hinh_ket_qua,

    /* 7. LÃNH ĐẠO UBND / VĂN PHÒNG & CHUYÊN VIÊN VP THEO DÕI */
    ppl.ld_ubnd,
    ppl.ld_van_phong,
    IF(u_create.DepartmentPath LIKE '490.698.752%', NULLIF(d_create.name, ''), NULL)              AS phong_chuyen_mon_theo_doi,
    IF(u_create.DepartmentPath LIKE '490.698.752%', NULLIF(u_create.eGovUserFullname, ''), NULL)  AS chuyen_vien_vp_theo_doi,

    /* 8. KHÓA HỆ THỐNG & ĐỒNG BỘ */
    t.TaskId                                                                AS task_id,
    /* id_cha: task_id đầu tiên (nhỏ nhất) cùng (tên nhiệm vụ, văn bản giao, trục giao) + '_GR', khớp id_cha bảng gộp */
    MAX(g.id_cha)                                                           AS id_cha,
    t.Status                                                                AS status,
    '${sync_ts}'                                                            AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* RESOLUTION */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL

/* LĨNH VỰC VĂN BẢN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_sector` s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

/* CHỦ ĐỀ NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn`.`qlnv_task_topic` tp
       ON tp.TopicId = t.TopicId

/* TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = IF(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$',
                                CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED), NULL)
      AND d_assign_cap2.IsDelete = 0

/* ĐƠN VỊ CHỦ TRÌ (id cuối của mã đã chuẩn hóa cấp) */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = IF(
              SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                 SUBSTRING_INDEX(t.TargetDepartment, '.', 4),
                                 SUBSTRING_INDEX(t.TargetDepartment, '.', 3)), '.', -1) REGEXP '^[0-9]+$',
              CAST(SUBSTRING_INDEX(IF(t.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                                      SUBSTRING_INDEX(t.TargetDepartment, '.', 4),
                                      SUBSTRING_INDEX(t.TargetDepartment, '.', 3)), '.', -1) AS UNSIGNED),
              NULL)
      AND d_chutri.IsDelete = 0

/* NGƯỜI TẠO & PHÒNG BAN NGƯỜI TẠO */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = IF(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) REGEXP '^[0-9]+$',
                           CAST(SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED), NULL)
      AND d_create.IsDelete = 0

/* NGƯỜI LIÊN QUAN THEO TASK */
LEFT JOIN (
    SELECT
        p.TaskId,

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
                  AND COALESCE(NULLIF(u.DepartmentPath, ''), p.dept) LIKE CONCAT(
                          IF(p.TargetDepartment REGEXP '^490[.]698[.](1841|1307|1310)',
                             SUBSTRING_INDEX(p.TargetDepartment, '.', 4),
                             SUBSTRING_INDEX(p.TargetDepartment, '.', 3)), '%')
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
        WHERE t2.AssignDepartment = '490.698' AND t2.DeletedDate IS NULL AND t2.TargetDepartment LIKE '490.698.%'
        UNION ALL
        SELECT t2.TaskId, 1, NULL, NULL, t2.TargetUser, NULLIF(t2.TargetDepartment, ''), t2.TargetDepartment
        FROM `db_theodoinv_hn`.`qlnv_task` t2
        WHERE t2.AssignDepartment = '490.698' AND t2.DeletedDate IS NULL AND t2.TargetDepartment LIKE '490.698.%'
          AND t2.TargetUser IS NOT NULL
        UNION ALL
        SELECT t2.TaskId, 2, NULL, NULL, t2.AssignUser, NULLIF(t2.AssignDepartment, ''), t2.TargetDepartment
        FROM `db_theodoinv_hn`.`qlnv_task` t2
        WHERE t2.AssignDepartment = '490.698' AND t2.DeletedDate IS NULL AND t2.TargetDepartment LIKE '490.698.%'
          AND t2.AssignUser IS NOT NULL
    ) p
    INNER JOIN `db_theodoinv_hn`.`qlnv_user` u
            ON u.eGovUserId = p.UserId

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

/* NHÓM GỘP (cùng khóa GROUP BY ten_nhiem_vu, id_truc_giao của qlnv_tonghop_gop_nvgiao_pth_ubndtp)
   Điều kiện lọc phải giữ giống hệt WHERE bên dưới để MIN(TaskId) khớp bảng gộp.
   MySQL 5.7 không có MIN() OVER (...); Title varchar(6000) không tạo được auto key cho bảng dẫn xuất
   => JOIN theo MD5(Title || DocCode) 32 ký tự (JOIN thẳng Title bị nested loop > 60s). */
LEFT JOIN (
    SELECT MD5(CONCAT(COALESCE(t3.Title, ''), '||', COALESCE(t3.DocCode, ''))) AS title_md5, t3.AssignDepartment, CONCAT(MIN(t3.TaskId), '_GR') AS id_cha
    FROM `db_theodoinv_hn`.`qlnv_task` t3
    INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r3
            ON r3.ResolutionId = t3.ResolutionId
           AND r3.DeletedDate IS NULL
    WHERE t3.DeletedDate IS NULL
      AND (   t3.Status IN (-1, 0, 1, 2)
           OR (t3.Status IN (3, 4) AND (t3.ExpireDate IS NULL OR COALESCE(t3.CompletedDate, t3.ApprovedDate) IS NOT NULL)))
      AND t3.AssignDepartment = '490.698'
      AND t3.TargetDepartment LIKE '490.698.%'
      AND t3.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')
    GROUP BY MD5(CONCAT(COALESCE(t3.Title, ''), '||', COALESCE(t3.DocCode, ''))), t3.AssignDepartment
) g
       ON g.title_md5 = MD5(CONCAT(COALESCE(t.Title, ''), '||', COALESCE(t.DocCode, '')))
      AND g.AssignDepartment = t.AssignDepartment

WHERE t.DeletedDate IS NULL
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4) AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))
  AND t.AssignDepartment = '490.698'
  AND t.TargetDepartment LIKE '490.698.%'
  AND t.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')

GROUP BY t.TaskId

/* UPSERT theo PK task_id thay cho TRUNCATE + INSERT: bảng không bị rỗng giữa chu kỳ.
   Bản ghi không còn thỏa điều kiện bị xóa ở bước sau (sync_date < ${sync_ts}). */
ON DUPLICATE KEY UPDATE
    id_truc_giao = VALUES(id_truc_giao),
    truc_giao = VALUES(truc_giao),
    nhom_van_ban = VALUES(nhom_van_ban),
    linh_vuc = VALUES(linh_vuc),
    chu_de = VALUES(chu_de),
    muc_do_uu_tien = VALUES(muc_do_uu_tien),
    nv_quantam = VALUES(nv_quantam),
    ma_nhiem_vu = VALUES(ma_nhiem_vu),
    ten_nhiem_vu = VALUES(ten_nhiem_vu),
    van_ban_giao = VALUES(van_ban_giao),
    id_don_vi_chu_tri = VALUES(id_don_vi_chu_tri),
    ten_don_vi_chu_tri = VALUES(ten_don_vi_chu_tri),
    lanh_dao_don_vi_va_chuyen_vien = VALUES(lanh_dao_don_vi_va_chuyen_vien),
    ngay_giao = VALUES(ngay_giao),
    han_xu_ly = VALUES(han_xu_ly),
    ngay_hoan_thanh = VALUES(ngay_hoan_thanh),
    ngay_xoa = VALUES(ngay_xoa),
    tinh_trang = VALUES(tinh_trang),
    tinh_hinh_ket_qua = VALUES(tinh_hinh_ket_qua),
    ld_ubnd = VALUES(ld_ubnd),
    ld_van_phong = VALUES(ld_van_phong),
    phong_chuyen_mon_theo_doi = VALUES(phong_chuyen_mon_theo_doi),
    chuyen_vien_vp_theo_doi = VALUES(chuyen_vien_vp_theo_doi),
    id_cha = VALUES(id_cha),
    status = VALUES(status),
    sync_date = VALUES(sync_date);
