/* ===========================================================================
   DDL — qlnv_thongke_nhanh_chitiet_nv_vpthanhuy

   Mỗi dòng = 1 NHIỆM VỤ (chiều NHẬN — đơn vị chủ trì là đơn vị thực hiện).
   Bảng danh sách để FE hiển thị/lọc, KHÔNG tự thống kê.

   ĐÂY LÀ PHẦN DỮ LIỆU MỞ RỘNG của `qlnv_thongke_nhanh_task_vpthanhuy` (chieu='nhan'):
   cùng phạm vi, cùng tập task, cùng cách tính `ten_don_vi` và `tinh_trang`
   -> join 1-1 theo task_id. Chỉ khác là có thêm cột lĩnh vực / chuyên viên / căn cứ.

   PHẠM VI & LOẠI TRỪ — giống hệt nhánh chieu='nhan':
       (AssignDepartment LIKE '490.695%' OR TargetDepartment LIKE '490.695%')
       AND AssignDepartment NOT LIKE '490.1775%'
       AND AssignDepartment NOT LIKE '490.698%'

   Ngày để kiểu DATE (không phải chuỗi dd/mm/yyyy) để FE lọc khoảng thời gian.

   ⚠ KHÔNG có khóa duy nhất (để KEY, không để PRIMARY KEY) — giống các file nv_nhan,
   để PutSQL của NiFi ghi lại batch (retry) không vỡ vì lỗi 1062.
   Đổi lại, BẮT BUỘC phải truncate trước mỗi lần nạp.

   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi.
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_thongke_nhanh_chitiet_nv_vpthanhuy` (
    task_id                  INT           NOT NULL,

    ma_nhiem_vu              VARCHAR(255)  NULL,       -- task.Code
    ten_nhiem_vu             TEXT          NULL,       -- task.Title
    van_ban_giao             VARCHAR(255)  NULL,       -- DocCode, thiếu thì DocumentCode
    can_cu                   VARCHAR(500)  NULL,       -- trích yếu văn bản (Compendium)

    id_don_vi_chu_tri        VARCHAR(50)   NULL,       -- task.TargetDepartment (mã Part)
    ten_don_vi_chu_tri       VARCHAR(500)  NULL,

    linh_vuc                 VARCHAR(256)  NULL,       -- qlnv_sector.SectorName (qua resolution), thiếu thì 'Khác'
    id_chuyen_vien           INT           NULL,       -- eGovUserId (task.TargetUser)
    chuyen_vien              VARCHAR(255)  NULL,

    /* --- NGÀY (kiểu DATE, cho FE lọc) --- */
    ngay_giao                DATE          NULL,       -- task.StartedDate
    han_xu_ly                DATE          NULL,       -- task.ExpireDate
    ngay_hoan_thanh          DATE          NULL,       -- COALESCE(CompletedDate, ApprovedDate)

    /* --- TÌNH TRẠNG: 5 giá trị RỜI NHAU, giống bảng task --- */
    tinh_trang               VARCHAR(32)   NULL,

    status                   TINYINT       NULL,
    sync_date                DATETIME      NULL,

    KEY idx_task      (task_id),          -- ⚠ KHÔNG phải PK: xem ghi chú đầu file
    KEY idx_don_vi    (ten_don_vi_chu_tri(191)),
    KEY idx_linh_vuc  (linh_vuc(191)),
    KEY idx_ngay_giao (ngay_giao),
    KEY idx_han       (han_xu_ly),
    KEY idx_tinh_trang(tinh_trang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_thongke_nhanh_chitiet_nv_vpthanhuy`;

   ⚠ Bảng không có khóa duy nhất nên truncate là BẮT BUỘC, không được bỏ qua:
   thiếu nó thì mỗi lần chạy sẽ cộng dồn thêm một bộ dữ liệu nữa.
   --------------------------------------------------------------------------- */


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

    /* 3. LĨNH VỰC: lĩnh vực văn bản (qlnv_sector qua resolution.SectorId); rỗng thì 'Khác' */
    COALESCE(NULLIF(MAX(s.SectorName), ''), 'Khác')        AS linh_vuc,

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
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* VĂN BẢN & LĨNH VỰC VĂN BẢN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_resolution` r
       ON r.ResolutionId = t.ResolutionId
      AND r.DeletedDate IS NULL
LEFT JOIN `db_theodoinv_hn`.`qlnv_sector` s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

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
GROUP BY t.TaskId;
