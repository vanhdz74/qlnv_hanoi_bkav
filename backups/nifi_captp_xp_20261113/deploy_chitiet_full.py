#!/usr/bin/env python3
"""Deploy chitiet_full SQL -> group 'BTH - Chi tiết' (142f43b8), then start the group.
Writes table datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full (created by CREATE TABLE IF NOT EXISTS in upsert)."""
import json, os, time, requests, urllib3
urllib3.disable_warnings()
ROOT = "/home/truongnbn/Documents/Superset,/QLNV"
env = {k: v.strip().strip('"').strip("'") for k, v in
       (l.strip().split("=", 1) for l in open(f"{ROOT}/.env") if "=" in l and not l.startswith("#"))}
B = env["NIFI_URL"].rstrip("/"); B = B[:-5] if B.endswith("/nifi") else B
GROUP = "142f43b8-6ef6-1fc2-606b-c592b98f3ec9"
D = f"{ROOT}/bcd57_chitiet/nv_captp_xp/chitiet_full"
SQL = {"ReplaceText - Upsert": open(f"{D}/1_replacetext_upsert.sql").read(),
       "ReplaceText - Delete": open(f"{D}/2_replacetext_delete.sql").read()}
OUT = os.path.dirname(os.path.abspath(__file__))

s = requests.Session(); s.verify = False
tok = s.post(f"{B}/nifi-api/access/token", data={"username": env["NIFI_USERNAME"], "password": env["NIFI_PASSWORD"]}).text
s.headers.update({"Authorization": f"Bearer {tok}", "Origin": B, "Referer": f"{B}/nifi/",
                  "Request-Token": s.cookies.get("__Secure-Request-Token") or ""})

flow = s.get(f"{B}/nifi-api/flow/process-groups/{GROUP}").json()["processGroupFlow"]["flow"]
json.dump(flow, open(f"{OUT}/backup_group_chitiet_142f43b8_before.json", "w"), ensure_ascii=False, indent=1)
for p in flow["processors"]:
    name = p["component"]["name"]
    if name not in SQL:
        continue
    assert p["component"]["state"] == "STOPPED", name
    pid = p["id"]
    r = s.put(f"{B}/nifi-api/processors/{pid}", json={"revision": p["revision"], "component": {
        "id": pid, "config": {"properties": {"Replacement Value": SQL[name]}}}})
    print("update", name, r.status_code); r.raise_for_status()
    c = s.get(f"{B}/nifi-api/processors/{pid}").json()["component"]
    assert c["config"]["properties"]["Replacement Value"] == SQL[name]
    print("  ", c.get("validationStatus"), c.get("validationErrors"))

g = s.get(f"{B}/nifi-api/process-groups/{GROUP}").json()
r = s.put(f"{B}/nifi-api/flow/process-groups/{GROUP}", json={"id": GROUP, "state": "RUNNING"})
print("start group", r.status_code); r.raise_for_status()
time.sleep(2)
for p in s.get(f"{B}/nifi-api/flow/process-groups/{GROUP}").json()["processGroupFlow"]["flow"]["processors"]:
    print(p["component"]["name"], p["component"]["state"])
