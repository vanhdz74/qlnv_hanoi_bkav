/* ===========================================================================
   DDL — qlnv_lichsutiendo_nvgiao_phongban_ubndtp
   Chạy MỘT LẦN bằng tay trên `datamart_hanoi`. KHÔNG dán khối này vào NiFi
   (NiFi chỉ nhận "truncate + câu lệnh" bên dưới).
   =========================================================================== */

CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_phongban_ubndtp` (
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
    id_phong_ban              VARCHAR(255)  NULL,     -- cấp cuối DepartmentPath của phòng ban
    sync_date                DATETIME      NULL,
    PRIMARY KEY (timeline_id),                          -- mỗi timeline 1 dòng (user đã khử trùng)
    KEY idx_task   (task_id),
    KEY idx_action (action_type, action_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/* --- Dòng truncate cho NiFi: dán ĐỨNG TRƯỚC câu lệnh bên dưới ---------------
   (JDBC phải bật allowMultiQueries=true)

   truncate table `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_phongban_ubndtp`;
   --------------------------------------------------------------------------- */


INSERT INTO `datamart_hanoi`.`qlnv_lichsutiendo_nvgiao_phongban_ubndtp` (
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
    `id_phong_ban`,
    `sync_date`
)


SELECT
    tl.TimelineId                                           AS timeline_id,
    tl.TaskId                                               AS task_id,
    t.Code                                                  AS ma_nhiem_vu,

    COALESCE(tl.UserId, tl.CreateUser)                      AS nguoi_xu_ly_id,
    COALESCE(
        NULLIF(u_action.fullname, ''),
        NULLIF(u_create.fullname, ''),
        CAST(COALESCE(tl.UserId, tl.CreateUser) AS CHAR)
    )                                                       AS nguoi_xu_ly_name,

    COALESCE(u_action.position_id, u_create.position_id)    AS nguoi_xu_ly_vai_tro_id,

    COALESCE(
        NULLIF(u_action.position_name, ''),
        NULLIF(u_create.position_name, '')
    )                                                       AS nguoi_xu_ly_vai_tro_name,

    tl.TargetUserId                                         AS nguoi_nhan_id,
    COALESCE(
        NULLIF(u_target.fullname, ''),
        CAST(tl.TargetUserId AS CHAR)
    )                                                       AS nguoi_nhan_name,

    u_target.position_id                                    AS nguoi_nhan_vai_tro_id,
    NULLIF(u_target.position_name, '')                      AS nguoi_nhan_vai_tro_name,

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
    /* PHÒNG BAN: cấp cuối của đơn vị giao, không thuộc phòng ban thì lấy từ người tạo */
    SUBSTRING_INDEX(COALESCE(
        IF(t.AssignDepartment LIKE '490.698.752.%', t.AssignDepartment, NULL),
        (SELECT MIN(uc.DepartmentPath)
         FROM `db_theodoinv_hn`.`qlnv_user` uc
         WHERE uc.eGovUserId = t.CreateUser
           AND uc.DepartmentPath LIKE '490.698.752.%')
    ), '.', -1)                                             AS id_phong_ban,
    NOW()                                                   AS sync_date

/* LẤY TẬP NHIỆM VỤ HỢP LỆ TRƯỚC (rất chọn lọc) RỒI MỚI BUNG RA TIMELINE */
FROM `db_theodoinv_hn`.`qlnv_task` t

/* JOIN NHÓM NHIỆM VỤ: LỌC TRỰC TIẾP ID NHÓM '55', 132 */
INNER JOIN `db_theodoinv_hn`.`qlnv_resolution` r
        ON r.ResolutionId = t.ResolutionId
       AND r.DeletedDate IS NULL
    --    AND r.ResolutionGroupId IN (55, 132)

INNER JOIN `db_theodoinv_hn`.`qlnv_timeline` tl
        ON tl.TaskId = t.TaskId

/* DANH BẠ USER ĐÃ KHỬ TRÙNG eGovUserId - CHỈ GIỮ 4 CỘT CẦN DÙNG.
   Nhờ vậy 3 LEFT JOIN dưới đây không thể nhân dòng, bỏ được GROUP BY ở ngoài. */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn`.`qlnv_user`
    GROUP BY eGovUserId
) u_action
       ON u_action.eGovUserId = tl.UserId

LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn`.`qlnv_user`
    GROUP BY eGovUserId
) u_create
       ON u_create.eGovUserId = tl.CreateUser

LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn`.`qlnv_user`
    GROUP BY eGovUserId
) u_target
       ON u_target.eGovUserId = tl.TargetUserId

/* ĐIỀU KIỆN LẤY TASK: đồng bộ với qlnv_tonghop_chitiet_nvgiao_phongban_ubndtp */
WHERE t.DeletedDate IS NULL
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4) AND (t.ExpireDate IS NULL OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))
  /* PHÒNG BAN GIAO: đơn vị giao thuộc phòng ban 490.698.752.x,
     hoặc người tạo nhiệm vụ (chuyên viên tham mưu) thuộc phòng ban 490.698.752.x */
  AND (   t.AssignDepartment LIKE '490.698.752.%'
       OR EXISTS (SELECT 1 FROM `db_theodoinv_hn`.`qlnv_user` uc
                  WHERE uc.eGovUserId = t.CreateUser
                    AND uc.DepartmentPath LIKE '490.698.752.%'))
  /* Loại nhóm văn bản 82, 109 */
--   AND r.ResolutionGroupId NOT IN (82, 109)
;
