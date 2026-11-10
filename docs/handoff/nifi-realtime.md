# Bàn giao: tối ưu NiFi → datamart_hanoi gần real-time

## Mục tiêu
Giảm độ trễ datamart (IOC/Superset) xuống ≤ 1 phút mà không gây khóa trên TDNV. Kế hoạch: docs/ke_hoach_toi_uu_nifi_realtime.md

## Nhánh/trạng thái git
- Nhánh `main`, chưa commit/push gì cho việc này. `docs/` và `backups/*20261110*` chưa được track.
- Có thay đổi Superset chưa commit, thuộc việc khác (chart.tpl.js, tao_dashboard.py, ss.py, build/*.js). Không động vào.

## Đã xong
- Đã đo hiện trạng NiFi/MySQL (chiều 10/11): docs/ke_hoach_toi_uu_nifi_realtime.md:5-28
- Pilot 3 luồng 'Nhận' PTH UBNDTP: chạy 1 phút với READ COMMITTED, đạt: docs/ke_hoach_toi_uu_nifi_realtime.md:30-37
- Backup trước khi sửa: backups/backup_nifi_pth_ubndtp_{chitiet,lichsu,tonghop}_nvnhan_20261110_before.json

## Quyết định đã chốt
- Mọi lần ghi lên NiFi: cho người dùng xem diff và đích sửa, chờ OK rồi mới PUT (memory confirm-scope-before-nifi-edit).
- Thay đổi bảng nào thì sửa trong group của bảng đó.

## Việc còn lại
1. Việc tiếp theo: kiểm tra chỉ đọc qua API `system-diagnostics`, `controller/config` và `Max Total Connections` của các DBCP trỏ 10.120.33.92:6033. Mục đích: xác nhận số liệu còn đúng trước GĐ0.1 (nâng thread 10 → 24).
2. GĐ0.1 và GĐ0.5 (FlowFile Expiration 1 giờ cho failure/retry), rồi GĐ1 (READ COMMITTED + back pressure, làm nhóm D/C trước): kế hoạch mục 3.

## Đang chờ
- Người dùng: chưa duyệt nâng thread lên 24, cũng chưa duyệt việc kiểm tra chỉ đọc ở bước 1.
- Chưa rõ ai xác nhận: tắt 12 group "TEST QLNV" cũ, dọn 13,4 GB hàng đợi NQ57 (không đảo ngược được).
- DBA: index `UpdatedDate` và đồng bộ NTP. IOC: có cần độ trễ dưới 1 phút (GĐ5) không. Xem kế hoạch mục 6.

## Lệnh kiểm tra
- Đăng nhập NiFi API: xem memory nifi-api-write. Đọc `GET /nifi-api/system-diagnostics`, `GET /nifi-api/controller/config`.
- MySQL: `SELECT NOW(), @@tx_isolation;` để xem độ lệch đồng hồ và mức cô lập.
