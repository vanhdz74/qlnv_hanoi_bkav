"""Đổi luồng bản sao 142f3e8a từ staging-swap sang upsert+delete (trừ qlnv_tongquan), lịch 1 phút,
thêm 2 processor DDL / ROLLBACK DDL (STOPPED / DISABLED). Không đụng luồng cũ."""
import re, json
exec(open('deploy.py').read().split('ROOT = ')[0].replace('from transform import PLAN', ''))
from transform_upsert import PLAN, DDL, DDL_ROLLBACK
ids = json.load(open('rt_copy_ids.json'))
NG, COP = ids['group'], ids['copies']

_old = {f['breadcrumb']['breadcrumb']['name']: f for f in json.load(open('bth_donvi_flow.json')).values()}
ORIG = {}
for _g, _items in PLAN.items():
    for _n, _prop, _ in _items:
        _m = [p for p in _old[_g]['flow']['processors'] if p['component']['name'] == _n and p['component']['state'] != 'DISABLED']
        assert len(_m) == 1, (_g, _n)
        ORIG[(_g, _n)] = _m[0]['component']['config']['properties'][_prop]

def procs(gid): return G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']['processors']
def put(p, comp):
    comp['id'] = p['id']
    return P('PUT', f'/processors/{p["id"]}', {'revision': p['revision'], 'component': comp})

# chắc chắn không có gì đang chạy trong group mới
st = G(f'/flow/process-groups/{NG}/status?recursive=true')['processGroupStatus']['aggregateSnapshot']
assert st['activeThreadCount'] == 0 and st['queuedCount'] == '0', st

for gname, items in PLAN.items():
    cp = procs(COP[gname])
    for pname, prop, fn in items:
        c = [p for p in cp if p['component']['name'] == pname + ' [stg]']
        assert len(c) == 1, (gname, pname)
        c = c[0]; assert c['component']['state'] == 'STOPPED'
        # lấy SQL GỐC từ bản backup luồng cũ (không lấy từ bản [stg])
        put(c, {'name': pname + ' [upsert]', 'config': {'properties': {prop: fn(ORIG[(gname, pname)])}}})
        print('upsert', gname, '|', pname)

# GFF: 1 phút, cổng 15 phút theo phút đồng hồ
g = [p for p in procs(NG) if p['component']['type'].endswith('GenerateFlowFile')][0]
put(g, {'name': '1 PHÚT / 1 LẦN (CRON :17)', 'config': {'schedulingStrategy': 'CRON_DRIVEN', 'schedulingPeriod': '17 * * * * ?',
        'properties': {'gate15': "${now():format('m'):toNumber():mod(15):equals(0)}"}}})
print('GFF -> 17 * * * * ?')

def esql(name, sql, pos):
    return P('POST', f'/process-groups/{NG}/processors', {'revision': REV0, 'component': {
        'type': 'org.apache.nifi.processors.standard.ExecuteSQL', 'name': name, 'position': pos,
        'config': {'schedulingStrategy': 'TIMER_DRIVEN', 'schedulingPeriod': '1 day',
                   'autoTerminatedRelationships': ['success', 'failure'],
                   'properties': {'Database Connection Pooling Service': 'a06e038b-019a-1000-f4f2-fdf9e5995ada',
                                  'SQL select query': sql}}}})
d = esql('0. DDL upsert — Run once SAU KHI dừng chuỗi cũ', DDL, {'x': -500.0, 'y': -300.0})
r = esql('0. ROLLBACK DDL — Run once TRƯỚC KHI bật lại chuỗi cũ', DDL_ROLLBACK, {'x': -500.0, 'y': -60.0})
P('PUT', f'/processors/{r["id"]}', {'revision': r['revision'], 'component': {'id': r['id'], 'state': 'DISABLED'}})
print('DDL', d['id'], 'ROLLBACK', r['id'])

# label trong group
labs = G(f'/flow/process-groups/{NG}')['processGroupFlow']['flow']['labels']
TXT = ("[RT CHỜ DUYỆT 12/11] Bản sao chuỗi Tiếp nhận NV → Giao NV → Giao + Nhận NV — UPSERT + DELETE theo syncdate. Đang STOPPED.\n"
       "• 15 bảng: INSERT … ON DUPLICATE KEY UPDATE, rồi DELETE WHERE syncdate < '${sync_ts}' (giờ NiFi). Phần SELECT giữ nguyên.\n"
       "  Khóa: Ma (tiepnhan/giaonv/don_le/theo_chuoi/nhom_*), (Ma, NhomGiaoNhan) (chitiet/nhom/khoi).\n"
       "  SELECT * → cột tường minh + syncdate = sync_ts (syncdate là TIMESTAMP ON UPDATE, giờ MySQL chậm 4'40\").\n"
       "  NhomCauTrucNhiemVu/DonViChuTri không ghi đè khi upsert; 3 câu UPDATE Nhóm → 1 câu tính lại toàn bộ.\n"
       "• qlnv_tongquan: giữ staging + RENAME swap (bảng GROUP BY 11 cột có NULL, không có khóa tự nhiên).\n"
       "• Lịch: CRON 17 * * * * ? (1 phút), back pressure 1 → thực tế = thời gian chạy chuỗi.\n"
       "THỬ: dừng GFF 15' cũ → Run once '0. DDL upsert' → start group. HOÀN TÁC: stop group → enable + Run once ROLLBACK DDL → start GFF cũ.")
for l in labs:
    P('PUT', f'/labels/{l["id"]}', {'revision': l['revision'], 'component': {'id': l['id'], 'label': TXT}})
print('label ok')
