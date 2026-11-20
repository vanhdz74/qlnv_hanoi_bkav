"""Helper Superset REST API: đăng nhập bằng form /login/ (JWT bị server bỏ qua) + CSRF + cookie session."""
import json, os, re, urllib.request, urllib.parse, http.cookiejar

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
ENV = {}
for line in open(os.path.join(REPO, ".env")):
    if "=" in line and not line.strip().startswith("#"):
        k, v = line.strip().split("=", 1)
        ENV[k] = v.strip().strip('"').strip("'")
BASE = ENV["SUPERSET_URL"].rstrip("/")
_cj = http.cookiejar.CookieJar()
_op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(_cj))
_tok = {}
HDR = {"Referer": BASE + "/login/", "Origin": BASE}


def _req(method, path, body=None):
    h = dict(HDR, **{"Content-Type": "application/json"})
    if method != "GET" and "csrf" in _tok:
        h["X-CSRFToken"] = _tok["csrf"]
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, method=method, headers=h)
    try:
        resp = _op.open(r, timeout=120).read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:3000]}")
    try:
        return json.loads(resp)
    except Exception:
        return resp.decode()


def login():
    html = _op.open(urllib.request.Request(BASE + "/login/", headers=HDR), timeout=60).read().decode()
    csrf = re.search(r'name="csrf_token"[^>]*value="([^"]+)"', html) or re.search(r'id="csrf_token"[^>]*value="([^"]+)"', html)
    form = urllib.parse.urlencode({"csrf_token": csrf.group(1),
                                   "username": ENV.get("SUPERSET_USER") or ENV["SUPERSET_USERNAME"],
                                   "password": ENV.get("SUPERSET_PASS") or ENV["SUPERSET_PASSWORD"]}).encode()
    _op.open(urllib.request.Request(BASE + "/login/", data=form, headers=dict(HDR, **{"Content-Type": "application/x-www-form-urlencoded"})), timeout=60).read()
    _tok["csrf"] = _req("GET", "/api/v1/security/csrf_token/")["result"]


def get(p): return _req("GET", p)
def post(p, b): return _req("POST", p, b)
def put(p, b): return _req("PUT", p, b)
def q(d): return urllib.parse.quote(d)


def sql(s, db=8):
    """Chạy SQL qua SQL Lab (đồng bộ)."""
    return post("/api/v1/sqllab/execute/", {"database_id": db, "sql": s, "runAsync": False, "schema": "datamart_hanoi"})


login()
