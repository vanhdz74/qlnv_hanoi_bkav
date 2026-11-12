"""Chỉ đọc. GROUP BY đơn vị riêng từng phía (không join), đối chiếu trong Python: đơn vị nào lệch số dòng."""
from rtlib import Q
S='datamart_hanoi'
for t,c in [('qlnv_tongquan_dieuhanh_lanhdao','iddv,donvi'),('qlnv_tongquan_donvi','iddv,donvi'),('qlnv_tonghop_chitiet_donvi','iddv,donvi'),
            ('qlnv_th_tongquan_donvi_tiepnhan','iddv,donvi'),('qlnv_th_tongquan_donvi_giaonv','iddv_dvthuchien,donvi_dvthuchien'),('qlnv_tongquan_vanban_chitiet','iddv,donvi')]:
    g=lambda tb:{tuple(str(r[k]) for k in c.split(',')):r['n'] for r in Q(f"SELECT {c},COUNT(*) n FROM {S}.{tb} GROUP BY {c}")}
    a,b=g(t),g(t+'_new_rt')
    d=[(k,a.get(k,0),b.get(k,0)) for k in set(a)|set(b) if a.get(k,0)!=b.get(k,0)]
    print(f"{t:38} nhóm cũ={len(a)} mới={len(b)} nhóm lệch={len(d)} tổng|Δ|={sum(abs(x[2]-x[1]) for x in d)}")
    for x in sorted(d,key=lambda x:-abs(x[2]-x[1]))[:4]: print('    ',x)
