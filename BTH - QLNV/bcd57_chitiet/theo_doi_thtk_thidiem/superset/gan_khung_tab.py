"""Thêm tab "3. Tình hình triển khai thí điểm" (dashboard bcd57-thidiem-trienkhai) vào khung tab BCĐ 57 (chart 763).

  python3 gan_khung_tab.py          -> in thay đổi, không ghi
  python3 gan_khung_tab.py apply    -> sao lưu params cũ vào backups/ rồi ghi lên Superset
Gỡ: khôi phục params từ file backup (bỏ slice_id/dashboards) rồi PUT /api/v1/chart/763.
"""
import json, os, sys, datetime
import ss

REPO = ss.REPO
URL = ss.BASE + "/superset/dashboard/bcd57-thidiem-trienkhai/"
NEO = """      noExport: true, // ẩn nút "Xuất tổng hợp Excel" khi đang mở tab này
    },
  ];"""
MOI = """      noExport: true, // ẩn nút "Xuất tổng hợp Excel" khi đang mở tab này
    },
    {
      id: "td",
      no: 3,
      label: "Tình hình triển khai thí điểm",
      url: "%s",
      passParams: false, // 17 đơn vị thí điểm, bộ lọc Khối/Đơn vị nằm trong dashboard
      hideIfParam: "id_xa_phuong",
      noExport: true,
    },
  ];""" % URL

charts = ss.get("/api/v1/dashboard/bcd57-khung-tab/charts")["result"]
c = next(x for x in charts if x["form_data"].get("viz_type") == "bkav-chart-advance")
fd = c["form_data"]
js = fd["js_echart_building"]
if URL in js:
    raise SystemExit(f"Chart {c['id']} đã có tab {URL}")
assert js.count(NEO) == 1, "Không tìm thấy đúng 1 điểm cuối TAB_CONFIG"
js2 = js.replace(NEO, MOI).replace("Header + 2 tab (theo v39): Nhiệm vụ 57 (gộp TP + Xã/phường) / Chuyên đề lớn (kèm số),",
                                   "Header + 3 tab: Nhiệm vụ 57 (gộp TP + Xã/phường) / Chuyên đề lớn (kèm số) / Tình hình triển khai thí điểm,")
print(f"Chart {c['id']} ({c['slice_name']}): thêm tab 3 -> {URL}")
if sys.argv[1:] == ["apply"]:
    bk = os.path.join(REPO, "backups", f"backup_superset_chart763_khungtab_{datetime.date.today():%Y%m%d}_before_tab_thidiem.json")
    json.dump(fd, open(bk, "w"), ensure_ascii=False, indent=1)
    print("Sao lưu:", bk)
    fd["js_echart_building"] = js2
    for k in ("slice_id", "dashboards"):
        fd.pop(k, None)
    ss.put(f"/api/v1/chart/{c['id']}", {"slice_name": "BCĐ 57 – Khung tab (header + 3 tab)", "params": json.dumps(fd, ensure_ascii=False)})
    print("Đã cập nhật.")
