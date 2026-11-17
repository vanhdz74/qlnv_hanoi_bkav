"""Deploy bảng dashboard chuyên đề NQ57 (test) lên NiFi group "Chuyên đề lớn". 16/11/2026

  python3 deploy.py ddl     # 0_ddl.sql ([1],[2]) + 1_nap_anh_xa.sql qua GFF tạm -> PutSQL "NQ57 - PutSQL xoa dong cu"
  python3 deploy.py flow    # GFF cron 2,32' -> ReplaceText (2_tinh_chuyen_de.sql) -> PutSQL; failure -> funnel; STOPPED
  python3 deploy.py run     # Run Once GFF tính, rồi bật ReplaceText
  python3 deploy.py start   # bật GFF tính
ID lưu ở nifi_ids.json. Helper NiFi dùng chung với docs/nq57_solieu/deploy_truong.py.
"""
import json, os, re, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
_H = "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu/deploy_truong.py"
_g = {"__file__": _H}
exec(open(_H, encoding="utf-8").read().split("if __name__")[0], _g)
call, proc, set_state, connect, delete_conn, delete_proc, new_gff, wait_queue, bulletins = (
    _g[k] for k in ("call", "proc", "set_state", "connect", "delete_conn", "delete_proc", "new_gff", "wait_queue", "bulletins"))
G, PUTSQL, FUNNEL = _g["G"], _g["PUTSQL"], _g["FUNNEL"]
IDS = os.path.join(HERE, "nifi_ids.json")
X = 2400


def ids():
    return json.load(open(IDS)) if os.path.exists(IDS) else {}


def save(d):
    json.dump(d, open(IDS, "w"), ensure_ascii=False, indent=1)


def run_sql_once(name, sql):
    gid = new_gff(name, X, -200, {"generate-ff-custom-text": sql, "Data Format": "Text"})
    cid = connect(gid, PUTSQL, ["success"])
    set_state(gid, "RUN_ONCE")
    ok = wait_queue(cid, 120); time.sleep(3)
    print(f"{name}: drained={ok}", [b["message"][:400] for b in bulletins({PUTSQL})][-2:])
    delete_conn(cid); delete_proc(gid)


def ddl():
    txt = open(os.path.join(HERE, "0_ddl.sql"), encoding="utf-8").read()
    for i, s in enumerate([s.strip().rstrip(";") for s in re.split(r"^-- \[\d\]\s*$", txt, flags=re.M)[1:]], 1):
        run_sql_once(f"TMP DDL chuyen de {i}", s)
    run_sql_once("TMP nap anh xa", open(os.path.join(HERE, "1_nap_anh_xa.sql"), encoding="utf-8").read().strip().rstrip(";"))


def flow():
    d = ids()
    if d.get("gff"):
        raise SystemExit("đã có flow: " + json.dumps(d))
    sql = open(os.path.join(HERE, "2_tinh_chuyen_de.sql"), encoding="utf-8").read()
    gff = call("POST", f"/process-groups/{G}/processors", {"revision": {"version": 0}, "component": {
        "type": "org.apache.nifi.processors.standard.GenerateFlowFile",
        "name": "NQ57 - Hen gio tinh chuyen de (phut 2, 32)", "position": {"x": X, "y": 420},
        "config": {"schedulingStrategy": "CRON_DRIVEN", "schedulingPeriod": "0 2,32 * * * ?",
                   "properties": {"sync_ts": "${now():format('yyyy-MM-dd HH:mm:ss')}"}}}})["id"]
    rtx = call("POST", f"/process-groups/{G}/processors", {"revision": {"version": 0}, "component": {
        "type": "org.apache.nifi.processors.standard.ReplaceText",
        "name": "NQ57 - SQL tinh chuyen_de_chi_tiet_nq57_test", "position": {"x": X, "y": 1080},
        "config": {"properties": {"Replacement Strategy": "Always Replace", "Regular Expression": "(?s)(^.*$)",
                                  "Replacement Value": sql, "Evaluation Mode": "Entire text",
                                  "Maximum Buffer Size": "1 MB", "Character Set": "UTF-8"}}}})["id"]
    conns = [connect(gff, rtx, ["success"]), connect(rtx, PUTSQL, ["success"]), connect(rtx, FUNNEL, ["failure"], "FUNNEL")]
    lab = call("POST", f"/process-groups/{G}/labels", {"revision": {"version": 0}, "component": {
        "label": ("⑤ chuyen_de_chi_tiet_nq57_test – dữ liệu dashboard (16/11)\n"
                  "Dashboard 279 'NQ57 – Chuyên đề chi tiết (test)', dataset 159\n"
                  "Chạy phút 2 và 32 (sau 4 nhánh ①–④). Tính từ ①② + danh mục\n"
                  "nq57_chi_so_anh_xa (145 chỉ số, cách lấy số sửa trong bảng này)\n"
                  "Upsert CHI_SO + NOI_DUNG_XA + XA_QUAN_TAM + DIEM_NGHEN_XA,\n"
                  "rồi DELETE sync_date < sync_ts. SQL: BTH - QLNV/…/sql/nq57_truong/"),
        "position": {"x": X, "y": 160}, "width": 420, "height": 230,
        "style": {"font-size": "12px", "background-color": "#fde2e4"}}})["id"]
    save({"gff": gff, "replace": rtx, "conns": conns, "label": lab})
    print(json.dumps(ids(), indent=1))


def run():
    d = ids()
    set_state(d["replace"], "RUNNING")
    set_state(d["gff"], "RUN_ONCE")
    time.sleep(40)
    for k in ("gff", "replace"):
        s = proc(d[k])["status"]["aggregateSnapshot"]
        print(k, "in", s["flowFilesIn"], "out", s["flowFilesOut"])
    print("PutSQL bulletins:", [b["message"][:500] for b in bulletins({PUTSQL, d["replace"]})][-3:])
    for c in d["conns"]:
        s = call("GET", f"/connections/{c}")["status"]["aggregateSnapshot"]
        if s["flowFilesQueued"]:
            print("QUEUED", s["sourceName"], "->", s["destinationName"], s["queued"])


def update():
    """Đẩy lại 2_tinh_chuyen_de.sql vào ReplaceText (sau khi sửa build.py)."""
    d = ids()
    sql = open(os.path.join(HERE, "2_tinh_chuyen_de.sql"), encoding="utf-8").read()
    set_state(d["replace"], "STOPPED"); time.sleep(1)
    p = proc(d["replace"])
    call("PUT", f"/processors/{d['replace']}", {"revision": p["revision"], "component": {
        "id": d["replace"], "config": {"properties": {"Replacement Value": sql}}}})
    print("ReplaceText updated,", len(sql), "chars")


def start():
    set_state(ids()["gff"], "RUNNING"); print("GFF tính đã RUNNING")


if __name__ == "__main__":
    {"ddl": ddl, "flow": flow, "run": run, "update": update, "start": start}[sys.argv[1]]()
