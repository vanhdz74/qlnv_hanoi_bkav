SELECT
    ma_bieu, ten_bieu, ma_phan, ten_phan,
    CASE WHEN nhieu_dong::text IN ('true', 't', '1') THEN 1 ELSE 0 END AS nhieu_dong,
    thu_tu::text AS thu_tu,
    ma_truong, ten_truong,
    stt_dong::text AS stt_dong,
    dong::text AS dong,
    cot::text AS cot,
    kieu::text AS kieu,
    don_vi_tinh, ma_chi_tieu,
    CASE WHEN tu_tinh::text IN ('true', 't', '1') THEN 1 ELSE 0 END AS tu_tinh,
    '${sync_ts}' AS sync_date
FROM dashboard.truong_nq57
