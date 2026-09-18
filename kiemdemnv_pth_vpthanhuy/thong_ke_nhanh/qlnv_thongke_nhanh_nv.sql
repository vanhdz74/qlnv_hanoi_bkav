/* ===========================================================================
   DDL — qlnv_thongke_nhanh_task_vpthanhuy

   Mỗi dòng = 1 NHIỆM VỤ × 1 CHIỀU (nhận hoặc giao). FE tự đếm / tự lọc theo ngày.
   1 task liên quan Thành ủy ở cả 2 đầu sẽ ra 2 dòng: chieu='nhan' và chieu='giao'.

   PHẠM VI (chung 2 chiều):
       AssignDepartment LIKE '490.695%' OR TargetDepartment LIKE '490.695%'

   LOẠI TRỪ — mỗi chiều một quy tắc riêng, bám đúng 2 trang chi tiết:
   - chieu='nhan': bỏ nhiệm vụ do 490.1775% / 490.698% giao (chỉ chặn chiều VÀO).
   - chieu='giao': bỏ nhiệm vụ giao cho 3 node tổng hợp "các sở ngành"
                   (490.698.1307 / 1310 / 1841).
   => Vì vậy COUNT(chieu='giao') KHÔNG bằng COUNT(chieu='nhan').

   Ngày để kiểu DATE (không phải chuỗi dd/mm/yyyy) để FE lọc khoảng thời gian.
   Đơn vị hiển thị gộp theo `ten_don_vi` giống bản thống kê cũ.

   ⚠ KHÔNG có khóa duy nhất (để KEY, không để PRIMARY KEY) — giống các file nv_nhan.
   task_id trùng là BÌNH THƯỜNG: 1 task ở cả 2 đầu ra 2 dòng ('nhan' + 'giao').
   Nhờ vậy PutSQL của NiFi ghi lại batch (retry) cũng không vỡ vì lỗi 1062.
   Đổi lại, BẮT BUỘC phải truncate trước mỗi lần nạp, nếu không dữ liệu sẽ nhân lên.

   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi.
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_thongke_nhanh_nv_vpthanhuy` (
    task_id                  INT           NOT NULL,
    chieu                    VARCHAR(4)    NOT NULL,   -- 'nhan' | 'giao'

    /* --- ĐƠN VỊ CỦA CHIỀU ĐÓ --- */
    id_don_vi                VARCHAR(50)   NULL,       -- mã Part (Target- hoặc AssignDepartment)
    ten_don_vi               VARCHAR(500)  NULL,       -- KHÓA GỘP khi FE group
    id_truc                  VARCHAR(50)   NULL,       -- node cấp 2, vd 490.695
    ten_truc                 VARCHAR(500)  NULL,
    cap                      TINYINT       NULL,       -- số đoạn của mã
    thu_tu                   VARCHAR(120)  NULL,       -- khóa sắp xếp cây (đã pad số)

    /* --- TÀI KHOẢN THUỘC ĐƠN VỊ (thuộc tính của đơn vị, lặp lại trên mọi dòng
           cùng đơn vị -> FE phải dùng MAX/MIN chứ KHÔNG được SUM) --- */
    so_tai_khoan_cap         INT           NOT NULL DEFAULT 0,  -- COUNT(DISTINCT eGovUserId)
    so_da_dang_nhap          INT           NULL,                -- chưa có nguồn -> NULL

    /* --- ĐƠN VỊ ĐẦU KIA (để FE lọc chéo) --- */
    id_don_vi_doi_ung        VARCHAR(50)   NULL,

    /* --- NHIỆM VỤ --- */
    ma_nhiem_vu              VARCHAR(255)  NULL,       -- task.Code
    ten_nhiem_vu             TEXT          NULL,       -- task.Title
    van_ban_giao             VARCHAR(255)  NULL,       -- DocCode, thiếu thì DocumentCode
    can_cu                   VARCHAR(500)  NULL,       -- trích yếu văn bản (Compendium)
    linh_vuc                 VARCHAR(256)  NULL,       -- task.Sector, thiếu thì NameGroup
    id_chuyen_vien           INT           NULL,       -- eGovUserId (task.TargetUser)
    chuyen_vien              VARCHAR(255)  NULL,
    status                   TINYINT       NULL,

    /* --- NGÀY (kiểu DATE, cho FE lọc) --- */
    ngay_giao                DATE          NULL,       -- task.StartedDate
    han_xu_ly                DATE          NULL,       -- task.ExpireDate
    ngay_hoan_thanh          DATE          NULL,       -- COALESCE(CompletedDate, ApprovedDate)

    /* --- TÌNH TRẠNG: 5 giá trị RỜI NHAU --- */
    tinh_trang               VARCHAR(32)   NULL,       -- xem CASE trong SELECT

    sync_date                DATETIME      NULL,

    KEY idx_task      (task_id, chieu),   -- ⚠ KHÔNG phải PK: xem ghi chú đầu file
    KEY idx_don_vi    (ten_don_vi(191), chieu),
    KEY idx_truc      (id_truc, thu_tu),
    KEY idx_ngay_giao (ngay_giao),
    KEY idx_han       (han_xu_ly),
    KEY idx_tinh_trang(tinh_trang, chieu),
    KEY idx_linh_vuc  (linh_vuc(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_thongke_nhanh_task_vpthanhuy`;

   ⚠ Bảng không có khóa duy nhất nên truncate là BẮT BUỘC, không được bỏ qua:
   thiếu nó thì mỗi lần chạy sẽ cộng dồn thêm một bộ dữ liệu nữa.
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_thongke_nhanh_nv_vpthanhuy` (
    `task_id`,
    `chieu`,
    `id_don_vi`,
    `ten_don_vi`,
    `id_truc`,
    `ten_truc`,
    `cap`,
    `thu_tu`,
    `so_tai_khoan_cap`,
    `so_da_dang_nhap`,
    `id_don_vi_doi_ung`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `van_ban_giao`,
    `can_cu`,
    `linh_vuc`,
    `id_chuyen_vien`,
    `chuyen_vien`,
    `status`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `tinh_trang`,
    `sync_date`
)

/* =======================================================================
   CHIỀU NHẬN — đơn vị = TargetDepartment
   ======================================================================= */
SELECT
    CAST(t.TaskId AS SIGNED)                                AS task_id,
    'nhan'                                                  AS chieu,

    t.TargetDepartment                                      AS id_don_vi,
    COALESCE(NULLIF(d.name, ''), t.TargetDepartment)        AS ten_don_vi,
    SUBSTRING_INDEX(t.TargetDepartment, '.', 2)             AS id_truc,
    COALESCE(NULLIF(d_truc.name, ''),
             SUBSTRING_INDEX(t.TargetDepartment, '.', 2))   AS ten_truc,

    LENGTH(t.TargetDepartment)
        - LENGTH(REPLACE(t.TargetDepartment, '.', '')) + 1  AS cap,

    /* Khóa sắp xếp: pad từng đoạn về 6 ký tự để đơn vị anh em xếp đúng thứ tự
       SỐ (không thì '1558' đứng trước '999'), con luôn nằm ngay dưới cha */
    CONCAT(
        LPAD(SUBSTRING_INDEX(t.TargetDepartment, '.', 1), 6, '0'),
        '.',
        LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1), 6, '0'),
        CASE WHEN LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', '')) + 1 >= 3
             THEN CONCAT('.', LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 3), '.', -1), 6, '0'))
             ELSE '' END,
        CASE WHEN LENGTH(t.TargetDepartment) - LENGTH(REPLACE(t.TargetDepartment, '.', '')) + 1 >= 4
             THEN CONCAT('.', LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 4), '.', -1), 6, '0'))
             ELSE '' END
    )                                                       AS thu_tu,

    COALESCE(MAX(tk.so_tai_khoan_cap), 0)                   AS so_tai_khoan_cap,
    MAX(tk.so_da_dang_nhap)                                 AS so_da_dang_nhap,

    t.AssignDepartment                                      AS id_don_vi_doi_ung,

    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(
        NULLIF(t.DocCode, ''),
        NULLIF(t.DocumentCode, '')
    )                                                       AS van_ban_giao,
    COALESCE(
        NULLIF(t.Compendium, ''),
        NULLIF(t.DocumentCompendium, '')
    )                                                       AS can_cu,

    /* Sector là cột "Lĩnh vực"; rỗng thì lấy tạm NameGroup */
    COALESCE(
        NULLIF(t.Sector, ''),
        NULLIF(t.NameGroup, '')
    )                                                       AS linh_vuc,

    /* Chuyên viên = người thực hiện (TargetUser); tra không ra thì lấy
       ChargeUser (cột text tên người phụ trách) */
    CAST(t.TargetUser AS SIGNED)                            AS id_chuyen_vien,
    COALESCE(
        NULLIF(MAX(u_target.eGovUserFullname), ''),
        NULLIF(t.ChargeUser, '')
    )                                                       AS chuyen_vien,

    CAST(t.Status AS SIGNED)                                AS status,

    DATE(t.StartedDate)                                     AS ngay_giao,
    DATE(t.ExpireDate)                                      AS han_xu_ly,
    DATE(COALESCE(t.CompletedDate, t.ApprovedDate))         AS ngay_hoan_thanh,

    /* 5 TÌNH TRẠNG RỜI NHAU — thứ tự WHEN quan trọng */
    CASE
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        WHEN t.Status IN (3, 4)
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
             AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
        THEN 'HT đúng hạn'

        WHEN t.Status IN (3, 4)
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'HT quá hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND DATE(t.ExpireDate) >= CURDATE()
        THEN 'ĐTH trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND DATE(t.ExpireDate) <  CURDATE()
        THEN 'ĐTH quá hạn'
    END                                                     AS tinh_trang,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* TÊN ĐƠN VỊ — join department.id = ĐOẠN CUỐI của mã.
   REGEXP chặn CAST lỗi khi đoạn cuối không phải số.
   Tra không ra thì lấy chính mã làm tên, để không mất dòng. */
LEFT JOIN `db_theodoinv_hn`.`department` d
       ON d.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      /* COALESCE: IsDelete NULL thì `= 0` trả NULL -> mất tên */
      AND COALESCE(d.IsDelete, 0) = 0

LEFT JOIN `db_theodoinv_hn`.`department` d_truc
       ON d_truc.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TargetDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND COALESCE(d_truc.IsDelete, 0) = 0

/* JOIN USER THỰC HIỆN (chuyên viên) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target
       ON u_target.eGovUserId = t.TargetUser

/* TÀI KHOẢN THUỘC ĐƠN VỊ — gộp sẵn theo qlnv_user.DepartmentPath */
LEFT JOIN (
    SELECT
        u.DepartmentPath                                    AS ma_don_vi,
        COUNT(DISTINCT u.eGovUserId)                        AS so_tai_khoan_cap,
        NULL                                                AS so_da_dang_nhap
    FROM `db_theodoinv_hn`.`qlnv_user` u
    WHERE NULLIF(u.DepartmentPath, '') IS NOT NULL
    GROUP BY 1
) tk
    ON tk.ma_don_vi = t.TargetDepartment

WHERE t.DeletedDate IS NULL
  AND t.Status <> 5
  AND NULLIF(t.TargetDepartment, '') IS NOT NULL

  /* Chỉ lấy nhiệm vụ có tình trạng xác định rõ ràng */
  AND (
      t.Status IN (-1, 0, 1, 2)
      OR (
          t.Status IN (3, 4)
          AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
      )
  )

  /* PHẠM VI: nhiệm vụ có liên quan Thành ủy ở BẤT KỲ đầu nào */
  AND (
      t.AssignDepartment LIKE '490.695%'
      OR t.TargetDepartment LIKE '490.695%'
  )

  /* LOẠI TRỪ 2 TRỤC GIAO KHÔNG TÍNH LÀ GIAO QUA — giống nv_nhan.
     Lọc theo AssignDepartment nên CHỈ chặn chiều VÀO Thành ủy. */
  AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.1775%'
  AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

/* Gom 1 dòng / 1 TaskId: chống nhân dòng do LEFT JOIN department */
GROUP BY t.TaskId

UNION ALL

/* =======================================================================
   CHIỀU GIAO — đơn vị = AssignDepartment
   ======================================================================= */
SELECT
    CAST(t.TaskId AS SIGNED)                                AS task_id,
    'giao'                                                  AS chieu,

    t.AssignDepartment                                      AS id_don_vi,
    COALESCE(NULLIF(d.name, ''), t.AssignDepartment)        AS ten_don_vi,
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2)             AS id_truc,
    COALESCE(NULLIF(d_truc.name, ''),
             SUBSTRING_INDEX(t.AssignDepartment, '.', 2))   AS ten_truc,

    LENGTH(t.AssignDepartment)
        - LENGTH(REPLACE(t.AssignDepartment, '.', '')) + 1  AS cap,

    CONCAT(
        LPAD(SUBSTRING_INDEX(t.AssignDepartment, '.', 1), 6, '0'),
        '.',
        LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1), 6, '0'),
        CASE WHEN LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', '')) + 1 >= 3
             THEN CONCAT('.', LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 3), '.', -1), 6, '0'))
             ELSE '' END,
        CASE WHEN LENGTH(t.AssignDepartment) - LENGTH(REPLACE(t.AssignDepartment, '.', '')) + 1 >= 4
             THEN CONCAT('.', LPAD(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 4), '.', -1), 6, '0'))
             ELSE '' END
    )                                                       AS thu_tu,

    COALESCE(MAX(tk.so_tai_khoan_cap), 0)                   AS so_tai_khoan_cap,
    MAX(tk.so_da_dang_nhap)                                 AS so_da_dang_nhap,

    t.TargetDepartment                                      AS id_don_vi_doi_ung,

    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(
        NULLIF(t.DocCode, ''),
        NULLIF(t.DocumentCode, '')
    )                                                       AS van_ban_giao,
    COALESCE(
        NULLIF(t.Compendium, ''),
        NULLIF(t.DocumentCompendium, '')
    )                                                       AS can_cu,

    /* Sector là cột "Lĩnh vực"; rỗng thì lấy tạm NameGroup */
    COALESCE(
        NULLIF(t.Sector, ''),
        NULLIF(t.NameGroup, '')
    )                                                       AS linh_vuc,

    /* Chuyên viên = người thực hiện (TargetUser); tra không ra thì lấy
       ChargeUser (cột text tên người phụ trách) */
    CAST(t.TargetUser AS SIGNED)                            AS id_chuyen_vien,
    COALESCE(
        NULLIF(MAX(u_target.eGovUserFullname), ''),
        NULLIF(t.ChargeUser, '')
    )                                                       AS chuyen_vien,

    CAST(t.Status AS SIGNED)                                AS status,

    DATE(t.StartedDate)                                     AS ngay_giao,
    DATE(t.ExpireDate)                                      AS han_xu_ly,
    DATE(COALESCE(t.CompletedDate, t.ApprovedDate))         AS ngay_hoan_thanh,

    CASE
        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        WHEN t.Status IN (3, 4)
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
             AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate)) <= DATE(t.ExpireDate)
        THEN 'HT đúng hạn'

        WHEN t.Status IN (3, 4)
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'HT quá hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND DATE(t.ExpireDate) >= CURDATE()
        THEN 'ĐTH trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND DATE(t.ExpireDate) <  CURDATE()
        THEN 'ĐTH quá hạn'
    END                                                     AS tinh_trang,

    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

LEFT JOIN `db_theodoinv_hn`.`department` d
       ON d.id = CASE
            WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND COALESCE(d.IsDelete, 0) = 0

LEFT JOIN `db_theodoinv_hn`.`department` d_truc
       ON d_truc.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      AND COALESCE(d_truc.IsDelete, 0) = 0

/* JOIN USER THỰC HIỆN (chuyên viên) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target
       ON u_target.eGovUserId = t.TargetUser

/* TÀI KHOẢN THUỘC ĐƠN VỊ — gộp sẵn theo qlnv_user.DepartmentPath */
LEFT JOIN (
    SELECT
        u.DepartmentPath                                    AS ma_don_vi,
        COUNT(DISTINCT u.eGovUserId)                        AS so_tai_khoan_cap,
        NULL                                                AS so_da_dang_nhap
    FROM `db_theodoinv_hn`.`qlnv_user` u
    WHERE NULLIF(u.DepartmentPath, '') IS NOT NULL
    GROUP BY 1
) tk
    ON tk.ma_don_vi = t.AssignDepartment

WHERE t.DeletedDate IS NULL
  AND t.Status <> 5
  AND NULLIF(t.AssignDepartment, '') IS NOT NULL

  AND (
      t.Status IN (-1, 0, 1, 2)
      OR (
          t.Status IN (3, 4)
          AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
      )
  )

  AND (
      t.AssignDepartment LIKE '490.695%'
      OR t.TargetDepartment LIKE '490.695%'
  )

  /* LOẠI 3 NODE TỔNG HỢP "CÁC SỞ NGÀNH" (chung chung, không phải đơn vị thật).
     NOT IN => chỉ loại đúng 3 node này, VẪN GIỮ đơn vị con. */
  AND COALESCE(t.TargetDepartment, '') NOT IN (
      '490.698.1307',
      '490.698.1310',
      '490.698.1841'
  )

GROUP BY t.TaskId;
