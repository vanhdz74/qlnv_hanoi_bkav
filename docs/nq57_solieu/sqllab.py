"""SELECT qua Superset SQL Lab (DB 8 đọc được datamart_hanoi).  python3 sqllab.py "SELECT ..." """
import http.cookiejar, json, os, re, ssl, sys, urllib.parse, urllib.request

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ENV = {}
for line in open(os.path.join(REPO, ".env")):
    if "=" in line and not line.startswith("#"):
        k, v = line.strip().split("=", 1); ENV[k] = v.strip().strip('"')
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
SB = ENV["SUPERSET_URL"].rstrip("/")
cj = http.cookiejar.CookieJar()
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj), urllib.request.HTTPSHandler(context=ctx))
H = {"Referer": SB + "/login/", "Origin": SB}
html = op.open(urllib.request.Request(SB + "/login/", headers=H)).read().decode()
csrf = re.search(r'name="csrf_token"[^>]*value="([^"]+)"', html).group(1)
op.open(urllib.request.Request(SB + "/login/", data=urllib.parse.urlencode(
    {"csrf_token": csrf, "username": ENV["SUPERSET_USERNAME"], "password": ENV["SUPERSET_PASSWORD"]}).encode(), headers=H))
tok = json.loads(op.open(urllib.request.Request(SB + "/api/v1/security/csrf_token/", headers=H)).read())["result"]


def run(sql, db=8):
    h = dict(H, **{"X-CSRFToken": tok, "Content-Type": "application/json"})
    try:
        r = op.open(urllib.request.Request(SB + "/api/v1/sqllab/execute/", headers=h, data=json.dumps(
            {"database_id": db, "sql": sql, "runAsync": False, "schema": "datamart_hanoi"}).encode()), timeout=120)
    except urllib.error.HTTPError as e:
        return {"error": f"HTTP {e.code}: " + e.read().decode()[:1500]}
    return json.loads(r.read())


if __name__ == "__main__":
    res = run(sys.argv[1])
    cols = [c["column_name"] for c in res.get("columns", [])]
    print(" | ".join(cols))
    for row in res.get("data", []):
        print(" | ".join(str(row.get(c)) for c in cols))
    if not res.get("data"):
        print(json.dumps(res, ensure_ascii=False)[:800])
