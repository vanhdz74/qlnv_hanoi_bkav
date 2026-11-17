-- BCĐ 57 — query 2/2 · CHỈ CÂU SELECT, chạy xem kết quả trước
-- Đọc bảng qlnv_bcd57_nhiemvu → chỉ chạy được SAU khi query 1 đã nạp xong.
-- Muốn thử trước khi có bảng: thay `FROM qlnv_bcd57_nhiemvu nv` bằng
--   FROM ( <dán toàn bộ SELECT của qlnv_bcd57_nhiemvu_select.sql> ) nv
-- Ghi chú: qlnv_bcd57_note.md

SELECT
    nv.ma_nhiem_vu                                            AS ma_nhiem_vu,
    nv.noi_dung                                               AS noi_dung,
    nv.lanh_dao_chi_dao                                       AS lanh_dao_chi_dao,
    nv.don_vi_thuc_hien                                       AS don_vi_thuc_hien,
    nv.so_van_ban                                             AS so_van_ban,
    nv.han_hoan_thanh                                         AS han_hoan_thanh,
    nv.han_hien_thi                                           AS han_hien_thi,
    nv.trang_thai                                             AS trang_thai,
    nv.ten_trang_thai                                         AS ten_trang_thai,
    nv.muc_do_canh_bao                                        AS muc_do_canh_bao,
    nv.so_ngay                                                AS so_ngay,
    nv.nhan_canh_bao                                          AS nhan_canh_bao,

    CASE nv.muc_do_canh_bao WHEN 'overdue' THEN '#e0453f'
                            ELSE                '#f2a325' END AS mau_vien,
    CASE nv.muc_do_canh_bao WHEN 'overdue' THEN '#c23934'
                            ELSE                '#b7791f' END AS mau_chu_nhan,
    CASE nv.muc_do_canh_bao WHEN 'overdue' THEN '#fdecec'
                            ELSE                '#fff5e2' END AS mau_nen_nhan,

    CASE WHEN nv.muc_do_canh_bao = 'overdue' THEN 1 ELSE 0 END AS la_qua_han,
    CASE WHEN nv.muc_do_canh_bao = 'soon'    THEN 1 ELSE 0 END AS la_gan_han,

    DATE_FORMAT(NOW(),'%Y-%m-%d %H:%i:%s')                    AS syncdate

FROM qlnv_bcd57_nhiemvu nv
WHERE nv.can_don_doc = 1
ORDER BY nv.so_ngay DESC, nv.han_hoan_thanh
;
