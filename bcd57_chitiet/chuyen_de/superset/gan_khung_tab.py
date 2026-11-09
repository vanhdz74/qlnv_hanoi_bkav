"""Thay dashboard của tab "Chuyên đề lớn" trong khung tab BCĐ 57 (dashboard bcd57-khung-tab, chart 763)
bằng dashboard "NQ57 – Chuyên đề chi tiết (theo báo cáo tháng)" (slug nq57-chuyen-de-chi-tiet).

  python3 gan_khung_tab.py          -> kiểm tra, in ra thay đổi (không ghi)
  python3 gan_khung_tab.py apply    -> ghi lên Superset
"""
import json, sys
import ss

KHUNG_DASH = "bcd57-khung-tab"
CU = "https://superbi-theodoinhiemvu.hanoi.gov.vn/superset/dashboard/bcd57-chuyen-de-lon/"
MOI = "https://superbi-theodoinhiemvu.hanoi.gov.vn/superset/dashboard/nq57-chuyen-de-chi-tiet/"

# Lưu ý: GET /api/v1/dashboard/<id|slug> và /api/v1/chart/<id> trên server này trả 404 cho admin
# dù đối tượng vẫn tồn tại (PUT vẫn được) -> không dùng GET để kiểm tra dashboard đích.

charts = ss.get(f"/api/v1/dashboard/{KHUNG_DASH}/charts")["result"]
c = next(x for x in charts if x["form_data"].get("viz_type") == "bkav-chart-advance")
fd = c["form_data"]
js = fd["js_echart_building"]
if MOI in js:
    raise SystemExit(f"Chart {c['id']} đã trỏ tới {MOI}")
assert js.count(CU) == 1, "Không tìm thấy đúng 1 URL tab Chuyên đề lớn cũ"
fd["js_echart_building"] = js.replace(CU, MOI)
print(f"Chart {c['id']} ({c['slice_name']}): {CU} -> {MOI}")

if sys.argv[1:] == ["apply"]:
    for k in ("slice_id", "dashboards"):
        fd.pop(k, None)
    ss.put(f"/api/v1/chart/{c['id']}", {"params": json.dumps(fd, ensure_ascii=False)})
    print("Đã cập nhật.")
