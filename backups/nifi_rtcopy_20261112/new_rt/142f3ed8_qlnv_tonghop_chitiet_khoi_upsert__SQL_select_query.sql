/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi_new_rt (`monthkey`, `date`, `month`, `year`, `nhomvb_ma`, `nhomvb`, `ma_nv_cha`, `Code`, `idnv`, `tennv_viettat`, `Ma`, `TenNhiemVu`, `SanPhamChuYeu`, `ThoiHanHoanThanh`, `NgayHoanThanh`, `TinhTrang`, `TienDoHoanThanh`, `tong_so_don_vi_thuc_hien`, `songayquahan`, `tongtg_canxuly`, `tongtg_daxuly`, `don_vi_cap_01_dvgiao`, `loaicapcha_dvgiao`, `loaicap_dvgiao`, `iddv_dvgiao`, `donvi_dvgiao`, `tenviettat_dvgiao`, `NguoiGiaoNhiemVu`, `don_vi_cap_01_dvthuchien`, `loaicapcha_dvthuchien`, `loaicap_dvthuchien`, `iddv_dvthuchien`, `donvi_dvthuchien`, `tenviettat_dvthuchien`, `NguoiThucHien`, `don_vi_cap_01`, `loaicapcha`, `loaicap`, `iddv`, `donvi`, `tenviettat`, `DonViPhoiHop`, `iddv_dvchutri`, `DonViChuTri`, `VanBanGiaoNhiemVu`, `NgayVanBan`, `LinhVuc`, `Kieu`, `UuTien`, `KetQuaGhiChu`, `NhomPhamViNhiemVu`, `TrangThai`, `TrangThaiVietTat`, `TrangThaiVietTat2`, `TenNhiemVu_Mobile`, `NhomGiaoNhan`, `syncdate`)
SELECT
    t.`monthkey`,
    t.`date`,
    t.`month`,
    t.`year`,
    t.`nhomvb_ma`,
    t.`nhomvb`,
    t.`ma_nv_cha`,
    t.`Code`,
    t.`idnv`,
    t.`tennv_viettat`,
    t.`Ma`,
    t.`TenNhiemVu`,
    t.`SanPhamChuYeu`,
    t.`ThoiHanHoanThanh`,
    t.`NgayHoanThanh`,
    t.`TinhTrang`,
    t.`TienDoHoanThanh`,
    t.`tong_so_don_vi_thuc_hien`,
    t.`songayquahan`,
    t.`tongtg_canxuly`,
    t.`tongtg_daxuly`,
    t.`don_vi_cap_01_dvgiao`,
    t.`loaicapcha_dvgiao`,
    t.`loaicap_dvgiao`,
    t.`iddv_dvgiao`,
    t.`donvi_dvgiao`,
    t.`tenviettat_dvgiao`,
    t.`NguoiGiaoNhiemVu`,
    t.`don_vi_cap_01_dvthuchien`,
    t.`loaicapcha_dvthuchien`,
    t.`loaicap_dvthuchien`,
    t.`iddv_dvthuchien`,
    t.`donvi_dvthuchien`,
    t.`tenviettat_dvthuchien`,
    t.`NguoiThucHien`,
    t.`don_vi_cap_01`,
    t.`loaicapcha`,
    t.`loaicap`,
    t.`iddv`,
    t.`donvi`,
    t.`tenviettat`,
    t.`DonViPhoiHop`,
    t.`iddv_dvchutri`,
    t.`DonViChuTri`,
    t.`VanBanGiaoNhiemVu`,
    t.`NgayVanBan`,
    t.`LinhVuc`,
    t.`Kieu`,
    t.`UuTien`,
    t.`KetQuaGhiChu`,
    t.`NhomPhamViNhiemVu`,
    t.`TrangThai`,
    t.`TrangThaiVietTat`,
    t.`TrangThaiVietTat2`,
    t.`TenNhiemVu_Mobile`,
    t.`NhomGiaoNhan`,
    '${sync_ts}' AS syncdate 
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom_new_rt t

WHERE t.don_vi_cap_01 = 'THÀNH PHỐ HÀ NỘI' 
AND (
    (
				t.NhomGiaoNhan = 'Đã giao'
    )
OR
    (
        t.NhomGiaoNhan = 'Được giao'
				AND ( 
							(	
									t.loaicapcha = 'UBND Thành phố'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối')
							 AND ( 
										t.donvi = 'UBND Thành phố'
										OR t.loaicap IN ('Xã, Phường', 'Sở ngành', 'Nhóm Sở ngành mở rộng')
									 )
							)
						OR
							(	
									t.loaicapcha = 'HĐND Thành phố'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối', 'Nhiệm vụ nội bộ')
							 AND t.donvi = 'HĐND Thành phố'
							)
						OR
							(	
									t.loaicapcha = 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối')
							 AND t.donvi REGEXP 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
							)
						)
		)
		)
ON DUPLICATE KEY UPDATE
    `monthkey` = VALUES(`monthkey`),
    `date` = VALUES(`date`),
    `month` = VALUES(`month`),
    `year` = VALUES(`year`),
    `nhomvb_ma` = VALUES(`nhomvb_ma`),
    `nhomvb` = VALUES(`nhomvb`),
    `ma_nv_cha` = VALUES(`ma_nv_cha`),
    `Code` = VALUES(`Code`),
    `idnv` = VALUES(`idnv`),
    `tennv_viettat` = VALUES(`tennv_viettat`),
    `TenNhiemVu` = VALUES(`TenNhiemVu`),
    `SanPhamChuYeu` = VALUES(`SanPhamChuYeu`),
    `ThoiHanHoanThanh` = VALUES(`ThoiHanHoanThanh`),
    `NgayHoanThanh` = VALUES(`NgayHoanThanh`),
    `TinhTrang` = VALUES(`TinhTrang`),
    `TienDoHoanThanh` = VALUES(`TienDoHoanThanh`),
    `tong_so_don_vi_thuc_hien` = VALUES(`tong_so_don_vi_thuc_hien`),
    `songayquahan` = VALUES(`songayquahan`),
    `tongtg_canxuly` = VALUES(`tongtg_canxuly`),
    `tongtg_daxuly` = VALUES(`tongtg_daxuly`),
    `don_vi_cap_01_dvgiao` = VALUES(`don_vi_cap_01_dvgiao`),
    `loaicapcha_dvgiao` = VALUES(`loaicapcha_dvgiao`),
    `loaicap_dvgiao` = VALUES(`loaicap_dvgiao`),
    `iddv_dvgiao` = VALUES(`iddv_dvgiao`),
    `donvi_dvgiao` = VALUES(`donvi_dvgiao`),
    `tenviettat_dvgiao` = VALUES(`tenviettat_dvgiao`),
    `NguoiGiaoNhiemVu` = VALUES(`NguoiGiaoNhiemVu`),
    `don_vi_cap_01_dvthuchien` = VALUES(`don_vi_cap_01_dvthuchien`),
    `loaicapcha_dvthuchien` = VALUES(`loaicapcha_dvthuchien`),
    `loaicap_dvthuchien` = VALUES(`loaicap_dvthuchien`),
    `iddv_dvthuchien` = VALUES(`iddv_dvthuchien`),
    `donvi_dvthuchien` = VALUES(`donvi_dvthuchien`),
    `tenviettat_dvthuchien` = VALUES(`tenviettat_dvthuchien`),
    `NguoiThucHien` = VALUES(`NguoiThucHien`),
    `don_vi_cap_01` = VALUES(`don_vi_cap_01`),
    `loaicapcha` = VALUES(`loaicapcha`),
    `loaicap` = VALUES(`loaicap`),
    `iddv` = VALUES(`iddv`),
    `donvi` = VALUES(`donvi`),
    `tenviettat` = VALUES(`tenviettat`),
    `DonViPhoiHop` = VALUES(`DonViPhoiHop`),
    `iddv_dvchutri` = VALUES(`iddv_dvchutri`),
    `DonViChuTri` = VALUES(`DonViChuTri`),
    `VanBanGiaoNhiemVu` = VALUES(`VanBanGiaoNhiemVu`),
    `NgayVanBan` = VALUES(`NgayVanBan`),
    `LinhVuc` = VALUES(`LinhVuc`),
    `Kieu` = VALUES(`Kieu`),
    `UuTien` = VALUES(`UuTien`),
    `KetQuaGhiChu` = VALUES(`KetQuaGhiChu`),
    `NhomPhamViNhiemVu` = VALUES(`NhomPhamViNhiemVu`),
    `TrangThai` = VALUES(`TrangThai`),
    `TrangThaiVietTat` = VALUES(`TrangThaiVietTat`),
    `TrangThaiVietTat2` = VALUES(`TrangThaiVietTat2`),
    `TenNhiemVu_Mobile` = VALUES(`TenNhiemVu_Mobile`),
    `syncdate` = VALUES(`syncdate`);
/* Xóa bản ghi không còn trong nguồn ở chu kỳ này */
DELETE FROM datamart_hanoi.qlnv_tonghop_chitiet_khoi_new_rt WHERE syncdate < '${sync_ts}' OR syncdate IS NULL;