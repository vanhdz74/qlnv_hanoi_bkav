/* [RT 12/11] upsert + delete theo syncdate (sync_ts của NiFi) — bảng không bao giờ rỗng */
UPDATE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan g

LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan g_cha
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