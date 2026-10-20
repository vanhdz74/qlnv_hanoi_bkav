# Bảng chi tiết nhiệm vụ: Phòng Tổng hợp, VP UBND TP

Tài liệu mô tả 3 bảng chi tiết: nhiệm vụ **giao**, **nhận** và **chờ duyệt**.

- **Nguồn:** `db_theodoinv_hn`. Bảng chính là `qlnv_task` (bí danh `t`).
- **Đích:** `datamart_hanoi`.
- **Hạt:** mỗi nhiệm vụ 1 dòng (`GROUP BY t.TaskId`).
- **Cột:** 3 bảng có cùng tên cột, nhưng một số cột được lấy theo cách khác nhau giữa các bảng.

Mã đơn vị: `490.698` là UBND TP, `490.698.752` là Văn phòng UBND TP, `490.698.752.x` là các phòng của Văn phòng, `490.698.x` là các sở, ngành, đơn vị trực thuộc UBND TP, `490.695…` là khối Thành ủy.

Tên đơn vị lấy từ bảng `department`: lấy số ở cấp tương ứng của mã đơn vị làm `department.id`, chỉ lấy dòng có `IsDelete = 0`.

---

## 1. Bảng `qlnv_chitiet_nvgiao_pth_ubndtp`: nhiệm vụ UBND TP giao

SQL: nv_giao/qlnv_chitiet_nvgiao_pth_ubndtp.sql

### Điều kiện lọc nhiệm vụ

Nhiệm vụ được lấy khi thỏa **tất cả** các điều kiện sau:

| # | Điều kiện | Viết trong SQL |
|---|---|---|
| 1 | Chưa xóa | `t.DeletedDate IS NULL` |
| 2 | Xác định được tình trạng: đang thực hiện, **hoặc** đã hoàn thành mà không có hạn hoặc có ngày hoàn thành/duyệt | `t.Status IN (-1,0,1,2)` **hoặc** (`t.Status IN (3,4)` và (`ExpireDate IS NULL` hoặc `COALESCE(CompletedDate, ApprovedDate) IS NOT NULL`)) |
| 3 | Có văn bản giao chưa xóa | `INNER JOIN qlnv_resolution r` theo `t.ResolutionId`, `r.DeletedDate IS NULL` (không lọc nhóm văn bản) |
| 4 | Do đúng UBND TP giao | `t.AssignDepartment = '490.698'` |
| 5 | Giao cho đơn vị trực thuộc UBND TP | `t.TargetDepartment LIKE '490.698.%'` |
| 6 | Trừ 3 đơn vị | `t.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')`. Chỉ loại đúng 3 mã này; các đơn vị con bên dưới của chúng vẫn được lấy. |

### Các bảng nối thêm

| Bí danh | Bảng nguồn | Nối theo |
|---|---|---|
| `r` | `qlnv_resolution` | `ResolutionId = t.ResolutionId`, chưa xóa |
| `d_assign_cap2` | `department` | `id` = số thứ 2 của `t.AssignDepartment` |
| `d_assign` | `department` | `id` = số cuối của `t.AssignDepartment` |
| `d_chutri` | `department` | `id` = số cuối của `id_don_vi_chu_tri` (mã đơn vị chủ trì đã chuẩn hóa) |
| `d_donvi` | `department` | `id` = số cuối của `t.TargetDepartment` |
| `u_assign` | `qlnv_user` | `eGovUserId = t.AssignUser` |
| `u_target` | `qlnv_user` | `eGovUserId = t.TargetUser` |
| *(subquery)* | `qlnv_report` | Báo cáo mới nhất: `TaskId = t.TaskId`, chưa xóa, sắp `CreatedDate DESC, ReportId DESC`, lấy 1 dòng |

### Các cột

| Cột | Ý nghĩa | Lấy từ đâu / cách tính |
|---|---|---|
| `task_id` | ID nhiệm vụ | `t.TaskId` |
| `status` | Trạng thái gốc | `t.Status` |
| `id_truc_giao` | Mã trục giao | `t.AssignDepartment` (theo điều kiện lọc thì luôn là `490.698`) |
| `truc_giao` | Tên trục giao | `t.AssignOrganization`; nếu trống thì `d_assign_cap2.name` |
| `van_ban_giao` | Văn bản giao | `t.DocCode` |
| `ma_nhiem_vu` | Mã nhiệm vụ | `t.Code` |
| `ten_nhiem_vu` | Tên nhiệm vụ | `t.Title` |
| `chu_de` | Chủ đề | `t.NameGroup`; nếu trống thì `'Chưa phân loại'` |
| `id_don_vi_giao` | Mã đơn vị giao | `t.AssignDepartment` |
| `don_vi_giao` | Tên đơn vị giao | `d_assign.name`; nếu trống thì `t.AssignOrganization` |
| `id_nguoi_giao` | ID người giao | `t.AssignUser` |
| `nguoi_giao` | Tên người giao | `u_assign.eGovUserFullname` |
| `id_don_vi_chu_tri` | Mã đơn vị chủ trì (chuẩn hóa cấp) | Từ `t.TargetDepartment`:<br>• thuộc nhánh `490.698.1841`, `490.698.1307`, `490.698.1310`: cắt còn **4 cấp**<br>• các nhánh khác: cắt còn **3 cấp** (ví dụ `490.698.123.45` → `490.698.123`) |
| `ten_don_vi_chu_tri` | Tên đơn vị chủ trì | `d_chutri.name` |
| `ten_don_vi_thuc_hien` | Tên đơn vị thực hiện (cấp cuối) | `d_donvi.name` |
| `id_nguoi_thuc_hien` | ID người thực hiện | `t.TargetUser` |
| `nguoi_thuc_hien` | Tên người thực hiện | `u_target.eGovUserFullname` |
| `lanh_dao_ban_phu_trach` | Lãnh đạo ban phụ trách | `u_target.eGovUserPositionName` (chức vụ người thực hiện); nếu trống thì `t.ChargeUser` (đây là ID) |
| `ngay_giao` | Ngày giao | `t.StartedDate`, định dạng `dd/mm/yyyy` |
| `han_xu_ly` | Hạn xử lý | `t.ExpireDate`, định dạng `dd/mm/yyyy` |
| `ngay_hoan_thanh` | Ngày hoàn thành | `t.CompletedDate`, định dạng `dd/mm/yyyy` |
| `ngay_chap_nhan` | Ngày duyệt | `t.ApprovedDate`, định dạng `dd/mm/yyyy` |
| `ngay_xoa` | Ngày xóa | `t.DeletedDate`, định dạng `dd/mm/yyyy`. Luôn trống vì chỉ lấy nhiệm vụ chưa xóa. |
| `tinh_trang` | Tình trạng | 4 loại chuẩn (xem mục 4) |
| `ket_qua_thuc_hien` | Kết quả thực hiện | `Content` của báo cáo mới nhất; nếu không có thì `t.Content`; nếu vẫn không có thì `'—'` |
| `kho_khan_vuong_mac` | Khó khăn, vướng mắc | `Difficulty` của báo cáo mới nhất; nếu trống thì `'—'` |
| `de_xuat_kien_nghi` | Đề xuất, kiến nghị | `Suggestion` của báo cáo mới nhất; nếu trống thì `'—'` |
| `sync_date` | Thời điểm đồng bộ | `NOW()` |

---

## 2. Bảng `qlnv_chitiet_nvnhan_pth_ubndtp`: nhiệm vụ UBND TP nhận

SQL: nv_nhan/qlnv_chitiet_nvnhan_pth_ubndtp.sql

### Điều kiện lọc nhiệm vụ

Nhiệm vụ được lấy khi thỏa **tất cả** các điều kiện sau:

| # | Điều kiện | Viết trong SQL |
|---|---|---|
| 1 | Chưa xóa, không phải trạng thái 5 | `t.DeletedDate IS NULL` và `t.Status <> 5` |
| 2 | Xác định được tình trạng | Giống điều kiện 2 của bảng giao |
| 3 | Văn bản giao thuộc nhóm 55, 111, 132, 129 | `INNER JOIN qlnv_resolution r` theo `t.ResolutionId`, `r.ResolutionGroupId IN (55, 111, 132, 129)` |
| 4 | Đơn vị nhận là UBND TP hoặc đơn vị trực thuộc | `t.TargetDepartment LIKE '490.698%'` |
| 5 | Trừ 3 đơn vị | `t.TargetDepartment NOT IN ('490.698.1307', '490.698.1841', '490.698.1310')` |
| 6 | Không phải UBND TP tự giao | `t.AssignDepartment NOT LIKE '490.698%'` |
| 7 | Nếu Thành ủy giao (`AssignDepartment LIKE '490.695%'`) thì số ký hiệu văn bản phải chứa một trong các chuỗi bên phải | `t.DocCode` chứa `TB/KL`, `TB/TU`, `TB/VPTU`, `CV/TU`, `CV/VPTU` hoặc `BCĐ` |

### Các bảng nối thêm

| Bí danh | Bảng nguồn | Nối theo |
|---|---|---|
| `r` | `qlnv_resolution` | `ResolutionId = t.ResolutionId`, chưa xóa, nhóm 55/111/132/129 |
| `d_assign_cap2` | `department` | `id` = số thứ 2 của `t.AssignDepartment` |
| `d_assign` | `department` | `id` = số cuối của `t.AssignDepartment` |
| `d_cap` | `department` | `id` = số thứ 3 của `t.TargetDepartment` |
| `d_donvi` | `department` | `id` = số cuối của `t.TargetDepartment` |
| `u_assign` | `qlnv_user` | `eGovUserId = t.AssignUser` |
| `u_target` | `qlnv_user` | `eGovUserId = t.TargetUser` |
| *(subquery)* | `qlnv_report` | Báo cáo mới nhất: giống bảng giao |

### Các cột

Chỉ liệt kê các cột **khác** bảng giao. Các cột còn lại lấy giống hệt mục 1.

| Cột | Ý nghĩa | Lấy từ đâu / cách tính |
|---|---|---|
| `id_truc_giao` | Mã trục giao | 2 cấp đầu của `t.AssignDepartment` (ví dụ `490.695`) |
| `id_don_vi_chu_tri` | Mã đơn vị chủ trì | `t.TargetDepartment`, giữ nguyên, **không** chuẩn hóa cấp |
| `ten_don_vi_chu_tri` | Tên đơn vị chủ trì | Lần lượt lấy giá trị đầu tiên không trống: `t.ResponsibleUnit` → `t.TargetOrganization` → `d_cap.name` (cấp 3) → `d_donvi.name` |
| `ten_don_vi_thuc_hien` | Tên đơn vị thực hiện | Lần lượt lấy giá trị đầu tiên không trống: `d_donvi.name` → `t.ResponsibleUnit` → `t.TargetOrganization` |
| `tinh_trang` | Tình trạng | 4 loại chuẩn (xem mục 4) |

---

## 3. Bảng `qlnv_chitiet_nvchoduyet_pth_ubndtp`: nhiệm vụ có báo cáo chờ duyệt

SQL: nv_choduyet/qlnv_chitiet_nvchoduyet_pth_ubndtp.sql

### Điều kiện lọc nhiệm vụ

Nhiệm vụ được lấy khi thỏa **tất cả** các điều kiện sau:

| # | Điều kiện | Viết trong SQL |
|---|---|---|
| 1 | Chưa xóa, không phải trạng thái 5 | `t.DeletedDate IS NULL` và `t.Status <> 5` |
| 2 | Có báo cáo đang chờ người giao duyệt | Có ít nhất 1 dòng `qlnv_report` thỏa: chưa xóa; `Type IN (1,2,3,4)`; `Status = 0` (chưa duyệt); nhiệm vụ chưa hoàn thành (`t.Status < 3`); người duyệt báo cáo là người tạo nhiệm vụ (`t.CreateUser = rp.ApprovedUser`) |
| 3 | Liên quan Văn phòng UBND TP: thỏa **một trong** 2 trường hợp | **TH1:** do Văn phòng giao: `t.AssignDepartment LIKE '490.698.752%'`<br>**TH2:** bên khác giao, nhưng có báo cáo (chưa xóa) mà người duyệt thuộc Văn phòng: `qlnv_user.DepartmentPath LIKE '490.698.752%'` của `ApprovedUser` |

Bảng này **không** lọc theo nhóm văn bản.

### Các bảng nối thêm

| Bí danh | Bảng nguồn | Nối theo |
|---|---|---|
| `rp_wait` | `qlnv_report` | Danh sách nhiệm vụ có báo cáo chờ duyệt (điều kiện 2), `INNER JOIN` |
| `rp_last` | `qlnv_report` | Báo cáo có `CreatedDate` lớn nhất của nhiệm vụ, chưa xóa |
| `r` | `qlnv_resolution` | `ResolutionId = t.ResolutionId`, chưa xóa (`LEFT JOIN`) |
| `d_assign` | `department` | `id` = số cuối của `t.AssignDepartment` |
| `u_create` | `qlnv_user` | `eGovUserId = t.CreateUser` (người tạo nhiệm vụ) |
| `d_create_dept` | `department` | `id` = số cuối của `u_create.DepartmentPath` (phòng của người tạo) |
| `d_cap` | `department` | `id` = số cuối của `id_don_vi_chu_tri` (đã chuẩn hóa cấp) |
| `d_donvi` | `department` | `id` = số cuối của `t.TargetDepartment` |
| `u_assign` | `qlnv_user` | `eGovUserId = t.CreateUser` (**người tạo**, không phải người giao) |
| `u_nguoi_giao` | `qlnv_user` | `eGovUserId = t.AssignUser` |
| `u_target` | `qlnv_user` | `eGovUserId = t.TargetUser` |

### Các cột

| Cột | Ý nghĩa | Lấy từ đâu / cách tính |
|---|---|---|
| `task_id` | ID nhiệm vụ | `t.TaskId` |
| `status` | Trạng thái gốc | `t.Status` |
| `id_truc_giao` | Mã trục giao | TH1 (Văn phòng giao): `t.AssignDepartment`<br>TH2 (bên khác giao): `u_create.DepartmentPath`, tức phòng của người tạo nhiệm vụ |
| `truc_giao` | Tên trục giao | TH1: `t.AssignOrganization`; nếu trống thì `d_assign.name`<br>TH2: `d_create_dept.name` |
| `van_ban_giao` | Văn bản giao | `t.DocCode`; nếu không có thì `r.DocCode` |
| `ma_nhiem_vu` | Mã nhiệm vụ | `t.Code` |
| `ten_nhiem_vu` | Tên nhiệm vụ | `t.Title` |
| `chu_de` | Chủ đề | `t.NameGroup`; nếu trống thì `'Chưa phân loại'` |
| `id_don_vi_giao` | Mã đơn vị giao | `t.AssignDepartment` |
| `don_vi_giao` | Tên đơn vị giao | `d_assign.name`; nếu trống thì `t.AssignOrganization` |
| `id_nguoi_giao` | ID người giao | `t.AssignUser` |
| `nguoi_giao` | Tên người giao | `u_nguoi_giao.eGovUserFullname` |
| `id_don_vi_chu_tri` | Mã đơn vị chủ trì | `t.TargetDepartment`; nếu từ **5 cấp** trở lên thì cắt còn 4 cấp, còn lại giữ nguyên |
| `ten_don_vi_chu_tri` | Tên đơn vị chủ trì | `d_cap.name`; nếu trống thì `d_donvi.name` |
| `ten_don_vi_thuc_hien` | Tên đơn vị thực hiện | Giống `ten_don_vi_chu_tri` |
| `id_nguoi_thuc_hien` | ID người thực hiện | `t.TargetUser` |
| `nguoi_thuc_hien` | Tên người thực hiện | `u_target.eGovUserFullname` |
| `lanh_dao_ban_phu_trach` | Lãnh đạo ban phụ trách | **Tên người tạo nhiệm vụ** (`u_assign.eGovUserFullname`, với `u_assign` nối theo `t.CreateUser`) |
| `ngay_giao` / `han_xu_ly` / `ngay_hoan_thanh` / `ngay_chap_nhan` / `ngay_xoa` | Các mốc thời gian | Giống bảng giao (`dd/mm/yyyy`) |
| `tinh_trang` | Tình trạng chờ duyệt | 3 loại (xem mục 4) |
| `ket_qua_thuc_hien` | Kết quả thực hiện | `rp_last.Content`; nếu không có thì `t.Content`; nếu vẫn không có thì `'—'` |
| `kho_khan_vuong_mac` | Khó khăn, vướng mắc | `rp_last.Difficulty`; nếu trống thì `'—'` |
| `de_xuat_kien_nghi` | Đề xuất, kiến nghị | `rp_last.Suggestion`; nếu trống thì `'—'` |
| `sync_date` | Thời điểm đồng bộ | `NOW()` |

---

## 4. Cột `tinh_trang`

### Bảng giao và bảng nhận: 4 loại chuẩn

Xét từ trên xuống, gặp điều kiện nào đúng trước thì lấy giá trị đó:

| Giá trị | Điều kiện |
|---|---|
| Đã hoàn thành | `t.Status` là 3 hoặc 4, có hạn (`ExpireDate`) và có ngày hoàn thành hoặc ngày duyệt |
| Thường xuyên | Không có hạn (`ExpireDate` trống) |
| Chưa hoàn thành trong hạn | `t.Status` là -1, 0, 1 hoặc 2, và hạn ≥ hôm nay |
| Chưa hoàn thành quá hạn | `t.Status` là -1, 0, 1 hoặc 2, và hạn < hôm nay |

### Bảng chờ duyệt: 3 loại

| Giá trị | Điều kiện |
|---|---|
| Chờ duyệt quá hạn | Có hạn và hạn < hôm nay |
| Chờ duyệt trong hạn | Có hạn và hạn ≥ hôm nay |
| Chờ duyệt - không có hạn | Không có hạn |
