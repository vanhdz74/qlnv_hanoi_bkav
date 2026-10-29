INSERT INTO `datamart_hanoi`.`qlnv_chitiet_nvgiao_pth_ubndtp` (
    `task_id`,
    `id_cha`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `van_ban_giao`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `chu_de`,
    `id_don_vi_giao`,
    `don_vi_giao`,
    `id_nguoi_giao`,
    `nguoi_giao`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `ten_don_vi_thuc_hien`,
    `id_nguoi_thuc_hien`,
    `nguoi_thuc_hien`,
    `lanh_dao_ban_phu_trach`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_chap_nhan`,
    `ngay_xoa`,
    `tinh_trang`,
    `ket_qua_thuc_hien`,
    `kho_khan_vuong_mac`,
    `de_xuat_kien_nghi`,
    `sync_date`
)

SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    /* id_cha: task_id đầu tiên (nhỏ nhất) cùng (tên nhiệm vụ, văn bản giao, trục giao) + '_GR', khớp id_cha bảng gộp */
    MAX(g.id_cha)                                           AS id_cha,
    t.Status                                                AS status,

    /* 2. NHÓM NHIỆM VỤ / TRỤC GIAO & VĂN BẢN GIAO */
    t.AssignDepartment                                      AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,
    t.DocCode                                               AS van_ban_giao,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS chu_de,

    /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(MAX(d_assign.name), NULLIF(t.AssignOrganization, '')) AS don_vi_giao,
    t.AssignUser                                            AS id_nguoi_giao,
    MAX(u_assign.eGovUserFullname)                          AS nguoi_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (CHUẨN HÓA CẤP) */
    CASE
        /* Nhánh 1841 / 1307 / 1310: chỉ đẩy về cấp 4 (cấp 5 -> cấp 4) */
        WHEN t.TargetDepartment LIKE '490.698.1841%'
          OR t.TargetDepartment LIKE '490.698.1307%'
          OR t.TargetDepartment LIKE '490.698.1310%'
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        /* Còn lại: đẩy về cấp 3 (cấp 4 trở lên -> cấp 3) */
        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
    END                                                     AS id_don_vi_chu_tri,

    COALESCE(
        MAX(d_chutri.name)
    )                                                       AS ten_don_vi_chu_tri,

    COALESCE(
        MAX(d_donvi.name)
    )                                                       AS ten_don_vi_thuc_hien,

    /* 5. NGƯỜI THỰC HIỆN & LÃNH ĐẠO BAN PHỤ TRÁCH */
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    MAX(u_target.eGovUserFullname)                          AS nguoi_thuc_hien,

    CONCAT_WS(' · ',
        COALESCE(MAX(u_target.eGovUserPositionName), NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%d/%m/%Y')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                  AS ngay_xoa,

    /* 7. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
    CASE
        /* 1. Đã hoàn thành (đúng hạn hoặc quá hạn) */
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'

        /* 2. Thường xuyên (nhiệm vụ không có hạn) */
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        /* 3. Chưa hoàn thành trong hạn */
        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        /* 4. Chưa hoàn thành quá hạn */
        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND DATE(t.ExpireDate) < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    /* 8. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Lấy bản ghi mới nhất) */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        t.Content,
        '—'
    )                                                       AS ket_qua_thuc_hien,

    COALESCE(
        (
            SELECT NULLIF(rp.Difficulty, '') 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        '—'
    )                                                       AS kho_khan_vuong_mac,

    COALESCE(
        (
            SELECT NULLIF(rp.Suggestion, '') 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        '—'
    )                                                       AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN NHÓM NHIỆM VỤ: LỌC TRỰC TIẾP ID NHÓM '55', 132 */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL
    --    AND r.ResolutionGroupId IN (55, 132)

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ GIAO (BÓC TÁCH ID TỪ T.ASSIGNDEPARTMENT ĐỂ LẤY TÊN) */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign
       ON d_assign.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign.IsDelete = 0

/* JOIN NGƯỜI GIAO NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_assign
       ON u_assign.eGovUserId = t.AssignUser

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

LEFT JOIN `db_theodoinv_hn`.`department` d_donvi
       ON d_donvi.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_donvi.IsDelete = 0

/* JOIN USER NHẬN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

/* JOIN NHÓM GỘP (cùng khóa GROUP BY ten_nhiem_vu, id_truc_giao của qlnv_tonghop_gop_nvgiao_pth_ubndtp)
   Điều kiện lọc phải giữ giống hệt WHERE bên dưới để MIN(TaskId) khớp bảng gộp.
   MySQL 5.7 không có MIN() OVER (...) => dùng subquery gom nhóm.
   Title là varchar(6000) => không tạo được auto key cho bảng dẫn xuất, JOIN thẳng theo Title
   thành nested loop N x M (> 60s, bị cắt kết nối) => JOIN theo MD5(Title || DocCode) 32 ký tự. */
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

/* ĐIỀU KIỆN LẤY TASK: đồng bộ với qlnv_tonghop_chitiet_nvgiao_pth_ubndtp */
WHERE t.DeletedDate IS NULL
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4) AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))
  /* UBND giao (đúng 490.698) cho đơn vị con 490.698.x, trừ 1307 / 1841 / 1310 */
  AND t.AssignDepartment = '490.698'
  AND t.TargetDepartment LIKE '490.698.%'
  AND t.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')
  /* Loại nhóm văn bản 82, 109 */
--   AND r.ResolutionGroupId NOT IN (82, 109)

/* GOM NHÓM THEO TASK_ID ĐỂ KHỬ TRÙNG LẶP */
GROUP BY t.TaskId;
