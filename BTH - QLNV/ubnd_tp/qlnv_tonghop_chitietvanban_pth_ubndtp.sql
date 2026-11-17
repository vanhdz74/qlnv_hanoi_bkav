USE db_theodoinv_hn;

SELECT
    /* =====================================================
       THỜI GIAN
       ===================================================== */
    YEAR(r.StartDate) AS yearkey,

    /* =====================================================
       VĂN BẢN / NGHỊ QUYẾT
       ===================================================== */
    r.ResolutionId,
    r.ResolutionGroupId,
    r.Compendium,
    r.DocCode,

    /* =====================================================
       KIỂU VĂN BẢN
       ===================================================== */
    rg.Name AS Kieu,

    /* =====================================================
       LĨNH VỰC
       ===================================================== */
    COALESCE(NULLIF(s.SectorName, ''), 'Khác') AS LinhVuc,

    /* =====================================================
       NGÀY VĂN BẢN
       ===================================================== */
    DATE_FORMAT(
        r.StartDate,
        '%d/%m/%Y'
    ) AS NgayVanBan,

    /* =====================================================
       CƠ QUAN BAN HÀNH
       ===================================================== */
    COALESCE(
        NULLIF(r.AssignOrganizationName, ''),
        NULLIF(r.AssignOrganization, '')
    ) AS CoQuanBanHanh,

    /* =====================================================
       LOẠI CẤP CHA
       Path bắt đầu:
       490.698.752...

       segment 2 = 698
       -> department.name
       ===================================================== */
    d_capcha.name AS loaicapcha,

    /* =====================================================
       LOẠI CẤP
       segment 3 = 752
       -> department.name
       ===================================================== */
    d_cap.name AS loaicap,

    /* =====================================================
       ID ĐƠN VỊ CẤP TRÊN

       LẤY PHẦN GẦN CUỐI CỦA PATH

       VD:
       490.698.752.794.806
                   -> 794

       490.698.752.794.806.900
                       -> 806
       ===================================================== */
    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(
                u.DepartmentPath,
                '.',
                -2
            ),
            '.',
            1
        ) AS UNSIGNED
    ) AS iddv_captren,

    /* =====================================================
       ID ĐƠN VỊ

       LẤY PHẦN CUỐI CÙNG CỦA PATH
       ===================================================== */
    CAST(
        SUBSTRING_INDEX(
            u.DepartmentPath,
            '.',
            -1
        ) AS UNSIGNED
    ) AS iddv,

    /* =====================================================
       TÊN ĐƠN VỊ

       Tra department theo ID cuối cùng
       ===================================================== */
    d_donvi.name AS donvi,

    /* =====================================================
       TÊN VIẾT TẮT

       Cũng tra theo ID cuối cùng
       ===================================================== */
    COALESCE(
        NULLIF(d_donvi.shortname, ''),
        d_donvi.name
    ) AS tenviettat,

    /* =====================================================
       NGƯỜI TẠO
       ===================================================== */
    r.CreateUser AS nguoitao_id,

    u.UserName AS nguoitao_taikhoan,

    u.eGovUserFullname AS nguoitao_ten,

    /* =====================================================
       SỐ NHIỆM VỤ
       ===================================================== */
    COALESCE(
        tc.so_nhiem_vu,
        0
    ) AS so_nhiem_vu

FROM db_theodoinv_hn.qlnv_resolution r

/* =========================================================
   NHÓM / LOẠI VĂN BẢN
   ========================================================= */
LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg
       ON rg.ResolutionGroupId = r.ResolutionGroupId
      AND rg.DeletedDate IS NULL

/* =========================================================
   LĨNH VỰC
   ========================================================= */
LEFT JOIN db_theodoinv_hn.qlnv_sector s
       ON s.SectorId = r.SectorId
      AND s.DeletedDate IS NULL
      AND s.IsActive = 1

/* =========================================================
   NGƯỜI TẠO
   Lấy DepartmentPath từ user
   ========================================================= */
LEFT JOIN db_theodoinv_hn.qlnv_user u
       ON u.eGovUserId = r.CreateUser

/* =========================================================
   698 -> loaicapcha
   ========================================================= */
LEFT JOIN db_theodoinv_hn.department d_capcha
       ON d_capcha.id = CAST(
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(
                    u.DepartmentPath,
                    '.',
                    2
                ),
                '.',
                -1
            ) AS UNSIGNED
       )
      AND d_capcha.IsDelete = 0

/* =========================================================
   752 -> loaicap
   ========================================================= */
LEFT JOIN db_theodoinv_hn.department d_cap
       ON d_cap.id = CAST(
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(
                    u.DepartmentPath,
                    '.',
                    3
                ),
                '.',
                -1
            ) AS UNSIGNED
       )
      AND d_cap.IsDelete = 0

/* =========================================================
   ĐƠN VỊ HIỆN TẠI

   Luôn lấy ID CUỐI CÙNG của DepartmentPath

   VD:
   490.698.752.794.806
                   -> 806

   490.698.752.794.806.900
                       -> 900
   ========================================================= */
LEFT JOIN db_theodoinv_hn.department d_donvi
       ON d_donvi.id = CAST(
            SUBSTRING_INDEX(
                u.DepartmentPath,
                '.',
                -1
            ) AS UNSIGNED
       )
      AND d_donvi.IsDelete = 0

/* =========================================================
   ĐẾM NHIỆM VỤ THEO RESOLUTION
   ========================================================= */
LEFT JOIN
(
    SELECT
        x.ResolutionId,
        COUNT(DISTINCT x.TaskId) AS so_nhiem_vu

    FROM
    (
        /* Quan hệ qua bảng trung gian */
        SELECT
            tr.ResolutionId,
            tr.TaskId
        FROM db_theodoinv_hn.qlnv_task_resolution tr

        UNION

        /* Quan hệ trực tiếp trong qlnv_task */
        SELECT
            t1.ResolutionId,
            t1.TaskId
        FROM db_theodoinv_hn.qlnv_task t1

        WHERE t1.ResolutionId > 0
          AND t1.DeletedDate IS NULL

    ) x

    INNER JOIN db_theodoinv_hn.qlnv_task t2
            ON t2.TaskId = x.TaskId
           AND t2.DeletedDate IS NULL
           /* =================================================
              CHỈ GIỮ TASK CÓ TÌNH TRẠNG XÁC ĐỊNH
              (loại đúng 2 ca CASE trả 'Chưa xác định')
              ================================================= */
           /* 1. Loại Status=5 (thu hồi) và giá trị ngoài bảng mã */
           AND t2.Status IN (-1, 0, 1, 2, 3, 4)

           /* 2. Đã HT mà có hạn thì buộc phải có ngày HT.
                 Chưa HT (-1,0,1,2) và mọi ca không có hạn: đã xác định */
           AND (
                t2.Status NOT IN (3, 4)
                OR t2.ExpireDate IS NULL
                OR COALESCE(t2.CompletedDate, t2.ApprovedDate) IS NOT NULL
           )

    GROUP BY
        x.ResolutionId

) tc
    ON tc.ResolutionId = r.ResolutionId

WHERE
    r.DeletedDate IS NULL

    /* =====================================================
       CHỈ LẤY NHÁNH NÀY
       ===================================================== */
    AND u.DepartmentPath LIKE '490.698.752%'

ORDER BY
    r.StartDate DESC,
    r.ResolutionId DESC;


