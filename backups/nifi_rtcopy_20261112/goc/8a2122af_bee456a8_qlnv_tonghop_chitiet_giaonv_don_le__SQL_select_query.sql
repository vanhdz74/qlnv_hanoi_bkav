TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_giaonv_don_le;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_giaonv_don_le
SELECT *
FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv t
WHERE t.ma_nv_cha IS NULL
AND NOT EXISTS (
    SELECT 1
    FROM datamart_hanoi.qlnv_tonghop_chitiet_giaonv c
    WHERE c.ma_nv_cha = t.Ma
);
