"""Deploy 2 nhánh NQ57 theo trường vào group NiFi "Chuyên đề lớn" (142f3c52). 16/11/2026

  python3 deploy_truong.py backup   # tải flow definition của group -> backups/
  python3 deploy_truong.py ddl      # tạo 3 GFF tạm (CREATE TABLE x2 + VIEW) -> PutSQL có sẵn, Run Once, rồi gỡ
  python3 deploy_truong.py build    # nhân bản chuỗi nq57_solieu x2 (STOPPED), sửa SQL/bảng, nối GFF 30' + funnel
  python3 deploy_truong.py test     # GFF tạm có sync_ts -> 2 ExecuteSQLRecord mới, bật chuỗi, Run Once
  python3 deploy_truong.py cleanup  # gỡ GFF test
  python3 deploy_truong.py status   # hàng đợi + bulletin của các processor mới
ID mới lưu ở nifi_truong_ids.json.
"""
import http.cookiejar, json, os, re, ssl, sys, time, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
ENV = {}
for line in open(os.path.join(REPO, ".env")):
    if "=" in line and not line.startswith("#"):
        k, v = line.strip().split("=", 1)
        ENV[k] = v.strip().strip('"')
CTX = ssl.create_default_context(); CTX.check_hostname = False; CTX.verify_mode = ssl.CERT_NONE
BASE = ENV["NIFI_URL"].rstrip("/")
BASE = BASE[:-5] if BASE.endswith("/nifi") else BASE
API = BASE + "/nifi-api"
CJ = http.cookiejar.CookieJar()
OP = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CJ), urllib.request.HTTPSHandler(context=CTX))
TOK = OP.open(urllib.request.Request(API + "/access/token", data=urllib.parse.urlencode(
    {"username": ENV["NIFI_USERNAME"], "password": ENV["NIFI_PASSWORD"]}).encode()), timeout=30).read().decode()
RT = next((c.value for c in CJ if c.name == "__Secure-Request-Token"), "")

G = "142f3c52-6ef6-1fc2-a385-be4d090930e0"
GFF30 = "142f3c8d-6ef6-1fc2-c5ea-24a1c5b0024f"
PUTSQL = "142f3c8f-6ef6-1fc2-c0b7-3261d37af1c3"
FUNNEL = "142f3c8e-6ef6-1fc2-364e-706cbf92c2d8"
SRC_CHAIN = ["142f3c90-6ef6-1fc2-3bc6-3dc39d9ccf1b",  # Doc nq57_solieu (PG)
             "142f3c91-6ef6-1fc2-c759-6a39ec6ec338",  # Co du lieu?
             "142f3c92-6ef6-1fc2-04d0-e54138d0a554",  # Upsert
             "142f3c93-6ef6-1fc2-2ac6-5733bf14673e"]  # SQL xoa dong cu
POOL_BIEU_MAU = "142f3c68-6ef6-1fc2-854e-1f92588c3218"
IDS_FILE = os.path.join(HERE, "nifi_truong_ids.json")
BR = {  # nhánh mới
    "solieu_truong": {"x": 2150, "sql": "5_select_solieu_truong_pg.sql", "pool": None},
    "truong": {"x": 2750, "sql": "6_select_truong_pg.sql", "pool": POOL_BIEU_MAU},
}


def call(method, path, body=None, raw=False):
    h = {"Authorization": "Bearer " + TOK, "Origin": BASE, "Referer": BASE + "/nifi/", "Request-Token": RT}
    data = None
    if body is not None:
        data = json.dumps(body).encode(); h["Content-Type"] = "application/json"
    try:
        r = OP.open(urllib.request.Request(API + path, data=data, method=method, headers=h), timeout=120).read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:1500]}")
    return r if raw else (json.loads(r) if r else None)


def load_ids():
    return json.load(open(IDS_FILE)) if os.path.exists(IDS_FILE) else {}


def save_ids(d):
    json.dump(d, open(IDS_FILE, "w"), ensure_ascii=False, indent=1)


def proc(pid):
    return call("GET", f"/processors/{pid}")


def set_state(pid, state):
    p = proc(pid)
    return call("PUT", f"/processors/{pid}/run-status", {"revision": p["revision"], "state": state})


def update_props(pid, name=None, props=None, extra=None):
    p = proc(pid)
    comp = {"id": pid}
    if name: comp["name"] = name
    cfg = {}
    if props: cfg["properties"] = props
    if extra: cfg.update(extra)
    if cfg: comp["config"] = cfg
    return call("PUT", f"/processors/{pid}", {"revision": p["revision"], "component": comp})


def connect(src, dst, rels, dst_type="PROCESSOR"):
    c = call("POST", f"/process-groups/{G}/connections", {"revision": {"version": 0}, "component": {
        "source": {"id": src, "groupId": G, "type": "PROCESSOR"},
        "destination": {"id": dst, "groupId": G, "type": dst_type},
        "selectedRelationships": rels}})
    return c["id"]


def delete_conn(cid):
    c = call("GET", f"/connections/{cid}")
    if c["status"]["aggregateSnapshot"]["flowFilesQueued"]:
        call("POST", f"/flowfile-queues/{cid}/drop-requests"); time.sleep(2)
        c = call("GET", f"/connections/{cid}")
    dst = c["component"]["destination"]
    restart = dst["type"] == "PROCESSOR" and proc(dst["id"])["component"]["state"] == "RUNNING"
    if restart:
        set_state(dst["id"], "STOPPED"); time.sleep(2)
    try:
        call("DELETE", f"/connections/{cid}?version={c['revision']['version']}")
    finally:
        if restart:
            set_state(dst["id"], "RUNNING")
            print("  (đã dừng/bật lại", dst["name"], ")")


def delete_proc(pid):
    p = proc(pid)
    if p["component"]["state"] == "RUNNING":
        set_state(pid, "STOPPED"); time.sleep(1); p = proc(pid)
    call("DELETE", f"/processors/{pid}?version={p['revision']['version']}")


def new_gff(name, x, y, props):
    p = call("POST", f"/process-groups/{G}/processors", {"revision": {"version": 0}, "component": {
        "type": "org.apache.nifi.processors.standard.GenerateFlowFile", "name": name,
        "position": {"x": x, "y": y},
        "config": {"schedulingPeriod": "1 day", "properties": props}}})
    return p["id"]


def wait_queue(cid, sec=60):
    for _ in range(sec):
        c = call("GET", f"/connections/{cid}")
        if not c["status"]["aggregateSnapshot"]["flowFilesQueued"]:
            return True
        time.sleep(1)
    return False


def bulletins(ids):
    b = call("GET", "/flow/bulletin-board?limit=200")["bulletinBoard"]["bulletins"]
    return [x["bulletin"] for x in b if x.get("sourceId") in ids and "bulletin" in x]


# ---------------------------------------------------------------- steps
def backup():
    out = os.path.join(REPO, "backups", "backup_nifi_chuyendelon_20261116_before_truong.json")
    open(out, "wb").write(call("GET", f"/process-groups/{G}/download", raw=True))
    print("backup ->", out, os.path.getsize(out), "bytes")


def ddl():
    txt = open(os.path.join(HERE, "4_ddl_truong.sql"), encoding="utf-8").read()
    stmts = [s.strip().rstrip(";") for s in re.split(r"^-- \[\d\]\s*$", txt, flags=re.M)[1:]]
    assert len(stmts) == 3, len(stmts)
    for i, s in enumerate(stmts, 1):
        gid = new_gff(f"TMP DDL truong {i}", 2150, -200, {"generate-ff-custom-text": s, "Data Format": "Text"})
        cid = connect(gid, PUTSQL, ["success"])
        set_state(gid, "RUN_ONCE")
        ok = wait_queue(cid, 60)
        time.sleep(2)
        print(f"DDL {i}: queue drained={ok}; bulletins PutSQL:",
              [b["message"][:300] for b in bulletins({PUTSQL})][-3:])
        delete_conn(cid); delete_proc(gid)


def build():
    ids = load_ids()
    if ids.get("branches"):
        raise SystemExit("đã build rồi: " + json.dumps(ids))
    flow = call("GET", f"/flow/process-groups/{G}")["processGroupFlow"]["flow"]
    revs = {p["id"]: p["revision"] for p in flow["processors"]}
    inner = {c["id"]: c["revision"] for c in flow["connections"]
             if c["component"]["source"]["id"] in SRC_CHAIN and c["component"]["destination"]["id"] in SRC_CHAIN}
    assert len(inner) == 3, inner
    ids["branches"] = {}
    for key, cfg in BR.items():
        snip = call("POST", "/snippets", {"snippet": {"parentGroupId": G,
                    "processors": {pid: revs[pid] for pid in SRC_CHAIN}, "connections": inner}})
        res = call("POST", f"/process-groups/{G}/snippet-instance",
                   {"snippetId": snip["snippet"]["id"], "originX": cfg["x"], "originY": 192})
        procs = {p["component"]["name"]: p["id"] for p in res["flow"]["processors"]}
        esr = procs["NQ57 - Doc nq57_solieu (PG)"]; rt = procs["NQ57 - Co du lieu nq57_solieu?"]
        pdr = procs["NQ57 - Upsert nq57_solieu"]; rtx = procs["NQ57 - SQL xoa dong cu nq57_solieu"]
        tbl = f"nq57_{key}"
        sql = open(os.path.join(HERE, cfg["sql"]), encoding="utf-8").read().strip()
        p = {"SQL select query": sql}
        if cfg["pool"]: p["Database Connection Pooling Service"] = cfg["pool"]
        update_props(esr, f"NQ57 - Doc {tbl} (PG)", p)
        update_props(rt, f"NQ57 - Co du lieu {tbl}?")
        update_props(pdr, f"NQ57 - Upsert {tbl}", {"put-db-record-table-name": tbl})
        update_props(rtx, f"NQ57 - SQL xoa dong cu {tbl}",
                     {"Replacement Value": f"DELETE FROM `datamart_hanoi`.`{tbl}` WHERE sync_date < '${{sync_ts}}'"})
        conns = [connect(GFF30, esr, ["success"]), connect(rtx, PUTSQL, ["success"]),
                 connect(esr, FUNNEL, ["failure"], "FUNNEL"), connect(pdr, FUNNEL, ["failure", "retry"], "FUNNEL"),
                 connect(rtx, FUNNEL, ["failure"], "FUNNEL")]
        ids["branches"][key] = {"table": tbl, "esr": esr, "route": rt, "upsert": pdr, "replace": rtx,
                                "inner_conns": [c["id"] for c in res["flow"]["connections"]], "conns": conns}
        save_ids(ids)
        print(key, json.dumps(ids["branches"][key], indent=1))


def test():
    ids = load_ids()
    br = ids["branches"]
    allp = [v for b in br.values() for v in (b["route"], b["upsert"], b["replace"])]
    for pid in allp:
        set_state(pid, "RUNNING")
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    gid = new_gff("TMP test NQ57 truong", 2450, -200, {"sync_ts": ts})
    cs = [connect(gid, b["esr"], ["success"]) for b in br.values()]
    for b in br.values():
        set_state(b["esr"], "RUNNING")
    set_state(gid, "RUN_ONCE")
    ids["test"] = {"gff": gid, "conns": cs, "sync_ts": ts}
    save_ids(ids)
    print("test sync_ts =", ts)
    time.sleep(45)
    status()


def cleanup():
    ids = load_ids()
    t = ids.pop("test", None)
    if t:
        for c in t["conns"]:
            delete_conn(c)
        delete_proc(t["gff"])
    save_ids(ids)
    print("cleanup ok")


def status():
    ids = load_ids()
    watch = set()
    for k, b in ids["branches"].items():
        for role in ("esr", "route", "upsert", "replace"):
            p = proc(b[role]); watch.add(b[role])
            s = p["status"]["aggregateSnapshot"]
            print(f"{k:14} {role:8} {p['component']['state']:8} in={s['flowFilesIn']} out={s['flowFilesOut']} task={s['taskCount']} {p['component']['validationStatus']}")
    for c in [c for b in ids["branches"].values() for c in b["conns"]]:
        s = call("GET", f"/connections/{c}")["status"]["aggregateSnapshot"]
        if s["flowFilesQueued"]:
            print("QUEUED", s["sourceName"], "->", s["destinationName"], s["queued"])
    for b in bulletins(watch | {PUTSQL}):
        print("BULLETIN", b["sourceName"], b["level"], b["message"][:400])


if __name__ == "__main__":
    {"backup": backup, "ddl": ddl, "build": build, "test": test, "cleanup": cleanup, "status": status}[sys.argv[1]]()
