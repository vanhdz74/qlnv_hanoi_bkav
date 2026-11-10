"""Sinh + triển khai dashboard Superset "NQ57 – Chuyên đề chi tiết" từ bảng chuyen_de_chi_tiet_nq57.

  python3 tao_dashboard.py preview   -> build/preview.html (render thử bằng echarts, dữ liệu từ sql/du_lieu_chuyen_de_nq57.json)
  python3 tao_dashboard.py deploy    -> tạo/cập nhật dataset, chart, dashboard trên Superset (tài khoản trong .env)

Mỗi thẻ KPI / biểu đồ / bảng là 1 chart riêng (viz bkav-chart-advance) dùng chung chart.tpl.js, khác nhau ở CFG.
Trạng thái triển khai (id dataset/chart/dashboard) lưu ở build/state.json để chạy lại thì cập nhật thay vì tạo mới.
"""
import json, os, sys, re, uuid

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")
os.makedirs(BUILD, exist_ok=True)
TPL = open(os.path.join(HERE, "chart.tpl.js")).read()
DATA = json.load(open(os.path.join(HERE, "..", "sql", "du_lieu_chuyen_de_nq57.json")))

TABLE, SCHEMA, DB_ID = "chuyen_de_chi_tiet_nq57", "datamart_hanoi", 8
DASH_TITLE, DASH_SLUG = "NQ57 – Chuyên đề chi tiết (theo báo cáo tháng)", "nq57-chuyen-de-chi-tiet"

COLS = {"nhom": "nhom_du_lieu", "ma": "ma_chi_so", "ky": "ky", "tt": "thu_tu_ky", "ttc": "thu_tu_chi_so", "scd": "stt_chuyen_de",
        "cd": "chuyen_de", "ten": "ten_chi_so", "tn": "ten_ngan", "dv": "don_vi_tinh", "loai": "loai_chi_so", "glt": "giam_la_tot",
        "ng": "nguong", "tng": "ten_nguong", "dm": "dau_moi", "pt": "phan_to", "nguon": "nguon_so_lieu", "gc": "ghi_chu", "ex": "thong_tin_them"}
METS = {"v": "gia_tri", "tu": "tu_so", "mau": "mau_so", "co": "co_so_lieu"}

# Dataset thứ 2: nhiệm vụ phụ lục đã map với task QLNV (luồng NiFi sql/nhiem_vu) - dùng cho bang_qh, hbar_cq
TABLE_NV = "chuyen_de_chi_tiet_nhiem_vu_nq57"
LOAI_NV = {"bang_qh", "hbar_cq"}
WHERE_NV = "loai_danh_sach = 'Quá hạn, chậm muộn'"
COLS_NV = {"nhom": "'NV_PL'", "ky": "ky", "tt": "thu_tu_ky", "stt": "thu_tu", "task": "task_id", "pl": "phu_luc",
           "tpl": "ten_phu_luc", "vbpl": "van_ban_phu_luc", "cqpl": "co_quan_phu_luc", "hanpl": "han_phu_luc",
           "ma": "ma_nhiem_vu", "vb": "van_ban_giao", "dvct": "ten_don_vi_chu_tri", "dvth": "ten_don_vi_thuc_hien",
           "han": "han_xu_ly", "nht": "ngay_hoan_thanh", "trg": "tinh_trang"}
METS_NV = {"td": "tien_do"}
PL_JSON = os.path.join(HERE, "..", "sql", "nhiem_vu", "phu_luc_nhiem_vu.json")

# ---------------- ĐỊNH NGHĨA TAB / CHART ----------------
CD = ["Nhiệm vụ", "Nguồn lực tài chính", "Dữ liệu đất đai", "Dữ liệu dùng chung", "TTHC và dịch vụ công", "Nền tảng số dùng chung",
      "Xã, phường và hạ tầng cơ sở", "KHCN, đổi mới sáng tạo, kinh tế số", "An toàn thông tin, an ninh mạng"]
TRANG = [
    ("nhiem-vu", "Nhiệm vụ", 1, ["NV01", "NV03", "NV05", "NV06"], [
        dict(loai="line", ma=["NV03"], kieu="pct", tieuDe="Tỷ lệ nhiệm vụ hoàn thành"),
        dict(loai="cot", ma=["NV05", "NV06"], tieuDe="Nhiệm vụ quá hạn qua các kỳ"),
        dict(loai="hbar_nguon", tieuDe="Theo nguồn giao"),
        dict(loai="hbar_cq", tieuDe="Quá hạn theo cơ quan chủ trì")]),
    ("tai-chinh", "Tài chính", 2, ["TC03", "TC06", "TC07", "TC08"], [
        dict(loai="line", ma=["TC06", "TC07", "TC08", "TC09"], kieu="pct", nguong="TC06", tieuDe="Tỷ lệ giải ngân qua các kỳ", rong=True),
        dict(loai="gauge", ma="TC03", tieuDe="Phân bổ dự toán"),
        dict(loai="cot", ma=["TC12"], tieuDe="Kinh phí chưa phân bổ (tỷ đồng)")]),
    ("dat-dai", "Đất đai", 3, ["DD01", "DD03", "DD05", "DD08"], [
        dict(loai="cot", ma=["DD01", "DD02", "DD04"], tieuDe="Tiến độ cơ sở dữ liệu đất đai (thửa)", rong=True),
        dict(loai="donut_dd", tieuDe="Cơ cấu thửa đất kỳ gần nhất"),
        dict(loai="gauge", ma="DD05", tieuDe="Thửa đạt Nhóm 1")]),
    ("du-lieu", "Dữ liệu dùng chung", 4, ["DL01", "DL07", "DL06", "DL05"], [
        dict(loai="line", ma=["DL01"], kieu="pct", tieuDe="Nguồn dữ liệu ưu tiên đã kết nối", rong=True),
        dict(loai="gauge", ma="DL07", tieuDe="Dữ liệu khai thác phục vụ TTHC"),
        dict(loai="gauge", ma="DL05", tieuDe="Nhiệm vụ triển khai Kho dữ liệu")]),
    ("tthc", "TTHC, dịch vụ công", 5, ["TT06", "TT03", "TT07", "TT16"], [
        dict(loai="line", ma=["TT03", "TT06"], kieu="pct", nguong="TT06", tieuDe="Toàn trình và tái cấu trúc qua các kỳ", rong=True),
        dict(loai="gauge", ma="TT06", tieuDe="Tái cấu trúc TTHC"),
        dict(loai="gauge", ma="TT14", tieuDe="TTHC trọng điểm trên hệ thống TP")]),
    ("nen-tang", "Nền tảng số", 6, ["NT01", "NT09", "NT12", "NT07"], [
        dict(loai="cot", ma=["NT01", "NT09", "NT11"], tieuDe="Tài khoản trên các nền tảng dùng chung", rong=True),
        dict(loai="gauge", ma="NT02", tieuDe="HanoiWork: tài khoản kích hoạt"),
        dict(loai="gauge", ma="NT12", tieuDe="Đảng viên dùng Sổ tay điện tử")]),
    ("xa-phuong", "Xã, phường", 7, ["CS01", "CS07", "CS08", "CS09"], [
        dict(loai="donut_xl", tieuDe="Xếp loại tiến độ xã, phường", h=52),
        dict(loai="hbar_nd", tieuDe="Có kết quả theo nhóm nội dung", h=52),
        dict(loai="hbar_dn", tieuDe="Điểm nghẽn chính xã phản ánh", rong=True, h=60)]),
    ("khcn", "KHCN, kinh tế số", 8, ["KH01", "KH05", "KH07", "KH13"], [
        dict(loai="line", ma=["KH01", "KH02", "KH03"], kieu="pct", tieuDe="Kinh tế số trong GRDP"),
        dict(loai="cot", ma=["KH10", "KH11", "KH12"], tieuDe="Sàn giao dịch công nghệ HanoTEX"),
        dict(loai="gauge", ma="KH04", tieuDe="Nhiệm vụ phát triển kinh tế số hoàn thành"),
        dict(loai="gauge", ma="KH01", tieuDe="Tỷ trọng kinh tế số / GRDP")]),
    ("attt", "An toàn thông tin", 9, ["AT01", "AT02", "AT03", "AT09"], [
        dict(loai="cot", ma=["AT01"], tieuDe="Hệ thống được phê duyệt cấp độ"),
        dict(loai="line", ma=["AT05"], kieu="num", tieuDe="Máy tính được SOC giám sát"),
        dict(loai="gauge", ma="AT02", tieuDe="Hệ thống đã phê duyệt cấp độ"),
        dict(loai="gauge", ma="AT09", tieuDe="Đơn vị gửi báo cáo ATTT")]),
]
TQ = [["nhiem-vu", "NV03"], ["tai-chinh", "TC08"], ["dat-dai", "DD05"], ["du-lieu", "DL01"], ["tthc", "TT06"], ["nen-tang", "NT01"],
      ["xa-phuong", "CS01"], ["khcn", "KH01"], ["attt", "AT01"]]
CAN_CHU_Y = [("NV01", "nhiem-vu"), ("NV06", "nhiem-vu"), ("TC06", "tai-chinh"), ("DL07", "du-lieu"), ("TT06", "tthc"), ("AT09", "attt")]


def loc(cfg):
    """(SQL WHERE, hàm lọc python) cho 1 chart."""
    L = cfg["loai"]
    if L in LOAI_NV:
        return WHERE_NV, lambda r: r.get("loai_danh_sach") == "Quá hạn, chậm muộn"
    nhom = {"hbar_nguon": "NGUON_GIAO", "hbar_nd": "NOI_DUNG_XA",
            "hbar_dn": "DIEM_NGHEN_XA", "bang_xa": "XA_QUAN_TAM"}.get(L)
    if nhom:
        return f"nhom_du_lieu = '{nhom}'", lambda r: r["nhom_du_lieu"] == nhom
    mas = {"donut_dd": ["DD01", "DD02", "DD04"], "donut_nv": ["NV01", "NV02", "NV04", "NV05"],
           "donut_xl": ["CS10", "CS11", "CS12", "CS13", "CS14"]}.get(L)
    if mas is None and "ma" in cfg:
        mas = cfg["ma"] if isinstance(cfg["ma"], list) else [cfg["ma"]]
        if cfg.get("nguong") and cfg["nguong"] not in mas:
            mas = mas + [cfg["nguong"]]
    if mas:
        return ("nhom_du_lieu = 'CHI_SO' AND ma_chi_so IN (" + ",".join(f"'{m}'" for m in mas) + ")",
                lambda r, s=set(mas): r["nhom_du_lieu"] == "CHI_SO" and r["ma_chi_so"] in s)
    if L == "bang_cs":
        return f"nhom_du_lieu = 'CHI_SO' AND stt_chuyen_de = {cfg['scd']}", lambda r: r["nhom_du_lieu"] == "CHI_SO" and r["stt_chuyen_de"] == cfg["scd"]
    return "nhom_du_lieu = 'CHI_SO'", lambda r: r["nhom_du_lieu"] == "CHI_SO"


def tabs():
    """Trả về [(ten_tab, [ROW = [(cfg, width, height) | ('COL', width, [(cfg,h),..])]])]"""
    T = []
    # ---- Tổng quan
    rows = [[(dict(loai="kpi", ma=m, icon=i, link=True), 2, 21) for m, i in CAN_CHU_Y]]
    tq = [[i, m, CD[n]] for n, (i, m) in enumerate(TQ)]
    rows.append([(dict(loai="bang_tq", tq=tq, tieuDe="Chín chuyên đề"), 8, 76),
                 ("COL", 4, [(dict(loai="donut_nv", tieuDe="Tình trạng nhiệm vụ"), 38), (dict(loai="donut_xl", tieuDe="Xếp loại tiến độ xã, phường"), 38)])])
    TEN_TAB = {"tong-quan": "Tổng quan", **{tid: ten for tid, ten, *_ in TRANG}, "danh-muc": "Danh mục chỉ số"}
    for row in rows:
        for it in row:
            for c in _cfgs_of(it):
                if c.get("link") or c["loai"] == "bang_tq":
                    c["tabTen"] = TEN_TAB
    T.append(("Tổng quan", "tong-quan", rows))
    # ---- 9 chuyên đề
    for tid, ten, scd, kpi, bds in TRANG:
        rows = [[(dict(loai="kpi", ma=m, icon=tid, gon=True), 3, 14) for m in kpi]]  # thẻ thấp (112px) cho đỡ cuộn
        # như UI mẫu: cột trái = các biểu đồ (lưới 2 cột), cột phải = bảng, nằm ngang hàng nhau
        LW, RW = 8, 4
        left, cur = [], []
        for b in sorted(bds, key=lambda b: 0 if b.get("rong") else 1):
            if b.get("rong"):
                left.append([(b, LW, b.get("h", 42))])
                continue
            cur.append((b, LW // 2, b.get("h", 40)))
            if len(cur) == 2:
                left.append(cur); cur = []
        if cur:
            left.append([(cur[0][0], LW, 40)])
        H = sum(max(h for _, _, h in r) for r in left)
        bang_cs = dict(loai="bang_cs", scd=scd, tieuDe=f"Tất cả chỉ số – {CD[scd - 1]}")
        if tid == "nhiem-vu":
            right = [(dict(loai="bang_qh", tieuDe="Nhiệm vụ quá hạn"), H // 2), (bang_cs, H - H // 2)]
        elif tid == "xa-phuong":
            right = [(dict(loai="bang_xa", tieuDe="Xã, phường cần quan tâm"), H // 2), (bang_cs, H - H // 2)]
        else:
            right = [(bang_cs, H)]
        rows.append([("COLR", LW, left), ("COL", RW, right)])
        T.append((ten, tid, rows))
    # ---- Danh mục
    rows = [[(dict(loai="dem", dem=k, nhan=n), 3, 19) for k, n in
             [("tong", "Tổng số chỉ số"), ("moi", "Có số liệu từ"), ("cu", "Chỉ có số liệu kỳ cũ hơn"), ("chua", "Chưa có số liệu")]]]
    rows.append([(dict(loai="bang_dm", tieuDe="Danh mục chỉ số"), 12, 100)])
    T.append(("Danh mục chỉ số", "danh-muc", rows))
    # gán key + tên chart
    for ten, tid, rows in T:
        n = 0
        for row in rows:
            for it in row:
                for cfg in _cfgs_of(it):
                    n += 1
                    cfg["key"] = f"{tid}-{n:02d}"
                    nm = cfg.get("tieuDe") or cfg.get("nhan") or (("KPI " + cfg["ma"]) if cfg["loai"] == "kpi" else cfg["loai"])
                    cfg["_name"] = f"NQ57 CĐ chi tiết – {ten} – {n:02d} {nm}"
    return T


def _cfgs_of(it):
    """it: (cfg, w, h) | ('COL', w, [(cfg, h)]) | ('COLR', w, [[(cfg, w, h), ...], ...])"""
    if it[0] == "COL":
        return [c for c, _ in it[2]]
    if it[0] == "COLR":
        return [c for r in it[2] for c, _, _ in r]
    return [it[0]]


def all_cfgs(T):
    for ten, tid, rows in T:
        for row in rows:
            for it in row:
                yield from _cfgs_of(it)


def js_of(cfg):
    c = {k: v for k, v in cfg.items() if not k.startswith("_")}
    return TPL.replace("__CFG__", json.dumps(c, ensure_ascii=False)).replace("__TITLE__", cfg["_name"])


def form_data(cfg, ds_id):
    where, _ = loc(cfg)
    cols, mets = (COLS_NV, METS_NV) if cfg["loai"] in LOAI_NV else (COLS, METS)
    return {
        "datasource": f"{ds_id}__table", "viz_type": "bkav-chart-advance",
        "groupby": [{"expressionType": "SQL", "label": k, "sqlExpression": v, "datasourceWarning": False} for k, v in cols.items()],
        "metrics": [{"expressionType": "SQL", "hasCustomLabel": True, "label": k, "sqlExpression": f"MAX({v})"} for k, v in mets.items()],
        "metric": [], "adhoc_filters": [{"expressionType": "SQL", "clause": "WHERE", "sqlExpression": where,
                                         "filterOptionName": "f_" + cfg["key"].replace("-", "_")}],
        "row_limit": 5000, "js_echart_building": js_of(cfg), "disable_padding_default": True, "is_hide_modal_header": True,
        "show_header_default": False, "show_metric": True, "empty_content": "Không có dữ liệu",
    }


def rows_for(cfg):
    _, f = loc(cfg)
    if cfg["loai"] in LOAI_NV:      # preview: chỉ có dữ liệu phụ lục, chưa có phần map QLNV (chạy trên NiFi)
        tt = {f"T{t}/2026": t - 1 for t in range(2, 13)}
        return [{"nhom": "NV_PL", "ky": r["ky"], "tt": tt.get(r["ky"]), "stt": r["thu_tu"], "task": 0, "pl": r["phu_luc"],
                 "tpl": r["ten"], "vbpl": r.get("vb"), "cqpl": r.get("dv"), "hanpl": r.get("han")}
                for r in json.load(open(PL_JSON)) if f(r)]
    out = []
    for r in DATA:
        if f(r):
            o = {k: r.get(v) for k, v in COLS.items()}
            o.update({k: r.get(v) for k, v in METS.items()})
            out.append(o)
    return out


# ---------------- PREVIEW ----------------
def preview(T):
    UNIT_W, UNIT_H = 1840 / 12, 8
    charts, tabs_html = [], []
    for ten, tid, rows in T:
        body = []
        for row in rows:
            cells = []
            for it in row:
                if it[0] == "COLR":
                    inner = []
                    for r in it[2]:
                        cs_ = "".join(f'<div class="cell" style="width:{w * UNIT_W - 16}px;height:{h * UNIT_H}px"><div id="nq57-{c["key"]}"></div></div>' for c, w, h in r)
                        inner.append(f'<div class="row" style="margin:0">{cs_}</div>')
                        charts += [(c, w * UNIT_W - 16, h * UNIT_H) for c, w, h in r]
                    cells.append(f'<div style="width:{it[1] * UNIT_W - 16}px;display:flex;flex-direction:column;gap:16px">{"".join(inner)}</div>')
                elif it[0] == "COL":
                    inner = "".join(f'<div class="cell" style="height:{h * UNIT_H}px"><div id="nq57-{c["key"]}"></div></div>' for c, h in it[2])
                    cells.append(f'<div style="width:{it[1] * UNIT_W - 16}px;display:flex;flex-direction:column;gap:16px">{inner}</div>')
                    charts += [(c, it[1] * UNIT_W - 16, h * UNIT_H) for c, h in it[2]]
                else:
                    c, w, h = it
                    cells.append(f'<div class="cell" style="width:{w * UNIT_W - 16}px;height:{h * UNIT_H}px"><div id="nq57-{c["key"]}"></div></div>')
                    charts.append((c, w * UNIT_W - 16, h * UNIT_H))
            body.append(f'<div class="row">{"".join(cells)}</div>')
        tabs_html.append(f'<section data-tab="{tid}"><h2>{ten}</h2>{"".join(body)}</section>')
    fns = []
    for c, w, h in charts:
        fns.append(f'(function(){{var jsEchartScriptFunc;{js_of(c)}\ntry{{jsEchartScriptFunc({{data:{json.dumps(rows_for(c), ensure_ascii=False)}}},{{}},echarts,'
                   f'{{elementId:"nq57-{c["key"]}",width:{int(w)},height:{int(h)}}});}}catch(e){{document.getElementById("nq57-{c["key"]}").innerText="LỖI "+e;console.error(e)}}}})();')
    html = f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><title>NQ57 preview</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/echarts/5.4.3/echarts.min.js"></script>
<style>body{{margin:0;padding:16px 24px;background:#F2F4F7;font-family:sans-serif}} h2{{margin:24px 0 8px;font-size:20px}}
.row{{display:flex;gap:16px;margin-bottom:16px}} .cell{{background:#fff;border-radius:6px;overflow:hidden;padding:0}}
section{{display:none}} section.on{{display:block}}</style></head><body>
{"".join(tabs_html)}
<script>var t=(location.hash||"#tong-quan").slice(1);document.querySelectorAll("section").forEach(function(s){{if(s.dataset.tab===t||t==="all")s.classList.add("on")}});</script>
<script>{chr(10).join(fns)}</script></body></html>"""
    p = os.path.join(BUILD, "preview.html")
    open(p, "w").write(html)
    print("preview:", p, "charts:", len(charts))


# ---------------- DEPLOY ----------------
# CSS dashboard bám ui/NQ57Dashboard.jsx: nền trắng, thanh tab cao 64px (px-8, gạch dưới #D9DEE7),
# tab bo 8px cao 44px chữ 15px #344054, hover nền #E4E7EC, tab đang chọn nền #1D6FE8 chữ trắng; nội dung px-10 py-5.
CSS = """
body, .dashboard, .dashboard-content, #app { background: #fff !important; }
/* lề 40px đặt trên grid-container để Superset tính đúng độ rộng chart; thanh tab kéo tràn lại bằng margin âm */
.standalone .grid-container, .grid-container { margin: 0 40px !important; background: #fff !important; }
body { overflow-x: hidden; }
.sidebar-resizer, .sidebar-resizer::after { display: none !important; }

/* ---- Thanh tab chuyên đề ---- */
#TABS-nq57 .ant-tabs-nav, .dashboard-component-tabs .ant-tabs-card > .ant-tabs-nav {
  height: 64px !important; margin: 0 -40px !important; padding: 0 32px !important;
  background: #fff !important; border-bottom: 1px solid #D9DEE7 !important;
}
.dashboard-component-tabs .ant-tabs-nav::before { border-bottom: 0 !important; }
.dashboard-component-tabs .ant-tabs-nav-list { align-items: center !important; gap: 4px; }
.dashboard-component-tabs .ant-tabs-ink-bar { display: none !important; }
.dashboard-component-tabs .ant-tabs-tab {
  height: 44px !important; margin: 0 !important; padding: 0 12px !important;
  border: 0 !important; border-radius: 8px !important; background: transparent !important;
  font-size: 15px !important; font-weight: 500 !important; color: #344054 !important;
  letter-spacing: -0.011em; transition: background-color .15s, color .15s;
}
.dashboard-component-tabs .ant-tabs-tab .ant-tabs-tab-btn,
.dashboard-component-tabs .ant-tabs-tab .editable-title,
.dashboard-component-tabs .ant-tabs-tab .editable-title * { color: inherit !important; font-weight: inherit !important; }
.dashboard-component-tabs .ant-tabs-tab:hover { background: #E4E7EC !important; color: #344054 !important; }
.dashboard-component-tabs .ant-tabs-tab.ant-tabs-tab-active,
.dashboard-component-tabs .ant-tabs-tab.ant-tabs-tab-active:hover { background: #1D6FE8 !important; color: #fff !important; font-weight: 600 !important; }
.dashboard-component-tabs .ant-tabs-tab .ant-tabs-tab-btn:focus-visible { outline: 2px solid #1D6FE8; outline-offset: 2px; border-radius: 8px; }
.dashboard-component-tabs .ant-tabs-tab .anchor-link-container { display: none !important; }

/* ---- Icon trên tab (bộ Lucide như UI mẫu), xanh khi thường, trắng khi đang chọn ---- */
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab .ant-tabs-tab-btn { display: inline-flex !important; align-items: center; gap: 8px; }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab .ant-tabs-tab-btn::before {
  content: ""; flex: none; width: 18px; height: 18px; background-color: #1D6FE8;
  -webkit-mask: var(--ico) center / contain no-repeat; mask: var(--ico) center / contain no-repeat;
}
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab.ant-tabs-tab-active .ant-tabs-tab-btn::before { background-color: #fff; }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(1) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Crect x=%223%22 y=%223%22 width=%227%22 height=%229%22 rx=%221%22/%3E%3Crect x=%2214%22 y=%223%22 width=%227%22 height=%225%22 rx=%221%22/%3E%3Crect x=%2214%22 y=%2212%22 width=%227%22 height=%229%22 rx=%221%22/%3E%3Crect x=%223%22 y=%2216%22 width=%227%22 height=%225%22 rx=%221%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(2) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Crect x=%228%22 y=%222%22 width=%228%22 height=%224%22 rx=%221%22/%3E%3Cpath d=%22M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2%22/%3E%3Cpath d=%22m9 14 2 2 4-4%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(3) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1%22/%3E%3Cpath d=%22M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(4) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z%22/%3E%3Cpath d=%22M15 5.764v15%22/%3E%3Cpath d=%22M9 3.236v15%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(5) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cellipse cx=%2212%22 cy=%225%22 rx=%229%22 ry=%223%22/%3E%3Cpath d=%22M3 5V19A9 3 0 0 0 21 19V5%22/%3E%3Cpath d=%22M3 12A9 3 0 0 0 21 12%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(6) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z%22/%3E%3Cpath d=%22M14 2v4a2 2 0 0 0 2 2h4%22/%3E%3Cpath d=%22M16 13H8%22/%3E%3Cpath d=%22M16 17H8%22/%3E%3Cpath d=%22M10 9H8%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(7) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z%22/%3E%3Cpath d=%22m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65%22/%3E%3Cpath d=%22m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(8) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M3 22h18%22/%3E%3Cpath d=%22M6 18v-7%22/%3E%3Cpath d=%22M10 18v-7%22/%3E%3Cpath d=%22M14 18v-7%22/%3E%3Cpath d=%22M18 18v-7%22/%3E%3Cpath d=%22M12 2 20 7H4z%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(9) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5%22/%3E%3Cpath d=%22M9 18h6%22/%3E%3Cpath d=%22M10 22h4%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(10) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z%22/%3E%3Cpath d=%22m9 12 2 2 4-4%22/%3E%3C/svg%3E"); }
.dashboard-component-tabs .ant-tabs-nav-list > .ant-tabs-tab:nth-child(11) { --ico: url("data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%23000%22 stroke-width=%222%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22%3E%3Cpath d=%22M3 5h.01%22/%3E%3Cpath d=%22M3 12h.01%22/%3E%3Cpath d=%22M3 19h.01%22/%3E%3Cpath d=%22M8 5h13%22/%3E%3Cpath d=%22M8 12h13%22/%3E%3Cpath d=%22M8 19h13%22/%3E%3C/svg%3E"); }

/* ---- Vùng nội dung: 20px trên/dưới (lề ngang nằm ở grid-container) ---- */
.dashboard-component-tabs .ant-tabs-content-holder { padding: 20px 0 !important; background: #fff !important; }
.dashboard-component-chart-holder { background: transparent !important; }
"""


def deploy(T):
    sys.path.insert(0, HERE)
    import ss
    stp = os.path.join(BUILD, "state.json")
    st = json.load(open(stp)) if os.path.exists(stp) else {"charts": {}}
    # dataset
    if not st.get("dataset_id"):
        r = ss.get("/api/v1/dataset/?q=" + ss.q(f"(filters:!((col:table_name,opr:eq,value:{TABLE})))"))
        hit = [d for d in r["result"] if d.get("schema") == SCHEMA and d["database"]["id"] == DB_ID]
        st["dataset_id"] = hit[0]["id"] if hit else ss.post("/api/v1/dataset/", {"database": DB_ID, "schema": SCHEMA, "table_name": TABLE})["id"]
        json.dump(st, open(stp, "w"), indent=1)
    ds = st["dataset_id"]
    if not st.get("dataset_nv_id"):
        r = ss.get("/api/v1/dataset/?q=" + ss.q(f"(filters:!((col:table_name,opr:eq,value:{TABLE_NV})))"))
        hit = [d for d in r["result"] if d.get("schema") == SCHEMA and d["database"]["id"] == DB_ID]
        st["dataset_nv_id"] = hit[0]["id"] if hit else ss.post("/api/v1/dataset/", {"database": DB_ID, "schema": SCHEMA, "table_name": TABLE_NV})["id"]
        json.dump(st, open(stp, "w"), indent=1)
    print("dataset", ds, "dataset nhiem vu", st["dataset_nv_id"])
    # charts
    for cfg in all_cfgs(T):
        dsi = st["dataset_nv_id"] if cfg["loai"] in LOAI_NV else ds
        fd = form_data(cfg, dsi)
        body = {"slice_name": cfg["_name"], "viz_type": "bkav-chart-advance", "datasource_id": dsi, "datasource_type": "table",
                "params": json.dumps(fd, ensure_ascii=False)}
        cid = st["charts"].get(cfg["key"])
        if cid:
            ss.put(f"/api/v1/chart/{cid}", body)
        else:
            cid = ss.post("/api/v1/chart/", body)["id"]
            st["charts"][cfg["key"]] = cid
            json.dump(st, open(stp, "w"), indent=1)
        cfg["_id"] = cid
    print("charts", len(st["charts"]))
    # layout
    pos = {"DASHBOARD_VERSION_KEY": "v2", "ROOT_ID": {"type": "ROOT", "id": "ROOT_ID", "children": ["GRID_ID"]},
           "GRID_ID": {"type": "GRID", "id": "GRID_ID", "children": ["TABS-nq57"], "parents": ["ROOT_ID"]},
           "HEADER_ID": {"id": "HEADER_ID", "type": "HEADER", "meta": {"text": DASH_TITLE}},
           "TABS-nq57": {"type": "TABS", "id": "TABS-nq57", "children": [], "parents": ["ROOT_ID", "GRID_ID"], "meta": {}}}
    def chart_node(cfg, w, h, parents):
        i = f"CHART-{cfg['key']}"
        pos[i] = {"type": "CHART", "id": i, "children": [], "parents": parents,
                  "meta": {"width": w, "height": h, "chartId": cfg["_id"], "sliceName": cfg["_name"], "uuid": str(uuid.uuid5(uuid.NAMESPACE_URL, i))}}
        return i
    for ten, tid, rows in T:
        tab = f"TAB-{tid}"
        tp = ["ROOT_ID", "GRID_ID", "TABS-nq57"]
        pos["TABS-nq57"]["children"].append(tab)
        pos[tab] = {"type": "TAB", "id": tab, "children": [], "parents": tp, "meta": {"text": ten, "defaultText": "Tab title", "placeholder": "Tab title"}}
        for n, row in enumerate(rows):
            rid = f"ROW-{tid}-{n}"
            rp = tp + [tab]
            pos[tab]["children"].append(rid)
            pos[rid] = {"type": "ROW", "id": rid, "children": [], "parents": rp, "meta": {"background": "BACKGROUND_TRANSPARENT"}}
            for k, it in enumerate(row):
                if it[0] == "COLR":
                    cid = f"COLUMN-{tid}-{n}-{k}"
                    pos[rid]["children"].append(cid)
                    cp = rp + [rid, cid]
                    pos[cid] = {"type": "COLUMN", "id": cid, "children": [], "parents": rp + [rid], "meta": {"width": it[1], "background": "BACKGROUND_TRANSPARENT"}}
                    for j, r in enumerate(it[2]):
                        sub = f"ROW-{tid}-{n}-{k}-{j}"
                        pos[cid]["children"].append(sub)
                        pos[sub] = {"type": "ROW", "id": sub, "children": [], "parents": cp, "meta": {"background": "BACKGROUND_TRANSPARENT"}}
                        for c, w, h in r:
                            pos[sub]["children"].append(chart_node(c, w, h, cp + [sub]))
                elif it[0] == "COL":
                    cid = f"COLUMN-{tid}-{n}-{k}"
                    pos[rid]["children"].append(cid)
                    pos[cid] = {"type": "COLUMN", "id": cid, "children": [], "parents": rp + [rid], "meta": {"width": it[1], "background": "BACKGROUND_TRANSPARENT"}}
                    for c, h in it[2]:
                        pos[cid]["children"].append(chart_node(c, it[1], h, rp + [rid, cid]))
                else:
                    pos[rid]["children"].append(chart_node(it[0], it[1], it[2], rp + [rid]))
    ids = list(st["charts"].values())
    meta = {"color_scheme": "", "refresh_frequency": 0, "expanded_slices": {}, "label_colors": {}, "timed_refresh_immune_slices": [],
            "cross_filters_enabled": False, "default_filters": "{}", "chart_configuration": {},
            "global_chart_configuration": {"scope": {"rootPath": ["ROOT_ID"], "excluded": []}, "chartsInScope": ids},
            "positions": pos}
    css = CSS
    body = {"dashboard_title": DASH_TITLE, "slug": DASH_SLUG, "position_json": json.dumps(pos, ensure_ascii=False),
            "json_metadata": json.dumps({k: v for k, v in meta.items() if k != "positions"}, ensure_ascii=False), "css": css, "published": True}
    if st.get("dashboard_id"):
        ss.put(f"/api/v1/dashboard/{st['dashboard_id']}", body)
    else:
        st["dashboard_id"] = ss.post("/api/v1/dashboard/", body)["id"]
        json.dump(st, open(stp, "w"), indent=1)
    did = st["dashboard_id"]
    for cid in ids:
        ss.put(f"/api/v1/chart/{cid}", {"dashboards": [did]})
    json.dump(st, open(stp, "w"), indent=1)
    print("dashboard", did, ss.BASE + f"/superset/dashboard/{DASH_SLUG}/")


if __name__ == "__main__":
    T = tabs()
    for cfg in all_cfgs(T):
        open(os.path.join(BUILD, cfg["key"] + ".js"), "w").write(js_of(cfg))
    if "preview" in sys.argv:
        preview(T)
    if "deploy" in sys.argv:
        deploy(T)
