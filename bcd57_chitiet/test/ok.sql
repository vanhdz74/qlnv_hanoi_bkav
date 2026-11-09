/* Upsert 1 lần cho cả 2 cấp: nhánh cấp Thành phố UNION ALL nhánh cấp Xã, phường.
   Bọc trong bảng dẫn xuất u để dùng được ON DUPLICATE KEY UPDATE với UNION. */
INSERT INTO `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57` (
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
         nhiệm vụ Thành phố (nhãn NQ57, logic truy_van_571_tp.sql) + nhiệm vụ Trung ương giao (bảng nv_tw)
       ======================================================================= */
    SELECT
        /* 0. CẤP NHIỆM VỤ (phân biệt nhiệm vụ cấp TP / cấp xã, phường trong cùng bảng) */
        'Cấp Thành phố'                                         AS cap_nhiem_vu,

        /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
        t.TaskId                                                AS task_id,
        t.Status                                                AS status,

        /* 2. TRỤC GIAO & VĂN BẢN GIAO */
        SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
        COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,

        /* NGUỒN GIAO */
        CASE
            /* Trung ương giao: task có trong bảng nv_tw */
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
            WHEN TRIM(t.DocCode) = '1'                                    THEN 'NV trọng tâm'
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
        COALESCE(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 'Chưa phân loại') AS nhom_nhiem_vu,

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
        IF(t.Status IN (3, 4), 100, COALESCE(t.Progress, 0))    AS tien_do,

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

        /* 03. Nhãn chuyên đề cd01-cd10, sắp theo mã, không có -> ''.
               Quy tắc tạm theo từ khóa trong tên nhiệm vụ (chưa có nhãn gán tay) */
        CONCAT_WS(',',
            IF(t.Title LIKE '%thể chế%' OR t.Title LIKE '%quy chế%' OR t.Title LIKE '%cơ chế%' OR t.Title LIKE '%chính sách%' OR t.Title LIKE '%nghị quyết%' OR t.Title LIKE '%đề án%' OR t.Title LIKE '%kiện toàn%', 'cd01', NULL),
            IF(t.Title LIKE '%hạ tầng%' OR t.Title LIKE '%trung tâm dữ liệu%' OR t.Title LIKE '%đường truyền%' OR t.Title LIKE '%máy chủ%' OR t.Title LIKE '%5G%' OR t.Title LIKE '%điện toán đám mây%', 'cd02', NULL),
            IF(t.Title LIKE '%dữ liệu%' OR t.Title LIKE '%CSDL%' OR t.Title LIKE '%số hóa%' OR t.Title LIKE '%làm sạch%' OR t.Title LIKE '%đất đai%' OR t.Title LIKE '%dân cư%' OR t.Title LIKE '%dữ liệu mở%', 'cd03', NULL),
            IF(t.Title LIKE '%nền tảng%' OR t.Title LIKE '%IOC%' OR t.Title LIKE '%iHanoi%' OR t.Title LIKE '%HanoiWork%' OR t.Title LIKE '%phần mềm%' OR t.Title LIKE '%ứng dụng%' OR t.Title LIKE '%chữ ký số%', 'cd04', NULL),
            IF(t.Title LIKE '%dịch vụ công%' OR t.Title LIKE '%thủ tục hành chính%' OR t.Title LIKE '%một cửa%' OR t.Title LIKE '%toàn trình%', 'cd05', NULL),
            IF(t.Title LIKE '%giải ngân%' OR t.Title LIKE '%kinh phí%' OR t.Title LIKE '%ngân sách%' OR t.Title LIKE '%đầu tư công%' OR t.Title LIKE '%mua sắm%' OR t.Title LIKE '%quyết toán%', 'cd06', NULL),
            IF(t.Title LIKE '%an toàn thông tin%' OR t.Title LIKE '%an ninh mạng%' OR t.Title LIKE '%bảo mật%' OR t.Title LIKE '%mã độc%' OR t.Title LIKE '%ứng cứu sự cố%', 'cd07', NULL),
            IF(t.Title LIKE '%đô thị thông minh%' OR t.Title LIKE '%giao thông thông minh%' OR t.Title LIKE '%camera%' OR t.Title LIKE '%IoT%' OR t.Title LIKE '%quan trắc%', 'cd08', NULL),
            IF(t.Title LIKE '%đột xuất%' OR t.Title LIKE '%khẩn trương%' OR t.Title LIKE '%cao điểm%' OR t.Title LIKE '%dứt điểm%' OR t.Title LIKE '%100 ngày%', 'cd09', NULL),
            IF(t.Title LIKE '%sản phẩm%' OR t.Title LIKE '%nghiệm thu%' OR t.Title LIKE '%đưa vào vận hành%' OR t.Title LIKE '%thí điểm%' OR t.Title LIKE '%bàn giao%', 'cd10', NULL)
        )                                                       AS nhan_chuyen_de,

        /* 04. Ngày ban hành, trích yếu văn bản giao */
        DATE(r_vb.StartDate)                                    AS ngay_ban_hanh_vb,
        COALESCE(
            NULLIF(TRIM(r_vb.Compendium), ''),
            NULLIF(TRIM(t.Compendium), '')
        )                                                       AS trich_yeu_vb,

        /* 06. Số thứ tự nhóm NQ57 (số sau 'Nhóm ') để sắp xếp */
        CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) AS UNSIGNED)
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

    /* NHÓM NHIỆM VỤ NQ57: nhãn dạng 'Nhóm <số>...' có SortOrder nhỏ nhất của task */
    LEFT JOIN (
            SELECT mn.TaskId,
                   SUBSTRING_INDEX(MIN(CONCAT(LPAD(COALESCE(tpn.SortOrder, 0), 10, '0'), '|', tpn.TopicName)), '|', -1) AS ten_nhom
            FROM `db_theodoinv_hn`.`qlnv_task_topic_map` mn
            INNER JOIN `db_theodoinv_hn`.`qlnv_task_topic` tpn
                    ON tpn.TopicId = mn.TopicId
                   AND tpn.DeletedDate IS NULL
            WHERE tpn.TopicName REGEXP 'Nhóm [0-9]'
            GROUP BY mn.TaskId
    ) nh
           ON nh.TaskId = t.TaskId

    /* NHIỆM VỤ TRUNG ƯƠNG GIAO: bảng nv_tw (nạp bằng bcd57_chitiet/nv_tw_ddl.sql),
       mỗi mã 1 task -> không nhân dòng */
    LEFT JOIN `db_theodoinv_hn`.`nv_tw` tw
           ON tw.TaskId = t.TaskId

    /* ĐIỀU KIỆN LẤY TASK: (Trung ương giao: bảng nv_tw) HOẶC (Thành phố: nhãn NQ57, theo truy_van_571_tp.sql) */
    WHERE (
          /* Nhiệm vụ Trung ương giao: task có trong bảng nv_tw */
          tw.TaskId IS NOT NULL

          OR

          /* Nhiệm vụ Thành phố: task chưa xoá, gắn nhãn NQ57 (nhóm "Nhãn", GroupId 1),
             EXISTS để task gắn nhãn nhiều lần không bị nhân dòng */
          (
              t.DeletedDate IS NULL
              AND EXISTS (
                  SELECT 1
                  FROM `db_theodoinv_hn`.`qlnv_task_topic_map` m57
                  INNER JOIN `db_theodoinv_hn`.`qlnv_task_topic` tp57
                          ON tp57.TopicId = m57.TopicId
                  WHERE m57.TaskId = t.TaskId
                    AND tp57.GroupId = 1
                    AND tp57.TopicName = 'NQ57'
                    AND tp57.DeletedDate IS NULL
              )
          )
      )

    GROUP BY t.TaskId

    UNION ALL

    /* =======================================================================
       NHÁNH 2 · CẤP XÃ, PHƯỜNG: nhiệm vụ BCĐ 57 có xã/phường giao hoặc nhận (qlnv_task)
       ======================================================================= */
    SELECT
        /* 0. CẤP NHIỆM VỤ */
        /* 4 nhiệm vụ Thành phố có xã/phường tham gia -> tính là cấp Thành phố */
        CASE WHEN t.Code IN ('2026-277-TB/TU-015', '2026-309/VP-ĐT-983', '2026-59/UBND-ĐT-820', '2026-601-CV/TU-376')
             THEN 'Cấp Thành phố' ELSE 'Cấp Xã, phường' END     AS cap_nhiem_vu,

        /* 1. KHÓA HỆ THỐNG & TRẠNG THÁI */
        t.TaskId                                                AS task_id,
        t.Status                                                AS status,

        /* 2. TRỤC GIAO & VĂN BẢN GIAO */
        SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc_giao,
        COALESCE(NULLIF(t.AssignOrganization, ''), d_assign_cap2.name) AS truc_giao,

        /* NGUỒN GIAO (nhánh 1 chỉ có BCĐ / Thành phố; Trung ương lấy ở nhánh 2) */
        CASE
            /* Ban Chỉ đạo giao / bút phê, chỉ đạo: bỏ nhóm 'Nhiệm vụ Ban Chỉ đạo' -> NULL */
            WHEN CONCAT_WS(' ', t.AssignOrganization, d_assign.name, u_assign.eGovUserPositionName)
                     LIKE '%Ban Chỉ đạo%'
              OR t.DocCode LIKE '%BCĐ%'
            THEN NULL

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
            WHEN TRIM(t.DocCode) = '1'                                    THEN 'NV trọng tâm'
            WHEN UPPER(t.DocCode) LIKE '%KH%'                                  THEN 'Kế hoạch'
            WHEN UPPER(t.DocCode) LIKE '%TB%' OR UPPER(t.DocCode) LIKE '%KL%'   THEN 'TBKL'
            ELSE 'Công văn'
        END                                                     AS loai_van_ban,

        /* 3. THÔNG TIN NHIỆM VỤ, TIÊU ĐỀ & CHỦ ĐỀ */
        t.Code                                                  AS ma_nhiem_vu,
        /* TÊN XÃ/PHƯỜNG (xem JOIN d_xa), đồng bộ qlnv_lichsutiendo_captp_xp_bcd57 */
        /* 02. Tên xã/phường chuẩn ('Phường Ba Đình'): xã nhận -> xã giao -> tên UBND xã cũ */
        COALESCE(xa_nhan.ten_xa_phuong, xa_goc.ten_xa_phuong, xa_giao.ten_xa_phuong, d_xa.name) AS ten_xa_phuong,
        t.Title                                                 AS ten_nhiem_vu,
        COALESCE(NULLIF(tp.TopicName, ''), 'Chưa phân loại')    AS chu_de,
        /* Nhóm nhiệm vụ NQ57 một dạng ('Nhóm 11: ...'), bỏ ký tự thừa ở đầu ('. Nhóm 8') */
        COALESCE(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 'Chưa phân loại') AS nhom_nhiem_vu,

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
                --  AND t.ExpireDate IS NOT NULL
                --  AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
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
        COALESCE(xa_nhan.ma_xa_phuong, xa_goc.ma_xa_phuong, xa_giao.ma_xa_phuong) AS ma_xa_phuong,
        COALESCE(xa_nhan.truc_xa_phuong, xa_goc.truc_xa_phuong, xa_giao.truc_xa_phuong) AS truc_xa_phuong,

        /* 03. Nhãn chuyên đề cd01-cd10, sắp theo mã, không có -> ''.
               Quy tắc tạm theo từ khóa trong tên nhiệm vụ (chưa có nhãn gán tay) */
        CONCAT_WS(',',
            IF(t.Title LIKE '%thể chế%' OR t.Title LIKE '%quy chế%' OR t.Title LIKE '%cơ chế%' OR t.Title LIKE '%chính sách%' OR t.Title LIKE '%nghị quyết%' OR t.Title LIKE '%đề án%' OR t.Title LIKE '%kiện toàn%', 'cd01', NULL),
            IF(t.Title LIKE '%hạ tầng%' OR t.Title LIKE '%trung tâm dữ liệu%' OR t.Title LIKE '%đường truyền%' OR t.Title LIKE '%máy chủ%' OR t.Title LIKE '%5G%' OR t.Title LIKE '%điện toán đám mây%', 'cd02', NULL),
            IF(t.Title LIKE '%dữ liệu%' OR t.Title LIKE '%CSDL%' OR t.Title LIKE '%số hóa%' OR t.Title LIKE '%làm sạch%' OR t.Title LIKE '%đất đai%' OR t.Title LIKE '%dân cư%' OR t.Title LIKE '%dữ liệu mở%', 'cd03', NULL),
            IF(t.Title LIKE '%nền tảng%' OR t.Title LIKE '%IOC%' OR t.Title LIKE '%iHanoi%' OR t.Title LIKE '%HanoiWork%' OR t.Title LIKE '%phần mềm%' OR t.Title LIKE '%ứng dụng%' OR t.Title LIKE '%chữ ký số%', 'cd04', NULL),
            IF(t.Title LIKE '%dịch vụ công%' OR t.Title LIKE '%thủ tục hành chính%' OR t.Title LIKE '%một cửa%' OR t.Title LIKE '%toàn trình%', 'cd05', NULL),
            IF(t.Title LIKE '%giải ngân%' OR t.Title LIKE '%kinh phí%' OR t.Title LIKE '%ngân sách%' OR t.Title LIKE '%đầu tư công%' OR t.Title LIKE '%mua sắm%' OR t.Title LIKE '%quyết toán%', 'cd06', NULL),
            IF(t.Title LIKE '%an toàn thông tin%' OR t.Title LIKE '%an ninh mạng%' OR t.Title LIKE '%bảo mật%' OR t.Title LIKE '%mã độc%' OR t.Title LIKE '%ứng cứu sự cố%', 'cd07', NULL),
            IF(t.Title LIKE '%đô thị thông minh%' OR t.Title LIKE '%giao thông thông minh%' OR t.Title LIKE '%camera%' OR t.Title LIKE '%IoT%' OR t.Title LIKE '%quan trắc%', 'cd08', NULL),
            IF(t.Title LIKE '%đột xuất%' OR t.Title LIKE '%khẩn trương%' OR t.Title LIKE '%cao điểm%' OR t.Title LIKE '%dứt điểm%' OR t.Title LIKE '%100 ngày%', 'cd09', NULL),
            IF(t.Title LIKE '%sản phẩm%' OR t.Title LIKE '%nghiệm thu%' OR t.Title LIKE '%đưa vào vận hành%' OR t.Title LIKE '%thí điểm%' OR t.Title LIKE '%bàn giao%', 'cd10', NULL)
        )                                                       AS nhan_chuyen_de,

        /* 04. Ngày ban hành, trích yếu văn bản giao */
        DATE(r_vb.StartDate)                                    AS ngay_ban_hanh_vb,
        COALESCE(
            NULLIF(TRIM(r_vb.Compendium), ''),
            NULLIF(TRIM(t.Compendium), '')
        )                                                       AS trich_yeu_vb,

        /* 06. Số thứ tự nhóm NQ57 (số sau 'Nhóm ') để sắp xếp */
        CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(COALESCE(TRIM(SUBSTRING(nh.ten_nhom, LOCATE('Nhóm ', nh.ten_nhom))), NULLIF(TRIM(IF(t.NameGroup REGEXP 'Nhóm [0-9]', SUBSTRING(t.NameGroup, LOCATE('Nhóm ', t.NameGroup)), TRIM(LEADING '.' FROM TRIM(t.NameGroup)))), '')), 6), ':', 1), ' ', 1) AS UNSIGNED)
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

    /* JOIN TÊN XÃ/PHƯỜNG: đoạn thứ 4 của TargetDepartment (490.698.1310.<xã>...) */
    LEFT JOIN `db_theodoinv_hn`.`department` d_cap
           ON d_cap.id = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 4), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 4), '.', -1) AS UNSIGNED)
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

    /* NHÓM NHIỆM VỤ NQ57: nhãn dạng 'Nhóm <số>...' có SortOrder nhỏ nhất của task */
    LEFT JOIN (
            SELECT mn.TaskId,
                   SUBSTRING_INDEX(MIN(CONCAT(LPAD(COALESCE(tpn.SortOrder, 0), 10, '0'), '|', tpn.TopicName)), '|', -1) AS ten_nhom
            FROM `db_theodoinv_hn`.`qlnv_task_topic_map` mn
            INNER JOIN `db_theodoinv_hn`.`qlnv_task_topic` tpn
                    ON tpn.TopicId = mn.TopicId
                   AND tpn.DeletedDate IS NULL
            WHERE tpn.TopicName REGEXP 'Nhóm [0-9]'
            GROUP BY mn.TaskId
    ) nh
           ON nh.TaskId = t.TaskId

    /* XÃ/PHƯỜNG: department có id = đoạn thứ 4 của path 490.698.1310.<id>...
       Ưu tiên xã/phường nhận -> xã/phường giao */
    LEFT JOIN `db_theodoinv_hn`.`department` d_xa
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

    /* XÃ/PHƯỜNG GIAO (nhánh xã, phường: xã/phường là bên giao) */
    LEFT JOIN `db_theodoinv_hn`.`dm_xa_phuong_4truc` xa_giao
           ON xa_giao.id_don_vi = CASE
                WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 4), '.', -1) REGEXP '^[0-9]+$'
                THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 4), '.', -1) AS UNSIGNED)
              END
          AND t.AssignDepartment LIKE CONCAT(xa_giao.nhanh, '.%')

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
          FROM `db_theodoinv_hn`.`qlnv_task_resolution` tr
          INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
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
