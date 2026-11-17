"""Dashboard "NQ57 – Chuyên đề chi tiết (test)" (279, dataset 159) đọc số từ 4 bảng NQ57 (16/11/2026).

  python3 build.py   -> sinh 0_ddl.sql, 1_nap_anh_xa.sql, 2_tinh_chuyen_de.sql, 3_kiem_tra_select.sql

Hai bảng đích (datamart_hanoi):
  nq57_chi_so_anh_xa            danh mục 145 chỉ số + cách lấy số (nạp 1 lần, sửa tay khi đổi cách tính)
  chuyen_de_chi_tiet_nq57_test  dữ liệu dashboard, cột giống hệt chuyen_de_chi_tiet_nq57; NiFi tính lại mỗi 30'

Nguồn số (bảng "vals" trong 2_tinh_chuyen_de.sql), mỗi mã x kỳ một giá trị:
  1) nq57_solieu  (theo chỉ tiêu): có dòng biểu TH-* thì lấy TH, không thì cộng biểu gốc (ACTUAL, phân tổ TONG)
  2) nq57_solieu_truong (theo trường): cộng mọi đơn vị / mọi dòng, chỉ dùng khi (1) không có mã đó trong kỳ đó
  3) mã tổng hợp tự đặt: XA_TT_* = đếm xã theo tỷ lệ văn bản toàn trình (Biểu 04 phần E, từng dòng = 1 xã)
Cách tính 1 chỉ số (cach_tinh = TONG):
  tu = tổng các mã trong tu_ma ('-MA' = trừ; có mã trừ thì phải có đủ cả mã cộng và mã trừ)
  mau = tổng các mã trong mau_ma, hoặc mau_hang_so
  có mẫu -> gia_tri = tu/mau (tu_so, mau_so giữ riêng)   | can_ty_le = 1 và không có mẫu -> gia_tri NULL
  không mẫu -> gia_tri = tu * he_so                     | chi_khi_mau_duong = 1 -> mẫu <= 0 thì bỏ cả tử
KHONG_CO -> vẫn có dòng mỗi kỳ, gia_tri NULL, co_so_lieu = 0 (dashboard hiện "!").
Kỳ: tháng 1 .. tháng lớn nhất đang có số; nhãn 'T8/2026', thu_tu_ky = tháng - 1 (giữ như bảng cũ).
MySQL 5.7: không CTE, không window function.
"""
import importlib.util, os

HERE = os.path.dirname(os.path.abspath(__file__))
DB = "`datamart_hanoi`"
OLD = f"{DB}.`chuyen_de_chi_tiet_nq57`"
MAP = f"{DB}.`nq57_chi_so_anh_xa`"
OUT = f"{DB}.`chuyen_de_chi_tiet_nq57_test`"

# ánh xạ cũ (75 chỉ số, đã dùng cho dataset 145 ngày 13/11)
_spec = importlib.util.spec_from_file_location("old", os.path.join(HERE, "..", "nq57_anh_xa", "build_sql.py"))
_old = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_old)

S = lambda *xs: ("sum", list(xs))
# ánh xạ bổ sung nhờ bảng theo trường. ma: (tu, mau[, can_ty_le[, he_so]])
NEW = {
    "CS01": ("XA_TT_GE90", 126), "CS02": ("XA_TT_100", 126), "CS03": ("XA_TT_LT50", None),
    # CS07–09: bản cũ dùng TH05_XA_* chặn bởi TH05_XA_SO (NQ57 không có) -> đếm xã trả lời "Có" ở Biểu 01 phần A
    "CS07": ("XA_A01_CO", 126), "CS08": ("XA_A03_CO", 126), "CS09": ("XA_A05_CO", 126),
    "CS04": (("-", "B04_D_MAYTINH_TONG", "B04_D_MAYTINH_CONLAI"), None),
    "CS05": (("-", "B04_D_PHONGHOP_TONG", "B04_D_PHONGHOP_CONLAI"), None),
    "CS06": (("-", "B04_D_CKS_TONG", "B04_D_CKS_CONLAI"), None),
    "DD02": ("B07_A02", None), "DD03": ("B07_A02", "B07_A01"), "DD06": ("B07_A03", "B07_A02"),
    "DD07": ("B07_A06", "B07_A05"), "DD08": ("B07_A09", None), "DD09": ("B07_A10", None),
    "DL04": ("B04_A08", None), "DL07": ("B04_A04", None),
    "KH05": ("B05_D04", None), "KH13": ("B05_E_TEX_HD_LK", None),
    "NT06": ("B04_C11", None), "NT16": ("B10_A02", "B10_A01"),
    "TC14": (S("B03_A_TX_TINH_GN_LK", "B03_A_TX_XA_GN_LK"), S("B03_A_TX_TINH_DUTOAN", "B03_A_TX_XA_DUTOAN")),
    "TT01": (S("B06_A_TTHC_TINH", "B06_A_TTHC_XA"), None),
    "TT02": (S("B06_A_TOANTRINH_TINH", "B06_A_TOANTRINH_XA"), None),
    "TT03": (S("B06_A_TOANTRINH_TINH", "B06_A_TOANTRINH_XA"), S("B06_A_TTHC_TINH", "B06_A_TTHC_XA")),
    "TT04": (S("B06_A_MOTPHAN_TINH", "B06_A_MOTPHAN_XA"), None),
    "TT09": (S("B06_A_PHANCAP_TINH", "B06_A_PHANCAP_XA"), None),
    "TT11": (S("B06_A_HS_NHAN_TINH", "B06_A_HS_NHAN_XA"), None),
    # nhóm chỉ số bổ sung (trước đây để trống)
    "BS01": ("B09_A04", "B09_A01"), "BS02": ("B09_A06", "B09_A05"), "BS03": ("B09_A07", None),
    "BS04": ("B04_C04", "B04_C03"), "BS05": ("B04_C06", None), "BS06": ("B04_C08", "B04_C07"),
    "BS07": (S("B06_A_HS_TOANTRINH_TINH", "B06_A_HS_TOANTRINH_XA"), S("B06_A_HS_NHAN_TINH", "B06_A_HS_NHAN_XA")),
    "BS08": ("B06_B06", None),
    "BS09": (S("B06_A_HS_TAISD_TINH", "B06_A_HS_TAISD_XA"), S("B06_A_HS_NHAN_TINH", "B06_A_HS_NHAN_XA")),
    "BS10": ("B04_A03", "B04_A01"), "BS13": ("B02_B05", None),
    "BS14": (S("B05_E_TEX_HD_LK", "B05_E_CHO_GD_LK"), None), "BS15": ("B02_B04", None),
    "BS16": ("B11_A01", None, False, 0.01),
    "BS17": (S("B12_B_THIEUNL_SO", "B12_B_THIEUKN_SO", "B12_B_THIEUKT_SO"), None),
    "BS18": (S("B01_E02", "B02_C02"), S("B01_E01", "B02_C01")),
}
MAPS = dict(_old.M); MAPS.update(NEW)   # NEW ghi đè CS07–09 của bản cũ
# ánh xạ cũ có PB/GN_ALL/DT_ALL là macro của file cũ, đã nằm sẵn trong _old.M


def flat(e, neg=False, flags=None):
    """-> list mã ('-MA' nếu trừ). if_pos(c, m): lấy m, đánh dấu chỉ lấy khi mẫu > 0."""
    if e is None:
        return []
    if isinstance(e, str):
        return [("-" if neg else "") + e]
    op = e[0]
    if op == "sum":
        return [c for x in e[1] for c in flat(x, neg, flags)]
    if op == "-":
        return flat(e[1], neg, flags) + flat(e[2], not neg, flags)
    if op == "if_pos":
        if flags is not None: flags.add("mau_duong")
        return flat(e[2], neg, flags)
    raise ValueError(e)


def row(ma, spec):
    tu, mau = spec[0], spec[1]
    can = spec[2] if len(spec) > 2 else False
    hs = spec[3] if len(spec) > 3 and spec[3] else 1
    fl = set()
    tu_ma = ",".join(flat(tu, flags=fl))
    mau_hs, mau_ma = (mau, "") if isinstance(mau, (int, float)) else (None, ",".join(flat(mau)))
    mo_ta = "NQ57: " + tu_ma.replace(",", " + ").replace("+ -", "− ") + (f" / {mau_ma.replace(',', ' + ') or mau_hs}" if (mau_ma or mau_hs) else "")
    return dict(ma=ma, tu=tu_ma, mau=mau_ma or None, mau_hs=mau_hs, hs=hs, can=int(bool(can)),
                duong=int("mau_duong" in fl), mo_ta=mo_ta[:500])


def q(v):
    if v is None: return "NULL"
    if isinstance(v, (int, float)): return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


DDL = f"""-- [1]
CREATE TABLE IF NOT EXISTS {MAP} (
    ma_chi_so          VARCHAR(30)    NOT NULL,
    thu_tu_chi_so      INT            NULL,
    stt_chuyen_de      INT            NULL,
    chuyen_de          VARCHAR(255)   NULL,
    ten_chi_so         VARCHAR(500)   NULL,
    ten_ngan           VARCHAR(255)   NULL,
    don_vi_tinh        VARCHAR(50)    NULL,
    loai_chi_so        VARCHAR(30)    NULL,
    giam_la_tot        TINYINT        NOT NULL DEFAULT 0,
    nguong             DECIMAL(10,4)  NULL,
    ten_nguong         VARCHAR(100)   NULL,
    dau_moi            VARCHAR(255)   NULL,
    luu_y              TEXT           NULL,
    cach_tinh          VARCHAR(20)    NOT NULL DEFAULT 'KHONG_CO' COMMENT 'TONG | KHONG_CO',
    tu_ma              VARCHAR(1000)  NULL COMMENT 'mã trường/chỉ tiêu NQ57, phân cách bằng dấu phẩy; -MA = trừ',
    mau_ma             VARCHAR(1000)  NULL,
    mau_hang_so        DECIMAL(24,6)  NULL COMMENT 'mẫu cố định, vd 126 xã',
    he_so              DECIMAL(12,6)  NOT NULL DEFAULT 1,
    can_ty_le          TINYINT        NOT NULL DEFAULT 0 COMMENT '1 = thiếu mẫu thì gia_tri NULL',
    chi_khi_mau_duong  TINYINT        NOT NULL DEFAULT 0 COMMENT '1 = mẫu <= 0 thì bỏ cả tử',
    mo_ta_nguon        VARCHAR(500)   NULL,
    ghi_chu            TEXT           NULL,
    cap_nhat           DATETIME       NULL,
    PRIMARY KEY (ma_chi_so)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [2]
CREATE TABLE IF NOT EXISTS {OUT} LIKE {OLD};
"""


def nap_anh_xa():
    rows = [row(m, s) for m, s in sorted(MAPS.items())]
    vals = "\n    UNION ALL ".join(
        f"SELECT {q(r['ma'])} ma, {q(r['tu'])} tu, {q(r['mau'])} mau, {q(r['mau_hs'])} mau_hs, {r['hs']} hs, "
        f"{r['can']} can, {r['duong']} duong, {q(r['mo_ta'])} mo_ta" for r in rows)
    return f"""/* Nạp danh mục chỉ số + ánh xạ. Danh mục (tên, chuyên đề, ngưỡng, đầu mối…) chép từ các dòng CHI_SO của bảng nhập tay.
   Chạy lại được (upsert). {len(rows)} chỉ số có ánh xạ; còn lại cach_tinh = KHONG_CO. */
INSERT INTO {MAP}
    (ma_chi_so, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, don_vi_tinh, loai_chi_so,
     giam_la_tot, nguong, ten_nguong, dau_moi, luu_y,
     cach_tinh, tu_ma, mau_ma, mau_hang_so, he_so, can_ty_le, chi_khi_mau_duong, mo_ta_nguon, ghi_chu, cap_nhat)
SELECT dm.ma_chi_so, dm.thu_tu_chi_so, dm.stt_chuyen_de, dm.chuyen_de, dm.ten_chi_so, dm.ten_ngan, dm.don_vi_tinh,
       dm.loai_chi_so, dm.giam_la_tot, dm.nguong, dm.ten_nguong, dm.dau_moi, dm.luu_y,
       IF(mp.ma IS NULL, 'KHONG_CO', 'TONG'), mp.tu, mp.mau, mp.mau_hs, COALESCE(mp.hs, 1),
       COALESCE(mp.can, 0), COALESCE(mp.duong, 0),
       COALESCE(mp.mo_ta, 'Chưa có chỉ tiêu tương ứng trong NQ57'), NULL, NOW()
FROM (
    SELECT ma_chi_so,
           MAX(thu_tu_chi_so) thu_tu_chi_so, MAX(stt_chuyen_de) stt_chuyen_de, MAX(chuyen_de) chuyen_de,
           MAX(ten_chi_so) ten_chi_so, MAX(ten_ngan) ten_ngan, MAX(don_vi_tinh) don_vi_tinh, MAX(loai_chi_so) loai_chi_so,
           MAX(giam_la_tot) giam_la_tot, MAX(nguong) nguong, MAX(ten_nguong) ten_nguong, MAX(dau_moi) dau_moi, MAX(luu_y) luu_y
    FROM {OLD}
    WHERE nhom_du_lieu = 'CHI_SO'
    GROUP BY ma_chi_so
) dm
LEFT JOIN (
    {vals}
) mp ON mp.ma = dm.ma_chi_so
ON DUPLICATE KEY UPDATE
    thu_tu_chi_so = VALUES(thu_tu_chi_so), stt_chuyen_de = VALUES(stt_chuyen_de), chuyen_de = VALUES(chuyen_de),
    ten_chi_so = VALUES(ten_chi_so), ten_ngan = VALUES(ten_ngan), don_vi_tinh = VALUES(don_vi_tinh),
    loai_chi_so = VALUES(loai_chi_so), giam_la_tot = VALUES(giam_la_tot), nguong = VALUES(nguong),
    ten_nguong = VALUES(ten_nguong), dau_moi = VALUES(dau_moi), luu_y = VALUES(luu_y),
    cach_tinh = VALUES(cach_tinh), tu_ma = VALUES(tu_ma), mau_ma = VALUES(mau_ma), mau_hang_so = VALUES(mau_hang_so),
    he_so = VALUES(he_so), can_ty_le = VALUES(can_ty_le), chi_khi_mau_duong = VALUES(chi_khi_mau_duong),
    mo_ta_nguon = VALUES(mo_ta_nguon), cap_nhat = VALUES(cap_nhat)
"""


# ---------------------------------------------------------------- tính bảng dữ liệu
KY_LABEL = "CONCAT('T', CAST(RIGHT({k}, 2) AS UNSIGNED), '/', LEFT({k}, 4))"
KY_TT = "(CAST(RIGHT({k}, 2) AS UNSIGNED) - 1)"
COLS = ("nhom_du_lieu, ma_chi_so, ky, phan_to, thu_tu_ky, thu_tu_chi_so, stt_chuyen_de, chuyen_de, ten_chi_so, ten_ngan, "
        "don_vi_tinh, loai_chi_so, giam_la_tot, nguong, ten_nguong, tu_so, mau_so, gia_tri, co_so_lieu, nguon_so_lieu, "
        "vi_tri, trich_dan, dau_moi, luu_y, ghi_chu, thong_tin_them, sync_date")
UPD = ", ".join(f"{c} = VALUES({c})" for c in COLS.split(", ")[4:])
TS = "'${sync_ts}'"

VALS = f"""(
        SELECT ma_chi_tieu AS m, ky,
               COALESCE(MAX(IF(ma_bieu LIKE 'NQ57HN-TH%', gia_tri, NULL)),
                        SUM(IF(ma_bieu LIKE 'NQ57HN-TH%', NULL, gia_tri))) AS v
        FROM {DB}.`nq57_solieu`
        WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL
        GROUP BY ma_chi_tieu, ky
        UNION ALL
        SELECT s.ma_truong, s.ky, SUM(s.gia_tri_so)
        FROM {DB}.`nq57_solieu_truong` s
        LEFT JOIN (SELECT DISTINCT ma_chi_tieu, ky FROM {DB}.`nq57_solieu`
                   WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL) c
               ON c.ma_chi_tieu = s.ma_truong AND c.ky = s.ky
        WHERE s.gia_tri_so IS NOT NULL AND c.ma_chi_tieu IS NULL
        GROUP BY s.ma_truong, s.ky
        UNION ALL
        SELECT x.m, e.ky,
               SUM(CASE x.m WHEN 'XA_TT_GE90' THEN e.r >= 0.9 WHEN 'XA_TT_100' THEN e.r >= 1 WHEN 'XA_TT_LT50' THEN e.r < 0.5 ELSE 1 END)
        FROM (
            SELECT ky, ma_don_vi, so_dong,
                   SUM(IF(ma_truong = 'B04_E03', gia_tri_so, NULL)) / NULLIF(SUM(IF(ma_truong = 'B04_E02', gia_tri_so, NULL)), 0) AS r
            FROM {DB}.`nq57_solieu_truong`
            WHERE ma_bieu = 'NQ57HN-B04' AND ma_phan = 'E' AND so_dong > 0
            GROUP BY ky, ma_don_vi, so_dong
        ) e
        CROSS JOIN (SELECT 'XA_TT_GE90' m UNION ALL SELECT 'XA_TT_100' UNION ALL SELECT 'XA_TT_LT50' UNION ALL SELECT 'XA_TT_SO') x
        WHERE e.r IS NOT NULL
        GROUP BY x.m, e.ky
        UNION ALL
        SELECT CONCAT('XA_', SUBSTRING(ma_truong, 5), '_CO'), ky, COUNT(DISTINCT ma_don_vi)
        FROM {DB}.`nq57_solieu_truong`
        WHERE ma_bieu = 'NQ57HN-B01' AND ma_truong IN ('B01_A01', 'B01_A03', 'B01_A05') AND gia_tri_chu = 'Có'
        GROUP BY ma_truong, ky
    )"""

KYS = f"""(
        SELECT CONCAT(y.nam, 'M', LPAD(n.t, 2, '0')) AS ky_nq57
        FROM (SELECT 1 t UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
              UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) n
        JOIN (SELECT LEFT(MAX(ky), 4) nam, CAST(RIGHT(MAX(ky), 2) AS UNSIGNED) den
              FROM (SELECT ky FROM {DB}.`nq57_solieu` UNION ALL SELECT ky FROM {DB}.`nq57_solieu_truong`) a
              WHERE ky LIKE '____M__') y ON n.t <= y.den
    )"""

def head(exprs):
    """SELECT có đặt tên cột theo COLS (SQL Lab cần tên cột không trùng)."""
    names = COLS.split(", ")
    assert len(exprs) == len(names), (len(exprs), len(names))
    return "SELECT " + ",\n       ".join(f"{e} AS {n}" for e, n in zip(exprs, names))


CHI_SO_SELECT = head([
    "'CHI_SO'", "z.ma_chi_so", KY_LABEL.format(k='z.ky_nq57'), "''", KY_TT.format(k='z.ky_nq57'),
    "z.thu_tu_chi_so", "z.stt_chuyen_de", "z.chuyen_de", "z.ten_chi_so", "z.ten_ngan", "z.don_vi_tinh", "z.loai_chi_so",
    "z.giam_la_tot", "z.nguong", "z.ten_nguong", "z.tu_so", "z.mau_so", "z.gia_tri",
    "IF(z.gia_tri IS NULL, 0, 1)",
    "IF(z.cach_tinh = 'KHONG_CO', NULL, 'NQ57 (CSDL số liệu NQ57)')",
    "z.mo_ta_nguon", "NULL", "z.dau_moi", "z.luu_y",
    "IF(z.cach_tinh = 'KHONG_CO', 'Chưa có chỉ tiêu tương ứng trong NQ57', IF(z.gia_tri IS NULL, 'NQ57 chưa có số kỳ này', NULL))",
    "NULL", TS]) + """
FROM ("""
CHI_SO_SELECT += f"""
    SELECT y.*,
           CASE WHEN y.co_mau = 1 OR y.can_ty_le = 1 THEN y.tu END AS tu_so,
           CASE WHEN y.co_mau = 1 THEN y.mau END AS mau_so,
           CASE WHEN y.co_mau = 1 THEN y.tu / NULLIF(y.mau, 0)
                WHEN y.can_ty_le = 1 THEN NULL
                ELSE y.tu * y.he_so END AS gia_tri
    FROM (
        SELECT x.*,
               IF(x.mau_ma IS NULL AND x.mau_hang_so IS NULL, 0, 1) AS co_mau,
               IF(x.chi_khi_mau_duong = 1 AND NOT (COALESCE(x.mau_raw, x.mau_hang_so) > 0), NULL,
                  IF(x.n_cong = 0 OR (LOCATE('-', x.tu_ma) > 0 AND x.n_tru = 0), NULL, x.tu_raw)) AS tu,
               COALESCE(x.mau_raw, x.mau_hang_so) AS mau
        FROM (
            SELECT m.*, k.ky_nq57,
                   SUM(CASE WHEN FIND_IN_SET(v.m, m.tu_ma) THEN v.v
                            WHEN FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) THEN -v.v END) AS tu_raw,
                   SUM(FIND_IN_SET(v.m, m.tu_ma) > 0) AS n_cong,
                   SUM(FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) > 0) AS n_tru,
                   SUM(IF(FIND_IN_SET(v.m, m.mau_ma), v.v, NULL)) AS mau_raw
            FROM {MAP} m
            CROSS JOIN {KYS} k
            LEFT JOIN {VALS} v
                   ON v.ky = k.ky_nq57
                  AND (FIND_IN_SET(v.m, m.tu_ma) OR FIND_IN_SET(CONCAT('-', v.m), m.tu_ma) OR FIND_IN_SET(v.m, m.mau_ma))
            GROUP BY m.ma_chi_so, k.ky_nq57
        ) x
    ) y
) z"""

TEN_XA = ("TRIM(REPLACE(REPLACE(REPLACE(REPLACE({c}, 'Thường trực BCĐ57 ', ''), 'UBND ', ''), "
          "'phường ', ''), 'xã ', ''))")


def phu(nhom, ma, ten, dv, ttc, tu, mau, gt, pt, src, where_group):
    return head([f"'{nhom}'", ma, KY_LABEL.format(k='q.ky'), pt, KY_TT.format(k='q.ky'),
                 str(ttc), "NULL", "NULL", ten, ten, f"'{dv}'", "NULL", "0", "NULL", "NULL",
                 tu, str(mau), gt, f"IF({gt} IS NULL, 0, 1)", "'NQ57 (CSDL số liệu NQ57)'", q(src),
                 "NULL", "NULL", "NULL", "NULL", "NULL", TS]) + "\n" + where_group


NOI_DUNG = phu("NOI_DUNG_XA", "'so_xa'", "'Số xã có kết quả'", "xã, phường", 9, "NULL", 126, "q.n", "q.pt",
               "Biểu 01 phần A: số xã trả lời 'Có' (B01_A01 mô hình, B01_A03 dữ liệu số, B01_A05 DVC)",
               f"""FROM (
    SELECT s.ky, t.pt, COUNT(DISTINCT s.ma_don_vi) n
    FROM {DB}.`nq57_solieu_truong` s
    JOIN (SELECT 'B01_A01' ma, 'Mô hình, sáng kiến nhân rộng' pt UNION ALL SELECT 'B01_A03', 'Dữ liệu số'
          UNION ALL SELECT 'B01_A05', 'DVC, TTHC') t ON t.ma = s.ma_truong
    WHERE s.ma_bieu = 'NQ57HN-B01' AND s.gia_tri_chu = 'Có'
    GROUP BY s.ky, t.pt
) q""")

XA_QT = phu("XA_QUAN_TAM", "c.ma", "c.ten", "nhiệm vụ", 10, "NULL", "NULL",
            "CASE c.ma WHEN 'tong_nhiem_vu' THEN q.tong WHEN 'hoan_thanh' THEN q.ht WHEN 'dang_qua_han' THEN q.qh ELSE q.xqh END",
            "q.ten_xa", "Biểu 01 phần B: xã có nhiệm vụ đang quá hạn (B01_B06 > 0); B01_B01, B01_B02, B01_B06, B01_B07",
            f"""FROM (
    SELECT ky, ma_don_vi, {TEN_XA.format(c='MAX(don_vi)')} ten_xa,
           SUM(IF(ma_truong = 'B01_B01', gia_tri_so, NULL)) tong, SUM(IF(ma_truong = 'B01_B02', gia_tri_so, NULL)) ht,
           SUM(IF(ma_truong = 'B01_B06', gia_tri_so, NULL)) qh,   SUM(IF(ma_truong = 'B01_B07', gia_tri_so, NULL)) xqh
    FROM {DB}.`nq57_solieu_truong`
    WHERE ma_bieu = 'NQ57HN-B01' AND ma_phan = 'B'
    GROUP BY ky, ma_don_vi
    HAVING qh > 0
) q
CROSS JOIN (SELECT 'tong_nhiem_vu' ma, 'Tổng nhiệm vụ' ten UNION ALL SELECT 'hoan_thanh', 'Hoàn thành'
            UNION ALL SELECT 'dang_qua_han', 'Đang quá hạn' UNION ALL SELECT 'xong_qua_han', 'Hoàn thành quá hạn') c""")

# phân loại điểm nghẽn theo từ khóa (không dấu hoa thường lẫn lộn -> so trên LOWER + utf8mb4_bin)
CHU_DE = {
    "ATTT, chữ ký số, cơ yếu": ["an toàn thông tin", "attt", "chữ ký số", "cơ yếu", "chứng thư", "an ninh mạng"],
    "Cơ chế, hướng dẫn, phân quyền": ["hướng dẫn", "cơ chế", "phân quyền", "quy định", "phân cấp", "thẩm quyền", "chưa có văn bản"],
    "Dữ liệu, chuẩn hóa, chia sẻ": ["dữ liệu", "chuẩn hóa", "làm sạch", "đồng bộ", "chia sẻ"],
    "DVC, TTHC, đảng phí": ["dịch vụ công", "dvc", "thủ tục", "tthc", "hồ sơ", "đảng phí"],
    "Hạ tầng, thiết bị, đường truyền": ["hạ tầng", "thiết bị", "máy tính", "đường truyền", "mạng", "máy chủ", "camera", "wifi", "internet"],
    "Kinh phí, mua sắm": ["kinh phí", "mua sắm", "ngân sách", "dự toán", "đấu thầu", "vốn"],
    "Nền tảng, phần mềm, liên thông": ["phần mềm", "nền tảng", "liên thông", "hệ thống", "kết nối", "tài khoản", "ứng dụng", "lỗi"],
    "Người dân, doanh nghiệp tiếp cận số": ["người dân", "doanh nghiệp", "người cao tuổi", "kỹ năng số của người"],
    "Nhân lực, kỹ năng số": ["nhân lực", "cán bộ", "kỹ năng", "đào tạo", "biên chế", "nhân sự", "chuyên trách"],
}
_kw = "\n          UNION ALL ".join(f"SELECT {q(cd)} cd, {q('%' + k + '%')} kw" for cd, ks in CHU_DE.items() for k in ks)
DIEM_NGHEN = phu("DIEM_NGHEN_XA", "'so_xa_phan_anh'", "'Số xã phản ánh'", "xã, phường", 10, "NULL", 126, "q.n", "q.cd",
                 "Biểu 01 phần F (B01_F01): phân loại tự động theo từ khóa, 1 xã có thể thuộc nhiều nhóm",
                 f"""FROM (
    SELECT f.ky, COALESCE(k.cd, 'Khác/không nêu rõ') cd, COUNT(DISTINCT f.ma_don_vi) n
    FROM (SELECT ky, ma_don_vi, so_dong, LOWER(CONVERT(gia_tri_chu USING utf8mb4)) COLLATE utf8mb4_bin AS txt
          FROM {DB}.`nq57_solieu_truong`
          WHERE ma_bieu = 'NQ57HN-B01' AND ma_truong = 'B01_F01' AND gia_tri_chu IS NOT NULL AND gia_tri_chu <> '') f
    LEFT JOIN (
          {_kw}
    ) k ON f.txt LIKE (CONVERT(k.kw USING utf8mb4) COLLATE utf8mb4_bin)
    GROUP BY f.ky, COALESCE(k.cd, 'Khác/không nêu rõ')
) q""")


def ins(select):
    # bọc bảng dẫn xuất: SELECT kết thúc bằng JOIN thì MySQL đọc "ON DUPLICATE" thành điều kiện ON của JOIN
    return f"INSERT INTO {OUT} ({COLS})\nSELECT * FROM (\n{select}\n) src\nON DUPLICATE KEY UPDATE {UPD}"


def tinh():
    return ("/* Tính chuyen_de_chi_tiet_nq57_test từ 4 bảng NQ57 + nq57_chi_so_anh_xa. NiFi thay ${sync_ts}. SINH TỰ ĐỘNG bởi build.py */\n"
            + ";\n\n".join([ins(CHI_SO_SELECT), ins(NOI_DUNG), ins(XA_QT), ins(DIEM_NGHEN),
                            f"DELETE FROM {OUT} WHERE sync_date < {TS}"]) + ";\n")


def kiem_tra():
    """SELECT thuần (chạy được trong SQL Lab) – bảng ánh xạ phải có trước."""
    sel = CHI_SO_SELECT.replace(TS, "NOW()")
    return sel


if __name__ == "__main__":
    open(os.path.join(HERE, "0_ddl.sql"), "w").write(DDL)
    open(os.path.join(HERE, "1_nap_anh_xa.sql"), "w").write(nap_anh_xa())
    open(os.path.join(HERE, "2_tinh_chuyen_de.sql"), "w").write(tinh())
    open(os.path.join(HERE, "3_kiem_tra_select.sql"), "w").write(kiem_tra())
    print('ghi đè bản cũ:', sorted(NEW.keys() & _old.M.keys()))
    print(len(MAPS), "chỉ số có ánh xạ:", sorted(NEW.keys() - _old.M.keys()))
