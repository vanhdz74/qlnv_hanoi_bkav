INSERT INTO `datamart_hanoi`.`bcd57_thidiem_trienkhai_thang` (khoa, ma_don_vi, ten_don_vi, tt_don_vi, khoi, ma_ky, loai_ky, nhan_ky, ten_ky, stt_ky, han_nop, den_han, ts_nhap_dau, ts_gui_duyet, ts_phat_hanh, trang_thai, o_kiem_dem, so_bieu, so_bieu_hoan_tat, so_lan_tra_lai, lech_han_phut, moc_chup, thieu_du_lieu, sync_date)
SELECT MD5(CONCAT(x.ma_don_vi, '|', x.ma_ky)) AS khoa,
  x.ma_don_vi,
  x.ten_don_vi,
  x.tt_don_vi,
  x.khoi,
  x.ma_ky,
  x.loai_ky,
  x.nhan_ky,
  x.ten_ky,
  x.stt_ky,
  x.han_nop,
  x.den_han,
  x.ts_nhap_dau,
  x.ts_gui_duyet,
  x.ts_phat_hanh,
  x.trang_thai,
  x.o_kiem_dem,
  x.so_bieu,
  x.so_bieu_hoan_tat,
  x.so_lan_tra_lai,
  x.lech_han_phut,
  x.moc_chup,
  NULLIF(CONCAT_WS(',', IF(x.han_nop IS NULL, 'han_nop', NULL), IF(x.trang_thai IS NULL, 'trang_thai', NULL), IF(x.so_bieu IS NULL, 'so_bieu', NULL), IF(x.so_lan_tra_lai IS NULL, 'so_lan_tra_lai', NULL)), '') AS thieu_du_lieu,
  '${sync_ts}' AS sync_date
FROM (
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
         MAX(b.ten_don_vi) LIKE 'Thường trực BCĐ57 _%' AS xa,
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
) x
ON DUPLICATE KEY UPDATE
  ma_don_vi = VALUES(ma_don_vi),
  ten_don_vi = VALUES(ten_don_vi),
  tt_don_vi = VALUES(tt_don_vi),
  khoi = VALUES(khoi),
  ma_ky = VALUES(ma_ky),
  loai_ky = VALUES(loai_ky),
  nhan_ky = VALUES(nhan_ky),
  ten_ky = VALUES(ten_ky),
  stt_ky = VALUES(stt_ky),
  han_nop = VALUES(han_nop),
  den_han = VALUES(den_han),
  ts_nhap_dau = VALUES(ts_nhap_dau),
  ts_gui_duyet = VALUES(ts_gui_duyet),
  ts_phat_hanh = VALUES(ts_phat_hanh),
  trang_thai = VALUES(trang_thai),
  o_kiem_dem = VALUES(o_kiem_dem),
  so_bieu = VALUES(so_bieu),
  so_bieu_hoan_tat = VALUES(so_bieu_hoan_tat),
  so_lan_tra_lai = VALUES(so_lan_tra_lai),
  lech_han_phut = VALUES(lech_han_phut),
  moc_chup = VALUES(moc_chup),
  thieu_du_lieu = VALUES(thieu_du_lieu),
  sync_date = VALUES(sync_date);
DELETE FROM `datamart_hanoi`.`bcd57_thidiem_trienkhai_thang`
WHERE sync_date < '${sync_ts}'
  AND (SELECT z.n FROM (SELECT COUNT(*) AS n FROM `datamart_hanoi`.`bcd57_thidiem_trienkhai_thang` WHERE sync_date = '${sync_ts}') z) > 0
