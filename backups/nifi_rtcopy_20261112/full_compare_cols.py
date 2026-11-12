"""Chỉ đọc. Với bảng cùng số dòng nhưng lệch CRC: (1) tổng CRC từng cột (1 lần quét/phía, không join) → cột nào lệch;
(2) nếu bảng _new_rt có UNIQUE/PK → LEFT JOIN cũ→mới (mới là phía bị dò, có index) đếm dòng lệch. python3 full_compare_cols.py bảng..."""
import sys
from rtlib import Q
S = 'datamart_hanoi'
SKIP = {'syncdate', 'sync_date'}
for t in sys.argv[1:]:
    n = t + '_new_rt'
    oc = {r['c'] for r in Q(f"SELECT column_name c FROM information_schema.columns WHERE table_schema='{S}' AND table_name='{t}'")}
    cols = [r['c'] for r in Q(f"SELECT column_name c FROM information_schema.columns WHERE table_schema='{S}' AND table_name='{n}' ORDER BY ordinal_position")
            if r['c'] in oc and r['c'].lower() not in SKIP]
    sel = ','.join(f"SUM(CRC32(IFNULL(`{c}`,'∅'))) `{c}`" for c in cols)
    a, b = Q(f"SELECT {sel} FROM {S}.{t}")[0], Q(f"SELECT {sel} FROM {S}.{n}")[0]
    diff = [c for c in cols if str(a[c]) != str(b[c])]
    idx = Q(f"SELECT index_name i, GROUP_CONCAT(column_name ORDER BY seq_in_index) k FROM information_schema.statistics "
            f"WHERE table_schema='{S}' AND table_name='{n}' AND non_unique=0 GROUP BY index_name")
    rows = ''
    if idx and diff:
        k = idx[0]['k'].split(',')
        if not any(c.lower() in SKIP for c in k):
            on = ' AND '.join(f"a.`{c}` <=> b.`{c}`" for c in k)
            same = lambda x: "CRC32(CONCAT_WS('|'," + ','.join(f"IFNULL({x}.`{c}`,'∅')" for c in cols) + "))"
            r = Q(f"SELECT SUM(b.`{k[0]}` IS NULL) chi_cu, SUM(b.`{k[0]}` IS NOT NULL AND {same('a')}<>{same('b')}) lech "
                  f"FROM {S}.{t} a LEFT JOIN {S}.{n} b ON {on}")[0]
            rows = f" | khóa {k}: chỉ_cũ={r['chi_cu']} dòng_lệch={r['lech']}"
    print(f"{t:45} cột lệch {len(diff)}/{len(cols)}: {diff}{rows}", flush=True)
