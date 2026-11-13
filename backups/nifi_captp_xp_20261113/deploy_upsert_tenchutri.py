#!/usr/bin/env python3
"""Deploy truyvan.sql -> ReplaceText - Upsert of group 'BTH - Chi tiết (Gộp)' (f5293b42)."""
import json, os, sys, time, requests, urllib3
urllib3.disable_warnings()
ROOT = "/home/truongnbn/Documents/Superset,/QLNV"
env = dict(l.strip().split("=", 1) for l in open(f"{ROOT}/.env") if "=" in l and not l.startswith("#"))
env = {k: v.strip().strip('"').strip("'") for k, v in env.items()}
B = env["NIFI_URL"].rstrip("/")
B = B[:-5] if B.endswith("/nifi") else B
GROUP = "f5293b42-bda1-1354-2ee5-a9cd66a45f19"
SQL = open(f"{ROOT}/bcd57_chitiet/nv_captp_xp/truyvan.sql").read()
OUT = os.path.dirname(os.path.abspath(__file__))

s = requests.Session(); s.verify = False
tok = s.post(f"{B}/nifi-api/access/token", data={"username": env["NIFI_USERNAME"], "password": env["NIFI_PASSWORD"]}).text
s.headers.update({"Authorization": f"Bearer {tok}", "Origin": B, "Referer": f"{B}/nifi/",
                  "Request-Token": s.cookies.get("__Secure-Request-Token") or ""})

flow = s.get(f"{B}/nifi-api/flow/process-groups/{GROUP}").json()["processGroupFlow"]["flow"]
procs = [p for p in flow["processors"] if p["component"]["name"] == "ReplaceText - Upsert"]
assert len(procs) == 1, procs
pid = procs[0]["id"]

def get():
    return s.get(f"{B}/nifi-api/processors/{pid}").json()

p = get()
json.dump(p, open(f"{OUT}/backup_upsert_processor_before_tenchutri.json", "w"), ensure_ascii=False, indent=1)
was_running = p["component"]["state"] == "RUNNING"
print("processor", pid, "state", p["component"]["state"])

if was_running:
    r = s.put(f"{B}/nifi-api/processors/{pid}/run-status", json={"revision": p["revision"], "state": "STOPPED"})
    print("stop", r.status_code); r.raise_for_status()
    for _ in range(30):
        p = get()
        if p["component"]["state"] == "STOPPED" and not p["status"]["aggregateSnapshot"].get("activeThreadCount"):
            break
        time.sleep(1)

r = s.put(f"{B}/nifi-api/processors/{pid}", json={"revision": p["revision"], "component": {
    "id": pid, "config": {"properties": {"Replacement Value": SQL}}}})
print("update", r.status_code); r.raise_for_status()
p = get()
assert p["component"]["config"]["properties"]["Replacement Value"] == SQL, "SQL mismatch after update"
print("validation", p["component"].get("validationStatus"), p["component"].get("validationErrors"))

if was_running:
    r = s.put(f"{B}/nifi-api/processors/{pid}/run-status", json={"revision": p["revision"], "state": "RUNNING"})
    print("start", r.status_code); r.raise_for_status()
print("final state", get()["component"]["state"])
