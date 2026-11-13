# Cutover RT 142f3e8a → bảng thật (bản chờ duyệt, 13/11)

Chưa thay đổi gì trên NiFi. Mọi số liệu trong tệp này là kết quả khảo sát chỉ đọc lúc 10:40 ngày 13/11.

## Phạm vi
- Luồng cũ: 64 processor đang RUNNING trong group f8207212 "BTH - Đơn vị" (cả 14 group con). Chỉ đổi sang STOPPED, không xóa.
- Luồng mới: 58 processor sửa SQL, chỉ bỏ hậu tố `_new_rt`. Danh sách nằm ở `plan_cutover.json`, diff từng dòng ở `diff.txt`.
  - Các bảng swap: `X_new_rt__stg` → `X__stg`, rồi RENAME vào `X`.
  - Các bảng upsert: ghi thẳng vào `X`.
  - Có 5 bảng thuộc schema `db_hdnd_qttt`, gồm các bảng `*_hdndtp`.
- DDL trên bảng thật dùng `upsert/0_DDL_v2.sql`, đã chạy thử ngày 12/11 hết 9,5s. Thuộc tính `ALGORITHM=INPLACE, LOCK=NONE`.
  - Thêm UNIQUE (Ma, NhomGiaoNhan) cho: chitiet, nhom, khoi.
  - Thêm cột syncdate và UNIQUE(Ma) cho: nhom_tiepnhan, nhom_giaonv.
  - Các bảng tiepnhan, giaonv, don_le, theo_chuoi đã có PRIMARY(Ma) nên không cần sửa.

## Đối soát trước cutover (10:40 ngày 13/11)
- 30 bảng có số dòng khớp. Phía mới thường nhiều hơn vài chục dòng vì dữ liệu tươi hơn.
- cbcc_danhgia, kpi_*, cbcc_danhgia_hdndtp:
  - Tháng hiện tại khớp.
  - Bảng mới thiếu các tháng cũ vì bảng nguồn `_new_rt` chỉ có dữ liệu từ 12/11. Sau cutover, các bảng này đọc bảng thật nên sẽ đủ tháng.
- cham_muon_theo_don_vi: cả bản cũ lẫn bản mới đều không có trigger nên không chạy (bản cũ đứng từ 05/2026). Giữ nguyên hiện trạng.

## Các bước
0. Backup flow JSON của f8207212 và 142f3e8a, cùng danh sách processor đang RUNNING.
1. STOP 64 processor của luồng cũ, chờ đến khi activeThreadCount = 0.
2. STOP các processor RUNNING của RT, chờ đến khi thread = 0.
3. Thay SQL của "0. DDL tạo bảng _new_rt" bằng `0_DDL_v2`, Run once, rồi kiểm tra đủ 5 khóa và 2 cột. Nếu lỗi do trùng khóa thì dừng lại và chuyển sang Rollback.
4. PUT SQL mới cho 58 processor.
5. Thay SQL của "0. ROLLBACK DDL" bằng `0_DDL_ROLLBACK_v2`, rồi DISABLE để processor không còn kẹt ở VALIDATING.
6. Dọn dẹp:
   - Xóa 3 connection từ cổng 15' ra output port và 3 output port. Nhánh này không còn dùng vì các group hạ nguồn đã nằm trong RT.
   - Đặt auto-terminate cho "Merge failure".
   - Xóa các flowfile lỗi cũ đang tồn ở LogAttribute.
7. START lại các processor RT trước đây đang chạy, trừ các processor "0.*". Theo dõi 30 phút các chỉ số:
   - failure queue
   - thread
   - kết nối pool
   - syncdate
   - số dòng
8. Sau 2–3 ngày ổn định: DROP các bảng `*_new_rt` và `*_new_rt__stg`. Có thể dùng `full/DROP_full.sql`.

## Rollback (khoảng 2 phút)
1. STOP luồng RT.
2. Run once "0. ROLLBACK DDL".
3. START lại 64 processor cũ theo danh sách đã lưu.

Dữ liệu trong bảng thật vẫn còn nguyên, vì upsert/swap không xóa trắng bảng.
