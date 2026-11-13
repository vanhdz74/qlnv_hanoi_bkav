# Bàn giao: NiFi → datamart_hanoi gần real-time (cập nhật 11/11/2026 ~15:00)

## Mục tiêu
Đưa group NiFi "BTH - Quản lý nhiệm vụ" (acf516ec-116f-119e-6a1c-aa864d1ac565) về chu kỳ 1–2 phút, không khóa TDNV. Kế hoạch: docs/ke_hoach_toi_uu_nifi_realtime.md

## Đã xong (11/11, đã chạy thật trên NiFi)
- Thread NiFi đã là 16 (ai đó nâng từ 10). Đo: TB 0,5–2,7 thread bận, đỉnh 12, chưa chạm trần.
- 67 label `[RT 11/11]` gắn trên group (ID ở backups/nifi_labels_rt_20261111_created.json).
- 48 luồng: thêm `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` trước INSERT, back pressure GFF→ReplaceText = 1.
- 20 luồng TRUNCATE+INSERT → upsert+delete (`sync_ts` lấy từ GFF, vì đồng hồ MySQL chậm 4'40"). DDL: thêm UNIQUE/sync_date trên 9 bảng. Số dòng của cả 20 bảng giữ nguyên, không có failure.
- Lịch: CRON lệch giây, không còn giây trùng. Kết quả: 28 luồng 1 phút (gồm 2 luồng captp chạy timer), 12 luồng 2 phút. Nhóm C (8–15s) giữ 5 phút, nhóm D giữ 15 phút.
- Đã dừng GFF của 3 group "TEST - … (1 phút, READ COMMITTED)". Chưa xóa.
- nv_captp_xp (BCĐ57 chi tiết): 2 luồng chạy timer 1 phút. BTH - Chi tiết mất ~15s/lượt, RC không làm nhanh hơn.

## Backup / rollback (script ở scratchpad phiên 9d69d51d; nếu mất thì dựng lại từ các file JSON)
- backups/backup_nifi_bth_qlnv_20261111_before_flowdef.json: flow definition cả group, trước mọi sửa đổi.
- backups/backup_nifi_bth_qlnv_20261111_items.json: 48 luồng trước khi thêm RC/BP/lịch.
- backups/backup_nifi_bth_trunc2upsert_20261111_before.json và backups/nifi_upsert_20261111/*.sql: 20 luồng chuyển upsert.
- backups/backup_nifi_captp_xp_{chitiet,lichsu}_20261111_before.json

## Quyết định đã chốt
- Mọi lần ghi lên NiFi: backup trước, thử 1–2 luồng, rồi mới làm hàng loạt. Thay đổi bảng nào thì sửa trong group của bảng đó.
- Bảng chạy dày phải là upsert+delete. Không chạy dày với kiểu TRUNCATE.

## Việc còn lại
1. ✅ Đo 20' (14:53–15:13): tải SQL ≈1,19 câu song song (trước 0,5–0,96), thread TB 1,58 / max 10 / 16, 0 lần chạm trần, 0 fail, 0 bulletin. Nặng nhất: captp BTH - Chi tiết 15,8s/lượt (26% 1 kết nối). Bảng gợi ý người dùng test RT: qlnv_chitiet_nvnhan_pth_ubndtp (dashboard ctnvn-pth), TaskId 362500.
2. Đối soát dữ liệu dashboard sau upsert. Đo số lần chờ khóa phía MySQL.
3. Pool `HaNoi_Datamart`: Max Wait 500ms → 5s (tránh lỗi khi >8 câu cùng lúc). Cần Disable service, 208 component đang dùng.
4. FlowFile Expiration 1 giờ cho các nhánh failure/retry (LogAttribute đang tắt, lỗi nằm im).
5. Nối tiếp các luồng "Gom nhóm" sau luồng chi tiết. Nhóm D: làm incremental (GĐ4). Xóa 3 group TEST.

## 12/11: chuỗi IOC `qlnv_tonghop_chitiet_khoi` (group BTH - Đơn vị f8207212), CHỜ DUYỆT
- Đã tạo group 142f3e8a "[RT CHỜ DUYỆT 12/11] …" phía dưới canvas, đang STOPPED. Đây là bản sao Tiếp nhận NV → Giao NV → Giao + Nhận NV, 16 processor chuyển sang ghi `X__stg` rồi `RENAME TABLE` swap (lock_wait_timeout 10s). Chọn swap thay vì upsert vì chuỗi có các bước UPDATE tại chỗ và `SELECT *` nối tiếp nhau.
- Lịch: CRON `17 */3 * * * ?`. Cổng 15 phút (attr gate15) dẫn ra 3 output port, chưa nối downstream. Cách cutover ghi trong label.
- SQL cũ/mới và script deploy: backups/nifi_rtcopy_20261112/. Backup: backups/backup_nifi_bth_donvi_20261112_full_before.json
- Chưa chạy lần nào. Cần kiểm khi chạy thử: thuộc tính gate15 có đi qua ExecuteSQL không; RENAME lỗi có ra failure không.
- Cập nhật cùng ngày theo yêu cầu người dùng: 15 bảng chuyển sang UPSERT + DELETE syncdate (SQL ở backups/nifi_rtcopy_20261112/upsert/), riêng tongquan vẫn dùng swap. Lịch đổi sang `17 * * * * ?`. Có processor "0. DDL upsert" (STOPPED) và "0. ROLLBACK DDL" (DISABLED). DDL phải chạy sau khi dừng chuỗi cũ, vì INSERT của nhom_* trong chuỗi cũ không ghi danh sách cột.
- **Chạy thử 12/11 11:24–11:47 (đã hoàn tác, chuỗi cũ chạy lại 11:48, cấu trúc bảng đã ROLLBACK):** DDL v2 idempotent 9,5s, không trùng khóa. 
  Sự cố: UPDATE Nhóm gộp dùng bảng dẫn xuất → BNL 82k×41k >60s → NiFi ngắt (socketTimeout 60s) nhưng query mồ côi giữ khóa → 3 upsert tiepnhan lỗi lock wait; đã KILL.
  Sửa v3 (upsert/v3_*.sql): bảng TEMPORARY có PK, chỉ UPDATE dòng đổi, `syncdate = syncdate`. Nhóm 60s+ → 1s. Đối chiếu logic cũ: lệch 0.
  Tuần tự: 7 lượt 57–60s. Đổi Tiếp nhận ∥ Giao + MergeContent theo sync_ts (rewire_parallel.py): 6 lượt 35–40s. 0 chờ khóa, NiFi ≤6 thread. Số dòng khớp mốc.
  Còn lại trong group bản sao: v3 + song song (STOPPED). Processor "0. ROLLBACK DDL" kẹt VALIDATING → đã dùng processor DDL để chạy ROLLBACK.
- 12/11 ~10:36: MySQL datamart restart ngay sau các câu COUNT DISTINCT của mình chạy qua SQL Lab. Không chạy câu đếm nặng trên bảng chitiet* nữa.

## 12/11 14:37: chạy thử song song vào bảng *_new_rt (ĐANG CHẠY)
- Group 142f3e8a ghi vào 13 bảng `*_new_rt` (new_rt.py; backup new_rt/backup_procs_before.json), GFF 1 phút, port downstream không nối. Luồng cũ vẫn chạy bình thường.
- Lượt 39–42s, 0 lỗi. Phát hiện bug v3: Update DonViChuTri nhánh Giao dùng logic Tiếp nhận → sửa v4 (new_rt/v4_*.sql). Sau sửa: số dòng khớp, lệch nội dung 0–22 dòng (do lệch thời điểm).
- So sánh: new_rt_compare.py. Dọn: dừng group + new_rt/DROP_new_rt.sql. Port ra tích 3 flowfile/15'.

## Đang chờ
- 12/11 ~16:45: group RT 142f3e8a (kèm label ghi chú) đã chuyển sang group "BTH _ Đơn vị _ Realtime (1p)" 142f43a6 (dưới QLNV), giữ nguyên trạng thái (move_rt_to_realtime.py; backup ở full/backup_RT_*). Cutover: nối port từ group mới tới group downstream nằm ở f8207212 → phải dùng port cấp cha.
- Người dùng duyệt group RT 142f3e8a, sau đó mới cutover. Rà 14:15 12/11: logic và hiệu năng đạt. Còn thiếu cho cutover: (a) nối 3 output port tới 7 group downstream (sau Tiếp nhận → acf5120d, bee45b54; sau Giao → bee43e21; sau Giao+Nhận → 916211c3, bee45689, f80d911d, f80bb6cb); (b) xóa 6 flowfile đang tồn ở cổng; (c) gỡ "0. ROLLBACK DDL" đang kẹt; (d) KHÔNG bấm Start cả group, vì sẽ bật 2 GFF 15' trùng và processor DDL. Đã kiểm: processor ngoài chuỗi đọc 15 bảng đều ghi rõ danh sách cột; các nhánh th_tongquan_donvi_* độc lập, giữ chạy ở group cũ.
- Người dùng: chọn lịch cho captp BTH - Chi tiết (1 phút hoặc 2 phút); duyệt các mục 3–5.
- Ban TCTW / BTH - Chi tiết: 58 flowfile kẹt trước InvokeHTTP "Gọi sang bên MB" (đang tắt). Cần người phụ trách quyết định.
- DBA: tăng Max Total pool (8 → 12?), index UpdatedDate, NTP cho MySQL. Các mục chưa duyệt cũ: tắt 12 group "TEST QLNV" cũ, dọn 13,4 GB hàng đợi NQ57.

## 12/11 15:36–15:50: đánh giá bản full RT (14 group hạ nguồn đã copy vào 142f3e8a, ghi *_new_rt)
- Script (chỉ đọc) ở backups/nifi_rtcopy_20261112/: full_compare.py (đếm + tổng CRC, không join), full_compare_cols.py (cột lệch + dòng lệch theo khóa UNIQUE bảng mới), full_compare_unit.py (GROUP BY đơn vị mỗi phía), full_perf.py. Log ở full/*_1.log.
- Đúng: 30 bảng có dữ liệu, số dòng khớp (lệch ≤2). Lệch nội dung 7–27 dòng/bảng, theo đơn vị 1–2 NV → do chụp lệch 6'. KHỚP tuyệt đối: tongquan, tongquan_khoi, nq57, kpi_theo_nguoi_xu_ly, *_theo_chuoi.
- Lỗi: output port của "Chi tiết đơn vị" và "Chi tiết HĐND" trong RT đang STOPPED → Kiểm đếm, Chi tiết HĐND, Copy HĐND không chạy (10 bảng _new_rt rỗng). cbcc_danhgia/kpi_theo_don_vi chưa có (GFF 60'). cham_muon cũ cũng đứng từ 05/2026.
- Hiệu năng (5'): lõi mỗi lượt nhanh hơn (tiepnhan 22,8→12,6s; giaonv 23,5→13,5s; DonViChuTri 3,5→0,4s), riêng qlnv_tonghop_chitiet 4,7→9,8s. Tải SQL RT 1,30 câu song song (cũ 0,82) vì chạy 1'/lần.
- 16:27–16:28 12/11: người dùng lỡ copy cả "BTH - Đơn vị" rồi Start cả group. 16:33 người dùng đã xóa bản copy. 16:35 đã Stop lại 8 component vừa bị bật (undo_start_1628.py; trạng thái trước khi sửa: full/undo_1628_before.json) → trạng thái giống lúc 16:00. Phụ phẩm: "Nhiệm vụ chờ duyệt" đã chạy khoảng 2 lượt UPSERT vào bảng thật trong khoảng 16:28–16:35.
- 16:53 so lần 2 (full/compare_2.log): 18 bảng khớp tuyệt đối (gồm Kiểm đếm, HĐND đã chạy trong lúc bật nhầm). Các bảng còn lại có số dòng bằng nhau; chỗ lệch là do hai bên chụp ở thời điểm khác nhau. cbcc_danhgia / kpi_theo_don_vi / cbcc_hdndtp ít dòng hơn vì bảng cũ tích lũy lịch sử theo monthkey (upsert không xóa), còn _new_rt mới bắt đầu từ hôm nay → khi cutover vẫn ghi vào bảng thật nên lịch sử giữ nguyên. So SQL (full_sql_diff.py, full_sql_class.py): đa số chỉ khác cách ghi (staging/RC/upsert); khác logic gồm 2 Update NhomCauTruc (TEMP có PK), 2 Update DonViChuTri (chỉ update dòng đổi + sửa v4), INSERT * → liệt kê cột.

## 13/11 09:50: rà sẵn sàng cutover RT 142f3e8a (chỉ đọc)
- Đạt: khoi_new_rt/tongquan_new_rt số dòng khớp cũ (23.990 / 12.881); chuỗi chạy mỗi phút, khoi 1,3s, tongquan 3,7s/lượt.
- Lỗi đang tồn: 00:07–00:19 13/11 chuỗi lõi (tiepnhan, nhom_tiepnhan, giaonv, giaonv_don_le, tongquan stg) bị ngắt 60s liên tiếp, đã tự hồi phục, chưa rõ nguyên nhân (job đêm/backup?). Kiểm đếm tongquan_donvi_kiemdem 61s > timeout → lỗi mọi lượt (luồng cũ cũng vậy). tongquan_donvi 54s, sát ngưỡng. kpi_theo_nguoi_xu_ly bị lock wait 17 lần.
- Tải SQL: RT 2,36 câu song song, cũ 0,61.
- tla_bao_cao_tong_quan có MAX(syncdate) = 01/11, cần kiểm BTH_theodoinq.

## 13/11 10:47–10:56: ĐÃ CUTOVER RT 142f3e8a → bảng thật
- Luồng cũ f8207212: 64 processor STOPPED, không xóa. Danh sách ở backups/nifi_rtcopy_20261112/cutover/running_ids.json, backup processor ở cutover/backup_*_104704.json.
- DDL v2 chạy trên bảng thật mất 16,9s. Đã thêm 5 khóa uk_rt_* và cột syncdate cho nhom_tiepnhan/nhom_giaonv. Sửa 58 processor bỏ hậu tố `_new_rt` (cutover/diff.txt). Xóa 3 output port cổng 15'. Hai cổng đặt auto-terminate qua_15phut và unmatched.
- "0. ROLLBACK DDL" vẫn kẹt RUN_ONCE/VALIDATING. Đã đổi SQL thành `SELECT 1` để không chạy nhầm. Bản rollback thật ở upsert/0_DDL_ROLLBACK_v2.sql.
- Theo dõi 6 phút (cutover/watch_1.log): 0 lỗi, thread ≤4. Chuỗi lõi cập nhật mỗi phút. tongquan ghi theo NOW() của MySQL (lệch -4,5 phút).
- Rollback: STOP RT → chạy 0_DDL_ROLLBACK_v2 → START lại các id old_running.

## Đang chờ (sau cutover)
- Kiểm các group hạ nguồn 15' (Chi tiết đơn vị, Kiểm đếm, HĐND) ở mốc :00/:15. Kiểm đếm 61s vượt timeout là lỗi cũ.
- 2–3 ngày ổn định → DROP các bảng *_new_rt, *_new_rt__stg (full/DROP_full.sql), xem lại trước khi chạy.
