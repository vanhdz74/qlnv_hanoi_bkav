UPDATE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan t

LEFT JOIN (
    -- Danh sách nhiệm vụ có con
    SELECT DISTINCT ma_nv_cha
    FROM datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan
    WHERE ma_nv_cha IS NOT NULL
) c ON c.ma_nv_cha = t.Ma

LEFT JOIN (
    -- Đếm số bản ghi theo tennv_viettat
    SELECT tennv_viettat, COUNT(*) cnt
    FROM datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan
    GROUP BY tennv_viettat
) g ON g.tennv_viettat = t.tennv_viettat

SET t.NhomCauTrucNhiemVu =
CASE
    WHEN t.ma_nv_cha IS NOT NULL 
         OR c.ma_nv_cha IS NOT NULL
        THEN 'Nhiệm vụ theo chuỗi'

    WHEN g.cnt = 1
        THEN 'Nhiệm vụ đơn lẻ'

    ELSE 'Chưa xác định'
END;