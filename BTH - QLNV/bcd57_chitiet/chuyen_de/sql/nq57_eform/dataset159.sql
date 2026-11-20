/* Dataset 159 (dashboard 279 "NQ57 – Chuyên đề chi tiết (test)") đọc số eForm. 18/11/2026
   Nguồn: datamart_hanoi.nq57_eform_chuyen_de / nq57_eform_cach_tinh (NiFi chép 1-1 từ PG bao_cao.dashboard, 5').
   Chuẩn hóa về khuôn bảng cũ mà chart.tpl.js đọc:
     ky 'T10/2026', thu_tu_ky = tháng - 1, phan_to '' với CHI_SO, gia_tri tỷ lệ 0..1 (eForm % đã nhân 100 -> chia 100),
     chuyen_de '5. TTHC và dịch vụ công'. Ngưỡng, đầu mối, loại, tên ngắn: eForm để trống -> lấy danh mục nq57_chi_so_anh_xa.
   Phần eForm không có: chuyên đề 1 (NV01–16), NGUON_GIAO, QUA_HAN -> giữ từ bảng nhập tay chuyen_de_chi_tiet_nq57.
   MySQL 5.7: không CTE, không window function. */
SELECT x.* FROM (
-- A. chỉ số chuyên đề 2–9 từ eForm
SELECT 'CHI_SO' AS nhom_du_lieu, e.ma_chi_so,
       CONCAT('T', CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED), '/', LEFT(e.ma_ky, 4)) AS ky, '' AS phan_to,
       CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED) - 1 AS thu_tu_ky,
       COALESCE(a.thu_tu_chi_so, e.thu_tu_chi_so) AS thu_tu_chi_so, e.stt_chuyen_de,
       CONCAT(e.stt_chuyen_de, '. ', e.chuyen_de) AS chuyen_de, e.ten_chi_so,
       COALESCE(NULLIF(a.ten_ngan, ''), e.ten_ngan) AS ten_ngan, e.don_vi_tinh,
       COALESCE(a.loai_chi_so, e.loai_chi_so) AS loai_chi_so,
       COALESCE(e.giam_la_tot, a.giam_la_tot, 0) AS giam_la_tot,
       COALESCE(e.nguong, a.nguong) AS nguong, COALESCE(e.ten_nguong, a.ten_nguong) AS ten_nguong,
       e.tu_so, e.mau_so, IF(e.don_vi_tinh = '%', e.gia_tri / 100, e.gia_tri) AS gia_tri, e.co_so_lieu,
       e.nguon_so_lieu, NULL AS vi_tri, NULL AS trich_dan,
       COALESCE(e.dau_moi, a.dau_moi) AS dau_moi, a.luu_y,
       COALESCE(e.ghi_chu, c.ghi_chu) AS ghi_chu, e.thong_tin_them, e.sync_date
FROM datamart_hanoi.nq57_eform_chuyen_de e
LEFT JOIN datamart_hanoi.nq57_chi_so_anh_xa a ON a.ma_chi_so = e.ma_chi_so
LEFT JOIN datamart_hanoi.nq57_eform_cach_tinh c ON c.ma_chi_so = e.ma_chi_so
WHERE e.nhom_du_lieu = 'CHI_SO'

UNION ALL
-- B. chỉ số dashboard (chuyên đề 2–9) mà eForm chưa có: 1 dòng không số để dashboard hiện "!"
SELECT 'CHI_SO', a.ma_chi_so, k.ky, '', k.tt, a.thu_tu_chi_so, a.stt_chuyen_de, a.chuyen_de, a.ten_chi_so, a.ten_ngan,
       a.don_vi_tinh, a.loai_chi_so, a.giam_la_tot, a.nguong, a.ten_nguong, NULL, NULL, NULL, 0,
       'eForm NQ57', NULL, NULL, a.dau_moi, a.luu_y, 'eForm chưa có chỉ số này', NULL, k.sync_date
FROM datamart_hanoi.nq57_chi_so_anh_xa a
JOIN (SELECT CONCAT('T', CAST(SUBSTRING(MAX(ma_ky), 6) AS UNSIGNED), '/', LEFT(MAX(ma_ky), 4)) ky,
             CAST(SUBSTRING(MAX(ma_ky), 6) AS UNSIGNED) - 1 tt, MAX(sync_date) sync_date
      FROM datamart_hanoi.nq57_eform_chuyen_de WHERE nhom_du_lieu = 'CHI_SO') k
WHERE a.stt_chuyen_de <> 1
  AND NOT EXISTS (SELECT 1 FROM datamart_hanoi.nq57_eform_cach_tinh c WHERE c.ma_chi_so = a.ma_chi_so)

UNION ALL
-- C. chuyên đề Nhiệm vụ, nguồn giao, quá hạn: chưa có trong eForm -> bảng nhập tay
SELECT o.nhom_du_lieu, o.ma_chi_so, o.ky, o.phan_to, o.thu_tu_ky, o.thu_tu_chi_so, o.stt_chuyen_de, o.chuyen_de, o.ten_chi_so,
       o.ten_ngan, o.don_vi_tinh, o.loai_chi_so, o.giam_la_tot, o.nguong, o.ten_nguong, o.tu_so, o.mau_so, o.gia_tri,
       o.co_so_lieu, o.nguon_so_lieu, o.vi_tri, o.trich_dan, o.dau_moi, o.luu_y, o.ghi_chu, o.thong_tin_them, o.sync_date
FROM datamart_hanoi.chuyen_de_chi_tiet_nq57 o
WHERE (o.nhom_du_lieu = 'CHI_SO' AND o.stt_chuyen_de = 1) OR o.nhom_du_lieu IN ('NGUON_GIAO', 'QUA_HAN')

UNION ALL
-- D. NOI_DUNG_XA: eForm mỗi xã x nhóm một dòng -> đếm xã theo nhóm, kỳ
SELECT 'NOI_DUNG_XA', 'so_xa', CONCAT('T', CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED), '/', LEFT(e.ma_ky, 4)), e.ten_chi_so,
       CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED) - 1, MIN(e.thu_tu_chi_so), 7, '7. Xã, phường và hạ tầng cơ sở',
       'Số xã có kết quả', 'Số xã có kết quả', 'xã, phường', NULL, 0, NULL, NULL,
       COUNT(DISTINCT e.phan_to), 126, COUNT(DISTINCT e.phan_to), 1, 'eForm NQ57', NULL, NULL, NULL, NULL, NULL, NULL, MAX(e.sync_date)
FROM datamart_hanoi.nq57_eform_chuyen_de e
WHERE e.nhom_du_lieu = 'NOI_DUNG_XA'
GROUP BY e.ma_ky, e.ten_chi_so

UNION ALL
-- E. DIEM_NGHEN_XA: kỳ mới nhất có >= 10 xã phản ánh (T9 eForm mới có 1 xã), nhóm theo phần trước dấu ':' của điểm nghẽn, đếm xã phản ánh
SELECT 'DIEM_NGHEN_XA', 'so_xa_phan_anh', CONCAT('T', CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED), '/', LEFT(e.ma_ky, 4)),
       LEFT(TRIM(SUBSTRING_INDEX(e.ten_chi_so, ':', 1)), 255), CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED) - 1,
       1000 - COUNT(DISTINCT e.phan_to), 7, '7. Xã, phường và hạ tầng cơ sở', 'Số xã phản ánh', 'Số xã phản ánh', 'xã, phường',
       NULL, 0, NULL, NULL, COUNT(DISTINCT e.phan_to), 126, COUNT(DISTINCT e.phan_to), 1, 'eForm NQ57', NULL, NULL, NULL, NULL,
       NULL, NULL, MAX(e.sync_date)
FROM datamart_hanoi.nq57_eform_chuyen_de e
JOIN (SELECT MAX(t.ma_ky) ma_ky FROM (SELECT ma_ky FROM datamart_hanoi.nq57_eform_chuyen_de WHERE nhom_du_lieu = 'DIEM_NGHEN_XA'
      GROUP BY ma_ky HAVING COUNT(DISTINCT phan_to) >= 10) t) m ON m.ma_ky = e.ma_ky
WHERE e.nhom_du_lieu = 'DIEM_NGHEN_XA'
GROUP BY e.ma_ky, LEFT(TRIM(SUBSTRING_INDEX(e.ten_chi_so, ':', 1)), 255)

UNION ALL
-- F. XA_QUAN_TAM: eForm CS13 'Có nhiệm vụ quá hạn' (gia_tri = số nhiệm vụ) -> dang_qua_han theo xã
SELECT 'XA_QUAN_TAM', 'dang_qua_han', CONCAT('T', CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED), '/', LEFT(e.ma_ky, 4)),
       TRIM(REPLACE(REPLACE(REPLACE(REPLACE(e.phan_to, 'Thường trực BCĐ57 ', ''), 'UBND ', ''), 'phường ', ''), 'xã ', '')),
       CAST(SUBSTRING(e.ma_ky, 6) AS UNSIGNED) - 1, 1000 - e.gia_tri, 7, '7. Xã, phường và hạ tầng cơ sở', 'Đang quá hạn',
       'Đang quá hạn', 'nhiệm vụ', NULL, 1, NULL, NULL, e.gia_tri, NULL, e.gia_tri, 1, 'eForm NQ57', NULL, NULL, NULL, NULL,
       e.ghi_chu, e.thong_tin_them, e.sync_date
FROM datamart_hanoi.nq57_eform_chuyen_de e
WHERE e.nhom_du_lieu = 'XA_QUAN_TAM' AND e.ma_chi_so = 'CS13'
) x
