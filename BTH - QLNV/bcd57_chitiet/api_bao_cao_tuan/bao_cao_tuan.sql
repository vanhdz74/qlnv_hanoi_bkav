/* API báo cáo tuần NQ57 – sinh bởi build.py, KHÔNG sửa tay */
SELECT CAST(JSON_OBJECT(
  'tu_ngay', '${p.tu}', 'den_ngay', '${p.den}', 'id_don_vi', '${p.dv}', 'thoi_diem', '${p.ts}',
  'muc_1_tinh_hinh_nhiem_vu', JSON_SET((SELECT JSON_OBJECT('tong_so', COUNT(*), 'hoan_thanh', COALESCE(SUM(ht), 0),
                           'dang_thuc_hien', COUNT(*) - COALESCE(SUM(ht), 0),
                           'qua_han', COALESCE(SUM(can_xl), 0)) FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n), '$.ds_qua_han', COALESCE((SELECT JSON_ARRAYAGG(ten_nhiem_vu) FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n WHERE n.can_xl), JSON_ARRAY())),
  'phu_luc_01', (SELECT JSON_ARRAYAGG(JSON_OBJECT(
     'stt', stt, 'nguon_giao', nguon_giao,
     'tong_so', tong_so, 'hoan_thanh', hoan_thanh, 'dang_thuc_hien', tong_so - hoan_thanh,
     'da_qua_thoi_han_giao', qua_han_giao, 'can_tiep_tuc_xu_ly', can_xl,
     'sap_den_han', sap_han, 'giao_moi_trong_tuan', giao_moi, 'hoan_thanh_trong_tuan', ht_tuan,
     'bien_dong', CONCAT('Giao mới ', giao_moi, ', hoàn thành ', ht_tuan, ' nhiệm vụ trong tuần')))
   FROM (SELECT d.stt, d.nguon_giao, COUNT(n.nhom) AS tong_so, COALESCE(SUM(n.ht), 0) AS hoan_thanh, COALESCE(SUM(n.can_xl), 0) AS can_xl,
                COALESCE(SUM(n.can_xl OR (n.ht AND n.han IS NOT NULL AND n.ngay_ht > n.han)), 0) AS qua_han_giao,
                COALESCE(SUM(n.sap_han), 0) AS sap_han,
                COALESCE(SUM(n.ngay_giao BETWEEN '${p.tu}' AND '${p.den}'), 0) AS giao_moi,
                COALESCE(SUM(n.ht AND n.ngay_ht BETWEEN '${p.tu}' AND '${p.den}'), 0) AS ht_tuan
           FROM (SELECT 1 AS stt, 'Nhiệm vụ Thành phố giao' AS nguon_giao
                 UNION ALL SELECT 2, 'Nhiệm vụ giao cấp xã') d
           LEFT JOIN (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n ON n.nhom = d.stt
          GROUP BY d.stt, d.nguon_giao
         UNION ALL
         SELECT NULL, 'Tổng số', COUNT(n.nhom) AS tong_so, COALESCE(SUM(n.ht), 0) AS hoan_thanh, COALESCE(SUM(n.can_xl), 0) AS can_xl,
                COALESCE(SUM(n.can_xl OR (n.ht AND n.han IS NOT NULL AND n.ngay_ht > n.han)), 0) AS qua_han_giao,
                COALESCE(SUM(n.sap_han), 0) AS sap_han,
                COALESCE(SUM(n.ngay_giao BETWEEN '${p.tu}' AND '${p.den}'), 0) AS giao_moi,
                COALESCE(SUM(n.ht AND n.ngay_ht BETWEEN '${p.tu}' AND '${p.den}'), 0) AS ht_tuan FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n) t),
  'phu_luc_02', COALESCE((SELECT JSON_ARRAYAGG(JSON_OBJECT('stt', stt, 'task_id', task_id, 'nguon_giao', nguon_giao, 'ten_nhiem_vu', ten_nhiem_vu, 'van_ban_giao', van_ban_giao, 'co_quan_chu_tri', co_quan_chu_tri, 'thoi_han_giao', han, 'ngay_ghi_nhan_hoan_thanh', ngay_ht, 'san_pham_phai_hoan_thanh', NULL, 'tai_lieu_kiem_chung', NULL)) FROM (
     SELECT x.*, (@s2 := @s2 + 1) AS stt FROM (
       SELECT * FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n WHERE n.ht AND n.ngay_ht BETWEEN '${p.tu}' AND '${p.den}' ORDER BY nhom, ngay_ht, task_id LIMIT 100000) x
     CROSS JOIN (SELECT @s2 := 0) i) s2), JSON_ARRAY()),
  'phu_luc_03', COALESCE((SELECT JSON_ARRAYAGG(JSON_OBJECT('stt', stt, 'task_id', task_id, 'nguon_giao', nguon_giao, 'ten_nhiem_vu', ten_nhiem_vu, 'van_ban_giao', van_ban_giao, 'co_quan_chu_tri', co_quan_chu_tri, 'thoi_han_hoan_thanh', han, 'so_ngay_qua_han', DATEDIFF('${p.den}', han), 'ket_qua_thuc_hien', kq, 'nguyen_nhan_vuong_mac', kk)) FROM (
     SELECT x.*, (@s3 := @s3 + 1) AS stt FROM (
       SELECT * FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n WHERE n.can_xl ORDER BY nhom, han, task_id LIMIT 100000) x
     CROSS JOIN (SELECT @s3 := 0) i) s3), JSON_ARRAY()),
  'phu_luc_04', COALESCE((SELECT JSON_ARRAYAGG(JSON_OBJECT('stt', stt, 'task_id', task_id, 'nguon_giao', nguon_giao, 'ten_nhiem_vu', ten_nhiem_vu, 'van_ban_giao', van_ban_giao, 'co_quan_chu_tri', co_quan_chu_tri, 'thoi_han_hoan_thanh', han, 'tien_do', tien_do, 'san_pham_phai_hoan_thanh', NULL, 'muc_nguy_co', CASE WHEN (COALESCE(tien_do, 0) < 50 AND DATEDIFF(han, '${p.den}') <= 7) OR COALESCE(tien_do, 0) < 30 THEN 'Cao' WHEN COALESCE(tien_do, 0) < 80 THEN 'Trung bình' ELSE 'Thấp' END)) FROM (
     SELECT x.*, (@s4 := @s4 + 1) AS stt FROM (
       SELECT * FROM (SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${p.den}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${p.den}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${p.den}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao, ten_don_vi_chu_tri AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao, COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri) AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND ('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))
  ) b) n WHERE n.sap_han ORDER BY nhom, han, task_id LIMIT 100000) x
     CROSS JOIN (SELECT @s4 := 0) i) s4), JSON_ARRAY())
) AS CHAR CHARACTER SET utf8mb4) AS bao_cao
