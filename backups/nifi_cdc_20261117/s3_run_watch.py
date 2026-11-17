"""Bước 1 CDC thử (17/11): đặt mật khẩu (từ .env MYSQL_CDC_PASSWORD nếu có), bật luồng, theo dõi N phút (mặc định 10), rồi DỪNG CDC.
Dừng sớm nếu hàng đợi > 15000 hoặc có bulletin lỗi lặp. Log ra watch.log."""
import sys, json, os, time, re
sys.path.insert(0, '/home/truongnbn/Documents/Superset,/QLNV/backups/nifi_rtcopy_20261112')
from rtlib import G, P, Q, setstate, env
HERE = os.path.dirname(os.path.abspath(__file__))
ids = json.load(open(f'{HERE}/ids.json'))
MIN = float(sys.argv[1]) if len(sys.argv) > 1 else 10
LOG = open(f'{HERE}/watch.log', 'a')
def out(*a):
    s = time.strftime('%T ') + ' '.join(str(x) for x in a); print(s, flush=True); LOG.write(s + '\n'); LOG.flush()

CDC, EV, RT, PS = ids['cdc'], ids['p_Tách trường sự kiện'], ids['p_Tạo INSERT rt_cdc_log'], ids['p_Ghi rt_cdc_log']
pw = env.get('MYSQL_CDC_PASSWORD')
if pw:
    p = G(f'/processors/{CDC}')
    P('PUT', f'/processors/{CDC}', {'revision': p['revision'], 'component': {'id': CDC, 'config': {
        'properties': {'capture-change-mysql-password': pw}}}})
    out('đã đặt mật khẩu từ .env')
elif not G(f'/processors/{CDC}')['component']['config']['properties'].get('capture-change-mysql-password'):
    raise SystemExit('Chưa có mật khẩu: điền MYSQL_CDC_PASSWORD trong .env hoặc nhập Password ở processor CDC trong NiFi UI.')

out('MASTER trước khi bật:', Q('SHOW MASTER STATUS')[0])
base = Q('SELECT COALESCE(MAX(id),0) m FROM datamart_hanoi.rt_cdc_log')[0]['m']
out('rt_cdc_log id mốc =', base)
for x in (PS, RT, EV, CDC): setstate({'id': x}, 'RUNNING')
out(f'ĐÃ BẬT CDC — theo dõi {MIN:g} phút')

seen_b, end, stop_reason = set(), time.time() + MIN * 60, 'hết giờ'
try:
    while time.time() < end:
        time.sleep(30)
        st = G(f'/flow/process-groups/{ids["group"]}/status')['processGroupStatus']['aggregateSnapshot']
        q = st['flowFilesQueued']
        r = Q(f"""SELECT db, tbl, op, COUNT(*) n, MAX(nifi_at) last_nifi FROM datamart_hanoi.rt_cdc_log
                  WHERE id > {base} GROUP BY db, tbl, op ORDER BY n DESC LIMIT 12""")
        tot = sum(x['n'] for x in r)
        out(f'hàng đợi={q} | đã ghi {tot} sự kiện (top bảng):',
            '; '.join(f"{x['db']}.{x['tbl']} {x['op']} {x['n']}" for x in r[:8]))
        for b in G(f'/flow/bulletin-board?groupId={ids["group"]}&limit=20')['bulletinBoard']['bulletins']:
            if b['id'] not in seen_b and b.get('bulletin'):
                seen_b.add(b['id']); out('BULLETIN', b['bulletin']['level'], b['bulletin']['sourceName'], b['bulletin']['message'][:300])
        if q > 15000: stop_reason = f'hàng đợi {q} > 15000'; break
finally:
    setstate({'id': CDC}, 'STOPPED')
    out('ĐÃ DỪNG CDC —', stop_reason, '| state:', json.dumps(G(f'/processors/{CDC}/state')['componentState']['localState']['state'])[:300])
    for _ in range(20):  # cho phần ghi xả hết hàng đợi rồi dừng
        if G(f'/flow/process-groups/{ids["group"]}/status')['processGroupStatus']['aggregateSnapshot']['flowFilesQueued'] == 0: break
        time.sleep(3)
    for x in (EV, RT, PS): setstate({'id': x}, 'STOPPED')
    out('đã dừng cả luồng. Tổng theo bảng:')
    for x in Q(f"""SELECT db, tbl, op, COUNT(*) n, MIN(nifi_at) dau, MAX(nifi_at) cuoi FROM datamart_hanoi.rt_cdc_log
                   WHERE id > {base} GROUP BY db, tbl, op ORDER BY db, tbl, op"""):
        out('  ', x)
