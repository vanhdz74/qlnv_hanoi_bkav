-- Lấy các nhiệm vụ có người giao (AssignUser) thuộc danh sách dưới. MySQL 5.7.
-- Bỏ dòng "AND t.DeletedDate IS NULL" nếu muốn xem cả nhiệm vụ đã xoá.
SELECT t.AssignUser,
       u.eGovUserFullname AS ten_nguoi_giao,
       t.*
FROM `db_theodoinv_hn`.`qlnv_task` t
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
       ON u.eGovUserId = t.AssignUser
WHERE t.AssignUser IN (4521, 4509, 4506, 1521, 1527, 1524)
  AND t.DeletedDate IS NULL
ORDER BY t.AssignUser, t.TaskId;

-- Gom các nhiệm vụ cùng Title + cùng AssignUser: mỗi dòng là một nhóm, kèm danh sách TaskId/Code.
-- Bỏ dòng HAVING nếu muốn xem cả nhóm chỉ có 1 nhiệm vụ.
SET SESSION group_concat_max_len = 100000;
SELECT t.AssignUser,
       MAX(u.eGovUserFullname)                          AS ten_nguoi_giao,
       t.Title,
       COUNT(*)                                         AS so_nhiem_vu,
       GROUP_CONCAT(t.TaskId ORDER BY t.TaskId SEPARATOR ', ') AS ds_task_id,
       GROUP_CONCAT(t.Code   ORDER BY t.TaskId SEPARATOR ', ') AS ds_ma_nhiem_vu
FROM `db_theodoinv_hn`.`qlnv_task` t
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
       ON u.eGovUserId = t.AssignUser
WHERE t.AssignUser IN (4521, 4509, 4506, 1521, 1527, 1524)
  AND t.DeletedDate IS NULL
GROUP BY t.AssignUser, t.Title
HAVING COUNT(*) > 1
ORDER BY so_nhiem_vu DESC, t.AssignUser, t.Title;

-- Gom các nhiệm vụ cùng Title + cùng AssignUser, lọc theo đơn vị giao AssignDepartment = '490.695.701.710'.
SET SESSION group_concat_max_len = 100000;
SELECT t.AssignUser,
       MAX(u.eGovUserFullname)                                 AS ten_nguoi_giao,
       t.Title,
       COUNT(*)                                                AS so_nhiem_vu,
       GROUP_CONCAT(t.TaskId ORDER BY t.TaskId SEPARATOR ', ') AS ds_task_id,
       GROUP_CONCAT(t.Code   ORDER BY t.TaskId SEPARATOR ', ') AS ds_ma_nhiem_vu
FROM `db_theodoinv_hn`.`qlnv_task` t
LEFT JOIN `db_theodoinv_hn`.`qlnv_user` u
       ON u.eGovUserId = t.AssignUser
WHERE t.AssignDepartment = '490.695.701.710'
  AND t.DeletedDate IS NULL
GROUP BY t.AssignUser, t.Title
ORDER BY so_nhiem_vu DESC, t.AssignUser, t.Title;
