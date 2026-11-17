-- BCĐ 57 — query 1/2 · CHỈ CÂU SELECT, chạy xem kết quả trước
-- Chạy trực tiếp trong SQL Lab / Workbench. Chưa gắn bảng, chưa truncate.
-- Workbench: cần `USE db_theodoinv_hn;` hoặc double-click DB ở cột SCHEMAS.
--
-- ⚠ ĐANG Ở CHẾ ĐỘ CHẠY THỬ — bộ lọc phạm vi BCĐ 57 đã TẮT (nhánh 4, `AND 1 = 1`).
--   Kết quả gồm TOÀN BỘ nhiệm vụ, chưa lọc BCĐ 57. Chỉ dùng để kiểm đường ống.
--   Bật lại phạm vi: chạy phễu E trong qlnv_bcd57_kiem_tra.sql, xem cột nào = 0,
--   rồi mở đúng một nhánh ở khối "phạm vi BCĐ 57" phía dưới.
--
-- Khi số liệu đã đúng: tạo bảng bằng qlnv_bcd57_ddl.sql rồi đưa câu này vào NiFi.
-- Ghi chú: qlnv_bcd57_note.md   ·   Kiểm tra: qlnv_bcd57_kiem_tra.sql

SELECT
    s.TaskId                                                            AS ma_nhiem_vu,
    CAST(s.TaskId AS CHAR)                                              AS ma_hien_thi,

    COALESCE(NULLIF(s.ten_nhom_vb,''), '(KXD)')                         AS nhom_nhiem_vu,
    CAST(s.TaskId AS CHAR)                                              AS stt_theo_doi,
    COALESCE(
        NULLIF(CONCAT_WS(' ngày ',
               NULLIF(s.so_van_ban,''),
               DATE_FORMAT(s.ngay_van_ban,'%d/%m/%Y')), ''), '(KXD)')   AS van_ban_giao,
    COALESCE(NULLIF(s.Title,''), s.Content)                             AS noi_dung,
    s.don_vi_thuc_hien                                                  AS don_vi_thuc_hien,
    '(KXD)'                                                             AS lanh_dao_dv_cv,
    s.han                                                               AS han_hoan_thanh,
    CASE s.tt WHEN 'ht_trong' THEN 'Hoàn thành trong hạn'
              WHEN 'ht_qua'   THEN 'Hoàn thành quá hạn'
              WHEN 'cht_con'  THEN 'Chưa HT — còn hạn'
              ELSE                 'Chưa HT — quá hạn' END              AS ten_trang_thai,
    s.ket_qua_thuc_hien                                                 AS ket_qua_thuc_hien,
    COALESCE(NULLIF(s.AssignUserName,''), '(KXD)')                      AS lanh_dao_ubnd,
    '(KXD)'                                                             AS lanh_dao_vp,
    '(KXD)'                                                             AS phong_chuyen_mon,
    '(KXD)'                                                             AS chuyen_vien_vp,

    s.lanh_dao_chi_dao                                                  AS lanh_dao_chi_dao,
    s.tt                                                                AS trang_thai,
    s.ma_don_vi                                                         AS ma_don_vi,
    COALESCE(NULLIF(s.so_van_ban,''), '(KXD)')                          AS so_van_ban,
    s.ngay_van_ban                                                      AS ngay_van_ban,
    s.ngay_ht                                                           AS ngay_hoan_thanh,
    YEAR(s.han)                                                         AS nam_han,
    MONTH(s.han)                                                        AS thang_han,
    DATE_FORMAT(s.han,'%Y%m')                                           AS monthkey,
    CASE WHEN s.han IS NULL THEN '(KXD)'
         ELSE CONCAT('T', MONTH(s.han)) END                             AS nhan_thang,
    CASE WHEN s.han IS NULL THEN NULL
         ELSE DATE_FORMAT(s.han,'%Y-%m-01') END                         AS ky_han,

    CASE s.tt WHEN 'ht_trong' THEN 'HT trong hạn'
              WHEN 'ht_qua'   THEN 'HT quá hạn'
              WHEN 'cht_con'  THEN 'Chưa HT còn hạn'
              ELSE                 'Chưa HT quá hạn' END                AS ten_ngan,
    CASE WHEN s.tt IN ('ht_trong','ht_qua') THEN 'HT' ELSE 'CHT' END    AS nhom_ht,
    CASE WHEN s.tt IN ('ht_qua','cht_qua') THEN 'QUA_HAN'
         ELSE 'TRONG_HAN' END                                           AS nhom_han,
    CASE s.tt WHEN 'ht_trong' THEN '#00a870'
              WHEN 'ht_qua'   THEN '#f2a325'
              WHEN 'cht_con'  THEN '#1f6fe0'
              ELSE                 '#e0453f' END                        AS mau_trang_thai,
    CASE s.tt WHEN 'ht_trong' THEN 1 WHEN 'ht_qua' THEN 2
              WHEN 'cht_con'  THEN 3 ELSE 4 END                         AS thu_tu_trang_thai,

    s.da_xong                                                           AS la_hoan_thanh,
    CASE WHEN s.tt IN ('ht_qua','cht_qua') THEN 1 ELSE 0 END            AS la_qua_han,
    CASE WHEN s.han IS NULL THEN 1 ELSE 0 END                           AS khong_co_han,
    s.da_gia_han                                                        AS da_gia_han,
    0                                                                   AS la_dinh_ky,
    NULL                                                                AS cap_nhiem_vu,
    s.so_dv_phoi_hop                                                    AS so_dv_phoi_hop,
    s.Progress                                                          AS tien_do,

    CASE WHEN s.da_xong = 0 AND s.han IS NOT NULL
              AND (s.han < NOW() OR DATEDIFF(s.han, NOW()) <= 7)
         THEN 1 ELSE 0 END                                              AS can_don_doc,
    CASE WHEN s.da_xong = 1 OR s.han IS NULL          THEN NULL
         WHEN s.han < NOW()                           THEN 'overdue'
         WHEN DATEDIFF(s.han, NOW()) <= 7             THEN 'soon' END   AS muc_do_canh_bao,
    CASE WHEN s.da_xong = 1 OR s.han IS NULL THEN NULL
         ELSE DATEDIFF(NOW(), s.han) END                                AS so_ngay,
    CASE WHEN s.da_xong = 1 OR s.han IS NULL          THEN NULL
         WHEN s.han < NOW()
              THEN CONCAT(DATEDIFF(NOW(), s.han), ' NGÀY QUÁ HẠN')
         WHEN DATEDIFF(s.han, NOW()) <= 7
              THEN CONCAT('CÒN ', DATEDIFF(s.han, NOW()), ' NGÀY') END  AS nhan_canh_bao,
    DATE_FORMAT(s.han,'%d/%m/%Y')                                       AS han_hien_thi,

    DATE_FORMAT(NOW(),'%Y-%m-%d %H:%i:%s')                              AS syncdate

FROM (
  SELECT b.*,
        CASE
          WHEN b.da_xong = 1
               AND (b.han IS NULL OR b.ngay_ht IS NULL
                    OR b.ngay_ht <= b.han)                     THEN 'ht_trong'
          WHEN b.da_xong = 1                                   THEN 'ht_qua'
          WHEN b.han IS NULL OR NOW() <= b.han                 THEN 'cht_con'
          ELSE                                                      'cht_qua'
        END                                                           AS tt
  FROM (
    SELECT
        t.TaskId, t.Title, t.Content, t.Progress,

        COALESCE(NULLIF(t.DocCode,''), r.DocCode)                AS so_van_ban,
        COALESCE(r.StartDate, t.CreatedDate)                     AS ngay_van_ban,
        r.AssignUserName,
        CAST(r.ResolutionGroupId AS CHAR)                        AS ten_nhom_vb,
        COALESCE(NULLIF(r.PositionName,''), '(Không xác định)')  AS lanh_dao_chi_dao,

        COALESCE(NULLIF(t.TargetDepartment,''), '(KXD)')         AS ma_don_vi,
        COALESCE(NULLIF(t.TargetDepartment,''), '(KXD)')         AS don_vi_thuc_hien,

        bc.Content                                               AS ket_qua_thuc_hien,
        COALESCE(pk.so_dv, 0)                                    AS so_dv_phoi_hop,

        CASE WHEN gh.han_gia_han IS NULL          THEN t.ExpireDate
             WHEN t.ExpireDate  IS NULL           THEN gh.han_gia_han
             WHEN gh.han_gia_han > t.ExpireDate   THEN gh.han_gia_han
             ELSE t.ExpireDate END                               AS han,
        CASE WHEN gh.han_gia_han IS NOT NULL THEN 1 ELSE 0 END   AS da_gia_han,

        COALESCE(t.ApprovedDate, t.CompletedDate)                AS ngay_ht,
        CASE WHEN t.Status IN (3,4)
                  OR t.ApprovedDate  IS NOT NULL
                  OR t.CompletedDate IS NOT NULL THEN 1 ELSE 0 END AS da_xong

    FROM qlnv_task t

    LEFT JOIN (
        SELECT tr.TaskId, MIN(tr.ResolutionId) AS ResolutionId
        FROM qlnv_task_resolution tr
        GROUP BY tr.TaskId
    ) trm ON trm.TaskId = t.TaskId
    LEFT JOIN qlnv_resolution r
           ON r.ResolutionId = trm.ResolutionId
          AND r.DeletedDate IS NULL

    LEFT JOIN (
        SELECT rp.TaskId, MAX(rp.NewExpiredDate) AS han_gia_han
        FROM qlnv_report rp
        WHERE rp.Type = 3 AND rp.Status = 1
          AND rp.DeletedDate    IS NULL
          AND rp.NewExpiredDate IS NOT NULL
        GROUP BY rp.TaskId
    ) gh ON gh.TaskId = t.TaskId

    LEFT JOIN (
        SELECT rp.TaskId, MAX(rp.ReportId) AS ReportId
        FROM qlnv_report rp
        WHERE rp.Type IN (1,2) AND rp.Status = 1
          AND rp.DeletedDate IS NULL
          AND rp.Content IS NOT NULL AND rp.Content <> ''
        GROUP BY rp.TaskId
    ) bcm ON bcm.TaskId  = t.TaskId
    LEFT JOIN qlnv_report bc
           ON bc.ReportId = bcm.ReportId

    LEFT JOIN (
        SELECT c.TaskId, COUNT(DISTINCT c.TargetDepartment) AS so_dv
        FROM qlnv_combination c
        WHERE c.DeletedDate IS NULL
        GROUP BY c.TaskId
    ) pk ON pk.TaskId = t.TaskId

    WHERE t.DeletedDate IS NULL
      AND t.Status <> 5

      -- phạm vi BCĐ 57 — bật đúng một nhánh (xem note, mục 4)
      -- nhánh 1: chức vụ người ký — TẮT, đang cho 0 dòng, chờ kết quả phễu E
      -- AND r.PositionName IN ('Trưởng Ban Chỉ đạo 57',
      --                        'Phó Trưởng Ban Thường trực',
      --                        'Phó Trưởng Ban Chỉ đạo')
      -- nhánh 2: danh mục nghị quyết
      -- AND r.ResolutionGroupId IN (1,2,3,4,5)
      -- nhánh 3: nhóm nhiệm vụ
      -- AND EXISTS (SELECT 1 FROM qlnv_task_group tg
      --              WHERE tg.TaskId = t.TaskId AND tg.GroupId IN (1,2))
      -- nhánh 4: KHÔNG lọc phạm vi — ĐANG BẬT, chỉ để chạy thử
      AND 1 = 1

      -- chỉ đếm nhiệm vụ gốc
      -- AND COALESCE(t.ParentId, 0) = 0
  ) b
) s
ORDER BY s.han, s.TaskId
;
