- Thông tin kết nối CSDL số liệu NQ57 (PostgreSQL, chỉ đọc):

Địa chỉ: 10.120.33.33
Cổng: 15432
Tài khoản: dashboard_ro
Mật khẩu: 2e$&?jAwA
CSDL bao_cao, bảng dashboard.so_lieu_nq57: số liệu đã chấp nhận
CSDL bieu_mau, bảng dashboard.chi_tieu_nq57: tên chỉ tiêu, phụ lục, phân tổ
Hai CSDL riêng nên em tạo 2 kết nối, ghép hai bảng theo ma_chi_tieu + ma_phan_to.
AnhHVd nay anh Cường bảo là thêm cả từ tháng 1 nữa chị ạ


- Thông tin mới:
CSDL số liệu NQ57 đã thay bộ biểu mới (bốn tầng). Kết nối giữ nguyên (10.120.33.33:15432, tài khoản dashboard_ro, mật khẩu như cũ). Hai bảng cũ vẫn dùng được, tên và cột không đổi. Có thêm 2 bảng mới:

Bảng mới

CSDL bao_cao, bảng dashboard.so_lieu_truong_nq57: số liệu đã chấp nhận theo từng ô của biểu, đủ mọi ô, kể cả ô chữ, ô tự tính, bảng nhiều dòng. Cột: ma_bieu, ma_phan, ma_truong, so_dong (0 = phần một dòng; 1, 2… = các dòng của bảng nhiều dòng), ky, ma_don_vi, don_vi, gia_tri_so, gia_tri_chu, cap_nhat_luc.
CSDL bieu_mau, bảng dashboard.truong_nq57: danh mục trường, tên trường như trên biểu. Cột: ma_bieu, ten_bieu, ma_phan, ten_phan, nhieu_dong, thu_tu, ma_truong, ten_truong, stt_dong, dong, cot, kieu, don_vi_tinh, ma_chi_tieu, tu_tinh.
Ghép hai bảng mới theo ma_bieu + ma_phan + ma_truong. Như cũ, hai CSDL riêng nên dùng hai kết nối.
Bảng cũ thay đổi gì

dashboard.so_lieu_nq57: mã biểu nay là NQ57HN-B01…B12 và NQ57HN-TH-00…TH-05. Số các dòng tổng hợp TH nằm ở nhóm chỉ tiêu NQ57HN_TH. Tháng không có số liệu thì không có dòng, không còn dòng giá trị 0.
dashboard.chi_tieu_nq57: cột ma_phu_luc nay là nhóm chỉ tiêu NQ57HN_B01…B12, NQ57HN_TH.
Dùng bảng nào: bảng theo chỉ tiêu (so_lieu_nq57) chỉ có những ô có gắn chỉ tiêu, hiện có 757 số tháng 2–10. Muốn hiển thị đủ nội dung biểu thì dùng bảng theo trường (so_lieu_truong_nq57), có 3.116 ô. ma_chi_tieu trong truong_nq57 cho phép nối sang bảng theo chỉ tiêu khi cần.