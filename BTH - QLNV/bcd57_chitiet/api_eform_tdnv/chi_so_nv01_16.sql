/* =====================================================================================
   CHỈ SỐ NHIỆM VỤ NQ57 NV01–NV16 THEO ĐƠN VỊ CHỦ TRÌ → API Eform TDNV_NHIEM_VU (19/11/2026)
   Chạy được trong Superset SQL Lab (MySQL 5.7, datamart_hanoi). Trả 3 cột đúng khóa của gói gửi:
       department_id | indicator_code | value
   Tham số: sửa ngày lấy số ở khối p (= ngày của taken_at, giờ VN; MySQL lệch giờ nên không dùng CURDATE()).

   Nguồn: qlnv_chitiet_captp_xp_bcd57, cap_nhiem_vu = 'Cấp Thành phố' (1 dòng / đầu giao, gồm cả
          nhiệm vụ Trung ương và Thành phố giao; không lấy bảng _full cấp xã vì 1 dòng / xã nhận).
   department_id = id nút cuối của id_don_vi_chu_tri (490.698.1307.1340 → 1340).

   Cách tính (cùng quy ước 4 biểu PL01–04 / API báo cáo tuần):
     NV01 tổng số đang theo dõi             NV02 đã hoàn thành (lũy kế tới ngày lấy số)
     NV03 = NV02 / NV01 × 100 (2 chữ số)    NV04 = NV01 − NV02 (gồm cả nhiệm vụ thường xuyên)
     NV05 đã quá thời hạn giao  = NV06 + đã hoàn thành nhưng ngày HT > hạn
     NV06 quá hạn cần xử lý      = chưa hoàn thành và hạn < ngày lấy số   (là một phần của NV05)
     NV07/08 Trung ương giao     : nguon_giao = 'Nhiệm vụ Trung ương'      tổng / đã HT
     NV09/10/11 KH 20-KH/BCĐ57   : van_ban_giao = '20-KH/BCĐ57'            tổng / đã HT / quá hạn (= kiểu NV06)
     NV12/13/14 KH 35-KH/BCĐ57   : van_ban_giao = '35-KH/BCĐ57'            tổng / đã HT / quá hạn (= kiểu NV06)
     NV15/16 Thông báo kết luận  : loai_van_ban = 'TBKL'                   tổng / đã HT
   Mỗi đơn vị có nhiệm vụ gửi đủ 16 mã (số 0 vẫn gửi vì là số thật).
   ===================================================================================== */
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
          CROSS JOIN (SELECT '2026-11-19' AS den) p
         WHERE t.cap_nhiem_vu = 'Cấp Thành phố'
           AND NULLIF(t.id_don_vi_chu_tri, '') IS NOT NULL
    ) b
    GROUP BY b.department_id
) a
CROSS JOIN (SELECT 'NV01' AS code UNION ALL SELECT 'NV02' UNION ALL SELECT 'NV03' UNION ALL SELECT 'NV04'
            UNION ALL SELECT 'NV05' UNION ALL SELECT 'NV06' UNION ALL SELECT 'NV07' UNION ALL SELECT 'NV08'
            UNION ALL SELECT 'NV09' UNION ALL SELECT 'NV10' UNION ALL SELECT 'NV11' UNION ALL SELECT 'NV12'
            UNION ALL SELECT 'NV13' UNION ALL SELECT 'NV14' UNION ALL SELECT 'NV15' UNION ALL SELECT 'NV16') k
ORDER BY a.department_id, k.code;
