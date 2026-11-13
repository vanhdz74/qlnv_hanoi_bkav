/* 11/11 test real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không đặt khóa S lên bảng nguồn db_theodoinv_hn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

/* 13/11 BẢNG CHI TIẾT (KHÔNG GỘP): cùng logic NQ57 TW + TP giao như bản Gộp (qlnv_chitiet_captp_xp_bcd57),
   nhưng KHÔNG gom theo AssignBatchId: mỗi task một dòng; bỏ task không có OriginalTargetDepartment (dòng gốc lô gộp).
   cap_nhiem_vu = 'Cấp Xã, phường' khi có xã/phường nhận, ngược lại ''. */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57_full` LIKE `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57`;

INSERT INTO `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57_full` (
    `cap_nhiem_vu`,
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
    `path_ten_don_vi_chu_tri`,
    `ma_xa_phuong`,
    `truc_xa_phuong`,
    `nhan_chuyen_de`,
    `ngay_ban_hanh_vb`,
    `trich_yeu_vb`,
    `stt_nhom_nhiem_vu`,
    `la_thuong_truc_bcd`,
    `sync_date`
)
SELECT u.* FROM (
    /* =======================================================================
       NHÁNH 1 · CẤP THÀNH PHỐ (qlnv_task):
         task có TopicCode LIKE '%"NQ57%': Trung ương giao (AssignDepartment 900000.900609%) + Thành phố giao (490.%)
       ======================================================================= */
    SELECT
        /* 0. CẤP NHIỆM VỤ: có xã/phường liên quan (xa_nhan / xa_goc khớp dm_xa_phuong_4truc) -> 'Cấp Xã, phường';
              còn lại để rỗng '' (cột thuộc PK, NOT NULL nên không dùng NULL) */
        CASE
            WHEN COALESCE(xa_nhan.id_don_vi, xa_goc.id_don_vi) IS NOT NULL THEN 'Cấp Xã, phường'
            ELSE ''
        END                                                     AS cap_nhiem_vu,

        /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
        t.TaskId                                                AS task_id,
        t.Status                                                AS status,

        /* 2. TRỤC GIAO & VĂN BẢN GIAO */
        SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
        COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,

        /* NGUỒN GIAO */
        CASE

            /* Trung ương giao: AssignDepartment 900000.900609% */
            WHEN tw.TaskId IS NOT NULL
            THEN 'Nhiệm vụ Trung ương'

            /* Còn lại: Thành ủy, HĐND, UBND TP, sở ngành TP giao */
            ELSE 'Nhiệm vụ Thành phố'
        END                                                     AS nguon_giao,
        /* Số văn bản một dạng ('1' = nhiệm vụ trọng tâm hiển thị 'TT'): bỏ 'Số:', bỏ khoảng trắng quanh '-' '/';
           mã viết tắt (không có '/', vd NQ79) -> số ký hiệu đầy đủ của văn bản (qlnv_resolution) */
        CASE
            WHEN TRIM(t.DocCode) = '1' THEN 'TT'
            ELSE TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CASE WHEN COALESCE(t.DocCode, '') NOT LIKE '%/%' AND NULLIF(TRIM(r_vb.DocCode), '') IS NOT NULL THEN r_vb.DocCode ELSE t.DocCode END, 'Số:', ''), 'số:', ''), 'SỐ:', ''), ' -', '-'), ' -', '-'), '- ', '-'), '- ', '-'), ' /', '/'), ' /', '/'), '/ ', '/'), '/ ', '/'))
        END                                                     AS van_ban_giao,
        /* Loại văn bản (4 nhóm):
             TT (DocCode = '1')                    -> NV trọng tâm
             mã chứa 'KH' (vd 20-KH/BCĐ57)          -> Kế hoạch
             mã chứa 'TB' hoặc 'KL' (gồm cả TBKL)  -> TBKL
             còn lại (kể cả rỗng)                  -> Công văn */
        CASE
            /* Số văn bản '1' -> nhiệm vụ trọng tâm (TT) */
            WHEN TRIM(t.DocCode) = 'TT'                                    THEN 'NV trọng tâm'
            WHEN UPPER(t.DocCode) LIKE '%KH%'                                  THEN 'Kế hoạch'
            WHEN UPPER(t.DocCode) LIKE '%TB%' OR UPPER(t.DocCode) LIKE '%KL%'   THEN 'TBKL'
            ELSE 'Công văn'
        END                                                     AS loai_van_ban,

        /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
        t.Code                                                  AS ma_nhiem_vu,
        /* 02. Tên xã/phường chuẩn ('Phường Ba Đình'), chỉ khi cơ quan xã nhận */
        COALESCE(xa_nhan.ten_xa_phuong, xa_goc.ten_xa_phuong) AS ten_xa_phuong,
        t.Title                                                 AS ten_nhiem_vu,
        COALESCE(NULLIF(tp.TopicName, ''), 'Chưa phân loại')    AS chu_de,
        /* Nhóm nhiệm vụ NQ57 một dạng ('Nhóm 11: ...'), bỏ ký tự thừa ở đầu ('. Nhóm 8') */
        COALESCE(COALESCE(NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 'Chưa phân loại') AS nhom_nhiem_vu,

        /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
        t.AssignDepartment                                      AS id_don_vi_giao,
        /* Cơ quan ban hành / giao nhiệm vụ, không lấy đơn vị nhập liệu (d_assign) trước */
        COALESCE(
            NULLIF(TRIM(r_vb.AssignOrganizationName), ''),
            NULLIF(TRIM(t.AssignOrganization), ''),
            d_assign.name
        )                                                       AS don_vi_giao,
        t.AssignUser                                            AS id_nguoi_giao,
        u_assign.eGovUserFullname                               AS nguoi_giao,

        /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ & NGƯỜI THỰC HIỆN */
        /* Path mã tới đơn vị nhận, không để trống (thiếu thì lấy đơn vị nhận gốc, cuối cùng là '490') */
        COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490') AS id_don_vi_chu_tri,
        /* Tên của mã sâu nhất trong path (không phải tên nhóm cha) */
        COALESCE(
            dp6.name, dp5.name, dp4.name, dp3.name, dp2.name,
            NULLIF(t.ResponsibleUnit, ''),
            NULLIF(t.TargetOrganization, ''),
            dp1.name
        )                                                       AS ten_don_vi_chu_tri,
    
        COALESCE(
            d_donvi.name,
            NULLIF(t.ResponsibleUnit, ''),
            NULLIF(t.TargetOrganization, '')
        )                                                       AS ten_don_vi_thuc_hien,

        t.TargetUser AS id_nguoi_thuc_hien,
        u_target.eGovUserFullname AS nguoi_thuc_hien,

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
            /* NV Trung ương giao (tw): Status = 4 + IsRecurring = 0 -> hoàn thành; IsRecurring = 1 -> thường xuyên */
            WHEN tw.TaskId IS NOT NULL AND t.Status = 4 AND COALESCE(t.IsRecurring, 0) = 0
            THEN 'Đã hoàn thành'
            WHEN tw.TaskId IS NOT NULL AND COALESCE(t.IsRecurring, 0) = 1
            THEN 'Thường xuyên'
            WHEN tw.TaskId IS NOT NULL
                 AND t.ExpireDate IS NOT NULL
                 AND DATE(t.ExpireDate) < CURDATE()
            THEN 'Chưa hoàn thành quá hạn'
            WHEN tw.TaskId IS NOT NULL
            THEN 'Chưa hoàn thành trong hạn'

            /* 1. Đã hoàn thành (đúng hạn hoặc quá hạn) */
            WHEN t.Status IN (3, 4)
  /*               AND t.ExpireDate IS NOT NULL
                 AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL */
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
        IF(IF(tw.TaskId IS NOT NULL, t.Status = 4 AND COALESCE(t.IsRecurring, 0) = 0, t.Status IN (3, 4)), 100, COALESCE(t.Progress, 0)) AS tien_do,

        /* 7. CHI TIẾT TÌNH HÌNH & BÁO CÁO (Lấy bản ghi mới nhất) */
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

        /* ===== BỔ SUNG THEO test/dac-ta-truong-bcd57.md ===== */
        /* 01. Path tên tương ứng id_don_vi_chu_tri, ngăn cách ' › ' */
        CONCAT_WS(' › ',
            IF(dp1.id = 490, 'Thành phố Hà Nội', dp1.name),
            dp2.name, dp3.name, dp4.name, dp5.name, dp6.name
        )                                                       AS path_ten_don_vi_chu_tri,

        /* 02. Xã/phường và trục của cơ quan xã nhận (dm_xa_phuong_4truc); nhiệm vụ không thuộc cấp xã -> NULL */
        COALESCE(xa_nhan.ma_xa_phuong, xa_goc.ma_xa_phuong) AS ma_xa_phuong,
        COALESCE(xa_nhan.truc_xa_phuong, xa_goc.truc_xa_phuong) AS truc_xa_phuong,

        /* 03. Nhãn chuyên đề dạng path 'NQ57/<TopicName>': lấy từ qlnv_task.TopicCode (chuỗi JSON ["NQ57.TCCĐ", "NQ57.CĐN"])
               join qlnv_task_topic (con của Code 'NQ57', mã đầy đủ = 'NQ57.' + Code); nhiều nhãn ngăn cách ';';
               không có nhãn con -> 'Khác' */
        COALESCE((SELECT GROUP_CONCAT(CONCAT(p57.Code, '/', c57.TopicName) ORDER BY c57.SortOrder SEPARATOR ';')
                    FROM `db_theodoinv_hn`.`qlnv_task_topic` c57
                    JOIN `db_theodoinv_hn`.`qlnv_task_topic` p57 ON p57.TopicId = c57.ParentTopicId
                   WHERE p57.Code = 'NQ57' AND p57.DeletedDate IS NULL
                     AND c57.Code IS NOT NULL AND c57.DeletedDate IS NULL
                     AND COALESCE(t.TopicCode, nhan_lo.TopicCode) LIKE CONCAT('%"', p57.Code, '.', c57.Code, '"%')), 'Khác') AS nhan_chuyen_de,

        /* 04. Ngày ban hành, trích yếu văn bản giao */
        DATE(r_vb.StartDate)                                    AS ngay_ban_hanh_vb,
        COALESCE(
            NULLIF(TRIM(r_vb.Compendium), ''),
            NULLIF(TRIM(t.Compendium), '')
        )                                                       AS trich_yeu_vb,

        /* 06. Số thứ tự nhóm NQ57 (số sau 'Nhóm ') để sắp xếp */
        CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) AS UNSIGNED)
        END                                                     AS stt_nhom_nhiem_vu,

        /* 07. Thường trực BCĐ 57: chủ trì là Công an TP/xã, Tổ Thường trực, Tổ Tư vấn - chuyên gia */
        IF(CONCAT_WS(' ', dp2.name, dp3.name, dp4.name, dp5.name, dp6.name, t.ResponsibleUnit) LIKE '%Công an%'
           OR CONCAT_WS(' ', dp2.name, dp3.name, dp4.name, dp5.name, dp6.name, t.ResponsibleUnit) LIKE '%Tổ Thường trực%'
           OR CONCAT_WS(' ', dp2.name, dp3.name, dp4.name, dp5.name, dp6.name, t.ResponsibleUnit) LIKE '%Tổ Tư vấn%',
           1, 0)                                                AS la_thuong_truc_bcd,

        '${sync_ts}'                                            AS sync_date

    FROM `db_theodoinv_hn`.`qlnv_task` t

    /* CHỦ ĐỀ (1 TopicId / task -> không nhân dòng) */
    LEFT JOIN `db_theodoinv_hn`.`qlnv_task_topic` tp
           ON tp.TopicId = t.TopicId

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

    /* JOIN DANH MỤC PHÒNG BAN ĐƠN VỊ NHẬN */
    LEFT JOIN `db_theodoinv_hn`.`department` d_cap
           ON d_cap.id = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1) AS UNSIGNED)
                ELSE NULL
              END
          AND d_cap.IsDelete = 0

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

    /* VĂN BẢN GIAO (số, ngày ban hành, trích yếu, cơ quan ban hành) */
    LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution` r_vb
           ON r_vb.ResolutionId = t.ResolutionId
          AND r_vb.DeletedDate IS NULL

    /* PATH ĐƠN VỊ CHỦ TRÌ: dp1..dp6 = department của từng mã trong path
       COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490') */

    LEFT JOIN `db_theodoinv_hn`.`department` dp1
           ON dp1.id = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 1), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 1), '.', -1) AS UNSIGNED)
              END

    LEFT JOIN `db_theodoinv_hn`.`department` dp2
           ON dp2.id = CASE
                WHEN LENGTH(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490')) - LENGTH(REPLACE(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', '')) >= 1
                 AND SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 2), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 2), '.', -1) AS UNSIGNED)
              END

    LEFT JOIN `db_theodoinv_hn`.`department` dp3
           ON dp3.id = CASE
                WHEN LENGTH(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490')) - LENGTH(REPLACE(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', '')) >= 2
                 AND SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 3), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 3), '.', -1) AS UNSIGNED)
              END

    LEFT JOIN `db_theodoinv_hn`.`department` dp4
           ON dp4.id = CASE
                WHEN LENGTH(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490')) - LENGTH(REPLACE(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', '')) >= 3
                 AND SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 4), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 4), '.', -1) AS UNSIGNED)
              END

    LEFT JOIN `db_theodoinv_hn`.`department` dp5
           ON dp5.id = CASE
                WHEN LENGTH(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490')) - LENGTH(REPLACE(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', '')) >= 4
                 AND SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 5), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 5), '.', -1) AS UNSIGNED)
              END

    LEFT JOIN `db_theodoinv_hn`.`department` dp6
           ON dp6.id = CASE
                WHEN LENGTH(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490')) - LENGTH(REPLACE(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', '')) >= 5
                 AND SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 6), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 6), '.', -1) AS UNSIGNED)
              END

    /* XÃ/PHƯỜNG NHẬN: đơn vị chủ trì là cơ quan cấp xã (bảng đối chiếu dm_xa_phuong_4truc_ddl.sql) */
    LEFT JOIN `db_theodoinv_hn`.`dm_xa_phuong_4truc` xa_nhan
           ON xa_nhan.id_don_vi = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 4), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490'), '.', 4), '.', -1) AS UNSIGNED)
              END
          AND COALESCE(NULLIF(TRIM(t.TargetDepartment), ''), NULLIF(TRIM(t.OriginalTargetDepartment), ''), '490') LIKE CONCAT(xa_nhan.nhanh, '.%')

    /* XÃ/PHƯỜNG NHẬN theo đơn vị nhận gốc (OriginalTargetDepartment) */
    LEFT JOIN `db_theodoinv_hn`.`dm_xa_phuong_4truc` xa_goc
           ON xa_goc.id_don_vi = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.OriginalTargetDepartment, '.', 4), '.', -1) AS UNSIGNED)
              END
          AND t.OriginalTargetDepartment LIKE CONCAT(xa_goc.nhanh, '.%')


    /* NHIỆM VỤ TRUNG ƯƠNG GIAO: TopicCode NQ57 + AssignDepartment 900000.900609% (1 dòng / task) */
    LEFT JOIN (
            SELECT t_tw.TaskId
            FROM `db_theodoinv_hn`.`qlnv_task` t_tw
            WHERE t_tw.DeletedDate IS NULL
              AND t_tw.TopicCode LIKE '%"NQ57%'
              AND t_tw.AssignDepartment LIKE '900000.900609%'
    ) tw
           ON tw.TaskId = t.TaskId

    /* Nhãn của cả lô giao (gốc + con), áp cho mọi dòng trong lô: dòng con thiếu TopicCode vẫn lấy được nhãn NQ57 của lô. */
    LEFT JOIN (
            SELECT c.AssignBatchId AS Dau, MIN(c.TopicCode) AS TopicCode
            FROM `db_theodoinv_hn`.`qlnv_task` c
            WHERE c.DeletedDate IS NULL AND c.TopicCode IS NOT NULL AND c.AssignBatchId IS NOT NULL
            GROUP BY c.AssignBatchId
    ) nhan_lo
           ON nhan_lo.Dau = COALESCE(t.AssignBatchId, t.TaskId)


    /* ĐIỀU KIỆN LẤY TASK: nhãn NQ57 (của task hoặc của lô) + Trung ương giao (900000.900609%) hoặc Thành phố giao (490.%).
       KHÔNG gom theo AssignBatchId: lấy mọi task; bỏ task không có OriginalTargetDepartment (dòng gốc lô gộp). */
    WHERE t.DeletedDate IS NULL
      AND NULLIF(TRIM(t.OriginalTargetDepartment), '') IS NOT NULL
      AND (t.TopicCode LIKE '%"NQ57%' OR nhan_lo.TopicCode LIKE '%"NQ57%')
      AND (
             /* Trung ương giao */
             t.AssignDepartment LIKE '900000.900609%'
             /* Thành phố giao */
          OR t.AssignDepartment LIKE '490.%'
      )

    GROUP BY t.TaskId
) u

ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    id_truc_giao = VALUES(id_truc_giao),
    truc_giao = VALUES(truc_giao),
    nguon_giao = VALUES(nguon_giao),
    van_ban_giao = VALUES(van_ban_giao),
    loai_van_ban = VALUES(loai_van_ban),
    ma_nhiem_vu = VALUES(ma_nhiem_vu),
    ten_xa_phuong = VALUES(ten_xa_phuong),
    ten_nhiem_vu = VALUES(ten_nhiem_vu),
    chu_de = VALUES(chu_de),
    nhom_nhiem_vu = VALUES(nhom_nhiem_vu),
    id_don_vi_giao = VALUES(id_don_vi_giao),
    don_vi_giao = VALUES(don_vi_giao),
    id_nguoi_giao = VALUES(id_nguoi_giao),
    nguoi_giao = VALUES(nguoi_giao),
    id_don_vi_chu_tri = VALUES(id_don_vi_chu_tri),
    ten_don_vi_chu_tri = VALUES(ten_don_vi_chu_tri),
    ten_don_vi_thuc_hien = VALUES(ten_don_vi_thuc_hien),
    id_nguoi_thuc_hien = VALUES(id_nguoi_thuc_hien),
    nguoi_thuc_hien = VALUES(nguoi_thuc_hien),
    lanh_dao_ban_phu_trach = VALUES(lanh_dao_ban_phu_trach),
    ngay_giao = VALUES(ngay_giao),
    han_xu_ly = VALUES(han_xu_ly),
    ngay_hoan_thanh = VALUES(ngay_hoan_thanh),
    ngay_chap_nhan = VALUES(ngay_chap_nhan),
    ngay_xoa = VALUES(ngay_xoa),
    tinh_trang = VALUES(tinh_trang),
    tien_do = VALUES(tien_do),
    ket_qua_thuc_hien = VALUES(ket_qua_thuc_hien),
    kho_khan_vuong_mac = VALUES(kho_khan_vuong_mac),
    de_xuat_kien_nghi = VALUES(de_xuat_kien_nghi),
    path_ten_don_vi_chu_tri = VALUES(path_ten_don_vi_chu_tri),
    ma_xa_phuong = VALUES(ma_xa_phuong),
    truc_xa_phuong = VALUES(truc_xa_phuong),
    nhan_chuyen_de = VALUES(nhan_chuyen_de),
    ngay_ban_hanh_vb = VALUES(ngay_ban_hanh_vb),
    trich_yeu_vb = VALUES(trich_yeu_vb),
    stt_nhom_nhiem_vu = VALUES(stt_nhom_nhiem_vu),
    la_thuong_truc_bcd = VALUES(la_thuong_truc_bcd),
    sync_date = VALUES(sync_date);
