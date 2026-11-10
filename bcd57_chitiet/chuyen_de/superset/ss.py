"""Helper Superset REST API (đăng nhập JWT + CSRF + cookie session)."""
import json, os, urllib.request, urllib.parse, http.cookiejar

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
ENV = {}
for line in open(os.path.join(REPO, ".env")):
    if "=" in line and not line.strip().startswith("#"):
        k, v = line.strip().split("=", 1)
        ENV[k] = v
BASE = ENV["SUPERSET_URL"].rstrip("/")
_cj = http.cookiejar.CookieJar()
_op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(_cj))
_tok = {}


def _req(method, path, body=None, auth=True):
    h = {"Content-Type": "application/json", "Referer": BASE + "/"}
    if auth:
        h["Authorization"] = "Bearer " + _tok["access"]
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
    d = _req("POST", "/api/v1/security/login", {"username": ENV.get("SUPERSET_USER") or ENV["SUPERSET_USERNAME"], "password": ENV.get("SUPERSET_PASS") or ENV["SUPERSET_PASSWORD"],
                                                "provider": "db", "refresh": True}, auth=False)
    _tok["access"] = d["access_token"]
    _tok["csrf"] = _req("GET", "/api/v1/security/csrf_token/")["result"]


def get(p):
    return _req("GET", p)


def post(p, b):
    return _req("POST", p, b)


def put(p, b):
    return _req("PUT", p, b)


def q(d):
    """rison đơn giản cho tham số q=(...)"""
    return urllib.parse.quote(d)


login()
