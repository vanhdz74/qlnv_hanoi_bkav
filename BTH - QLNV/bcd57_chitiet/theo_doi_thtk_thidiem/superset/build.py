"""Dashboard Superset "BCĐ 57 – Tình hình triển khai thí điểm" (tab 3 của khung tab bcd57-khung-tab).

  node gen_du_lieu_mau.js         -> du_lieu_mau.json (dữ liệu mẫu, sinh y hệt dashboard_tinhhinh_trienkhai_v03.html)
  python3 build.py                -> build/dataset.sql, build/chart.js, build/preview.html (xem thử cục bộ)
  python3 build.py deploy         -> tạo/cập nhật dataset ảo, chart, dashboard (id lưu ở build/state.json)
  python3 build.py deploy         -> dataset đọc bảng datamart_hanoi.bcd57_thidiem_trienkhai_thang (NiFi, ../nifi/deploy.py)
  python3 build.py deploy eform   -> dataset = SQL ảo dataset_eform_thang.sql (tính trực tiếp, không qua bảng)
  python3 build.py deploy mau     -> dataset dùng lại DỮ LIỆU MẪU

Dữ liệu hiện là MẪU: dataset ảo = SELECT ... UNION ALL các dòng trong du_lieu_mau.json, không tạo bảng trong DB.
Khi có số thật: đổi SQL của dataset (giữ đúng tên cột trong COLS), chart không phải sửa.
"""
import json, os, sys, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")
os.makedirs(BUILD, exist_ok=True)
# PREVIEW_JSON=build/du_lieu_eform_thang.json python3 build.py -> xem trước với dữ liệu khác (không ảnh hưởng deploy)
DATA = json.load(open(os.path.join(HERE, "du_lieu_mau.json")))
PREVIEW_DATA = json.load(open(os.environ["PREVIEW_JSON"])) if os.environ.get("PREVIEW_JSON") else DATA
# giao diện: mặc định v12 (chart_v12.tpl.js); "python3 build.py deploy v03" = giao diện cũ (chart.tpl.js)
V03 = "v03" in sys.argv
TPL = open(os.path.join(HERE, "chart.tpl.js" if V03 else "chart_v12.tpl.js")).read()

DB_ID, SCHEMA = 8, "datamart_hanoi"
DATASET = "bcd57_thidiem_trienkhai_mau"
CHART_NAME = "BCĐ 57 – Tình hình triển khai thí điểm"
DASH_TITLE, DASH_SLUG = "BCĐ 57 – Tình hình triển khai thí điểm", "bcd57-thidiem-trienkhai"
CHART_H = 132          # đơn vị lưới Superset (8px) ~ 1056px
COLS = ["ma_don_vi", "ten_don_vi", "tt_don_vi", "khoi", "ma_ky", "loai_ky", "nhan_ky", "ten_ky", "stt_ky", "han_nop", "den_han",
        "ts_nhap_dau", "ts_gui_duyet", "ts_phat_hanh", "ts_tiep_nhan", "trang_thai", "o_kiem_dem", "so_bieu", "so_bieu_hoan_tat",
        "so_lan_tra_lai", "lech_han_phut", "moc_chup"]
CSS = """
body, .dashboard, .dashboard-content, #app { background: #eef2f7 !important; }
.grid-container { margin: 0 !important; }
.sidebar-resizer, .sidebar-resizer::after { display: none !important; }
.dashboard-component-chart-holder { padding: 0 !important; box-shadow: none !important; background: transparent !important; }
html, body { overflow: hidden !important; }  /* chart tự co theo khung nhìn, không cuộn trang (tab 3 khung tab) */
.dashboard-content, .grid-container, .dashboard-component-chart-holder { margin: 0 !important; }
"""


def lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("\\", "\\\\").replace("'", "''") + "'"


def dataset_sql():
    out = ["-- DỮ LIỆU MẪU tình hình triển khai thí điểm (sinh bởi theo_doi_thtk_thidiem/superset/build.py)",
           "-- 1 dòng = 1 đơn vị x 1 kỳ báo cáo. Thay bằng SELECT từ bảng thật, giữ nguyên tên cột."]
    for i, r in enumerate(DATA):
        if i == 0:
            out.append("SELECT " + ", ".join(f"{lit(r.get(c))} AS {c}" for c in COLS))
        else:
            out.append("UNION ALL SELECT " + ", ".join(lit(r.get(c)) for c in COLS))
    return "\n".join(out)


def chart_js():
    return TPL.replace("__DATASET__", DATASET)


def form_data(ds_id):
    return {
        "datasource": f"{ds_id}__table", "viz_type": "bkav-chart-advance",
        "groupby": [{"expressionType": "SQL", "label": c, "sqlExpression": c, "datasourceWarning": False} for c in COLS],
        "metrics": [{"expressionType": "SQL", "hasCustomLabel": True, "label": "n", "sqlExpression": "COUNT(*)"}],
        "metric": [], "adhoc_filters": [], "row_limit": 5000, "js_echart_building": chart_js(),
        "disable_padding_default": True, "is_hide_modal_header": True, "show_header_default": False, "show_metric": True,
        "empty_content": "Không có dữ liệu",
    }


def preview():
    """build/preview.html: echarts lấy từ file HTML gốc, gọi đúng hàm chart với dữ liệu mẫu."""
    src = open(os.path.join(HERE, "..", "dashboard_tinhhinh_trienkhai_v03.html"), encoding="utf-8").read()
    a = src.index("<script>")
    b = src.index("</script>", a) + len("</script>")
    lib = src[a:b]
    rows = [dict({c: r.get(c) for c in COLS}, n=1) for r in PREVIEW_DATA]
    html = f"""<!DOCTYPE html><html lang="vi"><head><meta charset="utf-8"><title>Preview thí điểm</title>
<style>body{{margin:0;background:#eef2f7}} #c{{width:100vw;height:{CHART_H * 8}px}}</style></head><body>
<div id="c"></div>{lib}
<script>var jsEchartScriptFunc;\n{chart_js()}\n
jsEchartScriptFunc({{data:{json.dumps(rows, ensure_ascii=False)}}}, {{}}, echarts, {{elementId:"c", height:{CHART_H * 8}}});
</script></body></html>"""
    open(os.path.join(BUILD, "preview.html"), "w", encoding="utf-8").write(html)


def deploy():
    sys.path.insert(0, HERE)
    import ss
    stp = os.path.join(BUILD, "state.json")
    st = json.load(open(stp)) if os.path.exists(stp) else {}
    save = lambda: json.dump(st, open(stp, "w"), indent=1)
    # nguồn dataset: mặc định số eForm kỳ tháng; "mau" = dữ liệu mẫu
    # mặc định: bảng datamart (NiFi); "eform" = SQL ảo tính trực tiếp; "mau" = dữ liệu mẫu
    src = "dataset_eform_thang.sql" if "eform" in sys.argv else "dataset_bang.sql"
    sql = dataset_sql() if "mau" in sys.argv else open(os.path.join(HERE, src)).read()
    # dataset ảo
    if not st.get("dataset_id"):
        r = ss.get("/api/v1/dataset/?q=" + ss.q(f"(filters:!((col:table_name,opr:eq,value:{DATASET})))"))
        hit = [d for d in r["result"] if d["database"]["id"] == DB_ID]
        st["dataset_id"] = hit[0]["id"] if hit else ss.post("/api/v1/dataset/", {"database": DB_ID, "schema": SCHEMA, "table_name": DATASET, "sql": sql})["id"]
        save()
    ds = st["dataset_id"]
    ss.put(f"/api/v1/dataset/{ds}", {"sql": sql})
    ss.put(f"/api/v1/dataset/{ds}/refresh", {})
    print("dataset", ds)
    # chart
    body = {"slice_name": CHART_NAME, "viz_type": "bkav-chart-advance", "datasource_id": ds, "datasource_type": "table",
            "params": json.dumps(form_data(ds), ensure_ascii=False)}
    if st.get("chart_id"):
        ss.put(f"/api/v1/chart/{st['chart_id']}", body)
    else:
        st["chart_id"] = ss.post("/api/v1/chart/", body)["id"]
        save()
    cid = st["chart_id"]
    print("chart", cid)
    # dashboard: 1 chart full width
    ch = "CHART-thidiem"
    pos = {"DASHBOARD_VERSION_KEY": "v2",
           "ROOT_ID": {"type": "ROOT", "id": "ROOT_ID", "children": ["GRID_ID"]},
           "GRID_ID": {"type": "GRID", "id": "GRID_ID", "children": ["ROW-thidiem"], "parents": ["ROOT_ID"]},
           "HEADER_ID": {"id": "HEADER_ID", "type": "HEADER", "meta": {"text": DASH_TITLE}},
           "ROW-thidiem": {"type": "ROW", "id": "ROW-thidiem", "children": [ch], "parents": ["ROOT_ID", "GRID_ID"],
                           "meta": {"background": "BACKGROUND_TRANSPARENT"}},
           ch: {"type": "CHART", "id": ch, "children": [], "parents": ["ROOT_ID", "GRID_ID", "ROW-thidiem"],
                "meta": {"width": 12, "height": CHART_H, "chartId": cid, "sliceName": CHART_NAME, "uuid": str(uuid.uuid5(uuid.NAMESPACE_URL, ch))}}}
    meta = {"color_scheme": "", "refresh_frequency": 0, "expanded_slices": {}, "label_colors": {}, "timed_refresh_immune_slices": [],
            "cross_filters_enabled": False, "default_filters": "{}", "chart_configuration": {},
            "global_chart_configuration": {"scope": {"rootPath": ["ROOT_ID"], "excluded": []}, "chartsInScope": [cid]}}
    body = {"dashboard_title": DASH_TITLE, "slug": DASH_SLUG, "position_json": json.dumps(pos, ensure_ascii=False),
            "json_metadata": json.dumps(meta, ensure_ascii=False), "css": CSS, "published": True}
    if st.get("dashboard_id"):
        ss.put(f"/api/v1/dashboard/{st['dashboard_id']}", body)
    else:
        st["dashboard_id"] = ss.post("/api/v1/dashboard/", body)["id"]
        save()
    ss.put(f"/api/v1/chart/{cid}", {"dashboards": [st["dashboard_id"]]})
    save()
    print("dashboard", st["dashboard_id"], ss.BASE + f"/superset/dashboard/{DASH_SLUG}/")


if __name__ == "__main__":
    open(os.path.join(BUILD, "dataset.sql"), "w").write(dataset_sql())
    open(os.path.join(BUILD, "chart.js"), "w").write(chart_js())
    preview()
    print("build/ xong:", len(DATA), "dòng")
    if "deploy" in sys.argv:
        deploy()
