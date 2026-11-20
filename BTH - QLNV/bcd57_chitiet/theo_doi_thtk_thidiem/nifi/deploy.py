"""Bảng datamart cho tab 3 "Tình hình triển khai thí điểm" (dashboard 280 / dataset 160) — 19/11/2026.

Nguồn (từ 19/11 tối) = tinh_tu_bao_cao.sql (đọc nq57_bao_cao; trước đó ../superset/dataset_eform_thang.sql), đổ vào
datamart_hanoi.bcd57_thidiem_trienkhai_thang bằng upsert + DELETE theo sync_date (không TRUNCATE).
Nhánh NiFi đặt trong group "Chuyên đề lớn": GFF cron 30 2/5 (sau lượt đồng bộ eForm phút 0/5)
  → ReplaceText (INSERT…ON DUPLICATE KEY UPDATE; DELETE sync_date cũ) → PutSQL có sẵn "NQ57 - PutSQL xoa dong cu".
Cột thieu_du_lieu = danh sách cột nguồn còn NULL (chart hiện "!" cảnh báo).

  python3 deploy.py sql      # sinh upsert.sql (xem trước, không động NiFi)
  python3 deploy.py backup   # tải group về backups/
  python3 deploy.py ddl      # CREATE TABLE IF NOT EXISTS (ddl.sql)
  python3 deploy.py build    # tạo GFF + ReplaceText (STOPPED), id lưu nifi_ids.json
  python3 deploy.py update   # nạp lại upsert.sql vào ReplaceText
  python3 deploy.py run      # chạy 1 lượt (RUN_ONCE) rồi kiểm số dòng
  python3 deploy.py start | stop | check

Nhánh chép PG bao_cao.dashboard.bao_cao → datamart_hanoi.nq57_bao_cao (nhân bản nhánh eForm, chung GFF 5'):
  python3 deploy.py ddl_bc | build_bc | test_bc | status_bc
"""
import json, os, re, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "docs", "nq57_solieu"))
import deploy_truong as d  # noqa: E402  (đăng nhập NiFi, group Chuyên đề lớn, PutSQL, Funnel)

TABLE = "`datamart_hanoi`.`bcd57_thidiem_trienkhai_thang`"
IDS = os.path.join(HERE, "nifi_ids.json")
COLS = ["ma_don_vi", "ten_don_vi", "tt_don_vi", "khoi", "ma_ky", "loai_ky", "nhan_ky", "ten_ky", "stt_ky", "han_nop", "den_han",
        "ts_nhap_dau", "ts_gui_duyet", "ts_phat_hanh", "trang_thai", "o_kiem_dem", "so_bieu", "so_bieu_hoan_tat",
        "so_lan_tra_lai", "lech_han_phut", "moc_chup"]
# cột nguồn có thể chưa có → ghi tên vào thieu_du_lieu khi NULL
# (ts_phat_hanh / lech_han_phut NULL khi chưa nộp là bình thường, không tính thiếu)
# 19/11 tối: nguồn bao_cao đã đủ giờ nhập/gửi duyệt/số lần trả lại → NULL ở các cột đó là "chưa tới bước", không phải thiếu
CO_THE_THIEU = ["han_nop", "trang_thai", "so_bieu", "so_lan_tra_lai"]
SRC_FILE = os.path.join(HERE, "tinh_tu_bao_cao.sql")
CRON = "30 2/5 * * * ?"


def src_sql():
    s = open(SRC_FILE, encoding="utf-8").read()
    s = "\n".join(re.sub(r"\s--\s.*$", "", l).rstrip() for l in s.splitlines() if not l.strip().startswith("--"))
    return "\n".join(l for l in s.splitlines() if l.strip())


def upsert_sql():
    sel = ",\n  ".join(f"x.{c}" for c in COLS)
    thieu = ", ".join(f"IF(x.{c} IS NULL, '{c}', NULL)" for c in CO_THE_THIEU)
    upd = ",\n  ".join(f"{c} = VALUES({c})" for c in COLS + ["thieu_du_lieu", "sync_date"])
    return f"""INSERT INTO {TABLE} (khoa, {", ".join(COLS)}, thieu_du_lieu, sync_date)
SELECT MD5(CONCAT(x.ma_don_vi, '|', x.ma_ky)) AS khoa,
  {sel},
  NULLIF(CONCAT_WS(',', {thieu}), '') AS thieu_du_lieu,
  '${{sync_ts}}' AS sync_date
FROM (
{src_sql()}
) x
ON DUPLICATE KEY UPDATE
  {upd};
DELETE FROM {TABLE}
WHERE sync_date < '${{sync_ts}}'
  AND (SELECT z.n FROM (SELECT COUNT(*) AS n FROM {TABLE} WHERE sync_date = '${{sync_ts}}') z) > 0"""


def load():
    return json.load(open(IDS)) if os.path.exists(IDS) else {}


def save(x):
    json.dump(x, open(IDS, "w"), indent=1)


def write_sql():
    s = upsert_sql()
    open(os.path.join(HERE, "upsert.sql"), "w", encoding="utf-8").write(s + "\n")
    print("upsert.sql:", len(s), "ký tự")
    return s


def backup():
    out = os.path.join(REPO, "backups", "backup_nifi_chuyendelon_20261119_before_thidiem.json")
    open(out, "wb").write(d.call("GET", f"/process-groups/{d.G}/download", raw=True))
    print("backup ->", out, os.path.getsize(out), "bytes")


def run_once_sql(sql, name):
    gid = d.new_gff(name, 2100, -300, {"generate-ff-custom-text": sql, "Data Format": "Text"})
    cid = d.connect(gid, d.PUTSQL, ["success"])
    try:
        d.set_state(gid, "RUN_ONCE")
        ok = d.wait_queue(cid, 60); time.sleep(2)
        print(name, "drained=", ok, [b["message"][:300] for b in d.bulletins({d.PUTSQL})][-3:])
    finally:
        d.delete_conn(cid); d.delete_proc(gid)


def ddl():
    run_once_sql(open(os.path.join(HERE, "ddl.sql"), encoding="utf-8").read().strip().rstrip(";"), "TMP DDL thidiem")


def build():
    ids = load()
    if ids.get("gff"):
        raise SystemExit("đã build: " + json.dumps(ids))
    sql = write_sql()
    gff = d.new_gff("TD - Hen gio bcd57_thidiem_trienkhai_thang", 2100, 0,
                    {"sync_ts": "${now():format('yyyy-MM-dd HH:mm:ss')}", "File Size": "0B", "Data Format": "Text"})
    d.update_props(gff, extra={"schedulingStrategy": "CRON_DRIVEN", "schedulingPeriod": CRON})
    rt = d.call("POST", f"/process-groups/{d.G}/processors", {"revision": {"version": 0}, "component": {
        "type": "org.apache.nifi.processors.standard.ReplaceText", "name": "TD - Upsert + xoa cu bcd57_thidiem_trienkhai_thang",
        "position": {"x": 2100, "y": 400},
        "config": {"properties": {"Replacement Strategy": "Always Replace", "Evaluation Mode": "Entire text",
                                  "Regular Expression": "(?s)(^.*$)", "Maximum Buffer Size": "1 MB",
                                  "Replacement Value": sql}}}})["id"]
    ids = {"gff": gff, "replace": rt}; save(ids)
    ids["c_gff"] = d.connect(gff, rt, ["success"])
    ids["c_ok"] = d.connect(rt, d.PUTSQL, ["success"])
    ids["c_fail"] = d.connect(rt, d.FUNNEL, ["failure"], "FUNNEL")
    save(ids); print(ids)


def update():
    sql = write_sql()
    ids = load()
    st = d.proc(ids["replace"])["component"]["state"]
    if st == "RUNNING":
        d.set_state(ids["replace"], "STOPPED"); time.sleep(1)
    d.update_props(ids["replace"], props={"Replacement Value": sql})
    if st == "RUNNING":
        d.set_state(ids["replace"], "RUNNING")
    print("đã nạp upsert.sql")


def check():
    sys.path.insert(0, os.path.join(REPO, "docs", "nq57_solieu"))
    import sqllab
    print(sqllab.run(f"""SELECT COUNT(*) n, COUNT(DISTINCT ma_don_vi) dv, COUNT(DISTINCT ma_ky) ky,
      SUM(o_kiem_dem='da_nop') da_nop, SUM(o_kiem_dem='chua_nop') chua_nop,
      MIN(sync_date) min_sync, MAX(sync_date) max_sync, MAX(thieu_du_lieu) thieu FROM {TABLE}""").get("data"))


def run():
    ids = load()
    d.set_state(ids["replace"], "RUNNING")
    chay = d.proc(ids["gff"])["component"]["state"] == "RUNNING"
    if chay:
        d.set_state(ids["gff"], "STOPPED"); time.sleep(1)
    d.set_state(ids["gff"], "RUN_ONCE")
    time.sleep(3)
    d.wait_queue(ids["c_ok"], 60); time.sleep(3)
    if chay:   # RUN_ONCE xong processor về STOPPED → bật lại cron
        d.set_state(ids["gff"], "RUNNING")
    for c in ("c_gff", "c_ok", "c_fail"):
        print(c, d.call("GET", f"/connections/{ids[c]}")["status"]["aggregateSnapshot"]["flowFilesQueued"])
    print([b["message"][:400] for b in d.bulletins({d.PUTSQL, ids["replace"], ids["gff"]})][-5:])
    check()


def start():
    ids = load()
    d.set_state(ids["replace"], "RUNNING"); d.set_state(ids["gff"], "RUNNING")
    print("đã bật, cron", CRON)


def stop():
    ids = load()
    d.set_state(ids["gff"], "STOPPED"); print("đã dừng GFF")


# ---------------- nhánh chép bao_cao (PG) → nq57_bao_cao
EFORM = {"esr": "142f46a0-6ef6-1fc2-e9c1-4568a66a65db", "route": "142f46a1-6ef6-1fc2-c18e-c2b660ae86c8",
         "upsert": "142f46a2-6ef6-1fc2-104d-6bac21c35e31", "replace": "142f46a3-6ef6-1fc2-e940-ac73b63b60c2"}
TBL_BC = "nq57_bao_cao"


def ddl_bc():
    run_once_sql(open(os.path.join(HERE, "ddl_bao_cao.sql"), encoding="utf-8").read().strip().rstrip(";"), "TMP DDL nq57_bao_cao")


def build_bc():
    ids = load()
    if ids.get("bc"):
        raise SystemExit("đã build: " + json.dumps(ids["bc"]))
    flow = d.call("GET", f"/flow/process-groups/{d.G}")["processGroupFlow"]["flow"]
    revs = {p["id"]: p["revision"] for p in flow["processors"]}
    chain = set(EFORM.values())
    inner = {c["id"]: c["revision"] for c in flow["connections"]
             if c["component"]["source"]["id"] in chain and c["component"]["destination"]["id"] in chain}
    assert len(inner) == 3, inner
    snip = d.call("POST", "/snippets", {"snippet": {"parentGroupId": d.G,
                  "processors": {pid: revs[pid] for pid in chain}, "connections": inner}})
    res = d.call("POST", f"/process-groups/{d.G}/snippet-instance",
                 {"snippetId": snip["snippet"]["id"], "originX": 2700, "originY": 320})
    procs = {p["component"]["name"]: p["id"] for p in res["flow"]["processors"]}
    b = {"esr": procs["NQ57 - Doc nq57_eform_chuyen_de (PG)"], "route": procs["NQ57 - Co du lieu nq57_eform_chuyen_de?"],
         "upsert": procs["NQ57 - Upsert nq57_eform_chuyen_de"], "replace": procs["NQ57 - SQL xoa dong cu nq57_eform_chuyen_de"],
         "inner_conns": [c["id"] for c in res["flow"]["connections"]]}
    ids["bc"] = b; save(ids)
    for k in ("esr", "route", "upsert", "replace"):   # bản sao có thể đang RUNNING theo bản gốc → dừng trước khi sửa
        if d.proc(b[k])["component"]["state"] == "RUNNING":
            d.set_state(b[k], "STOPPED")
    time.sleep(1)
    sql = open(os.path.join(HERE, "select_bao_cao_pg.sql"), encoding="utf-8").read().strip()
    d.update_props(b["esr"], f"NQ57 - Doc {TBL_BC} (PG)", {"SQL select query": sql})
    d.update_props(b["route"], f"NQ57 - Co du lieu {TBL_BC}?")
    d.update_props(b["upsert"], f"NQ57 - Upsert {TBL_BC}", {"put-db-record-table-name": TBL_BC})
    d.update_props(b["replace"], f"NQ57 - SQL xoa dong cu {TBL_BC}",
                   {"Replacement Value": f"DELETE FROM `datamart_hanoi`.`{TBL_BC}` WHERE sync_date < '${{sync_ts}}'"})
    b["conns"] = [d.connect(b["replace"], d.PUTSQL, ["success"]),
                  d.connect(b["esr"], d.FUNNEL, ["failure"], "FUNNEL"),
                  d.connect(b["upsert"], d.FUNNEL, ["failure", "retry"], "FUNNEL"),
                  d.connect(b["replace"], d.FUNNEL, ["failure"], "FUNNEL")]
    save(ids); print(json.dumps(b, indent=1))


def test_bc():
    """chạy 1 lượt bằng GFF tạm; sau đó nối GFF 5' thật (nếu chưa) và bật nhánh."""
    ids = load(); b = ids["bc"]
    for k in ("route", "upsert", "replace"):
        d.set_state(b[k], "RUNNING")
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    gid = d.new_gff("TMP test nq57_bao_cao", 2700, 100, {"sync_ts": ts})
    cid = d.connect(gid, b["esr"], ["success"])
    try:
        d.set_state(b["esr"], "RUNNING"); d.set_state(gid, "RUN_ONCE")
        time.sleep(40)
    finally:
        d.delete_conn(cid); d.delete_proc(gid)
    status_bc()


def alter_bc():
    run_once_sql(open(os.path.join(HERE, "alter_bao_cao_1911.sql"), encoding="utf-8").read().strip().rstrip(";"), "TMP ALTER nq57_bao_cao")


def update_bc():
    """nạp lại select_bao_cao_pg.sql vào ExecuteSQL (dừng → sửa → bật)."""
    b = load()["bc"]
    st = d.proc(b["esr"])["component"]["state"]
    if st == "RUNNING":
        d.set_state(b["esr"], "STOPPED"); time.sleep(1)
    d.update_props(b["esr"], props={"SQL select query": open(os.path.join(HERE, "select_bao_cao_pg.sql"), encoding="utf-8").read().strip()})
    if st == "RUNNING":
        d.set_state(b["esr"], "RUNNING")
    print("đã nạp select_bao_cao_pg.sql")


def link_bc():
    ids = load(); b = ids["bc"]
    if not b.get("c_gff"):
        b["c_gff"] = d.connect(d.GFF30, b["esr"], ["success"]); save(ids)
    for k in ("esr", "route", "upsert", "replace"):
        d.set_state(b[k], "RUNNING")
    print("nhánh nq57_bao_cao nối GFF 5' và đang chạy")


def status_bc():
    b = load()["bc"]
    for k in ("esr", "route", "upsert", "replace"):
        p = d.proc(b[k]); s = p["status"]["aggregateSnapshot"]
        print(f"{k:8} {p['component']['state']:8} in={s['flowFilesIn']} out={s['flowFilesOut']} {p['component']['validationStatus']}")
    for x in d.bulletins(set(b[k] for k in ("esr", "route", "upsert", "replace")) | {d.PUTSQL}):
        print("BULLETIN", x["sourceName"], x["level"], x["message"][:400])
    import sqllab
    print(sqllab.run(f"""SELECT ma_che_do, COUNT(*) n, COUNT(DISTINCT don_vi_id) dv, MIN(sync_date) s1, MAX(sync_date) s2
      FROM datamart_hanoi.{TBL_BC} GROUP BY ma_che_do""").get("data"))


if __name__ == "__main__":
    {"alter_bc": alter_bc, "update_bc": update_bc, "ddl_bc": ddl_bc, "build_bc": build_bc, "test_bc": test_bc, "link_bc": link_bc, "status_bc": status_bc,"sql": write_sql, "backup": backup, "ddl": ddl, "build": build, "update": update, "run": run,
     "start": start, "stop": stop, "check": check}[sys.argv[1]]()
