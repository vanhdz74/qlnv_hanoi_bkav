CREATE TABLE IF NOT EXISTS `db_theodoinv_hn_test_data`.`qlnv_lichsutiendo_bcd57_cap_tp` (
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
    PRIMARY KEY (timeline_id),                          -- mỗi timeline 1 dòng (user đã khử trùng)
    KEY idx_task   (task_id),
    KEY idx_action (action_type, action_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

TRUNCATE TABLE `db_theodoinv_hn_test_data`.`qlnv_lichsutiendo_bcd57_cap_tp`;
