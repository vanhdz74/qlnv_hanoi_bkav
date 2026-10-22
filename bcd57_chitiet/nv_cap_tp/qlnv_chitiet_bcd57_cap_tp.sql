
/* =======================================================================
   NHIỆM VỤ BCĐ 57 TỪ HỆ THỐNG QLNV (qlnv_task) — 1 nhánh duy nhất:
     nhiệm vụ nghị quyết nhóm 55 (trừ xã/phường) + nhiệm vụ Trung ương giao (DocCode 'NQ%')
   ======================================================================= */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    t.Status                                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,

    /* NGUỒN GIAO */
    CASE
        /* Trung ương giao: số văn bản bắt đầu bằng 'NQ' */
        WHEN t.DocCode LIKE 'NQ%'
        THEN 'Nhiệm vụ Trung ương'

        /* Còn lại: Ban Chỉ đạo, Thành ủy, HĐND, UBND TP, sở ngành TP giao */
        ELSE 'Nhiệm vụ Thành phố'
    END                                                     AS nguon_giao,
    /* Số văn bản '1' (nhiệm vụ trọng tâm) hiển thị là 'TT' */
    IF(TRIM(t.DocCode) = '1', 'TT', t.DocCode)              AS van_ban_giao,
    /* Loại văn bản (4 nhóm):
         TT (DocCode = '1')                    -> NV trọng tâm
         mã chứa 'KH' (vd 20-KH/BCĐ57)          -> Kế hoạch
         mã chứa 'TB' hoặc 'KL' (gồm cả TBKL)  -> TBKL
         còn lại (kể cả rỗng)                  -> Công văn */
    CASE
        /* Số văn bản '1' -> nhiệm vụ trọng tâm (TT) */
        WHEN TRIM(t.DocCode) = '1'                                    THEN 'NV trọng tâm'
        WHEN UPPER(t.DocCode) LIKE '%KH%'                                  THEN 'Kế hoạch'
        WHEN UPPER(t.DocCode) LIKE '%TB%' OR UPPER(t.DocCode) LIKE '%KL%'   THEN 'TBKL'
        ELSE 'Công văn'
    END                                                     AS loai_van_ban,

    /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
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
        NULLIF(t.ResponsibleUnit, ''), 
        NULLIF(t.TargetOrganization, ''), 
        d_cap.name,
        d_donvi.name
    )                                                       AS ten_don_vi_chu_tri,
    
    COALESCE(
        d_donvi.name,
        NULLIF(t.ResponsibleUnit, ''),
        NULLIF(t.TargetOrganization, '')
    )                                                       AS ten_don_vi_thuc_hien,

    t.TargetUser                                            AS id_nguoi_thuc_hien,
    u_target.eGovUserFullname                               AS nguoi_thuc_hien,

    /* Lãnh đạo ban phụ trách */
    CONCAT_WS(' · ',
        COALESCE(u_target.eGovUserPositionName, NULLIF(t.ChargeUser, ''))
    )                                                       AS lanh_dao_ban_phu_trach,

    /* 5. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%Y-%m-%d')                  AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%Y-%m-%d')                   AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%Y-%m-%d')                AS ngay_hoan_thanh,
    DATE_FORMAT(t.ApprovedDate, '%Y-%m-%d')                 AS ngay_chap_nhan,
    DATE_FORMAT(t.DeletedDate, '%Y-%m-%d')                  AS ngay_xoa,

    /* 6. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
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

    /* Tiến độ (%): đã hoàn thành/kết thúc tính 100 */
    IF(t.Status IN (3, 4), 100, COALESCE(t.Progress, 0))    AS tien_do,

    /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (bản ghi mới nhất, JOIN rp) */
    COALESCE(rp.Content, t.Content, '—')                    AS ket_qua_thuc_hien,
    COALESCE(NULLIF(rp.Difficulty, ''), '—')                AS kho_khan_vuong_mac,
    COALESCE(NULLIF(rp.Suggestion, ''), '—')                AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

/* DANH SÁCH TASK CẦN LẤY: lọc điều kiện BCĐ 57 + mỗi tiêu đề chỉ giữ 1 task
   (ngày giao mới nhất; cùng ngày giao -> TaskId lớn hơn) */
FROM (
    SELECT
        CAST(SUBSTRING(
            MAX(CONCAT(
                COALESCE(DATE_FORMAT(e.StartedDate, '%Y%m%d%H%i%s'), '00000000000000'),
                LPAD(e.TaskId, 20, '0')
            )), 15) AS UNSIGNED)                            AS TaskId
    FROM `db_theodoinv_hn_test_data`.`qlnv_task` e
    WHERE e.DeletedDate IS NULL
      /* Chỉ lấy nhiệm vụ gốc (không lấy nhiệm vụ con) */
      AND e.ParentId IS NULL
      AND e.Status <> 5

      /* Tương đương tinh_trang <> 'Chưa xác định' của bản cũ */
      AND (   e.Status IN (-1, 0, 1, 2)
           OR (e.Status IN (3, 4)
               AND (   COALESCE(e.IsRecurring, 0) = 1
                    OR e.ExpireDate IS NULL
                    OR COALESCE(e.CompletedDate, e.ApprovedDate) IS NOT NULL)))

      AND (
          /* Nhiệm vụ Trung ương giao */
          e.DocCode LIKE 'NQ%'

          OR

          /* Nhiệm vụ BCĐ 57 cấp Thành phố */
          (
              /* Thuộc nghị quyết nhóm 55 (qlnv_resolution -> qlnv_task_resolution -> qlnv_task),
                 EXISTS để 1 task gắn nhiều nghị quyết nhóm 55 không bị nhân dòng */
              EXISTS (
                  SELECT 1
                  FROM `db_theodoinv_hn_test_data`.`qlnv_task_resolution` tr
                  INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_resolution` r
                          ON r.ResolutionId = tr.ResolutionId
                  WHERE tr.TaskId = e.TaskId
                    AND r.ResolutionGroupId = 55
                    AND r.DeletedDate IS NULL
              )

              /* Xã/phường (490.698.1310.%) tách sang tab 2 -> qlnv_chitiet_bcd57_xaphuong */
              AND COALESCE(e.OriginalTargetDepartment, '') NOT LIKE '490.698.1310.%'
          )
      )
    GROUP BY TRIM(e.Title)
) k
INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_task` t
        ON t.TaskId = k.TaskId

/* BÁO CÁO MỚI NHẤT CỦA TASK: gom 1 lần theo TaskId (CreatedDate mới nhất; trùng -> ReportId lớn hơn),
   thay cho JOIN theo subquery tương quan (quét lại qlnv_report cho từng task -> rất chậm) */
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

/* CHỦ ĐỀ (1 TopicId / task -> không nhân dòng) */
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_task_topic` tp
       ON tp.TopicId = t.TopicId

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign_cap2
       ON d_assign_cap2.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ GIAO (BÓC TÁCH ID TỪ T.ASSIGNDEPARTMENT ĐỂ LẤY TÊN) */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_assign
       ON d_assign.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND d_assign.IsDelete = 0

/* JOIN NGƯỜI GIAO NHIỆM VỤ (danh bạ user đã khử trùng eGovUserId -> không nhân dòng) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* JOIN DANH MỤC PHÒNG BAN ĐƠN VỊ NHẬN */
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

/* JOIN USER NHẬN (danh bạ user đã khử trùng eGovUserId -> không nhân dòng) */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_target
       ON u_target.eGovUserId = t.TargetUser;
