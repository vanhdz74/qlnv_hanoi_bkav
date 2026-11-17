INSERT INTO datamart_hanoi.qlnv_tonghop_lichsutiendo_banTCTW (
    timeline_id,
    task_id,
    ma_nhiem_vu,

    nguoi_xu_ly_id,
    nguoi_xu_ly_name,
    nguoi_xu_ly_vai_tro_id,
    nguoi_xu_ly_vai_tro_name,

    nguoi_nhan_id,
    nguoi_nhan_name,
    nguoi_nhan_vai_tro_id,
    nguoi_nhan_vai_tro_name,

    role,
    action_type,

    noi_dung,
    action_date
)

SELECT
    /* =====================================================
       TIMELINE / TASK
       ===================================================== */
    tl.TimelineId AS timeline_id,
    tl.TaskId     AS task_id,

    /* MÃ NHIỆM VỤ */
    t.Code        AS ma_nhiem_vu,

    /* =====================================================
       NGƯỜI XỬ LÝ
       Ưu tiên UserId
       Nếu UserId NULL thì lấy CreateUser
       ===================================================== */
    COALESCE(
        tl.UserId,
        tl.CreateUser
    ) AS nguoi_xu_ly_id,

    COALESCE(
        NULLIF(u_action.eGovUserFullname, ''),
        NULLIF(u_create.eGovUserFullname, ''),
        CAST(
            COALESCE(
                tl.UserId,
                tl.CreateUser
            ) AS CHAR
        )
    ) AS nguoi_xu_ly_name,

    /* Vai trò / chức vụ người xử lý */
    COALESCE(
        u_action.eGovUserPositionId,
        u_create.eGovUserPositionId
    ) AS nguoi_xu_ly_vai_tro_id,

    COALESCE(
        NULLIF(u_action.eGovUserPositionName, ''),
        NULLIF(u_create.eGovUserPositionName, '')
    ) AS nguoi_xu_ly_vai_tro_name,

    /* =====================================================
       NGƯỜI NHẬN
       ===================================================== */
    tl.TargetUserId AS nguoi_nhan_id,

    COALESCE(
        NULLIF(u_target.eGovUserFullname, ''),
        CAST(tl.TargetUserId AS CHAR)
    ) AS nguoi_nhan_name,

    /* Vai trò / chức vụ người nhận */
    u_target.eGovUserPositionId
        AS nguoi_nhan_vai_tro_id,

    NULLIF(
        u_target.eGovUserPositionName,
        ''
    ) AS nguoi_nhan_vai_tro_name,

    /* =====================================================
       ROLE CỦA TIMELINE
       Giữ riêng, không dùng làm chức vụ
       ===================================================== */
    tl.Role AS role,

    /* =====================================================
       LOẠI HÀNH ĐỘNG
       ===================================================== */
    tl.ActionType AS action_type,

    /* =====================================================
       NỘI DUNG
       ===================================================== */
    tl.Content AS noi_dung,

    /* =====================================================
       THỜI GIAN
       ===================================================== */
    COALESCE(
        tl.ActionDate,
        tl.CreatedDate
    ) AS action_date

FROM db_theodoinv_hn.qlnv_timeline tl

/* =========================================================
   TASK
   ========================================================= */
INNER JOIN db_theodoinv_hn.qlnv_task t
    ON t.TaskId = tl.TaskId

/* =========================================================
   USER: qlnv_user bị trùng eGovUserId (id 0 có ~174 dòng, vài id 2-3 dòng)
   => gom 1 dòng / eGovUserId để không nhân bản timeline (Duplicate entry PRIMARY timeline_id)
   ========================================================= */
/* =========================================================
   USER THỰC HIỆN ACTION
   ========================================================= */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM db_theodoinv_hn.qlnv_user
    GROUP BY eGovUserId
) u_action
    ON u_action.eGovUserId = tl.UserId

/* =========================================================
   USER TẠO TIMELINE
   fallback khi tl.UserId NULL
   ========================================================= */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM db_theodoinv_hn.qlnv_user
    GROUP BY eGovUserId
) u_create
    ON u_create.eGovUserId = tl.CreateUser

/* =========================================================
   USER NHẬN / ĐƯỢC GIAO
   ========================================================= */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM db_theodoinv_hn.qlnv_user
    GROUP BY eGovUserId
) u_target
    ON u_target.eGovUserId = tl.TargetUserId

WHERE
    t.AssignDepartment LIKE '900000%'
    AND t.DeletedDate IS NULL

    /* =====================================================
       KHÔNG LẤY TASK CÓ TRẠNG THÁI "CHƯA XÁC ĐỊNH"
       ===================================================== */
    AND (
        t.Status IN (-1, 0, 1, 2)

        OR

        (
            t.Status IN (3, 4)
            AND (
                t.ExpireDate IS NULL

                OR COALESCE(
                    t.CompletedDate,
                    t.ApprovedDate
                ) IS NOT NULL
            )
        )
    );