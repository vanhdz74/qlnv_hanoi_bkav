"""Số liệu trích tay từ 'tai_lieu/BC_CQTT_bao cao thang 10.2026_K.docx'
(BC tháng 10/2026 của CQTT - Công an TP, kỳ 25/9-14/10/2026, chốt 17h00 14/10/2026) -> t10.json.
Thay cho số tuần 41 (file 'BC tháng 10.pdf', đã chuyển sang t41_tuan41_cu.json, không dùng nữa).
Chỉ ghi chỉ số có số liệu tường minh trong báo cáo; chỉ số không có -> không ghi (bảng để NULL, dashboard hiện '!').
"""
import json, os

KY = "T10/2026"
# ma: (tu_so, mau_so, gia_tri, trich_dan, vi_tri, ghi_chu)   -- % lưu tỷ lệ 0..1
D = {
 "NV01": (None, None, 865, "toàn Thành phố đang theo dõi tổng số 865 nhiệm vụ (giảm 02 nhiệm vụ so với tháng 9/2026)", "Mục I.2, Trang 2; Phụ lục 01 (Tổng số)", ""),
 "NV02": (None, None, 478, "Hoàn thành 478 nhiệm vụ (tăng 17 nhiệm vụ so với tháng trước)", "Mục I.2(1); Phụ lục 01", ""),
 "NV03": (478, 865, 478 / 865, "865 nhiệm vụ ... Hoàn thành 478 nhiệm vụ", "Mục I.2(1)", "Tự tính NV02/NV01."),
 "NV04": (None, None, 387, "Tiếp tục thực hiện 387 nhiệm vụ (giảm 17 nhiệm vụ so với tháng trước)", "Mục I.2(1); Phụ lục 01",
          "Mục I.2 ghi 'giảm 17', dòng Tổng Phụ lục 01 ghi 'giảm 19' (406 -> 387 = giảm 19)."),
 "NV05": (None, None, 10, "trong đó có 10 nhiệm vụ quá hạn, giảm 5 nhiệm vụ so với tháng trước", "Mục I.2(1); Phụ lục 01", ""),
 "NV06": (None, None, 9, "09 nhiệm vụ cấp Thành phố đang tiếp tục xử lý", "Mục I.2(1); Phụ lục 01 (cột 'cần tiếp tục xử lý' = 09)", "01 nhiệm vụ TW chờ Sổ tay hướng dẫn không tính."),
 "NV07": (None, None, 294, "Nhiệm vụ Trung ương giao | 294 | 189 | 105 | 1 | 0 | 0", "Phụ lục 01, dòng 1", ""),
 "NV08": (None, None, 189, "Nhiệm vụ Trung ương giao | 294 | 189 | 105 | 1 | 0 | 0", "Phụ lục 01, dòng 1", ""),
 "NV09": (None, None, 126, "Nhiệm vụ theo Kế hoạch số 20-KH/BCĐ57 | 126 | 64 | 62 | 2 | 2 | 0", "Phụ lục 01, dòng 2", ""),
 "NV10": (None, None, 64, "Nhiệm vụ theo Kế hoạch số 20-KH/BCĐ57 | 126 | 64 | 62 | 2 | 2 | 0", "Phụ lục 01, dòng 2", ""),
 "NV11": (None, None, 2, "Nhiệm vụ theo Kế hoạch số 20-KH/BCĐ57 | 126 | 64 | 62 | 2 | 2 | 0", "Phụ lục 01, dòng 2 (cột Đã quá thời hạn giao)", ""),
 "NV12": (None, None, 26, "Nhiệm vụ theo Kế hoạch số 35-KH/BCĐ57 | 26 | 10 | 16 | 1 | 1 | 1", "Phụ lục 01, dòng 3", ""),
 "NV13": (None, None, 10, "Nhiệm vụ theo Kế hoạch số 35-KH/BCĐ57 | 26 | 10 | 16 | 1 | 1 | 1", "Phụ lục 01, dòng 3", ""),
 "NV14": (None, None, 1, "Nhiệm vụ theo Kế hoạch số 35-KH/BCĐ57 | 26 | 10 | 16 | 1 | 1 | 1", "Phụ lục 01, dòng 3 (cột Đã quá thời hạn giao)", ""),
 "NV15": (None, None, 366, "Nhiệm vụ theo Thông báo kết luận | 366 | 176 | 190 | 06 | 06 | 2", "Phụ lục 01, dòng 4", ""),
 "NV16": (None, None, 176, "Nhiệm vụ theo Thông báo kết luận | 366 | 176 | 190 | 06 | 06 | 2", "Phụ lục 01, dòng 4", ""),
 "TC01": (None, None, 9090.399, "tổng kinh phí Thành phố bố trí năm 2026 ... là 9.090,399 tỷ đồng", "Mục I.2.6 (Nguồn lực tài chính), cập nhật 14/10/2026", ""),
 "TC02": (None, None, 8881.969, "đã phân bổ 8.881,969 tỷ đồng, đạt 97,71%", "Mục I.2.6",
          "Phụ lục 02 (nhiệm vụ 7, số 30/9/2026) còn ghi 8.848,058 tỷ / chưa phân bổ 242,341 tỷ (và 267,443 tỷ) - lấy số 14/10 ở Mục I.2.6."),
 "TC03": (8881.969, 9090.399, 8881.969 / 9090.399, "đã phân bổ 8.881,969 tỷ đồng, đạt 97,71%", "Mục I.2.6", ""),
 "TC04": (5452.042, 5560, 5452.042 / 5560, "chi đầu tư đã phân bổ 5.452,042/5.560 tỷ đồng, đạt khoảng 98,1%", "Mục I.2.6", ""),
 "TC05": (3429.927, 3530.4, 3429.927 / 3530.4, "chi thường xuyên đã phân bổ 3.429,927/3.530,4 tỷ đồng, đạt 97,15%", "Mục I.2.6",
          "Mẫu số báo cáo ghi 3.530,4 (các kỳ trước 3.530,399)."),
 "TC06": (937.467, 4147.157, 937.467 / 4147.157, "chi thường xuyên khối cơ quan Thành phố đã giải ngân 937,467/4.147,157 tỷ đồng, đạt 22,61%", "Mục I.2.6", ""),
 "TC07": (200.553, 333.565, 200.553 / 333.565, "khối xã, phường giải ngân 200,553/333,565 tỷ đồng, đạt khoảng 60,12%", "Mục I.2.6", ""),
 "TC08": (3078.641, 5452.042, 3078.641 / 5452.042, "chi đầu tư giải ngân 3.078,641/5.452,042 tỷ đồng, đạt 56,47%", "Mục I.2.6", ""),
 "TC12": (None, None, 208.430, "còn 208,430 tỷ đồng chưa phân bổ", "Mục I.2.6", ""),
 "DD01": (None, None, 4827135, "tổng số thửa đất trên bản đồ ... là 4.827.135 thửa (so với báo cáo tháng 9/2026 giảm 72.504 thửa)", "Mục I.3.2(2)", ""),
 "DD02": (None, None, 4781746, "đã xây dựng cơ sở dữ liệu 4.781.746 thửa đất, đạt 99.1% (so với báo cáo tháng 9/2026 tăng 1.010.725 thửa)", "Mục I.3.2(2); Phụ lục 02 nhiệm vụ 6",
          "Mức tăng báo cáo ghi 1.010.725, tính theo số T9 (3.770.751) là 1.010.995."),
 "DD03": (4781746, 4827135, 4781746 / 4827135, "đã xây dựng cơ sở dữ liệu 4.781.746 thửa đất, đạt 99.1%", "Mục I.3.2(2)", "Báo cáo ghi 99,1%; tự tính DD02/DD01 = 99,06%."),
 "DD04": (None, None, 2782633, "thửa đất đã đạt tiêu chí Nhóm 1 'Đúng - Đủ - Sạch - Sống' là 2.782.633 thửa", "Mục I.3.2(2); Phụ lục 02 nhiệm vụ 6", ""),
 "DD05": (2782633, 4827135, 2782633 / 4827135, "Nhóm 1 ... 2.782.633 thửa / tổng 4.827.135 thửa", "Mục I.3.2(2)", "Tự tính DD04/DD01."),
 "DD08": (None, None, 2094324, "tổng số thửa đất cần phải xây dựng cơ sở dữ liệu, làm giàu, làm sạch: 2.094.324 thửa đất", "Phụ lục 02, mục I, nhiệm vụ 6 (452-TB/TU)", ""),
 "DD09": (22, 126, 22 / 126, "tiếp tục tổ chức 05 tổ công tác đôn đốc 22 địa phương có khối lượng dữ liệu còn lớn", "Mục I.3.2(2)", ""),
 "DL01": (13, 13, 1.0, "duy trì kết nối, thu thập 13/13 nguồn dữ liệu ưu tiên", "Mục I.3.2(1)", ""),
 "DL05": (2, 4, 0.5, "Nhóm 3 (triển khai hệ thống Kho dữ liệu dùng chung) tăng từ 1/4 lên 2/4 nhiệm vụ hoàn thành", "Mục I.3.2(1)", ""),
 "DL06": (None, None, 4, "Nhóm 5 ... đã xây dựng và khai thác 04 kịch bản", "Mục I.3.2(1)", ""),
 "DL07": (None, None, 3, "13/13 cơ sở dữ liệu đã kết nối kỹ thuật, hiện mới khai thác trực tiếp 03 cơ sở dữ liệu trong giải quyết thủ tục hành chính", "Mục I.3.2(3)",
          "Báo cáo tính theo số CSDL (03 CSDL), không phải 'loại dữ liệu'."),
 "DL08": (13, 13, 1.0, "13/13 cơ sở dữ liệu đã kết nối kỹ thuật", "Mục I.3.2(3)", ""),
 "TT05": (None, None, 1557, "đã phê duyệt phương án tái cấu trúc đối với 1.557/1.721 thủ tục hành chính, đạt 90,47%", "Mục I.3.2(3)", ""),
 "TT06": (1557, 1721, 1557 / 1721, "1.557/1.721 thủ tục hành chính, đạt 90,47%", "Mục I.3.2(3)", ""),
 "TT07": (None, None, 1731.48, "Đối với 25 thủ tục trọng điểm, các phương án tái cấu trúc dự kiến tiết kiệm khoảng 1.731,48 tỷ đồng chi phí tuân thủ/năm, mức cắt giảm bình quân 72,4%", "Mục I.3.2(3)",
          "Số dự kiến/năm cho 25 thủ tục trọng điểm."),
 "NT01": (None, None, 85500, "khoảng 85.500 tài khoản cán bộ, công chức, viên chức", "Mục I.3.1(3) Trục UBND", "Báo cáo ghi 'tài khoản', không nói rõ đã kích hoạt."),
 "NT03": (None, None, 183, "HanoiWork đã hình thành 183 không gian làm việc số", "Mục I.3.1(3) Trục UBND", "Báo cáo ghi 183 'không gian làm việc số' (T9: 183 cơ quan, đơn vị)."),
 "NT08": (None, None, 84, "Hệ thống IOC Thành ủy đã cấu hình 84 chỉ số", "Mục I.3.1(1) Trục Đảng", ""),
 "NT09": (None, None, 28000, "cấp khoảng 28.000 tài khoản tại 134 cơ quan, đơn vị", "Mục I.3.1(1) Trục Đảng", ""),
 "KH01": (None, None, 0.167, "tỷ trọng giá trị tăng thêm của kinh tế số đạt 16,7% GRDP Thành phố", "Mục I.3.5", "Số ước tính đến tháng 9/2026."),
 "KH02": (None, None, 0.094, "kinh tế số lõi chiếm 9,4%", "Mục I.3.5", "Số ước tính đến tháng 9/2026."),
 "KH03": (None, None, 0.073, "kinh tế số ngành chiếm 7,3% GRDP", "Mục I.3.5", "Số ước tính đến tháng 9/2026."),
 "KH06": (None, None, 160, "Đến tháng 9/2026, Thành phố đã tiếp nhận khoảng 160 đề xuất đặt hàng, xét tài trợ nhiệm vụ", "Mục I.3.5; Mục III.4 ('khoảng 160 đề xuất đặt hàng gắn với 30 bài toán lớn')", "Số 'khoảng'."),
 "KH07": (None, None, 3, "UBND Thành phố phê duyệt danh mục 03 nhiệm vụ KHCN đặt hàng trong năm 2026 với tổng mức trần kinh phí dự kiến 116 tỷ đồng", "Mục I.3.5", "Đợt phê duyệt đầu tháng 10/2026 (T8 ghi 11 nhiệm vụ - đợt trước)."),
 "AT01": (None, None, 263, "toàn Thành phố đã có 263 hệ thống thông tin được phê duyệt cấp độ; trong kỳ báo cáo đã phê duyệt mới 18 hồ sơ", "Mục I.2.7", ""),
 "AT03": (None, None, 4, "còn 04 hồ sơ đang được Công an Thành phố tiếp tục thẩm định", "Mục I.2.7", ""),
 "AT05": (None, None, 19505, "hoàn thành triển khai cài đặt giám sát đối với 19.505 máy tính", "Mục I.2.7", ""),
 "AT06": (None, None, 182, "19.505 máy tính, 182 máy chủ Internet", "Mục I.2.7", ""),
 "AT08": (None, None, 423, "Trong tháng đã phát hiện 423 cảnh báo về nguy cơ mất an ninh mạng", "Mục I.2.7", ""),
}

# Phụ lục 01 - bảng theo nguồn giao: tổng, hoàn thành, đang TH, quá hạn, cần xử lý, hạn trong tháng
NGUON_GIAO = {
    "Nhiệm vụ Trung ương giao": [294, 189, 105, 1, 0, 0],
    "Kế hoạch 20-KH/BCĐ57": [126, 64, 62, 2, 2, 0],
    "Kế hoạch 35-KH/BCĐ57": [26, 10, 16, 1, 1, 1],
    "Thông báo kết luận": [366, 176, 190, 6, 6, 2],
    "Công văn truyền đạt ý kiến": [44, 36, 8, 0, 0, 0],
    "Nhiệm vụ trọng tâm, cấp bách": [9, 3, 6, 0, 0, 0],
}

if __name__ == "__main__":
    out = [dict(ma=m, ky=KY, tu_so=t, mau_so=ms, gia_tri=round(v, 6), trich_dan=td, vi_tri=vt, ghi_chu=gc)
           for m, (t, ms, v, td, vt, gc) in D.items()]
    W = os.path.dirname(os.path.abspath(__file__))
    json.dump(out, open(os.path.join(W, "t10.json"), "w"), ensure_ascii=False, indent=1)
    print(len(out), "chi so T10")
