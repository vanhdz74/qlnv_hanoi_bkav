import sys, json, time; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
WATCH={'qlnv_tonghop_chitiet_donvi','qlnv_tongquan_donvi','qlnv_tongquan_donvi_kiemdem','qlnv_tongquan_vanban_chitiet','qlnv_tongquan_vanban','qlnv_tonghop_chitiet_hdndtp','qlnv_tongquan_donvi_hdndtp','qlnv_tongquan [stg]','qlnv_tonghop_chitiet_tiepnhan [upsert]'}
END=time.time()+float(sys.argv[1])*60; start={}; seen=set(); k=0
for x in G(f'/flow/bulletin-board?groupId={NEW}&limit=100')['bulletinBoard']['bulletins']: seen.add(x['id'])
while time.time()<END:
    try: agg=G(f'/flow/process-groups/{NEW}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
    except Exception as e: print('API',e,flush=True); time.sleep(3); continue
    def w(g,path):
        for p in g.get('processorStatusSnapshots',[]):
            s=p['processorStatusSnapshot']; n=s['name']; key=path+'/'+n
            if n not in WATCH: continue
            if s['activeThreadCount'] and key not in start: start[key]=time.time()
            elif not s['activeThreadCount'] and key in start:
                print(time.strftime('%T'),f'{time.time()-start.pop(key):5.0f}s',key[-60:],flush=True)
        for c in g.get('processGroupStatusSnapshots',[]): w(c['processGroupStatusSnapshot'],path+'/'+c['processGroupStatusSnapshot']['name'][:14])
    w(agg,'')
    k+=1
    if k%10==0:
        for x in G(f'/flow/bulletin-board?groupId={NEW}&limit=100')['bulletinBoard']['bulletins']:
            if x['id'] not in seen and 'bulletin' in x:
                seen.add(x['id']); print('LỖI',x['bulletin']['timestamp'],x['bulletin']['sourceName'][:35],x['bulletin']['message'][:250],flush=True)
    time.sleep(2)
print('XONG',time.strftime('%T'),'queued',agg['queued'],'threads',G('/flow/status')['controllerStatus']['activeThreadCount'])
