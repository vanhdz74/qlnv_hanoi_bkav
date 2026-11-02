# QLNV (BMM) — Cấu trúc & quan hệ các bảng

Nguồn: `BMM_Database_Structure (1).docx` · CSDL `db_theodoinv_hn` (MySQL 5.7) · lập 08/07/2026.
Tài liệu chỉ mô tả **Nhóm I — 12 bảng nghiệp vụ lõi**. Các bảng danh mục và bảng nền tảng
tổ chức/người dùng **không có trong tài liệu** (xem mục 4).

---

## 1. Bản đồ quan hệ (tóm gọn)

```
                          ┌──────────────────────────┐
              ParentId ───┤       qlnv_task          ├─── TaskSourceId ──┐
              (cây NV,    │   PK TaskId · hub        │                   │ (2 chiều!)
               level)     └──┬───┬───┬───┬───┬───┬───┘                   │
                            │   │   │   │   │   │                       │
   ┌────────────────────────┘   │   │   │   │   └───────────────┐        │
   │                            │   │   │   │                   │        │
qlnv_task_user            qlnv_task_group  │  qlnv_task_pin  qlnv_report │
(TaskId,UserId,Role)      (TaskId,GroupId) │  (UserId,TaskId)  PK ReportId
 0=giao 1=chủ trì            → qlnv_group  │                     │  │
 2=phối hợp                                │                     │  └── ParentId (tự nối)
                          qlnv_task_tag    │              CombinationId
                          (TaskId,TagId)   │                     │
                             → qlnv_tag    │                     ▼
                                           │            qlnv_combination
                          qlnv_task_period_configs      PK CombinationId
                          (chỉ khi IsRecurring=1)       (TaskId, TargetDepartment,
                           PeriodType 1..4               TargetUser) = đơn vị phối hợp
                                           │
        ┌──────────────────────────────────┴──────────────┐
        │                                                  │
  qlnv_task_resolution                              qlnv_task_source
  (TaskId, ResolutionId) N-N                        PK TaskSourceId
        │        ▲                                  (TaskId, DocumentID,
        │        └── qlnv_task.ResolutionId          DocumentCopyID, ReportId)
        │            (đường thứ 2 — trùng!)
        ▼
  qlnv_resolution ── ResolutionGroupId → qlnv_resolution_group
  PK ResolutionId  ── SectorId          → qlnv_sector
                   ── TaskIdParent      → qlnv_task (NV cha giao xuống VB)

  qlnv_file (PK FileId) ── TaskId | ReportId | ResolutionId  ← gắn 1 trong 3
```

## 2. Vai trò từng bảng — 1 dòng

| Bảng | Grain | Vai trò |
|---|---|---|
| `qlnv_task` | 1 nhiệm vụ | **Hub duy nhất.** Mọi thứ khác treo vào `TaskId`. Có sẵn cả người giao/thực hiện, hạn, tiến độ, và **denormalize luôn thông tin văn bản nguồn** |
| `qlnv_task_user` | 1 người × 1 NV | Vai trò tham gia (`Role` 0 giao / 1 chủ trì / 2 phối hợp) + đã đọc, theo dõi, chuyển tiếp, duyệt, **hạn riêng** `ExpiredDate` |
| `qlnv_combination` | 1 đơn vị × 1 NV | Đơn vị/người **phối hợp** ở cấp đơn vị (khác `task_user` là cấp người) |
| `qlnv_report` | 1 báo cáo | Vòng đời xử lý: `Type` 0 y/c tiến độ · 1 tiến độ · 2 hoàn thành · 3 **xin gia hạn** (`NewExpiredDate`) |
| `qlnv_resolution` | 1 văn bản chỉ đạo | Nghị quyết/KH/QĐ làm căn cứ giao NV. Có `PositionName`, `AssignUserName`, `DocCode`, `StartDate` **lưu sẵn dạng text** |
| `qlnv_task_source` | 1 nguồn × 1 NV | Truy nguồn văn bản eGov (`DocumentID`, `DocumentCopyID`) |
| `qlnv_task_group` / `_tag` / `_resolution` | cặp | 3 bảng nối N-N thuần |
| `qlnv_task_pin` / `_period_configs` | phụ trợ | Ghim cá nhân · cấu hình chu kỳ NV định kỳ |
| `qlnv_file` | 1 file | Đính kèm; `Type` 2 VB chỉ đạo · 3 KH/HD · 4 CTHĐ |

## 3. Bốn cái bẫy khi viết query

**(1) Hai đường đi tới nghị quyết.** `qlnv_task.ResolutionId` *và* `qlnv_task_resolution`.
Join cả hai → nhân dòng. Tài liệu nói `qlnv_task_resolution` mới là quan hệ N-N chính thức,
`ResolutionId` là đường tắt 1-1 cũ. **Chọn một, kiểm bằng `COUNT` trước khi tin.**

**(2) Hai đường đi tới nguồn văn bản, ba chỗ lưu cùng dữ liệu.**
`qlnv_task.TaskSourceId → qlnv_task_source.TaskSourceId` ngược chiều với
`qlnv_task_source.TaskId → qlnv_task.TaskId`. Và thông tin văn bản nằm ở **3 nơi**:
`qlnv_task.Compendium/DocCode`, `qlnv_task.DocumentCompendium/DocumentCode/DocumentOrganization`,
`qlnv_task_source.Compendium/DocCode/Organization`. Với dashboard, **đọc thẳng cột trên
`qlnv_task` là rẻ nhất** — khỏi join, khỏi rủi ro nhân dòng.

**(3) Năm cách biết "nhiệm vụ xong chưa"** — `Status`, `State`, `Progress`,
`CompletedDate`, `ApprovedDate`. Chúng có thể lệch nhau (đơn vị gửi báo cáo hoàn thành
nhưng lãnh đạo chưa duyệt: `State=3` mà `Status` vẫn `1`). Luật cho dashboard ở mục 5.

**(4) Hạn xử lý có thể đã được gia hạn.** `qlnv_task.ExpireDate` là hạn hiện hành,
nhưng hạn gốc/hạn mới nằm ở `qlnv_report` (`Type=3`, `Status=1`, `NewExpiredDate`).
**Phải kiểm xem service có ghi đè `ExpireDate` khi duyệt gia hạn hay không** — nếu không,
mọi con số "quá hạn" sẽ sai lệch theo hướng phóng đại. Query ở file SQL có sẵn nhánh xử lý.

Ngoài ra: `ParentId`/`level` tạo cây nhiệm vụ → **đếm cả cha lẫn con là đếm trùng**.
`IsRecurring=1` sinh nhiều bản ghi theo kỳ. `DeletedDate IS NOT NULL` = đã xóa mềm,
`Status=5` = đã thu hồi — cả hai phải loại.

## 4. Những gì tài liệu KHÔNG có (phải xác nhận trước khi chạy production)

| Cần | Thực tế trong tài liệu | Hệ quả |
|---|---|---|
| **Danh mục đơn vị** (mã Part → tên) | Không có bảng nào. `TargetDepartment`, `AssignDepartment`, `DepartmentId`, `ResponsibleUnit` đều là `varchar` mã trần, **không FK** | Chart "theo đơn vị chủ trì" không có tên đơn vị → phải trỏ sang bảng org của nền tảng |
| **Danh mục người dùng** (UserId → tên, SĐT, chức vụ) | Không có. `AssignUser`, `TargetUser`, `ChargeUser`, `FollowUser`, `CreateUser` là UserId eGov | Cột "Lãnh đạo đơn vị và chuyên viên (Số ĐT)" của bảng chi tiết không dựng được |
| `qlnv_group`, `qlnv_tag`, `qlnv_sector`, `qlnv_resolution_group` | Bị **tham chiếu tới nhưng không mô tả** | "Nhóm nhiệm vụ" phải suy từ `qlnv_resolution_group` hoặc `qlnv_task.NameGroup` |
| `qlnv_kl_ctpct_chitiet`, `dm_user.dm_donvi` | **Không tồn tại** | Xem mục 6 |

Không có danh mục nào để join, nên query chỉ đọc **text đã lưu sẵn** trên `qlnv_task` /
`qlnv_resolution`, cột nào thiếu thì trả `'(KXD)'`. Thêm một tầng khó nữa: CSDL thật còn
**thiếu cả một số cột mà tài liệu này có mô tả** — xem [qlnv_bcd57_note.md](qlnv_bcd57_note.md)
mục 5.

## 5. Luật 4 trạng thái cho dashboard BCĐ 57

Dashboard có đúng 4 ô: HT trong hạn · HT quá hạn · Chưa HT còn hạn · Chưa HT quá hạn.
Ánh xạ sang `qlnv_task`:

```
ngay_ht  := COALESCE(ApprovedDate, CompletedDate)        -- ưu tiên ngày duyệt
han      := ExpireDate                                   -- (đã gia hạn — xem bẫy (4))
da_xong  := Status IN (3,4) OR ngay_ht IS NOT NULL

ht_trong : da_xong = 1 AND (han IS NULL OR ngay_ht <= han)
ht_qua   : da_xong = 1 AND ngay_ht > han
cht_con  : da_xong = 0 AND (han IS NULL OR NOW() <= han)
cht_qua  : da_xong = 0 AND han < NOW()
```

Đây là dạng rút gọn để đọc cùng schema. **Bản luật đang chạy thật** — có xử lý thêm trường
hợp `ngay_ht IS NULL` và hạn đã gia hạn — nằm ở [qlnv_bcd57_note.md](qlnv_bcd57_note.md)
mục 3; sửa luật thì sửa ở đó.

Hai điểm cần chốt nghiệp vụ:
- **`Status=4` (Kết thúc) có tính là hoàn thành không?** Query đang tính là có.
- **NV không có hạn** (`ExpireDate IS NULL`) đang bị dồn vào `cht_con`, làm ô này phồng lên.
  Query tách sẵn cột `khong_co_han` để đếm riêng.

## 6. Đối chiếu với `mart_bcd57 (1).txt` — bản cũ không chạy được

| Vấn đề | Chi tiết |
|---|---|
| **Sai nguồn** | Đọc `db_theodoinv_hn.qlnv_kl_ctpct_chitiet` với `LoaiNhiemVu='BCD57'`, `TrangThaiXoa=0`, `MaDonViChuTri`, `LanhDaoChiDao`… **Không cột nào, không bảng nào trong số đó tồn tại** trong tài liệu BMM |
| **Sai phiên bản MySQL** | `ROW_NUMBER() OVER (...)` và `DENSE_RANK() OVER (...)` → **fail ngay ở bước Validate** trên MySQL 5.7 |
| **Không theo pattern NiFi** | Dùng `SET @ngay_bc`, `DROP/CREATE TABLE`, `DELETE ... WHERE`, `CREATE VIEW` — `ExecuteSQLRecord` + `PutDatabaseRecord` chỉ nhận `truncate` + một `SELECT` trả record |
| **`INSERT ... SELECT` không dùng được** | NiFi nạp bằng `PutDatabaseRecord`; SQL phải **trả về dòng**, không tự ghi |
| Cube dư | Grain tháng của cube làm **mất filter "hạn từ–đến" theo ngày** của dashboard |

Bản viết lại, **2 file SQL riêng** (mỗi file = 1 processor NiFi):
[qlnv_bcd57_nhiemvu_select.sql](qlnv_bcd57_nhiemvu_select.sql) →
[qlnv_bcd57_dondoc_select.sql](qlnv_bcd57_dondoc_select.sql), DDL riêng ở
[qlnv_bcd57_ddl.sql](qlnv_bcd57_ddl.sql).

---

## 7. Phạm vi "BCĐ 57" — cần chốt trước khi chạy

Bảng `qlnv_task` **không có cột nào đánh dấu BCĐ 57**. Bốn ứng viên, xếp theo độ tin cậy:

1. **`qlnv_resolution.PositionName`** — khớp *chính xác* 3 giá trị filter "Lãnh đạo chỉ đạo"
   của dashboard (`Trưởng Ban Chỉ đạo 57`, `Phó Trưởng Ban Thường trực`,
   `Phó Trưởng Ban Chỉ đạo`). Đây gần như chắc chắn là nguồn của filter đó.
2. **`qlnv_resolution.ResolutionGroupId`** — khớp các giá trị "Nhóm nhiệm vụ"
   (`TBKL Ban Chỉ đạo 57`, `KH triển khai NQ 57`, `TBKL Thành ủy`, `QĐ UBND Thành phố`,
   `CV chỉ đạo BCĐ 57`) → đây là **danh mục loại văn bản giao**, dùng làm phạm vi lọc.
3. `qlnv_task_group → qlnv_group` — nếu BCĐ 57 được dựng thành một "chương trình".
4. `qlnv_task.Sector` / `NameGroup` — text tự do, kém tin cậy nhất.

Query dùng **(1)+(2)** qua `qlnv_task_resolution`, đặt trong một block `WHERE` có nhãn
`--- PHẠM VI BCĐ 57 ---` để đổi một chỗ.

Chạy 3 câu này trước để chốt (mục 8 bên dưới là bảng ánh xạ dashboard → cột).

```sql
-- (a) chức vụ người ký nào đang có trong dữ liệu?
SELECT PositionName, COUNT(*) FROM qlnv_resolution
 WHERE DeletedDate IS NULL GROUP BY PositionName ORDER BY 2 DESC;

-- (b) danh mục nghị quyết nào? (cần biết tên bảng qlnv_resolution_group)
SELECT ResolutionGroupId, COUNT(*) FROM qlnv_resolution
 WHERE DeletedDate IS NULL GROUP BY ResolutionGroupId ORDER BY 2 DESC;

-- (c) task gắn nghị quyết qua đường nào? Hai số này phải xấp xỉ nhau
SELECT (SELECT COUNT(*) FROM qlnv_task WHERE ResolutionId > 0 AND DeletedDate IS NULL) AS qua_cot,
       (SELECT COUNT(DISTINCT TaskId) FROM qlnv_task_resolution)                       AS qua_bang_noi;
```

---

## 8. Ánh xạ dashboard → cột · cấu hình Superset · NiFi

Đã chuyển sang [qlnv_bcd57_note.md](qlnv_bcd57_note.md) để không có hai bản trôi lệch nhau:

- mục 1 — hai query, thứ tự chạy trong NiFi
- mục 2 — giới hạn MySQL 5.7 / Jinja / NiFi
- mục 3 — kiến trúc 3 tầng của query 1, luật 4 trạng thái, cách chặn nhân dòng
- mục 4 — ba thứ query đang suy luận (phạm vi BCĐ 57, hạn gia hạn, 3 chỗ hở KPI)
- mục 5 — cột nào tài liệu có mà CSDL không có, và cách bật lại
- mục 6 — bảng ánh xạ dashboard → dataset/dimension, 3 native filter
- mục 7 — số đối chiếu từ ảnh dashboard, cách đọc kết quả kiểm tra

File này giữ đúng phạm vi của tên nó: **cấu trúc và quan hệ bảng nguồn**.
