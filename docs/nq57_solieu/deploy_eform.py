"""Đồng bộ 2 view eForm NQ57 (bao_cao.dashboard.chuyen_de_chi_tiet_nq57, cach_tinh_chi_so_nq57)
về datamart_hanoi, giữ nguyên 1-1 (chưa chuẩn hóa) để kiểm tra. Group NiFi "Chuyên đề lớn". 18/11/2026

  python3 deploy_eform.py probe "SELECT ..."   # chạy 1 câu trên PG bao_cao qua NiFi, in kết quả (processor tạm, tự gỡ)
  python3 deploy_eform.py backup
  python3 deploy_eform.py ddl                  # tạo bảng từ 7_ddl_eform.sql
  python3 deploy_eform.py build                # nhân bản chuỗi nq57_solieu x2, nối GFF 5' + funnel
  python3 deploy_eform.py test | cleanup | status
ID lưu ở nifi_eform_ids.json.
"""
import json, os, re, sys, time
import deploy_truong as d

HERE = d.HERE
d.IDS_FILE = os.path.join(HERE, "nifi_eform_ids.json")
d.BR = {
    "eform_chuyen_de": {"x": 3350, "sql": "8_select_eform_chuyen_de_pg.sql", "pool": None},
    "eform_cach_tinh": {"x": 3950, "sql": "9_select_eform_cach_tinh_pg.sql", "pool": None},
}


def probe(sql):
    flow = d.call("GET", f"/flow/process-groups/{d.G}")["processGroupFlow"]["flow"]
    SRC = "142f46a0-6ef6-1fc2-e9c1-4568a66a65db"  # Doc nq57_eform_chuyen_de (PG bao_cao); nhánh cũ đã gỡ 18/11
    rev = {p["id"]: p["revision"] for p in flow["processors"]}[SRC]
    snip = d.call("POST", "/snippets", {"snippet": {"parentGroupId": d.G, "processors": {SRC: rev}}})
    res = d.call("POST", f"/process-groups/{d.G}/snippet-instance",
                 {"snippetId": snip["snippet"]["id"], "originX": 3350, "originY": -400})
    esr = res["flow"]["processors"][0]["id"]
    fun = d.call("POST", f"/process-groups/{d.G}/funnels",
                 {"revision": {"version": 0}, "component": {"position": {"x": 3350, "y": -150}}})["id"]
    gff = d.new_gff("TMP probe eform", 3350, -600, {"sync_ts": "2000-01-01 00:00:00"})
    d.update_props(esr, "TMP probe eform", {"SQL select query": sql})
    c1 = d.connect(gff, esr, ["success"])
    c2 = d.connect(esr, fun, ["success"], "FUNNEL")
    c3 = d.connect(esr, fun, ["failure"], "FUNNEL")
    try:
        d.set_state(esr, "RUNNING"); d.set_state(gff, "RUN_ONCE")
        for _ in range(40):
            q = {c: d.call("GET", f"/connections/{c}")["status"]["aggregateSnapshot"]["flowFilesQueued"] for c in (c2, c3)}
            if any(q.values()):
                break
            time.sleep(1)
        print("queued:", q)
        for c in (c2, c3):
            if not q[c]:
                continue
            lr = d.call("POST", f"/flowfile-queues/{c}/listing-requests")["listingRequest"]
            time.sleep(1)
            lr = d.call("GET", f"/flowfile-queues/{c}/listing-requests/{lr['id']}")["listingRequest"]
            for ff in lr.get("flowFileSummaries", []):
                if c == c3:
                    det = d.call("GET", f"/flowfile-queues/{c}/flowfiles/{ff['uuid']}")["flowFile"]
                    print("FAILURE attrs:", {k: v for k, v in det["attributes"].items() if "error" in k.lower() or "exec" in k.lower()})
                body = d.call("GET", f"/flowfile-queues/{c}/flowfiles/{ff['uuid']}/content", raw=True)
                print(body.decode("utf-8", "replace")[:20000])
            d.call("DELETE", f"/flowfile-queues/{c}/listing-requests/{lr['id']}")
        for b in d.bulletins({esr}):
            print("BULLETIN", b["message"][:500])
    finally:
        d.set_state(esr, "STOPPED"); time.sleep(1)
        for c in (c1, c2, c3):
            d.delete_conn(c)
        d.delete_proc(gff); d.delete_proc(esr)
        f = d.call("GET", f"/funnels/{fun}")
        d.call("DELETE", f"/funnels/{fun}?version={f['revision']['version']}")


def backup():
    out = os.path.join(d.REPO, "backups", "backup_nifi_chuyendelon_20261118_before_eform.json")
    open(out, "wb").write(d.call("GET", f"/process-groups/{d.G}/download", raw=True))
    print("backup ->", out, os.path.getsize(out), "bytes")


def ddl():
    txt = open(os.path.join(HERE, "7_ddl_eform.sql"), encoding="utf-8").read()
    stmts = [s.strip().rstrip(";") for s in re.split(r"^-- \[\d\]\s*$", txt, flags=re.M)[1:]]
    for i, s in enumerate(stmts, 1):
        gid = d.new_gff(f"TMP DDL eform {i}", 3350, -200, {"generate-ff-custom-text": s, "Data Format": "Text"})
        cid = d.connect(gid, d.PUTSQL, ["success"])
        d.set_state(gid, "RUN_ONCE")
        ok = d.wait_queue(cid, 60); time.sleep(2)
        print(f"DDL {i}: drained={ok}", [b["message"][:300] for b in d.bulletins({d.PUTSQL})][-3:])
        d.delete_conn(cid); d.delete_proc(gid)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "probe":
        probe(sys.argv[2])
    else:
        {"backup": backup, "ddl": ddl, "build": d.build, "test": d.test, "cleanup": d.cleanup,
         "status": d.status}[cmd]()
