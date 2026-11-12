# Kế hoạch: group RT 142f3e8a thay toàn bộ "BTH - Đơn vị" (f8207212), lịch 1 phút

Khảo sát 12/11/2026 15:00 (backups/nifi_rtcopy_20261112/survey_rest.py → new_rt/survey_rest.json). Thời gian = TB/max mỗi lượt theo status history NiFi.

## Hiện trạng
- Chuỗi lõi (Tiếp nhận → Giao → Giao+Nhận, 12 bảng): đã có trong group mới, 39–42 s/lượt, đang chạy thử vào *_new_rt.
- Ngoài chuỗi lõi: 35 processor SQL đang bật, mọi bảng đích đều TRUNCATE + INSERT, gần như không bảng nào có khóa UNIQUE.

| Loại | Processor (TB / max) |
|---|---|
| Nhẹ ≤ 5 s | HĐND ×4 (~1 s), Copy HĐND ×5 → db_hdnd_qttt (~1 s), Khối tongquan_khoi (2 s), vanban_kiemdem (1,3 s), Dashboard LĐ ×2 (3,6 / 2,3 s), kpi_theo_nguoi_xu_ly (2,8 s), kpi_theo_don_vi (0,9 s), tongquan_vanban (0,8 s), NQ57 ×2 (~1 s), Mốc thời gian ×3 (~1,5 s) |
| Vừa 8–15 s | th_tongquan_donvi_tiepnhan (8,7 / 26 s), th_tongquan_donvi_giaonv (9 / 44 s), vanban_chitiet (8,5 / 17 s), chitiet_donvi (13 / 23 s, 373 MB) |
| Nặng > 25 s | tongquan_donvi (26 / 51 s), tongquan_donvi_kiemdem (42 / 61 s), qlnv_cbcc_danhgia (58 / 84 s, lịch 60') |
| Riêng | qlnv_kl_ctpct_chitiet (lịch 30', 3 stage, stage01 max 115 s) |
| Không chuyển | Nhiệm vụ chờ duyệt (STOPPED), BTC TW, Lịch sử BC tiến độ, Copy of Đánh giá cán bộ (DISABLED) |

Đường găng nếu ép tất cả 1 phút: lõi 40 s → chitiet_donvi 13 s → tongquan_donvi 26 s → kiemdem 42 s ≈ 120 s > 60 s. Không thể chạy 1 phút cho mọi thứ nếu chưa tối ưu SQL nặng.

## Giai đoạn 1: đưa hết vào group mới (nhóm nặng tạm sau cổng 15')
1. Sao chép các group con đang bật vào 142f3e8a, giữ thứ tự phụ thuộc như cũ, các nhánh độc lập chạy song song.
2. Mọi bảng TRUNCATE → staging swap (X__stg + RENAME, lock_wait_timeout 10 s); bảng lớn có khóa tự nhiên → upsert + DELETE theo sync_ts. Dashboard không bao giờ thấy bảng rỗng.
3. Nhóm nhẹ: chạy mỗi phút ngay sau chuỗi lõi. Nhóm vừa/nặng và kl_ctpct: giữ sau cổng (15' / 30' / 60' như hiện nay).
4. Chạy thử vào *_new_rt như chuỗi lõi, so sánh bằng new_rt_compare.py (không join vào bảng không index).
5. Cutover: RENAME *_new_rt → tên thật, đổi SQL về tên gốc, dừng toàn bộ group cũ.

## Giai đoạn 2: tối ưu nhóm nặng để lên 1 phút
- Từng câu: EXPLAIN, thêm index bảng nguồn, bỏ bảng dẫn xuất lồng (BNL), tính incremental theo UpdatedDate khi có thể.
- Thứ tự: tongquan_donvi_kiemdem → tongquan_donvi → chitiet_donvi → th_tongquan_donvi_* → vanban_chitiet → cbcc_danhgia → kl_ctpct.
- Mỗi câu xong: đo, đối chiếu, rồi mới bỏ cổng.

## Rủi ro
- Tải MySQL tăng (thêm ~15 s truy vấn nhẹ mỗi phút). Theo dõi processlist/khóa; MySQL đã restart 1 lần sáng 12/11.
- Copy HĐND ghi sang DB khác (db_hdnd_qttt): cần kiểm quyền và hành vi swap trên DB đó.
- kl_ctpct có cả nhánh TRUNCATE lẫn nhánh "DỌN …" song song: cần làm rõ trước khi chuyển.
