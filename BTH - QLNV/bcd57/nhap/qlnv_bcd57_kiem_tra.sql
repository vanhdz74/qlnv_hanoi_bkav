-- BCĐ 57 — các câu kiểm tra
-- Workbench: chạy `USE db_theodoinv_hn;` trước, hoặc double-click DB ở cột SCHEMAS.
-- Ghi chú và cách đọc kết quả: qlnv_bcd57_note.md (mục 6, 7, 8)


-- ############################################################################
-- E. PHỄU THEO ĐÚNG CHUỖI JOIN CỦA QUERY NẠP
--    Chạy câu này TRƯỚC khi sửa gì. Cột nào tụt về 0 là chỗ query mất dòng.
--    Cách đọc từng trường hợp: note mục 8.
-- ############################################################################

SELECT
  COUNT(*)                                                  AS f1_sau_where_co_ban,
  SUM(trm.TaskId     IS NOT NULL)                           AS f2_co_trong_bang_noi,
  SUM(r.ResolutionId IS NOT NULL)                           AS f3_join_duoc_nghi_quyet,
  SUM(r.PositionName IS NOT NULL AND r.PositionName <> '')  AS f4_co_position_name,
  SUM(r.PositionName IN ('Trưởng Ban Chỉ đạo 57',
                         'Phó Trưởng Ban Thường trực',
                         'Phó Trưởng Ban Chỉ đạo'))         AS f5_khop_3_chuoi
FROM qlnv_task t
LEFT JOIN (
    SELECT tr.TaskId, MIN(tr.ResolutionId) AS ResolutionId
    FROM qlnv_task_resolution tr GROUP BY tr.TaskId
) trm ON trm.TaskId = t.TaskId
LEFT JOIN qlnv_resolution r
       ON r.ResolutionId = trm.ResolutionId
      AND r.DeletedDate IS NULL
WHERE t.DeletedDate IS NULL AND t.Status <> 5;

-- E2. nếu f3 = 0 mà f2 > 0 → thử bỏ điều kiện DeletedDate của nghị quyết
SELECT COUNT(*) AS join_duoc_khi_bo_deletedate
FROM qlnv_task t
JOIN (
    SELECT tr.TaskId, MIN(tr.ResolutionId) AS ResolutionId
    FROM qlnv_task_resolution tr GROUP BY tr.TaskId
) trm ON trm.TaskId = t.TaskId
JOIN qlnv_resolution r ON r.ResolutionId = trm.ResolutionId
WHERE t.DeletedDate IS NULL AND t.Status <> 5;

-- E3. nếu f4 = 0 → PositionName rỗng hết, hệ thống dùng PositionId
SELECT COUNT(*)                                              AS tong_nq,
       SUM(PositionName   IS NULL OR PositionName   = '')     AS rong_position_name,
       SUM(AssignUserName IS NULL OR AssignUserName = '')     AS rong_assign_user_name,
       COUNT(DISTINCT PositionId)                             AS so_position_id
FROM qlnv_resolution WHERE DeletedDate IS NULL;

-- E4. nếu f5 = 0 → xem chuỗi thật (do_dai để phát hiện dấu cách thừa)
SELECT PositionName, LENGTH(PositionName) AS do_dai, COUNT(*) AS so_vb
FROM qlnv_resolution WHERE DeletedDate IS NULL
GROUP BY PositionName, LENGTH(PositionName) ORDER BY so_vb DESC;


-- ############################################################################
-- D. PHỄU — query nạp trả 0 dòng thì chạy câu này TRƯỚC
--    Cột nào tụt về 0 là chỗ mất dòng. Cách đọc: note mục 8.
-- ############################################################################

SELECT
  (SELECT COUNT(*) FROM qlnv_task)                                     AS d1_tong_task,
  (SELECT COUNT(*) FROM qlnv_task
    WHERE DeletedDate IS NULL)                                         AS d2_chua_xoa,
  (SELECT COUNT(*) FROM qlnv_task
    WHERE DeletedDate IS NULL AND Status <> 5)                         AS d3_chua_thu_hoi,
  (SELECT COUNT(*) FROM qlnv_task_resolution)                          AS d4_dong_bang_noi,
  (SELECT COUNT(DISTINCT TaskId) FROM qlnv_task_resolution)            AS d5_task_co_nq,
  (SELECT COUNT(*) FROM qlnv_resolution)                               AS d6_tong_nq,
  (SELECT COUNT(*) FROM qlnv_resolution
    WHERE DeletedDate IS NULL)                                         AS d7_nq_con_song,
  (SELECT COUNT(*) FROM qlnv_resolution
    WHERE DeletedDate IS NULL
      AND PositionName IN ('Trưởng Ban Chỉ đạo 57',
                           'Phó Trưởng Ban Thường trực',
                           'Phó Trưởng Ban Chỉ đạo'))                  AS d8_khop_chuc_vu;

-- D9. nếu d8 = 0 → xem chuỗi thật (có thể lệch dấu cách / hoa thường / dấu)
SELECT PositionName, LENGTH(PositionName) AS do_dai, COUNT(*) AS so_vb
FROM qlnv_resolution
WHERE DeletedDate IS NULL
GROUP BY PositionName, LENGTH(PositionName)
ORDER BY so_vb DESC;

-- D10. nếu d4 = 0 (bảng nối rỗng) → task gắn nghị quyết qua CỘT ResolutionId?
--      chỉ chạy được nếu A1 xác nhận cột đó tồn tại
-- SELECT COUNT(*) AS task_co_cot_resolution FROM qlnv_task
--  WHERE DeletedDate IS NULL AND ResolutionId > 0;

-- D11. bỏ HẾT bộ lọc phạm vi — đếm số dòng query sẽ ra nếu không lọc BCĐ 57
SELECT COUNT(*) AS neu_khong_loc_pham_vi
FROM qlnv_task t
WHERE t.DeletedDate IS NULL AND t.Status <> 5;


-- ############################################################################
-- A. TRƯỚC KHI NẠP — cột nào có thật trong CSDL
-- ############################################################################

-- A1. qlnv_task — 20 cột nghi vấn
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS len
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME   = 'qlnv_task'
  AND COLUMN_NAME IN (
      'DocCode','Compendium','DocumentCode','DocumentCompendium','DocumentOrganization',
      'TargetOrganization','AssignOrganization','ResponsibleUnit',
      'CreateUserDepartment','ChargeUser','FollowUser',
      'Code','NameGroup','Sector','ResolutionId','TaskSourceId','level','IsRecurring',
      'ParentId','StartedDate')
ORDER BY ORDINAL_POSITION;

-- A2. qlnv_resolution — 4 cột xương sống
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH AS len
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME   = 'qlnv_resolution'
  AND COLUMN_NAME IN ('PositionName','AssignUserName','AssignOrganizationName',
                      'ResolutionGroupId','DocCode','StartDate','DeletedDate')
ORDER BY ORDINAL_POSITION;

-- A3. qlnv_report · qlnv_combination · qlnv_task_resolution
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND ( (TABLE_NAME = 'qlnv_report'
         AND COLUMN_NAME IN ('ReportId','TaskId','Type','Status','NewExpiredDate',
                             'Content','DeletedDate'))
     OR (TABLE_NAME = 'qlnv_combination'
         AND COLUMN_NAME IN ('TaskId','TargetDepartment','DeletedDate'))
     OR (TABLE_NAME = 'qlnv_task_resolution'
         AND COLUMN_NAME IN ('TaskId','ResolutionId')) )
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ############################################################################
-- B. TRƯỚC KHI NẠP — chốt phạm vi BCĐ 57
-- ############################################################################

-- B1. chức vụ người ký đang có
SELECT PositionName, COUNT(*) AS so_vb
FROM qlnv_resolution
WHERE DeletedDate IS NULL
GROUP BY PositionName
ORDER BY so_vb DESC;

-- B2. danh mục nghị quyết
SELECT ResolutionGroupId, COUNT(*) AS so_vb
FROM qlnv_resolution
WHERE DeletedDate IS NULL
GROUP BY ResolutionGroupId
ORDER BY so_vb DESC;

-- B3. tên bảng danh mục nhóm
SELECT TABLE_NAME FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'qlnv_%group%';

-- B4. task gắn nghị quyết qua đường nào
SELECT COUNT(DISTINCT TaskId) AS qua_bang_noi FROM qlnv_task_resolution;
-- chỉ chạy nếu A1 cho thấy cột ResolutionId có thật
-- SELECT COUNT(*) AS qua_cot FROM qlnv_task
--  WHERE ResolutionId > 0 AND DeletedDate IS NULL;

-- B5. quy mô dữ liệu
SELECT COUNT(*)                        AS tong_task_con_song,
       SUM(Status = 3)                 AS status_3_hoan_thanh,
       SUM(Status = 4)                 AS status_4_ket_thuc,
       SUM(Status = 5)                 AS status_5_thu_hoi,
       SUM(ExpireDate IS NULL)         AS thieu_han,
       SUM(CompletedDate IS NOT NULL)  AS co_ngay_ket_thuc,
       SUM(ApprovedDate  IS NOT NULL)  AS co_ngay_duyet
FROM qlnv_task
WHERE DeletedDate IS NULL;


-- ############################################################################
-- C. SAU KHI NẠP
-- ############################################################################

-- C0. trả về 0 dòng → khoanh vùng
SELECT COUNT(*) FROM qlnv_task WHERE DeletedDate IS NULL AND Status <> 5;
SELECT COUNT(DISTINCT TaskId) FROM qlnv_task_resolution;

-- C1. nhân dòng — hai số phải bằng nhau
SELECT COUNT(*) AS so_dong, COUNT(DISTINCT ma_nhiem_vu) AS so_nv_phan_biet
FROM qlnv_bcd57_nhiemvu;

-- C2. đối chiếu ảnh dashboard: 1284 / 651 / 91 / 478 / 64
SELECT COUNT(*) AS tong,
       SUM(trang_thai='ht_trong') AS ht_trong, SUM(trang_thai='ht_qua')  AS ht_qua,
       SUM(trang_thai='cht_con')  AS cht_con,  SUM(trang_thai='cht_qua') AS cht_qua,
       SUM(khong_co_han)          AS thieu_han
FROM qlnv_bcd57_nhiemvu;

-- C3. phạm vi lọc — phải ra đúng 3 giá trị filter
SELECT lanh_dao_chi_dao, COUNT(*) FROM qlnv_bcd57_nhiemvu
GROUP BY lanh_dao_chi_dao ORDER BY 2 DESC;

-- C4. NV thiếu hạn (đang dồn vào cht_con)
SELECT COUNT(*) FROM qlnv_bcd57_nhiemvu WHERE khong_co_han = 1;

-- C5. panel đôn đốc — ảnh dashboard: 6 overdue + 3 soon
SELECT muc_do_canh_bao, COUNT(*) FROM qlnv_bcd57_nhiemvu
WHERE can_don_doc = 1 GROUP BY muc_do_canh_bao;

-- C6. gia hạn có tác dụng không (0 = bmm-api đã ghi đè ExpireDate)
SELECT COUNT(*) FROM qlnv_bcd57_nhiemvu WHERE da_gia_han = 1;

-- C7. đóng bằng Status nhưng thiếu mốc ngày hoàn thành
SELECT COUNT(*) FROM qlnv_bcd57_nhiemvu
WHERE la_hoan_thanh = 1 AND ngay_hoan_thanh IS NULL;

-- C8. gia hạn sớm hơn hạn gốc (lùi hạn)
SELECT COUNT(*) FROM qlnv_task t
  JOIN (SELECT TaskId, MAX(NewExpiredDate) AS h FROM qlnv_report
         WHERE Type=3 AND Status=1 AND DeletedDate IS NULL GROUP BY TaskId) g
    ON g.TaskId = t.TaskId
WHERE g.h < t.ExpireDate;

-- C9. ba tổng của KPI / chart đơn vị / chart tháng
SELECT COUNT(*)                    AS tong_kpi,
       SUM(ma_don_vi <> '(KXD)')   AS vao_chart_dv,
       SUM(nam_han = YEAR(NOW()))  AS vao_chart_thang
FROM qlnv_bcd57_nhiemvu;

-- C10. số đơn vị thực tế (ảnh dashboard chỉ có 10)
SELECT COUNT(DISTINCT don_vi_thuc_hien) FROM qlnv_bcd57_nhiemvu;

-- C11. cột nào đang rỗng
SELECT COUNT(*)                          AS tong,
       SUM(don_vi_thuc_hien = '(KXD)')   AS thieu_don_vi,
       SUM(lanh_dao_ubnd    = '(KXD)')   AS thieu_ld_ubnd,
       SUM(nhom_nhiem_vu    = '(KXD)')   AS thieu_nhom,
       SUM(so_van_ban       = '(KXD)')   AS thieu_so_vb,
       SUM(ket_qua_thuc_hien IS NULL)    AS thieu_ket_qua
FROM qlnv_bcd57_nhiemvu;

-- C12. query 2 phải khớp query 1
SELECT (SELECT COUNT(*) FROM qlnv_bcd57_nhiemvu WHERE can_don_doc = 1) AS phan1,
       (SELECT COUNT(*) FROM qlnv_bcd57_dondoc)                        AS phan2;

-- C13. hai processor NiFi có chạy cùng lượt không
SELECT (SELECT MAX(syncdate) FROM qlnv_bcd57_nhiemvu) AS sync_phan1,
       (SELECT MAX(syncdate) FROM qlnv_bcd57_dondoc)  AS sync_phan2;

-- C14. dữ liệu cho popover "Thống kê theo đơn vị chủ trì"
SELECT don_vi_thuc_hien,
       SUM(la_qua_han) AS cht_qua_han,
       SUM(la_gan_han) AS cht_gan_han,
       COUNT(*)        AS tong
FROM qlnv_bcd57_dondoc
GROUP BY don_vi_thuc_hien
ORDER BY cht_qua_han DESC, tong DESC;

-- C15. nguồn cho dropdown "Tất cả văn bản"
SELECT DISTINCT so_van_ban FROM qlnv_bcd57_dondoc ORDER BY so_van_ban;
