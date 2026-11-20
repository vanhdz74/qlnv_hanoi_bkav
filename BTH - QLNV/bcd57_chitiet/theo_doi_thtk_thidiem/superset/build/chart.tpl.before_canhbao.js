jsEchartScriptFunc = function (queryData, option, echarts, context) {
  /* ==========================================================================
     TÌNH HÌNH TRIỂN KHAI THÍ ĐIỂM — BCĐ 57 Thành ủy Hà Nội (tab 3 khung tab)
     Chuyển từ theo_doi_thtk_thidiem/dashboard_tinhhinh_trienkhai_v03.html sang 1 chart bkav-chart-advance.
     Dữ liệu: dataset ảo __DATASET__ — mỗi dòng = 1 đơn vị × 1 kỳ báo cáo
       (ma_don_vi, ten_don_vi, tt_don_vi, khoi, ma_ky, loai_ky, nhan_ky, ten_ky, stt_ky, han_nop, den_han,
        ts_nhap_dau, ts_gui_duyet, ts_phat_hanh, trang_thai, o_kiem_dem, so_bieu, so_bieu_hoan_tat,
        so_lan_tra_lai, lech_han_phut, moc_chup).
     Hiện là DỮ LIỆU MẪU (sinh lại y hệt bản HTML). Đổi sang số thật: chỉ đổi SQL của dataset, giữ tên cột.
     Bộ lọc Khối / Đơn vị / Loại kỳ nằm trong chart; bấm thẻ KPI, cột, ô lưới nhiệt, dòng bảng → Lớp 2.
     File sinh bằng superset/build.py – sửa ở chart.tpl.js rồi chạy lại.
     ========================================================================== */
  const elementId = context && context.elementId ? context.elementId : "thidiem-trienkhai";
  const rootEl = document.getElementById(elementId);
  if (!rootEl) return {};
  if (rootEl.__tdCleanup) { try { rootEl.__tdCleanup(); } catch (e) {} }
  const height = context && context.height ? context.height : null;

  // ============ 1. HẰNG SỐ ============
  const MAU = { nop_dung_han: "#00a870", nop_qua_han: "#f59e0b", da_nop: "#0e9384", chua_nop_con_han: "#1b6fe3", chua_nop_qua_han: "#e0202a", chua_nop: "#94a3b8" };
  const NHAN_O = { nop_dung_han: "Nộp đúng hạn", nop_qua_han: "Nộp quá hạn", da_nop: "Đã có số liệu", chua_nop_con_han: "Chưa nộp, còn hạn",
    chua_nop_qua_han: "Chưa nộp, quá hạn", chua_nop: "Chưa có số liệu" };
  // da_nop / chua_nop: nguồn chưa có hạn nộp nên không xếp được đúng hạn / quá hạn
  const KEYS_ALL = ["nop_dung_han", "nop_qua_han", "da_nop", "chua_nop_con_han", "chua_nop_qua_han", "chua_nop"];
  const NHAN_TT = { chua_nhap: "Chưa nhập", cho_duyet: "Chờ lãnh đạo duyệt", bi_tra_lai: "Bị trả lại", da_phat_hanh: "Đã phát hành" };
  const MAU_TT = { chua_nhap: "#8a99ae", cho_duyet: "#f59e0b", bi_tra_lai: "#825ee4", da_phat_hanh: "#00a870" };
  const O_THEO_NHAN = {}; KEYS_ALL.forEach((k) => { O_THEO_NHAN[NHAN_O[k]] = k; });
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const N = (x) => (x == null || x === "" || isNaN(+x) ? null : +x);
  const dt = (s) => {
    if (s == null || s === "") return null;
    if (typeof s === "number") return new Date(s);
    const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/.exec(String(s));
    return m ? new Date(+m[1], m[2] - 1, +m[3], +m[4], +m[5]) : null;
  };
  const nv = (v) => (v == null ? "—" : v);
  const p2 = (n) => (n < 10 ? "0" + n : "" + n);
  const fmtDT = (d) => (d ? p2(d.getDate()) + "/" + p2(d.getMonth() + 1) + " " + p2(d.getHours()) + ":" + p2(d.getMinutes()) : "—");
  const fmtFull = (d) => (d ? p2(d.getDate()) + "/" + p2(d.getMonth() + 1) + "/" + d.getFullYear() + " " + p2(d.getHours()) + ":" + p2(d.getMinutes()) : "—");
  const lechHan = (p) => {
    if (p === null || p === undefined) return "—";
    const s = p < 0 ? "−" : "+", a = Math.abs(p), h = Math.floor(a / 60), m = a % 60;
    return s + (h ? h + "h" + p2(m) : m + " phút");
  };

  // ============ 2. DỮ LIỆU ============
  const raw = queryData && Array.isArray(queryData.data) ? queryData.data : [];
  const FACT = raw.map((r) => ({
    ma_don_vi: r.ma_don_vi, ten: r.ten_don_vi, tt_dv: N(r.tt_don_vi) || 0, khoi: r.khoi,
    ma_ky: r.ma_ky, loai_ky: r.loai_ky, nhan: r.nhan_ky, ten_ky: r.ten_ky, stt_ky: N(r.stt_ky) || 0,
    han: dt(r.han_nop), den_han: N(r.den_han) == null ? null : N(r.den_han) === 1,
    ts_nhap_dau: dt(r.ts_nhap_dau), ts_gui_duyet: dt(r.ts_gui_duyet), ts_phat_hanh: dt(r.ts_phat_hanh),
    trang_thai: r.trang_thai || null, o_kiem_dem: r.o_kiem_dem, so_bieu: N(r.so_bieu), so_bieu_hoan_tat: N(r.so_bieu_hoan_tat),
    so_lan_tra_lai: N(r.so_lan_tra_lai), lech_han_phut: N(r.lech_han_phut), moc: dt(r.moc_chup),
  }));
  const NOW = FACT.reduce((a, f) => (f.moc && (!a || f.moc > a) ? f.moc : a), null) || new Date();
  const DONVI = [], KY = [], seenDv = {}, seenKy = {};
  FACT.forEach((f) => {
    if (!seenDv[f.ma_don_vi]) { seenDv[f.ma_don_vi] = 1; DONVI.push({ ma: f.ma_don_vi, ten: f.ten, khoi: f.khoi, tt: f.tt_dv }); }
    if (!seenKy[f.ma_ky]) { seenKy[f.ma_ky] = 1; KY.push({ ma: f.ma_ky, loai: f.loai_ky, nhan: f.nhan, ten: f.ten_ky, han: f.han, stt: f.stt_ky }); }
  });
  DONVI.sort((a, b) => a.tt - b.tt || (a.ten < b.ten ? -1 : 1));
  KY.sort((a, b) => (a.loai < b.loai ? -1 : a.loai > b.loai ? 1 : 0) || a.stt - b.stt);
  const KHOI = Array.from(new Set(DONVI.map((u) => u.khoi)));
  const LOAI = Array.from(new Set(KY.map((k) => k.loai)));
  const KEYS = KEYS_ALL.filter((k) => FACT.some((f) => f.o_kiem_dem === k));
  const daNop = (f) => f.o_kiem_dem === "nop_dung_han" || f.o_kiem_dem === "nop_qua_han" || f.o_kiem_dem === "da_nop";
  const chuaNop = (f) => /^chua_nop/.test(f.o_kiem_dem || "");
  // nguồn có những gì: không có thì chart hiện "—", không tự suy
  const coHan = (rows) => rows.some((f) => f.den_han !== null);
  const coTT = (rows) => rows.some((f) => f.trang_thai || f.ts_nhap_dau || f.ts_gui_duyet || f.ts_phat_hanh);
  const TEN_KY = {}; KY.forEach((k) => { TEN_KY[k.ma] = k.ten; });

  // trạng thái bộ lọc giữ qua các lần vẽ lại của Superset
  const state = rootEl.__tdState || (rootEl.__tdState = { khoi: "all", donVi: "all", loaiKy: LOAI.indexOf("Kỳ ngày") >= 0 ? "Kỳ ngày" : LOAI[0] });
  if (LOAI.indexOf(state.loaiKy) < 0) state.loaiKy = LOAI[0];

  const daNhap = (f) => !!f.ts_nhap_dau || (!!f.trang_thai && f.trang_thai !== "chua_nhap");
  const daGui = (f) => !!f.ts_gui_duyet || f.trang_thai === "cho_duyet" || f.trang_thai === "bi_tra_lai" || f.trang_thai === "da_phat_hanh";
  const daPH = (f) => !!f.ts_phat_hanh || f.trang_thai === "da_phat_hanh";
  const loc = () => FACT.filter((f) => f.loai_ky === state.loaiKy && (state.khoi === "all" || f.khoi === state.khoi) && (state.donVi === "all" || f.ma_don_vi === state.donVi));
  const kyHienTai = () => KY.filter((k) => k.loai === state.loaiKy);
  const donViHienTai = () => DONVI.filter((u) => (state.khoi === "all" || u.khoi === state.khoi) && (state.donVi === "all" || u.ma === state.donVi));

  // đối soát: tổng 4 ô = số dòng, mốc thời gian không nghịch / không ở tương lai
  function doiSoat() {
    const loi = [], o = { nop_dung_han: 0, nop_qua_han: 0, chua_nop_con_han: 0, chua_nop_qua_han: 0 };
    const expect = DONVI.length * KY.length;
    if (FACT.length !== expect) loi.push("số dòng " + FACT.length + " ≠ " + expect);
    FACT.forEach((f) => {
      if (!(f.o_kiem_dem in o)) loi.push("ô kiểm đếm lạ: " + f.o_kiem_dem); else o[f.o_kiem_dem]++;
      if (f.ts_gui_duyet && f.ts_nhap_dau && f.ts_gui_duyet < f.ts_nhap_dau) loi.push("mốc nghịch " + f.ma_don_vi);
      if (f.ts_phat_hanh && f.ts_gui_duyet && f.ts_phat_hanh < f.ts_gui_duyet) loi.push("mốc nghịch " + f.ma_don_vi);
      if (f.so_bieu_hoan_tat > f.so_bieu) loi.push("biểu vượt phân bổ " + f.ma_don_vi);
      if (!f.den_han && f.o_kiem_dem === "chua_nop_qua_han") loi.push("quá hạn khi chưa đến hạn");
      if (f.trang_thai === "da_phat_hanh" && !f.ts_phat_hanh) loi.push("phát hành thiếu mốc");
      ["ts_nhap_dau", "ts_gui_duyet", "ts_phat_hanh"].forEach((c) => { if (f[c] && f[c] > NOW) loi.push("mốc ở tương lai: " + f.ma_don_vi + " " + f.ma_ky); });
    });
    const s = KEYS.reduce((a, k) => a + o[k], 0);
    if (s !== FACT.length) loi.push("tổng 4 ô " + s + " ≠ " + FACT.length);
    return loi.length ? { ok: false, txt: "Đối soát: " + loi.length + " lỗi — " + loi[0] }
      : { ok: true, txt: "Đối soát ✓ tổng 4 ô = " + FACT.length + "/" + FACT.length + " dòng · mốc thời gian hợp lệ" };
  }

  // ============ 3. HTML + CSS ============
  const W = "td-" + elementId.replace(/[^a-zA-Z0-9_-]/g, "");
  const L2 = W + "-l2";
  const css = `<style>
  #${W}{--ok:#00a870;--late:#f59e0b;--qh:#e0202a;--grey:#8a99ae;--ink:#1E293B;--muted:#5A6B84;--head:#cedef2;--bg:#eef2f7;--card:#fff;--line:#dce5ef;
    box-sizing:border-box;width:100%;height:${height ? height + "px" : "100%"};background:var(--bg);padding:14px 16px;display:flex;flex-direction:column;gap:12px;
    font-family:"Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif;color:var(--ink);overflow:hidden}
  #${W} *{box-sizing:border-box;margin:0;padding:0}
  #${W} .hd{display:flex;align-items:flex-end;justify-content:space-between;gap:12px}
  #${W} .hd h1{font-size:20px;font-weight:700;letter-spacing:.2px}
  #${W} .hd .sub{font-size:12.5px;color:var(--muted);margin-top:3px}
  #${W} .hd .right{text-align:right;font-size:12.5px;color:var(--muted);white-space:nowrap}
  #${W} .chk{display:inline-block;margin-top:5px;padding:3px 10px;border-radius:999px;font-size:12px;font-weight:600;background:#e6f7f0;color:#00794f}
  #${W} .chk.bad{background:#fdecec;color:#b3151d}
  #${W} .bar{display:flex;gap:10px;align-items:center;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px 14px;flex-wrap:wrap}
  #${W} .bar label{font-size:13px;color:var(--muted);font-weight:600}
  #${W} .bar select{font:inherit;font-size:13px;padding:5px 10px;border:1px solid var(--line);border-radius:8px;background:#fff;color:var(--ink);min-width:150px}
  #${W} .seg{display:flex;border:1px solid var(--line);border-radius:8px;overflow:hidden}
  #${W} .seg button{font:inherit;font-size:13px;font-weight:600;padding:6px 16px;border:0;background:#fff;color:var(--muted);cursor:pointer}
  #${W} .seg button.on{background:#1b6fe3;color:#fff}
  #${W} .bar .spacer{flex:1}
  #${W} .bar .note{font-size:12px;color:var(--grey)}
  #${W} .kpis{display:flex;gap:12px}
  #${W} .kpi{flex:1;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px 16px;position:relative;overflow:hidden;cursor:pointer;transition:box-shadow .15s}
  #${W} .kpi:hover{box-shadow:0 2px 10px rgba(27,111,227,.18)}
  #${W} .kpi::before{content:"";position:absolute;left:0;top:0;bottom:0;width:4px;background:var(--grey)}
  #${W} .kpi.k1::before{background:#334155}#${W} .kpi.k2::before{background:var(--ok)}
  #${W} .kpi.k3::before{background:var(--late)}#${W} .kpi.k4::before{background:var(--qh)}#${W} .kpi.k5::before{background:#f59e0b}
  #${W} .kpi .lb{font-size:13px;color:var(--muted);font-weight:600}
  #${W} .kpi .vl{font-size:30px;font-weight:700;line-height:1.15;margin-top:2px}
  #${W} .kpi .ft{font-size:12px;color:var(--grey);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  #${W} .row{display:flex;gap:12px;min-height:0}
  #${W} .row.r1{flex:0 0 32%}#${W} .row.r2{flex:1}
  #${W} .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:10px 14px;display:flex;flex-direction:column;min-height:0;min-width:0}
  #${W} .card h2{font-size:15px;font-weight:700}
  #${W} .card .cs{font-size:12px;color:var(--grey);margin-bottom:4px}
  #${W} .ch{flex:1;min-height:0}
  #${W} .tblwrap{flex:1;overflow:auto;border:1px solid var(--line);border-radius:8px}
  #${W} table{border-collapse:collapse;width:100%;font-size:12.5px}
  #${W} thead th{position:sticky;top:0;background:var(--head);color:var(--ink);text-align:center;font-weight:700;padding:6px 4px;white-space:normal;line-height:1.2;box-shadow:inset 0 4px 0 0 var(--qh)}
  #${W} tbody td{padding:5px 4px;border-top:1px solid var(--line);text-align:left;vertical-align:middle}
  #${W} tbody td.dv{white-space:nowrap;font-weight:600}
  #${W} tbody tr:nth-child(even){background:#f8fbff}
  #${W} tbody tr{cursor:pointer}#${W} tbody tr:hover{background:#eaf2fe}
  #${W} td.num{text-align:center;font-variant-numeric:tabular-nums}
  #${W} .pill,#${L2} .pill{display:inline-block;min-width:30px;text-align:center;padding:2px 8px;border-radius:999px;font-weight:600;font-size:11.5px}
  #${W} .p-ok{background:#e6f7f0;color:#00794f}#${W} .p-late{background:#fef3e2;color:#9a5b00}
  #${W} .p-qh{background:#fdecec;color:#b3151d}#${W} .p-in{background:#e8f1fd;color:#14529f}
  #${W} .ratio{display:flex;align-items:center;gap:8px}
  #${W} .ratio .track{flex:1;height:7px;background:#edf1f6;border-radius:4px;overflow:hidden;min-width:28px}
  #${W} .ratio .fill{height:100%;border-radius:4px}
  #${W} .lg{display:flex;gap:14px;flex-wrap:wrap;font-size:12px;color:var(--muted);margin-top:4px}
  #${W} .lg i{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:5px}
  #${W} .empty{flex:1;display:grid;place-items:center;color:var(--grey);font-size:14px}
  /* ---------- Lớp 2 (gắn vào body để phủ toàn khung) ---------- */
  #${L2}{position:fixed;inset:0;background:rgba(15,23,42,.45);display:none;align-items:center;justify-content:center;z-index:10000;
    font-family:"Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif;color:#1E293B}
  #${L2}.on{display:flex}
  #${L2} *{box-sizing:border-box}
  #${L2} .l2box{width:94vw;max-width:1680px;height:86vh;background:#fff;border-radius:14px;display:flex;flex-direction:column;overflow:hidden;box-shadow:0 18px 50px rgba(15,23,42,.35)}
  #${L2} .l2hd{display:flex;align-items:flex-start;justify-content:space-between;padding:14px 18px;border-bottom:1px solid #dce5ef}
  #${L2} .l2hd h2{font-size:17px;font-weight:700;text-transform:uppercase;letter-spacing:.3px;margin:0}
  #${L2} .l2hd .cs{font-size:12.5px;color:#5A6B84;margin-top:3px}
  #${L2} .l2hd button{font:inherit;font-size:13px;font-weight:600;padding:7px 14px;margin-left:8px;border:1px solid #dce5ef;background:#fff;color:#1E293B;border-radius:8px;cursor:pointer}
  #${L2} .l2hd button.pri{background:#1b6fe3;border-color:#1b6fe3;color:#fff}
  #${L2} .l2wrap{flex:1;overflow:auto}
  #${L2} table{border-collapse:separate;border-spacing:0;font-size:12.5px;width:max-content;min-width:100%}
  #${L2} th{position:sticky;top:0;z-index:3;background:#cedef2;color:#1E293B;text-align:center;font-weight:700;padding:9px 10px;white-space:nowrap;box-shadow:inset 0 4px 0 0 #dce5ef}
  #${L2} td{padding:7px 10px;border-bottom:1px solid #dce5ef;text-align:left;white-space:nowrap;background:#fff}
  #${L2} tr:nth-child(even) td{background:#f8fbff}
  #${L2} .st{position:sticky;z-index:2}
  #${L2} th.st{z-index:4}
  #${L2} .c0{left:0;width:46px;text-align:center}
  #${L2} .c1{left:46px;width:210px;font-weight:600}
  #${L2} .c2{left:256px;width:190px}
  #${L2} .c3{left:446px;width:124px;box-shadow:2px 0 0 0 #dce5ef}
  #${L2} .l2ft{padding:9px 18px;border-top:1px solid #dce5ef;font-size:12.5px;color:#5A6B84;display:flex;justify-content:space-between}
  #${L2} .tag{display:inline-block;padding:2px 9px;border-radius:999px;font-size:11.5px;font-weight:600;color:#fff}
  </style>`;

  const kyNgay = KY.filter((k) => k.loai === "Kỳ ngày"), kyTuan = KY.filter((k) => k.loai === "Kỳ tuần");
  const khoang = (ks) => (ks.length ? ks[0].nhan + "–" + ks[ks.length - 1].nhan + "/" + (ks[0].han ? ks[0].han.getFullYear() : "") : "");
  const ds = doiSoat();
  const html = `<div id="${W}">
    <div class="bar">
      <label>Khối</label>
      <select class="fKhoi"><option value="all">Tất cả</option>${KHOI.map((k) => `<option value="${esc(k)}">${esc(k)}</option>`).join("")}</select>
      <label>Đơn vị</label>
      <select class="fDonVi"></select>
      <label>Loại kỳ</label>
      <div class="seg fKy">${LOAI.map((l) => `<button data-v="${esc(l)}" class="${l === state.loaiKy ? "on" : ""}">${esc(l)}</button>`).join("")}</div>
      <div class="spacer"></div>
      <div class="note">Bấm thẻ chỉ số, cột, ô lưới nhiệt hoặc dòng bảng để mở Lớp 2 — danh sách chi tiết</div>
    </div>
    <div class="kpis">
      <div class="kpi k1" data-o="all"><div class="lb">Lượt phải nộp</div><div class="vl k1v">–</div><div class="ft k1f">&nbsp;</div></div>
      <div class="kpi k2" data-o="nop_dung_han"><div class="lb">Tỉ lệ đúng hạn</div><div class="vl k2v">–</div><div class="ft k2f">&nbsp;</div></div>
      <div class="kpi k3" data-o="nop_qua_han"><div class="lb">Nộp quá hạn</div><div class="vl k3v">–</div><div class="ft k3f">&nbsp;</div></div>
      <div class="kpi k4" data-o="chua_nop_qua_han"><div class="lb">Chưa nộp, quá hạn</div><div class="vl k4v">–</div><div class="ft k4f">&nbsp;</div></div>
      <div class="kpi k5" data-tt="cho_duyet"><div class="lb">Chờ lãnh đạo duyệt</div><div class="vl k5v">–</div><div class="ft k5f">&nbsp;</div></div>
    </div>
    <div class="row r1">
      <div class="card" style="flex:0 0 61.5%">
        <h2>Diễn biến theo kỳ</h2>
        <div class="cs">Mỗi cột là một kỳ báo cáo, chia theo 4 ô kiểm đếm — kỳ không ai nộp vẫn hiển thị đủ cột</div>
        <div class="ch chCot"></div>
      </div>
      <div class="card" style="flex:1">
        <h2>Phễu luồng xử lý</h2>
        <div class="cs">Số lượt rơi rụng qua từng chặng, tính trên toàn bộ lượt phải nộp</div>
        <div class="ch chPhieu"></div>
      </div>
    </div>
    <div class="row r2">
      <div class="card" style="flex:0 0 52%">
        <h2>Lưới nhiệt đơn vị × kỳ</h2>
        <div class="cs">Nhìn một mắt thấy đơn vị nào đứt chuỗi và đứt vào ngày nào</div>
        <div class="ch chHeat"></div>
        <div class="lg">${KEYS.map((k) => `<span><i style="background:${MAU[k]}"></i>${NHAN_O[k]}</span>`).join("")}</div>
      </div>
      <div class="card" style="flex:1">
        <h2>Đơn vị cần đôn đốc</h2>
        <div class="cs bangCs"></div>
        <div class="tblwrap"><table class="tbl">
          <thead></thead><tbody></tbody>
        </table></div>
      </div>
    </div>
  </div>`;

  if (!FACT.length) {
    rootEl.innerHTML = css + `<div id="${W}"><div class="empty">Không có dữ liệu</div></div>`;
    return {};
  }
  rootEl.innerHTML = css + html;
  const wrapEl = document.getElementById(W);
  const $ = (s) => wrapEl.querySelector(s);

  // Lớp 2: một hộp duy nhất gắn vào body (phủ toàn bộ dashboard / iframe)
  let l2 = document.getElementById(L2);
  if (l2) l2.remove();
  l2 = document.createElement("div");
  l2.id = L2;
  l2.innerHTML = `<div class="l2box">
      <div class="l2hd">
        <div><h2 class="l2tt">Danh sách chi tiết</h2><div class="cs l2sub"></div></div>
        <div style="white-space:nowrap"><button class="l2csv">Xuất CSV</button><button class="pri l2close">Đóng</button></div>
      </div>
      <div class="l2wrap"><table>
        <thead><tr>
          <th class="st c0">TT</th><th class="st c1" style="text-align:left">Đơn vị</th>
          <th class="st c2" style="text-align:left">Kỳ báo cáo</th><th class="st c3">Hạn nộp</th>
          <th>Khối</th><th>Trạng thái</th><th>Kết quả so với hạn</th><th>Biểu hoàn tất</th>
          <th>Nhập đầu tiên</th><th>Gửi duyệt</th><th>Phát hành</th><th>Lệch hạn</th><th>Số lần trả lại</th>
        </tr></thead><tbody></tbody>
      </table></div>
      <div class="l2ft"><span class="l2cnt"></span><span>Bản thật: cột Kỳ báo cáo sẽ liên kết mở Lớp 3 — chi tiết từng biểu và dòng thời gian xử lý</span></div>
    </div>`;
  // CSS của Lớp 2 nằm trong <style> của chart → chép sang body cùng hộp
  const st2 = document.createElement("style");
  st2.textContent = css.replace(/^<style>|<\/style>$/g, "");
  l2.appendChild(st2);
  document.body.appendChild(l2);
  const $2 = (s) => l2.querySelector(s);

  // ============ 4. VẼ ============
  const inst = [];
  const mk = (el) => { const c = echarts.init(el, null, { renderer: "canvas" }); inst.push(c); return c; };
  const chCot = mk($(".chCot")), chPhieu = mk($(".chPhieu")), chHeat = mk($(".chHeat"));

  function veKPI(rows) {
    const han = coHan(rows), tt = coTT(rows);
    const denHan = rows.filter((f) => f.den_han);
    const dem = (fn) => rows.filter(fn).length;
    const dung = dem((f) => f.o_kiem_dem === "nop_dung_han"), muon = dem((f) => f.o_kiem_dem === "nop_qua_han");
    const chua = dem((f) => f.o_kiem_dem === "chua_nop_qua_han"), cho = dem((f) => f.trang_thai === "cho_duyet"), tra = dem((f) => f.trang_thai === "bi_tra_lai");
    const nop = dem(daNop), chuaCo = dem(chuaNop);
    const pct = (a, b) => (b ? String(Math.round((1000 * a) / b) / 10).replace(".", ",") + "%" : "—");
    const the = (k, lb, o, v, ft) => {
      const c = $(".kpi." + k);
      c.querySelector(".lb").textContent = lb; c.setAttribute("data-o", o || ""); c.style.cursor = o ? "pointer" : "default";
      c.querySelector(".vl").textContent = v; c.querySelector(".ft").textContent = ft;
    };
    the("k1", "Lượt phải nộp", "all", rows.length, donViHienTai().length + " đơn vị × " + kyHienTai().length + " kỳ" + (han ? " · " + denHan.length + " lượt đã đến hạn" : ""));
    if (han) {
      the("k2", "Tỉ lệ đúng hạn", "nop_dung_han", pct(dung, denHan.length), dung + "/" + denHan.length + " lượt đã đến hạn");
      the("k3", "Nộp quá hạn", "nop_qua_han", muon, "nộp sau giờ hạn");
      the("k4", "Chưa nộp, quá hạn", "chua_nop_qua_han", chua, "hết hạn vẫn chưa phát hành");
    } else {
      the("k2", "Tỉ lệ đã có số liệu", "da_nop", pct(nop, rows.length), nop + "/" + rows.length + " lượt · nguồn chưa có hạn nộp");
      the("k3", "Nộp quá hạn", "", "—", "nguồn chưa có hạn nộp");
      the("k4", "Chưa có số liệu", "chua_nop", chuaCo, "chưa biết hạn nên chưa xếp quá hạn");
    }
    if (tt) the("k5", "Chờ lãnh đạo duyệt", "tt:cho_duyet", cho, tra + " báo cáo bị trả lại, chờ nhập lại");
    else the("k5", "Chờ lãnh đạo duyệt", "", "—", "nguồn chưa có trạng thái duyệt");
  }

  function veCot(rows) {
    const ks = kyHienTai(), idx = {}, data = {};
    ks.forEach((k, i) => { idx[k.ma] = i; });
    KEYS.forEach((k) => { data[k] = ks.map(() => 0); });
    rows.forEach((f) => { if (data[f.o_kiem_dem] && idx[f.ma_ky] != null) data[f.o_kiem_dem][idx[f.ma_ky]]++; });
    chCot.setOption({
      grid: { left: 40, right: 16, top: 40, bottom: 26 },
      legend: { top: 0, left: 0, itemWidth: 12, itemHeight: 12, itemGap: 18, textStyle: { fontSize: 12, color: "#5A6B84" } },
      tooltip: { trigger: "axis", axisPointer: { type: "shadow" } },
      xAxis: { type: "category", data: ks.map((k) => k.nhan), axisLine: { lineStyle: { color: "#dce5ef" } }, axisTick: { show: false }, axisLabel: { color: "#5A6B84", fontSize: 12 } },
      yAxis: { type: "value", minInterval: 1, splitLine: { lineStyle: { color: "#eef2f7" } }, axisLabel: { color: "#8a99ae", fontSize: 11 } },
      series: KEYS.map((k) => ({ name: NHAN_O[k], type: "bar", stack: "t", barMaxWidth: 46, itemStyle: { color: MAU[k] }, emphasis: { focus: "series" },
        label: { show: true, color: "#fff", fontSize: 11, formatter: (p) => (p.value ? p.value : "") }, data: data[k] })),
    }, true);
  }

  function vePhieu(rows) {
    const tong = rows.length;
    const nhap = rows.filter(daNhap).length, gui = rows.filter(daGui).length, ph = rows.filter(daPH).length;
    const data = coTT(rows)
      ? [{ value: tong, name: "Phải nộp", itemStyle: { color: "#334155" } }, { value: nhap, name: "Đã nhập", itemStyle: { color: "#5A6B84" } },
          { value: gui, name: "Đã gửi duyệt", itemStyle: { color: "#1b6fe3" } }, { value: ph, name: "Đã phát hành", itemStyle: { color: "#00a870" } }]
      : [{ value: tong, name: "Phải nộp", itemStyle: { color: "#334155" } }, { value: rows.filter(daNop).length, name: "Đã có số liệu", itemStyle: { color: MAU.da_nop } }];
    chPhieu.setOption({
      tooltip: { trigger: "item", formatter: "{b}: {c} lượt" },
      series: [{ type: "funnel", left: 8, right: 8, top: 10, bottom: 8, minSize: "32%", gap: 3, sort: "none",
        label: { position: "inside", color: "#fff", fontSize: 12.5, fontWeight: 600, formatter: (p) => p.name + ": " + p.value + " (" + (tong ? Math.round((100 * p.value) / tong) : 0) + "%)" },
        itemStyle: { borderWidth: 0 },
        data }],
    }, true);
  }

  function veHeat(rows) {
    const ks = kyHienTai(), us = donViHienTai(), ui = {}, ki = {};
    us.forEach((u, i) => { ui[u.ma] = i; });
    ks.forEach((k, i) => { ki[k.ma] = i; });
    const ma = {}; KEYS.forEach((k, i) => { ma[k] = i + 1; });
    const d = rows.filter((f) => ui[f.ma_don_vi] != null && ki[f.ma_ky] != null).map((f) => [ki[f.ma_ky], ui[f.ma_don_vi], ma[f.o_kiem_dem], f.o_kiem_dem]);
    chHeat.setOption({
      grid: { left: 168, right: us.length > 25 ? 26 : 12, top: 6, bottom: 24 },
      dataZoom: us.length > 25 ? [{ type: "slider", yAxisIndex: 0, right: 4, width: 12, startValue: 0, endValue: 24, showDetail: false, brushSelect: false, zoomLock: true },
        { type: "inside", yAxisIndex: 0, startValue: 0, endValue: 24, zoomOnMouseWheel: false, moveOnMouseWheel: true }] : [],
      tooltip: { formatter: (p) => esc(us[p.value[1]].ten) + "<br/>" + esc(ks[p.value[0]].ten) + "<br/><b>" + NHAN_O[p.value[3]] + "</b>" },
      xAxis: { type: "category", data: ks.map((k) => k.nhan), splitArea: { show: true }, axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: "#5A6B84", fontSize: 11.5 } },
      yAxis: { type: "category", inverse: true, data: us.map((u) => u.ten), splitArea: { show: true }, axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: "#1E293B", fontSize: 11.5 } },
      visualMap: { show: false, type: "piecewise", dimension: 2,
        pieces: KEYS.map((k, i) => ({ value: i + 1, color: MAU[k] })) },
      series: [{ type: "heatmap", data: d, itemStyle: { borderColor: "#fff", borderWidth: 2, borderRadius: 3 }, emphasis: { itemStyle: { borderColor: "#1E293B", borderWidth: 2 } } }],
    }, true);
  }

  function veBang(rows) {
    const han = coHan(rows), m = {};
    rows.forEach((f) => {
      const r = m[f.ma_don_vi] || (m[f.ma_don_vi] = { ten: f.ten, xet: 0, dung: 0, muon: 0, nop: 0, chua: 0, maxStt: 0, cuoi: null, kyCuoi: null });
      if (!han || f.den_han) { // có hạn: chỉ xét kỳ đã đến hạn; chưa có hạn: xét mọi kỳ
        r.xet++;
        if (f.o_kiem_dem === "nop_dung_han") r.dung++; else if (f.o_kiem_dem === "nop_qua_han") r.muon++;
        if (daNop(f)) { r.nop++; if (f.stt_ky > r.maxStt) r.maxStt = f.stt_ky; } else r.chua++;
      }
      if (daNop(f) && f.stt_ky >= (r.kyCuoiStt || 0)) { r.kyCuoiStt = f.stt_ky; r.kyCuoi = f.nhan; }
      if (f.ts_phat_hanh && (!r.cuoi || f.ts_phat_hanh > r.cuoi)) r.cuoi = f.ts_phat_hanh;
    });
    const soKy = kyHienTai().filter((k) => (han ? k.han && NOW > k.han : true)).length;
    const arr = Object.keys(m).map((k) => {
      const r = m[k]; r.ma = k;
      r.tl = r.xet ? Math.round((1000 * (han ? r.dung : r.nop)) / r.xet) / 10 : 0;
      r.lienTiep = Math.max(0, soKy - r.maxStt);
      return r;
    });
    arr.sort((a, b) => b.lienTiep - a.lienTiep || a.tl - b.tl || (a.ten < b.ten ? -1 : 1));
    $(".bangCs").textContent = han ? "Sắp theo số kỳ quá hạn liên tiếp, rồi đến tỉ lệ đúng hạn"
      : "Sắp theo số kỳ chưa có số liệu liên tiếp (tính từ kỳ mới nhất), rồi đến tỉ lệ có số liệu";
    $(".tbl thead").innerHTML = `<tr><th style="width:30px">TT</th><th style="text-align:left">Đơn vị</th>` +
      (han ? `<th>Đúng hạn</th><th>Quá hạn</th><th>Chưa nộp</th><th style="width:18%">Tỉ lệ đúng hạn</th><th>QH l.tiếp</th><th>Nộp gần nhất</th>`
           : `<th>Có số liệu</th><th>Chưa có</th><th style="width:22%">Tỉ lệ có số liệu</th><th>Chưa có l.tiếp</th><th>Kỳ gần nhất có số</th>`) + `</tr>`;
    $(".tbl tbody").innerHTML = arr.map((r, i) => {
      const mau = r.tl >= 80 ? "#00a870" : r.tl >= 60 ? "#f59e0b" : "#e0202a";
      const so = han ? `<td class="num"><span class="pill p-ok">${r.dung}</span></td><td class="num"><span class="pill p-late">${r.muon}</span></td>`
                     : `<td class="num"><span class="pill p-ok">${r.nop}</span></td>`;
      return `<tr data-ma="${esc(r.ma)}" data-ten="${esc(r.ten)}">
        <td class="num">${i + 1}</td>
        <td class="dv" title="${r.xet} kỳ được xét — bấm để mở Lớp 2">${esc(r.ten)}</td>
        ${so}<td class="num"><span class="pill p-qh">${r.chua}</span></td>
        <td><div class="ratio"><div class="track"><div class="fill" style="width:${r.tl}%;background:${mau}"></div></div><b>${String(r.tl).replace(".", ",")}%</b></div></td>
        <td class="num">${r.lienTiep ? `<span class="pill p-qh">${r.lienTiep}</span>` : '<span class="pill p-in">0</span>'}</td>
        <td class="num" style="white-space:nowrap">${r.cuoi ? fmtDT(r.cuoi) : esc(r.kyCuoi || "—")}</td></tr>`;
    }).join("");
  }

  function ve() {
    const rows = loc();
    veKPI(rows); veCot(rows); vePhieu(rows); veHeat(rows); veBang(rows);
  }

  // ============ 5. LỚP 2 ============
  let L2ROWS = [], L2TITLE = "";
  function moL2(fn, tieuDe, phuDe) {
    const rows = loc().filter(fn);
    rows.sort((a, b) => (a.han && b.han ? a.han - b.han : a.stt_ky - b.stt_ky) || (a.tt_dv - b.tt_dv) || (a.ten < b.ten ? -1 : 1));
    L2ROWS = rows; L2TITLE = tieuDe;
    $2(".l2tt").textContent = tieuDe;
    $2(".l2sub").textContent = phuDe + " · " + state.loaiKy + (state.khoi !== "all" ? " · " + state.khoi : "");
    $2(".l2cnt").textContent = rows.length + " dòng — khớp đúng con số vừa bấm ở Lớp 1";
    $2("tbody").innerHTML = rows.map((f, i) => `<tr>
      <td class="st c0">${i + 1}</td><td class="st c1">${esc(f.ten)}</td><td class="st c2">${esc(TEN_KY[f.ma_ky])}</td>
      <td class="st c3" style="text-align:center">${fmtDT(f.han)}</td><td>${esc(f.khoi)}</td>
      <td>${f.trang_thai ? `<span class="tag" style="background:${MAU_TT[f.trang_thai] || "#8a99ae"}">${esc(NHAN_TT[f.trang_thai] || f.trang_thai)}</span>` : "—"}</td>
      <td><span class="tag" style="background:${MAU[f.o_kiem_dem] || "#8a99ae"}">${esc(NHAN_O[f.o_kiem_dem] || f.o_kiem_dem)}</span></td>
      <td style="text-align:center">${nv(f.so_bieu_hoan_tat)}/${nv(f.so_bieu)}</td>
      <td style="text-align:center">${fmtDT(f.ts_nhap_dau)}</td><td style="text-align:center">${fmtDT(f.ts_gui_duyet)}</td>
      <td style="text-align:center">${fmtDT(f.ts_phat_hanh)}</td><td style="text-align:center">${lechHan(f.lech_han_phut)}</td>
      <td style="text-align:center">${f.so_lan_tra_lai == null ? "—" : f.so_lan_tra_lai || ""}</td></tr>`).join("");
    l2.classList.add("on");
  }
  const dongL2 = () => l2.classList.remove("on");
  function xuatCSV() {
    const head = ["TT", "Đơn vị", "Kỳ báo cáo", "Hạn nộp", "Khối", "Trạng thái", "Kết quả so với hạn", "Biểu hoàn tất", "Nhập đầu tiên", "Gửi duyệt", "Phát hành", "Lệch hạn", "Số lần trả lại"];
    const lines = [head.join(";")];
    L2ROWS.forEach((f, i) => lines.push([i + 1, f.ten, TEN_KY[f.ma_ky], fmtDT(f.han), f.khoi, f.trang_thai ? NHAN_TT[f.trang_thai] || f.trang_thai : "—", NHAN_O[f.o_kiem_dem] || f.o_kiem_dem, nv(f.so_bieu_hoan_tat) + "/" + nv(f.so_bieu),
      fmtDT(f.ts_nhap_dau), fmtDT(f.ts_gui_duyet), fmtDT(f.ts_phat_hanh), lechHan(f.lech_han_phut), nv(f.so_lan_tra_lai)].join(";")));
    const blob = new Blob(["﻿" + lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "lop2_" + L2TITLE.normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase().replace(/[^a-z0-9]+/g, "_").slice(0, 50) + ".csv";
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
  }

  // ============ 6. SỰ KIỆN ============
  const selKhoi = $(".fKhoi"), selDv = $(".fDonVi");
  function napDonVi() {
    const dsDv = DONVI.filter((u) => state.khoi === "all" || u.khoi === state.khoi);
    if (state.donVi !== "all" && !dsDv.some((u) => u.ma === state.donVi)) state.donVi = "all";
    selDv.innerHTML = `<option value="all">Tất cả đơn vị (${dsDv.length})</option>` + dsDv.map((u) => `<option value="${esc(u.ma)}">${esc(u.ten)}</option>`).join("");
    selDv.value = state.donVi;
  }
  selKhoi.value = state.khoi;
  napDonVi();
  selKhoi.addEventListener("change", (e) => { state.khoi = e.target.value; state.donVi = "all"; napDonVi(); ve(); });
  selDv.addEventListener("change", (e) => { state.donVi = e.target.value; ve(); });
  wrapEl.querySelectorAll(".fKy button").forEach((b) => b.addEventListener("click", () => {
    wrapEl.querySelectorAll(".fKy button").forEach((x) => x.classList.remove("on"));
    b.classList.add("on"); state.loaiKy = b.getAttribute("data-v"); ve();
  }));
  chCot.on("click", (p) => {
    const o = O_THEO_NHAN[p.seriesName], k = kyHienTai()[p.dataIndex];
    if (o && k) moL2((f) => f.ma_ky === k.ma && f.o_kiem_dem === o, NHAN_O[o] + " — " + k.ten, "Bấm từ biểu đồ Diễn biến theo kỳ");
  });
  chPhieu.on("click", (p) => {
    const fn = { "Phải nộp": () => true, "Đã có số liệu": daNop, "Đã nhập": daNhap, "Đã gửi duyệt": daGui, "Đã phát hành": daPH }[p.name];
    if (fn) moL2(fn, "Phễu — " + p.name, "Bấm từ Phễu luồng xử lý");
  });
  chHeat.on("click", (p) => {
    const k = kyHienTai()[p.value[0]], u = donViHienTai()[p.value[1]];
    if (k && u) moL2((f) => f.ma_ky === k.ma && f.ma_don_vi === u.ma, u.ten + " — " + k.ten, "Bấm từ lưới nhiệt đơn vị × kỳ");
  });
  wrapEl.querySelectorAll(".kpi").forEach((c) => c.addEventListener("click", () => {
    const o = c.getAttribute("data-o") || "", nhan = c.querySelector(".lb").textContent;
    if (!o) return; // chỉ tiêu nguồn chưa có
    if (o.indexOf("tt:") === 0) moL2((f) => f.trang_thai === o.slice(3), nhan, "Bấm từ thẻ chỉ số Lớp 1");
    else if (o === "all") moL2(() => true, "Toàn bộ lượt phải nộp", "Bấm từ thẻ chỉ số Lớp 1");
    else if (o === "da_nop") moL2(daNop, nhan, "Bấm từ thẻ chỉ số Lớp 1");
    else if (o === "chua_nop") moL2(chuaNop, nhan, "Bấm từ thẻ chỉ số Lớp 1");
    else moL2((f) => f.o_kiem_dem === o, NHAN_O[o], "Bấm từ thẻ chỉ số Lớp 1");
  }));
  $(".tbl tbody").addEventListener("click", (e) => {
    const tr = e.target.closest("tr");
    if (!tr || !tr.getAttribute("data-ma")) return;
    const ma = tr.getAttribute("data-ma");
    moL2((f) => f.ma_don_vi === ma, tr.getAttribute("data-ten"), "Bấm từ bảng Đơn vị cần đôn đốc");
  });
  $2(".l2close").addEventListener("click", dongL2);
  l2.addEventListener("click", (e) => { if (e.target === l2) dongL2(); });
  const onKey = (e) => { if (e.key === "Escape") dongL2(); };
  document.addEventListener("keydown", onKey);
  $2(".l2csv").addEventListener("click", xuatCSV);

  ve();

  // ============ 7. RESPONSIVE + CLEANUP ============
  let ro = null;
  if (typeof ResizeObserver !== "undefined") {
    ro = new ResizeObserver(() => inst.forEach((c) => { try { c.resize(); } catch (e) {} }));
    ro.observe(wrapEl);
  }
  rootEl.__tdCleanup = function () {
    if (ro) ro.disconnect();
    document.removeEventListener("keydown", onKey);
    if (l2 && l2.parentNode) l2.parentNode.removeChild(l2);
    inst.forEach((c) => { try { c.dispose(); } catch (e) {} });
  };
  return {};
};
