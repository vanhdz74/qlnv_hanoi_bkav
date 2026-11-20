"""Deploy v2 SQL (GROUP BY theo khóa) cho ExecuteSQL 142f3f99 qlnv_tongquan_donvi_kiemdem.
Chạy: python3 deploy_v2.py [rollback]
"""
import os, sys, time, json, requests, urllib3
urllib3.disable_warnings()
ROOT = os.path.dirname(os.path.abspath(__file__))
env = {}
for l in open(os.path.join(ROOT, '../../.env')):
    if '=' in l and not l.lstrip().startswith('#'):
        k, v = l.strip().split('=', 1); env[k] = v.strip('"\'')
B = env['NIFI_URL'].rstrip('/')
P = '142f3f99-6ef6-1fc2-3321-8ca8b54f106a'
PROP = 'SQL select query'

s = requests.Session(); s.verify = False
tok = s.post(B + '/nifi-api/access/token',
             data={'username': env.get('NIFI_USERNAME', 'admin'), 'password': env['NIFI_PASSWORD']}).text
rt = s.cookies.get('__Secure-Request-Token', '')
H = {'Authorization': 'Bearer ' + tok, 'Origin': B, 'Referer': B + '/nifi/',
     'Request-Token': rt, 'Content-Type': 'application/json'}

rollback = len(sys.argv) > 1 and sys.argv[1] == 'rollback'
old = open(os.path.join(ROOT, 'goc.sql')).read()
new = open(os.path.join(ROOT, 'v2_group_theo_khoa.sql')).read()
src, dst = (new, old) if rollback else (old, new)

def get():
    r = s.get(f'{B}/nifi-api/processors/{P}', headers=H); r.raise_for_status(); return r.json()

d = get()
cur = d['component']['config']['properties'][PROP]
if cur == dst:
    print('Đã là bản đích, không làm gì'); sys.exit(0)
assert cur == src, 'SQL hiện tại khác bản nguồn mong đợi -> dừng, không ghi'

# 1. dừng processor
r = s.put(f'{B}/nifi-api/processors/{P}/run-status', headers=H,
          json={'revision': d['revision'], 'state': 'STOPPED'}); r.raise_for_status()
for _ in range(120):
    d = get()
    if d['status']['aggregateSnapshot']['activeThreadCount'] == 0 and d['component']['state'] == 'STOPPED':
        break
    time.sleep(1)
else:
    sys.exit('Processor chưa dừng hẳn sau 120s (còn thread) -> kiểm tra thủ công')
print('Đã dừng')

# 2. cập nhật SQL
r = s.put(f'{B}/nifi-api/processors/{P}', headers=H, json={
    'revision': d['revision'],
    'component': {'id': P, 'config': {'properties': {PROP: dst}}}})
r.raise_for_status()
d = get()
assert d['component']['config']['properties'][PROP] == dst
print('Đã cập nhật SQL, validation:', d['component']['validationStatus'])
for _ in range(30):
    if d['component']['validationStatus'] == 'VALID': break
    time.sleep(1); d = get()

# 3. chạy lại
r = s.put(f'{B}/nifi-api/processors/{P}/run-status', headers=H,
          json={'revision': d['revision'], 'state': 'RUNNING'}); r.raise_for_status()
print('Đã chạy lại:', get()['component']['state'])
