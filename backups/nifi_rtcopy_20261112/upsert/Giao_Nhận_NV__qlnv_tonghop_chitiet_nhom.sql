/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_nhom (
    monthkey,
		`date`,
    `month`,
		`year`,
    nhomvb_ma,
    nhomvb,
    ma_nv_cha,
		`Code`,
		idnv,
		tennv_viettat,
    Ma,
    TenNhiemVu,
    SanPhamChuYeu,
    ThoiHanHoanThanh,
    NgayHoanThanh,
    TinhTrang,
    TienDoHoanThanh,
		tong_so_don_vi_thuc_hien,
    songayquahan,
		tongtg_canxuly,
		tongtg_daxuly,

    don_vi_cap_01_dvgiao,
		loaicapcha_dvgiao,
    loaicap_dvgiao,
    iddv_dvgiao,
    donvi_dvgiao,
    tenviettat_dvgiao,
    NguoiGiaoNhiemVu,

    don_vi_cap_01_dvthuchien,
		loaicapcha_dvthuchien,
    loaicap_dvthuchien,
    iddv_dvthuchien,
    donvi_dvthuchien,
    tenviettat_dvthuchien,
    NguoiThucHien,

    don_vi_cap_01,
		loaicapcha,
    loaicap,
    iddv,
    donvi,
    tenviettat,

    DonViPhoiHop,
		iddv_dvchutri,
		DonViChuTri,
    VanBanGiaoNhiemVu,
		NgayVanBan,
    LinhVuc,
    Kieu,
		UuTien,
    KetQuaGhiChu,
		NhomPhamViNhiemVu,
    TrangThai,
    TrangThaiVietTat,
    TrangThaiVietTat2,
    TenNhiemVu_Mobile,
    NhomGiaoNhan,
    syncdate
)

-- ================== PHẦN 1: ĐÃ GIAO ==================
SELECT
    t.monthkey,
		t.`date`,
    t.`month`,
		t.`year`,
    t.nhomvb_ma,
    t.nhomvb,
    t.ma_nv_cha,
		t.`Code`,
		t.idnv,
		t.tennv_viettat,
    t.Ma,
    t.TenNhiemVu,
    t.SanPhamChuYeu,
    t.ThoiHanHoanThanh,
    t.NgayHoanThanh,
    t.TinhTrang,
    t.TienDoHoanThanh,
		t.tong_so_don_vi_thuc_hien AS tong_so_don_vi_thuc_hien,
    t.songayquahan,
		t.tongtg_canxuly,
		t.tongtg_daxuly,
    -- đơn vị giao = đơn vị hiện tại
    t.don_vi_cap_01     AS don_vi_cap_01_dvgiao,
    t.loaicapcha        AS loaicapcha_dvgiao,
    t.loaicap           AS loaicap_dvgiao,
    t.iddv              AS iddv_dvgiao,
    t.donvi             AS donvi_dvgiao,
    t.tenviettat        AS tenviettat_dvgiao,
    t.NguoiGiaoNhiemVu,

    -- đơn vị thực hiện chưa có
    NULL AS don_vi_cap_01_dvthuchien,
    NULL AS loaicapcha_dvthuchien,
    NULL AS loaicap_dvthuchien,
    NULL AS iddv_dvthuchien,
    t.donvi_dvthuchien,
    NULL AS tenviettat_dvthuchien,
    NULL AS NguoiThucHien,

    t.don_vi_cap_01,
		t.loaicapcha,
    CASE
        WHEN t.iddv IS NULL
            THEN 'Chưa xác định'
        WHEN d1.Level = 3 THEN d1.DepartmentName
        WHEN d2.Level = 3 THEN d2.DepartmentName
        WHEN d3.Level = 3 THEN d3.DepartmentName
        WHEN d4.Level = 3 THEN d4.DepartmentName
        ELSE NULL
    END AS loaicap,
    t.iddv,
    t.donvi,
    t.tenviettat,

    t.DonViPhoiHop,
		t.iddv_dvchutri,
		t.DonViChuTri,
    t.VanBanGiaoNhiemVu,
		t.NgayVanBan,
    t.LinhVuc,
    t.Kieu,
		t.UuTien,
    t.KetQuaGhiChu,
		t.NhomPhamViNhiemVu,
    t.TrangThai,
    REPLACE(t.TrangThaiVietTat,'Chưa HT ','CHT '),
    t.TrangThaiVietTat2,
    t.TenNhiemVu_Mobile,
    'Đã giao' AS NhomGiaoNhan,
    '${sync_ts}'     AS syncdate
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv t
LEFT JOIN datamart_hanoi.department d1
    ON t.iddv = d1.DepartmentId

/* Cha */
LEFT JOIN datamart_hanoi.department d2
    ON d2.DepartmentId = d1.ParentId

/* Ông */
LEFT JOIN datamart_hanoi.department d3
    ON d3.DepartmentId = d2.ParentId

/* Cụ */
LEFT JOIN datamart_hanoi.department d4
    ON d4.DepartmentId = d3.ParentId
-- WHERE t.loaicapcha IS NOT NULL

UNION ALL

-- ================== PHẦN 2: ĐƯỢC GIAO ==================
SELECT
    t.monthkey,
		t.`date`,
    t.`month`,
		t.`year`,
    t.nhomvb_ma,
    t.nhomvb,
    t.ma_nv_cha,
		t.`Code`,
		t.idnv,
		t.tennv_viettat,
    t.Ma,
    t.TenNhiemVu,
    t.SanPhamChuYeu,
    t.ThoiHanHoanThanh,
    t.NgayHoanThanh,
    t.TinhTrang,
    t.TienDoHoanThanh,
		NULL AS tong_so_don_vi_thuc_hien,
    t.songayquahan,
		t.tongtg_canxuly,
		t.tongtg_daxuly,

    t.don_vi_cap_01_dvgiao,
		t.loaicapcha_dvgiao,
		CASE
        WHEN t.iddv_dvgiao IS NULL
            THEN 'Chưa xác định'
        WHEN d1.Level = 3 THEN d1.DepartmentName
        WHEN d2.Level = 3 THEN d2.DepartmentName
        WHEN d3.Level = 3 THEN d3.DepartmentName
        WHEN d4.Level = 3 THEN d4.DepartmentName
        ELSE NULL
    END AS loaicap_dvgiao,
    t.iddv_dvgiao,
    t.donvi_dvgiao,
    t.tenviettat_dvgiao,
    t.NguoiGiaoNhiemVu,

    -- đơn vị thực hiện = đơn vị hiện tại
    t.don_vi_cap_01 AS don_vi_cap_01_dvthuchien,
    t.loaicapcha AS loaicapcha_dvthuchien,
    t.loaicap AS loaicap_dvthuchien,
		NULL AS iddv_dvthuchien,
    donvi_dvthuchien AS donvi_dvthuchien,
    NULL AS tenviettat_dvthuchien,
    NULL as NguoiThucHien,

    t.don_vi_cap_01,
		t.loaicapcha,
    t.loaicap AS loaicap,
		NULL AS iddv,
    donvi_dvthuchien AS donvi,
    NULL AS tenviettat,

    t.DonViPhoiHop,
		t.iddv_dvchutri,
		t.DonViChuTri,
    t.VanBanGiaoNhiemVu,
		t.NgayVanBan,
    t.LinhVuc,
    t.Kieu,
		t.UuTien,
    t.KetQuaGhiChu,
		t.NhomPhamViNhiemVu,
    t.TrangThai,
    REPLACE(t.TrangThaiVietTat,'Chưa HT ','CHT '),
    t.TrangThaiVietTat2,
    t.TenNhiemVu_Mobile,
    'Được giao' AS NhomGiaoNhan,
    '${sync_ts}'       AS syncdate
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan t
LEFT JOIN datamart_hanoi.department d1
    ON t.iddv_dvgiao = d1.DepartmentId

/* Cha */
LEFT JOIN datamart_hanoi.department d2
    ON d2.DepartmentId = d1.ParentId

/* Ông */
LEFT JOIN datamart_hanoi.department d3
    ON d3.DepartmentId = d2.ParentId

/* Cụ */
LEFT JOIN datamart_hanoi.department d4
    ON d4.DepartmentId = d3.ParentId
-- WHERE t.loaicapcha IS NOT NULL
-- AND ( (t.donvi = 'UBND Thành phố' AND loaicapcha_dvgiao IN ('Thành ủy Hà Nội', 'HĐND Thành phố', 'Ủy ban MTTQ Việt Nam thành phố Hà Nội') )
-- OR (t.donvi = 'HĐND Thành phố' AND loaicapcha_dvgiao IN ('Thành ủy Hà Nội', 'UBND Thành phố', 'Ủy ban MTTQ Việt Nam thành phố Hà Nội') )
-- OR (t.loaicapcha = 'Ủy ban MTTQ Việt Nam thành phố Hà Nội' AND loaicapcha_dvgiao IN ('Thành ủy Hà Nội', 'UBND Thành phố', 'HĐND Thành phố') )
-- )
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
DELETE FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom WHERE syncdate < '${sync_ts}' OR syncdate IS NULL;