# Cách A: chỉ loại đúng nút gom nhóm, không loại cả nhánh (16/11/2026, CHƯA đẩy lên NiFi)

Hai tệp ở đây là bản sửa của `../sql/1_tiep_nhan/03_…tiepnhan_upsert.sql` (processor 142f3e95) và `../sql/2_giao/04_…giaonv_upsert.sql` (processor 142f3eb5). Xem thay đổi bằng `diff`.

- `loaicap_dvgiao NOT IN ('Sở ngành','Xã, Phường','Nhóm Sở ngành mở rộng') OR IS NULL` đổi thành `iddv_dvgiao NOT IN (1307,1310,1841)`.
- `loaicap_dvgiao <> 'Đảng bộ trực thuộc'` đổi thành `iddv_dvgiao <> 1558`.
- Nhánh Giao sửa giống hệt, nhưng dùng `iddv`. Ở nhánh Giao, `iddv` chính là `dv_giao.DepartmentId`.

## Ảnh hưởng (đo chỉ đọc qua SQL Lab, chạy subquery thật với cờ cũ/mới)

Số đếm theo bộ lọc cũ (97.132) khớp đúng số dòng thực tế của các bảng, nên việc mô phỏng là tin được.

| Bảng | Hiện tại | Sau cách A |
|---|---|---|
| qlnv_tonghop_chitiet_tiepnhan | 97.132 | 98.464 (+1.332, −0) |
| qlnv_tonghop_chitiet_giaonv | 97.132 | 98.464 (+1.332, −0) |
| qlnv_tonghop_chitiet_khoi "Đã giao" (IOC) | 22.854 | +701 |
| qlnv_tonghop_chitiet_khoi "Được giao" (IOC) | 1.372 | +175, không nhóm nào gộp vào nhóm cũ |

Phân rã 1.332 nhiệm vụ mới, kèm số dòng "Đã giao" sinh thêm trong `khoi`:

| Đơn vị giao | Nhiệm vụ | Dòng khoi |
|---|---|---|
| Thành ủy Hà Nội giao trực tiếp (id 695). Trước đây mất do loaicap NULL | 860 | 350 |
| Đảng bộ trực thuộc, nhánh con (đảng ủy xã/phường) | 142 | 104 |
| Sở ngành, nhánh con | 229 | 173 |
| Xã, Phường, nhánh con | 86 | 65 |
| Nhóm Sở ngành mở rộng, nhánh con | 15 | 9 |

- `qlnv_tongquan` cộng dồn từ `khoi`. Bảng này bỏ các dòng "Được giao" có loaicapcha là Thành ủy. Vì vậy số "Đã giao" của khối Thành ủy và khối UBND tăng, và số "Được giao" của UBND TP và HĐND tăng.
- NV 407556 có mặt ở cả hai nhánh sau khi sửa.

Script đo: impact_A.py (trong scratchpad của phiên, chỉ đọc).
