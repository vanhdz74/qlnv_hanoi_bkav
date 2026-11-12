/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
SET SESSION group_concat_max_len = 10000;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan (`monthkey`, `date`, `month`, `year`, `nhomvb_ma`, `nhomvb`, `ma_nv_cha`, `Code`, `idnv`, `tennv_viettat`, `Ma`, `TenNhiemVu`, `SanPhamChuYeu`, `ThoiHanHoanThanh`, `NgayHoanThanh`, `TinhTrang`, `TienDoHoanThanh`, `songayquahan`, `tongtg_canxuly`, `tongtg_daxuly`, `don_vi_cap_01`, `loaicapcha`, `loaicap`, `don_vi_cap_01_dvgiao`, `loaicapcha_dvgiao`, `iddv_dvgiao`, `donvi_dvgiao`, `tenviettat_dvgiao`, `NguoiGiaoNhiemVu`, `donvi_dvthuchien`, `DonViPhoiHop`, `iddv_dvchutri`, `DonViChuTri`, `VanBanGiaoNhiemVu`, `NgayVanBan`, `LinhVuc`, `Kieu`, `UuTien`, `KetQuaGhiChu`, `NhomPhamViNhiemVu`, `TrangThai`, `TrangThaiVietTat`, `TrangThaiVietTat2`, `TenNhiemVu_Mobile`, `syncdate`)
SELECT
    main.monthkey,
    main.`date`,
    main.monthkey,
    main.`year`,
    main.nhomvb_ma,
    main.nhomvb,
    main.ma_nv_cha,
	main.`Code`,
	main.idnv,
	main.tennv_viettat,
    main.Ma,
    main.TenNhiemVu,
    main.SanPhamChuYeu,
    main.ThoiHanHoanThanh,
    main.NgayHoanThanh,

    /* các cột còn lại */
    main.TinhTrang,
    main.TienDoHoanThanh,
    CASE
        /* chưa hoàn thành nhưng đã quá hạn */
        WHEN main.NgayHoanThanh IS NULL
             AND main.ThoiHanHoanThanh IS NOT NULL
             AND main.ThoiHanHoanThanh < CURDATE()
        THEN DATEDIFF(
                      CURDATE(),
                      main.ThoiHanHoanThanh
                         )

        /* đã hoàn thành nhưng quá hạn */
        WHEN main.NgayHoanThanh IS NOT NULL
             AND main.ThoiHanHoanThanh IS NOT NULL
             AND main.NgayHoanThanh > main.ThoiHanHoanThanh
        THEN DATEDIFF(
                      main.NgayHoanThanh,
                      main.ThoiHanHoanThanh
                         )

        ELSE NULL
    END AS songayquahan,
	main.tongtg_canxuly AS tongtg_canxuly,
	main.tongtg_daxuly AS tongtg_daxuly,
    -- main.songayquahan,
    main.don_vi_cap_01,
    main.loaicapcha,
	main.loaicap,
    main.don_vi_cap_01_dvgiao,
    main.loaicapcha_dvgiao,
    main.iddv_dvgiao,
    main.donvi_dvgiao,
    main.tenviettat_dvgiao,
    main.NguoiGiaoNhiemVu,
    main.donvi_dvthuchien,
    main.DonViPhoiHop,
	main.iddv_dvchutri,
	main.DonViChuTri,
    main.VanBanGiaoNhiemVu,
    main.NgayVanBan,
	main.LinhVuc,
    main.Kieu,
	main.UuTien,
    main.KetQuaGhiChu,
	main.NhomPhamViNhiemVu,
                /* TRẠNG THÁI SUY RA */
		CASE
				-- 1. Đã hoàn thành đúng hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 <= main.ThoiHanHoanThanh
						THEN 'Đã hoàn thành đúng hạn'

				-- 2. Đã hoàn thành quá hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 > main.ThoiHanHoanThanh
						THEN 'Đã hoàn thành quá hạn'

				-- 3. Chưa hoàn thành – trong hạn (còn > 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) > 5
						THEN 'Chưa hoàn thành trong hạn'

				-- 4. Chưa hoàn thành – sắp quá hạn (còn 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) <= 5
						THEN 'Chưa hoàn thành sắp quá hạn'

				-- 5. Chưa hoàn thành – quá hạn
				WHEN main.NgayHoanThanh IS NULL
						 AND CURDATE() > main.ThoiHanHoanThanh
						THEN 'Chưa hoàn thành quá hạn'
				-- NVU không hạn
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Đã hoàn thành' THEN
					CONCAT(main.TinhTrang,' đúng hạn')
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Chưa hoàn thành' THEN
					CONCAT(main.TinhTrang,' trong hạn')
		END AS TrangThai,
		CASE
				-- 1. Đã hoàn thành đúng hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 <= main.ThoiHanHoanThanh
						THEN 'HT đúng hạn'

				-- 2. Đã hoàn thành quá hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 > main.ThoiHanHoanThanh
						THEN 'HT quá hạn'

				-- 3. Chưa hoàn thành – trong hạn (còn > 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) > 5
						THEN 'CHT trong hạn'

				-- 4. Chưa hoàn thành – sắp quá hạn (còn 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) <= 5
						THEN 'CHT sắp quá hạn'

				-- 5. Chưa hoàn thành – quá hạn
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() > main.ThoiHanHoanThanh
						THEN 'CHT quá hạn'
				
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Đã hoàn thành' THEN
					'HT đúng hạn'
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Chưa hoàn thành' THEN
					'CHT trong hạn'
		END AS  TrangThaiVietTat,
		CASE
				-- 1. Đã hoàn thành đúng hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 <= main.ThoiHanHoanThanh
						THEN 'HT đúng hạn'

				-- 2. Đã hoàn thành quá hạn
				WHEN main.NgayHoanThanh IS NOT NULL
						AND main.NgayHoanThanh
								 > main.ThoiHanHoanThanh
						THEN 'HT quá hạn'

				-- 3. Chưa hoàn thành – trong hạn (còn > 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) > 5
						THEN 'Chưa HT trong hạn'

				-- 4. Chưa hoàn thành – sắp quá hạn (còn 1 ngày)
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() <= main.ThoiHanHoanThanh
						AND DATEDIFF(
										main.ThoiHanHoanThanh,
										CURDATE()
								 ) <= 5
						THEN 'Chưa HT sắp quá hạn'

				-- 5. Chưa hoàn thành – quá hạn
				WHEN main.NgayHoanThanh IS NULL
						AND CURDATE() > main.ThoiHanHoanThanh
						THEN 'Chưa HT quá hạn'
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Đã hoàn thành' THEN
					'HT đúng hạn'
				WHEN main.ThoiHanHoanThanh IS NULL AND main.TinhTrang = 'Chưa hoàn thành' THEN
					'Chưa HT trong hạn'
		END AS TrangThaiVietTat2,
                main.TenNhiemVu_Mobile,
    '${sync_ts}' AS syncdate

FROM (
    -- subquery của Tùng giữ nguyên
SELECT
        MAX(monthkey) AS monthkey,
				MAX(`date`) AS `date`,
        MAX(`month`) AS `month`,
				MAX(`year`) AS `year`,
        nhomvb_ma,
        MAX(nhomvb) AS nhomvb,
        MAX(ma_nv_cha) AS ma_nv_cha,
        -- SUBSTRING(GROUP_CONCAT(DISTINCT LEFT(Ma,50) ORDER BY Ma SEPARATOR ', '),1,255) AS Ma,
				MIN(`Code`) AS `Code`,
				MIN(idnv) AS idnv,
				MIN(tennv_viettat) AS tennv_viettat,
				MIN(Ma) AS Ma,
        TenNhiemVu,
        MAX(SanPhamChuYeu) AS SanPhamChuYeu,
        MAX(ThoiHanHoanThanh) AS ThoiHanHoanThanh,
        CASE
            WHEN COUNT( iddv) > 0 AND 
						COUNT( iddv)
                 = COUNT( CASE
                        WHEN TinhTrang = 'Đã hoàn thành'
                        THEN 1
                   END)
            THEN MAX(
            CASE
                WHEN TinhTrang = 'Đã hoàn thành'
                THEN NgayHoanThanh
            END
						)
            ELSE NULL
        END AS NgayHoanThanh,
        CASE
            WHEN COUNT( iddv) > 0 AND COUNT( iddv)
                 = COUNT( CASE
                        WHEN TinhTrang = 'Đã hoàn thành'
                        THEN 1
                   END)
            THEN 'Đã hoàn thành'
            ELSE 'Chưa hoàn thành'
        END AS TinhTrang,
        CONCAT(ROUND(
               COUNT( CASE
                               WHEN TinhTrang = 'Đã hoàn thành'
                               THEN iddv
               END)
               * 100.0
               / NULLIF(COUNT( iddv), 0),
               0
            ),'%') AS TienDoHoanThanh,
        MAX(songayquahan) AS songayquahan,
				MAX(tongtg_canxuly) AS tongtg_canxuly,
				MAX(tongtg_daxuly) AS tongtg_daxuly,
        don_vi_cap_01 AS don_vi_cap_01,
        loaicapcha AS loaicapcha,
        don_vi_cap_01_dvgiao AS don_vi_cap_01_dvgiao,
        loaicapcha_dvgiao AS loaicapcha_dvgiao,
        MAX(iddv_dvgiao) AS iddv_dvgiao,
        MAX(donvi_dvgiao) AS donvi_dvgiao,
        NULL AS tenviettat_dvgiao, -- MAX(tenviettat_dvgiao) AS tenviettat_dvgiao,
        SUBSTRING(GROUP_CONCAT(
            DISTINCT NguoiGiaoNhiemVu
            ORDER BY NguoiGiaoNhiemVu
            SEPARATOR '; '
        ),1,255) AS NguoiGiaoNhiemVu,
				loaicap,
        GROUP_CONCAT(
            DISTINCT donvi
            ORDER BY donvi
            SEPARATOR '; '
        ) AS donvi_dvthuchien,
        NULL AS DonViPhoiHop,
				MAX(iddv_dvchutri) AS iddv_dvchutri,
				MAX(DonViChuTri ) AS DonViChuTri,
        MAX(VanBanGiaoNhiemVu) AS VanBanGiaoNhiemVu,
        MAX(NgayVanBan) AS NgayVanBan,
				IFNULL(MAX(LinhVuc),'Chưa xác định') AS LinhVuc,
        MAX(Kieu) AS Kieu,
				CASE MIN(
						CASE UuTien
								WHEN 'Hỏa tốc'      THEN 1
								WHEN 'Thượng khẩn'  THEN 2
								WHEN 'Khẩn'         THEN 3
								WHEN 'Thường'       THEN 4
								ELSE 5
						END
				)
						WHEN 1 THEN 'Hỏa tốc'
						WHEN 2 THEN 'Thượng khẩn'
						WHEN 3 THEN 'Khẩn'
						WHEN 4 THEN 'Thường'
						ELSE 'Không xác định'
				END AS UuTien,
        MAX(KetQuaGhiChu) AS KetQuaGhiChu,
				MAX(NhomPhamViNhiemVu) AS NhomPhamViNhiemVu,
				NULL AS TenNhiemVu_Mobile
    FROM qlnv_tonghop_chitiet_tiepnhan
		-- WHERE loaicapcha !='Thành ủy Hà Nội'
		-- AND iddv_dvgiao NOT IN (1307)
		-- AND iddv IN (698, 1775, 1790)
		-- OR loaicap IN ('Sở ngành','Xã, Phường')
    GROUP BY
				monthkey,
				TenNhiemVu,
				don_vi_cap_01_dvgiao,
				loaicapcha_dvgiao,
				don_vi_cap_01,
				loaicap,
				loaicapcha,
				`month`,
				nhomvb_ma,
				VanBanGiaoNhiemVu,
        NhomPhamViNhiemVu,
        TenNhiemVu
) main
ORDER BY
		`year`,
		monthkey,
		`date`,
        TenNhiemVu,
		don_vi_cap_01_dvgiao,
        loaicapcha_dvgiao,
		don_vi_cap_01,
        loaicapcha,
        `month`,
        nhomvb_ma,
        VanBanGiaoNhiemVu,
        TenNhiemVu
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
    `songayquahan` = VALUES(`songayquahan`),
    `tongtg_canxuly` = VALUES(`tongtg_canxuly`),
    `tongtg_daxuly` = VALUES(`tongtg_daxuly`),
    `don_vi_cap_01` = VALUES(`don_vi_cap_01`),
    `loaicapcha` = VALUES(`loaicapcha`),
    `loaicap` = VALUES(`loaicap`),
    `don_vi_cap_01_dvgiao` = VALUES(`don_vi_cap_01_dvgiao`),
    `loaicapcha_dvgiao` = VALUES(`loaicapcha_dvgiao`),
    `iddv_dvgiao` = VALUES(`iddv_dvgiao`),
    `donvi_dvgiao` = VALUES(`donvi_dvgiao`),
    `tenviettat_dvgiao` = VALUES(`tenviettat_dvgiao`),
    `NguoiGiaoNhiemVu` = VALUES(`NguoiGiaoNhiemVu`),
    `donvi_dvthuchien` = VALUES(`donvi_dvthuchien`),
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
DELETE FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom_tiepnhan WHERE syncdate < '${sync_ts}' OR syncdate IS NULL;