TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_theo_chuoi;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_theo_chuoi
SELECT *
FROM qlnv_tonghop_chitiet_tiepnhan t
WHERE
    -- là nhiệm vụ con
    t.ma_nv_cha IS NOT NULL

    -- hoặc là nhiệm vụ cha
    OR EXISTS (
        SELECT 1
        FROM qlnv_tonghop_chitiet_tiepnhan c
        WHERE c.ma_nv_cha = t.Ma
    );
