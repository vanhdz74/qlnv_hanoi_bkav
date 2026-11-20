jsEchartScriptFunc = function (queryData, option, echarts, context) {
  /* ==========================================================================
     TÌNH HÌNH TRIỂN KHAI THÍ ĐIỂM — BCĐ 57 Thành ủy Hà Nội (giao diện v12)
     Chuyển từ theo_doi_thtk_thidiem/ui/dashboard_thidiem_bcd57_v12.html sang 1 chart bkav-chart-advance.
     Dữ liệu: dataset bcd57_thidiem_trienkhai_mau — mỗi dòng = 1 đơn vị × 1 kỳ (17 đơn vị thí điểm cố định trong SQL dataset)
       ma_don_vi, ten_don_vi, tt_don_vi, khoi, ma_ky, loai_ky, nhan_ky, ten_ky, stt_ky, han_nop, den_han,
       ts_nhap_dau, ts_gui_duyet, ts_phat_hanh, ts_tiep_nhan, trang_thai, o_kiem_dem, lech_han_phut, moc_chup.
     "Bây giờ" = moc_chup (giờ NiFi chụp số liệu). Khung 1920×1080 co giãn theo khung chart.
     File sinh bằng superset/build.py – sửa ở chart_v12.tpl.js rồi chạy lại.
     ========================================================================== */
  const elementId = context && context.elementId ? context.elementId : "thidiem-v12";
  const rootEl = document.getElementById(elementId);
  if (!rootEl) return {};
  if (rootEl.__tdCleanup) { try { rootEl.__tdCleanup(); } catch (e) {} }
  const height = context && context.height ? context.height : null;

  // ============ 1. TIỆN ÍCH ============
  const p2 = (n) => (n < 10 ? "0" + n : "" + n);
  const hhmm = (d) => (d ? p2(d.getHours()) + ":" + p2(d.getMinutes()) : "—");
  const dmy = (d) => p2(d.getDate()) + "/" + p2(d.getMonth() + 1) + "/" + d.getFullYear();
  const dm = (d) => p2(d.getDate()) + "/" + p2(d.getMonth() + 1);
  const addMin = (d, m) => new Date(d.getTime() + m * 60000);
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const N = (x) => (x == null || x === "" || isNaN(+x) ? null : +x);
  const dt = (s) => {
    if (s == null || s === "") return null;
    if (typeof s === "number") return new Date(s);
    const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?/.exec(String(s));
    return m ? new Date(+m[1], m[2] - 1, +m[3], +m[4], +m[5], +(m[6] || 0)) : null;
  };

  // ============ 2. DỮ LIỆU ============
  const raw = queryData && Array.isArray(queryData.data) ? queryData.data : [];
  const LOAI = (s) => (/tu[aầ]n/i.test(s || "") ? "tuan" : /ng[aà]y/i.test(s || "") ? "ngay" : null);
  // trạng thái nguồn → luồng v12: đã phát hành tách thành chờ tiếp nhận / đã tiếp nhận theo ts_tiep_nhan
  const FACT = raw.map((r) => {
    const tn = dt(r.ts_tiep_nhan), ph = dt(r.ts_phat_hanh);
    let tt = r.trang_thai || "chua_nhap";
    if (tt === "da_phat_hanh") tt = tn ? "da_tiep_nhan" : "cho_tiep_nhan";
    return {
      ma_don_vi: String(r.ma_don_vi), ten: r.ten_don_vi, khoi: r.khoi, tt_dv: N(r.tt_don_vi) || 0,
      ma_ky: String(r.ma_ky), loai_ky: LOAI(r.loai_ky), nhan_ky: r.nhan_ky, ten_ky: r.ten_ky, stt_ky: N(r.stt_ky) || 0,
      han: dt(r.han_nop), den_han: N(r.den_han) === 1,
      ts_nhap: dt(r.ts_nhap_dau), ts_gui: dt(r.ts_gui_duyet), ts_ph: ph, ts_tn: tn,
      trang_thai: tt, o_kiem_dem: r.o_kiem_dem, lech: N(r.lech_han_phut), moc: dt(r.moc_chup),
    };
  }).filter((f) => f.loai_ky && f.han);
  const NOW = FACT.reduce((a, f) => (f.moc && (!a || f.moc > a) ? f.moc : a), null) || new Date();

  const DONVI = [], seenDv = {}, kyMap = {};
  FACT.forEach((f) => {
    if (!seenDv[f.ma_don_vi]) { seenDv[f.ma_don_vi] = 1; DONVI.push({ ma: f.ma_don_vi, ten: f.ten, khoi: f.khoi, tt: f.tt_dv }); }
    const k = kyMap[f.ma_ky] || (kyMap[f.ma_ky] = { ma: f.ma_ky, loai: f.loai_ky, nhan: f.nhan_ky, ten: f.ten_ky, han: f.han, stt: f.stt_ky });
    if (f.han < k.han) k.han = f.han; // hạn của kỳ = hạn sớm nhất trong các đơn vị
  });
  DONVI.sort((a, b) => a.tt - b.tt || (a.ten < b.ten ? -1 : 1));
  const KY = Object.keys(kyMap).map((m) => kyMap[m]).sort((a, b) => a.han - b.han || a.stt - b.stt);
  const KHOI = Array.from(new Set(DONVI.map((u) => u.khoi)));

  const MAU = { nop_dung_han: "#00a870", nop_qua_han: "#f59e0b", chua_nop_con_han: "#1b6fe3", chua_nop_qua_han: "#e0202a", da_nop: "#0e9384" };
  const NHAN_O = { nop_dung_han: "Đã nộp đúng hạn", nop_qua_han: "Đã nộp quá hạn", chua_nop_con_han: "Chưa nộp còn hạn", chua_nop_qua_han: "Chưa nộp quá hạn", da_nop: "Đã nộp (nạp lùi)" };
  const O_THEO_NHAN = {}; Object.keys(NHAN_O).forEach((k) => { O_THEO_NHAN[NHAN_O[k]] = k; });
  const AI = { chua_nhap: "Cán bộ lập — chưa mở", dang_nhap: "Cán bộ lập — đang nhập", cho_duyet: "Lãnh đạo đơn vị", bi_tra_lai: "Cán bộ lập — sửa lại",
    cho_tiep_nhan: "Cơ quan nhận", da_tiep_nhan: "Đã xong, số liệu vào kho" };
  const NHAN_TT = { chua_nhap: "Chưa nhập", dang_nhap: "Đang nhập", cho_duyet: "Chờ lãnh đạo duyệt", bi_tra_lai: "Bị trả lại", cho_tiep_nhan: "Chờ tiếp nhận", da_tiep_nhan: "Đã tiếp nhận" };
  const MAU_TT = { chua_nhap: "#8a99ae", dang_nhap: "#64748b", cho_duyet: "#f59e0b", bi_tra_lai: "#825ee4", cho_tiep_nhan: "#1b6fe3", da_tiep_nhan: "#00a870" };
  const UU_TIEN = { chua_nop_qua_han: 0, chua_nop_con_han: 1, nop_qua_han: 2, da_nop: 3, nop_dung_han: 3 };
  const CUA_SO = { ngay: 5, tuan: 4 };
  const SVG = (d) => '<svg viewBox="0 0 24 24" fill="currentColor">' + d + "</svg>";
  const ICON = {
    tong: SVG('<path d="M14 2H7a2.5 2.5 0 0 0-2.5 2.5v15A2.5 2.5 0 0 0 7 22h10a2.5 2.5 0 0 0 2.5-2.5V7.5L14 2z" opacity=".95"/><path d="M14 2l5.5 5.5H15A1 1 0 0 1 14 6.5V2z" opacity=".55"/><rect x="8" y="12" width="8" height="1.7" rx=".85" fill="#fff" opacity=".85"/><rect x="8" y="15.6" width="5.4" height="1.7" rx=".85" fill="#fff" opacity=".85"/>'),
    dung: SVG('<path d="M12 1.8a10.2 10.2 0 1 0 0 20.4 10.2 10.2 0 0 0 0-20.4zm5.3 7.6l-6.2 6.4a1.15 1.15 0 0 1-1.66 0l-2.75-2.82a1.15 1.15 0 1 1 1.65-1.6l1.930 1.98 5.38-5.56a1.15 1.15 0 1 1 1.65 1.6z"/>'),
    muon: SVG('<path d="M12 1.8a10.2 10.2 0 1 0 0 20.4 10.2 10.2 0 0 0 0-20.4zm1.05 10.8l3.3 1.95a1.05 1.05 0 1 1-1.06 1.8l-3.8-2.25a1.05 1.05 0 0 1-.52-.9V6.6a1.05 1.05 0 1 1 2.1 0z"/>'),
    conhan: SVG('<path d="M6.2 2h11.6a1.05 1.05 0 1 1 0 2.1h-.9v1.55c0 2-1.05 3.85-2.78 4.88L13.3 12l.82.5a5.650 5.65 0 0 1 2.78 4.87v1.53h.9a1.05 1.05 0 1 1 0 2.1H6.2a1.05 1.05 0 1 1 0-2.1h.9v-1.53c0-2 1.05-3.85 2.78-4.87l.82-.5-.82-.47A5.65 5.65 0 0 1 7.1 5.65V4.1h-.9A1.05 1.05 0 0 1 6.2 2zm2.98 2.1v1.55c0 .52.1 1.02.3 1.48h5.04c.2-.46.3-.96.3-1.48V4.1H9.18z"/>'),
    quahan: SVG('<path d="M13.74 3.3l8.05 13.93a2.01 2.01 0 0 1-1.74 3.02H3.95a2.01 2.01 0 0 1-1.74-3.020L10.26 3.3a2.01 2.01 0 0 1 3.48 0zM12 7.9a1.15 1.15 0 0 0-1.15 1.24l.32 4.1a.84.84 0 0 0 1.66 0l.32-4.1A1.15 1.15 0 0 0 12 7.9zm0 8.2a1.26 1.26 0 1 0 0 2.52 1.26 1.26 0 0 0 0-2.52z"/>'),
  };

  // trạng thái giữ qua các lần Superset vẽ lại
  const state = rootEl.__tdState || (rootEl.__tdState = { khoi: "all", donVi: "all", loaiKy: "ngay", tab: "ky", tuKy: null, denKy: null, chiXau: false });
  if (!KY.some((k) => k.loai === state.loaiKy)) state.loaiKy = KY.length ? KY[0].loai : "ngay";

  const donViLoc = () => DONVI.filter((u) => (state.khoi === "all" || u.khoi === state.khoi) && (state.donVi === "all" || u.ma === state.donVi));
  const trongLoc = (ma) => donViLoc().some((u) => u.ma === ma);
  const rowsKy = (maKy) => FACT.filter((f) => f.ma_ky === maKy && trongLoc(f.ma_don_vi));
  const nhanKy = (k) => (k ? String(k.ten || k.nhan).replace(/^Báo cáo /, "Kỳ ") : "—");
  const tenKy = (maKy) => (kyMap[maKy] ? kyMap[maKy].ten : maKy);
  const daNop = (f) => f.trang_thai === "cho_tiep_nhan" || f.trang_thai === "da_tiep_nhan";

  // kỳ tuần: từ 00:00 thứ 7 đến hết thứ 6 (ngày hạn), theo lịch kỳ của nguồn
  const tuanTu = (k) => new Date(k.han.getFullYear(), k.han.getMonth(), k.han.getDate() - 6);
  const tuanDen = (k) => new Date(k.han.getFullYear(), k.han.getMonth(), k.han.getDate(), 23, 59, 59);
  function kyHienTai(loai) {
    const ds = KY.filter((k) => k.loai === loai);
    if (!ds.length) return null;
    // Kỳ tuần: kỳ đang chứa hôm nay (thứ 7 → hết thứ 6), kể cả sau giờ hạn của thứ 6
    if (loai === "tuan") {
      const dang = ds.filter((k) => tuanTu(k) <= NOW && NOW <= tuanDen(k));
      if (dang.length) return dang[0];
    }
    // Kỳ ngày: luôn là kỳ của chính hôm nay, kể cả sau giờ hạn
    if (loai === "ngay") {
      const hn = ds.filter((k) => k.han.getFullYear() === NOW.getFullYear() && k.han.getDate() === NOW.getDate() && k.han.getMonth() === NOW.getMonth());
      if (hn.length) return hn[0];
    }
    const mo = ds.filter((k) => k.han > NOW);
    if (mo.length) return mo[0];
    return ds[ds.length - 1];
  }
  const KY_NGAY = kyHienTai("ngay"), KY_TUAN = kyHienTai("tuan");
  const kyDangChon = () => (state.loaiKy === "ngay" ? KY_NGAY : KY_TUAN);
  const KY_NGAY_TRUOC = KY_NGAY ? KY.filter((k) => k.loai === "ngay" && k.han < KY_NGAY.han).slice(-5) : [];
  function KY_TRUOC() {
    const k = kyDangChon();
    return k ? KY.filter((x) => x.loai === k.loai && x.han < k.han).slice(-CUA_SO[k.loai]) : [];
  }

  // ============ 3. HTML + CSS ============
  const W = "tdv-" + elementId.replace(/[^a-zA-Z0-9_-]/g, "");
  const L2 = W + "-l2";
  const css = `<style>
  #${W},#${L2}{--ok:#00a870;--late:#f59e0b;--inhan:#1b6fe3;--qh:#e0202a;--tra:#825ee4;--grey:#8695a8;--ink:#0f172a;--muted:#475569;--head:#cedef2;--bg:#eef2f7;--card:#fff;--line:#dce5ef;
    font-family:"Segoe UI","Inter","Roboto","Helvetica Neue",Arial,sans-serif;font-size:14px;line-height:1.45;color:var(--ink);-webkit-font-smoothing:antialiased}
  #${W}{position:relative;width:100%;height:${height ? height + "px" : "100%"};overflow:hidden;background:var(--bg)}
  #${W} *,#${L2} *{box-sizing:border-box;margin:0;padding:0}
  #${W} .stage{position:absolute;top:0;left:0;width:1920px;height:1080px;padding:6px 10px 14px;transform-origin:top left;display:flex;flex-direction:column;gap:9px}
  #${W} .chk{display:inline-block;padding:4px 11px;border-radius:999px;font-size:12.5px;font-weight:700;background:#e6f7f0;color:#00794f;cursor:default}
  #${W} .chk.bad{background:#fdecec;color:#b3151d}
  #${W} .tabs{display:flex;gap:4px;border-bottom:2px solid var(--line);align-items:center}
  #${W} .tabs .tabinfo{margin-left:auto;display:flex;align-items:center;gap:12px;font-size:13px;color:var(--muted);padding:0 44px 4px 0}
  #${W} .tabs button{font:inherit;font-size:14.5px;font-weight:700;padding:5px 20px;border:0;background:transparent;color:var(--muted);cursor:pointer;border-bottom:3px solid transparent;margin-bottom:-2px}
  #${W} .tabs button.on{color:#1b6fe3;border-bottom-color:#1b6fe3}
  #${W} .bar{display:flex;gap:10px;align-items:center;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:5px 12px}
  #${W} .bar label{font-size:13.5px;color:var(--muted);font-weight:600}
  #${W} .bar select{font:inherit;font-size:13.5px;padding:4px 8px;border:1px solid var(--line);border-radius:7px;background:#fff;color:var(--ink);min-width:170px}
  #${W} .bar .spacer{flex:1}
  #${W} .kyrow{display:flex;gap:10px;align-items:stretch}
  #${W} .bar .han{font-size:12.5px;color:var(--muted);text-align:right;line-height:1.3}
  #${W} .bar .han b{display:block;font-size:13.5px}
  #${W} .bar .han b.red{color:var(--qh)} #${W} .bar .han b.blue{color:var(--inhan)}
  #${W} .kpi{flex:1;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:11px 18px 13px;display:flex;align-items:center;gap:13px;position:relative;overflow:hidden;
     box-shadow:0 1px 2px rgba(15,23,42,.05);transition:box-shadow .18s,transform .18s;cursor:pointer}
  #${W} .kpi:hover{box-shadow:0 8px 20px rgba(15,23,42,.10);transform:translateY(-1px)}
  #${W} .kpi .ic{width:44px;height:44px;border-radius:13px;flex:0 0 44px;display:flex;align-items:center;justify-content:center;
     background:linear-gradient(135deg,var(--c2) 0%,var(--c) 100%);color:#fff;box-shadow:0 4px 10px var(--c-sh),inset 0 1px 0 rgba(255,255,255,.28)}
  #${W} .kpi .ic svg{width:23px;height:23px;filter:drop-shadow(0 1px 1px rgba(0,0,0,.18))}
  #${W} .kpi .lb{font-size:13.5px;color:var(--muted);font-weight:600;letter-spacing:.1px}
  #${W} .kpi .vl{font-size:32px;font-weight:700;line-height:1.18;display:flex;align-items:center;gap:9px;color:var(--ink)}
  #${W} .kpi .pc{font-size:13.5px;font-weight:700;color:var(--c);background:var(--c-bg);padding:3px 10px;border-radius:999px}
  #${W} .kpi .trk{position:absolute;left:0;right:0;bottom:0;height:5px;background:#f1f5f9}
  #${W} .kpi .trk i{display:block;height:100%;background:var(--c);border-radius:0 3px 3px 0;transition:width .45s ease}
  #${W} .kpi.tong{--c:#334155;--c2:#64748b;--c-bg:#e8edf4;--c-sh:rgba(51,65,85,.30)}
  #${W} .kpi.dung{--c:#00a870;--c2:#34d39b;--c-bg:#e2f7ef;--c-sh:rgba(0,168,112,.32)}
  #${W} .kpi.muon{--c:#f59e0b;--c2:#fcd34d;--c-bg:#fef3e2;--c-sh:rgba(245,158,11,.34)}
  #${W} .kpi.conhan{--c:#1b6fe3;--c2:#60a5fa;--c-bg:#e7f0fd;--c-sh:rgba(27,111,227,.32)}
  #${W} .kpi.quahan{--c:#e0202a;--c2:#f87171;--c-bg:#fdeaea;--c-sh:rgba(224,32,42,.36)}
  #${W} .kpi.alert .ic{animation:tdvNhip 1.5s ease-in-out infinite}
  #${W} .kpi.alert .vl{color:var(--c)}
  #${W} .kpi.alert::after{content:"";position:absolute;inset:0;border-radius:14px;border:2px solid var(--c);opacity:0;animation:tdvVien 1.5s ease-in-out infinite;pointer-events:none}
  @keyframes tdvNhip{0%,100%{transform:scale(1)}50%{transform:scale(1.12)}}
  @keyframes tdvVien{0%,100%{opacity:0}50%{opacity:.5}}
  #${W} .row{display:flex;gap:10px;flex:1;min-height:0}
  #${W} .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:11px 15px;display:flex;flex-direction:column;min-height:0}
  #${W} .card h2{font-size:16px;font-weight:700;display:flex;justify-content:space-between;align-items:center}
  #${W} .card .cs{font-size:12.5px;color:var(--grey);margin:2px 0 6px}
  #${W} .ch{flex:1;min-height:0}
  #${W} .seg{display:flex;border:1px solid var(--line);border-radius:7px;overflow:hidden}
  #${W} .seg button{font:inherit;font-size:13.5px;font-weight:600;padding:4px 14px;border:0;background:#fff;color:var(--muted);cursor:pointer}
  #${W} .seg button.on{background:#1b6fe3;color:#fff}
  #${W} .sw{font-size:13.5px;color:var(--muted);font-weight:600;display:flex;align-items:center;gap:6px;cursor:pointer}
  #${W} .tblwrap{flex:1;overflow:auto;border:1px solid var(--line);border-radius:8px}
  #${W} table{border-collapse:separate;border-spacing:0;width:100%;font-size:13.5px}
  #${W} thead th{position:sticky;background:var(--head);color:var(--ink);text-align:center;font-weight:700;padding:8px 8px;white-space:nowrap;z-index:2}
  #${W} thead tr:first-child th{top:0;box-shadow:inset 0 4px 0 0 var(--inhan)}
  #${W} thead tr:last-child th{top:30px}
  #${W} thead th.gr{border-left:1px solid #b9cde6}
  #${W} tbody td{padding:5px 8px;border-bottom:1px solid var(--line);text-align:center;white-space:nowrap}
  #${W} tbody td.dv{text-align:left;font-weight:600}
  #${W} tbody tr:nth-child(even) td{background:#f8fbff}
  #${W} tbody tr.hot td{background:#fff6f6}
  #${W} .chip,#${L2} .chip{display:inline-block;min-width:132px;padding:4px 10px;border-radius:999px;font-size:12.5px;font-weight:600;color:#fff}
  #${W} .num0,#${L2} .num0{color:#c3cbd6}
  #${W} .pill{display:inline-block;min-width:28px;padding:3px 10px;border-radius:999px;font-size:12.5px;font-weight:700}
  #${W} .p-qh{background:#fdecec;color:#b3151d} #${W} .p-late{background:#fef3e2;color:#9a5b00} #${W} .p-ok{background:#eef2f7;color:#5A6B84}
  #${W} .who,#${L2} .who{font-size:13px;color:var(--muted)}
  #${W} .lk{cursor:pointer;text-decoration:none;border-bottom:1px dashed currentColor}
  #${W} .pill.lk:hover{filter:brightness(.94)}
  #${W} .lg{display:flex;gap:16px;flex-wrap:wrap;font-size:12.5px;color:var(--muted);margin-top:6px}
  #${W} .lg i{display:inline-block;width:11px;height:11px;border-radius:3px;margin-right:6px}
  #${W} .empty{flex:1;display:flex;align-items:center;justify-content:center;color:var(--grey);font-size:15px}
  #${L2}{position:fixed;inset:0;background:rgba(15,23,42,.45);display:none;align-items:center;justify-content:center;z-index:2000}
  #${L2}.on{display:flex}
  #${L2} .l2box{width:94vw;max-width:1640px;height:84vh;background:#fff;border-radius:14px;display:flex;flex-direction:column;overflow:hidden;box-shadow:0 18px 50px rgba(15,23,42,.35)}
  #${L2} .l2hd{display:flex;align-items:flex-start;justify-content:space-between;padding:14px 18px;border-bottom:1px solid var(--line)}
  #${L2} .l2hd h3{font-size:17px;font-weight:700;text-transform:uppercase;letter-spacing:.3px}
  #${L2} .l2hd .cs{font-size:12.5px;color:var(--muted);margin-top:3px}
  #${L2} .l2hd button{font:inherit;font-size:13px;font-weight:600;padding:7px 15px;border:0;background:#1b6fe3;color:#fff;border-radius:8px;cursor:pointer}
  #${L2} .l2wrap{flex:1;overflow:auto}
  #${L2} table{border-collapse:separate;border-spacing:0;font-size:12.5px;width:100%}
  #${L2} th{position:sticky;top:0;z-index:3;background:var(--head);color:var(--ink);text-align:center;font-weight:700;padding:9px 10px;white-space:nowrap;box-shadow:inset 0 4px 0 0 var(--line)}
  #${L2} td{padding:8px 10px;border-bottom:1px solid var(--line);text-align:center;white-space:nowrap;background:#fff}
  #${L2} td.l{text-align:left;font-weight:600}
  #${L2} tr:nth-child(even) td{background:#f8fbff}
  #${L2} .l2ft{padding:9px 18px;border-top:1px solid var(--line);font-size:12.5px;color:var(--muted)}
  </style>`;

  const optKhoi = KHOI.map((k) => `<option value="${esc(k)}">${esc(k)}</option>`).join("");
  const html = `
  <div class="stage">
    <div class="tabs">
      <button data-tab="ky">Kỳ hiện tại</button>
      <button data-tab="tq">Tổng quan</button>
      <div class="tabinfo"><span>Cập nhật lúc: <b class="nowtxt"></b></span><span class="chk" style="display:none"></span></div>
    </div>
    <div class="bar">
      <label>Loại kỳ</label>
      <div class="seg fKy"><button data-v="ngay">Kỳ ngày</button><button data-v="tuan">Kỳ tuần</button></div>
      <span class="fKhoang" style="display:none;align-items:center;gap:8px">
        <label>Từ</label><select class="fTu" style="min-width:150px"></select>
        <label>đến</label><select class="fDen" style="min-width:150px"></select>
      </span>
      <label>Khối</label>
      <select class="fKhoi"><option value="all">Tất cả</option>${optKhoi}</select>
      <label>Đơn vị</label>
      <select class="fDonVi"></select>
      <div class="spacer"></div>
      <div class="han"><span class="hanTxt"></span><b class="hanCd"></b></div>
    </div>

    <div class="tabKy" style="display:flex;flex-direction:column;gap:10px;flex:1;min-height:0">
      <div class="kyrow kpi1"></div>
      <div class="row">
        <div class="card" style="flex:0 0 1178px">
          <h2>Tình hình nộp theo đơn vị
            <label class="sw"><input type="checkbox" class="onlyBad"> Chỉ hiện đơn vị cần đôn đốc</label></h2>
          <div class="cs">Sắp theo mức độ cần xử lý: chưa nộp quá hạn → chưa nộp còn hạn → đã nộp quá hạn → đã nộp đúng hạn</div>
          <div class="tblwrap"><table class="tbl">
            <thead>
              <tr>
                <th rowspan="2" style="width:42px">TT</th>
                <th rowspan="2" style="width:300px;text-align:left">Đơn vị</th>
                <th rowspan="2" class="gr thKy" style="width:186px">Kỳ hiện tại</th>
                <th rowspan="2" class="gr thGio" style="width:132px">Thời điểm nộp</th>
                <th rowspan="2" class="gr" style="width:214px">Vị trí đang giữ</th>
                <th colspan="2" class="gr thPrev">5 kỳ gần nhất</th>
              </tr>
              <tr><th class="gr" style="width:122px">Đã nộp quá hạn</th><th style="width:130px">Chưa nộp quá hạn</th></tr>
            </thead>
            <tbody></tbody>
          </table></div>
        </div>
        <div style="flex:1;display:flex;flex-direction:column;gap:12px;min-height:0">
          <div class="card" style="flex:0 0 336px">
            <h2 class="hdPhieu">Tình hình xử lý theo luồng</h2>
            <div class="cs">Đếm lũy tiến — mỗi bậc gồm cả những báo cáo đã đi xa hơn</div>
            <div class="ch chPhieu"></div>
          </div>
          <div class="card" style="flex:1">
            <h2 class="hdGio">Tiến độ nộp theo giờ</h2>
            <div class="cs csGio"></div>
            <div class="ch chGio"></div>
          </div>
        </div>
      </div>
    </div>

    <div class="tabTq" style="display:none;flex-direction:column;gap:10px;flex:1;min-height:0">
      <div class="kyrow kpi2"></div>
      <div class="row">
        <div class="card" style="flex:0 0 1178px">
          <h2>Kết quả nộp theo đơn vị</h2>
          <div class="cs">Mỗi ô là một kỳ của một đơn vị — hàng ngang cho biết đơn vị nào đứt chuỗi, cột dọc cho biết kỳ nào cả loạt chậm</div>
          <div class="ch chHeat"></div>
          <div class="lg">
            <span><i style="background:#00a870"></i>Đã nộp đúng hạn</span>
            <span><i style="background:#f59e0b"></i>Đã nộp quá hạn</span>
            <span><i style="background:#1b6fe3"></i>Chưa nộp còn hạn</span>
            <span><i style="background:#e0202a"></i>Chưa nộp quá hạn</span>
            <span style="color:#8a99ae">Bấm vào ô để xem chi tiết</span>
          </div>
        </div>
        <div style="flex:1;display:flex;flex-direction:column;gap:10px;min-height:0">
          <div class="card" style="flex:0 0 336px">
            <h2>Tình hình xử lý theo luồng</h2>
            <div class="cs">Đếm lũy tiến trên các kỳ đã chọn — khoảng hụt giữa hai bậc là phần việc đang nằm lại ở khâu đó</div>
            <div class="ch chPhieu2"></div>
            <div class="lg lgPhieu"></div>
          </div>
          <div class="card" style="flex:1">
            <h2>Kết quả nộp theo từng kỳ</h2>
            <div class="cs">Cột chia theo ô kiểm đếm, đường đen là tỉ lệ đúng hạn — kỳ đánh dấu * còn hạn nên chưa chốt tỉ lệ</div>
            <div class="ch chCot"></div>
          </div>
        </div>
      </div>
    </div>
  </div>`;
  rootEl.innerHTML = css + `<div id="${W}">${html}</div>`;
  const wrapEl = document.getElementById(W);
  const stage = wrapEl.querySelector(".stage");
  const $ = (s) => stage.querySelector(s);

  // Lớp 2 gắn vào body: position:fixed không chạy đúng bên trong khung đang transform:scale
  const old = document.getElementById(L2);
  if (old && old.parentNode) old.parentNode.removeChild(old);
  const l2 = document.createElement("div");
  l2.id = L2;
  l2.innerHTML = `<div class="l2box">
    <div class="l2hd"><div><h3 class="l2tt"></h3><div class="cs l2sub"></div></div><button class="l2close">Đóng</button></div>
    <div class="l2wrap"><table>
      <thead><tr>
        <th style="width:46px">TT</th><th style="text-align:left">Đơn vị</th><th style="text-align:left">Kỳ báo cáo</th>
        <th style="width:124px">Hạn nộp</th><th style="width:168px">Trạng thái</th><th style="width:168px">Kết quả so với hạn</th>
        <th style="width:112px">Nhập đầu tiên</th><th style="width:112px">Gửi duyệt</th><th style="width:112px">Phát hành</th>
        <th style="width:112px">Tiếp nhận</th><th style="width:96px">Lệch hạn</th><th style="width:200px">Vị trí đang giữ</th>
      </tr></thead><tbody></tbody>
    </table></div>
    <div class="l2ft l2cnt"></div></div>`;
  document.body.appendChild(l2);
  const $2 = (s) => l2.querySelector(s);

  if (!FACT.length) {
    stage.innerHTML = '<div class="empty">Không có dữ liệu kỳ ngày / kỳ tuần</div>';
    rootEl.__tdCleanup = function () { if (l2.parentNode) l2.parentNode.removeChild(l2); };
    return {};
  }

  const inst = [];
  const mk = (s) => { const c = echarts.init($(s)); inst.push(c); return c; };
  const chPhieu = mk(".chPhieu"), chGio = mk(".chGio"), chHeat = mk(".chHeat"), chCot = mk(".chCot"), chPhieu2 = mk(".chPhieu2");

  // ============ 4. ĐỐI SOÁT ============
  function phieu(rows) {
    return [
      { n: "Tổng cần phải nộp", v: rows.length, ai: "" },
      { n: "Cán bộ đã mở nhập", v: rows.filter((f) => f.ts_nhap).length, ai: "cán bộ lập" },
      { n: "Đã chuyển lãnh đạo duyệt", v: rows.filter((f) => f.ts_gui).length, ai: "cán bộ lập" },
      { n: "Lãnh đạo đã duyệt, phát hành", v: rows.filter((f) => f.ts_ph).length, ai: "lãnh đạo đơn vị" },
      { n: "Cơ quan nhận đã tiếp nhận", v: rows.filter((f) => f.ts_tn).length, ai: "cơ quan nhận" },
    ];
  }
  function doiSoat() {
    const loi = [];
    [KY_NGAY, KY_TUAN].forEach((k) => {
      if (!k) return;
      const rows = FACT.filter((f) => f.ma_ky === k.ma);
      if (rows.length !== DONVI.length) loi.push(nhanKy(k) + ": " + rows.length + " ≠ " + DONVI.length + " dòng");
      const s = rows.filter((f) => f.o_kiem_dem in NHAN_O).length;
      if (s !== rows.length) loi.push(nhanKy(k) + ": tổng các ô ≠ số dòng");
    });
    FACT.forEach((f) => {
      [f.ts_nhap, f.ts_gui, f.ts_ph, f.ts_tn].forEach((t) => { if (t && t > addMin(NOW, 10)) loi.push("mốc ở tương lai " + f.ten + " " + f.ma_ky); });
      if (f.ts_ph && f.ts_gui && f.ts_ph < f.ts_gui) loi.push("mốc nghịch " + f.ten + " " + f.ma_ky);
      if (!f.den_han && f.o_kiem_dem === "chua_nop_qua_han") loi.push("quá hạn khi chưa tới hạn " + f.ten);
    });
    const el = $(".chk");
    if (loi.length) { el.className = "chk bad"; el.style.display = "inline-block"; el.textContent = "Số liệu lệch: " + loi.length + " lỗi"; el.title = loi.slice(0, 8).join("\n"); }
    else el.style.display = "none";
  }

  // ============ 5. KỲ HIỆN TẠI ============
  function conLai(han) {
    const m = Math.round((han - NOW) / 60000), qua = m < 0, a = Math.abs(m);
    const d = Math.floor(a / 1440), h = Math.floor((a % 1440) / 60), p = a % 60;
    const s = (d ? d + " ngày " : "") + (h ? h + " giờ " : "") + (d ? "" : p + " phút");
    return { qua, txt: (qua ? "Đã quá hạn " : "Còn ") + s.trim() };
  }
  function kpiHtml(rows) {
    const n = rows.length;
    const d = (o) => rows.filter((f) => f.o_kiem_dem === o).length;
    const pc = (x) => (n ? Math.round((100 * x) / n) : 0);
    const nl = d("da_nop");
    const o = [["tong", "Tổng cần nộp", n, null], ["dung", "Đã nộp đúng hạn" + (nl ? " / nạp lùi" : ""), d("nop_dung_han") + nl, pc(d("nop_dung_han") + nl)],
      ["muon", "Đã nộp quá hạn", d("nop_qua_han"), pc(d("nop_qua_han"))], ["conhan", "Chưa nộp còn hạn", d("chua_nop_con_han"), pc(d("chua_nop_con_han"))],
      ["quahan", "Chưa nộp quá hạn", d("chua_nop_qua_han"), pc(d("chua_nop_qua_han"))]];
    return o.map((c) => {
      const canhBao = c[0] === "quahan" && c[2] > 0;
      return `<div class="kpi ${c[0]}${canhBao ? " alert" : ""}" data-k="${c[0]}"><div class="ic">${ICON[c[0]]}</div>` +
        `<div><div class="lb">${c[1]}</div><div class="vl">${c[2]}${c[3] === null ? "" : '<span class="pc">' + c[3] + "%</span>"}</div></div>` +
        `<div class="trk"><i style="width:${c[3] === null ? 100 : c[3]}%"></i></div></div>`;
    }).join("");
  }
  function veKPI() {
    const k = kyDangChon();
    if (!k) { $(".kpi1").innerHTML = ""; $(".hanTxt").textContent = "Chưa có kỳ"; $(".hanCd").textContent = ""; return; }
    const cl = conLai(k.han);
    $(".hanTxt").textContent = nhanKy(k) + " · hạn nộp " + hhmm(k.han) + " ngày " + dmy(k.han);
    const cd = $(".hanCd"); cd.textContent = cl.txt; cd.className = "hanCd " + (cl.qua ? "red" : "blue");
    $(".kpi1").innerHTML = kpiHtml(rowsKy(k.ma));
  }

  function veBang() {
    const laNgay = state.loaiKy === "ngay";
    const k = kyDangChon();
    $(".thKy").innerHTML = esc(nhanKy(k));
    $(".thGio").innerHTML = laNgay ? "Giờ nộp" : "Thời điểm nộp";
    $(".thPrev").textContent = CUA_SO[state.loaiKy] + (laNgay ? " ngày" : " tuần") + " gần nhất";
    const truoc = KY_TRUOC().map((x) => x.ma);
    const tim = (ma, ky) => (ky ? FACT.filter((f) => f.ma_don_vi === ma && f.ma_ky === ky.ma)[0] : null);
    let ds = donViLoc().map((u) => {
      const tr = FACT.filter((f) => f.ma_don_vi === u.ma && truoc.indexOf(f.ma_ky) >= 0);
      return { u, n: tim(u.ma, KY_NGAY), t: tim(u.ma, KY_TUAN),
        muon: tr.filter((f) => f.o_kiem_dem === "nop_qua_han").length, bo: tr.filter((f) => f.o_kiem_dem === "chua_nop_qua_han").length };
    });
    const chinh = (r) => (laNgay ? r.n : r.t), phu = (r) => (laNgay ? r.t : r.n);
    const ut = (f) => (f ? UU_TIEN[f.o_kiem_dem] : 9);
    ds.sort((a, b) => ut(chinh(a)) - ut(chinh(b)) || ut(phu(a)) - ut(phu(b)) || b.bo + b.muon - (a.bo + a.muon) || a.u.tt - b.u.tt);
    if (state.chiXau) ds = ds.filter((r) => chinh(r) && chinh(r).o_kiem_dem !== "nop_dung_han" && chinh(r).o_kiem_dem !== "da_nop");
    $(".tbl tbody").innerHTML = ds.map((r, i) => {
      const c = chinh(r);
      if (!c) return `<tr><td>${i + 1}</td><td class="dv">${esc(r.u.ten)}</td><td colspan="5"><span class="num0">Không có dòng của kỳ này</span></td></tr>`;
      const hot = c.o_kiem_dem === "chua_nop_qua_han";
      const gio = c.ts_ph && daNop(c) ? (laNgay && c.ts_ph.toDateString() === c.han.toDateString() ? hhmm(c.ts_ph) : dm(c.ts_ph) + " " + hhmm(c.ts_ph)) : '<span class="num0">—</span>';
      return `<tr${hot ? ' class="hot"' : ""}><td>${i + 1}</td><td class="dv">${esc(r.u.ten)}</td>` +
        `<td><span class="chip" style="background:${MAU[c.o_kiem_dem] || "#94a3b8"}">${NHAN_O[c.o_kiem_dem] || esc(c.o_kiem_dem)}</span></td>` +
        `<td>${gio}</td><td class="who">${AI[c.trang_thai] || ""}</td>` +
        `<td>${r.muon ? `<span class="pill p-late lk" data-dv="${esc(r.u.ma)}" data-o="nop_qua_han">${r.muon}</span>` : '<span class="pill p-ok">0</span>'}</td>` +
        `<td>${r.bo ? `<span class="pill p-qh lk" data-dv="${esc(r.u.ma)}" data-o="chua_nop_qua_han">${r.bo}</span>` : '<span class="pill p-ok">0</span>'}</td></tr>`;
    }).join("");
  }

  const MAU_PHIEU = ["#334155", "#64748b", "#6b96d6", "#1b6fe3", "#00a870"];
  function phieuOpt(b, tong, donVi, minSize) {
    return {
      tooltip: { trigger: "item", formatter: (p) => p.name + "<br/><b>" + p.value + "</b> / " + tong + " " + donVi },
      series: [{ type: "funnel", left: 6, right: 6, top: 6, bottom: 4, minSize, gap: 3, sort: "none",
        label: { position: "inside", color: "#fff", fontSize: 12, fontWeight: 600, formatter: (p) => p.name + ": " + p.value + " (" + Math.round((100 * p.value) / tong) + "%)" },
        itemStyle: { borderWidth: 0 }, data: b.map((x, i) => ({ name: x.n, value: x.v, itemStyle: { color: MAU_PHIEU[i] } })) }],
    };
  }
  function vePhieu() {
    const k = kyDangChon();
    $(".hdPhieu").textContent = "Tình hình xử lý theo luồng — " + nhanKy(k);
    const b = phieu(k ? rowsKy(k.ma) : []), tong = b[0].v;
    if (!tong) { chPhieu.clear(); return; }
    chPhieu.setOption(phieuOpt(b, tong, "báo cáo", "30%"), true);
  }

  const gioOpt = (nhan, series, max, extraX) => ({
    grid: { left: 34, right: 30, top: 28, bottom: 24 },
    legend: { top: 0, left: 0, itemWidth: 14, itemHeight: 8, textStyle: { fontSize: 11.5, color: "#5A6B84" } },
    tooltip: { trigger: "axis" },
    xAxis: Object.assign({ type: "category", data: nhan, boundaryGap: false, axisTick: { show: false }, axisLine: { lineStyle: { color: "#dce5ef" } } }, extraX),
    yAxis: { type: "value", max: Math.max(1, max), minInterval: 1, splitLine: { lineStyle: { color: "#eef2f7" } }, axisLabel: { color: "#8a99ae", fontSize: 10.5 } },
    series,
  });
  function veGio() {
    if (state.loaiKy === "tuan") return veGioTuan();
    const k = KY_NGAY;
    $(".hdGio").textContent = "Tiến độ nộp theo giờ — " + nhanKy(k);
    $(".csGio").textContent = "Đường đậm là kỳ ngày hôm nay, đường mờ là trung bình các kỳ ngày trước, vạch đỏ là mốc hạn nộp";
    if (!k) { chGio.clear(); return; }
    const gio = []; for (let i = 7; i <= 20; i++) gio.push(p2(i) + ":00");
    const hanTxt = hhmm(k.han);
    // lũy tiến số đơn vị đã phát hành tính đến mỗi mốc giờ của chính ngày kỳ
    const luyTien = (kys, chia, catNow) => gio.map((g) => {
      const h = parseInt(g, 10);
      let s = 0;
      for (const ky of kys) {
        const moc = new Date(ky.han.getFullYear(), ky.han.getMonth(), ky.han.getDate(), h, 0);
        if (catNow && moc > NOW) return null;
        s += rowsKy(ky.ma).filter((f) => f.ts_ph && daNop(f) && f.ts_ph <= moc).length;
      }
      return Math.round((10 * s) / chia) / 10;
    });
    const dTn = luyTien([k], 1, true), dTr = luyTien(KY_NGAY_TRUOC, Math.max(1, KY_NGAY_TRUOC.length), false);
    const ml = gio.indexOf(p2(k.han.getHours()) + ":00") >= 0 ? p2(k.han.getHours()) + ":00" : "16:00";
    const series = [{ name: "Hôm nay", type: "line", data: dTn, step: "end", symbol: "circle", symbolSize: 5,
      lineStyle: { width: 2.6, color: "#1b6fe3" }, itemStyle: { color: "#1b6fe3" }, areaStyle: { color: "rgba(27,111,227,.08)" },
      markLine: { silent: true, symbol: "none", data: [{ xAxis: ml, lineStyle: { color: "#e0202a", width: 1.5 },
        label: { formatter: "hạn " + hanTxt, color: "#e0202a", fontSize: 10.5, position: "insideEndTop" } }] } }];
    if (KY_NGAY_TRUOC.length) series.push({ name: "Trung bình các ngày trước", type: "line", data: dTr, step: "end", symbol: "none", lineStyle: { width: 2, type: "dashed", color: "#8a99ae" } });
    chGio.setOption(gioOpt(gio, series, donViLoc().length, { axisLabel: { color: "#8a99ae", fontSize: 10.5, interval: 1 } }), true);
  }
  function veGioTuan() {
    const k = KY_TUAN;
    $(".hdGio").textContent = "Tiến độ nộp theo ngày — " + nhanKy(k);
    $(".csGio").textContent = "Kỳ tuần từ thứ 7 đến hết thứ 6 — lũy tiến số đơn vị đã phát hành tính đến cuối mỗi ngày; vạch đỏ là ngày đáo hạn";
    if (!k) { chGio.clear(); return; }
    const ngay = []; for (let d = 6; d >= 0; d--) ngay.push(new Date(k.han.getFullYear(), k.han.getMonth(), k.han.getDate() - d));
    const THU = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
    const nhan = ngay.map((x) => THU[x.getDay()] + " " + dm(x));
    const rows = rowsKy(k.ma).filter((f) => f.ts_ph && daNop(f));
    const duLieu = ngay.map((x) => {
      if (x > NOW) return null;
      const cuoi = new Date(x.getFullYear(), x.getMonth(), x.getDate(), 23, 59, 59);
      const moc = cuoi > NOW ? NOW : cuoi;
      return rows.filter((f) => f.ts_ph <= moc).length;
    });
    const series = [{ name: "Đã phát hành lũy tiến", type: "line", data: duLieu, symbol: "circle", symbolSize: 6,
      lineStyle: { width: 2.6, color: "#1b6fe3" }, itemStyle: { color: "#1b6fe3" }, areaStyle: { color: "rgba(27,111,227,.08)" },
      markLine: { silent: true, symbol: "none", data: [{ xAxis: nhan[nhan.length - 1], lineStyle: { color: "#e0202a", width: 1.5 },
        label: { formatter: "hạn " + hhmm(k.han), color: "#e0202a", fontSize: 10.5, position: "insideEndTop" } }] } }];
    chGio.setOption(gioOpt(nhan, series, donViLoc().length, { axisLabel: { color: "#8a99ae", fontSize: 11 } }), true);
  }

  // ============ 6. TỔNG QUAN ============
  const nhanNgan = (k) => (k.loai === "ngay" ? dm(k.han) : k.nhan);
  function daMoKy(k) {
    if (k.loai === "ngay") return new Date(k.han.getFullYear(), k.han.getMonth(), k.han.getDate()) <= new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate());
    return tuanTu(k) <= NOW; // kỳ tuần mở từ 00:00 thứ 7
  }
  const kyDongCuaLoai = () => KY.filter((k) => k.loai === state.loaiKy && daMoKy(k));
  function kyDaDong() {
    const ds = kyDongCuaLoai();
    if (!ds.length) return ds;
    const mas = ds.map((k) => k.ma);
    let ia = mas.indexOf(state.tuKy), iz = mas.indexOf(state.denKy);
    if (ia < 0) ia = 0;
    if (iz < 0) iz = ds.length - 1;
    if (ia > iz) { const t = ia; ia = iz; iz = t; }
    return ds.slice(ia, iz + 1);
  }
  function rowsDaDong() {
    const ks = kyDaDong().map((k) => k.ma);
    return FACT.filter((f) => ks.indexOf(f.ma_ky) >= 0 && trongLoc(f.ma_don_vi));
  }
  const MA_O = { nop_dung_han: 1, nop_qua_han: 2, chua_nop_qua_han: 3, chua_nop_con_han: 4, da_nop: 5 };
  function veHeat() {
    const ks = kyDaDong(), usY = donViLoc().slice().reverse(), ui = {}, ki = {};
    usY.forEach((u, i) => { ui[u.ma] = i; });
    ks.forEach((k, i) => { ki[k.ma] = i; });
    const d = rowsDaDong().map((f) => [ki[f.ma_ky], ui[f.ma_don_vi], MA_O[f.o_kiem_dem] || 4, f.o_kiem_dem, f.ma_ky, f.ma_don_vi]);
    chHeat.setOption({
      grid: { left: 196, right: Math.max(12, 968 - ks.length * 116), top: 8, bottom: 26 },
      tooltip: { formatter: (p) => esc(usY[p.value[1]].ten) + "<br/>" + esc(ks[p.value[0]].ten) + "<br/><b>" + (NHAN_O[p.value[3]] || "") + "</b>" },
      xAxis: { type: "category", data: ks.map(nhanNgan), splitArea: { show: true }, axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: "#475569", fontSize: 12, interval: 0 } },
      yAxis: { type: "category", data: usY.map((u) => u.ten), splitArea: { show: true }, axisLine: { show: false }, axisTick: { show: false }, axisLabel: { color: "#0f172a", fontSize: 12.5 } },
      visualMap: { show: false, type: "piecewise", dimension: 2, pieces: [{ value: 1, color: MAU.nop_dung_han }, { value: 2, color: MAU.nop_qua_han },
        { value: 3, color: MAU.chua_nop_qua_han }, { value: 4, color: MAU.chua_nop_con_han }, { value: 5, color: MAU.da_nop }] },
      series: [{ type: "heatmap", data: d, itemStyle: { borderColor: "#fff", borderWidth: 2, borderRadius: 4 }, emphasis: { itemStyle: { borderColor: "#0f172a", borderWidth: 2 } } }],
    }, true);
  }
  function veCot() {
    const ks = kyDaDong();
    const keys = ["nop_dung_han", "nop_qua_han", "chua_nop_con_han", "chua_nop_qua_han"];
    if (rowsDaDong().some((f) => f.o_kiem_dem === "da_nop")) keys.splice(1, 0, "da_nop");
    const data = {}; keys.forEach((k) => { data[k] = ks.map(() => 0); });
    const idx = {}; ks.forEach((k, i) => { idx[k.ma] = i; });
    rowsDaDong().forEach((f) => { if (data[f.o_kiem_dem]) data[f.o_kiem_dem][idx[f.ma_ky]]++; });
    const tiLe = ks.map((k, i) => {
      if (k.han > NOW) return null;
      const tong = keys.filter((x) => x !== "da_nop").reduce((a, x) => a + data[x][i], 0);
      return tong ? Math.round((1000 * data.nop_dung_han[i]) / tong) / 10 : null;
    });
    chCot.setOption({
      grid: { left: 40, right: 44, top: 86, bottom: 28 },
      legend: { top: 0, left: 0, itemWidth: 12, itemHeight: 12, itemGap: 12, textStyle: { fontSize: 11.5, color: "#475569" }, width: "96%" },
      tooltip: { trigger: "axis", axisPointer: { type: "shadow" } },
      xAxis: { type: "category", data: ks.map((k) => nhanNgan(k) + (k.han > NOW ? " *" : "")), axisTick: { show: false },
        axisLine: { lineStyle: { color: "#dce5ef" } }, axisLabel: { color: "#475569", fontSize: 11.5, interval: 0 } },
      yAxis: [{ type: "value", name: "Số lượt", minInterval: 1, nameTextStyle: { color: "#8695a8", fontSize: 11 }, splitLine: { lineStyle: { color: "#eef2f7" } }, axisLabel: { color: "#8695a8", fontSize: 11.5 } },
        { type: "value", max: 120, min: 0, interval: 20, name: "% đúng hạn", nameTextStyle: { color: "#8695a8", fontSize: 11 }, splitLine: { show: false },
          axisLabel: { color: "#8695a8", fontSize: 11.5, formatter: (v) => (v > 100 ? "" : v + "%") } }],
      series: keys.map((k) => ({ name: NHAN_O[k], type: "bar", stack: "t", barMaxWidth: 38, itemStyle: { color: MAU[k] }, emphasis: { focus: "series" },
        label: { show: true, color: "#fff", fontSize: 12, fontWeight: 600, formatter: (p) => (p.value ? p.value : "") }, data: data[k] }))
        .concat([{ name: "Tỉ lệ đúng hạn", type: "line", yAxisIndex: 1, data: tiLe, symbol: "circle", symbolSize: 7, lineStyle: { width: 2.6, color: "#0f172a" },
          itemStyle: { color: "#0f172a" }, connectNulls: false,
          label: { show: true, formatter: (p) => (p.value == null ? "" : p.value + "%"), fontSize: 11.5, color: "#0f172a", position: "top", distance: 8,
            backgroundColor: "rgba(255,255,255,.92)", padding: [2, 5], borderRadius: 4 } }]),
    }, true);
  }
  function vePhieuDot() {
    const rows = rowsDaDong(), tong = rows.length;
    if (!tong) { chPhieu2.clear(); $(".lgPhieu").innerHTML = ""; return; }
    const b = phieu(rows);
    const opt = phieuOpt(b, tong, "lượt", "46%"); opt.series[0].bottom = 6;
    chPhieu2.setOption(opt, true);
    let hut = 0, ten = "";
    for (let i = 1; i < b.length; i++) { const h = b[i - 1].v - b[i].v; if (h > hut) { hut = h; ten = b[i].ai; } }
    $(".lgPhieu").innerHTML = hut ? '<span>Hụt nhiều nhất <b style="color:#0f172a">' + hut + " lượt</b> ở khâu của " + ten + "</span>" : "<span>Không có khâu nào tồn đọng</span>";
  }
  function veTongQuan() {
    $(".kpi2").innerHTML = kpiHtml(rowsDaDong());
    veHeat(); veCot(); vePhieuDot();
  }

  function ve() {
    $(".fKhoang").style.display = state.tab === "ky" ? "none" : "inline-flex";
    if (state.tab === "ky") { veKPI(); veBang(); vePhieu(); veGio(); return; }
    const k = kyDaDong(), dangMo = k.filter((x) => x.han > NOW).length;
    $(".hanTxt").textContent = "Tính trên " + k.length + (state.loaiKy === "ngay" ? " kỳ ngày" : " kỳ tuần") +
      (dangMo ? " · " + (k.length - dangMo) + " đã đóng, " + dangMo + " đang mở" : " đã đóng");
    const chot = rowsDaDong().filter((f) => f.den_han && f.o_kiem_dem !== "da_nop");
    const dung = chot.filter((f) => f.o_kiem_dem === "nop_dung_han").length;
    const cd = $(".hanCd");
    cd.innerHTML = (k.length ? "Từ " + dm(k[0].han) + " đến " + dm(k[k.length - 1].han) : "") +
      (chot.length ? ' · đúng hạn trên kỳ đã chốt: <span style="color:#00a870">' + Math.round((1000 * dung) / chot.length) / 10 + "%</span>" : "");
    cd.className = "hanCd";
    veTongQuan();
  }

  // ============ 7. LỚP 2 ============
  function lechHan(p) {
    if (p === null || p === undefined) return "—";
    const s = p < 0 ? "−" : "+", a = Math.abs(p), h = Math.floor(a / 60), m = a % 60;
    return s + (h ? h + "h" + p2(m) : m + " phút");
  }
  const tg = (d) => (d ? dm(d) + " " + hhmm(d) : '<span class="num0">—</span>');
  function moL2(rows, tieuDe, phuDe) {
    rows = rows.slice().sort((a, b) => a.han - b.han || a.tt_dv - b.tt_dv);
    $2(".l2tt").textContent = tieuDe;
    $2(".l2sub").textContent = phuDe;
    $2(".l2cnt").innerHTML = rows.length + " dòng — khớp đúng con số vừa bấm ở Lớp 1. " +
      '<span style="color:#8a99ae">Bản đã phát hành nhưng bị cơ quan nhận trả lại vẫn tính là chưa nộp, vì số liệu chưa dùng được để tổng hợp.</span>';
    const tag = (mau, chu) => '<span class="chip" style="background:' + mau + '">' + chu + "</span>";
    $2("tbody").innerHTML = rows.map((f, i) => {
      const lech = f.lech != null ? f.lech : f.ts_ph && daNop(f) && f.o_kiem_dem !== "da_nop" ? Math.round((f.ts_ph - f.han) / 60000) : null;
      return "<tr><td>" + (i + 1) + '</td><td class="l">' + esc(f.ten) + '</td><td class="l">' + esc(tenKy(f.ma_ky)) + "</td>" +
        "<td>" + hhmm(f.han) + " " + dm(f.han) + "</td>" +
        "<td>" + tag(MAU_TT[f.trang_thai] || "#94a3b8", NHAN_TT[f.trang_thai] || esc(f.trang_thai)) + "</td>" +
        "<td>" + tag(MAU[f.o_kiem_dem] || "#94a3b8", NHAN_O[f.o_kiem_dem] || esc(f.o_kiem_dem)) + "</td>" +
        "<td>" + tg(f.ts_nhap) + "</td><td>" + tg(f.ts_gui) + "</td><td>" + tg(f.ts_ph) + "</td><td>" + tg(f.ts_tn) + "</td>" +
        "<td>" + lechHan(lech) + '</td><td class="who">' + (AI[f.trang_thai] || "") + "</td></tr>";
    }).join("");
    l2.classList.add("on");
  }
  const dongL2 = () => l2.classList.remove("on");
  const O_KPI = { tong: "all", dung: "nop_dung_han", muon: "nop_qua_han", conhan: "chua_nop_con_han", quahan: "chua_nop_qua_han" };
  const locO = (rows, o) => rows.filter((f) => o === "all" || f.o_kiem_dem === o || (o === "nop_dung_han" && f.o_kiem_dem === "da_nop"));

  // ============ 8. SỰ KIỆN ============
  $(".nowtxt").textContent = dmy(NOW) + " " + hhmm(NOW);
  doiSoat();
  $(".onlyBad").checked = !!state.chiXau;
  $(".onlyBad").addEventListener("change", (e) => { state.chiXau = e.target.checked; veBang(); });
  $(".kpi1").addEventListener("click", (e) => {
    const c = e.target.closest(".kpi"), k = kyDangChon(); if (!c || !k) return;
    const o = O_KPI[c.getAttribute("data-k")];
    moL2(locO(rowsKy(k.ma), o), (o === "all" ? "Toàn bộ lượt phải nộp" : c.querySelector(".lb").textContent) + " — " + nhanKy(k), "Bấm từ thẻ chỉ số Lớp 1");
  });
  $(".tbl tbody").addEventListener("click", (e) => {
    const el = e.target.closest(".lk"); if (!el) return;
    const ma = el.getAttribute("data-dv"), o = el.getAttribute("data-o"), ks = KY_TRUOC().map((k) => k.ma);
    const u = DONVI.filter((x) => x.ma === ma)[0];
    moL2(FACT.filter((f) => f.ma_don_vi === ma && ks.indexOf(f.ma_ky) >= 0 && f.o_kiem_dem === o), (u ? u.ten : ma) + " — " + NHAN_O[o],
      CUA_SO[state.loaiKy] + (state.loaiKy === "ngay" ? " ngày" : " tuần") + " gần nhất trước kỳ hiện tại");
  });
  $(".kpi2").addEventListener("click", (e) => {
    const c = e.target.closest(".kpi"); if (!c) return;
    moL2(locO(rowsDaDong(), O_KPI[c.getAttribute("data-k")]), c.querySelector(".lb").textContent, "Bấm từ thẻ chỉ số tab Tổng quan");
  });
  chHeat.on("click", (p) => {
    const rows = FACT.filter((f) => f.ma_ky === p.value[4] && f.ma_don_vi === p.value[5]);
    if (rows.length) moL2(rows, rows[0].ten + " — " + tenKy(p.value[4]), "Bấm từ lưới chấp hành");
  });
  chCot.on("click", (p) => {
    if (p.seriesType !== "bar") return;
    const k = kyDaDong()[p.dataIndex], o = O_THEO_NHAN[p.seriesName];
    if (k && o) moL2(rowsDaDong().filter((f) => f.ma_ky === k.ma && f.o_kiem_dem === o), NHAN_O[o] + " — " + k.ten, "Bấm từ biểu đồ kết quả từng kỳ");
  });
  $2(".l2close").addEventListener("click", dongL2);
  l2.addEventListener("click", (e) => { if (e.target === l2) dongL2(); });
  const onKey = (e) => { if (e.key === "Escape") dongL2(); };
  document.addEventListener("keydown", onKey);

  const selKhoi = $(".fKhoi"), selDv = $(".fDonVi"), selTu = $(".fTu"), selDen = $(".fDen");
  function napDonVi() {
    const ds = DONVI.filter((u) => state.khoi === "all" || u.khoi === state.khoi);
    if (state.donVi !== "all" && !ds.some((u) => u.ma === state.donVi)) state.donVi = "all";
    selDv.innerHTML = '<option value="all">Tất cả đơn vị (' + ds.length + ")</option>" + ds.map((u) => '<option value="' + esc(u.ma) + '">' + esc(u.ten) + "</option>").join("");
    selDv.value = state.donVi;
  }
  const nhanChon = (k) => (k.loai === "ngay" ? dmy(k.han) : String(k.ten || k.nhan).replace(/^Báo cáo /, ""));
  function napKhoang(giu) {
    const ds = kyDongCuaLoai(), mas = ds.map((k) => k.ma);
    const h = ds.map((k) => '<option value="' + esc(k.ma) + '">' + esc(nhanChon(k)) + "</option>").join("");
    selTu.innerHTML = h; selDen.innerHTML = h;
    if (!giu || mas.indexOf(state.tuKy) < 0) state.tuKy = ds.length ? ds[0].ma : null;
    if (!giu || mas.indexOf(state.denKy) < 0) state.denKy = ds.length ? ds[ds.length - 1].ma : null;
    selTu.value = state.tuKy || ""; selDen.value = state.denKy || "";
  }
  if (KHOI.indexOf(state.khoi) < 0) state.khoi = "all";
  selKhoi.value = state.khoi;
  napDonVi();
  napKhoang(true);
  selKhoi.addEventListener("change", (e) => { state.khoi = e.target.value; state.donVi = "all"; napDonVi(); ve(); });
  selDv.addEventListener("change", (e) => { state.donVi = e.target.value; ve(); });
  selTu.addEventListener("change", (e) => { state.tuKy = e.target.value; ve(); });
  selDen.addEventListener("change", (e) => { state.denKy = e.target.value; ve(); });
  const resizeAll = () => inst.forEach((c) => { try { c.resize(); } catch (e) {} });
  const setOn = (sel, attr, v) => stage.querySelectorAll(sel).forEach((b) => b.classList.toggle("on", b.getAttribute(attr) === v));
  setOn(".fKy button", "data-v", state.loaiKy);
  stage.querySelectorAll(".fKy button").forEach((b) => b.addEventListener("click", () => {
    state.loaiKy = b.getAttribute("data-v"); setOn(".fKy button", "data-v", state.loaiKy); napKhoang(false); ve();
  }));
  function datTab() {
    setOn(".tabs button", "data-tab", state.tab);
    $(".tabKy").style.display = state.tab === "ky" ? "flex" : "none";
    $(".tabTq").style.display = state.tab === "ky" ? "none" : "flex";
  }
  stage.querySelectorAll(".tabs button").forEach((b) => b.addEventListener("click", () => {
    state.tab = b.getAttribute("data-tab"); datTab(); ve(); setTimeout(resizeAll, 60);
  }));
  datTab();

  // khung thiết kế 1920×1080: co theo chiều hẹp hơn, rồi giãn khung cho lấp kín cả rộng lẫn cao (không chừa dải trống)
  // chiều cao = phần khung nhìn còn lại tính từ đỉnh chart (trong iframe khung tab) → không phải cuộn trang
  function datCao() {
    const top = rootEl.getBoundingClientRect().top + (window.scrollY || 0);
    let h = Math.floor(window.innerHeight - top - 2);
    if (height) h = Math.min(h, height);
    if (h > 420) wrapEl.style.height = h + "px";
  }
  function fit() {
    datCao();
    const w = wrapEl.clientWidth || 1920, h = wrapEl.clientHeight || 1080;
    const s = Math.min(w / 1920, h / 1080);
    stage.style.width = w / s + "px";
    stage.style.height = h / s + "px";
    stage.style.transform = "scale(" + s + ")";
    stage.style.left = "0px";
  }
  fit();
  ve();
  setTimeout(resizeAll, 80);

  const onWinResize = () => { fit(); resizeAll(); };
  window.addEventListener("resize", onWinResize);
  let ro = null;
  if (typeof ResizeObserver !== "undefined") { ro = new ResizeObserver(() => { fit(); resizeAll(); }); ro.observe(wrapEl); }
  rootEl.__tdCleanup = function () {
    if (ro) ro.disconnect();
    window.removeEventListener("resize", onWinResize);
    document.removeEventListener("keydown", onKey);
    if (l2.parentNode) l2.parentNode.removeChild(l2);
    inst.forEach((c) => { try { c.dispose(); } catch (e) {} });
  };
  return {};
};
