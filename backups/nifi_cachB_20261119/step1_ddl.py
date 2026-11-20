import sys, json, time; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
D='/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_cachB_20261119/'
CT='142f3f44-6ef6-1fc2-74a4-b7a2b349b634'; DDL='142f3f25-6ef6-1fc2-2b93-8f65947374c8'
def wait_idle(pid):
    for _ in range(90):
        if G(f'/flow/processors/{pid}/status')['processorStatus']['aggregateSnapshot']['activeThreadCount']==0: return
        time.sleep(1)
    raise SystemExit('still active '+pid)
def run_status(pid, st):
    p=G(f'/processors/{pid}'); return P('PUT',f'/processors/{pid}/run-status',{'revision':p['revision'],'state':st})
# 1 stop chitiet_donvi
run_status(CT,'STOPPED'); wait_idle(CT); print(time.strftime('%T'),'chitiet_donvi STOPPED')
# 2 DDL processor: backup SQL, enable(stopped), set SQL, run once
d=G(f'/processors/{DDL}'); old=d['component']['config']['properties']['SQL select query']
json.dump(d,open(D+'backup_ddl_proc.json','w'),ensure_ascii=False)
run_status(DDL,'STOPPED')
d=G(f'/processors/{DDL}')
P('PUT',f'/processors/{DDL}',{'revision':d['revision'],'component':{'id':DDL,'config':{'properties':{'SQL select query':open(D+'ddl.sql').read()}}}})
for _ in range(20):
    d=G(f'/processors/{DDL}')
    if d['component']['validationStatus']=='VALID': break
    time.sleep(1)
t0=time.time(); run_status(DDL,'RUN_ONCE'); time.sleep(3); wait_idle(DDL)
print('DDL xong %.1fs'%(time.time()-t0))
for x in G(f'/flow/bulletin-board?sourceId={DDL}&limit=5')['bulletinBoard']['bulletins']:
    if x['bulletin']['timestamp']: print('BULLETIN',x['bulletin']['timestamp'],x['bulletin']['message'][:300])
# 3 restore SQL + disable
d=G(f'/processors/{DDL}')
P('PUT',f'/processors/{DDL}',{'revision':d['revision'],'component':{'id':DDL,'config':{'properties':{'SQL select query':old}}}})
run_status(DDL,'DISABLED'); print('DDL proc restored+disabled')
print(Q("SELECT index_name,GROUP_CONCAT(column_name ORDER BY seq_in_index) c FROM information_schema.statistics WHERE table_schema='datamart_hanoi' AND table_name='qlnv_tonghop_chitiet_donvi' AND non_unique=0 GROUP BY index_name"))
