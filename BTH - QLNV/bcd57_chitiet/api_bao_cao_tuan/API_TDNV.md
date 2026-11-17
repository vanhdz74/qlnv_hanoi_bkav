# API báo cáo tuần NQ57 cho app TDNV

Trả số liệu điền **"DE CUONG BAO CAO TUAN - UPDATE.docx"**: mục I.1 và các phụ lục 01–04. Bản 1, ngày 17/11/2026.

## Gọi API

```
GET  http://<máy NiFi nội bộ>:9990/bcd57/api/bao-cao-tuan?tu_ngay=2026-11-10&den_ngay=2026-11-16&id_don_vi=490.698.1307
POST http://<máy NiFi nội bộ>:9990/bcd57/api/bao-cao-tuan
     Content-Type: application/json
     {"tu_ngay": "2026-11-10", "den_ngay": "2026-11-16", "id_don_vi": "490.698.1307"}
Header bắt buộc:  X-Api-Key: <khóa do bên datamart cấp>
```

| tham số | bắt buộc | ý nghĩa |
|---|---|---|
| `den_ngay` | không | `YYYY-MM-DD`. Mặc định là hôm nay. |
| `tu_ngay` | không | `YYYY-MM-DD`. Mặc định là `den_ngay` lùi 6 ngày. |
| `id_don_vi` | không | id đơn vị chủ trì (chỉ gồm số và dấu chấm). Lấy cả các đơn vị con của id này. Để trống là toàn bộ. |

Mã phản hồi:
- 200: báo cáo JSON (cấu trúc ở mục dưới).
- 400: sai định dạng tham số.
- 401: thiếu hoặc sai `X-Api-Key`.
- 500: lỗi truy vấn.

Khi lỗi, body có dạng `{"ma_loi", "thong_bao", "thoi_diem"}`. Nếu API không trả lời trong 1 phút, NiFi trả 503.

## Cấu trúc JSON (mẫu đầy đủ: `mau_tra_ve.json`)

| khóa | ô trong đề cương | trường |
|---|---|---|
| `muc_1_tinh_hinh_nhiem_vu` | I.1 "Hiện đơn vị đang theo dõi … nhiệm vụ" | `tong_so`, `hoan_thanh`, `dang_thuc_hien`, `qua_han`, `ds_qua_han` (mảng tên nhiệm vụ) |
| `phu_luc_01` | PL01 (3 dòng: TP giao, cấp xã, Tổng số với `stt` = null) | `nguon_giao`, `tong_so`, `hoan_thanh`, `dang_thuc_hien`, `da_qua_thoi_han_giao`, `can_tiep_tuc_xu_ly`, `sap_den_han`, `bien_dong` (+ `giao_moi_trong_tuan`, `hoan_thanh_trong_tuan`) |
| `phu_luc_02` | PL02 hoàn thành trong tuần | `ten_nhiem_vu`, `van_ban_giao`, `co_quan_chu_tri`, `thoi_han_giao`, `ngay_ghi_nhan_hoan_thanh`, `san_pham_phai_hoan_thanh`*, `tai_lieu_kiem_chung`* |
| `phu_luc_03` | PL03 quá hạn cần tiếp tục xử lý | `ten_nhiem_vu`, `van_ban_giao`, `co_quan_chu_tri`, `thoi_han_hoan_thanh`, `so_ngay_qua_han`, `ket_qua_thuc_hien`, `nguyen_nhan_vuong_mac` |
| `phu_luc_04` | PL04 sắp đến hạn trong tháng của `den_ngay` | `ten_nhiem_vu`, `van_ban_giao`, `co_quan_chu_tri`, `thoi_han_hoan_thanh`, `tien_do` (%), `san_pham_phai_hoan_thanh`*, `muc_nguy_co` (Cao / Trung bình / Thấp) |

Mỗi dòng phụ lục còn có `stt`, `task_id` (id nhiệm vụ trên QLNV) và `nguon_giao`. Thứ tự đúng là theo `stt`; thứ tự phần tử trong mảng không được bảo đảm.
\* Chưa có nguồn dữ liệu nên trả `null`. Sẽ bổ sung cùng các chỉ số định danh ở đợt sau.

## Quy ước tính (tạm, chờ TDNV xác nhận)

- **Nhiệm vụ Thành phố giao:** `qlnv_chitiet_captp_xp_bcd57`, NQ57, 1 dòng cho mỗi đầu giao (cùng nguồn với dashboard 272).
- **Nhiệm vụ giao cấp xã:** `qlnv_chitiet_captp_xp_bcd57_full`, mỗi xã nhận tính là 1 nhiệm vụ.
- **Đang thực hiện** = chưa hoàn thành, gồm cả nhiệm vụ thường xuyên.
- **Cần tiếp tục xử lý** = chưa hoàn thành và hạn < `den_ngay`.
- **Đã quá thời hạn giao** = các nhiệm vụ "cần tiếp tục xử lý", cộng các nhiệm vụ đã hoàn thành nhưng muộn hơn hạn.
- **Biến động** = số nhiệm vụ giao mới và số hoàn thành trong khoảng `tu_ngay`..`den_ngay`. Chưa so với số đã chốt của tuần trước.
- **Mức nguy cơ:**
  - Cao: tiến độ < 50% và còn ≤ 7 ngày, hoặc tiến độ < 30%.
  - Trung bình: tiến độ < 80%.
  - Thấp: các trường hợp còn lại.
- Số liệu trả về là trạng thái hiện tại của datamart, được đồng bộ từ QLNV vài phút một lần. Hỏi lại tuần cũ thì phần trạng thái vẫn tính theo hiện tại.

## Vận hành (bên datamart)

- NiFi: group "API - TDNV BCD57 Bao cao tuan (20261117)". ID lưu trong `nifi_ids.json`.
- Sửa cách tính: sửa `build.py`, chạy `python3 build.py test` (kiểm qua SQL Lab), rồi `python3 deploy.py sql` để nạp lên NiFi, cuối cùng `python3 deploy.py test` (tự gọi API từ trong NiFi).
- Khóa API: `BCD57_API_KEY` trong `.env` của repo.
