SELECT
    ma_chi_so, ten_chi_so, stt_chuyen_de::text AS stt_chuyen_de, chuyen_de, thu_tu_chi_so::text AS thu_tu_chi_so,
    don_vi_tinh, loai_chi_so, cach_tinh, tu_so, tru, mau_so, khoa, loc, gia_tri_chon,
    nguong_tu::text AS nguong_tu, nguong_den::text AS nguong_den, nguong::text AS nguong, ten_nguong,
    (giam_la_tot::int)::text AS giam_la_tot, dau_moi, ghi_chu, can_xac_nhan,
    '${sync_ts}' AS sync_date
FROM dashboard.cach_tinh_chi_so_nq57
