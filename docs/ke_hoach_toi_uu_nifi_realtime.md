# Kế hoạch tối ưu luồng NiFi → datamart_hanoi (gần real-time, vận hành ổn định)

Cập nhật: 10/11/2026 · Số liệu đo trực tiếp trên NiFi `bdw-theodoinhiemvu` và MySQL `10.120.33.92:6033` (qua ProxySQL)

## 1. Hiện trạng (số đo)

### Máy NiFi
| Chỉ số | Giá trị | Nhận xét |
|---|---|---|
| CPU | **32 lõi**, load average **0,78** | Gần như rảnh (dùng khoảng 2–3%) |
| Heap JVM | 3,1 / 15,7 GB (20%) | Dư nhiều; GC Old = 0 lần |
| Ổ đĩa repository (flowfile/content/provenance chung 1 ổ) | dùng 54%, còn trống 133 GB | Ổn, nhưng xem mục *Hàng đợi kẹt* |
| **Thread pool (`maxTimerDrivenThreadCount`)** | **10** | **Đây là giới hạn chính**: 10 thread chia cho khoảng 1.064 processor đang chạy |
| NiFi | 1.27.0, Java 17, standalone (không cluster) | — |
| **Hàng đợi kẹt** | **143.573 flowfile / 13,1 GB**, trong đó 13,4 GB nằm trước các processor đã **Stopped** ở nhóm *Đồng Bộ DL NQ57* | Không bao giờ được xử lý, chiếm đĩa. Nếu ai đó bật lại processor sẽ có một đợt xử lý dồn dập |

### Các luồng ghi datamart
- 89 luồng chạy theo lịch: 56 luồng mỗi 5 phút, 8 luồng mỗi 15 phút, 15 luồng mỗi 60 phút, 9 luồng CRON.
- Tổng thời gian SQL một vòng khoảng **488 giây**. Tải DB trung bình khoảng **0,96 câu SQL nặng chạy song song**.
- Phân bố thời gian chạy: dưới 1 giây: 22 luồng · 1–5 giây: 40 · 5–20 giây: 15 · trên 20 giây: 4 (BTH Đơn vị: Tiếp nhận NV 72 giây, Đánh giá cán bộ 68 giây, Giao NV 60 giây; Kiểm đếm PB 'Giao' 20 giây).
- Tất cả các luồng dùng mẫu: `GenerateFlowFile (timer)` → upsert `INSERT…SELECT…ON DUPLICATE KEY UPDATE` → `DELETE … sync_date < sync_ts`. Mỗi lượt tính lại toàn bộ bảng.
- **12 luồng trong các group "TEST QLNV …" cũ** vẫn chạy mỗi 5 phút, chiếm khoảng 12% tải DB.

### MySQL nguồn và đích
- 5.7.44, `REPEATABLE-READ`, binlog ROW. `INSERT…SELECT` ở mức RR **đặt khóa S lên các dòng `qlnv_task`** mà nó đọc. TDNV ghi vào đúng các dòng đó sẽ phải chờ.
- Các luồng 15 phút gây ra các đợt chờ khóa định kỳ: ví dụ 16:18–16:21, khoảng 100 lần chờ, tổng khoảng 220 giây, trong khi bình thường chỉ khoảng 2,9 lần/phút.
- **Đồng hồ MySQL chậm khoảng 4 phút 40 giây** so với NiFi. Đây là lý do có `UpdatedDate` nằm "ở tương lai".
- Superset (DB TDNV id 8) đặt `cache_timeout = -1`, tức không cache. Datamart mới thì dashboard mới ngay.

### Kết quả pilot (3 luồng 'Nhận', Phòng Tổng hợp VP UBND TP, 10/11, 16:16–16:26)
| Luồng | Trước (5 phút, RR) | Pilot (1 phút, READ COMMITTED) | Đối soát |
|---|---|---|---|
| Chi tiết 'Nhận' | 1,0 giây/lượt | **0,18 giây** | 1602 = 1602 |
| Tổng quan & chi tiết 'Nhận' | 2,7 giây | **1,6 giây** | 1602 = 1602 |
| Lịch sử 'Nhận' | 1,3 giây | **0,7 giây** | 4332 = 4332 |

Không có lỗi, không tồn hàng đợi, không làm tăng chờ khóa. Độ trễ hiển thị giảm từ tối đa khoảng 5 phút xuống tối đa khoảng 1 phút.

## 2. Nguyên tắc thiết kế

1. **Ngân sách tải:** tổng tải DB trung bình ≤ **1,5 câu nặng song song**, đỉnh ≤ 4. Mỗi luồng có thời gian chạy ≤ **10%** chu kỳ của nó.
2. **Không khóa nguồn:** mọi `INSERT…SELECT` từ `db_theodoinv_hn` chạy ở mức `READ COMMITTED`.
3. **Không dồn hàng:** connection `GenerateFlowFile → …` đặt back pressure = **1**. `Concurrent tasks` = 1 cho các processor SQL.
4. **Không có hàng đợi vô chủ:** mọi connection failure hoặc retry có `FlowFile Expiration`, không trỏ vào processor đã tắt rồi bỏ mặc.
5. **Mỗi thay đổi đều có đường lui:** clone thành group TEST → chuyển sang chạy bản TEST → đo 30 phút → mới chạy chính thức. Có file backup JSON trong `backups/`.
6. **Thay đổi bảng nào thì nằm trong group của bảng đó.** Không sửa ngoài phạm vi đã duyệt.

## 3. Lộ trình

### Giai đoạn 0: dọn dẹp và tăng sức chịu tải (1 buổi, rủi ro thấp)
| # | Việc | Lý do | Đường lui |
|---|---|---|---|
| 0.1 | Nâng `maxTimerDrivenThreadCount` **10 → 24** (Controller Settings) | 32 lõi, load 0,78. Các thread SQL chủ yếu chờ I/O. 24 thread đủ cho các luồng 1 phút mà vẫn dưới số lõi | Trả về 10 |
| 0.2 | **Tắt 12 group "TEST QLNV …" cũ** (xem bảng phụ lục, nhóm "Tắt"). Cần xác nhận người sở hữu trước | Giảm khoảng 12% tải DB vô ích | Bật lại |
| 0.3 | Xử lý **13,4 GB hàng đợi kẹt** ở *Đồng Bộ DL NQ57* (luồng "kỳ cũ"): xác nhận với người phụ trách NQ57 rồi Empty queue, hoặc đặt FlowFile Expiration | Tránh đầy đĩa, tránh xử lý dồn khi có người bật lại | Không đảo ngược được, **bắt buộc xác nhận trước** |
| 0.4 | Nhờ vận hành **đồng bộ NTP** cho server MySQL | Lệch khoảng 4 phút 40 giây làm sai mọi logic dựa trên thời gian (watermark, quá hạn) | — |
| 0.5 | Các connection `PutSQL → LogAttribute (failure/retry)`: đặt **FlowFile Expiration 1 giờ** | Hiện LogAttribute đang Disabled nên lỗi tích tụ vô hạn | Bỏ expiration |

### Giai đoạn 1: READ COMMITTED + back pressure cho mọi luồng, chưa đổi lịch (1–2 ngày)
- Với mỗi luồng (trừ CRON và API ngoài): thêm `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` vào đầu câu upsert. Đặt back pressure = 1 cho connection sau `GenerateFlowFile`.
- Làm theo từng group cha, ưu tiên **nhóm D và C** (các luồng gây chờ khóa) trước.
- Đo lại thời gian chạy của từng luồng sau 1 ngày, cập nhật bảng phụ lục. Kỳ vọng thời gian giảm 40–80% như pilot.
- **Tiêu chí đạt:** không còn các đợt chờ khóa định kỳ 15 phút (chờ khóa ≤ khoảng 3 lần/phút), không có bulletin lỗi.

### Giai đoạn 2: đổi lịch theo nhóm (2–3 ngày, cuốn chiếu)
| Nhóm | Điều kiện (thời gian chạy sau GĐ1) | Lịch | Số luồng (ước tính) |
|---|---|---|---|
| **A** | < 3 giây | **1 phút** | khoảng 28 (gồm 3 luồng 'Nhận' đã pilot) |
| **B** | 3–8 giây | **2 phút** | khoảng 12 |
| **C** | 8–15 giây | **5 phút** (giữ), xuống 2 phút nếu GĐ1 kéo thời gian xuống dưới 8 giây | khoảng 8 |
| **D** | > 15 giây | giữ nguyên, chuyển sang GĐ4 | 6 |
| Giữ nguyên | API ngoài, danh mục 60 phút, CRON | không đổi | 23 |

- **Chạy lệch giờ:** bật các luồng cách nhau 5–10 giây để không có hàng chục luồng cùng chạy một giây.
- **Luồng phụ thuộc nhau** (luồng tổng hợp đọc từ bảng datamart do luồng khác ghi, ví dụ "Gom nhóm" đọc bảng chi tiết): **nối tiếp** bằng cách nối `PutSQL (success)` của luồng trước vào `ReplaceText` của luồng sau, thay vì 2 timer độc lập. Như vậy không bao giờ đọc phải bảng đang ghi dở.
- **Tải ước tính sau GĐ2:** khoảng **1,0 câu nặng song song**, xấp xỉ hiện nay (0,96). Phần tăng do chạy dày được bù bởi READ COMMITTED và việc tắt các group TEST cũ. Thread NiFi dùng khoảng 2–3 trên 24.

### Giai đoạn 3: giám sát và tự bảo vệ (song song với GĐ2)
Dựng một group NiFi *"Giám sát datamart"* chạy mỗi phút, ghi vào bảng `datamart_hanoi.sync_monitor`:
- Lần chạy thành công gần nhất của từng luồng (đặt `sync_watermark`, có thể hiển thị "Cập nhật lúc …" trên dashboard/IOC).
- Số chờ khóa/phút (`performance_schema.global_status`), số truy vấn chạy trên 30 giây (`PROCESSLIST`).
- Tổng hàng đợi NiFi (`/flow/status`).

Ngưỡng cảnh báo (bulletin, email hoặc Telegram nếu có):
- Một luồng quá 3 chu kỳ chưa thành công.
- Chờ khóa trên 20 lần/phút trong 3 phút liên tiếp.
- Hàng đợi trên 1.000 flowfile.
- Đĩa repository trên 75%.

Cầu dao thủ công: tài liệu hóa thao tác "trả nhóm A/B về 5 phút" (1 script). Dùng khi DB quá tải.

### Giai đoạn 4: viết lại 6 luồng nặng (nhóm D) theo kiểu đồng bộ từng phần (1–2 tuần)
Áp cho BTH Đơn vị (Tiếp nhận NV, Giao NV, Đánh giá cán bộ), 2 luồng "Tổng quan & chi tiết 'Giao'", BCĐ57 nv_captp_xp chi tiết:
1. **Tìm task thay đổi:** `qlnv_task.UpdatedDate`, cộng `qlnv_report`, `qlnv_task_user`, `qlnv_timeline` (`UpdatedDate`/`CreatedDate`), so với mốc lần chạy trước **trừ đi 10 phút chồng lấn** để bù lệch đồng hồ. Hiện **không có index** trên các cột `UpdatedDate`. Đề xuất DBA thêm index trên `qlnv_task(UpdatedDate)` và `qlnv_report(UpdatedDate)`, hoặc chấp nhận quét toàn bảng (112 nghìn dòng, khoảng 0,1–0,3 giây).
2. **Tính lại chỉ cho các task đó:** thêm `AND t.TaskId IN (…)` vào câu upsert hiện có. Logic tính giữ nguyên nên số liệu vẫn khớp summary.
3. **Xóa theo khóa:** chỉ xóa task bị xóa mềm hoặc không còn thỏa điều kiện trong tập thay đổi.
4. **Tính lại toàn bộ hằng đêm** (khoảng 01:00) để đối soát, và xử lý `tinh_trang` phụ thuộc `CURDATE()` khi sang ngày mới.
5. Mục tiêu: chu kỳ **1–2 phút**, mỗi lượt dưới 2 giây.

### Giai đoạn 5 (tùy chọn): kích hoạt tức thì từ TDNV/IOC
- NiFi đã có sẵn group *"API IOC MBF"* (HandleHttpRequest/Response). Có thể thêm endpoint `POST /sync-now {group}`: TDNV hoặc IOC gọi sau khi tạo hoặc sửa nhiệm vụ, NiFi chạy ngay các luồng nhóm A liên quan, gom các yêu cầu trong 5 giây.
- Độ trễ giảm từ ≤ 1 phút xuống **khoảng 5 giây**. Chỉ làm khi bên IOC thật sự cần, vì phải phối hợp code phía TDNV/IOC.

## 4. Kết quả kỳ vọng
| Chỉ số | Hiện tại | Sau GĐ2 | Sau GĐ4 (+GĐ5) |
|---|---|---|---|
| Nhiệm vụ mới hiện trên IOC (luồng chính) | ≤ 5–15 phút | **≤ 1 phút** | ≤ 1 phút (khoảng 5 giây với GĐ5) |
| Luồng nặng BTH Đơn vị | ≤ 15–60 phút | ≤ 15 phút | **≤ 2 phút** |
| Đợt chờ khóa định kỳ trên TDNV | mỗi 15 phút | **không còn** | không còn |
| Tải DB trung bình | khoảng 0,96 | khoảng 1,0 | < 1,0 |
| Rủi ro dồn hàng/đầy đĩa | 13 GB hàng đợi kẹt, failure tích tụ | đã xử lý, có cảnh báo | — |

## 5. Rủi ro và cách kiểm soát
| Rủi ro | Kiểm soát |
|---|---|
| READ COMMITTED đọc bản trước của task đang sửa dở | Lượt sau (≤ 1 phút) cập nhật. Chấp nhận được với dashboard |
| Một luồng chậm bất thường (DB bận) | Back pressure = 1 nên không dồn. Có cảnh báo "quá 3 chu kỳ". Cầu dao trả về 5 phút |
| Bật lại nhầm luồng có hàng đợi lớn | GĐ0 dọn hàng đợi kẹt, đặt FlowFile Expiration |
| Sai số liệu khi chuyển đổi | Mỗi group đối soát số dòng nguồn với datamart (thiếu phải bằng 0) trước khi chạy chính thức |
| Lệch đồng hồ DB | GĐ0.4 (NTP), watermark có chồng lấn 10 phút |

## 6. Việc cần quyết định
1. Ai xác nhận việc tắt 12 group "TEST QLNV …" cũ và dọn 13,4 GB hàng đợi NQ57?
2. Có được nâng thread NiFi lên 24 không (cần quyền admin Controller Settings, không cần restart)?
3. DBA có đồng ý thêm index `UpdatedDate` (GĐ4) và đồng bộ NTP không?
4. IOC có cần dưới 1 phút (GĐ5) hay ≤ 1 phút là đủ?

## Phụ lục: phân nhóm từng luồng (số đo 1 giờ, 10/11/2026, trước READ COMMITTED)

| Nhóm | Luồng (đường dẫn NiFi, bỏ tiền tố "Thành Ủy Hà Nội / QLNV / BTH - Quản lý nhiệm vụ") | Lịch hiện tại | Thời gian chạy TB (giây) | Lịch đề xuất |
|---|---|---|---:|---|
| A (đã chạy bản TEST) | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Nhận' | 5 min | 2.7 | 1 min |
| A (đã chạy bản TEST) | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Nhận' | 5 min | 1.3 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Giao' | 5 min | 3.0 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Chi tiết nhiệm vụ 'Giao' | 5 min | 2.9 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Thống kê nhanh chi tiết | 5 min | 2.9 | 1 min |
| A | QLNV - Ban chỉ đạo 57 / BTH - Chi tiết | 5 min | 2.6 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLVB - Chi tiết | 5 min | 2.3 | 1 min |
| A | Phân quyền | 5 min | 2.2 | 1 min |
| A | QLNV - Ban TCTW / BTH - Lịch sử tiến độ | 5 min | 2.1 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Tổng quan & chi tiết nhiệm vụ cần phê duyệt | 5 min | 2.0 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Nhận' | 5 min | 2.0 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Chi tiết nhiệm vụ 'Chờ duyệt' | 5 min | 1.8 | 1 min |
| A | QLNV - Ban chỉ đạo 57 / BTH - Tổng quan | 5 min | 1.8 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Lịch sử nhiệm vụ 'Chờ duyệt' | 5 min | 1.6 | 1 min |
| A | QLNV - Theo dõi thông báo kết luận và nhiệm vụ Sơn Tây / QLNV - Tiến trình xử lý | 5 min | 1.5 | 1 min |
| A | QLNV - Theo dõi thông báo kết luận và nhiệm vụ Sơn Tây / QLNV - Chi tiết | 5 min | 1.5 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Lịch sử nhiệm vụ 'Nhận' | 5 min | 1.4 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLVB - Chi tiết | 5 min | 1.3 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Lịch sử nhiệm vụ 'Giao' | 5 min | 1.1 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết nhiệm vụ cần phê duyệt | 5 min | 1.0 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Chờ duyệt' | 5 min | 1.0 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLVB - Chi tiết | 5 min | 1.0 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Chi tiết nhiệm vụ 'Chờ duyệt' | 5 min | 0.7 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Chi tiết nhiệm vụ 'Nhận' | 5 min | 0.6 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Tổng quan & chi tiết nhiệm vụ cần phê duyệt | 5 min | 0.6 | 1 min |
| A | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Chi tiết nhiệm vụ 'Chờ duyệt' | 5 min | 0.4 | 1 min |
| A | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Lịch sử nhiệm vụ 'Chờ duyệt' | 5 min | 0.3 | 1 min |
| A | QLNV - Đảng ủy UBND TP / BTH - Gom nhóm nhiệm vụ giao | 5 min | 0.1 | 1 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Giao' | 5 min | 7.1 | 2 min |
| B | QLNV - Đảng ủy UBND TP / BTH - Summary | 5 min | 6.2 | 2 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Lịch sử nhiệm vụ 'Nhận' | 5 min | 4.3 | 2 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Thống kê nhanh | 5 min | 4.1 | 2 min |
| B | QLNV - Ban chỉ đạo 57 chi tiết / nv_captp_xp (gộp TP + Xã, phường) / BTH - Lịch sử tiến độ | 5 min | 4.0 | 2 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Chi tiết nhiệm vụ 'Nhận' | 5 min | 3.7 | 2 min |
| B | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - TQ & chi tiết các nhiệm vụ 'Giao' - Gom nhóm nhiệm vụ | 15 min | 3.6 | 2 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng Thành ủy / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Nhận' | 5 min | 3.5 | 2 min |
| B | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / BTH_theodoinq | 15 min | 3.4 | 2 min |
| B | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - TQ & chi tiết các nhiệm vụ 'Giao' - Gom nhóm nhiệm vụ | 15 min | 3.4 | 2 min |
| B | QLNV - Ban chỉ đạo 57 / BTH - Lịch sử tiến độ | 5 min | 3.3 | 2 min |
| B | QLNV - Ban TCTW / BTH - Chi tiết | 5 min | 3.1 | 2 min |
| C | QLNV - Thống kê nhanh / QLNV - Tổng quan thống kê nhanh | 5 min | 13.8 | 5 min |
| C | QLNV - Đảng ủy UBND TP / BTH - Details | 5 min | 10.4 | 5 min |
| C | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Chi tiết nhiệm vụ 'Giao' | 5 min | 10.2 | 5 min |
| C | QLNV - Ban TCTW / BTH - Chi tiết nhiệm vụ | 5 min | 10.2 | 5 min |
| C | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Lịch sử nhiệm vụ 'Giao' | 5 min | 9.7 | 5 min |
| C | Thành Ủy Hà Nội / QLNV / BTH - Đơn vị / qlnv_kl_ctpct_chitiet | 30 min | 9.5 | 5 min |
| C | QLNV - Thống kê nhanh / QLVB - Lịch sử thống kê nhanh | 5 min | 9.4 | 5 min |
| C | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Chi tiết nhiệm vụ 'Giao' | 5 min | 8.1 | 5 min |
| D | Thành Ủy Hà Nội / QLNV / BTH - Đơn vị / Tiếp nhận NV | 15 min | 72.4 | giữ 15 min → Giai đoạn 4 (incremental) |
| D | Thành Ủy Hà Nội / QLNV / BTH - Đơn vị / Đánh giá cán bộ | 60 min | 67.7 | giữ 60 min → Giai đoạn 4 (incremental) |
| D | Thành Ủy Hà Nội / QLNV / BTH - Đơn vị / Giao NV | 15 min | 60.0 | giữ 15 min → Giai đoạn 4 (incremental) |
| D | QLNV - Kiểm đếm nv, Phòng ban thuộc UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Giao' | 15 min | 20.3 | giữ 15 min → Giai đoạn 4 (incremental) |
| D | QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Giao' | 15 min | 16.7 | giữ 15 min → Giai đoạn 4 (incremental) |
| D | QLNV - Ban chỉ đạo 57 chi tiết / nv_captp_xp (gộp TP + Xã, phường) / BTH - Chi tiết | 5 min | 16.1 | giữ 5 min → Giai đoạn 4 (incremental) |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Giao' | 15 min | 14.7 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Giao' | 5 min | 13.2 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Chi tiết nhiệm vụ 'Giao' | 5 min | 9.6 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết các nhiệm vụ 'Nhận' | 5 min | 3.5 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Ban chỉ đạo 57 / BTH - Lịch sử tiến độ | 5 min | 3.3 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Ban chỉ đạo 57 / BTH - Chi tiết | 5 min | 2.8 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Nhận' | 5 min | 2.5 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Chi tiết nhiệm vụ 'Chờ duyệt' | 5 min | 2.3 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Tổng quan & chi tiết nhiệm vụ cần phê duyệt | 5 min | 2.2 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Chi tiết nhiệm vụ 'Nhận' | 5 min | 1.9 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Phòng Tổng hợp, Văn phòng UBND TP / QLNV - Lịch sử nhiệm vụ 'Chờ duyệt' | 5 min | 1.9 | STOP |
| Tắt (TEST cũ) | TEST QLNV - Ban chỉ đạo 57 / BTH - Tổng hợp | 5 min | 1.7 | STOP |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_bao_cao_tong_quan_nq_khac | 60 min | 0 | 60 min |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_danh_sach_nhiem_vu_chi_tiet | 60 min | 0 | 60 min |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_bao_cao_tong_quan_tat_ca_nq | 60 min | 0 | 60 min |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS Khóa họp | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS Chương trình tiếp xúc | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS nguồn kiến nghị | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS Lĩnh vực kiến nghị | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / Danh sách kiến nghị | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / Thống kê theo đơn vị hành chính | 60 mins | 0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / Chi tiết kiến nghị | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / Thống kê theo đơn vị giải quyết | 60 mins | 0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS Kỳ họp | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / Thống kê tổng quan | 60 mins | 0 | 60 mins |
| Giữ nguyên (API/danh mục) | Thành Ủy Hà Nội / HĐND / DS Loại kiến nghị | 60 mins | 0.0 | 60 mins |
| Giữ nguyên (CRON) | QLNV - Ban chỉ đạo 57 chi tiết / Chuyên đề lớn | 0 0/30 * * * ? | 0.2 | 0 0/30 * * * ? |
| Giữ nguyên (CRON) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_bao_cao_tong_quan | 0 15 0 * * ? | 0 | 0 15 0 * * ? |
| Giữ nguyên (CRON) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_danh_sach_nhiem_vu_chi_tiet_nq_khac | 0 18 0 * * ? | 0 | 0 18 0 * * ? |
| Giữ nguyên (CRON) | Thành Ủy Hà Nội / QLNV / API - TDNV NQ57 (Mới) (20260401) / tla_danh_sach_nhiem_vu_chi_tiet_tat_ca_nq | 0 16 0 * * ? | 0 | 0 16 0 * * ? |
| Giữ nguyên (CRON) | Thành Ủy Hà Nội / QLNV / EGov - Phòng ban | 0 0 0 * * ? | 0 | 0 0 0 * * ? |
| Giữ nguyên (CRON) | QLNV - Ban chỉ đạo 57 chi tiết / NQ57 - chuyen_de_chi_tiet_nq57 (BC tháng) | 0 0 7 * * ? | 0 | 0 0 7 * * ? |
| Giữ nguyên (CRON) | HĐND Hà Nội / Đồng bộ user vala / api_user_vala | 0 0 23 ? * * | 0 | 0 0 23 ? * * |
| Giữ nguyên (CRON) | HĐND Hà Nội / Đồng bộ user vala / api_vala_departments | 0 0 23 ? * * | 0 | 0 0 23 ? * * |
| Giữ nguyên (CRON) | HĐND Hà Nội / Đồng bộ user vala / api_vala_positions | 0 0 23 ? * * | 0 | 0 0 23 ? * * |
