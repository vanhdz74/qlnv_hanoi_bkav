/* ===========================================================================
   DDL — qlnv_lichsutiendo_nvgiao_pth_vpthanhuy
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (ExecuteSQLRecord chỉ nhận "truncate + select" bên dưới).
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_pth_vpthanhuy` (
    timeline_id              INT           NOT NULL,
    task_id                  INT           NULL,
    ma_nhiem_vu              VARCHAR(255)  NULL,      -- task.Code

    nguoi_xu_ly_id           INT           NULL,      -- eGovUserId
    nguoi_xu_ly_name         VARCHAR(255)  NULL,
    nguoi_xu_ly_vai_tro_id   INT           NULL,      -- eGovUserPositionId
    nguoi_xu_ly_vai_tro_name VARCHAR(255)  NULL,

    nguoi_nhan_id            INT           NULL,      -- eGovUserId
    nguoi_nhan_name          VARCHAR(255)  NULL,
    nguoi_nhan_vai_tro_id    INT           NULL,
    nguoi_nhan_vai_tro_name  VARCHAR(255)  NULL,

    `role`                   TINYINT       NULL,      -- từ khóa MySQL 8 -> backtick
    action_type              TINYINT       NULL,      -- 0..28, xem CASE trong SELECT
    ten_action_type          VARCHAR(64)   NULL,

    noi_dung                 LONGTEXT      NULL,      -- timeline.Content
    action_date              DATETIME      NULL,      -- ActionDate / CreatedDate
    sync_date                DATETIME      NULL,
    PRIMARY KEY (timeline_id),                          -- SELECT có GROUP BY tl.TimelineId
    KEY idx_task   (task_id),
    KEY idx_action (action_type, action_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_pth_vpthanhuy`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_pth_vpthanhuy` (
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

    MAX(u_target.eGovUserPositionId)                         AS nguoi_nhan_vai_tro_id,
    NULLIF(MAX(u_target.eGovUserPositionName), '')           AS nguoi_nhan_vai_tro_name,

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
    NOW()                                                   AS sync_date

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
        t.Status IN (-1, 0, 1, 2)
        OR (
            t.Status IN (3, 4)
            AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)
        )
    )

    /* ĐIỀU KIỆN ĐƠN VỊ GIAO CHÍNH XÁC 490.695 (VĂN PHÒNG THÀNH ỦY) */
    AND t.AssignDepartment = '490.695'

    /* LOẠI 3 NODE TỔNG HỢP "CÁC SỞ NGÀNH" (chung chung, không phải đơn vị thật).
       NOT IN => chỉ loại đúng 3 node này, VẪN GIỮ các đơn vị con bên dưới. */
    AND COALESCE(t.TargetDepartment, '') NOT IN (
        '490.698.1307',
        '490.698.1310',
        '490.698.1841'
    )

/* GOM NHÓM THEO TIMELINEID KHỬ TRÙNG LẶP TUYỆT ĐỐI */
GROUP BY tl.TimelineId;