"""Thư viện dùng chung cho chạy thử luồng RT 142f3e8a: NiFi API + SELECT qua Superset SQL Lab (chỉ đọc)."""
import re, json, time, requests, urllib3
urllib3.disable_warnings()
env = {}
for l in open('/home/truongnbn/Documents/Superset,/QLNV/.env'):
    m = re.match(r'\s*([A-Z_]+)\s*=\s*(.*)', l)
    if m: env[m[1]] = m[2].strip().strip('"\'')

# ---------- NiFi
B = env['NIFI_URL'].rstrip('/')
s = requests.Session(); s.verify = False
tok = s.post(B + '/nifi-api/access/token', data={'username': env['NIFI_USERNAME'], 'password': env['NIFI_PASSWORD']}).text
s.headers.update({'Authorization': 'Bearer ' + tok, 'Origin': B, 'Referer': B + '/nifi/',
                  'Request-Token': s.cookies.get('__Secure-Request-Token') or ''})
API = B + '/nifi-api'
def G(p): r = s.get(API + p); r.raise_for_status(); return r.json()
def P(m, p, body):
    r = s.request(m, API + p, json=body)
    if r.status_code >= 300: raise SystemExit(f'{m} {p} -> {r.status_code} {r.text[:500]}')
    return r.json()

OLD = 'f8207212-019b-1000-fcc5-817989167c53'   # BTH - Đơn vị
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'   # [RT CHỜ DUYỆT 12/11]

def procs(gid): return G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']['processors']
def allprocs(gid):
    f = G(f'/flow/process-groups/{gid}')['processGroupFlow']['flow']
    out = [dict(p, _g=gid) for p in f['processors']]
    for g in f['processGroups']: out += allprocs(g['id'])
    return out
def setstate(p, state):
    p = G(f'/processors/{p["id"]}')
    return P('PUT', f'/processors/{p["id"]}/run-status', {'revision': p['revision'], 'state': state})

# ---------- Superset SQL Lab (SELECT)
SU = env['SUPERSET_URL'].rstrip('/')
ss = requests.Session(); ss.verify = False
ss.headers.update({'Referer': SU + '/login/', 'Origin': SU})
_h = ss.get(SU + '/login/').text
_c = re.search(r'name="csrf_token"[^>]*value="([^"]+)"', _h) or re.search(r'value="([^"]+)"[^>]*name="csrf_token"', _h)
ss.post(SU + '/login/', data={'csrf_token': _c[1], 'username': env['SUPERSET_USERNAME'], 'password': env['SUPERSET_PASSWORD']})
ss.headers['X-CSRFToken'] = ss.get(SU + '/api/v1/security/csrf_token/').json()['result']
def Q(sql, db=8):
    r = ss.post(SU + '/api/v1/sqllab/execute/', json={'database_id': db, 'sql': sql, 'runAsync': False,
                                                         'schema': 'datamart_hanoi', 'queryLimit': 10000})
    j = r.json()
    if r.status_code >= 300: raise RuntimeError(str(j)[:500])
    return j.get('data', [])

P_ = 'qlnv_tonghop_chitiet'
TABLES = [P_ + x for x in ['_tiepnhan', '_tiepnhan_don_le', '_tiepnhan_theo_chuoi', '_nhom_tiepnhan',
                           '_giaonv', '_giaonv_don_le', '_giaonv_theo_chuoi', '_nhom_giaonv',
                           '', '_nhom', '_khoi']] + ['qlnv_tongquan']
