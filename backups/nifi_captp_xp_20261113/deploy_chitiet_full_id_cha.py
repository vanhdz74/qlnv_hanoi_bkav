#!/usr/bin/env python3
"""13/11: thêm cột id_cha (AssignBatchId) vào qlnv_chitiet_captp_xp_bcd57_full.
Chỉ cập nhật processor 'ReplaceText - Upsert' của group 'BTH - Chi tiết' (142f43b8): stop -> PUT -> start lại."""
import difflib, json, os, sys, time, requests, urllib3
urllib3.disable_warnings()
ROOT = "/home/truongnbn/Documents/Superset,/QLNV"
env = {k: v.strip().strip('"').strip("'") for k, v in
       (l.strip().split("=", 1) for l in open(f"{ROOT}/.env") if "=" in l and not l.startswith("#"))}
B = env["NIFI_URL"].rstrip("/"); B = B[:-5] if B.endswith("/nifi") else B
GROUP = "142f43b8-6ef6-1fc2-606b-c592b98f3ec9"
# dùng: deploy_chitiet_full_id_cha.py "<tên processor>" <tệp sql> [--dry]
NAME = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "ReplaceText - Upsert"
NEW = open(sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--")
           else f"{ROOT}/bcd57_chitiet/nv_captp_xp/chitiet_full/1_replacetext_upsert.sql").read()
OUT = os.path.dirname(os.path.abspath(__file__))

s = requests.Session(); s.verify = False
tok = s.post(f"{B}/nifi-api/access/token", data={"username": env["NIFI_USERNAME"], "password": env["NIFI_PASSWORD"]}).text
s.headers.update({"Authorization": f"Bearer {tok}", "Origin": B, "Referer": f"{B}/nifi/",
                  "Request-Token": s.cookies.get("__Secure-Request-Token") or ""})

flow = s.get(f"{B}/nifi-api/flow/process-groups/{GROUP}").json()["processGroupFlow"]["flow"]
p = [x for x in flow["processors"] if x["component"]["name"] == NAME]
assert len(p) == 1, [x["component"]["name"] for x in flow["processors"]]
pid = p[0]["id"]
cur = s.get(f"{B}/nifi-api/processors/{pid}").json()
bk = f"{OUT}/backup_{NAME.split()[-1].lower()}_chitiet_full_{time.strftime('%H%M%S')}.json"
json.dump(cur, open(bk, "w"), ensure_ascii=False, indent=1); print("backup", bk)
old = cur["component"]["config"]["properties"]["Replacement Value"]
print("state", cur["component"]["state"])
print("".join(difflib.unified_diff(old.splitlines(True), NEW.splitlines(True), "live", "new", n=1)))
if "--dry" in sys.argv:
    sys.exit(0)

was_running = cur["component"]["state"] == "RUNNING"
if was_running:
    r = s.put(f"{B}/nifi-api/processors/{pid}/run-status", json={"revision": cur["revision"], "state": "STOPPED"})
    print("stop", r.status_code); r.raise_for_status()
    for _ in range(30):
        c = s.get(f"{B}/nifi-api/processors/{pid}").json()
        if c["status"]["aggregateSnapshot"].get("activeThreadCount", 0) == 0 and c["component"]["state"] == "STOPPED":
            break
        time.sleep(1)
c = s.get(f"{B}/nifi-api/processors/{pid}").json()
r = s.put(f"{B}/nifi-api/processors/{pid}", json={"revision": c["revision"], "component": {
    "id": pid, "config": {"properties": {"Replacement Value": NEW}}}})
print("update", r.status_code); r.raise_for_status()
c = s.get(f"{B}/nifi-api/processors/{pid}").json()
assert c["component"]["config"]["properties"]["Replacement Value"] == NEW
print("validation", c["component"].get("validationStatus"), c["component"].get("validationErrors"))
if was_running:
    r = s.put(f"{B}/nifi-api/processors/{pid}/run-status", json={"revision": c["revision"], "state": "RUNNING"})
    print("start", r.status_code); r.raise_for_status()
for x in s.get(f"{B}/nifi-api/flow/process-groups/{GROUP}").json()["processGroupFlow"]["flow"]["processors"]:
    print(x["component"]["name"], x["component"]["state"])
