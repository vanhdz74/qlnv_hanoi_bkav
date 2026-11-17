"""Bỏ kỳ 'Tuần 41', nạp số BC tháng 10/2026 (t10.json + NGUON_GIAO trong t10_src.py) vào
du_lieu_chuyen_de_nq57.json, sinh lại 0_ddl.sql + 1_nap_du_lieu.sql (cùng định dạng build.py).
Chạy:  python t10_src.py && python cap_nhat_t10.py
"""
import json, os
from collections import Counter
from t10_src import NGUON_GIAO

W = os.path.dirname(os.path.abspath(__file__))
SQL = os.path.dirname(W)
KY = "T10/2026"
NGUON = "BC tháng 10/2026 (CQTT, chốt 17h00 14/10/2026)"
THU_TU = {**{f"T{m}/2026": m - 1 for m in range(2, 11)}, "TB 20/10": 10}   # T2..T10 = 1..9

rows = json.load(open(os.path.join(SQL, "du_lieu_chuyen_de_nq57.json")))
rows = [r for r in rows if r["ky"] != "Tuần 41" and not (r["ky"] == KY and r["nhom_du_lieu"] != "CHI_SO")]
for r in rows:
    r["thu_tu_ky"] = THU_TU.get(r["ky"], r["thu_tu_ky"])

t10 = {x["ma"]: x for x in json.load(open(os.path.join(W, "t10.json")))}
f = lambda v: None if v is None else float(v)
dung = set()
for r in rows:
    if r["nhom_du_lieu"] != "CHI_SO" or r["ky"] != KY:
        continue
    x = t10.get(r["ma_chi_so"])
    if x:
        dung.add(x["ma"])
        r.update(tu_so=f(x["tu_so"]), mau_so=f(x["mau_so"]), gia_tri=f(x["gia_tri"]), co_so_lieu=1, nguon_so_lieu=NGUON,
                 vi_tri=x["vi_tri"], trich_dan=x["trich_dan"][:500], ghi_chu=x["ghi_chu"] or None)
    else:
        r.update(tu_so=None, mau_so=None, gia_tri=None, co_so_lieu=0, nguon_so_lieu=None, vi_tri=None, trich_dan=None,
                 ghi_chu="Chưa có số liệu trong BC tháng 10/2026")
assert dung == set(t10), set(t10) - dung
for r in rows:   # ghi chú cũ nhắc tới số tuần 41 -> đổi sang BC tháng 10
    if r["ma_chi_so"] == "NT09":
        if r["luu_y"]:
            r["luu_y"] = r["luu_y"].replace("Tuần 41 ghi 28.000", "BC tháng 10 ghi khoảng 28.000")
        if r["ghi_chu"]:
            r["ghi_chu"] = r["ghi_chu"].replace("; Tuần 41 dashboard ghi 28.000", "")

mau = next(r for r in rows if r["nhom_du_lieu"] == "NGUON_GIAO")
NG_COLS = [("tong", "Tổng số"), ("hoan_thanh", "Hoàn thành"), ("dang_thuc_hien", "Đang thực hiện"),
           ("qua_han", "Quá hạn"), ("can_xu_ly", "Cần xử lý"), ("han_trong_thang", "Đến hạn trong tháng")]
for j, (ng, vals) in enumerate(NGUON_GIAO.items()):
    for k, (col, ten) in enumerate(NG_COLS):
        r = dict(mau)
        r.update(ma_chi_so=col, ten_chi_so=ten, ten_ngan=ten, ky=KY, thu_tu_ky=THU_TU[KY], phan_to=ng, thu_tu_chi_so=j + 1,
                 gia_tri=float(vals[k]), co_so_lieu=1, nguon_so_lieu=NGUON + " - Phụ lục 01", tu_so=None, mau_so=None)
        rows.append(r)

COLS = ["nhom_du_lieu", "ma_chi_so", "ky", "phan_to", "thu_tu_ky", "thu_tu_chi_so", "stt_chuyen_de", "chuyen_de",
        "ten_chi_so", "ten_ngan", "don_vi_tinh", "loai_chi_so", "giam_la_tot", "nguong", "ten_nguong",
        "tu_so", "mau_so", "gia_tri", "co_so_lieu", "nguon_so_lieu", "vi_tri", "trich_dan", "dau_moi", "luu_y",
        "ghi_chu", "thong_tin_them"]


def lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "1" if v else "0"
    if isinstance(v, (int, float)):
        return repr(round(v, 6)) if isinstance(v, float) else str(v)
    s = str(v).replace("\\", "\\\\").replace("'", "''").replace("\n", " ").replace("\r", " ").replace("${", "$ {")
    return "'" + s + "'"


json.dump(rows, open(os.path.join(SQL, "du_lieu_chuyen_de_nq57.json"), "w"), ensure_ascii=False, indent=1)

ddl = open(os.path.join(SQL, "0_ddl.sql")).read()
ddl = ddl.replace("'T2/2026..T10/2026, Tuần 41, TB 20/10'", "'T2/2026..T10/2026, TB 20/10'")
open(os.path.join(SQL, "0_ddl.sql"), "w").write(ddl)

out = ["/* Nạp toàn bộ số liệu chuyen_de_chi_tiet_nq57 (sinh tự động từ du_lieu_chuyen_de_nq57.json).",
       "   NiFi: GenerateFlowFile (Custom Text = file này) -> PutSQL (HN-Datamart-NEW, allowMultiQueries=true).",
       "   Chạy lại an toàn: upsert theo khóa chính rồi xóa dòng của lần nạp cũ (xóa luôn kỳ 'Tuần 41'). */",
       "SET @sync = NOW();"]
for i in range(0, len(rows), 200):
    chunk = rows[i:i + 200]
    vals = ",\n".join("(" + ",".join(lit(r[c]) for c in COLS) + ",@sync)" for r in chunk)
    upd = ", ".join(f"{c}=VALUES({c})" for c in COLS[4:]) + ", sync_date=VALUES(sync_date)"
    out.append(f"INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` ({','.join(COLS)},sync_date) VALUES\n{vals}\nON DUPLICATE KEY UPDATE {upd};")
out.append("DELETE FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` WHERE sync_date < @sync;")
open(os.path.join(SQL, "1_nap_du_lieu.sql"), "w").write("\n".join(out) + "\n")

cs = [r for r in rows if r["nhom_du_lieu"] == "CHI_SO"]
print("rows", len(rows), "| CHI_SO", len(cs))
print(sorted(Counter((r["thu_tu_ky"], r["ky"], r["co_so_lieu"]) for r in cs).items()))
print(Counter((r["nhom_du_lieu"], r["ky"]) for r in rows if r["nhom_du_lieu"] != "CHI_SO"))
