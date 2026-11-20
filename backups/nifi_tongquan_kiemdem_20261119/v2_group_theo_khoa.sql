/* [RT 12/11 full] ghi *; TRUNCATE+INSERT → staging + RENAME swap */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tongquan_donvi_kiemdem__stg LIKE datamart_hanoi.qlnv_tongquan_donvi_kiemdem;
TRUNCATE TABLE datamart_hanoi.qlnv_tongquan_donvi_kiemdem__stg;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tongquan_donvi_kiemdem__stg
SELECT
    c.monthkey,
		c.`date`,
    c.`month`,
		c.`year`,
		c.don_vi_cap_01,
    c.loaicapcha,

    /* ÉP loaicap = DepartmentName có Level = 3 */
    CASE
        WHEN c.iddv IS NULL
            THEN 'Chưa xác định'
        WHEN d1.Level = 3 THEN d1.DepartmentName
        WHEN d2.Level = 3 THEN d2.DepartmentName
        WHEN d3.Level = 3 THEN d3.DepartmentName
        WHEN d4.Level = 3 THEN d4.DepartmentName
        ELSE NULL
    END AS loaicap,

    c.iddv,
    c.donvi,
    c.tenviettat,
		c.don_vi_cap_01_dvgiao,
		c.loaicapcha_dvgiao,
		c.loaicap_dvgiao,
		c.iddv_dvgiao,
		c.donvi_dvgiao,
		c.tenviettat_dvgiao,
		c.don_vi_cap_01_dvthuchien,
		c.loaicapcha_dvthuchien,
		c.loaicap_dvthuchien,
		c.iddv_dvthuchien,
		c.donvi_dvthuchien,
		c.tenviettat_dvthuchien,
		
		CASE 
			WHEN c.loaicap_dvthuchien IN ( 'Đảng bộ trực thuộc', 'Xã, Phường', 'HĐND Xã, Phường', 'MTTQ Xã, Phường' ) 
				AND ( c.donvi_dvthuchien LIKE '%xã%' OR c.donvi_dvthuchien LIKE '%phường%' )  THEN 'Xã, phường'
			WHEN donvi_dvthuchien IN ('HĐND Thành phố','Thành ủy Hà Nội', 'UBND Thành phố', 'Ủy ban MTTQ Việt Nam thành phố Hà Nội', 'Đảng bộ trực thuộc', 'Xã, Phường', 'HĐND Xã, Phường', 'MTTQ Xã, Phường' )
			OR loaicap_dvthuchien = 'Văn phòng UBND TP' THEN 'Chưa xác định'
			ELSE
				'Sở, ban, ngành'
		END AS donvi_filter,
    c.VanBanGiaoNhiemVu,
		c.NgayVanBan,
    c.LinhVuc,
    c.Kieu,
		c.UuTien,

    COUNT(*) AS tongso,

    COUNT(CASE WHEN c.TrangThai LIKE 'Đã hoàn thành%' THEN 1 END) AS daht,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NOT NULL AND c.TrangThai = 'Đã hoàn thành đúng hạn' THEN 1 END) AS daht_dh,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NOT NULL AND c.TrangThai = 'Đã hoàn thành quá hạn' THEN 1 END) AS daht_qh,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NULL AND c.TrangThai LIKE 'Đã hoàn thành%' THEN 1 END) AS daht_kh,

    COUNT(CASE WHEN c.TrangThai LIKE 'Chưa hoàn thành%' THEN 1 END) AS dangth,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NOT NULL AND c.TrangThai = 'Chưa hoàn thành trong hạn' THEN 1 END) AS dangth_th,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NOT NULL AND c.TrangThai = 'Chưa hoàn thành quá hạn' THEN 1 END) AS dangth_qh,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NOT NULL AND c.TrangThai = 'Chưa hoàn thành sắp quá hạn' THEN 1 END) AS dangth_sqh,
    COUNT(CASE WHEN c.ThoiHanHoanThanh IS NULL AND c.TrangThai LIKE 'Chưa hoàn thành%' THEN 1 END) AS dangth_kh,
		SUM(c.tongtg_canxuly) AS tongtg_canxuly,
		SUM(c.tongtg_daxuly) AS tongtg_daxuly,

    c.nhomvb_ma,
    c.nhomvb,
		c.NhomPhamViNhiemVu,
    c.NhomGiaoNhan,
    NOW() AS syncdate
FROM datamart_hanoi.qlnv_tonghop_chitiet_donvi c

/* Level hiện tại */
LEFT JOIN datamart_hanoi.department d1
    ON c.iddv = d1.DepartmentId

/* Cha */
LEFT JOIN datamart_hanoi.department d2
    ON d2.DepartmentId = d1.ParentId

/* Ông */
LEFT JOIN datamart_hanoi.department d3
    ON d3.DepartmentId = d2.ParentId

/* Cụ */
LEFT JOIN datamart_hanoi.department d4
    ON d4.DepartmentId = d3.ParentId

WHERE c.iddv IS NOT NULL AND don_vi_cap_01 = 'THÀNH PHỐ HÀ NỘI'
GROUP BY
    /* [19/11] chỉ group theo khóa, cột tên phụ thuộc id (đã kiểm 0 vi phạm) — tránh sort 30 cột varchar vượt 60s */
    c.monthkey,
    c.iddv,
    c.iddv_dvgiao,
    c.iddv_dvthuchien,
    c.VanBanGiaoNhiemVu,
    c.NgayVanBan,
    c.LinhVuc,
    c.Kieu,
    c.UuTien,
    c.nhomvb_ma,
    c.NhomGiaoNhan,
    c.NhomPhamViNhiemVu
;
/* đổi chỗ nguyên tử, chờ khóa tối đa 10s */
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tongquan_donvi_kiemdem TO datamart_hanoi.qlnv_tongquan_donvi_kiemdem__old, datamart_hanoi.qlnv_tongquan_donvi_kiemdem__stg TO datamart_hanoi.qlnv_tongquan_donvi_kiemdem, datamart_hanoi.qlnv_tongquan_donvi_kiemdem__old TO datamart_hanoi.qlnv_tongquan_donvi_kiemdem__stg;
SET SESSION lock_wait_timeout = 31536000;