"""Sinh SQL cho luồng NiFi so khớp nhiệm vụ phụ lục <-> qlnv:
   0_ddl.sql      : bảng đích datamart_hanoi.chuyen_de_chi_tiet_nhiem_vu_nq57
   1_so_khop.sql  : nạp nhiệm vụ phụ lục (phu_luc_nhiem_vu.json) + so khớp theo đoạn giữa tiêu đề với
                    datamart_hanoi.qlnv_chitiet_captp_xp_bcd57 (cấp Thành phố) + ghi bảng đích.
Chạy: python trich_phu_luc.py && python build_sql.py
"""
import json, os
from chuan_hoa import DAU, ten, doan, vb_khoa, don_vi

W = os.path.dirname(os.path.abspath(__file__))
DB = "`datamart_hanoi`"
DICH = f"{DB}.`chuyen_de_chi_tiet_nhiem_vu_nq57`"
QLNV = f"{DB}.`qlnv_chitiet_captp_xp_bcd57`"
T_PL, T_Q, T_HIT, T_DEM = (f"{DB}.`_cdnq57_{x}`" for x in ("pl", "q", "hit", "dem"))
CO = "utf8mb4_unicode_ci"


def lit(v):
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).replace("\\", "\\\\").replace("'", "''").replace("\n", " ").replace("\r", " ")
    s = s.replace("${", "$ {")          # tránh NiFi Expression Language trong GenerateFlowFile
    return "'" + s + "'"


def sql_char(c):
    return {"\n": "CHAR(10)", "\r": "CHAR(13)", "\t": "CHAR(9)"}.get(c) or lit(c)


def sql_ten(col):
    """Biểu thức SQL tương đương chuan_hoa.ten() (trừ NFC: dữ liệu qlnv đã ở dạng NFC)."""
    e = f"LOWER(COALESCE({col}, ''))"
    for c in DAU:
        e = f"REPLACE({e}, {sql_char(c)}, ' ')"
    for _ in range(5):                    # gộp tối đa 32 dấu cách liên tiếp
        e = f"REPLACE({e}, '  ', ' ')"
    return f"CONCAT(' ', TRIM({e}), ' ')"


def sql_dv(col):
    """Tương đương chuan_hoa.don_vi() (kết quả có dấu cách 2 đầu)."""
    return f"REPLACE(REPLACE({sql_ten(col)}, ' thành phố ', ' tp '), ' hà nội ', ' ')"


def sql_vb(col):
    return f"REPLACE(REPLACE(REPLACE(UPPER(COALESCE({col}, '')), 'SỐ:', ''), 'SỐ', ''), ' ', '')"


THU_TU_KY = {f"T{t}/2026": t - 1 for t in range(2, 13)}
PL = json.load(open(os.path.join(W, "phu_luc_nhiem_vu.json")))
for p in PL:
    p["d1"] = doan(p["ten"])                       # đoạn giữa ~50% số từ
    p["d2"] = doan(p["ten"], 0.4, 6, 0.0)          # đoạn đầu ~40%
    p["d3"] = doan(p["ten"], 0.4, 6, 1.0)          # đoạn cuối ~40%
    p["vb_khoa"] = vb_khoa(p.get("vb", ""))
    p["dv_chuan"] = don_vi(p.get("dv", ""))            # cơ quan chủ trì trong phụ lục (đã chuẩn hóa)

COT_PL = [("ky", "VARCHAR(20) NOT NULL"), ("thu_tu_ky", "INT NULL"), ("thu_tu", "INT NOT NULL"),
          ("nguon", "VARCHAR(255) NULL"), ("phu_luc", "VARCHAR(255) NULL"), ("loai_danh_sach", "VARCHAR(50) NULL"),
          ("muc", "VARCHAR(255) NULL"), ("stt", "VARCHAR(20) NULL"),
          ("ten", "TEXT NULL"), ("vb", "TEXT NULL"), ("dv", "TEXT NULL"), ("han", "TEXT NULL"),
          ("tinh_trang", "TEXT NULL"), ("ket_qua", "TEXT NULL"), ("de_xuat", "TEXT NULL"),
          ("d1", "TEXT NULL"), ("d2", "TEXT NULL"), ("d3", "TEXT NULL"), ("vb_khoa", "VARCHAR(50) NULL"),
          ("dv_chuan", "TEXT NULL")]

DDL = f"""/* Nhiệm vụ trong phụ lục báo cáo tháng NQ57 (tai_lieu/BC tháng 2-10) đã map với nhiệm vụ trong QLNV.
   Grain: 1 nhiệm vụ phụ lục x 1 task QLNV khớp (task_id = 0 nếu chưa map được -> dashboard hiện '!').
   Map: tiêu đề QLNV (đã chuẩn hóa) chứa đoạn giữa (~50% số từ) tiêu đề phụ lục; nếu khớp nhiều nhiệm vụ thì ưu tiên
        nhiệm vụ cùng văn bản giao. Không khớp đoạn giữa -> thử đoạn đầu/cuối (~40%) nhưng bắt buộc cùng văn bản giao.
   Nguồn QLNV: datamart_hanoi.qlnv_chitiet_captp_xp_bcd57 (cap_nhiem_vu = 'Cấp Thành phố').
   Sinh bởi bcd57_chitiet/chuyen_de/sql/nhiem_vu/build_sql.py - chạy qua NiFi (HN-Datamart-NEW). */
CREATE TABLE IF NOT EXISTS {DICH} (
    ky                  VARCHAR(20)    NOT NULL COMMENT 'Kỳ báo cáo T2/2026..T10/2026',
    thu_tu_ky           INT            NULL,
    thu_tu              INT            NOT NULL COMMENT 'Thứ tự nhiệm vụ trong phụ lục của kỳ',
    task_id             BIGINT         NOT NULL DEFAULT 0 COMMENT '0 = chưa map được với QLNV',
    nguon_phu_luc       VARCHAR(255)   NULL COMMENT 'BC tháng x - trang/bảng',
    phu_luc             VARCHAR(255)   NULL COMMENT 'Tên phụ lục, vd PHỤ LỤC 03 - DANH MỤC NHIỆM VỤ ĐÃ QUÁ THỜI HẠN GIAO...',
    loai_danh_sach      VARCHAR(50)    NULL COMMENT 'Quá hạn, chậm muộn | Đến hạn trong kỳ | Hoàn thành | Nguy cơ chậm | Theo dõi',
    muc_phu_luc         VARCHAR(255)   NULL COMMENT 'Nhóm/mục trong phụ lục',
    stt_phu_luc         VARCHAR(20)    NULL,
    ten_phu_luc         TEXT           NULL,
    van_ban_phu_luc     TEXT           NULL,
    co_quan_phu_luc     TEXT           NULL,
    han_phu_luc         TEXT           NULL,
    tinh_trang_phu_luc  TEXT           NULL,
    ket_qua_phu_luc     TEXT           NULL,
    de_xuat_phu_luc     TEXT           NULL,
    doan_so_khop        TEXT           NULL COMMENT 'Đoạn giữa tiêu đề dùng để so',
    co_khop             TINYINT        NOT NULL DEFAULT 0,
    cach_map            VARCHAR(20)    NULL COMMENT 'doan_giua | doan_phu',
    vb_khop             TINYINT        NULL COMMENT '1 = văn bản giao QLNV trùng văn bản trong phụ lục',
    so_nhiem_vu_khop    INT            NULL COMMENT 'Số nhiệm vụ (id_cha) khớp; > 1 = cần xem lại',
    so_task_khop        INT            NULL COMMENT 'Số task khớp (1 nhiệm vụ giao nhiều đơn vị)',
    id_cha              VARCHAR(50)    NULL,
    ma_nhiem_vu         VARCHAR(255)   NULL,
    ten_nhiem_vu        TEXT           NULL,
    nguon_giao          VARCHAR(50)    NULL,
    van_ban_giao        VARCHAR(500)   NULL,
    loai_van_ban        VARCHAR(100)   NULL,
    chu_de              VARCHAR(500)   NULL,
    don_vi_giao         VARCHAR(500)   NULL,
    ten_don_vi_chu_tri  VARCHAR(500)   NULL,
    ten_don_vi_thuc_hien VARCHAR(500)  NULL,
    nguoi_thuc_hien     VARCHAR(255)   NULL,
    ngay_giao           VARCHAR(10)    NULL,
    han_xu_ly           VARCHAR(10)    NULL,
    ngay_hoan_thanh     VARCHAR(10)    NULL,
    tinh_trang          VARCHAR(50)    NULL,
    tien_do             INT            NULL,
    sync_date           DATETIME       NOT NULL,
    PRIMARY KEY (ky, thu_tu, task_id),
    KEY idx_task (task_id),
    KEY idx_ky (thu_tu_ky),
    KEY idx_loai (loai_danh_sach)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""

COT_Q = ["task_id", "id_cha", "ma_nhiem_vu", "ten_nhiem_vu", "nguon_giao", "van_ban_giao", "loai_van_ban", "chu_de",
         "don_vi_giao", "ten_don_vi_chu_tri", "ten_don_vi_thuc_hien", "nguoi_thuc_hien", "ngay_giao", "han_xu_ly",
         "ngay_hoan_thanh", "tinh_trang", "tien_do"]
COT_DICH = ["ky", "thu_tu_ky", "thu_tu", "task_id", "nguon_phu_luc", "phu_luc", "loai_danh_sach", "muc_phu_luc", "stt_phu_luc", "ten_phu_luc",
            "van_ban_phu_luc", "co_quan_phu_luc", "han_phu_luc", "tinh_trang_phu_luc", "ket_qua_phu_luc",
            "de_xuat_phu_luc", "doan_so_khop", "co_khop", "cach_map", "vb_khop", "so_nhiem_vu_khop", "so_task_khop"] + \
           COT_Q[1:] + ["sync_date"]

o = ["/* Luồng so khớp nhiệm vụ phụ lục NQ57 với QLNV -> chuyen_de_chi_tiet_nhiem_vu_nq57 (sinh bởi build_sql.py).",
     "   Bảng tạm _cdnq57_* là bảng thường (MySQL 5.7 không cho mở TEMPORARY TABLE 2 lần trong 1 câu), xóa ở cuối. */",
     "SET @sync = NOW();",
     f"DROP TABLE IF EXISTS {T_PL}, {T_Q}, {T_HIT}, {T_DEM};",
     f"CREATE TABLE {T_PL} ({', '.join(f'{c} {t}' for c, t in COT_PL)}, PRIMARY KEY (ky, thu_tu)) "
     f"ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE={CO};"]
for i in range(0, len(PL), 100):
    vals = ",\n".join("(" + ",".join(
        lit(THU_TU_KY.get(p["ky"])) if c == "thu_tu_ky" else lit(p.get(c) if p.get(c) != "" else None)
        for c, _ in COT_PL) + ")" for p in PL[i:i + 100])
    o.append(f"INSERT INTO {T_PL} ({','.join(c for c, _ in COT_PL)}) VALUES\n{vals};")

o += [
    "/* 1. Tiêu đề QLNV cấp Thành phố đã chuẩn hóa (giống chuan_hoa.ten) */",
    f"CREATE TABLE {T_Q} ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE={CO} AS\n"
    f"SELECT task_id, id_cha,\n       CONVERT({sql_ten('ten_nhiem_vu')} USING utf8mb4) COLLATE {CO} AS ten_chuan,\n"
    f"       CONVERT({sql_vb('van_ban_giao')} USING utf8mb4) COLLATE {CO} AS vb_chuan,\n"
    f"       CONVERT(CONCAT({sql_dv('ten_don_vi_thuc_hien')}, {sql_dv('ten_don_vi_chu_tri')}) USING utf8mb4) COLLATE {CO} AS dv_chuan\n"
    f"FROM {QLNV} WHERE cap_nhiem_vu = 'Cấp Thành phố';",
    "/* 2. Tầng 1: tiêu đề QLNV chứa đoạn giữa */",
    f"CREATE TABLE {T_HIT} ENGINE=InnoDB AS\n"
    f"SELECT p.ky, p.thu_tu, q.task_id, q.id_cha, CAST('doan_giua' AS CHAR(20)) AS cach_map,\n"
    f"       IF(p.vb_khoa IS NOT NULL AND q.vb_chuan LIKE CONCAT(p.vb_khoa, '%'), 1, 0) AS vb_khop\n"
    f"FROM {T_PL} p JOIN {T_Q} q ON q.ten_chuan LIKE CONCAT('% ', p.d1, ' %');",
    f"ALTER TABLE {T_HIT} ADD KEY k (ky, thu_tu);",
    "/*    khớp nhiều nhiệm vụ mà có nhiệm vụ cùng văn bản giao -> chỉ giữ nhiệm vụ cùng văn bản */",
    f"CREATE TABLE {T_DEM} ENGINE=InnoDB AS SELECT ky, thu_tu FROM {T_HIT} GROUP BY ky, thu_tu HAVING SUM(vb_khop) > 0;",
    f"DELETE h FROM {T_HIT} h JOIN {T_DEM} d ON d.ky = h.ky AND d.thu_tu = h.thu_tu WHERE h.vb_khop = 0;",
    f"DROP TABLE {T_DEM};",
    "/* 3. Tầng 2 (chưa khớp): đoạn đầu hoặc đoạn cuối + bắt buộc cùng văn bản giao */",
    f"CREATE TABLE {T_DEM} ENGINE=InnoDB AS SELECT DISTINCT ky, thu_tu FROM {T_HIT};",
    f"ALTER TABLE {T_DEM} ADD PRIMARY KEY (ky, thu_tu);",
    f"INSERT INTO {T_HIT} (ky, thu_tu, task_id, id_cha, cach_map, vb_khop)\n"
    f"SELECT p.ky, p.thu_tu, q.task_id, q.id_cha, 'doan_phu', 1\n"
    f"FROM {T_PL} p\nJOIN {T_Q} q ON p.vb_khoa IS NOT NULL AND q.vb_chuan LIKE CONCAT(p.vb_khoa, '%')\n"
    f"     AND (q.ten_chuan LIKE CONCAT('% ', p.d2, ' %') OR q.ten_chuan LIKE CONCAT('% ', p.d3, ' %'))\n"
    f"LEFT JOIN {T_DEM} d ON d.ky = p.ky AND d.thu_tu = p.thu_tu\nWHERE d.ky IS NULL;",
    f"DROP TABLE {T_DEM};",
    "/* 4. Nhiệm vụ giao nhiều đơn vị: nếu có task mà đơn vị thực hiện/chủ trì chứa cơ quan chủ trì ghi trong phụ lục\n"
    "      thì chỉ giữ các task đó */",
    f"ALTER TABLE {T_HIT} ADD COLUMN dv_khop TINYINT NOT NULL DEFAULT 0;",
    f"UPDATE {T_HIT} h JOIN {T_PL} p ON p.ky = h.ky AND p.thu_tu = h.thu_tu JOIN {T_Q} q ON q.task_id = h.task_id\n"
    f"SET h.dv_khop = 1 WHERE CHAR_LENGTH(p.dv_chuan) >= 4 AND q.dv_chuan LIKE CONCAT('% ', p.dv_chuan, ' %');",
    f"CREATE TABLE {T_DEM} ENGINE=InnoDB AS SELECT ky, thu_tu FROM {T_HIT} GROUP BY ky, thu_tu HAVING SUM(dv_khop) > 0;",
    f"DELETE h FROM {T_HIT} h JOIN {T_DEM} d ON d.ky = h.ky AND d.thu_tu = h.thu_tu WHERE h.dv_khop = 0;",
    f"DROP TABLE {T_DEM};",
    "/* 5. Sau khi lọc vẫn khớp > 3 nhiệm vụ khác nhau -> coi là chưa map được (đoạn quá chung) */",
    f"CREATE TABLE {T_DEM} ENGINE=InnoDB AS SELECT ky, thu_tu FROM {T_HIT} GROUP BY ky, thu_tu HAVING COUNT(DISTINCT id_cha) > 3;",
    f"DELETE h FROM {T_HIT} h JOIN {T_DEM} d ON d.ky = h.ky AND d.thu_tu = h.thu_tu;",
    f"DROP TABLE {T_DEM};",
    f"CREATE TABLE {T_DEM} ENGINE=InnoDB AS\n"
    f"SELECT ky, thu_tu, COUNT(DISTINCT id_cha) AS so_nv, COUNT(*) AS so_task FROM {T_HIT} GROUP BY ky, thu_tu;",
    f"ALTER TABLE {T_DEM} ADD PRIMARY KEY (ky, thu_tu);",
    "/* 6. Ghi bảng đích: upsert theo khóa rồi xóa dòng của lần chạy trước */",
    f"INSERT INTO {DICH} ({', '.join(COT_DICH)})\n"
    f"SELECT p.ky, p.thu_tu_ky, p.thu_tu, COALESCE(h.task_id, 0), p.nguon, p.phu_luc, p.loai_danh_sach, p.muc, p.stt, p.ten, p.vb, p.dv, p.han,\n"
    f"       p.tinh_trang, p.ket_qua, p.de_xuat, p.d1, IF(h.task_id IS NULL, 0, 1), h.cach_map, h.vb_khop, d.so_nv, d.so_task,\n"
    f"       {', '.join('c.' + c for c in COT_Q[1:])}, @sync\n"
    f"FROM {T_PL} p\nLEFT JOIN {T_HIT} h ON h.ky = p.ky AND h.thu_tu = p.thu_tu\n"
    f"LEFT JOIN {T_DEM} d ON d.ky = p.ky AND d.thu_tu = p.thu_tu\n"
    f"LEFT JOIN {QLNV} c ON c.task_id = h.task_id AND c.cap_nhiem_vu = 'Cấp Thành phố'\n"
    f"ON DUPLICATE KEY UPDATE {', '.join(f'{c} = VALUES({c})' for c in COT_DICH[4:])};",
    f"DELETE FROM {DICH} WHERE sync_date < @sync;",
    f"DROP TABLE IF EXISTS {T_PL}, {T_Q}, {T_HIT}, {T_DEM};",
]

open(os.path.join(W, "0_ddl.sql"), "w").write(DDL)
open(os.path.join(W, "1_so_khop.sql"), "w").write("\n".join(o) + "\n")
print("phu luc", len(PL), "| sql bytes", os.path.getsize(os.path.join(W, "1_so_khop.sql")))
