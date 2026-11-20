/* =====================================================================================
   BÁO CÁO TUẦN NQ57 – 4 BIỂU MẪU (PHỤ LỤC 01–04) của "DE CUONG BAO CAO TUAN - UPDATE.docx"
   Chạy được trực tiếp trong Superset SQL Lab (MySQL 5.7, datamart_hanoi). 18/11/2026.

   Nguồn = các bảng do NiFi "QLNV - Ban chỉ đạo 57 chi tiết" (5ebe3d34) / nv_captp_xp ghi:
     · Nhiệm vụ Thành phố giao : qlnv_chitiet_captp_xp_bcd57       (1 dòng / đầu giao, như dashboard 272)
                                 cap_nhiem_vu='Cấp Thành phố' AND nguon_giao='Nhiệm vụ Thành phố'
     · Nhiệm vụ giao cấp xã    : qlnv_chitiet_captp_xp_bcd57_full  (1 dòng / xã nhận)
                                 cap_nhiem_vu='Cấp Xã, phường'

   THAM SỐ: sửa 3 giá trị trong khối  p  ở đầu MỖI câu
     tu  = ngày đầu tuần, den = ngày cuối tuần ('YYYY-MM-DD'),
     dv  = id đơn vị chủ trì (lấy cả đơn vị con), '' = toàn bộ.

   Quy ước tính (giống API :9990/bcd57/api/bao-cao-tuan):
     Hoàn thành            = tinh_trang 'Đã hoàn thành'; Đang thực hiện = phần còn lại
     Cần tiếp tục xử lý    = chưa hoàn thành và hạn < den
     Đã quá thời hạn giao  = cần tiếp tục xử lý + đã hoàn thành nhưng ngày HT > hạn
     Sắp đến hạn           = chưa hoàn thành và den <= hạn <= cuối tháng của den
     Hoàn thành trong tuần = đã hoàn thành và tu <= ngày HT <= den
     Mức nguy cơ (PL04)    = Cao: tiến độ < 50% và còn ≤ 7 ngày, hoặc tiến độ < 30%;
                             Trung bình: tiến độ < 80%; Thấp: còn lại
   "Sản phẩm phải hoàn thành", "Tài liệu kiểm chứng": QLNV chưa có trường → để trống.
   ===================================================================================== */


/* ------------------------------------------------------------------
   PHỤ LỤC 01 – BẢNG TỔNG HỢP THEO DÕI NHIỆM VỤ TUẦN
   ------------------------------------------------------------------ */
SELECT NULLIF(t.stt, 3)                        AS `STT`,
       t.nguon_giao                            AS `Nguồn giao nhiệm vụ`,
       t.tong_so                               AS `Tổng số`,
       t.hoan_thanh                            AS `Hoàn thành`,
       t.tong_so - t.hoan_thanh                AS `Đang thực hiện`,
       t.qua_han_giao                          AS `Đã quá thời hạn giao`,
       t.can_xl                                AS `Trong đó cần tiếp tục xử lý`,
       t.sap_han                               AS `Sắp đến hạn (trong tháng)`,
       CONCAT('Giao mới ', t.giao_moi, ', hoàn thành ', t.ht_tuan, ' nhiệm vụ trong tuần')
                                               AS `Biến động chính so với tuần trước`
FROM (
    SELECT d.stt, d.nguon_giao,
           COUNT(n.nhom)                                                        AS tong_so,
           COALESCE(SUM(n.ht), 0)                                               AS hoan_thanh,
           COALESCE(SUM(n.can_xl OR (n.ht AND n.han IS NOT NULL AND n.ngay_ht > n.han)), 0) AS qua_han_giao,
           COALESCE(SUM(n.can_xl), 0)                                           AS can_xl,
           COALESCE(SUM(n.sap_han), 0)                                          AS sap_han,
           COALESCE(SUM(n.ngay_giao BETWEEN n.tu AND n.den), 0)                 AS giao_moi,
           COALESCE(SUM(n.ht AND n.ngay_ht BETWEEN n.tu AND n.den), 0)          AS ht_tuan
    FROM (SELECT 1 AS stt, 'Nhiệm vụ Thành phố giao' AS nguon_giao
          UNION ALL SELECT 2, 'Nhiệm vụ giao cấp xã'
          UNION ALL SELECT 3, 'Tổng số') d
    LEFT JOIN (
        SELECT b.*,
               (b.tinh_trang = 'Đã hoàn thành')                                   AS ht,
               (b.tinh_trang <> 'Đã hoàn thành' AND b.han < b.den)                AS can_xl,
               (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= b.den
                    AND b.han <= DATE_FORMAT(LAST_DAY(b.den), '%Y-%m-%d'))        AS sap_han
        FROM (
            SELECT 1 AS nhom, p.tu, p.den, tinh_trang,
                   NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht
              FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
              CROSS JOIN (SELECT '2026-11-10' AS tu, '2026-11-16' AS den, '' AS dv) p
             WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố'
               AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
            UNION ALL
            SELECT 2, p.tu, p.den, tinh_trang,
                   NULLIF(han_xu_ly, ''), NULLIF(ngay_giao, ''), NULLIF(ngay_hoan_thanh, '')
              FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
              CROSS JOIN (SELECT '2026-11-10' AS tu, '2026-11-16' AS den, '' AS dv) p
             WHERE cap_nhiem_vu = 'Cấp Xã, phường'
               AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
        ) b
    ) n ON n.nhom = d.stt OR d.stt = 3          -- dòng 3 "Tổng số" cộng cả 2 nhóm
    GROUP BY d.stt, d.nguon_giao
) t
ORDER BY t.stt;


/* ------------------------------------------------------------------
   PHỤ LỤC 02 – DANH MỤC NHIỆM VỤ ĐƯỢC GHI NHẬN HOÀN THÀNH TRONG TUẦN
   ------------------------------------------------------------------ */
SELECT CAST(@s2 := @s2 + 1 AS UNSIGNED)                                   AS `Stt`,
       x.ten_nhiem_vu                                      AS `Tên nhiệm vụ`,
       x.van_ban_giao                                      AS `Văn bản giao`,
       x.co_quan_chu_tri                                   AS `Cơ quan chủ trì`,
       DATE_FORMAT(x.han, '%d/%m/%Y')                      AS `Thời hạn giao`,
       DATE_FORMAT(x.ngay_ht, '%d/%m/%Y')                  AS `Ngày ghi nhận hoàn thành`,
       NULL                                                AS `Sản phẩm phải hoàn thành`,
       NULL                                                AS `Tài liệu kiểm chứng`,
       x.nguon_giao                                        AS `Nguồn giao`,
       x.task_id                                           AS `task_id`
FROM (
    SELECT * FROM (
        SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao,
               ten_don_vi_chu_tri AS co_quan_chu_tri, tinh_trang, p.tu, p.den,
               NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_hoan_thanh, '') AS ngay_ht
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
          CROSS JOIN (SELECT '2026-11-10' AS tu, '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
        UNION ALL
        SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao,
               COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri), tinh_trang, p.tu, p.den,
               NULLIF(han_xu_ly, ''), NULLIF(ngay_hoan_thanh, '')
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
          CROSS JOIN (SELECT '2026-11-10' AS tu, '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Xã, phường'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
    ) b
    WHERE b.tinh_trang = 'Đã hoàn thành' AND b.ngay_ht BETWEEN b.tu AND b.den
    ORDER BY b.nhom, b.ngay_ht, b.task_id
    LIMIT 100000
) x
CROSS JOIN (SELECT @s2 := 0) i;


/* ------------------------------------------------------------------
   PHỤ LỤC 03 – DANH MỤC NHIỆM VỤ ĐÃ QUÁ THỜI HẠN GIAO CẦN TIẾP TỤC XỬ LÝ
   ------------------------------------------------------------------ */
SELECT CAST(@s3 := @s3 + 1 AS UNSIGNED)                                   AS `Stt`,
       x.ten_nhiem_vu                                      AS `Tên nhiệm vụ`,
       x.van_ban_giao                                      AS `Văn bản giao nhiệm vụ`,
       x.co_quan_chu_tri                                   AS `Cơ quan chủ trì`,
       DATE_FORMAT(x.han, '%d/%m/%Y')                      AS `Thời hạn hoàn thành`,
       x.kq                                                AS `Kết quả thực hiện, sản phẩm đã có`,
       x.kk                                                AS `Nguyên nhân quá hạn, vướng mắc`,
       DATEDIFF(x.den, x.han)                              AS `Số ngày quá hạn`,
       x.nguon_giao                                        AS `Nguồn giao`,
       x.task_id                                           AS `task_id`
FROM (
    SELECT * FROM (
        SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao,
               ten_don_vi_chu_tri AS co_quan_chu_tri, tinh_trang, p.den,
               NULLIF(han_xu_ly, '') AS han, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
          CROSS JOIN (SELECT '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
        UNION ALL
        SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao,
               COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri), tinh_trang, p.den,
               NULLIF(han_xu_ly, ''), ket_qua_thuc_hien, kho_khan_vuong_mac
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
          CROSS JOIN (SELECT '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Xã, phường'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
    ) b
    WHERE b.tinh_trang <> 'Đã hoàn thành' AND b.han < b.den
    ORDER BY b.nhom, b.han, b.task_id
    LIMIT 100000
) x
CROSS JOIN (SELECT @s3 := 0) i;


/* ------------------------------------------------------------------
   PHỤ LỤC 04 – DANH MỤC NHIỆM VỤ SẮP ĐẾN HẠN TRONG THÁNG (tháng của den)
   ------------------------------------------------------------------ */
SELECT CAST(@s4 := @s4 + 1 AS UNSIGNED)                                   AS `Stt`,
       x.ten_nhiem_vu                                      AS `Tên nhiệm vụ`,
       x.van_ban_giao                                      AS `Văn bản giao nhiệm vụ`,
       x.co_quan_chu_tri                                   AS `Cơ quan chủ trì`,
       DATE_FORMAT(x.han, '%d/%m/%Y')                      AS `Thời hạn hoàn thành`,
       CONCAT(COALESCE(x.tien_do, 0), '%')                 AS `Tiến độ đến thời điểm báo cáo`,
       NULL                                                AS `Sản phẩm phải hoàn thành`,
       CASE WHEN (COALESCE(x.tien_do, 0) < 50 AND DATEDIFF(x.han, x.den) <= 7)
                 OR COALESCE(x.tien_do, 0) < 30 THEN 'Cao'
            WHEN COALESCE(x.tien_do, 0) < 80 THEN 'Trung bình'
            ELSE 'Thấp' END                                AS `Mức nguy cơ`,
       x.nguon_giao                                        AS `Nguồn giao`,
       x.task_id                                           AS `task_id`
FROM (
    SELECT * FROM (
        SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, task_id, ten_nhiem_vu, van_ban_giao,
               ten_don_vi_chu_tri AS co_quan_chu_tri, tinh_trang, tien_do, p.den,
               NULLIF(han_xu_ly, '') AS han
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
          CROSS JOIN (SELECT '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
        UNION ALL
        SELECT 2, 'Nhiệm vụ giao cấp xã', task_id, ten_nhiem_vu, van_ban_giao,
               COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri), tinh_trang, tien_do, p.den,
               NULLIF(han_xu_ly, '')
          FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
          CROSS JOIN (SELECT '2026-11-16' AS den, '' AS dv) p
         WHERE cap_nhiem_vu = 'Cấp Xã, phường'
           AND (p.dv = '' OR id_don_vi_chu_tri = p.dv OR id_don_vi_chu_tri LIKE CONCAT(p.dv, '.%'))
    ) b
    WHERE b.tinh_trang <> 'Đã hoàn thành'
      AND b.han >= b.den AND b.han <= DATE_FORMAT(LAST_DAY(b.den), '%Y-%m-%d')
    ORDER BY b.nhom, b.han, b.task_id
    LIMIT 100000
) x
CROSS JOIN (SELECT @s4 := 0) i;
