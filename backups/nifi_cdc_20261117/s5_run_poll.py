"""Bật processor đọc binlog qua SQL, theo dõi N phút (mặc định 10) rồi DỪNG. In mỗi 30s."""
import sys, json, os, time
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, Q, setstate
HERE = os.path.dirname(os.path.abspath(__file__))
ids = json.load(open(f'{HERE}/ids.json')); PID = ids['p_poll']
MIN = float(sys.argv[1]) if len(sys.argv) > 1 else 10
def out(*a): print(time.strftime('%T'), *a, flush=True)

c = G(f'/processors/{PID}')['component']
if c['validationStatus'] != 'VALID': raise SystemExit(f"processor chưa VALID: {c['validationStatus']} {c.get('validationErrors')}")
base = Q('SELECT COALESCE(MAX(id),0) m FROM datamart_hanoi.rt_cdc_log')[0]['m']
setstate({'id': PID}, 'RUNNING'); out(f'ĐÃ BẬT đọc binlog — theo dõi {MIN:g} phút, log id > {base}')
seen, end = set(), time.time() + MIN * 60
try:
    while time.time() < end:
        time.sleep(30)
        st = {x['k']: x['v'] for x in Q("SELECT k, v FROM datamart_hanoi.rt_cdc_state WHERE k IN ('last_poll')")}
        r = Q(f"""SELECT op, tbl, COUNT(*) n, GROUP_CONCAT(DISTINCT task_id ORDER BY task_id SEPARATOR ',') ids
                  FROM datamart_hanoi.rt_cdc_log WHERE id > {base} AND op IN ('taskid','khong_co_taskid','ddl')
                  GROUP BY op, tbl ORDER BY op, n DESC""")
        out('poll:', st.get('last_poll'), '|', '; '.join(f"{x['op']} {x['tbl']} {x['n']}" + (f" [{(x['ids'] or '')[:80]}]" if x['op'] == 'taskid' else '') for x in r) or '-')
        for b in G(f'/flow/bulletin-board?groupId={ids["group"]}&limit=20')['bulletinBoard']['bulletins']:
            if b['id'] not in seen and b.get('bulletin'):
                seen.add(b['id']); out('BULLETIN', b['bulletin']['level'], b['bulletin']['message'][:400])
finally:
    setstate({'id': PID}, 'STOPPED'); out('ĐÃ DỪNG đọc binlog')
    for x in Q(f"""SELECT op, db, tbl, COUNT(*) n FROM datamart_hanoi.rt_cdc_log WHERE id > {base}
                   GROUP BY op, db, tbl ORDER BY op, n DESC"""):
        out('  TỔNG', x)
