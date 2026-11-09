"""Gộp số liệu trích từ BC tháng (out/*.json) + số dashboard -> bảng chuyen_de_chi_tiet_nq57.
Xuất: <repo>/bcd57_chitiet/chuyen_de/sql/0_ddl.sql, 1_nap_du_lieu.sql, du_lieu_chuyen_de_nq57.json
"""
import json, glob, os, sys, datetime

W = os.path.dirname(os.path.abspath(__file__))
REPO = "/Users/hoangvietanh/Documents/BKAV/Superset, Nifi/qlnv_hanoi/qlnv_hanoi_bkav/bcd57_chitiet/chuyen_de/sql"
os.makedirs(REPO, exist_ok=True)
d = json.load(open(os.path.join(W, "dash.json")))

KY = ["T2/2026", "T3/2026", "T4/2026", "T5/2026", "T6/2026", "T7/2026", "T8/2026", "T9/2026",
      "Tuần 41", "TB 20/10", "T10/2026"]
THU_TU = {k: i + 1 for i, k in enumerate(KY)}
NGUON_KY = {f"T{m}/2026": f"BC tháng {m}/2026" for m in range(2, 11)}
NGUON_KY["Tuần 41"] = "BC tuần 41 (03-09/10/2026, file 'BC tháng 10.pdf')"
NGUON_KY["TB 20/10"] = "Thông báo kết luận 20/10/2026"

# ---- số trích từ báo cáo
ex = {}
for f in sorted(glob.glob(os.path.join(W, "out", "t*.json"))):
    for r in json.load(open(f)):
        k = (r["ma"], r["ky"])
        if k not in ex:
            ex[k] = r

# ---- bổ sung đọc từ ảnh infographic (PDF T8 trang 34, T9 trang 29; text layer trống)
ANH = {
    "T8/2026": ("BC tháng 8/2026", "Phụ lục 03, trang 34 (ảnh)", {"CS07": (87, 126), "CS08": (73, 126), "CS09": (56, 126),
               "CS10": 14, "CS11": 17, "CS12": 48, "CS13": 10, "CS14": 37}),
    "T9/2026": ("BC tháng 9/2026", "Phụ lục 03, trang 29 (ảnh)", {"CS07": (95, 126), "CS08": (81, 126), "CS09": (68, 126),
               "CS10": 14, "CS11": 17, "CS12": 48, "CS13": 10, "CS14": 37}),
}
for ky, (ng, vt, vals) in ANH.items():
    for ma, v in vals.items():
        if (ma, ky) in ex:
            continue
        tu, mau = (v if isinstance(v, tuple) else (None, None))
        ex[(ma, ky)] = {"ma": ma, "ky": ky, "tu_so": tu, "mau_so": mau,
                        "gia_tri": (tu / mau if mau else v), "trich_dan": "Đọc từ ảnh 'Bức tranh chuyển đổi số khối xã, phường'",
                        "vi_tri": vt, "ghi_chu": "", "_nguon": ng}

dash = {(r[0], r[1]): r for r in d["CHUOI_RAW"]}
giam = set(d["GIAM_LA_TOT"]) if isinstance(d["GIAM_LA_TOT"], list) else set()
nguong = d["NGUONG"]
ten_ngan = d["TEN_NGAN"]

rows = []
def num(x):
    return None if x is None else float(x)

for i, c in enumerate(d["CHI_SO_RAW"]):
    ma, cd, ten, dv, loai, luu_y, bs, dau_moi, pl_goc, cach_tinh = c[:10]
    for ky in KY:
        r = ex.get((ma, ky))
        dsh = dash.get((ma, ky))
        base = dict(nhom_du_lieu="CHI_SO", ma_chi_so=ma, thu_tu_chi_so=i + 1, stt_chuyen_de=cd + 1,
                    chuyen_de=d["CHUYEN_DE"][cd], ten_chi_so=ten, ten_ngan=ten_ngan.get(ma, ten), don_vi_tinh=dv,
                    loai_chi_so=loai, giam_la_tot=1 if ma in giam else 0,
                    nguong=(nguong.get(ma) or {}).get("v"), ten_nguong=(nguong.get(ma) or {}).get("ten"),
                    ky=ky, thu_tu_ky=THU_TU[ky], phan_to="", dau_moi=dau_moi or None,
                    luu_y=luu_y or None, thong_tin_them=None)
        if r:
            note = r.get("ghi_chu") or ""
            if dsh and dsh[5] is not None and r.get("gia_tri") is not None and abs(dsh[5] - r["gia_tri"]) > max(1e-3, abs(r["gia_tri"]) * 0.002):
                note = (note + " | " if note else "") + f"Dashboard cũ ghi {dsh[5]}" + (f" ({dsh[3]}/{dsh[4]})" if dsh[3] is not None else "")
            base.update(tu_so=num(r.get("tu_so")), mau_so=num(r.get("mau_so")), gia_tri=num(r.get("gia_tri")),
                        co_so_lieu=0 if r.get("gia_tri") is None else 1,
                        nguon_so_lieu=r.get("_nguon") or NGUON_KY[ky], vi_tri=r.get("vi_tri"),
                        trich_dan=(r.get("trich_dan") or "")[:500] or None, ghi_chu=note or None)
        else:
            # CHỈ lấy số đọc được từ file trong tai_lieu; không lấy số từ UI mẫu -> NULL, dashboard hiện "!"
            gc = "Chưa có số liệu trong báo cáo"
            if ky == "T10/2026":
                gc += " - tai_lieu không có báo cáo tháng 10 (file 'BC tháng 10.pdf' là BC tuần 41)"
            elif ky == "TB 20/10":
                gc += " - tai_lieu không có file Thông báo kết luận 20/10/2026"
            base.update(tu_so=None, mau_so=None, gia_tri=None, co_so_lieu=0, nguon_so_lieu=None,
                        vi_tri=None, trich_dan=None, ghi_chu=gc)
        rows.append(base)

# ---- dữ liệu phụ: chép từ phụ lục báo cáo trong tai_lieu (không lấy từ UI mẫu)
AUX = json.load(open(os.path.join(W, "aux_bao_cao.json")))
def aux(nhom, ma, ten, dv, ky, phan_to, v, nguon, thu_tu=0, extra=None, mau=None):
    rows.append(dict(nhom_du_lieu=nhom, ma_chi_so=ma, thu_tu_chi_so=thu_tu, stt_chuyen_de=None, chuyen_de=None,
                     ten_chi_so=ten, ten_ngan=ten, don_vi_tinh=dv, loai_chi_so=None, giam_la_tot=0, nguong=None,
                     ten_nguong=None, ky=ky, thu_tu_ky=THU_TU.get(ky, 0), phan_to=phan_to, dau_moi=None, luu_y=None,
                     tu_so=None, mau_so=None if mau is None else float(mau), gia_tri=None if v is None else float(v), co_so_lieu=0 if v is None else 1,
                     nguon_so_lieu=nguon, vi_tri=None, trich_dan=None, ghi_chu=None,
                     thong_tin_them=json.dumps(extra, ensure_ascii=False) if extra else None))

NG_COLS = [("tong", "Tổng số"), ("hoan_thanh", "Hoàn thành"), ("dang_thuc_hien", "Đang thực hiện"),
           ("qua_han", "Quá hạn"), ("can_xu_ly", "Cần xử lý"), ("han_trong_thang", "Đến hạn trong tháng")]
for ky, ds in AUX["NGUON_GIAO"].items():
    for j, (nguon_giao, vals) in enumerate(ds.items()):
        for k, (col, ten) in enumerate(NG_COLS):
            aux("NGUON_GIAO", col, ten, "nhiệm vụ", ky, nguon_giao, vals[k], AUX["nguon"]["NGUON_GIAO"][ky], j + 1)
XA_COLS = [("tong_nhiem_vu", "Tổng nhiệm vụ"), ("hoan_thanh", "Hoàn thành"), ("dang_qua_han", "Đang quá hạn"), ("xong_qua_han", "Hoàn thành quá hạn")]
for ky, ds in AUX["XA_QUAN_TAM"].items():
    for j, (xa, vals) in enumerate(ds.items()):
        for k, (col, ten) in enumerate(XA_COLS):
            aux("XA_QUAN_TAM", col, ten, "nhiệm vụ", ky, xa, vals[k], AUX["nguon"]["XA_QUAN_TAM"][ky], j + 1)
for ky, ds in AUX["DIEM_NGHEN_XA"].items():
    for j, (nhom, (pa, sm)) in enumerate(ds.items()):
        aux("DIEM_NGHEN_XA", "so_xa_phan_anh", "Số xã phản ánh", "xã, phường", ky, nhom, pa, AUX["nguon"]["DIEM_NGHEN_XA"][ky], j + 1, mau=AUX["tong_so_xa"])
        aux("DIEM_NGHEN_XA", "can_xu_ly_som", "Cần xử lý sớm", "xã, phường", ky, nhom, sm, AUX["nguon"]["DIEM_NGHEN_XA"][ky], j + 1, mau=AUX["tong_so_xa"])
for ky, ds in AUX["NOI_DUNG_XA"].items():
    for j, (nhom, v) in enumerate(ds.items()):
        aux("NOI_DUNG_XA", "so_xa", "Số xã có kết quả", "xã, phường", ky, nhom, v, AUX["nguon"]["NOI_DUNG_XA"][ky], j + 1, mau=AUX["tong_so_xa"])
# QUA_HAN (danh sách nhiệm vụ quá hạn) không còn chép cứng ở đây: lấy từ phụ lục + map QLNV
# -> bảng chuyen_de_chi_tiet_nhiem_vu_nq57 (luồng NiFi trong sql/nhiem_vu/).

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
    s = str(v).replace("\\", "\\\\").replace("'", "''").replace("\n", " ").replace("\r", " ")
    return "'" + s + "'"

json.dump(rows, open(os.path.join(REPO, "du_lieu_chuyen_de_nq57.json"), "w"), ensure_ascii=False, indent=1)

DDL = """/* Bảng số liệu chuyên đề chi tiết NQ57 - nhập từ báo cáo tháng (tai_lieu/BC tháng 2-10).
   Dạng dọc: mỗi dòng = 1 chỉ số x 1 kỳ (x 1 phân tổ với dữ liệu phụ).
   nhom_du_lieu: CHI_SO (145 chỉ số x 11 kỳ, kỳ chưa có số -> gia_tri NULL, co_so_lieu = 0)
                 NGUON_GIAO | XA_QUAN_TAM | DIEM_NGHEN_XA | NOI_DUNG_XA (dữ liệu phụ cho dashboard)
   Đơn vị %: gia_tri lưu tỷ lệ 0..1. Chạy qua NiFi PutSQL (HN-Datamart-NEW). */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` (
    nhom_du_lieu    VARCHAR(30)    NOT NULL,
    ma_chi_so       VARCHAR(30)    NOT NULL,
    ky              VARCHAR(20)    NOT NULL COMMENT 'T2/2026..T10/2026, Tuần 41, TB 20/10',
    phan_to         VARCHAR(255)   NOT NULL DEFAULT '' COMMENT 'nguồn giao / xã / nhóm, rỗng với CHI_SO',
    thu_tu_ky       INT            NULL,
    thu_tu_chi_so   INT            NULL,
    stt_chuyen_de   INT            NULL,
    chuyen_de       VARCHAR(255)   NULL,
    ten_chi_so      VARCHAR(500)   NULL,
    ten_ngan        VARCHAR(255)   NULL,
    don_vi_tinh     VARCHAR(50)    NULL,
    loai_chi_so     VARCHAR(30)    NULL COMMENT 'Đầu vào | Đầu ra | Kết quả',
    giam_la_tot     TINYINT        NOT NULL DEFAULT 0,
    nguong          DECIMAL(10,4)  NULL,
    ten_nguong      VARCHAR(100)   NULL,
    tu_so           DECIMAL(24,6)  NULL,
    mau_so          DECIMAL(24,6)  NULL,
    gia_tri         DECIMAL(24,6)  NULL,
    co_so_lieu      TINYINT        NOT NULL DEFAULT 0 COMMENT '0 = chưa có số -> dashboard hiện cảnh báo !',
    nguon_so_lieu   VARCHAR(255)   NULL,
    vi_tri          VARCHAR(500)   NULL,
    trich_dan       TEXT           NULL,
    dau_moi         VARCHAR(255)   NULL,
    luu_y           TEXT           NULL,
    ghi_chu         TEXT           NULL,
    thong_tin_them  TEXT           NULL COMMENT 'JSON, dữ liệu phụ',
    sync_date       DATETIME       NOT NULL,
    PRIMARY KEY (nhom_du_lieu, ma_chi_so, ky, phan_to),
    KEY idx_ky (thu_tu_ky),
    KEY idx_chuyen_de (stt_chuyen_de)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""
open(os.path.join(REPO, "0_ddl.sql"), "w").write(DDL)

out = ["/* Nạp toàn bộ số liệu chuyen_de_chi_tiet_nq57 (sinh tự động từ du_lieu_chuyen_de_nq57.json).",
       "   NiFi: GenerateFlowFile (Custom Text = file này) -> PutSQL (HN-Datamart-NEW, allowMultiQueries=true).",
       "   Chạy lại an toàn: upsert theo khóa chính rồi xóa dòng của lần nạp cũ. */",
       "SET @sync = NOW();"]
for i in range(0, len(rows), 200):
    chunk = rows[i:i + 200]
    vals = ",\n".join("(" + ",".join(lit(r[c]) for c in COLS) + ",@sync)" for r in chunk)
    upd = ", ".join(f"{c}=VALUES({c})" for c in COLS[4:]) + ", sync_date=VALUES(sync_date)"
    out.append(f"INSERT INTO `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` ({','.join(COLS)},sync_date) VALUES\n{vals}\nON DUPLICATE KEY UPDATE {upd};")
out.append("DELETE FROM `datamart_hanoi`.`chuyen_de_chi_tiet_nq57` WHERE sync_date < @sync;")
open(os.path.join(REPO, "1_nap_du_lieu.sql"), "w").write("\n".join(out) + "\n")

cs = [r for r in rows if r["nhom_du_lieu"] == "CHI_SO"]
print("rows", len(rows), "chi_so rows", len(cs), "co so lieu", sum(r["co_so_lieu"] for r in cs))
from collections import Counter
print(Counter((r["ky"], r["co_so_lieu"]) for r in cs))
print(Counter(r["nhom_du_lieu"] for r in rows))
print("sql bytes", os.path.getsize(os.path.join(REPO, "1_nap_du_lieu.sql")))
