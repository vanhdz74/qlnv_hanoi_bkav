SELECT
    md5(concat_ws('|', nhom_du_lieu, coalesce(ma_chi_so, ''), ky, coalesce(phan_to, ''), coalesce(ten_chi_so, ''))) AS khoa,
    nhom_du_lieu, stt_chuyen_de::text AS stt_chuyen_de, chuyen_de, ma_chi_so, thu_tu_chi_so::text AS thu_tu_chi_so,
    ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so, (giam_la_tot::int)::text AS giam_la_tot,
    nguong::text AS nguong, ten_nguong, dau_moi, phan_to, nguon_so_lieu, ghi_chu, thong_tin_them,
    ky, thu_tu_ky::text AS thu_tu_ky, ma_ky::text AS ma_ky,
    gia_tri::text AS gia_tri, tu_so::text AS tu_so, mau_so::text AS mau_so, co_so_lieu::text AS co_so_lieu, don_vi,
    to_char(sync_date AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS sync_date_eform,
    '${sync_ts}' AS sync_date
FROM dashboard.chuyen_de_chi_tiet_nq57
