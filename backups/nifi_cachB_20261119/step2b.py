import sys, json, time; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
D='/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_cachB_20261119/'
created=json.load(open(D+'created.json'))
OUT_OLD='142f3f41-6ef6-1fc2-c9a9-acc8890f3730'; HIN='142f3fab-6ef6-1fc2-f363-bc2083616b5b'
oldp='142f403a-6ef6-1fc2-112e-9aa20e6918a0'
def rs(pid,st,kind):
    p=G(f'/{kind}/{pid}'); P('PUT',f'/{kind}/{pid}/run-status',{'revision':p['revision'],'state':st})
rs(HIN,'STOPPED','input-ports'); time.sleep(1)
c=G(f'/connections/{oldp}'); r=s.delete(API+f'/connections/{oldp}',params={'version':c['revision']['version']}); print('delete',r.status_code,r.content.decode()[:150])
rs(HIN,'RUNNING','input-ports'); rs(OUT_OLD,'RUNNING','output-ports'); rs(created['out1'],'RUNNING','output-ports')
print(time.strftime('%T'),'4. ports chạy lại; HĐND nối output_1phut')
