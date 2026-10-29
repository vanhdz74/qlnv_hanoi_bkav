SET SESSION group_concat_max_len = 1048576;

/* Bảng nguồn đang bị luồng chi tiết TRUNCATE (chưa INSERT xong) => giữ nguyên dữ liệu cũ, không xóa.
   PutSQL autocommit = false => DELETE + INSERT chung 1 transaction, bảng gộp không bao giờ trống. */
DELETE FROM `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_pth_ubndtp`
WHERE EXISTS (SELECT 1 FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_ubndtp` LIMIT 1);

INSERT INTO `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_pth_ubndtp` (
    id_truc_giao, truc_giao, nhom_van_ban, linh_vuc, chu_de, muc_do_uu_tien, nv_quantam,
    ma_nhiem_vu, ten_nhiem_vu, van_ban_giao,
    id_don_vi_chu_tri, ten_don_vi_chu_tri, lanh_dao_don_vi_va_chuyen_vien,
    ngay_giao, han_xu_ly, ngay_hoan_thanh, ngay_xoa,
    tinh_trang, tinh_hinh_ket_qua,
    ld_ubnd, ld_van_phong, phong_chuyen_mon_theo_doi, chuyen_vien_vp_theo_doi,
    id_cha, task_id, status, so_luong_task, sync_date
)
/* GỘP NHIỆM VỤ GIAO UBND THEO (TÊN NHIỆM VỤ, TRỤC GIAO)
   Cùng 1 nhiệm vụ do 1 trục giao nhưng giao cho nhiều đơn vị => nhiều task, gộp lại 1 dòng.
   Nguồn: bảng datamart_hanoi.qlnv_tonghop_chitiet_nvgiao_pth_ubndtp (đã được luồng NiFi chi tiết nạp sẵn
   từ qlnv_tonghop_chitiet_nvgiao_pth_ubndtp.sql) => không tính lại từ db gốc (~13s -> ~2-3s).
   Cột không group by => danh sách tổng hợp các task, ngăn cách ' | '.
   Cột theo từng task (mã, đơn vị, ngày, tình trạng, ...) KHÔNG DISTINCT, sắp theo task_id để các list khớp vị trí;
   nếu mọi task trong nhóm cùng 1 giá trị (MIN = MAX) thì chỉ hiện 1 giá trị (tất cả NULL => NULL), không list.
   Riêng ngay_hoan_thanh: mỗi đơn vị khác nhau => luôn list theo task.
   tinh_trang: lấy 1 tình trạng xấu nhất của nhóm (quá hạn > trong hạn > thường xuyên > đã hoàn thành). */
SELECT
    /* 1. TRỤC GIAO & NHÓM VĂN BẢN */
    x.id_truc_giao,
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
    x.ten_nhiem_vu,
    GROUP_CONCAT(DISTINCT x.van_ban_giao  ORDER BY x.van_ban_giao  SEPARATOR ' | ')     AS van_ban_giao,

    /* 3. ĐƠN VỊ CHỦ TRÌ */
    IF(MIN(COALESCE(x.id_don_vi_chu_tri, '-')) = MAX(COALESCE(x.id_don_vi_chu_tri, '-')), MAX(x.id_don_vi_chu_tri),
       GROUP_CONCAT(COALESCE(x.id_don_vi_chu_tri, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS id_don_vi_chu_tri,
    IF(MIN(COALESCE(x.ten_don_vi_chu_tri, '-')) = MAX(COALESCE(x.ten_don_vi_chu_tri, '-')), MAX(x.ten_don_vi_chu_tri),
       GROUP_CONCAT(COALESCE(x.ten_don_vi_chu_tri, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS ten_don_vi_chu_tri,
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
       id_cha = task_id đầu tiên (nhỏ nhất) của nhóm + '_GR', khớp id_cha bên qlnv_chitiet_nvgiao_pth_ubndtp */
    CONCAT(MIN(x.task_id), '_GR')                                                       AS id_cha,
    GROUP_CONCAT(x.task_id ORDER BY x.task_id SEPARATOR ' | ')                          AS task_id,
    IF(MIN(x.status) = MAX(x.status), MAX(x.status),
       GROUP_CONCAT(x.status ORDER BY x.task_id SEPARATOR ' | '))                        AS status,
    COUNT(*)                                                                            AS so_luong_task,
    NOW()                                                                               AS sync_date

FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_nvgiao_pth_ubndtp` x

GROUP BY x.ten_nhiem_vu, x.id_truc_giao;
