-- Tình hình triển khai thí điểm — tính từ datamart_hanoi.nq57_bao_cao (chép 1-1 từ PG bao_cao.dashboard.bao_cao)
-- 1 dòng = 1 đơn vị × 1 kỳ; gộp các biểu của đơn vị trong kỳ, bỏ biểu EXEMPTED (không phải nộp).
-- Chế độ: NQ57_NGAY_TN (Kỳ ngày), NQ57_TUAN_TN (Kỳ tuần), NQ57_THANG (Kỳ tháng). Đơn vị: theo bao_cao.
-- Hạn nộp = han_nop_luc của nguồn (có giờ); nguồn trống thì ngày hạn (ưu tiên sau gia hạn) lúc 16:00 (người dùng chốt 19/11/2026).
--   Lấy hạn muộn nhất các biểu.
-- Nạp lùi (nap_lui = 1, nhập bù số cũ): đã phát hành nhưng không xét hạn → o_kiem_dem 'da_nop', lech_han_phut NULL.
-- '${sync_ts}' = giờ NiFi (đồng hồ MySQL lệch) → dùng làm "bây giờ" cho đến hạn và mốc chụp.
-- Đã phát hành = mọi biểu SUBMITTED/ACCEPTED; giờ phát hành = nop_luc muộn nhất.
-- ts_nhap_dau = nhap_dau_luc sớm nhất; ts_gui_duyet = gui_duyet_luc muộn nhất khi mọi biểu đã gửi duyệt;
-- so_lan_tra_lai = tổng so_lan_tra_lai các biểu (nguồn bổ sung 19/11).
SELECT
  g.ma_don_vi                                                         AS ma_don_vi,
  IF(g.xa = 1, CONCAT(UPPER(LEFT(g.t, 1)), SUBSTRING(g.t, 2)), g.ten_raw) AS ten_don_vi,
  IF(g.xa = 1, 2, 1)                                                  AS tt_don_vi,
  IF(g.xa = 1, 'Phường xã', 'Cơ quan Thành phố')                      AS khoi,
  g.ma_ky                                                             AS ma_ky,
  CASE g.lk WHEN 'NGAY' THEN 'Kỳ ngày' WHEN 'TUAN' THEN 'Kỳ tuần' ELSE 'Kỳ tháng' END AS loai_ky,
  CASE g.lk WHEN 'NGAY' THEN DATE_FORMAT(g.tu_ngay, '%d/%m')
            WHEN 'TUAN' THEN CONCAT('Tuần ', SUBSTRING(g.ma_ky, 6, 2))
            ELSE CONCAT('T', DATE_FORMAT(g.tu_ngay, '%m/%Y')) END     AS nhan_ky,
  CONCAT('Báo cáo ', LOWER(LEFT(g.tk, 1)), SUBSTRING(g.tk, 2))        AS ten_ky,
  (SELECT COUNT(DISTINCT b2.ma_ky) FROM datamart_hanoi.nq57_bao_cao b2
    WHERE b2.ma_che_do = g.ma_che_do AND b2.ma_trang_thai <> 'EXEMPTED' AND b2.tu_ngay <= g.tu_ngay) AS stt_ky,
  DATE_FORMAT(g.han, '%Y-%m-%d %H:%i:%s')                             AS han_nop,
  IF('${sync_ts}' >= g.han, 1, 0)                                     AS den_han,
  DATE_FORMAT(g.nhap_dau, '%Y-%m-%d %H:%i:%s')                        AS ts_nhap_dau,
  IF(g.so_gui = g.so_bieu, DATE_FORMAT(g.gui_duyet, '%Y-%m-%d %H:%i:%s'), NULL) AS ts_gui_duyet,
  IF(g.so_nop = g.so_bieu, DATE_FORMAT(g.nop_cuoi, '%Y-%m-%d %H:%i:%s'), NULL) AS ts_phat_hanh,
  CASE WHEN g.so_nop = g.so_bieu THEN 'da_phat_hanh'
       WHEN g.so_tra > 0 THEN 'bi_tra_lai'
       WHEN g.so_cho > 0 THEN 'cho_duyet'
       WHEN g.so_nhap > 0 OR g.so_nop > 0 THEN 'dang_nhap'
       ELSE 'chua_nhap' END                                           AS trang_thai,
  CASE WHEN g.so_nop = g.so_bieu AND g.so_nap_lui > 0 THEN 'da_nop'
       WHEN g.so_nop = g.so_bieu THEN IF(g.nop_cuoi > g.han, 'nop_qua_han', 'nop_dung_han')
       WHEN '${sync_ts}' >= g.han THEN 'chua_nop_qua_han'
       ELSE 'chua_nop_con_han' END                                    AS o_kiem_dem,
  g.so_bieu                                                           AS so_bieu,
  g.so_nop                                                            AS so_bieu_hoan_tat,
  g.so_tra_lai                                                        AS so_lan_tra_lai,
  IF(g.so_nop = g.so_bieu AND g.so_nap_lui = 0, TIMESTAMPDIFF(MINUTE, g.han, g.nop_cuoi), NULL) AS lech_han_phut,
  '${sync_ts}'                                                        AS moc_chup
FROM (
  SELECT b.ma_che_do, b.ma_ky, b.don_vi_id,
         MAX(b.ma_don_vi) AS ma_don_vi, MAX(b.ten_don_vi) AS ten_raw,
         MAX(b.ten_don_vi) LIKE 'Thường trực BCĐ57 _%' AS xa,  -- 'Thường trực BCĐ57' trơn = cấp TP
         TRIM(REPLACE(MAX(b.ten_don_vi), 'Thường trực BCĐ57', '')) AS t,
         MAX(b.loai_ky) AS lk, MAX(b.ten_ky) AS tk, MIN(b.tu_ngay) AS tu_ngay,
         MAX(COALESCE(b.han_nop_luc, TIMESTAMP(COALESCE(b.han_nop_sau_gia_han, b.han_nop), '16:00:00'))) AS han,
         COUNT(*) AS so_bieu,
         SUM(b.ma_trang_thai IN ('SUBMITTED', 'ACCEPTED')) AS so_nop,
         SUM(b.ma_trang_thai = 'RETURNED') AS so_tra,
         SUM(b.ma_trang_thai = 'PENDING_SIGN') AS so_cho,
         SUM(b.ma_trang_thai = 'DRAFT') AS so_nhap,
         MAX(b.nop_luc) AS nop_cuoi,
         MIN(b.nhap_dau_luc) AS nhap_dau,
         MAX(b.gui_duyet_luc) AS gui_duyet, COUNT(b.gui_duyet_luc) AS so_gui,
         IFNULL(SUM(b.so_lan_tra_lai), 0) AS so_tra_lai,
         IFNULL(SUM(b.nap_lui = 1), 0) AS so_nap_lui
  FROM datamart_hanoi.nq57_bao_cao b
  WHERE b.ma_che_do IN ('NQ57_NGAY_TN', 'NQ57_TUAN_TN', 'NQ57_THANG') AND b.ma_trang_thai <> 'EXEMPTED'
  GROUP BY b.ma_che_do, b.ma_ky, b.don_vi_id
) g
