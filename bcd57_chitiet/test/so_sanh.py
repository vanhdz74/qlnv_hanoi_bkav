import openpyxl, csv, re, sys, unicodedata
from rapidfuzz import fuzz, process
D='/home/truongnbn/Documents/Superset,/QLNV/bcd57_chitiet/test/'
def norm(s):
    s=unicodedata.normalize('NFC',str(s or '')).lower()
    s=re.sub(r'[^\w\s]',' ',s); return re.sub(r'\s+',' ',s).strip()
wb=openpyxl.load_workbook(D+'571 NV TP (1).xlsx',read_only=True,data_only=True)
X=[]
for i,r in enumerate(wb.worksheets[0].iter_rows(values_only=True)):
    if i>=4 and r[1] and str(r[1]).strip(): X.append(dict(stt=r[0],ten=str(r[1]).strip(),vb=r[2],ct=r[3]))
C=list(csv.DictReader(open(D+'check.csv',encoding='utf-8')))
for c in C:
    full=norm(c['ten_nhiem_vu']); cd=norm(c['chu_de'])
    c['n_full']=full
    c['n_strip']=full[len(cd):].strip() if cd and cd!='chưa phân loại' and full.startswith(cd) else full
xn=[norm(x['ten']) for x in X]
def score(a,c): return max(fuzz.ratio(a,c['n_full']),fuzz.ratio(a,c['n_strip']))
M=[[score(a,c) for c in C] for a in xn]
TH=70
missing=[];extra=[]
for i,x in enumerate(X):
    j=max(range(len(C)),key=lambda j:M[i][j]); x['best']=M[i][j]; x['bj']=j
    if M[i][j]<TH: missing.append(x)
for j,c in enumerate(C):
    i=max(range(len(X)),key=lambda i:M[i][j]); c['best']=M[i][j]; c['bi']=i
    if M[i][j]<TH: extra.append(c)
print('excel',len(X),'csv',len(C),'thieu',len(missing),'thua',len(extra))
import collections
print('csv distinct names',len(set(c['n_full'] for c in C)))
with open(sys.argv[1],'w',newline='',encoding='utf-8-sig') as f:
    w=csv.writer(f); w.writerow(['loai','stt_excel/task_id','van_ban','ten_nhiem_vu','diem_gan_nhat','ten_gan_nhat_ben_kia'])
    for x in missing: w.writerow(['THIEU (co trong Excel, khong co trong check.csv)',x['stt'],x['vb'],x['ten'],round(x['best']),C[x['bj']]['ten_nhiem_vu']])
    for c in extra: w.writerow(['THUA (co trong check.csv, khong co trong Excel)',c['task_id'],c['van_ban_giao'],c['ten_nhiem_vu'],round(c['best']),X[c['bi']]['ten']])
# score distribution near threshold
print('excel best 60-80:',sum(60<=x['best']<80 for x in X),' csv best 60-80:',sum(60<=c['best']<80 for c in C))
