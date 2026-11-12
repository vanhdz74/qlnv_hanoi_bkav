"""Thay các dòng T10/2026 trong phu_luc_nhiem_vu.json (trước đây lấy từ BC tuần 41 'BC tháng 10.pdf')
bằng Phụ lục 02 của 'tai_lieu/BC_CQTT_bao cao thang 10.2026_K.docx' (BC tháng 10/2026, chốt 17h00 14/10/2026):
  bảng 4 = I. Danh mục nhiệm vụ chậm muộn (9), bảng 5 = II. Nhiệm vụ có hạn trong tháng 10/2026 (3).
Đọc docx bằng zipfile (không cần python-docx).  Chạy:  python t10_docx.py && python build_sql.py
"""
import json, os, re, unicodedata, zipfile
from xml.etree import ElementTree as ET

W = os.path.dirname(os.path.abspath(__file__))
DOCX = os.path.join(W, "..", "..", "tai_lieu", "BC_CQTT_bao cao thang 10.2026_K.docx")
KY = "T10/2026"
PL = "PHỤ LỤC 02 - DANH MỤC CÁC NHIỆM VỤ CHẬM MUỘN; NHIỆM VỤ CÓ HẠN TRONG THÁNG 10/2026"
NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def clean(s):
    return re.sub(r"\s+", " ", unicodedata.normalize("NFC", s or "")).strip()


def bang():
    body = ET.fromstring(zipfile.ZipFile(DOCX).read("word/document.xml")).find(NS + "body")
    ds = []
    for t in body.findall(NS + "tbl"):
        ds.append([[clean(" ".join("".join(x.text or "" for x in p.iter(NS + "t")) for p in tc.iter(NS + "p")))
                    for tc in tr.findall(NS + "tc")] for tr in t.iter(NS + "tr")])
    return ds


B = bang()
qh, dh = B[3], B[4]
assert qh[0][1] == "Tên nhiệm vụ" and qh[0][8].startswith("Yêu cầu xử lý"), qh[0]
assert dh[0][5].startswith("Tiến độ") and dh[0][7] == "Mức nguy cơ", dh[0]
moi = []
for r in qh[1:]:
    moi.append(dict(ky=KY, nguon="BC tháng 10/2026 - bảng 4", phu_luc=PL, muc="I. DANH MỤC CÁC NHIỆM VỤ CHẬM MUỘN",
                    stt=r[0], ten=r[1], vb=r[2], dv=r[3], han=r[4], ket_qua=r[5], de_xuat=r[8],
                    loai_danh_sach="Quá hạn, chậm muộn"))
for r in dh[1:]:
    moi.append(dict(ky=KY, nguon="BC tháng 10/2026 - bảng 5", phu_luc=PL, muc="II. DANH MỤC NHIỆM VỤ CÓ HẠN TRONG THÁNG 10/2026",
                    stt=r[0], ten=r[1], vb=r[2], dv=r[3], han=r[4], tinh_trang=r[5] + (" | Mức nguy cơ: " + r[7] if r[7] else ""),
                    loai_danh_sach="Đến hạn trong kỳ"))
for i, r in enumerate(moi):
    r["thu_tu"] = i + 1

p = os.path.join(W, "phu_luc_nhiem_vu.json")
cu = json.load(open(p))
print("bo", sum(r["ky"] == KY for r in cu), "dong T10 cu (tuan 41) -> them", len(moi))
json.dump([r for r in cu if r["ky"] != KY] + moi, open(p, "w"), ensure_ascii=False, indent=1)
