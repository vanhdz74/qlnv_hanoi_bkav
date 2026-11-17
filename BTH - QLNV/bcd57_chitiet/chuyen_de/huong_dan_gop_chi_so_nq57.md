# Lấy 4 bảng NQ57 và gộp thành chỉ số chuyên đề

Cập nhật 16/11/2026. Áp dụng cho dashboard 279 "NQ57 – Chuyên đề chi tiết (test)" (dataset 159 → `datamart_hanoi.chuyen_de_chi_tiet_nq57_test`).
Dashboard thật 272 (dataset 145) vẫn đọc bảng nhập tay `chuyen_de_chi_tiet_nq57`.

## 1. Bốn bảng nguồn

Nguồn: PostgreSQL 10.120.33.33:15432, tài khoản chỉ đọc `dashboard_ro` (mật khẩu trong [prompt/quytrinh_up_data_from_db.md](prompt/quytrinh_up_data_from_db.md)).
Hai CSDL tách riêng (`bao_cao`, `bieu_mau`), không join chéo được trên PG → NiFi chép cả 4 bảng về MySQL `datamart_hanoi` rồi mới ghép.

| # | Bảng PG | Bảng MySQL (đích) | Nội dung | Khóa chính (MySQL) |
|---|---------|-------------------|----------|--------------------|
| 1 | `bao_cao.dashboard.so_lieu_nq57` | `nq57_solieu` | Số theo **chỉ tiêu** (chỉ ô có gắn chỉ tiêu, ~757 số T2–T10) | ma_chi_tieu, ma_phan_to, loai_so, ky, ma_don_vi |
| 2 | `bieu_mau.dashboard.chi_tieu_nq57` | `nq57_chitieu` | Danh mục chỉ tiêu: tên, nhóm (ma_phu_luc), phân tổ | ma_chi_tieu, ma_phan_to |
| 3 | `bao_cao.dashboard.so_lieu_truong_nq57` | `nq57_solieu_truong` | Số theo **trường** (mọi ô của biểu, kể cả ô chữ, ô tự tính, bảng nhiều dòng; ~3.116 ô) | ma_bieu, ma_phan, ma_truong, so_dong, ky, ma_don_vi |
| 4 | `bieu_mau.dashboard.truong_nq57` | `nq57_truong` | Danh mục trường: tên như trên biểu, dòng/cột, kiểu, ma_chi_tieu | ma_bieu, ma_phan, ma_truong |

View tiện tra cứu trên Superset: `v_nq57_solieu` (1 ⟕ 2) và `v_nq57_solieu_truong` (3 ⟕ 4).

Cách ghép:
- 1 ↔ 2 theo `ma_chi_tieu + ma_phan_to`.
- 3 ↔ 4 theo `ma_bieu + ma_phan + ma_truong`.
- Bảng trường → bảng chỉ tiêu: `nq57_truong.ma_chi_tieu` (khi trường có gắn chỉ tiêu).

Điểm cần nhớ về dữ liệu:
- `ky` dạng `2026M08`. Hiện chưa có tháng 1 trong PG (có M02–M10).
- Mã biểu: `NQ57HN-B01…B12` (biểu gốc) và `NQ57HN-TH-00…TH-05` (dòng tổng hợp; nhóm chỉ tiêu `NQ57HN_TH`).
- Tháng không có số thì **không có dòng** (không còn dòng 0) → thiếu dòng = chưa báo cáo, không phải bằng 0.
- `so_dong = 0`: phần một dòng; `1, 2, …`: từng dòng của bảng nhiều dòng (vd. Biểu 04 phần E, mỗi dòng là một xã).
- Ô chữ nằm ở `gia_tri_chu` (vd. Biểu 01 phần A trả lời "Có"/"Không"), ô số ở `gia_tri_so`.

## 2. Đồng bộ về datamart (NiFi)

NiFi group "Chuyên đề lớn", chạy mỗi 30': ExecuteSQLRecord (PG) → PutDatabaseRecord UPSERT → xóa dòng có `sync_date < ${sync_ts}`.
SQL đọc PG và DDL MySQL nằm ở [docs/nq57_solieu/](../../../docs/nq57_solieu/):

| Tệp | Việc |
|-----|------|
| `0_ddl.sql` | Tạo `nq57_solieu`, `nq57_chitieu`, view `v_nq57_solieu` |
| `1_select_solieu_pg.sql`, `2_select_chitieu_pg.sql` | Đọc bảng 1, 2 |
| `4_ddl_truong.sql` | Tạo `nq57_solieu_truong`, `nq57_truong`, view `v_nq57_solieu_truong` |
| `5_select_solieu_truong_pg.sql`, `6_select_truong_pg.sql` | Đọc bảng 3, 4 |
| `3_delete_cu.sql` | Xóa dòng cũ theo `sync_date` |
| `deploy_truong.py`, `sqllab.py` | Dựng nhánh bảng trường trên NiFi, chạy thử SQL qua SQL Lab |

Câu SELECT trên PG ép mọi cột số/ngày sang text (`::text`, `to_char(... AT TIME ZONE 'Asia/Ho_Chi_Minh')`) để MySQL nhận đúng, không lệch múi giờ.

## 3. Gộp thành chỉ số

Code: [sql/nq57_truong/](sql/nq57_truong/). `python3 build.py` sinh lại toàn bộ SQL; `deploy.py` đưa lên NiFi.

| Tệp | Việc |
|-----|------|
| `0_ddl.sql` | Bảng ánh xạ `nq57_chi_so_anh_xa`; bảng đích `chuyen_de_chi_tiet_nq57_test` (LIKE bảng cũ) |
| `1_nap_anh_xa.sql` | Nạp 145 chỉ số: tên, chuyên đề, ngưỡng, đầu mối (chép từ bảng nhập tay) + cách lấy số |
| `2_tinh_chuyen_de.sql` | Tính bảng đích; NiFi chạy phút 2 và 32 |
| `3_kiem_tra_select.sql` | Câu kiểm tra sau khi chạy |

### 3.1. Bảng ánh xạ `nq57_chi_so_anh_xa`

Mỗi chỉ số dashboard (`ma_chi_so`, vd. `DD03`) một dòng:

| Cột | Ý nghĩa |
|-----|---------|
| `cach_tinh` | `TONG` = tính từ NQ57; `KHONG_CO` = chưa có nguồn (vẫn sinh dòng, `gia_tri` NULL, dashboard hiện "!") |
| `tu_ma` | Các mã cộng làm tử số, phân cách dấu phẩy; `-MA` = trừ. Vd. `B04_D_MAYTINH_TONG,-B04_D_MAYTINH_CONLAI` |
| `mau_ma` | Các mã cộng làm mẫu số |
| `mau_hang_so` | Mẫu cố định (vd. 126 xã) khi không có mã mẫu |
| `he_so` | Nhân vào khi không có mẫu (mặc định 1) |
| `can_ty_le` | 1 = bắt buộc là tỷ lệ; thiếu mẫu thì `gia_tri` NULL |
| `chi_khi_mau_duong` | 1 = mẫu ≤ 0 thì bỏ cả tử |

Hiện có 116 chỉ số `TONG`, 29 `KHONG_CO`. Đổi cách tính một chỉ số: sửa dòng trong bảng này (hoặc sửa `NEW` trong `build.py` rồi build lại) — không cần sửa SQL tính.

### 3.2. Lấy một số cho mỗi (mã, kỳ)

`2_tinh_chuyen_de.sql` dựng tập `v(m, ky, v)` từ 4 nguồn, theo thứ tự ưu tiên:

1. **Bảng chỉ tiêu** `nq57_solieu`, chỉ `loai_so = 'ACTUAL'`, `ma_phan_to = 'TONG'`:
   có dòng biểu `NQ57HN-TH%` thì lấy số TH (đã tổng hợp sẵn), không thì cộng các biểu gốc của mọi đơn vị.
2. **Bảng trường** `nq57_solieu_truong`: cộng `gia_tri_so` mọi đơn vị, mọi dòng theo `ma_truong`.
   Chỉ dùng khi mã đó **không có** ở nguồn 1 trong cùng kỳ (so `ma_truong` với `ma_chi_tieu`) → không cộng trùng.
3. **Mã tự đặt** tính từ bảng trường:
   - `XA_TT_GE90`, `XA_TT_100`, `XA_TT_LT50`, `XA_TT_SO`: Biểu 04 phần E, mỗi dòng một xã, tỷ lệ = `B04_E03 / B04_E02`; đếm số xã đạt ≥ 90%, = 100%, < 50%, tổng số xã.
   - `XA_A01_CO`, `XA_A03_CO`, `XA_A05_CO`: Biểu 01, đếm xã trả lời "Có" ở `B01_A01/A03/A05`.

### 3.3. Công thức một chỉ số (`cach_tinh = TONG`)

```
tu  = Σ v của mã cộng trong tu_ma − Σ v của mã trừ
      (có mã trừ thì phải có đủ cả mã cộng và mã trừ, thiếu → NULL)
mau = Σ v của mã trong mau_ma, hoặc mau_hang_so
có mẫu    → gia_tri = tu / mau   (tu_so, mau_so giữ riêng để hiện tooltip)
không mẫu → gia_tri = tu * he_so
```

Kỳ sinh ra: tháng 1 → tháng lớn nhất đang có số trong năm; nhãn `ky = 'T8/2026'`, `thu_tu_ky = tháng − 1` (giữ như bảng cũ).
Cuối câu: `DELETE ... WHERE sync_date < '${sync_ts}'` xóa dòng không còn sinh ra.

### 3.4. Các nhóm phụ (ngoài `CHI_SO`)

| `nhom_du_lieu` | Nguồn | Ghi chú |
|----------------|-------|---------|
| `NOI_DUNG_XA` | Biểu 01 phần A, đếm xã "Có" theo 3 chủ đề | Mới có 3/9 chủ đề |
| `XA_QUAN_TAM` | Biểu 01 phần B: `B01_B01` tổng NV, `B01_B02` hoàn thành, `B01_B06` đang quá hạn, `B01_B07` xong quá hạn | Chỉ lấy xã có `B01_B06 > 0` |
| `DIEM_NGHEN_XA` | Biểu 01 `B01_F01` (văn bản) | Phân loại theo từ khóa; không khớp → "Khác/không nêu rõ" |

Chưa có nguồn: `NGUON_GIAO`, `QUA_HAN` (cần số NV01–16 từ QLNV, chưa chốt).

## 4. Tra cứu nhanh trên SQL Lab (datamart_hanoi)

Một mã có số ở bảng nào, kỳ nào:

```sql
SELECT 'chi_tieu' nguon, ma_bieu, ky, SUM(gia_tri) v FROM nq57_solieu
WHERE ma_chi_tieu = 'B07_A02' AND loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' GROUP BY ma_bieu, ky
UNION ALL
SELECT 'truong', ma_bieu, ky, SUM(gia_tri_so) FROM nq57_solieu_truong
WHERE ma_truong = 'B07_A02' GROUP BY ma_bieu, ky;
```

Tìm mã trường theo tên trên biểu (để thêm vào `tu_ma`/`mau_ma`):

```sql
SELECT ma_bieu, ma_phan, ma_truong, ten_truong, kieu, don_vi_tinh, ma_chi_tieu
FROM nq57_truong WHERE ten_truong LIKE '%máy tính%';
```

So kết quả với bảng nhập tay:

```sql
SELECT t.ma_chi_so, t.ky, t.gia_tri moi, c.gia_tri cu
FROM chuyen_de_chi_tiet_nq57_test t
LEFT JOIN chuyen_de_chi_tiet_nq57 c
  ON c.nhom_du_lieu = t.nhom_du_lieu AND c.ma_chi_so = t.ma_chi_so AND c.ky = t.ky AND c.phan_to = t.phan_to
WHERE t.nhom_du_lieu = 'CHI_SO' AND t.ky = 'T10/2026';
```

## 5. Lưu ý khi sửa

- MySQL 5.7: không CTE, không window function.
- Câu chạy > 60s bị NiFi ngắt nhưng vẫn chạy và giữ khóa trên MySQL → kiểm `SHOW PROCESSLIST`, KILL nếu cần.
- Sửa SQL tính thì sửa `build.py` rồi `python3 build.py`; không sửa tay các tệp `.sql` sinh tự động.
- Rollback dataset 159 về bảng cũ: `python3 superset_dataset.py rollback`.
