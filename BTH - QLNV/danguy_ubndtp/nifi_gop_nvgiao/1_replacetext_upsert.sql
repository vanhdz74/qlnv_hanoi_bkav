SET SESSION group_concat_max_len = 1048576;

/* Gộp các nhiệm vụ giao giống nhau (cùng tên nhiệm vụ + bên giao + văn bản giao) thành 1 dòng, theo id_cha
   (id_cha = task_id nhỏ nhất của nhóm + '_GR', do luồng BTH - Details cập nhật vào bảng chi tiết).
   Logic gộp giống qlnv_tonghop_gop_nvgiao_pth_ubndtp: giống nhau giữ 1 giá trị, khác nhau nối ' | ' theo task_id. */
INSERT INTO `datamart_hanoi`.`qlnv_tonghop_gop_nvgiao_ubndtp` (
    id_cha, task_id, so_luong_task,
    loai_nhiem_vu, hinh_thuc_giao,
    ben_giao_id, ben_giao_name, ben_nhan_id, ben_nhan_name,
    ten_task, nhom_nhiem_vu, stt_nhiem_vu_theo_doi, van_ban_giao, noi_dung_nhiem_vu,
    to_chuc_dang_chu_tri, lanh_dao_don_vi_va_chuyen_vien, cap_giao_nhiem_vu, lanh_dao_giao,
    ngay_bat_dau, thoi_han, ngay_het_han, ngay_hoan_thanh, nam_het_han, thang_het_han,
    tinh_trang, tinh_hinh_ket_qua_thuc_hien,
    ld_ubnd, ld_van_phong_ubnd, ban_chuyen_mon, chuyen_vien_theo_doi,
    sync_date
)

SELECT
    /* 1. KHÓA NHÓM */
    x.id_cha,
    GROUP_CONCAT(x.task_id ORDER BY x.task_id SEPARATOR ' | ')                          AS task_id,
    COUNT(*)                                                                            AS so_luong_task,
    MAX(x.loai_nhiem_vu)                                                                AS loai_nhiem_vu,
    GROUP_CONCAT(DISTINCT x.hinh_thuc_giao ORDER BY x.hinh_thuc_giao SEPARATOR ' | ')  AS hinh_thuc_giao,

    /* 2. BÊN GIAO / BÊN NHẬN */
    MAX(x.ben_giao_id)                                                                  AS ben_giao_id,
    MAX(x.ben_giao_name)                                                                AS ben_giao_name,
    GROUP_CONCAT(DISTINCT x.ben_nhan_id   ORDER BY x.ben_nhan_id   SEPARATOR ' | ')    AS ben_nhan_id,
    GROUP_CONCAT(DISTINCT x.ben_nhan_name ORDER BY x.ben_nhan_name SEPARATOR ' | ')    AS ben_nhan_name,

    /* 3. NHIỆM VỤ & VĂN BẢN GIAO */
    MAX(x.ten_task)                                                                     AS ten_task,
    GROUP_CONCAT(DISTINCT x.nhom_nhiem_vu         ORDER BY x.nhom_nhiem_vu         SEPARATOR ' | ') AS nhom_nhiem_vu,
    GROUP_CONCAT(DISTINCT x.stt_nhiem_vu_theo_doi ORDER BY x.stt_nhiem_vu_theo_doi SEPARATOR ' | ') AS stt_nhiem_vu_theo_doi,
    GROUP_CONCAT(DISTINCT x.van_ban_giao          ORDER BY x.van_ban_giao          SEPARATOR ' | ') AS van_ban_giao,
    IF(MIN(COALESCE(x.noi_dung_nhiem_vu, '-')) = MAX(COALESCE(x.noi_dung_nhiem_vu, '-')), MAX(x.noi_dung_nhiem_vu),
       GROUP_CONCAT(COALESCE(x.noi_dung_nhiem_vu, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS noi_dung_nhiem_vu,

    /* 4. ĐƠN VỊ CHỦ TRÌ & LÃNH ĐẠO */
    GROUP_CONCAT(DISTINCT x.to_chuc_dang_chu_tri ORDER BY x.to_chuc_dang_chu_tri SEPARATOR ' | ') AS to_chuc_dang_chu_tri,
    IF(MIN(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-')) = MAX(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-')), MAX(x.lanh_dao_don_vi_va_chuyen_vien),
       GROUP_CONCAT(COALESCE(x.lanh_dao_don_vi_va_chuyen_vien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS lanh_dao_don_vi_va_chuyen_vien,
    GROUP_CONCAT(DISTINCT q.cap_giao_nhiem_vu ORDER BY q.cap_giao_nhiem_vu SEPARATOR ' | ') AS cap_giao_nhiem_vu,
    GROUP_CONCAT(DISTINCT q.lanh_dao_giao     ORDER BY q.lanh_dao_giao     SEPARATOR ' | ') AS lanh_dao_giao,

    /* 5. MỐC THỜI GIAN: giữ kiểu DATETIME để lọc/biểu đồ theo thời gian.
       Hạn = hạn sớm nhất của nhóm; ngày hoàn thành chỉ có khi cả nhóm đã hoàn thành */
    MIN(x.ngay_bat_dau)                                                                 AS ngay_bat_dau,
    MIN(x.thoi_han)                                                                     AS thoi_han,
    MIN(x.thoi_han)                                                                     AS ngay_het_han,
    IF(SUM(x.tinh_trang LIKE 'Hoàn thành%') = COUNT(*), MAX(x.ngay_hoan_thanh), NULL)   AS ngay_hoan_thanh,
    YEAR(MIN(x.thoi_han))                                                               AS nam_het_han,
    MONTH(MIN(x.thoi_han))                                                              AS thang_het_han,

    /* 6. TÌNH TRẠNG: tình trạng xấu nhất trong nhóm
       VD: Hoàn thành đúng hạn | Đang thực hiện trong hạn => Đang thực hiện trong hạn */
    CASE
        WHEN MAX(x.tinh_trang = 'Đang thực hiện quá hạn')      = 1 THEN 'Đang thực hiện quá hạn'
        WHEN MAX(x.tinh_trang = 'Đang thực hiện trong hạn')    = 1 THEN 'Đang thực hiện trong hạn'
        WHEN MAX(x.tinh_trang = 'Thường xuyên - Chưa báo cáo') = 1 THEN 'Thường xuyên - Chưa báo cáo'
        WHEN MAX(x.tinh_trang = 'Thường xuyên - Đã báo cáo')   = 1 THEN 'Thường xuyên - Đã báo cáo'
        WHEN MAX(x.tinh_trang = 'Hoàn thành quá hạn')          = 1 THEN 'Hoàn thành quá hạn'
        WHEN MAX(x.tinh_trang = 'Hoàn thành đúng hạn')         = 1 THEN 'Hoàn thành đúng hạn'
    END                                                                                 AS tinh_trang,
    IF(MIN(COALESCE(x.tinh_hinh_ket_qua_thuc_hien, '-')) = MAX(COALESCE(x.tinh_hinh_ket_qua_thuc_hien, '-')), MAX(x.tinh_hinh_ket_qua_thuc_hien),
       GROUP_CONCAT(COALESCE(x.tinh_hinh_ket_qua_thuc_hien, '-') ORDER BY x.task_id SEPARATOR ' | ')) AS tinh_hinh_ket_qua_thuc_hien,

    /* 7. LÃNH ĐẠO UBND / VĂN PHÒNG & CHUYÊN VIÊN THEO DÕI */
    GROUP_CONCAT(DISTINCT x.ld_ubnd              SEPARATOR ' | ')                       AS ld_ubnd,
    GROUP_CONCAT(DISTINCT x.ld_van_phong_ubnd    SEPARATOR ' | ')                       AS ld_van_phong_ubnd,
    GROUP_CONCAT(DISTINCT x.ban_chuyen_mon       SEPARATOR ' | ')                       AS ban_chuyen_mon,
    GROUP_CONCAT(DISTINCT x.chuyen_vien_theo_doi SEPARATOR ' | ')                       AS chuyen_vien_theo_doi,

    '${sync_ts}'                                                                        AS sync_date

FROM `datamart_hanoi`.`qlnv_tonghop_chitiet_ubndtp` x
LEFT JOIN `datamart_hanoi`.`qlnv_tonghop_tongquan_ubndtp` q
       ON q.task_id = x.task_id
WHERE x.id_cha IS NOT NULL

GROUP BY x.id_cha

/* UPSERT theo PK id_cha: bảng không bị rỗng giữa chu kỳ.
   Nhóm không còn tồn tại bị xóa ở bước sau (sync_date < ${sync_ts}). */
ON DUPLICATE KEY UPDATE
    task_id = VALUES(task_id),
    so_luong_task = VALUES(so_luong_task),
    loai_nhiem_vu = VALUES(loai_nhiem_vu),
    hinh_thuc_giao = VALUES(hinh_thuc_giao),
    ben_giao_id = VALUES(ben_giao_id),
    ben_giao_name = VALUES(ben_giao_name),
    ben_nhan_id = VALUES(ben_nhan_id),
    ben_nhan_name = VALUES(ben_nhan_name),
    ten_task = VALUES(ten_task),
    nhom_nhiem_vu = VALUES(nhom_nhiem_vu),
    stt_nhiem_vu_theo_doi = VALUES(stt_nhiem_vu_theo_doi),
    van_ban_giao = VALUES(van_ban_giao),
    noi_dung_nhiem_vu = VALUES(noi_dung_nhiem_vu),
    to_chuc_dang_chu_tri = VALUES(to_chuc_dang_chu_tri),
    lanh_dao_don_vi_va_chuyen_vien = VALUES(lanh_dao_don_vi_va_chuyen_vien),
    cap_giao_nhiem_vu = VALUES(cap_giao_nhiem_vu),
    lanh_dao_giao = VALUES(lanh_dao_giao),
    ngay_bat_dau = VALUES(ngay_bat_dau),
    thoi_han = VALUES(thoi_han),
    ngay_het_han = VALUES(ngay_het_han),
    ngay_hoan_thanh = VALUES(ngay_hoan_thanh),
    nam_het_han = VALUES(nam_het_han),
    thang_het_han = VALUES(thang_het_han),
    tinh_trang = VALUES(tinh_trang),
    tinh_hinh_ket_qua_thuc_hien = VALUES(tinh_hinh_ket_qua_thuc_hien),
    ld_ubnd = VALUES(ld_ubnd),
    ld_van_phong_ubnd = VALUES(ld_van_phong_ubnd),
    ban_chuyen_mon = VALUES(ban_chuyen_mon),
    chuyen_vien_theo_doi = VALUES(chuyen_vien_theo_doi),
    sync_date = VALUES(sync_date);
