"""Luồng NiFi so khớp nhiệm vụ phụ lục <-> QLNV -> datamart_hanoi.chuyen_de_chi_tiet_nhiem_vu_nq57.
Nằm trong process group 'NQ57 - chuyen_de_chi_tiet_nq57 (BC tháng)', bên phải luồng nạp chỉ số.

  python nifi_flow.py tao       # tạo processor (1 lần), lưu id vào nifi_flow_ids.json
  python nifi_flow.py chay      # cập nhật SQL từ 0_ddl.sql + 1_so_khop.sql, chạy 1 lần, in kết quả kiểm tra
  python nifi_flow.py lich      # bật chạy hằng ngày 07:00 (cập nhật trạng thái task QLNV)
"""
import json, os, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "trich_xuat"))
from nifi import call, rev, set_state  # noqa: E402

W = os.path.dirname(os.path.abspath(__file__))
IDS = os.path.join(W, "nifi_flow_ids.json")
G = "142f3d9a-6ef6-1fc2-3dd8-717285e6326b"
POOL = "acf51838-116f-119e-c09b-1b31f6c8d1ae"     # HN-Datamart-NEW
WRITER = "0bfb327a-8a21-1e6a-c8ee-10be802ba0b8"   # JsonRecordSetWriter
R0 = {"version": 0, "clientId": "claude-cdnq57"}
TEN_GEN = "CDNQ57 NV - SQL so khop phu luc voi QLNV"
TEN_CHK = "CDNQ57 NV - Kiem tra ket qua map"
CRON = "0 0 7 * * ?"

CHECK_SQL = """SELECT ky, COUNT(DISTINCT thu_tu) AS nv_phu_luc,
       COUNT(DISTINCT CASE WHEN co_khop = 1 THEN thu_tu END) AS nv_map_duoc,
       COUNT(DISTINCT CASE WHEN so_nhiem_vu_khop > 1 THEN thu_tu END) AS nv_khop_nhieu,
       SUM(co_khop) AS so_task, MAX(sync_date) AS sync_date
FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nhiem_vu_nq57` GROUP BY ky, thu_tu_ky ORDER BY thu_tu_ky"""


def sql():
    tao_lai = "DROP TABLE IF EXISTS `datamart_hanoi`.`chuyen_de_chi_tiet_nhiem_vu_nq57`;\n" if os.environ.get("TAO_LAI") else ""
    return tao_lai + open(os.path.join(W, "0_ddl.sql")).read() + "\n" + open(os.path.join(W, "1_so_khop.sql")).read()


def tao():
    def proc(type_, name, x, y, props, sched="0 sec", strat="TIMER_DRIVEN"):
        return call("POST", f"/process-groups/{G}/processors", {"revision": R0, "component": {
            "type": type_, "name": name, "position": {"x": x, "y": y},
            "config": {"properties": props, "schedulingStrategy": strat, "schedulingPeriod": sched}}})["id"]

    def conn(src, dst, rels, dst_type="PROCESSOR"):
        call("POST", f"/process-groups/{G}/connections", {"revision": R0, "component": {
            "source": {"id": src, "groupId": G, "type": "PROCESSOR"},
            "destination": {"id": dst, "groupId": G, "type": dst_type}, "selectedRelationships": rels}})

    X = 900
    call("POST", f"/process-groups/{G}/labels", {"revision": R0, "component": {
        "position": {"x": X, "y": -120}, "width": 760, "height": 90,
        "label": "SO KHỚP NHIỆM VỤ PHỤ LỤC <-> QLNV -> chuyen_de_chi_tiet_nhiem_vu_nq57\n"
                 "Tiêu đề QLNV chứa đoạn giữa tiêu đề phụ lục => lấy task. Chạy 07:00 hằng ngày.\n"
                 "SQL: bcd57_chitiet/chuyen_de/sql/nhiem_vu/ (trich_phu_luc.py -> build_sql.py -> nifi_flow.py chay)"}})
    gen = proc("org.apache.nifi.processors.standard.GenerateFlowFile", TEN_GEN, X, 0, {
        "generate-ff-custom-text": sql(), "Batch Size": "1", "Data Format": "Text", "Unique FlowFiles": "false",
        "character-set": "UTF-8", "mime-type": "text/plain"}, sched=CRON, strat="CRON_DRIVEN")
    put = proc("org.apache.nifi.processors.standard.PutSQL", "CDNQ57 NV - PutSQL chuyen_de_chi_tiet_nhiem_vu_nq57", X, 240, {
        "JDBC Connection Pool": POOL, "Batch Size": "1", "Support Fragmented Transactions": "false",
        "rollback-on-failure": "false"})
    chk = proc("org.apache.nifi.processors.standard.ExecuteSQLRecord", TEN_CHK, X, 480, {
        "Database Connection Pooling Service": POOL, "SQL select query": CHECK_SQL, "esqlrecord-record-writer": WRITER})
    f_ok = call("POST", f"/process-groups/{G}/funnels", {"revision": R0, "component": {"position": {"x": X + 180, "y": 720}}})["id"]
    f_err = call("POST", f"/process-groups/{G}/funnels", {"revision": R0, "component": {"position": {"x": X + 600, "y": 300}}})["id"]
    conn(gen, put, ["success"])
    conn(put, chk, ["success"])
    conn(put, f_err, ["failure", "retry"], "FUNNEL")
    conn(chk, f_ok, ["success"], "FUNNEL")
    conn(chk, f_err, ["failure"], "FUNNEL")
    ids = {"pg": G, "gen": gen, "put": put, "chk": chk, "funnel_ok": f_ok, "funnel_err": f_err}
    json.dump(ids, open(IDS, "w"), indent=1)
    print(ids)


def _queues(ids):
    s = call("GET", f"/flow/process-groups/{ids['pg']}/status")["processGroupStatus"]["aggregateSnapshot"]
    out = {}
    for c in s["connectionStatusSnapshots"]:
        c = c["connectionStatusSnapshot"]
        out[(c["sourceName"], c["name"])] = (c["flowFilesQueued"], c["id"])
    return out


def _doc_queue(cid):
    lr = call("POST", f"/flowfile-queues/{cid}/listing-requests")
    for _ in range(10):
        time.sleep(1)
        lr = call("GET", f"/flowfile-queues/{cid}/listing-requests/{lr['listingRequest']['id']}")
        if lr["listingRequest"]["finished"]:
            break
    ff = lr["listingRequest"]["flowFileSummaries"][-1]["uuid"]
    return call("GET", f"/flowfile-queues/{cid}/flowfiles/{ff}/content", raw=True).decode()


def chay():
    ids = json.load(open(IDS))
    p = call("GET", f"/processors/{ids['gen']}")
    was = p["component"]["state"]
    if was == "RUNNING":
        set_state(ids["gen"], "STOPPED")
        p = call("GET", f"/processors/{ids['gen']}")
    call("PUT", f"/processors/{ids['gen']}", {"revision": rev(p), "component": {
        "id": ids["gen"], "config": {"properties": {"generate-ff-custom-text": sql()}}}})
    for k in ("put", "chk"):
        if call("GET", f"/processors/{ids[k]}")["component"]["state"] != "RUNNING":
            set_state(ids[k], "RUNNING")
    set_state(ids["gen"], "RUN_ONCE")
    ok = err = None
    for _ in range(100):
        time.sleep(3)
        q = _queues(ids)
        ok = next(v for (s, n), v in q.items() if s == TEN_CHK and n == "success")
        err = [(s, v) for (s, n), v in q.items() if "failure" in n and v[0]]
        if ok[0] or err:
            break
    if was == "RUNNING":
        set_state(ids["gen"], "RUNNING")
    if err:
        for s, (n, cid) in err:
            print("LOI tai", s, "- so flowfile:", n, "- xem bulletin trong NiFi")
        b = call("GET", f"/flow/bulletin-board?groupId={ids['pg']}&limit=5")["bulletinBoard"]["bulletins"]
        for x in b:
            print(" ", (x.get("bulletin") or {}).get("message", "")[:1500])
        return
    rows = json.loads(_doc_queue(ok[1]))
    call("POST", f"/flowfile-queues/{ok[1]}/drop-requests")
    for r in rows:
        print(r)
    print("TONG nv phu luc", sum(int(r["nv_phu_luc"]) for r in rows), "| map duoc", sum(int(r["nv_map_duoc"]) for r in rows),
          "| khop nhieu", sum(int(r["nv_khop_nhieu"]) for r in rows), "| so task", sum(int(r["so_task"]) for r in rows))


def lich():
    ids = json.load(open(IDS))
    for k in ("put", "chk", "gen"):
        if call("GET", f"/processors/{ids[k]}")["component"]["state"] != "RUNNING":
            set_state(ids[k], "RUNNING")
    print("da bat lich", CRON)


if __name__ == "__main__":
    {"tao": tao, "chay": chay, "lich": lich}[sys.argv[1]]()
