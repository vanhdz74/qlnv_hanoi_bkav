/* Nạp danh mục chỉ số + ánh xạ. Danh mục (tên, chuyên đề, ngưỡng, đầu mối…) chép từ các dòng CHI_SO của bảng nhập tay.
   Chạy lại được (upsert). 116 chỉ số có ánh xạ; còn lại cach_tinh = KHONG_CO. */
INSERT INTO `datamart_hanoi`.`nq57_chi_so_anh_xa`
    (ma_chi_so, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so,
     giam_la_tot, nguong, ten_nguong, dau_moi, luu_y,
     cach_tinh, tu_ma, mau_ma, mau_hang_so, he_so, can_ty_le, chi_khi_mau_duong, mo_ta_nguon, ghi_chu, cap_nhat)
SELECT dm.ma_chi_so, dm.thu_tu_chi_so, dm.stt_chuyen_de, dm.chuyen_de, dm.ten_chi_so, dm.ten_ngan, dm.don_vi_tinh,
       dm.loai_chi_so, dm.giam_la_tot, dm.nguong, dm.ten_nguong, dm.dau_moi, dm.luu_y,
       IF(mp.ma IS NULL, 'KHONG_CO', 'TONG'), mp.tu, mp.mau, mp.mau_hs, COALESCE(mp.hs, 1),
       COALESCE(mp.can, 0), COALESCE(mp.duong, 0),
       COALESCE(mp.mo_ta, 'Chưa có chỉ tiêu tương ứng trong NQ57'), NULL, NOW()
FROM (
    SELECT ma_chi_so,
           MAX(thu_tu_chi_so) thu_tu_chi_so, MAX(stt_chuyen_de) stt_chuyen_de, MAX(chuyen_de) chuyen_de,
           MAX(ten_chi_so) ten_chi_so, MAX(ten_ngan) ten_ngan, MAX(don_vi_tinh) don_vi_tinh, MAX(loai_chi_so) loai_chi_so,
           MAX(giam_la_tot) giam_la_tot, MAX(nguong) nguong, MAX(ten_nguong) ten_nguong, MAX(dau_moi) dau_moi, MAX(luu_y) luu_y
    FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nq57`
    WHERE nhom_du_lieu = 'CHI_SO'
    GROUP BY ma_chi_so
) dm
LEFT JOIN (
    SELECT 'AT01' ma, 'B08_A02' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A02' mo_ta
    UNION ALL SELECT 'AT02' ma, 'B08_A02' tu, 'B08_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A02 / B08_A01' mo_ta
    UNION ALL SELECT 'AT03' ma, 'B08_A03' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A03' mo_ta
    UNION ALL SELECT 'AT04' ma, 'B08_A04' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A04' mo_ta
    UNION ALL SELECT 'AT05' ma, 'B08_A11' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A11' mo_ta
    UNION ALL SELECT 'AT06' ma, 'B08_A12' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A12' mo_ta
    UNION ALL SELECT 'AT07' ma, 'B08_A08' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A08' mo_ta
    UNION ALL SELECT 'AT08' ma, 'B08_A07' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A07' mo_ta
    UNION ALL SELECT 'AT09' ma, 'B08_A14' tu, 'B08_A13' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B08_A14 / B08_A13' mo_ta
    UNION ALL SELECT 'BS01' ma, 'B09_A04' tu, 'B09_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A04 / B09_A01' mo_ta
    UNION ALL SELECT 'BS02' ma, 'B09_A06' tu, 'B09_A05' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A06 / B09_A05' mo_ta
    UNION ALL SELECT 'BS03' ma, 'B09_A07' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A07' mo_ta
    UNION ALL SELECT 'BS04' ma, 'B04_C04' tu, 'B04_C03' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C04 / B04_C03' mo_ta
    UNION ALL SELECT 'BS05' ma, 'B04_C06' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C06' mo_ta
    UNION ALL SELECT 'BS06' ma, 'B04_C08' tu, 'B04_C07' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C08 / B04_C07' mo_ta
    UNION ALL SELECT 'BS07' ma, 'B06_A_HS_TOANTRINH_TINH,B06_A_HS_TOANTRINH_XA' tu, 'B06_A_HS_NHAN_TINH,B06_A_HS_NHAN_XA' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_HS_TOANTRINH_TINH + B06_A_HS_TOANTRINH_XA / B06_A_HS_NHAN_TINH + B06_A_HS_NHAN_XA' mo_ta
    UNION ALL SELECT 'BS08' ma, 'B06_B06' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_B06' mo_ta
    UNION ALL SELECT 'BS09' ma, 'B06_A_HS_TAISD_TINH,B06_A_HS_TAISD_XA' tu, 'B06_A_HS_NHAN_TINH,B06_A_HS_NHAN_XA' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_HS_TAISD_TINH + B06_A_HS_TAISD_XA / B06_A_HS_NHAN_TINH + B06_A_HS_NHAN_XA' mo_ta
    UNION ALL SELECT 'BS10' ma, 'B04_A03' tu, 'B04_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A03 / B04_A01' mo_ta
    UNION ALL SELECT 'BS13' ma, 'B02_B05' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B02_B05' mo_ta
    UNION ALL SELECT 'BS14' ma, 'B05_E_TEX_HD_LK,B05_E_CHO_GD_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_TEX_HD_LK + B05_E_CHO_GD_LK' mo_ta
    UNION ALL SELECT 'BS15' ma, 'B02_B04' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B02_B04' mo_ta
    UNION ALL SELECT 'BS16' ma, 'B11_A01' tu, NULL mau, NULL mau_hs, 0.01 hs, 0 can, 0 duong, 'NQ57: B11_A01' mo_ta
    UNION ALL SELECT 'BS17' ma, 'B12_B_THIEUNL_SO,B12_B_THIEUKN_SO,B12_B_THIEUKT_SO' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B12_B_THIEUNL_SO + B12_B_THIEUKN_SO + B12_B_THIEUKT_SO' mo_ta
    UNION ALL SELECT 'BS18' ma, 'B01_E02,B02_C02' tu, 'B01_E01,B02_C01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B01_E02 + B02_C02 / B01_E01 + B02_C01' mo_ta
    UNION ALL SELECT 'CS01' ma, 'XA_TT_GE90' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_TT_GE90 / 126' mo_ta
    UNION ALL SELECT 'CS02' ma, 'XA_TT_100' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_TT_100 / 126' mo_ta
    UNION ALL SELECT 'CS03' ma, 'XA_TT_LT50' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_TT_LT50' mo_ta
    UNION ALL SELECT 'CS04' ma, 'B04_D_MAYTINH_TONG,-B04_D_MAYTINH_CONLAI' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_D_MAYTINH_TONG − B04_D_MAYTINH_CONLAI' mo_ta
    UNION ALL SELECT 'CS05' ma, 'B04_D_PHONGHOP_TONG,-B04_D_PHONGHOP_CONLAI' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_D_PHONGHOP_TONG − B04_D_PHONGHOP_CONLAI' mo_ta
    UNION ALL SELECT 'CS06' ma, 'B04_D_CKS_TONG,-B04_D_CKS_CONLAI' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_D_CKS_TONG − B04_D_CKS_CONLAI' mo_ta
    UNION ALL SELECT 'CS07' ma, 'XA_A01_CO' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_A01_CO / 126' mo_ta
    UNION ALL SELECT 'CS08' ma, 'XA_A03_CO' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_A03_CO / 126' mo_ta
    UNION ALL SELECT 'CS09' ma, 'XA_A05_CO' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: XA_A05_CO / 126' mo_ta
    UNION ALL SELECT 'CS15' ma, 'B01_C01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B01_C01' mo_ta
    UNION ALL SELECT 'CS16' ma, 'B01_C02' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B01_C02' mo_ta
    UNION ALL SELECT 'CS17' ma, 'B10_A03' tu, NULL mau, 126 mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B10_A03 / 126' mo_ta
    UNION ALL SELECT 'CS18' ma, 'B10_A04' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B10_A04' mo_ta
    UNION ALL SELECT 'DD01' ma, 'B07_A01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A01' mo_ta
    UNION ALL SELECT 'DD02' ma, 'B07_A02' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A02' mo_ta
    UNION ALL SELECT 'DD03' ma, 'B07_A02' tu, 'B07_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A02 / B07_A01' mo_ta
    UNION ALL SELECT 'DD04' ma, 'B07_A03' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A03' mo_ta
    UNION ALL SELECT 'DD05' ma, 'B07_A03' tu, 'B07_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A03 / B07_A01' mo_ta
    UNION ALL SELECT 'DD06' ma, 'B07_A03' tu, 'B07_A02' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A03 / B07_A02' mo_ta
    UNION ALL SELECT 'DD07' ma, 'B07_A06' tu, 'B07_A05' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A06 / B07_A05' mo_ta
    UNION ALL SELECT 'DD08' ma, 'B07_A09' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A09' mo_ta
    UNION ALL SELECT 'DD09' ma, 'B07_A10' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B07_A10' mo_ta
    UNION ALL SELECT 'DL01' ma, 'B04_A02' tu, 'B04_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A02 / B04_A01' mo_ta
    UNION ALL SELECT 'DL04' ma, 'B04_A08' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A08' mo_ta
    UNION ALL SELECT 'DL05' ma, 'B04_A07' tu, NULL mau, NULL mau_hs, 1 hs, 1 can, 0 duong, 'NQ57: B04_A07' mo_ta
    UNION ALL SELECT 'DL06' ma, 'B04_A06' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A06' mo_ta
    UNION ALL SELECT 'DL07' ma, 'B04_A04' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A04' mo_ta
    UNION ALL SELECT 'DL08' ma, 'B04_A05' tu, 'B04_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A05 / B04_A01' mo_ta
    UNION ALL SELECT 'DL09' ma, 'B04_A10' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_A10' mo_ta
    UNION ALL SELECT 'KH01' ma, 'B11_A01' tu, NULL mau, NULL mau_hs, 0.01 hs, 0 can, 0 duong, 'NQ57: B11_A01' mo_ta
    UNION ALL SELECT 'KH02' ma, 'B11_A02' tu, NULL mau, NULL mau_hs, 0.01 hs, 0 can, 0 duong, 'NQ57: B11_A02' mo_ta
    UNION ALL SELECT 'KH03' ma, 'B11_A03' tu, NULL mau, NULL mau_hs, 0.01 hs, 0 can, 0 duong, 'NQ57: B11_A03' mo_ta
    UNION ALL SELECT 'KH04' ma, 'B05_D02' tu, 'B05_D01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_D02 / B05_D01' mo_ta
    UNION ALL SELECT 'KH05' ma, 'B05_D04' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_D04' mo_ta
    UNION ALL SELECT 'KH06' ma, 'B05_B_DEXUAT_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_B_DEXUAT_LK' mo_ta
    UNION ALL SELECT 'KH07' ma, 'B05_B_DATHANG_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_B_DATHANG_LK' mo_ta
    UNION ALL SELECT 'KH08' ma, 'B05_B_BTUT_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_B_BTUT_LK' mo_ta
    UNION ALL SELECT 'KH09' ma, 'B05_E_CHUYENGIA_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_CHUYENGIA_LK' mo_ta
    UNION ALL SELECT 'KH10' ma, 'B05_E_TEX_TK_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_TEX_TK_LK' mo_ta
    UNION ALL SELECT 'KH11' ma, 'B05_E_TEX_DN_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_TEX_DN_LK' mo_ta
    UNION ALL SELECT 'KH12' ma, 'B05_E_TEX_GP_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_TEX_GP_LK' mo_ta
    UNION ALL SELECT 'KH13' ma, 'B05_E_TEX_HD_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_TEX_HD_LK' mo_ta
    UNION ALL SELECT 'KH14' ma, 'B05_E_DNKHCN_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_DNKHCN_LK' mo_ta
    UNION ALL SELECT 'KH15' ma, 'B05_E_SB_DX_LK' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B05_E_SB_DX_LK' mo_ta
    UNION ALL SELECT 'NT01' ma, 'B04_C03' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C03' mo_ta
    UNION ALL SELECT 'NT02' ma, 'B04_C03' tu, 'B04_C02' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C03 / B04_C02' mo_ta
    UNION ALL SELECT 'NT03' ma, 'B04_C01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C01' mo_ta
    UNION ALL SELECT 'NT04' ma, 'B04_C05' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C05' mo_ta
    UNION ALL SELECT 'NT05' ma, 'B04_C10' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C10' mo_ta
    UNION ALL SELECT 'NT06' ma, 'B04_C11' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C11' mo_ta
    UNION ALL SELECT 'NT07' ma, 'B04_C12' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_C12' mo_ta
    UNION ALL SELECT 'NT08' ma, 'B09_A01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A01' mo_ta
    UNION ALL SELECT 'NT09' ma, 'B09_A03' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A03' mo_ta
    UNION ALL SELECT 'NT10' ma, 'B09_A10' tu, 'B09_A09' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_A10 / B09_A09' mo_ta
    UNION ALL SELECT 'NT11' ma, 'B09_B01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_B01' mo_ta
    UNION ALL SELECT 'NT12' ma, 'B09_B03' tu, 'B09_B02' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_B03 / B09_B02' mo_ta
    UNION ALL SELECT 'NT13' ma, 'B09_B04' tu, 'B09_B02' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_B04 / B09_B02' mo_ta
    UNION ALL SELECT 'NT14' ma, 'B09_B05' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_B05' mo_ta
    UNION ALL SELECT 'NT15' ma, 'B09_B07' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B09_B07' mo_ta
    UNION ALL SELECT 'NT16' ma, 'B10_A02' tu, 'B10_A01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B10_A02 / B10_A01' mo_ta
    UNION ALL SELECT 'TC01' ma, 'TH00_27' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: TH00_27' mo_ta
    UNION ALL SELECT 'TC02' ma, 'B03_A_DT_PHANBO,B03_A_TX_TINH_PHANBO,B03_A_TX_XA_PHANBO' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_DT_PHANBO + B03_A_TX_TINH_PHANBO + B03_A_TX_XA_PHANBO' mo_ta
    UNION ALL SELECT 'TC03' ma, 'B03_A_DT_PHANBO,B03_A_TX_TINH_PHANBO,B03_A_TX_XA_PHANBO' tu, 'TH00_27' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_DT_PHANBO + B03_A_TX_TINH_PHANBO + B03_A_TX_XA_PHANBO / TH00_27' mo_ta
    UNION ALL SELECT 'TC04' ma, 'B03_A_DT_PHANBO' tu, 'B03_A_DT_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_DT_PHANBO / B03_A_DT_DUTOAN' mo_ta
    UNION ALL SELECT 'TC05' ma, 'B03_A_TX_TINH_PHANBO,B03_A_TX_XA_PHANBO' tu, 'B03_A_TX_TINH_DUTOAN,B03_A_TX_XA_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_TX_TINH_PHANBO + B03_A_TX_XA_PHANBO / B03_A_TX_TINH_DUTOAN + B03_A_TX_XA_DUTOAN' mo_ta
    UNION ALL SELECT 'TC06' ma, 'B03_A_TX_TINH_GN_LK' tu, 'B03_A_TX_TINH_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_TX_TINH_GN_LK / B03_A_TX_TINH_DUTOAN' mo_ta
    UNION ALL SELECT 'TC07' ma, 'B03_A_TX_XA_GN_LK' tu, 'B03_A_TX_XA_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_TX_XA_GN_LK / B03_A_TX_XA_DUTOAN' mo_ta
    UNION ALL SELECT 'TC08' ma, 'B03_A_DT_GN_LK' tu, 'B03_A_DT_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_DT_GN_LK / B03_A_DT_DUTOAN' mo_ta
    UNION ALL SELECT 'TC09' ma, 'TH00_28' tu, 'TH00_27' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: TH00_28 / TH00_27' mo_ta
    UNION ALL SELECT 'TC10' ma, 'B03_B01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_B01' mo_ta
    UNION ALL SELECT 'TC11' ma, 'B03_B02' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_B02' mo_ta
    UNION ALL SELECT 'TC12' ma, 'TH00_27,-B03_A_DT_PHANBO,-B03_A_TX_TINH_PHANBO,-B03_A_TX_XA_PHANBO' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: TH00_27 − B03_A_DT_PHANBO − B03_A_TX_TINH_PHANBO − B03_A_TX_XA_PHANBO' mo_ta
    UNION ALL SELECT 'TC13' ma, 'B03_A_DT_GN_LK,B03_A_TX_TINH_GN_LK,B03_A_TX_XA_GN_LK,B03_A_CN_GN_LK' tu, 'B03_A_DT_DUTOAN,B03_A_TX_TINH_DUTOAN,B03_A_TX_XA_DUTOAN,B03_A_CN_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_DT_GN_LK + B03_A_TX_TINH_GN_LK + B03_A_TX_XA_GN_LK + B03_A_CN_GN_LK / B03_A_DT_DUTOAN + B03_A_TX_TINH_DUTOAN + B03_A_TX_XA_DUTOAN + B03_A_CN_DUTOAN' mo_ta
    UNION ALL SELECT 'TC14' ma, 'B03_A_TX_TINH_GN_LK,B03_A_TX_XA_GN_LK' tu, 'B03_A_TX_TINH_DUTOAN,B03_A_TX_XA_DUTOAN' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B03_A_TX_TINH_GN_LK + B03_A_TX_XA_GN_LK / B03_A_TX_TINH_DUTOAN + B03_A_TX_XA_DUTOAN' mo_ta
    UNION ALL SELECT 'TT01' ma, 'B06_A_TTHC_TINH,B06_A_TTHC_XA' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_TTHC_TINH + B06_A_TTHC_XA' mo_ta
    UNION ALL SELECT 'TT02' ma, 'B06_A_TOANTRINH_TINH,B06_A_TOANTRINH_XA' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_TOANTRINH_TINH + B06_A_TOANTRINH_XA' mo_ta
    UNION ALL SELECT 'TT03' ma, 'B06_A_TOANTRINH_TINH,B06_A_TOANTRINH_XA' tu, 'B06_A_TTHC_TINH,B06_A_TTHC_XA' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_TOANTRINH_TINH + B06_A_TOANTRINH_XA / B06_A_TTHC_TINH + B06_A_TTHC_XA' mo_ta
    UNION ALL SELECT 'TT04' ma, 'B06_A_MOTPHAN_TINH,B06_A_MOTPHAN_XA' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_MOTPHAN_TINH + B06_A_MOTPHAN_XA' mo_ta
    UNION ALL SELECT 'TT05' ma, 'B06_B02' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_B02' mo_ta
    UNION ALL SELECT 'TT06' ma, 'B06_B02' tu, 'B06_B01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_B02 / B06_B01' mo_ta
    UNION ALL SELECT 'TT07' ma, 'B06_B05' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_B05' mo_ta
    UNION ALL SELECT 'TT08' ma, 'B06_B08' tu, 'B06_B07' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_B08 / B06_B07' mo_ta
    UNION ALL SELECT 'TT09' ma, 'B06_A_PHANCAP_TINH,B06_A_PHANCAP_XA' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_PHANCAP_TINH + B06_A_PHANCAP_XA' mo_ta
    UNION ALL SELECT 'TT10' ma, 'B06_A_766' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_766' mo_ta
    UNION ALL SELECT 'TT11' ma, 'B06_A_HS_NHAN_TINH,B06_A_HS_NHAN_XA' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_HS_NHAN_TINH + B06_A_HS_NHAN_XA' mo_ta
    UNION ALL SELECT 'TT12' ma, 'B06_A_DATLICH' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_DATLICH' mo_ta
    UNION ALL SELECT 'TT13' ma, 'B06_A_TGPV' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_A_TGPV' mo_ta
    UNION ALL SELECT 'TT14' ma, 'B06_B09' tu, 'B06_B07' mau, NULL mau_hs, 1 hs, 1 can, 0 duong, 'NQ57: B06_B09 / B06_B07' mo_ta
    UNION ALL SELECT 'TT15' ma, 'B06_D01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_D01' mo_ta
    UNION ALL SELECT 'TT16' ma, 'B06_D02' tu, 'B06_D01' mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B06_D02 / B06_D01' mo_ta
    UNION ALL SELECT 'TT17' ma, 'B04_F01' tu, NULL mau, NULL mau_hs, 1 hs, 0 can, 0 duong, 'NQ57: B04_F01' mo_ta
) mp ON mp.ma = dm.ma_chi_so
ON DUPLICATE KEY UPDATE
    thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de),
    ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh),
    loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong),
    ten_nguong = VALUES(ten_nguong), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y),
    cach_tinh = VALUES(cach_tinh), tu_ma = VALUES(tu_ma), mau_ma = VALUES(mau_ma), mau_hang_so = VALUES(mau_hang_so),
    he_so = VALUES(he_so), can_ty_le = VALUES(can_ty_le), chi_khi_mau_duong = VALUES(chi_khi_mau_duong),
    mo_ta_nguon = VALUES(mo_ta_nguon), cap_nhat = VALUES(cap_nhat)
