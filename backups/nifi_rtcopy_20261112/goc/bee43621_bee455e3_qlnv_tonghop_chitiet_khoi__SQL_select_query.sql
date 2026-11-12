TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_khoi;

INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_khoi
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