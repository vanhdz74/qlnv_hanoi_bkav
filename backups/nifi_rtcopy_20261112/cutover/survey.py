"""Chỉ đọc: liệt kê processor RT có tham chiếu _new_rt, lưu cấu hình hiện tại."""
import sys, json, re; sys.path.insert(0, '..'); sys.path.insert(0, '.')
from rtlib import G
NEW = '142f3e8a-6ef6-1fc2-54e3-a7ee0a9d3028'
out = []
def walk(g, path):
    f = G(f'/flow/process-groups/{g}')['processGroupFlow']['flow']
    for p in f['processors']:
        c = p['component']; props = c['config']['properties']
        hits = {k: v for k, v in props.items() if v and '_new_rt' in v}
        out.append(dict(id=c['id'], g=g, path=path, name=c['name'], type=c['type'].split('.')[-1], state=c['state'],
                        sched=c['config']['schedulingStrategy'] + ' ' + c['config']['schedulingPeriod'],
                        props_new_rt=hits, tables=sorted(set(t for v in hits.values() for t in re.findall(r'\b(\w+?)_new_rt\b', v)))))
    for sg in f['processGroups']: walk(sg['id'], path + '/' + sg['component']['name'])
walk(NEW, '')
json.dump(out, open('cutover/survey.json', 'w'), ensure_ascii=False, indent=1)
for x in out:
    if x['props_new_rt'] or x['type'] in ('GenerateFlowFile',) and x['state'] == 'RUNNING' or x['name'].startswith('0.'):
        print(f"{x['state']:8} {x['path'][:28]:28} | {x['name'][:55]:55} | {x['sched'][:22]:22} | {','.join(x['tables'])}")
