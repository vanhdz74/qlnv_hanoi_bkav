# Bảng `datamart_hanoi.qlnv_chitiet_bcd57`: nguồn và cách lấy từng cột

- **Nguồn:** `db_theodoinv_hn`. Bảng chính là `qlnv_task` (bí danh `t`).
- **Hạt:** mỗi nhiệm vụ 1 dòng.
- **SQL:** [qlnv_chitiet_bcd57.sql](qlnv_chitiet_bcd57.sql)

## Điều kiện lọc nhiệm vụ

Một nhiệm vụ trong `qlnv_task` được đưa vào bảng khi thỏa **cả 4** điều kiện sau:

| # | Điều kiện | Viết trong SQL |
|---|---|---|
| 1 | Chưa xóa, không phải trạng thái 5 | `t.DeletedDate IS NULL` và `t.Status <> 5` |
| 2 | Xác định được tình trạng: đang thực hiện, **hoặc** đã hoàn thành và thuộc một trong 3 trường hợp: nhiệm vụ thường xuyên, không có hạn, hoặc có ngày hoàn thành/duyệt | `t.Status IN (-1,0,1,2)` **hoặc** (`t.Status IN (3,4)` và (`IsRecurring = 1` hoặc `ExpireDate IS NULL` hoặc `COALESCE(CompletedDate, ApprovedDate) IS NOT NULL`)) |
| 3 | Thuộc nghị quyết BCĐ 57 | Có dòng trong `qlnv_task_resolution` nối sang `qlnv_resolution` với `ResolutionGroupId = 55` và `DeletedDate IS NULL` |
| 4 | Có đi qua UBND TP: thỏa **một trong** 4 nhánh ở bảng dưới | |

| Nhánh | Điều kiện |
|---|---|
| Giao | `t.AssignDepartment LIKE '490.698%'`: UBND TP hoặc đơn vị trực thuộc giao |
| Nhận trực tiếp | `t.TargetDepartment = '490.698'`: UBND TP nhận |
| Nhận tại phòng của Văn phòng | `t.TargetDepartment LIKE '490.698.752.%'` **và** trong `qlnv_task_user` của nhiệm vụ có dòng `DepartmentId = '490.698.752'` |
| Nhận qua UBND TP | `t.TargetDepartment LIKE '490.698.%'` (trừ `490.698.752.%`) **và** trong `qlnv_task_user` có dòng `DepartmentId = '490.698'` |

Mã đơn vị: `490.698` là UBND TP, `490.698.752` là Văn phòng UBND TP, `490.698.752.x` là các phòng của Văn phòng, `490.698.x` là các sở, ngành, đơn vị trực thuộc UBND TP.

Điều kiện 3 và các nhánh dùng `EXISTS`, nên một nhiệm vụ thuộc nhiều nghị quyết vẫn chỉ ra 1 dòng.

## Các bảng nối thêm

| Bí danh | Bảng nguồn | Nối theo |
|---|---|---|
| `d_assign_cap2` | `department` | `id` = số thứ 2 của `t.AssignDepartment` (ví dụ `490.698.xxx` → `698`) |
| `d_assign` | `department` | `id` = số cuối của `t.AssignDepartment` |
| `d_cap` | `department` | `id` = số thứ 3 của `t.TargetDepartment` |
| `d_donvi` | `department` | `id` = số cuối của `t.TargetDepartment` |
| `u_assign` | `qlnv_user` | `eGovUserId = t.AssignUser` |
| `u_target` | `qlnv_user` | `eGovUserId = t.TargetUser` |
| *(subquery)* | `qlnv_report` | Báo cáo mới nhất của nhiệm vụ: `TaskId = t.TaskId`, chưa xóa, sắp `CreatedDate DESC, ReportId DESC`, lấy 1 dòng |

Các bảng `department` chỉ lấy dòng có `IsDelete = 0`.

## Các cột

| Cột | Ý nghĩa | Lấy từ đâu / cách tính |
|---|---|---|
| `task_id` | ID nhiệm vụ | `t.TaskId` |
| `status` | Trạng thái gốc | `t.Status` |
| `id_truc_giao` | Mã trục giao | 2 cấp đầu của `t.AssignDepartment` (ví dụ `490.698`) |
| `truc_giao` | Tên trục giao | `t.AssignOrganization`; nếu trống thì `d_assign_cap2.name` |
| `van_ban_giao` | Văn bản giao | `t.DocCode` |
| `ma_nhiem_vu` | Mã nhiệm vụ | `t.Code` |
| `ten_nhiem_vu` | Tên nhiệm vụ | `t.Title` |
| `chu_de` | Chủ đề | `t.NameGroup`; nếu trống thì `'Chưa phân loại'` |
| `id_don_vi_giao` | Mã đơn vị giao | `t.AssignDepartment` |
| `don_vi_giao` | Tên đơn vị giao | `d_assign.name`; nếu trống thì `t.AssignOrganization` |
| `id_nguoi_giao` | ID người giao | `t.AssignUser` |
| `nguoi_giao` | Tên người giao | `u_assign.eGovUserFullname` |
| `id_don_vi_chu_tri` | Mã đơn vị chủ trì | `t.TargetDepartment` |
| `ten_don_vi_chu_tri` | Tên đơn vị chủ trì | Lần lượt lấy giá trị đầu tiên không trống: `t.ResponsibleUnit` → `t.TargetOrganization` → `d_cap.name` → `d_donvi.name` |
| `ten_don_vi_thuc_hien` | Tên đơn vị thực hiện | Lần lượt lấy giá trị đầu tiên không trống: `d_donvi.name` → `t.ResponsibleUnit` → `t.TargetOrganization` |
| `id_nguoi_thuc_hien` | ID người thực hiện | `t.TargetUser` |
| `nguoi_thuc_hien` | Tên người thực hiện | `u_target.eGovUserFullname` |
| `lanh_dao_ban_phu_trach` | Lãnh đạo ban phụ trách | `u_target.eGovUserPositionName` (chức vụ người thực hiện); nếu trống thì `t.ChargeUser` (đây là ID) |
| `ngay_giao` | Ngày giao | `t.StartedDate`, định dạng `dd/mm/yyyy` |
| `han_xu_ly` | Hạn xử lý | `t.ExpireDate`, định dạng `dd/mm/yyyy` |
| `ngay_hoan_thanh` | Ngày hoàn thành | `t.CompletedDate`, định dạng `dd/mm/yyyy` |
| `ngay_chap_nhan` | Ngày duyệt | `t.ApprovedDate`, định dạng `dd/mm/yyyy` |
| `ngay_xoa` | Ngày xóa | `t.DeletedDate`, định dạng `dd/mm/yyyy`. Luôn trống vì chỉ lấy nhiệm vụ chưa xóa. |
| `tinh_trang` | Tình trạng | Xem bảng bên dưới |
| `ket_qua_thuc_hien` | Kết quả thực hiện | `Content` của báo cáo mới nhất; nếu không có thì `t.Content`; nếu vẫn không có thì `'—'` |
| `kho_khan_vuong_mac` | Khó khăn, vướng mắc | `Difficulty` của báo cáo mới nhất; nếu trống thì `'—'` |
| `de_xuat_kien_nghi` | Đề xuất, kiến nghị | `Suggestion` của báo cáo mới nhất; nếu trống thì `'—'` |
| `sync_date` | Thời điểm đồng bộ | `NOW()` |

## Cột `tinh_trang`

Xét từ trên xuống, gặp điều kiện nào đúng trước thì lấy giá trị đó:

| Giá trị | Điều kiện |
|---|---|
| Đã hoàn thành | `t.Status` là 3 hoặc 4, có hạn (`ExpireDate`) và có ngày hoàn thành hoặc ngày duyệt |
| Thường xuyên | Không có hạn (`ExpireDate` trống) |
| Chưa hoàn thành trong hạn | `t.Status` là -1, 0, 1 hoặc 2, và hạn ≥ hôm nay |
| Chưa hoàn thành quá hạn | `t.Status` là -1, 0, 1 hoặc 2, và hạn < hôm nay |
