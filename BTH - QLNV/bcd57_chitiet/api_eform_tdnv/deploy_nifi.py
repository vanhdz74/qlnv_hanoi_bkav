"""Luồng NiFi đẩy số NV01–NV16 sang Eform (TDNV_NHIEM_VU) – 19/11/2026.
  python3 deploy_nifi.py build    # tạo group mới "Day so Eform - TDNV_NHIEM_VU" (mọi processor STOPPED)
  python3 deploy_nifi.py key      # ghi khóa EFORM_TDNV_API_KEY_PROD (.env) vào InvokeHTTP (thuộc tính nhạy cảm)
  python3 deploy_nifi.py start    # bật toàn bộ processor
  python3 deploy_nifi.py once     # chạy hẹn giờ 1 lần (gửi 3 gói ngay)
  python3 deploy_nifi.py sql      # nạp lại goi_eform.sql (sau khi sửa chi_so_nv01_16.sql → build_goi.py)
  python3 deploy_nifi.py stop | status
Luồng: Hẹn giờ (CRON, mỗi giờ giờ hành chính) → đặt p.ngay/p.taken → ExecuteSQL (3 dòng MONTH/WEEK/DAY)
  → Avro→JSON → tách dòng → lấy ô goi làm nội dung → InvokeHTTP POST Eform
  → 200: LogAttribute (ghi accepted/rejected)   khác 200 / lỗi mạng: LogAttribute WARN → hàng đợi "Giu goi loi" (giữ 7 ngày).
HTTPS: Java 17.0.10 của NiFi thiếu GlobalSign Root R46 → group gắn param context "LGSP Van Ban" (c6170e4a),
  service "SSL - GlobalSign R46" (khóa 'ssl' trong nifi_ids.json) = #{lgsp_truststore_file} / #{lgsp_truststore_pass},
  gắn vào InvokeHTTP. Thêm tay 19/11 sau build; dựng lại thì làm lại bước này.
Chỉ TẠO MỚI, không đụng group/processor đang có. ID lưu ở nifi_ids.json.
"""
import json, os, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
_H = "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu/deploy_truong.py"
_g = {"__file__": _H}
exec(open(_H, encoding="utf-8").read().split("if __name__")[0], _g)
call, proc, set_state, bulletins = (_g[k] for k in ("call", "proc", "set_state", "bulletins"))
REPO_ENV = os.path.join(_g["REPO"], ".env")
PARENT = "0bfb3422-8a21-1e6a-8a1d-f4ecee881205"   # cha của các group "API - …"
DBCP = "0bfb327e-8a21-1e6a-776c-e17610335bef"     # HaNoi_Datamart (pool đang dùng cho API báo cáo tuần)
URL = "https://theodoinhiemvu.hanoi.gov.vn/eform-bcd57/baocao/api/v1/integration/aggregation-flows/TDNV_NHIEM_VU/values"
URL_DEV = "http://10.2.22.69:28081/api/v1/integration/aggregation-flows/TDNV_NHIEM_VU/values"  # theo gui-doi-nifi-1911.md
CRON = "23 7 8-17 ? * MON-FRI"                    # 8:07 … 17:07, thứ Hai–Sáu (giây 23 để tránh dồn đợt giây 05)
IDS = os.path.join(HERE, "nifi_ids.json")
SQL_FILE = os.path.join(HERE, "goi_eform.sql")
STD = "org.apache.nifi.processors.standard."
ATTR = "org.apache.nifi.processors.attributes.UpdateAttribute"
PROCS = ("gen", "par", "exe", "avro", "split", "attr", "lay", "post", "ok", "warn", "hold")


def ids():
    return json.load(open(IDS)) if os.path.exists(IDS) else {}


def save(d):
    json.dump(d, open(IDS, "w"), ensure_ascii=False, indent=1)


def env(name):
    for line in open(REPO_ENV, encoding="utf-8"):
        k, _, v = line.strip().partition("=")
        if k == name:
            return v.strip().strip('"\'')


def P(g, typ, name, x, y, props=None, auto=None, sched=None, extra=None):
    cfg = {"properties": props or {}}
    if auto: cfg["autoTerminatedRelationships"] = auto
    if sched: cfg.update(sched)
    if extra: cfg.update(extra)
    return call("POST", f"/process-groups/{g}/processors", {"revision": {"version": 0}, "component": {
        "type": typ, "name": name, "position": {"x": x, "y": y}, "config": cfg}})["id"]


def C(g, src, dst, rels, expire="0 sec"):
    return call("POST", f"/process-groups/{g}/connections", {"revision": {"version": 0}, "component": {
        "source": {"id": src, "groupId": g, "type": "PROCESSOR"},
        "destination": {"id": dst, "groupId": g, "type": "PROCESSOR"},
        "selectedRelationships": rels, "flowFileExpiration": expire}})["id"]


def free_position():
    fl = call("GET", f"/flow/process-groups/{PARENT}")["processGroupFlow"]["flow"]
    ys = [x["position"]["y"] for k in ("processGroups", "processors", "labels") for x in fl.get(k, [])]
    xs = [x["position"]["x"] for x in fl.get("processGroups", [])] or [0]
    return {"x": min(xs), "y": (max(ys) if ys else 0) + 250}


def exe_props():
    return {"Database Connection Pooling Service": DBCP, "SQL select query": open(SQL_FILE, encoding="utf-8").read(),
            "Max Wait Time": "50 seconds", "dbf-normalize": "false", "dbf-user-logical-types": "false",
            "esql-auto-commit": "true"}


def build():
    if ids().get("group"):
        raise SystemExit("đã có: " + json.dumps(ids()))
    g = call("POST", f"/process-groups/{PARENT}/process-groups", {"revision": {"version": 0}, "component": {
        "name": "Day so Eform - TDNV_NHIEM_VU (20261119)", "position": free_position(),
        "comments": "Đẩy NV01–NV16 theo đơn vị sang Eform, mỗi giờ giờ hành chính. "
                    "SQL: BTH - QLNV/bcd57_chitiet/api_eform_tdnv/ (build_goi.py, deploy_nifi.py)"}})["id"]
    d = {"group": g}; save(d)
    gen = P(g, STD + "GenerateFlowFile", "Hen gio (moi gio, gio hanh chinh)", 0, 0,
            {"generate-ff-custom-text": "-", "Data Format": "Text"},
            sched={"schedulingStrategy": "CRON_DRIVEN", "schedulingPeriod": CRON})
    par = P(g, ATTR, "Ngay lay so + taken_at", 0, 200, {
        "p.ngay": "${now():format('yyyy-MM-dd', 'Asia/Ho_Chi_Minh')}",
        "p.taken": "${now():format(\"yyyy-MM-dd'T'HH:mm:ss'+07:00'\", 'Asia/Ho_Chi_Minh')}"})
    exe = P(g, STD + "ExecuteSQL", "Tinh goi NV01-16 (3 ky)", 0, 400, exe_props())
    avro = P(g, "org.apache.nifi.processors.avro.ConvertAvroToJSON", "Avro -> JSON", 0, 600, {
        "JSON container options": "array", "Wrap Single Record": "true"})
    split = P(g, STD + "SplitJson", "Tach tung ky", 0, 800, {"JsonPath Expression": "$.*"}, auto=["original"])
    attr = P(g, STD + "EvaluateJsonPath", "Lay loai ky + so dong", 0, 1000, {
        "Destination": "flowfile-attribute", "Return Type": "scalar", "Path Not Found Behavior": "ignore",
        "eform.ky": "$.loai", "eform.so_dong": "$.so_dong"})
    lay = P(g, STD + "EvaluateJsonPath", "Lay o goi lam noi dung", 0, 1200, {
        "Destination": "flowfile-content", "Return Type": "scalar", "Path Not Found Behavior": "ignore",
        "goi": "$.goi"})
    post = P(g, STD + "InvokeHTTP", "Gui Eform TDNV_NHIEM_VU", 0, 1400, {
        "HTTP Method": "POST", "Remote URL": URL, "Content-Type": "application/json; charset=UTF-8",
        "Connection Timeout": "10 secs", "Read Timeout": "60 secs",
        "X-API-KEY": env("EFORM_TDNV_API_KEY_PROD") or "CHUA_NHAP_KHOA"},
        auto=["Original"], extra={"sensitiveDynamicPropertyNames": ["X-API-KEY"]})
    ok = P(g, STD + "LogAttribute", "Da gui (log accepted/rejected)", 0, 1600, {
        "Log Level": "info", "Log Payload": "true", "attributes-to-log-regex": "eform\\..*|invokehttp\\.status\\..*"},
        auto=["success"])
    warn = P(g, STD + "LogAttribute", "Loi gui Eform", 600, 1600, {
        "Log Level": "warn", "Log Payload": "true",
        "attributes-to-log-regex": "eform\\..*|invokehttp\\..*"})
    hold = P(g, ATTR, "Giu goi loi (STOPPED, xem hang doi)", 600, 1800)
    e500 = [C(g, exe, warn, ["failure"]), C(g, avro, warn, ["failure"]), C(g, split, warn, ["failure"]),
            C(g, attr, warn, ["unmatched", "failure"]), C(g, lay, warn, ["unmatched", "failure"])]
    conns = [C(g, gen, par, ["success"]), C(g, par, exe, ["success"]), C(g, exe, avro, ["success"]),
             C(g, avro, split, ["success"]), C(g, split, attr, ["split"]), C(g, attr, lay, ["matched"]),
             C(g, lay, post, ["matched"]),
             C(g, post, ok, ["Response"]),          # mọi mã trả về có body; mã ≠ 2xx đi nhánh Retry/No Retry
             C(g, post, warn, ["Retry", "No Retry", "Failure"]),
             C(g, warn, hold, ["success"], expire="7 days")] + e500
    lab = call("POST", f"/process-groups/{g}/labels", {"revision": {"version": 0}, "component": {
        "label": ("Đẩy số NV01–NV16 sang Eform (19/11/2026)\n"
                  f"POST {URL}\nCRON {CRON} – 3 gói/lần: MONTH, WEEK (SAT), DAY của ngày chạy.\n"
                  "Khóa: thuộc tính nhạy cảm X-API-KEY trên InvokeHTTP. Lỗi → hàng đợi 'Giu goi loi' (7 ngày).\n"
                  "Sửa số: chi_so_nv01_16.sql → build_goi.py → deploy_nifi.py sql"),
        "position": {"x": 1200, "y": 0}, "width": 560, "height": 130,
        "style": {"font-size": "12px", "background-color": "#e2f0fd"}}})["id"]
    d.update({"gen": gen, "par": par, "exe": exe, "avro": avro, "split": split, "attr": attr, "lay": lay,
              "post": post, "ok": ok, "warn": warn, "hold": hold, "conns": conns, "label": lab})
    save(d)
    status()


def set_props(pid, props, extra=None):
    p = proc(pid)
    cfg = {"properties": props}
    if extra: cfg.update(extra)
    call("PUT", f"/processors/{pid}", {"revision": p["revision"], "component": {"id": pid, "config": cfg}})


def start():
    d = ids()
    for k in PROCS:
        if k != "hold":
            set_state(d[k], "RUNNING")
    status()


def stop():
    d = ids()
    for k in PROCS:
        set_state(d[k], "STOPPED")
    status()


def status():
    d = ids()
    for k in PROCS:
        c = proc(d[k])["component"]
        print(f"{k:5} {c['state']:8} {c.get('validationStatus')} {c['name']}",
              (c.get("validationErrors") or [""])[0][:300])
    for x in bulletins({d[k] for k in PROCS})[-8:]:
        print("BULLETIN", x["sourceName"], x["message"][:500])


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    d = ids()
    if cmd == "build":
        build()
    elif cmd == "key":
        k = env("EFORM_TDNV_API_KEY_PROD") or sys.exit("thiếu EFORM_TDNV_API_KEY_PROD trong .env")
        st = proc(d["post"])["component"]["state"]
        set_state(d["post"], "STOPPED"); set_props(d["post"], {"X-API-KEY": k}, {"sensitiveDynamicPropertyNames": ["X-API-KEY"]})
        if st == "RUNNING": set_state(d["post"], "RUNNING")
        print("đã ghi khóa")
    elif cmd == "dev":   # 20/11: chuyển sang địa chỉ dev theo gui-doi-nifi-1911.md
        k = env("EFORM_TDNV_API_KEY") or sys.exit("thiếu EFORM_TDNV_API_KEY trong .env")
        p = proc(d["post"])
        bk = os.path.join(_g["REPO"], "backups", "backup_nifi_eform_tdnv_post_20261120_before_dev.json")
        json.dump(p, open(bk, "w"), ensure_ascii=False, indent=1); print("backup", bk)
        st = p["component"]["state"]
        set_state(d["post"], "STOPPED")
        set_props(d["post"], {"Remote URL": URL_DEV, "X-API-KEY": k}, {"sensitiveDynamicPropertyNames": ["X-API-KEY"]})
        if st == "RUNNING": set_state(d["post"], "RUNNING")
        hold_conn = "142f47a3-6ef6-1fc2-a239-6787e73a8916"   # Loi gui Eform -> Giu goi loi
        r = call("POST", f"/flowfile-queues/{hold_conn}/drop-requests")["dropRequest"]
        time.sleep(2); call("DELETE", f"/flowfile-queues/{hold_conn}/drop-requests/{r['id']}")
        print("đã đổi URL →", URL_DEV, "| khóa dev | xóa hàng đợi lỗi cũ")
        status()
    elif cmd == "prod":  # địa chỉ chính thức Eform đưa (prod) + khóa EFORM_TDNV_API_KEY_PROD
        k = env("EFORM_TDNV_API_KEY_PROD") or sys.exit("thiếu EFORM_TDNV_API_KEY_PROD trong .env")
        st = proc(d["post"])["component"]["state"]
        set_state(d["post"], "STOPPED")
        set_props(d["post"], {"Remote URL": URL, "X-API-KEY": k}, {"sensitiveDynamicPropertyNames": ["X-API-KEY"]})
        if st == "RUNNING": set_state(d["post"], "RUNNING")
        print("Remote URL =", proc(d["post"])["component"]["config"]["properties"]["Remote URL"])
        status()
    elif cmd == "sql":
        set_state(d["exe"], "STOPPED"); set_props(d["exe"], exe_props()); set_state(d["exe"], "RUNNING"); print("đã nạp SQL")
    elif cmd == "once":
        set_state(d["gen"], "RUN_ONCE"); time.sleep(20); status()
    elif cmd == "start":
        start()
    elif cmd == "stop":
        stop()
    else:
        status()
