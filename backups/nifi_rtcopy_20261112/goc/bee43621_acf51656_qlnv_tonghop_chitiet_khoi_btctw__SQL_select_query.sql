TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw;

INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw
SELECT * 
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom t

WHERE t.don_vi_cap_01 = 'BAN TỔ CHỨC TRUNG ƯƠNG' 
;