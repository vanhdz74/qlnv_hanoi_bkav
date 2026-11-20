# API báo cáo tuần NQ57: tài liệu tích hợp cho app TDNV

> **ĐÃ GỠ 19/11/2026.** Bỏ hướng TDNV gọi vào; group NiFi cổng 9990 đã xóa (sao lưu: `backups/backup_nifi_api_bcd57_baocaotuan_9990_20261119_before_delete.json`). Thay bằng NiFi đẩy số sang Eform: xem `../api_eform_tdnv/`.

Bản 2, ngày 19/11/2026. Thay bản 1 ngày 17/11/2026.

API trả số liệu để điền **"DE CUONG BAO CAO TUAN - UPDATE.docx"**: mục I.1 và các phụ lục 01–04.
Mỗi lần gọi trả về **một JSON đầy đủ** cho một tuần và một đơn vị. API trả kết quả ngay trong lần gọi đó (khoảng 2–3 giây) và không gọi ngược lại sang hệ thống TDNV.

Tệp gửi kèm: `mau_tra_ve.json`, phản hồi thật của Sở Y tế cho tuần 13–19/11/2026.

---

## 1. Kết nối

| | |
|---|---|
| Địa chỉ | `<ĐỊA CHỈ>/bcd57/api/bao-cao-tuan` (bên datamart gửi riêng) |
| Phương thức | `GET` hoặc `POST`, kết quả như nhau |
| Xác thực | header `X-Api-Key: <khóa>` (khóa gửi riêng; không ghi vào mã nguồn, không đưa lên kho mã chung) |
| Kiểu trả về | `application/json; charset=UTF-8` |
| Thời gian chờ tối đa | 60 giây. Quá thời gian này API trả 503 |

## 2. Tham số

Với `GET`, truyền tham số trên query string. Với `POST`, truyền trong body JSON (`Content-Type: application/json`). Nếu cùng một tham số có ở cả hai nơi thì API dùng giá trị trong body.

| Tham số | Bắt buộc | Định dạng | Ý nghĩa | Mặc định |
|---|---|---|---|---|
| `den_ngay` | không | `YYYY-MM-DD` | Ngày cuối của tuần báo cáo | Hôm nay |
| `tu_ngay` | không | `YYYY-MM-DD` | Ngày đầu của tuần báo cáo | `den_ngay` lùi 6 ngày |
| `id_don_vi` | không | chỉ gồm chữ số và dấu chấm, tối đa 100 ký tự | id đơn vị chủ trì trên QLNV (dạng đường dẫn, ví dụ `490.698.1307.1352`). Kết quả **gồm cả các đơn vị con** | Để trống là lấy toàn Thành phố |

Ví dụ phạm vi đơn vị:

| `id_don_vi` | Phạm vi |
|---|---|
| (trống) | Toàn Thành phố |
| `490.698` | UBND Thành phố và mọi đơn vị trực thuộc |
| `490.698.1307.1352` | Sở Y tế |

Sai định dạng thì API trả 400. API không kiểm tra `tu_ngay` ≤ `den_ngay`: nếu gửi ngược thì các số "trong tuần" sẽ bằng 0.

## 3. Ví dụ gọi

**curl, GET**
```bash
curl -H "X-Api-Key: $KHOA" \
  "<ĐỊA CHỈ>/bcd57/api/bao-cao-tuan?tu_ngay=2026-11-13&den_ngay=2026-11-19&id_don_vi=490.698.1307.1352"
```

**curl, POST**
```bash
curl -X POST -H "X-Api-Key: $KHOA" -H "Content-Type: application/json" \
  -d '{"tu_ngay":"2026-11-13","den_ngay":"2026-11-19","id_don_vi":"490.698.1307.1352"}' \
  "<ĐỊA CHỈ>/bcd57/api/bao-cao-tuan"
```

**JavaScript / TypeScript**
```js
const res = await fetch(`${DIA_CHI}/bcd57/api/bao-cao-tuan`, {
  method: "POST",
  headers: { "X-Api-Key": KHOA, "Content-Type": "application/json" },
  body: JSON.stringify({ tu_ngay: "2026-11-13", den_ngay: "2026-11-19", id_don_vi: "490.698.1307.1352" }),
  signal: AbortSignal.timeout(70_000),
});
const data = await res.json();
if (!res.ok) throw new Error(`${data.ma_loi}: ${data.thong_bao}`);
const pl03 = [...data.phu_luc_03].sort((a, b) => a.stt - b.stt);
```

**C# (.NET)**
```csharp
using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(70) };
http.DefaultRequestHeaders.Add("X-Api-Key", khoa);
var res = await http.PostAsJsonAsync($"{diaChi}/bcd57/api/bao-cao-tuan",
    new { tu_ngay = "2026-11-13", den_ngay = "2026-11-19", id_don_vi = "490.698.1307.1352" });
var json = await res.Content.ReadAsStringAsync();   // 200: báo cáo; khác 200: {"ma_loi","thong_bao","thoi_diem"}
```

## 4. Phản hồi thành công (200)

### 4.1. Khung chung
```json
{
  "tu_ngay": "2026-11-13",
  "den_ngay": "2026-11-19",
  "id_don_vi": "490.698.1307.1352",
  "thoi_diem": "2026-11-19 14:16:12",
  "muc_1_tinh_hinh_nhiem_vu": { ... },
  "phu_luc_01": [ ... ],
  "phu_luc_02": [ ... ],
  "phu_luc_03": [ ... ],
  "phu_luc_04": [ ... ]
}
```

| Khóa | Kiểu | Ý nghĩa |
|---|---|---|
| `tu_ngay`, `den_ngay` | string `YYYY-MM-DD` | Tuần đã tính, sau khi điền giá trị mặc định |
| `id_don_vi` | string | Đơn vị đã lọc (`""` là toàn Thành phố) |
| `thoi_diem` | string `YYYY-MM-DD HH:mm:ss` | Thời điểm API nhận yêu cầu (giờ Việt Nam) |
| `phu_luc_02/03/04` | array | Mảng rỗng `[]` nếu không có nhiệm vụ nào, không bao giờ trả `null` |

Thứ tự khóa trong object và thứ tự phần tử trong mảng **không được bảo đảm**. Hãy sắp xếp các dòng theo `stt`.

### 4.2. `muc_1_tinh_hinh_nhiem_vu`: mục I.1
Câu cần điền: *"Hiện đơn vị đang theo dõi **[tong_so]** nhiệm vụ, gồm **[hoan_thanh]** nhiệm vụ đã hoàn thành và **[dang_thuc_hien]** nhiệm vụ đang thực hiện, trong đó có **[qua_han]** nhiệm vụ đã quá thời hạn (gồm **[ds_qua_han]**)."*

| Khóa | Kiểu | Ý nghĩa |
|---|---|---|
| `tong_so` | number | Tổng nhiệm vụ đang theo dõi (nhiệm vụ Thành phố giao và nhiệm vụ giao cấp xã) |
| `hoan_thanh` | number | Đã hoàn thành |
| `dang_thuc_hien` | number | `tong_so − hoan_thanh` (gồm cả nhiệm vụ thường xuyên) |
| `qua_han` | number | Chưa hoàn thành và hạn < `den_ngay` |
| `ds_qua_han` | array string | Tên các nhiệm vụ quá hạn (cùng tập với PL03). Có thể có tên trùng nhau vì là hai nhiệm vụ khác nhau |

### 4.3. `phu_luc_01`: bảng tổng hợp theo dõi nhiệm vụ tuần
Luôn có đúng 3 phần tử:

| `stt` | `nguon_giao` |
|---|---|
| `1` | `"Nhiệm vụ Thành phố giao"` |
| `2` | `"Nhiệm vụ giao cấp xã"` |
| `null` | `"Tổng số"` (= dòng 1 + dòng 2) |

| Cột đề cương | Khóa | Kiểu |
|---|---|---|
| STT | `stt` | number \| null |
| Nguồn giao nhiệm vụ | `nguon_giao` | string |
| Tổng số | `tong_so` | number |
| Hoàn thành | `hoan_thanh` | number |
| Đang thực hiện | `dang_thuc_hien` | number |
| Đã quá thời hạn giao | `da_qua_thoi_han_giao` | number |
| Trong đó cần tiếp tục xử lý | `can_tiep_tuc_xu_ly` | number |
| Sắp đến hạn (trong tháng) | `sap_den_han` | number |
| Biến động chính so với tuần trước | `bien_dong` | string, ví dụ `"Giao mới 0, hoàn thành 1 nhiệm vụ trong tuần"` |
| (thêm) | `giao_moi_trong_tuan`, `hoan_thanh_trong_tuan` | number, hai số dùng để ghép `bien_dong` |

### 4.4. Các dòng của `phu_luc_02`, `phu_luc_03`, `phu_luc_04`
Mọi dòng của 3 phụ lục đều có các khóa chung sau:

| Khóa | Kiểu | Ý nghĩa |
|---|---|---|
| `stt` | number | Số thứ tự trong phụ lục, bắt đầu từ 1 |
| `task_id` | number | id nhiệm vụ trên QLNV |
| `nguon_giao` | string | `"Nhiệm vụ Thành phố giao"` hoặc `"Nhiệm vụ giao cấp xã"` |
| `ten_nhiem_vu` | string | Tên nhiệm vụ |
| `van_ban_giao` | string | Số ký hiệu văn bản giao, ví dụ `"20-KH/BCĐ57"` |
| `co_quan_chu_tri` | string | Với nhiệm vụ giao cấp xã: tên xã, phường |

**PL02: nhiệm vụ được ghi nhận hoàn thành trong tuần** (đã hoàn thành, ngày hoàn thành nằm trong `tu_ngay`..`den_ngay`)

| Cột đề cương | Khóa | Kiểu |
|---|---|---|
| Thời hạn giao | `thoi_han_giao` | string `YYYY-MM-DD` \| null |
| Ngày ghi nhận hoàn thành | `ngay_ghi_nhan_hoan_thanh` | string `YYYY-MM-DD` |
| Sản phẩm phải hoàn thành | `san_pham_phai_hoan_thanh` | luôn `null` (QLNV chưa có trường) |
| Tài liệu kiểm chứng | `tai_lieu_kiem_chung` | luôn `null` (QLNV chưa có trường) |

**PL03: nhiệm vụ đã quá thời hạn giao cần tiếp tục xử lý** (chưa hoàn thành, hạn < `den_ngay`)

| Cột đề cương | Khóa | Kiểu |
|---|---|---|
| Thời hạn hoàn thành | `thoi_han_hoan_thanh` | string `YYYY-MM-DD` |
| (thêm) | `so_ngay_qua_han` | number = `den_ngay − thoi_han_hoan_thanh` |
| Kết quả thực hiện, sản phẩm đã có | `ket_qua_thuc_hien` | string \| null (có thể là chuỗi rỗng) |
| Nguyên nhân quá hạn, vướng mắc | `nguyen_nhan_vuong_mac` | string \| null (có thể là `"—"`) |

**PL04: nhiệm vụ sắp đến hạn trong tháng** (chưa hoàn thành, `den_ngay` ≤ hạn ≤ ngày cuối tháng của `den_ngay`)

| Cột đề cương | Khóa | Kiểu |
|---|---|---|
| Thời hạn hoàn thành | `thoi_han_hoan_thanh` | string `YYYY-MM-DD` |
| Tiến độ đến thời điểm báo cáo | `tien_do` | number (%, 0–100) \| null |
| Sản phẩm phải hoàn thành | `san_pham_phai_hoan_thanh` | luôn `null` |
| Mức nguy cơ | `muc_nguy_co` | `"Cao"` \| `"Trung bình"` \| `"Thấp"` |

Cách tính mức nguy cơ:
- **Cao:** tiến độ < 50% và còn ≤ 7 ngày đến hạn, hoặc tiến độ < 30%.
- **Trung bình:** tiến độ < 80%.
- **Thấp:** các trường hợp còn lại.

Nếu `tien_do` là `null` thì tính như 0%.

### 4.5. Ví dụ thật (Sở Y tế, 13–19/11/2026, chuỗi dài đã rút gọn)
```json
{
  "tu_ngay": "2026-11-13", "den_ngay": "2026-11-19", "id_don_vi": "490.698.1307.1352",
  "thoi_diem": "2026-11-19 14:16:12",
  "muc_1_tinh_hinh_nhiem_vu": {"tong_so": 22, "hoan_thanh": 9, "dang_thuc_hien": 13, "qua_han": 4,
    "ds_qua_han": ["Hình thành kho lưu trữ hình ảnh y tế tập trung…", "Phát triển mô hình kinh tế tóc bạc…", "…", "…"]},
  "phu_luc_01": [
    {"stt": 1, "nguon_giao": "Nhiệm vụ Thành phố giao", "tong_so": 22, "hoan_thanh": 9, "dang_thuc_hien": 13,
     "da_qua_thoi_han_giao": 5, "can_tiep_tuc_xu_ly": 4, "sap_den_han": 0,
     "bien_dong": "Giao mới 0, hoàn thành 0 nhiệm vụ trong tuần", "giao_moi_trong_tuan": 0, "hoan_thanh_trong_tuan": 0},
    {"stt": 2, "nguon_giao": "Nhiệm vụ giao cấp xã", "tong_so": 0, "hoan_thanh": 0, "dang_thuc_hien": 0,
     "da_qua_thoi_han_giao": 0, "can_tiep_tuc_xu_ly": 0, "sap_den_han": 0,
     "bien_dong": "Giao mới 0, hoàn thành 0 nhiệm vụ trong tuần", "giao_moi_trong_tuan": 0, "hoan_thanh_trong_tuan": 0},
    {"stt": null, "nguon_giao": "Tổng số", "tong_so": 22, "hoan_thanh": 9, "dang_thuc_hien": 13,
     "da_qua_thoi_han_giao": 5, "can_tiep_tuc_xu_ly": 4, "sap_den_han": 0,
     "bien_dong": "Giao mới 0, hoàn thành 0 nhiệm vụ trong tuần", "giao_moi_trong_tuan": 0, "hoan_thanh_trong_tuan": 0}
  ],
  "phu_luc_02": [],
  "phu_luc_03": [
    {"stt": 1, "task_id": 11223, "nguon_giao": "Nhiệm vụ Thành phố giao",
     "ten_nhiem_vu": "Hình thành kho lưu trữ hình ảnh y tế tập trung…", "van_ban_giao": "20-KH/BCĐ57",
     "co_quan_chu_tri": "Sở Y tế", "thoi_han_hoan_thanh": "2026-06-30", "so_ngay_qua_han": 142,
     "ket_qua_thuc_hien": "Sở Y tế đã có Tờ trình số 7658/TTr-SYT ngày 29/7/2026…", "nguyen_nhan_vuong_mac": "—"}
  ],
  "phu_luc_04": []
}
```

Dòng mẫu thật của PL02 và PL04 (lấy toàn Thành phố, cùng tuần):
```json
{"stt": 1, "task_id": 387920, "nguon_giao": "Nhiệm vụ Thành phố giao", "ten_nhiem_vu": "Các tổ chức đảng, Đảng ủy xã, phường…",
 "van_ban_giao": "21-CV/BCĐ57", "co_quan_chu_tri": "Các Xã, Phường và Cơ quan Đảng bộ trực thuộc",
 "thoi_han_giao": "2026-10-25", "ngay_ghi_nhan_hoan_thanh": "2026-11-18",
 "san_pham_phai_hoan_thanh": null, "tai_lieu_kiem_chung": null}

{"stt": 1, "task_id": 362547, "nguon_giao": "Nhiệm vụ Thành phố giao", "ten_nhiem_vu": "Phối hợp tiếp nhận, triển khai và đưa vào sử dụng Nền tảng kết nối…",
 "van_ban_giao": "1014-CV/TU", "co_quan_chu_tri": "Văn phòng Thành ủy", "thoi_han_hoan_thanh": "2026-11-20",
 "tien_do": 0, "san_pham_phai_hoan_thanh": null, "muc_nguy_co": "Cao"}
```

## 5. Lỗi

Khi lỗi, body luôn có dạng:
```json
{"ma_loi": 401, "thong_bao": "Thiếu hoặc sai header X-Api-Key", "thoi_diem": "2026-11-19 14:16:19"}
```

| HTTP | Khi nào | Xử lý phía TDNV |
|---|---|---|
| 400 | Sai định dạng `tu_ngay`, `den_ngay` hoặc `id_don_vi` | Sửa tham số |
| 401 | Thiếu hoặc sai `X-Api-Key` | Kiểm lại khóa |
| 500 | Lỗi truy vấn cơ sở dữ liệu (`thong_bao` ghi chi tiết) | Thử lại sau; nếu còn lỗi thì báo bên datamart |
| 503 | Quá 60 giây chưa có kết quả, hoặc máy chủ đang bận | Thử lại sau 1–2 phút |

## 6. Nguồn và quy ước tính số liệu

**Nguồn và độ mới**
- Số liệu lấy từ QLNV, đồng bộ sang datamart **mỗi phút**. Một thay đổi trên QLNV có trong API sau khoảng 1–2 phút.
- **Không có số chốt theo tuần.** Các ô trạng thái (hoàn thành, đang thực hiện, quá hạn, sắp đến hạn) luôn tính theo dữ liệu tại lúc gọi. Hỏi lại tuần cũ thì chỉ các số "trong tuần" (`giao_moi_trong_tuan`, `hoan_thanh_trong_tuan`, PL02) tính đúng theo khoảng ngày đó. Nếu TDNV cần lưu số đã nộp, hãy lưu JSON nhận được tại thời điểm chốt.

**Cách đếm nhiệm vụ**
- **Nhiệm vụ Thành phố giao:** nhiệm vụ NQ57 do Thành phố giao, mỗi đầu giao tính 1 nhiệm vụ.
- **Nhiệm vụ giao cấp xã:** mỗi xã, phường nhận tính là 1 nhiệm vụ.
- **Hoàn thành:** tình trạng "Đã hoàn thành" trên QLNV. **Đang thực hiện** là phần còn lại, gồm cả nhiệm vụ thường xuyên.

**Quá hạn và sắp đến hạn**
- **Cần tiếp tục xử lý:** chưa hoàn thành và hạn < `den_ngay`.
- **Đã quá thời hạn giao:** các nhiệm vụ cần tiếp tục xử lý, cộng các nhiệm vụ đã hoàn thành nhưng ngày hoàn thành muộn hơn hạn.
- **Sắp đến hạn:** chưa hoàn thành và hạn nằm từ `den_ngay` đến ngày cuối tháng của `den_ngay`.

**Biến động:** số nhiệm vụ giao mới và số nhiệm vụ hoàn thành trong `tu_ngay`..`den_ngay`. Chưa so với số đã chốt của tuần trước.

**Phần không có trong API:** các mục I.2, II và III của đề cương là nội dung đơn vị tự viết, API không trả.

## 7. Khuyến nghị khi tích hợp

- **Cách gọi:** gọi khi người dùng mở hoặc làm mới báo cáo. Không cần gọi dày hơn 1 lần mỗi phút, vì số liệu chỉ cập nhật mỗi phút.
- **Đặt thời gian chờ phía client ≥ 70 giây.** Gọi cho toàn Thành phố trả khoảng 80 KB, mất vài giây.
- **Phân biệt nhiệm vụ:** dùng `task_id`, không dùng tên. Có những nhiệm vụ trùng tên.
- **Hiển thị:** tự đổi ngày `YYYY-MM-DD` sang `dd/mm/yyyy`. Dòng PL01 có `stt = null` là dòng "Tổng số", in ở cuối bảng.

---

## Phụ lục: vận hành (nội bộ bên datamart, không cần gửi TDNV)

- NiFi: group "API - TDNV BCD57 Bao cao tuan (20261117)", https://bdw-theodoinhiemvu.hanoi.gov.vn/nifi/?processGroupId=142f451b-6ef6-1fc2-ddb6-2fe21e4cd829. ID các processor ở `nifi_ids.json`. Cổng 9990 (HandleHttpRequest).
- Nguồn: `datamart_hanoi.qlnv_chitiet_captp_xp_bcd57` (group "BTH - Chi tiết (Gộp)") và `qlnv_chitiet_captp_xp_bcd57_full` (group "BTH - Chi tiết"), đồng bộ mỗi phút.
- Sửa cách tính: sửa `build.py` → chạy `python3 build.py test` (kiểm qua SQL Lab) → `python3 deploy.py sql` (nạp lên NiFi) → `python3 deploy.py test` (gọi API từ trong NiFi).
- Khóa API: `BCD57_API_KEY` trong `.env` của repo và trong processor "Kiem tra khoa + tham so". Đổi khóa thì sửa cả hai nơi.
- Cổng 9990 hiện chưa mở ra ngoài: cần bên hạ tầng mở cổng, hoặc thêm đường dẫn `/bcd57/api/` trên openresty trỏ sang NiFi `:9990`.
