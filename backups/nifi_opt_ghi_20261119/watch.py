import sys, time, json
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, Q
IDS = {'tiepnhan': '142f3e95-6ef6-1fc2-5b4c-b08f5bee47c3', 'giaonv': '142f3eb5-6ef6-1fc2-7578-0f74d7189542',
       'khoi': '142f3ee7-6ef6-1fc2-8ecf-70ddfebc58b3'}
mins = int(sys.argv[1]) if len(sys.argv) > 1 else 4
time.sleep(mins * 60)
for k, pid in IDS.items():
    s = G(f'/flow/processors/{pid}/status')['processorStatus']['aggregateSnapshot']
    n = s['taskCount'] or 1
    print(k, 'tasks5m', s['taskCount'], f"avg {s['tasksDurationNanos']/n/1e9:.1f}s", 'in', s['flowFilesIn'], 'out', s['flowFilesOut'])
    for b in G(f'/flow/bulletin-board?sourceId={pid}&limit=5')['bulletinBoard']['bulletins']:
        bb = b.get('bulletin', {}); print('   BULLETIN', bb.get('timestamp'), bb.get('level'), bb.get('message', '')[:300])
    p = G(f'/processors/{pid}')
    for c in G(f"/flow/process-groups/{p['component']['parentGroupId']}")['processGroupFlow']['flow']['connections']:
        cc = c['component']
        if cc['source']['id'] == pid and set(cc['selectedRelationships']) & {'failure', 'retry'}:
            print('   queue', cc['selectedRelationships'], c['status']['aggregateSnapshot']['queued'])
for tb in ['qlnv_tonghop_chitiet_tiepnhan', 'qlnv_tonghop_chitiet_giaonv', 'qlnv_tonghop_chitiet_khoi']:
    print(tb, Q(f"SELECT COUNT(*) n, MAX(syncdate) mx FROM datamart_hanoi.{tb}"))
print('processlist', Q("SELECT id,time,state,LEFT(info,70) i FROM information_schema.processlist WHERE command<>'Sleep' AND time>20"))
