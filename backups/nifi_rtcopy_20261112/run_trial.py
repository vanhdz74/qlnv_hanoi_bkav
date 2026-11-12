"""python3 run_trial.py ddl     → Run once '0. DDL upsert', đợi xong, kiểm information_schema
   python3 run_trial.py start   → start group mới (trừ nhánh th_tongquan_donvi bản sao, GFF 15' bản sao, DDL)
   python3 run_trial.py monitor N → theo dõi N phút, ghi trial.jsonl, in tóm tắt
   python3 run_trial.py stop    → stop mọi processor đang chạy trong group mới"""
import sys, json, time
from rtlib import *
DDL_ID = '142f3f25'
SKIP = {'142f3e9a', '142f3e9b', '142f3ebe', '142f3ebc', DDL_ID}  # nhánh th_tongquan_donvi (luồng cũ vẫn chạy) + DDL
GFF_NEW = '142f3f00-6ef6-1fc2-88e9-5f49f8a9cc5a'
DB, T = 'datamart_hanoi', 'qlnv_tonghop_chitiet'

def walk(gid):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
    out = [('proc', p) for p in f['processors']]
    out += [('in', p) for p in f['inputPorts']] + [('out', p) for p in f['outputPorts']]
    for g in f['processGroups']: out += walk(g['id'])
    return out

def ddl_state():
    k = Q(f"SELECT table_name t, index_name k FROM information_schema.statistics WHERE table_schema='{DB}' "
          f"AND index_name LIKE 'uk_rt_%' AND table_name LIKE '{T}%' GROUP BY 1,2")
    c = Q(f"SELECT table_name t FROM information_schema.columns WHERE table_schema='{DB}' AND column_name='syncdate' "
          f"AND table_name IN ('{T}_nhom_tiepnhan','{T}_nhom_giaonv')")
    return {'keys': k, 'syncdate_cols': c}

cmd = sys.argv[1]
if cmd == 'ddl':
    p = [p for k, p in walk(NEW) if k == 'proc' and p['id'].startswith(DDL_ID)][0]
    a = G(f'/flow/process-groups/{OLD}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
    old_gff = G('/processors/bee43592-c2d0-1c10-f125-4abd0acb46fa')['component']['state']
    assert old_gff == 'STOPPED' and a['activeThreadCount'] == 0 and a['queuedCount'] == '0', (old_gff, a)
    print('trước', ddl_state())
    t0 = time.time(); setstate(p, 'RUN_ONCE')
    time.sleep(3)
    while True:
        st = G(f'/flow/processors/{p["id"]}/status')['processorStatus']['aggregateSnapshot']
        if st['activeThreadCount'] == 0 and st['taskCount'] > 0: break
        time.sleep(2)
    print(f'xong {time.time()-t0:.0f}s', st['tasksDuration'])
    b = G(f'/flow/bulletin-board?sourceId={p["id"]}')['bulletinBoard']['bulletins']
    for x in b: print('BULLETIN', x['bulletin']['message'][:400])
    print('sau', ddl_state())
elif cmd in ('start', 'stop'):
    items = walk(NEW)
    if cmd == 'start':
        # chỉ start port có kết nối ra (3 output port 'ra downstream' chưa nối → để STOPPED)
        conns = []
        def wc(gid):
            f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
            conns.extend(c['component']['source']['id'] for c in f['connections'])
            for g in f['processGroups']: wc(g['id'])
        wc(NEW)
        for k, p in items:
            if p['id'][:8] in SKIP or p['id'] == GFF_NEW or p['component']['state'] != 'STOPPED': continue
            if k != 'proc' and p['id'] not in conns: continue
            path = {'proc': 'processors', 'in': 'input-ports', 'out': 'output-ports'}[k]
            q = G(f'/{path}/{p["id"]}')
            P('PUT', f'/{path}/{p["id"]}/run-status', {'revision': q['revision'], 'state': 'RUNNING'})
            print('RUN', k, p['component']['name'][:60])
        setstate({'id': GFF_NEW}, 'RUNNING'); print('RUN GFF 1 phút', time.strftime('%T'))
    else:
        setstate({'id': GFF_NEW}, 'STOPPED'); print('STOP GFF', time.strftime('%T'))
        time.sleep(5)
        while G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']['activeThreadCount']:
            time.sleep(3)
        for k, p in walk(NEW):
            if p['component']['state'] != 'RUNNING': continue
            path = {'proc': 'processors', 'in': 'input-ports', 'out': 'output-ports'}[k]
            q = G(f'/{path}/{p["id"]}')
            P('PUT', f'/{path}/{p["id"]}/run-status', {'revision': q['revision'], 'state': 'STOPPED'})
        a = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
        print('đã stop', a['queued'])
elif cmd == 'monitor':
    mins = float(sys.argv[2]); t_end = time.time() + mins * 60
    f = open('trial.jsonl', 'a')
    while time.time() < t_end:
        snap = {'t': time.strftime('%T')}
        procs_ = []
        def ws(g):
            for p in g.get('processorStatusSnapshots', []):
                x = p['processorStatusSnapshot']
                if x['taskCount']: procs_.append({'n': x['name'][:45], 'tasks': x['taskCount'],
                    'avg_s': round(x['tasksDurationNanos'] / x['taskCount'] / 1e9, 2), 'act': x['activeThreadCount']})
            for c in g.get('processGroupStatusSnapshots', []): ws(c['processGroupStatusSnapshot'])
        agg = G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
        ws(agg)
        snap['procs_5m'] = procs_
        snap['new_threads'] = agg['activeThreadCount']; snap['new_queued'] = agg['queued']
        snap['nifi_threads'] = G('/flow/status')['controllerStatus']['activeThreadCount']
        b = G(f'/flow/bulletin-board?groupId={NEW}&limit=20')['bulletinBoard']['bulletins']
        snap['bulletins'] = [x['bulletin']['message'][:300] for x in b if 'bulletin' in x]
        snap['mysql'] = Q("SELECT id, time, state, LEFT(info,70) info FROM information_schema.processlist "
                          "WHERE command <> 'Sleep' AND info NOT LIKE '%processlist%' AND "
                          "(state LIKE '%lock%' OR info LIKE '%tonghop_chitiet%' OR info LIKE '%tongquan%') ORDER BY time DESC LIMIT 15")
        snap['sync'] = Q("SELECT " + ", ".join(
            f"(SELECT MAX(syncdate) FROM {DB}.{t}) `{t.replace(T, 'c')}`" for t in TABLES) )[0]
        snap['rows'] = Q("SELECT " + ", ".join(
            f"(SELECT COUNT(*) FROM {DB}.{t}) `{t.replace(T, 'c')}`" for t in TABLES))[0] if int(time.time()) % 180 < 30 else None
        f.write(json.dumps(snap, ensure_ascii=False, default=str) + '\n'); f.flush()
        time.sleep(max(0, 30 - (time.time() % 30)))
    print('monitor xong')
