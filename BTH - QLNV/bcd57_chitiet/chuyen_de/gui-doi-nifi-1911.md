Chào các anh chị đội NiFi,

Eform đã có API để NiFi gửi số tiến độ nhiệm vụ. Mời đội thử trên môi trường dev:

**1. Địa chỉ**
- Gửi số (N1): `POST http://10.2.22.69:28081/api/v1/integration/aggregation-flows/TDNV_NHIEM_VU/values`
- Xem lại lần nhận gần nhất (N2): `GET` cùng địa chỉ, kèm `?period_type=MONTH&period_date=2026-11-30`
- Header: `X-API-KEY: htbc_5ig1nTRj3GeMtbpQmdT_DEoXHjYws_Ng5Hn0KcXGK3E`
  Khoá chỉ dùng cho môi trường dev, nhờ đội không đưa khoá vào mã nguồn.

**2. Gói gửi**, mỗi kỳ một gói và gửi trọn bộ số của kỳ đó:

```json
{
  "period": { "type": "MONTH", "date": "2026-11-30" },
  "taken_at": "2026-11-19T10:00:00+07:00",
  "values": [
    { "department_id": 1234, "indicator_code": "NV01", "value": 12 }
  ]
}
```

- `department_id`: id phòng ban BMM.
- `taken_at`: lúc NiFi lấy số từ kho, không phải lúc gửi.
- `value`: số JSON, không bọc trong ngoặc kép. Không có số thì bỏ dòng, không gửi `null`.

**3. Mã chỉ số:** NV01–NV16, theo bảng đối chiếu chỉ số NQ57. Nhờ đội xác nhận hai cách hiểu Eform đang dùng:
- NV02 là số **lũy kế** tới ngày lấy số;
- NV06 là số quá hạn **chưa hoàn thành**, là một phần của NV05.

**4. Loại kỳ:** gửi theo từng chế độ, cùng mã `TDNV_NHIEM_VU`:

| Chế độ | `period` |
|---|---|
| Báo cáo tháng NQ57 | `{"type":"MONTH","date":"2026-11-30"}` |
| Báo cáo tuần NQ57 (tuần từ thứ Bảy) | `{"type":"WEEK","date":"2026-11-20","week_start":"SAT"}` |
| Báo cáo ngày NQ57 | `{"type":"DAY","date":"2026-11-19"}` |

Khi xem lại kỳ tuần bằng N2, thêm `&period_week_start=SAT`.

**5. Kết quả trả về**
- `200`: kèm số dòng nhận (`accepted`) và các dòng bị bỏ kèm lý do (`rejected`), ví dụ mã chỉ số lạ, phòng ban không có trong Eform.
- `401`: thiếu khoá hoặc khoá sai.
- `404`: sai mã quy trình.
- `409 SNAPSHOT_OUTDATED`: gói có `taken_at` cũ hơn gói Eform đang giữ cho kỳ đó.
- `413`: gói quá 5.000 dòng hoặc quá 2 MB.
- `422 PERIOD_INVALID`: kỳ sai.

**6. Lịch gửi đề xuất:** mỗi giờ trong giờ hành chính, không dày hơn 15 phút một lần. Kỳ vừa qua thì gửi lại khi số trong kho thay đổi, tới hết hạn nộp báo cáo.

Tài liệu đầy đủ: hợp đồng «API gửi số tổng hợp tự động NiFi → Eform», bản 1.2.0 (gửi kèm tệp).

Số NiFi gửi chỉ nằm ở bảng chờ. Số vào biểu khi cán bộ bấm «Tổng hợp số» trên Eform, và không đè ô đơn vị đã tự sửa.