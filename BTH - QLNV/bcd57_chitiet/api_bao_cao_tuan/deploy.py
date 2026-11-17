"""Dựng API báo cáo tuần NQ57 cho app TDNV trên NiFi – 17/11/2026.

  python3 deploy.py build    # tạo group mới "API - TDNV BCD57 Bao cao tuan" (mọi processor STOPPED)
  python3 deploy.py start    # bật context map + toàn bộ processor
  python3 deploy.py test     # tự gọi API từ trong NiFi (InvokeHTTP → localhost) rồi in kết quả, xóa flow thử
  python3 deploy.py sql      # nạp lại bao_cao_tuan.sql vào ReplaceText (sau khi sửa build.py)
  python3 deploy.py stop | status

Gọi API (trong mạng nội bộ, tới máy NiFi):
  GET|POST http://<nifi-host>:9990/bcd57/api/bao-cao-tuan?tu_ngay=2026-11-10&den_ngay=2026-11-16&id_don_vi=490.698.1307
  header  X-Api-Key: <BCD57_API_KEY trong .env của repo>
  POST có thể gửi body JSON {"tu_ngay": "...", "den_ngay": "...", "id_don_vi": "..."} thay cho query string.
  Không truyền den_ngay → hôm nay; không truyền tu_ngay → den_ngay - 6 ngày; id_don_vi rỗng → toàn bộ.
ID lưu ở nifi_ids.json. Chỉ TẠO MỚI, không đụng group/processor đang có.
"""
import json, os, secrets, sys, time, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
_H = "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu/deploy_truong.py"
_g = {"__file__": _H}
exec(open(_H, encoding="utf-8").read().split("if __name__")[0], _g)
call, proc, set_state, delete_proc, bulletins = (_g[k] for k in ("call", "proc", "set_state", "delete_proc", "bulletins"))
REPO_ENV = os.path.join(_g["REPO"], ".env")

PARENT = "0bfb3422-8a21-1e6a-8a1d-f4ecee881205"   # cha của các group "API - …" hiện có
DBCP = "0bfb327e-8a21-1e6a-776c-e17610335bef"     # HaNoi_Datamart (cùng pool với API IOC MBF)
PORT = 9990
PATH = "/bcd57/api/bao-cao-tuan"
IDS = os.path.join(HERE, "nifi_ids.json")
SQL_FILE = os.path.join(HERE, "bao_cao_tuan.sql")
STD = "org.apache.nifi.processors.standard."
ATTR = "org.apache.nifi.processors.attributes.UpdateAttribute"


def ids():
    return json.load(open(IDS)) if os.path.exists(IDS) else {}


def save(d):
    json.dump(d, open(IDS, "w"), ensure_ascii=False, indent=1)


def api_key():
    for line in open(REPO_ENV, encoding="utf-8"):
        if line.startswith("BCD57_API_KEY="):
            return line.split("=", 1)[1].strip()
    k = secrets.token_hex(20)
    with open(REPO_ENV, "a", encoding="utf-8") as f:
        f.write(f"\nBCD57_API_KEY={k}\n")
    print("đã tạo BCD57_API_KEY trong .env")
    return k


def P(g, typ, name, x, y, props=None, auto=None, sched=None):
    cfg = {"properties": props or {}}
    if auto: cfg["autoTerminatedRelationships"] = auto
    if sched: cfg.update(sched)
    return call("POST", f"/process-groups/{g}/processors", {"revision": {"version": 0}, "component": {
        "type": typ, "name": name, "position": {"x": x, "y": y}, "config": cfg}})["id"]


def C(g, src, dst, rels):
    return call("POST", f"/process-groups/{g}/connections", {"revision": {"version": 0}, "component": {
        "source": {"id": src, "groupId": g, "type": "PROCESSOR"},
        "destination": {"id": dst, "groupId": g, "type": "PROCESSOR"},
        "selectedRelationships": rels}})["id"]


def free_position():
    fl = call("GET", f"/flow/process-groups/{PARENT}")["processGroupFlow"]["flow"]
    ys = [x["position"]["y"] for k in ("processGroups", "processors", "labels") for x in fl.get(k, [])]
    xs = [x["position"]["x"] for x in fl.get("processGroups", [])] or [0]
    return {"x": min(xs), "y": (max(ys) if ys else 0) + 250}


def build():
    if ids().get("group"):
        raise SystemExit("đã có: " + json.dumps(ids()))
    key = api_key()
    g = call("POST", f"/process-groups/{PARENT}/process-groups", {"revision": {"version": 0}, "component": {
        "name": "API - TDNV BCD57 Bao cao tuan (20261117)", "position": free_position(),
        "comments": f"API báo cáo tuần NQ57 cho app TDNV. Cổng {PORT}{PATH}. "
                    "SQL: BTH - QLNV/bcd57_chitiet/api_bao_cao_tuan/ (build.py, deploy.py)"}})["id"]
    d = {"group": g}; save(d)
    ctx = call("POST", f"/process-groups/{g}/controller-services", {"revision": {"version": 0}, "component": {
        "type": "org.apache.nifi.http.StandardHttpContextMap", "name": "BCD57 API context",
        "properties": {"Maximum Outstanding Requests": "50", "Request Expiration": "1 min"}}})["id"]
    d["ctx"] = ctx; save(d)

    req = P(g, STD + "HandleHttpRequest", "Nhan yeu cau TDNV", 0, 0, {
        "Listening Port": str(PORT), "Hostname": "0.0.0.0", "HTTP Context Map": ctx, "Allowed Paths": PATH,
        "Allow GET": "true", "Allow POST": "true", "Allow PUT": "false", "Allow DELETE": "false",
        "Allow HEAD": "false", "Allow OPTIONS": "false", "Client Authentication": "No Authentication"},
        sched={"schedulingPeriod": "100 ms"})
    body = P(g, STD + "EvaluateJsonPath", "Doc tham so tu body JSON (neu co)", 0, 200, {
        "Destination": "flowfile-attribute", "Return Type": "scalar", "Path Not Found Behavior": "ignore",
        "Null Value Representation": "empty string",
        "j.tu_ngay": "$.tu_ngay", "j.den_ngay": "$.den_ngay", "j.id_don_vi": "$.id_don_vi"})
    par = P(g, ATTR, "Chuan hoa tham so", 0, 400, {
        "p.den": "${j.den_ngay:replaceEmpty(${http.query.param.den_ngay}):trim():replaceEmpty(${now():format('yyyy-MM-dd')})}",
        "p.tu": "${j.tu_ngay:replaceEmpty(${http.query.param.tu_ngay}):trim()}",
        "p.dv": "${j.id_don_vi:replaceEmpty(${http.query.param.id_don_vi}):trim()}",
        "p.ts": "${now():format('yyyy-MM-dd HH:mm:ss')}",
        "p.key": "${'http.headers.X-Api-Key':replaceEmpty(${'http.headers.x-api-key'})}"})
    rte = P(g, STD + "RouteOnAttribute", "Kiem tra khoa + tham so", 0, 600, route_props(key))
    # rte: unmatched = sai/thiếu khóa
    tu = P(g, ATTR, "Mac dinh tu_ngay = den_ngay - 6", 0, 800, {
        "p.tu": "${p.tu:replaceEmpty(${p.den:toDate('yyyy-MM-dd'):toNumber():minus(518400000):format('yyyy-MM-dd')})}"})
    # SQL đặt trong THUỘC TÍNH (EL thay ${p.*}); không dùng ReplaceText → nội dung flowfile, vì ExecuteSQL
    # đọc nội dung bằng charset mặc định JVM (không phải UTF-8) → hỏng chữ có dấu trong SQL.
    exe = P(g, STD + "ExecuteSQL", "Chay SQL bao cao tuan (build.py)", 0, 1100, exe_props())
    avro = P(g, "org.apache.nifi.processors.avro.ConvertAvroToJSON", "Avro -> JSON", 0, 1400, {
        "JSON container options": "array", "Wrap Single Record": "true"})
    lay = P(g, STD + "EvaluateJsonPath", "Lay o bao_cao lam noi dung", 0, 1600, {
        "Destination": "flowfile-content", "Return Type": "scalar", "Path Not Found Behavior": "ignore",
        "bao_cao": "$[0].bao_cao"})
    ok = P(g, ATTR, "Tra 200", 0, 1800, {"resp.code": "200", "mime.type": "application/json"})
    e401 = P(g, ATTR, "Loi 401 khoa", 600, 600, {"resp.code": "401",
             "resp.msg": "Thiếu hoặc sai header X-Api-Key"})
    e400 = P(g, ATTR, "Loi 400 tham so", 600, 800, {"resp.code": "400",
             "resp.msg": "Tham số không hợp lệ: tu_ngay, den_ngay dạng YYYY-MM-DD; id_don_vi chỉ gồm số và dấu chấm"})
    e500 = P(g, ATTR, "Loi 500 xu ly", 600, 1400, {"resp.code": "500",
             "resp.msg": "${executesql.error.message:replaceEmpty('Lỗi xử lý phía NiFi')}"})
    ejs = P(g, STD + "ReplaceText", "JSON loi", 600, 1800, {
        "Replacement Strategy": "Always Replace", "Regular Expression": "(?s)(^.*$)", "Evaluation Mode": "Entire text",
        "Replacement Value": '{"ma_loi": ${resp.code}, "thong_bao": "${resp.msg:escapeJson()}", "thoi_diem": "${p.ts}"}',
        "Character Set": "UTF-8"}, auto=["failure"])
    mime = P(g, ATTR, "mime json (loi)", 600, 2000, {"mime.type": "application/json"})
    res = P(g, STD + "HandleHttpResponse", "Tra ket qua TDNV", 0, 2200, {
        "HTTP Status Code": "${resp.code}", "HTTP Context Map": ctx,
        "Content-Type": "application/json; charset=UTF-8"}, auto=["success", "failure"])

    conns = [C(g, req, body, ["success"]),
             C(g, body, par, ["matched", "unmatched", "failure"]),
             C(g, par, rte, ["success"]),
             C(g, rte, tu, ["hop_le"]),
             C(g, rte, e400, ["sai_tham_so"]),
             C(g, rte, e401, ["unmatched"]),
             C(g, tu, exe, ["success"]),
             C(g, exe, avro, ["success"]),
             C(g, exe, e500, ["failure"]),
             C(g, avro, lay, ["success"]),
             C(g, avro, e500, ["failure"]),
             C(g, lay, ok, ["matched"]),
             C(g, lay, e500, ["unmatched", "failure"]),
             C(g, ok, res, ["success"]),
             C(g, e401, ejs, ["success"]), C(g, e400, ejs, ["success"]), C(g, e500, ejs, ["success"]),
             C(g, ejs, mime, ["success"]), C(g, mime, res, ["success"])]
    lab = call("POST", f"/process-groups/{g}/labels", {"revision": {"version": 0}, "component": {
        "label": (f"API báo cáo tuần NQ57 cho app TDNV (17/11/2026)\n"
                  f"GET|POST :{PORT}{PATH}?tu_ngay=YYYY-MM-DD&den_ngay=YYYY-MM-DD&id_don_vi=490.x\n"
                  "Header X-Api-Key (BCD57_API_KEY trong .env repo). Trả JSON mục I.1 + phụ lục 01–04\n"
                  "theo DE CUONG BAO CAO TUAN - UPDATE.docx. Nguồn: qlnv_chitiet_captp_xp_bcd57(_full).\n"
                  "Sửa SQL: BTH - QLNV/bcd57_chitiet/api_bao_cao_tuan/build.py → deploy.py sql"),
        "position": {"x": 1200, "y": 0}, "width": 520, "height": 150,
        "style": {"font-size": "12px", "background-color": "#e2f0fd"}}})["id"]
    d.update({"req": req, "body": body, "par": par, "rte": rte, "tu": tu, "exe": exe, "avro": avro,
              "lay": lay, "ok": ok, "e401": e401, "e400": e400, "e500": e500, "ejs": ejs, "mime": mime, "res": res,
              "conns": conns, "label": lab})
    save(d)
    status()


def exe_props():
    return {"Database Connection Pooling Service": DBCP, "SQL select query": open(SQL_FILE, encoding="utf-8").read(),
            "Max Wait Time": "45 seconds", "dbf-normalize": "false", "dbf-user-logical-types": "false",
            "esql-auto-commit": "true"}


def migrate_no_replacetext():
    """17/11: bỏ ReplaceText 'sql', đưa SQL vào thuộc tính ExecuteSQL (lỗi charset)."""
    d = ids(); g = d["group"]
    if not d.get("sql"):
        return print("đã migrate")
    for k in ("tu", "sql", "exe", "e500"):
        set_state(d[k], "STOPPED")
    time.sleep(2)
    fl = call("GET", f"/flow/process-groups/{g}")["processGroupFlow"]["flow"]
    for cn in fl["connections"]:
        c = cn["component"]
        if d["sql"] in (c["source"]["id"], c["destination"]["id"]):
            x = call("GET", f"/connections/{c['id']}")
            if x["status"]["aggregateSnapshot"]["flowFilesQueued"]:
                call("POST", f"/flowfile-queues/{c['id']}/drop-requests"); time.sleep(1.5)
                x = call("GET", f"/connections/{c['id']}")
            call("DELETE", f"/connections/{c['id']}?version={x['revision']['version']}")
    delete_proc(d.pop("sql"))
    _g["update_props"](d["exe"], name="Chay SQL bao cao tuan (build.py)", props=exe_props())
    if not any(cn["component"]["source"]["id"] == d["tu"] for cn in fl["connections"]
               if cn["component"]["destination"]["id"] == d["exe"]):
        C(g, d["tu"], d["exe"], ["success"])
    fl = call("GET", f"/flow/process-groups/{g}")["processGroupFlow"]["flow"]
    d["conns"] = [cn["id"] for cn in fl["connections"]]
    save(d)
    for k in ("e500", "exe", "tu"):
        set_state(d[k], "RUNNING")
    print("migrate xong")


def fix_route():
    """17/11: sai_tham_so = khóa đúng AND NOT(tham số đúng) (bản đầu bị NOT cả cụm → sai khóa ra 400)."""
    d = ids(); key = api_key()
    set_state(d["rte"], "STOPPED"); time.sleep(1)
    _g["update_props"](d["rte"], props=route_props(key))
    set_state(d["rte"], "RUNNING"); print("đã sửa RouteOnAttribute")


def route_props(key):
    D = "'^\\d{4}-\\d{2}-\\d{2}$'"
    # tham số hợp lệ (biểu thức con, lồng được vào :and(...)); bản phủ định thêm :not() trước dấu } cuối
    ok_par = (f"${{p.den:matches({D}):and(${{p.tu:isEmpty():or(${{p.tu:matches({D})}})}})"
              f":and(${{p.dv:matches('^[0-9.]{{0,100}}$')}})}}")
    bad_par = ok_par[:-1] + ":not()}"
    return {"Routing Strategy": "Route to Property name",
            "hop_le": f"${{p.key:equals('{key}'):and({ok_par})}}",
            "sai_tham_so": f"${{p.key:equals('{key}'):and({bad_par})}}"}


PROCS = ("req", "body", "par", "rte", "tu", "exe", "avro", "lay", "ok", "e401", "e400", "e500", "ejs", "mime", "res")


def cs_state(cid, state):
    c = call("GET", f"/controller-services/{cid}")
    if c["component"]["state"] != state:
        call("PUT", f"/controller-services/{cid}/run-status", {"revision": c["revision"], "state": state})
        for _ in range(20):
            time.sleep(1)
            if call("GET", f"/controller-services/{cid}")["component"]["state"] == state:
                break


def start():
    d = ids()
    cs_state(d["ctx"], "ENABLED")
    for k in PROCS[::-1]:
        set_state(d[k], "RUNNING")
    time.sleep(3); status()


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
    b = bulletins({d[k] for k in PROCS})
    for x in b[-5:]:
        print("BULLETIN", x["sourceName"], x["message"][:400])


def update_sql():
    d = ids()
    set_state(d["exe"], "STOPPED"); time.sleep(1)
    _g["update_props"](d["exe"], props={"SQL select query": open(SQL_FILE, encoding="utf-8").read()})
    set_state(d["exe"], "RUNNING"); print("đã nạp lại SQL")


def test(cases=None):
    """InvokeHTTP tạm trong group gọi localhost, lấy body phản hồi từ hàng đợi, rồi xóa."""
    d = ids(); g = d["group"]; key = api_key()
    cases = cases or [
        ("ok", f"?tu_ngay=2026-11-10&den_ngay=2026-11-16", key, "GET", ""),
        ("donvi", f"?den_ngay=2026-11-16&id_don_vi=490.698.1307.1352", key, "GET", ""),
        ("post", "", key, "POST", '{"tu_ngay":"2026-11-10","den_ngay":"2026-11-16","id_don_vi":"490.698.1307.1352"}'),
        ("sai_khoa", "?den_ngay=2026-11-16", "sai", "GET", ""),
        ("sai_ts", "?den_ngay=16/11/2026", key, "GET", ""),
        ("tiem", "?id_don_vi=1'%20OR%20'1'='1", key, "GET", ""),
    ]
    tmp = []
    try:
        for i, (name, qs, k, method, body) in enumerate(cases):
            gff = P(g, STD + "GenerateFlowFile", f"TMP test {name}", 1800, 300 + i * 160,
                    {"generate-ff-custom-text": body or "-", "Data Format": "Text"},  # GFF không nhận chuỗi rỗng
                    sched={"schedulingPeriod": "1 day"})
            inv = P(g, STD + "InvokeHTTP", f"TMP goi {name}", 2200, 300 + i * 160, {
                "HTTP Method": method, "Remote URL": f"http://localhost:{PORT}{PATH}{qs}",
                "X-Api-Key": k, "Content-Type": "application/json", "Always Output Response": "true"},
                auto=["Original"])
            tmp += [gff, inv]
            c1 = C(g, gff, inv, ["success"])
            hold = P(g, ATTR, f"TMP giu {name}", 2600, 300 + i * 160)  # STOPPED → giữ phản hồi trong hàng đợi
            tmp.append(hold)
            q = C(g, inv, hold, ["Response", "No Retry", "Retry", "Failure"])
            tmp.append(("conn", c1)); tmp.append(("conn", q))
            set_state(inv, "RUNNING"); set_state(gff, "RUN_ONCE")
            for _ in range(60):
                time.sleep(1)
                if call("GET", f"/connections/{q}")["status"]["aggregateSnapshot"]["flowFilesQueued"]:
                    break
            lr = call("POST", f"/flowfile-queues/{q}/listing-requests")["listingRequest"]
            for _ in range(10):
                lr = call("GET", f"/flowfile-queues/{q}/listing-requests/{lr['id']}")["listingRequest"]
                if lr["finished"]: break
                time.sleep(0.5)
            if not lr.get("flowFileSummaries"):
                print(f"[{name}] không có phản hồi"); continue
            ff = max(lr["flowFileSummaries"], key=lambda f: f["size"])  # phản hồi, không phải bản gốc "-"
            det = call("GET", f"/flowfile-queues/{q}/flowfiles/{ff['uuid']}")["flowFile"]["attributes"]
            raw = call("GET", f"/flowfile-queues/{q}/flowfiles/{ff['uuid']}/content", raw=True)
            open(os.path.join(HERE, f"test_{name}.json"), "wb").write(raw)
            body_txt = raw.decode("utf-8", "replace")
            short = body_txt[:300].replace("\n", " ")
            print(f"[{name}] HTTP {det.get('invokehttp.status.code')} {det.get('mime.type')} | {len(body_txt)} ký tự | {short}")
            call("DELETE", f"/flowfile-queues/{q}/listing-requests/{lr['id']}")
            call("POST", f"/flowfile-queues/{q}/drop-requests"); time.sleep(1)
            set_state(inv, "STOPPED")
    finally:
        cleanup()


def cleanup():
    """Dọn mọi processor 'TMP …' trong group API (kèm connection của chúng)."""
    g = ids()["group"]
    fl = call("GET", f"/flow/process-groups/{g}")["processGroupFlow"]["flow"]
    tmp = {p["id"] for p in fl["processors"] if p["component"]["name"].startswith("TMP ")}
    for pid in tmp:
        if proc(pid)["component"]["state"] == "RUNNING":
            set_state(pid, "STOPPED")
    time.sleep(2)
    for cn in fl["connections"]:
        c = cn["component"]
        if c["source"]["id"] in tmp or c["destination"]["id"] in tmp:
            cid = c["id"]
            x = call("GET", f"/connections/{cid}")
            if x["status"]["aggregateSnapshot"]["flowFilesQueued"]:
                call("POST", f"/flowfile-queues/{cid}/drop-requests"); time.sleep(1.5); x = call("GET", f"/connections/{cid}")
            call("DELETE", f"/connections/{cid}?version={x['revision']['version']}")
    for pid in tmp:
        delete_proc(pid)
    print("đã xóa", len(tmp), "processor TMP")


if __name__ == "__main__":
    {"build": build, "start": start, "stop": stop, "status": status, "test": test, "sql": update_sql,
     "cleanup": cleanup, "migrate": migrate_no_replacetext, "fix_route": fix_route}[sys.argv[1]]()
