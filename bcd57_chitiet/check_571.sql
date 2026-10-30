use db_theodoinv_hn;

-- =====================================================================================
-- 571 NHIEM VU NQ57 — QUERY THUAN DB (khong bang phu, khong danh sach cung)
-- DB THAT db_theodoinv_hn. Nhan "NQ57" (nhom "Nhan", GroupId 1) danh dau dung 1 dong NV cho moi STT
-- trong file Phan_loai_da_nhom_571_nhiem_vu.xlsx => chay ra dung 571 dong.
-- Nguoi giao / chu tri lay tu qlnv_task_user (Role 0 = giao, Role 1 = chu tri), nhan tu qlnv_task_topic_map.
-- =====================================================================================
SELECT t.TaskId,
       COALESCE(t.AssignBatchId, t.TaskId)                         AS DauNV_Id,
       CASE WHEN t.AssignBatchId IS NULL THEN 'Giao 1 don vi'
            WHEN t.AssignBatchId = t.TaskId THEN 'Dong goc lo'
            ELSE 'Dong don vi trong lo' END                        AS LoaiDong,
       t.Code                                                      AS MaNV,
       t.Title                                                     AS TieuDe,
       t.DocCode                                                   AS SoKyHieu,
       r.DocCode                                                   AS VanBan,
       LEFT(r.Compendium, 300)                                     AS TrichYeuVanBan,
       t.AssignUser                                                AS UserId_NguoiGiaoChinh,
       ug.eGovUserFullname                                         AS NguoiGiaoChinh,
       -- nguoi giao (Role 0) / chu tri (Role 1) / phoi hop (Role 2) tu qlnv_task_user
       (SELECT GROUP_CONCAT(DISTINCT tu.UserId ORDER BY tu.UserId) FROM qlnv_task_user tu WHERE tu.TaskId = t.TaskId AND tu.Role = 0) AS UserId_NguoiGiao,
       (SELECT GROUP_CONCAT(DISTINCT u.eGovUserFullname SEPARATOR '; ') FROM qlnv_task_user tu
          JOIN qlnv_user u ON u.eGovUserId = tu.UserId WHERE tu.TaskId = t.TaskId AND tu.Role = 0)                        AS NguoiGiao,
       dg.name                                                     AS DonViGiao,
       (SELECT GROUP_CONCAT(DISTINCT tu.UserId ORDER BY tu.UserId) FROM qlnv_task_user tu WHERE tu.TaskId = t.TaskId AND tu.Role = 1) AS UserId_ChuTri,
       (SELECT GROUP_CONCAT(DISTINCT u.eGovUserFullname SEPARATOR '; ') FROM qlnv_task_user tu
          JOIN qlnv_user u ON u.eGovUserId = tu.UserId WHERE tu.TaskId = t.TaskId AND tu.Role = 1)                        AS NguoiChuTri,
       dt.name                                                     AS DonViChuTri,
       (SELECT GROUP_CONCAT(DISTINCT u.eGovUserFullname SEPARATOR '; ') FROM qlnv_task_user tu
          JOIN qlnv_user u ON u.eGovUserId = tu.UserId WHERE tu.TaskId = t.TaskId AND tu.Role = 2)                        AS NguoiPhoiHop,
       CASE t.Status WHEN 0 THEN 'Moi tao' WHEN 1 THEN 'Cho bao cao tien do' WHEN 2 THEN 'Xin gia han' WHEN 3 THEN 'Hoan thanh'
                     WHEN 4 THEN 'Ket thuc' WHEN 5 THEN 'Thu hoi' WHEN 6 THEN 'Du thao' ELSE t.Status END             AS TrangThai,
       CASE t.State WHEN 0 THEN 'Moi tao' WHEN 1 THEN 'Da nhan' WHEN 2 THEN 'Da gui BC tien do' WHEN 3 THEN 'Da gui BC hoan thanh' ELSE t.State END AS TinhTrangTiepNhan,
       t.Progress                                                  AS TienDo,
       t.StartedDate                                               AS NgayBatDau,
       t.ExpireDate                                                AS HanXuLy,
       t.CompletedDate                                             AS NgayHoanThanh,
       t.CreatedDate                                               AS NgayTao,
       t.IsRecurring                                               AS DinhKy,
       (SELECT CONCAT(CASE p.PeriodType WHEN 1 THEN 'Tuan' WHEN 2 THEN 'Thang' WHEN 3 THEN 'Quy' WHEN 4 THEN 'Nam' WHEN 5 THEN 'Ngay' END,
                      ', ngay ', IFNULL(p.DayOfMonth, '-'), ', ', p.ValidFrom, ' -> ', IFNULL(p.ValidTo, '...'))
          FROM qlnv_task_period_configs p WHERE p.TaskId = t.TaskId ORDER BY p.Id LIMIT 1)                                 AS CauHinhBaoCao,
       -- nhan (topic)
       (SELECT GROUP_CONCAT(tp2.TopicName ORDER BY tp2.SortOrder SEPARATOR ', ')
          FROM qlnv_task_topic_map m2 JOIN qlnv_task_topic tp2 ON tp2.TopicId = m2.TopicId
         WHERE m2.TaskId = t.TaskId AND tp2.DeletedDate IS NULL AND tp2.TopicName <> 'NQ57')                               AS NhomNhiemVu,
       (SELECT COUNT(*) FROM qlnv_report rp WHERE rp.TaskId = t.TaskId AND rp.DeletedDate IS NULL)                         AS SoBaoCao,
       (SELECT MAX(rp.CreatedDate) FROM qlnv_report rp WHERE rp.TaskId = t.TaskId AND rp.DeletedDate IS NULL)              AS BaoCaoGanNhat,
       (SELECT COUNT(*) FROM qlnv_task ch WHERE ch.ParentId = t.TaskId AND ch.DeletedDate IS NULL)                        AS SoNVCon
FROM qlnv_task t
JOIN qlnv_task_topic_map m ON m.TaskId = t.TaskId
JOIN qlnv_task_topic tp    ON tp.TopicId = m.TopicId AND tp.GroupId = 1 AND tp.TopicName = 'NQ57' AND tp.DeletedDate IS NULL
LEFT JOIN qlnv_resolution r ON r.ResolutionId = t.ResolutionId
LEFT JOIN (SELECT eGovUserId, MAX(eGovUserFullname) eGovUserFullname FROM qlnv_user GROUP BY eGovUserId) ug ON ug.eGovUserId = t.AssignUser
LEFT JOIN (SELECT departmentextid, MAX(name) name FROM department GROUP BY departmentextid) dg ON dg.departmentextid = t.AssignDepartment
LEFT JOIN (SELECT departmentextid, MAX(name) name FROM department GROUP BY departmentextid) dt ON dt.departmentextid = t.TargetDepartment
WHERE t.DeletedDate IS NULL
  -- AND t.AssignUser = 4521                 -- loc theo nguoi giao
  -- AND EXISTS (SELECT 1 FROM qlnv_task_topic_map mx JOIN qlnv_task_topic tx ON tx.TopicId = mx.TopicId
  --             WHERE mx.TaskId = t.TaskId AND tx.TopicName = 'Nhóm dữ liệu')   -- loc theo nhom
ORDER BY t.AssignUser, t.TaskId;

-- Thong ke theo nguoi giao (tong = 571)
-- SELECT t.AssignUser, MAX(u.eGovUserFullname) AS NguoiGiao, COUNT(*) AS SoNV
-- FROM qlnv_task t
-- JOIN qlnv_task_topic_map m ON m.TaskId = t.TaskId
-- JOIN qlnv_task_topic tp ON tp.TopicId = m.TopicId AND tp.GroupId = 1 AND tp.TopicName = 'NQ57' AND tp.DeletedDate IS NULL
-- LEFT JOIN qlnv_user u ON u.eGovUserId = t.AssignUser
-- WHERE t.DeletedDate IS NULL
-- GROUP BY t.AssignUser ORDER BY SoNV DESC;