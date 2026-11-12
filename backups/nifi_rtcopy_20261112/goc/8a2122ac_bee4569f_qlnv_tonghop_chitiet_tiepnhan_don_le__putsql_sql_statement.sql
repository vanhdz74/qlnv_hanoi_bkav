TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan_don_le
SELECT *
FROM qlnv_tonghop_chitiet_tiepnhan t
WHERE t.ma_nv_cha IS NULL
AND NOT EXISTS (
    SELECT 1
    FROM qlnv_tonghop_chitiet_tiepnhan c
    WHERE c.ma_nv_cha = t.Ma
);
