"""Đợi GFF cũ bee43592 phát lượt tiếp theo → STOP ngay GFF đó (lượt đang chạy vẫn đi hết) → đợi chuỗi cũ rỗng."""
import time
from rtlib import *
GFF = 'bee43592-c2d0-1c10-f125-4abd0acb46fa'
t0 = time.time()
while True:
    st = G(f'/flow/processors/{GFF}/status')['processorStatus']['aggregateSnapshot']
    if st['flowFilesOut'] > 0: break
    if time.time() - t0 > 1500: raise SystemExit('quá 25 phút không thấy lượt mới')
    time.sleep(5)
print('lượt cũ bắt đầu', time.strftime('%T'))
setstate(G(f'/processors/{GFF}'), 'STOPPED')
print('GFF cũ STOPPED', time.strftime('%T'))
time.sleep(20)
idle = 0
while idle < 3:
    a = G(f'/process-groups/{OLD}/status?recursive=true'.replace('/process-groups', '/flow/process-groups'))['processGroupStatus']['aggregateSnapshot']
    idle = idle + 1 if a['activeThreadCount'] == 0 and a['queuedCount'] == '0' else 0
    time.sleep(5)
print('chuỗi cũ xong', time.strftime('%T'))
for t in TABLES:
    if 'nhom_' not in t: print(t, Q(f'SELECT MAX(syncdate) m FROM datamart_hanoi.{t}')[0]['m'])
