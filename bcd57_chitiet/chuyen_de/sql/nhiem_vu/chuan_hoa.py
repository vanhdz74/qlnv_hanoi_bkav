"""Chuẩn hóa tên nhiệm vụ / số văn bản - PHẢI khớp 1-1 với biểu thức SQL trong build_sql.py (SQL_TEN, SQL_VB)."""
import re, unicodedata

# Các ký tự thay bằng dấu cách (cùng danh sách dùng trong SQL REPLACE lồng nhau)
DAU = [",", ".", ";", ":", "(", ")", "[", "]", '"', "“", "”", "'", "‘", "’", "-", "–", "—", "/", "\\", "!", "?",
       "…", "%", "+", "&", "*", "\n", "\r", "\t", "«", "»", "•"]


def ten(s):
    s = unicodedata.normalize("NFC", str(s or "")).lower()
    for c in DAU:
        s = s.replace(c, " ")
    return re.sub(r" +", " ", s).strip()


def don_vi(s):
    """Tên cơ quan: như ten() + 'thành phố' -> 'tp', bỏ 'hà nội' (qlnv hay viết 'Đảng ủy UBND TP')."""
    x = " " + ten(s) + " "
    return x.replace(" thành phố ", " tp ").replace(" hà nội ", " ").strip()


def doan(s, ti_le=0.5, toi_thieu=6, vi_tri=0.5):
    """Đoạn liên tục ~ti_le số từ, tâm đặt tại vi_tri (0..1) của tên đã chuẩn hóa."""
    w = ten(s).split()
    n = len(w)
    m = min(n, max(toi_thieu, int(round(n * ti_le))))
    a = int(round((n - m) * vi_tri))
    return " ".join(w[a:a + m])


def vb_khoa(s):
    """'KH 20' / '20- KH/BCĐ57' -> '20-KH';  '59 -TB/VPTU' -> '59-TB';  'Quyết định số 11/QĐ-BCĐCP' -> '11/QĐ'."""
    s = unicodedata.normalize("NFC", str(s or "")).upper()
    m = re.search(r"(\d+)\s*-\s*([A-ZĐ]+)", s)
    if m:
        return f"{m.group(1)}-{m.group(2)}"
    m = re.search(r"(\d+)\s*/\s*([A-ZĐ]+)", s)
    if m:
        return f"{m.group(1)}/{m.group(2)}"
    m = re.search(r"\b(KH|TB|KL|QĐ|CV)\s*(?:SỐ\s*)?(\d+)", s)
    if m:
        return f"{m.group(2)}-{m.group(1)}"
    return ""


def vb_qlnv(s):
    """Chuẩn hóa van_ban_giao bên qlnv để so tiền tố với vb_khoa: bỏ 'Số:', bỏ dấu cách, chữ hoa."""
    s = unicodedata.normalize("NFC", str(s or "")).upper()
    for x in ("SỐ:", "SỐ", " "):
        s = s.replace(x, "")
    return s
