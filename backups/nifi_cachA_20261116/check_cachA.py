"""Kiểm tra sau deploy cách A: chờ khoi có syncdate mới hơn mốc deploy + 70s, rồi đếm."""
import sys, time, datetime
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import Q, G

start = Q("SELECT MAX(syncdate) m FROM datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan")[0]['m']
print('mốc tiepnhan lúc kiểm:', start)
t0 = datetime.datetime.fromisoformat(start)
for _ in range(40):
    m = Q("SELECT MAX(syncdate) m FROM datamart_hanoi.qlnv_tonghop_chitiet_khoi")[0]['m']
    if datetime.datetime.fromisoformat(m) >= t0 + datetime.timedelta(seconds=70): break
    time.sleep(10)
print('khoi syncdate:', m)
for t in ['qlnv_tonghop_chitiet_tiepnhan', 'qlnv_tonghop_chitiet_giaonv', 'qlnv_tonghop_chitiet_nhom_tiepnhan',
          'qlnv_tonghop_chitiet_nhom_giaonv', 'qlnv_tongquan']:
    print(t, Q(f"SELECT COUNT(*) n, MAX(syncdate) m FROM datamart_hanoi.{t}")[0])
print('khoi', Q("SELECT NhomGiaoNhan, COUNT(*) n FROM datamart_hanoi.qlnv_tonghop_chitiet_khoi GROUP BY NhomGiaoNhan"))
print('407556 khoi', Q("SELECT Ma, NhomGiaoNhan, donvi_dvgiao, donvi, TinhTrang FROM datamart_hanoi.qlnv_tonghop_chitiet_khoi WHERE Ma='407556'"))
print('695 giaonv', Q("SELECT COUNT(*) n FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv WHERE iddv=695"))
gid = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
b = G('/flow/bulletin-board?groupId=' + gid + '&limit=20')['bulletinBoard']['bulletins']
print('bulletins:', [(x['bulletin']['timestamp'], x['bulletin']['sourceName'], x['bulletin']['message'][:200]) for x in b if 'bulletin' in x])
for pid in ['142f3e95-6ef6-1fc2-5b4c-b08f5bee47c3', '142f3eb5-6ef6-1fc2-7578-0f74d7189542']:
    st = G(f'/processors/{pid}')['status']['aggregateSnapshot']
    print(pid[:8], 'tasks', st['taskCount'], 'in', st['flowFilesIn'], 'out', st['flowFilesOut'], 'dur', st['tasksDuration'])
