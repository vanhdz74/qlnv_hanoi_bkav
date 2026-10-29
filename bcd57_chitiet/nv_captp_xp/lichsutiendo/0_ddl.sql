/* =====================================================================
   BCĐ 57 · Lịch sử tiến độ GỘP cấp Thành phố + cấp Xã, phường
   (thay cho qlnv_lichsutiendo_bcd57_cap_tp + qlnv_lichsutiendo_bcd57_xaphuong)
   - cap_nhiem_vu: 'Cấp Thành phố' | 'Cấp Xã, phường' (khớp qlnv_chitiet_captp_xp_bcd57)
   - PK (timeline_id, cap_nhiem_vu): 1 task có thể thuộc cả 2 cấp
   ===================================================================== */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_lichsutiendo_captp_xp_bcd57` (
  `cap_nhiem_vu` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `timeline_id` int(11) NOT NULL,
  `task_id` int(11) DEFAULT NULL,
  `ma_nhiem_vu` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ten_xa_phuong` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nguoi_xu_ly_id` int(11) DEFAULT NULL,
  `nguoi_xu_ly_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nguoi_xu_ly_vai_tro_id` int(11) DEFAULT NULL,
  `nguoi_xu_ly_vai_tro_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nguoi_nhan_id` int(11) DEFAULT NULL,
  `nguoi_nhan_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nguoi_nhan_vai_tro_id` int(11) DEFAULT NULL,
  `nguoi_nhan_vai_tro_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` tinyint(4) DEFAULT NULL,
  `action_type` tinyint(4) DEFAULT NULL,
  `ten_action_type` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `noi_dung` longtext COLLATE utf8mb4_unicode_ci,
  `action_date` datetime DEFAULT NULL,
  `sync_date` datetime DEFAULT NULL,
  PRIMARY KEY (`timeline_id`, `cap_nhiem_vu`),
  KEY `idx_cap` (`cap_nhiem_vu`),
  KEY `idx_task` (`task_id`),
  KEY `idx_action` (`action_type`,`action_date`),
  KEY `idx_xa` (`ten_xa_phuong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
