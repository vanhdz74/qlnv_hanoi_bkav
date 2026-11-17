"""Trỏ dataset 159 (dashboard 279 'NQ57 – Chuyên đề chi tiết (test)') sang bảng NQ57.

  python3 superset_dataset.py switch    # backup rồi đổi SQL -> chuyen_de_chi_tiet_nq57_test
  python3 superset_dataset.py rollback  # trả SQL như trong backup
"""
import json, os, sys, urllib.request

_S = "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu/sqllab.py"
_g = {"__file__": _S}
exec(open(_S, encoding="utf-8").read().split("\nif __name__")[0], _g)
op, H, SB, tok = _g["op"], _g["H"], _g["SB"], _g["tok"]
DS = 159
BK = "/home/truongnbn/Documents/Superset,/QLNV/backups/backup_superset_dataset159_20261116_before_nq57_test.json"
NEW_SQL = "SELECT * FROM datamart_hanoi.chuyen_de_chi_tiet_nq57_test"


def api(method, path, body=None):
    h = dict(H, **{"X-CSRFToken": tok, "Content-Type": "application/json"})
    req = urllib.request.Request(SB + path, method=method, headers=h, data=json.dumps(body).encode() if body is not None else None)
    try:
        return json.loads(op.open(req, timeout=120).read() or b"{}")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code}: {e.read().decode()[:1500]}")


def put_sql(sql):
    r = api("PUT", f"/api/v1/dataset/{DS}?override_columns=false", {"sql": sql})
    print("PUT ok:", r.get("result", {}).get("sql", r)[:200])


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "switch":
        cur = api("GET", f"/api/v1/dataset/{DS}")["result"]
        if not os.path.exists(BK):
            json.dump(cur, open(BK, "w"), ensure_ascii=False, indent=1)
            print("backup ->", BK)
        print("before:", cur["table_name"], "|", cur["sql"])
        put_sql(NEW_SQL)
    elif cmd == "rollback":
        put_sql(json.load(open(BK))["sql"])
