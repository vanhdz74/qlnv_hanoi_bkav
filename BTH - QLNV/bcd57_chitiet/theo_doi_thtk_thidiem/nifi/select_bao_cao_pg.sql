SELECT
    bai_id::text AS bai_id, bao_cao_id::text AS bao_cao_id, tenant, ma_che_do, ten_che_do, ma_quy_trinh, ten_quy_trinh,
    dot_id::text AS dot_id, ma_ky, loai_ky, ten_ky, tu_ngay::text AS tu_ngay, den_ngay::text AS den_ngay,
    don_vi_id::text AS don_vi_id, ma_don_vi, ten_don_vi, co_quan_nhan_id::text AS co_quan_nhan_id, ma_co_quan_nhan,
    ma_bieu, phien_ban_bieu_id::text AS phien_ban_bieu_id, array_to_string(cac_phan_duoc_giao, ',') AS cac_phan_duoc_giao,
    ma_trang_thai, trang_thai, han_nop::text AS han_nop, han_nop_sau_gia_han::text AS han_nop_sau_gia_han,
    to_char(nop_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS nop_luc,
    to_char(tiep_nhan_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS tiep_nhan_luc,
    (nop_tre::int)::text AS nop_tre, lan_sua::text AS lan_sua, so_o_trong_kho::text AS so_o_trong_kho,
    to_char(thay_doi_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS thay_doi_luc,
    to_char(han_nop_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS han_nop_luc, den_han::text AS den_han,
    to_char(nhap_dau_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS nhap_dau_luc,
    to_char(gui_duyet_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS gui_duyet_luc,
    so_lan_lanh_dao_khong_duyet::text AS so_lan_lanh_dao_khong_duyet, so_lan_tra_lai::text AS so_lan_tra_lai,
    so_lan_huy_tiep_nhan::text AS so_lan_huy_tiep_nhan, so_bieu_phai_nop::text AS so_bieu_phai_nop,
    so_bieu_da_tiep_nhan::text AS so_bieu_da_tiep_nhan, lech_han_phut::text AS lech_han_phut, (nap_lui::int)::text AS nap_lui,
    '${sync_ts}' AS sync_date
FROM dashboard.bao_cao
