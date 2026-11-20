-- Tình hình triển khai thí điểm — đọc bảng datamart do NiFi đổ (group "Chuyên đề lớn", cron 30 2/5, upsert + xóa theo sync_date)
-- Cách tính: ../nifi/tinh_tu_bao_cao.sql. Cột nguồn chưa có = NULL → chart hiện "!".
-- 20/11/2026 (tạm): bỏ Kỳ tháng; đơn vị CỐ ĐỊNH 17 đơn vị theo dashboard mẫu v03 (tên, thứ tự, khối theo mẫu),
--   số liệu ghép theo TÊN đơn vị nguồn (ten_nguon). Khi đủ danh mục sẽ sửa lại (bản cũ: dataset_bang_truoc_2011.sql).
--   VP Ủy ban MTTQ Thành phố ↔ 'Văn phòng Cơ quan' (mã 2010) là ghép TẠM, chưa xác minh.
-- 20/11/2026 (giao diện v12): thêm ts_tiep_nhan = giờ tiếp nhận muộn nhất khi MỌI biểu của đơn vị trong kỳ đã ACCEPTED
--   (gộp trực tiếp từ nq57_bao_cao, không qua NiFi). Bản trước: dataset_bang_truoc_v12.sql.
SELECT d.ma AS ma_don_vi, d.ten AS ten_don_vi, d.tt AS tt_don_vi, d.khoi,
       t.ma_ky, t.loai_ky, t.nhan_ky, t.ten_ky, t.stt_ky, t.han_nop, t.den_han,
       t.ts_nhap_dau, t.ts_gui_duyet, t.ts_phat_hanh,
       IF(b.so_tn = b.so_bieu, DATE_FORMAT(b.tn_cuoi, '%Y-%m-%d %H:%i:%s'), NULL) AS ts_tiep_nhan, t.trang_thai, t.o_kiem_dem, t.so_bieu, t.so_bieu_hoan_tat,
       t.so_lan_tra_lai, t.lech_han_phut, t.moc_chup, t.thieu_du_lieu
FROM (
            SELECT 'VPTU' AS ma, 'Văn phòng Thành ủy' AS ten, 1 AS tt, 'Cơ quan Thành phố' AS khoi, 'Văn phòng Thành ủy' AS ten_nguon
  UNION ALL SELECT 'VPMTTQ', 'VP Ủy ban MTTQ Thành phố', 2, 'Cơ quan Thành phố', 'Văn phòng Cơ quan'
  UNION ALL SELECT 'VPDBQH', 'VP Đoàn ĐBQH và HĐND TP', 3, 'Cơ quan Thành phố', 'Văn phòng Đoàn ĐBQH - HĐND Thành phố'
  UNION ALL SELECT 'VPUBND', 'Văn phòng UBND Thành phố', 4, 'Cơ quan Thành phố', 'Văn phòng UBND TP'
  UNION ALL SELECT 'SKHCN', 'Sở Khoa học và Công nghệ', 5, 'Cơ quan Thành phố', 'Sở Khoa học và Công nghệ'
  UNION ALL SELECT 'STC', 'Sở Tài chính', 6, 'Cơ quan Thành phố', 'Sở Tài chính'
  UNION ALL SELECT 'TTPVHCC', 'TT Phục vụ hành chính công', 7, 'Cơ quan Thành phố', 'Trung tâm Phục vụ hành chính công thành phố Hà Nội'
  UNION ALL SELECT 'P_HOANKIEM', 'Phường Hoàn Kiếm', 8, 'Phường xã', 'Phường Hoàn Kiếm'
  UNION ALL SELECT 'P_CUANAM', 'Phường Cửa Nam', 9, 'Phường xã', 'Phường Cửa Nam'
  UNION ALL SELECT 'P_HONGHA', 'Phường Hồng Hà', 10, 'Phường xã', 'Phường Hồng Hà'
  UNION ALL SELECT 'P_HAIBATRUNG', 'Phường Hai Bà Trưng', 11, 'Phường xã', 'Phường Hai Bà Trưng'
  UNION ALL SELECT 'P_BACHMAI', 'Phường Bạch Mai', 12, 'Phường xã', 'Phường Bạch Mai'
  UNION ALL SELECT 'P_KIMLIEN', 'Phường Kim Liên', 13, 'Phường xã', 'Phường Kim Liên'
  UNION ALL SELECT 'P_DONGDA', 'Phường Đống Đa', 14, 'Phường xã', 'Phường Đống Đa'
  UNION ALL SELECT 'P_OCHODUA', 'Phường Ô Chợ Dừa', 15, 'Phường xã', 'Phường Ô Chợ Dừa'
  UNION ALL SELECT 'P_VINHTUY', 'Phường Vĩnh Tuy', 16, 'Phường xã', 'Phường Vĩnh Tuy'
  UNION ALL SELECT 'P_BADINH', 'Phường Ba Đình', 17, 'Phường xã', 'Phường Ba Đình'
) d
JOIN datamart_hanoi.bcd57_thidiem_trienkhai_thang t
  ON t.ten_don_vi = d.ten_nguon AND t.loai_ky <> 'Kỳ tháng'
LEFT JOIN (
  SELECT ma_ky, ma_don_vi, COUNT(*) AS so_bieu, SUM(ma_trang_thai = 'ACCEPTED') AS so_tn, MAX(tiep_nhan_luc) AS tn_cuoi
  FROM datamart_hanoi.nq57_bao_cao
  WHERE ma_che_do IN ('NQ57_NGAY_TN', 'NQ57_TUAN_TN') AND ma_trang_thai <> 'EXEMPTED'
  GROUP BY ma_ky, ma_don_vi
) b ON b.ma_ky = t.ma_ky AND b.ma_don_vi = t.ma_don_vi
