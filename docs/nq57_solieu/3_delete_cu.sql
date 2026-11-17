/* NiFi ReplaceText (Always Replace, Entire text) -> PutSQL (HN-Datamart-NEW), chạy SAU khi upsert thành công.
   Xóa dòng không còn ở nguồn. Chỉ tới được bước này khi nguồn trả >0 dòng (RouteOnAttribute chặn trước),
   nên nguồn rỗng/lỗi không làm bảng đích trống. */

-- nhánh số liệu
DELETE FROM `datamart_hanoi`.`nq57_solieu`  WHERE sync_date < '${sync_ts}';

-- nhánh chỉ tiêu
DELETE FROM `datamart_hanoi`.`nq57_chitieu` WHERE sync_date < '${sync_ts}';
