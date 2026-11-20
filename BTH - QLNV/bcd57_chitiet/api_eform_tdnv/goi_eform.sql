/* Gói Eform TDNV_NHIEM_VU – sinh bởi build_goi.py, KHÔNG sửa tay */
SELECT k.loai,
       CAST(JSON_OBJECT(
         'period', CASE k.loai
             WHEN 'MONTH' THEN JSON_OBJECT('type', 'MONTH', 'date', DATE_FORMAT(LAST_DAY('${p.ngay}'), '%Y-%m-%d'))
             WHEN 'WEEK'  THEN JSON_OBJECT('type', 'WEEK', 'week_start', 'SAT', 'date',
                               DATE_FORMAT(DATE_ADD('${p.ngay}', INTERVAL (11 - WEEKDAY('${p.ngay}')) % 7 DAY), '%Y-%m-%d'))
             ELSE                JSON_OBJECT('type', 'DAY', 'date', '${p.ngay}') END,
         'taken_at', '${p.taken}',
         'values', v.ds) AS CHAR CHARACTER SET utf8mb4) AS goi,
       v.so_dong
FROM (SELECT 'MONTH' AS loai UNION ALL SELECT 'WEEK' UNION ALL SELECT 'DAY') k
CROSS JOIN (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('department_id', s.department_id,
                                     'indicator_code', s.indicator_code, 'value', s.value)) AS ds,
           COUNT(*) AS so_dong
    FROM (
SELECT a.department_id,
       k.code AS indicator_code,
       CASE k.code
         WHEN 'NV01' THEN a.tong        WHEN 'NV02' THEN a.ht
         WHEN 'NV03' THEN ROUND(100 * a.ht / a.tong, 2)
         WHEN 'NV04' THEN a.tong - a.ht
         WHEN 'NV05' THEN a.qua_han_giao WHEN 'NV06' THEN a.can_xl
         WHEN 'NV07' THEN a.tw          WHEN 'NV08' THEN a.tw_ht
         WHEN 'NV09' THEN a.k20         WHEN 'NV10' THEN a.k20_ht     WHEN 'NV11' THEN a.k20_qh
         WHEN 'NV12' THEN a.k35         WHEN 'NV13' THEN a.k35_ht     WHEN 'NV14' THEN a.k35_qh
         WHEN 'NV15' THEN a.tb          WHEN 'NV16' THEN a.tb_ht
       END AS value
FROM (
    SELECT b.department_id,
           COUNT(*)                                   AS tong,
           SUM(b.ht)                                  AS ht,
           SUM(b.can_xl)                              AS can_xl,
           SUM(b.can_xl OR b.ht_muon)                 AS qua_han_giao,
           SUM(b.tw)                                  AS tw,
           SUM(b.tw AND b.ht)                         AS tw_ht,
           SUM(b.k20)                                 AS k20,
           SUM(b.k20 AND b.ht)                        AS k20_ht,
           SUM(b.k20 AND b.can_xl)                    AS k20_qh,
           SUM(b.k35)                                 AS k35,
           SUM(b.k35 AND b.ht)                        AS k35_ht,
           SUM(b.k35 AND b.can_xl)                    AS k35_qh,
           SUM(b.tb)                                  AS tb,
           SUM(b.tb AND b.ht)                         AS tb_ht
    FROM (
        SELECT CAST(SUBSTRING_INDEX(t.id_don_vi_chu_tri, '.', -1) AS UNSIGNED)          AS department_id,
               (t.tinh_trang = 'Đã hoàn thành')                                          AS ht,
               (t.tinh_trang <> 'Đã hoàn thành'
                    AND COALESCE(NULLIF(t.han_xu_ly, '') < p.den, 0))                    AS can_xl,
               (t.tinh_trang = 'Đã hoàn thành'
                    AND COALESCE(NULLIF(t.ngay_hoan_thanh, '') > NULLIF(t.han_xu_ly, ''), 0)) AS ht_muon,
               (t.nguon_giao = 'Nhiệm vụ Trung ương')                                    AS tw,
               (t.van_ban_giao = '20-KH/BCĐ57')                                          AS k20,
               (t.van_ban_giao = '35-KH/BCĐ57')                                          AS k35,
               (t.loai_van_ban = 'TBKL')                                                 AS tb
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57 t
          CROSS JOIN (SELECT '${p.ngay}' AS den) p
         WHERE t.cap_nhiem_vu = 'Cấp Thành phố'
           AND NULLIF(t.id_don_vi_chu_tri, '') IS NOT NULL
    ) b
    GROUP BY b.department_id
) a
CROSS JOIN (SELECT 'NV01' AS code UNION ALL SELECT 'NV02' UNION ALL SELECT 'NV03' UNION ALL SELECT 'NV04'
            UNION ALL SELECT 'NV05' UNION ALL SELECT 'NV06' UNION ALL SELECT 'NV07' UNION ALL SELECT 'NV08'
            UNION ALL SELECT 'NV09' UNION ALL SELECT 'NV10' UNION ALL SELECT 'NV11' UNION ALL SELECT 'NV12'
            UNION ALL SELECT 'NV13' UNION ALL SELECT 'NV14' UNION ALL SELECT 'NV15' UNION ALL SELECT 'NV16') k
    ) s
    WHERE s.value IS NOT NULL
) v
