import { useEffect, useMemo, useRef, useState } from "react";

/* =========================================================================
   IOC Bộ Tư pháp – bản web (màn hình 16:9), các lĩnh vực trọng tâm
   Ba lớp thông tin: Lớp 1 = Tổng quan 6 thẻ lĩnh vực · Lớp 2 = trang chỉ số từng lĩnh vực (và thống kê chi tiết theo nguồn giao)
   · Lớp 3 = danh sách chi tiết có tìm kiếm, lọc, sắp xếp, phân trang; bấm một dòng để xem đủ thông tin bản ghi.
   Thiết kế theo khung dashboard Nghị quyết 57: nền trắng, header xanh thương hiệu có vạch vàng,
   thanh chọn trang, hàng 4–5 thẻ KPI, lưới biểu đồ bên trái (7/12) và bảng có thẻ chọn bên phải (5/12).
   Khung cố định 1920×1080 tự co giãn vừa màn hình. Biểu đồ là SVG tự vẽ, không dùng thư viện.

   Sáu lĩnh vực trọng tâm = 6 phân hệ trang Tổng quan của IOC bản di động:
     Nhiệm vụ Trung ương giao · Xây dựng pháp luật · Phản ánh, kiến nghị về VBQPPL ·
     Thi hành án dân sự · Giải quyết TTHC · Giải ngân vốn đầu tư công
   Toàn bộ số liệu là DỮ LIỆU MẪU lấy nguyên từ IOC bản di động; khi có API thay các hằng số dữ liệu bên dưới.
   Màu trạng thái giữ chuẩn 5S của IOC: Hoàn thành #12B76A · Trong hạn #2E90FA · Theo dõi #F79009 · Quá hạn #F04438.
   ========================================================================= */

/* CSS Tailwind đã biên dịch sẵn (dùng chung bộ lớp với NQ57), phạm vi trong .iocw */
const TAILWIND_CSS = ".iocw,.iocw *,.iocw :after,.iocw :before{box-sizing:border-box;border-width:0;border-style:solid;border-color:#E2E8F0}.iocw{line-height:1.5;-webkit-text-size-adjust:100%;font-feature-settings:\"tnum\";font-weight:500;-webkit-font-smoothing:auto;-moz-osx-font-smoothing:auto;text-rendering:optimizeLegibility}.iocw h1,.iocw h2,.iocw h3,.iocw p,.iocw ul,.iocw li,.iocw dl,.iocw dd{margin:0;padding:0;list-style:none}.iocw button,.iocw input,.iocw select{font:inherit;color:inherit;margin:0}.iocw button{background:transparent;padding:0;cursor:pointer;text-align:inherit}.iocw table{border-collapse:collapse;text-indent:0;border-color:inherit}.iocw th{text-align:inherit;font-weight:inherit}.iocw svg{display:block;font-weight:500}.iocw b{font-weight:800}.iocw input[type=search]{-webkit-appearance:none;appearance:none}.iocw,.iocw *,.iocw :after,.iocw :before{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59,130,246,.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }.iocw .pointer-events-none{pointer-events:none}.iocw .fixed{position:fixed}.iocw .absolute{position:absolute}.iocw .relative{position:relative}.iocw .sticky{position:sticky}.iocw .inset-0{inset:0}.iocw .inset-y-0{top:0;bottom:0}.iocw .left-0{left:0}.iocw .top-0{top:0}.iocw .top-1{top:.25rem}.iocw .z-10{z-index:10}.iocw .col-span-2{grid-column:span 2/span 2}.iocw .col-span-4{grid-column:span 4/span 4}.iocw .col-span-5{grid-column:span 5/span 5}.iocw .col-span-7{grid-column:span 7/span 7}.iocw .col-span-8{grid-column:span 8/span 8}.iocw .mb-0\\.5{margin-bottom:.125rem}.iocw .mb-2{margin-bottom:.5rem}.iocw .ml-1{margin-left:.25rem}.iocw .ml-auto{margin-left:auto}.iocw .mt-0\\.5{margin-top:.125rem}.iocw .mt-1{margin-top:.25rem}.iocw .mt-2\\.5{margin-top:.625rem}.iocw .mt-3{margin-top:.75rem}.iocw .line-clamp-2{overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:2}.iocw .block{display:block}.iocw .inline-block{display:inline-block}.iocw .flex{display:flex}.iocw .inline-flex{display:inline-flex}.iocw .table{display:table}.iocw .grid{display:grid}.iocw .h-0\\.5{height:.125rem}.iocw .h-11{height:2.75rem}.iocw .h-2{height:.5rem}.iocw .h-2\\.5{height:.625rem}.iocw .h-3{height:.75rem}.iocw .h-\\[156px\\]{height:156px}.iocw .h-\\[64px\\]{height:64px}.iocw .h-full{height:100%}.iocw .min-h-0{min-height:0}.iocw .w-10{width:2.5rem}.iocw .w-12{width:3rem}.iocw .w-14{width:3.5rem}.iocw .w-2{width:.5rem}.iocw .w-2\\.5{width:.625rem}.iocw .w-40{width:10rem}.iocw .w-44{width:11rem}.iocw .w-5{width:1.25rem}.iocw .w-80{width:20rem}.iocw .w-full{width:100%}.iocw .min-w-0{min-width:0}.iocw .max-w-\\[340px\\]{max-width:340px}.iocw .flex-1{flex:1 1 0%}.iocw .flex-none{flex:none}.iocw .shrink-0{flex-shrink:0}.iocw .-rotate-90{--tw-rotate:-90deg}.iocw .-rotate-90,.iocw .transform{transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}.iocw .cursor-pointer{cursor:pointer}.iocw .resize{resize:both}.iocw .grid-cols-12{grid-template-columns:repeat(12,minmax(0,1fr))}.iocw .grid-cols-4{grid-template-columns:repeat(4,minmax(0,1fr))}.iocw .grid-cols-5{grid-template-columns:repeat(5,minmax(0,1fr))}.iocw .grid-rows-2{grid-template-rows:repeat(2,minmax(0,1fr))}.iocw .flex-col{flex-direction:column}.iocw .flex-wrap{flex-wrap:wrap}.iocw .items-end{align-items:flex-end}.iocw .items-center{align-items:center}.iocw .items-baseline{align-items:baseline}.iocw .justify-start{justify-content:flex-start}.iocw .justify-center{justify-content:center}.iocw .justify-between{justify-content:space-between}.iocw .justify-around{justify-content:space-around}.iocw .gap-1{gap:.25rem}.iocw .gap-1\\.5{gap:.375rem}.iocw .gap-10{gap:2.5rem}.iocw .gap-2{gap:.5rem}.iocw .gap-2\\.5{gap:.625rem}.iocw .gap-3{gap:.75rem}.iocw .gap-4{gap:1rem}.iocw .gap-5{gap:1.25rem}.iocw .gap-8{gap:2rem}.iocw .gap-x-10{-moz-column-gap:2.5rem;column-gap:2.5rem}.iocw .gap-x-5{-moz-column-gap:1.25rem;column-gap:1.25rem}.iocw .gap-y-1{row-gap:.25rem}.iocw .gap-y-5{row-gap:1.25rem}.iocw :is(.space-y-2>:not([hidden])~:not([hidden])){--tw-space-y-reverse:0;margin-top:calc(.5rem*(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.5rem*var(--tw-space-y-reverse))}.iocw .overflow-auto{overflow:auto}.iocw .overflow-hidden{overflow:hidden}.iocw .truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.iocw .whitespace-nowrap{white-space:nowrap}.iocw .rounded-2xl{border-radius:1rem}.iocw .rounded-full{border-radius:9999px}.iocw .rounded-lg{border-radius:.5rem}.iocw .rounded-md{border-radius:.375rem}.iocw .rounded-sm{border-radius:.125rem}.iocw .rounded-xl{border-radius:.75rem}.iocw .border{border-width:1px}.iocw .border-b{border-bottom-width:1px}.iocw .border-t-2{border-top-width:2px}.iocw .border-dashed{border-style:dashed}.iocw .border-\\[\\#D9DEE7\\]{--tw-border-opacity:1;border-color:rgb(217 222 231/var(--tw-border-opacity,1))}.iocw .border-\\[\\#E4E7EC\\]{--tw-border-opacity:1;border-color:rgb(228 231 236/var(--tw-border-opacity,1))}.iocw .bg-\\[\\#E4E7EC\\]{--tw-bg-opacity:1;background-color:rgb(228 231 236/var(--tw-bg-opacity,1))}.iocw .bg-white{--tw-bg-opacity:1;background-color:rgb(255 255 255/var(--tw-bg-opacity,1))}.iocw .p-0\\.5{padding:.125rem}.iocw .px-10{padding-left:2.5rem;padding-right:2.5rem}.iocw .px-2{padding-left:.5rem;padding-right:.5rem}.iocw .px-3{padding-left:.75rem;padding-right:.75rem}.iocw .px-5{padding-left:1.25rem;padding-right:1.25rem}.iocw .px-8{padding-left:2rem;padding-right:2rem}.iocw .py-0\\.5{padding-top:.125rem;padding-bottom:.125rem}.iocw .py-1{padding-top:.25rem;padding-bottom:.25rem}.iocw .py-1\\.5{padding-top:.375rem;padding-bottom:.375rem}.iocw .py-2{padding-top:.5rem;padding-bottom:.5rem}.iocw .py-2\\.5{padding-top:.625rem;padding-bottom:.625rem}.iocw .py-4{padding-top:1rem;padding-bottom:1rem}.iocw .py-5{padding-top:1.25rem;padding-bottom:1.25rem}.iocw .pl-2{padding-left:.5rem}.iocw .pt-1{padding-top:.25rem}.iocw .pt-3{padding-top:.75rem}.iocw .text-left{text-align:left}.iocw .text-right{text-align:right}.iocw .align-top{vertical-align:top}.iocw .align-middle{vertical-align:middle}.iocw .text-\\[13px\\]{font-size:13px}.iocw .text-\\[14px\\]{font-size:14px}.iocw .text-\\[15px\\]{font-size:15px}.iocw .text-\\[17px\\]{font-size:17px}.iocw .text-\\[24px\\]{font-size:24px}.iocw .text-\\[40px\\]{font-size:40px}.iocw .text-base{font-size:1rem;line-height:1.5rem}.iocw .text-sm{font-size:.875rem;line-height:1.25rem}.iocw .text-xs{font-size:.75rem;line-height:1rem}.iocw .font-bold{font-weight:700}.iocw .font-medium{font-weight:500}.iocw .font-normal{font-weight:400}.iocw .font-semibold{font-weight:600}.iocw .uppercase{text-transform:uppercase}.iocw .italic{font-style:italic}.iocw .tabular-nums{--tw-numeric-spacing:tabular-nums;font-variant-numeric:var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)}.iocw .leading-none{line-height:1}.iocw .leading-tight{line-height:1.25}.iocw .tracking-wide{letter-spacing:.025em}.iocw .text-\\[\\#101828\\]{--tw-text-opacity:1;color:rgb(16 24 40/var(--tw-text-opacity,1))}.iocw .text-\\[\\#344054\\]{--tw-text-opacity:1;color:rgb(52 64 84/var(--tw-text-opacity,1))}.iocw .text-\\[\\#475467\\]{--tw-text-opacity:1;color:rgb(71 84 103/var(--tw-text-opacity,1))}.iocw .text-\\[\\#667085\\]{--tw-text-opacity:1;color:rgb(102 112 133/var(--tw-text-opacity,1))}.iocw .text-\\[\\#98A2B3\\]{--tw-text-opacity:1;color:rgb(152 162 179/var(--tw-text-opacity,1))}.iocw .text-white{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.iocw .shadow-lg{--tw-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -4px rgba(0,0,0,.1);--tw-shadow-colored:0 10px 15px -3px var(--tw-shadow-color),0 4px 6px -4px var(--tw-shadow-color)}.iocw .shadow-lg,.iocw .shadow-sm{box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.iocw .shadow-sm{--tw-shadow:0 1px 2px 0 rgba(0,0,0,.05);--tw-shadow-colored:0 1px 2px 0 var(--tw-shadow-color)}.iocw .filter{filter:var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)}.iocw .transition-colors{transition-property:color,background-color,border-color,text-decoration-color,fill,stroke;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.iocw .transition-shadow{transition-property:box-shadow;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.iocw .hover\\:bg-\\[\\#E4E7EC\\]:hover{--tw-bg-opacity:1;background-color:rgb(228 231 236/var(--tw-bg-opacity,1))}.iocw .hover\\:bg-\\[\\#FAFBFC\\]:hover{--tw-bg-opacity:1;background-color:rgb(250 251 252/var(--tw-bg-opacity,1))}.iocw .hover\\:text-\\[\\#101828\\]:hover{--tw-text-opacity:1;color:rgb(16 24 40/var(--tw-text-opacity,1))}.iocw .hover\\:shadow-xl:hover{--tw-shadow:0 20px 25px -5px rgba(0,0,0,.1),0 8px 10px -6px rgba(0,0,0,.1);--tw-shadow-colored:0 20px 25px -5px var(--tw-shadow-color),0 8px 10px -6px var(--tw-shadow-color);box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.iocw .focus\\:border-\\[\\#1D6FE8\\]:focus{--tw-border-opacity:1;border-color:rgb(29 111 232/var(--tw-border-opacity,1))}.iocw .focus\\:outline-none:focus{outline:2px solid transparent;outline-offset:2px}.iocw .focus-visible\\:underline:focus-visible{text-decoration-line:underline}.iocw .focus-visible\\:ring-2:focus-visible{--tw-ring-offset-shadow:var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow,0 0 #0000)}.iocw .focus-visible\\:ring-\\[\\#1D6FE8\\]:focus-visible{--tw-ring-opacity:1;--tw-ring-color:rgb(29 111 232/var(--tw-ring-opacity,1))}.iocw .font-medium{font-weight:600}.iocw .font-semibold{font-weight:700}.iocw .font-bold{font-weight:800}.iocw .text-xs{font-size:13px;line-height:1.4}.iocw .text-sm{font-size:15px;line-height:1.45}.iocw .w-56{width:14rem}.iocw :is(.space-y-1>:not([hidden])~:not([hidden])){margin-top:.25rem}.iocw .mr-2{margin-right:.5rem}.iocw .col-span-6{grid-column:span 6/span 6}.iocw .pr-2{padding-right:.5rem}.iocw .pt-2{padding-top:.5rem}.iocw .mb-1{margin-bottom:.25rem}.iocw .w-20{width:5rem}.iocw .gap-6{gap:1.5rem}.iocw .gap-x-3{column-gap:.75rem}.iocw .grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.iocw .grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}.iocw .h-5{height:1.25rem}.iocw .hover\\:shadow-lg:hover{box-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -4px rgba(0,0,0,.1)}.iocw .hover\\:underline:hover{text-decoration-line:underline}.iocw .items-start{align-items:flex-start}.iocw .justify-end{justify-content:flex-end}.iocw .mr-auto{margin-right:auto}.iocw .mt-1\\.5{margin-top:.375rem}.iocw .px-4{padding-left:1rem;padding-right:1rem}.iocw .py-3{padding-top:.75rem;padding-bottom:.75rem}.iocw .py-6{padding-top:1.5rem;padding-bottom:1.5rem}.iocw .text-\\[20px\\]{font-size:20px}.iocw .text-center{text-align:center}.iocw .w-11{width:2.75rem}.iocw .w-3{width:.75rem}.iocw .h-11{height:2.75rem}";

const LOGO_BTP = "data:image/png;base64,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";

/* ---------- Bảng màu: giữ đúng hệ màu NQ57 + màu trạng thái 5S của IOC ---------- */
const P = { navy: "#101828", xanh: "#1D6FE8", sang: "#7FB1F6", nhat: "#EEF4FF", ink2: "#344054", mo: "#475467", vien: "#D9DEE7", c1: "#163C8E" };
const C = { tot: "#12B76A", xau: "#F04438", trung: "#98A2B3", warn: "#F79009", grid: "#E4E7EC", track: "#DDE2EA", info: "#2E90FA", tx: "#98A2B3" };
const NEN = { tot: "#ECFDF3", xau: "#FEF1F0", trung: "#E4E7EC", warn: "#FFF6E8" };
const THUONG_HIEU = "#1D6FE8";
const ACC = P.xanh;
const W0 = 1920, H0 = 1080;
const FONT_APPLE = '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", "Segoe UI", Roboto, Arial, sans-serif';

/* ---------- Định dạng số ---------- */
const so = (v, d = 0) => new Intl.NumberFormat("vi-VN", { maximumFractionDigits: d }).format(v);
const soTuDong = (v) => so(v, Number.isInteger(v) ? 0 : Math.abs(v) >= 100 ? 1 : 2);
const gon = (v) => (Math.abs(v) >= 1e6 ? so(v / 1e6, Math.abs(v) >= 1e7 ? 1 : 2) + " triệu" : soTuDong(v));
const pt = (v, d = 1) => so(v, d) + "%";
const ty = (trieu) => so(trieu / 1000, 1);            /* triệu đồng → tỷ đồng */
const tyLe = (a, b) => (b ? (a / b) * 100 : 0);
const NGAY_CHOT = new Date(2026, 10, 9);               /* mốc tính số ngày quá hạn: ngày cập nhật số liệu 09/11/2026 */
const parseVN = (d) => { const [dd, mm, yy] = d.split("/").map(Number); return new Date(yy, mm - 1, dd); };
const treHan = (d) => Math.round((NGAY_CHOT - parseVN(d)) / 864e5);
const dauDiem = (d) => (d > 0 ? "+" : d < 0 ? "−" : "") + so(Math.abs(d), 1) + " điểm";

/* Chia một số nguyên theo trọng số, tổng luôn khớp (lấy từ IOC) */
const allocate = (total, weights) => {
  const W = weights.reduce((a, b) => a + b, 0) || 1;
  const raw = weights.map((w) => (total * w) / W);
  const base = raw.map(Math.floor);
  let rest = total - base.reduce((a, b) => a + b, 0);
  raw.map((v, i) => [v - Math.floor(v), i]).sort((a, b) => b[0] - a[0]).forEach(([, i]) => { if (rest > 0) { base[i]++; rest--; } });
  return base;
};
const seeded = (key) => {
  let h = 2166136261;
  for (const ch of key) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
  return (i) => { let t = (h + Math.imul(i + 1, 0x6D2B79F5)) >>> 0; t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
};


/* =========================================================================
   DỮ LIỆU – số tổng theo ảnh màn hình IOC (cập nhật 09/11/2026); bản ghi chi tiết (lớp 3) là DỮ LIỆU MẪU
   sinh có điều kiện để khớp đúng số tổng, xen các bản ghi thật đã có trong ảnh và văn bản nguồn.
   Khi tích hợp: thay các hàm sinh *_DS bằng dữ liệu tải từ API của từng hệ thống.
   ========================================================================= */
const fmtD = (d) => `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
const congNgay = (d, n) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
const HOM_NAY = NGAY_CHOT;
const chon = (r, arr, k) => arr[Math.floor(r(k) * arr.length) % arr.length];
/* Phân bổ trạng thái vào nhóm: rút không hoàn lại theo trọng số – tổng theo nhóm và theo trạng thái đều khớp */
function phanBo(nhom, dem, key) {
  const r = seeded(key), con = { ...dem }, ks = Object.keys(dem), out = [];
  let z = 0;
  nhom.forEach((g, gi) => {
    const uu = Object.fromEntries(ks.map((s, si) => [s, 0.35 + r(gi * 17 + si) * 1.3]));
    for (let i = 0; i < g.n; i++) {
      const co = ks.filter((s) => con[s] > 0), w = co.map((s) => con[s] * uu[s]);
      let x = r(5000 + z++) * w.reduce((a, b) => a + b, 0), k = 0;
      while (k < co.length - 1 && x >= w[k]) { x -= w[k]; k++; }
      con[co[k]]--; out.push([g, co[k]]);
    }
  });
  return out;
}
const HO_TEN = ["Nguyễn Văn An", "Trần Thị Bình", "Lê Minh Châu", "Phạm Thu Hà", "Hoàng Đức Hùng", "Vũ Thị Lan", "Đặng Quốc Minh", "Bùi Thanh Nga", "Đỗ Hải Phương", "Ngô Thị Thảo", "Vũ Thị Thảo", "Trịnh Văn Sơn"];

/* ---------- Trạng thái nhiệm vụ: nhãn, màu chữ, màu nền, nhóm ở lớp 1 ---------- */
const TT_NV = {
  htdh: ["HT đúng hạn", "#067647", NEN.tot, "done"],
  htqh: ["HT quá hạn", "#C4320A", "#FFF4ED", "done"],
  th: ["Chưa HT trong hạn", "#175CD3", "#EFF8FF", "th"],
  txc: ["TX đã báo cáo", "#0E7C6B", "#E6F6F4", "th"],
  txk: ["TX chưa báo cáo", "#475467", "#F2F4F7", "th"],
  gh: ["Chưa HT gần hạn", "#B54708", "#FFFAEB", "gh"],
  qh: ["Chưa HT quá hạn", "#B42318", NEN.xau, "qh"],
};
const NHOM_TT = { done: ["Đã hoàn thành", C.tot], th: ["Chưa HT trong hạn", C.info], gh: ["Chưa HT gần hạn", C.warn], qh: ["Chưa HT quá hạn", C.xau] };
const NHOM_KEYS = Object.keys(NHOM_TT);

/* =============== 1. NHIỆM VỤ TRUNG ƯƠNG GIAO (HT Văn bản điều hành Bộ và HT theo dõi nhiệm vụ TW) =============== */
const NV_NGUON = [
  { id: "bct", ten: "Bộ Chính trị, Ban Bí thư", ngan: "Bộ Chính trị, BBT",
    tt: { htdh: 20, htqh: 226, th: 41, txc: 35, txk: 141, gh: 0, qh: 2 },
    nhom: [["Nghị quyết 57", 204, "57-NQ/TW", "Nghị quyết 57-NQ/TW về đột phá phát triển khoa học, công nghệ, đổi mới sáng tạo và chuyển đổi số quốc gia"],
      ["Nghị quyết 66", 62, "140/NQ-CP", "Nghị quyết 66-NQ/TW về đổi mới công tác xây dựng và thi hành pháp luật"],
      ["Nghị quyết 71", 29, "281/NQ-CP", "Nghị quyết 71-NQ/TW về đột phá phát triển giáo dục và đào tạo"],
      ["Nghị quyết 79", 25, "29/NQ-CP", "Nghị quyết 79-NQ/TW về phát triển kinh tế nhà nước"],
      ["Nghị quyết 59", 18, "59-NQ/TW", "Nghị quyết 59-NQ/TW về hội nhập quốc tế trong tình hình mới"],
      ["Nghị quyết 11", 17, "11-NQ/TW", "Nghị quyết 11-NQ/TW"], ["Nghị quyết 80", 16, "30/NQ-CP", "Nghị quyết 80-NQ/TW về phát triển văn hóa Việt Nam"],
      ["Nghị quyết 68", 16, "68-NQ/TW", "Nghị quyết 68-NQ/TW về phát triển kinh tế tư nhân"], ["Nghị quyết 70", 8, "70-NQ/TW", "Nghị quyết 70-NQ/TW về bảo đảm an ninh năng lượng quốc gia"],
      ["Nghị quyết 72", 8, "282/NQ-CP", "Nghị quyết 72-NQ/TW về tăng cường bảo vệ, chăm sóc và nâng cao sức khỏe nhân dân"],
      ["Nghị quyết ĐH 14", 4, "NQ ĐH XIV", "Nghị quyết Đại hội đại biểu toàn quốc lần thứ XIV của Đảng"], ["Văn bản khác", 58, "TB/VPTW", "Kết luận, thông báo của Bộ Chính trị, Ban Bí thư"]] },
  { id: "cp", ten: "Chính phủ, Thủ tướng Chính phủ", ngan: "Chính phủ, TTg",
    tt: { htdh: 250, htqh: 74, th: 120, txc: 10, txk: 22, gh: 9, qh: 7 },
    nhom: [["Thông báo kết luận", 184, "TB-VPCP", "Thông báo kết luận của Thủ tướng, Phó Thủ tướng"], ["Nghị quyết phiên họp", 105, "NQ-CP", "Nghị quyết phiên họp Chính phủ thường kỳ"],
      ["Văn bản khác", 82, "VPCP-PL", "Công văn chỉ đạo của Văn phòng Chính phủ"], ["Chỉ thị TTg", 68, "CT-TTg", "Chỉ thị của Thủ tướng Chính phủ"], ["Công điện TTg", 53, "CĐ-TTg", "Công điện của Thủ tướng Chính phủ"]] },
];
const NV_BCD57 = { tong: 289, done: 183, th: 106 };
const DV_BO = ["Cục Hành chính tư pháp", "Cục Quản lý thi hành án dân sự", "Cục Bổ trợ tư pháp", "Cục Công nghệ thông tin", "Cục Kiểm tra văn bản và Tổ chức thi hành pháp luật", "Cục Pháp luật dân sự – kinh tế",
  "Cục Pháp luật hình sự – hành chính", "Cục Kế hoạch – Tài chính", "Văn phòng Bộ", "Vụ Tổ chức cán bộ", "Cục Phổ biến, giáo dục pháp luật và Trợ giúp pháp lý", "Viện Chiến lược và Khoa học pháp lý"];
const VERB_BCT = ["Quán triệt, triển khai thực hiện", "Xây dựng kế hoạch thực hiện", "Rà soát, đề xuất hoàn thiện thể chế theo", "Báo cáo sơ kết việc thực hiện", "Tổ chức tuyên truyền, phổ biến", "Thể chế hóa chủ trương tại"];
const VERB_CP = ["Xây dựng đề án", "Báo cáo kết quả thực hiện", "Rà soát, đề xuất sửa đổi", "Hướng dẫn triển khai", "Tổng kết thi hành", "Đề xuất phương án xử lý vướng mắc về"];
const OBJ_CP = ["Luật Hộ tịch", "Luật Trợ giúp pháp lý", "Luật Thi hành án dân sự", "Luật Ban hành văn bản quy phạm pháp luật", "Luật Công chứng", "Luật Đấu giá tài sản", "chuyển đổi số ngành Tư pháp", "Luật Luật sư", "Luật Xử lý vi phạm hành chính", "cơ sở dữ liệu quốc gia về pháp luật"];
const NV_THAT = [
  { nguon: "bct", nhom: "Nghị quyết 66", tt: "htqh", ma: "001_NQ66", ten: "Tham gia cùng Ban Tuyên giáo và Dân vận Trung ương tổ chức Hội nghị toàn quốc nghiên cứu, quán triệt Nghị quyết số 66-NQ/TW theo chỉ đạo của cấp có thẩm quyền", han: "31/05/2025", donVi: "Bộ Tư pháp" },
  { nguon: "bct", nhom: "Nghị quyết 72", tt: "txc", ma: "001_NQ72", ten: "Truyền thông, giáo dục, tư vấn, phổ biến kiến thức về bảo vệ, chăm sóc và nâng cao sức khỏe, tạo ý thức tự giác, chủ động trong phòng bệnh của mỗi người dân", donVi: "Bộ Tư pháp", kq: "Bộ Tư pháp đã tham gia Hội nghị toàn quốc quán triệt, triển khai Nghị quyết số 72-NQ/TW." },
  { nguon: "bct", nhom: "Nghị quyết 79", tt: "txk", ma: "001_NQ79", ten: "Quán triệt đầy đủ, sâu sắc tới toàn thể công chức, viên chức, người lao động về quan điểm, chủ trương của Đảng đối với phát triển kinh tế nhà nước", donVi: "Bộ Tư pháp", kq: "Viện Chiến lược và Khoa học pháp lý đã quán triệt, phổ biến nội dung của Nghị quyết số 79-NQ/TW tại buổi họp chi bộ ngày 3/4/2026." },
  { nguon: "bct", nhom: "Nghị quyết 80", tt: "txk", ma: "001_NQ80", ten: "Quán triệt, nhận thức đầy đủ, sâu sắc và toàn diện về vai trò nền tảng, sức mạnh nội sinh và động lực đột phá của văn hóa trong phát triển đất nước", donVi: "Bộ Tư pháp", kq: "Đảng ủy Bộ Tư pháp đã chỉ đạo các chi bộ, đảng ủy cử thành phần tham dự Hội nghị toàn quốc quán triệt, triển khai thực hiện các Nghị quyết của Bộ Chính trị." },
  { nguon: "bct", nhom: "Nghị quyết 71", tt: "htqh", ma: "002_NQ71", ten: "Xây dựng, ban hành và chỉ đạo thực hiện Kế hoạch thực hiện Chương trình hành động của Chính phủ thực hiện Nghị quyết số 71-NQ/TW", han: "31/12/2025", donVi: "Bộ Tư pháp" },
  { nguon: "bct", nhom: "Nghị quyết 72", tt: "txc", ma: "002_NQ72", ten: "Lồng ghép và ưu tiên các chỉ tiêu về bảo vệ, chăm sóc và nâng cao sức khỏe nhân dân trong các chiến lược, kế hoạch của ngành", donVi: "Bộ Tư pháp", kq: "Nhiệm vụ không thuộc chức năng, nhiệm vụ của Bộ Tư pháp." },
  { nguon: "bct", nhom: "Nghị quyết 80", tt: "qh", ten: "Rà soát, nghiên cứu, sửa đổi, bổ sung các văn bản pháp luật liên quan về chính sách ưu đãi đầu tư, chính sách hỗ trợ về thuế, đất đai, đấu thầu, dữ liệu, cơ chế tài chính, cơ chế khuyến khích sáng tạo trong các luật chuyên ngành", vb: "30/NQ-CP", han: "30/09/2026", donVi: "Cục Pháp luật dân sự – kinh tế" },
  { nguon: "bct", nhom: "Nghị quyết 80", tt: "qh", ten: "Xây dựng Đề án “Văn hóa trong tuân thủ luật pháp”", vb: "30/NQ-CP", han: "30/10/2026", donVi: "Cục Phổ biến, giáo dục pháp luật và Trợ giúp pháp lý" },
  { nguon: "cp", nhom: "Văn bản khác", tt: "qh", ten: "Kết nối Hệ thống thông tin giải quyết TTHC với các CSDL đã công bố và các CSDL mới hoàn thành; tự động điền, xác thực và tái sử dụng dữ liệu", vb: "88/QĐ-BCĐCP", han: "30/08/2026", donVi: "Cục Công nghệ thông tin" },
  { nguon: "cp", nhom: "Văn bản khác", tt: "qh", ten: "Chủ trì, phối hợp với Bộ Công an và các bộ, cơ quan ngang bộ rà soát các TTHC trong danh mục kèm theo Văn bản số 3666/BCA-C12 ngày 16/7/2026, thống nhất danh mục TTHC và thành phần hồ sơ", vb: "7795/VPCP-CĐS", han: "30/09/2026", donVi: "Cục Kiểm soát thủ tục hành chính" },
];
const NV_DS = (() => {
  const out = [];
  NV_NGUON.forEach((ng) => {
    const r = seeded("nv|" + ng.id);
    const slots = phanBo(ng.nhom.map(([ten, n, vb, day]) => ({ ten, n, vb, day })), ng.tt, "pb|" + ng.id);
    const k = {};
    slots.forEach(([g, tt], i) => {
      k[g.ten] = (k[g.ten] || 0) + 1;
      const ma = ng.id === "bct" ? `${String(k[g.ten]).padStart(3, "0")}_${g.ten.replace(/^Nghị quyết\s*/, "NQ").replace(/\s/g, "").replace("Vănbảnkhác", "VBK")}` : `CP-2026-${String(i + 1).padStart(4, "0")}`;
      const no = 100 + Math.floor(r(i * 11 + 1) * 3800);
      const vb = ng.id === "bct" ? (g.vb === "TB/VPTW" ? `${no}-TB/VPTW` : g.vb) : `${no}/${g.vb}`;
      const ten = ng.id === "bct" ? `${chon(r, VERB_BCT, i * 11 + 2)} ${g.day}, nội dung ${k[g.ten]}` : `${chon(r, VERB_CP, i * 11 + 2)} ${chon(r, OBJ_CP, i * 11 + 3)}`;
      let han = null, ht = null, giao;
      const lui = (a, b) => congNgay(HOM_NAY, -(a + Math.floor(r(i * 11 + 4) * b)));
      if (tt === "htdh") { han = lui(5, 280); ht = congNgay(han, -(1 + Math.floor(r(i * 11 + 5) * 12))); }
      else if (tt === "htqh") { han = lui(40, 320); ht = congNgay(han, 3 + Math.floor(r(i * 11 + 5) * 40)); if (ht > HOM_NAY) ht = congNgay(HOM_NAY, -1); }
      else if (tt === "th") han = congNgay(HOM_NAY, 10 + Math.floor(r(i * 11 + 4) * 200));
      else if (tt === "gh") han = congNgay(HOM_NAY, 1 + Math.floor(r(i * 11 + 4) * 7));
      else if (tt === "qh") han = lui(3, 70);
      giao = han ? congNgay(han, -(30 + Math.floor(r(i * 11 + 6) * 150))) : lui(10, 300);
      out.push({ ma, nguon: ng.ten, nguonId: ng.id, nhom: g.ten, ten, vb, donVi: chon(r, DV_BO, i * 11 + 7), han: han ? fmtD(han) : "Thường xuyên",
        giao: fmtD(giao), ngayHT: ht ? fmtD(ht) : "", tt, ttTen: TT_NV[tt][0], ttNhom: NHOM_TT[TT_NV[tt][3]][0], nhomKey: TT_NV[tt][3],
        kq: tt === "htdh" || tt === "htqh" ? `Đã hoàn thành, báo cáo kết quả gửi ${ng.id === "bct" ? "Văn phòng Trung ương Đảng" : "Văn phòng Chính phủ"}` : tt === "txc" ? "Đã báo cáo kết quả thực hiện định kỳ" : "" });
    });
  });
  NV_THAT.forEach((t) => {
    const ng = NV_NGUON.find((x) => x.id === t.nguon);
    let j = out.findIndex((x) => !x.that && x.nguonId === t.nguon && x.nhom === t.nhom && x.tt === t.tt);
    if (j < 0) j = out.findIndex((x) => !x.that && x.nguonId === t.nguon && x.tt === t.tt);
    if (j < 0) return;
    const g = ng.nhom.find((x) => x[0] === t.nhom);
    const maMoi = t.ma || (t.nguon === "bct" ? `${String(900 + j % 99).padStart(3, "0")}_${t.nhom.replace(/^Nghị quyết\s*/, "NQ").replace(/\s/g, "")}` : out[j].ma);
    out[j] = { ...out[j], ...t, that: true, nhom: t.nhom, ma: maMoi, vb: t.vb || (g ? g[2] : out[j].vb), han: t.han || out[j].han, kq: t.kq ?? out[j].kq, nguon: ng.ten, nguonId: ng.id };
  });
  return [...out.filter((x) => x.that), ...out.filter((x) => !x.that)].map((x, i) => ({ ...x, stt: i + 1, tre: x.han && x.han !== "Thường xuyên" && x.nhomKey === "qh" ? treHan(x.han) : 0 }));
})();
const demTheo = (ds, f, keys) => Object.fromEntries(keys.map((k) => [k, ds.filter((x) => f(x) === k).length]));
const NV_NHOM_DEM = demTheo(NV_DS, (x) => x.nhomKey, NHOM_KEYS);
const NV_TONG = NV_DS.length;
const THANG_2026 = ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11"];
const theoThang = (ds, ngayCua) => THANG_2026.map((_, m) => ds.filter((x) => { const d = ngayCua(x); if (!d) return false; const p = parseVN(d); return p.getFullYear() === 2026 && p.getMonth() === m; }));

/* =============== 1b. NHIỆM VỤ LÃNH ĐẠO BỘ GIAO =============== */
const LDB_TT = { htdh: ["HT đúng hạn", "#067647", NEN.tot], htqh: ["HT quá hạn", "#C4320A", "#FFF4ED"], th: ["Chưa HT trong hạn", "#175CD3", "#EFF8FF"], gh: ["Chưa HT gần hạn", "#B54708", "#FFFAEB"], qh: ["Chưa HT quá hạn", "#B42318", NEN.xau] };
const LDB_KEYS = Object.keys(LDB_TT);
const LDB_TONG_TT = { htdh: 703, htqh: 224, th: 1308, gh: 16, qh: 9 };
/* [đơn vị, HT đúng hạn, HT quá hạn, chưa HT trong hạn, gần hạn, quá hạn] – 9 đơn vị đầu theo ảnh hệ thống, còn lại chia theo trọng số cho khớp tổng */
const LDB_DV = (() => {
  const co = [["Báo Pháp luật Việt Nam", 8, 4, 11, 0, 2], ["Cục Bổ trợ tư pháp", 27, 3, 21, 0, 0], ["Cục Công nghệ thông tin", 111, 29, 163, 3, 1], ["Cục Hành chính tư pháp", 24, 8, 50, 2, 0],
    ["Cục Hợp tác quốc tế", 0, 0, 1, 0, 0], ["Cục Kế hoạch – Tài chính", 1, 7, 31, 0, 1], ["Cục Kiểm soát thủ tục hành chính", 32, 7, 8, 0, 0], ["Cục Kiểm tra văn bản và Tổ chức thi hành pháp luật", 0, 11, 31, 1, 3],
    ["Cục Pháp luật dân sự – kinh tế", 15, 16, 67, 0, 0]];
  const them = [["Cục Pháp luật hình sự – hành chính", 9], ["Cục Quản lý thi hành án dân sự", 30], ["Cục Phổ biến, giáo dục pháp luật và Trợ giúp pháp lý", 12], ["Cục Đăng ký quốc gia giao dịch bảo đảm", 5],
    ["Thanh tra Bộ", 6], ["Văn phòng Bộ", 20], ["Vụ Tổ chức cán bộ", 8], ["Viện Chiến lược và Khoa học pháp lý", 6], ["Học viện Tư pháp", 4], ["Nhà xuất bản Tư pháp", 2]];
  const con = LDB_KEYS.map((k, j) => LDB_TONG_TT[k] - co.reduce((a, r) => a + r[j + 1], 0));
  const r = seeded("ldb-dv");
  const cot = con.map((n, j) => (j === 4 ? them.map(([t]) => (t === "Nhà xuất bản Tư pháp" || t === "Cục Quản lý thi hành án dân sự" ? 1 : 0)) : allocate(n, them.map(([, w], i) => w * (0.7 + r(i * 5 + j) * 0.6)))));
  return [...co, ...them.map(([t], i) => [t, ...cot.map((c) => c[i])])];
})();
const LDB_THAT = [
  { donVi: "Cục Hành chính tư pháp", tt: "htdh", ten: "Xây dựng dự án Luật Hộ tịch (sửa đổi)", vb: "3602/QĐ-BTP", nguoi: "Không xác định", han: "30/04/2026", phoiHop: "Văn phòng Bộ; Vụ Công tác xây dựng văn bản quy phạm pháp luật" },
  { donVi: "Cục Hành chính tư pháp", tt: "htdh", ten: "Xây dựng kế hoạch triển khai thi hành Luật; triển khai có hiệu quả kế hoạch sau khi được phê duyệt", vb: "3602/QĐ-BTP", nguoi: "Vũ Thị Thảo", han: "31/12/2026" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htqh", ten: "Xây dựng Nghị định quy định chi tiết một số điều và biện pháp thi hành Luật Thi hành án dân sự số 106/2025/QH15", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "15/04/2026", phoiHop: "Ban Pháp chế và Nghiệp vụ thi hành án dân sự" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htdh", ten: "Xây dựng Nghị định quy định về tổ chức và hoạt động của Văn phòng thi hành án dân sự, Thừa hành viên thay thế Nghị định số 08/2020/NĐ-CP ngày 08/01/2020", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "30/06/2026" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htdh", ten: "Xây dựng Nghị định quy định chi tiết và hướng dẫn thi hành một số nội dung về bảo đảm hoạt động thi hành án dân sự", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "30/06/2026" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htdh", ten: "Xây dựng các Thông tư, Thông tư liên tịch hướng dẫn biện pháp thi hành Luật", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "30/09/2026" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htdh", ten: "Xây dựng 02 Thông tư thay thế Thông tư số 05/2020/TT-BTP ngày 28/8/2020 quy định chi tiết và biện pháp thi hành một số điều của Nghị định số 62/2015/NĐ-CP", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "30/09/2026" },
  { donVi: "Cục Quản lý thi hành án dân sự", tt: "htdh", ten: "Xây dựng, phê duyệt nhiệm vụ và dự toán kinh phí sửa chữa, cải tạo, nâng cấp mở rộng trụ sở từ nguồn chi thường xuyên cho các đơn vị thuộc hệ thống thi hành án dân sự", vb: "3805/QĐ-BTP", nguoi: "Không xác định", han: "31/12/2026" },
  { donVi: "Cục Kế hoạch – Tài chính", tt: "qh", ten: "Hoàn thiện báo cáo, phương án xử lý tổng thể và hồ sơ đối với các dự án còn vướng mắc để báo cáo Ban Thường vụ Đảng ủy Bộ, Lãnh đạo Bộ trước ngày 30/8/2026", vb: "96/TB-BTP", han: "20/08/2026" },
  { donVi: "Nhà xuất bản Tư pháp", tt: "qh", ten: "Nghiên cứu, đề xuất cơ chế tài chính, nguồn kinh phí phù hợp để thực hiện đăng tải xuất bản phẩm điện tử lên Cổng Pháp luật quốc gia", vb: "68/TB-BTP", han: "30/09/2026" },
  { donVi: "Cục Công nghệ thông tin", tt: "qh", ten: "Ban hành Quyết định của Bộ trưởng công bố chức năng, tính năng, nghiệp vụ, phạm vi triển khai “Hệ thống thông tin giải quyết thủ tục hành chính các lĩnh vực thuộc phạm vi quản lý nhà nước của Bộ Tư pháp”", vb: "72/TB-BTP", han: "15/10/2026" },
];
const LDB_VERB = ["Xây dựng báo cáo", "Tham mưu văn bản chỉ đạo về", "Rà soát, hoàn thiện dự thảo về", "Tổ chức triển khai", "Chuẩn bị nội dung làm việc về", "Tổng hợp, đánh giá kết quả"];
const LDB_OBJ = ["công tác hộ tịch", "chuyển đổi số ngành Tư pháp", "thi hành án dân sự", "kiểm soát thủ tục hành chính", "rà soát văn bản quy phạm pháp luật", "Đề án 06", "an toàn thông tin mạng", "công tác cán bộ", "kế hoạch tài chính năm 2027", "phổ biến, giáo dục pháp luật", "hợp tác quốc tế về pháp luật", "đấu giá tài sản"];
const LDB_DS = (() => {
  const out = []; let i = 0;
  const r = seeded("ldb");
  LDB_DV.forEach(([dv, ...so]) => so.forEach((n, j) => {
    for (let q = 0; q < n; q++) {
      i++;
      const tt = LDB_KEYS[j];
      let han, ht = "";
      if (tt === "htdh") { const h = congNgay(HOM_NAY, -(3 + Math.floor(r(i * 7) * 280))); han = h; ht = fmtD(congNgay(h, -(1 + (i % 9)))); }
      else if (tt === "htqh") { const h = congNgay(HOM_NAY, -(20 + Math.floor(r(i * 7) * 260))); han = h; ht = fmtD(congNgay(h, 2 + (i % 25))); }
      else if (tt === "th") han = congNgay(HOM_NAY, 10 + Math.floor(r(i * 7) * 220));
      else if (tt === "gh") han = congNgay(HOM_NAY, 1 + (i % 7));
      else han = congNgay(HOM_NAY, -(5 + Math.floor(r(i * 7) * 60)));
      out.push({ donVi: dv, tt, ten: `${chon(r, LDB_VERB, i * 7 + 1)} ${chon(r, LDB_OBJ, i * 7 + 2)}`, vb: `${100 + Math.floor(r(i * 7 + 3) * 3900)}/${r(i * 7 + 4) < 0.5 ? "TB-BTP" : "QĐ-BTP"}`,
        nguoi: r(i * 7 + 5) < 0.55 ? "Không xác định" : chon(r, HO_TEN, i * 7 + 6), han: fmtD(han), ngayHT: ht, phoiHop: r(i * 7 + 8) < 0.3 ? chon(r, DV_BO, i * 7 + 9) : "",
        kq: tt === "htdh" || tt === "htqh" ? (r(i * 7 + 10) < 0.7 ? "Chưa đánh giá" : "Đạt yêu cầu") : "Đang thực hiện" });
    }
  }));
  LDB_THAT.forEach((t) => {
    const j = out.findIndex((x) => !x.that && x.donVi === t.donVi && x.tt === t.tt);
    if (j >= 0) out[j] = { ...out[j], ...t, that: true, phoiHop: t.phoiHop || "", nguoi: t.nguoi || "Không xác định", kq: t.tt.startsWith("ht") ? "Chưa đánh giá" : "Đang thực hiện" };
  });
  return [...out.filter((x) => x.that), ...out.filter((x) => !x.that)].map((x, k) => ({ ...x, stt: k + 1, ttTen: LDB_TT[x.tt][0], tre: x.tt === "qh" ? treHan(x.han) : 0 }));
})();
const LDB_TUAN = { ky: ["Tuần 41", "Tuần 42", "Tuần 43", "Tuần 44", "Tuần 45", "Tuần 46"], ton: [1102, 1148, 1296, 1302, 1318, 1333], moi: [64, 168, 22, 31, 24, 12], xong: [748, 893, 868, 865, 870, 869] };

/* =============== 2. XÂY DỰNG PHÁP LUẬT (HT quản lý chương trình xây dựng VBQPPL) =============== */
const XD_TOM = { dua: [67, 80], ctHT: [18, 67], qdct: [141, 230], tq: [152, 347], noLuat: 22, cham: 50, sapToi: 2, tyLe: 61.3 };
const CT_ST = { tq: ["Đã được thông qua/ban hành", "#067647", NEN.tot], xd: ["Đang xây dựng", "#B54708", "#FFFAEB"], ra: ["Đã đưa ra khỏi chương trình/tạm dừng", "#475467", "#F2F4F7"] };
const CT_CT = { dua: ["Đã đưa vào chương trình", "#067647", NEN.tot], de: ["Đang đề xuất đưa vào chương trình", "#B54708", "#FFFAEB"], chua: ["Chưa đề xuất đưa vào chương trình", "#B42318", NEN.xau] };
/* [tên, CQ chủ trì, hạn trình CP, dự kiến hiệu lực, chương trình, trạng thái] – 26 dòng thật theo ảnh hệ thống */
const LUAT_THAT = [
  ["Luật sửa đổi, bổ sung một số điều của Luật Thi đua, khen thưởng", "Bộ Nội vụ", "31/12/2025", "31/12/2026", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Bảo hiểm xã hội", "Bộ Nội vụ", "10/07/2026", "31/12/2026", "dua", "xd"],
  ["Luật sửa đổi, bổ sung một số điều của 04 luật thuộc lĩnh vực nội vụ", "Bộ Nội vụ", "20/08/2026", "01/03/2027", "dua", "xd"],
  ["Luật Xử lý vi phạm hành chính (sửa đổi)", "Bộ Công an", "10/08/2026", "01/07/2026", "dua", "xd"],
  ["Luật Tín ngưỡng, tôn giáo (sửa đổi)", "G21", "31/01/2026", "31/12/2026", "dua", "xd"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Cơ quan đại diện nước Cộng hòa xã hội chủ nghĩa Việt Nam ở nước ngoài", "Bộ Ngoại giao", "31/01/2026", "31/12/2026", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Thỏa thuận quốc tế", "Bộ Ngoại giao", "30/06/2026", "31/12/2026", "dua", "ra"],
  ["Luật Sửa đổi, bổ sung một số điều của Luật Thương mại, Luật Cạnh tranh, Luật Quản lý ngoại thương, Luật Bảo vệ quyền lợi người tiêu dùng", "G02", "10/07/2026", "01/03/2026", "dua", "xd"],
  ["Luật Dầu khí sửa đổi", "G02", "31/05/2026", "01/01/2027", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Điện lực", "G02", "10/08/2026", "01/01/2027", "dua", "xd"],
  ["Luật Giao dịch hàng hoá phái sinh", "G02", "21/08/2026", "01/01/2027", "dua", "xd"],
  ["Bộ luật Hàng hải Việt Nam (sửa đổi)", "Bộ Xây dựng", "31/05/2026", "31/12/2026", "dua", "xd"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Kiến trúc", "Bộ Xây dựng", "10/06/2026", "01/03/2027", "dua", "tq"],
  ["Luật Nhà ở (sửa đổi)", "Bộ Xây dựng", "10/08/2026", "01/07/2027", "dua", "xd"],
  ["Luật Kinh doanh bất động sản (sửa đổi)", "Bộ Xây dựng", "10/08/2026", "01/07/2027", "dua", "xd"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Người lao động Việt Nam đi làm việc ở nước ngoài theo hợp đồng", "Bộ Nội vụ", "20/08/2026", "01/03/2027", "de", "tq"],
  ["Luật Hòa giải ở cơ sở (sửa đổi)", "Bộ Tư pháp", "30/06/2026", "01/03/2027", "dua", "tq"],
  ["Dự án Luật Phổ biến, giáo dục pháp luật (sửa đổi)", "Bộ Tư pháp", "10/05/2026", "01/07/2026", "dua", "tq"],
  ["Luật Hộ tịch", "Bộ Tư pháp", "10/02/2026", "01/01/2027", "dua", "tq"],
  ["Dự án Luật Thủ đô", "Bộ Tư pháp", "16/02/2026", "01/07/2026", "dua", "tq"],
  ["Luật Tiếp cận thông tin", "Bộ Tư pháp", "07/02/2026", "01/09/2026", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Công chứng", "Bộ Tư pháp", "10/01/2026", "01/01/2027", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Hải quan", "Bộ Tài chính", "31/07/2026", "01/01/2027", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Ngân hàng Nhà nước Việt Nam số 46/2010/QH12, Luật Phòng, chống rửa tiền số 14/2022/QH15 và Luật Các tổ chức tín dụng số 32/2024/QH15", "G19", "26/06/2026", "01/12/2026", "dua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Đầu tư", "Bộ Tài chính", "01/07/2026", "01/03/2027", "chua", "tq"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Tần số vô tuyến điện, Luật Viễn thông, Luật Chuyển giao công nghệ và Luật Giao dịch điện tử", "Bộ Khoa học và Công nghệ", "26/06/2026", "01/03/2026", "dua", "tq"],
];
const LUAT_TEN = ["Đất đai", "Đầu tư công", "Ngân sách nhà nước", "Quản lý thuế", "Thuế giá trị gia tăng", "Thuế thu nhập doanh nghiệp", "Thuế thu nhập cá nhân", "Kế toán", "Kiểm toán độc lập", "Chứng khoán",
  "Kinh doanh bảo hiểm", "Doanh nghiệp", "Hợp tác xã", "Đấu thầu", "Quy hoạch", "Bảo vệ môi trường", "Tài nguyên nước", "Địa chất và khoáng sản", "Lâm nghiệp", "Thủy sản", "Trồng trọt", "Chăn nuôi", "Thú y",
  "Giáo dục", "Giáo dục đại học", "Giáo dục nghề nghiệp", "Khám bệnh, chữa bệnh", "Dược", "Bảo hiểm y tế", "An toàn thực phẩm", "Báo chí", "Xuất bản", "Điện ảnh", "Di sản văn hóa", "Du lịch", "Thể dục, thể thao",
  "Quảng cáo", "An ninh mạng", "Đo lường", "Sở hữu trí tuệ", "Năng lượng nguyên tử", "Hóa chất", "Cư trú", "Căn cước", "Nghĩa vụ quân sự", "Thanh niên", "Bình đẳng giới", "Người cao tuổi", "Trẻ em", "Việc làm",
  "Công đoàn", "Khiếu nại", "Tố cáo", "Tiếp công dân", "Thanh tra", "Luật sư", "Giám định tư pháp", "Đấu giá tài sản", "Trọng tài thương mại", "Phá sản"];
const CQ_LUAT = { "Đất đai": "Bộ Nông nghiệp và Môi trường", "Bảo vệ môi trường": "Bộ Nông nghiệp và Môi trường", "Tài nguyên nước": "Bộ Nông nghiệp và Môi trường", "Địa chất và khoáng sản": "Bộ Nông nghiệp và Môi trường", "Lâm nghiệp": "Bộ Nông nghiệp và Môi trường", "Thủy sản": "Bộ Nông nghiệp và Môi trường", "Trồng trọt": "Bộ Nông nghiệp và Môi trường", "Chăn nuôi": "Bộ Nông nghiệp và Môi trường", "Thú y": "Bộ Nông nghiệp và Môi trường",
  "Giáo dục": "Bộ Giáo dục và Đào tạo", "Giáo dục đại học": "Bộ Giáo dục và Đào tạo", "Giáo dục nghề nghiệp": "Bộ Giáo dục và Đào tạo", "Khám bệnh, chữa bệnh": "Bộ Y tế", "Dược": "Bộ Y tế", "Bảo hiểm y tế": "Bộ Y tế", "An toàn thực phẩm": "Bộ Y tế",
  "Báo chí": "Bộ Văn hóa, Thể thao và Du lịch", "Xuất bản": "Bộ Văn hóa, Thể thao và Du lịch", "Điện ảnh": "Bộ Văn hóa, Thể thao và Du lịch", "Di sản văn hóa": "Bộ Văn hóa, Thể thao và Du lịch", "Du lịch": "Bộ Văn hóa, Thể thao và Du lịch", "Thể dục, thể thao": "Bộ Văn hóa, Thể thao và Du lịch", "Quảng cáo": "Bộ Văn hóa, Thể thao và Du lịch",
  "An ninh mạng": "Bộ Công an", "Cư trú": "Bộ Công an", "Căn cước": "Bộ Công an", "Nghĩa vụ quân sự": "Bộ Quốc phòng", "Đo lường": "Bộ Khoa học và Công nghệ", "Sở hữu trí tuệ": "Bộ Khoa học và Công nghệ", "Năng lượng nguyên tử": "Bộ Khoa học và Công nghệ",
  "Hóa chất": "Bộ Công Thương", "Thanh niên": "Bộ Nội vụ", "Bình đẳng giới": "Bộ Nội vụ", "Người cao tuổi": "Bộ Y tế", "Trẻ em": "Bộ Y tế", "Việc làm": "Bộ Nội vụ", "Công đoàn": "Tổng Liên đoàn Lao động Việt Nam",
  "Khiếu nại": "Thanh tra Chính phủ", "Tố cáo": "Thanh tra Chính phủ", "Tiếp công dân": "Thanh tra Chính phủ", "Thanh tra": "Thanh tra Chính phủ", "Luật sư": "Bộ Tư pháp", "Giám định tư pháp": "Bộ Tư pháp", "Đấu giá tài sản": "Bộ Tư pháp", "Trọng tài thương mại": "Bộ Tư pháp", "Phá sản": "Tòa án nhân dân tối cao" };
const LUAT_DS = (() => {
  const r = seeded("luat");
  const can = [...Array(5).fill(["dua", "tq"]), ...Array(38).fill(["dua", "xd"]), ["chua", "tq"], ...Array(6).fill(["de", "xd"]), ...Array(4).fill(["chua", "xd"])];
  const sinh = can.map(([ct, st], i) => {
    const ten = LUAT_TEN[i % LUAT_TEN.length];
    const han = congNgay(new Date(2026, 0, 10), Math.floor(r(i * 3) * 300));
    const hl = new Date(han.getFullYear() + (r(i * 3 + 1) < 0.5 ? 0 : 1), r(i * 3 + 2) < 0.5 ? 0 : 6, 1);
    return [`Luật sửa đổi, bổ sung một số điều của Luật ${ten}`, CQ_LUAT[ten] || "Bộ Tài chính", fmtD(han), fmtD(hl < han ? new Date(han.getFullYear() + 1, 0, 1) : hl), ct, st];
  });
  return [...LUAT_THAT, ...sinh].map(([ten, cq, han, hl, ct, st], i) => ({ stt: i + 1, ten, loai: "Luật", cq, nam: 2026, han, hl, ct, ctTen: CT_CT[ct][0], st, stTen: CT_ST[st][0], that: i < LUAT_THAT.length }));
})();

/* VB quy định chi tiết: 12 dòng thật theo văn bản nguồn, còn lại sinh khớp 141 thông qua / 50 chậm, nợ (thuộc 22 luật) / 2 sắp đến hạn / 37 đang xây dựng */
const QD_ST = { tq: ["Đã được thông qua/ban hành", "#067647", NEN.tot], no: ["Chậm, nợ ban hành", "#B42318", NEN.xau], sap: ["Sắp đến hạn ban hành", "#B54708", "#FFFAEB"], xd: ["Đang xây dựng", "#175CD3", "#EFF8FF"] };
const QD_THAT = [
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Thông tư của Bộ trưởng Bộ Công an quy định chi tiết một số nội dung về hoạt động xây dựng trong Công an nhân dân (khoản 6 Điều 28; khoản 5 Điều 29; khoản 3 Điều 69; khoản 3 Điều 70)", "Thông tư", "Bộ Công an", "TQ_BT_01", "Các bộ, ngành, cơ quan liên quan", "Bộ trưởng/ Thủ trưởng cơ quan ngang Bộ xem xét, thông qua", "01/07/2026", 2025, "01/07/2026", "10/06/2026"],
  ["Luật sửa đổi, bổ sung một số điều của Luật Quy hoạch đô thị và nông thôn số 144/2025/QH15 có hiệu lực từ ngày 01/01/2026", "Nghị định sửa đổi, bổ sung một số điều của Nghị định số 178/2025/NĐ-CP ngày 01/7/2025 của Chính phủ quy định chi tiết một số điều của Luật Quy hoạch đô thị và nông thôn (điểm b, điểm c khoản 2, khoản 6, khoản 11 Điều 1; khoản 5 Điều 4)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "31/12/2025", 2025, "01/01/2026", "22/01/2026"],
  ["Luật sửa đổi, bổ sung một số điều của 10 luật có liên quan đến an ninh, trật tự. Có hiệu lực từ ngày 01/7/2026", "Nghị định sửa đổi, bổ sung một số điều của Nghị định số 165/2024/NĐ-CP ngày 26/12/2024 của Chính phủ quy định chi tiết, hướng dẫn thi hành một số điều của Luật Đường bộ và Điều 77 Luật Trật tự, an toàn giao thông đường bộ (khoản 3, khoản 5 Điều 8 Luật sửa đổi, bổ sung Điều 8, khoản 1 Điều 29 Luật Đường bộ)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "26/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định quy định chi tiết một số điều và biện pháp để tổ chức, hướng dẫn thi hành Luật Xây dựng về quản lý hoạt động xây dựng (khoản 19 Điều 3; Điều 7; khoản 1 Điều 9; Điều 11; Điều 16; khoản 4 Điều 17; điểm a khoản 1 Điều 18; Điều 19; Điều 21; Điều 22; điểm b khoản 2 và khoản 3 Điều 23; điểm c khoản 1 Điều 27; khoản 5 Điều 28; khoản 2 Điều 30; khoản 3 Điều 31; Điều 32; Điều 42; điểm b khoản 1 và khoản 3 Điều 44; Điều 47; Điều 68; khoản 2 Điều 70)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "19/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định quy định chi tiết một số nội dung về quản lý chất lượng, thi công xây dựng và bảo trì công trình xây dựng (khoản 1 Điều 6; khoản 1 Điều 48; Điều 49; Điều 51; Điều 54; Điều 55; khoản 6 Điều 57; Điều 58; Điều 64; Điều 65; Điều 67)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "15/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định quy định chi tiết về quản lý chi phí đầu tư xây dựng (khoản 4 Điều 74; khoản 7 Điều 76; Điều 79)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "15/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định quy định chi tiết về hợp đồng xây dựng (Điều 82; khoản 4 Điều 83; khoản 4 Điều 84; Điều 85; Điều 87)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "15/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định quy định chi tiết về hệ thống thông tin, cơ sở dữ liệu quốc gia về hoạt động xây dựng, điều kiện năng lực hoạt động xây dựng (khoản 3 Điều 14; khoản 7 Điều 88)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "17/06/2026"],
  ["Luật Xây dựng số 135/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định về quản lý vật liệu xây dựng (Điều 8, khoản 4 Điều 11)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "15/06/2026"],
  ["Luật Hàng không dân dụng Việt Nam số 130/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định về nhà chức trách hàng không và quản lý an toàn (Điều 8; Điều 79; Điều 80; Điều 81; Điều 82; Điều 83; Điều 84; Điều 85; Điều 86; Điều 87; Điều 88; Điều 89; Điều 90; Điều 99; Điều 100; khoản 2 Điều 103)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "22/06/2026"],
  ["Luật Hàng không dân dụng Việt Nam số 130/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định về tàu bay và khai thác tàu bay (Điều 9; Điều 13; Điều 14; Điều 15; Điều 16; Điều 17; Điều 21; Điều 22; Điều 23; Điều 24; Điều 25; Điều 99)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "23/06/2026"],
  ["Luật Hàng không dân dụng Việt Nam số 130/2025/QH15 có hiệu lực từ ngày 01/7/2026", "Nghị định về hoạt động bay (Điều 39; Điều 40; Điều 41; Điều 42; Điều 43; Điều 45; Điều 46; Điều 47; Điều 48; Điều 99; khoản 3 Điều 103)", "Nghị định", "Bộ Xây dựng", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", "30/04/2026", 2025, "01/07/2026", "22/06/2026"],
];
const QD_LOAI = [["Nghị định", "TQ_CP_01", "Bộ Tư pháp, Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", 5], ["Thông tư", "TQ_BT_01", "Các bộ, ngành, cơ quan liên quan", "Bộ trưởng/ Thủ trưởng cơ quan ngang Bộ xem xét, thông qua", 5],
  ["Quyết định", "TQ_TTg_01", "Văn phòng Chính phủ và các cơ quan liên quan", "Thủ tướng Chính phủ xem xét, ban hành", 1.2], ["Nghị quyết của CP", "TQ_CP_02", "Văn phòng Chính phủ và các cơ quan liên quan", "Chính phủ xem xét, thông qua", 0.6]];
const QD_DS = (() => {
  const r = seeded("qdct");
  const luatNo = LUAT_TEN.slice(0, 22), sl = allocate(50, luatNo.map((_, i) => 1 + r(i)));
  const can = [...Array(141 - QD_THAT.length).fill("tq"), ...luatNo.flatMap((t, i) => Array(sl[i]).fill("no|" + t)), "sap", "sap", ...Array(37).fill("xd")];
  const sinh = can.map((c, i) => {
    const [st, tl] = c.split("|");
    const ten = tl || LUAT_TEN[(i * 7) % LUAT_TEN.length];
    const L = QD_LOAI[Math.min(3, Math.floor(r(i * 5) * 3.1))];
    const rl = seeded("luat|" + ten), so = 100 + Math.floor(rl(1) * 90);
    const hl = st === "no" ? congNgay(new Date(2025, 6, 1), Math.floor(rl(2) * 300)) : congNgay(new Date(2026, 0, 1), Math.floor(rl(3) * 540));
    const han = st === "sap" ? congNgay(HOM_NAY, 5 + i % 10) : congNgay(hl, -(20 + Math.floor(r(i * 5 + 3) * 60)));
    const cq = CQ_LUAT[ten] || "Bộ Tài chính";
    const tenVB = L[0] === "Thông tư" ? `Thông tư của Bộ trưởng ${cq} hướng dẫn thi hành một số điều của Luật ${ten}` : L[0] === "Quyết định" ? `Quyết định của Thủ tướng Chính phủ quy định chi tiết Luật ${ten}` : `${L[0] === "Nghị định" ? "Nghị định" : "Nghị quyết của Chính phủ"} quy định chi tiết một số điều và biện pháp thi hành Luật ${ten}`;
    return [`Luật ${ten} số ${so}/${st === "no" ? 2025 : hl.getFullYear() - 1}/QH15 có hiệu lực từ ngày ${fmtD(hl)}`, tenVB, L[0], cq, L[1], L[2], L[3], fmtD(han), hl.getFullYear() - 1, fmtD(hl), st === "tq" ? fmtD(congNgay(han, Math.floor(r(i * 5 + 4) * 40))) : "", st];
  });
  return [...QD_THAT.map((x) => [...x, "tq"]), ...sinh].map(([luat, ten, loai, cq, ma, phoiHop, cap, han, nam, hl, ngayTQ, st], i) => ({ stt: i + 1, luat, ten, loai, cq, ma, phoiHop, cap, han, nam, hl, ngayTQ, st, stTen: QD_ST[st][0], that: i < QD_THAT.length }));
})();
const TQ_DS = (() => {
  const r = seeded("tqbtp");
  const doi = ["hộ tịch", "chứng thực", "công chứng", "luật sư", "đấu giá tài sản", "thừa phát lại", "giám định tư pháp", "lý lịch tư pháp", "trợ giúp pháp lý", "thi hành án dân sự", "bồi thường nhà nước", "kiểm tra văn bản", "phổ biến, giáo dục pháp luật", "hòa giải ở cơ sở", "quốc tịch", "nuôi con nuôi"];
  return Array.from({ length: XD_TOM.tq[1] }, (_, i) => {
    const xong = i < XD_TOM.tq[0], loai = r(i * 3) < 0.65 ? "Thông tư" : "Quyết định";
    const han = congNgay(new Date(2026, 0, 15), Math.floor(r(i * 3 + 1) * 330));
    return { stt: i + 1, ten: `${loai} ${loai === "Thông tư" ? "quy định chi tiết, hướng dẫn về" : "của Bộ trưởng ban hành quy chế về"} ${doi[i % doi.length]}${i >= doi.length ? ` (đợt ${Math.floor(i / doi.length) + 1})` : ""}`, loai, cq: chon(r, DV_BO, i * 3 + 2), han: fmtD(han), st: xong ? "tq" : "xd", stTen: xong ? "Đã hoàn thành xây dựng" : "Đang xây dựng" };
  });
})();

/* =============== 3. PHẢN ÁNH KIẾN NGHỊ VỀ VBQPPL – tháng 11/2026 =============== */
const PAKN_TOM = { tong: 319, xong: 81, qh: 77, th: 161 };
const PAKN_ST = { xong: ["Đã hoàn thành", "#067647", NEN.tot], qh: ["Đang xử lý quá hạn", "#B42318", NEN.xau], th: ["Đang xử lý trong hạn", "#175CD3", "#EFF8FF"] };
const PAKN_CQ = [["Bộ Nông nghiệp và Môi trường", 70], ["Bộ Tài chính", 40], ["Bộ Công an", 30], ["Bộ Tư pháp", 30], ["Bộ Nội vụ", 26], ["Bộ Giáo dục và Đào tạo", 22], ["Bộ Xây dựng", 16], ["Bộ Y tế", 12], ["Thanh tra Chính phủ", 8], ["Bộ Khoa học và Công nghệ", 8], ["Ngân hàng Nhà nước", 6], ["Bộ Công Thương", 6]];
const PAKN_LV = [["Đất đai", 21], ["Đầu tư", 12], ["Thuế, phí, lệ phí", 9], ["Xây dựng", 8], ["Giáo dục", 6], ["Lao động, việc làm", 6], ["Y tế", 4], ["Doanh nghiệp", 6], ["Khác", 8]];
const PAKN_ND = { "Đất đai": ["thủ tục chuyển mục đích sử dụng đất", "thời hạn giải quyết hồ sơ cấp giấy chứng nhận", "bồi thường khi Nhà nước thu hồi đất"], "Đầu tư": ["thủ tục chấp thuận chủ trương đầu tư", "điều kiện ưu đãi đầu tư"], "Thuế, phí, lệ phí": ["mức thu lệ phí trước bạ", "hoàn thuế giá trị gia tăng"], "Xây dựng": ["thời hạn cấp phép xây dựng", "điều kiện năng lực hoạt động xây dựng"], "Giáo dục": ["tuyển sinh đầu cấp", "liên kết đào tạo"], "Lao động, việc làm": ["cấp giấy phép lao động cho người nước ngoài", "chế độ bảo hiểm thất nghiệp"], "Y tế": ["đăng ký lưu hành thuốc", "điều kiện hành nghề khám bệnh"], "Doanh nghiệp": ["đăng ký thay đổi nội dung doanh nghiệp", "điều kiện kinh doanh dịch vụ cầm đồ"], "Khác": ["quy định về quản lý cư trú", "thủ tục cấp phiếu lý lịch tư pháp"] };
const PAKN_DS = (() => {
  const r = seeded("pakn");
  const cqN = allocate(PAKN_TOM.tong, PAKN_CQ.map((x) => x[1])), lvW = PAKN_LV.map((x) => x[1]);
  const pb = phanBo(PAKN_CQ.map(([ten], i) => ({ ten, n: cqN[i] })), { xong: PAKN_TOM.xong, qh: PAKN_TOM.qh, th: PAKN_TOM.th }, "pakn-pb");
  return pb.map(([g, st], i) => {
    let x = r(i * 9) * lvW.reduce((a, b) => a + b, 0), k = 0; while (k < lvW.length - 1 && x >= lvW[k]) { x -= lvW[k]; k++; }
    const lv = PAKN_LV[k][0];
    const nhan = st === "qh" ? congNgay(HOM_NAY, -(25 + Math.floor(r(i * 9 + 1) * 240))) : st === "th" ? congNgay(HOM_NAY, -Math.floor(r(i * 9 + 1) * 28)) : congNgay(HOM_NAY, -(5 + Math.floor(r(i * 9 + 1) * 200)));
    const han = congNgay(nhan, 20);
    return { ma: `PAKN-2026-${String(812 + i * 3).padStart(4, "0")}`, nd: `${chon(r, ["Phản ánh về", "Kiến nghị sửa đổi quy định về", "Đề nghị hướng dẫn"], i * 9 + 2)} ${chon(r, PAKN_ND[lv], i * 9 + 3)}`, cq: g.ten, lv,
      doiTuong: chon(r, ["Doanh nghiệp", "Người dân", "Hiệp hội doanh nghiệp", "Cơ quan, tổ chức"], i * 9 + 4), kenh: chon(r, ["Cổng Dịch vụ công quốc gia", "Cổng tiếp nhận phản ánh, kiến nghị", "Văn phòng Chính phủ chuyển"], i * 9 + 5),
      nhan: fmtD(nhan), han: fmtD(han), st, stTen: PAKN_ST[st][0], tre: st === "qh" ? treHan(fmtD(han)) : 0, ngayXL: st === "xong" ? fmtD(congNgay(han, Math.floor(r(i * 9 + 6) * 30) - 15)) : "" };
  }).map((x, i) => ({ ...x, stt: i + 1 }));
})();
const PAKN_SAT = [["Rất hài lòng", 39.77, C.tot], ["Hài lòng", 1.69, "#6EDB8F"], ["Bình thường", 4.32, C.warn], ["Không hài lòng", 1.69, C.xau], ["Ý kiến khác", 52.53, "#B197FC"]];

/* =============== 4. THI HÀNH ÁN DÂN SỰ – đến tháng 11/2026 =============== */
/* Số tổng theo màn hình IOC ngày 09/11/2026 09:13 (Nền tảng số THADS). Chỉ tiêu giao năm 2026 theo góp ý của Bộ: việc 84,3%, tiền 56,20% */
const THA = { viecPhai: 1251140, viecDK: 843755, viecXong: 588399, tlViec: 69.74, viecMoi: 657883, viecTruoc: 601715, viecChuaDK: 407385,
  tienDK: 389724.7, tienXong: 185327.4, tlTien: 47.55 };
/* Chưa có trên màn hình nguồn: Tổng số tiền phải thi hành và cơ cấu nguồn về tiền. Tạm dùng SỐ MẪU (theo tỷ lệ của kỳ trước), chờ Cục Quản lý THADS cung cấp */
const THA_MAU_TIEN = (() => { const phai = Math.round(THA.tienDK * (875549.6 / 716479.0) * 10) / 10, moi = Math.round(phai * 0.526 * 10) / 10;
  return { phai, chuaDK: Math.round((phai - THA.tienDK) * 10) / 10, moi, truoc: Math.round((phai - moi) * 10) / 10 }; })();
const THA_CHI_TIEU = { viec: 84.3, tien: 56.2 };
/* SO SÁNH CÙNG KỲ – Cục Quản lý THADS cung cấp số liệu. Quy tắc: số liệu ngày hiện tại thuộc tháng m năm Y được so với số liệu
   lũy kế tháng m năm Y-1 (đến hết ngày cuối tháng m/Y-1); sang tháng mới thì kỳ so sánh chuyển theo.
   Ví dụ ngày 09/11/2026 so với số liệu đến hết 30/11/2025. Khi có số, điền vào THA_CUNG_KY (null = chưa có). */
const THA_CUNG_KY = { viecPhai: null, viecDK: null, viecXong: null, tlViec: null, tienPhai: null, tienDK: null, tienXong: null, tlTien: null };
const kyCungKy = (d = HOM_NAY) => { const het = new Date(d.getFullYear() - 1, d.getMonth() + 1, 0); return { nhan: `T${d.getMonth() + 1}/${d.getFullYear() - 1}`, den: fmtD(het) }; };
const cungKyText = (k, v, phanTram = false) => {
  const ck = THA_CUNG_KY[k], kk = kyCungKy();
  if (ck == null) return `Cùng kỳ ${kk.nhan}: chưa có số liệu`;
  const d = phanTram ? v - ck : tyLe(v - ck, ck);
  return `${d >= 0 ? "▲" : "▼"} ${so(Math.abs(d), 2)}${phanTram ? " điểm" : "%"} so với cùng kỳ ${kk.nhan}`;
};
const datChiTieu = (tl, ct) => (tl / ct) * 100;
const THA_GOC = [["TP. Hồ Chí Minh", 106888, 69.0, 120824.7, 37.9], ["Hà Nội", 61405, 66.7, 36112.8, 31.6], ["An Giang", 40270, 64.8, 24759.5, 35.1], ["Đồng Nai", 37235, 60.5, 24986.9, 46.5], ["Phú Thọ", 33518, 67.8, 39902.9, 48.9], ["Đồng Tháp", 33391, 65.8, 27486.2, 29.1], ["Ninh Bình", 30253, 57.7, 28902.3, 42.7], ["Hưng Yên", 30172, 58.5, 22006.9, 29.1], ["Thanh Hóa", 28642, 57.1, 24989.9, 45.2], ["Hải Phòng", 28578, 70.0, 22526.8, 35.9], ["Đắk Lắk", 28462, 55.7, 21745.0, 49.1], ["Lâm Đồng", 24820, 70.5, 22995.8, 51.5], ["Gia Lai", 23454, 60.9, 21716.8, 40.1], ["Vĩnh Long", 23202, 53.1, 26635.1, 52.0], ["Đà Nẵng", 23192, 66.1, 23047.1, 35.4], ["Cần Thơ", 23023, 53.5, 26825.0, 29.8], ["Sơn La", 8464, 70.3, 9435.6, 42.4], ["Cao Bằng", 12528, 70.2, 15136.3, 28.8], ["Hà Tĩnh", 10215, 69.7, 10075.3, 32.7], ["Cà Mau", 13320, 69.6, 8440.4, 37.8], ["Khánh Hòa", 13609, 68.8, 15211.3, 42.7], ["Lạng Sơn", 6176, 52.9, 7348.9, 31.7], ["Quảng Ngãi", 5481, 53.1, 6293.9, 29.0], ["Quảng Trị", 16418, 53.6, 15029.4, 48.8], ["Quảng Ninh", 8748, 53.9, 8886.6, 35.5], ["Tuyên Quang", 8416, 54.3, 5613.4, 51.0], ["Lai Châu", 18517, 54.7, 20324.1, 49.5], ["Bắc Ninh", 11546, 66.5, 10604.9, 37.1], ["Huế", 16405, 64.6, 11782.6, 39.0], ["Điện Biên", 11627, 67.1, 6563.6, 40.5], ["Lào Cai", 13786, 60.7, 15345.0, 43.5], ["Thái Nguyên", 7305, 65.6, 8819.9, 42.3], ["Nghệ An", 13730, 61.3, 7989.6, 41.4], ["Tây Ninh", 16834, 67.2, 18114.5, 42.9]];
/* Quy đổi số theo tỉnh để tổng khớp số toàn quốc mới (844.938 việc, 389.776,9 tỷ) */
const THA_DS = (() => {
  const vk = allocate(THA.viecDK, THA_GOC.map((x) => x[1]));
  const vx0 = THA_GOC.map((x, i) => vk[i] * x[2]); const fv = THA.viecXong / vx0.reduce((a, b) => a + b, 0);
  const vx = allocate(THA.viecXong, vx0.map((v) => v * fv));
  const tk0 = THA_GOC.map((x) => x[3]), ft = THA.tienDK / tk0.reduce((a, b) => a + b, 0);
  const tx0 = THA_GOC.map((x, i) => tk0[i] * ft * x[4]), fx = THA.tienXong / tx0.reduce((a, b) => a + b, 0);
  return THA_GOC.map(([ten], i) => { const tk = Math.round(tk0[i] * ft * 10) / 10, tx = Math.round(tx0[i] * fx * 10) / 10;
    return { ten: `Thi hành án dân sự ${ten}`, tinh: ten, viecDK: vk[i], viecXong: vx[i], viecDang: vk[i] - vx[i], tlViec: tyLe(vx[i], vk[i]), tienDK: tk, tienXong: tx, tienDang: Math.round((tk - tx) * 10) / 10, tlTien: tyLe(tx, tk) }; })
    .sort((a, b) => b.viecDK - a.viecDK).map((x, i) => ({ ...x, stt: i + 1 }));
})();
const THA_THANG = { ky: ["T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11"], viec: [38.9, 50.8, 58.2, 55.0, 56.6, 62.9, 66.4, 69.77], tien: [22.0, 27.0, 31.0, 33.0, 35.5, 38.6, 44.9, 47.57] };

/* =============== 5. GIẢI QUYẾT TTHC – tháng 11/2026 =============== */
const TTHC_TOM = { luyKe: 12504316, thang: 551006, tt: 536995, tiep: 14011, tlTT: 97.5, daXL: 91.1, tuChoi: 0.7 };
const TTHC_THANG = { ky: ["T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11"], nhan: [410500, 1012000, 1810000, 2105000, 2052000, 2048000, 1982809, 551006], xl: [352000, 905000, 1702000, 1980000, 1965000, 1990000, 1902400, 501966] };
const TTHC_LV = [["Chứng thực", 0.52, 91.6], ["Hộ tịch", 0.33, 94.8], ["Lý lịch tư pháp", 0.075, 95.4], ["Đăng ký biện pháp bảo đảm", 0.06, 99.1], ["Trợ giúp pháp lý", 0.008, 88.2], ["Quốc tịch", 0.004, 72.4], ["Nuôi con nuôi", 0.002, 58.2], ["Bồi thường nhà nước", 0.001, 66.7]];
const tthcHang = (ten, tong, dungHan, r, k) => {
  const tt = Math.round(tong * (TTHC_TOM.tlTT / 100 + (r(k) - 0.5) * 0.04)), xl = Math.round(tong * (TTHC_TOM.daXL / 100 + (r(k + 1) - 0.5) * 0.06));
  const xlDH = Math.round(xl * dungHan / 100), dang = tong - xl, dangQH = Math.round(dang * (0.05 + r(k + 2) * 0.12));
  return { ten, tong, tt: Math.min(tong, tt), tiep: tong - Math.min(tong, tt), xlDH, xlQH: xl - xlDH, dangDH: dang - dangQH, dangQH, tuChoi: Math.round(tong * TTHC_TOM.tuChoi / 100), tlDH: dungHan };
};
const TTHC_LV_DS = (() => { const r = seeded("tthc-lv"); const n = allocate(TTHC_TOM.thang, TTHC_LV.map((x) => x[1])); return TTHC_LV.map(([t, , dh], i) => ({ ...tthcHang(t, n[i], dh, r, i * 5), stt: i + 1 })); })();
const TTHC_DP_DS = (() => { const r = seeded("tthc-dp"); const n = allocate(TTHC_TOM.thang, THA_GOC.map((x) => x[1])); return THA_GOC.map(([t], i) => tthcHang(t, n[i], Math.round((82 + r(i * 7 + 3) * 17) * 10) / 10, r, i * 7)).sort((a, b) => a.tlDH - b.tlDH).map((x, i) => ({ ...x, stt: i + 1 })); })();

/* =============== 6. GIẢI NGÂN VỐN ĐẦU TƯ CÔNG – đến tháng 10/2026 (số tổng theo ảnh; danh mục dự án quy đổi cho khớp) =============== */
const GN_TOM = { kh: 497929, da: 263310.4, chua: 234618.6, tl: 52.88, bo: [236972.5, 466355.0], thads: [26337.9, 36574.0] };
const GN_GOC = [
  ["Nền tảng số pháp luật Việt Nam", "Cục CNTT", "bo", 87000, 28719.4], ["Trụ sở Cục Trợ giúp pháp lý", "Cục PBGDPL&TGPL", "bo", 59126, 27056.7],
  ["Trụ sở THADS tỉnh Đồng Tháp", "Tỉnh Đồng Tháp", "thads", 9200, 9200.0], ["Trụ sở THADS TP Quảng Ninh", "TP Quảng Ninh", "thads", 10600, 10589.4], ["Trụ sở THADS TP Bắc Ninh", "TP Bắc Ninh", "thads", 8400, 8391.6],
  ["Trụ sở THADS tỉnh Tuyên Quang", "Tỉnh Tuyên Quang", "thads", 7100, 7092.9], ["Trụ sở THADS tỉnh Quảng Ngãi", "Tỉnh Quảng Ngãi", "thads", 9800, 8526.0], ["Trụ sở THADS TP Đà Nẵng", "TP Đà Nẵng", "thads", 12200, 7368.8],
  ["Trụ sở THADS tỉnh Lai Châu", "Tỉnh Lai Châu", "thads", 6400, 3859.2], ["Trụ sở THADS tỉnh Thái Nguyên", "Tỉnh Thái Nguyên", "thads", 8600, 3483.0], ["Trụ sở THADS tỉnh An Giang", "Tỉnh An Giang", "thads", 11000, 4213.0],
  ["Trụ sở THADS tỉnh Hưng Yên", "Tỉnh Hưng Yên", "thads", 7700, 0], ["Trụ sở THADS tỉnh Tây Ninh", "Tỉnh Tây Ninh", "thads", 6900, 0], ["Trụ sở THADS TP Hải Phòng", "TP Hải Phòng", "thads", 13000, 0],
  ["Mở rộng cơ sở đào tạo Học viện Tư pháp tại TP. Hồ Chí Minh", "Học viện Tư pháp", "bo", 13500, 7213.1], ["Ký túc xá sinh viên Trường Đại học Luật Hà Nội", "Đại học Luật Hà Nội", "bo", 14800, 2230.4],
  ["CSDL hộ tịch điện tử toàn quốc giai đoạn 2", "Cục HCTP", "bo", 19200, 0], ["Nâng cấp Hệ thống quản lý lý lịch tư pháp", "Trung tâm LLTP QG", "bo", 13700, 9384.5], ["Cơ sở dữ liệu công chứng, chứng thực", "Cục Bổ trợ tư pháp", "bo", 14200, 1459.1],
  ["Trung tâm dữ liệu ngành Tư pháp", "Cục CNTT", "bo", 15100, 0], ["Hệ thống quản lý THADS điện tử", "Cục QLTHADS", "bo", 10300, 0], ["Cải tạo trụ sở Văn phòng Bộ", "Văn phòng Bộ", "bo", 14200, 3404.5],
  ["Kho lưu trữ chuyên dụng Bộ Tư pháp", "Văn phòng Bộ", "bo", 15600, 3740.1], ["Cổng pháp luật quốc gia giai đoạn 2", "Cục PBGDPL&TGPL", "bo", 17600, 0], ["Hệ thống đăng ký biện pháp bảo đảm trực tuyến", "Cục Đăng ký QG GDBĐ", "bo", 9200, 4915.6],
  ["Thư viện pháp luật số", "Viện Chiến lược và KHPL", "bo", 11700, 4408.0], ["Trụ sở Báo Pháp luật Việt Nam", "Báo PLVN", "bo", 9100, 4862.1], ["Nâng cấp Trường Cao đẳng Luật miền Trung", "CĐ Luật miền Trung", "bo", 17800, 4267.6],
  ["Phần mềm kiểm tra, rà soát VBQPPL giai đoạn 2", "Cục KTVB & TCTHPL", "bo", 16400, 11234.0], ["Hạ tầng an toàn thông tin ngành Tư pháp", "Cục CNTT", "bo", 8500, 2037.9], ["Trụ sở Tạp chí Dân chủ và Pháp luật", "Tạp chí DC&PL", "bo", 20003, 5754.6],
];
const GN_DS = (() => {
  const nhom = (g) => GN_GOC.filter((x) => x[2] === g);
  const out = [];
  ["bo", "thads"].forEach((g) => {
    const xs = nhom(g), [da, kh] = GN_TOM[g];
    const fk = kh / xs.reduce((a, x) => a + x[3], 0);
    const khs = xs.map((x) => Math.round(x[3] * fk * 10) / 10);
    const w = xs.map((x) => x[4]), fd = da / w.reduce((a, b) => a + b, 0);
    xs.forEach((x, i) => { const k = khs[i]; const d = Math.min(k, Math.round(x[4] * fd * 10) / 10); out.push({ ten: x[0], cdt: x[1], nhom: g, nhomTen: g === "bo" ? "Đơn vị thuộc Bộ" : "Cơ quan THADS", kh: k, da: d, p: tyLe(d, k) }); });
  });
  return out.sort((a, b) => a.p - b.p).map((x, i) => ({ ...x, stt: i + 1, ttTen: x.p >= 99.95 ? "Đã giải ngân hết" : x.p > 0 ? "Giải ngân một phần" : "Chưa giải ngân" }));
})();
const GN_TT = { "Đã giải ngân hết": ["#067647", NEN.tot], "Giải ngân một phần": ["#B54708", "#FFFAEB"], "Chưa giải ngân": ["#B42318", NEN.xau] };
const GN_THANG = { ky: ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10"], bo: [21.1, 22.2, 24.2, 26.6, 32.7, 19.8, 23.7, 24.6, 36.8, 52.88], tq: [3.2, 6.1, 10.5, 15.0, 20.4, 27.1, 32.8, 38.5, 46.2, null] };

/* ---------- Mốc cập nhật từng hệ thống ---------- */
const CAP_NHAT = { nv: ["Vừa xong", "09/11/2026 13:54"], xdpl: ["2 ngày trước", "06/11/2026 22:39"], pakn: ["Vừa xong", "09/11/2026 13:16"], thads: ["4 giờ trước", "09/11/2026 09:13"], tthc: ["1 giờ trước", "09/11/2026 12:01"], gn: ["9 ngày trước", "30/10/2026", true] };

/* ---------- Biểu tượng (nét vẽ theo bộ Lucide, giấy phép ISC) ---------- */
const ICON = {
  "tong-quan": <><rect x="3" y="3" width="7" height="9" rx="1" /><rect x="14" y="3" width="7" height="5" rx="1" /><rect x="14" y="12" width="7" height="9" rx="1" /><rect x="3" y="16" width="7" height="5" rx="1" /></>,
  nv: <><rect x="8" y="2" width="8" height="4" rx="1" /><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" /><path d="m9 14 2 2 4-4" /></>,
  xdpl: <><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" /><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" /></>,
  pakn: <><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /><path d="M8 9h8" /><path d="M8 13h5" /></>,
  thads: <><path d="m14.5 12.5-8 8a2.119 2.119 0 1 1-3-3l8-8" /><path d="m16 16 6-6" /><path d="m8 8 6-6" /><path d="m9 7 8 8" /><path d="m21 11-8-8" /></>,
  tthc: <><path d="M5 22h14" /><path d="M19.27 13.73A2.5 2.5 0 0 0 17.5 13h-11A2.5 2.5 0 0 0 4 15.5V17a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-1.5c0-.66-.26-1.3-.73-1.77Z" /><path d="M14 13V8.5C14 7 15 7 15 5a3 3 0 0 0-3-3c-1.69 0-3 1-3 3s1 2 1 3.5V13" /></>,
  gn: <><path d="M3 22h18" /><path d="M6 18v-7" /><path d="M10 18v-7" /><path d="M14 18v-7" /><path d="M18 18v-7" /><path d="M12 2 20 7H4z" /></>,
  "canh-bao": <><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" /></>,
  tim: <><circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" /></>,
  "quay-lai": <><path d="m15 18-6-6 6-6" /></>,
  dong: <><path d="M18 6 6 18" /><path d="m6 6 12 12" /></>,
  "mui-ten": <><path d="m9 18 6-6-6-6" /></>,
  "dong-ho": <><circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" /></>,
  play: <><polygon points="6 3 20 12 6 21 6 3" /></>,
  pause: <><rect x="14" y="4" width="4" height="16" rx="1" /><rect x="6" y="4" width="4" height="16" rx="1" /></>,
  sau: <><polygon points="5 4 15 12 5 20 5 4" /><line x1="19" x2="19" y1="5" y2="19" /></>,
  truoc: <><polygon points="19 20 9 12 19 4 19 20" /><line x1="5" x2="5" y1="19" y2="5" /></>,
  "cau-hinh": <><line x1="21" x2="14" y1="4" y2="4" /><line x1="10" x2="3" y1="4" y2="4" /><line x1="21" x2="12" y1="12" y2="12" /><line x1="8" x2="3" y1="12" y2="12" /><line x1="21" x2="16" y1="20" y2="20" /><line x1="12" x2="3" y1="20" y2="20" /><line x1="14" x2="14" y1="2" y2="6" /><line x1="8" x2="8" y1="10" y2="14" /><line x1="16" x2="16" y1="18" y2="22" /></>,
  "toan-man-hinh": <><path d="M8 3H5a2 2 0 0 0-2 2v3" /><path d="M21 8V5a2 2 0 0 0-2-2h-3" /><path d="M3 16v3a2 2 0 0 0 2 2h3" /><path d="M16 21h3a2 2 0 0 0 2-2v-3" /></>,
  len: <><path d="m18 15-6-6-6 6" /></>,
  xuong: <><path d="m6 9 6 6 6-6" /></>,
};
function Icon({ name, size = 22, color = "currentColor" }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{ICON[name]}</svg>;
}
const HUE = { "tong-quan": "#1D5FD6", nv: "#1D5FD6", xdpl: "#6D4AE0", pakn: "#0369A1", thads: "#C0183F", tthc: "#0E8F80", gn: "#D97706", "canh-bao": "#E8590C" };
function AppIcon({ name, size = 32 }) {
  return (
    <span className="flex shrink-0 items-center justify-center" style={{ width: size, height: size, borderRadius: size * 0.27, background: HUE[name] || HUE.nv }}>
      <Icon name={name} size={Math.round(size * 0.55)} color="#fff" />
    </span>
  );
}

/* ---------- Khung 16:9 ---------- */
function Stage({ children }) {
  const [k, setK] = useState(1);
  useEffect(() => {
    const f = () => setK(Math.min(window.innerWidth / W0, window.innerHeight / H0));
    f();
    window.addEventListener("resize", f);
    return () => window.removeEventListener("resize", f);
  }, []);
  return (
    <div className="fixed inset-0 flex items-center justify-center overflow-hidden bg-white">
      <div className="relative flex-none overflow-hidden bg-white" style={{ width: W0, height: H0, transform: `scale(${k})`, transformOrigin: "center center" }}>{children}</div>
    </div>
  );
}

/* ---------- Tiện ích ---------- */
function useSize() {
  const ref = useRef(null);
  const [size, setSize] = useState({ w: 600, h: 240 });
  useEffect(() => {
    if (!ref.current) return;
    const ro = new ResizeObserver(([e]) => setSize({ w: Math.max(120, Math.round(e.contentRect.width)), h: Math.max(100, Math.round(e.contentRect.height)) }));
    ro.observe(ref.current);
    return () => ro.disconnect();
  }, []);
  return [ref, size];
}
const niceTicks = (max, n = 4) => {
  if (max <= 0) return [0, 1];
  const raw = max / n, mag = 10 ** Math.floor(Math.log10(raw)), f = raw / mag;
  const step = (f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10) * mag;
  const top = Math.ceil(max / step) * step;
  return Array.from({ length: Math.round(top / step) + 1 }, (_, i) => +(i * step).toFixed(10));
};
const mauXu = (x) => (x === "tot" ? C.tot : x === "xau" ? C.xau : x === "warn" ? C.warn : ACC);
/* Tông màu theo ngưỡng: đạt / theo dõi (hụt ≤ 5 điểm) / chưa đạt – như hàm status() của IOC */
const xuNguong = (v, t) => (v >= t ? "tot" : t - v <= 5 ? "warn" : "xau");

/* Thay đổi so với kỳ trước: chữ màu, không nền */
function Delta({ d }) {
  if (!d) return null;
  const col = d.xu === "trung" ? P.mo : mauXu(d.xu);
  return <span className="inline-flex items-center gap-1 whitespace-nowrap text-[13px] font-semibold" style={{ color: col }}>{d.t.startsWith("+") ? "▲" : d.t.startsWith("−") ? "▼" : ""} {d.t}</span>;
}

function Spark({ vals, w = 110, h = 30, color = ACC }) {
  const v = (vals || []).filter((x) => x != null);
  if (v.length < 2) return null;
  const lo = Math.min(0, ...v), hi = Math.max(...v) || 1;
  const X = (i) => 3 + (i / (v.length - 1)) * (w - 6), Y = (x) => h - 3 - ((x - lo) / (hi - lo || 1)) * (h - 6);
  const d = v.map((x, i) => `${i ? "L" : "M"}${X(i).toFixed(1)},${Y(x).toFixed(1)}`).join("");
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} aria-hidden="true" className="block">
      <path d={`${d}L${X(v.length - 1).toFixed(1)},${h}L${X(0).toFixed(1)},${h}Z`} fill={color} opacity=".12" />
      <path d={d} fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={X(v.length - 1)} cy={Y(v[v.length - 1])} r="2.8" fill={color} />
    </svg>
  );
}

function Ring({ v, color = ACC, size = 64, stroke = 6 }) {
  const r = (size - stroke) / 2, c = 2 * Math.PI * r, p = Math.max(0, Math.min(1, v || 0));
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={C.track} strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeDasharray={`${p * c} ${c}`} />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center text-[14px] font-bold tabular-nums" style={{ color: P.navy }}>{so(p * 100, 0)}%</div>
    </div>
  );
}

/* Thẻ KPI – cùng hình thức thẻ NQ57: vạch màu trên theo trạng thái, số lớn, thay đổi, vòng tỷ lệ hoặc đường diễn biến */
function Kpi({ nhan, gt, dv, d, ky, ring, ringMau, spark, icon, xu, onClick, nho = false }) {
  const Tag = onClick ? "button" : "div";
  const vach = xu ? mauXu(xu) : ACC;
  const nenDelta = d ? (d.xu === "tot" ? NEN.tot : d.xu === "xau" ? NEN.xau : d.xu === "warn" ? NEN.warn : NEN.trung) : NEN.trung;
  return (
    <Tag onClick={onClick} className={`flex h-full flex-col justify-between rounded-2xl px-5 py-4 text-left ${onClick ? "transition-shadow hover:shadow-xl focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]" : ""}`}
      style={{ background: "#FFFFFF", border: `1px solid ${P.vien}`, borderTop: `4px solid ${vach}`, boxShadow: "0 8px 22px -12px rgba(15,42,92,.28), 0 1px 2px rgba(15,42,92,.05)" }}>
      <p className="flex items-center gap-2.5 font-semibold text-[#344054]" style={{ fontSize: 15 }}>
        <AppIcon name={icon} size={32} />
        <span className="min-w-0 truncate" title={nhan}>{nhan}</span>
      </p>
      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <p className="flex items-baseline gap-1.5 whitespace-nowrap">
            <span className="tabular-nums" style={{ color: P.navy, fontFamily: FONT_APPLE, fontSize: nho ? 36 : 46, fontWeight: 700, lineHeight: 1, letterSpacing: "-0.03em" }}>{gt}</span>
            {dv && <span className="text-sm font-medium text-[#475467]">{dv}</span>}
          </p>
          <p className="mt-2.5 flex items-center gap-2 text-sm text-[#475467]">
            {d && <span className="rounded-md px-2 py-0.5" style={{ background: nenDelta }}><Delta d={d} /></span>}
            <span className="truncate">{ky}</span>
          </p>
        </div>
        {nho ? null : ring != null ? <Ring v={ring} color={ringMau || ACC} size={72} stroke={8} /> : <Spark vals={spark} w={110} h={48} color={xu === "xau" ? C.xau : ACC} />}
      </div>
    </Tag>
  );
}

/* ---------- Biểu đồ (SVG tự vẽ, cùng hình thức NQ57) ---------- */
function Chu({ items }) {
  return (
    <div className="mb-2 flex flex-wrap gap-x-5 gap-y-1 text-sm text-[#344054]">
      {items.map((x) => (
        <span key={x.ten} className="inline-flex items-center gap-1.5">
          {x.dash ? <span className="inline-block w-5 border-t-2 border-dashed" style={{ borderColor: x.color }} /> : <span className={`inline-block ${x.line ? "h-0.5 w-5" : "h-2.5 w-2.5"} rounded-sm`} style={{ background: x.color }} />}
          {x.ten}
        </span>
      ))}
    </div>
  );
}
function Tip({ left, tieuDe, dong }) {
  return (
    <div className="pointer-events-none absolute top-1 z-10 max-w-[340px] rounded-lg border border-[#D9DEE7] bg-white px-3 py-2 text-sm shadow-lg" style={{ left: `${Math.min(Math.max(0, left + 1), 62)}%` }}>
      <p className="mb-0.5 font-semibold text-[#101828]">{tieuDe}</p>
      {dong.map(([c, t, v]) => <p key={t} className="flex items-center gap-1.5"><span className="inline-block h-2.5 w-2.5 shrink-0 rounded-sm" style={{ background: c }} /><span className="truncate text-[#344054]">{t}</span><b className="ml-auto pl-2 font-semibold text-[#101828]">{v}</b></p>)}
    </div>
  );
}

/* Đường: series = [{ ten, color, vals }], vals cùng độ dài kys (null = không có số) */
function LineChart({ kys, series, fmt = gon, fmtTick, nguong }) {
  const [ref, { w: W, h: H }] = useSize();
  const [hover, setHover] = useState(null);
  const top = 14, bottom = 28, fs = 14, cw = 7.8;
  const ft = fmtTick || fmt;
  const lastI = (s) => { let i = s.vals.length - 1; while (i > 0 && s.vals[i] == null) i--; return i; };
  const ticks = niceTicks(Math.max(...series.flatMap((s) => s.vals.filter((v) => v != null)), nguong ? nguong.v : 0));
  const ml = Math.max(...ticks.map((t) => ft(t).length)) * 8 + 22;
  const ends = series.map((s) => fmt(s.vals[lastI(s)]));
  const mr = Math.max(0, ...ends.map((e) => e.length)) * cw + 18;
  const inner = W - ml - mr, n = kys.length;
  const X = (i) => ml + (n === 1 ? inner / 2 : (i / (n - 1)) * inner);
  const Y = (v) => top + (1 - v / ticks[ticks.length - 1]) * (H - top - bottom);
  const every = Math.max(1, Math.ceil((Math.max(...kys.map((k) => k.length)) * cw + 12) / (n > 1 ? inner / (n - 1) : inner)));
  const endY = series.map((s) => Y(s.vals[lastI(s)]));
  [...endY.keys()].sort((a, b) => endY[a] - endY[b]).forEach((idx, k, arr) => { if (k && endY[idx] - endY[arr[k - 1]] < 15) endY[idx] = endY[arr[k - 1]] + 15; });
  const pts = (s) => s.vals.map((v, i) => [i, v]).filter(([, v]) => v != null);
  const duong = (s) => pts(s).map(([i, v], j) => `${j ? "L" : "M"}${X(i).toFixed(1)},${Y(v).toFixed(1)}`).join("");
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={series.map((s) => ({ ten: s.ten, color: s.color, line: true })).concat(nguong ? [{ ten: nguong.ten, color: P.navy, dash: true }] : [])} />
      <div ref={ref} className="relative min-h-0 flex-1">
        <svg className="absolute inset-0" width={W} height={H} viewBox={`0 0 ${W} ${H}`} onMouseLeave={() => setHover(null)}
          onMouseMove={(e) => { const r = e.currentTarget.getBoundingClientRect(); const mx = ((e.clientX - r.left) / r.width) * W; let b = 0; kys.forEach((_, i) => { if (Math.abs(X(i) - mx) < Math.abs(X(b) - mx)) b = i; }); setHover(b); }}>
          {ticks.map((t) => <g key={t}><line x1={ml} x2={W - mr + 6} y1={Y(t)} y2={Y(t)} stroke={C.grid} /><text x={ml - 8} y={Y(t)} dy="0.32em" textAnchor="end" fontSize={fs} fill={P.mo}>{ft(t)}</text></g>)}
          {kys.map((k, i) => ((n - 1 - i) % every === 0 ? <text key={k} x={X(i)} y={H - 6} textAnchor="middle" fontSize={fs} fill={P.mo}>{k}</text> : null))}
          {nguong && <line x1={ml} x2={W - mr + 6} y1={Y(nguong.v)} y2={Y(nguong.v)} stroke={P.navy} strokeWidth="1.3" strokeDasharray="6 5" />}
          {hover != null && <line x1={X(hover)} x2={X(hover)} y1={top} y2={H - bottom} stroke="#D0D5DD" />}
          {series.map((s, si) => {
            const p = pts(s);
            return (
              <g key={s.ten}>
                {series.length <= 2 && p.length > 1 && <path d={`${duong(s)}L${X(p[p.length - 1][0]).toFixed(1)},${Y(0)}L${X(p[0][0]).toFixed(1)},${Y(0)}Z`} fill={s.color} opacity=".10" />}
                <path d={duong(s)} fill="none" stroke={s.color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
                {p.map(([i, v]) => <circle key={i} cx={X(i)} cy={Y(v)} r={hover === i ? 5 : 3.2} fill="#fff" stroke={s.color} strokeWidth="2" />)}
                <text x={X(lastI(s)) + 9} y={endY[si]} dy="0.32em" fontSize={fs + 1} fontWeight="700" fill={s.color}>{ends[si]}</text>
              </g>
            );
          })}
        </svg>
        {hover != null && <Tip left={(X(hover) / W) * 100} tieuDe={kys[hover]} dong={series.map((s) => [s.color, s.ten, s.vals[hover] != null ? fmt(s.vals[hover]) : "—"])} />}
      </div>
    </div>
  );
}

/* Cột: nhóm cạnh nhau, hoặc xếp chồng (stack) */
function Columns({ kys, series, fmt = gon, stack = false }) {
  const [ref, { w: W, h: H }] = useSize();
  const [hover, setHover] = useState(null);
  const tong = (i) => series.reduce((a, s) => a + (s.vals[i] || 0), 0);
  const ticks = niceTicks(stack ? Math.max(...kys.map((_, i) => tong(i))) : Math.max(...series.flatMap((s) => s.vals)));
  const top = 22, bottom = 26, ml = Math.max(...ticks.map((t) => gon(t).length)) * 8 + 20, mr = 8;
  const band = (W - ml - mr) / kys.length;
  const gw = stack ? Math.min(band * 0.62, 46) : Math.min(band * 0.7, 44 * series.length), bw = stack ? gw : gw / series.length;
  const Y = (v) => top + (1 - v / ticks[ticks.length - 1]) * (H - top - bottom);
  const every = Math.max(1, Math.ceil((Math.max(...kys.map((k) => k.length)) * 7.4 + 10) / band));
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={series.map((s) => ({ ten: s.ten, color: s.color }))} />
      <div ref={ref} className="relative min-h-0 flex-1" onMouseLeave={() => setHover(null)}>
        <svg className="absolute inset-0" width={W} height={H} viewBox={`0 0 ${W} ${H}`}>
          {ticks.map((t) => <g key={t}><line x1={ml} x2={W - mr} y1={Y(t)} y2={Y(t)} stroke={C.grid} /><text x={ml - 8} y={Y(t)} dy="0.32em" textAnchor="end" fontSize="14" fill={P.mo}>{gon(t)}</text></g>)}
          {kys.map((k, i) => {
            const x0 = ml + i * band + (band - gw) / 2;
            let acc = 0;
            return (
              <g key={k} onMouseEnter={() => setHover(i)}>
                <rect x={ml + i * band} y={top} width={band} height={H - top - bottom} fill={hover === i ? "#FAFBFC" : "transparent"} />
                {series.map((s, j) => {
                  const v = s.vals[i];
                  if (v == null) return null;
                  if (stack) {
                    const y0 = Y(acc), y1 = Y(acc + v); acc += v;
                    return <rect key={s.ten} x={x0} y={y1} width={gw} height={Math.max(0, y0 - y1)} fill={s.color} />;
                  }
                  return (
                    <g key={s.ten}>
                      <rect x={x0 + j * bw + 1.5} y={Y(v)} width={Math.max(2, bw - 3)} height={Math.max(0, Y(0) - Y(v))} rx="3" fill={s.color} />
                      {(series.length === 1 ? bw > 30 : bw > 56) && <text x={x0 + j * bw + bw / 2} y={Y(v) - 6} textAnchor="middle" fontSize="13" fontWeight="700" fill={P.ink2}>{gon(v)}</text>}
                    </g>
                  );
                })}
                {stack && band > 34 && <text x={x0 + gw / 2} y={Y(tong(i)) - 6} textAnchor="middle" fontSize="13" fontWeight="700" fill={P.ink2}>{gon(tong(i))}</text>}
                {(kys.length - 1 - i) % every === 0 && <text x={ml + i * band + band / 2} y={H - 6} textAnchor="middle" fontSize="14" fill={P.mo}>{k}</text>}
              </g>
            );
          })}
        </svg>
        {hover != null && <Tip left={((ml + hover * band + band) / W) * 100} tieuDe={kys[hover]} dong={series.map((s) => [s.color, s.ten, s.vals[hover] != null ? fmt(s.vals[hover]) : "—"]).concat(stack ? [[P.navy, "Tổng", fmt(tong(hover))]] : [])} />}
      </div>
    </div>
  );
}

function Donut({ parts, giua, phu, fmt = gon, phanTram = true }) {
  const [ref, { w, h }] = useSize();
  const tong = parts.reduce((a, p) => a + p.v, 0) || 1;
  const size = Math.min(h, w * 0.42, 190), R = size / 2 - 4, r = R * 0.7, cx = size / 2, cy = h / 2;
  let a0 = -Math.PI / 2;
  const cung = parts.filter((p) => p.v > 0).map((p) => {
    const a1 = a0 + (p.v / tong) * Math.PI * 2 - (p.v === tong ? 1e-4 : 0), big = a1 - a0 > Math.PI ? 1 : 0;
    const d = `M${cx + R * Math.cos(a0)},${cy + R * Math.sin(a0)} A${R},${R} 0 ${big} 1 ${cx + R * Math.cos(a1)},${cy + R * Math.sin(a1)} L${cx + r * Math.cos(a1)},${cy + r * Math.sin(a1)} A${r},${r} 0 ${big} 0 ${cx + r * Math.cos(a0)},${cy + r * Math.sin(a0)}Z`;
    a0 = a1;
    return { ...p, d };
  });
  return (
    <div ref={ref} className="flex h-full w-full items-center gap-8">
      <svg width={size} height={h} viewBox={`0 0 ${size} ${h}`} className="shrink-0">
        {cung.map((c) => <path key={c.ten} d={c.d} fill={c.color} stroke="#fff" strokeWidth="2" />)}
        <text x={cx} y={cy - 2} textAnchor="middle" fontSize={Math.max(22, r * 0.42)} fontWeight="600" fill={P.navy} style={{ fontFamily: FONT_APPLE }}>{giua}</text>
        <text x={cx} y={cy + 20} textAnchor="middle" fontSize="13" fill={P.mo}>{phu}</text>
      </svg>
      <ul className="min-w-0 flex-1 space-y-2">
        {parts.map((p) => (
          <li key={p.ten} className="flex items-center gap-2 text-[15px]">
            <span className="h-2.5 w-2.5 shrink-0 rounded-sm" style={{ background: p.color }} />
            <span className="leading-tight text-[#101828]">{p.ten}</span>
            <span className="ml-auto whitespace-nowrap font-semibold tabular-nums text-[#101828]">{fmt(p.v)}</span>
            {phanTram && <span className="w-14 text-right text-sm tabular-nums text-[#475467]">{so((p.v / tong) * 100, 1)}%</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}

/* Thanh ngang: xếp chồng (mặc định) hoặc chồng lớp (overlay); muc = vạch chỉ tiêu theo % của max */
function HBars({ rows, segs, max, overlay = false, giaTri, muc, onRow, motDong = false, nhanW = 160 }) {
  const m = max || Math.max(...rows.map((r) => (overlay ? Math.max(...segs.map((s) => s.v(r))) : segs.reduce((a, s) => a + s.v(r), 0))));
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={segs.filter((s) => typeof s.color === "string").map((s) => ({ ten: s.ten, color: s.color })).concat(muc ? [{ ten: muc.ten, color: P.navy, dash: true }] : [])} />
      <ul className="flex min-h-0 flex-1 flex-col justify-around">
        {motDong && rows.map((r, i) => (
          <li key={i} onClick={onRow ? () => onRow(r) : undefined} className={`flex items-center gap-3 text-sm ${onRow ? "cursor-pointer rounded-md hover:bg-[#FAFBFC]" : ""}`}>
            <span className="shrink-0 truncate text-[#101828]" style={{ width: nhanW }} title={r.nhan}>{r.nhan}</span>
            <div className="relative flex h-2.5 flex-1 overflow-hidden rounded-sm" style={{ background: C.track }}>
              {overlay
                ? segs.map((s) => <div key={s.ten} className="absolute inset-y-0 left-0" style={{ width: `${(s.v(r) / m) * 100}%`, background: typeof s.color === "function" ? s.color(r) : s.color }} />)
                : segs.map((s) => <div key={s.ten} style={{ width: `${(s.v(r) / m) * 100}%`, background: typeof s.color === "function" ? s.color(r) : s.color }} />)}
              {muc && <div className="absolute inset-y-0" style={{ left: `${(muc.v / m) * 100}%`, width: 2, background: P.navy }} />}
            </div>
            <span className="shrink-0 text-right font-semibold tabular-nums text-[#101828]" style={{ minWidth: 80 }}>{giaTri(r)}</span>
          </li>
        ))}
        {!motDong && rows.map((r, i) => (
          <li key={i} onClick={onRow ? () => onRow(r) : undefined} className={onRow ? "cursor-pointer rounded-md hover:bg-[#FAFBFC]" : ""}>
            <div className="flex items-baseline justify-between gap-3 text-sm">
              <span className="truncate text-[#101828]" title={r.nhan}>{r.nhan}</span>
              <span className="shrink-0 font-semibold tabular-nums text-[#101828]">{giaTri(r)}</span>
            </div>
            <div className="relative mt-1 h-3 w-full overflow-hidden rounded-sm" style={{ background: C.track }}>
              {overlay
                ? segs.map((s) => <div key={s.ten} className="absolute inset-y-0 left-0" style={{ width: `${(s.v(r) / m) * 100}%`, background: typeof s.color === "function" ? s.color(r) : s.color }} title={`${s.ten}: ${soTuDong(s.v(r))}`} />)
                : <div className="flex h-full">{segs.map((s) => <div key={s.ten} style={{ width: `${(s.v(r) / m) * 100}%`, background: s.color }} title={`${s.ten}: ${soTuDong(s.v(r))}`} />)}</div>}
              {muc && <div className="absolute inset-y-0" style={{ left: `${(muc.v / m) * 100}%`, width: 2, background: P.navy }} />}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

/* Mục nội dung: không khung, ngăn bằng đường kẻ mảnh phía trên */
function Muc({ tieuDe, children, phai, className = "", style }) {
  const coDau = tieuDe || phai;
  return (
    <section style={{ borderTop: `1px solid ${P.vien}`, ...style }} className={`flex min-h-0 flex-col pt-3 ${className}`}>
      {coDau && (
        <div className={`flex items-center gap-4 ${tieuDe ? "justify-between" : "justify-start"}`}>
          {tieuDe && <h3 className="text-[17px] font-semibold text-[#101828]">{tieuDe}</h3>}
          {phai}
        </div>
      )}
      <div className={`min-h-0 flex-1 ${coDau ? "mt-3" : ""}`}>{children}</div>
    </section>
  );
}

function Seg({ items, value, onChange }) {
  return (
    <div className="flex shrink-0 rounded-lg bg-[#E4E7EC] p-0.5 text-sm" role="tablist">
      {items.map(([id, ten]) => <button key={id} role="tab" aria-selected={value === id} onClick={() => onChange(id)} className={`whitespace-nowrap rounded-md px-3 py-1 font-medium ${value === id ? "bg-white text-[#101828] shadow-sm" : "text-[#475467]"}`}>{ten}</button>)}
    </div>
  );
}

/* ---------- Bảng ---------- */
const thCls = "sticky top-0 z-10 whitespace-nowrap bg-white px-2 py-2.5 text-xs font-semibold uppercase tracking-wide text-[#475467] border-b border-[#D9DEE7]";
function ThanhTyLe({ v, color = ACC, w = "w-12" }) {
  return (
    <div className="flex items-center gap-2">
      <div className="h-2 flex-1 overflow-hidden rounded-sm" style={{ background: C.track }}><div className="h-full" style={{ width: `${Math.max(0, Math.min(100, v))}%`, background: color }} /></div>
      <span className={`${w} text-right text-sm font-semibold tabular-nums`} style={{ color: P.navy }}>{pt(v)}</span>
    </div>
  );
}
function Nhan({ t, c, bg }) {
  return <span className="inline-block whitespace-nowrap rounded-md px-2 py-0.5 text-xs font-semibold" style={{ color: c, background: bg }}>{t}</span>;
}


/* =========================================================================
   THÀNH PHẦN DÙNG CHUNG CHO LỚP 2 VÀ LỚP 3
   ========================================================================= */
const normVN = (t) => String(t ?? "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d");
const laNgay = (v) => typeof v === "string" && /^\d{2}\/\d{2}\/\d{4}$/.test(v);
const soSanh = (a, b) => (typeof a === "number" && typeof b === "number" ? a - b : laNgay(a) && laNgay(b) ? parseVN(a) - parseVN(b) : String(a ?? "").localeCompare(String(b ?? ""), "vi", { numeric: true }));
const pill = (map) => (v) => { const m = map[v] || Object.values(map).find((x) => x[0] === v); return m ? <Nhan t={m[0] || v} c={m[1]} bg={m[2]} /> : v; };
const pillTen = (map) => (v) => { const m = Object.values(map).find((x) => x[0] === v); return m ? <Nhan t={v} c={m[1]} bg={m[2]} /> : <span>{v}</span>; };
const LOAI_PILL = (v) => <Nhan t={v} c="#175CD3" bg="#EFF8FF" />;
const soO = (d = 0) => (v) => (v == null || v === "" ? "" : so(v, d));
const thanhO = (ct) => (v) => <div style={{ minWidth: 150 }}><ThanhTyLe v={v} color={ct ? mauXu(xuNguong(v, ct)) : ACC} /></div>;

/* Thẻ chi tiết một bản ghi (lớp chi tiết cuối cùng) */
function BanGhi({ r, truong, tieuDe, onClose }) {
  useEffect(() => {
    const f = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", f);
    return () => window.removeEventListener("keydown", f);
  }, [onClose]);
  return (
    <div className="absolute inset-0 z-10 flex justify-end" style={{ background: "rgba(16,24,40,.35)" }} onClick={onClose}>
      <div role="dialog" aria-modal="true" aria-label={tieuDe} className="flex h-full flex-col bg-white shadow-lg" style={{ width: 720 }} onClick={(e) => e.stopPropagation()}>
        <div className="flex items-start justify-between gap-4 border-b border-[#D9DEE7] px-8 py-5">
          <div className="min-w-0">
            <p className="text-sm text-[#475467]">Chi tiết bản ghi</p>
            <h3 className="mt-1 text-[20px] font-semibold leading-tight text-[#101828]">{tieuDe}</h3>
          </div>
          <button onClick={onClose} aria-label="Đóng" className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg hover:bg-[#E4E7EC] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]"><Icon name="dong" size={22} color={P.ink2} /></button>
        </div>
        <dl className="min-h-0 flex-1 overflow-auto px-8 py-4">
          {truong.map((t) => {
            const v = r[t.k];
            if (v === "" || v == null) return null;
            return (
              <div key={t.k} className="grid gap-4 border-b border-[#E4E7EC] py-3" style={{ gridTemplateColumns: "190px minmax(0,1fr)" }}>
                <dt className="text-sm text-[#475467]">{t.ten}</dt>
                <dd className="text-[15px] font-medium text-[#101828]">{t.render ? t.render(v, r) : String(v)}</dd>
              </div>
            );
          })}
        </dl>
        <p className="border-t border-[#D9DEE7] px-8 py-3 text-xs text-[#667085]">{r.that ? "Bản ghi theo hệ thống nguồn." : "Bản ghi mẫu, sẽ thay bằng dữ liệu từ hệ thống nguồn."}</p>
      </div>
    </div>
  );
}

/* LỚP 3: danh sách chi tiết – tìm kiếm, lọc, sắp xếp theo cột, phân trang, bấm dòng để xem bản ghi */
const MOI_TRANG = 14;
function DanhSach({ cfg, locBanDau = {}, gon: gonGon = false }) {
  const { tieuDe, rows, cot, boLoc = [], timKeys, tomTat, truong, tenBanGhi } = cfg;
  const [q, setQ] = useState("");
  const [loc, setLoc] = useState(() => ({ ...locBanDau }));
  const [sx, setSx] = useState(null);
  const [tr, setTr] = useState(0);
  const [ban, setBan] = useState(null);
  const opts = useMemo(() => Object.fromEntries(boLoc.map((b) => [b.k, b.opts || [...new Set(rows.map((r) => r[b.k]))].filter((v) => v !== "" && v != null).sort(soSanh)])), [rows, boLoc]);
  const nq = normVN(q.trim());
  const loaiRows = useMemo(() => {
    const x = rows.filter((r) => Object.entries(loc).every(([k, v]) => v === "" || v == null || String(r[k]) === String(v)) && (!nq || timKeys.some((k) => normVN(r[k]).includes(nq))));
    return sx ? [...x].sort((a, b) => soSanh(a[sx.k], b[sx.k]) * sx.dir) : x;
  }, [rows, loc, nq, sx, timKeys]);
  const soTrang = Math.max(1, Math.ceil(loaiRows.length / MOI_TRANG)), t0 = Math.min(tr, soTrang - 1);
  const xem = loaiRows.slice(t0 * MOI_TRANG, (t0 + 1) * MOI_TRANG);
  const datLoc = (k, v) => { setLoc({ ...loc, [k]: v }); setTr(0); };
  const chipNgoai = Object.entries(loc).filter(([k, v]) => v && !boLoc.some((b) => b.k === k));
  const tenCot = (k) => (truong || cot).find((c) => c.k === k)?.ten || k;
  const NutTrang = ({ ten, den, tat, on }) => (
    <button disabled={tat} onClick={() => setTr(den)} className={`rounded-md border px-3 py-1 text-sm font-medium ${on ? "border-[#1D6FE8] text-white" : "border-[#D9DEE7] text-[#344054] hover:bg-[#E4E7EC]"}`}
      style={{ background: on ? ACC : "#fff", opacity: tat ? 0.45 : 1, cursor: tat ? "default" : "pointer" }}>{ten}</button>
  );
  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="flex flex-none flex-wrap items-center gap-3">
        {!gonGon && <h3 className="mr-auto text-[17px] font-semibold text-[#101828]">{tieuDe}</h3>}
        <input type="search" value={q} onChange={(e) => { setQ(e.target.value); setTr(0); }} placeholder="Tìm kiếm" aria-label="Tìm kiếm trong danh sách"
          className="w-80 rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-sm text-[#101828] focus:border-[#1D6FE8] focus:outline-none" />
        {boLoc.map((b) => (
          <label key={b.k} className="flex items-center gap-2 text-sm text-[#475467]">{b.ten}
            <select value={loc[b.k] || ""} onChange={(e) => datLoc(b.k, e.target.value)} className="rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-sm text-[#101828] focus:border-[#1D6FE8] focus:outline-none" style={{ maxWidth: 230 }}>
              <option value="">Tất cả</option>{opts[b.k].map((o) => <option key={o} value={o}>{o}</option>)}
            </select>
          </label>
        ))}
      </div>
      <div className="mt-2 flex flex-none flex-wrap items-center gap-x-5 gap-y-1 text-sm">
        {tomTat && tomTat(loaiRows).map(([l, v, c]) => <span key={l} className="text-[#475467]">{l}: <b className="tabular-nums" style={{ color: c || P.navy }}>{typeof v === "number" ? so(v) : v}</b></span>)}
        {chipNgoai.map(([k, v]) => (
          <button key={k} onClick={() => datLoc(k, "")} className="inline-flex items-center gap-1.5 rounded-md bg-[#E4E7EC] px-2 py-0.5 text-xs font-semibold text-[#344054]" title="Bỏ điều kiện lọc">
            {tenCot(k)}: {v}<Icon name="dong" size={12} />
          </button>
        ))}
      </div>
      <div className="mt-2 min-h-0 flex-1 overflow-auto rounded-lg border border-[#D9DEE7]">
        <table className="w-full text-left text-sm">
          <thead><tr>{cot.map((c) => (
            <th key={c.k} className={`${thCls} ${c.right ? "text-right" : ""}`} style={c.w ? { width: c.w } : undefined} aria-sort={sx?.k === c.k ? (sx.dir > 0 ? "ascending" : "descending") : "none"}>
              <button className="uppercase hover:text-[#101828] focus:outline-none focus-visible:underline" onClick={() => setSx({ k: c.k, dir: sx?.k === c.k ? -sx.dir : 1 })}>{c.ten}{sx?.k === c.k ? (sx.dir > 0 ? " ▲" : " ▼") : ""}</button>
            </th>))}</tr></thead>
          <tbody>
            {xem.map((r, i) => (
              <tr key={i} className="cursor-pointer border-b border-[#E4E7EC] align-middle hover:bg-[#FAFBFC]" onClick={() => setBan(r)}>
                {cot.map((c) => (
                  <td key={c.k} className={`px-2 py-2 ${c.right ? "text-right tabular-nums" : ""} ${c.nowrap ? "whitespace-nowrap" : ""}`} style={c.chinh ? { color: P.navy, fontWeight: 600 } : { color: P.ink2 }}>
                    {c.render ? c.render(r[c.k], r) : c.clamp ? <span className="line-clamp-2" title={r[c.k]}>{r[c.k]}</span> : r[c.k]}
                  </td>
                ))}
              </tr>
            ))}
            {!xem.length && <tr><td colSpan={cot.length} className="px-3 py-6 text-sm text-[#475467]">Không có bản ghi khớp điều kiện. Xóa từ khóa hoặc chọn Tất cả ở bộ lọc.</td></tr>}
          </tbody>
        </table>
      </div>
      <div className="mt-2 flex flex-none items-center justify-between gap-3 text-sm">
        <span className="text-[#475467]">Tổng số: <b className="text-[#101828]">{so(loaiRows.length)}</b> bản ghi</span>
        <div className="flex items-center gap-1.5">
          <NutTrang ten="Đầu" den={0} tat={t0 === 0} /><NutTrang ten="Trước" den={t0 - 1} tat={t0 === 0} />
          <span className="rounded-md border border-[#1D6FE8] px-3 py-1 text-sm font-semibold text-[#1D6FE8]">Trang {t0 + 1}/{soTrang}</span>
          <NutTrang ten="Tiếp" den={t0 + 1} tat={t0 >= soTrang - 1} /><NutTrang ten="Cuối" den={soTrang - 1} tat={t0 >= soTrang - 1} />
        </div>
      </div>
      {ban && <BanGhi r={ban} truong={truong || cot} tieuDe={tenBanGhi ? tenBanGhi(ban) : tieuDe} onClose={() => setBan(null)} />}
    </div>
  );
}

/* ---------- Cấu hình danh sách lớp 3 ---------- */
const demTT = (rows, k, map, nhan) => Object.entries(map).map(([key, m]) => [m[0], rows.filter((r) => r[k] === (nhan ? m[0] : key)).length, m[1]]);
const DS = {
  nv: { tieuDe: "Chi tiết nhiệm vụ Trung ương giao", rows: NV_DS, timKeys: ["ma", "ten", "vb", "donVi", "nhom"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ma", ten: "Mã NV", w: 130, nowrap: true }, { k: "ten", ten: "Tên nhiệm vụ", clamp: true, chinh: true, w: 460 }, { k: "nhom", ten: "Nhóm nhiệm vụ", w: 150 }, { k: "vb", ten: "Văn bản giao", w: 130 },
      { k: "donVi", ten: "Đơn vị chủ trì", w: 220 }, { k: "han", ten: "Hạn HT", w: 110 }, { k: "ttTen", ten: "Trạng thái", render: pillTen(TT_NV), w: 160 }, { k: "kq", ten: "Kết quả thực hiện", clamp: true }],
    truong: [{ k: "ma", ten: "Mã nhiệm vụ" }, { k: "ten", ten: "Tên nhiệm vụ" }, { k: "nguon", ten: "Nguồn giao" }, { k: "nhom", ten: "Nhóm nhiệm vụ" }, { k: "vb", ten: "Văn bản giao" }, { k: "donVi", ten: "Đơn vị chủ trì" },
      { k: "giao", ten: "Ngày giao" }, { k: "han", ten: "Hạn hoàn thành" }, { k: "ngayHT", ten: "Ngày hoàn thành" }, { k: "ttTen", ten: "Trạng thái", render: pillTen(TT_NV) }, { k: "tre", ten: "Số ngày quá hạn", render: (v) => (v ? <b style={{ color: C.xau }}>{v} ngày</b> : null) }, { k: "kq", ten: "Kết quả thực hiện" }],
    boLoc: [{ k: "nguon", ten: "Nguồn giao" }, { k: "nhom", ten: "Nhóm" }, { k: "ttNhom", ten: "Tiến độ", opts: NHOM_KEYS.map((k) => NHOM_TT[k][0]) }, { k: "ttTen", ten: "Trạng thái", opts: Object.values(TT_NV).map((x) => x[0]) }, { k: "donVi", ten: "Đơn vị" }],
    tomTat: (rs) => [["Tổng", rs.length], ...demTT(rs, "tt", TT_NV).filter((x) => x[1])] },
  ldb: { tieuDe: "Chi tiết nhiệm vụ do Lãnh đạo Bộ giao", rows: LDB_DS.map((x) => ({ ...x, daHT: x.tt.startsWith("ht") ? "Đã hoàn thành" : "Chưa hoàn thành" })), timKeys: ["ten", "vb", "donVi", "nguoi", "phoiHop"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: "Tên nhiệm vụ", clamp: true, chinh: true, w: 440 }, { k: "vb", ten: "Văn bản giao", w: 120 }, { k: "nguoi", ten: "Người thực hiện", w: 150 }, { k: "han", ten: "Hạn HT", w: 110 },
      { k: "donVi", ten: "Đơn vị chủ trì", w: 230 }, { k: "kq", ten: "Kết quả thực hiện", w: 150 }, { k: "phoiHop", ten: "Đơn vị phối hợp", clamp: true }, { k: "ttTen", ten: "Trạng thái", render: pillTen(LDB_TT), w: 160 }],
    truong: [{ k: "ten", ten: "Tên nhiệm vụ" }, { k: "vb", ten: "Văn bản giao" }, { k: "donVi", ten: "Đơn vị chủ trì" }, { k: "phoiHop", ten: "Đơn vị phối hợp" }, { k: "nguoi", ten: "Người thực hiện" }, { k: "han", ten: "Hạn hoàn thành" },
      { k: "ngayHT", ten: "Ngày hoàn thành" }, { k: "ttTen", ten: "Trạng thái", render: pillTen(LDB_TT) }, { k: "tre", ten: "Số ngày quá hạn", render: (v) => (v ? <b style={{ color: C.xau }}>{v} ngày</b> : null) }, { k: "kq", ten: "Kết quả thực hiện" }],
    boLoc: [{ k: "donVi", ten: "Đơn vị chủ trì" }, { k: "daHT", ten: "Tiến độ" }, { k: "ttTen", ten: "Trạng thái", opts: Object.values(LDB_TT).map((x) => x[0]) }],
    tomTat: (rs) => [["Tổng", rs.length], ...demTT(rs, "tt", LDB_TT).filter((x) => x[1])] },
  luat: { tieuDe: "Danh sách chi tiết văn bản: luật, pháp lệnh, nghị quyết", rows: LUAT_DS, timKeys: ["ten", "cq"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: "Tên văn bản", clamp: true, chinh: true, w: 560 }, { k: "loai", ten: "Phân loại", render: LOAI_PILL, w: 100 }, { k: "cq", ten: "CQ chủ trì", w: 220 }, { k: "nam", ten: "Năm BH", w: 80 },
      { k: "han", ten: "Hạn trình CP", w: 120 }, { k: "hl", ten: "Dự kiến hiệu lực", w: 130 }, { k: "ctTen", ten: "Chương trình", render: pillTen(CT_CT), w: 250 }, { k: "stTen", ten: "Trạng thái", render: pillTen(CT_ST) }],
    boLoc: [{ k: "loai", ten: "Phân loại" }, { k: "cq", ten: "CQ chủ trì" }, { k: "ctTen", ten: "Chương trình" }, { k: "stTen", ten: "Trạng thái" }],
    tomTat: (rs) => [["Tổng", rs.length], ...demTT(rs, "stTen", CT_ST, true).filter((x) => x[1])] },
  qdct: { tieuDe: "Danh sách chi tiết văn bản quy định chi tiết", rows: QD_DS, timKeys: ["ten", "luat", "cq", "ma"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "luat", ten: "Văn bản được quy định chi tiết", clamp: true, w: 330 }, { k: "ten", ten: "Tên văn bản quy định chi tiết", clamp: true, chinh: true, w: 520 }, { k: "loai", ten: "Loại", render: LOAI_PILL, w: 130 },
      { k: "cq", ten: "CQ chủ trì", w: 200 }, { k: "han", ten: "Hạn trình", w: 110 }, { k: "stTen", ten: "Trạng thái", render: pillTen(QD_ST), w: 200 }, { k: "ngayTQ", ten: "Ngày thông qua" }],
    truong: [{ k: "luat", ten: "Văn bản được quy định chi tiết" }, { k: "ten", ten: "Tên văn bản quy định chi tiết" }, { k: "loai", ten: "Loại văn bản" }, { k: "cq", ten: "Cơ quan chủ trì" }, { k: "ma", ten: "Mã nhiệm vụ" },
      { k: "phoiHop", ten: "Cơ quan phối hợp" }, { k: "cap", ten: "Cấp thông qua" }, { k: "han", ten: "Hạn trình" }, { k: "stTen", ten: "Trạng thái", render: pillTen(QD_ST) }, { k: "nam", ten: "Năm" }, { k: "hl", ten: "Ngày luật có hiệu lực" }, { k: "ngayTQ", ten: "Ngày thông qua/ban hành" }],
    boLoc: [{ k: "loai", ten: "Phân loại" }, { k: "cq", ten: "CQ chủ trì" }, { k: "stTen", ten: "Trạng thái" }],
    tomTat: (rs) => [["Tổng", rs.length], ...demTT(rs, "stTen", QD_ST, true).filter((x) => x[1])] },
  tq: { tieuDe: "Văn bản theo thẩm quyền của Bộ Tư pháp", rows: TQ_DS, timKeys: ["ten", "cq"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: "Tên văn bản", chinh: true, w: 640 }, { k: "loai", ten: "Loại", render: LOAI_PILL, w: 130 }, { k: "cq", ten: "Đơn vị chủ trì", w: 320 }, { k: "han", ten: "Hạn ban hành", w: 140 },
      { k: "stTen", ten: "Trạng thái", render: (v) => <Nhan t={v} c={v.startsWith("Đã") ? "#067647" : "#175CD3"} bg={v.startsWith("Đã") ? NEN.tot : "#EFF8FF"} /> }],
    boLoc: [{ k: "loai", ten: "Loại" }, { k: "cq", ten: "Đơn vị" }, { k: "stTen", ten: "Trạng thái" }],
    tomTat: (rs) => [["Tổng", rs.length], ["Đã hoàn thành", rs.filter((r) => r.st === "tq").length, C.tot], ["Đang xây dựng", rs.filter((r) => r.st === "xd").length, C.info]] },
  pakn: { tieuDe: "Chi tiết phản ánh, kiến nghị về VBQPPL", rows: PAKN_DS, timKeys: ["ma", "nd", "cq", "lv"], tenBanGhi: (r) => `${r.ma}: ${r.nd}`,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ma", ten: "Mã phản ánh", w: 150, nowrap: true }, { k: "nd", ten: "Nội dung", clamp: true, chinh: true, w: 440 }, { k: "cq", ten: "Cơ quan xử lý", w: 240 }, { k: "lv", ten: "Lĩnh vực", w: 140 },
      { k: "doiTuong", ten: "Đối tượng", w: 150 }, { k: "nhan", ten: "Ngày nhận", w: 110 }, { k: "han", ten: "Hạn xử lý", w: 110 }, { k: "stTen", ten: "Trạng thái", render: pillTen(PAKN_ST), w: 180 },
      { k: "tre", ten: "Quá hạn", right: true, nowrap: true, render: (v) => (v ? <b style={{ color: C.xau }}>{v} ngày</b> : "") }],
    truong: [{ k: "ma", ten: "Mã phản ánh" }, { k: "nd", ten: "Nội dung" }, { k: "lv", ten: "Lĩnh vực" }, { k: "doiTuong", ten: "Đối tượng phản ánh" }, { k: "kenh", ten: "Kênh tiếp nhận" }, { k: "cq", ten: "Cơ quan xử lý" },
      { k: "nhan", ten: "Ngày tiếp nhận" }, { k: "han", ten: "Hạn xử lý" }, { k: "ngayXL", ten: "Ngày hoàn thành" }, { k: "stTen", ten: "Trạng thái", render: pillTen(PAKN_ST) }, { k: "tre", ten: "Số ngày quá hạn", render: (v) => (v ? <b style={{ color: C.xau }}>{v} ngày</b> : null) }],
    boLoc: [{ k: "cq", ten: "Cơ quan" }, { k: "lv", ten: "Lĩnh vực" }, { k: "kenh", ten: "Kênh" }, { k: "stTen", ten: "Trạng thái" }],
    tomTat: (rs) => [["Tổng", rs.length], ...demTT(rs, "st", PAKN_ST)] },
  thads: { tieuDe: "Kết quả thi hành án dân sự theo địa phương", rows: THA_DS.map((x) => ({ ...x, datViec: x.tlViec >= THA_CHI_TIEU.viec ? "Đạt chỉ tiêu" : "Dưới chỉ tiêu", datTien: x.tlTien >= THA_CHI_TIEU.tien ? "Đạt chỉ tiêu" : "Dưới chỉ tiêu" })), timKeys: ["ten"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: "Cơ quan THADS", chinh: true, w: 320 }, { k: "viecDK", ten: "Việc có ĐK", right: true, render: soO() }, { k: "viecXong", ten: "Việc giải quyết xong", right: true, render: soO() },
      { k: "tlViec", ten: "Tỷ lệ thi hành xong về việc (%)", render: thanhO(THA_CHI_TIEU.viec), w: 240 }, { k: "tienDK", ten: "Tiền có ĐK (tỷ)", right: true, render: soO(1) }, { k: "tienXong", ten: "Tiền giải quyết xong (tỷ)", right: true, render: soO(1) }, { k: "tlTien", ten: "Tỷ lệ thi hành xong về tiền (%)", render: thanhO(THA_CHI_TIEU.tien), w: 240 }],
    truong: [{ k: "ten", ten: "Cơ quan thi hành án" }, { k: "viecDK", ten: "Việc có điều kiện thi hành", render: soO() }, { k: "viecXong", ten: "Việc giải quyết xong", render: soO() }, { k: "viecDang", ten: "Việc đang thi hành", render: soO() },
      { k: "tlViec", ten: "Tỷ lệ việc thi hành xong", render: thanhO(THA_CHI_TIEU.viec) }, { k: "datViec", ten: `So với chỉ tiêu ${THA_CHI_TIEU.viec}%` }, { k: "tienDK", ten: "Tiền có điều kiện (tỷ đồng)", render: soO(1) },
      { k: "tienXong", ten: "Tiền giải quyết xong (tỷ đồng)", render: soO(1) }, { k: "tienDang", ten: "Tiền đang thi hành (tỷ đồng)", render: soO(1) }, { k: "tlTien", ten: "Tỷ lệ tiền thi hành xong", render: thanhO(THA_CHI_TIEU.tien) }, { k: "datTien", ten: `So với chỉ tiêu ${THA_CHI_TIEU.tien}%` }],
    boLoc: [{ k: "datViec", ten: "Về việc" }, { k: "datTien", ten: "Về tiền" }],
    tomTat: (rs) => [["Số đơn vị", rs.length], ["Việc có ĐK", rs.reduce((a, r) => a + r.viecDK, 0)], ["Việc giải quyết xong", rs.reduce((a, r) => a + r.viecXong, 0), C.tot], ["Tiền giải quyết xong (tỷ)", so(rs.reduce((a, r) => a + r.tienXong, 0), 1), C.tot]] },
  tthc_lv: null, tthc_dp: null,
  gn: { tieuDe: "Danh sách dự án đầu tư công", rows: GN_DS, timKeys: ["ten", "cdt"], tenBanGhi: (r) => r.ten,
    cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: "Dự án", chinh: true, w: 520 }, { k: "cdt", ten: "Chủ đầu tư", w: 220 }, { k: "nhomTen", ten: "Nhóm", w: 170 }, { k: "kh", ten: "KH vốn (triệu)", right: true, render: soO(1) },
      { k: "da", ten: "Đã giải ngân (triệu)", right: true, render: soO(1) }, { k: "p", ten: "Tỷ lệ", render: (v) => <div style={{ minWidth: 150 }}><ThanhTyLe v={v} color={v >= 99.95 ? C.tot : v > 0 ? C.warn : C.xau} /></div>, w: 220 },
      { k: "ttTen", ten: "Trạng thái", render: (v) => <Nhan t={v} c={GN_TT[v][0]} bg={GN_TT[v][1]} /> }],
    boLoc: [{ k: "nhomTen", ten: "Nhóm" }, { k: "ttTen", ten: "Trạng thái" }, { k: "cdt", ten: "Chủ đầu tư" }],
    tomTat: (rs) => [["Số dự án", rs.length], ["Kế hoạch vốn (triệu)", so(rs.reduce((a, r) => a + r.kh, 0), 1)], ["Đã giải ngân (triệu)", so(rs.reduce((a, r) => a + r.da, 0), 1), C.tot]] },
};
const cfgTthc = (tieuDe, rows, nhan) => ({ tieuDe, rows, timKeys: ["ten"], tenBanGhi: (r) => r.ten,
  cot: [{ k: "stt", ten: "STT", w: 56 }, { k: "ten", ten: nhan, chinh: true, w: 300 }, { k: "tong", ten: "Tiếp nhận", right: true, render: soO() }, { k: "tt", ten: "Trực tuyến", right: true, render: soO() }, { k: "tiep", ten: "Trực tiếp", right: true, render: soO() },
    { k: "xlDH", ten: "Đã XL đúng hạn", right: true, render: soO() }, { k: "xlQH", ten: "Đã XL quá hạn", right: true, render: (v) => <b style={{ color: v ? C.warn : "#98A2B3" }}>{so(v)}</b> }, { k: "dangDH", ten: "Đang XL trong hạn", right: true, render: soO() },
    { k: "dangQH", ten: "Đang XL quá hạn", right: true, render: (v) => <b style={{ color: v ? C.xau : "#98A2B3" }}>{so(v)}</b> }, { k: "tuChoi", ten: "Từ chối", right: true, render: soO() }, { k: "tlDH", ten: "Tỷ lệ đúng hạn", render: thanhO(90), w: 200 }],
  truong: [{ k: "ten", ten: nhan }, { k: "tong", ten: "Hồ sơ tiếp nhận", render: soO() }, { k: "tt", ten: "Tiếp nhận trực tuyến", render: soO() }, { k: "tiep", ten: "Tiếp nhận trực tiếp", render: soO() }, { k: "xlDH", ten: "Đã xử lý đúng hạn", render: soO() },
    { k: "xlQH", ten: "Đã xử lý quá hạn", render: soO() }, { k: "dangDH", ten: "Đang xử lý trong hạn", render: soO() }, { k: "dangQH", ten: "Đang xử lý quá hạn", render: soO() }, { k: "tuChoi", ten: "Hồ sơ từ chối", render: soO() }, { k: "tlDH", ten: "Tỷ lệ đúng hạn", render: thanhO(90) }],
  tomTat: (rs) => [["Tiếp nhận", rs.reduce((a, r) => a + r.tong, 0)], ["Trực tuyến", rs.reduce((a, r) => a + r.tt, 0), ACC], ["Đang XL quá hạn", rs.reduce((a, r) => a + r.dangQH, 0), C.xau]] });
DS.tthc_lv = cfgTthc("Kết quả giải quyết TTHC theo lĩnh vực, tháng 11/2026", TTHC_LV_DS, "Lĩnh vực");
DS.tthc_dp = cfgTthc("Kết quả giải quyết TTHC theo địa phương, tháng 11/2026", TTHC_DP_DS, "Địa phương");

/* Danh sách cần đôn đốc (quá hạn, gần hạn) – dạng thẻ, bấm để xem chi tiết */
function DonDoc({ rows, cfg }) {
  const [ban, setBan] = useState(null);
  return (
    <div className="h-full overflow-auto">
      <ul className="space-y-2">
        {rows.map((r, i) => {
          const qh = r.tre > 0, conLai = !qh && r.han && laNgay(r.han) ? Math.round((parseVN(r.han) - HOM_NAY) / 864e5) : null;
          return (
            <li key={i}>
              <button onClick={() => setBan(r)} className="block w-full rounded-xl border px-4 py-3 text-left hover:shadow-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]" style={{ borderColor: qh ? "#FECDCA" : "#FEDF89", background: qh ? "#FFFBFA" : "#FFFCF5" }}>
                <span className="line-clamp-2 text-sm font-semibold text-[#101828]">{r.ten}</span>
                <span className="mt-2 flex items-center justify-between gap-3 text-xs text-[#475467]">
                  <span className="truncate">{r.nguon ? `${r.nguon}, chủ trì: ` : "Chủ trì: "}{r.donVi}</span><span className="shrink-0">{r.vb}</span>
                </span>
                <span className="mt-1 flex items-center justify-between gap-3 text-xs text-[#475467]">
                  <span>Hạn: {r.han}</span>
                  <Nhan t={qh ? `${r.tre} ngày quá hạn` : `Còn ${conLai} ngày`} c="#fff" bg={qh ? C.xau : C.warn} />
                </span>
              </button>
            </li>
          );
        })}
      </ul>
      {ban && <BanGhi r={ban} truong={cfg.truong || cfg.cot} tieuDe={ban.ten} onClose={() => setBan(null)} />}
    </div>
  );
}

/* Bảng tóm tắt bấm từng dòng để xem bản ghi; có nút mở danh sách đầy đủ ở lớp 3 */
function BangNho({ rows, cot, cfg, moDayDu, chuThich }) {
  const [ban, setBan] = useState(null);
  return (
    <div className="flex h-full flex-col">
      <div className="min-h-0 flex-1 overflow-auto">
        <table className="w-full text-left text-sm">
          <thead><tr>{cot.map((c) => <th key={c.k} className={`${thCls} ${c.right ? "text-right" : ""}`}>{c.ten}</th>)}</tr></thead>
          <tbody>{rows.map((r, i) => (
            <tr key={i} className="cursor-pointer border-b border-[#E4E7EC] hover:bg-[#FAFBFC]" onClick={() => (r.__mo ? r.__mo() : setBan(r))}>
              {cot.map((c) => <td key={c.k} className={`px-2 py-2 ${c.right ? "text-right tabular-nums" : ""} ${c.nowrap ? "whitespace-nowrap" : ""}`} style={{ color: c.chinh ? P.navy : P.ink2, fontWeight: c.chinh ? 600 : 400 }}>{c.render ? c.render(r[c.k], r) : c.clamp ? <span className="line-clamp-2">{r[c.k]}</span> : r[c.k]}</td>)}
            </tr>))}
          </tbody>
        </table>
      </div>
      {ban && cfg && <BanGhi r={ban} truong={cfg.truong || cfg.cot} tieuDe={cfg.tenBanGhi ? cfg.tenBanGhi(ban) : ""} onClose={() => setBan(null)} />}
    </div>
  );
}

/* Bố cục trang lớp 2: hàng thẻ KPI + lưới biểu đồ (7/12) + khối bảng có thẻ chọn (5/12) */
function TrangLinhVuc({ kpi, o, bang, hangDeu = false, soCot = 4 }) {
  const [chon, setChon] = useState(bang[0].id);
  const b = bang.find((x) => x.id === chon) || bang[0];
  const moDu = b.el && b.el.props ? b.el.props.moDayDu : null;
  const sorted = [...o].sort((a, c) => (c.rong ? 1 : 0) - (a.rong ? 1 : 0));
  let used = 0;
  const span = sorted.map((x, i) => { const full = x.rong || (used % 2 === 0 && i === sorted.length - 1); used += full ? 2 : 1; return full; });
  const rows = Math.ceil(used / 2);
  const luoi = { gridTemplateColumns: "repeat(2, minmax(0, 1fr))", gridTemplateRows: !hangDeu && sorted.some((x) => x.rong) && rows > 1 ? `minmax(0, 1.25fr) repeat(${rows - 1}, minmax(0, 1fr))` : `repeat(${rows}, minmax(0, 1fr))` };
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid flex-none gap-5" style={{ height: soCot > 5 ? 128 : 156, gridTemplateColumns: `repeat(${soCot}, minmax(0, 1fr))` }}>{kpi.map((k) => <Kpi key={k.nhan} nho={soCot > 5} {...k} />)}</div>
      <div className="grid min-h-0 flex-1 grid-cols-12 gap-10">
        <div className="col-span-7 grid min-h-0 gap-x-10 gap-y-5" style={luoi}>
          {sorted.map((x, i) => <Muc key={x.key} tieuDe={x.tieuDe} phai={x.phai} className={span[i] ? "col-span-2" : ""}>{x.el}</Muc>)}
        </div>
        <Muc className="col-span-5" tieuDe={bang.length === 1 ? b.ten : undefined}
          phai={(bang.length > 1 || moDu) && (
            <div className="flex flex-1 items-center justify-between gap-3">
              {bang.length > 1 ? <Seg items={bang.map((x) => [x.id, x.ten])} value={chon} onChange={setChon} /> : <span />}
              {moDu && <button onClick={moDu} className="inline-flex shrink-0 items-center gap-1 rounded-lg border border-[#D9DEE7] px-3 py-1 text-sm font-semibold text-[#1D6FE8] hover:bg-[#EEF4FF]">Mở danh sách đầy đủ<Icon name="mui-ten" size={15} /></button>}
            </div>)}>{b.el}</Muc>
      </div>
    </div>
  );
}
const pctTong = (n, t) => `${so(tyLe(n, t), 1)}%`;

/* =========================================================================
   LỚP 2 – NHIỆM VỤ: Trung ương giao
   ========================================================================= */
function NvTrungUong({ mo }) {
  const thang = theoThang(NV_DS, (x) => x.giao);
  const donDoc = NV_DS.filter((x) => x.nhomKey === "qh" || x.nhomKey === "gh").sort((a, b) => b.tre - a.tre);
  const nhom = NV_NGUON.flatMap((ng) => ng.nhom.map(([ten]) => { const xs = NV_DS.filter((x) => x.nguonId === ng.id && x.nhom === ten); return { nhom: ten, nguon: ng.ngan, tong: xs.length, xong: xs.filter((x) => x.nhomKey === "done").length, qh: xs.filter((x) => x.nhomKey === "qh").length, __mo: () => mo({ trang: "nv", lop: 3, ds: "nv", loc: { nhom: ten, nguon: ng.ten }, nhan: `Nhóm ${ten}` }) }; })).sort((a, b) => b.tong - a.tong);
  const dv = DV_BO.concat("Bộ Tư pháp", "Cục Kiểm soát thủ tục hành chính").map((d) => { const xs = NV_DS.filter((x) => x.donVi === d); return { donVi: d, tong: xs.length, xong: xs.filter((x) => x.nhomKey === "done").length, dang: xs.filter((x) => x.nhomKey === "th" || x.nhomKey === "gh").length, qh: xs.filter((x) => x.nhomKey === "qh").length, __mo: () => mo({ trang: "nv", lop: 3, ds: "nv", loc: { donVi: d }, nhan: d }) }; }).filter((x) => x.tong).sort((a, b) => b.qh - a.qh || b.tong - a.tong);
  const k = (key, icon, xu) => ({ nhan: NHOM_TT[key][0], gt: so(NV_NHOM_DEM[key]), dv: "nhiệm vụ", icon, xu, ky: `${pctTong(NV_NHOM_DEM[key], NV_TONG)} trên ${so(NV_TONG)} nhiệm vụ`, ring: key === "done" ? NV_NHOM_DEM[key] / NV_TONG : undefined, ringMau: C.tot,
    onClick: () => mo({ trang: "nv", lop: 3, ds: "nv", loc: { ttNhom: NHOM_TT[key][0] }, nhan: NHOM_TT[key][0] }) });
  const kpi = [k("done", "nv", "tot"), k("th", "nv"), k("gh", "dong-ho", "warn"), k("qh", "canh-bao", "xau")];
  const o = [
    { key: "thang", rong: true, tieuDe: "Xu hướng theo tháng giao (năm 2026)", el: <Columns stack kys={THANG_2026} series={NHOM_KEYS.map((nk) => ({ ten: NHOM_TT[nk][0], color: NHOM_TT[nk][1], vals: thang.map((xs) => xs.filter((x) => x.nhomKey === nk).length) }))} /> },
    { key: "tq", tieuDe: "Tổng quan tiến độ nhiệm vụ", el: <Donut giua={so(NV_TONG)} phu="tổng nhiệm vụ" parts={NHOM_KEYS.map((nk) => ({ ten: NHOM_TT[nk][0], v: NV_NHOM_DEM[nk], color: NHOM_TT[nk][1] }))} /> },
    { key: "nguon", tieuDe: "Nguồn giao nhiệm vụ", el: <HBars rows={NV_NGUON.map((ng) => ({ nhan: ng.ten, id: ng.id, ...demTheo(NV_DS.filter((x) => x.nguonId === ng.id), (x) => x.nhomKey, NHOM_KEYS) }))} onRow={(r) => mo({ trang: "nv", lop: 2, nguon: r.id, nhan: `Thống kê chi tiết: ${r.nhan}` })}
      segs={NHOM_KEYS.map((nk) => ({ ten: NHOM_TT[nk][0], color: NHOM_TT[nk][1], v: (r) => r[nk] }))} giaTri={(r) => `${so(NHOM_KEYS.reduce((a, nk) => a + r[nk], 0))} nhiệm vụ, xem chi tiết`} /> },
  ];
  const bang = [
    { id: "dd", ten: `Cần đôn đốc (${donDoc.length})`, el: <DonDoc rows={donDoc} cfg={DS.nv} /> },
    { id: "nhom", ten: "Theo nhóm văn bản", el: <BangNho rows={nhom} moDayDu={() => mo({ trang: "nv", lop: 3, ds: "nv", nhan: "Danh sách đầy đủ" })}
      cot={[{ k: "nhom", ten: "Nhóm", chinh: true }, { k: "nguon", ten: "Nguồn giao" }, { k: "tong", ten: "Tổng", right: true }, { k: "xong", ten: "Hoàn thành", right: true }, { k: "qh", ten: "Quá hạn", right: true, render: (v) => <b style={{ color: v ? C.xau : "#98A2B3" }}>{v}</b> }]} /> },
    { id: "dv", ten: "Theo đơn vị chủ trì", el: <BangNho rows={dv}
      cot={[{ k: "donVi", ten: "Đơn vị", chinh: true }, { k: "tong", ten: "Tổng", right: true }, { k: "xong", ten: "Hoàn thành", right: true }, { k: "dang", ten: "Đang làm", right: true }, { k: "qh", ten: "Quá hạn", right: true, render: (v) => <b style={{ color: v ? C.xau : "#98A2B3" }}>{v}</b> }]} /> },
  ];
  return <TrangLinhVuc kpi={kpi} o={o} bang={bang} />;
}

/* LỚP 2 (nhánh): Thống kê chi tiết theo nguồn giao – tiến độ theo nhóm, xu hướng tháng, bảng chi tiết */
function NvNguon({ id }) {
  const ng = NV_NGUON.find((x) => x.id === id);
  const ds = NV_DS.filter((x) => x.nguonId === id);
  const [nhomChon, setNhomChon] = useState("");
  const thang = theoThang(ds, (x) => x.giao);
  const cfg = { ...DS.nv, tieuDe: `Chi tiết nhiệm vụ do ${ng.ten} giao`, rows: ds, boLoc: DS.nv.boLoc.filter((b) => b.k !== "nguon") };
  const SEG4 = [["done", "Đã hoàn thành"], ["th", "Đang TH trong hạn"], ["gh", "Gần hạn"], ["qh", "Đang TH quá hạn"]];
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid flex-none grid-cols-12 gap-10" style={{ height: 330 }}>
        <Muc className="col-span-7" tieuDe="Tiến độ theo nhóm nhiệm vụ" >
          <HBars motDong rows={ng.nhom.map(([ten]) => ({ nhan: ten, ...demTheo(ds.filter((x) => x.nhom === ten), (x) => x.nhomKey, NHOM_KEYS) }))} onRow={(r) => setNhomChon(r.nhan)}
            segs={SEG4.map(([k, t]) => ({ ten: t, color: NHOM_TT[k][1], v: (r) => r[k] }))} giaTri={(r) => `${r.done}/${NHOM_KEYS.reduce((a, k) => a + r[k], 0)}`} />
        </Muc>
        <Muc className="col-span-5" tieuDe="Xu hướng theo tháng giao">
          <Columns stack kys={THANG_2026} series={NHOM_KEYS.map((nk) => ({ ten: NHOM_TT[nk][0], color: NHOM_TT[nk][1], vals: thang.map((xs) => xs.filter((x) => x.nhomKey === nk).length) }))} />
        </Muc>
      </div>
      <Muc className="min-h-0 flex-1"><DanhSach key={nhomChon} cfg={cfg} locBanDau={nhomChon ? { nhom: nhomChon } : {}} /></Muc>
    </div>
  );
}

/* LỚP 2 – NHIỆM VỤ: Lãnh đạo Bộ giao */
function NvLanhDaoBo({ mo }) {
  const T = LDB_TONG_TT, tong = LDB_DS.length, xong = T.htdh + T.htqh;
  const moDs = (loc, nhan) => mo({ trang: "nv", lop: 3, ds: "ldb", loc, nhan });
  const kpi = [
    { nhan: "Tổng nhiệm vụ", gt: so(tong), icon: "nv", ky: "Lãnh đạo Bộ giao", onClick: () => moDs({}, "Tất cả") },
    { nhan: "Đã hoàn thành", gt: so(xong), icon: "nv", xu: "tot", ky: pctTong(xong, tong), onClick: () => moDs({ daHT: "Đã hoàn thành" }, "Đã hoàn thành") },
    ...LDB_KEYS.map((key) => ({ nhan: LDB_TT[key][0], gt: so(T[key]), icon: key === "qh" ? "canh-bao" : key === "gh" ? "dong-ho" : "nv", xu: key === "htdh" ? "tot" : key === "qh" ? "xau" : key === "htqh" || key === "gh" ? "warn" : undefined,
      ky: pctTong(T[key], tong), onClick: () => moDs({ ttTen: LDB_TT[key][0] }, LDB_TT[key][0]) })),
  ];
  const donDoc = LDB_DS.filter((x) => x.tt === "qh" || x.tt === "gh").sort((a, b) => b.tre - a.tre);
  const SEGC = [["htdh", C.tot], ["htqh", C.warn], ["th", C.info], ["gh", "#FDB022"], ["qh", C.xau]];
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid flex-none gap-4" style={{ height: 128, gridTemplateColumns: "repeat(7, minmax(0, 1fr))" }}>{kpi.map((k) => <Kpi key={k.nhan} nho {...k} />)}</div>
      <div className="grid min-h-0 flex-1 grid-cols-12 gap-10">
        <div className="col-span-7 grid min-h-0 gap-5" style={{ gridTemplateRows: "minmax(0, 1.5fr) minmax(0, 1fr)" }}>
          <Muc tieuDe="Tiến độ thực hiện nhiệm vụ theo đơn vị" >
            <div className="h-full overflow-auto">
              <table className="w-full text-left text-sm">
                <thead><tr><th className={thCls}>Đơn vị chủ trì</th><th className={`${thCls} text-right`}>Tổng</th><th className={`${thCls} w-56`}>Biểu đồ tỷ lệ</th>{LDB_KEYS.map((k) => <th key={k} className={`${thCls} text-right`}>{LDB_TT[k][0].replace("Chưa HT ", "")}</th>)}</tr></thead>
                <tbody>{LDB_DV.map(([dv, ...v]) => { const t = v.reduce((a, b) => a + b, 0); return (
                  <tr key={dv} className="cursor-pointer border-b border-[#E4E7EC] hover:bg-[#FAFBFC]" onClick={() => moDs({ donVi: dv }, dv)}>
                    <td className="px-2 py-2 font-semibold text-[#101828]">{dv}</td>
                    <td className="px-2 py-2 text-right font-semibold tabular-nums text-[#101828]">{so(t)}</td>
                    <td className="px-2 py-2"><div className="flex h-2.5 overflow-hidden rounded-sm" style={{ background: C.track }}>{SEGC.map(([k, c], j) => <div key={k} style={{ width: `${tyLe(v[j], t)}%`, background: c }} />)}</div></td>
                    {v.map((n, j) => <td key={j} className="px-2 py-2 text-right tabular-nums" style={{ color: n ? SEGC[j][1] : "#98A2B3", fontWeight: n ? 600 : 400 }}>{so(n)}</td>)}
                  </tr>); })}
                </tbody>
              </table>
            </div>
          </Muc>
          <Muc tieuDe="Xu hướng theo tuần">
            <Columns kys={LDB_TUAN.ky} series={[{ ten: "Tồn tuần trước", color: "#98A2B3", vals: LDB_TUAN.ton }, { ten: "Tiếp nhận mới", color: "#0BA5EC", vals: LDB_TUAN.moi }, { ten: "Hoàn thành trong tuần", color: C.tot, vals: LDB_TUAN.xong }]} />
          </Muc>
        </div>
        <Muc className="col-span-5" tieuDe={`Cần đôn đốc (${donDoc.length})`}><DonDoc rows={donDoc} cfg={DS.ldb} /></Muc>
      </div>
    </div>
  );
}

/* LỚP 2 – XÂY DỰNG PHÁP LUẬT */
function TrangXdpl({ mo }) {
  const m = (ds, loc, nhan) => () => mo({ trang: "xdpl", lop: 3, ds, loc, nhan });
  const kpi = [
    { nhan: "Văn bản đã đưa vào chương trình", gt: `${XD_TOM.dua[0]}/${XD_TOM.dua[1]}`, icon: "xdpl", ky: "Luật, pháp lệnh, nghị quyết", ring: XD_TOM.dua[0] / XD_TOM.dua[1], onClick: m("luat", { ctTen: CT_CT.dua[0] }, "Đã đưa vào chương trình") },
    { nhan: "Chương trình đã hoàn thành xây dựng", gt: `${XD_TOM.ctHT[0]}/${XD_TOM.ctHT[1]}`, icon: "xdpl", ky: "Đã được thông qua", ring: XD_TOM.ctHT[0] / XD_TOM.ctHT[1], onClick: m("luat", { ctTen: CT_CT.dua[0], stTen: CT_ST.tq[0] }, "Chương trình đã hoàn thành") },
    { nhan: "VB chi tiết đã thông qua, ban hành", gt: `${XD_TOM.qdct[0]}/${XD_TOM.qdct[1]}`, icon: "xdpl", ky: `Tỷ lệ ${pt(XD_TOM.tyLe, 2)}`, ring: XD_TOM.qdct[0] / XD_TOM.qdct[1], ringMau: C.warn, onClick: m("qdct", { stTen: QD_ST.tq[0] }, "VB chi tiết đã thông qua") },
    { nhan: "VB theo thẩm quyền đã hoàn thành", gt: `${XD_TOM.tq[0]}/${XD_TOM.tq[1]}`, icon: "xdpl", ky: "Thông tư, quyết định của Bộ", ring: XD_TOM.tq[0] / XD_TOM.tq[1], onClick: m("tq", {}, "VB theo thẩm quyền") },
  ];
  const cqs = [...new Set(QD_DS.map((x) => x.cq))].map((cq) => ({ nhan: cq, ...demTheo(QD_DS.filter((x) => x.cq === cq), (x) => x.st, Object.keys(QD_ST)) })).map((r) => ({ ...r, t: Object.keys(QD_ST).reduce((a, k) => a + r[k], 0) })).sort((a, b) => b.t - a.t).slice(0, 9);
  const luatNo = [...new Set(QD_DS.filter((x) => x.st === "no").map((x) => x.luat))].map((l) => ({ luat: l, n: QD_DS.filter((x) => x.st === "no" && x.luat === l).length, cq: QD_DS.find((x) => x.luat === l).cq, __mo: m("qdct", { luat: l, stTen: QD_ST.no[0] }, "VB nợ của một luật") })).sort((a, b) => b.n - a.n);
  const loai = QD_LOAI.map(([l]) => { const xs = QD_DS.filter((x) => x.loai === l); return { loai: l, tong: xs.length, tq: xs.filter((x) => x.st === "tq").length, no: xs.filter((x) => x.st === "no").length, xd: xs.filter((x) => x.st === "xd" || x.st === "sap").length, __mo: m("qdct", { loai: l }, l) }; });
  const CanhBao = ({ n, t, phu, c, onClick }) => (
    <li className="border-b border-[#E4E7EC]">
      <button onClick={onClick} className="flex w-full items-center gap-3 rounded-md px-2 py-3 text-left hover:bg-[#FAFBFC] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]">
        <i className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: c }} />
        <span className="min-w-0 flex-1"><span className="block text-sm font-semibold text-[#101828]">{t}</span><span className="block text-xs text-[#475467]">{phu}</span></span>
        <b className="shrink-0 tabular-nums" style={{ fontSize: 24, color: c, lineHeight: 1 }}>{n}</b>
        <Icon name="mui-ten" size={16} color="#98A2B3" />
      </button>
    </li>
  );
  const o = [
    { key: "cq", rong: true, tieuDe: "Văn bản quy định chi tiết theo cơ quan chủ trì",
      el: <HBars motDong nhanW={250} rows={cqs} onRow={(r) => mo({ trang: "xdpl", lop: 3, ds: "qdct", loc: { cq: r.nhan }, nhan: r.nhan })} segs={[["tq", C.tot], ["xd", C.info], ["sap", C.warn], ["no", C.xau]].map(([k, c]) => ({ ten: QD_ST[k][0], color: c, v: (r) => r[k] }))} giaTri={(r) => `${r.tq}/${r.t}`} /> },
    { key: "cb", tieuDe: "Cảnh báo cần chỉ đạo", el: (
      <ul className="flex h-full flex-col justify-center">
        <CanhBao n={XD_TOM.noLuat} c={C.xau} t="Luật, NQ, pháp lệnh nợ văn bản" phu="Đã có hiệu lực, còn văn bản QĐCT chưa ban hành" onClick={m("qdct", { stTen: QD_ST.no[0] }, "Luật có hiệu lực nợ VB")} />
        <CanhBao n={XD_TOM.cham} c={C.xau} t="VB quy định chi tiết chậm, nợ" phu={`${pt(tyLe(XD_TOM.cham, XD_TOM.qdct[1]), 1)} trong ${XD_TOM.qdct[1]} văn bản QĐCT`} onClick={m("qdct", { stTen: QD_ST.no[0] }, "VB chậm, nợ ban hành")} />
        <CanhBao n={XD_TOM.sapToi} c={C.warn} t="VB quy định chi tiết sắp đến hạn" phu="Phải ban hành trong thời gian tới" onClick={m("qdct", { stTen: QD_ST.sap[0] }, "VB sắp đến hạn")} />
      </ul>) },
    { key: "luat", tieuDe: "Dự án luật theo trạng thái", el: <Donut giua={so(LUAT_DS.length)} phu="văn bản" parts={Object.entries(CT_ST).map(([k, [t]], i) => ({ ten: t.replace("/tạm dừng", ""), v: LUAT_DS.filter((x) => x.st === k).length, color: [C.tot, C.warn, C.tx][i] }))} /> },
  ];
  const bang = [
    { id: "no", ten: `Luật nợ văn bản (${luatNo.length})`, el: <BangNho rows={luatNo} moDayDu={m("qdct", { stTen: QD_ST.no[0] }, "VB chậm, nợ ban hành")}
      cot={[{ k: "luat", ten: "Luật có hiệu lực", clamp: true, chinh: true }, { k: "cq", ten: "CQ chủ trì" }, { k: "n", ten: "VB nợ", right: true, render: (v) => <b style={{ color: C.xau }}>{v}</b> }]} /> },
    { id: "loai", ten: "Theo loại văn bản", el: <BangNho rows={loai} moDayDu={m("qdct", {}, "Toàn bộ VB chi tiết")}
      cot={[{ k: "loai", ten: "Loại", chinh: true }, { k: "tong", ten: "Tổng", right: true }, { k: "tq", ten: "Đã ban hành", right: true }, { k: "xd", ten: "Đang xây dựng", right: true }, { k: "no", ten: "Chậm, nợ", right: true, render: (v) => <b style={{ color: v ? C.xau : "#98A2B3" }}>{v}</b> }]} /> },
    { id: "btp", ten: "Luật Bộ Tư pháp chủ trì", el: <BangNho rows={LUAT_DS.filter((x) => x.cq === "Bộ Tư pháp")} cfg={DS.luat} moDayDu={m("luat", { cq: "Bộ Tư pháp" }, "Bộ Tư pháp chủ trì")}
      cot={[{ k: "ten", ten: "Tên văn bản", clamp: true, chinh: true }, { k: "han", ten: "Hạn trình" }, { k: "stTen", ten: "Trạng thái", render: pillTen(CT_ST) }]} /> },
  ];
  return <TrangLinhVuc kpi={kpi} o={o} bang={bang} />;
}

/* LỚP 2 – PHẢN ÁNH, KIẾN NGHỊ */
function TrangPakn({ mo }) {
  const T = PAKN_TOM, m = (loc, nhan) => () => mo({ trang: "pakn", lop: 3, ds: "pakn", loc, nhan });
  const kpi = [
    { nhan: "Tổng phản ánh", gt: so(T.tong), dv: "phản ánh", icon: "pakn", ky: "Tháng 11/2026", onClick: m({}, "Tất cả") },
    { nhan: "Đã hoàn thành", gt: so(T.xong), icon: "pakn", xu: "tot", ky: pctTong(T.xong, T.tong), ring: T.xong / T.tong, ringMau: C.tot, onClick: m({ stTen: PAKN_ST.xong[0] }, "Đã hoàn thành") },
    { nhan: "Đang xử lý quá hạn", gt: so(T.qh), icon: "canh-bao", xu: "xau", ky: pctTong(T.qh, T.tong), ring: T.qh / T.tong, ringMau: C.xau, onClick: m({ stTen: PAKN_ST.qh[0] }, "Đang xử lý quá hạn") },
    { nhan: "Đang xử lý trong hạn", gt: so(T.th), icon: "pakn", ky: pctTong(T.th, T.tong), ring: T.th / T.tong, onClick: m({ stTen: PAKN_ST.th[0] }, "Đang xử lý trong hạn") },
  ];
  const theo = (k, list) => list.map(([ten]) => ({ nhan: ten, ...demTheo(PAKN_DS.filter((x) => x[k] === ten), (x) => x.st, Object.keys(PAKN_ST)) }));
  const segs = [["xong", C.tot], ["th", C.info], ["qh", C.xau]].map(([k, c]) => ({ ten: PAKN_ST[k][0], color: c, v: (r) => r[k] }));
  const o = [
    { key: "cq", rong: true, tieuDe: "Theo cơ quan xử lý", el: <HBars motDong nhanW={250} rows={theo("cq", PAKN_CQ)} segs={segs} onRow={(r) => mo({ trang: "pakn", lop: 3, ds: "pakn", loc: { cq: r.nhan }, nhan: r.nhan })} giaTri={(r) => `${r.xong + r.th + r.qh} phản ánh, ${r.qh} quá hạn`} /> },
    { key: "lv", tieuDe: "Theo lĩnh vực", el: <HBars motDong nhanW={130} rows={theo("lv", PAKN_LV).slice(0, 7)} segs={segs} onRow={(r) => mo({ trang: "pakn", lop: 3, ds: "pakn", loc: { lv: r.nhan }, nhan: r.nhan })} giaTri={(r) => `${r.xong + r.th + r.qh}`} /> },
    { key: "hl", tieuDe: "Mức độ hài lòng", el: <Donut giua={pt(PAKN_SAT[0][1] + PAKN_SAT[1][1])} phu="hài lòng trở lên" fmt={(v) => pt(v, 2)} phanTram={false} parts={PAKN_SAT.map(([ten, v, color]) => ({ ten, v, color }))} /> },
  ];
  const qhLau = PAKN_DS.filter((x) => x.st === "qh").sort((a, b) => b.tre - a.tre);
  const bang = [
    { id: "qh", ten: `Quá hạn (${qhLau.length})`, el: <BangNho rows={qhLau} cfg={DS.pakn} moDayDu={m({ stTen: PAKN_ST.qh[0] }, "Đang xử lý quá hạn")}
      cot={[{ k: "ma", ten: "Mã", nowrap: true }, { k: "nd", ten: "Nội dung", clamp: true, chinh: true }, { k: "cq", ten: "Cơ quan" }, { k: "tre", ten: "Quá hạn", right: true, nowrap: true, render: (v) => <b style={{ color: C.xau }}>{v} ngày</b> }]} /> },
    { id: "kenh", ten: "Theo kênh tiếp nhận", el: <BangNho rows={["Cổng Dịch vụ công quốc gia", "Cổng tiếp nhận phản ánh, kiến nghị", "Văn phòng Chính phủ chuyển"].map((k) => { const xs = PAKN_DS.filter((x) => x.kenh === k); return { kenh: k, tong: xs.length, xong: xs.filter((x) => x.st === "xong").length, qh: xs.filter((x) => x.st === "qh").length, __mo: m({ kenh: k }, k) }; })}
      cot={[{ k: "kenh", ten: "Kênh", chinh: true }, { k: "tong", ten: "Tổng", right: true }, { k: "xong", ten: "Đã xong", right: true }, { k: "qh", ten: "Quá hạn", right: true, render: (v) => <b style={{ color: C.xau }}>{v}</b> }]} /> },
  ];
  return <TrangLinhVuc kpi={kpi} o={o} bang={bang} />;
}

/* LỚP 2 – THI HÀNH ÁN DÂN SỰ */
/* Bảng xếp hạng cơ quan THADS địa phương: cột = tỷ lệ đạt được, đường cam = trung bình toàn quốc, đường xanh lá = chỉ tiêu giao */
function XepHang({ rows, tb, ct, onBar }) {
  const [ref, { w: W, h: H }] = useSize();
  const [hv, setHv] = useState(null);
  const ds = [...rows].sort((a, b) => b.v - a.v);
  const top = 10, bottom = 70, ml = 40, mr = 8;
  const ticks = niceTicks(Math.max(ct, ...ds.map((r) => r.v)), 5), mx = ticks[ticks.length - 1];
  const band = (W - ml - mr) / ds.length, bw = Math.max(4, band * 0.7);
  const Y = (v) => top + (1 - v / mx) * (H - top - bottom);
  const X = (i) => ml + i * band + band / 2;
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={[{ ten: "Tỷ lệ đạt được", color: ACC }, { ten: `Trung bình toàn quốc ${pt(tb, 2)}`, color: C.warn, line: true }, { ten: `Chỉ tiêu giao ${pt(ct, 2)}`, color: C.tot, line: true }]} />
      <div ref={ref} className="relative min-h-0 flex-1" onMouseLeave={() => setHv(null)}>
        <svg className="absolute inset-0" width={W} height={H} viewBox={`0 0 ${W} ${H}`}>
          {ticks.map((t) => <g key={t}><line x1={ml} x2={W - mr} y1={Y(t)} y2={Y(t)} stroke={C.grid} /><text x={ml - 6} y={Y(t)} dy="0.32em" textAnchor="end" fontSize="12" fill={P.mo}>{t}</text></g>)}
          {ds.map((r, i) => (
            <g key={r.ten} onMouseEnter={() => setHv(i)} onClick={() => onBar && onBar(r)} style={{ cursor: onBar ? "pointer" : "default" }}>
              <rect x={ml + i * band} y={top} width={band} height={H - top - bottom} fill={hv === i ? "#F2F4F7" : "transparent"} />
              <rect x={X(i) - bw / 2} y={Y(r.v)} width={bw} height={Y(0) - Y(r.v)} rx="2" fill={r.v >= ct ? C.tot : ACC} opacity={hv === null || hv === i ? 1 : 0.75} />
              <text transform={`translate(${X(i) + 3},${H - bottom + 8}) rotate(-45)`} textAnchor="end" fontSize="11" fill={P.ink2}>{`${String(i + 1).padStart(2, "0")}. ${r.ten}`}</text>
            </g>
          ))}
          <line x1={ml} x2={W - mr} y1={Y(tb)} y2={Y(tb)} stroke={C.warn} strokeWidth="2" />
          <line x1={ml} x2={W - mr} y1={Y(ct)} y2={Y(ct)} stroke={C.tot} strokeWidth="2" />
        </svg>
        {hv != null && <Tip left={(X(hv) / W) * 100} tieuDe={`${String(hv + 1).padStart(2, "0")}. ${ds[hv].ten}`} dong={[[ACC, "Tỷ lệ đạt được", pt(ds[hv].v, 2)], [C.warn, "Trung bình toàn quốc", pt(tb, 2)], [C.tot, "Chỉ tiêu giao", pt(ct, 2)], [P.navy, "Đạt so với chỉ tiêu", pt(datChiTieu(ds[hv].v, ct), 2)]]} />}
      </div>
    </div>
  );
}
/* Ô cơ cấu: hai thành phần và dòng tổng */
function CoCau({ tieuDe, chuGiai, rows, tongTen, tongGt, mauTong, ghiChu }) {
  const mx = Math.max(...rows.map((r) => r[1]));
  return (
    <div className="flex h-full min-h-0 flex-col rounded-xl border border-[#D9DEE7] px-4 py-3">
      <div className="flex items-center justify-between gap-3"><h4 className="text-[15px] font-semibold text-[#101828]">{tieuDe}</h4><span className="text-xs text-[#475467]">{chuGiai}</span></div>
      <ul className="flex min-h-0 flex-1 flex-col justify-around">
        {rows.map(([t, v, c, fm]) => (
          <li key={t} className="flex items-center gap-3 text-sm">
            <span className="shrink-0 whitespace-nowrap text-[#344054]" style={{ width: 168 }}>{t}</span>
            <span className="h-2.5 flex-1 overflow-hidden rounded-sm" style={{ background: C.track }}><span className="block h-full" style={{ width: `${(v / mx) * 100}%`, background: c }} /></span>
            <b className="shrink-0 text-right tabular-nums text-[#101828]" style={{ minWidth: 86 }}>{fm ? fm(v) : so(v)}</b>
          </li>))}
      </ul>
      <div className="flex items-baseline justify-between border-t border-[#E4E7EC] pt-2"><span className="text-sm text-[#475467]">{tongTen}</span><b className="tabular-nums" style={{ fontSize: 22, color: mauTong }}>{tongGt}</b></div>
      {ghiChu && <p className="mt-1 text-xs" style={{ color: C.warn }}>{ghiChu}</p>}
    </div>
  );
}
/* LỚP 2 – THI HÀNH ÁN DÂN SỰ / VIỆC VÀ TIỀN THI HÀNH XONG: một dòng về việc, một dòng về tiền */
function TrangThads({ mo, cuon }) {
  const cuonRef = useRef(null);
  useEffect(() => { const el = cuonRef.current; if (!el) return; const t = cuon === "tien" ? el.querySelector("[data-dong=tien]") : null; el.scrollTo({ top: t ? t.offsetTop - el.offsetTop : 0, behavior: "smooth" }); }, [cuon]);
  const m = (loc, nhan) => mo({ trang: "thads", lop: 3, ds: "thads", loc, nhan });
  const ttV = datChiTieu(THA.tlViec, THA_CHI_TIEU.viec), ttT = datChiTieu(THA.tlTien, THA_CHI_TIEU.tien);
  const MAU = "Số mẫu, chờ Cục QL THADS cung cấp";
  const dong = [
    { id: "viec", ten: "1. Về việc", ct: THA_CHI_TIEU.viec, tb: THA.tlViec, k: "tlViec",
      kpi: [
        { nhan: "Tổng số việc phải thi hành", gt: so(THA.viecPhai), dv: "việc", icon: "thads", ky: cungKyText("viecPhai", THA.viecPhai) },
        { nhan: "Tổng số việc có điều kiện", gt: so(THA.viecDK), dv: "việc", icon: "thads", ky: cungKyText("viecDK", THA.viecDK) },
        { nhan: "Tổng số việc giải quyết xong", gt: so(THA.viecXong), dv: "việc", icon: "thads", xu: "tot", ky: cungKyText("viecXong", THA.viecXong) },
        { nhan: "Tỷ lệ việc thi hành xong (%)", gt: pt(THA.tlViec, 2), icon: "thads", xu: xuNguong(THA.tlViec, THA_CHI_TIEU.viec), ky: `Chỉ tiêu ${pt(THA_CHI_TIEU.viec)}, đạt ${pt(ttV, 2)} chỉ tiêu` },
      ],
      coCau: [
        <CoCau key="n" tieuDe="Nguồn tiếp nhận" chuGiai="Số việc" rows={[["Thụ lý mới trong kỳ", THA.viecMoi, ACC], ["Kỳ trước chuyển sang", THA.viecTruoc, "#98A2B3"]]} tongTen="Tổng số việc phải thi hành" tongGt={so(THA.viecPhai)} mauTong={ACC} />,
        <CoCau key="p" tieuDe="Phân loại điều kiện thi hành" chuGiai="Số việc" rows={[["Có điều kiện thi hành", THA.viecDK, "#0BA5EC"], ["Chưa có điều kiện, khác", THA.viecChuaDK, "#98A2B3"]]} tongTen="Tỷ lệ có điều kiện thi hành" tongGt={pt(tyLe(THA.viecDK, THA.viecPhai), 2)} mauTong="#0BA5EC" />,
      ] },
    { id: "tien", ten: "2. Về tiền", ct: THA_CHI_TIEU.tien, tb: THA.tlTien, k: "tlTien",
      kpi: [
        { nhan: "Tổng số tiền phải thi hành", gt: so(THA_MAU_TIEN.phai, 1), dv: "tỷ đồng", icon: "thads", ky: MAU },
        { nhan: "Tổng số tiền có điều kiện", gt: so(THA.tienDK, 1), dv: "tỷ đồng", icon: "thads", ky: cungKyText("tienDK", THA.tienDK) },
        { nhan: "Tổng số tiền giải quyết xong", gt: so(THA.tienXong, 1), dv: "tỷ đồng", icon: "thads", xu: "tot", ky: cungKyText("tienXong", THA.tienXong) },
        { nhan: "Tỷ lệ tiền thi hành xong (%)", gt: pt(THA.tlTien, 2), icon: "thads", xu: xuNguong(THA.tlTien, THA_CHI_TIEU.tien), ky: `Chỉ tiêu ${pt(THA_CHI_TIEU.tien, 2)}, đạt ${pt(ttT, 2)} chỉ tiêu` },
      ],
      coCau: [
        <CoCau key="n" tieuDe="Nguồn tiếp nhận" chuGiai="Tỷ đồng" rows={[["Thụ lý mới trong kỳ", THA_MAU_TIEN.moi, ACC, (v) => so(v, 1)], ["Kỳ trước chuyển sang", THA_MAU_TIEN.truoc, "#98A2B3", (v) => so(v, 1)]]} tongTen="Tổng số tiền phải thi hành" tongGt={so(THA_MAU_TIEN.phai, 1)} mauTong={ACC} ghiChu={MAU} />,
        <CoCau key="p" tieuDe="Phân loại điều kiện thi hành" chuGiai="Tỷ đồng" rows={[["Có điều kiện thi hành", THA.tienDK, "#0BA5EC", (v) => so(v, 1)], ["Chưa có điều kiện, khác", THA_MAU_TIEN.chuaDK, "#98A2B3", (v) => so(v, 1)]]} tongTen="Tỷ lệ có điều kiện thi hành" tongGt={pt(tyLe(THA.tienDK, THA_MAU_TIEN.phai), 2)} mauTong="#0BA5EC" ghiChu={MAU} />,
      ] },
  ];
  return (
    <div ref={cuonRef} className="h-full overflow-auto pr-2">
      {dong.map((d) => (
        <section key={d.id} data-dong={d.id} className="flex flex-col gap-3" style={{ height: 548, marginBottom: 28 }}>
          <div className="flex flex-none items-center gap-4">
            <h3 className="text-[17px] font-semibold text-[#101828]">{d.ten}</h3>
            <span className="text-sm text-[#475467]">Chỉ tiêu giao năm 2026: <b className="text-[#101828]">{pt(d.ct, 2)}</b></span>
            <button onClick={() => m({}, d.id === "viec" ? "Về việc" : "Về tiền")} className="ml-auto inline-flex items-center gap-1 rounded-lg border border-[#D9DEE7] px-3 py-1 text-sm font-semibold text-[#1D6FE8] hover:bg-[#EEF4FF]">Danh sách cơ quan THADS<Icon name="mui-ten" size={15} /></button>
          </div>
          <div className="grid flex-none grid-cols-4 gap-4" style={{ height: 132 }}>{d.kpi.map((k) => <Kpi key={k.nhan} nho {...k} />)}</div>
          <div className="grid min-h-0 flex-1 grid-cols-12 gap-6" style={{ marginTop: 16 }}>
            <section className="col-span-6 flex min-h-0 flex-col">
              <h4 className="mb-2 text-[15px] font-semibold text-[#101828]">Cơ cấu hồ sơ {d.id === "viec" ? "về việc" : "về tiền"}, lũy kế đến 09/11/2026</h4>
              <div className="grid min-h-0 flex-1 grid-cols-2 gap-4">{d.coCau}</div>
            </section>
            <section className="col-span-6 flex min-h-0 flex-col">
              <h4 className="mb-2 text-[15px] font-semibold text-[#101828]">Xếp hạng cơ quan THADS địa phương theo tỷ lệ thi hành xong về {d.id === "viec" ? "việc" : "tiền"} (%)</h4>
              <div className="min-h-0 flex-1"><XepHang rows={DS.thads.rows.map((r) => ({ ten: r.tinh, v: r[d.k] }))} tb={d.tb} ct={d.ct} onBar={(r) => m({ tinh: r.ten }, r.ten)} /></div>
            </section>
          </div>
        </section>
      ))}
    </div>
  );
}

/* LỚP 2 – THỦ TỤC HÀNH CHÍNH */
function TrangTthc({ mo }) {
  const T = TTHC_TOM, m = (ds, nhan) => () => mo({ trang: "tthc", lop: 3, ds, nhan });
  const kpi = [
    { nhan: "Tổng số hồ sơ tiếp nhận", gt: so(T.luyKe), dv: "hồ sơ", icon: "tthc", ky: "Lũy kế năm 2026", spark: TTHC_THANG.nhan, onClick: m("tthc_lv", "Theo lĩnh vực") },
    { nhan: "Hồ sơ tháng 11/2026", gt: so(T.thang), dv: "hồ sơ", icon: "tthc", ky: "Đến 09/11/2026", onClick: m("tthc_dp", "Theo địa phương") },
    { nhan: "Tiếp nhận trực tuyến", gt: pt(T.tlTT), icon: "tthc", ky: `${so(T.tt)} trực tuyến, ${so(T.tiep)} trực tiếp`, ring: T.tlTT / 100 },
    { nhan: "Tỷ lệ đã xử lý", gt: pt(T.daXL), icon: "tthc", xu: xuNguong(T.daXL, 90), ky: `Hồ sơ từ chối ${pt(T.tuChoi)}`, ring: T.daXL / 100, ringMau: C.tot },
  ];
  const o = [
    { key: "th", rong: true, tieuDe: "Hồ sơ tiếp nhận và đã xử lý theo tháng", el: <Columns kys={TTHC_THANG.ky} series={[{ ten: "Tiếp nhận", color: ACC, vals: TTHC_THANG.nhan }, { ten: "Đã xử lý", color: C.tot, vals: TTHC_THANG.xl }]} /> },
    { key: "lv", tieuDe: "Tỷ lệ đúng hạn theo lĩnh vực", el: <HBars motDong nhanW={190} rows={[...TTHC_LV_DS].sort((a, b) => a.tlDH - b.tlDH).map((x) => ({ ...x, nhan: x.ten }))} max={100} overlay muc={{ v: 90, ten: "Ngưỡng 90%" }} onRow={() => mo({ trang: "tthc", lop: 3, ds: "tthc_lv", nhan: "Theo lĩnh vực" })}
      segs={[{ ten: "Đúng hạn", color: (r) => mauXu(xuNguong(r.tlDH, 90)), v: (r) => r.tlDH }]} giaTri={(r) => pt(r.tlDH)} /> },
    { key: "kenh", tieuDe: "Kênh tiếp nhận tháng 11", el: <Donut giua={pt(T.tlTT)} phu="trực tuyến" parts={[{ ten: "Trực tuyến", v: T.tt, color: ACC }, { ten: "Trực tiếp", v: T.tiep, color: C.tx }]} /> },
  ];
  const bang = [
    { id: "dp", ten: "Địa phương", el: <BangNho rows={TTHC_DP_DS} cfg={DS.tthc_dp} moDayDu={m("tthc_dp", "Theo địa phương")}
      cot={[{ k: "ten", ten: "Địa phương", chinh: true }, { k: "tong", ten: "Tiếp nhận", right: true, render: soO() }, { k: "dangQH", ten: "Đang XL quá hạn", right: true, render: (v) => <b style={{ color: C.xau }}>{so(v)}</b> }, { k: "tlDH", ten: "Đúng hạn", render: thanhO(90) }]} /> },
    { id: "lv", ten: "Lĩnh vực", el: <BangNho rows={TTHC_LV_DS} cfg={DS.tthc_lv} moDayDu={m("tthc_lv", "Theo lĩnh vực")}
      cot={[{ k: "ten", ten: "Lĩnh vực", chinh: true }, { k: "tong", ten: "Tiếp nhận", right: true, render: soO() }, { k: "tt", ten: "Trực tuyến", right: true, render: soO() }, { k: "tlDH", ten: "Đúng hạn", render: thanhO(90) }]} /> },
  ];
  return <TrangLinhVuc kpi={kpi} o={o} bang={bang} hangDeu />;
}

/* LỚP 2 – GIẢI NGÂN ĐẦU TƯ CÔNG */
function TrangGiaiNgan({ mo }) {
  const T = GN_TOM, m = (loc, nhan) => () => mo({ trang: "gn", lop: 3, ds: "gn", loc, nhan });
  const dem = (t) => GN_DS.filter((x) => x.ttTen === t).length;
  const kpi = [
    { nhan: "Kế hoạch vốn năm 2026", gt: so(T.kh), dv: "triệu đồng", icon: "gn", ky: `${GN_DS.length} dự án`, onClick: m({}, "Tất cả dự án") },
    { nhan: "Đã giải ngân", gt: so(T.da, 1), dv: "triệu", icon: "gn", xu: "tot", ky: `Tiến độ ${pt(T.tl, 2)}`, ring: T.tl / 100, ringMau: C.tot, onClick: m({ ttTen: "Đã giải ngân hết" }, "Đã giải ngân hết") },
    { nhan: "Chưa giải ngân", gt: so(T.chua, 1), dv: "triệu", icon: "canh-bao", xu: "xau", ky: pt(100 - T.tl, 2), ring: 1 - T.tl / 100, ringMau: C.xau, onClick: m({ ttTen: "Chưa giải ngân" }, "Chưa giải ngân") },
    { nhan: "Dự án chưa giải ngân", gt: so(dem("Chưa giải ngân")), dv: "dự án", icon: "canh-bao", xu: "xau", ky: `${dem("Giải ngân một phần")} dự án giải ngân một phần`, onClick: m({ ttTen: "Chưa giải ngân" }, "Dự án chưa giải ngân") },
  ];
  const o = [
    { key: "tl", rong: true, tieuDe: "Tỷ lệ giải ngân lũy kế theo tháng", el: <LineChart kys={GN_THANG.ky} fmt={(v) => pt(v, 2)} fmtTick={(v) => so(v) + "%"} series={[{ ten: "Bộ Tư pháp", color: ACC, vals: GN_THANG.bo }, { ten: "Toàn quốc", color: C.tx, vals: GN_THANG.tq }]} /> },
    { key: "nhom", tieuDe: "Theo nhóm chủ đầu tư (triệu đồng)", el: <HBars rows={[["Đơn vị thuộc Bộ", ...T.bo], ["Cơ quan THADS", ...T.thads]].map(([nhan, da, kh]) => ({ nhan, da, kh, p: tyLe(da, kh) }))} max={100} overlay onRow={(r) => mo({ trang: "gn", lop: 3, ds: "gn", loc: { nhomTen: r.nhan }, nhan: r.nhan })}
      segs={[{ ten: "Tỷ lệ giải ngân", color: (r) => mauXu(xuNguong(r.p, T.tl)), v: (r) => r.p }]} giaTri={(r) => `${so(r.da, 1)}/${so(r.kh, 1)}, ${pt(r.p, 2)}`} /> },
    { key: "tt", tieuDe: "Tình trạng dự án", el: <Donut giua={so(GN_DS.length)} phu="dự án" parts={Object.entries(GN_TT).map(([t, [c]]) => ({ ten: t, v: dem(t), color: c }))} /> },
  ];
  const bang = [{ id: "da", ten: "Dự án giải ngân thấp", el: <BangNho rows={GN_DS} cfg={DS.gn} moDayDu={m({}, "Tất cả dự án")}
    cot={[{ k: "ten", ten: "Dự án", chinh: true }, { k: "kh", ten: "KH (triệu)", right: true, render: soO(1) }, { k: "p", ten: "Đã giải ngân", render: (v) => <div style={{ minWidth: 140 }}><ThanhTyLe v={v} color={v >= 99.95 ? C.tot : v > 0 ? C.warn : C.xau} /></div> }]} /> }];
  return <TrangLinhVuc kpi={kpi} o={o} bang={bang} />;
}

/* =========================================================================
   LỚP 1 – TỔNG QUAN: 6 thẻ lĩnh vực trọng tâm (theo bố cục màn hình "Nhiệm vụ trọng tâm")
   ========================================================================= */
function The({ id, tieuDe, nguon, mo, children }) {
  const [luc, ngay, cu] = CAP_NHAT[id];
  return (
    <section className="flex min-h-0 flex-col rounded-2xl bg-white" style={{ border: `1px solid ${P.vien}`, boxShadow: "0 8px 22px -14px rgba(15,42,92,.25), 0 1px 2px rgba(15,42,92,.05)" }}>
      <div className="flex flex-none items-center gap-3 border-b border-[#E4E7EC] px-5 py-3">
        <AppIcon name={id} size={34} />
        <div className="min-w-0 flex-1"><h2 className="truncate text-[17px] font-semibold text-[#101828]">{tieuDe}</h2><p className="truncate text-xs text-[#475467]">{nguon}</p></div>
        <button onClick={() => mo({ trang: id, lop: 2 })} className="inline-flex shrink-0 items-center gap-1 rounded-lg border border-[#D9DEE7] px-3 py-1.5 text-sm font-semibold text-[#1D6FE8] hover:bg-[#EEF4FF] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]">Xem chi tiết<Icon name="mui-ten" size={15} /></button>
      </div>
      <div className="min-h-0 flex-1 px-5 py-4">{children}</div>
      <div className="flex flex-none items-center gap-3 border-t border-[#E4E7EC] px-5 py-2 text-xs text-[#667085]">
        <span>{luc}</span><span style={{ opacity: 0.5 }}>|</span><span>Dữ liệu đến: {ngay}</span>
        <span className="ml-auto inline-block h-2.5 w-2.5 rounded-full" style={{ background: cu ? C.warn : C.tot }} title={cu ? "Số liệu chưa cập nhật trong 7 ngày" : "Số liệu mới"} />
      </div>
    </section>
  );
}
/* Vòng phân phối gọn (không chú giải) cho thẻ lớp 1 */
function VongPhan({ parts, size, giua, phu }) {
  const tong = parts.reduce((x, p) => x + p[0], 0) || 1, R = size / 2 - 2, r = R * 0.68, c = size / 2;
  let a0 = -Math.PI / 2;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="shrink-0" role="img" aria-label={`${giua} ${phu}`}>
      {parts.filter((p) => p[0] > 0).map(([v, col], i) => {
        const a1 = a0 + (v / tong) * Math.PI * 2 - (v === tong ? 1e-4 : 0), big = a1 - a0 > Math.PI ? 1 : 0;
        const d = `M${c + R * Math.cos(a0)},${c + R * Math.sin(a0)} A${R},${R} 0 ${big} 1 ${c + R * Math.cos(a1)},${c + R * Math.sin(a1)} L${c + r * Math.cos(a1)},${c + r * Math.sin(a1)} A${r},${r} 0 ${big} 0 ${c + r * Math.cos(a0)},${c + r * Math.sin(a0)}Z`;
        a0 = a1;
        return <path key={i} d={d} fill={col} stroke="#fff" strokeWidth="2" />;
      })}
      <text x={c} y={c} textAnchor="middle" fontSize={size * 0.17} fontWeight="700" fill={P.navy} style={{ fontFamily: FONT_APPLE }}>{giua}</text>
      <text x={c} y={c + size * 0.13} textAnchor="middle" fontSize="12" fill={P.mo}>{phu}</text>
    </svg>
  );
}
const NutO = ({ onClick, children, className = "", style }) => <button onClick={onClick} className={`block w-full rounded-xl text-left hover:shadow-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8] ${className}`} style={style}>{children}</button>;
function VongNho({ a, b, size = 70, color = ACC }) {
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90"><circle cx={size / 2} cy={size / 2} r={size / 2 - 5} fill="none" stroke={C.track} strokeWidth="7" /><circle cx={size / 2} cy={size / 2} r={size / 2 - 5} fill="none" stroke={color} strokeWidth="7" strokeLinecap="round" strokeDasharray={`${(a / b) * 2 * Math.PI * (size / 2 - 5)} 999`} /></svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center leading-none"><b className="tabular-nums" style={{ fontSize: 18, color }}>{a}</b><span className="mt-0.5 text-xs tabular-nums text-[#475467]">{b}</span></div>
    </div>
  );
}
function ThanhNguon({ ten, tong, parts, onClick }) {
  const Tag = onClick ? "button" : "div";
  return (
    <Tag onClick={onClick} className={`block w-full rounded-xl border border-[#E4E7EC] px-3 py-2 text-left ${onClick ? "hover:shadow-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]" : ""}`}>
      <span className="flex items-baseline justify-between gap-2"><span className="truncate text-sm font-semibold text-[#101828]">{ten}</span><b className="tabular-nums text-[#101828]" style={{ fontSize: 20 }}>{so(tong)}</b></span>
      <span className="mt-1.5 flex h-5 overflow-hidden rounded-md" style={{ background: C.track }}>
        {parts.filter((p) => p[1]).map(([t, v, c]) => <span key={t} className="flex items-center justify-center text-xs font-bold text-white" style={{ width: `${(v / tong) * 100}%`, background: c }} title={`${t}: ${so(v)}`}>{v / tong > 0.08 ? so(v) : ""}</span>)}
      </span>
    </Tag>
  );
}
function TongQuan({ mo }) {
  const dem = (id, k) => NV_DS.filter((x) => x.nguonId === id && x.nhomKey === k).length;
  const XD_O = [["Văn bản đã đưa vào chương trình", XD_TOM.dua, ACC, ["luat", { ctTen: CT_CT.dua[0] }]], ["Chương trình đã hoàn thành xây dựng", XD_TOM.ctHT, "#0E9384", ["luat", { ctTen: CT_CT.dua[0], stTen: CT_ST.tq[0] }]],
    ["VB chi tiết đã được thông qua/ban hành", XD_TOM.qdct, C.warn, ["qdct", { stTen: QD_ST.tq[0] }]], ["VB theo thẩm quyền đã hoàn thành", XD_TOM.tq, C.tot, ["tq", {}]]];
  const GN_B = [["Đơn vị thuộc Bộ", GN_TOM.bo, C.tot], ["Cơ quan THADS", GN_TOM.thads, ACC]];
  return (
    <div className="grid h-full gap-5" style={{ gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gridTemplateRows: "repeat(2, minmax(0, 1fr))" }}>
      <The id="nv" tieuDe="Quản lý nhiệm vụ Trung ương giao" nguon="Năm 2026. HT văn bản điều hành Bộ và HT theo dõi nhiệm vụ TW" mo={mo}>
        <div className="flex h-full gap-5">
          <div className="flex shrink-0 flex-col items-center justify-center" style={{ width: 190 }}>
            <VongPhan size={150} giua={so(NV_TONG)} phu="nhiệm vụ" parts={NHOM_KEYS.map((k) => [NV_NHOM_DEM[k], NHOM_TT[k][1]])} />
            <ul className="mt-3 w-full space-y-1 text-sm text-[#344054]">{NHOM_KEYS.map((k) => <li key={k} className="flex items-center gap-1.5 whitespace-nowrap"><i className="h-2 w-2 shrink-0 rounded-sm" style={{ background: NHOM_TT[k][1] }} />{{ done: "Hoàn thành", th: "Trong hạn", gh: "Gần hạn", qh: "Quá hạn" }[k]}<b className="ml-auto tabular-nums">{NV_NHOM_DEM[k]}</b></li>)}</ul>
          </div>
          <div className="flex min-w-0 flex-1 flex-col justify-between gap-2">
            {NV_NGUON.map((ng) => <ThanhNguon key={ng.id} ten={ng.ten} tong={NV_DS.filter((x) => x.nguonId === ng.id).length} onClick={() => mo({ trang: "nv", lop: 2, nguon: ng.id, nhan: `Thống kê chi tiết: ${ng.ten}` })}
              parts={NHOM_KEYS.map((k) => [NHOM_TT[k][0], dem(ng.id, k), NHOM_TT[k][1]])} />)}
            <ThanhNguon ten="Nhiệm vụ Ban Chỉ đạo 57" tong={NV_BCD57.tong} parts={[["Hoàn thành", NV_BCD57.done, C.tot], ["Trong hạn", NV_BCD57.th, C.info]]} />
          </div>
        </div>
      </The>
      <The id="xdpl" tieuDe="Công tác xây dựng pháp luật" nguon="Năm 2026. HT quản lý chương trình xây dựng VBQPPL" mo={mo}>
        <div className="flex h-full flex-col gap-3">
          <div className="grid flex-1 grid-cols-4 gap-3">
            {XD_O.map(([t, [a, b], c, [ds, loc]]) => (
              <NutO key={t} onClick={() => mo({ trang: "xdpl", lop: 3, ds, loc, nhan: t })} className="flex flex-col items-center justify-center gap-2 border border-[#E4E7EC] px-2 py-2 text-center">
                <VongNho a={a} b={b} color={c} /><span className="text-xs font-medium leading-tight text-[#344054]">{t}</span>
              </NutO>))}
          </div>
          <div className="grid flex-none grid-cols-3 gap-3">
            {[[XD_TOM.noLuat, "Luật, NQ, PL có hiệu lực nợ ban hành", C.xau, NEN.xau, QD_ST.no[0]], [XD_TOM.cham, "VB QĐCT chậm, nợ ban hành", C.xau, NEN.xau, QD_ST.no[0]], [XD_TOM.sapToi, "VB QĐCT phải ban hành sắp tới", C.warn, NEN.warn, QD_ST.sap[0]]].map(([n, t, c, bg, st]) => (
              <NutO key={t} onClick={() => mo({ trang: "xdpl", lop: 3, ds: "qdct", loc: { stTen: st }, nhan: t })} className="border px-2 py-2 text-center" style={{ borderColor: c, background: bg }}>
                <b className="block tabular-nums" style={{ fontSize: 24, color: c, lineHeight: 1.1 }}>{n}</b><span className="block text-xs font-medium leading-tight" style={{ color: c }}>{t}</span>
              </NutO>))}
          </div>
          <div className="flex-none">
            <p className="flex justify-between text-sm"><span className="font-semibold text-[#101828]">Tỷ lệ văn bản quy định chi tiết đã ban hành</span><b className="tabular-nums" style={{ color: C.tot }}>{pt(XD_TOM.tyLe, 2)}</b></p>
            <div className="mt-1 h-2 overflow-hidden rounded-sm" style={{ background: C.track }}><div className="h-full" style={{ width: `${XD_TOM.tyLe}%`, background: C.tot }} /></div>
          </div>
        </div>
      </The>
      <The id="pakn" tieuDe="Phản ánh, kiến nghị về VBQPPL" nguon="Tháng 11/2026. HT phản ánh kiến nghị về VBQPPL" mo={mo}>
        <div className="flex h-full flex-col gap-3">
          <NutO onClick={() => mo({ trang: "pakn", lop: 3, ds: "pakn", nhan: "Tất cả phản ánh" })} className="flex-none px-1"><b className="tabular-nums text-[#101828]" style={{ fontSize: 36 }}>{so(PAKN_TOM.tong)}</b> <span className="text-sm text-[#475467]">phản ánh</span></NutO>
          {[["xong", C.tot, NEN.tot], ["qh", C.xau, NEN.xau], ["th", C.info, "#EFF8FF"]].map(([k, c, bg]) => (
            <NutO key={k} onClick={() => mo({ trang: "pakn", lop: 3, ds: "pakn", loc: { stTen: PAKN_ST[k][0] }, nhan: PAKN_ST[k][0] })} className="flex flex-1 items-center gap-3 border px-4" style={{ borderColor: c, background: bg }}>
              <i className="h-3 w-3 rounded-full" style={{ background: c }} />
              <span className="flex-1"><span className="block text-sm font-semibold text-[#344054]">{PAKN_ST[k][0]}</span><b className="tabular-nums text-[#101828]" style={{ fontSize: 22 }}>{so(PAKN_TOM[k])}</b></span>
              <b className="tabular-nums" style={{ fontSize: 22, color: c }}>{pt(tyLe(PAKN_TOM[k], PAKN_TOM.tong), 2)}</b>
            </NutO>))}
        </div>
      </The>
      <The id="thads" tieuDe="Thi hành án dân sự" nguon="Đến tháng 11/2026. Nền tảng số THADS" mo={mo}>
        <div className="flex h-full flex-col gap-3">
          <div className="grid flex-1 grid-cols-2 gap-3">
            {[["Tổng số việc có điều kiện thi hành", so(THA.viecDK), ACC, "viecDK", THA.viecDK], ["Tổng số tiền có điều kiện thi hành (tỷ)", so(THA.tienDK, 1), C.warn, "tienDK", THA.tienDK],
              ["Tổng số việc giải quyết xong", so(THA.viecXong), C.tot, "viecXong", THA.viecXong], ["Tổng số tiền giải quyết xong (tỷ)", so(THA.tienXong, 1), C.tot, "tienXong", THA.tienXong]].map(([t, v, c, k, n]) => (
              <NutO key={t} onClick={() => mo({ trang: "thads", lop: 2 })} className="flex flex-col justify-center border border-[#E4E7EC] px-4">
                <span className="text-xs font-medium text-[#475467]">{t}</span><b className="tabular-nums" style={{ fontSize: 24, color: c, lineHeight: 1.2 }}>{v}</b>
                <span className="text-xs text-[#667085]">{cungKyText(k, n)}</span>
              </NutO>))}
          </div>
          {[["Tỷ lệ thi hành xong về việc (%)", THA.tlViec, THA_CHI_TIEU.viec, C.tot], ["Tỷ lệ thi hành xong về tiền (%)", THA.tlTien, THA_CHI_TIEU.tien, "#F5B800"]].map(([t, v, ct, c]) => {
            const dat = datChiTieu(v, ct);
            return (
              <div key={t} className="flex-none" title={`${pt(v, 2)} / chỉ tiêu ${pt(ct, 2)} = đạt ${pt(dat, 2)} chỉ tiêu`}>
                <p className="flex items-baseline justify-between gap-3 text-sm"><span className="font-semibold text-[#101828]">{t}</span>
                  <span className="tabular-nums text-[#475467]"><b style={{ color: c === C.tot ? "#067647" : "#B54708" }}>{pt(v, 2)}</b> / chỉ tiêu {pt(ct, 2)}</span></p>
                <div className="mt-1 h-2 overflow-hidden rounded-sm" style={{ background: C.track }}><div className="h-full" style={{ width: `${Math.min(100, dat)}%`, background: c }} /></div>
                <p className="mt-0.5 text-right text-xs tabular-nums text-[#475467]">Đạt {pt(dat, 2)} chỉ tiêu, còn {pt(Math.max(0, 100 - dat), 2)}</p>
              </div>);
          })}
        </div>
      </The>
      <The id="tthc" tieuDe="Giải quyết thủ tục hành chính" nguon="Tháng 11/2026. Hệ thống thông tin giải quyết TTHC" mo={mo}>
        <div className="flex h-full flex-col gap-3">
          <div className="grid flex-none grid-cols-3 gap-3">
            {[["Tổng số hồ sơ tiếp nhận", so(T_LUY_KE_GON, 2) + " triệu", "tthc_lv"], ["Hồ sơ tháng 11/2026", so(TTHC_TOM.thang), "tthc_dp"], ["Tỷ lệ đã xử lý", pt(TTHC_TOM.daXL), "tthc_dp"]].map(([t, v, ds], i) => (
              <NutO key={t} onClick={() => mo({ trang: "tthc", lop: 3, ds, nhan: ds === "tthc_lv" ? "Theo lĩnh vực" : "Theo địa phương" })} className="border border-[#E4E7EC] px-3 py-2">
                <span className="block text-xs font-medium text-[#475467]">{t}</span><b className="tabular-nums" style={{ fontSize: 22, color: i === 2 ? ACC : P.navy }}>{v}</b>
              </NutO>))}
          </div>
          <div className="flex min-h-0 flex-1 items-center gap-6">
            <VongPhan size={160} giua={pt(TTHC_TOM.tlTT)} phu="trực tuyến" parts={[[TTHC_TOM.tt, ACC], [TTHC_TOM.tiep, C.tx]]} />
            <ul className="flex-1 space-y-2 text-sm">
              <li className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-sm" style={{ background: ACC }} /><span className="text-[#344054]">Trực tuyến</span><b className="ml-auto tabular-nums text-[#101828]" style={{ fontSize: 18 }}>{so(TTHC_TOM.tt)}</b></li>
              <li className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-sm" style={{ background: C.tx }} /><span className="text-[#344054]">Trực tiếp</span><b className="ml-auto tabular-nums text-[#101828]" style={{ fontSize: 18 }}>{so(TTHC_TOM.tiep)}</b></li>
              <li className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-sm" style={{ background: C.xau }} /><span style={{ color: C.xau }}>Hồ sơ từ chối</span><b className="ml-auto tabular-nums" style={{ fontSize: 18, color: C.xau }}>{pt(TTHC_TOM.tuChoi)}</b></li>
            </ul>
          </div>
        </div>
      </The>
      <The id="gn" tieuDe="Giải ngân vốn đầu tư công" nguon="Đến tháng 10/2026. Dữ liệu ngoại tuyến, Cục Kế hoạch – Tài chính" mo={mo}>
        <div className="flex h-full flex-col justify-between gap-3">
          <p className="flex items-baseline justify-between"><span><b className="tabular-nums text-[#101828]" style={{ fontSize: 32 }}>{so(GN_TOM.kh)}</b> <span className="text-sm text-[#475467]">triệu đồng kế hoạch</span></span><span className="text-sm text-[#475467]">Tiến độ: <b style={{ color: C.tot }}>{pt(GN_TOM.tl, 2)}</b></span></p>
          {GN_B.map(([t, [da, kh], c]) => (
            <NutO key={t} onClick={() => mo({ trang: "gn", lop: 3, ds: "gn", loc: { nhomTen: t }, nhan: t })} className="px-1 py-1">
              <span className="flex justify-between text-sm"><span className="font-semibold text-[#101828]">{t}</span><span className="tabular-nums text-[#344054]">{so(da, 1)}/{so(kh, 1)} triệu</span></span>
              <span className="mt-1 block h-2 overflow-hidden rounded-sm" style={{ background: C.track }}><span className="block h-full" style={{ width: `${tyLe(da, kh)}%`, background: c }} /></span>
            </NutO>))}
          <div className="grid grid-cols-2 gap-3">
            {[["Chưa giải ngân", GN_TOM.chua, 100 - GN_TOM.tl, C.xau, NEN.xau, "Chưa giải ngân"], ["Đã giải ngân", GN_TOM.da, GN_TOM.tl, C.tot, NEN.tot, "Đã giải ngân hết"]].map(([t, v, p, c, bg, tt]) => (
              <NutO key={t} onClick={() => mo({ trang: "gn", lop: 3, ds: "gn", loc: tt === "Chưa giải ngân" ? { ttTen: tt } : {}, nhan: t })} className="border px-3 py-2" style={{ borderColor: c, background: bg }}>
                <span className="flex items-center justify-between text-xs font-medium text-[#344054]">{t}<Nhan t={pt(p, 2)} c="#fff" bg={c} /></span>
                <b className="tabular-nums" style={{ fontSize: 22, color: c }}>{so(v, 1)} triệu</b>
              </NutO>))}
          </div>
        </div>
      </The>
    </div>
  );
}
const T_LUY_KE_GON = TTHC_TOM.luyKe / 1e6;

/* =========================================================================
   KHUNG CHÍNH: điều hướng 3 lớp (ngăn xếp màn hình), đường dẫn và nút Quay lại
   ========================================================================= */
const TRANG = [
  { id: "tong-quan", ten: "Tổng quan" }, { id: "nv", ten: "Nhiệm vụ" }, { id: "xdpl", ten: "Xây dựng pháp luật" }, { id: "pakn", ten: "Phản ánh, kiến nghị" },
  { id: "thads", ten: "Thi hành án dân sự" }, { id: "tthc", ten: "Thủ tục hành chính" }, { id: "gn", ten: "Giải ngân đầu tư công" },
];
const TEN_LV = { nv: "Quản lý nhiệm vụ", xdpl: "Công tác xây dựng pháp luật", pakn: "Phản ánh, kiến nghị về VBQPPL", thads: "Thi hành án dân sự / Việc và tiền thi hành xong", tthc: "Giải quyết thủ tục hành chính", gn: "Giải ngân vốn đầu tư công" };
const GOC = { trang: "tong-quan", lop: 1, nhan: "Tổng quan" };

/* =========================================================================
   TRÌNH CHIẾU: tự chuyển lần lượt giữa các màn hình đã chọn, mỗi màn hình có thời gian riêng.
   Cấu hình lưu trên trình duyệt đang dùng (localStorage); muốn dùng chung cho mọi màn hình IOC thì
   thay hàm docCauHinh/luuCauHinh bằng lời gọi API.
   ========================================================================= */
const MAN_TC = [
  { id: "tong-quan", ten: "Tổng quan 6 lĩnh vực", view: GOC },
  { id: "nv-tw", ten: "Nhiệm vụ Trung ương giao", view: { trang: "nv", lop: 2, tab: "tw" } },
  { id: "nv-ldb", ten: "Nhiệm vụ Lãnh đạo Bộ giao", view: { trang: "nv", lop: 2, tab: "ldb" } },
  { id: "xdpl", ten: "Công tác xây dựng pháp luật", view: { trang: "xdpl", lop: 2 } },
  { id: "pakn", ten: "Phản ánh, kiến nghị về VBQPPL", view: { trang: "pakn", lop: 2 } },
  { id: "thads-viec", ten: "Thi hành án dân sự: về việc", view: { trang: "thads", lop: 2, cuon: "viec" } },
  { id: "thads-tien", ten: "Thi hành án dân sự: về tiền", view: { trang: "thads", lop: 2, cuon: "tien" } },
  { id: "tthc", ten: "Giải quyết thủ tục hành chính", view: { trang: "tthc", lop: 2 } },
  { id: "gn", ten: "Giải ngân vốn đầu tư công", view: { trang: "gn", lop: 2 } },
];
const TC_MAC_DINH = { thuTu: MAN_TC.map((x) => x.id), bat: Object.fromEntries(MAN_TC.map((x) => [x.id, true])), giay: Object.fromEntries(MAN_TC.map((x) => [x.id, 30])), tuChay: 60 };
const TC_KHOA = "iocw-trinh-chieu-v1";
const docCauHinh = () => {
  try { const x = JSON.parse(window.localStorage.getItem(TC_KHOA)); if (x && x.thuTu) return { ...TC_MAC_DINH, ...x, thuTu: [...x.thuTu.filter((id) => MAN_TC.some((m) => m.id === id)), ...TC_MAC_DINH.thuTu.filter((id) => !x.thuTu.includes(id))] }; } catch (e) { /* không có bộ nhớ trình duyệt */ }
  return TC_MAC_DINH;
};
const luuCauHinh = (c) => { try { window.localStorage.setItem(TC_KHOA, JSON.stringify(c)); } catch (e) { /* bỏ qua */ } };
const gioiHan = (v, a, b) => Math.max(a, Math.min(b, Math.round(Number(v) || a)));

function CauHinhTrinhChieu({ cfg, onLuu, onDong, onBatDau }) {
  const [c, setC] = useState(cfg);
  const doi = (i, d) => { const t = [...c.thuTu]; const j = i + d; if (j < 0 || j >= t.length) return; [t[i], t[j]] = [t[j], t[i]]; setC({ ...c, thuTu: t }); };
  const chuan = (x) => ({ ...x, tuChay: gioiHan(x.tuChay, 10, 900), giay: Object.fromEntries(Object.entries(x.giay).map(([k, g]) => [k, gioiHan(g, 5, 600)])) });
  const soChon = c.thuTu.filter((id) => c.bat[id]).length;
  const tong = c.thuTu.filter((id) => c.bat[id]).reduce((a, id) => a + gioiHan(c.giay[id], 5, 600), 0);
  const datTatCa = (g) => setC({ ...c, giay: Object.fromEntries(c.thuTu.map((id) => [id, g])) });
  useEffect(() => { const f = (e) => { if (e.key === "Escape") onDong(); }; window.addEventListener("keydown", f); return () => window.removeEventListener("keydown", f); }, [onDong]);
  return (
    <div data-tc="1" className="absolute inset-0 z-10 flex items-center justify-center" style={{ background: "rgba(16,24,40,.45)" }} onClick={onDong}>
      <div role="dialog" aria-modal="true" aria-label="Cấu hình trình chiếu" className="flex flex-col rounded-2xl bg-white shadow-lg" style={{ width: 860, maxHeight: 900 }} onClick={(e) => e.stopPropagation()}>
        <div className="flex items-start justify-between gap-4 border-b border-[#D9DEE7] px-8 py-5">
          <div><h3 className="text-[20px] font-semibold text-[#101828]">Cấu hình trình chiếu</h3>
            <p className="mt-1 text-sm text-[#475467]">Chọn màn hình sẽ chạy, thứ tự và thời gian dừng ở mỗi màn hình.</p></div>
          <button onClick={onDong} aria-label="Đóng" className="flex h-11 w-11 items-center justify-center rounded-lg hover:bg-[#E4E7EC]"><Icon name="dong" size={22} color={P.ink2} /></button>
        </div>
        <div className="flex items-center gap-3 border-b border-[#E4E7EC] px-8 py-3 text-sm text-[#344054]">
          <span>Đặt nhanh thời gian cho tất cả:</span>
          {[15, 30, 60, 120].map((g) => <button key={g} onClick={() => datTatCa(g)} className="rounded-md border border-[#D9DEE7] px-3 py-1 font-semibold hover:bg-[#E4E7EC]">{g} giây</button>)}
        </div>
        <ul className="min-h-0 flex-1 overflow-auto px-8 py-2">
          {c.thuTu.map((id, i) => {
            const mh = MAN_TC.find((x) => x.id === id), on = !!c.bat[id];
            return (
              <li key={id} className="flex items-center gap-4 border-b border-[#E4E7EC] py-2.5">
                <span className="w-10 text-sm tabular-nums text-[#98A2B3]">{String(i + 1).padStart(2, "0")}</span>
                <label className="flex flex-1 cursor-pointer items-center gap-3">
                  <input type="checkbox" checked={on} onChange={(e) => setC({ ...c, bat: { ...c.bat, [id]: e.target.checked } })} style={{ width: 18, height: 18, accentColor: ACC }} />
                  <AppIcon name={mh.view.trang === "tong-quan" ? "tong-quan" : mh.view.trang} size={28} />
                  <span className={`text-[15px] ${on ? "font-semibold text-[#101828]" : "text-[#98A2B3]"}`}>{mh.ten}</span>
                </label>
                <label className="flex items-center gap-2 text-sm text-[#475467]">
                  <input type="number" min={5} max={600} step={5} value={c.giay[id]} disabled={!on} aria-label={`Thời gian hiển thị ${mh.ten}`}
                    onChange={(e) => setC({ ...c, giay: { ...c.giay, [id]: e.target.value } })} onBlur={(e) => setC({ ...c, giay: { ...c.giay, [id]: gioiHan(e.target.value, 5, 600) } })}
                    className="rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-right text-sm text-[#101828] focus:border-[#1D6FE8] focus:outline-none" style={{ width: 90, opacity: on ? 1 : 0.5 }} />giây
                </label>
                <span className="flex gap-1">
                  <button onClick={() => doi(i, -1)} disabled={i === 0} aria-label="Đưa lên" className="flex h-11 w-11 items-center justify-center rounded-lg border border-[#D9DEE7] hover:bg-[#E4E7EC]" style={{ opacity: i === 0 ? 0.35 : 1 }}><Icon name="len" size={18} /></button>
                  <button onClick={() => doi(i, 1)} disabled={i === c.thuTu.length - 1} aria-label="Đưa xuống" className="flex h-11 w-11 items-center justify-center rounded-lg border border-[#D9DEE7] hover:bg-[#E4E7EC]" style={{ opacity: i === c.thuTu.length - 1 ? 0.35 : 1 }}><Icon name="xuong" size={18} /></button>
                </span>
              </li>
            );
          })}
        </ul>
        <div className="flex items-center gap-3 border-t border-[#E4E7EC] px-8 py-3 text-sm text-[#344054]">
          <span>Khi người xem bấm vào màn hình, tạm dừng rồi tự chạy lại sau</span>
          <input type="number" min={10} max={900} step={10} value={c.tuChay} aria-label="Số giây tự chạy lại" onChange={(e) => setC({ ...c, tuChay: e.target.value })} onBlur={(e) => setC({ ...c, tuChay: gioiHan(e.target.value, 10, 900) })}
            className="rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-right text-sm focus:border-[#1D6FE8] focus:outline-none" style={{ width: 90 }} />giây
        </div>
        <div className="flex items-center gap-3 border-t border-[#D9DEE7] px-8 py-4">
          <span className="mr-auto text-sm text-[#475467]">{soChon ? `${soChon} màn hình, một vòng ${Math.floor(tong / 60)} phút ${tong % 60} giây` : "Chọn ít nhất một màn hình để trình chiếu"}</span>
          <button onClick={() => setC(TC_MAC_DINH)} className="rounded-lg border border-[#D9DEE7] px-4 py-2 text-sm font-semibold text-[#344054] hover:bg-[#E4E7EC]">Khôi phục mặc định</button>
          <button onClick={() => onLuu(chuan(c))} disabled={!soChon} className="rounded-lg border border-[#D9DEE7] px-4 py-2 text-sm font-semibold text-[#1D6FE8] hover:bg-[#EEF4FF]" style={{ opacity: soChon ? 1 : 0.4 }}>Lưu cấu hình</button>
          <button onClick={() => onBatDau(chuan(c))} disabled={!soChon} className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-white" style={{ background: ACC, opacity: soChon ? 1 : 0.4 }}><Icon name="play" size={16} color="#fff" />Lưu và bắt đầu</button>
        </div>
      </div>
    </div>
  );
}

export default function IOCBoTuPhapWeb() {
  const [ngan, setNgan] = useState([GOC]);
  const v = ngan[ngan.length - 1];
  const mo = (x) => {
    const nhan = x.nhan || (x.lop === 2 ? TEN_LV[x.trang] : DS[x.ds]?.tieuDe);
    if (x.lop === 2 && !x.nguon) { setNgan([GOC, { tab: "tw", ...x, nhan: TEN_LV[x.trang] }]); return; }
    const goc = ngan.some((s) => s.trang === x.trang && s.lop === 2) ? ngan : [GOC, { trang: x.trang, lop: 2, tab: x.ds === "ldb" ? "ldb" : "tw", nhan: TEN_LV[x.trang] }];
    setNgan([...goc, { ...x, nhan: x.lop === 3 ? `${DS[x.ds].tieuDe}${x.nhan ? `: ${x.nhan}` : ""}` : nhan }]);
  };
  const quayLai = () => setNgan(ngan.length > 1 ? ngan.slice(0, -1) : ngan);
  const veMuc = (i) => setNgan(ngan.slice(0, i + 1));
  const datTab = (tab) => setNgan([...ngan.slice(0, -1), { ...v, tab }]);
  useEffect(() => {
    const f = (e) => { if (e.key === "Backspace" && !/input|select|textarea/i.test(e.target.tagName) && ngan.length > 1) { e.preventDefault(); quayLai(); } };
    window.addEventListener("keydown", f);
    return () => window.removeEventListener("keydown", f);
  });

  /* ----- Trình chiếu ----- */
  const [tc, setTc] = useState(docCauHinh);
  const [moCH, setMoCH] = useState(false);
  const [chay, setChay] = useState(false);          /* đang ở chế độ trình chiếu */
  const [dung, setDung] = useState(0);              /* > 0: đang tạm dừng, số giây còn lại trước khi tự chạy lại; -1: dừng hẳn */
  const [vt, setVt] = useState(0);
  const [con, setCon] = useState(0);
  const ds = tc.thuTu.filter((id) => tc.bat[id]);
  const hien = (i, c = tc) => {
    const d = c.thuTu.filter((id) => c.bat[id]); if (!d.length) return;
    const k = ((i % d.length) + d.length) % d.length, mh = MAN_TC.find((x) => x.id === d[k]);
    setVt(k); setCon(c.giay[mh.id]);
    setNgan(mh.view.trang === "tong-quan" ? [GOC] : [GOC, { ...mh.view, nhan: TEN_LV[mh.view.trang] }]);
  };
  const batDau = (c = tc) => { setTc(c); luuCauHinh(c); setMoCH(false); setChay(true); setDung(0); hien(0, c); };
  const ketThuc = () => { setChay(false); setDung(0); try { if (document.fullscreenElement) document.exitFullscreen(); } catch (e) { /* bỏ qua */ } };
  useEffect(() => {
    if (!chay) return undefined;
    const t = setInterval(() => {
      if (dung > 0) { setDung(dung <= 1 ? 0 : dung - 1); return; }
      if (dung < 0) return;
      if (con <= 1) hien(vt + 1); else setCon(con - 1);
    }, 1000);
    return () => clearInterval(t);
  });
  /* Người xem thao tác trên màn hình → tạm dừng, tự chạy lại sau tc.tuChay giây */
  useEffect(() => {
    if (!chay) return undefined;
    const f = (e) => { if (e.target.closest && e.target.closest("[data-tc]")) return; if (dung >= 0) setDung(tc.tuChay); };
    window.addEventListener("pointerdown", f);
    return () => window.removeEventListener("pointerdown", f);
  }, [chay, dung, tc.tuChay]);
  useEffect(() => {
    if (!chay) return undefined;
    const f = (e) => {
      if (/input|select|textarea/i.test(e.target.tagName)) return;
      if (e.key === "ArrowRight") { e.preventDefault(); setDung(0); hien(vt + 1); }
      else if (e.key === "ArrowLeft") { e.preventDefault(); setDung(0); hien(vt - 1); }
      else if (e.key === " ") { e.preventDefault(); setDung((x) => (x === 0 ? -1 : 0)); }
      else if (e.key === "Escape" && !moCH) ketThuc();
    };
    window.addEventListener("keydown", f);
    return () => window.removeEventListener("keydown", f);
  });
  const toanManHinh = () => { try { if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen(); } catch (e) { /* trình duyệt không hỗ trợ */ } };
  const tenMH = chay && ds.length ? MAN_TC.find((x) => x.id === ds[vt])?.ten : "";
  const tongGiay = chay && ds.length ? tc.giay[ds[vt]] : 1;
  const NutTC = ({ icon, nhan, onClick, chinh }) => (
    <button data-tc="1" onClick={onClick} aria-label={nhan} title={nhan} className="flex h-11 w-11 items-center justify-center rounded-lg border border-[#D9DEE7] hover:bg-[#E4E7EC] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]"
      style={chinh ? { background: ACC, borderColor: ACC } : undefined}><Icon name={icon} size={18} color={chinh ? "#fff" : P.ink2} /></button>
  );
  return (
    <div className="iocw">
      <style>{TAILWIND_CSS}</style>
      <Stage>
        <div className="flex h-full flex-col text-[#101828] bg-white" style={{ fontFamily: FONT_APPLE, letterSpacing: "-0.011em" }}>
          <header className="flex flex-none items-center justify-between px-10" style={{ height: 84, background: THUONG_HIEU, borderBottom: "3px solid #F5C24C" }}>
            <div className="flex items-center gap-4">
              <img src={LOGO_BTP} alt="Logo Bộ Tư pháp" width={40} height={53} style={{ width: 40, height: 53, filter: "drop-shadow(0 2px 4px rgba(0,0,0,.25))" }} />
              <div>
                <h1 className="text-white" style={{ fontFamily: FONT_APPLE, fontSize: 30, fontWeight: 700, lineHeight: 1.15, letterSpacing: "-0.02em" }}>IOC Bộ Tư pháp</h1>
                <p style={{ fontSize: 15, color: "#DCE9FF" }}>Hệ thống chỉ đạo điều hành thông minh, nhiệm vụ trọng tâm</p>
              </div>
            </div>
            <p style={{ fontSize: 15, color: "#DCE9FF" }}>Bộ Tư pháp<span style={{ margin: "0 12px", opacity: 0.5 }}>|</span><b style={{ color: "#FFFFFF", fontWeight: 600 }}>Số liệu đến 09/11/2026</b></p>
          </header>
          <nav className="flex h-[64px] flex-none items-center gap-1 border-b border-[#D9DEE7] bg-white px-8" aria-label="Lĩnh vực" role="tablist">
            {TRANG.map((x) => {
              const on = v.trang === x.id;
              return (
                <button key={x.id} role="tab" aria-selected={on} onClick={() => (x.id === "tong-quan" ? setNgan([GOC]) : mo({ trang: x.id, lop: 2 }))}
                  className={`flex h-11 items-center gap-1.5 whitespace-nowrap rounded-lg px-3 text-[15px] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8] ${on ? "font-semibold text-white" : "font-medium text-[#344054] hover:bg-[#E4E7EC]"}`}
                  style={on ? { background: THUONG_HIEU } : undefined}>
                  <Icon name={x.id} size={18} color={on ? "#fff" : "#1D6FE8"} />{x.ten}
                </button>
              );
            })}
            {v.trang === "nv" && v.lop === 2 && !v.nguon && <span className="ml-4"><Seg items={[["tw", "Trung ương giao"], ["ldb", "Lãnh đạo Bộ giao"]]} value={v.tab} onChange={datTab} /></span>}
            {!chay ? (
              <span className="ml-auto flex items-center gap-2">
                <button data-tc="1" onClick={() => batDau()} disabled={!ds.length} className="inline-flex h-11 items-center gap-2 rounded-lg px-4 text-[15px] font-semibold text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]" style={{ background: ACC, opacity: ds.length ? 1 : 0.4 }}>
                  <Icon name="play" size={16} color="#fff" />Trình chiếu</button>
                <NutTC icon="cau-hinh" nhan="Cấu hình trình chiếu" onClick={() => setMoCH(true)} />
              </span>
            ) : (
              <span data-tc="1" className="ml-auto flex items-center gap-2">
                <span className="mr-2 text-right leading-tight">
                  <span className="block text-sm font-semibold text-[#101828]">{vt + 1}/{ds.length}. {tenMH}</span>
                  <span className="block text-xs tabular-nums" style={{ color: dung ? C.warn : P.mo }}>{dung > 0 ? `Tạm dừng do thao tác, tự chạy lại sau ${dung} giây` : dung < 0 ? "Đã tạm dừng" : `Chuyển màn hình sau ${con} giây`}</span>
                </span>
                <NutTC icon="truoc" nhan="Màn hình trước (phím ←)" onClick={() => { setDung(0); hien(vt - 1); }} />
                <NutTC icon={dung ? "play" : "pause"} nhan={dung ? "Tiếp tục (phím cách)" : "Tạm dừng (phím cách)"} chinh onClick={() => setDung(dung ? 0 : -1)} />
                <NutTC icon="sau" nhan="Màn hình sau (phím →)" onClick={() => { setDung(0); hien(vt + 1); }} />
                <NutTC icon="toan-man-hinh" nhan="Toàn màn hình" onClick={toanManHinh} />
                <NutTC icon="cau-hinh" nhan="Cấu hình trình chiếu" onClick={() => { setDung(-1); setMoCH(true); }} />
                <NutTC icon="dong" nhan="Thoát trình chiếu (Esc)" onClick={ketThuc} />
              </span>
            )}
          </nav>
          {chay && (
            <div className="flex-none" style={{ height: 3, background: C.track }} aria-hidden="true">
              <div style={{ height: 3, width: `${dung ? ((tongGiay - con) / tongGiay) * 100 : ((tongGiay - con + 1) / tongGiay) * 100}%`, background: dung ? C.warn : ACC, transition: dung ? "none" : "width 1s linear" }} />
            </div>
          )}
          {(v.lop === 3 || v.nguon) && !chay && (
            <div className="flex flex-none items-center gap-4 border-b border-[#E4E7EC] px-10" style={{ height: 56 }}>
              <button onClick={quayLai} className="inline-flex items-center gap-1 rounded-lg border border-[#D9DEE7] px-3 py-1.5 text-sm font-semibold text-[#344054] hover:bg-[#E4E7EC] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]"><Icon name="quay-lai" size={16} />Quay lại</button>
              <ol className="flex min-w-0 items-center gap-2 text-sm" aria-label="Đường dẫn">
                {ngan.map((s, i) => (
                  <li key={i} className="flex min-w-0 items-center gap-2">
                    {i > 0 && <Icon name="mui-ten" size={14} color="#98A2B3" />}
                    {i < ngan.length - 1
                      ? <button onClick={() => veMuc(i)} className="truncate font-medium text-[#1D6FE8] hover:underline">{s.nhan}</button>
                      : <span className="truncate font-semibold text-[#101828]" aria-current="page">{s.nhan}</span>}
                  </li>
                ))}
              </ol>
            </div>
          )}
          <main className="relative min-h-0 flex-1 px-10 py-5">
            {v.lop === 1 && <TongQuan mo={mo} />}
            {v.lop === 2 && v.trang === "nv" && (v.nguon ? <NvNguon key={v.nguon} id={v.nguon} /> : v.tab === "ldb" ? <NvLanhDaoBo mo={mo} /> : <NvTrungUong mo={mo} />)}
            {v.lop === 2 && v.trang === "xdpl" && <TrangXdpl mo={mo} />}
            {v.lop === 2 && v.trang === "pakn" && <TrangPakn mo={mo} />}
            {v.lop === 2 && v.trang === "thads" && <TrangThads mo={mo} cuon={v.cuon} />}
            {v.lop === 2 && v.trang === "tthc" && <TrangTthc mo={mo} />}
            {v.lop === 2 && v.trang === "gn" && <TrangGiaiNgan mo={mo} />}
            {v.lop === 3 && <DanhSach key={ngan.length + JSON.stringify(v.loc || {}) + v.ds} cfg={DS[v.ds]} locBanDau={v.loc || {}} />}
          </main>
          {moCH && <CauHinhTrinhChieu cfg={tc} onDong={() => { setMoCH(false); if (chay) setDung(0); }} onLuu={(c) => { setTc(c); luuCauHinh(c); setMoCH(false); if (chay) { setDung(0); hien(0, c); } }} onBatDau={batDau} />}
        </div>
      </Stage>
    </div>
  );
}
