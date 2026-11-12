/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
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
        NULLIF(t.DocCode, '')
    )                                                       AS van_ban_giao,
    COALESCE(
        NULLIF(t.Compendium, '')
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

    '${sync_ts}' AS sync_date

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
        NULLIF(t.DocCode, '')
    )                                                       AS van_ban_giao,
    COALESCE(
        NULLIF(t.Compendium, '')
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

    '${sync_ts}' AS sync_date

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

GROUP BY t.TaskId
ON DUPLICATE KEY UPDATE
    `id_don_vi` = VALUES(`id_don_vi`),
    `ten_don_vi` = VALUES(`ten_don_vi`),
    `id_truc` = VALUES(`id_truc`),
    `ten_truc` = VALUES(`ten_truc`),
    `cap` = VALUES(`cap`),
    `thu_tu` = VALUES(`thu_tu`),
    `so_tai_khoan_cap` = VALUES(`so_tai_khoan_cap`),
    `so_da_dang_nhap` = VALUES(`so_da_dang_nhap`),
    `id_don_vi_doi_ung` = VALUES(`id_don_vi_doi_ung`),
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `ten_nhiem_vu` = VALUES(`ten_nhiem_vu`),
    `van_ban_giao` = VALUES(`van_ban_giao`),
    `can_cu` = VALUES(`can_cu`),
    `linh_vuc` = VALUES(`linh_vuc`),
    `id_chuyen_vien` = VALUES(`id_chuyen_vien`),
    `chuyen_vien` = VALUES(`chuyen_vien`),
    `status` = VALUES(`status`),
    `ngay_giao` = VALUES(`ngay_giao`),
    `han_xu_ly` = VALUES(`han_xu_ly`),
    `ngay_hoan_thanh` = VALUES(`ngay_hoan_thanh`),
    `tinh_trang` = VALUES(`tinh_trang`),
    `sync_date` = VALUES(`sync_date`);
