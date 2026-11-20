-- Tình hình triển khai thí điểm — KỲ THÁNG, nguồn eForm (datamart_hanoi.nq57_eform_chuyen_de)
-- 1 dòng = 1 xã/phường × 1 tháng. Cột giữ đúng tên chart 1069 đang đọc.
-- NGUYÊN TẮC: chỉ điền cái nguồn có; cột nguồn chưa có thì để NULL (chart hiện "—"), không tự đặt giá trị.
--   * Có số: xã có ≥1 dòng NOI_DUNG_XA hoặc DIEM_NGHEN_XA trong tháng → o_kiem_dem = 'da_nop' (chưa rõ đúng hạn hay muộn).
--     Không có dòng nào → 'chua_nop' (chưa biết hạn nên không xếp còn hạn / quá hạn).
--     XA_QUAN_TAM (có nhiệm vụ quá hạn) là số TDNV tính ra, không phải xã nộp → không tính.
--   * so_bieu_hoan_tat = số phần (NOI_DUNG_XA, DIEM_NGHEN_XA) xã đã có trong tháng.
--   * NULL vì eForm chưa có: han_nop, den_han, ts_nhap_dau, ts_gui_duyet, ts_phat_hanh, trang_thai,
--     so_bieu, so_lan_tra_lai, lech_han_phut.
--   * moc_chup = lần đồng bộ gần nhất của bảng.
SELECT
  dv.don_vi                                                           AS ma_don_vi,
  dv.ten                                                              AS ten_don_vi,
  dv.tt                                                               AS tt_don_vi,
  dv.khoi                                                             AS khoi,
  k.ma_ky                                                             AS ma_ky,
  'Kỳ tháng'                                                          AS loai_ky,
  CONCAT('T', k.ky)                                                   AS nhan_ky,
  CONCAT('Báo cáo tháng ', k.ky)                                      AS ten_ky,
  k.stt                                                               AS stt_ky,
  CAST(NULL AS CHAR)                                                  AS han_nop,
  CAST(NULL AS SIGNED)                                                AS den_han,
  CAST(NULL AS CHAR)                                                  AS ts_nhap_dau,
  CAST(NULL AS CHAR)                                                  AS ts_gui_duyet,
  CAST(NULL AS CHAR)                                                  AS ts_phat_hanh,
  CAST(NULL AS CHAR)                                                  AS trang_thai,
  IF(n.so_phan > 0, 'da_nop', 'chua_nop')                             AS o_kiem_dem,
  CAST(NULL AS SIGNED)                                                AS so_bieu,
  IFNULL(n.so_phan, 0)                                                AS so_bieu_hoan_tat,
  CAST(NULL AS SIGNED)                                                AS so_lan_tra_lai,
  CAST(NULL AS SIGNED)                                                AS lech_han_phut,
  (SELECT DATE_FORMAT(MAX(sync_date), '%Y-%m-%d %H:%i:%s') FROM datamart_hanoi.nq57_eform_chuyen_de) AS moc_chup
FROM (
  -- 126 xã/phường: "Thường trực BCĐ57 phường Xuân Đỉnh" → "Phường Xuân Đỉnh"
  SELECT d.don_vi,
         CONCAT(UPPER(LEFT(d.t, 1)), SUBSTRING(d.t, 2))               AS ten,
         IF(d.t LIKE 'phường%', 'Phường', 'Xã')                       AS khoi,
         IF(d.t LIKE 'phường%', 1, 2)                                 AS tt
  FROM (SELECT DISTINCT don_vi, TRIM(REPLACE(don_vi, 'Thường trực BCĐ57', '')) AS t
        FROM datamart_hanoi.nq57_eform_chuyen_de WHERE don_vi IS NOT NULL) d
) dv
CROSS JOIN (
  -- các tháng có dữ liệu theo xã; stt liên tục 1..n (chart dùng để đếm số kỳ chưa nộp liên tiếp)
  SELECT a.ky, a.ma_ky, a.thu_tu_ky,
         (SELECT COUNT(DISTINCT b.thu_tu_ky) FROM datamart_hanoi.nq57_eform_chuyen_de b
           WHERE b.don_vi IS NOT NULL AND b.thu_tu_ky <= a.thu_tu_ky)  AS stt
  FROM (SELECT DISTINCT ky, ma_ky, thu_tu_ky FROM datamart_hanoi.nq57_eform_chuyen_de WHERE don_vi IS NOT NULL) a
) k
LEFT JOIN (
  SELECT don_vi, ma_ky, COUNT(DISTINCT nhom_du_lieu) AS so_phan
  FROM datamart_hanoi.nq57_eform_chuyen_de
  WHERE nhom_du_lieu IN ('NOI_DUNG_XA', 'DIEM_NGHEN_XA') AND don_vi IS NOT NULL
  GROUP BY don_vi, ma_ky
) n ON n.don_vi = dv.don_vi AND n.ma_ky = k.ma_ky
