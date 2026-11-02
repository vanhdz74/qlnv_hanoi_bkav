jsEchartScriptFunc = function (queryData, option, echarts, context) {
  const elementId =
    context && context.elementId ? context.elementId : "fallback-table-id";
  const rootEl = document.getElementById(elementId);
  if (!rootEl) return {};

  const chartHeight =
    context && context.height ? context.height + "px" : "100%";
  const chartWidth = context && context.width ? context.width + "px" : "100%";
  rootEl.style.height = chartHeight;
  rootEl.style.width = chartWidth;
  rootEl.style.boxSizing = "border-box";
  rootEl.style.position = "relative";

  const wrapperId = "detail-table-" + elementId;

  // Đặt false nếu modal cha ĐÃ có thanh tiêu đề xanh + nút quay lại (tránh hiện 2 tiêu đề)
  const SHOW_TITLE_BAR = true;

  // ==========================================
  // 1. HÀM ĐỌC THAM SỐ TỪ URL TRÌNH DUYỆT
  // ==========================================
  function getURLParam(paramName) {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      if (urlParams.has(paramName)) return urlParams.get(paramName);
      if (window.parent && window.parent.location) {
        const parentParams = new URLSearchParams(window.parent.location.search);
        if (parentParams.has(paramName)) return parentParams.get(paramName);
      }
    } catch (e) {}
    const name = paramName.replace(/[\[\]]/g, "\\$&");
    const regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
    const results = regex.exec(window.location.href);
    if (!results || !results[2]) return null;
    return decodeURIComponent(results[2].replace(/\+/g, " "));
  }

  // ==========================================
  // 2. CẤU HÌNH ĐỘNG MÀU SẮC & CỘT HIỂN THỊ CHUẨN ẢNH
  // ==========================================
  // ĐỒNG BỘ VỚI MẪU "NHIỆM VỤ NHẬN": khóa trạng thái + c (màu chủ đạo) + tc (màu chữ tiêu đề)
  //   match = mã trạng thái nội bộ do getStatusType() trả về
  const STATUS_CONFIG = {
    all:          { c: "#0f3d8c", tc: "#04204F", label: "Toàn bộ",                  match: "all" },
    dht:          { c: "#00a870", tc: "#00754A", label: "Đã hoàn thành",            match: "ok" },
    dht_tronghan: { c: "#1b6fe3", tc: "#1B6FE3", label: "Đang thực hiện trong hạn", match: "run" },
    dht_quahan:   { c: "#e0202a", tc: "#C4161C", label: "Đang thực hiện quá hạn",   match: "late" },
    thuong_xuyen: { c: "#825ee4", tc: "#5B3FC4", label: "Nhiệm vụ thường xuyên",    match: "recurring" },
    // Bổ sung ngoài mẫu: dùng cho bản ghi chưa gắn trạng thái
    unknown:      { c: "#6B7280", tc: "#4B5563", label: "Chưa xác định trạng thái", match: "unknown" },
  };

  // NHÃN + MÀU CHUẨN CHO CÁC TÌNH TRẠNG (theo ảnh thống kê)
  //   khóa = mã nội bộ do getStatusType() trả về
  const ST_META = {
    ok:        { n: "Đã hoàn thành",     c: "#00a870" },
    run:       { n: "Đang TH trong hạn", c: "#1b6fe3" },
    late:      { n: "Đang TH quá hạn",   c: "#e0202a" },
    recurring: { n: "Thường xuyên",      c: "#825ee4" },
    unknown:   { n: "Chưa xác định",     c: "#6B7280" },
  };
  // Thứ tự cột trong bảng thống kê theo đơn vị
  const ST_ORDER = ["ok", "run", "late", "recurring"];

  // Khóa cũ -> khóa mới, để các liên kết lớp 1 đang dùng tên cũ vẫn chạy
  const STATUS_ALIAS = {
    ok: "dht",
    run: "dht_tronghan",
    late: "dht_quahan",
    recurring: "thuong_xuyen",
  };

  function resolveStatusKey(v) {
    if (v === null || v === undefined || v === "") return null;
    const k = String(v).trim();
    if (STATUS_CONFIG[k]) return k;
    if (STATUS_ALIAS[k]) return STATUS_ALIAS[k];
    return null;
  }

  const currentStatusKey =
    resolveStatusKey(getURLParam("status")) ||
    resolveStatusKey(context && context.status_filter) ||
    "all";

  const activeTheme = STATUS_CONFIG[currentStatusKey];

  // ĐƠN VỊ LỌC TỪ LỚP 1: don_vi_thuc_hien={don_vi_chu_tri}
  // (vẫn đọc don_vi_chu_tri / truc_giao / to_chuc_dang_chu_tri để liên kết cũ không gãy)
  const urlDVTHRaw =
    getURLParam("don_vi_thuc_hien") ||
    getURLParam("don_vi_chu_tri") ||
    getURLParam("truc_giao") ||
    getURLParam("to_chuc_dang_chu_tri") ||
    (context && context.don_vi_chu_tri) ||
    "";
  // Chuẩn hóa dấu "|" -> ", " cho khớp với dữ liệu đã được fixPipe ở bước nạp dữ liệu
  const urlDVTH = isEmptyParam(urlDVTHRaw)
    ? null
    : String(fixPipe(String(urlDVTHRaw))).replace(/\s+/g, " ").trim();
  const urlDVTHKey = urlDVTH ? normText(urlDVTH) : "";

  // TIÊU ĐỀ: NHIỆM VỤ GIAO — <ĐƠN VỊ CHỦ TRÌ> — <TRẠNG THÁI>
  // Đổi SHOW_UNIT_IN_TITLE = false nếu không muốn ghép tên đơn vị vào tiêu đề
  const SHOW_UNIT_IN_TITLE = true;
  const BASE_TITLE = "DANH SÁCH CHI TIẾT — NHIỆM VỤ GIAO GỘP";
  let currentTitle = BASE_TITLE;
  if (SHOW_UNIT_IN_TITLE && urlDVTH) {
    currentTitle += " — " + urlDVTH.toUpperCase();
  }
  if (currentStatusKey !== "all") {
    currentTitle += " — " + activeTheme.label.toUpperCase();
  }

  // GIỐNG BẢNG CHI TIẾT NHIỆM VỤ GIAO (616), BỎ CỘT "MÃ NHIỆM VỤ"
  const DISPLAY_COLUMNS = [
    { keys: ["TT", "tt"], label: "TT" },
    { keys: ["nhom_van_ban","Nhóm nhiệm vụ", "nhom_nhiem_vu"], label: "Nhóm nhiệm vụ" },
    { keys: ["Văn bản giao", "van_ban_giao"], label: "Văn bản giao" },
    { keys: ["Nội dung nhiệm vụ", "ten_nhiem_vu"], label: "Nội dung nhiệm vụ" },
    { keys: ["Đơn vị thực hiện", "Đơn vị chủ trì", "don_vi_chu_tri", "ten_don_vi_chu_tri", "to_chuc_dang_chu_tri"], label: "Đơn vị thực hiện" },
    { keys: ["LĐ đơn vị và chuyên viên (SĐT)", "ten_lanh_dao", "Lãnh đạo đơn vị và chuyên viên", "lanh_dao_va_chuyen_vien", "Lãnh đạo đơn vị và chuyên..."], prefixMatch: "Lãnh đạo", label: "LĐ đơn vị và chuyên viên (SĐT)" },
    { keys: ["Thời hạn", "thoi_han", "han"], label: "Thời hạn" },
    { keys: ["Tình trạng", "tinh_trang"], label: "Tình trạng" },
    { keys: ["Tình hình, kết quả thực hiện", "tinh_hinh_ket_qua_thuc_hien"], label: "Tình hình, kết quả thực hiện" },
    { keys: ["LĐ UBND", "ld_dang_uy"], label: "LĐ UBND" },
    { keys: ["LĐ Văn phòng UBND", "ld_van_phong_dang_uy"], label: "LĐ Văn phòng UBND" },
    { keys: ["Phòng ban chuyên môn", "ban_chuyen_mon"], label: "Phòng ban chuyên môn" },
    { keys: ["Chuyên viên theo dõi", "chuyen_vien_theo_doi"], label: "Chuyên viên theo dõi" },
  ];

  // ==========================================
  // 2b. NGUỒN NGÀY CHO BỘ LỌC "TỪ NGÀY - ĐẾN NGÀY"
  //   Một nhiệm vụ được giữ lại nếu CÓ ÍT NHẤT MỘT trong các mốc ngày dưới đây
  //   nằm trong khoảng lọc (Ngày giao / Hạn xử lý / Ngày hoàn thành).
  //   Muốn bỏ bớt mốc nào thì xóa cụm tương ứng khỏi mảng này.
  // ==========================================
  const DATE_FILTER_SOURCES = [
    {
      name: "Ngày giao",
      keys: ["Ngày giao", "ngay_giao", "Ngày ban hành", "ngay_ban_hanh", "Ngày văn bản", "ngay_van_ban"],
    },
    {
      name: "Hạn xử lý",
      keys: ["Hạn xử lý", "han_xu_ly", "Thời hạn", "thoi_han", "han"],
      fallbackLabel: "Thời hạn",
    },
    {
      name: "Ngày hoàn thành",
      keys: ["Ngày hoàn thành", "ngay_hoan_thanh", "Ngày kết thúc", "ngay_ket_thuc", "Ngày thực hiện xong", "ngay_thuc_hien_xong"],
    },
  ];

  const APP_CONFIG = {
    themeColor: activeTheme.c,
    titleColor: activeTheme.tc,
    title: currentTitle,
    targetStatus: activeTheme.match,
    // HEADER kiểu v12: nền xanh rất nhạt, chữ đậm màu tối, icon xám
    headerBg: "#cedef2",
    headerText: "#1E293B",
    headerIcon: "#5A6B84",
    headerLine: "#A9C3E4",
    columnsWithFilter: [
      "Nhóm nhiệm vụ", "Đơn vị thực hiện", "Thời hạn", "Tình trạng", "LĐ UBND", "LĐ Văn phòng UBND", "Phòng ban chuyên môn", "Văn bản giao"
    ],
    // Chỉ còn TT có mũi tên sắp xếp (bỏ ở Thời hạn, Tình trạng) — như v12
    columnsWithSort: ["TT"],
    // Sắp xếp ngầm định theo khóa yyyymmdd của cột Thời hạn (không hiện mũi tên)
    defaultSortCol: "Thời hạn",
    defaultSortOrder: "asc",
    searchableColumns: [
      "Nhóm nhiệm vụ",
      "Văn bản giao",
      "Nội dung nhiệm vụ",
      "Đơn vị thực hiện",
      "Tình hình, kết quả thực hiện",
    ],
    defaultPageSize: 20,
  };

  if (!rootEl.filterState) rootEl.filterState = {};
  if (!rootEl.sortState) rootEl.sortState = { col: null, order: null };
  if (typeof rootEl.searchKeyword === "undefined") rootEl.searchKeyword = "";
  if (typeof rootEl.currentPage === "undefined") rootEl.currentPage = 1;
  if (typeof rootEl.pageSize === "undefined")
    rootEl.pageSize = APP_CONFIG.defaultPageSize;
  // TRẠNG THÁI BỘ LỌC THỜI GIAN (khóa yyyymmdd, null = không lọc)
  if (typeof rootEl.dateFrom === "undefined") rootEl.dateFrom = null;
  if (typeof rootEl.dateTo === "undefined") rootEl.dateTo = null;
  // Mốc dùng để lọc: "all" = bất kỳ mốc nào, hoặc đúng tên một mốc trong DATE_FILTER_SOURCES
  if (typeof rootEl.dateMode === "undefined")
    rootEl.dateMode = getURLParam("moc_thoi_gian") || "all";

  // ==========================================
  // 3. CÁC HÀM BỔ TRỢ & ICON SVG
  // ==========================================
  // Chuẩn hóa chuỗi để so khớp tham số URL (bỏ dấu cách thừa, không phân biệt hoa/thường)
  function normText(v) {
    let s = String(v === null || v === undefined ? "" : v);
    if (typeof s.normalize === "function") s = s.normalize("NFC");
    return s.replace(/\s+/g, " ").trim().toLowerCase();
  }

  // Đổi dấu "|" (có hoặc không có khoảng trắng quanh) thành ", "
  // Chỉ xử lý chuỗi; số / null / undefined giữ nguyên
  function fixPipe(v) {
    if (v === null || v === undefined) return v;
    if (typeof v !== "string") return v;
    return v.replace(/\s*\|\s*/g, ", ");
  }

  // Giá trị coi như "không lọc" (link lớp 1 truyền rỗng hoặc chọn tất cả)
  function isEmptyParam(v) {
    const k = normText(v);
    return k === "" || k === "all" || k === "tất cả" || k === "toàn bộ" || k === "__all__";
  }

  function isDateColumn(colLabel) {
    const lower = String(colLabel).toLowerCase();
    return lower.indexOf("ngày") > -1 || lower.indexOf("thời hạn") > -1;
  }

  function formatTimestamp(ts) {
    const num = Number(ts);
    if (isNaN(num) || num === 0) return "";
    const date = new Date(num > 9999999999 ? num : num * 1000);
    if (isNaN(date.getTime())) return ts;

    const d = String(date.getDate()).padStart(2, "0");
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const y = date.getFullYear();
    return d + "/" + m + "/" + y;
  }

  // Đổi chuỗi "dd/mm/yyyy" thành số yyyymmdd để sắp xếp đúng thứ tự thời gian
  function dateSortKey(str) {
    const m = String(str).trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (!m) return null;
    return Number(m[3]) * 10000 + Number(m[2]) * 100 + Number(m[1]);
  }

  // Đổi MỌI dạng ngày (timestamp / dd-mm-yyyy / dd/mm/yyyy / yyyy-mm-dd) thành số yyyymmdd
  function toDateKey(v) {
    if (v === null || v === undefined || v === "") return null;
    const s = String(v).trim();
    if (s === "") return null;

    if (!isNaN(Number(s)) && Number(s) > 10000000) {
      const num = Number(s);
      const d = new Date(num > 9999999999 ? num : num * 1000);
      if (isNaN(d.getTime())) return null;
      return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
    }

    let m = s.match(/^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})/);
    if (m) return Number(m[3]) * 10000 + Number(m[2]) * 100 + Number(m[1]);

    m = s.match(/^(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})/);
    if (m) return Number(m[1]) * 10000 + Number(m[2]) * 100 + Number(m[3]);

    return null;
  }

  // Khóa yyyymmdd của một dòng theo cột ngày (ưu tiên chuỗi đã format, dự phòng timestamp gốc)
  function getDateKeyOfRow(row, colLabel) {
    const k = dateSortKey(row[colLabel]);
    if (k !== null) return k;
    const ts = row[colLabel + "_rawTS"];
    if (ts !== undefined && ts !== null && !isNaN(Number(ts))) {
      const num = Number(ts);
      const d = new Date(num > 9999999999 ? num : num * 1000);
      if (!isNaN(d.getTime())) {
        return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
      }
    }
    return null;
  }

  function getUniqueValues(colLabel) {
    const map = {};
    for (let i = 0; i < data.length; i++) {
      const val = data[i][colLabel];
      if (val !== undefined && val !== null && String(val).trim() !== "") {
        map[String(val).trim()] = true;
      }
    }
    const keys = Object.keys(map);

    // Cột ngày tháng: sắp xếp theo thời gian, không sắp xếp theo chuỗi
    if (isDateColumn(colLabel)) {
      return keys.sort(function (a, b) {
        const ka = dateSortKey(a);
        const kb = dateSortKey(b);
        if (ka === null && kb === null) return a < b ? -1 : a > b ? 1 : 0;
        if (ka === null) return 1;
        if (kb === null) return -1;
        return ka - kb;
      });
    }
    return keys.sort();
  }

  // =========================================================================
  // LOGIC PHÂN LOẠI TRẠNG THÁI NGHIỆP VỤ CHUẨN XÁC 100%
  // =========================================================================
  function getStatusType(row) {
    if (!row) return null;
    if (row["_stKey"]) return row["_stKey"];   // đã chuẩn hóa ở bước nạp dữ liệu
    let stText = String(row["Tình trạng"] || row["tinh_trang"] || "")
      .toLowerCase()
      .trim();
    if (typeof stText.normalize === "function")
      stText = stText.normalize("NFC");

    // 0. UNKNOWN: Chưa xác định
    if (stText.indexOf("chưa xác định") > -1) return "unknown";

    // 1. RECURRING: Thường xuyên (Thay thế warn)
    if (stText.indexOf("thường xuyên") > -1) return "recurring";

    // 2. LATE: Đang TH quá hạn / Chưa hoàn thành quá hạn
    if ((stText.indexOf("quá hạn") > -1 && stText.indexOf("chưa") > -1) || stText.indexOf("đang thực hiện quá hạn") > -1) return "late";

    // 3. OK: Đã hoàn thành (trong hạn)
    if (stText.indexOf("đã hoàn thành") > -1 || stText.indexOf("đúng hạn") > -1) return "ok";

    // 4. RUN: Đang TH trong hạn / Chưa hoàn thành trong hạn
    if (stText.indexOf("chưa hoàn thành") > -1 || stText.indexOf("đang thực hiện trong hạn") > -1 || stText.indexOf("trong hạn") > -1) return "run";

    return null;
  }

  function getBadgeHtml(row, text) {
    const statusType = getStatusType(row);
    if (!statusType) {
      return text ? '<span class="status-badge badge-default">' + text + "</span>" : "";
    }
    const m = ST_META[statusType] || ST_META.unknown;
    return (
      '<span class="status-badge" style="color:' + m.c +
      ";background:" + m.c + "1f;border-color:" + m.c + '55;">' + m.n + "</span>"
    );
  }

  // ICON: đổi từ trắng sang màu tối / màu theme cho hợp header nền sáng (kiểu v12)
  function SvgFilter(isActive) {
    return (
      '<svg style="width:11px;height:11px;color:' +
      (isActive ? APP_CONFIG.themeColor : APP_CONFIG.headerIcon) +
      ';" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"></polygon></svg>'
    );
  }
  function SvgSortUp(isActive) {
    return (
      '<svg style="width:10px;height:10px;color:' +
      (isActive ? APP_CONFIG.themeColor : APP_CONFIG.headerIcon) +
      ';fill:currentColor;margin-bottom:-3px;" viewBox="0 0 1024 1024"><path d="M858.9 689L530.5 308.2c-9.4-10.9-27.5-10.9-37 0L165.1 689c-12.2 14.2-1.2 35 18.5 35h656.8c19.7 0 30.7-20.8 18.5-35z"/></svg>'
    );
  }
  function SvgSortDown(isActive) {
    return (
      '<svg style="width:10px;height:10px;color:' +
      (isActive ? APP_CONFIG.themeColor : APP_CONFIG.headerIcon) +
      ';fill:currentColor;" viewBox="0 0 1024 1024"><path d="M840.4 300H183.6c-19.7 0-30.7 20.8-18.5 35l328.4 380.8c9.4 10.9 27.5 10.9 37 0L858.9 335c12.2-14.2 1.2-35-18.5-35z"/></svg>'
    );
  }
  const ThreeDotsIcon = (color) =>
    `<svg style="width:20px;height:20px;color:${color};flex-shrink:0;" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
      <polyline points="7 10 12 15 17 10"></polyline>
      <line x1="12" y1="15" x2="12" y2="3"></line>
    </svg>`;

  function getExportCellValue(row, colLabel, idx) {
    if (colLabel === "TT") return String(idx + 1);
    return row[colLabel] !== null && row[colLabel] !== undefined
      ? String(row[colLabel])
      : "";
  }

  function exportToCSV() {
    const exportData = rootEl.currentViewData || data;
    let csvContent = "\uFEFF";
    const headers = DISPLAY_COLUMNS.map((c) => c.label);
    csvContent += headers.join(",") + "\n";
    exportData.forEach((row, idx) => {
      let rowData = headers.map((colLabel) => {
        const cellVal = getExportCellValue(row, colLabel, idx);
        return `"${cellVal.replace(/"/g, '""')}"`;
      });
      csvContent += rowData.join(",") + "\n";
    });

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = "Danh_sach_nhiem_vu_giao_gop.csv";
    link.click();
  }

  function exportToExcel() {
    const exportData = rootEl.currentViewData || data;
    let tableHtml = `<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
        <head><meta charset="utf-8"></head><body><table border="1">`;
    tableHtml +=
      "<tr>" +
      DISPLAY_COLUMNS.map(
        (col) => `<th style="background-color:#f2f2f2;">${col.label}</th>`,
      ).join("") +
      "</tr>";
    exportData.forEach((row, idx) => {
      tableHtml +=
        "<tr>" +
        DISPLAY_COLUMNS.map(
          (col) => `<td>${getExportCellValue(row, col.label, idx)}</td>`,
        ).join("") +
        "</tr>";
    });
    tableHtml += "</table></body></html>";

    const blob = new Blob([tableHtml], { type: "application/vnd.ms-excel" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = "Danh_sach_nhiem_vu_giao_gop.xls";
    link.click();
  }

  // ==========================================
  // 4. CHUẨN HÓA DỮ LIỆU SANG ĐÚNG 14 CỘT — GIỮ NGUYÊN
  // ==========================================
  let rawIncomingData =
    queryData &&
    queryData.data &&
    queryData.data.length > 0 &&
    !Object.values(queryData.data[0]).every((v) => v === "")
      ? queryData.data
      : [];

  // Số dòng thực sự có dữ liệu của từng mốc -> dùng để khóa lựa chọn không có dữ liệu
  const DATE_AVAIL = {};
  DATE_FILTER_SOURCES.forEach(function (g) { DATE_AVAIL[g.name] = 0; });

  let data = [];
  for (let i = 0; i < rawIncomingData.length; i++) {
    let row = Object.assign({}, rawIncomingData[i]);
    let normalizedRow = {};

    for (let j = 0; j < DISPLAY_COLUMNS.length; j++) {
      const col = DISPLAY_COLUMNS[j];
      let val = "";

      for (let k = 0; k < col.keys.length; k++) {
        const candidateKey = col.keys[k];
        if (row[candidateKey] !== undefined && row[candidateKey] !== null) {
          val = row[candidateKey];
          break;
        }
      }

      if (val === "" && col.label.indexOf("...") > -1) {
          const prefix = col.label.replace("...", "");
          for (let rawKey in row) {
              if (rawKey.startsWith(prefix)) {
                  val = row[rawKey];
                  break;
              }
          }
      }

      // Dự phòng: nhãn hiển thị khác tên cột nguồn -> dò theo tiền tố (vd "Lãnh đạo ...")
      if (val === "" && col.prefixMatch) {
          for (let rawKey in row) {
              if (
                  String(rawKey).indexOf(col.prefixMatch) === 0 &&
                  row[rawKey] !== null &&
                  row[rawKey] !== undefined &&
                  String(row[rawKey]).trim() !== ""
              ) {
                  val = row[rawKey];
                  break;
              }
          }
      }

      if (val !== null && val !== undefined && val !== "") {
        if (
          isDateColumn(col.label) &&
          !isNaN(Number(val)) &&
          Number(val) > 10000000
        ) {
          normalizedRow[col.label + "_rawTS"] = Number(val);
          val = formatTimestamp(val);
        }
      }
      // ĐỔI "|" -> ", " cho mọi cột (Đơn vị thực hiện, LĐ đơn vị..., Phòng ban...)
      normalizedRow[col.label] = fixPipe(val);
    }

    // TÌNH TRẠNG: quy về nhãn chuẩn (Đã hoàn thành / Đang TH trong hạn / Đang TH quá hạn / Thường xuyên)
    const stKey = getStatusType({ "Tình trạng": normalizedRow["Tình trạng"] });
    if (stKey) {
      normalizedRow["_stKey"] = stKey;
      normalizedRow["Tình trạng"] = ST_META[stKey].n;
    }

    // KHÓA NHIỆM VỤ GỘP: bấm ô "Nội dung nhiệm vụ" -> mở danh sách chi tiết nhiệm vụ giao theo id_cha
    normalizedRow["_id_cha"] =
      row["id_cha"] !== undefined && row["id_cha"] !== null ? String(row["id_cha"]) : "";

    normalizedRow["chuc_danh"] = row["Chức danh"] || row["chuc_danh"] || "";
    normalizedRow["loai_van_ban"] = row["Loại văn bản"] || row["loai_van_ban"] || "";
    normalizedRow["nguoi_giao_nhiem_vu"] = row["nguoi_giao_nhiem_vu"] || row["Người giao nhiệm vụ"] || "";
    // GIÁ TRỊ DÙNG ĐỂ SO KHỚP THAM SỐ don_vi_thuc_hien={don_vi_chu_tri} TỪ LỚP 1
    // (cũng đổi "|" -> ", " để khớp với urlDVTH đã chuẩn hóa)
    normalizedRow["don_vi_thuc_hien_filter"] = fixPipe(
      row["don_vi_chu_tri"] ||
      row["Đơn vị chủ trì"] ||
      row["ten_don_vi_chu_tri"] ||
      row["Đơn vị thực hiện"] ||
      row["to_chuc_dang_chu_tri"] ||
      row["don_vi_thuc_hien"] ||
      ""
    );

    // ===== KHÓA NGÀY PHỤC VỤ BỘ LỌC "TỪ NGÀY - ĐẾN NGÀY" =====
    // _dateKeys = [yyyymmdd của Ngày giao, Hạn xử lý, Ngày hoàn thành] (bỏ qua mốc rỗng)
    const dateKeys = [];
    const dateKeyMap = {};
    for (let g = 0; g < DATE_FILTER_SOURCES.length; g++) {
      const grp = DATE_FILTER_SOURCES[g];
      let dv = "";
      for (let k = 0; k < grp.keys.length; k++) {
        const dk = grp.keys[k];
        if (row[dk] !== undefined && row[dk] !== null && String(row[dk]).trim() !== "") {
          dv = row[dk];
          break;
        }
      }
      // Dự phòng: lấy lại từ cột đã chuẩn hóa (vd "Thời hạn" đã format dd/mm/yyyy)
      if (dv === "" && grp.fallbackLabel) dv = normalizedRow[grp.fallbackLabel] || "";
      const key = toDateKey(dv);
      if (key !== null) {
        dateKeys.push(key);
        dateKeyMap[grp.name] = key;
        DATE_AVAIL[grp.name]++;
      }
    }
    normalizedRow["_dateKeys"] = dateKeys;
    normalizedRow["_dateKeyMap"] = dateKeyMap;

    data.push(normalizedRow);
  }

  // Khởi tạo bộ lọc thời gian từ URL nếu lớp 1 truyền xuống (tu_ngay / den_ngay: yyyy-mm-dd hoặc dd/mm/yyyy)
  const urlFromRaw = getURLParam("tu_ngay") || getURLParam("from_date");
  const urlToRaw = getURLParam("den_ngay") || getURLParam("to_date");
  if (rootEl.dateFrom === null && urlFromRaw) rootEl.dateFrom = toDateKey(urlFromRaw);
  if (rootEl.dateTo === null && urlToRaw) rootEl.dateTo = toDateKey(urlToRaw);
  // Đổi khóa yyyymmdd -> "yyyy-mm-dd" để gán vào ô <input type="date">
  function dateKeyToInput(k) {
    if (!k) return "";
    const s = String(k);
    if (s.length !== 8) return "";
    return s.slice(0, 4) + "-" + s.slice(4, 6) + "-" + s.slice(6, 8);
  }

  // ==========================================
  // 5. CSS — HEADER SỬA THEO MẪU v12 (nền sáng, chữ tối, viền trên theo màu trạng thái)
  // ==========================================
  const styleEl0 = document.getElementById("style-" + wrapperId);
  if (styleEl0) styleEl0.parentNode.removeChild(styleEl0);
  {
    const style = document.createElement("style");
    style.id = "style-" + wrapperId;
    style.innerHTML = `
      #${wrapperId} { width: 100%; height: 100%; background-color: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 12px; display: flex; flex-direction: column; font-family: 'Inter', -apple-system, sans-serif; position: relative; box-sizing: border-box; }
      #${wrapperId} * { box-sizing: border-box; }
      
      /* TOOLBAR kiểu v12: nền trắng, nút quay lại + tiêu đề in hoa + số nhiệm vụ */
      #${wrapperId} .tbl-toolbar { display: flex; align-items: center; justify-content: space-between; padding: 10px 16px; background-color: #FFFFFF; border-bottom: 1px solid #E5EAF2; border-radius: 12px 12px 0 0; flex-wrap: wrap; gap: 12px; }
      #${wrapperId} .toolbar-left { display: flex; align-items: center; gap: 12px; min-width: 0; }
      #${wrapperId} .l2-btn { width: 34px; height: 34px; flex: 0 0 34px; border-radius: 8px; cursor: pointer; background: #FFFFFF; border: 1px solid #D9E0EC; box-shadow: 0 1px 2px rgba(16,32,64,.06), 0 2px 6px rgba(16,32,64,.05); color: #3D4759; display: grid; place-items: center; padding: 0; transition: background .18s, color .18s, border-color .18s, box-shadow .18s, transform .18s; }
      #${wrapperId} .l2-btn:hover { background: #F7F9FD; color: ${APP_CONFIG.themeColor}; border-color: ${APP_CONFIG.themeColor}; box-shadow: 0 2px 4px rgba(16,32,64,.10), 0 6px 14px rgba(16,32,64,.08); transform: translateY(-1px); }
      #${wrapperId} .l2-btn:active { transform: translateY(0); box-shadow: 0 1px 2px rgba(16,32,64,.10) inset; }
      #${wrapperId} .l2-btn svg { width: 16px; height: 16px; display: block; }
      #${wrapperId} .l2-title { display: flex; align-items: baseline; gap: 10px; min-width: 0; flex: 1 1 auto; overflow: hidden; }
      #${wrapperId} .l2-title h2 { margin: 0; font-size: 16.5px; font-weight: 900; letter-spacing: .2px; color: ${APP_CONFIG.titleColor}; text-transform: uppercase; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; min-width: 0; -webkit-text-stroke: .35px ${APP_CONFIG.titleColor}; text-shadow: 0 0 .35px ${APP_CONFIG.titleColor}; }
      #${wrapperId} .l2-count { font-size: 13px; font-weight: 600; color: #7A879B; white-space: nowrap; }
      #${wrapperId} .toolbar-actions { display: flex; align-items: center; gap: 10px; }
      #${wrapperId} .search-input { width: 320px; max-width: 100%; height: 32px; padding: 0 12px; font-size: 12.5px; color: #1E293B; border: 1px solid #CBD5E1; border-radius: 6px; outline: none; background-color: #FFFFFF; }
      #${wrapperId} .search-input:focus { border-color: ${APP_CONFIG.themeColor}; }

      /* BỘ LỌC THỜI GIAN: Từ ngày - Đến ngày */
      #${wrapperId} .date-filter { display: flex; align-items: center; gap: 6px; height: 32px; padding: 0 8px; border: 1px solid #CBD5E1; border-radius: 6px; background: #FFFFFF; }
      #${wrapperId} .date-filter.on { border-color: ${APP_CONFIG.themeColor}; box-shadow: 0 0 0 2px ${APP_CONFIG.themeColor}1a; }
      #${wrapperId} .date-label { font-size: 11.5px; font-weight: 600; color: #5B6B83; white-space: nowrap; }
      #${wrapperId} .date-input { height: 24px; padding: 0 6px; font-family: inherit; font-size: 12px; color: #1E293B; border: 1px solid #E2E8F0; border-radius: 4px; outline: none; background: #FFFFFF; cursor: pointer; }
      #${wrapperId} .date-input:focus { border-color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .date-sep { font-size: 12px; color: #A3AFC0; }
      #${wrapperId} .date-mode { height: 24px; padding: 0 4px; font-family: inherit; font-size: 11.5px; font-weight: 600; color: #1E293B; border: 1px solid #E2E8F0; border-radius: 4px; outline: none; background: #FFFFFF; cursor: pointer; }
      #${wrapperId} .date-mode:focus { border-color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .date-apply { width: 22px; height: 22px; display: grid; place-items: center; border-radius: 4px; color: #5B6B83; cursor: pointer; border: 1px solid transparent; transition: all .15s; }
      #${wrapperId} .date-apply:hover { background: #EAF2FE; color: ${APP_CONFIG.themeColor}; border-color: ${APP_CONFIG.themeColor}; }
      /* Có thay đổi chưa áp dụng -> nút sáng màu để nhắc bấm */
      #${wrapperId} .date-apply.pending { background: ${APP_CONFIG.themeColor}; color: #FFFFFF; border-color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .date-apply svg { display: block; }
      #${wrapperId} .date-clear { width: 20px; height: 20px; display: grid; place-items: center; border-radius: 4px; color: #8A99AE; cursor: pointer; font-size: 13px; line-height: 1; }
      #${wrapperId} .date-clear:hover { background: #F1F5F9; color: ${APP_CONFIG.themeColor}; }
      
      /* Ô NỔI HIỂN THỊ SỐ NHIỆM VỤ -> mở bảng thống kê theo đơn vị */
      #${wrapperId} .stats-chip { flex: 0 0 auto; display: flex; align-items: center; gap: 7px; height: 32px; padding: 0 11px; border: 1px solid #CBD5E1; border-radius: 6px; background: #FFFFFF; cursor: pointer; user-select: none; transition: all .18s; }
      #${wrapperId} .stats-chip:hover { background: #F7F9FD; border-color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .stats-chip.on { border-color: ${APP_CONFIG.themeColor}; box-shadow: 0 0 0 2px ${APP_CONFIG.themeColor}1a; }
      #${wrapperId} .stats-chip svg { width: 14px; height: 14px; color: ${APP_CONFIG.themeColor}; flex: 0 0 14px; }
      #${wrapperId} .stats-chip .sc-num { font-size: 13px; font-weight: 800; color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .stats-chip .sc-unit { font-size: 11.5px; font-weight: 600; color: #5B6B83; white-space: nowrap; }

      #statsov-${elementId} { position: fixed; inset: 0; z-index: 99997; display: none; background: transparent; }
      #statspanel-${elementId} { position: fixed; z-index: 99998; display: none; flex-direction: column; width: 820px; max-width: calc(100vw - 24px); max-height: 70vh; background: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 10px; box-shadow: 0 12px 32px rgba(16,32,64,.20); font-family: 'Inter', -apple-system, Segoe UI, Roboto, sans-serif; overflow: hidden; text-align: left; }
      #statspanel-${elementId} * { box-sizing: border-box; }
      #statspanel-${elementId} .sp-head { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border-bottom: 1px solid #EAEFF6; background: #F8FAFD; }
      #statspanel-${elementId} .sp-title { font-size: 12.5px; font-weight: 800; color: ${APP_CONFIG.titleColor}; text-transform: uppercase; letter-spacing: .3px; white-space: nowrap; }
      #statspanel-${elementId} .sp-sub { margin-left: auto; font-size: 11.5px; font-weight: 600; color: #7A879B; white-space: nowrap; }
      #statspanel-${elementId} .sp-btn { width: 26px; height: 26px; flex: 0 0 26px; display: grid; place-items: center; border: 1px solid #D9E0EC; border-radius: 6px; color: #4A5C75; cursor: pointer; background: #FFFFFF; }
      #statspanel-${elementId} .sp-btn:hover { color: ${APP_CONFIG.themeColor}; border-color: ${APP_CONFIG.themeColor}; background: #F1F5F9; }
      #statspanel-${elementId} .sp-btn svg { width: 14px; height: 14px; display: block; }
      #statspanel-${elementId} .sp-body { overflow: auto; }
      #statspanel-${elementId} .sp-body::-webkit-scrollbar { width: 8px; height: 8px; }
      #statspanel-${elementId} .sp-body::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 4px; }
      /* table-layout: fixed -> cột Đơn vị chiếm phần lớn bề ngang, cột số co gọn */
      #statspanel-${elementId} table { width: 100%; border-collapse: collapse; font-size: 12px; table-layout: fixed; }
      #statspanel-${elementId} th { position: sticky; top: 0; background: #FFFFFF; padding: 10px 10px; font-size: 10.5px; font-weight: 700; color: #7A879B; text-transform: uppercase; letter-spacing: .2px; border-bottom: 1px solid #E6ECF5; text-align: right; white-space: normal; line-height: 1.3; }
      #statspanel-${elementId} th:first-child { text-align: left; width: 44%; min-width: 300px; }
      #statspanel-${elementId} th:last-child, #statspanel-${elementId} td:last-child { width: 72px; }
      #statspanel-${elementId} td { padding: 9px 10px; border-bottom: 1px solid #F3F6FB; color: #1E293B; text-align: right; white-space: nowrap; }
      #statspanel-${elementId} td:first-child { text-align: left; font-weight: 600; white-space: normal; word-wrap: break-word; line-height: 1.4; }
      #statspanel-${elementId} tbody tr:hover td { background: #FAFCFF; }
      #statspanel-${elementId} tr.sp-total td { font-weight: 800; background: #F8FAFD; border-top: 1px solid #E2E8F0; border-bottom: none; }
      #statspanel-${elementId} .sp-zero { color: #C7CFDA; }
      #statspanel-${elementId} .sp-empty { padding: 28px; text-align: center; color: #8A99AE; font-size: 12.5px; font-style: italic; }

      #${wrapperId} .export-wrap { position: relative; display: inline-block; }
      #${wrapperId} .export-btn { display: flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 6px; cursor: pointer; color: #4A5C75; border: 1px solid #CBD5E1; background: #FFFFFF; transition: all 0.2s; }
      #${wrapperId} .export-btn:hover { background-color: #F1F5F9; color: ${APP_CONFIG.themeColor}; border-color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .export-menu { position: absolute; top: calc(100% + 4px); right: 0; background: #FFFFFF; min-width: 160px; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); z-index: 105; border: 1px solid #E2E8F0; display: none; flex-direction: column; padding: 4px 0; }
      #${wrapperId} .export-item { padding: 8px 14px; font-size: 12.5px; font-weight: 600; color: #334155; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: background 0.2s; }
      #${wrapperId} .export-item:hover { background-color: #F8FAFC; color: ${APP_CONFIG.themeColor}; }

      #${wrapperId} .tbl-container { flex: 1; overflow-y: auto; overflow-x: auto; min-height: 0; height: 100%; position: relative; }
      #${wrapperId} .tbl-container::-webkit-scrollbar { width: 8px; height: 8px; }
      #${wrapperId} .tbl-container::-webkit-scrollbar-track { background: #F1F5F9; }
      #${wrapperId} .tbl-container::-webkit-scrollbar-thumb { background: #CBD5E1; border-radius: 4px; }
      #${wrapperId} table { width: 100%; border-collapse: separate; border-spacing: 0; text-align: left; }
      
      /* THEAD kiểu v12: nền #EEF3FA, chữ tối, viền trên 3px theo màu trạng thái, canh giữa */
      #${wrapperId} thead th { position: sticky; top: 0; background-color: ${APP_CONFIG.headerBg}; padding: 12px; font-size: 11.5px; font-weight: 700; color: ${APP_CONFIG.headerText}; border-top: 4px solid ${APP_CONFIG.themeColor}; border-bottom: 1px solid ${APP_CONFIG.headerLine}; border-right: 1px solid ${APP_CONFIG.headerLine}; z-index: 10; text-align: center; vertical-align: middle; }
      #${wrapperId} thead th:last-child { border-right: none; }
      #${wrapperId} .th-wrap { position: relative; display: flex; align-items: center; justify-content: center; min-height: 20px; padding-right: 26px; cursor: pointer; user-select: none; }
      #${wrapperId} .th-wrap span { display: block; width: 100%; word-wrap: break-word; text-align: center; }
      #${wrapperId} .th-actions { position: absolute; top: 50%; right: -8px; transform: translateY(-50%); display: flex; align-items: center; gap: 2px; flex-shrink: 0; }
      #${wrapperId} .sort-btns { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 18px; cursor: pointer; }
      #${wrapperId} .filter-btn { display: flex; align-items: center; justify-content: center; width: 22px; height: 22px; border-radius: 4px; cursor: pointer; }
      #${wrapperId} .filter-btn:hover { background-color: #B6CDE9; }

      /* Header không có nút lọc/sắp xếp thì bỏ khoảng chừa 26px bên phải */
      #${wrapperId} thead th .th-wrap.no-actions { padding-right: 0; }
      /* Tên trường nằm gọn trên 1 dòng, cột tự co vừa đủ theo tiêu đề */
      #${wrapperId} thead th .th-wrap.nowrap-head span { white-space: nowrap; word-wrap: normal; }

      /* CỐ ĐỊNH (FREEZE) CÁC CỘT BÊN TRÁI TỚI "Mã nhiệm vụ" */
      #${wrapperId} thead th.sticky-col { z-index: 20; }
      #${wrapperId} tbody td.sticky-col { position: sticky; z-index: 3; background-color: #FFFFFF; }
      #${wrapperId} tbody tr:nth-child(even) td.sticky-col { background-color: #FFFFFF; }
      #${wrapperId} tbody tr:hover td.sticky-col { background-color: #FAFAFA; }
      #${wrapperId} .sticky-edge { box-shadow: 2px 0 0 0 #DCE4EF, 8px 0 10px -8px rgba(16,32,64,.25); }

      /* CỘT TT: nới rộng + không cho tiêu đề xuống dòng */
      #${wrapperId} thead th.col-tt { padding-left: 8px; padding-right: 8px; }
      #${wrapperId} thead th.col-tt .th-wrap { padding-right: 18px; }
      #${wrapperId} thead th.col-tt .th-wrap span { white-space: nowrap; word-wrap: normal; }
      #${wrapperId} thead th.col-tt .th-actions { right: -4px; }

      #${wrapperId} tbody td { padding: 10px 12px; font-size: 12.5px; color: #334155; border-bottom: 1px solid #F0F0F0; vertical-align: top; line-height: 1.5; text-align: left; }
      #${wrapperId} tbody tr:hover td { background-color: #FAFAFA; }
      /* cursor: inherit -> chỉ ô link mới hiện con trỏ bàn tay */
      #${wrapperId} .col-truncate { width: 100%; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; cursor: inherit; }

      /* Ô "Nội dung nhiệm vụ": chữ xanh, gạch chân, CHỈ ô này bấm được để mở danh sách chi tiết nhiệm vụ giao */
      #${wrapperId} tbody td.link { color: #1f6fe0; font-weight: 600; cursor: pointer; text-decoration: underline; text-decoration-color: #bcd3f2; text-underline-offset: 2px; }
      #${wrapperId} tbody td.link:hover { color: #0f3d8c; text-decoration-color: #1f6fe0; background-color: #EAF2FE !important; }

      #${wrapperId} .status-badge { display: inline-flex; padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; white-space: nowrap; border: 1px solid transparent; }
      #${wrapperId} .badge-green { background-color: #DCFCE7; color: #16A34A; border: 1px solid #22C55E; }
      #${wrapperId} .badge-orange { background-color: #FFEDD5; color: #EA580C; border: 1px solid #F97316; }
      #${wrapperId} .badge-purple { background-color: #F4F0FD; color: #825EE4; border: 1px solid #825EE4; }
      #${wrapperId} .badge-blue { background-color: #DBEAFE; color: #2563EB; border: 1px solid #3B82F6; }
      #${wrapperId} .badge-red { background-color: #FEE2E2; color: #DC2626; border: 1px solid #EF4444; }
      #${wrapperId} .badge-gray { background-color: #F3F4F6; color: #4B5563; border: 1px solid #9CA3AF; }
      #${wrapperId} .badge-default { background-color: #F5F5F5; color: #595959; border: 1px solid #D9D9D9; }

      /* FOOTER — theo mẫu ds_nhiem_vu_nhan (.ft / .info / .pg) */
      #${wrapperId} .tbl-footer { height: 46px; flex: none; border-top: 1px solid #E2E8F0; display: flex; align-items: center; gap: 10px; padding: 0 14px; background: #fff; border-radius: 0 0 12px 12px; }
      #${wrapperId} .page-info { font-size: 11.5px; color: #5b6b83; white-space: nowrap; }
      #${wrapperId} .page-size-select { height: 28px; border: 1px solid #d5deea; border-radius: 5px; font: inherit; font-size: 12px; padding: 0 6px; color: #1a2b45; outline: none; cursor: pointer; background: #fff; }
      #${wrapperId} .page-controls { margin-left: auto; display: flex; align-items: center; gap: 4px; }
      #${wrapperId} .page-btn { min-width: 28px; height: 28px; padding: 0 8px; border: 1px solid #d5deea; border-radius: 5px; background: #fff; font: inherit; font-size: 12px; color: #46566e; cursor: pointer; }
      #${wrapperId} .page-btn:hover:not(:disabled) { border-color: ${APP_CONFIG.themeColor}; color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .page-btn.on { background: ${APP_CONFIG.themeColor}; border-color: ${APP_CONFIG.themeColor}; color: #fff; font-weight: 700; }
      #${wrapperId} .page-btn:disabled { opacity: .4; cursor: default; }

      #${wrapperId} .antd-dropdown-overlay { position: absolute; top: 0; left: 0; right: 0; bottom: 0; z-index: 100; display: none; background: transparent; }
      #${wrapperId} .antd-dropdown-menu { position: absolute; background: #FFF; min-width: 220px; max-width: 280px; border-radius: 6px; box-shadow: 0 6px 16px 0 rgba(0,0,0,0.08); z-index: 101; font-size: 13px; display: none; flex-direction: column; border: 1px solid #F0F0F0; text-align: left; }
      #${wrapperId} .dropdown-search-wrap { padding: 8px 12px; border-bottom: 1px solid #F0F0F0; }
      #${wrapperId} .dropdown-search-input { width: 100%; padding: 6px 8px; font-size: 12px; border: 1px solid #CBD5E1; border-radius: 4px; outline: none; text-align: left; }
      #${wrapperId} .antd-dropdown-list { max-height: 200px; overflow-y: auto; padding: 6px 0; }
      #${wrapperId} .antd-chk-item { display: flex; align-items: flex-start; padding: 6px 12px; cursor: pointer; user-select: none; line-height: 1.35; text-align: left; }
      /* Giá trị dài xuống nhiều dòng vẫn phải căn trái (tránh thừa kế text-align:center của khung Superset) */
      #${wrapperId} .antd-chk-item span { flex: 1 1 auto; min-width: 0; text-align: left; }
      #${wrapperId} .antd-chk-item input { flex: 0 0 auto; margin-right: 8px; margin-top: 1px; }
      #${wrapperId} .antd-select-all-line { border-bottom: 1px solid #F0F0F0; padding-bottom: 8px; margin-bottom: 6px; font-weight: bold; color: ${APP_CONFIG.themeColor}; }
      #${wrapperId} .antd-dropdown-footer { display: flex; justify-content: space-between; padding: 8px 12px; border-top: 1px solid #F0F0F0; background: #FAFAFA; border-radius: 0 0 6px 6px; }
      #${wrapperId} .antd-btn { padding: 4px 10px; font-size: 12px; border-radius: 4px; cursor: pointer; border: 1px solid transparent; font-weight: 600; }
      #${wrapperId} .antd-btn-reset { background: #FFFFFF; color: #1E293B; border-color: #D9D9D9; }
      #${wrapperId} .antd-btn-ok { background: ${APP_CONFIG.themeColor}; color: #FFF; }
    `;
    document.head.appendChild(style);
  }

  // ==========================================
  // 6. KHỞI TẠO BỘ KHUNG GIAO DIỆN CHÍNH
  // ==========================================
  if (!rootEl.querySelector("#" + wrapperId)) {
    // Ô nổi số nhiệm vụ — đứng ngay sau tiêu đề, thay cho dòng chữ "N nhiệm vụ"
    const statsChipHtml = `<div class="stats-chip" id="statschip-${elementId}">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
                <line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line>
              </svg>
              <span class="sc-num" id="scnum-${elementId}">0</span>
              <span class="sc-unit">nhiệm vụ</span>
            </div>`;

    const titleBarHtml = SHOW_TITLE_BAR
      ? `<div class="toolbar-left">
            <button class="l2-btn" id="btn-back-${elementId}" title="Quay lại lớp trước" aria-label="Quay lại lớp trước">
              <svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M13.5 8 H3.5 M7.5 3.5 L3 8 L7.5 12.5" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
            <div class="l2-title">
              <h2 title="${String(APP_CONFIG.title).replace(/"/g, "&quot;")}">${APP_CONFIG.title}</h2>
            </div>
            ${statsChipHtml}
          </div>`
      : `<div class="toolbar-left">${statsChipHtml}</div>`;

    // Danh sách mốc thời gian; mốc nào dataset không có sẽ bị khóa kèm chú thích
    const dateModeOptions =
      '<option value="all"' + (rootEl.dateMode === "all" ? " selected" : "") + ">Tất cả mốc</option>" +
      DATE_FILTER_SOURCES.map(function (g) {
        const n = DATE_AVAIL[g.name] || 0;
        return '<option value="' + String(g.name).replace(/"/g, "&quot;") + '"' +
          (rootEl.dateMode === g.name ? " selected" : "") +
          (n === 0 ? " disabled" : "") + ">" +
          g.name + (n === 0 ? " (không có dữ liệu)" : "") + "</option>";
      }).join("");

    rootEl.innerHTML = `
      <div id="${wrapperId}">
        <div class="antd-dropdown-overlay" id="overlay-${elementId}"></div>
        <div class="tbl-toolbar">
          ${titleBarHtml}
          <div class="toolbar-actions">
            <input type="text" id="search-${elementId}" class="search-input" placeholder="Tìm theo nhóm nhiệm vụ, nội dung..." autocomplete="off">
            
            <div class="date-filter" id="datefilter-${elementId}" title="Lọc theo Ngày giao / Hạn xử lý / Ngày hoàn thành">
              <select class="date-mode" id="dmode-${elementId}" title="Chọn mốc thời gian dùng để lọc">${dateModeOptions}</select>
              <span class="date-label">Từ ngày</span>
              <input type="date" class="date-input" id="dfrom-${elementId}" value="${dateKeyToInput(rootEl.dateFrom)}">
              <span class="date-sep">→</span>
              <span class="date-label">Đến ngày</span>
              <input type="date" class="date-input" id="dto-${elementId}" value="${dateKeyToInput(rootEl.dateTo)}">
              <div class="date-apply" id="dapply-${elementId}" title="Áp dụng bộ lọc thời gian">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
              </div>
              <div class="date-clear" id="dclear-${elementId}" title="Bỏ lọc thời gian">✕</div>
            </div>

            <div class="export-wrap">
              <div class="export-btn" id="btn-export-${elementId}" title="Xuất dữ liệu">
                ${ThreeDotsIcon("currentColor")}
              </div>
              <div class="export-menu" id="menu-export-${elementId}">
                <div class="export-item" id="export-csv-${elementId}">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                  Xuất sang .CSV 
                </div>
                <div class="export-item" id="export-xls-${elementId}">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><line x1="3" y1="9" x2="21" y2="9"></line><line x1="9" y1="21" x2="9" y2="9"></line></svg>
                  Xuất sang Excel
                </div>
              </div>
            </div>

          </div>
        </div>
        <div class="tbl-container">
          <table>
            <thead id="thead-${elementId}"></thead>
            <tbody id="tbody-${elementId}"></tbody>
          </table>
        </div>
        <div class="tbl-footer" id="footer-${elementId}"></div>
        <div id="dropdowns-${elementId}"></div>
      </div>
    `;

    const overlay = rootEl.querySelector("#overlay-" + elementId);
    overlay.addEventListener("click", function () {
      overlay.style.display = "none";
      const menus = rootEl.querySelectorAll(".antd-dropdown-menu");
      for (let i = 0; i < menus.length; i++) menus[i].style.display = "none";
      const exportMenu = rootEl.querySelector("#menu-export-" + elementId);
      if (exportMenu) exportMenu.style.display = "none";
    });

    rootEl
      .querySelector("#search-" + elementId)
      .addEventListener("input", function (e) {
        rootEl.searchKeyword = e.target.value.toLowerCase().trim();
        rootEl.currentPage = 1;
        renderTableDynamic();
      });

    // ===== SỰ KIỆN BỘ LỌC THỜI GIAN =====
    const dFromEl = rootEl.querySelector("#dfrom-" + elementId);
    const dToEl = rootEl.querySelector("#dto-" + elementId);
    const dClearEl = rootEl.querySelector("#dclear-" + elementId);
    const dWrapEl = rootEl.querySelector("#datefilter-" + elementId);

    const applyDateFilter = function () {
      rootEl.dateFrom = toDateKey(dFromEl.value);
      rootEl.dateTo = toDateKey(dToEl.value);
      // Chọn ngược (Từ > Đến) thì tự hoán đổi cho khỏi ra 0 kết quả
      if (rootEl.dateFrom && rootEl.dateTo && rootEl.dateFrom > rootEl.dateTo) {
        const tmp = rootEl.dateFrom;
        rootEl.dateFrom = rootEl.dateTo;
        rootEl.dateTo = tmp;
        dFromEl.value = dateKeyToInput(rootEl.dateFrom);
        dToEl.value = dateKeyToInput(rootEl.dateTo);
      }
      if (dWrapEl) {
        if (rootEl.dateFrom || rootEl.dateTo) dWrapEl.classList.add("on");
        else dWrapEl.classList.remove("on");
      }
      const dApplyBtn = rootEl.querySelector("#dapply-" + elementId);
      if (dApplyBtn) dApplyBtn.classList.remove("pending");
      rootEl.currentPage = 1;
      renderTableDynamic();
    };

    const dApplyEl = rootEl.querySelector("#dapply-" + elementId);
    // Chọn ngày CHƯA lọc ngay — chỉ đánh dấu chờ, bấm nút ✓ mới áp dụng
    const onDatePick = function () { if (dApplyEl) dApplyEl.classList.add("pending"); };
    dFromEl.addEventListener("change", onDatePick);
    dToEl.addEventListener("change", onDatePick);
    if (dApplyEl) dApplyEl.addEventListener("click", applyDateFilter);
    dClearEl.addEventListener("click", function () {
      dFromEl.value = "";
      dToEl.value = "";
      applyDateFilter();
    });

    const dModeEl = rootEl.querySelector("#dmode-" + elementId);
    if (dModeEl) {
      dModeEl.addEventListener("change", function () {
        rootEl.dateMode = this.value;
        rootEl.currentPage = 1;
        renderTableDynamic();
      });
    }
    if (rootEl.dateFrom || rootEl.dateTo) dWrapEl.classList.add("on");

    // MỞ DANH SÁCH CHI TIẾT NHIỆM VỤ GIAO:
    // CHỈ bấm vào ô "Nội dung nhiệm vụ" (td.link) -> handleClickChart({ id_cha })
    rootEl
      .querySelector("#tbody-" + elementId)
      .addEventListener("click", function (e) {
        const cellEl = e.target.closest("td.link");
        if (!cellEl) return;
        const rowEl = cellEl.closest("tr");
        const idCha = rowEl ? rowEl.getAttribute("data-idcha") || "" : "";
        if (!idCha) return;
        if (context && typeof context.handleClickChart === "function") {
          context.handleClickChart({ id_cha: idCha });
        }
      });

    // ==========================================
    // TOOLTIP Ô "NỘI DUNG NHIỆM VỤ" — gợi ý bấm để mở danh sách chi tiết
    //   Gắn vào document.body + position:fixed để không bị vùng cuộn của bảng cắt mất.
    // ==========================================
    const TIP_TEXT = "Bấm để xem danh sách chi tiết nhiệm vụ";
    const TIP_DELAY = 180; // ms — đủ nhanh để thấy, đủ trễ để không nháy khi lướt chuột
    const oldTip = document.getElementById("linktip-" + elementId);
    if (oldTip && oldTip.parentNode) oldTip.parentNode.removeChild(oldTip);

    const tipEl = document.createElement("div");
    tipEl.id = "linktip-" + elementId;
    tipEl.style.cssText =
      "position:fixed;z-index:99999;display:none;align-items:center;gap:6px;" +
      "padding:5px 9px;border-radius:6px;background:#1E293B;color:#fff;" +
      "font-family:'Inter',-apple-system,Segoe UI,Roboto,sans-serif;font-size:11.5px;font-weight:600;" +
      "line-height:1.2;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .12s ease;" +
      "box-shadow:0 4px 12px rgba(16,32,64,.28);";
    tipEl.innerHTML =
      '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="flex:0 0 12px;">' +
      '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>' +
      "<span>" + TIP_TEXT + "</span>";
    document.body.appendChild(tipEl);

    let tipTimer = null, tipCell = null;

    const tipTextEl = tipEl.querySelector("span");
    const placeTip = function (cell, text) {
      tipTextEl.textContent = text || TIP_TEXT;
      const r = cell.getBoundingClientRect();
      tipEl.style.display = "flex";
      const tw = tipEl.offsetWidth, th = tipEl.offsetHeight;
      let left = r.left + r.width / 2 - tw / 2;
      if (left < 6) left = 6;
      if (left + tw > window.innerWidth - 6) left = window.innerWidth - tw - 6;
      let top = r.top - th - 8;          // ưu tiên hiện phía trên ô
      if (top < 6) top = r.bottom + 8;   // không đủ chỗ thì lật xuống dưới
      tipEl.style.left = left + "px";
      tipEl.style.top = top + "px";
      tipEl.style.opacity = "1";
    };
    const hideTip = function () {
      clearTimeout(tipTimer);
      tipCell = null;
      tipEl.style.opacity = "0";
      tipEl.style.display = "none";
    };

    const tbodyEl = rootEl.querySelector("#tbody-" + elementId);
    tbodyEl.addEventListener("mouseover", function (e) {
      // CHỈ hiện tooltip khi rê vào ô link (Nội dung nhiệm vụ)
      const cell = e.target.closest("td.link");
      if (!cell) { if (tipCell) hideTip(); return; }
      if (cell === tipCell) return;
      clearTimeout(tipTimer);
      tipCell = cell;
      tipTimer = setTimeout(function () { if (tipCell === cell) placeTip(cell); }, TIP_DELAY);
    });
    tbodyEl.addEventListener("mouseout", function (e) {
      const to = e.relatedTarget;
      if (tipCell && to && tipCell.contains(to)) return;  // vẫn còn trong ô -> giữ tooltip
      hideTip();
    });
    tbodyEl.addEventListener("click", hideTip);
    const scrollHost = rootEl.querySelector(".tbl-container");
    if (scrollHost) scrollHost.addEventListener("scroll", hideTip);
    window.addEventListener("scroll", hideTip, true);

    // ==========================================
    // BẢNG THỐNG KÊ THEO ĐƠN VỊ (mở từ ô nổi số nhiệm vụ)
    //   Số liệu luôn tính trên DỮ LIỆU ĐANG HIỂN THỊ -> nhảy theo mọi bộ lọc.
    //   Đổi STATS_GROUP_COL nếu muốn gom nhóm theo cột khác.
    // ==========================================
    const STATS_GROUP_COL = "Đơn vị thực hiện";
    const STATS_TITLE = "THỐNG KÊ THEO ĐƠN VỊ";
    const chipEl = rootEl.querySelector("#statschip-" + elementId);
    const chipNumEl = rootEl.querySelector("#scnum-" + elementId);

    const oldPanel = document.getElementById("statspanel-" + elementId);
    if (oldPanel && oldPanel.parentNode) oldPanel.parentNode.removeChild(oldPanel);
    const oldStatsOv = document.getElementById("statsov-" + elementId);
    if (oldStatsOv && oldStatsOv.parentNode) oldStatsOv.parentNode.removeChild(oldStatsOv);

    const statsOv = document.createElement("div");
    statsOv.id = "statsov-" + elementId;
    document.body.appendChild(statsOv);

    const statsPanel = document.createElement("div");
    statsPanel.id = "statspanel-" + elementId;
    statsPanel.innerHTML =
      '<div class="sp-head">' +
        '<div class="sp-title">' + STATS_TITLE + "</div>" +
        '<div class="sp-sub" id="spsub-' + elementId + '"></div>' +
        '<div class="sp-btn" id="spdl-' + elementId + '" title="Tải bảng thống kê">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
          '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>' +
        "</div>" +
        '<div class="sp-btn" id="spclose-' + elementId + '" title="Đóng">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>' +
        "</div>" +
      "</div>" +
      '<div class="sp-body" id="spbody-' + elementId + '"></div>';
    document.body.appendChild(statsPanel);

    const spBodyEl = statsPanel.querySelector("#spbody-" + elementId);
    const spSubEl = statsPanel.querySelector("#spsub-" + elementId);

    // Gom nhóm theo đơn vị trên tập dữ liệu đang hiển thị
    function buildStats() {
      const rows = rootEl.currentViewData || [];
      const map = {};
      for (let i = 0; i < rows.length; i++) {
        const key = String(rows[i][STATS_GROUP_COL] || "").trim() || "(Chưa xác định đơn vị)";
        if (!map[key]) {
          map[key] = { dv: key, total: 0, ok: 0, run: 0, late: 0, recurring: 0, unknown: 0 };
        }
        const st = getStatusType(rows[i]) || "unknown";
        if (map[key][st] === undefined) map[key].unknown++;
        else map[key][st]++;
        map[key].total++;
      }
      return Object.keys(map)
        .map(function (k) { return map[k]; })
        .sort(function (a, b) {
          return b.total - a.total || a.dv.localeCompare(b.dv, "vi");
        });
    }

    const vnN = function (x) { return Number(x || 0).toLocaleString("vi-VN"); };
    const numCell = function (v, color) {
      return v > 0
        ? '<td style="color:' + color + ';font-weight:700;">' + vnN(v) + "</td>"
        : '<td class="sp-zero">—</td>';
    };

    function renderStats() {
      const stats = buildStats();
      const totalNV = stats.reduce(function (a, r) { return a + r.total; }, 0);
      spSubEl.textContent = vnN(stats.length) + " đơn vị · " + vnN(totalNV) + " nhiệm vụ";

      if (!stats.length) {
        spBodyEl.innerHTML = '<div class="sp-empty">Không có dữ liệu phù hợp với bộ lọc hiện tại</div>';
        return;
      }

      let head = "<tr><th>Đơn vị</th>";
      for (let i = 0; i < ST_ORDER.length; i++) head += "<th>" + ST_META[ST_ORDER[i]].n + "</th>";
      head += "<th>Tổng</th></tr>";

      let body = "";
      const sum = { ok: 0, run: 0, late: 0, recurring: 0, total: 0 };
      for (let i = 0; i < stats.length; i++) {
        const r = stats[i];
        body += "<tr><td>" + String(r.dv).replace(/&/g, "&amp;").replace(/</g, "&lt;") + "</td>";
        for (let j = 0; j < ST_ORDER.length; j++) {
          const k = ST_ORDER[j];
          body += numCell(r[k], ST_META[k].c);
          sum[k] += r[k];
        }
        body += '<td style="font-weight:700;">' + vnN(r.total) + "</td></tr>";
        sum.total += r.total;
      }

      let foot = '<tr class="sp-total"><td>Tổng cộng</td>';
      for (let j = 0; j < ST_ORDER.length; j++) {
        const k = ST_ORDER[j];
        foot += sum[k] > 0
          ? '<td style="color:' + ST_META[k].c + ';">' + vnN(sum[k]) + "</td>"
          : '<td class="sp-zero">—</td>';
      }
      foot += "<td>" + vnN(sum.total) + "</td></tr>";

      spBodyEl.innerHTML = "<table><thead>" + head + "</thead><tbody>" + body + foot + "</tbody></table>";
    }

    function placeStatsPanel() {
      const r = chipEl.getBoundingClientRect();
      statsPanel.style.display = "flex";
      const pw = statsPanel.offsetWidth, ph = statsPanel.offsetHeight;
      let left = r.right - pw;
      if (left < 8) left = 8;
      if (left + pw > window.innerWidth - 8) left = Math.max(8, window.innerWidth - pw - 8);
      let top = r.bottom + 8;
      if (top + ph > window.innerHeight - 8) {
        top = Math.max(8, r.top - ph - 8);          // không đủ chỗ dưới thì lật lên trên
      }
      statsPanel.style.left = left + "px";
      statsPanel.style.top = top + "px";
    }

    const closeStats = function () {
      statsPanel.style.display = "none";
      statsOv.style.display = "none";
      chipEl.classList.remove("on");
    };
    const openStats = function () {
      renderStats();
      statsOv.style.display = "block";
      placeStatsPanel();
      chipEl.classList.add("on");
    };

    chipEl.addEventListener("click", function () {
      hideTip();
      if (statsPanel.style.display === "flex") closeStats();
      else openStats();
    });
    chipEl.addEventListener("mouseenter", function () {
      clearTimeout(tipTimer);
      tipCell = chipEl;
      tipTimer = setTimeout(function () {
        if (tipCell === chipEl && statsPanel.style.display !== "flex") {
          placeTip(chipEl, "Bấm để xem theo đơn vị");
        }
      }, TIP_DELAY);
    });
    chipEl.addEventListener("mouseleave", hideTip);
    statsOv.addEventListener("click", closeStats);
    statsPanel.querySelector("#spclose-" + elementId).addEventListener("click", closeStats);
    window.addEventListener("resize", function () {
      if (statsPanel.style.display === "flex") placeStatsPanel();
    });

    // Tải bảng thống kê (.xls)
    statsPanel.querySelector("#spdl-" + elementId).addEventListener("click", function () {
      const stats = buildStats();
      if (!stats.length) return;
      let html = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">' +
        '<head><meta charset="utf-8"></head><body><table border="1"><tr>' +
        '<th style="background-color:#f2f2f2;">Đơn vị</th>';
      for (let i = 0; i < ST_ORDER.length; i++) html += '<th style="background-color:#f2f2f2;">' + ST_META[ST_ORDER[i]].n + "</th>";
      html += '<th style="background-color:#f2f2f2;">Tổng</th></tr>';
      const sum = { ok: 0, run: 0, late: 0, recurring: 0, total: 0 };
      stats.forEach(function (r) {
        html += "<tr><td>" + r.dv + "</td>";
        ST_ORDER.forEach(function (k) { html += "<td>" + r[k] + "</td>"; sum[k] += r[k]; });
        html += "<td>" + r.total + "</td></tr>";
        sum.total += r.total;
      });
      html += "<tr><td><b>Tổng cộng</b></td>";
      ST_ORDER.forEach(function (k) { html += "<td><b>" + sum[k] + "</b></td>"; });
      html += "<td><b>" + sum.total + "</b></td></tr></table></body></html>";

      const blob = new Blob([html], { type: "application/vnd.ms-excel" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "Thong_ke_theo_don_vi_" + Date.now() + ".xls";
      a.click();
    });

    // Cập nhật số trên ô nổi + làm mới bảng khi bộ lọc thay đổi
    rootEl.__statsRefresh = function () {
      const n = (rootEl.currentViewData || []).length;
      if (chipNumEl) chipNumEl.textContent = n.toLocaleString("vi-VN");
      if (statsPanel.style.display === "flex") { renderStats(); placeStatsPanel(); }
    };

    const backBtn = rootEl.querySelector("#btn-back-" + elementId);
    if (backBtn) {
      backBtn.addEventListener("click", function () {
        if (window.parent) {
          window.parent.postMessage("back-antd-modal", "*");
          window.parent.postMessage("close-antd-modal", "*");
        }
      });
    }

    const exportBtn = rootEl.querySelector("#btn-export-" + elementId);
    const exportMenu = rootEl.querySelector("#menu-export-" + elementId);

    exportBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      const isVisible = exportMenu.style.display === "flex";
      exportMenu.style.display = isVisible ? "none" : "flex";
      overlay.style.display = isVisible ? "none" : "block";
    });

    rootEl
      .querySelector("#export-csv-" + elementId)
      .addEventListener("click", function () {
        exportToCSV();
        exportMenu.style.display = "none";
        overlay.style.display = "none";
      });

    rootEl
      .querySelector("#export-xls-" + elementId)
      .addEventListener("click", function () {
        exportToExcel();
        exportMenu.style.display = "none";
        overlay.style.display = "none";
      });
  }

  // ==========================================
  // 7. HÀM RENDER NỘI DUNG ĐỘNG (TABLE + PAGINATION + AUTO FILTER TỪ URL)
  // ==========================================
  const renderTableDynamic = function () {
    let processedData = [];
    const filterCols = Object.keys(rootEl.filterState);

    const urlCD = getURLParam("chuc_danh"); 
    const urlDM = getURLParam("nguoi_giao_nhiem_vu"); 
    const urlLVB = getURLParam("loai_van_ban"); 
    // urlDVTH / urlDVTHKey đã lấy ở mục 2 (dùng chung cho tiêu đề và bộ lọc)

    for (let i = 0; i < data.length; i++) {
      let isMatch = true;

      if (APP_CONFIG.targetStatus && APP_CONFIG.targetStatus !== "all") {
        const statusType = getStatusType(data[i]);
        if (statusType !== APP_CONFIG.targetStatus) isMatch = false;
      }

      if (
        isMatch &&
        urlCD &&
        String(data[i]["chuc_danh"] || "").trim() !== urlCD
      ) {
        isMatch = false;
      }
      if (
        isMatch &&
        urlDM &&
        String(data[i]["nguoi_giao_nhiem_vu"] || "").trim() !== urlDM
      ) {
        isMatch = false;
      }
      if (
        isMatch &&
        urlLVB &&
        String(data[i]["loai_van_ban"] || "").trim() !== urlLVB
      ) {
        isMatch = false;
      }
      
      // LỌC THEO KIỂU LIKE (%giá trị%): chứa chuỗi là khớp, không cần bằng tuyệt đối
      if (isMatch && urlDVTHKey) {
        const dvFilter = normText(data[i]["don_vi_thuc_hien_filter"] || "");
        const dvShow = normText(data[i]["Đơn vị thực hiện"] || "");
        if (dvFilter.indexOf(urlDVTHKey) === -1 && dvShow.indexOf(urlDVTHKey) === -1) {
          isMatch = false;
        }
      }

      // ===== LỌC THỜI GIAN =====
      // "Tất cả mốc" = khớp bất kỳ mốc nào; ngược lại chỉ xét đúng mốc đã chọn
      if (isMatch && (rootEl.dateFrom || rootEl.dateTo)) {
        const dkMap = data[i]["_dateKeyMap"] || {};
        const dks =
          rootEl.dateMode === "all"
            ? data[i]["_dateKeys"] || []
            : dkMap[rootEl.dateMode] !== undefined
              ? [dkMap[rootEl.dateMode]]
              : [];
        let hitDate = false;
        for (let d = 0; d < dks.length; d++) {
          const k = dks[d];
          if (
            (!rootEl.dateFrom || k >= rootEl.dateFrom) &&
            (!rootEl.dateTo || k <= rootEl.dateTo)
          ) {
            hitDate = true;
            break;
          }
        }
        if (!hitDate) isMatch = false;
      }

      if (isMatch) processedData.push(data[i]);
    }

    let tempFilteredData = [];
    for (let i = 0; i < processedData.length; i++) {
      let isMatch = true;
      for (let j = 0; j < filterCols.length; j++) {
        const colLabel = filterCols[j];
        const selectedArr = rootEl.filterState[colLabel];
        if (selectedArr && selectedArr.length > 0) {
          const cellVal =
            processedData[i][colLabel] !== undefined &&
            processedData[i][colLabel] !== null
              ? String(processedData[i][colLabel]).trim()
              : "";
          if (selectedArr.indexOf(cellVal) === -1) {
            isMatch = false;
            break;
          }
        }
      }
      if (isMatch) tempFilteredData.push(processedData[i]);
    }
    processedData = tempFilteredData;

    if (rootEl.searchKeyword !== "") {
      const matchedData = [];
      const keyword = rootEl.searchKeyword;
      for (let i = 0; i < processedData.length; i++) {
        let isSearchMatch = false;
        for (let j = 0; j < DISPLAY_COLUMNS.length; j++) {
          const colLabel = DISPLAY_COLUMNS[j].label;
          const cellVal = processedData[i][colLabel];
          if (cellVal !== undefined && cellVal !== null) {
            if (String(cellVal).toLowerCase().indexOf(keyword) > -1) {
              isSearchMatch = true;
              break;
            }
          }
        }
        if (isSearchMatch) matchedData.push(processedData[i]);
      }
      processedData = matchedData;
    }

    if (rootEl.sortState.col) {
      const sc = rootEl.sortState.col;
      const order = rootEl.sortState.order;
      processedData.sort(function (a, b) {
        let valA =
          a[sc + "_rawTS"] !== undefined
            ? a[sc + "_rawTS"]
            : a[sc] !== undefined && a[sc] !== null
              ? String(a[sc]).trim()
              : "";
        let valB =
          b[sc + "_rawTS"] !== undefined
            ? b[sc + "_rawTS"]
            : b[sc] !== undefined && b[sc] !== null
              ? String(b[sc]).trim()
              : "";

        if (!isNaN(Number(valA)) && !isNaN(Number(valB))) {
          return order === "asc"
            ? Number(valA) - Number(valB)
            : Number(valB) - Number(valA);
        }
        if (valA < valB) return order === "asc" ? -1 : 1;
        if (valA > valB) return order === "asc" ? 1 : -1;
        return 0;
      });
    } else if (APP_CONFIG.defaultSortCol) {
      // SẮP XẾP MẶC ĐỊNH: dữ liệu vẫn xếp theo khóa yyyymmdd của cột Thời hạn,
      // nhưng header KHÔNG hiển thị biểu tượng mũi tên.
      const dsc = APP_CONFIG.defaultSortCol;
      const dso = APP_CONFIG.defaultSortOrder;
      processedData.sort(function (a, b) {
        const ka = getDateKeyOfRow(a, dsc);
        const kb = getDateKeyOfRow(b, dsc);
        if (ka === null && kb === null) return 0;
        if (ka === null) return 1; // dòng trống thời hạn luôn xuống cuối
        if (kb === null) return -1;
        return dso === "desc" ? kb - ka : ka - kb;
      });
    }

    const colStyles = {};
    for (let i = 0; i < DISPLAY_COLUMNS.length; i++) {
      const colLabel = DISPLAY_COLUMNS[i].label;
      const lowerCol = String(colLabel).toLowerCase();

      if (lowerCol === "tt") {
        // NỚI RỘNG CỘT TT: đủ chỗ cho chữ "TT" + nút sắp xếp, không xuống dòng
        colStyles[colLabel] = "width: 78px; min-width: 78px; max-width: 78px; text-align: center; white-space: nowrap;";
      } else if (lowerCol.indexOf("ngày") > -1 || lowerCol.indexOf("thời hạn") > -1) {
        colStyles[colLabel] = "min-width: 110px; max-width: 130px; text-align: center; white-space: normal; word-wrap: break-word;";
      } else if (
        lowerCol.indexOf("nhóm nhiệm vụ") > -1 ||
        lowerCol.indexOf("văn bản") > -1 ||
        lowerCol.indexOf("stt") > -1
      ) {
        colStyles[colLabel] = "min-width: 130px; max-width: 160px; white-space: normal; word-wrap: break-word;";
      } else if (lowerCol.indexOf("lđ đơn vị") > -1) {
        // CỘT LÃNH ĐẠO: nới rộng để tiêu đề chỉ xuống tối đa 2 dòng
        colStyles[colLabel] = "min-width: 215px; max-width: 228px; white-space: normal; word-wrap: break-word;";
      } else if (
        lowerCol.indexOf("nội dung") > -1 ||
        lowerCol.indexOf("tình hình") > -1
      ) {
        colStyles[colLabel] = "min-width: 300px; max-width: 480px; white-space: normal; word-wrap: break-word;";
      } else {
        colStyles[colLabel] = "min-width: 140px; max-width: 200px; white-space: normal; word-wrap: break-word;";
      }
    }

    // ==========================================
    // CỐ ĐỊNH CÁC CỘT BÊN TRÁI TỚI "VĂN BẢN GIAO"
    // Muốn bỏ cố định: để FROZEN_COLS = []
    // ==========================================
    const FROZEN_COLS = ["TT", "Nhóm nhiệm vụ", "Văn bản giao"];
    // Các cột có phần DỮ LIỆU căn trái
    const CELL_LEFT_COLS = ["Nhóm nhiệm vụ", "Văn bản giao"];
    // CHỈ cột "Nội dung nhiệm vụ" bấm được (mở danh sách chi tiết theo id_cha)
    const LINK_COLS = ["Nội dung nhiệm vụ"];

    // Các cột để tiêu đề nằm trọn 1 dòng: bỏ min/max-width, cột tự co vừa đủ
    const HEADER_NOWRAP_COLS = [
      "Đơn vị thực hiện",
      "LĐ đơn vị và chuyên viên (SĐT)",
      "LĐ UBND",
      "LĐ Văn phòng UBND",
      "Phòng ban chuyên môn",
      "Chuyên viên theo dõi"
    ];
    const FROZEN_WIDTH = { "TT": 78, "Nhóm nhiệm vụ": 110, "Văn bản giao": 130 };
    const FROZEN_LAST = FROZEN_COLS.length ? FROZEN_COLS[FROZEN_COLS.length - 1] : null;
    const stickyLeft = {};
    let accLeft = 0;
    for (let i = 0; i < FROZEN_COLS.length; i++) {
      const fc = FROZEN_COLS[i];
      const fw = FROZEN_WIDTH[fc] || 140;
      stickyLeft[fc] = accLeft;
      accLeft += fw;
      colStyles[fc] =
        "width: " + fw + "px; min-width: " + fw + "px; max-width: " + fw + "px; " +
        (fc === "TT"
          ? "text-align: center; white-space: nowrap; "
          : "white-space: normal; word-wrap: break-word; ") +
        "position: sticky; left: " + stickyLeft[fc] + "px;";
    }

    // Bề rộng tối thiểu riêng cho vài cột nowrap (để dữ liệu không bị gãy dòng)
    const NOWRAP_MIN_WIDTH = { "LĐ UBND": 140 };
    for (let i = 0; i < HEADER_NOWRAP_COLS.length; i++) {
      const nc = HEADER_NOWRAP_COLS[i];
      if (colStyles[nc] !== undefined) {
        colStyles[nc] =
          "white-space: normal; word-wrap: break-word;" +
          (NOWRAP_MIN_WIDTH[nc] ? " min-width: " + NOWRAP_MIN_WIDTH[nc] + "px;" : "");
      }
    }

    rootEl.currentViewData = processedData;

    const totalItems = processedData.length;
    let totalPages = Math.ceil(totalItems / rootEl.pageSize);
    if (totalPages === 0) totalPages = 1;
    if (rootEl.currentPage > totalPages) rootEl.currentPage = totalPages;
    if (rootEl.currentPage < 1) rootEl.currentPage = 1;

    let startIndex = (rootEl.currentPage - 1) * rootEl.pageSize;
    let endIndex = startIndex + rootEl.pageSize;
    const paginatedData = processedData.slice(startIndex, endIndex);

    let rowsHtml = "";
    if (paginatedData.length === 0) {
      rowsHtml =
        '<tr><td colspan="' +
        DISPLAY_COLUMNS.length +
        '" style="text-align:center; padding: 40px; color:#BFBFBF;">Không có bản ghi phù hợp</td></tr>';
    } else {
      for (let i = 0; i < paginatedData.length; i++) {
        // id_cha của dòng: ô "Nội dung nhiệm vụ" chỉ bấm được khi dòng có id_cha
        const idCha = String(paginatedData[i]["_id_cha"] || "");
        let cellsHtml = "";
        for (let j = 0; j < DISPLAY_COLUMNS.length; j++) {
          const colLabel = DISPLAY_COLUMNS[j].label;
          let cellValue = paginatedData[i][colLabel] || "";
          let lowerCol = String(colLabel).toLowerCase();
          // Nhóm nhiệm vụ / Văn bản giao / Nội dung nhiệm vụ: dữ liệu căn trái (header vẫn canh giữa)
          const isLinkCol = LINK_COLS.indexOf(colLabel) > -1;
          const cellStyle =
            colStyles[colLabel] +
            (CELL_LEFT_COLS.indexOf(colLabel) > -1 || isLinkCol ? " text-align: left;" : "");
          const rawCellText = String(
            paginatedData[i][colLabel] === null || paginatedData[i][colLabel] === undefined
              ? ""
              : paginatedData[i][colLabel]
          );

          if (lowerCol === "tt") {
            cellValue = startIndex + i + 1;
          } else if (lowerCol.indexOf("tình trạng") > -1) {
            cellValue = getBadgeHtml(paginatedData[i], cellValue);
          } else if (String(cellValue).length > 60) {
            let safeString = String(cellValue)
              .replace(/&/g, "&amp;")
              .replace(/</g, "&lt;")
              .replace(/>/g, "&gt;")
              .replace(/"/g, "&quot;");

            cellValue =
              '<div class="col-truncate" title="' +
              safeString +
              '">' +
              cellValue +
              "</div>";
          }
          const clsArr = [];
          if (stickyLeft[colLabel] !== undefined) {
            clsArr.push("sticky-col");
            if (colLabel === FROZEN_LAST) clsArr.push("sticky-edge");
          }
          if (isLinkCol && rawCellText !== "" && idCha) clsArr.push("link");
          const tdCls = clsArr.length ? ' class="' + clsArr.join(" ") + '"' : "";
          cellsHtml +=
            "<td" + tdCls + ' style="' + cellStyle + '">' + cellValue + "</td>";
        }
        // Dòng KHÔNG còn bấm được; chỉ giữ data-idcha để ô link đọc ra khi click
        rowsHtml += idCha
          ? '<tr data-idcha="' + idCha.replace(/&/g, "&amp;").replace(/"/g, "&quot;") + '">' + cellsHtml + "</tr>"
          : "<tr>" + cellsHtml + "</tr>";
      }
    }

    let theadHtml = "<tr>";
    let dropdownsHtml = "";

    for (let i = 0; i < DISPLAY_COLUMNS.length; i++) {
      const colLabel = DISPLAY_COLUMNS[i].label;
      let hasSort = APP_CONFIG.columnsWithSort.indexOf(colLabel) > -1;
      let hasFilter = APP_CONFIG.columnsWithFilter.indexOf(colLabel) > -1;

      const isSortAsc =
        rootEl.sortState.col === colLabel && rootEl.sortState.order === "asc";
      const isSortDesc =
        rootEl.sortState.col === colLabel && rootEl.sortState.order === "desc";
      const isFilterActive =
        rootEl.filterState[colLabel] && rootEl.filterState[colLabel].length > 0;
      const thStyle = colStyles[colLabel];
      // Class của ô header: cột TT + cột được cố định bên trái
      const thClsArr = [];
      if (colLabel === "TT") thClsArr.push("col-tt");
      if (stickyLeft[colLabel] !== undefined) thClsArr.push("sticky-col");
      if (colLabel === FROZEN_LAST) thClsArr.push("sticky-edge");
      const thClass = thClsArr.length ? ' class="' + thClsArr.join(" ") + '"' : "";

      let sortHtml = hasSort
        ? '<div class="sort-btns">' +
          SvgSortUp(isSortAsc) +
          SvgSortDown(isSortDesc) +
          "</div>"
        : "";
      let filterHtml = "";

      if (hasFilter) {
        filterHtml =
          '<div class="filter-btn">' + SvgFilter(isFilterActive) + "</div>";
        const uValues = getUniqueValues(colLabel);
        const selectedArr = rootEl.filterState[colLabel] || [];
        const isAllChecked =
          uValues.length > 0 && selectedArr.length === uValues.length
            ? "checked"
            : "";

        let searchBoxHtml = `
            <div class="dropdown-search-wrap">
              <input type="text" class="dropdown-search-input" data-list-id="list-${wrapperId}-${i}" placeholder="Tìm nhanh..." autocomplete="off">
            </div>
          `;

        let chkHtml = `
            <label class="antd-chk-item antd-select-all-line">
              <input type="checkbox" class="chk-select-all" ${isAllChecked}>
              <span>Chọn tất cả</span>
            </label>
          `;
        for (let k = 0; k < uValues.length; k++) {
          const v = uValues[k];
          const isChecked = selectedArr.indexOf(v) > -1 ? "checked" : "";
          chkHtml += `
              <label class="antd-chk-item chk-data-row">
                <input type="checkbox" class="chk-item" value="${String(v).replace(/"/g, "&quot;")}" ${isChecked}>
                <span>${v}</span>
              </label>
            `;
        }
        dropdownsHtml += `
            <div class="antd-dropdown-menu" id="dropdown-${wrapperId}-${i}">
              ${searchBoxHtml}
              <div class="antd-dropdown-list" id="list-${wrapperId}-${i}">${chkHtml}</div>
              <div class="antd-dropdown-footer">
                <button class="antd-btn antd-btn-reset" data-col="${colLabel}">Bỏ lọc</button>
                <button class="antd-btn antd-btn-ok" data-col="${colLabel}" data-index="${i}">Lọc</button>
              </div>
            </div>
          `;
      }

      theadHtml +=
        "<th" +
        thClass +
        ' style="' +
        thStyle +
        '"><div class="th-wrap' +
        (!hasSort && !hasFilter ? " no-actions" : "") +
        (HEADER_NOWRAP_COLS.indexOf(colLabel) > -1 ? " nowrap-head" : "") +
        '" data-col="' +
        colLabel +
        '" data-sortable="' +
        hasSort +
        '"><span>' +
        colLabel +
        '</span><div class="th-actions">' +
        sortHtml +
        filterHtml +
        "</div></div></th>";
    }
    theadHtml += "</tr>";

    const startCount = totalItems === 0 ? 0 : startIndex + 1;
    const endCount = endIndex > totalItems ? totalItems : endIndex;

    const countEl = rootEl.querySelector("#count-" + elementId);
    if (countEl) {
      countEl.textContent = totalItems.toLocaleString("vi-VN") + " nhiệm vụ";
    }

    // Dãy số trang trượt quanh trang hiện tại: 1 … 4 5 6 … N (theo mẫu ds_nhiem_vu_nhan)
    function pageWindow(cur, tp) {
      const out = [], win = 2;
      let lo = Math.max(1, cur - win), hi = Math.min(tp, cur + win);
      if (lo > 1) { out.push(1); if (lo > 2) out.push("…"); }
      for (let i = lo; i <= hi; i++) out.push(i);
      if (hi < tp) { if (hi < tp - 1) out.push("…"); out.push(tp); }
      return out;
    }

    const vnNum = (x) => Number(x || 0).toLocaleString("vi-VN");
    const pagesHtml = pageWindow(rootEl.currentPage, totalPages)
      .map(function (p) {
        return p === "…"
          ? '<button class="page-btn" disabled>…</button>'
          : '<button class="page-btn page-num' + (p === rootEl.currentPage ? " on" : "") + '" data-page="' + p + '">' + p + "</button>";
      })
      .join("");

    let footerHtml = `
      <span class="page-info">Hiển thị ${vnNum(startCount)}–${vnNum(endCount)} / ${vnNum(totalItems)}</span>
      <select class="page-size-select" id="pagesize-${elementId}">
        <option value="10" ${rootEl.pageSize === 10 ? "selected" : ""}>10 / trang</option>
        <option value="20" ${rootEl.pageSize === 20 ? "selected" : ""}>20 / trang</option>
        <option value="50" ${rootEl.pageSize === 50 ? "selected" : ""}>50 / trang</option>
        <option value="100" ${rootEl.pageSize === 100 ? "selected" : ""}>100 / trang</option>
      </select>
      <div class="page-controls">
        <button class="page-btn page-prev" ${rootEl.currentPage === 1 ? "disabled" : ""}>‹</button>
        ${pagesHtml}
        <button class="page-btn page-next" ${rootEl.currentPage === totalPages || totalPages === 0 ? "disabled" : ""}>›</button>
      </div>
    `;

    rootEl.querySelector("#tbody-" + elementId).innerHTML = rowsHtml;
    rootEl.querySelector("#thead-" + elementId).innerHTML = theadHtml;
    rootEl.querySelector("#dropdowns-" + elementId).innerHTML = dropdownsHtml;
    rootEl.querySelector("#footer-" + elementId).innerHTML = footerHtml;

    // Ô nổi số nhiệm vụ + bảng thống kê bám theo dữ liệu đang hiển thị
    if (typeof rootEl.__statsRefresh === "function") rootEl.__statsRefresh();

    attachDynamicEvents();
  };

  // ==========================================
  // 8. LIÊN KẾT CÁC SỰ KIỆN ĐỘNG
  // ==========================================
  const attachDynamicEvents = function () {
    const overlay = rootEl.querySelector("#overlay-" + elementId);

    const thElements = rootEl.querySelectorAll("thead th");
    thElements.forEach(function (th, colIdx) {
      const fBtn = th.querySelector(".filter-btn");
      if (fBtn) {
        fBtn.addEventListener("click", function (e) {
          e.stopPropagation();
          overlay.click();
          const menu = rootEl.querySelector(
            "#dropdown-" + wrapperId + "-" + colIdx,
          );
          if (menu) {
            menu.style.display = "flex";
            overlay.style.display = "block";
            const btnRect = this.getBoundingClientRect();
            const wrapRect = rootEl
              .querySelector("#" + wrapperId)
              .getBoundingClientRect();
            let targetLeft = btnRect.left - wrapRect.left;
            if (targetLeft + 240 > wrapRect.width)
              targetLeft = btnRect.right - wrapRect.left - 210;
            menu.style.top = btnRect.bottom - wrapRect.top + 4 + "px";
            menu.style.left = targetLeft + "px";

            const searchInput = menu.querySelector(".dropdown-search-input");
            if (searchInput) setTimeout(() => searchInput.focus(), 50);
          }
        });
      }
    });

    const dropdownSearchInputs = rootEl.querySelectorAll(
      ".dropdown-search-input",
    );
    dropdownSearchInputs.forEach((input) => {
      input.addEventListener("input", function (e) {
        const searchTerm = e.target.value.toLowerCase().trim();
        const listId = this.getAttribute("data-list-id");
        const listEl = rootEl.querySelector("#" + listId);
        if (!listEl) return;

        const chkLabels = listEl.querySelectorAll(".chk-data-row");
        chkLabels.forEach((label) => {
          const textSpan = label.querySelector("span");
          if (textSpan) {
            const textValue = textSpan.textContent.toLowerCase();
            label.style.display =
              textValue.indexOf(searchTerm) > -1 ? "flex" : "none";
          }
        });
      });
    });

    const allDropdownLists = rootEl.querySelectorAll(".antd-dropdown-list");
    allDropdownLists.forEach(function (listEl) {
      const chkAll = listEl.querySelector(".chk-select-all");
      const chkItems = listEl.querySelectorAll(".chk-item");
      if (chkAll) {
        chkAll.addEventListener("change", function () {
          for (let i = 0; i < chkItems.length; i++)
            chkItems[i].checked = this.checked;
        });
      }
      for (let i = 0; i < chkItems.length; i++) {
        chkItems[i].addEventListener("change", function () {
          let allTicked = true;
          for (let j = 0; j < chkItems.length; j++) {
            if (!chkItems[j].checked) {
              allTicked = false;
              break;
            }
          }
          if (chkAll) chkAll.checked = allTicked;
        });
      }
    });

    const okBtns = rootEl.querySelectorAll(".antd-btn-ok");
    for (let i = 0; i < okBtns.length; i++) {
      okBtns[i].addEventListener("click", function () {
        const colLabel = this.getAttribute("data-col");
        const idx = this.getAttribute("data-index");
        const list = rootEl.querySelector("#list-" + wrapperId + "-" + idx);
        const checkboxes = list.querySelectorAll(".chk-item");
        const selected = [];
        for (let j = 0; j < checkboxes.length; j++) {
          if (checkboxes[j].checked) selected.push(checkboxes[j].value);
        }
        rootEl.filterState[colLabel] = selected;
        rootEl.currentPage = 1;
        overlay.click();
        renderTableDynamic();
      });
    }

    const resetBtns = rootEl.querySelectorAll(".antd-btn-reset");
    for (let i = 0; i < resetBtns.length; i++) {
      resetBtns[i].addEventListener("click", function () {
        const colLabel = this.getAttribute("data-col");
        rootEl.filterState[colLabel] = [];
        rootEl.currentPage = 1;
        overlay.click();
        renderTableDynamic();
      });
    }

    const thWraps = rootEl.querySelectorAll(".th-wrap");
    thWraps.forEach(function (wrap) {
      if (wrap.getAttribute("data-sortable") === "true") {
        wrap.addEventListener("click", function (e) {
          if (e.target.closest(".filter-btn")) return;
          const colLabel = this.getAttribute("data-col");
          let newOrder = "asc";
          if (rootEl.sortState.col === colLabel) {
            if (rootEl.sortState.order === "asc") newOrder = "desc";
            else if (rootEl.sortState.order === "desc") newOrder = null;
          }
          rootEl.sortState = {
            col: newOrder ? colLabel : null,
            order: newOrder,
          };
          rootEl.currentPage = 1;
          renderTableDynamic();
        });
      }
    });

    const prevBtn = rootEl.querySelector(".page-prev");
    const nextBtn = rootEl.querySelector(".page-next");
    const sizeSelect = rootEl.querySelector("#pagesize-" + elementId);

    const numBtns = rootEl.querySelectorAll(".page-num");
    for (let i = 0; i < numBtns.length; i++) {
      numBtns[i].addEventListener("click", function () {
        const target = Number(this.getAttribute("data-page"));
        if (!isNaN(target) && target !== rootEl.currentPage) {
          rootEl.currentPage = target;
          renderTableDynamic();
        }
      });
    }

    if (prevBtn) {
      prevBtn.addEventListener("click", function () {
        if (rootEl.currentPage > 1) {
          rootEl.currentPage--;
          renderTableDynamic();
        }
      });
    }
    if (nextBtn) {
      nextBtn.addEventListener("click", function () {
        rootEl.currentPage++;
        renderTableDynamic();
      });
    }
    if (sizeSelect) {
      sizeSelect.addEventListener("change", function (e) {
        rootEl.pageSize = Number(e.target.value);
        rootEl.currentPage = 1;
        renderTableDynamic();
      });
    }
  };

  renderTableDynamic();
  return {};
};