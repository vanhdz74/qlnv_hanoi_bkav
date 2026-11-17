INSERT INTO `datamart_hanoi`.`qlnv_lichsutiendo_thongkenhanh_nv` (
    `timeline_id`,
    `task_id`,
    `ma_nhiem_vu`,
    `nguoi_xu_ly_id`,
    `nguoi_xu_ly_name`,
    `nguoi_xu_ly_vai_tro_id`,
    `nguoi_xu_ly_vai_tro_name`,
    `ma_phong_nguoi_xu_ly`,
    `ten_phong_nguoi_xu_ly`,
    `nguoi_nhan_id`,
    `nguoi_nhan_name`,
    `nguoi_nhan_vai_tro_id`,
    `nguoi_nhan_vai_tro_name`,
    `role`,
    `action_type`,
    `ten_action_type`,
    `noi_dung`,
    `action_date`,
    `sync_date`
)
SELECT
    tl.TimelineId                                           AS timeline_id,
    tl.TaskId                                               AS task_id,
    t.Code                                                  AS ma_nhiem_vu,

    /* 1. NGƯỜI XỬ LÝ (THAO TÁC) */
    COALESCE(tl.UserId, tl.CreateUser)                      AS nguoi_xu_ly_id,
    COALESCE(
        u_action.eGovUserFullname,
        u_create.eGovUserFullname,
        CAST(COALESCE(tl.UserId, tl.CreateUser) AS CHAR)
    )                                                       AS nguoi_xu_ly_name,

    COALESCE(
        u_action.eGovUserPositionId,
        u_create.eGovUserPositionId
    )                                                       AS nguoi_xu_ly_vai_tro_id,

    COALESCE(
        NULLIF(u_action.eGovUserPositionName, ''),
        NULLIF(u_create.eGovUserPositionName, '')
    )                                                       AS nguoi_xu_ly_vai_tro_name,

    /* PHÒNG BAN CỦA NGƯỜI XỬ LÝ */
    IF(d_action.id IS NULL, NULL,
       COALESCE(u_action.DepartmentPath, u_create.DepartmentPath)) AS ma_phong_nguoi_xu_ly,
    NULLIF(d_action.name, '')                               AS ten_phong_nguoi_xu_ly,

    /* 2. NGƯỜI NHẬN (ĐÃ SỬA CÚ PHÁP ĐÓNG NGOẶC NULLIF) */
    tl.TargetUserId                                         AS nguoi_nhan_id,
    COALESCE(
        NULLIF(u_target.eGovUserFullname, ''),
        CAST(tl.TargetUserId AS CHAR)
    )                                                       AS nguoi_nhan_name,

    u_target.eGovUserPositionId                             AS nguoi_nhan_vai_tro_id,
    NULLIF(u_target.eGovUserPositionName, '')               AS nguoi_nhan_vai_tro_name,

    /* 3. VAI TRÒ VÀ LOẠI HÀNH ĐỘNG */
    tl.Role                                                 AS role,
    tl.ActionType                                           AS action_type,

    CASE tl.ActionType
        WHEN 0 THEN 'Giao nhiệm vụ'
        WHEN 1 THEN 'Chỉnh sửa nhiệm vụ'
        WHEN 2 THEN 'Báo cáo công việc'
        WHEN 3 THEN 'Báo cáo % tiến độ'
        WHEN 4 THEN 'Duyệt báo cáo công việc'
        WHEN 5 THEN 'Từ chối báo cáo công việc'
        WHEN 6 THEN 'Trả lại nhiệm vụ'
        WHEN 7 THEN 'Gửi ý kiến xử lý'
        WHEN 8 THEN 'Xin gia hạn'
        WHEN 9 THEN 'Báo cáo hoàn thành'
        WHEN 10 THEN 'Kết thúc nhiệm vụ'
        WHEN 11 THEN 'Chuyển xử lý'
        WHEN 12 THEN 'Thu hồi báo cáo hoàn thành'
        WHEN 13 THEN 'Yêu cầu báo cáo tiến độ'
        WHEN 14 THEN 'Gửi báo cáo'
        WHEN 15 THEN 'Xóa nhiệm vụ'
        WHEN 16 THEN 'Duyệt báo cáo tiến độ'
        WHEN 17 THEN 'Duyệt xin gia hạn nhiệm vụ'
        WHEN 18 THEN 'Duyệt báo cáo hoàn thành'
        WHEN 19 THEN 'Từ chối báo cáo tiến độ'
        WHEN 20 THEN 'Từ chối xin gia hạn nhiệm vụ'
        WHEN 21 THEN 'Từ chối báo cáo hoàn thành'
        WHEN 22 THEN 'Thu hồi báo cáo hoàn thành'
        WHEN 23 THEN 'Thu hồi xin gia hạn'
        WHEN 24 THEN 'Báo cáo lộ trình triển khai'
        WHEN 25 THEN 'Duyệt báo cáo lộ trình'
        WHEN 26 THEN 'Từ chối báo cáo lộ trình'
        WHEN 27 THEN 'Thu hồi báo cáo lộ trình'
        WHEN 28 THEN 'Được tạo bởi AI bóc tách nhiệm vụ'
        ELSE 'Khác'
    END                                                     AS ten_action_type,

    /* 4. NỘI DUNG VÀ THỜI GIAN */
    tl.Content                                              AS noi_dung,
    COALESCE(tl.ActionDate, tl.CreatedDate)                 AS action_date,
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn`.`qlnv_timeline` tl

/* LỌC TASK THEO ĐIỀU KIỆN CHUẨN CỦA HỆ THỐNG */
INNER JOIN `db_theodoinv_hn`.`qlnv_task` t
        ON t.TaskId = tl.TaskId
       AND t.DeletedDate IS NULL
       AND t.Status <> 5
       AND (
           t.Status IN (-1, 0, 1, 2)
           OR (
               t.Status IN (3, 4)
               AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
           )
       )

/* CHỈ LẤY TASK CÓ ĐƠN VỊ GIAO & ĐƠN VỊ NHẬN CÒN TỒN TẠI (IsDelete <> 1) */
INNER JOIN `db_theodoinv_hn`.`department` d_giao
        ON d_giao.id = CASE 
             WHEN SUBSTRING_INDEX(t.AssignDepartment, '.', -1) REGEXP '^[0-9]+$' 
             THEN CAST(SUBSTRING_INDEX(t.AssignDepartment, '.', -1) AS UNSIGNED) 
             ELSE NULL 
           END
       AND COALESCE(d_giao.IsDelete, 0) <> 1

INNER JOIN `db_theodoinv_hn`.`department` d_nhan
        ON d_nhan.id = CASE 
             WHEN SUBSTRING_INDEX(t.TargetDepartment, '.', -1) REGEXP '^[0-9]+$' 
             THEN CAST(SUBSTRING_INDEX(t.TargetDepartment, '.', -1) AS UNSIGNED) 
             ELSE NULL 
           END
       AND COALESCE(d_nhan.IsDelete, 0) <> 1

/* TRA CỨU USER THAO TÁC (KÈM DEPARTMENTPATH) */
LEFT JOIN (
    SELECT 
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName,
        MAX(DepartmentPath)       AS DepartmentPath
    FROM `db_theodoinv_hn`.`qlnv_user`
    WHERE eGovUserId IS NOT NULL
    GROUP BY eGovUserId
) u_action ON u_action.eGovUserId = tl.UserId

/* TRA CỨU USER TẠO BẢN GHI (KÈM DEPARTMENTPATH) */
LEFT JOIN (
    SELECT 
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName,
        MAX(DepartmentPath)       AS DepartmentPath
    FROM `db_theodoinv_hn`.`qlnv_user`
    WHERE eGovUserId IS NOT NULL
    GROUP BY eGovUserId
) u_create ON u_create.eGovUserId = tl.CreateUser

/* TRA CỨU USER ĐÍCH / NHẬN */
LEFT JOIN (
    SELECT 
        eGovUserId,
        MAX(eGovUserFullname)     AS eGovUserFullname,
        MAX(eGovUserPositionId)   AS eGovUserPositionId,
        MAX(eGovUserPositionName) AS eGovUserPositionName
    FROM `db_theodoinv_hn`.`qlnv_user`
    WHERE eGovUserId IS NOT NULL
    GROUP BY eGovUserId
) u_target ON u_target.eGovUserId = tl.TargetUserId

/* GIẢI MÃ TÊN PHÒNG BAN NGƯỜI XỬ LÝ (CHỐNG LỖI CAST INT) */
LEFT JOIN `db_theodoinv_hn`.`department` d_action
       ON d_action.id = CASE 
            WHEN SUBSTRING_INDEX(COALESCE(u_action.DepartmentPath, u_create.DepartmentPath), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(COALESCE(u_action.DepartmentPath, u_create.DepartmentPath), '.', -1) AS UNSIGNED)
            ELSE NULL 
          END
      AND COALESCE(d_action.IsDelete, 0) <> 1;