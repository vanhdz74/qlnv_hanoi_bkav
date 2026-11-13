"""Sinh SQL ánh xạ datamart_hanoi.v_nq57_solieu (NQ57, nguồn chính) -> cấu trúc cột của chuyen_de_chi_tiet_nq57
để dashboard nq57-chuyen-de-chi-tiet (dataset 145) đọc thẳng từ NQ57, không dùng số bóc từ báo cáo tháng nữa.

  python3 build_sql.py   -> ghi v_chuyen_de_nq57.sql cạnh file này

Quy ước giữ nguyên như bảng cũ (chart.tpl.js dựa vào):
  - dv = '%'           -> gia_tri là tỷ lệ 0..1
  - có tử số + mẫu số  -> tu_so, mau_so lưu riêng, gia_tri = tu/mau (KPI hiện "tu/mau", gauge/đường % dùng gia_tri)
  - chỉ số chưa có nguồn NQ57 -> vẫn có dòng, gia_tri NULL, co_so_lieu = 0 (dashboard hiện "!")
Danh mục (tên, chuyên đề, ngưỡng, đầu mối...) lấy từ các dòng CHI_SO của bảng cũ — chỉ metadata, không lấy số.
NQ57 ghi cùng 1 chỉ tiêu ở cả biểu gốc lẫn biểu tổng hợp TH-*: có dòng TH-* thì lấy dòng đó, không thì cộng biểu gốc.
MySQL 5.7: không CTE, chỉ dùng bảng dẫn xuất.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = "datamart_hanoi.v_nq57_solieu"
OLD = "datamart_hanoi.chuyen_de_chi_tiet_nq57"

PB = ("sum", ["B03_A_DT_PHANBO", "B03_A_TX_TINH_PHANBO", "B03_A_TX_XA_PHANBO"])
GN_ALL = ("sum", ["B03_A_DT_GN_LK", "B03_A_TX_TINH_GN_LK", "B03_A_TX_XA_GN_LK", "B03_A_CN_GN_LK"])
DT_ALL = ("sum", ["B03_A_DT_DUTOAN", "B03_A_TX_TINH_DUTOAN", "B03_A_TX_XA_DUTOAN", "B03_A_CN_DUTOAN"])
XA = lambda m: ("if_pos", "TH05_XA_SO", m)   # TH-05 các kỳ cũ ghi 0 khi chưa nhập -> chỉ lấy khi có tổng số xã

# ma_chi_so: (tu, mau, can_ty_le, he_so)
#   mau None -> gia_tri = tu * he_so ; mau có -> gia_tri = tu/mau
#   can_ty_le=True và thiếu mẫu -> gia_tri NULL (gauge/đường % không hiểu số đếm)
M = {
    "TC01": ("TH00_27", None), "TC02": (PB, None),
    "TC03": (PB, "TH00_27"),
    "TC04": ("B03_A_DT_PHANBO", "B03_A_DT_DUTOAN"),
    "TC05": (("sum", ["B03_A_TX_TINH_PHANBO", "B03_A_TX_XA_PHANBO"]), ("sum", ["B03_A_TX_TINH_DUTOAN", "B03_A_TX_XA_DUTOAN"])),
    "TC06": ("B03_A_TX_TINH_GN_LK", "B03_A_TX_TINH_DUTOAN"),
    "TC07": ("B03_A_TX_XA_GN_LK", "B03_A_TX_XA_DUTOAN"),
    "TC08": ("B03_A_DT_GN_LK", "B03_A_DT_DUTOAN"),
    "TC09": ("TH00_28", "TH00_27"),
    "TC10": ("B03_B01", None), "TC11": ("B03_B02", None),
    "TC12": (("-", "TH00_27", PB), None),
    "TC13": (GN_ALL, DT_ALL),
    "DD01": ("B07_A01", None), "DD04": ("B07_A03", None), "DD05": ("B07_A03", "B07_A01"),
    "DL01": ("B04_A02", "B04_A01"), "DL05": ("B04_A07", None, True), "DL06": ("B04_A06", None),
    "DL08": ("B04_A05", "B04_A01"), "DL09": ("B04_A10", None),
    "TT05": ("B06_B02", None), "TT06": ("B06_B02", "B06_B01"), "TT07": ("B06_B05", None),
    "TT08": ("B06_B08", "B06_B07"), "TT10": ("B06_A_766", None), "TT12": ("B06_A_DATLICH", None),
    "TT13": ("B06_A_TGPV", None), "TT14": ("B06_B09", "B06_B07", True), "TT15": ("B06_D01", None),
    "TT16": ("B06_D02", "B06_D01"), "TT17": ("B04_F01", None),
    "NT01": ("B04_C03", None), "NT02": ("B04_C03", "B04_C02"), "NT03": ("B04_C01", None),
    "NT04": ("B04_C05", None), "NT05": ("B04_C10", None), "NT07": ("B04_C12", None),
    "NT08": ("B09_A01", None), "NT09": ("B09_A03", None), "NT10": ("B09_A10", "B09_A09"),
    "NT11": ("B09_B01", None), "NT12": ("B09_B03", "B09_B02"), "NT13": ("B09_B04", "B09_B02"),
    "NT14": ("B09_B05", None), "NT15": ("B09_B07", None),
    "CS07": (XA("TH05_XA_MOHINH"), "TH05_XA_SO", True), "CS08": (XA("TH05_XA_DULIEU"), "TH05_XA_SO", True),
    "CS09": (XA("TH05_XA_DVC"), "TH05_XA_SO", True),
    "CS15": ("B01_C01", None), "CS16": ("B01_C02", None), "CS17": ("B10_A03", 126), "CS18": ("B10_A04", None),
    "KH01": ("B11_A01", None, False, 0.01), "KH02": ("B11_A02", None, False, 0.01), "KH03": ("B11_A03", None, False, 0.01),
    "KH04": ("B05_D02", "B05_D01"), "KH06": ("B05_B_DEXUAT_LK", None), "KH07": ("B05_B_DATHANG_LK", None),
    "KH08": ("B05_B_BTUT_LK", None), "KH09": ("B05_E_CHUYENGIA_LK", None), "KH10": ("B05_E_TEX_TK_LK", None),
    "KH11": ("B05_E_TEX_DN_LK", None), "KH12": ("B05_E_TEX_GP_LK", None), "KH14": ("B05_E_DNKHCN_LK", None),
    "KH15": ("B05_E_SB_DX_LK", None),
    "AT01": ("B08_A02", None), "AT02": ("B08_A02", "B08_A01"), "AT03": ("B08_A03", None),
    "AT04": ("B08_A04", None), "AT05": ("B08_A11", None), "AT06": ("B08_A12", None),
    "AT07": ("B08_A08", None), "AT08": ("B08_A07", None), "AT09": ("B08_A14", "B08_A13"),
}


def codes(e, out):
    if isinstance(e, str):
        out.add(e)
    elif isinstance(e, tuple):
        for x in e[1:]:
            for y in (x if isinstance(x, list) else [x]):
                codes(y, out)
    return out


def sql(e):
    if e is None:
        return "NULL"
    if isinstance(e, (int, float)):
        return repr(e)
    if isinstance(e, str):
        return f"p.`{e}`"
    op = e[0]
    if op == "sum":
        xs = [sql(x) for x in e[1]]
        return f"(CASE WHEN COALESCE({', '.join(xs)}) IS NULL THEN NULL ELSE {' + '.join(f'IFNULL({x},0)' for x in xs)} END)"
    if op == "-":
        return f"({sql(e[1])} - {sql(e[2])})"
    if op == "if_pos":
        return f"IF({sql(e[1])} > 0, {sql(e[2])}, NULL)"
    raise ValueError(op)


def build():
    allc = sorted(set().union(*(codes(v[0], set()) | codes(v[1], set()) for v in M.values())))
    piv = ",\n            ".join(f"MAX(IF(b.m = '{c}', b.v, NULL)) AS `{c}`" for c in allc)
    tu_cases, mau_cases, gt_cases = [], [], []
    for ma, spec in sorted(M.items()):
        tu, mau = spec[0], spec[1]
        can = spec[2] if len(spec) > 2 else False
        hs = spec[3] if len(spec) > 3 else None
        t, m = sql(tu), sql(mau)
        if mau is not None:
            tu_cases.append(f"WHEN '{ma}' THEN {t}")
            mau_cases.append(f"WHEN '{ma}' THEN {m}")
            gt_cases.append(f"WHEN '{ma}' THEN {t} / NULLIF({m}, 0)")
        elif can:
            tu_cases.append(f"WHEN '{ma}' THEN {t}")
            gt_cases.append(f"WHEN '{ma}' THEN NULL")
        else:
            gt_cases.append(f"WHEN '{ma}' THEN {t}" + (f" * {hs}" if hs else ""))
    ind = "\n                "
    mas = " UNION ALL ".join(f"SELECT '{m}' AS ma" for m in sorted(M))
    return f"""/* SINH TỰ ĐỘNG bởi build_sql.py — không sửa tay.
   Dataset dashboard nq57-chuyen-de-chi-tiet: số liệu lấy từ {SRC} (NQ57), cột giống {OLD}.
   Danh mục chỉ số (tên/chuyên đề/ngưỡng/đầu mối) lấy từ các dòng CHI_SO của bảng cũ; số liệu bảng cũ KHÔNG dùng. */
SELECT
    'CHI_SO'                       AS nhom_du_lieu,
    dm.ma_chi_so,
    k.ky,
    ''                             AS phan_to,
    k.thu_tu_ky,
    dm.thu_tu_chi_so, dm.stt_chuyen_de, dm.chuyen_de, dm.ten_chi_so, dm.ten_ngan, dm.don_vi_tinh,
    dm.loai_chi_so, dm.giam_la_tot, dm.nguong, dm.ten_nguong,
    x.tu_so, x.mau_so, x.gia_tri,
    IF(x.gia_tri IS NULL, 0, 1)    AS co_so_lieu,
    IF(x.gia_tri IS NULL, NULL, CONCAT('NQ57 – cập nhật ', DATE_FORMAT(k.cap_nhat_luc, '%d/%m/%Y %H:%i'))) AS nguon_so_lieu,
    NULL AS vi_tri, NULL AS trich_dan,
    dm.dau_moi, dm.luu_y,
    IF(x.gia_tri IS NULL AND x.ma IS NOT NULL, 'NQ57 chưa có số kỳ này', IF(x.ma IS NULL, 'Chưa có chỉ tiêu tương ứng trong NQ57', NULL)) AS ghi_chu,
    NULL AS thong_tin_them,
    k.sync_date
FROM (
    SELECT ma_chi_so,
           MAX(thu_tu_chi_so) thu_tu_chi_so, MAX(stt_chuyen_de) stt_chuyen_de, MAX(chuyen_de) chuyen_de,
           MAX(ten_chi_so) ten_chi_so, MAX(ten_ngan) ten_ngan, MAX(don_vi_tinh) don_vi_tinh, MAX(loai_chi_so) loai_chi_so,
           MAX(giam_la_tot) giam_la_tot, MAX(nguong) nguong, MAX(ten_nguong) ten_nguong, MAX(dau_moi) dau_moi, MAX(luu_y) luu_y
    FROM {OLD}
    WHERE nhom_du_lieu = 'CHI_SO'
    GROUP BY ma_chi_so
) dm
CROSS JOIN (
    SELECT ky AS ky_nq57,
           CONCAT('T', CAST(RIGHT(ky, 2) AS UNSIGNED), '/', LEFT(ky, 4)) AS ky,
           CAST(RIGHT(ky, 2) AS UNSIGNED) - 1 + (CAST(LEFT(ky, 4) AS UNSIGNED) - 2026) * 12 AS thu_tu_ky,
           MAX(cap_nhat_luc) cap_nhat_luc, MAX(sync_date) sync_date
    FROM {SRC}
    WHERE loai_so = 'ACTUAL' AND ky LIKE '____M__'  -- không dùng REGEXP: Superset đổi thành REGEXP_LIKE, MySQL 5.7 không có
    GROUP BY ky
) k
LEFT JOIN (
    SELECT mp.ma, p.ky,
           CASE mp.ma{ind}{ind.join(tu_cases)}
           END AS tu_so,
           CASE mp.ma{ind}{ind.join(mau_cases)}
           END AS mau_so,
           CASE mp.ma{ind}{ind.join(gt_cases)}
           END AS gia_tri
    FROM (
        SELECT b.ky,
            {piv}
        FROM (
            SELECT ma_chi_tieu AS m, ky,
                   COALESCE(MAX(IF(ma_bieu LIKE 'NQ57HN-TH%', gia_tri, NULL)),
                            SUM(IF(ma_bieu LIKE 'NQ57HN-TH%', NULL, gia_tri))) AS v
            FROM {SRC}
            WHERE loai_so = 'ACTUAL' AND ma_phan_to = 'TONG' AND gia_tri IS NOT NULL
            GROUP BY ma_chi_tieu, ky
        ) b
        GROUP BY b.ky
    ) p
    CROSS JOIN ({mas}) mp
) x ON x.ma = dm.ma_chi_so AND x.ky = k.ky_nq57
"""


if __name__ == "__main__":
    out = os.path.join(HERE, "v_chuyen_de_nq57.sql")
    open(out, "w").write(build())
    print(out, len(M), "chỉ số ánh xạ")
