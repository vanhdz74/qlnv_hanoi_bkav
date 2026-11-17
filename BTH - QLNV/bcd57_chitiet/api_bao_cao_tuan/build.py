"""API báo cáo tuần NQ57 (đề cương "DE CUONG BAO CAO TUAN - UPDATE.docx") – 17/11/2026.

Sinh 1 câu SELECT trả về đúng 1 ô `bao_cao` = JSON đầy đủ (mục I.1 + phụ lục 01–04).
  python3 build.py            # ghi bao_cao_tuan.sql (mẫu NiFi, tham số ${p.tu} ${p.den} ${p.dv} ${p.ts})
  python3 build.py test [tu] [den] [dv]   # thay tham số, chạy qua Superset SQL Lab, in JSON

Tham số (NiFi đã kiểm định dạng trước khi thay vào):
  p.tu, p.den : 'YYYY-MM-DD' (tuần báo cáo)     p.dv : tiền tố id đơn vị chủ trì, '' = tất cả
  p.ts        : thời điểm NiFi nhận yêu cầu (MySQL lệch giờ nên không dùng NOW()).

Nguồn:
  nhóm 1 "Nhiệm vụ Thành phố giao" = qlnv_chitiet_captp_xp_bcd57 (1 dòng/đầu giao, cùng nguồn dashboard 272)
         cap_nhiem_vu='Cấp Thành phố' AND nguon_giao='Nhiệm vụ Thành phố'
  nhóm 2 "Nhiệm vụ giao cấp xã"    = qlnv_chitiet_captp_xp_bcd57_full, cap_nhiem_vu='Cấp Xã, phường' (1 dòng/xã nhận)
Quy ước (tạm, chờ TDNV xác nhận):
  hoàn thành       = tinh_trang 'Đã hoàn thành'; đang thực hiện = còn lại (gồm thường xuyên)
  cần tiếp tục xử lý = chưa HT và han_xu_ly < den
  đã quá thời hạn giao = cần tiếp tục xử lý + đã HT nhưng ngay_hoan_thanh > han_xu_ly
  sắp đến hạn      = chưa HT và den <= han_xu_ly <= cuối tháng của den
  hoàn thành trong tuần = đã HT và tu <= ngay_hoan_thanh <= den
  mức nguy cơ (PL04) = Cao: tiến độ < 50% và còn ≤ 7 ngày, hoặc tiến độ < 30%; Trung bình: < 80%; Thấp: còn lại
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "bao_cao_tuan.sql")

DV = "('${p.dv}' = '' OR id_don_vi_chu_tri = '${p.dv}' OR id_don_vi_chu_tri LIKE CONCAT('${p.dv}', '.%'))"
COLS = """task_id, ten_nhiem_vu, van_ban_giao, {co_quan} AS co_quan_chu_tri,
       NULLIF(han_xu_ly, '') AS han, NULLIF(ngay_giao, '') AS ngay_giao, NULLIF(ngay_hoan_thanh, '') AS ngay_ht,
       tinh_trang, tien_do, ket_qua_thuc_hien AS kq, kho_khan_vuong_mac AS kk"""

BASE = f"""(SELECT b.*,
       (b.tinh_trang = 'Đã hoàn thành') AS ht,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han < '${{p.den}}') AS can_xl,
       (b.tinh_trang <> 'Đã hoàn thành' AND b.han >= '${{p.den}}'
            AND b.han <= DATE_FORMAT(LAST_DAY('${{p.den}}'), '%Y-%m-%d')) AS sap_han
  FROM (
    SELECT 1 AS nhom, 'Nhiệm vụ Thành phố giao' AS nguon_giao, {COLS.format(co_quan="ten_don_vi_chu_tri")}
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57
     WHERE cap_nhiem_vu = 'Cấp Thành phố' AND nguon_giao = 'Nhiệm vụ Thành phố' AND {DV}
    UNION ALL
    SELECT 2, 'Nhiệm vụ giao cấp xã', {COLS.format(co_quan="COALESCE(NULLIF(ten_xa_phuong, ''), ten_don_vi_chu_tri)")}
      FROM datamart_hanoi.qlnv_chitiet_captp_xp_bcd57_full
     WHERE cap_nhiem_vu = 'Cấp Xã, phường' AND {DV}
  ) b)"""


def ds(alias, where, order, obj):
    """Danh sách có stt theo thứ tự `order` → JSON_ARRAYAGG."""
    return f"""(SELECT JSON_ARRAYAGG(JSON_OBJECT({obj})) FROM (
     SELECT x.*, (@{alias} := @{alias} + 1) AS stt FROM (
       SELECT * FROM {BASE} n WHERE {where} ORDER BY {order} LIMIT 100000) x
     CROSS JOIN (SELECT @{alias} := 0) i) {alias})"""


AGG = """COUNT(n.nhom) AS tong_so, COALESCE(SUM(n.ht), 0) AS hoan_thanh, COALESCE(SUM(n.can_xl), 0) AS can_xl,
                COALESCE(SUM(n.can_xl OR (n.ht AND n.han IS NOT NULL AND n.ngay_ht > n.han)), 0) AS qua_han_giao,
                COALESCE(SUM(n.sap_han), 0) AS sap_han,
                COALESCE(SUM(n.ngay_giao BETWEEN '${p.tu}' AND '${p.den}'), 0) AS giao_moi,
                COALESCE(SUM(n.ht AND n.ngay_ht BETWEEN '${p.tu}' AND '${p.den}'), 0) AS ht_tuan"""

# 2 dòng nguồn giao luôn có (0 nếu không có nhiệm vụ) + dòng Tổng số
PL01 = f"""(SELECT JSON_ARRAYAGG(JSON_OBJECT(
     'stt', stt, 'nguon_giao', nguon_giao,
     'tong_so', tong_so, 'hoan_thanh', hoan_thanh, 'dang_thuc_hien', tong_so - hoan_thanh,
     'da_qua_thoi_han_giao', qua_han_giao, 'can_tiep_tuc_xu_ly', can_xl,
     'sap_den_han', sap_han, 'giao_moi_trong_tuan', giao_moi, 'hoan_thanh_trong_tuan', ht_tuan,
     'bien_dong', CONCAT('Giao mới ', giao_moi, ', hoàn thành ', ht_tuan, ' nhiệm vụ trong tuần')))
   FROM (SELECT d.stt, d.nguon_giao, {AGG}
           FROM (SELECT 1 AS stt, 'Nhiệm vụ Thành phố giao' AS nguon_giao
                 UNION ALL SELECT 2, 'Nhiệm vụ giao cấp xã') d
           LEFT JOIN {BASE} n ON n.nhom = d.stt
          GROUP BY d.stt, d.nguon_giao
         UNION ALL
         SELECT NULL, 'Tổng số', {AGG} FROM {BASE} n) t)"""

MUC1 = f"""(SELECT JSON_OBJECT('tong_so', COUNT(*), 'hoan_thanh', COALESCE(SUM(ht), 0),
                           'dang_thuc_hien', COUNT(*) - COALESCE(SUM(ht), 0),
                           'qua_han', COALESCE(SUM(can_xl), 0)) FROM {BASE} n)"""

LIST_COMMON = "'stt', stt, 'task_id', task_id, 'nguon_giao', nguon_giao, 'ten_nhiem_vu', ten_nhiem_vu, " \
              "'van_ban_giao', van_ban_giao, 'co_quan_chu_tri', co_quan_chu_tri, "

PL02 = ds("s2", "n.ht AND n.ngay_ht BETWEEN '${p.tu}' AND '${p.den}'", "nhom, ngay_ht, task_id",
          LIST_COMMON + "'thoi_han_giao', han, 'ngay_ghi_nhan_hoan_thanh', ngay_ht, "
                        "'san_pham_phai_hoan_thanh', NULL, 'tai_lieu_kiem_chung', NULL")
PL03 = ds("s3", "n.can_xl", "nhom, han, task_id",
          LIST_COMMON + "'thoi_han_hoan_thanh', han, 'so_ngay_qua_han', DATEDIFF('${p.den}', han), "
                        "'ket_qua_thuc_hien', kq, 'nguyen_nhan_vuong_mac', kk")
PL04 = ds("s4", "n.sap_han", "nhom, han, task_id",
          LIST_COMMON + "'thoi_han_hoan_thanh', han, 'tien_do', tien_do, 'san_pham_phai_hoan_thanh', NULL, "
                        "'muc_nguy_co', CASE WHEN (COALESCE(tien_do, 0) < 50 AND DATEDIFF(han, '${p.den}') <= 7) "
                        "OR COALESCE(tien_do, 0) < 30 THEN 'Cao' WHEN COALESCE(tien_do, 0) < 80 THEN 'Trung bình' "
                        "ELSE 'Thấp' END")
DS_QH = f"(SELECT JSON_ARRAYAGG(ten_nhiem_vu) FROM {BASE} n WHERE n.can_xl)"

SQL = f"""/* API báo cáo tuần NQ57 – sinh bởi build.py, KHÔNG sửa tay */
SELECT CAST(JSON_OBJECT(
  'tu_ngay', '${{p.tu}}', 'den_ngay', '${{p.den}}', 'id_don_vi', '${{p.dv}}', 'thoi_diem', '${{p.ts}}',
  'muc_1_tinh_hinh_nhiem_vu', JSON_SET({MUC1}, '$.ds_qua_han', COALESCE({DS_QH}, JSON_ARRAY())),
  'phu_luc_01', {PL01},
  'phu_luc_02', COALESCE({PL02}, JSON_ARRAY()),
  'phu_luc_03', COALESCE({PL03}, JSON_ARRAY()),
  'phu_luc_04', COALESCE({PL04}, JSON_ARRAY())
) AS CHAR CHARACTER SET utf8mb4) AS bao_cao
"""

if __name__ == "__main__":
    open(OUT, "w", encoding="utf-8").write(SQL)
    print("ghi", OUT, len(SQL), "ký tự")
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        tu, den = (sys.argv[2:4] + ["2026-11-10", "2026-11-16"][len(sys.argv[2:4]):])[:2]
        dv = sys.argv[4] if len(sys.argv) > 4 else ""
        q = SQL.replace("${p.tu}", tu).replace("${p.den}", den).replace("${p.dv}", dv).replace("${p.ts}", "test")
        sys.path.insert(0, "/home/truongnbn/Documents/Superset,/QLNV/docs/nq57_solieu")
        import sqllab
        r = sqllab.run(q)
        if "error" in r or not r.get("data"):
            print(json.dumps(r, ensure_ascii=False)[:2000]); sys.exit(1)
        d = json.loads(r["data"][0]["bao_cao"])
        out = os.path.join(os.environ.get("OUT_DIR", HERE), "mau_tra_ve.json")
        json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("muc_1:", json.dumps({k: v for k, v in d["muc_1_tinh_hinh_nhiem_vu"].items() if k != "ds_qua_han"}, ensure_ascii=False),
              "| ds_qua_han:", len(d["muc_1_tinh_hinh_nhiem_vu"]["ds_qua_han"]))
        for r1 in d["phu_luc_01"]:
            print("PL01", json.dumps(r1, ensure_ascii=False))
        for k in ("phu_luc_02", "phu_luc_03", "phu_luc_04"):
            print(k, len(d[k]), "dòng; dòng đầu:", json.dumps({a: (str(b)[:40] if b else b) for a, b in (d[k][0].items() if d[k] else [])}, ensure_ascii=False))
        print("JSON", len(json.dumps(d, ensure_ascii=False)), "ký tự →", out)
