TRUNCATE TABLE datamart_hanoi.qlnv_tongquan;

INSERT INTO datamart_hanoi.qlnv_tongquan
SELECT
    t.monthkey,
    t.loaicapcha,
    t.VanBanGiaoNhiemVu,
    t.LinhVuc,
    t.Kieu,
		t.UuTien,

    /* Tổng số nhiệm vụ */
    COUNT(*) AS tongso,

    /* ===== ĐÃ HOÀN THÀNH ===== */
    SUM(
        CASE 
            WHEN t.TrangThai LIKE 'Đã hoàn thành%' 
            THEN 1 ELSE 0 
        END
    ) AS daht,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Đã hoàn thành đúng hạn' 
            THEN 1 ELSE 0 
        END
    ) AS daht_dh,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Đã hoàn thành quá hạn' 
            THEN 1 ELSE 0 
        END
    ) AS daht_qh,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Đã hoàn thành không hạn' 
            THEN 1 ELSE 0 
        END
    ) AS daht_kh,

    /* ===== CHƯA HOÀN THÀNH ===== */
    SUM(
        CASE 
            WHEN t.TrangThai LIKE 'Chưa hoàn thành%' 
            THEN 1 ELSE 0 
        END
    ) AS dangth,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Chưa hoàn thành trong hạn' 
            THEN 1 ELSE 0 
        END
    ) AS dangth_th,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Chưa hoàn thành quá hạn' 
            THEN 1 ELSE 0 
        END
    ) AS dangth_qh,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Chưa hoàn thành sắp quá hạn' 
            THEN 1 ELSE 0 
        END
    ) AS dangth_sqh,

    SUM(
        CASE 
            WHEN t.TrangThai = 'Chưa hoàn thành không hạn' 
            THEN 1 ELSE 0 
        END
    ) AS dangth_kh,
		SUM(t.tongtg_canxuly) AS tongtg_canxuly,
		SUM(t.tongtg_daxuly) AS tongtg_daxuly,

    t.nhomvb_ma,
    t.nhomvb,
		t.NhomPhamViNhiemVu,
    t.NhomGiaoNhan,
    NOW() AS syncdate

FROM datamart_hanoi.qlnv_tonghop_chitiet t
WHERE NOT (
    t.loaicapcha = 'Thành ủy Hà Nội'
    AND t.NhomGiaoNhan = 'Được giao'
) 
/*AND NOT ( t.loaicapcha = 'UBND Thành phố'
    AND 
         t.NhomGiaoNhan = 'Được giao'
          AND t.NhomPhamViNhiemVu = 'Nhiệm vụ nội bộ')*/
GROUP BY
    t.monthkey,
    t.loaicapcha,
    t.VanBanGiaoNhiemVu,
    t.LinhVuc,
    t.Kieu,
		t.UuTien,
    t.nhomvb_ma,
    t.nhomvb,
		t.NhomPhamViNhiemVu,
    t.NhomGiaoNhan

		
UNION ALL

SELECT
 t.monthkey,

"Thành ủy Hà Nội" AS loaicapcha,

 t.loai_nhiem_vu_viettat AS VanBanGiaoNhiemVu,
NULL AS LinhVuc,
NULL AS Kieu,
NULL AS UuTien,
SUM( t.tong_so_nhiem_vu) AS tongso,
SUM( t.da_hoan_thanh) AS daht,
SUM( t.da_hoan_thanh_dung_han) AS daht_dh,
SUM( t.da_hoan_thanh_qua_han) AS daht_qh,
0 AS daht_kh,
SUM( t.on_dinh_dung_han) + SUM( t.thuong_xuyen) + SUM( t.dang_tien_hanh_qua_han) AS dangth,
SUM( t.on_dinh_dung_han) + SUM( t.thuong_xuyen) AS dangth_th,
SUM( t.dang_tien_hanh_qua_han) AS dangth_qh,
SUM( t.sap_den_han) AS dangth_sqh,
0 AS dangth_kh,
NULL AS tongtg_canxuly,
NULL AS tongtg_daxuly,
t.nhom_nhiem_vu AS nhomvb_ma,
t.nhom_nhiem_vu AS nhomvb,
'Nhiệm vụ ngoài khối' AS NhomPhamViNhiemVu,
'Được giao' AS NhomGiaoNhan,
MAX( t.syncdate)
FROM datamart_hanoi.tla_bao_cao_tong_quan t
WHERE t.monthkey = (
    SELECT MAX(monthkey)
    FROM datamart_hanoi.tla_bao_cao_tong_quan
)
GROUP BY 
 t.monthkey,
 t.loai_nhiem_vu_viettat,
 t.nhom_nhiem_vu
		
ORDER BY 
    monthkey,
    loaicapcha,
    VanBanGiaoNhiemVu,
    LinhVuc,
    Kieu,
		UuTien,
    nhomvb_ma,
    nhomvb,
		NhomGiaoNhan,
		NhomPhamViNhiemVu
