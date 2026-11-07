/* NiFi ExecuteSQLRecord (NQ57_bao_cao, PostgreSQL). ${sync_ts} = thuộc tính từ GenerateFlowFile.
   Ép kiểu sang text để PutDatabaseRecord (MySQL) nhận đúng, không lệch múi giờ/epoch. */
SELECT
    ma_bieu, ma_chi_tieu, ma_phan_to, loai_so, ky, ma_don_vi, don_vi,
    gia_tri::text AS gia_tri,
    to_char(cap_nhat_luc AT TIME ZONE 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI:SS') AS cap_nhat_luc,
    '${sync_ts}' AS sync_date
FROM dashboard.so_lieu_nq57
