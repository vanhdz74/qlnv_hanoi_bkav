"""Deploy cách A (16/11/2026): bộ lọc đơn vị giao theo id nút thay vì tên tổ tiên cấp 3.
Processor: 142f3e95 (tiepnhan), 142f3eb5 (giaonv) trong group RT 142f3e8a.
Rollback: python3 deploy_cachA.py rollback  (ghi lại SQL từ backup_*_before.json)."""
import sys, os, json, time
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P, setstate

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = 'putsql-sql-statement'
TARGETS = {
    '142f3e95-6ef6-1fc2-5b4c-b08f5bee47c3': [  # tiepnhan
        ("\t\tAND ( ( main.loaicap_dvgiao NOT IN ('Sở ngành', 'Xã, Phường', 'Nhóm Sở ngành mở rộng') ) OR main.loaicap_dvgiao IS NULL )",
         "\t\tAND main.iddv_dvgiao NOT IN (1307, 1310, 1841) -- [cách A 16/11] chỉ loại đúng nút Sở ngành / Xã, Phường / Nhóm Sở ngành MR"),
        ("\t\tAND main.loaicap_dvgiao <> 'Đảng bộ trực thuộc'",
         "\t\tAND main.iddv_dvgiao <> 1558 -- [cách A 16/11] chỉ loại đúng nút Đảng bộ trực thuộc"),
    ],
    '142f3eb5-6ef6-1fc2-7578-0f74d7189542': [  # giaonv
        ("\t\t\t\tAND ( ( main.loaicap NOT IN ('Sở ngành','Xã, Phường','Nhóm Sở ngành mở rộng') ) OR main.loaicap IS NULL )",
         "\t\t\t\tAND main.iddv NOT IN (1307, 1310, 1841) -- [cách A 16/11] iddv = dv_giao.DepartmentId"),
        ("\t\t\t\tAND main.loaicap <> 'Đảng bộ trực thuộc'",
         "\t\t\t\tAND main.iddv <> 1558 -- [cách A 16/11]"),
    ],
}

def wait_stopped(pid):
    for _ in range(120):
        p = G(f'/processors/{pid}')
        if p['component']['state'] == 'STOPPED' and p['status']['aggregateSnapshot']['activeThreadCount'] == 0:
            return p
        time.sleep(1)
    raise SystemExit(f'{pid} không dừng được trong 120s')

def put_sql(pid, sql):
    p = wait_stopped(pid)
    P('PUT', f'/processors/{pid}', {'revision': p['revision'],
      'component': {'id': pid, 'config': {'properties': {KEY: sql}}}})

rollback = len(sys.argv) > 1 and sys.argv[1] == 'rollback'
new_sql = {}
for pid, reps in TARGETS.items():
    bf = os.path.join(HERE, f'backup_{pid[:8]}_before.json')
    if rollback:
        new_sql[pid] = json.load(open(bf))['component']['config']['properties'][KEY]
        continue
    p = G(f'/processors/{pid}')
    if not os.path.exists(bf):
        json.dump(p, open(bf, 'w'), ensure_ascii=False, indent=1)
    sql = p['component']['config']['properties'][KEY]
    for a, b in reps:
        assert sql.count(a) == 1, (pid, a)
        sql = sql.replace(a, b)
    new_sql[pid] = sql
    open(os.path.join(HERE, f'{pid[:8]}_after.sql'), 'w').write(sql)

states = {pid: G(f'/processors/{pid}')['component']['state'] for pid in TARGETS}
print('trạng thái trước:', states)
for pid in TARGETS:
    if states[pid] == 'RUNNING': setstate({'id': pid}, 'STOPPED')
for pid, sql in new_sql.items():
    put_sql(pid, sql); print('đã ghi SQL', pid[:8])
for pid in TARGETS:
    if states[pid] == 'RUNNING': setstate({'id': pid}, 'RUNNING')
for pid in TARGETS:
    c = G(f'/processors/{pid}')['component']
    ok = all(b in c['config']['properties'][KEY] for _, b in TARGETS[pid])
    print(pid[:8], c['state'], c.get('validationStatus'), 'cách A có mặt' if ok else 'KHÔNG có cách A')
