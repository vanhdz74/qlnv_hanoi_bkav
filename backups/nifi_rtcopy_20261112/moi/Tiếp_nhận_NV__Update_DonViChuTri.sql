/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg g

LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg g_cha
    ON g.ma_nv_cha = g_cha.Ma

SET 
    g.iddv_dvchutri =
        CASE 
            WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' 
                THEN g.iddv

            WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' 
                THEN COALESCE(g_cha.iddv, g.iddv)

            ELSE g.iddv
        END,

    g.DonViChuTri =
        CASE 
            WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ đơn lẻ' 
                THEN g.donvi

            WHEN g.NhomCauTrucNhiemVu = 'Nhiệm vụ theo chuỗi' 
                THEN COALESCE(g_cha.donvi, g.donvi)

            ELSE g.donvi
        END;
/* Đổi chỗ nguyên tử; chờ khóa tối đa 10s để không chặn dashboard */
SET SESSION lock_wait_timeout = 10;
RENAME TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__old, datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan, datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__old TO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg;
SET SESSION lock_wait_timeout = 31536000;