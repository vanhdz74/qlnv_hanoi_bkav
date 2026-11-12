"""Theo dõi N phút group mới (cả hạ nguồn): bulletin mới, hàng đợi failure/retry, processor chậm, khóa MySQL. In khi có sự kiện + tóm tắt mỗi 3'."""
import sys, time
from rtlib import *
END = time.time() + float(sys.argv[1]) * 60
gids = set()
def wg(g):
    gids.add(g)
    for c in G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']['processGroups']: wg(c['id'])
wg(NEW)
seen = {b['id'] for b in G('/flow/bulletin-board?limit=200')['bulletinBoard']['bulletins']}
k = 0
while time.time() < END:
    try:
        for b in G('/flow/bulletin-board?limit=200')['bulletinBoard']['bulletins']:
            if b['id'] in seen: continue
            seen.add(b['id'])
            if b.get('groupId') in gids:
                print('BULLETIN', b['bulletin']['timestamp'], b['bulletin'].get('sourceName', '')[:40], b['bulletin']['message'][:250], flush=True)
        if k % 6 == 0:
            st = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
            fails, slow = [], []
            def w(g):
                for c in g.get('connectionStatusSnapshots', []):
                    cs = c['connectionStatusSnapshot']
                    if cs['flowFilesQueued'] and ('LogAttribute' in cs['destinationName'] or 'failure' in cs.get('name', '')):
                        fails.append(f"{cs['sourceName'][:30]}→{cs['destinationName'][:15]}={cs['flowFilesQueued']}")
                    elif cs['flowFilesQueued'] >= 3:
                        slow.append(f"{cs['destinationName'][:30]}={cs['flowFilesQueued']}")
                for c in g.get('processGroupStatusSnapshots', []): w(c['processGroupStatusSnapshot'])
            w(st)
            pl = Q("SELECT COUNT(*) n, SUM(state LIKE '%lock%') lk, MAX(time) mx FROM information_schema.processlist WHERE command<>'Sleep' AND info NOT LIKE '%processlist%'")[0]
            print(time.strftime('%T'), f"threads={st['activeThreadCount']} queued={st['queued']} | mysql chạy={pl['n']} chờ_khóa={pl['lk']} lâu_nhất={pl['mx']}s"
                  f" | failure: {fails or 0} | dồn: {slow or 0}", flush=True)
    except Exception as e:
        print('ERR', str(e)[:150], flush=True)
    k += 1
    time.sleep(30)
print('XONG', time.strftime('%T'))
