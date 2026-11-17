/* Xóa bản ghi không còn thỏa điều kiện (không được upsert ở chu kỳ này) */
DELETE FROM datamart_hanoi.qlnv_tonghop_chitiet_ubndtp WHERE sync_date < '${sync_ts}';

/* id_cha: task_id đầu tiên (nhỏ nhất) cùng (tên nhiệm vụ, bên giao, văn bản giao) + '_GR', chỉ cho nhiệm vụ giao;
   khớp id_cha bảng gộp qlnv_tonghop_gop_nvgiao_ubndtp. GROUP BY theo MD5 vì ten_task là TEXT. */
UPDATE `datamart_hanoi`.`qlnv_tonghop_chitiet_ubndtp` c
LEFT JOIN (
    SELECT MD5(COALESCE(ten_task, '')) AS title_md5, COALESCE(ben_giao_id, '') AS ben_giao_id,
           COALESCE(van_ban_giao, '') AS van_ban_giao,
           CONCAT(MIN(task_id), '_GR') AS id_cha
    FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_ubndtp`
    WHERE loai_nhiem_vu = 'Nhiệm vụ giao'
    GROUP BY MD5(COALESCE(ten_task, '')), COALESCE(ben_giao_id, ''), COALESCE(van_ban_giao, '')
) g
       ON g.title_md5 = MD5(COALESCE(c.ten_task, ''))
      AND g.ben_giao_id = COALESCE(c.ben_giao_id, '')
      AND g.van_ban_giao = COALESCE(c.van_ban_giao, '')
      AND c.loai_nhiem_vu = 'Nhiệm vụ giao'
SET c.id_cha = g.id_cha;
