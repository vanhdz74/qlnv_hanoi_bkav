"""Cập nhật SQL trong GenerateFlowFile, chạy 1 lần, in số dòng kiểm tra."""
import json,time,os
from nifi import call,set_state,rev
ids=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'nifi_flow_ids.json')))
D="/Users/hoangvietanh/Documents/BKAV/Superset, Nifi/qlnv_hanoi/qlnv_hanoi_bkav/bcd57_chitiet/chuyen_de/sql"
sql=open(os.path.join(D,"0_ddl.sql")).read()+"\n"+open(os.path.join(D,"1_nap_du_lieu.sql")).read()
p=call('GET',f"/processors/{ids['gen']}"); assert p['component']['state']=='STOPPED'
call('PUT',f"/processors/{ids['gen']}",{"revision":rev(p),"component":{"id":ids['gen'],"config":{"properties":{"generate-ff-custom-text":sql}}}})
for k in ('put','chk'): set_state(ids[k],'RUNNING')
set_state(ids['gen'],'RUN_ONCE')
for i in range(40):
    time.sleep(3)
    s=call('GET',f"/flow/process-groups/{ids['pg']}/status")['processGroupStatus']['aggregateSnapshot']
    q={c['connectionStatusSnapshot']['name']+'<-'+c['connectionStatusSnapshot']['sourceName']:(c['connectionStatusSnapshot']['flowFilesQueued'],c['id']) for c in s['connectionStatusSnapshots']}
    ok=[v for k,v in q.items() if k.startswith('success<-CDNQ57 - Kiem tra')][0]
    err=sum(v[0] for k,v in q.items() if 'failure' in k)
    if ok[0] or err: break
for k in ('put','chk'): set_state(ids[k],'STOPPED')
print('loi:',err)
cid=ok[1]
lr=call('POST',f"/flowfile-queues/{cid}/listing-requests"); time.sleep(2)
lr=call('GET',f"/flowfile-queues/{cid}/listing-requests/{lr['listingRequest']['id']}")
body=json.loads(call('GET',f"/flowfile-queues/{cid}/flowfiles/{lr['listingRequest']['flowFileSummaries'][-1]['uuid']}/content",raw=True))
print('tong dong',sum(int(r['so_dong']) for r in body),'co so lieu',sum(int(r['co_so_lieu']) for r in body),'sync',body[0]['sync_date'])
call('POST',f"/flowfile-queues/{cid}/drop-requests")
