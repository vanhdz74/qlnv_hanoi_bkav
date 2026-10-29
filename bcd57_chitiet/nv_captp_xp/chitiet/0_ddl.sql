/* =====================================================================
   BCĐ 57 · Bảng chi tiết GỘP nhiệm vụ cấp Thành phố + cấp Xã, phường
   (thay cho qlnv_chitiet_bcd57_cap_tp + qlnv_chitiet_bcd57_xaphuong)
   - cap_nhiem_vu: 'Cấp Thành phố' | 'Cấp Xã, phường'
   - PK (task_id, cap_nhiem_vu): 1 task có thể thuộc cả 2 cấp
     (vd xã/phường giao nhưng đơn vị nhận không phải xã/phường)
   - UPSERT theo PK, bản ghi không còn thỏa điều kiện bị xóa ở bước sau (sync_date < sync_ts)
   ===================================================================== */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57` (
  `cap_nhiem_vu` varchar(50) NOT NULL,
  `task_id` bigint(20) NOT NULL,
  `status` int(11) DEFAULT NULL,
  `id_truc_giao` varchar(100) DEFAULT NULL,
  `truc_giao` varchar(500) DEFAULT NULL,
  `nguon_giao` varchar(50) DEFAULT NULL,
  `van_ban_giao` varchar(500) DEFAULT NULL,
  `loai_van_ban` varchar(100) DEFAULT NULL,
  `ma_nhiem_vu` varchar(255) DEFAULT NULL,
  `ten_xa_phuong` varchar(255) DEFAULT NULL,
  `ten_nhiem_vu` text,
  `chu_de` varchar(500) DEFAULT NULL,
  `nhom_nhiem_vu` varchar(500) DEFAULT NULL,
  `id_don_vi_giao` varchar(100) DEFAULT NULL,
  `don_vi_giao` varchar(500) DEFAULT NULL,
  `id_nguoi_giao` varchar(100) DEFAULT NULL,
  `nguoi_giao` varchar(255) DEFAULT NULL,
  `id_don_vi_chu_tri` varchar(100) DEFAULT NULL,
  `ten_don_vi_chu_tri` varchar(500) DEFAULT NULL,
  `ten_don_vi_thuc_hien` varchar(500) DEFAULT NULL,
  `id_nguoi_thuc_hien` varchar(100) DEFAULT NULL,
  `nguoi_thuc_hien` varchar(255) DEFAULT NULL,
  `lanh_dao_ban_phu_trach` varchar(500) DEFAULT NULL,
  `ngay_giao` varchar(10) DEFAULT NULL,
  `han_xu_ly` varchar(10) DEFAULT NULL,
  `ngay_hoan_thanh` varchar(10) DEFAULT NULL,
  `ngay_chap_nhan` varchar(10) DEFAULT NULL,
  `ngay_xoa` varchar(10) DEFAULT NULL,
  `tinh_trang` varchar(50) DEFAULT NULL,
  `tien_do` int(11) DEFAULT NULL,
  `ket_qua_thuc_hien` longtext,
  `kho_khan_vuong_mac` longtext,
  `de_xuat_kien_nghi` longtext,
  `id_cha` varchar(50) DEFAULT NULL,
  `sync_date` datetime DEFAULT NULL,
  PRIMARY KEY (`task_id`, `cap_nhiem_vu`),
  KEY `idx_cap` (`cap_nhiem_vu`),
  KEY `idx_nguon_giao` (`nguon_giao`),
  KEY `idx_truc_giao` (`id_truc_giao`),
  KEY `idx_tinh_trang` (`tinh_trang`),
  KEY `idx_xa` (`ten_xa_phuong`),
  KEY `idx_id_cha` (`id_cha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
