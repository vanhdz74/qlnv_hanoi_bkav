"""Theo dõi N phút: mỗi lượt (bắt đầu = upsert tiepnhan chạy, kết thúc = tongquan xong) in thời lượng và bước chậm nhất.
Một dòng mỗi lượt + dòng LỖI khi có flowfile vào nhánh failure/retry hoặc bulletin mới."""
import sys, time
from rtlib import *
END = time.time() + float(sys.argv[1]) * 60
FIRST, LAST = 'qlnv_tonghop_chitiet_tiepnhan [upsert]', 'qlnv_tongquan [stg]'
cyc, prev_act, seen_b = None, set(), set()
for x in G(f'/flow/bulletin-board?groupId={NEW}&limit=50')['bulletinBoard']['bulletins']:
    seen_b.add(x['id'])
k = 0
while time.time() < END:
    try:
        agg = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
    except Exception as e:
        print('API', e, flush=True); time.sleep(5); continue
    act = set()
    def w(g):
        for p in g.get('processorStatusSnapshots', []):
            if p['processorStatusSnapshot']['activeThreadCount']: act.add(p['processorStatusSnapshot']['name'])
        for c in g.get('processGroupStatusSnapshots', []): w(c['processGroupStatusSnapshot'])
    w(agg)
    now = time.time()
    if FIRST in act and FIRST not in prev_act and (cyc is None or cyc.get('done')):
        cyc = {'t0': now, 'start': time.strftime('%T'), 'steps': {}}
    if cyc and not cyc.get('done'):
        for n in act: cyc['steps'][n] = cyc['steps'].get(n, 0) + 1
        if LAST in prev_act and LAST not in act:
            cyc['done'] = True
            top = sorted(cyc['steps'].items(), key=lambda x: -x[1])[:3]
            print(f"LƯỢT {cyc['start']} dài {now - cyc['t0']:.0f}s | chậm: " + ', '.join(f'{n[:28]} {s}s' for n, s in top)
                  + f" | NiFi threads {G('/flow/status')['controllerStatus']['activeThreadCount']}", flush=True)
    prev_act = act
    k += 1
    if k % 10 == 0:
        for x in G(f'/flow/bulletin-board?groupId={NEW}&limit=50')['bulletinBoard']['bulletins']:
            if x['id'] not in seen_b and 'bulletin' in x:
                seen_b.add(x['id']); print('LỖI', x['bulletin']['timestamp'], x['bulletin']['sourceName'][:35], x['bulletin']['message'][:200], flush=True)
    time.sleep(1)
print('XONG theo dõi', time.strftime('%T'), 'queued', agg['queued'], flush=True)
