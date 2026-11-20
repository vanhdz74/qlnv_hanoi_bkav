import sys, json, time; sys.path.insert(0,'/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import *
D='/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_cachB_20261119/'
GFF='142f3f00-'; CT='142f3f44-6ef6-1fc2-74a4-b7a2b349b634'; TQ='142f3f46-6ef6-1fc2-c4f1-b056108b9c4a'
GATE='142f3f07-6ef6-1fc2-31a6-eac5fc8029b8'; CGID='142f3f3f-6ef6-1fc2-473c-0776d4cf6dbb'
OUT_OLD='142f3f41-6ef6-1fc2-c9a9-acc8890f3730'; HDND_IN='142f3fab'; HDND_G='142f3faa-6ef6-1fc2-6805-d3971fd21a42'
created=json.load(open(D+'created.json')) if __import__('os').path.exists(D+'created.json') else {}
def save(): json.dump(created,open(D+'created.json','w'),indent=1)
def idle(pid,kind='processors'):
    for _ in range(90):
        if G(f'/flow/{kind}/{pid}/status')[{'processors':'processorStatus','output-ports':'portStatus'}[kind]]['aggregateSnapshot'].get('activeThreadCount',0)==0: return
        time.sleep(1)
    raise SystemExit('active '+pid)
def rs(pid,st,kind='processors'):
    p=G(f'/{kind}/{pid}'); P('PUT',f'/{kind}/{pid}/run-status',{'revision':p['revision'],'state':st})
def upd(pid,comp):
    p=G(f'/processors/{pid}'); comp['id']=pid; return P('PUT',f'/processors/{pid}',{'revision':p['revision'],'component':comp})
gff=[p['id'] for p in allprocs(NEW) if p['id'].startswith(GFF)][0]
hdnd_in=[x['id'] for x in G(f'/flow/process-groups/{HDND_G}')['processGroupFlow']['flow']['inputPorts'] if x['id'].startswith(HDND_IN)][0]
# ---- 1. GFF gate5 (tránh giây :17)
print('1. bỏ qua (đã xong)')
# ---- 2. SQL chitiet_donvi (đang STOPPED)
print('2. bỏ qua (đã xong)')
# ---- 3. trong Chi tiết đơn vị
rs(TQ,'STOPPED'); idle(TQ)
gate=G(f'/processors/{GATE}')['component']
if 'cong5' not in created:
    r=P('POST',f'/process-groups/{CGID}/processors',{'revision':{'version':0},'component':{'type':gate['type'],'bundle':gate['bundle'],
        'name':'Cổng 5 phút (trước tổng quan đơn vị) [19/11]','position':{'x':3976.0,'y':1176.0},
        'config':{'properties':{'Routing Strategy':'Route to Property name','qua_5phut':"${gate5:equals('true')}"},'autoTerminatedRelationships':['unmatched']}}})
    created['cong5']=r['id']; save()
if 'out1' not in created:
    r=P('POST',f'/process-groups/{CGID}/output-ports',{'revision':{'version':0},'component':{'name':'output_1phut','position':{'x':4600.0,'y':1496.0}}})
    created['out1']=r['id']; save()
def conn(gid,src,stype,sg,dst,dtype,dg,rels,key):
    if key in created: return
    c={'source':{'id':src,'groupId':sg,'type':stype},'destination':{'id':dst,'groupId':dg,'type':dtype}}
    if rels: c['selectedRelationships']=rels
    created[key]=P('POST',f'/process-groups/{gid}/connections',{'revision':{'version':0},'component':c})['id']; save()
conn(CGID,CT,'PROCESSOR',CGID,created['cong5'],'PROCESSOR',CGID,['success'],'c_ct_cong5')
conn(CGID,created['cong5'],'PROCESSOR',CGID,TQ,'PROCESSOR',CGID,['qua_5phut'],'c_cong5_tq')
conn(CGID,CT,'PROCESSOR',CGID,created['out1'],'OUTPUT_PORT',CGID,['success'],'c_ct_out1')
old='142f3f48-6ef6-1fc2-2b92-4813b6878c82'
try:
    c=G(f'/connections/{old}'); s.delete(API+f'/connections/{old}',params={'version':c['revision']['version']}).raise_for_status(); print('   xóa chitiet->tongquan')
except requests.HTTPError as e: print('   old conn', e)
rs(created['cong5'],'RUNNING'); rs(TQ,'RUNNING'); print('3. Chi tiết đơn vị OK')
# ---- 4. cha: output_1phut -> HĐND, bỏ output -> HĐND
conn(NEW,created['out1'],'OUTPUT_PORT',CGID,hdnd_in,'INPUT_PORT',HDND_G,None,'c_out1_hdnd')
oldp=None
pass
r=s.delete(API+f'/connections/{oldp}',params={'version':c['revision']['version']})
if r.status_code>=300:
    print('   delete cần dừng port:',r.text[:150]); rs(OUT_OLD,'STOPPED','output-ports'); time.sleep(1)
    c=G(f'/connections/{oldp}'); s.delete(API+f'/connections/{oldp}',params={'version':c['revision']['version']}).raise_for_status()
    rs(OUT_OLD,'RUNNING','output-ports')
rs(created['out1'],'RUNNING','output-ports'); print('4. HĐND nối output_1phut OK, port chạy')
# ---- 5. cổng tổng: qua_15phut -> moi_phut cho Chi tiết đơn vị + Văn bản
rs(GATE,'STOPPED'); idle(GATE)
g=G(f'/processors/{GATE}')['component']; at=set(g['config'].get('autoTerminatedRelationships') or []); at.add('qua_15phut')
for cid in ['142f4040-6ef6-1fc2-13e7-a0b8b72204a0','142f403f-6ef6-1fc2-9db8-837759e8ea10']:
    c=G(f'/connections/{cid}'); P('PUT',f'/connections/{cid}',{'revision':c['revision'],'component':{'id':cid,'selectedRelationships':['moi_phut']}})
upd(GATE,{'config':{'autoTerminatedRelationships':sorted(at)}})
rs(GATE,'RUNNING'); print('5. cổng tổng OK, autoterm',sorted(at))
# ---- 6. bật chitiet_donvi
rs(CT,'RUNNING'); print(time.strftime('%T'),'6. chitiet_donvi RUNNING')
