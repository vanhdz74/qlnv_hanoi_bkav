"""Helper NiFi REST API. Đọc NIFI_URL/USER/PASS từ .env của repo."""
import json, os, ssl, urllib.request, urllib.parse, sys, time

REPO = "/Users/hoangvietanh/Documents/BKAV/Superset, Nifi/qlnv_hanoi/qlnv_hanoi_bkav"
ENV = {}
for line in open(os.path.join(REPO, ".env")):
    if "=" in line and not line.startswith("#"):
        k, v = line.strip().split("=", 1)
        ENV[k] = v
URL = ENV["NIFI_URL"].rstrip("/") + "/nifi-api"
W = os.path.dirname(os.path.abspath(__file__))
TOKEN_FILE = os.path.join(W, ".nifi_token")


def _tok():
    if os.path.exists(TOKEN_FILE) and time.time() - os.path.getmtime(TOKEN_FILE) < 3600 * 6:
        return open(TOKEN_FILE).read().strip()
    data = urllib.parse.urlencode({"username": ENV["NIFI_USER"], "password": ENV["NIFI_PASS"]}).encode()
    t = urllib.request.urlopen(urllib.request.Request(URL + "/access/token", data=data), timeout=30).read().decode()
    open(TOKEN_FILE, "w").write(t)
    return t


def call(method, path, body=None, raw=False):
    h = {"Authorization": "Bearer " + _tok()}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        r = urllib.request.urlopen(req, timeout=120).read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:2000]}")
    if raw:
        return r
    return json.loads(r) if r else None


def rev(entity):
    return {"version": entity["revision"]["version"], "clientId": "claude-cdnq57"}


def set_state(proc_id, state):
    p = call("GET", f"/processors/{proc_id}")
    return call("PUT", f"/processors/{proc_id}/run-status", {"revision": rev(p), "state": state})
