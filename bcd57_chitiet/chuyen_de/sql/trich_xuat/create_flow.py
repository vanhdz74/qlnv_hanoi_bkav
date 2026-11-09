"""Tạo process group nạp bảng chuyen_de_chi_tiet_nq57 (chưa chạy)."""
import json, os
from nifi import call, W

PARENT = "5ebe3d34-c913-1f31-8eb9-10b6b15afd2e"   # QLNV - Ban chỉ đạo 57 chi tiết
POOL = "acf51838-116f-119e-c09b-1b31f6c8d1ae"     # HN-Datamart-NEW
WRITER = "0bfb327a-8a21-1e6a-c8ee-10be802ba0b8"   # JsonRecordSetWriter
SQLDIR = "/Users/hoangvietanh/Documents/BKAV/Superset, Nifi/qlnv_hanoi/qlnv_hanoi_bkav/bcd57_chitiet/chuyen_de/sql"
R0 = {"version": 0, "clientId": "claude-cdnq57"}

sql = open(os.path.join(SQLDIR, "0_ddl.sql")).read() + "\n" + open(os.path.join(SQLDIR, "1_nap_du_lieu.sql")).read()
check_sql = """SELECT nhom_du_lieu, ky, COUNT(*) AS so_dong, SUM(co_so_lieu) AS co_so_lieu, MAX(sync_date) AS sync_date
FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` GROUP BY nhom_du_lieu, ky ORDER BY nhom_du_lieu, ky"""

pg = call("POST", f"/process-groups/{PARENT}/process-groups", {"revision": R0, "component": {
    "name": "NQ57 - chuyen_de_chi_tiet_nq57 (BC tháng)", "position": {"x": 2936.0, "y": -880.0},
    "comments": "Nạp số liệu chuyên đề NQ57 trích từ báo cáo tháng (T2-T10/2026) vào datamart_hanoi.chuyen_de_chi_tiet_nq57. "
                "Chạy tay: Run Once processor GenerateFlowFile. SQL nguồn: bcd57_chitiet/chuyen_de/sql/."}})
G = pg["id"]


def proc(type_, name, x, y, props, auto=(), sched="1 day"):
    p = call("POST", f"/process-groups/{G}/processors", {"revision": R0, "component": {
        "type": type_, "name": name, "position": {"x": x, "y": y},
        "config": {"properties": props, "schedulingStrategy": "TIMER_DRIVEN", "schedulingPeriod": sched,
                   "autoTerminatedRelationships": list(auto)}}})
    return p["id"]


def conn(src, dst, rels, src_type="PROCESSOR", dst_type="PROCESSOR"):
    call("POST", f"/process-groups/{G}/connections", {"revision": R0, "component": {
        "source": {"id": src, "groupId": G, "type": src_type},
        "destination": {"id": dst, "groupId": G, "type": dst_type},
        "selectedRelationships": rels}})


gen = proc("org.apache.nifi.processors.standard.GenerateFlowFile", "CDNQ57 - SQL tao bang + nap du lieu", 0, 0, {
    "generate-ff-custom-text": sql, "Batch Size": "1", "Data Format": "Text", "Unique FlowFiles": "false",
    "character-set": "UTF-8", "mime-type": "text/plain"})
put = proc("org.apache.nifi.processors.standard.PutSQL", "CDNQ57 - PutSQL nap chuyen_de_chi_tiet_nq57", 0, 240, {
    "JDBC Connection Pool": POOL, "Batch Size": "1", "Support Fragmented Transactions": "false",
    "rollback-on-failure": "false"}, sched="0 sec")
chk = proc("org.apache.nifi.processors.standard.ExecuteSQLRecord", "CDNQ57 - Kiem tra so dong", 0, 480, {
    "Database Connection Pooling Service": POOL, "SQL select query": check_sql, "esqlrecord-record-writer": WRITER},
    sched="0 sec")
f_ok = call("POST", f"/process-groups/{G}/funnels", {"revision": R0, "component": {"position": {"x": 180, "y": 720}}})["id"]
f_err = call("POST", f"/process-groups/{G}/funnels", {"revision": R0, "component": {"position": {"x": 600, "y": 300}}})["id"]
conn(gen, put, ["success"])
conn(put, chk, ["success"])
conn(put, f_err, ["failure", "retry"], dst_type="FUNNEL")
conn(chk, f_ok, ["success"], dst_type="FUNNEL")
conn(chk, f_err, ["failure"], dst_type="FUNNEL")
ids = {"pg": G, "gen": gen, "put": put, "chk": chk, "funnel_ok": f_ok, "funnel_err": f_err}
json.dump(ids, open(os.path.join(W, "flow_ids.json"), "w"), indent=1)
print(ids)
