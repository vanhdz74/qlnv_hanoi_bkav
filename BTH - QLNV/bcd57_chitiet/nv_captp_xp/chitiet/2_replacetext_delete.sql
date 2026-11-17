/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57` WHERE sync_date < '${sync_ts}';

/* id_cha: task_id đầu tiên (nhỏ nhất) cùng (cấp, tên nhiệm vụ, đơn vị giao, văn bản giao) + '_GR'.
   GROUP BY theo MD5 vì ten_nhiem_vu là TEXT. */
UPDATE `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57` c
LEFT JOIN (
    SELECT cap_nhiem_vu, MD5(COALESCE(ten_nhiem_vu, '')) AS title_md5, COALESCE(id_don_vi_giao, '') AS id_don_vi_giao,
           COALESCE(van_ban_giao, '') AS van_ban_giao,
           CONCAT(MIN(task_id), '_GR') AS id_cha
    FROM `datamart_hanoi`.`qlnv_chitiet_captp_xp_bcd57`
    GROUP BY cap_nhiem_vu, MD5(COALESCE(ten_nhiem_vu, '')), COALESCE(id_don_vi_giao, ''), COALESCE(van_ban_giao, '')
) g
       ON g.cap_nhiem_vu = c.cap_nhiem_vu
      AND g.title_md5 = MD5(COALESCE(c.ten_nhiem_vu, ''))
      AND g.id_don_vi_giao = COALESCE(c.id_don_vi_giao, '')
      AND g.van_ban_giao = COALESCE(c.van_ban_giao, '')
SET c.id_cha = g.id_cha;
