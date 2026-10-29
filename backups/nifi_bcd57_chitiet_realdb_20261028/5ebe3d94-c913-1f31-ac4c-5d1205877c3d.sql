INSERT INTO `db_theodoinv_hn_test_data`.`qlnv_lichsutiendo_bcd57_xaphuong` (
    `timeline_id`,
    `task_id`,
    `ma_nhiem_vu`,
    `ten_xa_phuong`,

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
    t.Code                                                  AS ma_nhiem_vu,

    /* TÊN XÃ/PHƯỜNG (xem JOIN d_xa) */
    d_xa.name                                               AS ten_xa_phuong,

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
    NOW()                                                   AS sync_date

FROM `db_theodoinv_hn_test_data`.`qlnv_task` t

INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_timeline` tl
        ON tl.TaskId = t.TaskId

/* XÃ/PHƯỜNG: department có id = đoạn thứ 4 của path 490.698.1310.<id>...
   Ưu tiên xã/phường nhận -> xã/phường giao */
LEFT JOIN `db_theodoinv_hn_test_data`.`department` d_xa
       ON d_xa.id = CASE
            WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(
                 CASE
                     WHEN t.OriginalTargetDepartment LIKE '490.698.1310.%' THEN t.OriginalTargetDepartment
                     ELSE t.AssignDepartment
                 END, '.', 4), '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(
                 CASE
                     WHEN t.OriginalTargetDepartment LIKE '490.698.1310.%' THEN t.OriginalTargetDepartment
                     ELSE t.AssignDepartment
                 END, '.', 4), '.', -1) AS UNSIGNED)
          END
      AND d_xa.IsDelete = 0

/* DANH BẠ USER ĐÃ KHỬ TRÙNG eGovUserId - CHỈ GIỮ 4 CỘT CẦN DÙNG.
   Nhờ vậy 3 LEFT JOIN dưới đây không thể nhân dòng, bỏ được GROUP BY ở ngoài. */
LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_action
       ON u_action.eGovUserId = tl.UserId

LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_create
       ON u_create.eGovUserId = tl.CreateUser

LEFT JOIN (
    SELECT
        eGovUserId,
        MAX(eGovUserFullname)     AS fullname,
        MAX(eGovUserPositionId)   AS position_id,
        MAX(eGovUserPositionName) AS position_name
    FROM `db_theodoinv_hn_test_data`.`qlnv_user`
    GROUP BY eGovUserId
) u_target
       ON u_target.eGovUserId = tl.TargetUserId

/* ĐIỀU KIỆN LẤY TASK: đồng bộ với qlnv_chitiet_bcd57_xaphuong */
WHERE t.DeletedDate IS NULL
  AND t.Status <> 5

  /* Tương đương x.tinh_trang <> 'Chưa xác định' bên chitiet */
  AND (   t.Status IN (-1, 0, 1, 2)
       OR (t.Status IN (3, 4)
           AND (   COALESCE(t.IsRecurring, 0) = 1
                OR t.ExpireDate IS NULL
                OR COALESCE(t.CompletedDate, t.ApprovedDate) IS NOT NULL)))

  /* Task thuộc nghị quyết nhóm 55 (qua qlnv_task_resolution), EXISTS để không nhân dòng */
  AND EXISTS (
      SELECT 1
      FROM `db_theodoinv_hn_test_data`.`qlnv_task_resolution` tr
      INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_resolution` r
              ON r.ResolutionId = tr.ResolutionId
      WHERE tr.TaskId = t.TaskId
        AND r.ResolutionGroupId = 55
        AND r.DeletedDate IS NULL
  )

  /* Có liên quan đến xã/phường: xã/phường giao hoặc nhận (không tính người tham gia) */
  AND (
         t.OriginalTargetDepartment LIKE '490.698.1310.%'
      OR t.AssignDepartment LIKE '490.698.1310.%'
  )
;
