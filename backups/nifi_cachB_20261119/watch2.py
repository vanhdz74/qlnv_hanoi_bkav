import sys,time,json; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
cr=json.load(open('created.json'))
IDS={'chitiet_donvi':'142f3f44-6ef6-1fc2-74a4-b7a2b349b634','tongquan_donvi':'142f3f46-6ef6-1fc2-c4f1-b056108b9c4a','kiemdem':[p['id'] for p in allprocs(NEW) if p['id'].startswith('142f3f99')][0]}
INQ='142f3f47-6ef6-1fc2-a03a-9a1e8074584d'
END=time.time()+float(sys.argv[1])*60; st={}
while time.time()<END:
    for n,i in IDS.items():
        a=G(f'/flow/processors/{i}/status')['processorStatus']['aggregateSnapshot']['activeThreadCount']
        if a and n not in st: st[n]=time.time()
        if not a and n in st: print(time.strftime('%T'),f'{n:15} {time.time()-st.pop(n):4.0f}s  hàng đợi vào chitiet_donvi:',G(f'/connections/{INQ}')['status']['aggregateSnapshot']['queued'],flush=True)
    time.sleep(1)
for x in G(f'/flow/bulletin-board?groupId={NEW}&limit=20')['bulletinBoard']['bulletins']:
    if 'bulletin' in x and x['bulletin']['timestamp']>='09:49': print('B',x['bulletin']['timestamp'],x['bulletin']['sourceName'],x['bulletin']['message'][:200])
print(Q("SELECT NhomGiaoNhan, COUNT(*) n, MAX(syncdate) mx FROM datamart_hanoi.qlnv_tonghop_chitiet_donvi GROUP BY NhomGiaoNhan"))
