"""Trích các nhiệm vụ trong phụ lục báo cáo tháng (tai_lieu/BC tháng 2-10) -> phu_luc_nhiem_vu.json.

Mỗi bảng có cột "tên nhiệm vụ" (+ cơ quan/đơn vị chủ trì) được coi là bảng nhiệm vụ.
Cột được nhận diện theo từ khóa ở dòng tiêu đề (tiêu đề lặp lại ở mỗi trang PDF).
Cần: python-docx, pdfplumber.  Chạy:  python trich_phu_luc.py
"""
import json, os, re, unicodedata
import docx, pdfplumber
from docx.oxml.ns import qn
from docx.table import Table

W = os.path.dirname(os.path.abspath(__file__))
TL = os.path.join(W, "..", "..", "tai_lieu")
THANG = [2, 3, 4, 5, 6, 7, 8, 9, 10]


def clean(s):
    s = unicodedata.normalize("NFC", str(s or ""))
    return re.sub(r"\s+", " ", s.replace("\n", " ")).strip()


def kw(h):
    return clean(h).lower()


# (khóa, hàm nhận diện tiêu đề cột) - lấy cột đầu tiên khớp
COT = [
    ("ten", lambda h: ("nhiệm vụ" in h and "nguồn" not in h and "nhóm" not in h) or h.startswith("tên văn bản")),
    ("vb", lambda h: "văn bản giao" in h or h.startswith("vb giao") or h == "văn bản giao"),
    ("dv", lambda h: "chủ trì" in h),
    ("han", lambda h: "thời hạn" in h or h == "hạn"),
    ("tinh_trang", lambda h: h in ("tình trạng", "trạng thái hiện nay", "đánh giá tiến độ") or h.startswith("tiến độ")
        or h.startswith("tình trạng")),
    ("ket_qua", lambda h: h.startswith("kết quả") or h.startswith("tình hình thực hiện") or h.startswith("kết luận")),
    ("de_xuat", lambda h: "đề xuất" in h or "kiến nghị" in h or "yêu cầu" in h),
]


def map_cot(header):
    hs = [kw(h) for h in header]
    m = {}
    for k, f in COT:
        for i, h in enumerate(hs):
            if i not in m.values() and h and f(h):
                m[k] = i
                break
    return m if "ten" in m and "dv" in m else None


def la_muc(cells, m):
    """Dòng tiêu đề nhóm: 'I.', 'NHÓM I: ...', cả dòng cùng 1 nội dung."""
    vals = [c for c in cells if c]
    return len(set(vals)) == 1 and len(vals) >= 2 or (cells[0] and re.fullmatch(r"[IVX]+\.?", cells[0]) and
                                                       (not cells[m["dv"]] or cells[m["dv"]] == cells[m["ten"]]))


def tieu_de(text, state):
    """Dòng chữ ngoài bảng: 'PHỤ LỤC 03' + dòng tên phụ lục ngay sau; 'I. DANH MỤC ...' (mục in hoa)."""
    t = clean(text)
    if not t or re.fullmatch(r"[-_*. ]+", t):
        return
    if re.match(r"PHỤ (LỤC|BIỂU)\b", t):
        state.update(phu_luc=t[:255], cho_ten=len(t) < 20, muc="", co_stt=False)
    elif state.get("cho_ten"):
        if not t.startswith("("):
            state["phu_luc"] = (state["phu_luc"] + " - " + t)[:255]
        state["cho_ten"] = False
    elif re.match(r"(I|II|III|IV|V|VI|VII|VIII)\.\s+\S", t) and t == t.upper() and len(t) < 200:
        state["muc"] = t[:255]


def loai_ds(r):
    """Loại danh sách suy ra từ tên mục (ưu tiên) hoặc tên phụ lục."""
    for la_muc_, src in ((True, r.get("muc", "")), (False, r.get("phu_luc", ""))):
        S = src.upper()
        if "QUÁ" in S or "CHẬM" in S:
            return "Quá hạn, chậm muộn"
        if "NGUY CƠ" in S:
            return "Nguy cơ chậm"
        if "HẠN TRONG" in S or "ĐẾN HẠN" in S or "CÓ HẠN" in S:
            return "Đến hạn trong kỳ"
        if "HOÀN THÀNH" in S and not la_muc_:     # mục 'Nhóm II: đã hoàn thành một phần...' không tính
            return "Hoàn thành"
    return "Theo dõi"


def doc_bang(rows, ky, nguon, out, state):
    if not rows:
        return
    r0 = [clean(c) for c in rows[0]]
    if len(set(r0)) == 1 and re.match(r"PHỤ (LỤC|BIỂU)", r0[0].upper()):   # bảng tiêu đề 'PHỤ BIỂU 1 | Bảng ...'
        ten = clean(rows[1][0]) if len(rows) > 1 else ""
        state.update(phu_luc=(r0[0] + (" - " + ten if ten else ""))[:255], muc="", co_stt=False, cho_ten=False)
        return
    m = map_cot(rows[0])
    if m:
        hdr = [kw(h) for h in rows[0]]
        if hdr != state.get("hdr"):
            state["co_stt"] = False          # sang bảng khác -> không nối vào dòng của bảng trước
        state["m"], state["hdr"] = m, hdr
        body = rows[1:]
    elif state.get("m") and len(rows[0]) == len(state["hdr"]) and not kw(rows[0][0]).startswith("stt"):
        m, body = state["m"], rows          # bảng nối trang không lặp tiêu đề
    else:
        state["m"] = None
        return
    for r in body:
        cells = [clean(c) for c in r]
        if len(cells) <= max(m.values()) or not any(cells):
            continue
        if la_muc(cells, m):
            state["muc"] = max(cells, key=len)[:255]
            continue
        ten = cells[m["ten"]]
        if not ten or kw(ten) in ("tên nhiệm vụ", "nhiệm vụ"):
            continue
        stt = cells[0] if m["ten"] != 0 else ""
        rec = {k: (cells[i] if i < len(cells) else "") for k, i in m.items()}
        # dòng nối tiếp (cắt sang trang mới / PDF tách từng dòng chữ): không STT, sau 1 dòng có STT -> nối vào dòng trước
        if out and not stt and out[-1]["ky"] == ky and (state.get("co_stt") or not rec.get("dv")):
            for k, v in rec.items():
                if v:
                    out[-1][k] = (out[-1].get(k, "") + " " + v).strip()
            continue
        state["co_stt"] = bool(stt)
        out.append(dict(ky=ky, nguon=nguon, phu_luc=state.get("phu_luc", ""), muc=state.get("muc", ""), stt=stt, **rec))


def trich():
    out = []
    for t in THANG:
        ky = f"T{t}/2026"
        state = {}
        p = os.path.join(TL, f"BC tháng {t}.docx")
        if os.path.exists(p):
            d = docx.Document(p)
            i = 0
            for el in d.element.body.iterchildren():      # đoạn văn + bảng theo đúng thứ tự trong văn bản
                if el.tag == qn("w:p"):
                    van = "".join((x.text or "") if x.tag == qn("w:t") else "\n" for x in el.iter(qn("w:t"), qn("w:br")))
                    for dong in van.split("\n"):
                        tieu_de(dong, state)
                elif el.tag == qn("w:tbl"):
                    i += 1
                    rows = [[c.text for c in r.cells] for r in Table(el, d).rows]
                    doc_bang(rows, ky, f"BC tháng {t}/2026 - bảng {i}", out, state)
        else:
            with pdfplumber.open(os.path.join(TL, f"BC tháng {t}.pdf")) as pdf:
                for pi, pg in enumerate(pdf.pages):
                    tbs = pg.find_tables()
                    # bảng không kẻ ngang từng dòng -> pdfplumber tách theo dòng chữ (nhiều dòng trống STT):
                    # tách lại theo các đường kẻ ngang thật của trang (ranh giới giữa các nhiệm vụ)
                    if any(len(x) > 12 and sum(1 for r in x if not clean(r[0])) > len(x) / 2 for x in (b.extract() for b in tbs)):
                        hs = sorted({l["top"] for l in pg.lines if abs(l["top"] - l["bottom"]) < 1})
                        if len(hs) >= 2:
                            tbs = pg.find_tables({"horizontal_strategy": "explicit", "explicit_horizontal_lines": hs,
                                                  "vertical_strategy": "lines"})
                    tbs = sorted(tbs, key=lambda b: b.bbox[1])
                    # dòng chữ ngoài bảng (tên phụ lục, tên mục) xử lý theo thứ tự từ trên xuống, xen kẽ với bảng
                    dong = [l for l in pg.extract_text_lines()
                            if not any(b.bbox[1] - 1 <= l["top"] <= b.bbox[3] + 1 for b in tbs)]
                    for b in tbs + [None]:
                        top = b.bbox[1] if b else 1e9
                        while dong and dong[0]["top"] < top:
                            tieu_de(dong.pop(0)["text"], state)
                        if b:
                            doc_bang(b.extract(), ky, f"BC tháng {t}/2026 - trang {pi + 1}", out, state)
    # thứ tự trong kỳ
    n = {}
    for r in out:
        n[r["ky"]] = n.get(r["ky"], 0) + 1
        r["thu_tu"] = n[r["ky"]]
        r["loai_danh_sach"] = loai_ds(r)
    return out


if __name__ == "__main__":
    ds = trich()
    json.dump(ds, open(os.path.join(W, "phu_luc_nhiem_vu.json"), "w"), ensure_ascii=False, indent=1)
    from collections import Counter
    print(len(ds), Counter(r["ky"] for r in ds))
