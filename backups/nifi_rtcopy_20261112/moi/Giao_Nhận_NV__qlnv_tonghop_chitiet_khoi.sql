/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tonghop_chitiet_khoi__stg LIKE datamart_hanoi.qlnv_tonghop_chitiet_khoi;
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi__stg;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi__stg
SELECT * 
FROM datamart_hanoi.qlnv_tonghop_chitiet_nhom t

WHERE t.don_vi_cap_01 = 'THÀNH PHỐ HÀ NỘI' 
AND (
    (
				t.NhomGiaoNhan = 'Đã giao'
    )
OR
    (
        t.NhomGiaoNhan = 'Được giao'
				AND ( 
							(	
									t.loaicapcha = 'UBND Thành phố'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối')
							 AND ( 
										t.donvi = 'UBND Thành phố'
										OR t.loaicap IN ('Xã, Phường', 'Sở ngành', 'Nhóm Sở ngành mở rộng')
									 )
							)
						OR
							(	
									t.loaicapcha = 'HĐND Thành phố'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối', 'Nhiệm vụ nội bộ')
							 AND t.donvi = 'HĐND Thành phố'
							)
						OR
							(	
									t.loaicapcha = 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
							 AND t.NhomPhamViNhiemVu IN ('Nhiệm vụ ngoài khối')
							 AND t.donvi REGEXP 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
							)
						)
		)
		)
;
/* Đổi chỗ nguyên tử; chờ khóa tối đa 10s để không chặn dashboard */
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi TO datamart_hanoi.qlnv_tonghop_chitiet_khoi__old, datamart_hanoi.qlnv_tonghop_chitiet_khoi__stg TO datamart_hanoi.qlnv_tonghop_chitiet_khoi, datamart_hanoi.qlnv_tonghop_chitiet_khoi__old TO datamart_hanoi.qlnv_tonghop_chitiet_khoi__stg;
SET SESSION lock_wait_timeout = 31536000;