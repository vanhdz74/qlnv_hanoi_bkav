"""Chỉ đọc. So hiệu năng processor ghi DB: group RT (bản sao) vs group cũ cùng tên, từ status 5 phút của NiFi.
Thời gian TB/lượt = tasksDuration / taskCount."""
from rtlib import G
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
OLD = 'f8207212-019b-1000-fcc5-817989167c53'
def dur(s):
    h, m, x = s.split(':'); return int(h) * 3600 + int(m) * 60 + float(x)
def collect(g, pre='', skip=()):
    out = {}
    for p in g.get('processorStatusSnapshots', []):
        x = p['processorStatusSnapshot']
        if x['type'] in ('ExecuteSQL', 'PutSQL', 'PutDatabaseRecord') and x['runStatus'] == 'Running':
            k = (pre, x['name'].replace(' [upsert]', '').replace(' [stg]', ''))
            out[k] = (x['taskCount'], dur(x['tasksDuration']))
    for c in g.get('processGroupStatusSnapshots', []):
        cg = c['processGroupStatusSnapshot']
        if cg['id'] in skip: continue
        out.update(collect(cg, cg['name'], skip))
    return out
new = collect(G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot'])
old = collect(G(f'/flow/process-groups/{OLD}/status?recursive=true')['processGroupStatus']['aggregateSnapshot'], skip={NEW})
tn = to = 0
print(f"{'group / processor':70} {'cũ lượt':>7} {'cũ s/lượt':>9} | {'mới lượt':>8} {'mới s/lượt':>10}")
for k in sorted(set(new) | set(old)):
    a, b = old.get(k, (0, 0)), new.get(k, (0, 0))
    to += a[1]; tn += b[1]
    f = lambda c, d: f"{c:>7} {d / c if c else 0:>9.1f}"
    print(f"{(k[0][:28] + ' / ' + k[1])[:70]:70} {f(*a)} | {f(*b)}")
print(f"Tổng giây SQL trong 5 phút: cũ {to:.0f}s (≈{to/300:.2f} câu song song) | mới {tn:.0f}s (≈{tn/300:.2f})")
