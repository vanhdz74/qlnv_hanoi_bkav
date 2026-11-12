# Sửa lỗi PutSQL 73bb390c "Transaction characteristics can't be changed while a transaction is in progress"
# Group: QLNV - Tổng quan & chi tiết các nhiệm vụ 'Giao' (73bb3909, trong "Kiểm đếm nv, Phòng ban thuộc UBND TP")
# Nguyên nhân: PutSQL autocommit=false; CREATE TEMPORARY TABLE ... SELECT (không implicit commit) mở transaction,
# rồi mới tới SET TRANSACTION ISOLATION LEVEL -> MySQL từ chối.
# Sửa: đưa SET TRANSACTION ISOLATION LEVEL READ COMMITTED lên dòng đầu (cả bảng tạm + INSERT cùng chạy RC).
import json, sys, os
sys.path.insert(0, '/tmp/claude-1000/-home-truongnbn-Documents-Superset--QLNV/9d9dbb56-7ece-4f92-b12b-78abb5eef6d0/scratchpad')
from nifi import G, P

PID = '73bb390a-cea7-1f5d-ba09-f110dcc745ab'
HERE = os.path.dirname(os.path.abspath(__file__))
RC = 'SET TRANSACTION ISOLATION LEVEL READ COMMITTED;'
CMT = '/* 11/11 real-time: READ COMMITTED để INSERT…SELECT đọc snapshot, không khóa S bảng nguồn */'

p = G('/processors/' + PID)
json.dump(p, open(os.path.join(HERE, 'backup_73bb390a_before.json'), 'w'), ensure_ascii=False, indent=1)
v = p['component']['config']['properties']['Replacement Value']
assert v.count(RC) == 1 and v.count(CMT) == 1, 'nội dung đã khác dự kiến'
new = v.replace(CMT + '\n' + RC + '\n', '')
assert RC not in new
new = CMT.replace('11/11', '11/11 (12/11: đưa lên đầu, trước bảng tạm)') + '\n' + RC + '\n' + new
open(os.path.join(HERE, 'new_73bb390a.sql'), 'w').write(new)
if '--apply' not in sys.argv:
    print(new[:400]); print('... (dry-run, thêm --apply để ghi)'); sys.exit()
import time
def rev(): return G('/processors/' + PID)['revision']
P('PUT', '/processors/' + PID + '/run-status', {'revision': rev(), 'state': 'STOPPED'})
for _ in range(30):
    if G('/processors/' + PID)['status']['aggregateSnapshot'].get('activeThreadCount', 0) == 0: break
    time.sleep(1)
P('PUT', '/processors/' + PID, {'revision': rev(), 'component': {'id': PID,
  'config': {'properties': {'Replacement Value': new}}}})
P('PUT', '/processors/' + PID + '/run-status', {'revision': rev(), 'state': 'RUNNING'})
c = G('/processors/' + PID)['component']
print('OK', c['state'], c['validationStatus'])
