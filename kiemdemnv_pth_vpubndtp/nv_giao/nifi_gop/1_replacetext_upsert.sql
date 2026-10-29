SET SESSION group_concat_max_len = 1048576;

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_pth_ubndtp` (
    id_truc_giao, truc_giao, nhom_van_ban, linh_vuc, chu_de, muc_do_uu_tien, nv_quantam,
    ma_nhiem_vu, ten_nhiem_vu, van_ban_giao,
    id_don_vi_chu_tri, ten_don_vi_chu_tri, lanh_dao_don_vi_va_chuyen_vien,
    ngay_giao, han_xu_ly, ngay_hoan_thanh, ngay_xoa,
    tinh_trang, tinh_hinh_ket_qua,
    ld_ubnd, ld_van_phong, phong_chuyen_mon_theo_doi, chuyen_vien_vp_theo_doi,
    id_cha, task_id, status, so_luong_task, sync_date
)

SELECT
    /* 1. TRỤC GIAO & NHÓM VĂN BẢN */
    MAX(x.id_truc_giao)                                                                 AS id_truc_giao,
    GROUP_CONCAT(DISTINCT x.truc_giao     ORDER BY x.truc_giao     SEPARATOR ' | ')     AS truc_giao,
    GROUP_CONCAT(DISTINCT x.nhom_van_ban  ORDER BY x.nhom_van_ban  SEPARATOR ' | ')     AS nhom_van_ban,
    GROUP_CONCAT(DISTINCT x.linh_vuc      ORDER BY x.linh_vuc      SEPARATOR ' | ')     AS linh_vuc,

    /* CHỦ ĐỀ, MỨC ĐỘ ƯU TIÊN, NHIỆM VỤ QUAN TÂM */
    GROUP_CONCAT(DISTINCT x.chu_de         ORDER BY x.chu_de         SEPARATOR ' | ')   AS chu_de,
    GROUP_CONCAT(DISTINCT x.muc_do_uu_tien ORDER BY x.muc_do_uu_tien SEPARATOR ' | ')   AS muc_do_uu_tien,
    MAX(x.nv_quantam)                                                                   AS nv_quantam,

    /* 2. NHIỆM VỤ & VĂN BẢN GIAO */
    IF(MIN(COALESCE(x.ma_nhiem_vu, '-')) = MAX(COALESCE(x.ma_nhiem_vu, '-')), MAX(x.ma_nhiem_vu),
       GROUP_CONCAT(COALESCE(x.ma_nhiem_vu, '-') ORDER BY x.task_id SEPARATOR ' | '))       AS ma_nhiem_vu,
    MAX(x.ten_nhiem_vu)                                                                 AS ten_nhiem_vu,
    GROUP_CONCAT(DISTINCT x.van_ban_giao  ORDER BY x.van_ban_giao  SEPARATOR ' | ')     AS van_ban_giao,

    /* 3. ĐƠN VỊ CHỦ TRÌ */
    IF(MIN(COALESCE(x.id_don_vi_chu_tri, '-')) = MAX(COALESCE(x.id_don_vi_chu_tri, '-')), MAX(x.id_don_vi_chu_tri),
       GROUP_CONCAT(COALESCE(x.id_don_vi_chu_tri, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS id_don_vi_chu_tri,
    /* Tên chủ trì: nhiều Sở ngành (490.698.1307) => 'Các Sở ngành', nhiều Xã, Phường (490.698.1310) => 'Các Xã, Phường',
       nhiều cả 2 => 'Các Sở ngành, Xã, Phường'; đơn vị khác liệt kê tên (không trùng) */
    NULLIF(CONCAT_WS(' | ',
        CASE
            WHEN COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1307([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
             AND COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1310([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
                THEN 'Các Sở ngành, Xã, Phường'
            WHEN COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1307([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
                THEN 'Các Sở ngành'
            ELSE GROUP_CONCAT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1307([.]|$)', x.ten_don_vi_chu_tri, NULL) SEPARATOR ' | ')
        END,
        CASE
            WHEN COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1307([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
             AND COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1310([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
                THEN NULL
            WHEN COUNT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1310([.]|$)', x.id_don_vi_chu_tri, NULL)) > 1
                THEN 'Các Xã, Phường'
            ELSE GROUP_CONCAT(DISTINCT IF(x.id_don_vi_chu_tri REGEXP '^490[.]698[.]1310([.]|$)', x.ten_don_vi_chu_tri, NULL) SEPARATOR ' | ')
        END,
        GROUP_CONCAT(DISTINCT IF(COALESCE(x.id_don_vi_chu_tri, '') NOT REGEXP '^490[.]698[.](1307|1310)([.]|$)', x.ten_don_vi_chu_tri, NULL)
                     ORDER BY x.ten_don_vi_chu_tri SEPARATOR ' | ')
    ), '')                                                                              AS ten_don_vi_chu_tri,
    IF(MIN(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-')) = MAX(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-')), MAX(x.lanh_dao_don_vi_va_chuyen_vien),
       GROUP_CONCAT(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS lanh_dao_don_vi_va_chuyen_vien,

    /* 4. MỐC THỜI GIAN */
    IF(MIN(COALESCE(x.ngay_giao, '-')) = MAX(COALESCE(x.ngay_giao, '-')), MAX(x.ngay_giao),
       GROUP_CONCAT(COALESCE(x.ngay_giao, '-') ORDER BY x.task_id SEPARATOR ' | '))   AS ngay_giao,
    IF(MIN(COALESCE(x.han_xu_ly, '-')) = MAX(COALESCE(x.han_xu_ly, '-')), MAX(x.han_xu_ly),
       GROUP_CONCAT(COALESCE(x.han_xu_ly, '-') ORDER BY x.task_id SEPARATOR ' | '))   AS han_xu_ly,
    GROUP_CONCAT(COALESCE(x.ngay_hoan_thanh, '-') ORDER BY x.task_id SEPARATOR ' | ')   AS ngay_hoan_thanh,
    IF(MIN(COALESCE(x.ngay_xoa, '-')) = MAX(COALESCE(x.ngay_xoa, '-')), MAX(x.ngay_xoa),
       GROUP_CONCAT(COALESCE(x.ngay_xoa, '-') ORDER BY x.task_id SEPARATOR ' | '))   AS ngay_xoa,

    /* 5. TÌNH TRẠNG: tình trạng xấu nhất trong nhóm
       VD: Đã hoàn thành | Đã hoàn thành | Chưa hoàn thành trong hạn => Chưa hoàn thành trong hạn */
    CASE
        WHEN MAX(x.tinh_trang = 'Chưa hoàn thành quá hạn')   = 1 THEN 'Chưa hoàn thành quá hạn'
        WHEN MAX(x.tinh_trang = 'Chưa hoàn thành trong hạn') = 1 THEN 'Chưa hoàn thành trong hạn'
        WHEN MAX(x.tinh_trang = 'Thường xuyên')              = 1 THEN 'Thường xuyên'
        WHEN MAX(x.tinh_trang = 'Đã hoàn thành')             = 1 THEN 'Đã hoàn thành'
    END                                                                                 AS tinh_trang,

    /* 6. TÌNH HÌNH, KẾT QUẢ */
    IF(MIN(COALESCE(x.tinh_hinh_ket_qua, '-')) = MAX(COALESCE(x.tinh_hinh_ket_qua, '-')), MAX(x.tinh_hinh_ket_qua),
       GROUP_CONCAT(COALESCE(x.tinh_hinh_ket_qua, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS tinh_hinh_ket_qua,

    /* 7. LÃNH ĐẠO UBND / VĂN PHÒNG & CHUYÊN VIÊN VP THEO DÕI */
    GROUP_CONCAT(DISTINCT x.ld_ubnd                   SEPARATOR ' | ')                  AS ld_ubnd,
    GROUP_CONCAT(DISTINCT x.ld_van_phong              SEPARATOR ' | ')                  AS ld_van_phong,
    GROUP_CONCAT(DISTINCT x.phong_chuyen_mon_theo_doi SEPARATOR ' | ')                  AS phong_chuyen_mon_theo_doi,
    GROUP_CONCAT(DISTINCT x.chuyen_vien_vp_theo_doi   SEPARATOR ' | ')                  AS chuyen_vien_vp_theo_doi,

    /* 8. KHÓA HỆ THỐNG & ĐỒNG BỘ
       id_cha = task_id đầu tiên (nhỏ nhất) cùng (tên nhiệm vụ, văn bản giao, trục giao) + '_GR',
       lấy sẵn từ bảng chi tiết nên khớp id_cha bên qlnv_chitiet_nvgiao_pth_ubndtp */
    x.id_cha                                                                            AS id_cha,
    GROUP_CONCAT(x.task_id ORDER BY x.task_id SEPARATOR ' | ')                          AS task_id,
    IF(MIN(x.status) = MAX(x.status), MAX(x.status),
       GROUP_CONCAT(x.status ORDER BY x.task_id SEPARATOR ' | '))                        AS status,
    COUNT(*)                                                                            AS so_luong_task,
    '${sync_ts}'                                                                        AS sync_date

FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_ubndtp` x

WHERE x.id_cha IS NOT NULL

GROUP BY x.id_cha

/* UPSERT theo khóa duy nhất id_cha thay cho TRUNCATE + INSERT: bảng không bị rỗng giữa chu kỳ.
   Nhóm không còn tồn tại bị xóa ở bước sau (sync_date < ${sync_ts}). */
ON DUPLICATE KEY UPDATE
    id_truc_giao = VALUES(id_truc_giao),
    truc_giao = VALUES(truc_giao),
    nhom_van_ban = VALUES(nhom_van_ban),
    linh_vuc = VALUES(linh_vuc),
    chu_de = VALUES(chu_de),
    muc_do_uu_tien = VALUES(muc_do_uu_tien),
    nv_quantam = VALUES(nv_quantam),
    ma_nhiem_vu = VALUES(ma_nhiem_vu),
    ten_nhiem_vu = VALUES(ten_nhiem_vu),
    van_ban_giao = VALUES(van_ban_giao),
    id_don_vi_chu_tri = VALUES(id_don_vi_chu_tri),
    ten_don_vi_chu_tri = VALUES(ten_don_vi_chu_tri),
    lanh_dao_don_vi_va_chuyen_vien = VALUES(lanh_dao_don_vi_va_chuyen_vien),
    ngay_giao = VALUES(ngay_giao),
    han_xu_ly = VALUES(han_xu_ly),
    ngay_hoan_thanh = VALUES(ngay_hoan_thanh),
    ngay_xoa = VALUES(ngay_xoa),
    tinh_trang = VALUES(tinh_trang),
    tinh_hinh_ket_qua = VALUES(tinh_hinh_ket_qua),
    ld_ubnd = VALUES(ld_ubnd),
    ld_van_phong = VALUES(ld_van_phong),
    phong_chuyen_mon_theo_doi = VALUES(phong_chuyen_mon_theo_doi),
    chuyen_vien_vp_theo_doi = VALUES(chuyen_vien_vp_theo_doi),
    task_id = VALUES(task_id),
    status = VALUES(status),
    so_luong_task = VALUES(so_luong_task),
    sync_date = VALUES(sync_date);
