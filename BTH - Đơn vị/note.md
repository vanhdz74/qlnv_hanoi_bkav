loaicap_dvgiao <> 'Đảng bộ trực thuộc, loaicapcha = 'UBND Thành phố' AND loaicap NOT IN ('Sở ngành','Xã, Phường',…)

bạn cần check lại ý tôi: trên đây là lấy ra các id cấp nên là giống như like. Có vẻ sai về mặt logic. Ý là chỉ loại bỏ các trường hợp mà cấp 3 là Đảng bộ trực thuộc 

# id	code	departmentextid	departmentpath	DeptFullName	DeptFullNameParent	DicstrinstCode	domain	IsDelete	level	name	ObjectGuid	parent_id	ProvinceCode	shortname	status	unit_level	UserManager	createBy	create_time	modify_time	updateBy	parent	SyncedAt	sort_order	manual_parent	IsActive
1558		490.695.1558	THÀNH PHỐ HÀ NỘI\Thành ủy Hà Nội\Đảng bộ trực thuộc					0	3	Đảng bộ trực thuộc		695		Đảng bộ trực thuộc	1			896	2025-11-20 18:27:33	2026-08-02 23:31:23	896		2026-08-02 23:31:23	6	0	1

chứ những id ví dụ 490.695.1558.1571, ... thì vẫn lấy mà 
bên ubnd hay các logic khác cũng vậy 

bạn xem có đúng ko, cách sửa đúng check nifi
https://bdw-theodoinhiemvu.hanoi.gov.vn/nifi/?processGroupId=142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028&componentIds=