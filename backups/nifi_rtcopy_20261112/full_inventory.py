"""Chỉ đọc. Kê từng processor ghi DB trong group RT: bảng mới (_new_rt) ↔ bảng cũ, lịch kích, thời gian TB/lượt
(từ status history của NiFi = tổng taskMillis / tổng taskCount), link NiFi. Ghi full/inventory.md + in ra."""
import re
from rtlib import G
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
U = 'https://bdw-theodoinhiemvu.hanoi.gov.vn/nifi/?processGroupId={}&componentIds={}'
# Lịch kích theo cách nối ở cấp RT (xem full_rt_gates.py): nhánh moi_phut / qua_15phut
SCHED = {'Tiếp nhận NV': '1 phút', 'Giao NV': '1 phút', 'Giao + Nhận NV': '1 phút', 'Dashboard Lãnh đạo các phòng, sở ngành, xã phường': '1 phút',
         'Mốc thời gian': '1 phút', 'Khối': '1 phút', 'NV theo NQ57': '1 phút', 'Đánh giá cán bộ': '1 phút (+cbcc 60 phút)',
         'Chi tiết đơn vị': '15 phút', 'Văn bản giao nhiệm vụ': '15 phút', 'Kiểm đếm': 'sau Chi tiết đơn vị', 'Chi tiết HĐND': 'sau Chi tiết đơn vị',
         'Copy of Chi tiết HĐND': 'sau Chi tiết HĐND', 'qlnv_kl_ctpct_chitiet': '30 phút'}
def avg(pid):
    try:
        h = G(f'/flow/processors/{pid}/status/history')['statusHistory']['aggregateSnapshots']
    except Exception: return None, 0
    ms = sum(x['statusMetrics'].get('taskMillis', 0) for x in h); n = sum(x['statusMetrics'].get('taskCount', 0) for x in h)
    return (ms / n / 1000 if n else None), n
rows = []
for sg in G(f'/flow/process-groups/{NEW}')['processGroupFlow']['flow']['processGroups']:
    gname = sg['component']['name']
    for p in G(f"/process-groups/{sg['id']}/processors")['processors']:
        c = p['component']
        if c['state'] != 'RUNNING' or c['type'].split('.')[-1] not in ('ExecuteSQL', 'PutSQL', 'PutDatabaseRecord'): continue
        pr = c['config']['properties']
        sql = ' '.join(v for k, v in pr.items() if v and k in ('SQL select query', 'putsql-sql-statement', 'sql-pre-query', 'sql-post-query'))
        w = re.findall(r'(?i)(?:insert\s+(?:ignore\s+)?into|replace\s+into|rename\s+table|update|delete\s+\w*\s*from)\s+`?([\w]+\.[\w]+_new_rt)\b', sql)
        if c['type'].endswith('PutDatabaseRecord'): w = [pr.get('put-db-record-table-name')]
        if not w: continue  # SELECT thuần (kl_ctpct 01/02/03) → ghi qua PutDatabaseRecord kế tiếp
        tb = w[0]
        mode = 'swap __stg' if '__stg' in sql else ('UPSERT' if c['type'].endswith('PutDatabaseRecord') or 'duplicate key' in sql.lower() else 'UPDATE/DELETE')
        a, n = avg(c['id'])
        rows.append((gname, c['name'], tb, tb.replace('_new_rt', ''), mode, SCHED.get(gname, '?'), a, n, U.format(sg['id'], c['id'])))
rows.sort(key=lambda r: -(r[6] or 0))
out = ['| # | Group | Processor | Bảng mới | Bảng cũ (thật) | Cách ghi | Lịch | s/lượt | Link |', '|---|---|---|---|---|---|---|---|---|']
for i, r in enumerate(rows, 1):
    out.append(f"| {i} | {r[0][:24]} | {r[1]} | `{r[2].split('.')[-1]}` | `{r[3]}` | {r[4]} | {r[5]} | {'%.1f' % r[6] if r[6] else '–'} ({r[7]}) | [mở]({r[8]}) |")
open('full/inventory.md', 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
