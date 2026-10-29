SET SESSION group_concat_max_len = 1048576;

/* Gộp các nhiệm vụ BCĐ 57 cấp TP giống nhau (cùng tên nhiệm vụ + đơn vị giao + văn bản giao) thành 1 dòng, theo id_cha
   (id_cha = task_id nhỏ nhất của nhóm + '_GR', do luồng BTH - Chi tiết cập nhật vào bảng chi tiết).
   Logic gộp giống qlnv_tonghop_gop_nvgiao_pth_ubndtp: cột theo từng task giống nhau giữ 1 giá trị,
   khác nhau nối ' | ' theo task_id (KHÔNG DISTINCT để các list khớp vị trí); cột phân loại nối DISTINCT. */
INSERT INTO `datamart_hanoi`.`qlnv_chitiet_gop_bcd57_cap_tp` (
    id_cha, task_id, so_luong_task, status, id_truc_giao, truc_giao,
    nguon_giao, van_ban_giao, loai_van_ban, ma_nhiem_vu, ten_nhiem_vu, chu_de,
    nhom_nhiem_vu, id_don_vi_giao, don_vi_giao, id_nguoi_giao, nguoi_giao, id_don_vi_chu_tri,
    ten_don_vi_chu_tri, ten_don_vi_thuc_hien, id_nguoi_thuc_hien, nguoi_thuc_hien, lanh_dao_ban_phu_trach, ngay_giao,
    han_xu_ly, ngay_hoan_thanh, ngay_chap_nhan, ngay_xoa, tinh_trang, tien_do,
    ket_qua_thuc_hien, kho_khan_vuong_mac, de_xuat_kien_nghi, sync_date
)

SELECT
    /* 1. KHÓA NHÓM & TRẠNG THÁI */
    x.id_cha                                                                         AS id_cha,
    GROUP_CONCAT(x.task_id ORDER BY x.task_id SEPARATOR ' | ')                       AS task_id,
    COUNT(*)                                                                         AS so_luong_task,
    IF(MIN(COALESCE(x.status, '-')) = MAX(COALESCE(x.status, '-')), MAX(x.status),
       GROUP_CONCAT(COALESCE(x.status, '-') ORDER BY x.task_id SEPARATOR ' | '))     AS status,

    /* 2. TRỤC GIAO, NGUỒN GIAO & VĂN BẢN GIAO (cùng đơn vị giao + văn bản giao trong nhóm) */
    MAX(x.id_truc_giao)                                                              AS id_truc_giao,
    GROUP_CONCAT(DISTINCT x.truc_giao ORDER BY x.truc_giao SEPARATOR ' | ')          AS truc_giao,
    GROUP_CONCAT(DISTINCT x.nguon_giao ORDER BY x.nguon_giao SEPARATOR ' | ')        AS nguon_giao,
    MAX(x.van_ban_giao)                                                              AS van_ban_giao,
    GROUP_CONCAT(DISTINCT x.loai_van_ban ORDER BY x.loai_van_ban SEPARATOR ' | ')    AS loai_van_ban,

    /* 3. THÔNG TIN NHIỆM VỤ & CHỦ ĐỀ */
    IF(MIN(COALESCE(x.ma_nhiem_vu, '-')) = MAX(COALESCE(x.ma_nhiem_vu, '-')), MAX(x.ma_nhiem_vu),
       GROUP_CONCAT(COALESCE(x.ma_nhiem_vu, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS ma_nhiem_vu,
    MAX(x.ten_nhiem_vu)                                                              AS ten_nhiem_vu,
    GROUP_CONCAT(DISTINCT x.chu_de ORDER BY x.chu_de SEPARATOR ' | ')                AS chu_de,
    GROUP_CONCAT(DISTINCT x.nhom_nhiem_vu ORDER BY x.nhom_nhiem_vu SEPARATOR ' | ')  AS nhom_nhiem_vu,

    /* ĐƠN VỊ GIAO & NGƯỜI GIAO */
    MAX(x.id_don_vi_giao)                                                            AS id_don_vi_giao,
    MAX(x.don_vi_giao)                                                               AS don_vi_giao,
    IF(MIN(COALESCE(x.id_nguoi_giao, '-')) = MAX(COALESCE(x.id_nguoi_giao, '-')), MAX(x.id_nguoi_giao),
       GROUP_CONCAT(COALESCE(x.id_nguoi_giao, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS id_nguoi_giao,
    IF(MIN(COALESCE(x.nguoi_giao, '-')) = MAX(COALESCE(x.nguoi_giao, '-')), MAX(x.nguoi_giao),
       GROUP_CONCAT(COALESCE(x.nguoi_giao, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS nguoi_giao,

    /* 4. ĐƠN VỊ CHỦ TRÌ / THỰC HIỆN */
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
    ), '')                                                                           AS ten_don_vi_chu_tri,
    IF(MIN(COALESCE(x.ten_don_vi_thuc_hien, '-')) = MAX(COALESCE(x.ten_don_vi_thuc_hien, '-')), MAX(x.ten_don_vi_thuc_hien),
       GROUP_CONCAT(COALESCE(x.ten_don_vi_thuc_hien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS ten_don_vi_thuc_hien,
    IF(MIN(COALESCE(x.id_nguoi_thuc_hien, '-')) = MAX(COALESCE(x.id_nguoi_thuc_hien, '-')), MAX(x.id_nguoi_thuc_hien),
       GROUP_CONCAT(COALESCE(x.id_nguoi_thuc_hien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS id_nguoi_thuc_hien,
    IF(MIN(COALESCE(x.nguoi_thuc_hien, '-')) = MAX(COALESCE(x.nguoi_thuc_hien, '-')), MAX(x.nguoi_thuc_hien),
       GROUP_CONCAT(COALESCE(x.nguoi_thuc_hien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS nguoi_thuc_hien,
    IF(MIN(COALESCE(x.lanh_dao_ban_phu_trach, '-')) = MAX(COALESCE(x.lanh_dao_ban_phu_trach, '-')), MAX(x.lanh_dao_ban_phu_trach),
       GROUP_CONCAT(COALESCE(x.lanh_dao_ban_phu_trach, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS lanh_dao_ban_phu_trach,

    /* 5. MỐC THỜI GIAN (ngày hoàn thành: mỗi đơn vị khác nhau => luôn list theo task) */
    IF(MIN(COALESCE(x.ngay_giao, '-')) = MAX(COALESCE(x.ngay_giao, '-')), MAX(x.ngay_giao),
       GROUP_CONCAT(COALESCE(x.ngay_giao, '-') ORDER BY x.task_id SEPARATOR ' | '))  AS ngay_giao,
    IF(MIN(COALESCE(x.han_xu_ly, '-')) = MAX(COALESCE(x.han_xu_ly, '-')), MAX(x.han_xu_ly),
       GROUP_CONCAT(COALESCE(x.han_xu_ly, '-') ORDER BY x.task_id SEPARATOR ' | '))  AS han_xu_ly,
    GROUP_CONCAT(COALESCE(x.ngay_hoan_thanh, '-') ORDER BY x.task_id SEPARATOR ' | ') AS ngay_hoan_thanh,
    IF(MIN(COALESCE(x.ngay_chap_nhan, '-')) = MAX(COALESCE(x.ngay_chap_nhan, '-')), MAX(x.ngay_chap_nhan),
       GROUP_CONCAT(COALESCE(x.ngay_chap_nhan, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS ngay_chap_nhan,
    IF(MIN(COALESCE(x.ngay_xoa, '-')) = MAX(COALESCE(x.ngay_xoa, '-')), MAX(x.ngay_xoa),
       GROUP_CONCAT(COALESCE(x.ngay_xoa, '-') ORDER BY x.task_id SEPARATOR ' | '))   AS ngay_xoa,

    /* 6. TÌNH TRẠNG: tình trạng xấu nhất trong nhóm
       VD: Đã hoàn thành | Đã hoàn thành | Chưa hoàn thành trong hạn => Chưa hoàn thành trong hạn */
    CASE
        WHEN MAX(x.tinh_trang = 'Chưa hoàn thành quá hạn')   = 1 THEN 'Chưa hoàn thành quá hạn'
        WHEN MAX(x.tinh_trang = 'Chưa hoàn thành trong hạn') = 1 THEN 'Chưa hoàn thành trong hạn'
        WHEN MAX(x.tinh_trang = 'Thường xuyên')              = 1 THEN 'Thường xuyên'
        WHEN MAX(x.tinh_trang = 'Đã hoàn thành')             = 1 THEN 'Đã hoàn thành'
    END                                                                              AS tinh_trang,
    /* Tiến độ nhóm = trung bình tiến độ các task */
    ROUND(AVG(x.tien_do))                                                            AS tien_do,

    /* 7. KẾT QUẢ, KHÓ KHĂN, ĐỀ XUẤT */
    IF(MIN(COALESCE(x.ket_qua_thuc_hien, '-')) = MAX(COALESCE(x.ket_qua_thuc_hien, '-')), MAX(x.ket_qua_thuc_hien),
       GROUP_CONCAT(COALESCE(x.ket_qua_thuc_hien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS ket_qua_thuc_hien,
    IF(MIN(COALESCE(x.kho_khan_vuong_mac, '-')) = MAX(COALESCE(x.kho_khan_vuong_mac, '-')), MAX(x.kho_khan_vuong_mac),
       GROUP_CONCAT(COALESCE(x.kho_khan_vuong_mac, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS kho_khan_vuong_mac,
    IF(MIN(COALESCE(x.de_xuat_kien_nghi, '-')) = MAX(COALESCE(x.de_xuat_kien_nghi, '-')), MAX(x.de_xuat_kien_nghi),
       GROUP_CONCAT(COALESCE(x.de_xuat_kien_nghi, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS de_xuat_kien_nghi,

    '${sync_ts}'                                                                     AS sync_date

FROM `datamart_hanoi`.`qlnv_chitiet_bcd57_cap_tp` x
WHERE x.id_cha IS NOT NULL

GROUP BY x.id_cha

/* UPSERT theo PK id_cha: bảng không bị rỗng giữa chu kỳ.
   Nhóm không còn tồn tại bị xóa ở bước sau (sync_date < ${sync_ts}). */
ON DUPLICATE KEY UPDATE
    task_id = VALUES(task_id),
    so_luong_task = VALUES(so_luong_task),
    status = VALUES(status),
    id_truc_giao = VALUES(id_truc_giao),
    truc_giao = VALUES(truc_giao),
    nguon_giao = VALUES(nguon_giao),
    van_ban_giao = VALUES(van_ban_giao),
    loai_van_ban = VALUES(loai_van_ban),
    ma_nhiem_vu = VALUES(ma_nhiem_vu),
    ten_nhiem_vu = VALUES(ten_nhiem_vu),
    chu_de = VALUES(chu_de),
    nhom_nhiem_vu = VALUES(nhom_nhiem_vu),
    id_don_vi_giao = VALUES(id_don_vi_giao),
    don_vi_giao = VALUES(don_vi_giao),
    id_nguoi_giao = VALUES(id_nguoi_giao),
    nguoi_giao = VALUES(nguoi_giao),
    id_don_vi_chu_tri = VALUES(id_don_vi_chu_tri),
    ten_don_vi_chu_tri = VALUES(ten_don_vi_chu_tri),
    ten_don_vi_thuc_hien = VALUES(ten_don_vi_thuc_hien),
    id_nguoi_thuc_hien = VALUES(id_nguoi_thuc_hien),
    nguoi_thuc_hien = VALUES(nguoi_thuc_hien),
    lanh_dao_ban_phu_trach = VALUES(lanh_dao_ban_phu_trach),
    ngay_giao = VALUES(ngay_giao),
    han_xu_ly = VALUES(han_xu_ly),
    ngay_hoan_thanh = VALUES(ngay_hoan_thanh),
    ngay_chap_nhan = VALUES(ngay_chap_nhan),
    ngay_xoa = VALUES(ngay_xoa),
    tinh_trang = VALUES(tinh_trang),
    tien_do = VALUES(tien_do),
    ket_qua_thuc_hien = VALUES(ket_qua_thuc_hien),
    kho_khan_vuong_mac = VALUES(kho_khan_vuong_mac),
    de_xuat_kien_nghi = VALUES(de_xuat_kien_nghi),
    sync_date = VALUES(sync_date);
