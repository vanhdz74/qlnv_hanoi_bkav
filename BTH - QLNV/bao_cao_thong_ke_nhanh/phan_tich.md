Cột | Kiểu | Mô tả | Tổng quan | Chi tiết |
|---|---|---|---|---|
| `ma_nhiem_vu` | varchar | Mã nhiệm vụ | Đếm | ✔ |
| `vai_tro` | varchar | `giao` · `nhan` · `chu_tri` · `phoi_hop` · `theo_doi` | Tách khối giao/nhận, lọc "Vai trò thực hiện" | Lọc |
| `ma_don_vi` | varchar | Đơn vị ở vai trò đó | Dòng của bảng cây | Lọc |
| `ten_don_vi` | varchar | Tên đơn vị | Cột "Trục / Tên đơn vị" | |
| `ma_don_vi_cha` | varchar | Đơn vị cha | Dựng cây | |
| `path_don_vi` | varchar | Đường dẫn mã, ví dụ `/UB/UB.SN/UB.SXD/`. Lọc cây con bằng `LIKE '/UB/UB.SN/%'` | Lọc, RLS | Lọc, RLS |
| `path_ten_don_vi` | varchar | Đường dẫn tên, ví dụ `UBND Thành phố / Sở ngành / Sở Xây dựng`. Giúp dựng đủ các nút tổ tiên kể cả khi tổ tiên không có dòng dữ liệu riêng | Dựng cây | |
| `cap_don_vi` | int | Độ sâu trong cây | Thụt lề, màu dòng | |
| `thu_tu_don_vi` | int | Thứ tự giữa các đơn vị cùng cấp | Sắp xếp | |
| `ma_doi_tac` | varchar | Với dòng `giao` là đơn vị nhận; với dòng `nhan` là đơn vị giao; vai trò khác để `NULL` | Góc nhìn đối tác | Tiêu đề "A GIAO → B" |
| `ten_doi_tac` | varchar | Tên đơn vị đối tác | Góc nhìn đối tác | |
| `path_doi_tac` | varchar | Dùng để loại các cặp mà hai bên cùng nằm trong cây con đang xem | Góc nhìn đối tác | |

### 2.2 Thuộc tính nhiệm vụ (giống nhau trên mọi dòng của cùng một nhiệm vụ)

**Nội dung và phân loại**

| Cột | Kiểu | Tổng quan | Chi tiết |
|---|---|---|---|
| `ten_nhiem_vu` | text | Lọc (tìm kiếm) | ✔ |
| `trich_yeu_nhiem_vu` | text | | ✔ |
| `linh_vuc` | varchar | Nhóm theo lĩnh vực, lọc | ✔ |
| `do_khan` | varchar | Lọc | ✔ |
| `loai_chi_dao` | varchar | Lọc | ✔ |

**Văn bản giao**

| Cột | Kiểu | Tổng quan | Chi tiết |
|---|---|---|---|
| `vb_so_hieu` | varchar | Nhóm theo văn bản, lọc | ✔ |
| `vb_ky_hieu` | varchar | | ✔ |
| `vb_trich_yeu` | text | Dòng phụ khi nhóm theo văn bản, lọc | ✔ |
| `vb_ngay_ban_hanh` | date | | ✔ |
| `vb_phan_loai` | varchar | Lọc | ✔ |
| `vb_ma_co_quan_ban_hanh`, `vb_ten_co_quan_ban_hanh` | varchar | Lọc | ✔ |

**Đơn vị và người (cấp nhiệm vụ).** Dùng cho các cột hiển thị ở Lớp 2 và cho các ô lọc nâng cao "ĐV giao", "ĐV chủ trì". Hai ô lọc này độc lập với cặp "Đơn vị + Vai trò".

| Cột | Kiểu | Tổng quan | Chi tiết |
|---|---|---|---|
| `ma_dv_giao`, `ten_dv_giao`, `path_dv_giao` | varchar | Lọc "ĐV giao" | ✔ |
| `nguoi_giao` | varchar | | ✔ |
| `ma_dv_nhan`, `ten_dv_nhan` | varchar | | ✔ |
| `nguoi_nhan` | varchar | | ✔ |
| `ma_dv_chu_tri`, `ten_dv_chu_tri`, `path_dv_chu_tri` | varchar | Lọc "ĐV chủ trì" | ✔ |
| `nguoi_chu_tri` | varchar | Lọc | ✔ |
| `ds_ten_dv_phoi_hop` | text | | ✔ (nối bằng `; `) |
| `ten_dv_dang_xu_ly` | varchar | | ✔ |
| `ma_phong_theo_doi`, `ten_phong_theo_doi` | varchar | Nhóm theo phòng | ✔ |

**Thời gian, trạng thái, tiến độ**

| Cột | Kiểu | Tổng quan | Chi tiết |
|---|---|---|---|
| `ngay_tao` | date | **Cột thời gian chính** cho "Kỳ thời gian" và "Từ ngày → Đến ngày" | ✔ |
| `han_xu_ly` | date, nullable | | ✔ |
| `ngay_hoan_thanh` | date, nullable | | ✔ |
| `trang_thai` | varchar (5 mã chuẩn) | Đếm theo trạng thái, lọc | ✔ |
| `ten_trang_thai` | varchar | | ✔ (pill màu) |
| `la_hoan_thanh` | int 0/1 | Cột "Đã hoàn thành", lọc "TT hoàn thành" | ✔ |
| `la_qua_han` | int 0/1 | Cột "Tỷ lệ quá hạn" | Lọc nhanh |
| `la_thuong_xuyen` | int 0/1 | Cột "Thường xuyên" | |
| `so_ngay_qua_han` | int | | ✔ |
| `tien_do_pct` | int | | ✔ |
| `la_cho_duyet`, `la_quan_tam`, `la_ban_chi_dao` | int 0/1 | | Lọc nhanh |
| `ngay_chot_so_lieu` | date | "Ngày lập" trên tiêu đề | "Ngày lập" |