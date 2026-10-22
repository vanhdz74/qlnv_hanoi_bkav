/* =====================================================================
   BCĐ 57 · Tab 2 "Nhiệm vụ cấp Xã/Phường"
   - Phạm vi: nhiệm vụ BCĐ 57 (nhóm NQ 55) có liên quan đến xã/phường (490.698.1310.%):
     xã/phường giao (AssignDepartment) hoặc nhận (OriginalTargetDepartment)
   - Cột giống bảng cấp TP (qlnv_chitiet_bcd57_cap_tp) để dùng chung chart/filter
   - nguon_giao chỉ có 'Nhiệm vụ Ban Chỉ đạo' | 'Nhiệm vụ Thành phố'
     (API Trung ương không có mã đơn vị nên không tách được xã/phường)
   ===================================================================== */

/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong`;
   --------------------------------------------------------------------------- */
INSERT INTO `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong` (
    `task_id`,
    `status`,
    `id_truc_giao`,
    `truc_giao`,
    `nguon_giao`,
    `van_ban_giao`,
    `loai_van_ban`,
    `ma_nhiem_vu`,
    `ten_xa_phuong`,
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
   NHIỆM VỤ BCĐ 57 GIAO XÃ/PHƯỜNG (qlnv_task)
   ======================================================================= */
SELECT
    /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
    t.TaskId                                                AS task_id,
    t.Status                                                AS status,

    /* 2. TRỤC GIAO & VĂN BẢN GIAO */
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,

    /* NGUỒN GIAO (nhánh 1 chỉ có BCĐ / Thành phố; Trung ương lấy ở nhánh 2) */
    CASE
        /* Ban Chỉ đạo giao / bút phê, chỉ đạo */
        WHEN CONCAT_WS(' ', t.AssignOrganization, d_assign.name, u_assign.eGovUserPositionName)
                 LIKE '%Ban Chỉ đạo%'
          OR t.DocCode LIKE '%BCĐ%'
        THEN 'Nhiệm vụ Ban Chỉ đạo'

        /* Còn lại: Thành ủy, HĐND, UBND TP, sở ngành TP giao */
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
    /* TÊN XÃ/PHƯỜNG (xem JOIN d_xa), đồng bộ qlnv_lichsutiendo_bcd57_xaphuong */
    d_xa.name                                               AS ten_xa_phuong,
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

    /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Lấy bản ghi mới nhất) */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn_test_data`.`qlnv_report` rp 
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
            FROM `db_theodoinv_hn_test_data`.`qlnv_report` rp 
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
            FROM `db_theodoinv_hn_test_data`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        '—'
    )                                                       AS de_xuat_kien_nghi,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn_test_data`.`qlnv_task` t

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

/* JOIN NGƯỜI GIAO NHIỆM VỤ */
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_user` u_assign
       ON u_assign.eGovUserId = t.AssignUser

/* JOIN TÊN XÃ/PHƯỜNG: đoạn thứ 4 của TargetDepartment (490.698.1310.<xã>...) */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_cap
       ON d_cap.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 4), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 4), '.', -1) AS UNSIGNED)
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

/* JOIN USER NHẬN */
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

/* XÃ/PHƯỜNG: department có id = đoạn thứ 4 của path 490.698.1310.<id>...
   Ưu tiên xã/phường nhận -> xã/phường giao */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_xa
       ON d_xa.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(
                 CASE
                     WHEN t.OriginalTargetDepartment LIKE '490.698.1310.%' THEN t.OriginalTargetDepartment
                     ELSE t.AssignDepartment
                 END, '.', 4), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(
                 CASE
                     WHEN t.OriginalTargetDepartment LIKE '490.698.1310.%' THEN t.OriginalTargetDepartment
                     ELSE t.AssignDepartment
                 END, '.', 4), '.', -1) AS UNSIGNED)
          END
      AND d_xa.IsDelete = 0

/* ĐIỀU KIỆN LẤY TASK: BCĐ 57 + có liên quan đến xã/phường */
WHERE t.DeletedDate IS NULL
  AND t.Status <> 5

  /* Tương đương tinh_trang <> 'Chưa xác định' của bản cũ */
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4)
           AND (   COALESCE(t.IsRecurring, 0) = 1
                OR t.ExpireDate IS NULL
                OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))

  /* Task thuộc nghị quyết nhóm 55 (qua qlnv_task_resolution), EXISTS để không nhân dòng */
  AND EXISTS (
      SELECT 1
      FROM `db_theodoinv_hn_test_data`.`qlnv_task_resolution` tr
      INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_resolution` r
              ON r.ResolutionId = tr.ResolutionId
      WHERE tr.TaskId = t.TaskId
        AND r.ResolutionGroupId = 55
        AND r.DeletedDate IS NULL
  )

  /* Có liên quan đến xã/phường: xã/phường giao hoặc nhận (không tính người tham gia) */
  AND (
         t.OriginalTargetDepartment LIKE '490.698.1310.%'
      OR t.AssignDepartment LIKE '490.698.1310.%'
  )

GROUP BY t.TaskId;
