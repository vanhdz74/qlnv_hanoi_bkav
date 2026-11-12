TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv;
SET SESSION group_concat_max_len = 5000;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_nhom_giaonv
SELECT
    main.monthkey,
    main.`month`,
    main.nhomvb_ma,
    main.nhomvb,
    main.ma_nv_cha,
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
        WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
                         AND STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y') IS NOT NULL
                         AND STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y') < CURDATE()
        THEN DATEDIFF(
                                        CURDATE(),
                                        STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
                         )

        /* đã hoàn thành nhưng quá hạn */
        WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
                         AND STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y') IS NOT NULL
                         AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y')
                                         > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
        THEN DATEDIFF(
                                        STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y'),
                                        STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
                         )

        ELSE NULL
    END AS songayquahan,

    -- main.songayquahan,
    main.loaicapcha,
    main.loaicap,
    main.iddv,
    main.donvi,
    main.tenviettat,
    main.NguoiGiaoNhiemVu,
    main.donvi_dvthuchien,
    main.DonViPhoiHop,
    main.VanBanGiaoNhiemVu,
		main.LinhVuc,
    main.Kieu,
    main.KetQuaGhiChu,
                /* TRẠNG THÁI SUY RA */
		CASE
				-- 1. Đã hoàn thành đúng hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
						 AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y')
								 <= STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'Đã hoàn thành đúng hạn'

				-- 2. Đã hoàn thành quá hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
						 AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y')
								 > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'Đã hoàn thành quá hạn'

				-- 3. Chưa hoàn thành – trong hạn (còn > 1 ngày)
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND DATEDIFF(
										STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y'),
										CURDATE()
								 ) > 1
						THEN 'Chưa hoàn thành trong hạn'

				-- 4. Chưa hoàn thành – sắp quá hạn (còn 1 ngày)
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND DATEDIFF(
										STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y'),
										CURDATE()
								 ) = 1
						THEN 'Chưa hoàn thành sắp quá hạn'

				-- 5. Chưa hoàn thành – quá hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND CURDATE() > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'Chưa hoàn thành quá hạn'
		END AS TrangThai,
		CASE
				-- 1. Đã hoàn thành đúng hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
						 AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y')
								 <= STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'HT đúng hạn'

				-- 2. Đã hoàn thành quá hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
						 AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y')
								 > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'HT quá hạn'

				-- 3. Chưa hoàn thành – trong hạn (còn > 1 ngày)
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND DATEDIFF(
										STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y'),
										CURDATE()
								 ) > 1
						THEN 'CHT trong hạn'

				-- 4. Chưa hoàn thành – sắp quá hạn (còn 1 ngày)
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND DATEDIFF(
										STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y'),
										CURDATE()
								 ) = 1
						THEN 'CHT sắp quá hạn'

				-- 5. Chưa hoàn thành – quá hạn
				WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
						 AND CURDATE() > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
						THEN 'CHT quá hạn'
		END AS  TrangThaiVietTat,
    CASE
        WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
             AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') <= STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
            THEN 'Đã HT đúng hạn'

        WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NOT NULL
             AND STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') > STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
            THEN 'Đã HT quá hạn'

        WHEN STR_TO_DATE(main.NgayHoanThanh, '%d/%m/%Y') IS NULL
             AND CURDATE() <= STR_TO_DATE(main.ThoiHanHoanThanh, '%d/%m/%Y')
            THEN 'Chưa HT trong hạn'

        ELSE 'Chưa HT quá hạn'
    END AS TrangThaiVietTat2,
                main.TenNhiemVu_Mobile

FROM (
    -- subquery của Tùng giữ nguyên
    SELECT
        MAX(monthkey) AS monthkey,
        MAX(month) AS `month`,
        nhomvb_ma,
        MAX(nhomvb) AS nhomvb,
        MAX(ma_nv_cha) AS ma_nv_cha,
        -- SUBSTRING(GROUP_CONCAT(DISTINCT LEFT(Ma,50) ORDER BY Ma SEPARATOR ', '),1,255) AS Ma,
				MIN(Ma) AS Ma,
        TenNhiemVu,
        MAX(SanPhamChuYeu) AS SanPhamChuYeu,
        MAX(ThoiHanHoanThanh) AS ThoiHanHoanThanh,
        CASE
            WHEN COUNT(DISTINCT iddv_dvthuchien)
                 = COUNT(DISTINCT CASE
                        WHEN TinhTrang = 'Đã hoàn thành'
                        THEN iddv_dvthuchien
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
            WHEN COUNT(DISTINCT iddv_dvthuchien)
                 = COUNT(DISTINCT CASE
                        WHEN TinhTrang = 'Đã hoàn thành'
                        THEN iddv_dvthuchien
                   END)
            THEN 'Đã hoàn thành'
            ELSE 'Chưa hoàn thành'
        END AS TinhTrang,
        CONCAT(ROUND(
               COUNT(DISTINCT CASE
                               WHEN TinhTrang = 'Đã hoàn thành'
                               THEN iddv_dvthuchien
               END)
               * 100.0
               / NULLIF(COUNT(DISTINCT iddv_dvthuchien), 0),
               0
            ),'%') AS TienDoHoanThanh,
        MAX(songayquahan) AS songayquahan,
        MAX(loaicapcha) AS loaicapcha,
        MAX(loaicap) AS loaicap,
        iddv,
        MAX(donvi) AS donvi,
        MAX(tenviettat) AS tenviettat,
        SUBSTRING(GROUP_CONCAT(
            DISTINCT NguoiGiaoNhiemVu
            ORDER BY NguoiGiaoNhiemVu
            SEPARATOR '; '
        ),1,255) AS NguoiGiaoNhiemVu,
        GROUP_CONCAT(
            DISTINCT donvi_dvthuchien
            ORDER BY donvi_dvthuchien
            SEPARATOR '; '
        ) AS donvi_dvthuchien,
        NULL AS DonViPhoiHop,
        MAX(VanBanGiaoNhiemVu) AS VanBanGiaoNhiemVu,
				IFNULL(MAX(LinhVuc),'Chưa xác định') AS LinhVuc,
        MAX(Kieu) AS Kieu,
        MAX(KetQuaGhiChu) AS KetQuaGhiChu,
                                NULL AS TenNhiemVu_Mobile
    FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv
    GROUP BY
        month,
        nhomvb_ma,
				VanBanGiaoNhiemVu,
        iddv,
        TenNhiemVu
) main
ORDER BY
    month,
    nhomvb_ma,
		VanBanGiaoNhiemVu,
    iddv,
    TenNhiemVu;
