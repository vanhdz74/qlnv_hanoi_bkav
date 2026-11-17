// [CDC THỬ 17/11] Đọc binlog qua SQL (SHOW BINLOG EVENTS, đi qua ProxySQL 6033) mỗi 5s.
// Ghi vào datamart_hanoi.rt_cdc_log:
//   op='binlog'          : 1 dòng / bảng có sự kiện trong lượt; payload = số sự kiện theo loại (1 sự kiện có thể gồm nhiều dòng)
//   op='taskid'          : TaskId có UpdatedDate mới ở bảng đó (lấy theo watermark từng bảng)
//   op='khong_co_taskid' : binlog thấy bảng (có TaskId) bị ghi nhưng không có UpdatedDate mới → UpdatedDate không đổi
//   op='ddl'             : câu Query không phải BEGIN/COMMIT
// Trạng thái (file/pos binlog, watermark) trong datamart_hanoi.rt_cdc_state. datamart_hanoi không nằm trong Binlog_Do_DB → không tự bắt chính mình.
import groovy.json.JsonOutput
def db = SQL.db
def now = { new Date().format('yyyy-MM-dd HH:mm:ss.SSS') }
def TBL = ['qlnv_task','qlnv_task_user','qlnv_report','qlnv_timeline','qlnv_file','qlnv_task_ext','qlnv_combination',
           'qlnv_task_period_configs','qlnv_task_roadmap','qlnv_follow','qlnv_task_roadmap_report','qlnv_task_roadmap_file',
           'qlnv_eform_round','qlnv_rotation_log','qlnv_rotation','qlnv_task_delegation'] as Set
def SRC = 'db_theodoinv_hn'

def st = [:]
db.eachRow("SELECT k, v FROM datamart_hanoi.rt_cdc_state") { st[it.k] = it.v }
def put = { k, v -> db.execute("INSERT INTO datamart_hanoi.rt_cdc_state(k,v) VALUES (?,?) ON DUPLICATE KEY UPDATE v=VALUES(v)", [k, v as String]) }
def log = { Map m -> db.execute("""INSERT INTO datamart_hanoi.rt_cdc_log(nifi_at,db,tbl,op,pk,task_id,binlog_file,binlog_pos,payload)
                                    VALUES (?,?,?,?,?,?,?,?,?)""",
        [now(), m.db, m.tbl, m.op, m.pk, m.task_id, m.file, m.pos, m.payload]) }

def master = db.firstRow("SHOW MASTER STATUS")
if (!st.binlog_file) {   // lần đầu: bắt đầu từ vị trí hiện tại, đặt watermark = MAX(UpdatedDate) hiện có
    put('binlog_file', master.File); put('binlog_pos', master.Position)
    TBL.each { t -> put('wm:' + t, db.firstRow("SELECT COALESCE(MAX(UpdatedDate),'1970-01-01') m FROM ${SRC}.${t}".toString()).m) }
    log(op: 'khoi_dong', file: master.File, pos: master.Position, payload: 'bắt đầu từ vị trí hiện tại')
    return
}

def files = db.rows("SHOW BINARY LOGS")*.Log_name.findAll { it >= st.binlog_file }.sort()
def tblById = [:], cnt = [:].withDefault { [:].withDefault { 0 } }
String curFile = st.binlog_file; long curPos = st.binlog_pos as long; int total = 0
for (f in files) {
    long from = (f == st.binlog_file) ? (st.binlog_pos as long) : 4L
    curFile = f; curPos = from
    while (true) {
        def rows = db.rows("SHOW BINLOG EVENTS IN '${f}' FROM ${from} LIMIT 5000".toString())
        rows.each { r ->
            String ty = r.Event_type, info = r.Info ?: ''
            if (ty == 'Table_map') {
                def m = info =~ /table_id: (\d+) \((.+)\)/
                if (m) tblById[m[0][1]] = m[0][2]
            } else if (ty ==~ /(Write|Update|Delete)_rows.*/) {
                def m = info =~ /table_id: (\d+)/
                cnt[m ? (tblById[m[0][1]] ?: '?') : '?'][ty]++
            } else if (ty == 'Query' && !(info in ['BEGIN', 'COMMIT']) && !info.startsWith('SET ')) {
                log(op: 'ddl', file: f, pos: r.Pos, payload: info.take(2000))
            }
        }
        total += rows.size()
        if (rows) { curPos = rows[-1].End_log_pos as long; from = curPos }
        if (rows.size() < 5000 || total > 200000) break
    }
    if (total > 200000) break
}

cnt.each { full, ops ->
    def (d, t) = full.contains('.') ? full.split('\\.', 2) : [null, full]
    log(op: 'binlog', db: d, tbl: t, file: curFile, pos: curPos, payload: JsonOutput.toJson(ops))
    if (d == SRC && t in TBL) {
        String wm = st['wm:' + t] ?: '1970-01-01'
        def ids = db.rows("""SELECT TaskId, MAX(UpdatedDate) u FROM ${SRC}.${t} WHERE UpdatedDate > ? GROUP BY TaskId ORDER BY u LIMIT 1000""".toString(), [wm])
        if (ids) {
            ids.each { log(op: 'taskid', db: d, tbl: t, task_id: it.TaskId as String, file: curFile, pos: curPos,
                           payload: JsonOutput.toJson([UpdatedDate: it.u?.toString(), watermark_truoc: wm])) }
            put('wm:' + t, ids*.u.max())
        } else {
            log(op: 'khong_co_taskid', db: d, tbl: t, file: curFile, pos: curPos,
                payload: 'binlog có ghi nhưng không có UpdatedDate > ' + wm)
        }
    }
}
put('binlog_file', curFile); put('binlog_pos', curPos)
put('last_poll', now() + ' | ' + total + ' sự kiện | master ' + master.File + ':' + master.Position)
