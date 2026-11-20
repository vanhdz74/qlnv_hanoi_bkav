"""18/11/2026 - Gỡ 5 nhánh cũ trong group NiFi "Chuyên đề lớn" (chuyên đề chỉ còn dùng 2 bảng eForm)
và DROP các bảng/view datamart không còn dùng.

  python3 go_nhanh_cu.py check   -> in danh sách sẽ gỡ (không ghi)
  python3 go_nhanh_cu.py nifi    -> backup group + gỡ processor/connection
  python3 go_nhanh_cu.py drop    -> backup dữ liệu bảng (JSON) + DROP qua PutSQL
"""
import json, os, sys, time
import deploy_truong as d

# Processor của 5 nhánh (id đầy đủ lấy từ group, khớp theo tiền tố) - KHÔNG gồm GFF 5' dùng chung và PutSQL dùng chung
PREFIX = [
    "142f3c90", "142f3c91", "142f3c92", "142f3c93",  # nq57_solieu
    "142f4466", "142f4467", "142f4468", "142f4469",  # nq57_solieu_truong
    "142f4473", "142f4474", "142f4475", "142f4476",  # nq57_truong
    "142f3c9c", "142f3c9d", "142f3c9e", "142f3c9f",  # nq57_chitieu
    "142f448d", "142f448e",                          # tính chuyen_de_chi_tiet_nq57_test (cron phút 1/5)
]
DROPS = [
    "DROP VIEW IF EXISTS datamart_hanoi.v_nq57_solieu",
    "DROP VIEW IF EXISTS datamart_hanoi.v_nq57_solieu_truong",
    "DROP TABLE IF EXISTS datamart_hanoi.nq57_solieu",
    "DROP TABLE IF EXISTS datamart_hanoi.nq57_solieu_truong",
    "DROP TABLE IF EXISTS datamart_hanoi.nq57_truong",
    "DROP TABLE IF EXISTS datamart_hanoi.nq57_chitieu",
    "DROP TABLE IF EXISTS datamart_hanoi.chuyen_de_chi_tiet_nq57_test",
]
BK = os.path.join(d.REPO, "backups")


def targets():
    f = d.call("GET", f"/flow/process-groups/{d.G}")["processGroupFlow"]["flow"]
    procs = {p["id"]: p["component"]["name"] for p in f["processors"] if p["id"][:8] in PREFIX}
    assert len(procs) == len(PREFIX), (len(procs), len(PREFIX))
    assert d.PUTSQL not in procs
    conns = [c for c in f["connections"]
             if c["component"]["source"]["id"] in procs or c["component"]["destination"]["id"] in procs]
    return procs, conns


def check():
    procs, conns = targets()
    for pid, n in procs.items():
        print("P", pid, n)
    for c in conns:
        cc = c["component"]
        print("C", c["id"], cc["source"]["name"], "->", cc["destination"]["name"], cc.get("selectedRelationships"))
    return procs, conns


def nifi():
    out = os.path.join(BK, "backup_nifi_chuyendelon_20261118_before_go_nhanh_cu_lan2.json")
    open(out, "wb").write(d.call("GET", f"/process-groups/{d.G}/download", raw=True))
    print("backup ->", out, os.path.getsize(out), "bytes")
    procs, conns = check()
    for pid in procs:  # dừng trước để không phát sinh flowfile mới
        if d.proc(pid)["component"]["state"] == "RUNNING":
            d.set_state(pid, "STOPPED")
    gff = "142f3c8d-6ef6-1fc2-c5ea-24a1c5b0024f"  # GFF 5' dùng chung (eForm) - dừng tạm để xóa connection ra từ nó
    d.set_state(gff, "STOPPED")
    try:
        time.sleep(3)
        for c in conns:
            d.delete_conn(c["id"])
        for pid, n in procs.items():
            d.delete_proc(pid); print("đã xóa", n)
    finally:
        d.set_state(gff, "RUNNING"); print("đã bật lại GFF 5'")


def drop():
    sys.argv = sys.argv[:1]
    import sqllab
    data = {}
    for s in DROPS:
        t = s.split()[-1]
        r = sqllab.run(f"SELECT * FROM {t}")
        cr = sqllab.run(f"SHOW CREATE {'VIEW' if 'VIEW' in s else 'TABLE'} {t}")
        data[t] = {"create": cr.get("data"), "rows": r.get("data"), "error": r.get("error")}
        print(t, "rows:", len(r.get("data") or []), r.get("error", "")[:100])
    out = os.path.join(BK, "backup_datamart_nq57_bang_cu_20261118_before_drop.json")
    json.dump(data, open(out, "w"), ensure_ascii=False, default=str)
    print("backup ->", out, os.path.getsize(out), "bytes")
    for i, s in enumerate(DROPS, 1):
        gid = d.new_gff(f"TMP DROP {i}", 950, 1550, {"generate-ff-custom-text": s, "Data Format": "Text"})
        cid = d.connect(gid, d.PUTSQL, ["success"])
        d.set_state(gid, "RUN_ONCE")
        ok = d.wait_queue(cid, 60); time.sleep(2)
        print(s, "| drained:", ok, "| bulletins:", [b["message"][:200] for b in d.bulletins({d.PUTSQL})][-2:])
        d.delete_conn(cid); d.delete_proc(gid)
    left = sqllab.run("SELECT table_name FROM information_schema.tables WHERE table_schema='datamart_hanoi' AND table_name IN "
                      "('v_nq57_solieu','v_nq57_solieu_truong','nq57_solieu','nq57_solieu_truong','nq57_truong','nq57_chitieu','chuyen_de_chi_tiet_nq57_test')")
    print("còn lại:", left.get("data"))


if __name__ == "__main__":
    {"check": check, "nifi": nifi, "drop": drop}[sys.argv[1]]()
