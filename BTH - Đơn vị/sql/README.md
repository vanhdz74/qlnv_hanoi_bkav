# SQL chuỗi `qlnv_tonghop_chitiet_khoi` (NiFi, bản đang chạy)

Lấy từ NiFi ngày 16/11/2026. Group RT `142f3e8a` "[RT CHỜ DUYỆT 12/11] Chuỗi Tiếp nhận → Giao → Giao+Nhận", nằm trong "BTH _ Đơn vị _ Realtime (1p)". Group này đã cutover và ghi vào bảng thật từ 13/11.

- `1_tiep_nhan/`: group "Tiếp nhận NV"
- `2_giao/`: group "Giao NV"
- `3_giao_nhan/`: group "Giao + Nhận NV" (chitiet → nhom → khoi, tongquan)

Tiếp nhận và Giao chạy song song. Giao + Nhận chạy sau khi cả hai xong, MergeContent ghép theo `sync_ts`.

Tên tệp đánh số theo thứ tự nối trong flow. Hậu tố `__DISABLED` là processor đang tắt. Đầu mỗi tệp ghi id processor, trạng thái và lịch chạy.

`${sync_ts}` là thuộc tính do GenerateFlowFile đặt. Muốn chạy tay thì thay bằng một mốc thời gian.

## Bộ lọc phạm vi đơn vị giao (xem `../note.md`)

| Tệp | Dòng | Điều kiện |
|---|---|---|
| 1_tiep_nhan/03_qlnv_tonghop_chitiet_tiepnhan_upsert.sql | 409, 413 | `loaicap_dvgiao NOT IN ('Sở ngành','Xã, Phường','Nhóm Sở ngành mở rộng')`, `loaicap_dvgiao <> 'Đảng bộ trực thuộc'` |
| 2_giao/04_qlnv_tonghop_chitiet_giaonv_upsert.sql | 422, 427 | Như trên, nhưng tên cột là `loaicap`, vẫn tính theo cây `dv_giao` |
| 3_giao_nhan/07_qlnv_tonghop_chitiet_khoi_upsert.sql | 83 | `loaicap IN ('Xã, Phường','Sở ngành','Nhóm Sở ngành mở rộng')` (bao gồm cả nhánh) |

`loaicap*` là tên tổ tiên cấp 3 của đơn vị, nên mỗi điều kiện áp dụng cho cả nhánh con, không riêng một nút.

Lưu ý: đây là bản chép để đọc. Sửa ở đây không tự lên NiFi.
