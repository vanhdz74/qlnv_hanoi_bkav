UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_giaonv c
    ON c.ma_nv_cha = t.Ma
SET t.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi'
WHERE t.ma_nv_cha IS NOT NULL 
   OR c.ma_nv_cha IS NOT NULL;
	 
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_giaonv t2
    ON t.tennv_viettat = t2.tennv_viettat
    AND t.Ma <> t2.Ma
SET t.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ'
WHERE t2.Ma IS NULL
  AND t.NhomCauTrucNhiemVu IS NULL;
	
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_giaonv
SET NhomCauTrucNhiemVu = 'Chưa xác định'
WHERE NhomCauTrucNhiemVu IS NULL;