# TÀI LIỆU CẤU TRÚC CƠ SỞ DỮ LIỆU

**Hệ thống Quản lý Nhiệm vụ (BMM) · CSDL `db_theodoinv_hn` (MySQL)**  
_Ngày lập: 08/07/2026_

---

## Giới thiệu

Tài liệu mô tả cấu trúc từng bảng và ý nghĩa từng cột trong CSDL của hệ thống, được tổng hợp từ script db_theodoinv_hn.sql kết hợp phân tích mã nguồn (Entity/Service của bmm-api). Mỗi bảng gồm: mục đích sử dụng, và bảng chi tiết các cột (tên cột, kiểu dữ liệu, ràng buộc khóa, mô tả mục đích).

### Chú thích ràng buộc

| Ký hiệu | Ý nghĩa                      |
| :------ | :--------------------------- |
| `PK`    | Khóa chính                   |
| `FK→`   | Khóa ngoại (tham chiếu bảng) |
| `AI`    | Tự tăng (AUTO_INCREMENT)     |
| `NN`    | Không được rỗng (NOT NULL)   |
| `UQ`    | Duy nhất (UNIQUE)            |

### Phân nhóm bảng

- **Nhóm I** — Nhiệm vụ, Nghị quyết/Văn bản, Báo cáo (nghiệp vụ lõi).

> **Lưu ý:** CSDL dùng chung cho nhiều phân hệ. Nhóm `qlnv_*` là các bảng nghiệp vụ chính do bmm-api quản lý; các bảng còn lại thuộc nền tảng tích hợp/tổ chức (sinh bởi Java/Spring) dùng chung dữ liệu.

---

## NHÓM I — NHIỆM VỤ, NGHỊ QUYẾT/VĂN BẢN, BÁO CÁO

### Danh mục bảng

|   # | Bảng                                                    |
| --: | :------------------------------------------------------ |
|   1 | [`qlnv_task`](#qlnv_task)                               |
|   2 | [`qlnv_task_group`](#qlnv_task_group)                   |
|   3 | [`qlnv_task_user`](#qlnv_task_user)                     |
|   4 | [`qlnv_task_tag`](#qlnv_task_tag)                       |
|   5 | [`qlnv_task_source`](#qlnv_task_source)                 |
|   6 | [`qlnv_task_resolution`](#qlnv_task_resolution)         |
|   7 | [`qlnv_task_pin`](#qlnv_task_pin)                       |
|   8 | [`qlnv_task_period_configs`](#qlnv_task_period_configs) |
|   9 | [`qlnv_resolution`](#qlnv_resolution)                   |
|  10 | [`qlnv_report`](#qlnv_report)                           |
|  11 | [`qlnv_combination`](#qlnv_combination)                 |
|  12 | [`qlnv_file`](#qlnv_file)                               |

---

### `qlnv_task`

**Mục đích:** Bảng trung tâm lưu toàn bộ nhiệm vụ (công việc được giao) của hệ thống. Mỗi bản ghi là một nhiệm vụ với thông tin người giao, đơn vị/người thực hiện, nguồn phát sinh, tiến độ và trạng thái xử lý.

|   # | Cột                    | Kiểu            | Ràng buộc  | Mô tả / mục đích                                                                                                           |
| --: | :--------------------- | :-------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------- |
|   1 | `TaskId`               | `int(11)`       | `PK`, `AI` | Khóa chính, mã nhiệm vụ                                                                                                    |
|   2 | `CreateUser`           | `int(11)`       |            | Id người tạo nhiệm vụ; giá trị 0 = do hệ thống tạo                                                                         |
|   3 | `ParentId`             | `int(11)`       |            | Id nhiệm vụ cha (nhiệm vụ con giao xuống); dùng cho cây phân cấp nhiệm vụ                                                  |
|   4 | `Type`                 | `tinyint(4)`    | `NN`       | Loại nhiệm vụ: 0 = Cá nhân, 1 = Đơn vị                                                                                     |
|   5 | `Status`               | `tinyint(4)`    | `NN`       | Trạng thái nhiệm vụ: 0 = Mới tạo, 1 = Chờ báo cáo tiến độ, 2 = Xin gia hạn, 3 = Hoàn thành, 4 = Kết thúc, 5 = Thu hồi      |
|   6 | `State`                | `tinyint(4)`    | `NN`       | Tình trạng tiếp nhận: 0 = Mới tạo (có thể thu hồi), 1 = Đã nhận, 2 = Đã gửi báo cáo tiến độ, 3 = Đã gửi báo cáo hoàn thành |
|   7 | `Priority`             | `tinyint(4)`    | `NN`       | Mức độ ưu tiên của nhiệm vụ                                                                                                |
|   8 | `Progress`             | `int(11)`       | `NN`       | Tiến độ hoàn thành (%)                                                                                                     |
|   9 | `Title`                | `varchar(6000)` | `NN`       | Tiêu đề nhiệm vụ (có FULLTEXT index để tìm kiếm)                                                                           |
|  10 | `AssignOrganization`   | `varchar(255)`  |            | Cơ quan giao nhiệm vụ (phase 2)                                                                                            |
|  11 | `AssignDepartment`     | `varchar(50)`   | `NN`       | Đơn vị giao nhiệm vụ (mã Part/phòng ban)                                                                                   |
|  12 | `AssignUser`           | `int(11)`       |            | Người giao nhiệm vụ (UserId)                                                                                               |
|  13 | `TargetOrganization`   | `varchar(255)`  |            | Cơ quan thực hiện (phase 2)                                                                                                |
|  14 | `TargetDepartment`     | `varchar(50)`   | `NN`       | Đơn vị thực hiện (mã Part/phòng ban)                                                                                       |
|  15 | `TargetUser`           | `int(11)`       |            | Người thực hiện (UserId)                                                                                                   |
|  16 | `SourceId`             | `tinyint(4)`    | `NN`       | Nguồn phát sinh nhiệm vụ: 0 = từ văn bản, 1 = trực tiếp, 2 = khác                                                          |
|  17 | `DocumentId`           | `varchar(40)`   |            | Mã DocumentId trên hệ thống eGov (văn bản gốc)                                                                             |
|  18 | `Compendium`           | `varchar(255)`  |            | Trích yếu văn bản                                                                                                          |
|  19 | `DocCode`              | `varchar(50)`   |            | Số ký hiệu văn bản                                                                                                         |
|  20 | `Content`              | `longtext`      |            | Nội dung chi tiết nhiệm vụ                                                                                                 |
|  21 | `ExpireDate`           | `datetime(6)`   |            | Hạn xử lý nhiệm vụ                                                                                                         |
|  22 | `CompletedDate`        | `datetime(0)`   |            | Ngày kết thúc nhiệm vụ                                                                                                     |
|  23 | `ApprovedDate`         | `datetime(0)`   |            | Ngày duyệt báo cáo hoàn thành                                                                                              |
|  24 | `CreatedDate`          | `datetime(0)`   | `NN`       | Ngày tạo bản ghi (mặc định thời điểm hiện tại)                                                                             |
|  25 | `UpdatedDate`          | `datetime(0)`   | `NN`       | Ngày cập nhật gần nhất (tự động cập nhật)                                                                                  |
|  26 | `DeletedDate`          | `datetime(0)`   |            | Ngày xóa mềm; khác NULL nghĩa là đã bị xóa                                                                                 |
|  27 | `ExternalId`           | `int(11)`       |            | TaskId đối chiếu từ cơ quan khác (đồng bộ liên thông)                                                                      |
|  28 | `Code`                 | `varchar(255)`  |            | Mã nhiệm vụ (mã hiển thị/tra cứu)                                                                                          |
|  29 | `CreateUserDepartment` | `varchar(255)`  |            | Đơn vị của người tạo nhiệm vụ                                                                                              |
|  30 | `ChargeUser`           | `varchar(255)`  |            | Người phụ trách/chịu trách nhiệm                                                                                           |
|  31 | `ResolutionId`         | `int(11)`       |            | Id nghị quyết/văn bản gắn với nhiệm vụ (→ qlnv_resolution)                                                                 |
|  32 | `OtherSourceDes`       | `varchar(255)`  |            | Mô tả nguồn khác (khi SourceId = 2)                                                                                        |
|  33 | `IsReturned`           | `tinyint(4)`    |            | Cờ đánh dấu nhiệm vụ bị trả lại                                                                                            |
|  34 | `TaskSourceId`         | `int(11)`       |            | Id nguồn nhiệm vụ (→ qlnv_task_source)                                                                                     |
|  35 | `NameGroup`            | `varchar(255)`  |            | Tên nhóm nhiệm vụ (hiển thị)                                                                                               |
|  36 | `FollowUser`           | `varchar(255)`  |            | Danh sách người theo dõi nhiệm vụ                                                                                          |
|  37 | `Synced`               | `varchar(255)`  |            | Trạng thái đồng bộ dữ liệu                                                                                                 |
|  38 | `DataSync`             | `longtext`      |            | Dữ liệu đồng bộ (JSON) từ/đến hệ thống ngoài                                                                               |
|  39 | `level`                | `int(11)`       |            | Cấp/bậc của nhiệm vụ trong cây phân cấp                                                                                    |
|  40 | `Order`                | `int(11)`       |            | Thứ tự sắp xếp hiển thị                                                                                                    |
|  41 | `IsRecurring`          | `tinyint(1)`    | `NN`       | Loại lặp lại: 0 = nhiệm vụ thường, 1 = nhiệm vụ định kỳ                                                                    |
|  42 | `StartedDate`          | `datetime(0)`   |            | Ngày bắt đầu thực hiện nhiệm vụ                                                                                            |
|  43 | `Sector`               | `varchar(256)`  |            | Lĩnh vực của nhiệm vụ                                                                                                      |
|  44 | `ResponsibleUnit`      | `varchar(256)`  |            | Đơn vị chịu trách nhiệm chính                                                                                              |
|  45 | `DocumentCompendium`   | `varchar(255)`  |            | Trích yếu văn bản nguồn                                                                                                    |
|  46 | `DocumentCode`         | `varchar(255)`  |            | Số ký hiệu văn bản nguồn                                                                                                   |
|  47 | `DocumentOrganization` | `varchar(255)`  |            | Cơ quan ban hành văn bản nguồn                                                                                             |

### `qlnv_task_group`

**Mục đích:** Bảng liên kết N-N gán nhiệm vụ vào nhóm nhiệm vụ (chương trình / nhiệm vụ năm / nhóm thường). Một nhiệm vụ có thể thuộc nhiều nhóm.

|   # | Cột       | Kiểu      | Ràng buộc             | Mô tả / mục đích              |
| --: | :-------- | :-------- | :-------------------- | :---------------------------- |
|   1 | `Id`      | `int(11)` | `PK`, `AI`            | Khóa chính                    |
|   2 | `TaskId`  | `int(11)` | `NN`, `FK→qlnv_task`  | Mã nhiệm vụ được gán vào nhóm |
|   3 | `GroupId` | `int(11)` | `NN`, `FK→qlnv_group` | Mã nhóm nhiệm vụ              |

### `qlnv_task_user`

**Mục đích:** Bảng liên kết nhiệm vụ với người dùng, lưu vai trò và trạng thái của từng người tham gia nhiệm vụ (người giao, chủ trì, phối hợp), trạng thái đọc, theo dõi, chuyển tiếp và duyệt.

|   # | Cột                     | Kiểu           | Ràng buộc  | Mô tả / mục đích                                               |
| --: | :---------------------- | :------------- | :--------- | :------------------------------------------------------------- |
|   1 | `Id`                    | `bigint(20)`   | `PK`, `AI` | Khóa chính                                                     |
|   2 | `TaskId`                | `int(11)`      | `NN`       | Mã nhiệm vụ                                                    |
|   3 | `UserId`                | `int(11)`      | `NN`       | Mã người dùng tham gia nhiệm vụ (eGovUserId)                   |
|   4 | `Role`                  | `tinyint(4)`   | `NN`       | Vai trò: 0 = Người giao, 1 = Người chủ trì, 2 = Người phối hợp |
|   5 | `HasRead`               | `tinyint(4)`   | `NN`       | Trạng thái đọc: 0 = Chưa xem, 1 = Đã xem                       |
|   6 | `CreatedDate`           | `datetime(6)`  | `NN`       | Ngày tạo bản ghi                                               |
|   7 | `UpdatedDate`           | `datetime(0)`  | `NN`       | Ngày cập nhật gần nhất                                         |
|   8 | `Permission`            | `int(11)`      | `NN`       | Quyền của người dùng trên nhiệm vụ                             |
|   9 | `IsFollow`              | `int(11)`      | `NN`       | Cờ đang theo dõi nhiệm vụ (1 = theo dõi)                       |
|  10 | `IsPined`               | `tinyint(4)`   |            | Cờ đánh dấu ghim nhiệm vụ                                      |
|  11 | `TransferredFromUserId` | `int(11)`      |            | Người đã chuyển tiếp nhiệm vụ cho người này                    |
|  12 | `TransferredDate`       | `datetime(6)`  |            | Ngày chuyển tiếp nhiệm vụ                                      |
|  13 | `IsApproved`            | `tinyint(4)`   |            | Trạng thái duyệt: 0 = Chưa duyệt, 1 = Đã duyệt                 |
|  14 | `ApprovedDate`          | `datetime(6)`  |            | Ngày duyệt                                                     |
|  15 | `ExpiredDate`           | `datetime(0)`  |            | Hạn xử lý riêng của người dùng này                             |
|  16 | `DepartmentId`          | `varchar(255)` |            | Đơn vị của người dùng khi tham gia nhiệm vụ                    |

### `qlnv_task_tag`

**Mục đích:** Bảng liên kết N-N gán nhãn (tag) cho nhiệm vụ, phục vụ phân loại và lọc nhiệm vụ theo nhãn.

|   # | Cột      | Kiểu      | Ràng buộc            | Mô tả / mục đích          |
| --: | :------- | :-------- | :------------------- | :------------------------ |
|   1 | `Id`     | `int(11)` | `PK`, `AI`           | Khóa chính                |
|   2 | `TaskId` | `int(11)` | `NN`, `FK→qlnv_task` | Mã nhiệm vụ được gán nhãn |
|   3 | `TagId`  | `int(11)` | `NN`, `FK→qlnv_tag`  | Mã nhãn (tag)             |

### `qlnv_task_source`

**Mục đích:** Lưu thông tin nguồn văn bản phát sinh nhiệm vụ (văn bản đến/đi trên eGov) gắn với nhiệm vụ, dùng để tra ngược nguồn gốc nhiệm vụ.

|   # | Cột              | Kiểu           | Ràng buộc  | Mô tả / mục đích                                            |
| --: | :--------------- | :------------- | :--------- | :---------------------------------------------------------- |
|   1 | `TaskSourceId`   | `int(11)`      | `PK`, `AI` | Khóa chính, mã nguồn nhiệm vụ                               |
|   2 | `TaskId`         | `int(11)`      | `NN`       | Mã nhiệm vụ tương ứng                                       |
|   3 | `DocumentID`     | `varchar(255)` |            | Mã văn bản trên hệ thống eGov                               |
|   4 | `DocumentCopyID` | `int(11)`      |            | Mã bản sao văn bản (document copy)                          |
|   5 | `Compendium`     | `varchar(255)` |            | Trích yếu văn bản                                           |
|   6 | `DocCode`        | `varchar(255)` |            | Số ký hiệu văn bản                                          |
|   7 | `Organization`   | `varchar(255)` |            | Cơ quan ban hành văn bản                                    |
|   8 | `Type`           | `int(11)`      | `NN`       | Loại nguồn văn bản                                          |
|   9 | `ReportId`       | `int(11)`      |            | Mã báo cáo liên quan (nếu nguồn từ báo cáo) (→ qlnv_report) |

### `qlnv_task_resolution`

**Mục đích:** Bảng liên kết N-N giữa nhiệm vụ và nghị quyết/văn bản, cho phép một nhiệm vụ gắn với nhiều nghị quyết và ngược lại (cặp TaskId+ResolutionId là duy nhất).

|   # | Cột                | Kiểu      | Ràng buộc                  | Mô tả / mục đích                          |
| --: | :----------------- | :-------- | :------------------------- | :---------------------------------------- |
|   1 | `TaskResolutionId` | `int(11)` | `PK`, `AI`                 | Khóa chính                                |
|   2 | `TaskId`           | `int(11)` | `UQ (TaskId,ResolutionId)` | Mã nhiệm vụ (→ qlnv_task)                 |
|   3 | `ResolutionId`     | `int(11)` | `UQ (TaskId,ResolutionId)` | Mã nghị quyết/văn bản (→ qlnv_resolution) |

### `qlnv_task_pin`

**Mục đích:** Lưu danh sách nhiệm vụ được người dùng ghim (pin) để truy cập nhanh; mỗi bản ghi là một cặp người dùng - nhiệm vụ được ghim.

|   # | Cột      | Kiểu      | Ràng buộc            | Mô tả / mục đích            |
| --: | :------- | :-------- | :------------------- | :-------------------------- |
|   1 | `Id`     | `int(11)` | `PK`, `AI`           | Khóa chính                  |
|   2 | `UserId` | `int(11)` | `NN`                 | Mã người dùng ghim nhiệm vụ |
|   3 | `TaskId` | `int(11)` | `NN`, `FK→qlnv_task` | Mã nhiệm vụ được ghim       |

### `qlnv_task_period_configs`

**Mục đích:** Cấu hình chu kỳ lặp cho nhiệm vụ định kỳ (tuần/tháng/quý/năm) và khoảng thời gian hiệu lực; dùng để hệ thống tự động sinh kỳ báo cáo/nhiệm vụ theo lịch.

|   # | Cột              | Kiểu          | Ràng buộc            | Mô tả / mục đích                                     |
| --: | :--------------- | :------------ | :------------------- | :--------------------------------------------------- |
|   1 | `Id`             | `int(11)`     | `PK`, `AI`           | Khóa chính                                           |
|   2 | `TaskId`         | `int(11)`     | `NN`, `FK→qlnv_task` | Mã nhiệm vụ định kỳ (xóa cascade theo nhiệm vụ)      |
|   3 | `PeriodType`     | `tinyint(4)`  | `NN`                 | Loại chu kỳ: 1 = tuần, 2 = tháng, 3 = quý, 4 = năm   |
|   4 | `Offset`         | `int(11)`     |                      | Độ lệch kỳ: 0 = trong kỳ, 1 = kỳ tiếp theo           |
|   5 | `DayOfWeek`      | `int(11)`     |                      | Thứ trong tuần: 2-8 tương ứng Thứ 2 đến Chủ nhật     |
|   6 | `DayOfMonth`     | `int(11)`     |                      | Ngày trong tháng: 1-31, hoặc -1/99 = ngày cuối tháng |
|   7 | `MonthOfQuarter` | `int(11)`     |                      | Tháng trong quý: 1-3                                 |
|   8 | `MonthOfYear`    | `int(11)`     |                      | Tháng trong năm: 1-12                                |
|   9 | `ValidFrom`      | `date`        | `NN`                 | Ngày bắt đầu hiệu lực của cấu hình                   |
|  10 | `ValidTo`        | `date`        |                      | Ngày kết thúc hiệu lực (NULL = không giới hạn)       |
|  11 | `CreatedDate`    | `datetime(0)` | `NN`                 | Ngày tạo bản ghi                                     |
|  12 | `UpdatedDate`    | `datetime(0)` | `NN`                 | Ngày cập nhật gần nhất                               |

### `qlnv_resolution`

**Mục đích:** Lưu nghị quyết/văn bản chỉ đạo (nghị quyết, kế hoạch, hướng dẫn...) làm căn cứ giao nhiệm vụ. Chứa thông tin số ký hiệu, trích yếu, cơ quan ban hành, người ký, danh mục và lĩnh vực.

|   # | Cột                      | Kiểu            | Ràng buộc                        | Mô tả / mục đích                                |
| --: | :----------------------- | :-------------- | :------------------------------- | :---------------------------------------------- |
|   1 | `ResolutionId`           | `int(11)`       | `PK`, `AI`                       | Khóa chính, mã nghị quyết/văn bản               |
|   2 | `ResolutionGroupId`      | `int(11)`       | `NN`, `FK→qlnv_resolution_group` | Id danh mục nghị quyết                          |
|   3 | `SectorId`               | `int(11)`       | `NN`, `FK→qlnv_sector`           | Id lĩnh vực                                     |
|   4 | `AssignUser`             | `int(11)`       | `NN`                             | Lãnh đạo ký văn bản (UserId)                    |
|   5 | `Compendium`             | `varchar(1000)` | `NN`                             | Trích yếu văn bản                               |
|   6 | `DocCode`                | `varchar(255)`  | `NN`                             | Số ký hiệu văn bản                              |
|   7 | `AssignOrganization`     | `varchar(255)`  | `NN`                             | Cơ quan ban hành                                |
|   8 | `PositionId`             | `int(11)`       | `NN`                             | Id chức vụ người ký                             |
|   9 | `Type`                   | `int(11)`       | `NN`                             | Kiểu/loại văn bản                               |
|  10 | `StartDate`              | `datetime(0)`   | `NN`                             | Ngày bắt đầu (ngày ban hành)                    |
|  11 | `ApprovedDate`           | `datetime(0)`   |                                  | Ngày hiệu lực                                   |
|  12 | `Status`                 | `int(11)`       | `NN`                             | Trạng thái nghị quyết                           |
|  13 | `CreatedDate`            | `datetime(0)`   | `NN`                             | Ngày tạo bản ghi                                |
|  14 | `UpdatedDate`            | `datetime(0)`   | `NN`                             | Ngày cập nhật gần nhất                          |
|  15 | `DeletedDate`            | `datetime(0)`   |                                  | Ngày xóa mềm                                    |
|  16 | `CreateUser`             | `int(11)`       | `NN`                             | Id người tạo bản ghi                            |
|  17 | `AssignOrganizationName` | `varchar(500)`  |                                  | Tên cơ quan ban hành (lưu sẵn để hiển thị)      |
|  18 | `PositionName`           | `varchar(500)`  |                                  | Tên chức vụ người ký (lưu sẵn để hiển thị)      |
|  19 | `AssignUserName`         | `varchar(500)`  |                                  | Tên lãnh đạo ký (lưu sẵn để hiển thị)           |
|  20 | `PeriodicReport`         | `tinyint(4)`    |                                  | Cờ báo cáo định kỳ: 1 = là báo cáo định kỳ      |
|  21 | `TaskIdParent`           | `int(11)`       |                                  | Id nhiệm vụ cha giao xuống văn bản (mặc định 0) |
|  22 | `DepartmentId`           | `varchar(50)`   |                                  | Đơn vị gắn với nghị quyết                       |

### `qlnv_report`

**Mục đích:** Lưu các báo cáo liên quan đến nhiệm vụ: yêu cầu báo cáo, báo cáo tiến độ, báo cáo hoàn thành, xin gia hạn. Chứa nội dung, trạng thái duyệt và thông tin kỳ báo cáo.

|   # | Cột                 | Kiểu           | Ràng buộc            | Mô tả / mục đích                                                                                        |
| --: | :------------------ | :------------- | :------------------- | :------------------------------------------------------------------------------------------------------ |
|   1 | `ReportId`          | `int(11)`      | `PK`, `AI`           | Khóa chính, mã báo cáo                                                                                  |
|   2 | `OrganizationId`    | `varchar(255)` |                      | Mã tổ chức/cơ quan của báo cáo                                                                          |
|   3 | `DepartmentPath`    | `varchar(255)` |                      | Đường dẫn phòng ban (idext)                                                                             |
|   4 | `TaskId`            | `int(11)`      | `NN`, `FK→qlnv_task` | Mã nhiệm vụ được báo cáo                                                                                |
|   5 | `CreateUser`        | `int(11)`      | `NN`                 | Id người tạo báo cáo (mặc định 0)                                                                       |
|   6 | `UserId`            | `int(11)`      | `NN`                 | Id người báo cáo/liên quan                                                                              |
|   7 | `ParentId`          | `int(11)`      |                      | Id báo cáo cha                                                                                          |
|   8 | `CombinationId`     | `int(11)`      |                      | Id phối hợp xử lý (→ qlnv_combination)                                                                  |
|   9 | `ApprovedUser`      | `int(11)`      |                      | Id người duyệt báo cáo                                                                                  |
|  10 | `ApprovedAt`        | `datetime(0)`  |                      | Ngày duyệt báo cáo                                                                                      |
|  11 | `Type`              | `tinyint(4)`   | `NN`                 | Loại báo cáo: 0 = Yêu cầu báo cáo tiến độ, 1 = Báo cáo tiến độ, 2 = Báo cáo hoàn thành, 3 = Xin gia hạn |
|  12 | `Status`            | `tinyint(4)`   | `NN`                 | Trạng thái duyệt: 0 = Chờ duyệt, 1 = Đã duyệt, 2 = Từ chối                                              |
|  13 | `State`             | `tinyint(4)`   | `NN`                 | Tình trạng: 0 = Mới tạo (có thể thu hồi), 1 = Đã nhận được thông tin                                    |
|  14 | `Content`           | `text`         |                      | Ý kiến xử lý / nội dung báo cáo                                                                         |
|  15 | `NewExpiredDate`    | `datetime(0)`  |                      | Ngày xin gia hạn (khi Type = 3)                                                                         |
|  16 | `CompletedDate`     | `datetime(0)`  |                      | Ngày hoàn thành                                                                                         |
|  17 | `CreatedDate`       | `datetime(0)`  | `NN`                 | Ngày tạo bản ghi                                                                                        |
|  18 | `UpdatedDate`       | `datetime(0)`  | `NN`                 | Ngày cập nhật gần nhất                                                                                  |
|  19 | `DeletedDate`       | `datetime(0)`  |                      | Ngày xóa mềm                                                                                            |
|  20 | `ExternalId`        | `int(11)`      |                      | ReportId đối chiếu từ cơ quan khác (đồng bộ liên thông)                                                 |
|  21 | `Difficulty`        | `text`         |                      | Khó khăn, vướng mắc                                                                                     |
|  22 | `Suggestion`        | `text`         |                      | Đề xuất, kiến nghị                                                                                      |
|  23 | `CompletedProduct`  | `text`         |                      | Sản phẩm hoàn thành                                                                                     |
|  24 | `ReportType`        | `tinyint(4)`   |                      | Phân loại báo cáo                                                                                       |
|  25 | `ReportYear`        | `int(11)`      |                      | Năm báo cáo                                                                                             |
|  26 | `ReportValue`       | `int(11)`      |                      | Giá trị/chỉ số của báo cáo                                                                              |
|  27 | `PeriodStartDate`   | `date`         |                      | Ngày bắt đầu kỳ báo cáo                                                                                 |
|  28 | `PeriodEndDate`     | `date`         |                      | Ngày kết thúc kỳ báo cáo                                                                                |
|  29 | `ReportDeadline`    | `datetime(0)`  |                      | Hạn nộp báo cáo                                                                                         |
|  30 | `RequestReportType` | `tinyint(4)`   |                      | Loại yêu cầu báo cáo: 1 = Tiến độ, 2 = Báo cáo công việc, 3 = Hoàn thành                                |
|  31 | `Progress`          | `int(11)`      |                      | Tiến độ báo cáo (%)                                                                                     |

### `qlnv_combination`

**Mục đích:** Lưu danh sách đơn vị/người phối hợp thực hiện một nhiệm vụ (ngoài người chủ trì); theo dõi trạng thái báo cáo của từng đối tượng phối hợp.

|   # | Cột                | Kiểu          | Ràng buộc            | Mô tả / mục đích                        |
| --: | :----------------- | :------------ | :------------------- | :-------------------------------------- |
|   1 | `CombinationId`    | `int(11)`     | `PK`, `AI`           | Khóa chính                              |
|   2 | `TaskId`           | `int(11)`     | `NN`, `FK→qlnv_task` | Mã nhiệm vụ được phối hợp               |
|   3 | `Status`           | `tinyint(1)`  | `NN`                 | Trạng thái: 0 = Mới tạo, 1 = Đã báo cáo |
|   4 | `TargetDepartment` | `varchar(50)` | `NN`                 | Đơn vị phối hợp thực hiện (mã Part)     |
|   5 | `TargetUser`       | `int(11)`     |                      | Người phối hợp thực hiện (UserId)       |
|   6 | `Content`          | `longtext`    |                      | Nội dung (chưa dùng)                    |
|   7 | `ExpireDate`       | `datetime(6)` |                      | Hạn xử lý                               |
|   8 | `CreatedDate`      | `datetime(0)` | `NN`                 | Ngày tạo bản ghi                        |
|   9 | `UpdatedDate`      | `datetime(0)` | `NN`                 | Ngày cập nhật gần nhất                  |
|  10 | `DeletedDate`      | `datetime(0)` |                      | Ngày xóa mềm                            |

### `qlnv_file`

**Mục đích:** Lưu thông tin file đính kèm của nhiệm vụ, báo cáo hoặc nghị quyết (tên file, đường dẫn lưu trữ, kích thước, loại). Một file gắn với nhiệm vụ và/hoặc báo cáo/nghị quyết.

|   # | Cột             | Kiểu           | Ràng buộc      | Mô tả / mục đích                                                                |
| --: | :-------------- | :------------- | :------------- | :------------------------------------------------------------------------------ |
|   1 | `FileId`        | `int(11)`      | `PK`, `AI`     | Khóa chính                                                                      |
|   2 | `TaskId`        | `int(11)`      | `FK→qlnv_task` | Mã nhiệm vụ đính kèm file                                                       |
|   3 | `UserId`        | `int(11)`      | `NN`           | Id người tải lên file                                                           |
|   4 | `ReportId`      | `int(11)`      |                | Mã báo cáo (nếu file được gửi trong báo cáo tiến độ) (→ qlnv_report)            |
|   5 | `FileName`      | `varchar(255)` | `NN`           | Tên file gốc                                                                    |
|   6 | `FileLocalName` | `varchar(255)` | `NN`           | Tên GUID của file khi lưu trên hệ thống                                         |
|   7 | `FilePath`      | `varchar(255)` | `NN`           | Đường dẫn tương đối tới file                                                    |
|   8 | `Extension`     | `varchar(10)`  | `NN`           | Phần mở rộng của file (đuôi file)                                               |
|   9 | `Size`          | `int(11)`      | `NN`           | Kích thước file (byte)                                                          |
|  10 | `CreatedDate`   | `datetime(0)`  | `NN`           | Ngày tạo bản ghi                                                                |
|  11 | `UpdatedDate`   | `datetime(0)`  | `NN`           | Ngày cập nhật gần nhất                                                          |
|  12 | `DeletedDate`   | `datetime(0)`  |                | Ngày xóa mềm                                                                    |
|  13 | `ResolutionId`  | `int(11)`      |                | Mã nghị quyết (nếu file thuộc nghị quyết) (→ qlnv_resolution)                   |
|  14 | `Type`          | `int(11)`      |                | Loại file: 2 = Văn bản chỉ đạo thực hiện, 3 = KH/HD chỉ đạo, 4 = CTHĐ thực hiện |
|  15 | `IsSync`        | `tinyint(4)`   |                | Cờ đã đồng bộ (mặc định 0)                                                      |
|  16 | `AIStatus`      | `tinyint(4)`   |                | Trạng thái xử lý AI của file                                                    |

department

# id code departmentextid departmentpath DeptFullName DeptFullNameParent DicstrinstCode domain IsDelete level name ObjectGuid parent_id ProvinceCode shortname status unit_level UserManager createBy create_time modify_time updateBy parent SyncedAt sort_order manual_parent

490 490 THÀNH PHỐ HÀ NỘI 0 1 THÀNH PHỐ HÀ NỘI THÀNH PHỐ HÀ NỘI 1 2026-08-02 23:31:23 896 2026-08-02 23:31:23 8 0
