/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
SET SESSION group_concat_max_len = 100000;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv_new_rt (`monthkey`, `date`, `month`, `year`, `nhomvb_ma`, `nhomvb`, `ma_nv_cha`, `Code`, `idnv`, `tennv_viettat`, `Ma`, `TenNhiemVu`, `SanPhamChuYeu`, `ThoiHanHoanThanh`, `NgayHoanThanh`, `TinhTrang`, `TienDoHoanThanh`, `tong_so_don_vi_thuc_hien`, `songayquahan`, `tongtg_canxuly`, `tongtg_daxuly`, `don_vi_cap_01`, `loaicapcha`, `loaicap`, `iddv`, `donvi`, `tenviettat`, `NguoiGiaoNhiemVu`, `donvi_dvthuchien`, `DonViPhoiHop`, `iddv_dvchutri`, `DonViChuTri`, `VanBanGiaoNhiemVu`, `NgayVanBan`, `LinhVuc`, `Kieu`, `UuTien`, `KetQuaGhiChu`, `NoiDungBaoCao`, `NhomPhamViNhiemVu`, `TrangThai`, `TrangThaiVietTat`, `TrangThaiVietTat2`, `TenNhiemVu_Mobile`, `nhiem_vu_co_thoi_han`, `syncdate`)
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
		main.tong_so_don_vi_thuc_hien,
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
                         AND main.NgayHoanThanh
                                         > main.ThoiHanHoanThanh
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
    main.iddv,
    main.donvi,
    main.tenviettat,
    main.NguoiGiaoNhiemVu,
    main.donvi_dvthuchien,
    main.DonViPhoiHop,
		main.iddv_dvchutri ,
		main.DonViChuTri,
    main.VanBanGiaoNhiemVu,
    main.NgayVanBan,
		main.LinhVuc,
    main.Kieu,
		main.UuTien,
    main.KetQuaGhiChu,
		main.NoiDungBaoCao,
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
		IF(main.ThoiHanHoanThanh IS NOT NULL, 1, 0) AS nhiem_vu_co_thoi_han,
    '${sync_ts}' AS syncdate

FROM (
    -- subquery của Tùng giữ nguyên
    SELECT
        MAX(g.monthkey) AS monthkey,
				MAX(g.`date`) AS `date`,
        MAX(g.`month`) AS `month`,
				MAX(g.`year`) AS `year`,
        g.nhomvb_ma,
        MAX(g.nhomvb) AS nhomvb,
        MAX(g.ma_nv_cha) AS ma_nv_cha,
				
        -- SUBSTRING(GROUP_CONCAT(DISTINCT LEFT(Ma,50) ORDER BY Ma SEPARATOR ', '),1,255) AS Ma,
				MIN(g.`Code`) AS `Code`,
				MIN(g.idnv) AS idnv,
				MIN(g.tennv_viettat) AS tennv_viettat,
				MIN(g.Ma) AS Ma,
        g.TenNhiemVu,
        MAX(g.SanPhamChuYeu) AS SanPhamChuYeu,
        CASE 
						WHEN ( MAX(g.ma_nv_cha) IS NOT NULL AND g_cha.ThoiHanHoanThanh IS NOT NULL) THEN  MAX( g_cha.ThoiHanHoanThanh)
						ELSE MAX( g.ThoiHanHoanThanh)
				END AS ThoiHanHoanThanh,
        CASE
						WHEN MAX(g.ma_nv_cha) IS NOT NULL AND MAX(g_cha.NgayHoanThanh) IS NOT NULL THEN MAX(g_cha.NgayHoanThanh)
            WHEN ((MAX(g.ma_nv_cha) IS NULL) OR (MAX(g.ma_nv_cha) IS NOT NULL AND MAX(g_cha.NgayHoanThanh) IS NULL ))
						AND COUNT( g.iddv_dvthuchien) > 0 AND 
						COUNT( g.iddv_dvthuchien)
                 = COUNT( CASE
                        WHEN g.TinhTrang = 'Đã hoàn thành'
                        THEN 1
                   END)
            THEN MAX(
            CASE
                WHEN g.TinhTrang = 'Đã hoàn thành'
                THEN g.NgayHoanThanh
            END )

            ELSE NULL
        END AS NgayHoanThanh,
        CASE
						WHEN MAX( g.ma_nv_cha) IS NOT NULL AND MAX( g_cha.TinhTrang) IS NOT NULL THEN MAX(g_cha.TinhTrang)
            WHEN ( ( MAX( g.ma_nv_cha) IS NULL ) OR ( MAX( g.ma_nv_cha) IS NOT NULL AND MAX(g_cha.TinhTrang) IS NULL ) ) 
						AND COUNT( g.iddv_dvthuchien) > 0 AND COUNT( g.iddv_dvthuchien)
                 = COUNT( CASE
                        WHEN g.TinhTrang = 'Đã hoàn thành'
                        THEN 1
                   END)
            THEN 'Đã hoàn thành'
            ELSE 'Chưa hoàn thành'
        END AS TinhTrang,
        CONCAT( ROUND(
               COUNT( CASE
                               WHEN g.TinhTrang = 'Đã hoàn thành'
                               THEN g.iddv_dvthuchien
               END)
               * 100.0
               / NULLIF(COUNT( g.iddv_dvthuchien), 0),
               2
            ),'%') AS TienDoHoanThanh,
				COUNT( g.iddv_dvthuchien) AS tong_so_don_vi_thuc_hien,
        MAX(g.songayquahan) AS songayquahan,
				MAX(g.tongtg_canxuly) AS tongtg_canxuly,
				MAX(g.tongtg_daxuly) AS tongtg_daxuly,
        MAX(g.don_vi_cap_01) AS don_vi_cap_01,
        MAX(g.loaicapcha) AS loaicapcha,
        MAX(g.loaicap) AS loaicap,
        g.iddv,
        MAX(g.donvi) AS donvi,
        MAX(g.tenviettat) AS tenviettat,
        SUBSTRING(GROUP_CONCAT(
            DISTINCT g.NguoiGiaoNhiemVu
            ORDER BY g.NguoiGiaoNhiemVu
            SEPARATOR '; '
        ),1,255) AS NguoiGiaoNhiemVu,
        GROUP_CONCAT(
            DISTINCT g.donvi_dvthuchien
            ORDER BY g.donvi_dvthuchien
            SEPARATOR '; '
        ) AS donvi_dvthuchien,
        NULL AS DonViPhoiHop,
				MAX(g.iddv_dvchutri) AS iddv_dvchutri,
				MAX(g.DonViChuTri ) AS DonViChuTri ,
        MAX(g.VanBanGiaoNhiemVu) AS VanBanGiaoNhiemVu,
        MAX(g.NgayVanBan) AS NgayVanBan,
				IFNULL(MAX(g.LinhVuc),'Chưa xác định') AS LinhVuc,
        MAX(g.Kieu) AS Kieu,
				CASE MIN(
						CASE g.UuTien
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
        MAX(g.KetQuaGhiChu) AS KetQuaGhiChu,
				GROUP_CONCAT(
						CONCAT(
								'- (<b>',
								DATE_FORMAT(g.ThoiDiemBaoCao, '%Y-%m-%d %H:%i:%s'),
								'</b>) ',
								UPPER(g.NguoiThucHien),
								' - ',
								UPPER(g.donvi_dvthuchien),
								': ',
								g.NoiDungBaoCao
						)
						SEPARATOR '<br>'
				) AS NoiDungBaoCao,
				/*COALESCE(g_cha.NhomPhamViNhiemVu,g.NhomPhamViNhiemVu) */ NULL AS NhomPhamViNhiemVu,
				NULL AS TenNhiemVu_Mobile
    FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt g
		LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_giaonv_new_rt g_cha ON g.ma_nv_cha = g_cha.Ma
    GROUP BY
        LEFT(g.monthkey,4),
        g.nhomvb_ma,
				g.VanBanGiaoNhiemVu,
        g.iddv,
				-- COALESCE(g_cha.NhomPhamViNhiemVu, g.NhomPhamViNhiemVu),
        g.TenNhiemVu
) main
ORDER BY
    `year`,
    monthkey,
    `date`,
    nhomvb_ma,
		VanBanGiaoNhiemVu,
    iddv,
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
    `tong_so_don_vi_thuc_hien` = VALUES(`tong_so_don_vi_thuc_hien`),
    `songayquahan` = VALUES(`songayquahan`),
    `tongtg_canxuly` = VALUES(`tongtg_canxuly`),
    `tongtg_daxuly` = VALUES(`tongtg_daxuly`),
    `don_vi_cap_01` = VALUES(`don_vi_cap_01`),
    `loaicapcha` = VALUES(`loaicapcha`),
    `loaicap` = VALUES(`loaicap`),
    `iddv` = VALUES(`iddv`),
    `donvi` = VALUES(`donvi`),
    `tenviettat` = VALUES(`tenviettat`),
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
    `NoiDungBaoCao` = VALUES(`NoiDungBaoCao`),
    `NhomPhamViNhiemVu` = VALUES(`NhomPhamViNhiemVu`),
    `TrangThai` = VALUES(`TrangThai`),
    `TrangThaiVietTat` = VALUES(`TrangThaiVietTat`),
    `TrangThaiVietTat2` = VALUES(`TrangThaiVietTat2`),
    `TenNhiemVu_Mobile` = VALUES(`TenNhiemVu_Mobile`),
    `nhiem_vu_co_thoi_han` = VALUES(`nhiem_vu_co_thoi_han`),
    `syncdate` = VALUES(`syncdate`);
/* Xóa bản ghi không còn trong nguồn ở chu kỳ này */
DELETE FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv_new_rt WHERE syncdate < '${sync_ts}' OR syncdate IS NULL;