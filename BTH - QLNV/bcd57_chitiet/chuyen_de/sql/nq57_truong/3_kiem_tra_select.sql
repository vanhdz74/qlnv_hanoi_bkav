SELECT 'CHI_SO' AS nhom_du_lieu,
       z.ma_chi_so AS ma_chi_so,
       CONCAT('T', CAST(RIGHT(z.ky_nq57, 2) AS UNSIGNED), '/', LEFT(z.ky_nq57, 4)) AS ky,
       '' AS phan_to,
       (CAST(RIGHT(z.ky_nq57, 2) AS UNSIGNED) - 1) AS thu_tu_ky,
       z.thu_tu_chi_so AS thu_tu_chi_so,
       z.stt_chuyen_de AS stt_chuyen_de,
       z.chuyen_de AS chuyen_de,
       z.ten_chi_so AS ten_chi_so,
       z.ten_ngan AS ten_ngan,
       z.don_vi_tinh AS don_vi_tinh,
       z.loai_chi_so AS loai_chi_so,
       z.giam_la_tot AS giam_la_tot,
       z.nguong AS nguong,
       z.ten_nguong AS ten_nguong,
       z.tu_so AS tu_so,
       z.mau_so AS mau_so,
       z.gia_tri AS gia_tri,
       IF(z.gia_tri IS NULL, 0, 1) AS co_so_lieu,
       IF(z.cach_tinh = 'KHONG_CO', NULL, 'NQ57 (CSDL số liệu NQ57)') AS nguon_so_lieu,
       z.mo_ta_nguon AS vi_tri,
       NULL AS trich_dan,
       z.dau_moi AS dau_moi,
       z.luu_y AS luu_y,
       IF(z.cach_tinh = 'KHONG_CO', 'Chưa có chỉ tiêu tương ứng trong NQ57', IF(z.gia_tri IS NULL, 'NQ57 chưa có số kỳ này', NULL)) AS ghi_chu,
       NULL AS thong_tin_them,
       NOW() AS sync_date
FROM (
    SELECT y.*,
           CASE WHEN y.co_mau = 1 OR y.can_ty_le = 1 THEN y.tu END AS tu_so,
           CASE WHEN y.co_mau = 1 THEN y.mau END AS mau_so,
           CASE WHEN y.co_mau = 1 THEN y.tu / NULLIF(y.mau, 0)
                WHEN y.can_ty_le = 1 THEN NULL
                ELSE y.tu * y.he_so END AS gia_tri
    FROM (
        SELECT x.*,
               IF(x.mau_ma IS NULL AND x.mau_hang_so IS NULL, 0, 1) AS co_mau,
               IF(x.chi_khi_mau_duong = 1 AND NOT (COALESCE(x.mau_raw, x.mau_hang_so) > 0), NULL,
                  IF(x.n_cong = 0 OR (LOCATE('-', x.tu_ma) > 0 AND x.n_tru = 0), NULL, x.tu_raw)) AS tu,
               COALESCE(x.mau_raw, x.mau_hang_so) AS mau
        FROM (
            SELECT m.*, k.ky_nq57,
                   SUM(CASE WHEN FIND_IN_SET(v.m, m.tu_ma) THEN v.v
                            WHEN FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) THEN -v.v END) AS tu_raw,
                   SUM(FIND_IN_SET(v.m, m.tu_ma) > 0) AS n_cong,
                   SUM(FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) > 0) AS n_tru,
                   SUM(IF(FIND_IN_SET(v.m, m.mau_ma), v.v, NULL)) AS mau_raw
            FROM `datamart_hanoi`.`nq57_chi_so_anh_xa` m
            CROSS JOIN (
        SELECT CONCAT(y.nam, 'M', LPAD(n.t, 2, '0')) AS ky_nq57
        FROM (SELECT 1 t UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
              UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) n
        JOIN (SELECT LEFT(MAX(ky), 4) nam, CAST(RIGHT(MAX(ky), 2) AS UNSIGNED) den
              FROM (SELECT ky FROM `datamart_hanoi`.`nq57_solieu` UNION ALL SELECT ky FROM `datamart_hanoi`.`nq57_solieu_truong`) a
              WHERE ky LIKE '____M__') y ON n.t <= y.den
    ) k
            LEFT JOIN (
        SELECT ma_chi_tieu AS m, ky,
               COALESCE(MAX(IF(ma_bieu LIKE 'NQ57HN-TH%', gia_tri, NULL)),
                        SUM(IF(ma_bieu LIKE 'NQ57HN-TH%', NULL, gia_tri))) AS v
        FROM `datamart_hanoi`.`nq57_solieu`
        WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL
        GROUP BY ma_chi_tieu, ky
        UNION ALL
        SELECT s.ma_truong, s.ky, SUM(s.gia_tri_so)
        FROM `datamart_hanoi`.`nq57_solieu_truong` s
        LEFT JOIN (SELECT DISTINCT ma_chi_tieu, ky FROM `datamart_hanoi`.`nq57_solieu`
                   WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL) c
               ON c.ma_chi_tieu = s.ma_truong AND c.ky = s.ky
        WHERE s.gia_tri_so IS NOT NULL AND c.ma_chi_tieu IS NULL
        GROUP BY s.ma_truong, s.ky
        UNION ALL
        SELECT x.m, e.ky,
               SUM(CASE x.m WHEN 'XA_TT_GE90' THEN e.r >= 0.9 WHEN 'XA_TT_100' THEN e.r >= 1 WHEN 'XA_TT_LT50' THEN e.r < 0.5 ELSE 1 END)
        FROM (
            SELECT ky, ma_don_vi, so_dong,
                   SUM(IF(ma_truong = 'B04_E03', gia_tri_so, NULL)) / NULLIF(SUM(IF(ma_truong = 'B04_E02', gia_tri_so, NULL)), 0) AS r
            FROM `datamart_hanoi`.`nq57_solieu_truong`
            WHERE ma_bieu = 'NQ57HN-B04' AND ma_phan = 'E' AND so_dong > 0
            GROUP BY ky, ma_don_vi, so_dong
        ) e
        CROSS JOIN (SELECT 'XA_TT_GE90' m UNION ALL SELECT 'XA_TT_100' UNION ALL SELECT 'XA_TT_LT50' UNION ALL SELECT 'XA_TT_SO') x
        WHERE e.r IS NOT NULL
        GROUP BY x.m, e.ky
        UNION ALL
        SELECT CONCAT('XA_', SUBSTRING(ma_truong, 5), '_CO'), ky, COUNT(DISTINCT ma_don_vi)
        FROM `datamart_hanoi`.`nq57_solieu_truong`
        WHERE ma_bieu = 'NQ57HN-B01' AND ma_truong IN ('B01_A01', 'B01_A03', 'B01_A05') AND gia_tri_chu = 'Có'
        GROUP BY ma_truong, ky
    ) v
                   ON v.ky = k.ky_nq57
                  AND (FIND_IN_SET(v.m, m.tu_ma) OR FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) OR FIND_IN_SET(v.m, m.mau_ma))
            GROUP BY m.ma_chi_so, k.ky_nq57
        ) x
    ) y
) z