TRUNCATE TABLE datamart_hanoi.qlnv_kl_ctpct_chitiet_stage01;

INSERT INTO datamart_hanoi.qlnv_kl_ctpct_chitiet_stage01

SELECT
    t.TaskId AS tt,
    r.DocCode AS so_ky_hieu,
    r.StartDate AS ngay_ban_hanh,
    t.Title AS trich_yeu,

    u.donvi AS phong_tham_muu,
    u.canbo_hoten AS nguoi_soan_thao,
    CAST(NULL AS CHAR(255)) AS nguoi_tao_nhiem_vu,
    CAST(NULL AS CHAR(255)) AS don_vi_nguoi_tao_nhiem_vu,
    CAST(NULL AS CHAR(255)) AS loai_van_ban,

    r.Compendium AS noi_dung_nhiem_vu,
    CAST(NULL AS CHAR(255)) AS linh_vuc,
    tp.TopicName AS chu_de,
    t.isFocus AS nv_quantam,
    rp.nhiem_vu_cho_duyet,

    CAST(NULL AS CHAR(255)) AS don_vi_chu_tri,

    t.ExpireDate AS thoi_han,

    CAST(NULL AS CHAR(255)) AS tinh_trang,
    CAST(NULL AS CHAR(255)) AS ket_qua_thuc_hien,

    t.UpdatedDate AS ngay_cap_nhat,

    u.canbo_hoten AS dau_moi_cap_nhat,

    u.canbo_chuc_danh AS chuc_danh,
    CASE 
        WHEN t.Priority = 3 THEN 'Hỏa tốc'
        WHEN t.Priority = 2 THEN 'Thượng khẩn'
        WHEN t.Priority = 1 THEN 'Khẩn'
        ELSE 'Thường'
    END AS muc_do_uu_tien,

    NOW() AS syncdate

FROM (
    SELECT *
    FROM datamart_hanoi.dm_user
    WHERE loaicapcha = 'UBND Thành phố'
      AND loaicap IS NULL
      AND canbo_chuc_danh LIKE '%Chủ tịch%'
) u
INNER JOIN (
    SELECT * 
    FROM db_theodoinv_hn.qlnv_task 
    WHERE DeletedDate IS NULL 
      AND TargetDepartment NOT IN ('490.698', '490.698.1307', '490.698.1310', '490.698.1841')
) t
    ON u.canbo_id = t.AssignUser
INNER JOIN db_theodoinv_hn.qlnv_resolution r
    ON t.ResolutionId = r.ResolutionId
LEFT JOIN db_theodoinv_hn.qlnv_task_topic tp
    ON t.TopicId = tp.TopicId
LEFT JOIN (
    SELECT DISTINCT TaskId, 'Chờ duyệt' AS nhiem_vu_cho_duyet
    FROM db_theodoinv_hn.qlnv_report
    WHERE Type IN (1, 2, 3, 4)
      AND Status = 0
) rp 
    ON t.TaskId = rp.TaskId;
tham khảo cái này lấy 3 cột theo logic đó thêm vào qlnv_tonghop_chitiet_nvgiao_pth_ubndtp sau linh_vuc: chu_de, muc_do_uu_tiennv_quantam, 