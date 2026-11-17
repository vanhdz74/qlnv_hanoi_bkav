/* Kiểm tra tab Xã/Phường */

/* K1. Số NV theo nguồn giao */
SELECT nguon_giao, COUNT(*) AS so_nv
FROM `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong`
GROUP BY nguon_giao WITH ROLLUP;

/* K2. Tên xã/phường lấy được chưa (ten_don_vi_chu_tri trống = thiếu trong department) */
SELECT id_don_vi_chu_tri, ten_don_vi_chu_tri, ten_don_vi_thuc_hien, COUNT(*) AS so_nv
FROM `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong`
GROUP BY 1, 2, 3
ORDER BY so_nv DESC;

/* K3. Task có ở cả 2 tab: xã/phường chỉ giao hoặc tham gia, không phải đơn vị nhận (được phép) */
SELECT COUNT(*) AS so_trung
FROM `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_xaphuong` x
INNER JOIN `db_theodoinv_hn_test_data`.`qlnv_chitiet_bcd57_cap_tp` c
        ON c.task_id = x.task_id
       AND c.nguon_giao <> 'Nhiệm vụ Trung ương';
