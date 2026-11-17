/* SINH TỰ ĐỘNG bởi build_sql.py — không sửa tay.
   Dataset dashboard nq57-chuyen-de-chi-tiet: số liệu lấy từ datamart_hanoi.v_nq57_solieu (NQ57), cột giống datamart_hanoi.chuyen_de_chi_tiet_nq57.
   Danh mục chỉ số (tên/chuyên đề/ngưỡng/đầu mối) lấy từ các dòng CHI_SO của bảng cũ; số liệu bảng cũ KHÔNG dùng. */
SELECT
    'CHI_SO'                       AS nhom_du_lieu,
    dm.ma_chi_so,
    k.ky,
    ''                             AS phan_to,
    k.thu_tu_ky,
    dm.thu_tu_chi_so, dm.stt_chuyen_de, dm.chuyen_de, dm.ten_chi_so, dm.ten_ngan, dm.don_vi_tinh,
    dm.loai_chi_so, dm.giam_la_tot, dm.nguong, dm.ten_nguong,
    x.tu_so, x.mau_so, x.gia_tri,
    IF(x.gia_tri IS NULL, 0, 1)    AS co_so_lieu,
    IF(x.gia_tri IS NULL, NULL, CONCAT('NQ57 – cập nhật ', DATE_FORMAT(k.cap_nhat_luc, '%d/%m/%Y %H:%i'))) AS nguon_so_lieu,
    NULL AS vi_tri, NULL AS trich_dan,
    dm.dau_moi, dm.luu_y,
    IF(x.gia_tri IS NULL AND x.ma IS NOT NULL, 'NQ57 chưa có số kỳ này', IF(x.ma IS NULL, 'Chưa có chỉ tiêu tương ứng trong NQ57', NULL)) AS ghi_chu,
    NULL AS thong_tin_them,
    k.sync_date
FROM (
    SELECT ma_chi_so,
           MAX(thu_tu_chi_so) thu_tu_chi_so, MAX(stt_chuyen_de) stt_chuyen_de, MAX(chuyen_de) chuyen_de,
           MAX(ten_chi_so) ten_chi_so, MAX(ten_ngan) ten_ngan, MAX(don_vi_tinh) don_vi_tinh, MAX(loai_chi_so) loai_chi_so,
           MAX(giam_la_tot) giam_la_tot, MAX(nguong) nguong, MAX(ten_nguong) ten_nguong, MAX(dau_moi) dau_moi, MAX(luu_y) luu_y
    FROM datamart_hanoi.chuyen_de_chi_tiet_nq57
    WHERE nhom_du_lieu = 'CHI_SO'
    GROUP BY ma_chi_so
) dm
CROSS JOIN (
    SELECT ky AS ky_nq57,
           CONCAT('T', CAST(RIGHT(ky, 2) AS UNSIGNED), '/', LEFT(ky, 4)) AS ky,
           CAST(RIGHT(ky, 2) AS UNSIGNED) - 1 + (CAST(LEFT(ky, 4) AS UNSIGNED) - 2026) * 12 AS thu_tu_ky,
           MAX(cap_nhat_luc) cap_nhat_luc, MAX(sync_date) sync_date
    FROM datamart_hanoi.v_nq57_solieu
    WHERE loai_so = 'ACTUAL' AND ky LIKE '____M__'  -- không dùng REGEXP: Superset đổi thành REGEXP_LIKE, MySQL 5.7 không có
    GROUP BY ky
) k
LEFT JOIN (
    SELECT mp.ma, p.ky,
           CASE mp.ma
                WHEN 'AT02' THEN p.`B08_A02`
                WHEN 'AT09' THEN p.`B08_A14`
                WHEN 'CS07' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_MOHINH`, NULL)
                WHEN 'CS08' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_DULIEU`, NULL)
                WHEN 'CS09' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_DVC`, NULL)
                WHEN 'CS17' THEN p.`B10_A03`
                WHEN 'DD05' THEN p.`B07_A03`
                WHEN 'DL01' THEN p.`B04_A02`
                WHEN 'DL05' THEN p.`B04_A07`
                WHEN 'DL08' THEN p.`B04_A05`
                WHEN 'KH04' THEN p.`B05_D02`
                WHEN 'NT02' THEN p.`B04_C03`
                WHEN 'NT10' THEN p.`B09_A10`
                WHEN 'NT12' THEN p.`B09_B03`
                WHEN 'NT13' THEN p.`B09_B04`
                WHEN 'TC03' THEN (CASE WHEN COALESCE(p.`B03_A_DT_PHANBO`, p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_PHANBO`,0) + IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END)
                WHEN 'TC04' THEN p.`B03_A_DT_PHANBO`
                WHEN 'TC05' THEN (CASE WHEN COALESCE(p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END)
                WHEN 'TC06' THEN p.`B03_A_TX_TINH_GN_LK`
                WHEN 'TC07' THEN p.`B03_A_TX_XA_GN_LK`
                WHEN 'TC08' THEN p.`B03_A_DT_GN_LK`
                WHEN 'TC09' THEN p.`TH00_28`
                WHEN 'TC13' THEN (CASE WHEN COALESCE(p.`B03_A_DT_GN_LK`, p.`B03_A_TX_TINH_GN_LK`, p.`B03_A_TX_XA_GN_LK`, p.`B03_A_CN_GN_LK`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_GN_LK`,0) + IFNULL(p.`B03_A_TX_TINH_GN_LK`,0) + IFNULL(p.`B03_A_TX_XA_GN_LK`,0) + IFNULL(p.`B03_A_CN_GN_LK`,0) END)
                WHEN 'TT06' THEN p.`B06_B02`
                WHEN 'TT08' THEN p.`B06_B08`
                WHEN 'TT14' THEN p.`B06_B09`
                WHEN 'TT16' THEN p.`B06_D02`
           END AS tu_so,
           CASE mp.ma
                WHEN 'AT02' THEN p.`B08_A01`
                WHEN 'AT09' THEN p.`B08_A13`
                WHEN 'CS07' THEN p.`TH05_XA_SO`
                WHEN 'CS08' THEN p.`TH05_XA_SO`
                WHEN 'CS09' THEN p.`TH05_XA_SO`
                WHEN 'CS17' THEN 126
                WHEN 'DD05' THEN p.`B07_A01`
                WHEN 'DL01' THEN p.`B04_A01`
                WHEN 'DL08' THEN p.`B04_A01`
                WHEN 'KH04' THEN p.`B05_D01`
                WHEN 'NT02' THEN p.`B04_C02`
                WHEN 'NT10' THEN p.`B09_A09`
                WHEN 'NT12' THEN p.`B09_B02`
                WHEN 'NT13' THEN p.`B09_B02`
                WHEN 'TC03' THEN p.`TH00_27`
                WHEN 'TC04' THEN p.`B03_A_DT_DUTOAN`
                WHEN 'TC05' THEN (CASE WHEN COALESCE(p.`B03_A_TX_TINH_DUTOAN`, p.`B03_A_TX_XA_DUTOAN`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_TX_TINH_DUTOAN`,0) + IFNULL(p.`B03_A_TX_XA_DUTOAN`,0) END)
                WHEN 'TC06' THEN p.`B03_A_TX_TINH_DUTOAN`
                WHEN 'TC07' THEN p.`B03_A_TX_XA_DUTOAN`
                WHEN 'TC08' THEN p.`B03_A_DT_DUTOAN`
                WHEN 'TC09' THEN p.`TH00_27`
                WHEN 'TC13' THEN (CASE WHEN COALESCE(p.`B03_A_DT_DUTOAN`, p.`B03_A_TX_TINH_DUTOAN`, p.`B03_A_TX_XA_DUTOAN`, p.`B03_A_CN_DUTOAN`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_DUTOAN`,0) + IFNULL(p.`B03_A_TX_TINH_DUTOAN`,0) + IFNULL(p.`B03_A_TX_XA_DUTOAN`,0) + IFNULL(p.`B03_A_CN_DUTOAN`,0) END)
                WHEN 'TT06' THEN p.`B06_B01`
                WHEN 'TT08' THEN p.`B06_B07`
                WHEN 'TT14' THEN p.`B06_B07`
                WHEN 'TT16' THEN p.`B06_D01`
           END AS mau_so,
           CASE mp.ma
                WHEN 'AT01' THEN p.`B08_A02`
                WHEN 'AT02' THEN p.`B08_A02` / NULLIF(p.`B08_A01`, 0)
                WHEN 'AT03' THEN p.`B08_A03`
                WHEN 'AT04' THEN p.`B08_A04`
                WHEN 'AT05' THEN p.`B08_A11`
                WHEN 'AT06' THEN p.`B08_A12`
                WHEN 'AT07' THEN p.`B08_A08`
                WHEN 'AT08' THEN p.`B08_A07`
                WHEN 'AT09' THEN p.`B08_A14` / NULLIF(p.`B08_A13`, 0)
                WHEN 'CS07' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_MOHINH`, NULL) / NULLIF(p.`TH05_XA_SO`, 0)
                WHEN 'CS08' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_DULIEU`, NULL) / NULLIF(p.`TH05_XA_SO`, 0)
                WHEN 'CS09' THEN IF(p.`TH05_XA_SO` > 0, p.`TH05_XA_DVC`, NULL) / NULLIF(p.`TH05_XA_SO`, 0)
                WHEN 'CS15' THEN p.`B01_C01`
                WHEN 'CS16' THEN p.`B01_C02`
                WHEN 'CS17' THEN p.`B10_A03` / NULLIF(126, 0)
                WHEN 'CS18' THEN p.`B10_A04`
                WHEN 'DD01' THEN p.`B07_A01`
                WHEN 'DD04' THEN p.`B07_A03`
                WHEN 'DD05' THEN p.`B07_A03` / NULLIF(p.`B07_A01`, 0)
                WHEN 'DL01' THEN p.`B04_A02` / NULLIF(p.`B04_A01`, 0)
                WHEN 'DL05' THEN NULL
                WHEN 'DL06' THEN p.`B04_A06`
                WHEN 'DL08' THEN p.`B04_A05` / NULLIF(p.`B04_A01`, 0)
                WHEN 'DL09' THEN p.`B04_A10`
                WHEN 'KH01' THEN p.`B11_A01` * 0.01
                WHEN 'KH02' THEN p.`B11_A02` * 0.01
                WHEN 'KH03' THEN p.`B11_A03` * 0.01
                WHEN 'KH04' THEN p.`B05_D02` / NULLIF(p.`B05_D01`, 0)
                WHEN 'KH06' THEN p.`B05_B_DEXUAT_LK`
                WHEN 'KH07' THEN p.`B05_B_DATHANG_LK`
                WHEN 'KH08' THEN p.`B05_B_BTUT_LK`
                WHEN 'KH09' THEN p.`B05_E_CHUYENGIA_LK`
                WHEN 'KH10' THEN p.`B05_E_TEX_TK_LK`
                WHEN 'KH11' THEN p.`B05_E_TEX_DN_LK`
                WHEN 'KH12' THEN p.`B05_E_TEX_GP_LK`
                WHEN 'KH14' THEN p.`B05_E_DNKHCN_LK`
                WHEN 'KH15' THEN p.`B05_E_SB_DX_LK`
                WHEN 'NT01' THEN p.`B04_C03`
                WHEN 'NT02' THEN p.`B04_C03` / NULLIF(p.`B04_C02`, 0)
                WHEN 'NT03' THEN p.`B04_C01`
                WHEN 'NT04' THEN p.`B04_C05`
                WHEN 'NT05' THEN p.`B04_C10`
                WHEN 'NT07' THEN p.`B04_C12`
                WHEN 'NT08' THEN p.`B09_A01`
                WHEN 'NT09' THEN p.`B09_A03`
                WHEN 'NT10' THEN p.`B09_A10` / NULLIF(p.`B09_A09`, 0)
                WHEN 'NT11' THEN p.`B09_B01`
                WHEN 'NT12' THEN p.`B09_B03` / NULLIF(p.`B09_B02`, 0)
                WHEN 'NT13' THEN p.`B09_B04` / NULLIF(p.`B09_B02`, 0)
                WHEN 'NT14' THEN p.`B09_B05`
                WHEN 'NT15' THEN p.`B09_B07`
                WHEN 'TC01' THEN p.`TH00_27`
                WHEN 'TC02' THEN (CASE WHEN COALESCE(p.`B03_A_DT_PHANBO`, p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_PHANBO`,0) + IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END)
                WHEN 'TC03' THEN (CASE WHEN COALESCE(p.`B03_A_DT_PHANBO`, p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_PHANBO`,0) + IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END) / NULLIF(p.`TH00_27`, 0)
                WHEN 'TC04' THEN p.`B03_A_DT_PHANBO` / NULLIF(p.`B03_A_DT_DUTOAN`, 0)
                WHEN 'TC05' THEN (CASE WHEN COALESCE(p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END) / NULLIF((CASE WHEN COALESCE(p.`B03_A_TX_TINH_DUTOAN`, p.`B03_A_TX_XA_DUTOAN`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_TX_TINH_DUTOAN`,0) + IFNULL(p.`B03_A_TX_XA_DUTOAN`,0) END), 0)
                WHEN 'TC06' THEN p.`B03_A_TX_TINH_GN_LK` / NULLIF(p.`B03_A_TX_TINH_DUTOAN`, 0)
                WHEN 'TC07' THEN p.`B03_A_TX_XA_GN_LK` / NULLIF(p.`B03_A_TX_XA_DUTOAN`, 0)
                WHEN 'TC08' THEN p.`B03_A_DT_GN_LK` / NULLIF(p.`B03_A_DT_DUTOAN`, 0)
                WHEN 'TC09' THEN p.`TH00_28` / NULLIF(p.`TH00_27`, 0)
                WHEN 'TC10' THEN p.`B03_B01`
                WHEN 'TC11' THEN p.`B03_B02`
                WHEN 'TC12' THEN (p.`TH00_27` - (CASE WHEN COALESCE(p.`B03_A_DT_PHANBO`, p.`B03_A_TX_TINH_PHANBO`, p.`B03_A_TX_XA_PHANBO`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_PHANBO`,0) + IFNULL(p.`B03_A_TX_TINH_PHANBO`,0) + IFNULL(p.`B03_A_TX_XA_PHANBO`,0) END))
                WHEN 'TC13' THEN (CASE WHEN COALESCE(p.`B03_A_DT_GN_LK`, p.`B03_A_TX_TINH_GN_LK`, p.`B03_A_TX_XA_GN_LK`, p.`B03_A_CN_GN_LK`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_GN_LK`,0) + IFNULL(p.`B03_A_TX_TINH_GN_LK`,0) + IFNULL(p.`B03_A_TX_XA_GN_LK`,0) + IFNULL(p.`B03_A_CN_GN_LK`,0) END) / NULLIF((CASE WHEN COALESCE(p.`B03_A_DT_DUTOAN`, p.`B03_A_TX_TINH_DUTOAN`, p.`B03_A_TX_XA_DUTOAN`, p.`B03_A_CN_DUTOAN`) IS NULL THEN NULL ELSE IFNULL(p.`B03_A_DT_DUTOAN`,0) + IFNULL(p.`B03_A_TX_TINH_DUTOAN`,0) + IFNULL(p.`B03_A_TX_XA_DUTOAN`,0) + IFNULL(p.`B03_A_CN_DUTOAN`,0) END), 0)
                WHEN 'TT05' THEN p.`B06_B02`
                WHEN 'TT06' THEN p.`B06_B02` / NULLIF(p.`B06_B01`, 0)
                WHEN 'TT07' THEN p.`B06_B05`
                WHEN 'TT08' THEN p.`B06_B08` / NULLIF(p.`B06_B07`, 0)
                WHEN 'TT10' THEN p.`B06_A_766`
                WHEN 'TT12' THEN p.`B06_A_DATLICH`
                WHEN 'TT13' THEN p.`B06_A_TGPV`
                WHEN 'TT14' THEN p.`B06_B09` / NULLIF(p.`B06_B07`, 0)
                WHEN 'TT15' THEN p.`B06_D01`
                WHEN 'TT16' THEN p.`B06_D02` / NULLIF(p.`B06_D01`, 0)
                WHEN 'TT17' THEN p.`B04_F01`
           END AS gia_tri
    FROM (
        SELECT b.ky,
            MAX(IF(b.m = 'B01_C01', b.v, NULL)) AS `B01_C01`,
            MAX(IF(b.m = 'B01_C02', b.v, NULL)) AS `B01_C02`,
            MAX(IF(b.m = 'B03_A_CN_DUTOAN', b.v, NULL)) AS `B03_A_CN_DUTOAN`,
            MAX(IF(b.m = 'B03_A_CN_GN_LK', b.v, NULL)) AS `B03_A_CN_GN_LK`,
            MAX(IF(b.m = 'B03_A_DT_DUTOAN', b.v, NULL)) AS `B03_A_DT_DUTOAN`,
            MAX(IF(b.m = 'B03_A_DT_GN_LK', b.v, NULL)) AS `B03_A_DT_GN_LK`,
            MAX(IF(b.m = 'B03_A_DT_PHANBO', b.v, NULL)) AS `B03_A_DT_PHANBO`,
            MAX(IF(b.m = 'B03_A_TX_TINH_DUTOAN', b.v, NULL)) AS `B03_A_TX_TINH_DUTOAN`,
            MAX(IF(b.m = 'B03_A_TX_TINH_GN_LK', b.v, NULL)) AS `B03_A_TX_TINH_GN_LK`,
            MAX(IF(b.m = 'B03_A_TX_TINH_PHANBO', b.v, NULL)) AS `B03_A_TX_TINH_PHANBO`,
            MAX(IF(b.m = 'B03_A_TX_XA_DUTOAN', b.v, NULL)) AS `B03_A_TX_XA_DUTOAN`,
            MAX(IF(b.m = 'B03_A_TX_XA_GN_LK', b.v, NULL)) AS `B03_A_TX_XA_GN_LK`,
            MAX(IF(b.m = 'B03_A_TX_XA_PHANBO', b.v, NULL)) AS `B03_A_TX_XA_PHANBO`,
            MAX(IF(b.m = 'B03_B01', b.v, NULL)) AS `B03_B01`,
            MAX(IF(b.m = 'B03_B02', b.v, NULL)) AS `B03_B02`,
            MAX(IF(b.m = 'B04_A01', b.v, NULL)) AS `B04_A01`,
            MAX(IF(b.m = 'B04_A02', b.v, NULL)) AS `B04_A02`,
            MAX(IF(b.m = 'B04_A05', b.v, NULL)) AS `B04_A05`,
            MAX(IF(b.m = 'B04_A06', b.v, NULL)) AS `B04_A06`,
            MAX(IF(b.m = 'B04_A07', b.v, NULL)) AS `B04_A07`,
            MAX(IF(b.m = 'B04_A10', b.v, NULL)) AS `B04_A10`,
            MAX(IF(b.m = 'B04_C01', b.v, NULL)) AS `B04_C01`,
            MAX(IF(b.m = 'B04_C02', b.v, NULL)) AS `B04_C02`,
            MAX(IF(b.m = 'B04_C03', b.v, NULL)) AS `B04_C03`,
            MAX(IF(b.m = 'B04_C05', b.v, NULL)) AS `B04_C05`,
            MAX(IF(b.m = 'B04_C10', b.v, NULL)) AS `B04_C10`,
            MAX(IF(b.m = 'B04_C12', b.v, NULL)) AS `B04_C12`,
            MAX(IF(b.m = 'B04_F01', b.v, NULL)) AS `B04_F01`,
            MAX(IF(b.m = 'B05_B_BTUT_LK', b.v, NULL)) AS `B05_B_BTUT_LK`,
            MAX(IF(b.m = 'B05_B_DATHANG_LK', b.v, NULL)) AS `B05_B_DATHANG_LK`,
            MAX(IF(b.m = 'B05_B_DEXUAT_LK', b.v, NULL)) AS `B05_B_DEXUAT_LK`,
            MAX(IF(b.m = 'B05_D01', b.v, NULL)) AS `B05_D01`,
            MAX(IF(b.m = 'B05_D02', b.v, NULL)) AS `B05_D02`,
            MAX(IF(b.m = 'B05_E_CHUYENGIA_LK', b.v, NULL)) AS `B05_E_CHUYENGIA_LK`,
            MAX(IF(b.m = 'B05_E_DNKHCN_LK', b.v, NULL)) AS `B05_E_DNKHCN_LK`,
            MAX(IF(b.m = 'B05_E_SB_DX_LK', b.v, NULL)) AS `B05_E_SB_DX_LK`,
            MAX(IF(b.m = 'B05_E_TEX_DN_LK', b.v, NULL)) AS `B05_E_TEX_DN_LK`,
            MAX(IF(b.m = 'B05_E_TEX_GP_LK', b.v, NULL)) AS `B05_E_TEX_GP_LK`,
            MAX(IF(b.m = 'B05_E_TEX_TK_LK', b.v, NULL)) AS `B05_E_TEX_TK_LK`,
            MAX(IF(b.m = 'B06_A_766', b.v, NULL)) AS `B06_A_766`,
            MAX(IF(b.m = 'B06_A_DATLICH', b.v, NULL)) AS `B06_A_DATLICH`,
            MAX(IF(b.m = 'B06_A_TGPV', b.v, NULL)) AS `B06_A_TGPV`,
            MAX(IF(b.m = 'B06_B01', b.v, NULL)) AS `B06_B01`,
            MAX(IF(b.m = 'B06_B02', b.v, NULL)) AS `B06_B02`,
            MAX(IF(b.m = 'B06_B05', b.v, NULL)) AS `B06_B05`,
            MAX(IF(b.m = 'B06_B07', b.v, NULL)) AS `B06_B07`,
            MAX(IF(b.m = 'B06_B08', b.v, NULL)) AS `B06_B08`,
            MAX(IF(b.m = 'B06_B09', b.v, NULL)) AS `B06_B09`,
            MAX(IF(b.m = 'B06_D01', b.v, NULL)) AS `B06_D01`,
            MAX(IF(b.m = 'B06_D02', b.v, NULL)) AS `B06_D02`,
            MAX(IF(b.m = 'B07_A01', b.v, NULL)) AS `B07_A01`,
            MAX(IF(b.m = 'B07_A03', b.v, NULL)) AS `B07_A03`,
            MAX(IF(b.m = 'B08_A01', b.v, NULL)) AS `B08_A01`,
            MAX(IF(b.m = 'B08_A02', b.v, NULL)) AS `B08_A02`,
            MAX(IF(b.m = 'B08_A03', b.v, NULL)) AS `B08_A03`,
            MAX(IF(b.m = 'B08_A04', b.v, NULL)) AS `B08_A04`,
            MAX(IF(b.m = 'B08_A07', b.v, NULL)) AS `B08_A07`,
            MAX(IF(b.m = 'B08_A08', b.v, NULL)) AS `B08_A08`,
            MAX(IF(b.m = 'B08_A11', b.v, NULL)) AS `B08_A11`,
            MAX(IF(b.m = 'B08_A12', b.v, NULL)) AS `B08_A12`,
            MAX(IF(b.m = 'B08_A13', b.v, NULL)) AS `B08_A13`,
            MAX(IF(b.m = 'B08_A14', b.v, NULL)) AS `B08_A14`,
            MAX(IF(b.m = 'B09_A01', b.v, NULL)) AS `B09_A01`,
            MAX(IF(b.m = 'B09_A03', b.v, NULL)) AS `B09_A03`,
            MAX(IF(b.m = 'B09_A09', b.v, NULL)) AS `B09_A09`,
            MAX(IF(b.m = 'B09_A10', b.v, NULL)) AS `B09_A10`,
            MAX(IF(b.m = 'B09_B01', b.v, NULL)) AS `B09_B01`,
            MAX(IF(b.m = 'B09_B02', b.v, NULL)) AS `B09_B02`,
            MAX(IF(b.m = 'B09_B03', b.v, NULL)) AS `B09_B03`,
            MAX(IF(b.m = 'B09_B04', b.v, NULL)) AS `B09_B04`,
            MAX(IF(b.m = 'B09_B05', b.v, NULL)) AS `B09_B05`,
            MAX(IF(b.m = 'B09_B07', b.v, NULL)) AS `B09_B07`,
            MAX(IF(b.m = 'B10_A03', b.v, NULL)) AS `B10_A03`,
            MAX(IF(b.m = 'B10_A04', b.v, NULL)) AS `B10_A04`,
            MAX(IF(b.m = 'B11_A01', b.v, NULL)) AS `B11_A01`,
            MAX(IF(b.m = 'B11_A02', b.v, NULL)) AS `B11_A02`,
            MAX(IF(b.m = 'B11_A03', b.v, NULL)) AS `B11_A03`,
            MAX(IF(b.m = 'TH00_27', b.v, NULL)) AS `TH00_27`,
            MAX(IF(b.m = 'TH00_28', b.v, NULL)) AS `TH00_28`,
            MAX(IF(b.m = 'TH05_XA_DULIEU', b.v, NULL)) AS `TH05_XA_DULIEU`,
            MAX(IF(b.m = 'TH05_XA_DVC', b.v, NULL)) AS `TH05_XA_DVC`,
            MAX(IF(b.m = 'TH05_XA_MOHINH', b.v, NULL)) AS `TH05_XA_MOHINH`,
            MAX(IF(b.m = 'TH05_XA_SO', b.v, NULL)) AS `TH05_XA_SO`
        FROM (
            SELECT ma_chi_tieu AS m, ky,
                   COALESCE(MAX(IF(ma_bieu LIKE 'NQ57HN-TH%', gia_tri, NULL)),
                            SUM(IF(ma_bieu LIKE 'NQ57HN-TH%', NULL, gia_tri))) AS v
            FROM datamart_hanoi.v_nq57_solieu
            WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL
            GROUP BY ma_chi_tieu, ky
        ) b
        GROUP BY b.ky
    ) p
    CROSS JOIN (SELECT 'AT01' AS ma UNION ALL SELECT 'AT02' AS ma UNION ALL SELECT 'AT03' AS ma UNION ALL SELECT 'AT04' AS ma UNION ALL SELECT 'AT05' AS ma UNION ALL SELECT 'AT06' AS ma UNION ALL SELECT 'AT07' AS ma UNION ALL SELECT 'AT08' AS ma UNION ALL SELECT 'AT09' AS ma UNION ALL SELECT 'CS07' AS ma UNION ALL SELECT 'CS08' AS ma UNION ALL SELECT 'CS09' AS ma UNION ALL SELECT 'CS15' AS ma UNION ALL SELECT 'CS16' AS ma UNION ALL SELECT 'CS17' AS ma UNION ALL SELECT 'CS18' AS ma UNION ALL SELECT 'DD01' AS ma UNION ALL SELECT 'DD04' AS ma UNION ALL SELECT 'DD05' AS ma UNION ALL SELECT 'DL01' AS ma UNION ALL SELECT 'DL05' AS ma UNION ALL SELECT 'DL06' AS ma UNION ALL SELECT 'DL08' AS ma UNION ALL SELECT 'DL09' AS ma UNION ALL SELECT 'KH01' AS ma UNION ALL SELECT 'KH02' AS ma UNION ALL SELECT 'KH03' AS ma UNION ALL SELECT 'KH04' AS ma UNION ALL SELECT 'KH06' AS ma UNION ALL SELECT 'KH07' AS ma UNION ALL SELECT 'KH08' AS ma UNION ALL SELECT 'KH09' AS ma UNION ALL SELECT 'KH10' AS ma UNION ALL SELECT 'KH11' AS ma UNION ALL SELECT 'KH12' AS ma UNION ALL SELECT 'KH14' AS ma UNION ALL SELECT 'KH15' AS ma UNION ALL SELECT 'NT01' AS ma UNION ALL SELECT 'NT02' AS ma UNION ALL SELECT 'NT03' AS ma UNION ALL SELECT 'NT04' AS ma UNION ALL SELECT 'NT05' AS ma UNION ALL SELECT 'NT07' AS ma UNION ALL SELECT 'NT08' AS ma UNION ALL SELECT 'NT09' AS ma UNION ALL SELECT 'NT10' AS ma UNION ALL SELECT 'NT11' AS ma UNION ALL SELECT 'NT12' AS ma UNION ALL SELECT 'NT13' AS ma UNION ALL SELECT 'NT14' AS ma UNION ALL SELECT 'NT15' AS ma UNION ALL SELECT 'TC01' AS ma UNION ALL SELECT 'TC02' AS ma UNION ALL SELECT 'TC03' AS ma UNION ALL SELECT 'TC04' AS ma UNION ALL SELECT 'TC05' AS ma UNION ALL SELECT 'TC06' AS ma UNION ALL SELECT 'TC07' AS ma UNION ALL SELECT 'TC08' AS ma UNION ALL SELECT 'TC09' AS ma UNION ALL SELECT 'TC10' AS ma UNION ALL SELECT 'TC11' AS ma UNION ALL SELECT 'TC12' AS ma UNION ALL SELECT 'TC13' AS ma UNION ALL SELECT 'TT05' AS ma UNION ALL SELECT 'TT06' AS ma UNION ALL SELECT 'TT07' AS ma UNION ALL SELECT 'TT08' AS ma UNION ALL SELECT 'TT10' AS ma UNION ALL SELECT 'TT12' AS ma UNION ALL SELECT 'TT13' AS ma UNION ALL SELECT 'TT14' AS ma UNION ALL SELECT 'TT15' AS ma UNION ALL SELECT 'TT16' AS ma UNION ALL SELECT 'TT17' AS ma) mp
) x ON x.ma = dm.ma_chi_so AND x.ky = k.ky_nq57
