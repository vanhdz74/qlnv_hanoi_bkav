"""Sinh câu SQL cho NiFi: trả 3 dòng (MONTH, WEEK, DAY), mỗi dòng 1 ô `goi` = gói JSON gửi Eform
POST .../aggregation-flows/TDNV_NHIEM_VU/values (theo chuyen_de/gui-doi-nifi-1911.md).
  python3 build_goi.py            # ghi goi_eform.sql (mẫu NiFi, tham số ${p.ngay} ${p.taken})
  python3 build_goi.py test       # thay tham số = bây giờ, chạy qua SQL Lab, in tóm tắt 3 gói
Tham số (NiFi UpdateAttribute đặt, giờ VN; MySQL lệch giờ nên không dùng CURDATE()/NOW()):
  p.ngay  = ngày lấy số 'yyyy-MM-dd'
  p.taken = taken_at 'yyyy-MM-ddTHH:mm:ss+07:00'
Kỳ chứa p.ngay: MONTH date = cuối tháng; WEEK (Thứ Bảy → Thứ Sáu) date = Thứ Sáu, week_start SAT; DAY date = p.ngay.
Số: chi_so_nv01_16.sql (NV01–NV16 theo đơn vị chủ trì); bỏ dòng value NULL.
"""
import datetime as dt, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "goi_eform.sql")

src = open(os.path.join(HERE, "chi_so_nv01_16.sql"), encoding="utf-8").read()
body = src[src.index("SELECT a.department_id"):src.index("ORDER BY a.department_id")]
body = body.replace("(SELECT '2026-11-19' AS den) p", "(SELECT '${p.ngay}' AS den) p")
assert "${p.ngay}" in body

SQL = f"""/* Gói Eform TDNV_NHIEM_VU – sinh bởi build_goi.py, KHÔNG sửa tay */
SELECT k.loai,
       CAST(JSON_OBJECT(
         'period', CASE k.loai
             WHEN 'MONTH' THEN JSON_OBJECT('type', 'MONTH', 'date', DATE_FORMAT(LAST_DAY('${{p.ngay}}'), '%Y-%m-%d'))
             WHEN 'WEEK'  THEN JSON_OBJECT('type', 'WEEK', 'week_start', 'SAT', 'date',
                               DATE_FORMAT(DATE_ADD('${{p.ngay}}', INTERVAL (11 - WEEKDAY('${{p.ngay}}')) % 7 DAY), '%Y-%m-%d'))
             ELSE                JSON_OBJECT('type', 'DAY', 'date', '${{p.ngay}}') END,
         'taken_at', '${{p.taken}}',
         'values', v.ds) AS CHAR CHARACTER SET utf8mb4) AS goi,
       v.so_dong
FROM (SELECT 'MONTH' AS loai UNION ALL SELECT 'WEEK' UNION ALL SELECT 'DAY') k
CROSS JOIN (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('department_id', s.department_id,
                                     'indicator_code', s.indicator_code, 'value', s.value)) AS ds,
           COUNT(*) AS so_dong
    FROM (
{body}    ) s
    WHERE s.value IS NOT NULL
) v
"""

if __name__ == "__main__":
    open(OUT, "w", encoding="utf-8").write(SQL)
    print("ghi", OUT, len(SQL), "ký tự")
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        now = dt.datetime.now(dt.timezone(dt.timedelta(hours=7))).replace(microsecond=0)
        q = SQL.replace("${p.ngay}", now.date().isoformat()).replace("${p.taken}", now.isoformat())
        sys.path.insert(0, "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu")
        import sqllab
        r = sqllab.run(q)
        if "error" in r or not r.get("data"):
            print(json.dumps(r, ensure_ascii=False)[:2000]); sys.exit(1)
        for row in r["data"]:
            g = json.loads(row["goi"])
            v = g["values"]
            bad = [x for x in v if not isinstance(x["value"], (int, float)) or isinstance(x["value"], bool)]
            print(row["loai"], json.dumps(g["period"]), g["taken_at"], "| dòng:", len(v), "| đơn vị:",
                  len({x["department_id"] for x in v}), "| value không phải số:", len(bad),
                  "| byte:", len(row["goi"].encode()), "| mẫu:", v[2])
        json.dump(json.loads(r["data"][0]["goi"]), open(os.path.join(HERE, "goi_mau.json"), "w", encoding="utf-8"),
                  ensure_ascii=False, indent=1)
