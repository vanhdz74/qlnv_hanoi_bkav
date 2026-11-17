SELECT
    ma_bieu, ma_phan, ma_truong,
    COALESCE(so_dong::text, '0') AS so_dong,
    ky::text AS ky,
    COALESCE(ma_don_vi::text, '') AS ma_don_vi,
    don_vi,
    gia_tri_so::text AS gia_tri_so,
    gia_tri_chu::text AS gia_tri_chu,
    to_char(cap_nhat_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS cap_nhat_luc,
    '${sync_ts}' AS sync_date
FROM dashboard.so_lieu_truong_nq57
