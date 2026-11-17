import { useEffect, useMemo, useRef, useState } from "react";

/* =========================================================================
   Dashboard theo dõi thực hiện Nghị quyết 57-NQ/TW – Thành phố Hà Nội
   React + Tailwind, khung cố định 16:9 (1920×1080) tự co giãn vừa màn hình. Không dùng thư viện biểu đồ: các biểu đồ là SVG/HTML tự vẽ.
   Số liệu: Bộ danh mục chỉ số NQ57 Hà Nội (BC tháng 2–9/2026, BC tuần 41,
   Thông báo kết luận 20/10/2026); phụ lục BC tháng 8, tháng 9/2026.
   Khi có API/eForm, thay các hằng số dữ liệu dưới đây bằng dữ liệu tải về.
   ========================================================================= */

/* CSS Tailwind đã biên dịch sẵn, phạm vi trong .nq57: file chạy được cả khi môi trường không có Tailwind đầy đủ */
const TAILWIND_CSS = ".nq57,.nq57 *,.nq57 :after,.nq57 :before{box-sizing:border-box;border-width:0;border-style:solid;border-color:#E2E8F0}.nq57{line-height:1.5;-webkit-text-size-adjust:100%;font-feature-settings:\"tnum\";font-weight:500;-webkit-font-smoothing:auto;-moz-osx-font-smoothing:auto;text-rendering:optimizeLegibility}.nq57 h1,.nq57 h2,.nq57 h3,.nq57 p,.nq57 ul,.nq57 li,.nq57 dl,.nq57 dd{margin:0;padding:0;list-style:none}.nq57 button,.nq57 input,.nq57 select{font:inherit;color:inherit;margin:0}.nq57 button{background:transparent;padding:0;cursor:pointer;text-align:inherit}.nq57 table{border-collapse:collapse;text-indent:0;border-color:inherit}.nq57 th{text-align:inherit;font-weight:inherit}.nq57 svg{display:block;font-weight:500}.nq57 b{font-weight:800}.nq57 input[type=search]{-webkit-appearance:none;appearance:none}.nq57,.nq57 *,.nq57 :after,.nq57 :before{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59,130,246,.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }.nq57 .pointer-events-none{pointer-events:none}.nq57 .fixed{position:fixed}.nq57 .absolute{position:absolute}.nq57 .relative{position:relative}.nq57 .sticky{position:sticky}.nq57 .inset-0{inset:0}.nq57 .inset-y-0{top:0;bottom:0}.nq57 .left-0{left:0}.nq57 .top-0{top:0}.nq57 .top-1{top:.25rem}.nq57 .z-10{z-index:10}.nq57 .col-span-2{grid-column:span 2/span 2}.nq57 .col-span-4{grid-column:span 4/span 4}.nq57 .col-span-5{grid-column:span 5/span 5}.nq57 .col-span-7{grid-column:span 7/span 7}.nq57 .col-span-8{grid-column:span 8/span 8}.nq57 .mb-0\\.5{margin-bottom:.125rem}.nq57 .mb-2{margin-bottom:.5rem}.nq57 .ml-1{margin-left:.25rem}.nq57 .ml-auto{margin-left:auto}.nq57 .mt-0\\.5{margin-top:.125rem}.nq57 .mt-1{margin-top:.25rem}.nq57 .mt-2\\.5{margin-top:.625rem}.nq57 .mt-3{margin-top:.75rem}.nq57 .line-clamp-2{overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:2}.nq57 .block{display:block}.nq57 .inline-block{display:inline-block}.nq57 .flex{display:flex}.nq57 .inline-flex{display:inline-flex}.nq57 .table{display:table}.nq57 .grid{display:grid}.nq57 .h-0\\.5{height:.125rem}.nq57 .h-11{height:2.75rem}.nq57 .h-2{height:.5rem}.nq57 .h-2\\.5{height:.625rem}.nq57 .h-3{height:.75rem}.nq57 .h-\\[156px\\]{height:156px}.nq57 .h-\\[64px\\]{height:64px}.nq57 .h-full{height:100%}.nq57 .min-h-0{min-height:0}.nq57 .w-10{width:2.5rem}.nq57 .w-12{width:3rem}.nq57 .w-14{width:3.5rem}.nq57 .w-2{width:.5rem}.nq57 .w-2\\.5{width:.625rem}.nq57 .w-40{width:10rem}.nq57 .w-44{width:11rem}.nq57 .w-5{width:1.25rem}.nq57 .w-80{width:20rem}.nq57 .w-full{width:100%}.nq57 .min-w-0{min-width:0}.nq57 .max-w-\\[340px\\]{max-width:340px}.nq57 .flex-1{flex:1 1 0%}.nq57 .flex-none{flex:none}.nq57 .shrink-0{flex-shrink:0}.nq57 .-rotate-90{--tw-rotate:-90deg}.nq57 .-rotate-90,.nq57 .transform{transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}.nq57 .cursor-pointer{cursor:pointer}.nq57 .resize{resize:both}.nq57 .grid-cols-12{grid-template-columns:repeat(12,minmax(0,1fr))}.nq57 .grid-cols-4{grid-template-columns:repeat(4,minmax(0,1fr))}.nq57 .grid-cols-5{grid-template-columns:repeat(5,minmax(0,1fr))}.nq57 .grid-rows-2{grid-template-rows:repeat(2,minmax(0,1fr))}.nq57 .flex-col{flex-direction:column}.nq57 .flex-wrap{flex-wrap:wrap}.nq57 .items-end{align-items:flex-end}.nq57 .items-center{align-items:center}.nq57 .items-baseline{align-items:baseline}.nq57 .justify-start{justify-content:flex-start}.nq57 .justify-center{justify-content:center}.nq57 .justify-between{justify-content:space-between}.nq57 .justify-around{justify-content:space-around}.nq57 .gap-1{gap:.25rem}.nq57 .gap-1\\.5{gap:.375rem}.nq57 .gap-10{gap:2.5rem}.nq57 .gap-2{gap:.5rem}.nq57 .gap-2\\.5{gap:.625rem}.nq57 .gap-3{gap:.75rem}.nq57 .gap-4{gap:1rem}.nq57 .gap-5{gap:1.25rem}.nq57 .gap-8{gap:2rem}.nq57 .gap-x-10{-moz-column-gap:2.5rem;column-gap:2.5rem}.nq57 .gap-x-5{-moz-column-gap:1.25rem;column-gap:1.25rem}.nq57 .gap-y-1{row-gap:.25rem}.nq57 .gap-y-5{row-gap:1.25rem}.nq57 :is(.space-y-2>:not([hidden])~:not([hidden])){--tw-space-y-reverse:0;margin-top:calc(.5rem*(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.5rem*var(--tw-space-y-reverse))}.nq57 .overflow-auto{overflow:auto}.nq57 .overflow-hidden{overflow:hidden}.nq57 .truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.nq57 .whitespace-nowrap{white-space:nowrap}.nq57 .rounded-2xl{border-radius:1rem}.nq57 .rounded-full{border-radius:9999px}.nq57 .rounded-lg{border-radius:.5rem}.nq57 .rounded-md{border-radius:.375rem}.nq57 .rounded-sm{border-radius:.125rem}.nq57 .rounded-xl{border-radius:.75rem}.nq57 .border{border-width:1px}.nq57 .border-b{border-bottom-width:1px}.nq57 .border-t-2{border-top-width:2px}.nq57 .border-dashed{border-style:dashed}.nq57 .border-\\[\\#D9DEE7\\]{--tw-border-opacity:1;border-color:rgb(217 222 231/var(--tw-border-opacity,1))}.nq57 .border-\\[\\#E4E7EC\\]{--tw-border-opacity:1;border-color:rgb(228 231 236/var(--tw-border-opacity,1))}.nq57 .bg-\\[\\#E4E7EC\\]{--tw-bg-opacity:1;background-color:rgb(228 231 236/var(--tw-bg-opacity,1))}.nq57 .bg-white{--tw-bg-opacity:1;background-color:rgb(255 255 255/var(--tw-bg-opacity,1))}.nq57 .p-0\\.5{padding:.125rem}.nq57 .px-10{padding-left:2.5rem;padding-right:2.5rem}.nq57 .px-2{padding-left:.5rem;padding-right:.5rem}.nq57 .px-3{padding-left:.75rem;padding-right:.75rem}.nq57 .px-5{padding-left:1.25rem;padding-right:1.25rem}.nq57 .px-8{padding-left:2rem;padding-right:2rem}.nq57 .py-0\\.5{padding-top:.125rem;padding-bottom:.125rem}.nq57 .py-1{padding-top:.25rem;padding-bottom:.25rem}.nq57 .py-1\\.5{padding-top:.375rem;padding-bottom:.375rem}.nq57 .py-2{padding-top:.5rem;padding-bottom:.5rem}.nq57 .py-2\\.5{padding-top:.625rem;padding-bottom:.625rem}.nq57 .py-4{padding-top:1rem;padding-bottom:1rem}.nq57 .py-5{padding-top:1.25rem;padding-bottom:1.25rem}.nq57 .pl-2{padding-left:.5rem}.nq57 .pt-1{padding-top:.25rem}.nq57 .pt-3{padding-top:.75rem}.nq57 .text-left{text-align:left}.nq57 .text-right{text-align:right}.nq57 .align-top{vertical-align:top}.nq57 .align-middle{vertical-align:middle}.nq57 .text-\\[13px\\]{font-size:13px}.nq57 .text-\\[14px\\]{font-size:14px}.nq57 .text-\\[15px\\]{font-size:15px}.nq57 .text-\\[17px\\]{font-size:17px}.nq57 .text-\\[24px\\]{font-size:24px}.nq57 .text-\\[40px\\]{font-size:40px}.nq57 .text-base{font-size:1rem;line-height:1.5rem}.nq57 .text-sm{font-size:.875rem;line-height:1.25rem}.nq57 .text-xs{font-size:.75rem;line-height:1rem}.nq57 .font-bold{font-weight:700}.nq57 .font-medium{font-weight:500}.nq57 .font-normal{font-weight:400}.nq57 .font-semibold{font-weight:600}.nq57 .uppercase{text-transform:uppercase}.nq57 .italic{font-style:italic}.nq57 .tabular-nums{--tw-numeric-spacing:tabular-nums;font-variant-numeric:var(--tw-ordinal) var(--tw-slashed-zero) var(--tw-numeric-figure) var(--tw-numeric-spacing) var(--tw-numeric-fraction)}.nq57 .leading-none{line-height:1}.nq57 .leading-tight{line-height:1.25}.nq57 .tracking-wide{letter-spacing:.025em}.nq57 .text-\\[\\#101828\\]{--tw-text-opacity:1;color:rgb(16 24 40/var(--tw-text-opacity,1))}.nq57 .text-\\[\\#344054\\]{--tw-text-opacity:1;color:rgb(52 64 84/var(--tw-text-opacity,1))}.nq57 .text-\\[\\#475467\\]{--tw-text-opacity:1;color:rgb(71 84 103/var(--tw-text-opacity,1))}.nq57 .text-\\[\\#667085\\]{--tw-text-opacity:1;color:rgb(102 112 133/var(--tw-text-opacity,1))}.nq57 .text-\\[\\#98A2B3\\]{--tw-text-opacity:1;color:rgb(152 162 179/var(--tw-text-opacity,1))}.nq57 .text-white{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.nq57 .shadow-lg{--tw-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -4px rgba(0,0,0,.1);--tw-shadow-colored:0 10px 15px -3px var(--tw-shadow-color),0 4px 6px -4px var(--tw-shadow-color)}.nq57 .shadow-lg,.nq57 .shadow-sm{box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.nq57 .shadow-sm{--tw-shadow:0 1px 2px 0 rgba(0,0,0,.05);--tw-shadow-colored:0 1px 2px 0 var(--tw-shadow-color)}.nq57 .filter{filter:var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)}.nq57 .transition-colors{transition-property:color,background-color,border-color,text-decoration-color,fill,stroke;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.nq57 .transition-shadow{transition-property:box-shadow;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.nq57 .hover\\:bg-\\[\\#E4E7EC\\]:hover{--tw-bg-opacity:1;background-color:rgb(228 231 236/var(--tw-bg-opacity,1))}.nq57 .hover\\:bg-\\[\\#FAFBFC\\]:hover{--tw-bg-opacity:1;background-color:rgb(250 251 252/var(--tw-bg-opacity,1))}.nq57 .hover\\:text-\\[\\#101828\\]:hover{--tw-text-opacity:1;color:rgb(16 24 40/var(--tw-text-opacity,1))}.nq57 .hover\\:shadow-xl:hover{--tw-shadow:0 20px 25px -5px rgba(0,0,0,.1),0 8px 10px -6px rgba(0,0,0,.1);--tw-shadow-colored:0 20px 25px -5px var(--tw-shadow-color),0 8px 10px -6px var(--tw-shadow-color);box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.nq57 .focus\\:border-\\[\\#1D6FE8\\]:focus{--tw-border-opacity:1;border-color:rgb(29 111 232/var(--tw-border-opacity,1))}.nq57 .focus\\:outline-none:focus{outline:2px solid transparent;outline-offset:2px}.nq57 .focus-visible\\:underline:focus-visible{text-decoration-line:underline}.nq57 .focus-visible\\:ring-2:focus-visible{--tw-ring-offset-shadow:var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow,0 0 #0000)}.nq57 .focus-visible\\:ring-\\[\\#1D6FE8\\]:focus-visible{--tw-ring-opacity:1;--tw-ring-color:rgb(29 111 232/var(--tw-ring-opacity,1))}.nq57 .font-medium{font-weight:600}.nq57 .font-semibold{font-weight:700}.nq57 .font-bold{font-weight:800}.nq57 .text-xs{font-size:13px;line-height:1.4}.nq57 .text-sm{font-size:15px;line-height:1.45}";







/* ---------- Dữ liệu (thay bằng API/eForm khi có) ---------- */
const CHUYEN_DE = ["1. Nhiệm vụ", "2. Nguồn lực tài chính", "3. Dữ liệu đất đai", "4. Dữ liệu dùng chung", "5. TTHC và dịch vụ công", "6. Nền tảng số dùng chung", "7. Xã, phường và hạ tầng cơ sở", "8. KHCN, đổi mới sáng tạo, kinh tế số", "9. An toàn thông tin, an ninh mạng"];
// [mã, chuyên đề (chỉ mục), tên, đơn vị, loại, lưu ý, cần bổ sung, đầu mối, tình trạng trong phụ lục gốc, cách tính gợi ý]
const CHI_SO_RAW = [["NV01",0,"Tổng số nhiệm vụ đang theo dõi","nhiệm vụ","Đầu vào","Tháng 2 là cộng gộp hai nhóm báo cáo riêng",0,"Cơ quan Thường trực (Công an TP)","Có",""],["NV02",0,"Số nhiệm vụ đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Cơ quan Thường trực (Công an TP)","Có một phần",""],["NV03",0,"Tỷ lệ nhiệm vụ hoàn thành","%","Kết quả","Tự tính từ NV02 và NV01",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV04",0,"Số nhiệm vụ đang thực hiện","nhiệm vụ","Đầu vào","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV05",0,"Số nhiệm vụ đã quá thời hạn giao","nhiệm vụ","Kết quả","Tháng 2 cộng gộp 4 (Trung ương) + 8 (BCĐ)",0,"Cơ quan Thường trực (Công an TP)","Có",""],["NV06",0,"Số nhiệm vụ quá hạn cần xử lý trực tiếp","nhiệm vụ","Kết quả","T7: báo cáo viết \"323\", tôi hiểu là 32 (33 trừ 1)",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV07",0,"Nhiệm vụ Trung ương giao: tổng số","nhiệm vụ","Đầu vào","",0,"Cơ quan Thường trực (Công an TP)","Có",""],["NV08",0,"Nhiệm vụ Trung ương giao: đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Cơ quan Thường trực (Công an TP)","Có một phần",""],["NV09",0,"Kế hoạch 20-KH/BCĐ57: tổng số nhiệm vụ","nhiệm vụ","Đầu vào","Điều chỉnh theo QĐ 37-QĐ/BCĐ57 (15/9)",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV10",0,"Kế hoạch 20-KH/BCĐ57: đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV11",0,"Kế hoạch 20-KH/BCĐ57: quá hạn","nhiệm vụ","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV12",0,"Kế hoạch 35-KH/BCĐ57 (100 ngày): tổng số","nhiệm vụ","Đầu vào","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV13",0,"Kế hoạch 35-KH/BCĐ57: đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV14",0,"Kế hoạch 35-KH/BCĐ57: quá hạn","nhiệm vụ","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV15",0,"Thông báo kết luận: tổng số nhiệm vụ","nhiệm vụ","Đầu vào","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["NV16",0,"Thông báo kết luận: đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["TC01",1,"Tổng kinh phí bố trí 2026 cho KHCN, ĐMST, CĐS","tỷ đồng","Đầu vào","",0,"Sở Tài chính","Có",""],["TC02",1,"Kinh phí đã phân bổ chi tiết","tỷ đồng","Đầu vào","",0,"Sở Tài chính","Có",""],["TC03",1,"Tỷ lệ phân bổ trên tổng dự toán","%","Kết quả","Tự tính. T8, T9 phạm vi theo báo cáo",0,"Sở Tài chính","Tính được",""],["TC04",1,"Chi đầu tư: đã phân bổ / kế hoạch","%","Kết quả","",0,"Sở Tài chính","Tính được",""],["TC05",1,"Chi thường xuyên: đã phân bổ / dự toán","%","Kết quả","",0,"Sở Tài chính","Tính được",""],["TC06",1,"Giải ngân chi thường xuyên (khối cơ quan TP)","%","Kết quả","Mẫu số đổi qua các kỳ (T5, T6 chỉ có tỷ lệ). Số toàn TP theo TB 20/10 ở TC14",0,"Sở Tài chính","Có một phần",""],["TC07",1,"Giải ngân chi thường xuyên (khối xã, phường)","%","Kết quả","",0,"Sở Tài chính","Có một phần",""],["TC08",1,"Giải ngân chi đầu tư","%","Kết quả","Mẫu số đổi qua các kỳ (2.017 → 5.482 → 5.987 → 5.452 tỷ)",0,"Sở Tài chính","Có",""],["TC09",1,"Giải ngân trên tổng nguồn thuộc phạm vi theo dõi","%","Kết quả","Chỉ có số T8. Số theo TB 20/10 có phạm vi khác, ở TC13",0,"Sở Tài chính","Có một phần",""],["TC10",1,"Số đơn vị khối sở, ngành chưa phát sinh giải ngân","đơn vị","Kết quả","",0,"Sở Tài chính","Chưa có",""],["TC11",1,"Số xã, phường chưa phát sinh giải ngân","xã, phường","Kết quả","",0,"Sở Tài chính","Chưa có",""],["TC12",1,"Kinh phí chưa phân bổ","tỷ đồng","Kết quả","",0,"Sở Tài chính","Có",""],["TC13",1,"Giải ngân trên tổng dự toán được giao (gồm kinh phí chuyển nguồn)","%","Kết quả","Phạm vi khác TC09, không so sánh trực tiếp",0,"Sở Tài chính","Chưa có",""],["TC14",1,"Giải ngân chi thường xuyên toàn Thành phố (theo TB 20/10)","%","Kết quả","Phạm vi khác TC06 và TC07",0,"Sở Tài chính","Có",""],["DD01",2,"Tổng số thửa đất trên bản đồ","thửa","Đầu vào","Mẫu số thay đổi theo từng kỳ (cập nhật thửa thuộc dự án GPMB)",0,"Sở NN&MT","Có",""],["DD02",2,"Số thửa đã xây dựng cơ sở dữ liệu","thửa","Đầu ra","",0,"Sở NN&MT","Chưa có",""],["DD03",2,"Tỷ lệ thửa đã có trong CSDL","%","Kết quả","Tự tính",0,"Sở NN&MT","Chưa có",""],["DD04",2,"Số thửa Nhóm 1 \"Đúng - Đủ - Sạch - Sống\"","thửa","Đầu ra","",0,"Sở NN&MT","Có",""],["DD05",2,"Tỷ lệ thửa Nhóm 1 trên tổng thửa","%","Kết quả","Tự tính, chỉ ở kỳ có đủ cả tử và mẫu",0,"Sở NN&MT","Tính được",""],["DD06",2,"Tỷ lệ dữ liệu đạt chuẩn theo báo cáo (cách tính khác nhau)","%","Kết quả","Không so sánh với DD05",0,"Sở NN&MT","Có một phần",""],["DD07",2,"Tiến độ thu nhận so với khối lượng hiện có","%","Đầu ra","Báo cáo T8 lưu ý rõ điểm này",0,"Sở NN&MT","Chưa có",""],["DD08",2,"Số thửa cần tiếp tục làm giàu, làm sạch","thửa","Đầu vào","",0,"Sở NN&MT","Chưa có",""],["DD09",2,"Số địa phương còn khối lượng lớn được tổ công tác đôn đốc","xã, phường","Đầu vào","",0,"Sở NN&MT","Chưa có",""],["DL01",3,"Số nguồn dữ liệu ưu tiên đã kết nối vào Kho dữ liệu","nguồn","Đầu ra","T7 báo cáo chưa đủ cơ sở xác định",0,"Sở KHCN","Chưa có",""],["DL02",3,"Dữ liệu thu ngân sách đã tích hợp","%","Đầu ra","T8: tăng từ 35% lên 100% (9.758.394 bản ghi)",0,"Sở KHCN","Chưa có",""],["DL03",3,"Dữ liệu quản lý văn bản, điều hành đã tích hợp","văn bản","Đầu ra","",0,"Sở KHCN","Chưa có",""],["DL04",3,"Số bộ dữ liệu mở đã công bố","bộ","Đầu ra","T8 chỉ đạo rà soát, tạm dừng công khai dữ liệu không cập nhật",0,"Sở KHCN","Chưa có",""],["DL05",3,"Số nhiệm vụ nhóm 3 (triển khai Kho dữ liệu) hoàn thành","nhiệm vụ","Đầu ra","",0,"Sở KHCN","Chưa có",""],["DL06",3,"Số kịch bản khai thác dữ liệu đã xây dựng","kịch bản","Kết quả","",0,"Sở KHCN","Chưa có",""],["DL07",3,"Số loại dữ liệu được khai thác phục vụ giải quyết TTHC","loại","Kết quả","TB 20/10 nêu chỉ 03 loại",0,"Sở KHCN","Chưa có",""],["DL08",3,"Số CSDL kết nối kỹ thuật với HTTT giải quyết TTHC","CSDL","Đầu ra","",0,"Sở KHCN","Chưa có",""],["DL09",3,"Dung lượng lưu trữ Kho dữ liệu dùng chung","TB","Đầu vào","",0,"Sở KHCN","Chưa có",""],["DL10",3,"Số tài sản công trong CSDL","tài sản","Đầu ra","",0,"Sở Tài chính","Có một phần",""],["DL11",3,"Số dự án trong CSDL quản lý đầu tư","dự án","Đầu ra","",0,"Sở Tài chính","Có một phần",""],["DL12",3,"Số hồ sơ cán bộ, công chức đồng bộ CSDL quốc gia","hồ sơ","Đầu ra","",0,"Sở Nội vụ","Có một phần",""],["DL13",3,"Số người dân có hồ sơ sức khỏe điện tử","người","Đầu ra","",0,"Sở Y tế","Có một phần",""],["TT01",4,"Tổng số TTHC thực hiện trên địa bàn","TTHC","Đầu vào","Số đổi do Trung ương điều chỉnh, cắt giảm",0,"Trung tâm PVHCC","Có",""],["TT02",4,"Số TTHC dịch vụ công trực tuyến toàn trình","TTHC","Đầu ra","",0,"Trung tâm PVHCC","Có",""],["TT03",4,"Tỷ lệ TTHC trực tuyến toàn trình","%","Kết quả","Tự tính. Là tỷ lệ thủ tục có dịch vụ, chưa phải tỷ lệ hồ sơ thực tế giải quyết trực tuyến",0,"Trung tâm PVHCC","Tính được",""],["TT04",4,"Số TTHC trực tuyến một phần","TTHC","Đầu ra","",0,"Trung tâm PVHCC","Chưa có",""],["TT05",4,"Số TTHC đã phê duyệt phương án tái cấu trúc","TTHC","Đầu ra","",0,"Trung tâm PVHCC","Chưa có",""],["TT06",4,"Tỷ lệ TTHC đã phê duyệt tái cấu trúc","%","Kết quả","Tự tính",0,"Trung tâm PVHCC","Chưa có",""],["TT07",4,"Chi phí tuân thủ giảm","tỷ đồng","Kết quả","Báo cáo T8 nêu 60,8%",0,"Trung tâm PVHCC","Chưa có",""],["TT08",4,"Số TTHC trọng điểm đã chuyển toàn trình (không nhận hồ sơ trực tiếp)","TTHC","Kết quả","",0,"Trung tâm PVHCC","Chưa có",""],["TT09",4,"Số TTHC được phân cấp, ủy quyền","TTHC","Đầu ra","Định nghĩa khác nhau giữa các kỳ (phân cấp; ủy quyền; duy trì ủy quyền)",0,"Trung tâm PVHCC","Chưa có",""],["TT10",4,"Điểm Bộ chỉ số 766","điểm","Kết quả","Xếp hạng 19/34 (T3)",0,"Trung tâm PVHCC","Chưa có",""],["TT11",4,"Số hồ sơ phát sinh trên Cổng Dịch vụ công TP trong kỳ","hồ sơ","Đầu ra","",0,"Trung tâm PVHCC","Có",""],["TT12",4,"Số lượt lấy số đặt lịch trực tuyến trong kỳ","lượt","Đầu ra","",0,"Trung tâm PVHCC","Chưa có",""],["TT13",4,"Thời gian phục vụ trung bình","phút","Kết quả","",0,"Trung tâm PVHCC","Chưa có",""],["TT14",4,"Số TTHC trọng điểm chạy trên HTTT giải quyết TTHC của TP","TTHC","Đầu ra","",0,"Trung tâm PVHCC","Chưa có",""],["TT15",4,"Số tài khoản doanh nghiệp trên hệ thống văn bản điện tử","tài khoản","Đầu ra","",0,"Trung tâm PVHCC","Chưa có",""],["TT16",4,"Tỷ lệ doanh nghiệp đã xác thực","%","Kết quả","Tự tính",0,"Trung tâm PVHCC","Chưa có",""],["TT17",4,"Số tài khoản định danh iHanoi","tài khoản","Đầu ra","",0,"Sở KHCN","Có một phần",""],["NT01",5,"HanoiWork: số tài khoản kích hoạt","tài khoản","Đầu ra","T9 là số xấp xỉ (~84.000, tạo lập)",0,"Sở KHCN","Chưa có",""],["NT02",5,"HanoiWork: tỷ lệ kích hoạt / sử dụng","%","Kết quả","T3, T5 báo cáo \"khoảng 90%\" trực tiếp. T8 tự tính",0,"Sở KHCN","Chưa có",""],["NT03",5,"HanoiWork: số cơ quan, đơn vị triển khai","đơn vị","Đầu ra","",0,"Sở KHCN","Chưa có",""],["NT04",5,"HanoiWork: số công việc khởi tạo","công việc","Đầu ra","",0,"Sở KHCN","Chưa có",""],["NT05",5,"HanoiWork: số cán bộ được đánh giá OKR/KPI trong tháng","người","Kết quả","",0,"Sở KHCN","Chưa có",""],["NT06",5,"HanoiWork: số lượt dùng trợ lý AI","lượt","Kết quả","",0,"Sở KHCN","Chưa có",""],["NT07",5,"HanoiWork: điểm chất lượng trả lời của trợ lý AI","điểm /100","Kết quả","",0,"Sở KHCN","Chưa có",""],["NT08",5,"IOC Thành ủy: số chỉ số đã cấu hình","chỉ số","Đầu ra","",0,"Văn phòng Thành ủy","Chưa có",""],["NT09",5,"IOC Thành ủy: số tài khoản đã cấp","tài khoản","Đầu ra","Tuần 41 ghi 28.000, tăng nhiều so với T8 (9.269)",0,"Văn phòng Thành ủy","Chưa có",""],["NT10",5,"IOC Thành ủy: tỷ lệ đơn vị thống nhất dự thảo quy chế","%","Kết quả","",0,"Văn phòng Thành ủy","Chưa có",""],["NT11",5,"Hệ thống theo dõi nhiệm vụ 04 trục: số tài khoản","tài khoản","Đầu ra","",0,"Văn phòng Thành ủy","Chưa có",""],["NT12",5,"Tỷ lệ đảng viên cài đặt, sử dụng Sổ tay đảng viên điện tử","%","Kết quả","T4 báo cáo \"trên 51%\". Mẫu số 472.845 (T8)",0,"Văn phòng Thành ủy","Chưa có",""],["NT13",5,"Tỷ lệ đảng viên đăng nhập 04 dịch vụ công của Đảng","%","Kết quả","",0,"Văn phòng Thành ủy","Chưa có",""],["NT14",5,"Số giao dịch nộp đảng phí trực tuyến thành công","giao dịch","Kết quả","",0,"Văn phòng Thành ủy","Chưa có",""],["NT15",5,"Thư điện tử công vụ Đảng: số tài khoản khai mới","tài khoản","Đầu ra","",0,"Văn phòng Thành ủy","Chưa có",""],["NT16",5,"Khối MTTQ: tỷ lệ hoàn thành đúng hạn trên HanoiWork","%","Kết quả","",0,"Văn phòng UB MTTQ TP","Chưa có",""],["CS01",6,"Số xã, phường phát hành văn bản toàn trình từ 90% trở lên","xã, phường","Kết quả","Cách đo của T7 khác (chỉ 17 đơn vị đạt 100%)",0,"Sở KHCN / VPTU (cần xác nhận)","Chưa có",""],["CS02",6,"Số xã, phường đạt 100% văn bản toàn trình","xã, phường","Kết quả","",0,"Sở KHCN / VPTU (cần xác nhận)","Chưa có",""],["CS03",6,"Số đơn vị có tỷ lệ văn bản toàn trình dưới 50%","đơn vị","Kết quả","",0,"Sở KHCN / VPTU (cần xác nhận)","Chưa có",""],["CS04",6,"Số máy tính đã bàn giao, lắp đặt cho xã, phường","máy","Đầu vào","",0,"Sở KHCN","Có một phần",""],["CS05",6,"Số phòng họp trực tuyến đã lắp đặt","phòng","Đầu vào","",0,"Sở KHCN","Có một phần",""],["CS06",6,"Chữ ký số cá nhân cấp cho cán bộ xử lý văn bản","chữ ký","Đầu vào","",0,"Cần xác nhận","Chưa có",""],["CS07",6,"Số xã, phường có mô hình, sáng kiến nhân rộng","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS08",6,"Số xã, phường có kết quả dữ liệu số","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS09",6,"Số xã, phường có kết quả dịch vụ công, TTHC","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Có một phần",""],["CS10",6,"Xếp loại A: hoàn thành toàn bộ","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS11",6,"Xếp loại B: tiến độ tốt (từ 80%)","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS12",6,"Xếp loại C: đang triển khai bình thường","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS13",6,"Xếp loại D/D2: có tín hiệu quá hạn","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS14",6,"Xếp loại E: cần chuẩn hóa, chưa đủ số liệu","xã, phường","Kết quả","",0,"Cơ quan Thường trực (Công an TP)","Chưa có",""],["CS15",6,"Số phiên livestream giới thiệu sản phẩm","phiên","Đầu ra","",0,"Cần xác nhận","Chưa có",""],["CS16",6,"Số sản phẩm được giới thiệu","sản phẩm","Đầu ra","",0,"Cần xác nhận","Chưa có",""],["CS17",6,"Số xã, phường triển khai Thôn, Tổ dân phố số","xã, phường","Đầu ra","",0,"Văn phòng UB MTTQ TP","Chưa có",""],["CS18",6,"Số nhóm Chat, nhóm Cộng đồng cơ sở","nhóm","Đầu ra","",0,"Văn phòng UB MTTQ TP","Chưa có",""],["KH01",7,"Tỷ trọng kinh tế số trong GRDP","%","Kết quả","TB 20/10 yêu cầu tách rõ tỷ trọng và mức đóng góp tăng trưởng",0,"Thống kê TP + Sở KHCN","Chưa có",""],["KH02",7,"Kinh tế số lõi trong GRDP","%","Kết quả","",0,"Thống kê TP + Sở KHCN","Chưa có",""],["KH03",7,"Kinh tế số ngành trong GRDP","%","Kết quả","",0,"Thống kê TP + Sở KHCN","Chưa có",""],["KH04",7,"Số nhiệm vụ phát triển kinh tế số đã hoàn thành","nhiệm vụ","Đầu ra","",0,"Sở KHCN","Chưa có",""],["KH05",7,"Số đơn vị đã đăng ký sản phẩm gắn với kinh tế số","đơn vị","Đầu ra","Đăng ký sản phẩm lượng hóa được trước 07/11/2026 (TB 20/10)",0,"Sở KHCN","Chưa có",""],["KH06",7,"Số đề xuất giải quyết 30 bài toán lớn","đề xuất","Đầu vào","",0,"Sở KHCN","Có một phần",""],["KH07",7,"Số nhiệm vụ KHCN đặt hàng đã phê duyệt","nhiệm vụ","Đầu ra","",0,"Sở KHCN","Có một phần",""],["KH08",7,"Số bài toán lớn ưu tiên triển khai ngay","bài toán","Đầu ra","",0,"Sở KHCN","Có một phần",""],["KH09",7,"Số chuyên gia, nhà khoa học trong cơ sở dữ liệu","người","Đầu vào","",0,"Sở KHCN","Chưa có",""],["KH10",7,"HanoTEX: số tài khoản đăng ký","tài khoản","Đầu ra","",0,"Sở KHCN","Có một phần",""],["KH11",7,"HanoTEX: số doanh nghiệp tham gia, niêm yết","doanh nghiệp","Đầu ra","",0,"Sở KHCN","Có một phần",""],["KH12",7,"HanoTEX: số giải pháp công nghệ trên sàn","giải pháp","Đầu ra","",0,"Sở KHCN","Có một phần",""],["KH13",7,"HanoTEX: số hợp đồng ký kết","hợp đồng","Kết quả","",0,"Sở KHCN","Có một phần",""],["KH14",7,"Số doanh nghiệp khoa học và công nghệ","doanh nghiệp","Đầu vào","",0,"Sở KHCN","Chưa có",""],["KH15",7,"Số mô hình đề xuất thử nghiệm có kiểm soát (sandbox)","mô hình","Đầu vào","",0,"Sở KHCN","Có một phần",""],["AT01",8,"Số hệ thống thông tin được phê duyệt cấp độ ATTT","hệ thống","Đầu ra","Nhảy từ 101 (25/6) lên 238 (30/6): có thể khác cách đếm hồ sơ và hệ thống",0,"Công an TP","Có",""],["AT02",8,"Tỷ lệ hệ thống được phê duyệt cấp độ","%","Kết quả","Tổng số hệ thống: 245 (T5, T6), 249 (T8). Tự tính",0,"Công an TP","Tính được",""],["AT03",8,"Số hồ sơ cấp độ đang thẩm định","hồ sơ","Đầu vào","",0,"Công an TP","Chưa có",""],["AT04",8,"Số đơn vị chưa lập hồ sơ cấp độ","đơn vị","Kết quả","",0,"Công an TP","Chưa có",""],["AT05",8,"Số máy tính được SOC giám sát","máy","Đầu vào","",0,"Công an TP","Chưa có",""],["AT06",8,"Số máy chủ Internet được SOC giám sát","máy","Đầu vào","",0,"Công an TP","Chưa có",""],["AT07",8,"Số cảnh báo an ninh rất nghiêm trọng (EDR)","cảnh báo","Kết quả","",0,"Công an TP","Có một phần",""],["AT08",8,"Số cảnh báo nguy cơ mất an ninh mạng trong kỳ","cảnh báo","Kết quả","",0,"Công an TP","Có một phần",""],["AT09",8,"Tỷ lệ đơn vị gửi báo cáo tình hình ATTT","%","Kết quả","",0,"Công an TP","Chưa có",""],["BS01",5,"Tỷ lệ dữ liệu IOC cập nhật tự động","","Kết quả","",1,"Văn phòng Thành ủy","Chưa có","Dữ liệu cập nhật tự động / tổng dữ liệu cấu hình"],["BS02",5,"Tỷ lệ dữ liệu IOC được xác nhận đúng hạn","","Kết quả","",1,"Văn phòng Thành ủy","Chưa có","Đã xác nhận đúng hạn / phải xác nhận"],["BS03",5,"Tần suất khai thác IOC và số nội dung chỉ đạo, điều hành được hỗ trợ từ hệ thống","","Kết quả","",1,"Văn phòng Thành ủy","Chưa có","Lượt truy cập; số chỉ đạo dùng dữ liệu IOC"],["BS04",5,"Tỷ lệ cán bộ hoạt động thường xuyên trên nền tảng dùng chung","","Kết quả","",1,"Sở KHCN","Chưa có","Tài khoản có thao tác trong kỳ / tổng tài khoản"],["BS05",5,"Tỷ lệ nhiệm vụ giao và cập nhật hoàn toàn trên hệ thống","","Kết quả","",1,"Sở KHCN","Chưa có","Nhiệm vụ xử lý hoàn toàn trên hệ thống / tổng nhiệm vụ"],["BS06",5,"Tỷ lệ hoàn thành đúng hạn và mức độ gắn nhiệm vụ với sản phẩm đầu ra","","Kết quả","",1,"Sở KHCN","Chưa có","Hoàn thành đúng hạn / hoàn thành; nhiệm vụ có sản phẩm đầu ra / tổng"],["BS07",4,"Tỷ lệ hồ sơ thực tế giải quyết trực tuyến toàn trình","","Kết quả","",1,"Trung tâm PVHCC","Có một phần","Hồ sơ trực tuyến toàn trình / tổng hồ sơ tiếp nhận"],["BS08",4,"Số thành phần hồ sơ, giấy tờ được cắt giảm; thời gian xử lý và chi phí thực giảm","","Kết quả","",1,"Trung tâm PVHCC","Chưa có","Trước và sau tái cấu trúc, theo từng TTHC"],["BS09",4,"Tỷ lệ tái sử dụng dữ liệu dùng chung trong giải quyết TTHC","","Kết quả","",1,"Trung tâm PVHCC","Chưa có","Hồ sơ dùng dữ liệu có sẵn / tổng hồ sơ"],["BS10",3,"Tỷ lệ nguồn dữ liệu đạt kiểm chứng chất lượng, nghiệm thu, phân quyền","","Kết quả","",1,"Sở KHCN","Chưa có","Nguồn đã nghiệm thu / 13"],["BS11",3,"Tần suất cập nhật và tiêu chí chất lượng theo từng nguồn dữ liệu","","Kết quả","",1,"Sở KHCN","Chưa có","Theo từng nguồn trong 13 nguồn"],["BS12",2,"Tỷ lệ hoàn thành làm sạch theo từng xã, phường (126 đơn vị) so với KPI","","Kết quả","",1,"Sở NN&MT","Chưa có","Thửa Nhóm 1 / thửa phải hoàn thành theo KPI từng xã"],["BS13",7,"Doanh thu mới, năng suất tăng thêm, chi phí cắt giảm, sản phẩm dịch vụ mới từ chuyển đổi số theo ngành","","Kết quả","",1,"Sở KHCN","Chưa có","Theo từng sản phẩm đăng ký của sở, ngành"],["BS14",7,"Số giao dịch, hợp đồng, giá trị thương mại hóa qua Sàn giao dịch công nghệ, Chợ Chuyển đổi số","","Kết quả","",1,"Sở KHCN","Có một phần","Số hợp đồng, giá trị hợp đồng"],["BS15",7,"Số người dùng và hiệu quả khai thác của các ứng dụng đã triển khai (HanoiCheck, camera AI...)","","Kết quả","",1,"Sở KHCN","Có một phần","Người dùng; kết quả nghiệm thu; chuyển giao"],["BS16",7,"Tỷ trọng kinh tế số trong GRDP và mức đóng góp vào tăng trưởng GRDP (tách riêng)","","Kết quả","",1,"Thống kê TP + Sở KHCN","Chưa có","Hai chỉ số khác nhau, cần chuẩn hóa phương pháp"],["BS17",6,"Số xã, phường thiếu nhân lực công nghệ thông tin chuyên trách theo nhóm (thiếu nhân lực, kỹ năng, điều kiện kỹ thuật)","","Kết quả","",1,"Sở Nội vụ","Có một phần","Phân loại 126 xã, phường"],["BS18",1,"Giải ngân theo từng đơn vị và hồ sơ còn thiếu, khối lượng có thể nghiệm thu","","Kết quả","",1,"Sở Tài chính","Có một phần","Danh sách theo đơn vị, theo khoản chi"]];
// [mã, kỳ, thứ tự kỳ, tử số, mẫu số, giá trị]
const CHUOI_RAW = [["NV01","T2/2026",1,null,null,585],["NV01","T3/2026",2,null,null,606],["NV01","T4/2026",3,null,null,628],["NV01","T5/2026",4,null,null,695],["NV01","T6/2026",5,null,null,713],["NV01","T7/2026",6,null,null,749],["NV01","T8/2026",7,null,null,846],["NV01","T9/2026",8,null,null,867],["NV01","Tuần 41",9,null,null,865],["NV02","T2/2026",1,null,null,227],["NV02","T3/2026",2,null,null,266],["NV02","T4/2026",3,null,null,277],["NV02","T5/2026",4,null,null,306],["NV02","T6/2026",5,null,null,344],["NV02","T7/2026",6,null,null,380],["NV02","T8/2026",7,null,null,424],["NV02","T9/2026",8,null,null,461],["NV02","Tuần 41",9,null,null,478],["NV03","T2/2026",1,227,585,0.388034],["NV03","T3/2026",2,266,606,0.438944],["NV03","T4/2026",3,277,628,0.441083],["NV03","T5/2026",4,306,695,0.440288],["NV03","T6/2026",5,344,713,0.482468],["NV03","T7/2026",6,380,749,0.507343],["NV03","T8/2026",7,424,846,0.501182],["NV03","T9/2026",8,461,867,0.531719],["NV03","Tuần 41",9,478,865,0.552601],["NV04","T3/2026",2,null,null,340],["NV04","T4/2026",3,null,null,351],["NV04","T5/2026",4,null,null,389],["NV04","T6/2026",5,null,null,369],["NV04","T7/2026",6,null,null,369],["NV04","T8/2026",7,null,null,422],["NV04","T9/2026",8,null,null,406],["NV04","Tuần 41",9,null,null,387],["NV05","T2/2026",1,null,null,12],["NV05","T3/2026",2,null,null,36],["NV05","T4/2026",3,null,null,26],["NV05","T5/2026",4,null,null,22],["NV05","T6/2026",5,null,null,19],["NV05","T7/2026",6,null,null,33],["NV05","T8/2026",7,null,null,24],["NV05","T9/2026",8,null,null,15],["NV05","Tuần 41",9,null,null,10],["NV06","T6/2026",5,null,null,18],["NV06","T7/2026",6,null,null,32],["NV06","T8/2026",7,null,null,23],["NV06","T9/2026",8,null,null,14],["NV06","Tuần 41",9,null,null,9],["NV07","T2/2026",1,null,null,258],["NV07","T5/2026",4,null,null,292],["NV07","T8/2026",7,null,null,296],["NV07","T9/2026",8,null,null,296],["NV08","T2/2026",1,null,null,145],["NV08","T5/2026",4,null,null,164],["NV08","T8/2026",7,null,null,189],["NV08","T9/2026",8,null,null,190],["NV09","T5/2026",4,null,null,125],["NV09","T8/2026",7,null,null,125],["NV09","T9/2026",8,null,null,126],["NV10","T5/2026",4,null,null,27],["NV10","T8/2026",7,null,null,56],["NV10","T9/2026",8,null,null,58],["NV11","T5/2026",4,null,null,8],["NV11","T8/2026",7,null,null,5],["NV11","T9/2026",8,null,null,0],["NV12","T8/2026",7,null,null,26],["NV12","T9/2026",8,null,null,26],["NV13","T8/2026",7,null,null,3],["NV13","T9/2026",8,null,null,8],["NV14","T8/2026",7,null,null,4],["NV14","T9/2026",8,null,null,2],["NV15","T5/2026",4,null,null,269],["NV15","T8/2026",7,null,null,346],["NV15","T9/2026",8,null,null,366],["NV16","T5/2026",4,null,null,114],["NV16","T8/2026",7,null,null,153],["NV16","T9/2026",8,null,null,166],["TC01","T2/2026",1,null,null,9090.399],["TC02","T2/2026",1,null,null,1866.044],["TC02","T3/2026",2,null,null,2136.052],["TC02","T4/2026",3,null,null,2529.289],["TC02","T5/2026",4,null,null,3404.63],["TC02","T6/2026",5,null,null,3479.86],["TC02","T7/2026",6,null,null,4920.47],["TC02","T8/2026",7,null,null,8942.06],["TC02","T9/2026",8,null,null,8832.626],["TC03","T2/2026",1,1866.044,9090.399,0.205276],["TC03","T3/2026",2,2136.052,9090.399,0.234979],["TC03","T4/2026",3,2529.289,9090.399,0.278237],["TC03","T5/2026",4,3404.63,9090.399,0.37453],["TC03","T6/2026",5,3479.86,9090.399,0.382806],["TC03","T7/2026",6,4920.47,9090.399,0.541282],["TC03","T8/2026",7,8942.06,9090.399,0.983682],["TC03","T9/2026",8,8832.626,9090.399,0.971643],["TC04","T2/2026",1,622.6,5560,0.111978],["TC04","T5/2026",4,1437.04,5560,0.25846],["TC04","T9/2026",8,5452.042,5560,0.980583],["TC05","T2/2026",1,1243.444,3530.399,0.352211],["TC05","T5/2026",4,1967.59,3530.399,0.557328],["TC05","T9/2026",8,3380.584,3530.399,0.957564],["TC06","T5/2026",4,47.247,null,0.0298],["TC06","T6/2026",5,53.772,null,0.033],["TC06","T7/2026",6,321.897,4105.159,0.078413],["TC06","T8/2026",7,441.315,4510.813,0.097835],["TC06","T9/2026",8,650.72,4126.753,0.157683],["TC06","Tuần 41",9,726.458,4147.157,0.17517],["TC07","T9/2026",8,131.724,304.626,0.432412],["TC07","Tuần 41",9,179.962,323.964,0.5555],["TC08","T5/2026",4,227.601,null,0.1751],["TC08","T6/2026",5,325.455,null,0.2196],["TC08","T7/2026",6,405.301,2017.241,0.200918],["TC08","T8/2026",7,334.247,5482.042,0.060971],["TC08","T9/2026",8,2980.959,5987.241,0.497885],["TC08","Tuần 41",9,3076.037,5452.042,0.564199],["TC09","T8/2026",7,775.562,9992.855,0.077612],["TC10","T7/2026",6,null,null,7],["TC11","T7/2026",6,33,126,0.261905],["TC12","T2/2026",1,null,null,7224.295],["TC12","T5/2026",4,null,null,5685.77],["TC12","T6/2026",5,null,null,5610.54],["TC12","T8/2026",7,null,null,148.34],["TC12","T9/2026",8,null,null,257.773],["TC13","TB 20/10",10,null,null,0.4116],["TC14","TB 20/10",10,null,null,0.2628],["DD01","T5/2026",4,null,null,4189073],["DD01","T8/2026",7,null,null,4986393],["DD01","T9/2026",8,null,null,4899639],["DD01","Tuần 41",9,null,null,4827135],["DD02","T5/2026",4,null,null,2115220],["DD02","T8/2026",7,null,null,3204196],["DD02","T9/2026",8,null,null,3770751],["DD02","Tuần 41",9,null,null,4781746],["DD03","T5/2026",4,2115220,4189073,0.504937],["DD03","T8/2026",7,3204196,4986393,0.642588],["DD03","T9/2026",8,3770751,4899639,0.769598],["DD03","Tuần 41",9,4781746,4827135,0.990597],["DD04","T5/2026",4,null,null,711116],["DD04","T7/2026",6,null,null,1080181],["DD04","T8/2026",7,null,null,2072808],["DD04","T9/2026",8,null,null,2553383],["DD04","Tuần 41",9,null,null,2782633],["DD05","T5/2026",4,711116,4189073,0.169755],["DD05","T8/2026",7,2072808,4986393,0.415693],["DD05","T9/2026",8,2553383,4899639,0.521137],["DD05","Tuần 41",9,2782633,4827135,0.576456],["DD06","T4/2026",3,null,null,0.46],["DD06","T6/2026",5,null,null,0.38],["DD07","T8/2026",7,null,null,0.94],["DD08","T9/2026",8,null,null,2410803],["DD09","T9/2026",8,22,126,0.174603],["DL01","T8/2026",7,10,13,0.769231],["DL01","T9/2026",8,13,13,1],["DL01","Tuần 41",9,13,13,1],["DL02","T8/2026",7,null,null,1],["DL03","T8/2026",7,null,null,755490],["DL04","T6/2026",5,93,93,1],["DL05","T9/2026",8,2,4,0.5],["DL05","Tuần 41",9,2,4,0.5],["DL06","T9/2026",8,null,null,4],["DL07","TB 20/10",10,3,13,0.230769],["DL08","T9/2026",8,13,13,1],["DL09","T9/2026",8,null,null,39],["DL10","T6/2026",5,null,null,543000],["DL11","T6/2026",5,null,null,27000],["DL12","T6/2026",5,null,null,129098],["DL13","T6/2026",5,null,null,9236484],["TT01","T2/2026",1,null,null,2072],["TT01","T4/2026",3,null,null,2075],["TT01","T7/2026",6,null,null,1941],["TT02","T2/2026",1,null,null,1363],["TT02","T4/2026",3,null,null,1120],["TT02","T7/2026",6,null,null,1100],["TT02","T8/2026",7,null,null,1173],["TT03","T2/2026",1,1363,2072,0.657819],["TT03","T4/2026",3,1120,2075,0.539759],["TT03","T7/2026",6,1100,1941,0.566718],["TT04","T4/2026",3,null,null,921],["TT04","T7/2026",6,null,null,812],["TT04","T8/2026",7,null,null,762],["TT05","T6/2026",5,null,null,1512],["TT05","T7/2026",6,null,null,1548],["TT05","T8/2026",7,null,null,1552],["TT05","T9/2026",8,null,null,1552],["TT06","T6/2026",5,1512,1721,0.878559],["TT06","T7/2026",6,1548,1721,0.899477],["TT06","T8/2026",7,1552,1721,0.901801],["TT06","T9/2026",8,1552,1721,0.901801],["TT07","T6/2026",5,null,null,408],["TT07","T8/2026",7,null,null,408.4],["TT08","T5/2026",4,12,25,0.48],["TT09","T2/2026",1,null,null,243],["TT09","T4/2026",3,null,null,661],["TT09","T7/2026",6,null,null,535],["TT10","T3/2026",2,null,null,95.32],["TT11","T8/2026",7,null,null,247614],["TT12","T8/2026",7,null,null,146830],["TT13","T8/2026",7,null,null,6.583333],["TT14","T9/2026",8,10,24,0.416667],["TT15","T8/2026",7,null,null,260285],["TT15","T9/2026",8,null,null,260295],["TT16","T8/2026",7,5747,260285,0.02208],["TT16","T9/2026",8,6003,260295,0.023062],["TT17","T6/2026",5,null,null,6200000],["NT01","T3/2026",2,null,null,20833],["NT01","T5/2026",4,null,null,39300],["NT01","T8/2026",7,null,null,79463],["NT01","T9/2026",8,null,null,84000],["NT02","T3/2026",2,null,null,0.9],["NT02","T5/2026",4,null,null,0.9],["NT02","T8/2026",7,79463,87409,0.909094],["NT03","T5/2026",4,null,null,161],["NT03","T9/2026",8,null,null,183],["NT04","T8/2026",7,null,null,877672],["NT05","T8/2026",7,null,null,42359],["NT06","T8/2026",7,null,null,10858],["NT07","T8/2026",7,null,null,74.7],["NT08","T6/2026",5,null,null,62],["NT08","T8/2026",7,null,null,84],["NT08","Tuần 41",9,null,null,84],["NT09","T6/2026",5,null,null,6252],["NT09","T8/2026",7,null,null,9269],["NT09","Tuần 41",9,null,null,28000],["NT10","T8/2026",7,134,135,0.992593],["NT11","T6/2026",5,null,null,11392],["NT11","T7/2026",6,null,null,11392],["NT11","T8/2026",7,null,null,11392],["NT12","T4/2026",3,null,null,0.51],["NT12","T8/2026",7,354052,472845,0.74877],["NT13","T2/2026",1,235503,473898,0.496949],["NT14","T2/2026",1,null,null,146371],["NT15","T2/2026",1,null,null,1027],["NT16","T8/2026",7,null,null,0.9597],["CS01","T6/2026",5,96,126,0.761905],["CS01","T8/2026",7,110,126,0.873016],["CS02","T7/2026",6,17,126,0.134921],["CS03","T3/2026",2,null,null,18],["CS03","T4/2026",3,null,null,2],["CS04","T3/2026",2,null,null,7411],["CS04","T5/2026",4,null,null,7388],["CS05","T6/2026",5,null,null,302],["CS05","T8/2026",7,null,null,306],["CS06","T8/2026",7,1502,1662,0.90373],["CS07","T8/2026",7,87,126,0.690476],["CS07","T9/2026",8,95,126,0.753968],["CS08","T8/2026",7,73,126,0.579365],["CS08","T9/2026",8,81,126,0.642857],["CS09","T8/2026",7,56,126,0.444444],["CS09","T9/2026",8,68,126,0.539683],["CS10","T8/2026",7,null,null,14],["CS10","T9/2026",8,null,null,14],["CS11","T8/2026",7,null,null,17],["CS11","T9/2026",8,null,null,17],["CS12","T8/2026",7,null,null,48],["CS12","T9/2026",8,null,null,48],["CS13","T8/2026",7,null,null,10],["CS13","T9/2026",8,null,null,10],["CS14","T8/2026",7,null,null,37],["CS14","T9/2026",8,null,null,37],["CS15","T9/2026",8,null,null,445],["CS16","T9/2026",8,null,null,2520],["CS17","T8/2026",7,126,126,1],["CS18","T8/2026",7,null,null,2770],["KH01","T7/2026",6,null,null,0.167],["KH01","T8/2026",7,null,null,0.167],["KH02","T7/2026",6,null,null,0.097],["KH02","T8/2026",7,null,null,0.097],["KH03","T7/2026",6,null,null,0.07],["KH03","T8/2026",7,null,null,0.07],["KH04","T7/2026",6,10,65,0.153846],["KH05","T9/2026",8,null,null,9],["KH06","T2/2026",1,null,null,93],["KH06","T6/2026",5,null,null,120],["KH06","T8/2026",7,null,null,127],["KH07","T8/2026",7,null,null,11],["KH08","T8/2026",7,null,null,9],["KH09","T8/2026",7,null,null,3060],["KH10","T5/2026",4,null,null,213],["KH10","T8/2026",7,null,null,242],["KH11","T5/2026",4,null,null,224],["KH11","T8/2026",7,null,null,227],["KH12","T5/2026",4,null,null,40],["KH12","T8/2026",7,null,null,44],["KH13","T8/2026",7,null,null,6],["KH14","T7/2026",6,null,null,222],["KH15","T8/2026",7,null,null,182],["AT01","T5/2026",4,null,null,91],["AT01","T6/2026",5,null,null,101],["AT01","T7/2026",6,null,null,238],["AT01","T8/2026",7,null,null,238],["AT01","T9/2026",8,null,null,245],["AT01","Tuần 41",9,null,null,259],["AT02","T5/2026",4,91,245,0.371429],["AT02","T6/2026",5,101,245,0.412245],["AT02","T8/2026",7,238,249,0.955823],["AT03","T9/2026",8,null,null,4],["AT03","Tuần 41",9,null,null,3],["AT04","T7/2026",6,null,null,11],["AT05","T5/2026",4,null,null,10024],["AT05","T8/2026",7,null,null,18206],["AT05","T9/2026",8,null,null,19492],["AT06","T5/2026",4,null,null,158],["AT06","T8/2026",7,null,null,178],["AT06","T9/2026",8,null,null,178],["AT07","T5/2026",4,null,null,15878],["AT08","T8/2026",7,null,null,111],["AT09","T9/2026",8,99,141,0.702128]];
// [stt, nhiệm vụ, cơ quan chủ trì, hạn, mốc kiểm tra, chờ Trung ương]
const QUA_HAN_RAW = [[1,"Giao Đảng ủy UBND Thành phố lãnh đạo, chỉ đạo UBND Thành phố giao các sở, ban, ngành, chính quyền các địa phương xây dựng kế hoạch, lộ trình triển khai theo chức năng, nhiệm vụ và phạm vi dự án; gửi UBND Thành phố để tổng hợp, chỉ đạo triển khai; báo cáo Ban Chỉ đạo 57 Thành ủy trước ngày 15/03/2026","Đảng ủy UBND Thành phố","2026-03-15","01/10/2026",false],[2,"Rà soát, phân loại các đề xuất, kiến nghị của Ban Quản lý các Khu công nghệ cao và Khu công nghiệp thành phố Hà Nội; chủ động xem xét, xử lý theo thẩm quyền. Đối với nội dung vượt thẩm quyền, báo cáo cấp có thẩm quyền xem xét, quyết định. Kết quả rà soát, xử lý được tổng hợp trong Báo cáo tổng thể trình Ban Thường vụ Thành ủy.","UBND Thành phố","2026-08-15","01/10/2026",false],[3,"Tham mưu đồng chí Phó Bí thư Thành ủy chỉ đạo các đồng chí Bí thư Đảng ủy 126 xã, phường tập trung lãnh đạo, chỉ đạo thực hiện làm sạch dữ liệu đất đai. Kết quả thực hiện đến ngày 30/8/2026 được đối chiếu với KPI đã được thông báo đến từng xã, phường và sử dụng làm căn cứ đánh giá kết quả thực hiện nhiệm vụ, trách nhiệm người đứng đầu trong quý III/2026.","Văn phòng Thành ủy","2026-08-30","02/10/2026",false],[4,"Các sở, ngành lựa chọn, đăng ký từ 01-02 sản phẩm cụ thể gắn với phát triển kinh tế số của ngành, lĩnh vực; hoàn thành đăng ký trong đầu tháng 9/2026 để làm cơ sở kiểm đếm, đánh giá kết quả thực hiện vào cuối năm.","Sở, ngành Thành phố","2026-09-15","",false],[5,"Phê duyệt hồ sơ đề xuất cấp độ an toàn hệ thống thông tin đối với các hệ thống trước khi đưa vào vận hành, khai thác; tổ chức kiểm tra, đánh giá an ninh mạng định kỳ.","Các sở, ban, ngành Thành phố và UBND xã, phường","2026-08-15","01/10/2026",false],[6,"Các sở, ban, ngành rà soát, chuẩn hóa, hoàn thiện các cơ sở dữ liệu chuyên ngành thuộc phạm vi quản lý, bảo đảm dữ liệu đúng, đủ, sạch, sống, thống nhất, dùng chung, kết nối và chia sẻ được; hoàn thành trước ngày 30/8/2026. Sở Khoa học và Công nghệ chủ trì hướng dẫn tiêu chuẩn kỹ thuật, kiến trúc dữ liệu, kết nối, chia sẻ dữ liệu; bảo đảm đồng bộ, thống nhất trong xây dựng, chia sẻ, tích hợp dữ liệu của các cơ quan, đơn vị.","Các sở, ban, ngành Thành phố","2026-08-30","02/10/2026",false],[7,"Phân công đồng chí Trương Việt Dũng, Thành ủy viên, Phó Chủ tịch UBND Thành phố trực tiếp chỉ đạo Ban Quản lý các Khu công nghệ cao và Khu công nghiệp thành phố Hà Nội chủ trì, phối hợp với các cơ quan, đơn vị liên quan xây dựng Báo cáo tổng thể về định hướng, nhiệm vụ và giải pháp phát triển Khu công nghệ cao Hòa Lạc trong giai đoạn mới; báo cáo Ban Thường vụ Thành ủy. Báo cáo tập trung làm rõ: Kết quả thực hiện các kết luận, chỉ đạo liên quan; tồn tại, hạn chế, nguyên nhân, trách nhiệm và những nội dung cần thay đổi trong phương thức tổ chức thực hiện. Vị trí, vai trò, mục tiêu, định hướng và mô hình phát triển Khu công nghệ cao Hòa Lạc trong tổng thể phát triển khu vực phía Tây Thành phố. Việc rà soát quy hoạch Khu công nghệ cao Hòa Lạc với quy mô hiện có 1.586 ha và phạm vi mở rộng 460 ha, tổng quy mô 2.046 ha; việc kết nối với Đại học Quốc gia Hà Nội, các trường đại học, viện nghiên cứu, hệ thống giao thông, các khu đô thị, đô thị thông minh và không gian phát triển xung quanh. Lợi thế cạnh tranh thực chất của Khu Công nghệ cao Hòa Lạc so với các điểm đến đầu tư cạnh tranh trong khu vực; giải pháp thu hút nhà đầu tư có chất lượng, nhất là nhà đầu tư lớn, doanh nghiệp dẫn dắt có khả năng kéo hệ sinh thái, doanh nghiệp vệ tinh, chuỗi cung ứng, nhân lực chất lượng cao, trung tâm nghiên cứu và phát triển vào Hòa Lạc; đề xuất chính sách đặc biệt đủ sức cạnh tranh, gắn với ràng buộc cụ thể về vốn, công nghệ, tiến độ, hiệu quả sử dụng đất và mức độ đóng góp cho hệ sinh thái. Kết quả rà soát các dự án đã được chấp thuận và các dự án đang nghiên cứu, chuẩn bị đầu tư; năng lực nhà đầu tư, tiến độ thực hiện, hiệu quả sử dụng đất, mức độ đáp ứng tiêu chí công nghệ cao và phương án xử lý theo quy định đối với các dự án không triển khai, chậm triển khai, sử dụng đất kém hiệu quả hoặc không còn đáp ứng tiêu chí. Kết quả rà soát các cơ chế, chính sách, quy định và thủ tục hành chính liên quan đến hoạt động của Khu công nghệ cao Hòa Lạc; mô hình quản lý, vận hành, khai thác và phương án tổ chức bộ máy phù hợp, bảo đảm hoạt động hiệu lực, hiệu quả.","Ban Quản lý các Khu công nghệ cao và Khu công nghiệp thành phố Hà Nội","2026-08-15","02/10/2026",false],[8,"Chủ trì, phối hợp với các cơ quan liên quan xây dựng phương án cung cấp thiết bị công nghệ thông tin cho các cơ quan trong hệ thống chính trị Thành phố (Thành ủy, HĐND, UBND Thành phố, Ủy ban MTTQ Việt Nam Thành phố và các sở, ban, ngành), bảo đảm đồng bộ, hiệu quả, tránh chồng chéo, dàn trải, lãng phí; hoàn thành trước ngày 20/3/2026.","Sở Khoa học và Công nghệ","2026-03-20","02/10/2026",false],[9,"Đồng chí Nguyễn Xuân Lưu, Ủy viên Ban Thường vụ Thành ủy, Phó Chủ tịch UBND Thành phố, Tổ phó Tổ công tác của Ban Thường vụ Thành ủy về sắp xếp các đơn vị sự nghiệp công lập, doanh nghiệp nhà nước trên địa bàn Thành phố trực tiếp chỉ đạo Công ty Cổ phần Hanel, Công ty TNHH một thành viên Chiếu sáng và Thiết bị đô thị, Công ty TNHH một thành viên Thoát nước Hà Nội và Công ty Cổ phần Giống gia súc Hà Nội hoàn thiện đề án phát triển doanh nghiệp trên cơ sở Nghị quyết 57 của Bộ Chính trị. Các đề án phải đánh giá đúng thực chất năng lực hiện có; xác định rõ định hướng phát triển, lộ trình thực hiện, tổ chức bộ máy, nhân lực và các kiến nghị, đề xuất với Thành phố; hoàn thành trước ngày 15/8/2026. Giao Sở Khoa học và Công nghệ chủ trì, phối hợp với các sở, ngành liên quan thẩm định, tham mưu UBND Thành phố báo cáo Ban Chỉ đạo 57 Thành ủy trước ngày 30/8/2026.","Sở Khoa học và Công nghệ","2026-08-30","02/10/2026",false],[10,"Chỉ đạo Sở Nông nghiệp và Môi trường chủ trì, phối hợp Công an Thành phố và các cơ quan liên quan triển khai Kế hoạch cao điểm hoàn thiện dữ liệu đất đai; phân rã tiến độ theo tuần, theo địa bàn, theo nhóm dữ liệu; hoàn thành trước ngày 30/6/2026.","Sở Nông nghiệp và Môi trường","2026-06-30","02/10/2026",false],[11,"Khẩn trương rà soát khối lượng, hiện trạng, chỉ tiêu đã giao và tiến độ thực hiện của 126 xã, phường; đề xuất KPI phải hoàn thành đến ngày 30/8/2026 đối với từng đơn vị; lập bảng tổng hợp, nêu rõ tỷ lệ hoàn thành, KPI đề xuất và các đơn vị chưa quan tâm, thiếu quyết liệt hoặc có kết quả thấp, gửi Văn phòng Thành ủy trước ngày 21/8/2026","Sở Nông nghiệp và Môi trường","2026-08-21","02/10/2026",false],[12,"Phối hợp với Sở Khoa học và Công nghệ, Công an Thành phố và các cơ quan liên quan rà soát phương án bảo đảm an toàn, an ninh thông tin, định danh người sử dụng; kết nối cơ sở dữ liệu đất đai với nền tảng iHanoi để người dân kiểm tra, xác nhận và tham gia làm sạch dữ liệu, hoàn thành trước ngày 15/9/2026.","Sở Nông nghiệp và Môi trường","2026-09-15","02/10/2026",false],[13,"Rà soát, hoàn thiện phương án phân bổ, giao dự toán đối với kinh phí năm 2026 đã được bố trí nhưng chưa phân bổ, chưa giao dự toán; ưu tiên cơ sở dữ liệu, nền tảng dùng chung, an ninh mạng, thiết bị thiết yếu và nhiệm vụ cấp bách.","Sở Tài chính","2026-08-15","",false],[14,"Phối hợp Sở Khoa học và Công nghệ hoàn thành cập nhật các lớp dữ liệu hiện có của ngành phục vụ việc rà soát, cụ thể hóa Quy hoạch tổng thể Thủ đô Hà Nội tầm nhìn 100 năm, hoàn thành trước ngày 25/8/2026. (Y tế)","Sở Y tế","2026-08-24","",false],[15,"Nhiệm vụ do Trung ương giao theo thông báo ngày 04/7/2025 (chờ Ban Chỉ đạo Trung ương ban hành Sổ tay hướng dẫn)","—","","",true]];
const NGUON_GIAO = [{"ky":"T8/2026","nguon_giao":"Nhiệm vụ Trung ương giao","tong":296,"hoan_thanh":189,"dang_thuc_hien":107,"qua_han":1,"can_xu_ly":0,"han_trong_thang":0,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T8/2026","nguon_giao":"Kế hoạch 20-KH/BCĐ57","tong":125,"hoan_thanh":56,"dang_thuc_hien":69,"qua_han":5,"can_xu_ly":5,"han_trong_thang":0,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T8/2026","nguon_giao":"Kế hoạch 35-KH/BCĐ57","tong":26,"hoan_thanh":3,"dang_thuc_hien":23,"qua_han":4,"can_xu_ly":4,"han_trong_thang":2,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T8/2026","nguon_giao":"Thông báo kết luận","tong":346,"hoan_thanh":153,"dang_thuc_hien":193,"qua_han":11,"can_xu_ly":11,"han_trong_thang":7,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T8/2026","nguon_giao":"Công văn truyền đạt ý kiến","tong":44,"hoan_thanh":20,"dang_thuc_hien":24,"qua_han":3,"can_xu_ly":3,"han_trong_thang":11,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T8/2026","nguon_giao":"Nhiệm vụ trọng tâm, cấp bách","tong":9,"hoan_thanh":3,"dang_thuc_hien":6,"qua_han":0,"can_xu_ly":0,"han_trong_thang":0,"nguon":"BC tháng 8, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Nhiệm vụ Trung ương giao","tong":296,"hoan_thanh":190,"dang_thuc_hien":106,"qua_han":1,"can_xu_ly":0,"han_trong_thang":1,"nguon":"BC tháng 9, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Kế hoạch 20-KH/BCĐ57","tong":126,"hoan_thanh":58,"dang_thuc_hien":68,"qua_han":0,"can_xu_ly":0,"han_trong_thang":8,"nguon":"BC tháng 9, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Kế hoạch 35-KH/BCĐ57","tong":26,"hoan_thanh":8,"dang_thuc_hien":18,"qua_han":2,"can_xu_ly":2,"han_trong_thang":0,"nguon":"BC tháng 9, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Thông báo kết luận","tong":366,"hoan_thanh":166,"dang_thuc_hien":200,"qua_han":12,"can_xu_ly":12,"han_trong_thang":3,"nguon":"BC tháng 9, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Công văn truyền đạt ý kiến","tong":44,"hoan_thanh":36,"dang_thuc_hien":8,"qua_han":0,"can_xu_ly":0,"han_trong_thang":0,"nguon":"BC tháng 9, Phụ lục 01"},{"ky":"T9/2026","nguon_giao":"Nhiệm vụ trọng tâm, cấp bách","tong":9,"hoan_thanh":3,"dang_thuc_hien":6,"qua_han":0,"can_xu_ly":0,"han_trong_thang":0,"nguon":"BC tháng 9, Phụ lục 01"}];
const XA_QUAN_TAM = [{"xa":"Kiều Phú","tong_nhiem_vu":242,"hoan_thanh":97,"dang_qua_han":0,"xong_qua_han":25},{"xa":"Từ Liêm","tong_nhiem_vu":279,"hoan_thanh":176,"dang_qua_han":0,"xong_qua_han":24},{"xa":"Ngọc Hồi","tong_nhiem_vu":247,"hoan_thanh":124,"dang_qua_han":0,"xong_qua_han":17},{"xa":"Phú Xuyên","tong_nhiem_vu":48,"hoan_thanh":40,"dang_qua_han":4,"xong_qua_han":0},{"xa":"Dân Hòa","tong_nhiem_vu":260,"hoan_thanh":161,"dang_qua_han":0,"xong_qua_han":3},{"xa":"Xuân Đỉnh","tong_nhiem_vu":64,"hoan_thanh":32,"dang_qua_han":0,"xong_qua_han":2},{"xa":"Hà Đông","tong_nhiem_vu":100,"hoan_thanh":96,"dang_qua_han":1,"xong_qua_han":0},{"xa":"Phú Lương","tong_nhiem_vu":162,"hoan_thanh":109,"dang_qua_han":1,"xong_qua_han":0},{"xa":"Sơn Tây","tong_nhiem_vu":92,"hoan_thanh":80,"dang_qua_han":0,"xong_qua_han":1},{"xa":"Yên Bài","tong_nhiem_vu":241,"hoan_thanh":219,"dang_qua_han":0,"xong_qua_han":1}];
const DIEM_NGHEN_XA = [{"nhom":"Nền tảng, phần mềm, liên thông","so_xa_phan_anh":105,"can_xu_ly_som":44},{"nhom":"Dữ liệu, chuẩn hóa, chia sẻ","so_xa_phan_anh":79,"can_xu_ly_som":39},{"nhom":"Hạ tầng, thiết bị, đường truyền","so_xa_phan_anh":66,"can_xu_ly_som":29},{"nhom":"Nhân lực, kỹ năng số","so_xa_phan_anh":59,"can_xu_ly_som":14},{"nhom":"ATTT, chữ ký số, cơ yếu","so_xa_phan_anh":34,"can_xu_ly_som":31},{"nhom":"Cơ chế, hướng dẫn, phân quyền","so_xa_phan_anh":28,"can_xu_ly_som":8},{"nhom":"Kinh phí, mua sắm","so_xa_phan_anh":18,"can_xu_ly_som":4},{"nhom":"Khác, không nêu rõ","so_xa_phan_anh":13,"can_xu_ly_som":2},{"nhom":"DVC, TTHC, đảng phí","so_xa_phan_anh":10,"can_xu_ly_som":5},{"nhom":"Người dân, doanh nghiệp tiếp cận số","so_xa_phan_anh":8,"can_xu_ly_som":4}];
const NOI_DUNG_XA = [{"nhom":"Mô hình, sáng kiến nhân rộng","ky":"T8/2026","so_xa":87},{"nhom":"Mô hình, sáng kiến nhân rộng","ky":"T9/2026","so_xa":95},{"nhom":"Dữ liệu số","ky":"T8/2026","so_xa":73},{"nhom":"Dữ liệu số","ky":"T9/2026","so_xa":81},{"nhom":"DVC, TTHC","ky":"T8/2026","so_xa":56},{"nhom":"DVC, TTHC","ky":"T9/2026","so_xa":68},{"nhom":"Quản trị số, HanoiWork, IOC","ky":"T8/2026","so_xa":49},{"nhom":"Quản trị số, HanoiWork, IOC","ky":"T9/2026","so_xa":68},{"nhom":"Xã hội số, kỹ năng số","ky":"T8/2026","so_xa":46},{"nhom":"Xã hội số, kỹ năng số","ky":"T9/2026","so_xa":58},{"nhom":"Kinh tế số, TMĐT, thanh toán","ky":"T8/2026","so_xa":29},{"nhom":"Kinh tế số, TMĐT, thanh toán","ky":"T9/2026","so_xa":41},{"nhom":"Ứng dụng AI","ky":"T8/2026","so_xa":22},{"nhom":"Ứng dụng AI","ky":"T9/2026","so_xa":33},{"nhom":"An toàn thông tin","ky":"T8/2026","so_xa":20},{"nhom":"An toàn thông tin","ky":"T9/2026","so_xa":28},{"nhom":"Hạ tầng số","ky":"T8/2026","so_xa":7},{"nhom":"Hạ tầng số","ky":"T9/2026","so_xa":11}];


/* ---------- Chuẩn hóa dữ liệu ---------- */
const CHI_SO = CHI_SO_RAW.map(([ma, cd, ten, donVi, loai, luuY, bs, dauMoi, phuLucGoc, cachTinh]) => ({
  ma, chuyenDe: CHUYEN_DE[cd], ten, donVi, loai, luuY, canBoSung: !!bs, dauMoi, phuLucGoc, cachTinh,
}));
const CHUOI = CHUOI_RAW.map(([ma, ky, thuTu, tu, mau, v]) => ({ ma, ky, thuTu, tu, mau, v }));
const QUA_HAN = QUA_HAN_RAW.map(([stt, ten, coQuan, han, moc, choTW]) => ({ stt, ten, coQuan, han, moc, choTW }));
const NGAY_CHOT_QUA_HAN = "2026-09-25";
const KY_MOI = 8; // từ T9/2026 trở đi coi là số liệu mới
const GIAM_LA_TOT = new Set(["NV05", "NV06", "NV11", "NV14", "TC10", "TC11", "TC12", "DD08", "DD09", "CS03", "CS13", "CS14", "AT03", "AT04", "AT07", "AT08", "TT13"]);
const NGUONG = { TC06: { v: 0.3, ten: "Ngưỡng 30%" }, TT06: { v: 0.95, ten: "Mục tiêu 95%" } };
// Bảng màu tiết chế: một tông xanh chủ đạo; đỏ, vàng, xanh lá chỉ dùng để báo trạng thái
const P = { navy: "#101828", xanh: "#1D6FE8", sang: "#7FB1F6", nhat: "#EEF4FF", ink2: "#344054", mo: "#475467", vien: "#D9DEE7", c1: "#163C8E" };
const MAU = ["#1D6FE8", "#7A5AF8", "#0E9384", "#F79009", "#E31B54"];
const C = { tot: "#12B76A", xau: "#F04438", trung: "#98A2B3", muted: "#D0D5DD", warn: "#F79009", ink: "#101828", grid: "#E4E7EC", track: "#DDE2EA" };
const NEN = { tot: "#ECFDF3", xau: "#FEF1F0", trung: "#E4E7EC", warn: "#FFF6E8" };
const THUONG_HIEU = "#1D6FE8";

/* ---------- Định dạng ---------- */
const so = (v, d = 0) => new Intl.NumberFormat("vi-VN", { maximumFractionDigits: d }).format(v);
const soTuDong = (v) => so(v, Number.isInteger(v) ? 0 : Math.abs(v) >= 100 ? 1 : 2);
const gon = (v) => (Math.abs(v) >= 10000 ? new Intl.NumberFormat("vi-VN", { notation: "compact", maximumFractionDigits: 1 }).format(v) : soTuDong(v));
const kieuCua = (cs, r) => (cs.donVi === "%" ? "pct" : r.tu != null && r.mau != null ? "frac" : "num");
const hienThi = (k, r) => (k === "pct" ? so(r.v * 100, 1) + "%" : k === "frac" ? soTuDong(r.tu) + "/" + soTuDong(r.mau) : soTuDong(r.v));
const ngayVN = (iso) => (iso ? iso.split("-").reverse().join("/") : "");

function tinhMoiNhat() {
  const out = {};
  CHI_SO.forEach((c) => {
    const s = CHUOI.filter((r) => r.ma === c.ma).sort((a, b) => a.thuTu - b.thuTu);
    if (!s.length) return;
    const r = s[s.length - 1], p = s[s.length - 2], k = kieuCua(c, r);
    let thayDoi = "Chưa có kỳ trước", ngan = "Chưa có kỳ trước", xuHuong = "trung";
    if (p && kieuCua(c, p) === k) {
      const d = k === "pct" ? Math.round((r.v - p.v) * 1000) / 10 : k === "frac" ? r.tu - p.tu : r.v - p.v;
      const t = (d > 0 ? "+" : "−") + (k === "pct" ? so(Math.abs(d), 1) + " điểm %" : soTuDong(Math.abs(d)));
      thayDoi = d === 0 ? `Không đổi so với ${p.ky}` : `${t} so với ${p.ky}`;
      ngan = d === 0 ? "Không đổi" : t;
      const tot = GIAM_LA_TOT.has(c.ma) ? d < 0 : d > 0;
      xuHuong = d === 0 || c.loai === "Đầu vào" ? "trung" : tot ? "tot" : "xau";
    }
    out[c.ma] = { ...r, kieu: k, hienThi: hienThi(k, r), thayDoi, ngan, xuHuong, soKy: s.length, chuoi: s };
  });
  return out;
}

/* ---------- Biểu tượng (nét vẽ theo bộ Lucide, giấy phép ISC) ---------- */
const ICON = {
  "tong-quan": <><rect x="3" y="3" width="7" height="9" rx="1" /><rect x="14" y="3" width="7" height="5" rx="1" /><rect x="14" y="12" width="7" height="9" rx="1" /><rect x="3" y="16" width="7" height="5" rx="1" /></>,
  "nhiem-vu": <><rect x="8" y="2" width="8" height="4" rx="1" /><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" /><path d="m9 14 2 2 4-4" /></>,
  "tai-chinh": <><path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1" /><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4" /></>,
  "dat-dai": <><path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z" /><path d="M15 5.764v15" /><path d="M9 3.236v15" /></>,
  "du-lieu": <><ellipse cx="12" cy="5" rx="9" ry="3" /><path d="M3 5V19A9 3 0 0 0 21 19V5" /><path d="M3 12A9 3 0 0 0 21 12" /></>,
  "tthc": <><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /><path d="M14 2v4a2 2 0 0 0 2 2h4" /><path d="M16 13H8" /><path d="M16 17H8" /><path d="M10 9H8" /></>,
  "nen-tang": <><path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z" /><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65" /><path d="m22 12.65-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65" /></>,
  "xa-phuong": <><path d="M3 22h18" /><path d="M6 18v-7" /><path d="M10 18v-7" /><path d="M14 18v-7" /><path d="M18 18v-7" /><path d="M12 2 20 7H4z" /></>,
  "khcn": <><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5" /><path d="M9 18h6" /><path d="M10 22h4" /></>,
  "attt": <><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" /><path d="m9 12 2 2 4-4" /></>,
  "danh-muc": <><path d="M3 5h.01" /><path d="M3 12h.01" /><path d="M3 19h.01" /><path d="M8 5h13" /><path d="M8 12h13" /><path d="M8 19h13" /></>,
  "canh-bao": <><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" /></>,
};
function Icon({ name, size = 22, color = "currentColor" }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{ICON[name]}</svg>;
}
/* Biểu tượng kiểu ứng dụng: ô bo góc màu đặc, biểu tượng trắng */
const HUE = {
  "tong-quan": "#1D5FD6", "nhiem-vu": "#1D5FD6", "tai-chinh": "#0E8F80", "dat-dai": "#E8590C", "du-lieu": "#6D4AE0", "tthc": "#0369A1",
  "nen-tang": "#4338CA", "xa-phuong": "#BE185D", "khcn": "#D97706", "attt": "#C0183F", "danh-muc": "#475467", "canh-bao": "#E8590C",
};
function AppIcon({ name, size = 32 }) {
  return (
    <span className="flex shrink-0 items-center justify-center" style={{ width: size, height: size, borderRadius: size * 0.27, background: HUE[name] || HUE["nhiem-vu"] }}>
      <Icon name={name} size={Math.round(size * 0.55)} color="#fff" />
    </span>
  );
}

const tint = (hex, a) => hex + Math.round(a * 255).toString(16).padStart(2, "0");

/* ---------- Cấu hình trang ---------- */
const TRANG = [
  { id: "tong-quan", ten: "Tổng quan", mau: "#1D6FE8" },
  { id: "nhiem-vu", ten: "Nhiệm vụ", cd: 0, mau: "#1D6FE8", kpi: ["NV01", "NV03", "NV05", "NV06"],
    bieuDo: [{ dang: "line", ma: ["NV03"], kieu: "pct", ten: "Tỷ lệ nhiệm vụ hoàn thành" }, { dang: "cot", ma: ["NV05", "NV06"], ten: "Nhiệm vụ quá hạn qua các kỳ" }] },
  { id: "tai-chinh", ten: "Tài chính", cd: 1, mau: "#1D6FE8", cot: 2, kpi: ["TC03", "TC06", "TC07", "TC08"],
    bieuDo: [{ dang: "line", ma: ["TC06", "TC07", "TC08", "TC09"], kieu: "pct", ten: "Tỷ lệ giải ngân qua các kỳ", nguong: "TC06", rong: true },
             { dang: "gauge", ma: "TC03", ten: "Phân bổ dự toán" }, { dang: "cot", ma: ["TC12"], ten: "Kinh phí chưa phân bổ (tỷ đồng)" }] },
  { id: "dat-dai", ten: "Đất đai", cd: 2, mau: "#1D6FE8", cot: 2, kpi: ["DD01", "DD03", "DD05", "DD08"],
    bieuDo: [{ dang: "cot", ma: ["DD01", "DD02", "DD04"], ten: "Tiến độ cơ sở dữ liệu đất đai (thửa)", rong: true }, { dang: "donut-dd", ten: "Cơ cấu thửa đất kỳ gần nhất" }, { dang: "gauge", ma: "DD05", ten: "Thửa đạt Nhóm 1" }] },
  { id: "du-lieu", ten: "Dữ liệu dùng chung", cd: 3, mau: "#1D6FE8", cot: 2, kpi: ["DL01", "DL07", "DL06", "DL05"],
    bieuDo: [{ dang: "line", ma: ["DL01"], kieu: "pct", ten: "Nguồn dữ liệu ưu tiên đã kết nối", rong: true }, { dang: "gauge", ma: "DL07", ten: "Dữ liệu khai thác phục vụ TTHC" }, { dang: "gauge", ma: "DL05", ten: "Nhiệm vụ triển khai Kho dữ liệu" }] },
  { id: "tthc", ten: "TTHC, dịch vụ công", cd: 4, mau: "#1D6FE8", cot: 2, kpi: ["TT06", "TT03", "TT07", "TT16"],
    bieuDo: [{ dang: "gauge", ma: "TT06", ten: "Tái cấu trúc TTHC", muc: 0.95 }, { dang: "gauge", ma: "TT14", ten: "TTHC trọng điểm trên hệ thống TP" },
             { dang: "line", ma: ["TT03", "TT06"], kieu: "pct", ten: "Toàn trình và tái cấu trúc qua các kỳ", nguong: "TT06", rong: true }] },
  { id: "nen-tang", ten: "Nền tảng số", cd: 5, mau: "#1D6FE8", cot: 2, kpi: ["NT01", "NT09", "NT12", "NT07"],
    bieuDo: [{ dang: "cot", ma: ["NT01", "NT09", "NT11"], ten: "Tài khoản trên các nền tảng dùng chung", rong: true }, { dang: "gauge", ma: "NT02", ten: "HanoiWork: tài khoản kích hoạt" }, { dang: "gauge", ma: "NT12", ten: "Đảng viên dùng Sổ tay điện tử" }] },
  { id: "xa-phuong", ten: "Xã, phường", cd: 6, mau: "#1D6FE8", kpi: ["CS01", "CS07", "CS08", "CS09"], bieuDo: [] },
  { id: "khcn", ten: "KHCN, kinh tế số", cd: 7, mau: "#1D6FE8", cot: 2, kpi: ["KH01", "KH05", "KH07", "KH13"],
    bieuDo: [{ dang: "line", ma: ["KH01", "KH02", "KH03"], kieu: "pct", ten: "Kinh tế số trong GRDP" }, { dang: "cot", ma: ["KH10", "KH11", "KH12"], ten: "Sàn giao dịch công nghệ HanoTEX" },
             { dang: "gauge", ma: "KH04", ten: "Nhiệm vụ phát triển kinh tế số hoàn thành" }, { dang: "gauge", ma: "KH01", ten: "Tỷ trọng kinh tế số / GRDP" }] },
  { id: "attt", ten: "An toàn thông tin", cd: 8, mau: "#1D6FE8", cot: 2, kpi: ["AT01", "AT02", "AT03", "AT09"],
    bieuDo: [{ dang: "cot", ma: ["AT01"], ten: "Hệ thống được phê duyệt cấp độ" }, { dang: "line", ma: ["AT05"], kieu: "num", ten: "Máy tính được SOC giám sát" },
             { dang: "gauge", ma: "AT02", ten: "Hệ thống đã phê duyệt cấp độ", muc: 1 }, { dang: "gauge", ma: "AT09", ten: "Đơn vị gửi báo cáo ATTT", muc: 1 }] },
  { id: "danh-muc", ten: "Danh mục chỉ số", mau: "#1D6FE8" },
];
const TONG_QUAN = [["nhiem-vu", "NV03"], ["tai-chinh", "TC08"], ["dat-dai", "DD05"], ["du-lieu", "DL01"], ["tthc", "TT06"], ["nen-tang", "NT01"], ["xa-phuong", "CS01"], ["khcn", "KH01"], ["attt", "AT01"]];
const CAN_CHU_Y = [
  { ma: "NV06", trang: "nhiem-vu" },
  { ma: "TC06", trang: "tai-chinh" },
  { ma: "DL07", trang: "du-lieu" },
  { ma: "TT06", trang: "tthc" },
  { ma: "AT09", trang: "attt" },
];


/* ---------- Khung 16:9 ---------- */
const W0 = 1920, H0 = 1080;
// Phông Apple (SF Pro) trên máy Apple; máy khác tự dùng Segoe UI / Roboto / Arial
const FONT_APPLE = '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", "Segoe UI", Roboto, Arial, sans-serif';
const ACC = P.xanh;

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
const mauXuHuong = (x) => (x === "tot" ? C.tot : x === "xau" ? C.xau : C.trung);
/* Tên rút gọn để hiển thị trên thẻ, chú giải; tên đầy đủ vẫn dùng trong bảng chỉ số. TX = thường xuyên, VB = văn bản */
const TEN_NGAN = {"NV01": "Tổng nhiệm vụ theo dõi", "NV03": "Tỷ lệ nhiệm vụ hoàn thành", "NV05": "Nhiệm vụ quá hạn giao", "NV06": "Quá hạn cần xử lý", "TC03": "Tỷ lệ phân bổ dự toán", "TC06": "Giải ngân chi TX khối TP", "TC07": "Giải ngân chi TX khối xã", "TC08": "Giải ngân chi đầu tư", "TC09": "Giải ngân/tổng nguồn theo dõi", "TC12": "Kinh phí chưa phân bổ", "DD01": "Tổng số thửa đất", "DD02": "Thửa đã có trong CSDL", "DD03": "Tỷ lệ thửa có trong CSDL", "DD04": "Thửa đạt Nhóm 1", "DD05": "Tỷ lệ thửa đạt Nhóm 1", "DD08": "Thửa cần làm sạch", "DL01": "Nguồn dữ liệu đã kết nối", "DL05": "Nhiệm vụ Kho dữ liệu xong", "DL06": "Kịch bản khai thác dữ liệu", "DL07": "Dữ liệu khai thác cho TTHC", "TT03": "TTHC trực tuyến toàn trình", "TT06": "TTHC đã tái cấu trúc", "TT07": "Chi phí tuân thủ giảm", "TT14": "TTHC trọng điểm trên hệ thống TP", "TT16": "Doanh nghiệp đã xác thực", "NT01": "HanoiWork: tài khoản kích hoạt", "NT02": "HanoiWork: tỷ lệ kích hoạt", "NT07": "Điểm chất lượng trợ lý AI", "NT09": "IOC: tài khoản đã cấp", "NT11": "Tài khoản theo dõi nhiệm vụ", "NT12": "Đảng viên dùng Sổ tay điện tử", "CS01": "Xã, phường VB toàn trình ≥90%", "CS07": "Xã có mô hình nhân rộng", "CS08": "Xã có kết quả dữ liệu số", "CS09": "Xã có kết quả dịch vụ công", "KH01": "Kinh tế số / GRDP", "KH02": "Kinh tế số lõi", "KH03": "Kinh tế số ngành", "KH04": "Nhiệm vụ kinh tế số xong", "KH05": "Sở, ngành đăng ký sản phẩm", "KH07": "Nhiệm vụ đặt hàng đã duyệt", "KH10": "HanoTEX: tài khoản", "KH11": "HanoTEX: doanh nghiệp", "KH12": "HanoTEX: giải pháp", "KH13": "HanoTEX: hợp đồng ký", "AT01": "Hệ thống đã duyệt cấp độ", "AT02": "Tỷ lệ hệ thống đã duyệt", "AT03": "Hồ sơ cấp độ đang thẩm định", "AT05": "Máy tính được SOC giám sát", "AT09": "Đơn vị gửi báo cáo ATTT"};
const tenCS = (ma) => TEN_NGAN[ma] || CHI_SO.find((c) => c.ma === ma)?.ten || ma;
const donVi = (ma) => { const d = CHI_SO.find((c) => c.ma === ma)?.donVi; return d && d !== "%" ? d : ""; };
const tyLe = (m) => (m && (m.kieu === "pct" || m.kieu === "frac") ? m.v : null);

/* Thay đổi so với kỳ trước: chữ màu, không nền */
function Delta({ m }) {
  if (!m) return null;
  return <span className="inline-flex items-center gap-1 whitespace-nowrap text-[13px] font-semibold" style={{ color: m.xuHuong === "trung" ? P.mo : mauXuHuong(m.xuHuong) }}>{m.ngan.startsWith("+") ? "▲" : m.ngan.startsWith("−") ? "▼" : ""} {m.ngan}</span>;
}

function Spark({ chuoi, w = 110, h = 30, color = ACC }) {
  if (!chuoi || chuoi.length < 2) return null;
  const xs = chuoi.map((p) => p.thuTu), vs = chuoi.map((p) => p.v);
  const x0 = Math.min(...xs), x1 = Math.max(...xs), lo = Math.min(0, ...vs), hi = Math.max(...vs) || 1;
  const X = (t) => 3 + ((t - x0) / (x1 - x0 || 1)) * (w - 6), Y = (v) => h - 3 - ((v - lo) / (hi - lo || 1)) * (h - 6);
  const d = chuoi.map((p, i) => `${i ? "L" : "M"}${X(p.thuTu).toFixed(1)},${Y(p.v).toFixed(1)}`).join("");
  const l = chuoi[chuoi.length - 1];
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} aria-hidden="true" className="block">
            <path d={`${d}L${X(l.thuTu).toFixed(1)},${h}L${X(chuoi[0].thuTu).toFixed(1)},${h}Z`} fill={color} opacity=".12" />
      <path d={d} fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={X(l.thuTu)} cy={Y(l.v)} r="2.8" fill={color} />
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

/* Thẻ KPI: nổi bật, số lớn đậm, vạch màu theo xu hướng, biểu tượng trong khung nhạt */
function Kpi({ ma, mn, nhan, icon, onClick }) {
  const m = mn[ma];
  const p = tyLe(m), dv = donVi(ma);
  const Tag = onClick ? "button" : "div";
  const vach = m && m.xuHuong === "tot" ? C.tot : m && m.xuHuong === "xau" ? C.xau : ACC;
  const nenDelta = m ? (m.xuHuong === "tot" ? NEN.tot : m.xuHuong === "xau" ? NEN.xau : NEN.trung) : NEN.trung;
  return (
    <Tag onClick={onClick} className={`flex h-full flex-col justify-between rounded-2xl px-5 py-4 text-left ${onClick ? "transition-shadow hover:shadow-xl focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8]" : ""}`}
      style={{ background: "#FFFFFF", border: `1px solid ${P.vien}`, borderTop: `4px solid ${vach}`, boxShadow: "0 8px 22px -12px rgba(15,42,92,.28), 0 1px 2px rgba(15,42,92,.05)" }}>
      <p className="flex items-center gap-2.5 font-semibold text-[#344054]" style={{ fontSize: 15 }}>
        <AppIcon name={icon} size={32} />
        <span className="min-w-0 truncate" title={tenCS(ma)}>{nhan || tenCS(ma)}</span>
      </p>
      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <p className="flex items-baseline gap-1.5 whitespace-nowrap">
            <span className="tabular-nums" style={{ color: P.navy, fontFamily: FONT_APPLE, fontSize: 46, fontWeight: 700, lineHeight: 1, letterSpacing: "-0.03em" }}>{m ? m.hienThi : "—"}</span>
            {dv && <span className="text-sm font-medium text-[#475467]">{dv}</span>}
          </p>
          <p className="mt-2.5 flex items-center gap-2 text-sm text-[#475467]">
            {m && <span className="rounded-md px-2 py-0.5" style={{ background: nenDelta }}><Delta m={m} /></span>}
            <span className="truncate">{m?.ky}</span>
          </p>
        </div>
        {p != null ? <Ring v={p} size={72} stroke={8} /> : <Spark chuoi={m?.chuoi} w={110} h={48} />}
      </div>
    </Tag>
  );
}

/* ---------- Biểu đồ ---------- */
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

function LineChart({ maList, kieu, mn, nguong }) {
  const [ref, { w: W, h: H }] = useSize();
  const [hover, setHover] = useState(null);
  const top = 14, bottom = 28, fs = 14, cw = 7.8;
  const series = maList.map((ma, i) => ({ ma, ten: tenCS(ma), color: MAU[i % MAU.length], pts: mn[ma]?.chuoi || [] })).filter((s) => s.pts.length);
  const kys = [...new Map(series.flatMap((s) => s.pts).sort((a, b) => a.thuTu - b.thuTu).map((p) => [p.ky, p.thuTu])).keys()];
  const ref0 = nguong ? NGUONG[nguong] : null;
  const ticks = niceTicks(Math.max(...series.flatMap((s) => s.pts.map((p) => p.v)), ref0 ? ref0.v : 0));
  const fmtTick = kieu === "pct" ? (v) => so(v * 100, 0) + "%" : gon;
  const fmtPt = (p) => (kieu === "pct" ? so(p.v * 100, 1) + "%" : p.tu != null && p.mau != null ? soTuDong(p.tu) + "/" + soTuDong(p.mau) : gon(p.v));
  const ml = Math.max(...ticks.map((t) => fmtTick(t).length)) * 8 + 22;
  const ends = series.map((s) => fmtPt(s.pts[s.pts.length - 1]));
  const mr = Math.max(0, ...ends.map((e) => e.length)) * cw + 18;
  const inner = W - ml - mr, n = kys.length;
  const X = (ky) => ml + (n === 1 ? inner / 2 : (kys.indexOf(ky) / (n - 1)) * inner);
  const Y = (v) => top + (1 - v / ticks[ticks.length - 1]) * (H - top - bottom);
  const every = Math.max(1, Math.ceil((Math.max(...kys.map((k) => k.length)) * cw + 12) / (n > 1 ? inner / (n - 1) : inner)));
  const endY = series.map((s) => Y(s.pts[s.pts.length - 1].v));
  [...endY.keys()].sort((a, b) => endY[a] - endY[b]).forEach((idx, k, arr) => { if (k && endY[idx] - endY[arr[k - 1]] < 15) endY[idx] = endY[arr[k - 1]] + 15; });
  const duong = (s) => s.pts.map((p, j) => `${j ? "L" : "M"}${X(p.ky).toFixed(1)},${Y(p.v).toFixed(1)}`).join("");
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={series.map((s) => ({ ten: s.ten, color: s.color, line: true })).concat(ref0 ? [{ ten: ref0.ten, color: P.navy, dash: true }] : [])} />
      <div ref={ref} className="relative min-h-0 flex-1">
        <svg className="absolute inset-0" width={W} height={H} viewBox={`0 0 ${W} ${H}`} onMouseLeave={() => setHover(null)}
          onMouseMove={(e) => { const r = e.currentTarget.getBoundingClientRect(); const mx = ((e.clientX - r.left) / r.width) * W; setHover(kys.reduce((a, b) => (Math.abs(X(b) - mx) < Math.abs(X(a) - mx) ? b : a), kys[0])); }}>
                    {ticks.map((t) => <g key={t}><line x1={ml} x2={W - mr + 6} y1={Y(t)} y2={Y(t)} stroke={C.grid} /><text x={ml - 8} y={Y(t)} dy="0.32em" textAnchor="end" fontSize={fs} fill={P.mo}>{fmtTick(t)}</text></g>)}
          {kys.map((k, i) => (i % every === 0 ? <text key={k} x={X(k)} y={H - 6} textAnchor="middle" fontSize={fs} fill={P.mo}>{k}</text> : null))}
          {ref0 && <line x1={ml} x2={W - mr + 6} y1={Y(ref0.v)} y2={Y(ref0.v)} stroke={P.navy} strokeWidth="1.3" strokeDasharray="6 5" />}
          {hover && <line x1={X(hover)} x2={X(hover)} y1={top} y2={H - bottom} stroke="#D0D5DD" />}
          {series.map((s, i) => (
            <g key={s.ma}>
              {series.length <= 2 && <path d={`${duong(s)}L${X(s.pts[s.pts.length - 1].ky).toFixed(1)},${Y(0)}L${X(s.pts[0].ky).toFixed(1)},${Y(0)}Z`} fill={s.color} opacity=".10" />}
              <path d={duong(s)} fill="none" stroke={s.color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
              {s.pts.map((p) => <circle key={p.ky} cx={X(p.ky)} cy={Y(p.v)} r={hover === p.ky ? 5 : 3.2} fill="#fff" stroke={s.color} strokeWidth="2" />)}
              <text x={X(s.pts[s.pts.length - 1].ky) + 9} y={endY[i]} dy="0.32em" fontSize={fs + 1} fontWeight="700" fill={s.color}>{ends[i]}</text>
            </g>
          ))}
        </svg>
        {hover && <Tip left={(X(hover) / W) * 100} tieuDe={hover} dong={series.map((s) => { const p = s.pts.find((q) => q.ky === hover); return [s.color, s.ten, p ? fmtPt(p) : "—"]; })} />}
      </div>
    </div>
  );
}

function Columns({ maList, mn }) {
  const [ref, { w: W, h: H }] = useSize();
  const [hover, setHover] = useState(null);
  const series = maList.map((ma, i) => ({ ma, ten: tenCS(ma), color: MAU[i % MAU.length], pts: mn[ma]?.chuoi || [] })).filter((s) => s.pts.length);
  const kys = [...new Map(series.flatMap((s) => s.pts).sort((a, b) => a.thuTu - b.thuTu).map((p) => [p.ky, p.thuTu])).keys()];
  const ticks = niceTicks(Math.max(...series.flatMap((s) => s.pts.map((p) => p.v))));
  const top = 22, bottom = 26, ml = Math.max(...ticks.map((t) => gon(t).length)) * 8 + 20, mr = 8;
  const band = (W - ml - mr) / kys.length, gw = Math.min(band * 0.7, 44 * series.length), bw = gw / series.length;
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
            return (
              <g key={k} onMouseEnter={() => setHover(k)}>
                <rect x={ml + i * band} y={top} width={band} height={H - top - bottom} fill={hover === k ? "#FAFBFC" : "transparent"} />
                {series.map((s, j) => {
                  const p = s.pts.find((q) => q.ky === k);
                  if (!p) return null;
                  return (
                    <g key={s.ma}>
                      <rect x={x0 + j * bw + 1.5} y={Y(p.v)} width={Math.max(2, bw - 3)} height={Math.max(0, Y(0) - Y(p.v))} rx="3" fill={s.color} />
                      {(series.length === 1 || bw > 34) && <text x={x0 + j * bw + bw / 2} y={Y(p.v) - 6} textAnchor="middle" fontSize="13" fontWeight="700" fill={P.ink2}>{gon(p.v)}</text>}
                    </g>
                  );
                })}
                {i % every === 0 && <text x={ml + i * band + band / 2} y={H - 6} textAnchor="middle" fontSize="14" fill={P.mo}>{k}</text>}
              </g>
            );
          })}
        </svg>
        {hover && <Tip left={((ml + kys.indexOf(hover) * band + band) / W) * 100} tieuDe={hover} dong={series.map((s) => { const p = s.pts.find((q) => q.ky === hover); return [s.color, s.ten, p ? soTuDong(p.v) : "—"]; })} />}
      </div>
    </div>
  );
}

/* Chỉ số tỷ lệ: vòng tròn cùng kích thước, cùng bố cục với biểu đồ vành khuyên để các ô đồng đều */
function Gauge({ ma, mn, muc, tran = 1 }) {
  const [ref, { w, h }] = useSize();
  const m = mn[ma];
  const v = m ? m.v : 0, frac = Math.max(0, Math.min(1, v / tran));
  const size = Math.min(h, w * 0.42, 190), R = size / 2 - 4, r = R * 0.7, rm = (R + r) / 2, cx = size / 2, cy = h / 2, c = 2 * Math.PI * rm;
  const mau = muc != null ? (v >= muc ? C.tot : v >= muc * 0.85 ? C.warn : C.xau) : ACC;
  const dong = [
    { ten: "Đã đạt", mau, val: `${so(frac * 100, 1)}%`, bold: true },
    { ten: "Còn lại", mau: C.track, val: `${so((1 - frac) * 100, 1)}%` },
  ];
  if (muc != null) dong.push({ ten: "Mục tiêu", mau: P.navy, val: `${so(muc * 100, 0)}%` });
  return (
    <div ref={ref} className="flex h-full w-full items-center gap-8">
      <svg width={size} height={h} viewBox={`0 0 ${size} ${h}`} className="shrink-0">
        <circle cx={cx} cy={cy} r={rm} fill="none" stroke={C.track} strokeWidth={R - r} />
        <circle cx={cx} cy={cy} r={rm} fill="none" stroke={mau} strokeWidth={R - r} strokeLinecap="butt" strokeDasharray={`${frac * c} ${c}`} transform={`rotate(-90 ${cx} ${cy})`} />
        {muc != null && (() => { const t = (muc / tran) * 2 * Math.PI - Math.PI / 2; return <line x1={cx + (r - 3) * Math.cos(t)} y1={cy + (r - 3) * Math.sin(t)} x2={cx + (R + 3) * Math.cos(t)} y2={cy + (R + 3) * Math.sin(t)} stroke={P.navy} strokeWidth="2.5" strokeLinecap="round" />; })()}
        <text x={cx} y={cy - 2} textAnchor="middle" fontSize={Math.max(22, r * 0.42)} fontWeight="600" fill={P.navy} style={{ fontFamily: FONT_APPLE }}>{m ? m.hienThi : "—"}</text>
        <text x={cx} y={cy + 20} textAnchor="middle" fontSize="13" fill={P.mo}>{m ? m.ky : ""}</text>
      </svg>
      <ul className="min-w-0 flex-1 space-y-2">
        {dong.map((d) => (
          <li key={d.ten} className="flex items-center gap-2 text-[15px]">
            <span className="h-2.5 w-2.5 shrink-0 rounded-sm" style={{ background: d.mau }} />
            <span className="leading-tight text-[#101828]">{d.ten}</span>
            <span className="ml-auto whitespace-nowrap font-semibold tabular-nums text-[#101828]">{d.val}</span>
          </li>
        ))}
        {m && <li className="flex items-center gap-2 pt-1 text-[15px]"><span className="leading-tight text-[#475467]">Thay đổi</span><span className="ml-auto"><Delta m={m} /></span></li>}
      </ul>
    </div>
  );
}

function Donut({ parts, giua, phu }) {
  const [ref, { w, h }] = useSize();
  const tong = parts.reduce((a, p) => a + p.v, 0) || 1;
  const size = Math.min(h, w * 0.42, 190), R = size / 2 - 4, r = R * 0.7, cx = size / 2, cy = h / 2;
  let a0 = -Math.PI / 2;
  const cung = parts.map((p) => {
    const a1 = a0 + (p.v / tong) * Math.PI * 2, big = a1 - a0 > Math.PI ? 1 : 0;
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
            <span className="ml-auto whitespace-nowrap font-semibold tabular-nums text-[#101828]">{gon(p.v)}</span>
            <span className="w-14 text-right text-sm tabular-nums text-[#475467]">{so((p.v / tong) * 100, 1)}%</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

function HBars({ rows, segs, max, overlay = false, giaTri }) {
  const m = max || Math.max(...rows.map((r) => (overlay ? Math.max(...segs.map((s) => s.v(r))) : segs.reduce((a, s) => a + s.v(r), 0))));
  return (
    <div className="flex h-full min-h-0 flex-col">
      <Chu items={segs.map((s) => ({ ten: s.ten, color: s.color }))} />
      <ul className="flex min-h-0 flex-1 flex-col justify-around">
        {rows.map((r, i) => (
          <li key={i}>
            <div className="flex items-baseline justify-between gap-3 text-sm">
              <span className="truncate text-[#101828]" title={r.nhan}>{r.nhan}</span>
              <span className="shrink-0 font-semibold tabular-nums text-[#101828]">{giaTri(r)}</span>
            </div>
            <div className="relative mt-1 h-3 w-full overflow-hidden rounded-sm" style={{ background: C.track }}>
              {overlay
                ? segs.map((s) => <div key={s.ten} className="absolute inset-y-0 left-0" style={{ width: `${(s.v(r) / m) * 100}%`, background: s.color }} title={`${s.ten}: ${soTuDong(s.v(r))}`} />)
                : <div className="flex h-full">{segs.map((s) => <div key={s.ten} style={{ width: `${(s.v(r) / m) * 100}%`, background: s.color }} title={`${s.ten}: ${soTuDong(s.v(r))}`} />)}</div>}
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

/* ---------- Bảng ---------- */
const thCls = "sticky top-0 z-10 whitespace-nowrap bg-white px-2 py-2.5 text-xs font-semibold uppercase tracking-wide text-[#475467] border-b border-[#D9DEE7]";
function BangChiSo({ cd, mn }) {
  return (
    <div className="h-full overflow-auto">
      <table className="w-full text-left text-sm">
        <thead><tr><th className={thCls}>Chỉ số</th><th className={`${thCls} text-right`}>Giá trị</th><th className={thCls}>Thay đổi</th><th className={thCls}>Diễn biến</th></tr></thead>
        <tbody>
          {CHI_SO.filter((c) => c.chuyenDe === cd).map((c) => {
            const m = mn[c.ma];
            return (
              <tr key={c.ma} className="border-b border-[#E4E7EC] align-middle">
                <td className="px-2 py-2"><p className={c.canBoSung ? "italic text-[#667085]" : "text-[#101828]"}>{c.ten}</p>{m && <p className="text-xs text-[#667085]">{m.ky}</p>}</td>
                <td className="whitespace-nowrap px-2 py-2 text-right text-base font-semibold tabular-nums text-[#101828]">{m ? m.hienThi : <span className="text-sm font-normal text-[#98A2B3]">Chưa có</span>}{m && donVi(c.ma) && <span className="ml-1 text-xs font-normal text-[#475467]">{donVi(c.ma)}</span>}</td>
                <td className="px-2 py-2"><Delta m={m} /></td>
                <td className="px-2 py-2"><Spark chuoi={m?.chuoi} w={90} h={28} /></td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

const nguonGiaoT9 = () => NGUON_GIAO.filter((r) => r.ky === "T9/2026").map((r) => ({ ...r, nhan: r.nguon_giao }));
const SEG_NGUON = [{ ten: "Hoàn thành", color: "#1D6FE8", v: (r) => r.hoan_thanh }, { ten: "Đang trong hạn", color: "#7FB1F6", v: (r) => r.dang_thuc_hien - r.qua_han }, { ten: "Quá hạn", color: "#F04438", v: (r) => r.qua_han }];
const XEP_LOAI = [["A hoàn thành", "CS10", "#12B76A"], ["B tiến độ tốt", "CS11", "#6EDB8F"], ["C bình thường", "CS12", "#1D6FE8"], ["D/D2 quá hạn", "CS13", "#F04438"], ["E chưa đủ số liệu", "CS14", "#D0D5DD"]];
const quaHan = () => QUA_HAN.map((q) => ({ ...q, soNgay: q.han ? Math.round((Date.parse(NGAY_CHOT_QUA_HAN) - Date.parse(q.han)) / 864e5) : null })).sort((a, b) => (b.soNgay ?? -1) - (a.soNgay ?? -1));

function BangQuaHan() {
  return (
    <div className="h-full overflow-auto">
      <table className="w-full text-left text-sm">
        <thead><tr><th className={thCls}>Nhiệm vụ</th><th className={`${thCls} text-right`}>Quá hạn</th><th className={thCls}>Mốc kiểm tra</th></tr></thead>
        <tbody>
          {quaHan().map((q) => (
            <tr key={q.stt} className="border-b border-[#E4E7EC] align-top">
              <td className="px-2 py-2"><p className="line-clamp-2 text-[#101828]" title={q.ten}>{q.ten}</p><p className="mt-0.5 text-xs text-[#667085]">{q.coQuan}</p></td>
              <td className="whitespace-nowrap px-2 py-2 text-right font-semibold tabular-nums" style={{ color: q.soNgay > 90 ? C.xau : q.soNgay > 30 ? C.warn : P.ink2 }}>{q.soNgay != null ? `${q.soNgay} ngày` : ""}</td>
              <td className="whitespace-nowrap px-2 py-2 text-xs text-[#344054]">{q.choTW ? "Chờ Trung ương" : q.moc}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function BangXa() {
  return (
    <div className="h-full overflow-auto">
      <table className="w-full text-left text-sm">
        <thead><tr><th className={thCls}>Xã, phường</th><th className={thCls}>Tỷ lệ hoàn thành</th><th className={`${thCls} text-right`}>Đang quá hạn</th><th className={`${thCls} text-right`}>Xong quá hạn</th></tr></thead>
        <tbody>
          {XA_QUAN_TAM.map((x) => {
            const tl = x.hoan_thanh / x.tong_nhiem_vu, col = tl < 0.6 ? C.xau : tl < 0.85 ? C.warn : ACC;
            return (
              <tr key={x.xa} className="border-b border-[#E4E7EC]">
                <td className="px-2 py-2.5 font-medium text-[#101828]">{x.xa}<span className="block text-xs font-normal text-[#667085]">{x.hoan_thanh}/{x.tong_nhiem_vu} nhiệm vụ</span></td>
                <td className="px-2 py-2.5"><div className="flex items-center gap-2"><div className="h-2 flex-1 overflow-hidden rounded-sm" style={{ background: C.track }}><div className="h-full" style={{ width: `${tl * 100}%`, background: col }} /></div><span className="w-12 text-right text-sm font-semibold tabular-nums" style={{ color: P.navy }}>{so(tl * 100, 0)}%</span></div></td>
                <td className="px-2 py-2.5 text-right font-semibold tabular-nums" style={{ color: x.dang_qua_han ? C.xau : "#98A2B3" }}>{x.dang_qua_han}</td>
                <td className="px-2 py-2.5 text-right tabular-nums text-[#344054]">{x.xong_qua_han}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

/* ---------- Ô biểu đồ ---------- */
function veBieuDo(b, mn) {
  if (b.dang === "line") return <LineChart maList={b.ma} kieu={b.kieu} mn={mn} nguong={b.nguong} />;
  if (b.dang === "cot") return <Columns maList={b.ma} mn={mn} />;
  if (b.dang === "gauge") return <Gauge ma={b.ma} mn={mn} muc={b.muc} tran={b.tran} />;
  if (b.dang === "donut-dd") {
    const a = mn.DD01?.v || 0, c = mn.DD02?.v || 0, d = mn.DD04?.v || 0;
    return <Donut giua={gon(a)} phu={`thửa · ${mn.DD01?.ky || ""}`} parts={[{ ten: "Đạt Nhóm 1", v: d, color: "#1D6FE8" }, { ten: "Có CSDL, chưa đạt", v: c - d, color: "#7FB1F6" }, { ten: "Chưa có CSDL", v: a - c, color: "#D0D5DD" }]} />;
  }
  return null;
}
function oBieuDo(trang, mn) {
  const o = trang.bieuDo.map((b) => ({ key: b.ten, rong: !!b.rong, tieuDe: b.ten, el: veBieuDo(b, mn) }));
  if (trang.id === "nhiem-vu") {
    const theoCQ = [...quaHan().filter((q) => !q.choTW).reduce((m, q) => m.set(q.coQuan, (m.get(q.coQuan) || 0) + 1), new Map())].map(([nhan, n]) => ({ nhan, n })).sort((a, b) => b.n - a.n).slice(0, 7);
    o.push({ key: "nguon", tieuDe: "Theo nguồn giao, tháng 9/2026", el: <HBars rows={nguonGiaoT9()} segs={SEG_NGUON} giaTri={(r) => `${r.tong}`} /> });
    o.push({ key: "cq", tieuDe: "Quá hạn theo cơ quan chủ trì", el: <HBars rows={theoCQ} segs={[{ ten: "Nhiệm vụ quá hạn", color: "#F04438", v: (r) => r.n }]} giaTri={(r) => `${r.n}`} /> });
  }
  if (trang.id === "xa-phuong") {
    const nhom = [...new Set(NOI_DUNG_XA.map((r) => r.nhom))].map((n) => ({ nhan: n, t8: NOI_DUNG_XA.find((r) => r.nhom === n && r.ky === "T8/2026")?.so_xa || 0, t9: NOI_DUNG_XA.find((r) => r.nhom === n && r.ky === "T9/2026")?.so_xa || 0 }));
    const xl = XEP_LOAI.map(([ten, ma, color]) => ({ ten, color, v: CHUOI.find((r) => r.ma === ma && r.ky === "T9/2026")?.v || 0 }));
    o.push({ key: "xl", tieuDe: "Xếp loại tiến độ, tháng 9/2026", el: <Donut parts={xl} giua={xl.reduce((a, p) => a + p.v, 0)} phu="xã, phường" /> });
    o.push({ key: "nd", tieuDe: "Có kết quả theo nhóm nội dung", el: <HBars rows={nhom} overlay max={126} segs={[{ ten: "T9/2026", color: "#1D6FE8", v: (r) => r.t9 }, { ten: "T8/2026", color: "#7FB1F6", v: (r) => r.t8 }]} giaTri={(r) => `${r.t8} → ${r.t9}`} /> });
    o.push({ key: "dn", tieuDe: "Điểm nghẽn chính xã phản ánh (tháng 8)", el: <HBars rows={DIEM_NGHEN_XA.slice(0, 7).map((r) => ({ ...r, nhan: r.nhom }))} overlay max={126} segs={[{ ten: "Phản ánh", color: "#7FB1F6", v: (r) => r.so_xa_phan_anh }, { ten: "Cần xử lý sớm", color: "#F04438", v: (r) => r.can_xu_ly_som }]} giaTri={(r) => `${r.so_xa_phan_anh} (${r.can_xu_ly_som})`} /> });
  }
  return o;
}

/* ---------- Trang ---------- */
function TrangChuyenDe({ trang, mn }) {
  const cd = CHUYEN_DE[trang.cd];
  const o = oBieuDo(trang, mn);
  const bang = [{ id: "chi-so", ten: "Tất cả chỉ số", el: <BangChiSo cd={cd} mn={mn} /> }];
  if (trang.id === "nhiem-vu") bang.unshift({ id: "qua-han", ten: "Nhiệm vụ quá hạn", el: <BangQuaHan /> });
  if (trang.id === "xa-phuong") bang.unshift({ id: "xa", ten: "Xã, phường cần quan tâm", el: <BangXa /> });
  const [chon, setChon] = useState(bang[0].id);
  const b = bang.find((x) => x.id === chon) || bang[0];
  const xa = trang.id === "xa-phuong";
  const cols = xa ? 2 : trang.cot || (o.length >= 3 ? 2 : 1);
  const sorted = [...o].sort((a, c) => (c.rong ? 1 : 0) - (a.rong ? 1 : 0));
  let used = 0;
  const span = sorted.map((x, i) => { const full = cols === 2 && (x.rong || (used % 2 === 0 && i === sorted.length - 1)); used += full ? 2 : 1; return full; });
  const rows = Math.ceil(used / cols);
  const luoi = xa
    ? { gridTemplateColumns: "repeat(2, minmax(0, 1fr))", gridTemplateRows: "minmax(0, 1fr) minmax(0, 1.4fr)", gridTemplateAreas: '"xl nd" "dn nd"' }
    : { gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`, gridTemplateRows: sorted.some((x) => x.rong) && rows > 1 ? `minmax(0, 1.25fr) repeat(${rows - 1}, minmax(0, 1fr))` : `repeat(${rows}, minmax(0, 1fr))` };
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid h-[156px] flex-none grid-cols-4 gap-5">{trang.kpi.map((ma) => <Kpi key={ma} ma={ma} mn={mn} icon={trang.id} />)}</div>
      <div className="grid min-h-0 flex-1 grid-cols-12 gap-10">
        <div className="col-span-7 grid min-h-0 gap-x-10 gap-y-5" style={luoi}>
          {(xa ? o : sorted).map((x, i) => <Muc key={x.key} tieuDe={x.tieuDe} className={!xa && span[i] ? "col-span-2" : ""} style={xa ? { gridArea: x.key } : undefined}>{x.el}</Muc>)}
        </div>
        <Muc className="col-span-5"
          phai={bang.length > 1 && (
            <div className="flex shrink-0 rounded-lg bg-[#E4E7EC] p-0.5 text-sm" role="tablist">
              {bang.map((x) => <button key={x.id} role="tab" aria-selected={chon === x.id} onClick={() => setChon(x.id)} className={`rounded-md px-3 py-1 font-medium ${chon === x.id ? "bg-white text-[#101828] shadow-sm" : "text-[#475467]"}`}>{x.ten}</button>)}
            </div>
          )}>{b.el}</Muc>
      </div>
    </div>
  );
}

function TongQuan({ mn, moTrang }) {
  const doPhu = CHUYEN_DE.map((cd) => {
    const ds = CHI_SO.filter((c) => c.chuyenDe === cd);
    return { moi: ds.filter((c) => mn[c.ma] && mn[c.ma].thuTu >= KY_MOI).length, cu: ds.filter((c) => mn[c.ma] && mn[c.ma].thuTu < KY_MOI).length, bs: ds.filter((c) => c.canBoSung).length, tong: ds.length };
  });
  const ht = mn.NV02?.v || 0, dang = mn.NV04?.v || 0, qh = mn.NV05?.v || 0;
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid h-[156px] flex-none grid-cols-5 gap-5">{CAN_CHU_Y.map((k) => <Kpi key={k.ma} ma={k.ma} mn={mn} icon={k.trang} onClick={() => moTrang(k.trang)} />)}</div>
      <div className="grid min-h-0 flex-1 grid-cols-12 gap-10">
        <Muc className="col-span-8" tieuDe="Chín chuyên đề"
          phai={<div className="flex gap-4 text-xs text-[#475467]"><span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm" style={{ background: ACC }} />Có số liệu từ T9</span><span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm" style={{ background: P.sang }} />Số liệu kỳ cũ</span><span className="inline-flex items-center gap-1.5"><i className="h-2 w-2 rounded-sm" style={{ background: "#D0D5DD" }} />Cần bổ sung</span></div>}>
          <table className="h-full w-full text-left text-sm">
            <thead><tr><th className={thCls}>Chuyên đề</th><th className={`${thCls} text-right`}>Giá trị</th><th className={thCls}>Tiến độ</th><th className={thCls}>Thay đổi</th><th className={thCls}>Diễn biến</th><th className={`${thCls} w-44`}>Độ đầy đủ số liệu</th></tr></thead>
            <tbody>
              {TONG_QUAN.map(([id, ma], i) => {
                const m = mn[ma], p = doPhu[i], tl = tyLe(m), dv = donVi(ma);
                return (
                  <tr key={id} className="cursor-pointer border-b border-[#E4E7EC] hover:bg-[#FAFBFC]" onClick={() => moTrang(id)}>
                    <td className="px-2 py-1.5">
                      <div className="flex items-center gap-3">
                        <AppIcon name={id} size={34} />
                        <div className="min-w-0"><p className="text-[15px] font-semibold text-[#101828]">{CHUYEN_DE[i].replace(/^\d+\.\s*/, "")}</p><p className="truncate text-xs text-[#475467]">{tenCS(ma)}</p></div>
                      </div>
                    </td>
                    <td className="whitespace-nowrap px-2 py-1.5 text-right text-[24px] font-semibold tabular-nums" style={{ color: P.navy, fontFamily: FONT_APPLE }}>{m?.hienThi}{dv && <span className="ml-1 text-xs font-normal text-[#475467]" style={{ fontFamily: "inherit" }}>{dv}</span>}</td>
                    <td className="w-40 px-2 py-1.5">{tl != null ? <div className="flex items-center gap-2"><div className="h-2 flex-1 overflow-hidden rounded-sm" style={{ background: C.track }}><div className="h-full" style={{ width: `${Math.min(100, tl * 100)}%`, background: ACC }} /></div><span className="w-10 text-right text-xs font-semibold tabular-nums text-[#101828]">{so(tl * 100, 0)}%</span></div> : <span className="text-xs text-[#98A2B3]">—</span>}</td>
                    <td className="px-2 py-1.5"><Delta m={m} /><span className="block text-xs text-[#667085]">{m?.ky}</span></td>
                    <td className="px-2 py-1.5"><Spark chuoi={m?.chuoi} w={120} h={32} /></td>
                    <td className="px-2 py-1.5">
                      <div className="flex h-2 overflow-hidden rounded-sm" style={{ background: C.track }} title={`${p.moi} có số liệu mới · ${p.cu} kỳ cũ · ${p.bs} cần bổ sung`}>
                        <div style={{ width: `${(p.moi / p.tong) * 100}%`, background: ACC }} /><div style={{ width: `${(p.cu / p.tong) * 100}%`, background: P.sang }} /><div style={{ width: `${(p.bs / p.tong) * 100}%`, background: "#D0D5DD" }} />
                      </div>
                      <p className="mt-1 text-xs tabular-nums text-[#475467]">{p.moi} · {p.cu} · {p.bs}</p>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </Muc>
        <div className="col-span-4 grid min-h-0 grid-rows-2 gap-5">
          <Muc tieuDe="Tình trạng nhiệm vụ">
            <Donut giua={gon(mn.NV01?.v || 0)} phu={`nhiệm vụ · ${mn.NV01?.ky || ""}`} parts={[{ ten: "Hoàn thành", v: ht, color: "#1D6FE8" }, { ten: "Đang trong hạn", v: dang - qh, color: "#7FB1F6" }, { ten: "Quá hạn", v: qh, color: "#F04438" }]} />
          </Muc>
          <Muc tieuDe="Xếp loại tiến độ xã, phường">
            <Donut giua="126" phu="xã, phường · T9/2026" parts={XEP_LOAI.map(([ten, ma, color]) => ({ ten, color, v: CHUOI.find((r) => r.ma === ma && r.ky === "T9/2026")?.v || 0 }))} />
          </Muc>
        </div>
      </div>
    </div>
  );
}

function DanhMuc({ mn }) {
  const [q, setQ] = useState("");
  const [cd, setCd] = useState("");
  const [sx, setSx] = useState({ k: "ma", dir: 1 });
  const rows = useMemo(() => CHI_SO.map((c) => ({ ...c, giaTri: mn[c.ma]?.hienThi || "", ky: mn[c.ma]?.ky || "", soKy: mn[c.ma]?.soKy || 0, thuTu: mn[c.ma]?.thuTu || 0 })), [mn]);
  const loc = rows.filter((r) => (!cd || r.chuyenDe === cd) && (!q || `${r.ma} ${r.ten} ${r.dauMoi}`.toLowerCase().includes(q.toLowerCase())))
    .sort((a, b) => (typeof a[sx.k] === "number" ? a[sx.k] - b[sx.k] : String(a[sx.k]).localeCompare(String(b[sx.k]), "vi")) * sx.dir);
  const dem = [
    { nhan: "Tổng số chỉ số", v: rows.length, mau: P.navy, icon: "danh-muc" },
    { nhan: "Có số liệu từ T9/2026", v: rows.filter((r) => r.thuTu >= KY_MOI).length, mau: ACC, icon: "tong-quan" },
    { nhan: "Chỉ có số liệu kỳ cũ hơn", v: rows.filter((r) => r.thuTu && r.thuTu < KY_MOI).length, mau: C.warn, icon: "canh-bao" },
    { nhan: "Cần bổ sung, chưa có số liệu", v: rows.filter((r) => r.canBoSung).length, mau: C.xau, icon: "canh-bao" },
  ];
  const Th = ({ k, children, right }) => (
    <th className={`${thCls} ${right ? "text-right" : ""}`} aria-sort={sx.k === k ? (sx.dir > 0 ? "ascending" : "descending") : "none"}>
      <button className="uppercase hover:text-[#101828] focus:outline-none focus-visible:underline" onClick={() => setSx({ k, dir: sx.k === k ? -sx.dir : 1 })}>{children}{sx.k === k ? (sx.dir > 0 ? " ▲" : " ▼") : ""}</button>
    </th>
  );
  const PL = { "Có": C.tot, "Tính được": ACC, "Có một phần": C.warn, "Chưa có": C.xau };
  return (
    <div className="flex h-full flex-col gap-5">
      <div className="grid h-[156px] flex-none grid-cols-4 gap-5">
        {dem.map((d) => (
          <div key={d.nhan} className="flex h-full flex-col justify-between rounded-xl bg-white px-5 py-4" style={{ border: `1px solid ${P.vien}`, borderTop: `3px solid ${d.mau}`, boxShadow: "0 1px 2px rgba(15,42,92,.04)" }}>
            <p className="flex items-center gap-2 text-[15px] font-medium text-[#344054]"><span style={{ color: d.mau }}><Icon name={d.icon} size={18} /></span>{d.nhan}</p>
            <div className="flex items-end justify-between"><p className="text-[40px] font-semibold leading-none tabular-nums" style={{ color: P.navy, fontFamily: FONT_APPLE }}>{d.v}</p><Ring v={d.v / rows.length} color={d.mau} size={58} /></div>
          </div>
        ))}
      </div>
      <Muc className="min-h-0 flex-1" tieuDe={`Danh mục chỉ số (${loc.length})`}
        phai={(
          <div className="flex shrink-0 gap-3">
            <input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm chỉ số, đầu mối" aria-label="Tìm chỉ số" className="w-80 rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-sm text-[#101828] focus:border-[#1D6FE8] focus:outline-none" />
            <select value={cd} onChange={(e) => setCd(e.target.value)} aria-label="Chuyên đề" className="rounded-lg border border-[#D9DEE7] bg-white px-3 py-1.5 text-sm text-[#101828] focus:border-[#1D6FE8] focus:outline-none">
              <option value="">Tất cả chuyên đề</option>{CHUYEN_DE.map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>
        )}>
        <div className="h-full overflow-auto">
          <table className="w-full text-left text-sm">
            <thead><tr><Th k="ten">Chỉ số</Th><Th k="chuyenDe">Chuyên đề</Th><th className={`${thCls} text-right`}>Giá trị mới nhất</th><Th k="thuTu">Kỳ</Th><Th k="soKy" right>Số kỳ</Th><Th k="dauMoi">Đầu mối</Th><Th k="phuLucGoc">Phụ lục gốc</Th></tr></thead>
            <tbody>
              {loc.map((r) => (
                <tr key={r.ma} className="border-b border-[#E4E7EC] align-middle hover:bg-[#FAFBFC]">
                  <td className={`px-2 py-1.5 ${r.canBoSung ? "italic text-[#667085]" : "text-[#101828]"}`}>{r.ten}</td>
                  <td className="whitespace-nowrap px-2 py-1.5 text-xs text-[#475467]">{r.chuyenDe.replace(/^\d+\.\s*/, "")}</td>
                  <td className="whitespace-nowrap px-2 py-1.5 text-right font-semibold tabular-nums text-[#101828]">{r.giaTri || <span className="font-normal text-[#98A2B3]">Chưa có</span>}</td>
                  <td className="whitespace-nowrap px-2 py-1.5 text-xs text-[#475467]">{r.ky}</td>
                  <td className="px-2 py-1.5 text-right text-xs font-semibold tabular-nums" style={{ color: r.soKy === 1 ? C.warn : "#475467" }}>{r.soKy}</td>
                  <td className="px-2 py-1.5 text-xs text-[#344054]">{r.dauMoi}</td>
                  <td className="px-2 py-1.5"><span className="inline-flex items-center gap-1.5 whitespace-nowrap text-xs font-medium text-[#101828]"><i className="h-2 w-2 rounded-full" style={{ background: PL[r.phuLucGoc] || P.mo }} />{r.phuLucGoc}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Muc>
    </div>
  );
}

export default function NQ57Dashboard() {
  const mn = useMemo(tinhMoiNhat, []);
  const [trang, setTrang] = useState(() => (typeof window !== "undefined" && TRANG.some((t) => t.id === window.location.hash.slice(1)) ? window.location.hash.slice(1) : "tong-quan"));
  const moTrang = (id) => { setTrang(id); try { window.history.replaceState(null, "", `#${id}`); } catch (e) { /* khung xem trước */ } };
  const t = TRANG.find((x) => x.id === trang);
  return (
    <div className="nq57">
    <style>{TAILWIND_CSS}</style>
    <Stage>
      <div className="flex h-full flex-col text-[#101828] bg-white" style={{ fontFamily: FONT_APPLE, letterSpacing: "-0.011em" }}>
        <header className="flex flex-none items-center justify-between px-10" style={{ height: 84, background: THUONG_HIEU, borderBottom: "3px solid #F5C24C" }}>
          <h1 className="text-white" style={{ fontFamily: FONT_APPLE, fontSize: 30, fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.02em" }}>Theo dõi thực hiện Nghị quyết 57-NQ/TW</h1>
          <p style={{ fontSize: 15, color: "#DCE9FF" }}>Ban Chỉ đạo 57 Thành ủy Hà Nội<span style={{ margin: "0 12px", opacity: 0.5 }}>|</span><b style={{ color: "#FFFFFF", fontWeight: 600 }}>Số liệu đến Tuần 41</b></p>
        </header>
        <nav className="flex h-[64px] flex-none items-center gap-1 border-b border-[#D9DEE7] bg-white px-8" aria-label="Chuyên đề" role="tablist">
          {TRANG.map((x) => {
            const on = trang === x.id;
            return (
              <button key={x.id} role="tab" aria-selected={on} onClick={() => moTrang(x.id)}
                className={`flex h-11 items-center gap-1.5 whitespace-nowrap rounded-lg px-3 text-[15px] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#1D6FE8] ${on ? "font-semibold text-white" : "font-medium text-[#344054] hover:bg-[#E4E7EC]"}`}
                style={on ? { background: THUONG_HIEU, boxShadow: "none" } : undefined}>
                <Icon name={x.id} size={18} color={on ? "#fff" : "#1D6FE8"} />{x.ten}
              </button>
            );
          })}
        </nav>
        <main className="relative min-h-0 flex-1 px-10 py-5">
          {trang === "tong-quan" && <TongQuan mn={mn} moTrang={moTrang} />}
          {trang === "danh-muc" && <DanhMuc mn={mn} />}
          {t?.cd != null && <TrangChuyenDe key={t.id} trang={t} mn={mn} />}
        </main>
      </div>
    </Stage>
    </div>
  );
}
