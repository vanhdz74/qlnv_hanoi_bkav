"""Run once GFF 1 phút, ghi thời điểm bắt đầu/kết thúc từng processor (poll 1s), in bulletin + hàng đợi failure."""
import time, json
from rtlib import *
GFF = '142f3f00-6ef6-1fc2-88e9-5f49f8a9cc5a'
seen = {}
t0 = time.time()
setstate({'id': GFF}, 'RUN_ONCE')
idle = 0
while time.time() - t0 < 300:
    agg = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
    act = []
    def w(g):
        for p in g.get('processorStatusSnapshots', []):
            x = p['processorStatusSnapshot']
            if x['activeThreadCount']: act.append(x['name'])
        for c in g.get('processGroupStatusSnapshots', []): w(c['processGroupStatusSnapshot'])
    w(agg)
    now = time.time() - t0
    for n in act:
        seen.setdefault(n, [now, now]); seen[n][1] = now
    idle = idle + 1 if not act and now > 3 else 0
    if idle >= 4: break
    time.sleep(1)
tot = time.time() - t0
for n, (a, b) in sorted(seen.items(), key=lambda x: x[1][0]):
    print(f'{a:6.1f} → {b:6.1f}  ~{b - a + 1:5.1f}s  {n}')
print(f'TỔNG ~{tot - 4:.0f}s')
b = G(f'/flow/bulletin-board?groupId={NEW}&after=0&limit=50')['bulletinBoard']['bulletins']
for x in b:
    if 'bulletin' in x and x['bulletin']['timestamp'] >= time.strftime('%H:%M:%S', time.localtime(t0)):
        print('B', x['bulletin']['timestamp'], x['bulletin']['sourceName'][:40], x['bulletin']['message'][:300])
print('queued', G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['queued'])
