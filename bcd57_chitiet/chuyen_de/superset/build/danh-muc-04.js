jsEchartScriptFunc = function (queryData, option, echarts, context) {
  /* ==========================================================================
     NQ57 – CHUYÊN ĐỀ CHI TIẾT · chart "NQ57 CĐ chi tiết – Danh mục chỉ số – 04 Chưa có số liệu"
     Dataset: datamart_hanoi.chuyen_de_chi_tiet_nq57 (nạp từ báo cáo tháng qua NiFi).
     Mỗi chart dùng chung template này (superset/chart.tpl.js), khác nhau ở CFG.loai:
       kpi | dem | line | cot | gauge | donut_dd | donut_nv | donut_xl | hbar_nguon | hbar_cq |
       hbar_nd | hbar_dn | bang_cs | bang_qh | bang_xa | bang_tq | bang_dm
     Chỉ số chưa có số liệu (co_so_lieu = 0 / gia_tri NULL) → biểu tượng "!" màu cam.
     File sinh bằng superset/tao_dashboard.py – sửa ở template rồi chạy lại.
     ========================================================================== */
  const CFG = {"loai": "dem", "dem": "chua", "nhan": "Chưa có số liệu", "key": "danh-muc-04"};
  const elementId = context && context.elementId ? context.elementId : "nq57-" + CFG.key;
  const width = context && context.width ? context.width : null;
  const height = context && context.height ? context.height : null;
  const rootEl = document.getElementById(elementId);
  if (!rootEl) return {};
  if (rootEl.__nq57Cleanup) { try { rootEl.__nq57Cleanup(); } catch (e) {} }

  // ============ 1. MÀU, ĐỊNH DẠNG ============
  const P = { navy: "#101828", xanh: "#1D6FE8", sang: "#7FB1F6", ink2: "#344054", mo: "#475467", vien: "#D9DEE7" };
  const C = { tot: "#12B76A", xau: "#F04438", trung: "#98A2B3", warn: "#F79009", grid: "#E4E7EC", track: "#DDE2EA" };
  const NEN = { tot: "#ECFDF3", xau: "#FEF1F0", trung: "#EEF0F3" };
  const MAU = ["#1D6FE8", "#7A5AF8", "#0E9384", "#F79009", "#E31B54"];
  const HUE = { "tong-quan": "#1D5FD6", "nhiem-vu": "#1D5FD6", "tai-chinh": "#0E8F80", "dat-dai": "#E8590C", "du-lieu": "#6D4AE0", tthc: "#0369A1",
    "nen-tang": "#4338CA", "xa-phuong": "#BE185D", khcn: "#D97706", attt: "#C0183F", "danh-muc": "#475467", "canh-bao": "#E8590C" };
  const FONT = '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, Arial, sans-serif';
  const N = (x) => (x == null || x === "" || isNaN(+x) ? null : +x);
  const so = (v, d) => new Intl.NumberFormat("vi-VN", { maximumFractionDigits: d == null ? 0 : d }).format(v);
  const soTD = (v) => so(v, Number.isInteger(v) ? 0 : Math.abs(v) >= 100 ? 1 : 2);
  const gon = (v) => (Math.abs(v) >= 10000 ? new Intl.NumberFormat("vi-VN", { notation: "compact", maximumFractionDigits: 1 }).format(v) : soTD(v));
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const NOD = "Chưa có số liệu";
  const warn = (tip, big) => `<span class="nq-w${big ? " big" : ""}" title="${esc(tip || NOD)}">!</span>`;

  // ============ 2. DỮ LIỆU ============
  const rows = queryData && Array.isArray(queryData.data) ? queryData.data : [];
  const CS = {};
  rows.filter((r) => r.nhom === "CHI_SO").forEach((r) => {
    const o = CS[r.ma] || (CS[r.ma] = { ma: r.ma, ten: r.ten, tn: r.tn || r.ten, dv: r.dv, loai: r.loai, glt: N(r.glt) === 1,
      ng: N(r.ng), tng: r.tng, cd: r.cd, scd: N(r.scd), ttc: N(r.ttc), dm: r.dm, pts: [], miss: [] });
    const p = { ky: r.ky, tt: N(r.tt), v: N(r.v), tu: N(r.tu), mau: N(r.mau), nguon: r.nguon, gc: r.gc };
    (N(r.co) === 1 && p.v != null ? o.pts : o.miss).push(p);
  });
  const kieuCua = (o, p) => (o.dv === "%" ? "pct" : p.tu != null && p.mau != null ? "frac" : "num");
  const hienThi = (k, p) => (k === "pct" ? so(p.v * 100, 1) + "%" : k === "frac" ? soTD(p.tu) + "/" + soTD(p.mau) : soTD(p.v));
  Object.values(CS).forEach((o) => {
    o.pts.sort((a, b) => a.tt - b.tt);
    const r = o.pts[o.pts.length - 1], p = o.pts[o.pts.length - 2];
    o.m = null;
    if (!r) { o.lyDo = (o.miss.find((x) => x.gc) || {}).gc || NOD; return; }
    const k = kieuCua(o, r);
    let ngan = "Chưa có kỳ trước", xh = "trung";
    if (p && kieuCua(o, p) === k) {
      const d = k === "pct" ? Math.round((r.v - p.v) * 1000) / 10 : k === "frac" ? r.tu - p.tu : r.v - p.v;
      const t = (d > 0 ? "+" : "−") + (k === "pct" ? so(Math.abs(d), 1) + " điểm %" : soTD(Math.abs(d)));
      ngan = d === 0 ? "Không đổi" : t;
      xh = d === 0 || o.loai === "Đầu vào" ? "trung" : (o.glt ? d < 0 : d > 0) ? "tot" : "xau";
    }
    o.m = Object.assign({}, r, { kieu: k, hienThi: hienThi(k, r), ngan, xh, truoc: p ? p.ky : null, soKy: o.pts.length });
  });
  // kỳ báo cáo tháng mới nhất có số liệu (lấy từ bảng, không cấu hình cứng)
  const kyThang = Object.values(CS).flatMap((o) => o.pts).filter((p) => /^T\d+\//.test(p.ky)).reduce((m, p) => (!m || p.tt > m.tt ? p : m), null);
  const KY_MOI = kyThang ? kyThang.tt : Infinity, TEN_KY_MOI = kyThang ? kyThang.ky : "";
  const kyMoiNhat = (ds) => ds.reduce((m, r) => (!m || N(r.tt) > N(m.tt) ? r : m), null);
  const cs = (ma) => CS[ma] || { ma, tn: ma, ten: ma, pts: [], miss: [], m: null, lyDo: NOD };
  const tyLe = (m) => (m && (m.kieu === "pct" || m.kieu === "frac") ? m.v : null);
  const donVi = (o) => (o.dv && o.dv !== "%" ? o.dv : "");
  const aux = (nhom) => rows.filter((r) => r.nhom === nhom);
  const kyCua = (o, ky) => o.pts.find((p) => p.ky === ky);
  // Nhiệm vụ phụ lục (dataset chuyen_de_chi_tiet_nhiem_vu_nq57, nhom = 'NV_PL'): gộp các task QLNV theo nhiệm vụ phụ lục
  const ngay = (s) => { if (!s) return null; let m = /^(\d{4})-(\d{1,2})-(\d{1,2})/.exec(s); if (m) return Date.UTC(+m[1], m[2] - 1, +m[3]);
    m = /(\d{1,2})\/(\d{1,2})\/(\d{4})/.exec(s); return m ? Date.UTC(+m[3], m[2] - 1, +m[1]) : null; };
  const nvPhuLuc = () => {
    const all = rows.filter((r) => r.nhom === "NV_PL"), k = kyMoiNhat(all), ky = k ? k.ky : "";
    const G = new Map();
    all.filter((r) => r.ky === ky).forEach((r) => {
      const g = G.get(r.stt) || { stt: N(r.stt), ten: r.tpl, vb: r.vbpl, cqPL: r.cqpl, hanPL: r.hanpl, pl: r.pl, tasks: [] };
      if (N(r.task) > 0) g.tasks.push(r);
      G.set(r.stt, g);
    });
    const homNay = Date.now();
    const ds = [...G.values()].map((g) => {
      const t = g.tasks, dv = [...new Set(t.map((x) => x.dvth || x.dvct).filter(Boolean))];
      const han = t.map((x) => ngay(x.han)).filter((x) => x != null).sort((a, b) => a - b)[0] ?? ngay(g.hanPL);
      const xong = t.length > 0 && t.every((x) => x.trg === "Đã hoàn thành");   // tinh_trang QLNV
      const den = xong ? Math.max(...t.map((x) => ngay(x.nht) || homNay)) : homNay;
      const td = t.map((x) => N(x.td)).filter((x) => x != null);
      return Object.assign(g, { coQuan: dv.length ? dv.slice(0, 2).join("; ") + (dv.length > 2 ? "…" : "") : g.cqPL, xong,
        soNgay: han != null ? Math.max(0, Math.round((den - han) / 864e5)) : null,
        tinhTrang: [...new Set(t.map((x) => x.trg).filter(Boolean))].join(", "), tienDo: td.length ? Math.min(...td) : null });
    }).sort((a, b) => (a.xong - b.xong) || ((b.soNgay ?? -1) - (a.soNgay ?? -1)));
    return { ky, ds, thieu: ds.filter((q) => !q.tasks.length).length };
  };

  // ============ 3. KHUNG + CSS ============
  const cssSize = (v) => (v == null ? "100%" : typeof v === "number" ? v + "px" : v);
  rootEl.style.width = cssSize(width);
  rootEl.style.height = cssSize(height);
  rootEl.style.overflow = "hidden";
  rootEl.style.maxWidth = "100%";
  for (let p = rootEl.parentElement; p && p !== document.body; p = p.parentElement) p.style.minWidth = "0";
  const wrapId = elementId + "-nq57";
  const S = `#${wrapId}`;
  const css = `<style>
${S}{width:100%;height:100%;box-sizing:border-box;font-family:${FONT};color:${P.navy};letter-spacing:-.01em;font-feature-settings:"tnum";display:flex;flex-direction:column;background:#fff}
${S} *{box-sizing:border-box}
${S} .muc{flex:1;min-height:0;display:flex;flex-direction:column;border-top:1px solid ${P.vien};padding:10px 4px 4px}
${S} .muc-h{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:6px}
${S} .muc-t{font-size:16px;font-weight:650;color:${P.navy};white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
${S} .muc-b{flex:1;min-height:0;position:relative}
${S} .chu{display:flex;flex-wrap:wrap;gap:4px 16px;font-size:13px;color:${P.ink2};margin-bottom:4px}
${S} .chu i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:6px;vertical-align:-1px}
${S} .nq-w{display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;border-radius:50%;background:${C.warn};color:#fff;font-weight:800;font-size:12px;line-height:1;cursor:help;flex:none}
${S} .nq-w.big{width:34px;height:34px;font-size:20px}
${S} .nod{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;gap:10px;color:${P.mo};font-size:14px}
${S} .kpi{height:100%;display:flex;flex-direction:column;justify-content:space-between;border-radius:16px;padding:14px 18px;background:#fff;border:1px solid ${P.vien};box-shadow:0 8px 22px -12px rgba(15,42,92,.28),0 1px 2px rgba(15,42,92,.05)}
${S} .kpi-t{display:flex;align-items:center;gap:10px;font-size:15px;font-weight:600;color:${P.ink2};min-width:0}
${S} .kpi-t span.n{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
${S} .ico{flex:none;min-width:30px;height:30px;padding:0 7px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:13px;font-weight:700}
${S} .kpi-v{font-size:40px;font-weight:700;line-height:1;letter-spacing:-.03em;white-space:nowrap}
${S} .kpi-v small{font-size:13px;font-weight:500;color:${P.mo};margin-left:6px;letter-spacing:0}
${S} .kpi-s{margin-top:8px;display:flex;align-items:center;gap:8px;font-size:13px;color:${P.mo};white-space:nowrap}
${S} .dl{border-radius:6px;padding:2px 8px;font-weight:600}
${S} .kpi-f{display:flex;align-items:flex-end;justify-content:space-between;gap:10px}
${S} .kpi-miss{display:flex;align-items:center;gap:10px;color:${C.warn};font-weight:600;font-size:15px}
${S} table{width:100%;border-collapse:collapse;font-size:13px;text-align:left}
${S} th{position:sticky;top:0;z-index:1;background:#fff;padding:8px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:${P.mo};border-bottom:1px solid ${P.vien};white-space:nowrap}
${S} td{padding:7px 8px;border-bottom:1px solid #E4E7EC;vertical-align:middle}
${S} tr.cl{cursor:pointer} ${S} tr.cl:hover td{background:#FAFBFC}
${S} .r{text-align:right} ${S} .nw{white-space:nowrap}
${S} .sub{display:block;font-size:11px;color:#667085;margin-top:1px}
${S} .val{font-size:15px;font-weight:650}
${S} .scroll{position:absolute;inset:0;overflow:auto}
${S} .bar{height:8px;border-radius:2px;background:${C.track};overflow:hidden;flex:1}
${S} .bar>div{height:100%}
${S} .hb{position:absolute;inset:0;display:flex;flex-direction:column;justify-content:space-around;gap:4px}
${S} .hb-l{display:flex;justify-content:space-between;gap:10px;font-size:13px}
${S} .hb-l span:first-child{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
${S} .hb-t{position:relative;height:11px;margin-top:3px;border-radius:2px;background:${C.track};overflow:hidden}
${S} .hb-t>div{position:absolute;top:0;bottom:0}
${S} .tool{display:flex;gap:8px}
${S} .tool input,${S} .tool select{font:inherit;font-size:13px;border:1px solid ${P.vien};border-radius:8px;padding:5px 10px;color:${P.navy};background:#fff}
${S} .tool input{width:240px}
${S} .dem{height:100%;display:flex;flex-direction:column;justify-content:space-between;border-radius:12px;padding:14px 18px;background:#fff;border:1px solid ${P.vien}}
${S} .ech{position:absolute;inset:0}
</style>`;

  // ============ 4. THÀNH PHẦN DÙNG CHUNG ============
  const muc = (tieuDe, body, phai) => `<div class="muc"><div class="muc-h"><span class="muc-t" title="${esc(tieuDe)}">${esc(tieuDe)}</span>${phai || ""}</div><div class="muc-b">${body}</div></div>`;
  const chu = (items) => `<div class="chu">${items.map((x) => `<span>${x.miss ? warn(x.tip) + " " : `<i style="background:${x.c}"></i>`}${esc(x.n)}</span>`).join("")}</div>`;
  const nod = (tip) => `<div class="nod">${warn(tip, true)}<span>${esc(NOD)}</span></div>`;
  const mauXH = (x) => (x === "tot" ? C.tot : x === "xau" ? C.xau : P.mo);
  const delta = (m) => (m ? `<span class="dl" style="color:${mauXH(m.xh)};background:${NEN[m.xh]}">${m.ngan.startsWith("+") ? "▲ " : m.ngan.startsWith("−") ? "▼ " : ""}${esc(m.ngan)}</span>` : "");
  const spark = (pts, w, h, col) => {
    if (!pts || pts.length < 2) return "";
    const xs = pts.map((p) => p.tt), vs = pts.map((p) => p.v);
    const x0 = Math.min(...xs), x1 = Math.max(...xs), lo = Math.min(0, ...vs), hi = Math.max(...vs) || 1;
    const X = (t) => 3 + ((t - x0) / (x1 - x0 || 1)) * (w - 6), Y = (v) => h - 3 - ((v - lo) / (hi - lo || 1)) * (h - 6);
    const d = pts.map((p, i) => `${i ? "L" : "M"}${X(p.tt).toFixed(1)},${Y(p.v).toFixed(1)}`).join("");
    const l = pts[pts.length - 1];
    return `<svg width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" style="display:block"><path d="${d}L${X(l.tt).toFixed(1)},${h}L${X(pts[0].tt).toFixed(1)},${h}Z" fill="${col}" opacity=".12"/>` +
      `<path d="${d}" fill="none" stroke="${col}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><circle cx="${X(l.tt)}" cy="${Y(l.v)}" r="2.8" fill="${col}"/></svg>`;
  };
  const ring = (v, col, size, sw) => {
    const r = (size - sw) / 2, c = 2 * Math.PI * r, p = Math.max(0, Math.min(1, v || 0));
    return `<div style="position:relative;width:${size}px;height:${size}px;flex:none"><svg width="${size}" height="${size}" style="transform:rotate(-90deg)">` +
      `<circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${C.track}" stroke-width="${sw}"/>` +
      `<circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${col}" stroke-width="${sw}" stroke-linecap="round" stroke-dasharray="${p * c} ${c}"/></svg>` +
      `<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700">${so(p * 100, 0)}%</div></div>`;
  };
  const icon = (id, txt) => `<span class="ico" style="background:${HUE[id] || HUE["nhiem-vu"]}">${esc(txt || "")}</span>`;
  const giaTriO = (o) => (o.m ? `<span class="val">${esc(o.m.hienThi)}</span>${donVi(o) ? ` <span style="font-size:11px;color:${P.mo}">${esc(donVi(o))}</span>` : ""}` :
    `<span style="display:inline-flex;align-items:center;gap:6px;color:${C.warn};font-weight:600">${warn(o.lyDo)}Chưa có</span>`);

  // ============ 5. ECHARTS ============
  const inst = [];
  const mk = (el) => { const c = echarts.init(el, null, { renderer: "canvas" }); inst.push(c); return c; };
  const TIP = { trigger: "axis", backgroundColor: "#fff", borderColor: P.vien, textStyle: { color: P.navy, fontSize: 13 }, extraCssText: "box-shadow:0 8px 20px -8px rgba(15,42,92,.3);border-radius:8px" };
  const AX = { axisLine: { lineStyle: { color: P.vien } }, axisTick: { show: false }, axisLabel: { color: P.mo, fontSize: 12 } };
  const seriesOf = (mas) => mas.map((ma, i) => ({ o: cs(ma), c: MAU[i % MAU.length] }));
  const kysOf = (ss) => [...new Map(ss.flatMap((s) => s.o.pts).sort((a, b) => a.tt - b.tt).map((p) => [p.ky, p.tt])).keys()];
  const chuSeries = (ss, extra) => chu(ss.map((s) => (s.o.pts.length ? { n: s.o.tn, c: s.c } : { n: s.o.tn + " (chưa có)", miss: true, tip: s.o.lyDo })).concat(extra || []));
  const fmtPt = (o, p, kieu) => (kieu === "pct" ? so(p.v * 100, 1) + "%" : p.tu != null && p.mau != null && o.dv !== "%" ? soTD(p.tu) + "/" + soTD(p.mau) : soTD(p.v));

  function veLine(el, ss) {
    const kys = kysOf(ss), pct = CFG.kieu === "pct";
    const ng = CFG.nguong ? cs(CFG.nguong) : null;
    const sr = ss.filter((s) => s.o.pts.length).map((s) => ({
      name: s.o.tn, type: "line", smooth: false, symbol: "circle", symbolSize: 7, connectNulls: true,
      itemStyle: { color: s.c }, lineStyle: { width: 2.4 }, areaStyle: ss.length <= 2 ? { opacity: 0.08 } : undefined,
      data: kys.map((k) => { const p = kyCua(s.o, k); return p ? p.v : null; }),
      endLabel: { show: true, color: s.c, fontWeight: 700, fontSize: 13, formatter: () => fmtPt(s.o, s.o.pts[s.o.pts.length - 1], CFG.kieu) },
    }));
    if (ng && ng.ng != null && sr.length) sr[0].markLine = { silent: true, symbol: "none", lineStyle: { color: P.navy, type: "dashed" }, label: { formatter: ng.tng || "Ngưỡng", color: P.navy, position: "insideEndTop" }, data: [{ yAxis: ng.ng }] };
    mk(el).setOption({
      grid: { left: 8, right: 70, top: 18, bottom: 4, containLabel: true },
      tooltip: Object.assign({}, TIP, { valueFormatter: (v) => (v == null ? "—" : pct ? so(v * 100, 1) + "%" : soTD(v)) }),
      xAxis: Object.assign({ type: "category", data: kys, boundaryGap: false }, AX),
      yAxis: { type: "value", splitLine: { lineStyle: { color: C.grid } }, axisLabel: { color: P.mo, formatter: (v) => (pct ? so(v * 100, 0) + "%" : gon(v)) } },
      series: sr,
    });
  }
  function veCot(el, ss) {
    const kys = kysOf(ss);
    mk(el).setOption({
      grid: { left: 8, right: 8, top: 22, bottom: 4, containLabel: true },
      tooltip: Object.assign({}, TIP, { axisPointer: { type: "shadow" }, valueFormatter: (v) => (v == null ? "—" : soTD(v)) }),
      xAxis: Object.assign({ type: "category", data: kys }, AX),
      yAxis: { type: "value", splitLine: { lineStyle: { color: C.grid } }, axisLabel: { color: P.mo, formatter: gon } },
      series: ss.filter((s) => s.o.pts.length).map((s) => ({
        name: s.o.tn, type: "bar", barMaxWidth: 34, itemStyle: { color: s.c, borderRadius: [3, 3, 0, 0] },
        label: { show: ss.length === 1 || kys.length <= 6, position: "top", color: P.ink2, fontSize: 11, fontWeight: 700, formatter: (p) => (p.value == null ? "" : gon(p.value)) },
        data: kys.map((k) => { const p = kyCua(s.o, k); return p ? p.v : null; }),
      })),
    });
  }
  function veDonut(el, parts, giua, phu) {
    const tong = parts.reduce((a, p) => a + (p.v || 0), 0) || 1;
    el.innerHTML = `<div style="position:absolute;inset:0;display:flex;align-items:center;gap:22px"><div class="dn" style="position:relative;height:100%;flex:0 0 46%"></div>
      <ul style="flex:1;min-width:0;max-width:340px;list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:7px">${parts.map((p) =>
        `<li style="display:flex;align-items:center;gap:8px;font-size:14px"><i style="width:10px;height:10px;border-radius:2px;background:${p.c};flex:none"></i><span style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(p.n)}</span>` +
        `<b style="margin-left:auto">${p.v == null ? warn(p.tip) : gon(p.v)}</b><span style="width:52px;text-align:right;color:${P.mo};font-size:13px">${p.v == null ? "" : so((p.v / tong) * 100, 1) + "%"}</span></li>`).join("")}</ul></div>`;
    mk(el.querySelector(".dn")).setOption({
      tooltip: { trigger: "item", formatter: (p) => `${esc(p.name)}: <b>${soTD(p.value)}</b> (${so(p.percent, 1)}%)` },
      title: { text: giua, subtext: phu, left: "center", top: "center", itemGap: 4, textStyle: { fontSize: 24, fontWeight: 650, color: P.navy, fontFamily: FONT }, subtextStyle: { fontSize: 12, color: P.mo } },
      series: [{ type: "pie", radius: ["62%", "90%"], avoidLabelOverlap: false, label: { show: false }, itemStyle: { borderColor: "#fff", borderWidth: 2 },
        data: parts.filter((p) => p.v != null).map((p) => ({ name: p.n, value: p.v, itemStyle: { color: p.c } })) }],
    });
  }
  function veGauge(el) {
    const o = cs(CFG.ma), m = o.m;
    if (!m) { el.innerHTML = nod(o.lyDo); return; }
    const tran = CFG.tran || 1, frac = Math.max(0, Math.min(1, m.v / tran)), muc = o.ng; // mục tiêu = cột nguong trong bảng
    const col = muc != null ? (m.v >= muc ? C.tot : m.v >= muc * 0.85 ? C.warn : C.xau) : P.xanh;
    const parts = [{ n: "Đã đạt", c: col, v: frac }, { n: "Còn lại", c: C.track, v: 1 - frac }];
    el.innerHTML = `<div style="position:absolute;inset:0;display:flex;align-items:center;gap:22px"><div class="dn" style="position:relative;height:100%;flex:0 0 46%"></div>
      <ul style="flex:1;max-width:300px;list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:7px;font-size:14px">
      ${parts.map((p) => `<li style="display:flex;align-items:center;gap:8px"><i style="width:10px;height:10px;border-radius:2px;background:${p.c}"></i>${p.n}<b style="margin-left:auto">${so(p.v * 100, 1)}%</b></li>`).join("")}
      ${muc != null ? `<li style="display:flex;align-items:center;gap:8px"><i style="width:10px;height:10px;border-radius:2px;background:${P.navy}"></i>Mục tiêu<b style="margin-left:auto">${so(muc * 100, 0)}%</b></li>` : ""}
      <li style="color:${P.mo};font-size:12px">${esc(m.kieu === "frac" ? soTD(m.tu) + "/" + soTD(m.mau) + " · " : "")}${esc(m.ky)}</li></ul></div>`;
    mk(el.querySelector(".dn")).setOption({
      title: { text: m.hienThi, subtext: m.ky, left: "center", top: "center", itemGap: 4, textStyle: { fontSize: 22, fontWeight: 650, color: P.navy, fontFamily: FONT }, subtextStyle: { fontSize: 12, color: P.mo } },
      series: [{ type: "pie", radius: ["62%", "90%"], silent: true, label: { show: false }, startAngle: 90,
        data: [{ value: frac, itemStyle: { color: col } }, { value: 1 - frac, itemStyle: { color: C.track } }] }],
    });
  }
  const hbars = (rs, segs, max, overlay, giaTri) => {
    const m = max || Math.max(1, ...rs.map((r) => (overlay ? Math.max(...segs.map((s) => s.v(r) || 0)) : segs.reduce((a, s) => a + (s.v(r) || 0), 0))));
    return chu(segs.map((s) => ({ n: s.n, c: s.c }))) + `<div style="position:relative;flex:1;height:calc(100% - 24px)"><div class="hb">${rs.map((r) => {
      let x = 0;
      const bars = segs.map((s) => { const w = ((s.v(r) || 0) / m) * 100; const b = `<div title="${esc(s.n)}: ${soTD(s.v(r) || 0)}" style="left:${overlay ? 0 : x}%;width:${w}%;background:${s.c}"></div>`; if (!overlay) x += w; return b; }).join("");
      return `<div><div class="hb-l"><span title="${esc(r.nhan)}">${esc(r.nhan)}</span><b>${esc(giaTri(r))}</b></div><div class="hb-t">${bars}</div></div>`;
    }).join("")}</div></div>`;
  };

  // ============ 6. VẼ THEO LOẠI ============
  let html = "";
  const sau = []; // việc chạy sau khi gắn HTML (echarts)
  const L = CFG.loai;
  if (L === "kpi") {
    const o = cs(CFG.ma), m = o.m, p = tyLe(m);
    const vach = m && m.xh === "tot" ? C.tot : m && m.xh === "xau" ? C.xau : m ? P.xanh : C.warn;
    html = `<div class="kpi" style="border-top:4px solid ${vach}${CFG.link ? ";cursor:pointer" : ""}" title="${esc(o.ten)}">
      <div class="kpi-t">${icon(CFG.icon, CFG.ma)}<span class="n">${esc(CFG.nhan || o.tn)}</span></div>
      ${m ? `<div class="kpi-f"><div style="min-width:0"><div class="kpi-v">${esc(m.hienThi)}${donVi(o) ? `<small>${esc(donVi(o))}</small>` : ""}</div>
        <div class="kpi-s">${delta(m)}<span>${esc(m.ky)}</span></div></div>${p != null ? ring(p, P.xanh, 66, 8) : spark(o.pts, 110, 46, P.xanh)}</div>`
      : `<div class="kpi-f"><div class="kpi-miss">${warn(o.lyDo, true)}<span>${esc(NOD)}<span class="sub" style="font-weight:400">${esc(o.lyDo)}</span></span></div></div>`}
    </div>`;
  } else if (L === "dem") {
    const all = Object.values(CS), moi = all.filter((o) => o.m && o.m.tt >= KY_MOI).length, cu = all.filter((o) => o.m && o.m.tt < KY_MOI).length, chua = all.filter((o) => !o.m).length;
    const D = { tong: [all.length, P.navy], moi: [moi, P.xanh], cu: [cu, C.warn], chua: [chua, C.xau] }[CFG.dem];
    html = `<div class="dem" style="border-top:3px solid ${D[1]}"><div class="kpi-t">${CFG.dem === "chua" ? warn(NOD) : ""}<span class="n">${esc(CFG.dem === "moi" ? CFG.nhan + " " + TEN_KY_MOI : CFG.nhan)}</span></div>
      <div class="kpi-f"><div class="kpi-v">${D[0]}</div>${ring(D[0] / (all.length || 1), D[1], 58, 7)}</div></div>`;
  } else if (L === "line" || L === "cot") {
    const ss = seriesOf(CFG.ma);
    const extra = CFG.nguong && cs(CFG.nguong).ng != null ? [{ n: cs(CFG.nguong).tng, c: P.navy }] : [];
    const has = ss.some((s) => s.o.pts.length);
    html = muc(CFG.tieuDe, chuSeries(ss, extra) + `<div style="position:absolute;inset:24px 0 0 0">${has ? `<div class="ech"></div>` : nod(ss[0].o.lyDo)}</div>`);
    if (has) sau.push((w) => (L === "line" ? veLine : veCot)(w.querySelector(".ech"), ss));
  } else if (L === "gauge") {
    html = muc(CFG.tieuDe, `<div class="ech"></div>`);
    sau.push((w) => veGauge(w.querySelector(".ech")));
  } else if (L === "donut_dd" || L === "donut_nv" || L === "donut_xl") {
    let parts, giua, phu;
    if (L === "donut_dd") {
      const a = cs("DD01").m, b = cs("DD02").m, d = cs("DD04").m;
      parts = [{ n: "Đạt Nhóm 1", c: P.xanh, v: d ? d.v : null, tip: cs("DD04").lyDo }, { n: "Có CSDL, chưa đạt", c: P.sang, v: b && d ? b.v - d.v : null, tip: NOD },
        { n: "Chưa có CSDL", c: "#D0D5DD", v: a && b ? a.v - b.v : null, tip: NOD }];
      giua = a ? gon(a.v) : "!"; phu = "thửa · " + (a ? a.ky : "");
    } else if (L === "donut_nv") {
      const t = cs("NV01").m, h = cs("NV02").m, dg = cs("NV04").m, q = cs("NV05").m;
      parts = [{ n: "Hoàn thành", c: P.xanh, v: h ? h.v : null }, { n: "Đang trong hạn", c: P.sang, v: dg && q ? dg.v - q.v : null }, { n: "Quá hạn", c: C.xau, v: q ? q.v : null }];
      giua = t ? gon(t.v) : "!"; phu = "nhiệm vụ · " + (t ? t.ky : "");
    } else {
      const XL = [["CS10", "#12B76A"], ["CS11", "#6EDB8F"], ["CS12", "#1D6FE8"], ["CS13", "#F04438"], ["CS14", "#D0D5DD"]].map(([ma, c]) => [cs(ma).tn, ma, c]);
      const ky = (cs("CS10").m || {}).ky;
      parts = XL.map(([n, ma, c]) => { const p = ky ? kyCua(cs(ma), ky) : null; return { n, c, v: p ? p.v : null, tip: cs(ma).lyDo }; });
      giua = String(parts.reduce((a, p) => a + (p.v || 0), 0)); phu = "xã, phường · " + (ky || "");
    }
    const has = parts.some((p) => p.v != null);
    html = muc(CFG.tieuDe, has ? `<div class="ech"></div>` : nod());
    if (has) sau.push((w) => veDonut(w.querySelector(".ech"), parts, giua, phu));
  } else if (L === "hbar_nguon") {
    const all = aux("NGUON_GIAO"), ky = (kyMoiNhat(all) || {}).ky, ds = all.filter((r) => r.ky === ky);
    const G = {};
    ds.forEach((r) => { (G[r.pt] = G[r.pt] || { nhan: r.pt })[r.ma] = N(r.v); });
    const rs = Object.values(G);
    html = muc(CFG.tieuDe + (ky ? ", " + ky : ""), rs.length ? hbars(rs, [{ n: "Hoàn thành", c: P.xanh, v: (r) => r.hoan_thanh }, { n: "Đang trong hạn", c: P.sang, v: (r) => (r.dang_thuc_hien || 0) - (r.qua_han || 0) },
      { n: "Quá hạn", c: C.xau, v: (r) => r.qua_han }], null, false, (r) => String(r.tong)) : nod());
  } else if (L === "hbar_cq") {
    // đếm nhiệm vụ quá hạn chưa xong (phụ lục kỳ mới nhất) theo đơn vị thực hiện trong QLNV; chưa map thì theo cơ quan ghi trong phụ lục
    const P0 = nvPhuLuc(), M = new Map();
    P0.ds.filter((q) => !q.xong).forEach((q) => M.set(q.coQuan || "Chưa rõ", (M.get(q.coQuan || "Chưa rõ") || 0) + 1));
    const rs = [...M].map(([nhan, n]) => ({ nhan, n })).sort((a, b) => b.n - a.n).slice(0, 7);
    html = muc(CFG.tieuDe + (P0.ky ? ", " + P0.ky : ""), rs.length ? hbars(rs, [{ n: "Nhiệm vụ quá hạn", c: C.xau, v: (r) => r.n }], null, false, (r) => String(r.n)) : nod());
  } else if (L === "hbar_nd") {
    const ds = aux("NOI_DUNG_XA"), nh = [...new Set(ds.map((r) => r.pt))];
    const kys = [...new Set(ds.map((r) => r.ky))].sort();
    const [k1, k2] = [kys[0], kys[kys.length - 1]];
    const rs = nh.map((n) => ({ nhan: n, a: N((ds.find((r) => r.pt === n && r.ky === k1) || {}).v), b: N((ds.find((r) => r.pt === n && r.ky === k2) || {}).v) }));
    html = muc(CFG.tieuDe, rs.length ? hbars(rs, [{ n: k2, c: P.xanh, v: (r) => r.b }, { n: k1, c: P.sang, v: (r) => r.a }], N((ds[0] || {}).mau), true, (r) => `${r.a ?? "!"} → ${r.b ?? "!"}`) : nod());
  } else if (L === "hbar_dn") {
    const ds = aux("DIEM_NGHEN_XA"), G = {};
    ds.forEach((r) => { (G[r.pt] = G[r.pt] || { nhan: r.pt, tt: N(r.ttc) })[r.ma] = N(r.v); });
    const rs = Object.values(G).sort((a, b) => a.tt - b.tt);
    const kyD = (ds[0] || {}).ky;
    html = muc(CFG.tieuDe + (kyD ? ", " + kyD : ""), rs.length ? hbars(rs, [{ n: "Phản ánh", c: P.sang, v: (r) => r.so_xa_phan_anh }, { n: "Cần xử lý sớm", c: C.xau, v: (r) => r.can_xu_ly_som }], N((ds[0] || {}).mau), true,
      (r) => `${r.so_xa_phan_anh} · ${r.can_xu_ly_som}`) : nod());
  } else if (L === "bang_cs") {
    const ds = Object.values(CS).sort((a, b) => a.ttc - b.ttc);
    const thieu = ds.filter((o) => !o.m).length;
    html = muc(CFG.tieuDe + ` (${ds.length})`, `<div class="scroll"><table><thead><tr><th>Chỉ số</th><th class="r">Giá trị</th><th>Thay đổi</th><th>Diễn biến</th></tr></thead><tbody>${ds.map((o) =>
      `<tr title="${esc(o.ten)}"><td>${esc(o.ten)}<span class="sub">${esc(o.ma)}${o.m ? " · " + esc(o.m.ky) : ""}</span></td><td class="r nw">${giaTriO(o)}</td><td class="nw">${delta(o.m)}</td><td>${spark(o.pts, 90, 26, P.xanh)}</td></tr>`).join("")}</tbody></table></div>`,
      thieu ? `<span style="display:inline-flex;align-items:center;gap:6px;font-size:12px;color:${C.warn};font-weight:600">${warn(thieu + " chỉ số chưa có số liệu")}${thieu} chưa có</span>` : "");
  } else if (L === "bang_qh") {
    // Nhiệm vụ trong phụ lục "quá hạn, chậm muộn" của kỳ báo cáo mới nhất, map với task QLNV (bảng chuyen_de_chi_tiet_nhiem_vu_nq57)
    const P0 = nvPhuLuc(), ds = P0.ds;
    html = muc(CFG.tieuDe + ` (${ds.length})` + (P0.ky ? ` – ${P0.ky}` : ""), ds.length ? `<div class="scroll"><table><thead><tr><th>Nhiệm vụ</th><th class="r">Quá hạn</th><th>Tình trạng QLNV</th></tr></thead><tbody>${ds.map((q) =>
      `<tr><td><span style="display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden" title="${esc(q.ten)}">${esc(q.ten)}</span>` +
      `<span class="sub">${esc(q.coQuan)}${q.vb ? " · " + esc(q.vb) : ""}${q.tasks.length > 1 ? " · " + q.tasks.length + " task" : ""}</span></td>` +
      `<td class="r nw" style="font-weight:650;color:${q.xong ? C.tot : q.soNgay > 90 ? C.xau : q.soNgay > 30 ? C.warn : P.ink2}">${q.xong ? "Đã xong" : q.soNgay != null ? q.soNgay + " ngày" : warn("Chưa có thời hạn")}</td>` +
      `<td class="nw" style="font-size:12px">${q.tasks.length ? esc(q.tinhTrang || "") + (q.tienDo != null ? ` · ${q.tienDo}%` : "") : warn("Chưa map được với nhiệm vụ trong QLNV") + ' <span style="color:#98A2B3">Chưa map</span>'}</td></tr>`).join("")}</tbody></table></div>`
      : nod("Chưa có nhiệm vụ quá hạn trong phụ lục"), P0.thieu ? `<span style="display:inline-flex;align-items:center;gap:6px;font-size:12px;color:${C.warn};font-weight:600" title="Nhiệm vụ phụ lục chưa tìm thấy task tương ứng trong QLNV">${warn("Chưa map được với QLNV")}${P0.thieu} chưa map</span>` : "");
  } else if (L === "bang_xa") {
    const G = {};
    const xs = aux("XA_QUAN_TAM"), kyX = xs.reduce((m, r) => (N(r.tt) > (m ? N(m.tt) : -1) ? r : m), null);
    xs.filter((r) => kyX && r.ky === kyX.ky).forEach((r) => { (G[r.pt] = G[r.pt] || { xa: r.pt, tt: N(r.ttc) })[r.ma] = N(r.v); });
    const ds = Object.values(G).sort((a, b) => a.tt - b.tt);
    html = muc(CFG.tieuDe + (kyX ? ", " + kyX.ky : ""), ds.length ? `<div class="scroll"><table><thead><tr><th>Xã, phường</th><th>Tỷ lệ hoàn thành</th><th class="r">Đang quá hạn</th><th class="r">Xong quá hạn</th></tr></thead><tbody>${ds.map((x) => {
      const tl = x.tong_nhiem_vu ? x.hoan_thanh / x.tong_nhiem_vu : null, col = tl == null ? C.warn : tl < 0.6 ? C.xau : tl < 0.85 ? C.warn : P.xanh;
      return `<tr><td style="font-weight:600">${esc(x.xa)}<span class="sub" style="font-weight:400">${x.hoan_thanh ?? "!"}/${x.tong_nhiem_vu ?? "!"} nhiệm vụ</span></td>` +
        `<td>${tl == null ? warn() : `<div style="display:flex;align-items:center;gap:8px"><div class="bar"><div style="width:${tl * 100}%;background:${col}"></div></div><b style="width:42px;text-align:right">${so(tl * 100, 0)}%</b></div>`}</td>` +
        `<td class="r" style="font-weight:650;color:${x.dang_qua_han ? C.xau : C.trung}">${x.dang_qua_han ?? warn()}</td><td class="r">${x.xong_qua_han ?? warn()}</td></tr>`; }).join("")}</tbody></table></div>` : nod());
  } else if (L === "bang_tq") {
    const tqRows = CFG.tq.map(([id, ma, ten]) => {
      const o = cs(ma), ds = Object.values(CS).filter((x) => x.cd === o.cd);
      const moi = ds.filter((x) => x.m && x.m.tt >= KY_MOI).length, cu = ds.filter((x) => x.m && x.m.tt < KY_MOI).length, chua = ds.length - moi - cu;
      const tl = tyLe(o.m);
      return `<tr><td><div style="display:flex;align-items:center;gap:10px">${icon(id, String(o.scd || ""))}<div style="min-width:0"><b style="font-size:14px">${esc(ten)}</b><span class="sub">${esc(o.tn)}</span></div></div></td>` +
        `<td class="r nw">${o.m ? `<span style="font-size:20px;font-weight:650">${esc(o.m.hienThi)}</span>${donVi(o) ? ` <span style="font-size:11px;color:${P.mo}">${esc(donVi(o))}</span>` : ""}` : warn(o.lyDo, true)}</td>` +
        `<td style="width:140px">${tl != null ? `<div style="display:flex;align-items:center;gap:8px"><div class="bar"><div style="width:${Math.min(100, tl * 100)}%;background:${P.xanh}"></div></div><b style="font-size:12px">${so(tl * 100, 0)}%</b></div>` : ""}</td>` +
        `<td class="nw">${delta(o.m)}<span class="sub">${o.m ? esc(o.m.ky) : ""}</span></td><td>${spark(o.pts, 110, 30, P.xanh)}</td>` +
        `<td style="width:170px"><div class="bar" style="display:flex" title="${moi} có số liệu mới · ${cu} chỉ có kỳ cũ · ${chua} chưa có số liệu"><div style="width:${(moi / (ds.length || 1)) * 100}%;background:${P.xanh}"></div><div style="width:${(cu / (ds.length || 1)) * 100}%;background:${P.sang}"></div></div>` +
        `<span class="sub">${moi} · ${cu} · <span style="color:${chua ? C.warn : "inherit"};font-weight:${chua ? 700 : 400}">${chua} chưa có</span></span></td></tr>`;
    }).join("");
    html = muc(CFG.tieuDe, `<div class="scroll"><table><thead><tr><th>Chuyên đề</th><th class="r">Giá trị</th><th>Tiến độ</th><th>Thay đổi</th><th>Diễn biến</th><th>Độ đầy đủ số liệu</th></tr></thead><tbody>${tqRows}</tbody></table></div>`,
      chu([{ n: "Có số liệu từ " + TEN_KY_MOI, c: P.xanh }, { n: "Chỉ có kỳ cũ", c: P.sang }, { n: "Chưa có", c: C.track }]));
  } else if (L === "bang_dm") {
    const ds = Object.values(CS).sort((a, b) => a.ttc - b.ttc);
    const cds = [...new Set(ds.map((o) => o.cd))];
    html = muc(`Danh mục chỉ số (${ds.length})`, `<div class="scroll"><table><thead><tr><th>Chỉ số</th><th>Chuyên đề</th><th class="r">Giá trị mới nhất</th><th>Kỳ</th><th class="r">Số kỳ</th><th>Đầu mối</th><th>Nguồn</th></tr></thead><tbody>${ds.map((o) =>
      `<tr data-q="${esc((o.ma + " " + o.ten + " " + (o.dm || "")).toLowerCase())}" data-cd="${esc(o.cd)}"><td>${esc(o.ten)}<span class="sub">${esc(o.ma)}</span></td><td class="nw" style="font-size:12px;color:${P.mo}">${esc(String(o.cd || "").replace(/^\d+\.\s*/, ""))}</td>` +
      `<td class="r nw">${giaTriO(o)}</td><td class="nw" style="font-size:12px">${o.m ? esc(o.m.ky) : ""}</td><td class="r" style="font-weight:650;color:${o.pts.length === 1 ? C.warn : P.mo}">${o.pts.length}</td>` +
      `<td style="font-size:12px">${esc(o.dm || "")}</td><td style="font-size:11px;color:${P.mo}">${o.m ? esc(o.m.nguon || "") : ""}</td></tr>`).join("")}</tbody></table></div>`,
      `<div class="tool"><input type="search" placeholder="Tìm chỉ số, đầu mối" class="q"><select class="cd"><option value="">Tất cả chuyên đề</option>${cds.map((c) => `<option>${esc(c)}</option>`).join("")}</select></div>`);
  }

  rootEl.innerHTML = `<div id="${wrapId}">${css}${html}</div>`;
  const wrapEl = document.getElementById(wrapId);
  sau.forEach((f) => { try { f(wrapEl); } catch (e) { if (window.console) console.error("nq57", CFG.key, e); } });

  // lọc bảng danh mục
  const onInput = () => {
    const q = (wrapEl.querySelector(".q") || {}).value || "", cd = (wrapEl.querySelector(".cd") || {}).value || "";
    let n = 0;
    wrapEl.querySelectorAll("tr[data-q]").forEach((tr) => { const ok = (!q || tr.getAttribute("data-q").includes(q.toLowerCase())) && (!cd || tr.getAttribute("data-cd") === cd); tr.style.display = ok ? "" : "none"; n += ok ? 1 : 0; });
    const t = wrapEl.querySelector(".muc-t"); if (t) t.textContent = `Danh mục chỉ số (${n})`;
  };
  wrapEl.addEventListener("input", onInput);
  wrapEl.addEventListener("change", onInput);

  // ============ 7. RESPONSIVE + CLEANUP ============
  let ro = null;
  if (typeof ResizeObserver !== "undefined") {
    ro = new ResizeObserver(() => inst.forEach((c) => { try { c.resize(); } catch (e) {} }));
    ro.observe(wrapEl);
  }
  rootEl.__nq57Cleanup = function () {
    if (ro) ro.disconnect();
    wrapEl.removeEventListener("input", onInput);
    wrapEl.removeEventListener("change", onInput);
    inst.forEach((c) => { try { c.dispose(); } catch (e) {} });
  };
  return {};
};
