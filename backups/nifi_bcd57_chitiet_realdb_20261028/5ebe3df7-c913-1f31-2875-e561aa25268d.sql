INSERT INTO `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_cap_tp` (
    `task_id`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `nguon_giao`,
    `van_ban_giao`,
    `loai_van_ban`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `chu_de`,
    `nhom_nhiem_vu`,
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
    `tien_do`,
    `ket_qua_thuc_hien`,
    `kho_khan_vuong_mac`,
    `de_xuat_kien_nghi`,
    `sync_date`
)

/* =======================================================================
   NHIỆM VỤ BCĐ 57 TỪ EXCEL — cùng bộ cột với qlnv_chitiet_bcd57_cap_tp.sql, 2 phần:
     PHẦN 1: Nhiệm vụ Thành phố  <- datamart_hanoi.nv57_thanhuy_giao_excel
     PHẦN 2: Nhiệm vụ Trung ương <- datamart_hanoi.nv57_tla_chitiet_excel
   Cột Excel có -> lấy Excel; cột Excel không có -> tính như qlnv_chitiet_bcd57_cap_tp.sql
   từ task QLNV khớp (qlnv_task + báo cáo mới nhất + đơn vị + user).
   Khớp task: task gốc, chưa xoá, Status <> 5; nhiều task trùng -> ngày giao mới nhất, rồi TaskId lớn hơn.
     - Thành phố : khớp tên
     - Trung ương: khớp mã nhiệm vụ (Code), không có thì khớp tên
   Chuẩn hoá tên (giống check.sql): CR/LF/TAB -> space, gộp space, bỏ dấu "." cuối, không phân biệt hoa thường.
   Không khớp task QLNV -> task_id âm: Thành phố = -id, Trung ương = -(1000000 + id).
   ======================================================================= */

/* ============================ PHẦN 1: NHIỆM VỤ THÀNH PHỐ ============================ */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    COALESCE(t.TaskId, -ex.id)                              AS task_id,
    t.Status                                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(TRIM(ex.truc), ''), NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,
    'Nhiệm vụ Thành phố'                                    AS nguon_giao,
    COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), IF(TRIM(t.DocCode) = '1', 'TT', t.DocCode)) AS van_ban_giao,
    /* Loại văn bản (4 nhóm), tính trên văn bản Excel, thiếu thì DocCode:
         TT (= '1')                            -> NV trọng tâm
         mã chứa 'KH' (vd 20-KH/BCĐ57)          -> Kế hoạch
         mã chứa 'TB' hoặc 'KL' (gồm cả TBKL)  -> TBKL
         còn lại (kể cả rỗng)                  -> Công văn */
    CASE
        WHEN TRIM(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) = '1'            THEN 'NV trọng tâm'
        WHEN UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%KH%'     THEN 'Kế hoạch'
        WHEN UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%TB%'
          OR UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%KL%'     THEN 'TBKL'
        ELSE 'Công văn'
    END                                                     AS loai_van_ban,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    ex.ten_nhiem_vu                                         AS ten_nhiem_vu,
    COALESCE(NULLIF(tp.TopicName, ''), 'Chưa phân loại')    AS chu_de,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS nhom_nhiem_vu,

    /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(d_assign.name, NULLIF(t.AssignOrganization, '')) AS don_vi_giao,
    t.AssignUser                                            AS id_nguoi_giao,
    u_assign.eGovUserFullname                               AS nguoi_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    COALESCE(
        NULLIF(TRIM(ex.co_quan_chu_tri), ''),
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        d_cap.name,
        d_donvi.name
    )                                                       AS ten_don_vi_chu_tri,
    COALESCE(
        d_donvi.name,
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        NULLIF(TRIM(ex.co_quan_chu_tri), '')
    )                                                       AS ten_don_vi_thuc_hien,
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    u_target.eGovUserFullname                               AS nguoi_thuc_hien,
    CONCAT_WS(' · ',
        COALESCE(u_target.eGovUserPositionName, NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 5. CÁC MỐC THỜI GIAN (hạn ưu tiên Excel) */
    DATE_FORMAT(t.StartedDate, '%Y-%m-%d')                  AS ngay_giao,
    COALESCE(ex.han_excel, DATE_FORMAT(t.ExpireDate, '%Y-%m-%d')) AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%Y-%m-%d')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%Y-%m-%d')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%Y-%m-%d')                  AS ngay_xoa,

    /* 6. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN: ưu tiên Excel, Excel không đủ thông tin -> như bản QLNV */
    CASE
        WHEN ex.tinh_trang LIKE '%hoàn thành%' AND ex.tinh_trang NOT LIKE '%chưa%'
        THEN 'Đã hoàn thành'
        WHEN ex.thoi_han_text LIKE '%thường xuyên%'
        THEN 'Thường xuyên'
        WHEN ex.han_excel >= DATE_FORMAT(CURDATE(), '%Y-%m-%d')
        THEN 'Chưa hoàn thành trong hạn'
        WHEN ex.han_excel IS NOT NULL
          OR ex.trang_thai_han LIKE '%quá hạn%'
        THEN 'Chưa hoàn thành quá hạn'

        /* Theo QLNV (giống qlnv_chitiet_bcd57_cap_tp.sql) */
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'
        WHEN DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'
        ELSE 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    /* Tiến độ (%): đã hoàn thành (Excel) / kết thúc (QLNV) tính 100 */
    CASE
        WHEN ex.tinh_trang LIKE '%hoàn thành%' AND ex.tinh_trang NOT LIKE '%chưa%' THEN 100
        WHEN t.Status IN (3, 4) THEN 100
        ELSE COALESCE(t.Progress, 0)
    END                                                     AS tien_do,

    /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (sản phẩm Excel, thiếu thì báo cáo mới nhất) */
    COALESCE(NULLIF(TRIM(ex.san_pham), ''), rp.Content, t.Content, '—') AS ket_qua_thuc_hien,
    COALESCE(NULLIF(rp.Difficulty, ''), '—')                AS kho_khan_vuong_mac,
    COALESCE(NULLIF(rp.Suggestion, ''), '—')                AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

/* NHIỆM VỤ EXCEL THÀNH ỦY GIAO + khóa tên chuẩn hoá */
FROM (
    SELECT
        x.*,
        MD5(LOWER(TRIM(TRIM(TRAILING '.' FROM TRIM(
            REPLACE(REPLACE(REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(CONVERT(IFNULL(x.ten_nhiem_vu, '') USING utf8mb4), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '  ', ' '), '  ', ' '), '  ', ' '), '  ', ' ')))))) AS ten_hash,
        /* Hạn trong Excel -> yyyy-mm-dd:
             yyyy-mm-dd[...] / dd/mm/yyyy[...] -> ngày đó; chỉ có năm (vd '2026') -> 31/12 năm đó;
             rỗng / 0000-00-00 / dạng khác -> NULL (tránh đẩy '2026' vào cột ngày) */
        CASE
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}'
             AND LEFT(TRIM(CAST(x.thoi_han AS CHAR)), 4) <> '0000'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.thoi_han AS CHAR)), ' ', 1), '%Y-%m-%d'), '%Y-%m-%d')
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.thoi_han AS CHAR)), ' ', 1), '%d/%m/%Y'), '%Y-%m-%d')
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{4}$'
             AND TRIM(CAST(x.thoi_han AS CHAR)) <> '0000'
            THEN CONCAT(TRIM(CAST(x.thoi_han AS CHAR)), '-12-31')
            ELSE NULL
        END                                                 AS han_excel
    FROM `datamart_hanoi`.`nv57_thanhuy_giao_excel` x
) ex

/* TASK QLNV KHỚP TÊN (mỗi tên 1 task) */
LEFT JOIN (
    SELECT
        e.ten_hash,
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(e.StartedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(e.TaskId, 20, '0')
            )), 15) AS UNSIGNED)                            AS TaskId
    FROM (
        SELECT
            e0.TaskId,
            e0.StartedDate,
            MD5(LOWER(TRIM(TRIM(TRAILING '.' FROM TRIM(
                REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(CONVERT(IFNULL(e0.Title, '') USING utf8mb4), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
                '  ', ' '), '  ', ' '), '  ', ' '), '  ', ' ')))))) AS ten_hash
        FROM `db_theodoinv_hn_test_data`.`qlnv_task` e0
        WHERE e0.DeletedDate IS NULL
          AND e0.ParentId IS NULL
          AND e0.Status <> 5
    ) e
    GROUP BY e.ten_hash
) k
       ON k.ten_hash = ex.ten_hash
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_task` t
       ON t.TaskId = k.TaskId

/* BÁO CÁO MỚI NHẤT CỦA TASK (CreatedDate mới nhất; trùng -> ReportId lớn hơn) */
LEFT JOIN (
    SELECT
        rp0.TaskId,
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(rp0.CreatedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(rp0.ReportId, 20, '0')
            )), 15) AS UNSIGNED)                            AS ReportId
    FROM `db_theodoinv_hn_test_data`.`qlnv_report` rp0
    WHERE rp0.DeletedDate IS NULL
    GROUP BY rp0.TaskId
) lr
       ON lr.TaskId = t.TaskId
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_report` rp
       ON rp.ReportId = lr.ReportId

/* CHỦ ĐỀ */
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_task_topic` tp
       ON tp.TopicId = t.TopicId

/* TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* ĐƠN VỊ GIAO */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign
       ON d_assign.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign.IsDelete = 0

/* NGƯỜI GIAO (khử trùng eGovUserId) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* PHÒNG BAN ĐƠN VỊ NHẬN */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_cap
       ON d_cap.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_cap.IsDelete = 0
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_donvi
       ON d_donvi.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_donvi.IsDelete = 0

/* USER NHẬN (khử trùng eGovUserId) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_target
       ON u_target.eGovUserId = t.TargetUser

UNION ALL

/* ============================ PHẦN 2: NHIỆM VỤ TRUNG ƯƠNG ============================ */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    COALESCE(t.TaskId, -(1000000 + ex.id))                  AS task_id,
    t.Status                                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,
    'Nhiệm vụ Trung ương'                                   AS nguon_giao,
    COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), IF(TRIM(t.DocCode) = '1', 'TT', t.DocCode)) AS van_ban_giao,
    CASE
        WHEN TRIM(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) = '1'            THEN 'NV trọng tâm'
        WHEN UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%KH%'     THEN 'Kế hoạch'
        WHEN UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%TB%'
          OR UPPER(COALESCE(NULLIF(TRIM(ex.van_ban_giao), ''), t.DocCode)) LIKE '%KL%'     THEN 'TBKL'
        ELSE 'Công văn'
    END                                                     AS loai_van_ban,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    COALESCE(NULLIF(TRIM(ex.ma_nhiem_vu), ''), t.Code)      AS ma_nhiem_vu,
    ex.ten_nhiem_vu                                         AS ten_nhiem_vu,
    COALESCE(NULLIF(TRIM(ex.chu_de_nhiem_vu), ''), NULLIF(tp.TopicName, ''), 'Chưa phân loại') AS chu_de,
    COALESCE(NULLIF(t.NameGroup, ''), 'Chưa phân loại')     AS nhom_nhiem_vu,

    /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
    t.AssignDepartment                                      AS id_don_vi_giao,
    COALESCE(d_assign.name, NULLIF(t.AssignOrganization, '')) AS don_vi_giao,
    t.AssignUser                                            AS id_nguoi_giao,
    u_assign.eGovUserFullname                               AS nguoi_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    COALESCE(
        NULLIF(TRIM(ex.co_quan_chu_tri), ''),
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, ''),
        d_cap.name,
        d_donvi.name
    )                                                       AS ten_don_vi_chu_tri,
    COALESCE(
        NULLIF(TRIM(ex.don_vi_thuc_hien), ''),
        d_donvi.name,
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, '')
    )                                                       AS ten_don_vi_thuc_hien,
    t.TargetUser                                            AS id_nguoi_thuc_hien,
    u_target.eGovUserFullname                               AS nguoi_thuc_hien,
    CONCAT_WS(' · ',
        COALESCE(u_target.eGovUserPositionName, NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 5. CÁC MỐC THỜI GIAN (hạn, ngày hoàn thành ưu tiên Excel) */
    DATE_FORMAT(t.StartedDate, '%Y-%m-%d')                  AS ngay_giao,
    COALESCE(ex.han_excel, DATE_FORMAT(t.ExpireDate, '%Y-%m-%d')) AS han_xu_ly,
    COALESCE(ex.ngay_ht_excel, DATE_FORMAT(t.CompletedDate, '%Y-%m-%d')) AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%Y-%m-%d')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%Y-%m-%d')                  AS ngay_xoa,

    /* 6. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN: ưu tiên Excel (trang_thai), không đủ thông tin -> như bản QLNV */
    CASE
        WHEN ex.trang_thai LIKE '%hoàn thành%' AND ex.trang_thai NOT LIKE '%chưa%'
        THEN 'Đã hoàn thành'
        WHEN ex.trang_thai LIKE '%thường xuyên%'
          OR ex.thoi_han_text LIKE '%thường xuyên%'
        THEN 'Thường xuyên'
        WHEN ex.trang_thai LIKE '%quá hạn%'
        THEN 'Chưa hoàn thành quá hạn'
        WHEN ex.han_excel >= DATE_FORMAT(CURDATE(), '%Y-%m-%d')
        THEN 'Chưa hoàn thành trong hạn'
        WHEN ex.han_excel IS NOT NULL
        THEN 'Chưa hoàn thành quá hạn'

        /* Theo QLNV (giống qlnv_chitiet_bcd57_cap_tp.sql) */
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'
        WHEN DATE(t.ExpireDate) >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'
        ELSE 'Chưa hoàn thành quá hạn'
    END                                                     AS tinh_trang,

    CASE
        WHEN ex.trang_thai LIKE '%hoàn thành%' AND ex.trang_thai NOT LIKE '%chưa%' THEN 100
        WHEN t.Status IN (3, 4) THEN 100
        ELSE COALESCE(t.Progress, 0)
    END                                                     AS tien_do,

    /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Excel, thiếu thì báo cáo mới nhất) */
    COALESCE(NULLIF(TRIM(ex.mo_ta), ''), rp.Content, t.Content, '—') AS ket_qua_thuc_hien,
    COALESCE(NULLIF(TRIM(ex.kho_khan), ''), NULLIF(rp.Difficulty, ''), '—') AS kho_khan_vuong_mac,
    COALESCE(NULLIF(TRIM(ex.de_xuat_kien_nghi), ''), NULLIF(rp.Suggestion, ''), '—') AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

/* NHIỆM VỤ EXCEL TRUNG ƯƠNG + khóa mã / tên chuẩn hoá */
FROM (
    SELECT
        x.*,
        MD5(LOWER(TRIM(CONVERT(IFNULL(x.ma_nhiem_vu, '') USING utf8mb4)))) AS ma_hash,
        MD5(LOWER(TRIM(TRIM(TRAILING '.' FROM TRIM(
            REPLACE(REPLACE(REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(CONVERT(IFNULL(x.ten_nhiem_vu, '') USING utf8mb4), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
            '  ', ' '), '  ', ' '), '  ', ' '), '  ', ' ')))))) AS ten_hash,
        /* Ngày Excel -> yyyy-mm-dd (cùng quy tắc phần 1); dạng khác -> NULL */
        CASE
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}'
             AND LEFT(TRIM(CAST(x.thoi_han AS CHAR)), 4) <> '0000'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.thoi_han AS CHAR)), ' ', 1), '%Y-%m-%d'), '%Y-%m-%d')
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.thoi_han AS CHAR)), ' ', 1), '%d/%m/%Y'), '%Y-%m-%d')
            WHEN TRIM(CAST(x.thoi_han AS CHAR)) REGEXP '^[0-9]{4}$'
             AND TRIM(CAST(x.thoi_han AS CHAR)) <> '0000'
            THEN CONCAT(TRIM(CAST(x.thoi_han AS CHAR)), '-12-31')
            ELSE NULL
        END                                                 AS han_excel,
        CASE
            WHEN TRIM(CAST(x.ngay_hoan_thanh_thuc_te AS CHAR)) REGEXP '^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}'
             AND LEFT(TRIM(CAST(x.ngay_hoan_thanh_thuc_te AS CHAR)), 4) <> '0000'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.ngay_hoan_thanh_thuc_te AS CHAR)), ' ', 1), '%Y-%m-%d'), '%Y-%m-%d')
            WHEN TRIM(CAST(x.ngay_hoan_thanh_thuc_te AS CHAR)) REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
            THEN DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(TRIM(CAST(x.ngay_hoan_thanh_thuc_te AS CHAR)), ' ', 1), '%d/%m/%Y'), '%Y-%m-%d')
            ELSE NULL
        END                                                 AS ngay_ht_excel
    FROM `datamart_hanoi`.`nv57_tla_chitiet_excel` x
) ex

/* TASK QLNV KHỚP MÃ NHIỆM VỤ (mỗi mã 1 task) */
LEFT JOIN (
    SELECT
        MD5(LOWER(TRIM(CONVERT(e.Code USING utf8mb4)))) AS ma_hash,
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(e.StartedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(e.TaskId, 20, '0')
            )), 15) AS UNSIGNED)                            AS TaskId
    FROM `db_theodoinv_hn_test_data`.`qlnv_task` e
    WHERE e.DeletedDate IS NULL
      AND e.ParentId IS NULL
      AND e.Status <> 5
      AND NULLIF(TRIM(e.Code), '') IS NOT NULL
    GROUP BY MD5(LOWER(TRIM(CONVERT(e.Code USING utf8mb4))))
) kc
       ON kc.ma_hash = ex.ma_hash
      AND NULLIF(TRIM(ex.ma_nhiem_vu), '') IS NOT NULL

/* TASK QLNV KHỚP TÊN (mỗi tên 1 task) — dùng khi không khớp mã */
LEFT JOIN (
    SELECT
        e.ten_hash,
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(e.StartedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(e.TaskId, 20, '0')
            )), 15) AS UNSIGNED)                            AS TaskId
    FROM (
        SELECT
            e0.TaskId,
            e0.StartedDate,
            MD5(LOWER(TRIM(TRIM(TRAILING '.' FROM TRIM(
                REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(CONVERT(IFNULL(e0.Title, '') USING utf8mb4), CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' '),
                '  ', ' '), '  ', ' '), '  ', ' '), '  ', ' ')))))) AS ten_hash
        FROM `db_theodoinv_hn_test_data`.`qlnv_task` e0
        WHERE e0.DeletedDate IS NULL
          AND e0.ParentId IS NULL
          AND e0.Status <> 5
    ) e
    GROUP BY e.ten_hash
) k
       ON k.ten_hash = ex.ten_hash
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_task` t
       ON t.TaskId = COALESCE(kc.TaskId, k.TaskId)

/* BÁO CÁO MỚI NHẤT CỦA TASK (CreatedDate mới nhất; trùng -> ReportId lớn hơn) */
LEFT JOIN (
    SELECT
        rp0.TaskId,
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(rp0.CreatedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(rp0.ReportId, 20, '0')
            )), 15) AS UNSIGNED)                            AS ReportId
    FROM `db_theodoinv_hn_test_data`.`qlnv_report` rp0
    WHERE rp0.DeletedDate IS NULL
    GROUP BY rp0.TaskId
) lr
       ON lr.TaskId = t.TaskId
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_report` rp
       ON rp.ReportId = lr.ReportId

/* CHỦ ĐỀ */
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_task_topic` tp
       ON tp.TopicId = t.TopicId

/* TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* ĐƠN VỊ GIAO */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign
       ON d_assign.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign.IsDelete = 0

/* NGƯỜI GIAO (khử trùng eGovUserId) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* PHÒNG BAN ĐƠN VỊ NHẬN */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_cap
       ON d_cap.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_cap.IsDelete = 0
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_donvi
       ON d_donvi.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_donvi.IsDelete = 0

/* USER NHẬN (khử trùng eGovUserId) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_target
       ON u_target.eGovUserId = t.TargetUser;
