/* Kiểm tra quy tắc nguon_giao — chạy trên db_theodoinv_hn_test_data trước khi đưa lên NiFi */

/* K1. Nhánh 1: các giá trị dùng để tách Ban Chỉ đạo / Thành phố */
SELECT
    SUBSTRING_INDEX(t.AssignDepartment, '.', 2) AS id_truc_giao,
    t.AssignOrganization,
    u.eGovUserPositionName,
    LEFT(t.DocCode, 40)                          AS doc_code_mau,
    COUNT(*)                                     AS so_nv
FROM `db_theodoinv_hn_test_data`.`qlnv_task` t
LEFT JOIN `db_theodoinv_hn_test_data`.`qlnv_user` u ON u.eGovUserId = t.AssignUser
WHERE t.DeletedDate IS NULL
  AND t.Status <> 5
  AND EXISTS (
      SELECT 1
      FROM `db_theodoinv_hn_test_data`.`qlnv_task_resolution` tr
      INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_resolution` r ON r.ResolutionId = tr.ResolutionId
      WHERE tr.TaskId = t.TaskId AND r.ResolutionGroupId = 55 AND r.DeletedDate IS NULL
  )
GROUP BY 1, 2, 3, 4
ORDER BY so_nv DESC;

/* K2. Sau khi chạy SQL chính: đối chiếu tổng với số trên tab (642) — Trung ương lấy từ API */
SELECT nguon_giao, COUNT(*) AS so_nv
FROM `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_cap_tp`
GROUP BY nguon_giao WITH ROLLUP;

/* K3. Chéo nguồn giao × trục giao */
SELECT nguon_giao, truc_giao, COUNT(*) AS so_nv
FROM `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_cap_tp`
GROUP BY nguon_giao, truc_giao
ORDER BY nguon_giao, so_nv DESC;
