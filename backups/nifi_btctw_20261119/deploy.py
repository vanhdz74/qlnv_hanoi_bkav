import sys, json, time, re; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
GID='142f3ed8-6ef6-1fc2-d06d-d0c4aa837b0b'
full=lambda pre:[x['id'] for x in allprocs(GID) if x['id'].startswith(pre)][0]
KB,TQ,NHOM=full('142f3edf'),full('142f3ee0'),full('142f3ee1')
bk={n:G(f'/processors/{i}') for n,i in [('khoi_btctw',KB),('tongquan_btctw',TQ),('nhom',NHOM)]}
json.dump(bk,open('backup_before.json','w'),ensure_ascii=False,indent=1); print('backup ok')
def swap(sql,t):
    body=re.sub(r'^\s*TRUNCATE TABLE datamart_hanoi\.'+t+r'\s*;\s*','',sql)
    body=body.replace(f'INSERT INTO datamart_hanoi.{t}',f'INSERT INTO datamart_hanoi.{t}__stg',1).rstrip().rstrip(';')
    assert f'{t}__stg' in body and 'TRUNCATE' not in body
    T=f'datamart_hanoi.{t}'
    return (f"/* [RT 19/11 BTCTW] mỗi phút sau nhom; TRUNCATE+INSERT → staging + RENAME swap */\n"
            f"CREATE TABLE IF NOT EXISTS {T}__stg LIKE {T};\nTRUNCATE TABLE {T}__stg;\n"
            f"SET TRANSACTION ISOLATION LEVEL READ COMMITTED;\n{body};\n"
            f"SET SESSION lock_wait_timeout = 10;\n"
            f"RENAME TABLE {T} TO {T}__old, {T}__stg TO {T}, {T}__old TO {T}__stg;\n"
            f"SET SESSION lock_wait_timeout = 31536000;")
new={}
for n,i,t in [('khoi_btctw',KB,'qlnv_tonghop_chitiet_khoi_btctw'),('tongquan_btctw',TQ,'qlnv_tongquan_btctw')]:
    new[n]=swap(bk[n]['component']['config']['properties']['SQL select query'],t)
    open(f'{n}_new.sql','w').write(new[n])
if '--dry' in sys.argv: print(new['khoi_btctw']); sys.exit()
def rs(pid,st):
    p=G(f'/processors/{pid}'); P('PUT',f'/processors/{pid}/run-status',{'revision':p['revision'],'state':st})
for n,i in [('khoi_btctw',KB),('tongquan_btctw',TQ)]:
    rs(i,'STOPPED')          # DISABLED -> STOPPED
    p=G(f'/processors/{i}')
    rels=[r['name'] for r in p['component']['relationships']]
    at=['success'] if n=='tongquan_btctw' else []
    P('PUT',f'/processors/{i}',{'revision':p['revision'],'component':{'id':i,'config':{'properties':{'SQL select query':new[n]},'autoTerminatedRelationships':at}}})
    print(n,'SQL đổi, rels',rels,'autoterm',at)
# nối nhom success -> khoi_btctw
c=P('POST',f'/process-groups/{GID}/connections',{'revision':{'version':0},'component':{'source':{'id':NHOM,'groupId':GID,'type':'PROCESSOR'},'destination':{'id':KB,'groupId':GID,'type':'PROCESSOR'},'selectedRelationships':['success']}})
json.dump({'conn_nhom_khoibtctw':c['id']},open('created.json','w')); print('conn',c['id'])
for n,i in [('tongquan_btctw',TQ),('khoi_btctw',KB)]:
    for _ in range(15):
        p=G(f'/processors/{i}')
        if p['component']['validationStatus']=='VALID': break
        time.sleep(1)
    print(n,p['component']['validationStatus'],p['component'].get('validationErrors'))
    rs(i,'RUNNING')
print(time.strftime('%T'),'đã bật')
