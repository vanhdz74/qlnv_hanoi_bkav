"""Chỉ đọc. So mọi bảng *_new_rt (group RT 142f3e8a) với bảng thật của luồng cũ.
Mỗi bảng 2 câu quét đơn (không JOIN, không COUNT DISTINCT): số dòng + tổng CRC32 nội dung (bỏ cột sync).
Tổng CRC bằng nhau => cùng tập dòng. python3 full_compare.py [lọc_tên]"""
import sys, time
from rtlib import Q
SKIP = {'syncdate', 'sync_date', 'sync_ts', 'updated_sync'}
flt = sys.argv[1] if len(sys.argv) > 1 else ''
rows = Q("SELECT table_schema s, table_name t, table_rows r FROM information_schema.tables "
         "WHERE table_name LIKE '%\\_new\\_rt' AND table_schema IN ('datamart_hanoi','db_hdnd_qttt') ORDER BY 1,2")
print(time.strftime('%T'), len(rows), 'bảng _new_rt', flush=True)
for x in rows:
    s, n = x['s'], x['t']; t = n[:-len('_new_rt')]
    if flt not in n: continue
    try:
        oc = {r['c'] for r in Q(f"SELECT column_name c FROM information_schema.columns WHERE table_schema='{s}' AND table_name='{t}'")}
        nc = [r['c'] for r in Q(f"SELECT column_name c FROM information_schema.columns WHERE table_schema='{s}' AND table_name='{n}' ORDER BY ordinal_position")]
        if not oc:
            print(f"{s}.{t:50} KHÔNG CÓ bảng cũ", flush=True); continue
        cols = [c for c in nc if c in oc and c.lower() not in SKIP]
        extra = sorted(c for c in set(nc) ^ oc if c.lower() not in SKIP)
        crc = "SUM(CRC32(CONCAT_WS('|'," + ','.join(f"IFNULL(`{c}`,'∅')" for c in cols) + ")))"
        ts = lambda tb: next((f", MAX(`{c}`) m" for c in ('syncdate', 'sync_date') if c in (oc if tb == t else nc)), ", NULL m")
        t0 = time.time()
        a = Q(f"SELECT COUNT(*) n, {crc} h{ts(t)} FROM {s}.{t}")[0]
        b = Q(f"SELECT COUNT(*) n, {crc} h{ts(n)} FROM {s}.{n}")[0]
        ok = 'KHỚP' if (a['n'], str(a['h'])) == (b['n'], str(b['h'])) else 'LỆCH'
        print(f"{ok} {s[:8]}.{t:48} cũ={a['n']:>7} mới={b['n']:>7} Δ={int(b['n'] or 0)-int(a['n'] or 0):>+5} "
              f"| mốc cũ {a['m']} mới {b['m']} | {time.time()-t0:.1f}s" + (f" | cột khác: {extra}" if extra else ''), flush=True)
    except Exception as e:
        print(f"ERR {s}.{t}: {str(e)[:200]}", flush=True)
