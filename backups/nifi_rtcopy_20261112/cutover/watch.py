import sys, time; sys.path.insert(0, '.')
from rtlib import G, Q
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
T = ['qlnv_tonghop_chitiet_tiepnhan', 'qlnv_tonghop_chitiet_giaonv', 'qlnv_tonghop_chitiet_nhom_tiepnhan', 'qlnv_tonghop_chitiet_nhom_giaonv', 'qlnv_tonghop_chitiet', 'qlnv_tonghop_chitiet_nhom', 'qlnv_tonghop_chitiet_khoi', 'qlnv_tongquan', 'qlnv_tongquan_khoi']
def fails(g, path=''):
    out = []; ff = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for c in ff['connections']:
        rel = c['component'].get('selectedRelationships') or []; n = c['status']['aggregateSnapshot']['flowFilesQueued']
        if n and (set(rel) & {'failure', 'retry'}): out.append(f"{path}/{c['component']['source']['name']}={n}")
    for sg in ff['processGroups']: out += fails(sg['id'], path + '/' + sg['component']['name'][:12])
    return out
for k in range(int(sys.argv[1]) if len(sys.argv) > 1 else 6):
    st = G(f'/flow/process-groups/{NEW}/status')['processGroupStatus']['aggregateSnapshot']
    r = {t[13:]: (lambda x: f"{x['n']}@{(x['mx'] or '')[11:]}")(Q(f"SELECT COUNT(*) n, MAX(syncdate) mx FROM {t}")[0]) for t in T}
    print(time.strftime('%H:%M:%S'), 'threads', st['activeThreadCount'], 'queued', st['queued'], '| lỗi:', fails(NEW) or '0', flush=True)
    print('   ', r, flush=True)
    b = G(f'/flow/bulletin-board?groupId={NEW}&after=0&limit=10')['bulletinBoard']['bulletins']
    for x in b:
        if x.get('bulletin') and x['bulletin']['timestamp'] >= '10:52' and 'ROLLBACK' not in x['bulletin']['sourceName']: print('    BULLETIN', x['bulletin']['timestamp'], x['bulletin']['sourceName'][:40], x['bulletin']['message'][:200], flush=True)
    time.sleep(60)
