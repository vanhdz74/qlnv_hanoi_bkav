import sys, time, collections
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P, Q, s, API
IDS = {'tiepnhan': '142f3e95-6ef6-1fc2-5b4c-b08f5bee47c3', 'giaonv': '142f3eb5-6ef6-1fc2-7578-0f74d7189542'}
# 1) tuổi flowfile trong hàng failure/retry
for k, pid in IDS.items():
    p = G(f'/processors/{pid}')
    for c in G(f"/flow/process-groups/{p['component']['parentGroupId']}")['processGroupFlow']['flow']['connections']:
        cc = c['component']
        if cc['source']['id'] == pid and set(cc['selectedRelationships']) & {'failure', 'retry'}:
            r = P('POST', f"/flowfile-queues/{cc['id']}/listing-requests", {})
            lid = r['listingRequest']['id']
            for _ in range(10):
                r = G(f"/flowfile-queues/{cc['id']}/listing-requests/{lid}")
                if r['listingRequest']['finished']: break
                time.sleep(0.5)
            s.delete(API + f"/flowfile-queues/{cc['id']}/listing-requests/{lid}")
            ffs = r['listingRequest'].get('flowFileSummaries', [])
            ages = sorted(f['queuedDuration'] // 1000 for f in ffs)
            print(k, cc['selectedRelationships'], 'n', len(ffs), 'tuổi (s) nhỏ nhất', ages[:3], 'lớn nhất', ages[-1:] if ages else None)
# 2) lấy mẫu processlist 75s để biết câu nào trong bản OPT tốn thời gian
cnt = collections.Counter(); t_end = time.time() + 75
while time.time() < t_end:
    for r in Q("SELECT LEFT(REPLACE(info,'\\n',' '),60) i, state FROM information_schema.processlist WHERE info LIKE '%opt\\_%' AND info NOT LIKE '%processlist%'"):
        i = r['i']
        tag = ('tmp-fill' if i.startswith('INSERT INTO opt_') else 'upsert-changed' if i.startswith('INSERT INTO datamart') else
               'delete' if i.startswith('DELETE') else i[:30])
        tbl = 'tiepnhan' if 'tiepnhan' in i else 'giaonv' if 'giaonv' in i else '?'
        cnt[(tbl, tag, r['state'])] += 1
    time.sleep(0.5)
for k, v in sorted(cnt.items()): print('mẫu', k, v, f'≈{v*0.5+v*0.25:.0f}s?')
