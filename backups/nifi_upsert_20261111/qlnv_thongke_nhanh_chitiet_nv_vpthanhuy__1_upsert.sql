/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO `datamart_hanoi`.`qlnv_thongke_nhanh_chitiet_nv_vpthanhuy` (
    `task_id`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `van_ban_giao`,
    `can_cu`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `linh_vuc`,
    `id_chuyen_vien`,
    `chuyen_vien`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `tinh_trang`,
    `status`,
    `sync_date`
)

SELECT
    CAST(t.TaskId AS SIGNED)                                AS task_id,

    /* 1. NHIỆM VỤ & VĂN BẢN CĂN CỨ */
    t.Code                                                  AS ma_nhiem_vu,
    t.Title                                                 AS ten_nhiem_vu,
    COALESCE(
        NULLIF(t.DocCode, '')
    )                                                       AS van_ban_giao,
    COALESCE(
        NULLIF(t.Compendium, '')
    )                                                       AS can_cu,

    /* 2. ĐƠN VỊ CHỦ TRÌ — PHẢI dùng đúng công thức của qlnv_thongke_nhanh_task
          (department.name theo đoạn cuối của mã, tra không ra thì lấy chính mã)
          thì `ten_don_vi_chu_tri` ở đây mới khớp `ten_don_vi` bên đó.
          KHÔNG lấy ResponsibleUnit/TargetOrganization như file nv_nhan. */
    t.TargetDepartment                                      AS id_don_vi_chu_tri,
    COALESCE(NULLIF(MAX(d.name), ''), t.TargetDepartment)   AS ten_don_vi_chu_tri,

    /* 3. LĨNH VỰC — Sector là cột "Lĩnh vực"; rỗng thì lấy tạm NameGroup */
    COALESCE(
        NULLIF(t.Sector, ''),
        NULLIF(t.NameGroup, '')
    )                                                       AS linh_vuc,

    /* 4. CHUYÊN VIÊN = người thực hiện (TargetUser); tra không ra thì lấy
          ChargeUser (cột text tên người phụ trách) */
    CAST(t.TargetUser AS SIGNED)                            AS id_chuyen_vien,
    COALESCE(
        NULLIF(MAX(u_target.eGovUserFullname), ''),
        NULLIF(t.ChargeUser, '')
    )                                                       AS chuyen_vien,

    /* 5. CÁC MỐC THỜI GIAN */
    DATE(t.StartedDate)                                     AS ngay_giao,
    DATE(t.ExpireDate)                                      AS han_xu_ly,
    DATE(COALESCE(t.CompletedDate, t.ApprovedDate))         AS ngay_hoan_thanh,

    /* 6. TÌNH TRẠNG — 5 giá trị RỜI NHAU, thứ tự WHEN quan trọng */
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

    CAST(t.Status AS SIGNED)                                AS status,
    '${sync_ts}' AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* TÊN ĐƠN VỊ — join department.id = ĐOẠN CUỐI của mã, giống hệt bảng task.
   REGEXP chặn CAST lỗi khi đoạn cuối không phải số. */
LEFT JOIN `db_theodoinv_hn`.`department` d
       ON d.id = CASE
            WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED)
            ELSE NULL
          END
      /* COALESCE: IsDelete NULL thì `= 0` trả NULL -> mất tên */
      AND COALESCE(d.IsDelete, 0) = 0

/* JOIN USER THỰC HIỆN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target
       ON u_target.eGovUserId = t.TargetUser

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

  /* LOẠI TRỪ 2 TRỤC GIAO KHÔNG TÍNH LÀ GIAO QUA — giống nv_nhan */
  AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.1775%'
  AND COALESCE(t.AssignDepartment, '') NOT LIKE '490.698%'

/* Gom 1 dòng / 1 TaskId: chống nhân dòng do LEFT JOIN qlnv_user & department */
GROUP BY t.TaskId
ON DUPLICATE KEY UPDATE
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `ten_nhiem_vu` = VALUES(`ten_nhiem_vu`),
    `van_ban_giao` = VALUES(`van_ban_giao`),
    `can_cu` = VALUES(`can_cu`),
    `id_don_vi_chu_tri` = VALUES(`id_don_vi_chu_tri`),
    `ten_don_vi_chu_tri` = VALUES(`ten_don_vi_chu_tri`),
    `linh_vuc` = VALUES(`linh_vuc`),
    `id_chuyen_vien` = VALUES(`id_chuyen_vien`),
    `chuyen_vien` = VALUES(`chuyen_vien`),
    `ngay_giao` = VALUES(`ngay_giao`),
    `han_xu_ly` = VALUES(`han_xu_ly`),
    `ngay_hoan_thanh` = VALUES(`ngay_hoan_thanh`),
    `tinh_trang` = VALUES(`tinh_trang`),
    `status` = VALUES(`status`),
    `sync_date` = VALUES(`sync_date`);
