/* ===========================================================================
   DDL — qlnv_tonghop_chitiet_nvgiao_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).

   Ghi chú: Cột ld_ubnd / ld_van_phong giữ nguyên tên theo bản pth_ubndtp (SELECT trả NULL);
   đổi thành ld_thanh_uy nếu muốn đúng nghiệp vụ Thành ủy.
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_vpthanhuy` (
    id_truc_giao              VARCHAR(50)   NULL,     -- task.AssignDepartment (mã Part)
    truc_giao                 VARCHAR(500)  NULL,
    nhom_nhiem_vu             VARCHAR(255)  NULL,     -- task.NameGroup

    ma_nhiem_vu               VARCHAR(255)  NULL,     -- task.Code
    ten_nhiem_vu              TEXT          NULL,     -- task.Title varchar(6000)
    van_ban_giao              VARCHAR(50)   NULL,     -- task.DocCode

    id_don_vi_chu_tri         VARCHAR(50)   NULL,     -- TargetDepartment đẩy về cấp 3
    ten_don_vi_chu_tri        VARCHAR(500)  NULL,

    id_lanh_dao               INT           NULL,     -- eGovUserId (task.TargetUser)
    ten_lanh_dao              VARCHAR(255)  NULL,
    id_chuyen_vien            INT           NULL,     -- hiện SELECT trả NULL
    chuyen_vien               VARCHAR(255)  NULL,     -- hiện SELECT trả NULL

    ngay_giao                 VARCHAR(10)   NULL,     -- dd/mm/yyyy (DATE_FORMAT)
    han_xu_ly                 VARCHAR(10)   NULL,     -- dd/mm/yyyy
    ngay_hoan_thanh           VARCHAR(10)   NULL,     -- dd/mm/yyyy
    ngay_xoa                  VARCHAR(10)   NULL,     -- dd/mm/yyyy

    tinh_trang                VARCHAR(32)   NULL,
    tinh_hinh_ket_qua         LONGTEXT      NULL,     -- report.Content / task.Content

    ld_ubnd                   VARCHAR(255)  NULL,     -- placeholder, SELECT trả NULL
    ld_van_phong              VARCHAR(255)  NULL,     -- placeholder, SELECT trả NULL
    phong_chuyen_mon_theo_doi VARCHAR(500)  NULL,     -- department.name của người tạo
    chuyen_vien_vp_theo_doi   VARCHAR(255)  NULL,     -- eGovUserFullname của người tạo

    task_id                   INT           NOT NULL,
    status                    TINYINT       NULL,
    sync_date                 DATETIME      NULL,
    PRIMARY KEY (task_id),                              -- SELECT có GROUP BY t.TaskId
    KEY idx_tinh_trang (tinh_trang),
    KEY idx_don_vi     (id_don_vi_chu_tri)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_vpthanhuy` (
    `id_truc_giao`,
    `truc_giao`,
    `nhom_nhiem_vu`,
    `ma_nhiem_vu`,
    `ten_nhiem_vu`,
    `van_ban_giao`,
    `id_don_vi_chu_tri`,
    `ten_don_vi_chu_tri`,
    `id_lanh_dao`,
    `ten_lanh_dao`,
    `id_chuyen_vien`,
    `chuyen_vien`,
    `ngay_giao`,
    `han_xu_ly`,
    `ngay_hoan_thanh`,
    `ngay_xoa`,
    `tinh_trang`,
    `tinh_hinh_ket_qua`,
    `ld_ubnd`,
    `ld_van_phong`,
    `phong_chuyen_mon_theo_doi`,
    `chuyen_vien_vp_theo_doi`,
    `task_id`,
    `status`,
    `sync_date`
)
SELECT
    /* 1. NHÓM NHIỆM VỤ / TRỤC GIAO */
    t.AssignDepartment                                     AS id_truc_giao,
    COALESCE(NULLIF(t.AssignOrganization, ''), MAX(d_assign_cap2.name)) AS truc_giao,

	t.NameGroup AS nhom_nhiem_vu,

    /* 2. MÃ NHIỆM VỤ & TÊN NHIỆM VỤ */
    t.Code                                                 AS ma_nhiem_vu,
    t.Title                                                AS ten_nhiem_vu,

    /* 3. VĂN BẢN GIAO */
    t.DocCode                                              AS van_ban_giao,

    /* 4. ĐƠN VỊ THỰC HIỆN / CHỦ TRÌ (CHUẨN HÓA CẤP) */
    CASE
        /* Nhánh sở ngành 1307 / 1310 / 1841: chỉ đẩy về cấp 4 (cấp 5 -> cấp 4),
           vì cấp 3 của 3 nhánh này là node tổng hợp "các sở ngành" */
        WHEN t.TargetDepartment LIKE '490.698.1307%'
          OR t.TargetDepartment LIKE '490.698.1310%'
          OR t.TargetDepartment LIKE '490.698.1841%'
        THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
        /* Còn lại: đẩy về cấp 3 (cấp 4 trở lên -> cấp 3) */
        ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
    END                                                    AS id_don_vi_chu_tri,

    COALESCE(
        MAX(d_chutri.name)
    )                                                      AS ten_don_vi_chu_tri,

    /* 5. LÃNH ĐẠO ĐƠN VỊ VÀ CHUYÊN VIÊN */
    t.TargetUser                                           AS id_lanh_dao,
    MAX(u_target.eGovUserFullname)                         AS ten_lanh_dao,
    NULL                                                   AS id_chuyen_vien,
    NULL                                                   AS chuyen_vien,

    /* 6. CÁC MỐC THỜI GIAN */
    DATE_FORMAT(t.StartedDate, '%d/%m/%Y')                 AS ngay_giao,
    DATE_FORMAT(t.ExpireDate, '%d/%m/%Y')                  AS han_xu_ly,
    DATE_FORMAT(t.CompletedDate, '%d/%m/%Y')               AS ngay_hoan_thanh,
    DATE_FORMAT(t.DeletedDate, '%d/%m/%Y')                 AS ngay_xoa,

    /* 7. PHÂN LOẠI 4 TÌNH TRẠNG CHUẨN */
    CASE
        WHEN t.Status IN (3, 4)
             AND t.ExpireDate IS NOT NULL
             AND COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL
        THEN 'Đã hoàn thành'

        WHEN t.ExpireDate IS NULL
        THEN 'Thường xuyên'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate >= CURDATE()
        THEN 'Chưa hoàn thành trong hạn'

        WHEN t.Status IN (-1, 0, 1, 2)
             AND t.ExpireDate IS NOT NULL
             AND t.ExpireDate < CURDATE()
        THEN 'Chưa hoàn thành quá hạn'
    END                                                    AS tinh_trang,

    /* 8. TÌNH HÌNH, KẾT QUẢ THỰC HIỆN */
    COALESCE(
        (
            SELECT rp.Content 
            FROM `db_theodoinv_hn`.`qlnv_report` rp 
            WHERE rp.TaskId = t.TaskId 
              AND rp.DeletedDate IS NULL 
            ORDER BY rp.CreatedDate DESC, rp.ReportId DESC 
            LIMIT 1
        ), 
        t.Content
    )                                                      AS tinh_hinh_ket_qua,

    /* 9. BỔ SUNG 4 CỘT THEO DÕI
          - ld_ubnd / ld_van_phong: chưa có logic xử lý -> tạm để NULL
          - phong_chuyen_mon_theo_doi / chuyen_vien_vp_theo_doi:
            lấy theo t.CreateUser (người tạo nhiệm vụ) -> qlnv_user -> DepartmentPath -> department */
    CAST(NULL AS CHAR(255))                                AS ld_ubnd,
    CAST(NULL AS CHAR(255))                                AS ld_van_phong,

    NULLIF(MAX(d_create.name), '')                         AS phong_chuyen_mon_theo_doi,

    NULLIF(MAX(u_create.eGovUserFullname), '')             AS chuyen_vien_vp_theo_doi,

    /* 10. KHÓA HỆ THỐNG & ĐỒNG BỘ */
    t.TaskId                                               AS task_id,
    t.Status                                               AS status,
    NOW()                                                  AS sync_date

FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN TÊN ĐƠN VỊ TRỤC GIAO CẤP 2 */
LEFT JOIN `db_theodoinv_hn`.`department` d_assign_cap2
       ON d_assign_cap2.id = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(t.AssignDepartment, '.', 2), '.', -1) 
            AS UNSIGNED
          ) AND d_assign_cap2.IsDelete = 0

/* JOIN ĐƠN VỊ CHỦ TRÌ (theo id cấp đã chuẩn hóa) */
LEFT JOIN `db_theodoinv_hn`.`department` d_chutri
       ON d_chutri.id = CAST(
            SUBSTRING_INDEX(
                CASE
                    WHEN t.TargetDepartment LIKE '490.698.1307%'
                      OR t.TargetDepartment LIKE '490.698.1310%'
                      OR t.TargetDepartment LIKE '490.698.1841%'
                    THEN SUBSTRING_INDEX(t.TargetDepartment, '.', 4)
                    ELSE SUBSTRING_INDEX(t.TargetDepartment, '.', 3)
                END,
                '.',
                -1
            ) AS UNSIGNED
          ) AND d_chutri.IsDelete = 0

/* JOIN USER NHẬN */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target 
       ON u_target.eGovUserId = t.TargetUser

/* JOIN NGƯỜI TẠO NHIỆM VỤ (chuyên viên VP theo dõi) */
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = t.CreateUser

/* JOIN PHÒNG/ĐƠN VỊ CỦA NGƯỜI TẠO (phòng chuyên môn theo dõi) */
LEFT JOIN `db_theodoinv_hn`.`department` d_create
       ON d_create.id = CAST(
            SUBSTRING_INDEX(u_create.DepartmentPath, '.', -1) AS UNSIGNED
          ) AND d_create.IsDelete = 0

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )

    /* ĐIỀU KIỆN ĐƠN VỊ GIAO CHÍNH XÁC 490.695 (THÀNH ỦY) */
    AND t.AssignDepartment = '490.695'

    /* LOẠI 3 NODE TỔNG HỢP "CÁC SỞ NGÀNH" (chung chung, không phải đơn vị thật).
       NOT IN => chỉ loại đúng 3 node này, VẪN GIỮ các đơn vị con bên dưới. */
    AND COALESCE(t.TargetDepartment, '') NOT IN (
        '490.698.1307',
        '490.698.1310',
        '490.698.1841'
    )

/* GOM NHÓM THEO TASK_ID ĐỂ KHỬ TRÙNG LẶP TUYỆT ĐỐI */
GROUP BY t.TaskId;