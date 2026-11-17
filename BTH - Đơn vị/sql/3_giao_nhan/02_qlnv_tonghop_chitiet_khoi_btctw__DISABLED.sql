-- NiFi processor: qlnv_tonghop_chitiet_khoi_btctw
-- id: 142f3edf-6ef6-1fc2-a5d2-e5db13304cb1  group: Giao + Nhận NV (142f3ed8-6ef6-1fc2-d06d-d0c4aa837b0b)
-- state: DISABLED  schedule: TIMER_DRIVEN 0 sec

-- ===== SQL select query =====
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw;

INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi_btctw
SELECT * 
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom t

WHERE t.don_vi_cap_01 = 'BAN TỔ CHỨC TRUNG ƯƠNG' 
;
