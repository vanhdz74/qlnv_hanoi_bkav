"""Đẩy chỉ số NV01–NV16 (chi_so_nv01_16.sql) sang Eform: POST .../aggregation-flows/TDNV_NHIEM_VU/values
  python3 day_eform.py                 # chạy SQL, in gói, KHÔNG gửi
  python3 day_eform.py gui [MONTH WEEK DAY]   # gửi các kỳ chứa ngày hôm nay (mặc định cả 3)
  python3 day_eform.py xem MONTH|WEEK|DAY     # N2: xem lần nhận gần nhất của kỳ hiện tại
Khóa: EFORM_TDNV_API_KEY trong .env của repo (không đưa khóa vào mã nguồn).
Máy Eform 10.2.22.69 phải đi thẳng, không qua proxy Squid.
"""
import datetime as dt, json, os, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/home/truongnbn/Documents/Superset,/QLNV"
URL = "http://10.2.22.69:28081/api/v1/integration/aggregation-flows/TDNV_NHIEM_VU/values"
VN = dt.timezone(dt.timedelta(hours=7))


def api_key():
    for line in open(os.path.join(ROOT, ".env"), encoding="utf-8"):
        k, _, v = line.strip().partition("=")
        if k == "EFORM_TDNV_API_KEY":
            return v.strip().strip('"\'')
    sys.exit("thiếu EFORM_TDNV_API_KEY trong .env")


def period(kind, today):
    """Kỳ chứa `today`. date = ngày cuối kỳ (tháng: cuối tháng; tuần Thứ Bảy→Thứ Sáu: Thứ Sáu)."""
    if kind == "MONTH":
        nxt = (today.replace(day=28) + dt.timedelta(days=4)).replace(day=1)
        return {"type": "MONTH", "date": (nxt - dt.timedelta(days=1)).isoformat()}
    if kind == "WEEK":
        fri = today + dt.timedelta(days=(4 - today.weekday()) % 7)
        return {"type": "WEEK", "date": fri.isoformat(), "week_start": "SAT"}
    return {"type": "DAY", "date": today.isoformat()}


def lay_so(today):
    sys.path.insert(0, os.path.join(ROOT, "docs/nq57_solieu"))
    import sqllab
    sql = open(os.path.join(HERE, "chi_so_nv01_16.sql"), encoding="utf-8").read()
    sql = sql.replace("'2026-11-19' AS den", f"'{today.isoformat()}' AS den").rstrip().rstrip(";")
    taken = dt.datetime.now(VN).replace(microsecond=0)
    r = sqllab.run(sql)
    if "error" in r or r.get("data") is None:
        sys.exit(json.dumps(r, ensure_ascii=False)[:2000])
    vals = []
    for x in r["data"]:
        if x["value"] is None:
            continue  # không có số → bỏ dòng, không gửi null
        v = float(x["value"])
        vals.append({"department_id": int(x["department_id"]), "indicator_code": x["indicator_code"],
                     "value": int(v) if v.is_integer() else v})
    return taken, vals


def call(method, url, key, body=None):
    req = urllib.request.Request(url, method=method, data=None if body is None else json.dumps(body).encode(),
                                 headers={"X-API-KEY": key, "Content-Type": "application/json"})
    op = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    try:
        with op.open(req, timeout=60) as f:
            return f.status, json.loads(f.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")[:2000]


if __name__ == "__main__":
    today = dt.datetime.now(VN).date()
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "xem":
        p = period(sys.argv[2] if len(sys.argv) > 2 else "MONTH", today)
        q = f"?period_type={p['type']}&period_date={p['date']}" + ("&period_week_start=SAT" if p["type"] == "WEEK" else "")
        st, body = call("GET", URL + q, api_key())
        print(st, json.dumps(body, ensure_ascii=False)[:3000] if not isinstance(body, str) else body)
        sys.exit()
    taken, vals = lay_so(today)
    dvs = sorted({v["department_id"] for v in vals})
    tong = {c: sum(v["value"] for v in vals if v["indicator_code"] == c) for c in ("NV01", "NV02", "NV05", "NV06", "NV07", "NV09", "NV12", "NV15")}
    print(f"ngày lấy số {today}, taken_at {taken.isoformat()}: {len(vals)} dòng, {len(dvs)} đơn vị; cộng các đơn vị: {tong}")
    if cmd != "gui":
        json.dump({"period": period("MONTH", today), "taken_at": taken.isoformat(), "values": vals},
                  open(os.path.join(HERE, "goi_mau.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("chưa gửi; gói mẫu → goi_mau.json"); sys.exit()
    key = api_key()
    for kind in (sys.argv[2:] or ["MONTH", "WEEK", "DAY"]):
        body = {"period": period(kind, today), "taken_at": taken.isoformat(), "values": vals}
        st, res = call("POST", URL, key, body)
        if isinstance(res, dict):
            rej = res.get("rejected") or []
            print(kind, body["period"], "→", st, "accepted:", res.get("accepted"), "rejected:", len(rej))
            for r in rej[:20]:
                print("   ", json.dumps(r, ensure_ascii=False))
        else:
            print(kind, body["period"], "→", st, res)
