/* NiFi ExecuteSQLRecord (NQ57_bieu_mau, PostgreSQL). ${sync_ts} = thuộc tính từ GenerateFlowFile. */
SELECT
    ma_chi_tieu, chi_tieu, ma_phu_luc, phu_luc, don_vi_tinh, ma_phan_to, phan_to,
    '${sync_ts}' AS sync_date
FROM dashboard.chi_tieu_nq57
