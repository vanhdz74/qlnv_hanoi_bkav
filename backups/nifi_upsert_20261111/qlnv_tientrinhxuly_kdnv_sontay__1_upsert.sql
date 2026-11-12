/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO `datamart_hanoi`.`qlnv_tientrinhxuly_kdnv_sontay` (
    `timeline_id`,
    `task_id`,
    `ma_nhiem_vu`,

    `nguoi_xu_ly_id`,
    `nguoi_xu_ly_name`,
    `nguoi_xu_ly_vai_tro_id`,
    `nguoi_xu_ly_vai_tro_name`,

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
    MAX(t.Code)                                             AS ma_nhiem_vu,

    COALESCE(tl.UserId, tl.CreateUser)                      AS nguoi_xu_ly_id,
    COALESCE(
        NULLIF(MAX(u_action.eGovUserFullname), ''),
        NULLIF(MAX(u_create.eGovUserFullname), ''),
        CAST(COALESCE(tl.UserId, tl.CreateUser) AS CHAR)
    )                                                       AS nguoi_xu_ly_name,

    COALESCE(
        MAX(u_action.eGovUserPositionId),
        MAX(u_create.eGovUserPositionId)
    )                                                       AS nguoi_xu_ly_vai_tro_id,

    COALESCE(
        NULLIF(MAX(u_action.eGovUserPositionName), ''),
        NULLIF(MAX(u_create.eGovUserPositionName), '')
    )                                                       AS nguoi_xu_ly_vai_tro_name,

    tl.TargetUserId                                         AS nguoi_nhan_id,
    COALESCE(
        NULLIF(MAX(u_target.eGovUserFullname), ''),
        CAST(tl.TargetUserId AS CHAR)
    )                                                       AS nguoi_nhan_name,

    MAX(u_target.eGovUserPositionId)                        AS nguoi_nhan_vai_tro_id,
    NULLIF(MAX(u_target.eGovUserPositionName), '')          AS nguoi_nhan_vai_tro_name,

    tl.Role                                                 AS role,
    tl.ActionType                                           AS action_type,

    /* Map Description từ Enum Notification */
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

    tl.Content                                              AS noi_dung,
    COALESCE(tl.ActionDate, tl.CreatedDate)                 AS action_date,
    '${sync_ts}' AS sync_date

FROM `db_theodoinv_hn`.`qlnv_timeline` tl

INNER JOIN `db_theodoinv_hn`.`qlnv_task` t
        ON t.TaskId = tl.TaskId

LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_action
       ON u_action.eGovUserId = tl.UserId

LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_create
       ON u_create.eGovUserId = tl.CreateUser

LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u_target
       ON u_target.eGovUserId = tl.TargetUserId

WHERE
    t.DeletedDate IS NULL
    AND t.Status <> 5
    AND (
        /* TH1: AssignDepartment = '490.698.1310.1496' giao đi */
        t.AssignDepartment = '490.698.1310.1496'

        OR

        /* TH2: Trục khác giao sang (Nhận) */
        (
            /* Giao trực tiếp */
            t.TargetDepartment = '490.698.1310.1496'

            OR

            /* Giao cấp con -> check log trong qlnv_task_user */
            (
                t.TargetDepartment LIKE '490.698.1310.1496.%'
                AND EXISTS (
                    SELECT 1
                    FROM `db_theodoinv_hn`.`qlnv_task_user` tu
                    WHERE tu.TaskId = t.TaskId
                      AND tu.DepartmentId = '490.698.1310.1496'
                )
            )
        )
    )

/* GOM NHÓM THEO TIMELINEID ĐỂ KHỬ TRÙNG KHÓA CHÍNH */
GROUP BY tl.TimelineId
ON DUPLICATE KEY UPDATE
    `task_id` = VALUES(`task_id`),
    `ma_nhiem_vu` = VALUES(`ma_nhiem_vu`),
    `nguoi_xu_ly_id` = VALUES(`nguoi_xu_ly_id`),
    `nguoi_xu_ly_name` = VALUES(`nguoi_xu_ly_name`),
    `nguoi_xu_ly_vai_tro_id` = VALUES(`nguoi_xu_ly_vai_tro_id`),
    `nguoi_xu_ly_vai_tro_name` = VALUES(`nguoi_xu_ly_vai_tro_name`),
    `nguoi_nhan_id` = VALUES(`nguoi_nhan_id`),
    `nguoi_nhan_name` = VALUES(`nguoi_nhan_name`),
    `nguoi_nhan_vai_tro_id` = VALUES(`nguoi_nhan_vai_tro_id`),
    `nguoi_nhan_vai_tro_name` = VALUES(`nguoi_nhan_vai_tro_name`),
    `role` = VALUES(`role`),
    `action_type` = VALUES(`action_type`),
    `ten_action_type` = VALUES(`ten_action_type`),
    `noi_dung` = VALUES(`noi_dung`),
    `action_date` = VALUES(`action_date`),
    `sync_date` = VALUES(`sync_date`);
