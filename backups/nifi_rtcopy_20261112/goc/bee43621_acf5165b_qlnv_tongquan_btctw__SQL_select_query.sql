TRUNCATE TABLE datamart_hanoi.qlnv_tongquan_btctw;
INSERT INTO datamart_hanoi.qlnv_tongquan_btctw

SELECT
    t.monthkey,
		t.`year`,
		t.don_vi_cap_01,
    t.loaicapcha,
    t.VanBanGiaoNhiemVu,
		t.NgayVanBan,
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

FROM datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw t
GROUP BY
    t.monthkey,
		t.don_vi_cap_01,
    t.loaicapcha,
    t.VanBanGiaoNhiemVu,
    t.LinhVuc,
    t.Kieu,
		t.UuTien,
    t.nhomvb_ma,
    t.nhomvb,
		t.NhomPhamViNhiemVu,
    t.NhomGiaoNhan
;