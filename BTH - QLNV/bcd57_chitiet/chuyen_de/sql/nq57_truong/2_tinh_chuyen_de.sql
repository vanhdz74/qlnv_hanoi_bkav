/* Tính chuyen_de_chi_tiet_nq57_test từ 4 bảng NQ57 + nq57_chi_so_anh_xa. NiFi thay ${sync_ts}. SINH TỰ ĐỘNG bởi build.py */
INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` (nhom_du_lieu, ma_chi_so, ky, phan_to, thu_tu_ky, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so, giam_la_tot, nguong, ten_nguong, tu_so, mau_so, gia_tri, co_so_lieu, nguon_so_lieu, vi_tri, trich_dan, dau_moi, luu_y, ghi_chu, thong_tin_them, sync_date)
SELECT * FROM (
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
       '${sync_ts}' AS sync_date
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
) src
ON DUPLICATE KEY UPDATE thu_tu_ky = VALUES(thu_tu_ky), thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de), ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh), loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong), ten_nguong = VALUES(ten_nguong), tu_so = VALUES(tu_so), mau_so = VALUES(mau_so), gia_tri = VALUES(gia_tri), co_so_lieu = VALUES(co_so_lieu), nguon_so_lieu = VALUES(nguon_so_lieu), vi_tri = VALUES(vi_tri), trich_dan = VALUES(trich_dan), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y), ghi_chu = VALUES(ghi_chu), thong_tin_them = VALUES(thong_tin_them), sync_date = VALUES(sync_date);

INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` (nhom_du_lieu, ma_chi_so, ky, phan_to, thu_tu_ky, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so, giam_la_tot, nguong, ten_nguong, tu_so, mau_so, gia_tri, co_so_lieu, nguon_so_lieu, vi_tri, trich_dan, dau_moi, luu_y, ghi_chu, thong_tin_them, sync_date)
SELECT * FROM (
SELECT 'NOI_DUNG_XA' AS nhom_du_lieu,
       'so_xa' AS ma_chi_so,
       CONCAT('T', CAST(RIGHT(q.ky, 2) AS UNSIGNED), '/', LEFT(q.ky, 4)) AS ky,
       q.pt AS phan_to,
       (CAST(RIGHT(q.ky, 2) AS UNSIGNED) - 1) AS thu_tu_ky,
       9 AS thu_tu_chi_so,
       NULL AS stt_chuyen_de,
       NULL AS chuyen_de,
       'Số xã có kết quả' AS ten_chi_so,
       'Số xã có kết quả' AS ten_ngan,
       'xã, phường' AS don_vi_tinh,
       NULL AS loai_chi_so,
       0 AS giam_la_tot,
       NULL AS nguong,
       NULL AS ten_nguong,
       NULL AS tu_so,
       126 AS mau_so,
       q.n AS gia_tri,
       IF(q.n IS NULL, 0, 1) AS co_so_lieu,
       'NQ57 (CSDL số liệu NQ57)' AS nguon_so_lieu,
       'Biểu 01 phần A: số xã trả lời ''Có'' (B01_A01 mô hình, B01_A03 dữ liệu số, B01_A05 DVC)' AS vi_tri,
       NULL AS trich_dan,
       NULL AS dau_moi,
       NULL AS luu_y,
       NULL AS ghi_chu,
       NULL AS thong_tin_them,
       '${sync_ts}' AS sync_date
FROM (
    SELECT s.ky, t.pt, COUNT(DISTINCT s.ma_don_vi) n
    FROM `datamart_hanoi`.`nq57_solieu_truong` s
    JOIN (SELECT 'B01_A01' ma, 'Mô hình, sáng kiến nhân rộng' pt UNION ALL SELECT 'B01_A03', 'Dữ liệu số'
          UNION ALL SELECT 'B01_A05', 'DVC, TTHC') t ON t.ma = s.ma_truong
    WHERE s.ma_bieu = 'NQ57HN-B01' AND s.gia_tri_chu = 'Có'
    GROUP BY s.ky, t.pt
) q
) src
ON DUPLICATE KEY UPDATE thu_tu_ky = VALUES(thu_tu_ky), thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de), ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh), loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong), ten_nguong = VALUES(ten_nguong), tu_so = VALUES(tu_so), mau_so = VALUES(mau_so), gia_tri = VALUES(gia_tri), co_so_lieu = VALUES(co_so_lieu), nguon_so_lieu = VALUES(nguon_so_lieu), vi_tri = VALUES(vi_tri), trich_dan = VALUES(trich_dan), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y), ghi_chu = VALUES(ghi_chu), thong_tin_them = VALUES(thong_tin_them), sync_date = VALUES(sync_date);

INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` (nhom_du_lieu, ma_chi_so, ky, phan_to, thu_tu_ky, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so, giam_la_tot, nguong, ten_nguong, tu_so, mau_so, gia_tri, co_so_lieu, nguon_so_lieu, vi_tri, trich_dan, dau_moi, luu_y, ghi_chu, thong_tin_them, sync_date)
SELECT * FROM (
SELECT 'XA_QUAN_TAM' AS nhom_du_lieu,
       c.ma AS ma_chi_so,
       CONCAT('T', CAST(RIGHT(q.ky, 2) AS UNSIGNED), '/', LEFT(q.ky, 4)) AS ky,
       q.ten_xa AS phan_to,
       (CAST(RIGHT(q.ky, 2) AS UNSIGNED) - 1) AS thu_tu_ky,
       10 AS thu_tu_chi_so,
       NULL AS stt_chuyen_de,
       NULL AS chuyen_de,
       c.ten AS ten_chi_so,
       c.ten AS ten_ngan,
       'nhiệm vụ' AS don_vi_tinh,
       NULL AS loai_chi_so,
       0 AS giam_la_tot,
       NULL AS nguong,
       NULL AS ten_nguong,
       NULL AS tu_so,
       NULL AS mau_so,
       CASE c.ma WHEN 'tong_nhiem_vu' THEN q.tong WHEN 'hoan_thanh' THEN q.ht WHEN 'dang_qua_han' THEN q.qh ELSE q.xqh END AS gia_tri,
       IF(CASE c.ma WHEN 'tong_nhiem_vu' THEN q.tong WHEN 'hoan_thanh' THEN q.ht WHEN 'dang_qua_han' THEN q.qh ELSE q.xqh END IS NULL, 0, 1) AS co_so_lieu,
       'NQ57 (CSDL số liệu NQ57)' AS nguon_so_lieu,
       'Biểu 01 phần B: xã có nhiệm vụ đang quá hạn (B01_B06 > 0); B01_B01, B01_B02, B01_B06, B01_B07' AS vi_tri,
       NULL AS trich_dan,
       NULL AS dau_moi,
       NULL AS luu_y,
       NULL AS ghi_chu,
       NULL AS thong_tin_them,
       '${sync_ts}' AS sync_date
FROM (
    SELECT ky, ma_don_vi, TRIM(REPLACE(REPLACE(REPLACE(REPLACE(MAX(don_vi), 'Thường trực BCĐ57 ', ''), 'UBND ', ''), 'phường ', ''), 'xã ', '')) ten_xa,
           SUM(IF(ma_truong = 'B01_B01', gia_tri_so, NULL)) tong, SUM(IF(ma_truong = 'B01_B02', gia_tri_so, NULL)) ht,
           SUM(IF(ma_truong = 'B01_B06', gia_tri_so, NULL)) qh,   SUM(IF(ma_truong = 'B01_B07', gia_tri_so, NULL)) xqh
    FROM `datamart_hanoi`.`nq57_solieu_truong`
    WHERE ma_bieu = 'NQ57HN-B01' AND ma_phan = 'B'
    GROUP BY ky, ma_don_vi
    HAVING qh > 0
) q
CROSS JOIN (SELECT 'tong_nhiem_vu' ma, 'Tổng nhiệm vụ' ten UNION ALL SELECT 'hoan_thanh', 'Hoàn thành'
            UNION ALL SELECT 'dang_qua_han', 'Đang quá hạn' UNION ALL SELECT 'xong_qua_han', 'Hoàn thành quá hạn') c
) src
ON DUPLICATE KEY UPDATE thu_tu_ky = VALUES(thu_tu_ky), thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de), ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh), loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong), ten_nguong = VALUES(ten_nguong), tu_so = VALUES(tu_so), mau_so = VALUES(mau_so), gia_tri = VALUES(gia_tri), co_so_lieu = VALUES(co_so_lieu), nguon_so_lieu = VALUES(nguon_so_lieu), vi_tri = VALUES(vi_tri), trich_dan = VALUES(trich_dan), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y), ghi_chu = VALUES(ghi_chu), thong_tin_them = VALUES(thong_tin_them), sync_date = VALUES(sync_date);

INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` (nhom_du_lieu, ma_chi_so, ky, phan_to, thu_tu_ky, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so, giam_la_tot, nguong, ten_nguong, tu_so, mau_so, gia_tri, co_so_lieu, nguon_so_lieu, vi_tri, trich_dan, dau_moi, luu_y, ghi_chu, thong_tin_them, sync_date)
SELECT * FROM (
SELECT 'DIEM_NGHEN_XA' AS nhom_du_lieu,
       'so_xa_phan_anh' AS ma_chi_so,
       CONCAT('T', CAST(RIGHT(q.ky, 2) AS UNSIGNED), '/', LEFT(q.ky, 4)) AS ky,
       q.cd AS phan_to,
       (CAST(RIGHT(q.ky, 2) AS UNSIGNED) - 1) AS thu_tu_ky,
       10 AS thu_tu_chi_so,
       NULL AS stt_chuyen_de,
       NULL AS chuyen_de,
       'Số xã phản ánh' AS ten_chi_so,
       'Số xã phản ánh' AS ten_ngan,
       'xã, phường' AS don_vi_tinh,
       NULL AS loai_chi_so,
       0 AS giam_la_tot,
       NULL AS nguong,
       NULL AS ten_nguong,
       NULL AS tu_so,
       126 AS mau_so,
       q.n AS gia_tri,
       IF(q.n IS NULL, 0, 1) AS co_so_lieu,
       'NQ57 (CSDL số liệu NQ57)' AS nguon_so_lieu,
       'Biểu 01 phần F (B01_F01): phân loại tự động theo từ khóa, 1 xã có thể thuộc nhiều nhóm' AS vi_tri,
       NULL AS trich_dan,
       NULL AS dau_moi,
       NULL AS luu_y,
       NULL AS ghi_chu,
       NULL AS thong_tin_them,
       '${sync_ts}' AS sync_date
FROM (
    SELECT f.ky, COALESCE(k.cd, 'Khác/không nêu rõ') cd, COUNT(DISTINCT f.ma_don_vi) n
    FROM (SELECT ky, ma_don_vi, so_dong, LOWER(CONVERT(gia_tri_chu USING utf8mb4)) COLLATE utf8mb4_bin AS txt
          FROM `datamart_hanoi`.`nq57_solieu_truong`
          WHERE ma_bieu = 'NQ57HN-B01' AND ma_truong = 'B01_F01' AND gia_tri_chu IS NOT NULL AND gia_tri_chu <> '') f
    LEFT JOIN (
          SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%an toàn thông tin%' kw
          UNION ALL SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%attt%' kw
          UNION ALL SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%chữ ký số%' kw
          UNION ALL SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%cơ yếu%' kw
          UNION ALL SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%chứng thư%' kw
          UNION ALL SELECT 'ATTT, chữ ký số, cơ yếu' cd, '%an ninh mạng%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%hướng dẫn%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%cơ chế%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%phân quyền%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%quy định%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%phân cấp%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%thẩm quyền%' kw
          UNION ALL SELECT 'Cơ chế, hướng dẫn, phân quyền' cd, '%chưa có văn bản%' kw
          UNION ALL SELECT 'Dữ liệu, chuẩn hóa, chia sẻ' cd, '%dữ liệu%' kw
          UNION ALL SELECT 'Dữ liệu, chuẩn hóa, chia sẻ' cd, '%chuẩn hóa%' kw
          UNION ALL SELECT 'Dữ liệu, chuẩn hóa, chia sẻ' cd, '%làm sạch%' kw
          UNION ALL SELECT 'Dữ liệu, chuẩn hóa, chia sẻ' cd, '%đồng bộ%' kw
          UNION ALL SELECT 'Dữ liệu, chuẩn hóa, chia sẻ' cd, '%chia sẻ%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%dịch vụ công%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%dvc%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%thủ tục%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%tthc%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%hồ sơ%' kw
          UNION ALL SELECT 'DVC, TTHC, đảng phí' cd, '%đảng phí%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%hạ tầng%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%thiết bị%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%máy tính%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%đường truyền%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%mạng%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%máy chủ%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%camera%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%wifi%' kw
          UNION ALL SELECT 'Hạ tầng, thiết bị, đường truyền' cd, '%internet%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%kinh phí%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%mua sắm%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%ngân sách%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%dự toán%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%đấu thầu%' kw
          UNION ALL SELECT 'Kinh phí, mua sắm' cd, '%vốn%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%phần mềm%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%nền tảng%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%liên thông%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%hệ thống%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%kết nối%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%tài khoản%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%ứng dụng%' kw
          UNION ALL SELECT 'Nền tảng, phần mềm, liên thông' cd, '%lỗi%' kw
          UNION ALL SELECT 'Người dân, doanh nghiệp tiếp cận số' cd, '%người dân%' kw
          UNION ALL SELECT 'Người dân, doanh nghiệp tiếp cận số' cd, '%doanh nghiệp%' kw
          UNION ALL SELECT 'Người dân, doanh nghiệp tiếp cận số' cd, '%người cao tuổi%' kw
          UNION ALL SELECT 'Người dân, doanh nghiệp tiếp cận số' cd, '%kỹ năng số của người%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%nhân lực%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%cán bộ%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%kỹ năng%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%đào tạo%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%biên chế%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%nhân sự%' kw
          UNION ALL SELECT 'Nhân lực, kỹ năng số' cd, '%chuyên trách%' kw
    ) k ON f.txt LIKE (CONVERT(k.kw USING utf8mb4) COLLATE utf8mb4_bin)
    GROUP BY f.ky, COALESCE(k.cd, 'Khác/không nêu rõ')
) q
) src
ON DUPLICATE KEY UPDATE thu_tu_ky = VALUES(thu_tu_ky), thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de), ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh), loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong), ten_nguong = VALUES(ten_nguong), tu_so = VALUES(tu_so), mau_so = VALUES(mau_so), gia_tri = VALUES(gia_tri), co_so_lieu = VALUES(co_so_lieu), nguon_so_lieu = VALUES(nguon_so_lieu), vi_tri = VALUES(vi_tri), trich_dan = VALUES(trich_dan), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y), ghi_chu = VALUES(ghi_chu), thong_tin_them = VALUES(thong_tin_them), sync_date = VALUES(sync_date);

DELETE FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nq57_test` WHERE sync_date < '${sync_ts}';
