/* [OPT 19/11] chỉ ghi dòng đổi: tính vào bảng tạm (PK Ma) → upsert dòng khác bảng thật → xóa dòng không còn trong nguồn.
   Bỏ 9 JOIN không dùng (dv_taonv*, rg1-4) và ORDER BY. syncdate = lần dòng đổi gần nhất. Bản cũ: backups/nifi_opt_ghi_20261119/ */
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DROP TEMPORARY TABLE IF EXISTS opt_tiepnhan;
CREATE TEMPORARY TABLE opt_tiepnhan ENGINE=InnoDB AS SELECT * FROM datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan LIMIT 0;
ALTER TABLE opt_tiepnhan ADD PRIMARY KEY (Ma);
INSERT INTO opt_tiepnhan
SELECT
		main.monthkey AS monthkey,
		main.`date` AS `date`,
		main.`month` AS `month`,
		main.`year` AS `year`,
		main.nhomvb_ma AS nhomvb_ma,
		main.nhomvb AS nhomvb,
		main.NhomNhiemVu AS NhomNhiemVu,
		main.ma_nv_cha AS ma_nv_cha,
		main.`Code` AS `Code`,		
		CONCAT(LEFT(main.monthkey,4),'-',main.VanBanGiaoNhiemVu,'-',main.Ma) AS idnv,
		CONCAT(LEFT(main.monthkey,4),'-',main.VanBanGiaoNhiemVu,'-',LEFT(MD5(main.TenNhiemVu), 12)) AS tennv_viettat,
		main.Ma AS Ma,
		main.TenNhiemVu AS TenNhiemVu,
		main.SanPhamChuYeu AS SanPhamChuYeu,
		main.ThoiHanHoanThanh AS ThoiHanHoanThanh,
		main.NgayHoanThanh AS NgayHoanThanh,
		main.TinhTrang AS TinhTrang,
		main.nhiem_vu_cho_duyet AS nhiem_vu_cho_duyet,
		main.TienDoHoanThanh AS TienDoHoanThanh,
		main.songayquahan AS songayquahan,
		main.tongtg_canxuly AS tongtg_canxuly,
		main.tongtg_daxuly AS tongtg_daxuly,
		main.don_vi_cap_01_dvgiao AS don_vi_cap_01_dvgiao,
		main.loaicapcha_dvgiao AS loaicapcha_dvgiao,
		main.loaicap_dvgiao AS loaicap_dvgiao,
		main.iddv_dvgiao AS iddv_dvgiao,
		main.donvi_dvgiao AS donvi_dvgiao,
		main.tenviettat_dvgiao AS tenviettat_dvgiao,
		main.iddv_captren_dvgiao AS iddv_captren_dvgiao,
		main.NguoiGiaoNhiemVuID AS NguoiGiaoNhiemVuID,
		main.NguoiGiaoNhiemVu AS NguoiGiaoNhiemVu,
		main.don_vi_cap_01 AS don_vi_cap_01,
		main.loaicapcha AS loaicapcha,
		main.loaicap AS loaicap,
		main.iddv AS iddv,
		main.donvi AS donvi,
		main.tenviettat AS tenviettat,
		main.iddv_captren AS iddv_captren,
		main.NguoiThucHienID AS NguoiThucHienID,
		main.NguoiThucHien AS NguoiThucHien,
		main.DonViPhoiHop AS DonViPhoiHop,
		main.iddv_dvchutri AS iddv_dvchutri,
		main.DonViChuTri AS DonViChuTri,
		main.don_vi_cap_01_dvtaonv AS don_vi_cap_01_dvtaonv,
		main.loaicapcha_dvtaonv AS loaicapcha_dvtaonv,
		main.loaicap_dvtaonv AS loaicap_dvtaonv,
		main.iddv_dvtaonv AS iddv_dvtaonv,
		main.donvi_dvtaonv AS donvi_dvtaonv,
		main.tenviettat_dvtaonv AS tenviettat_dvtaonv,
		main.iddv_captren_dvtaonv AS iddv_captren_dvtaonv,
		main.NguoiTaoNhiemVuID AS NguoiTaoNhiemVuID,
		main.NguoiTaoNhiemVu AS NguoiTaoNhiemVu,
		main.VanBanGiaoNhiemVu AS VanBanGiaoNhiemVu,
		main.NgayVanBan AS NgayVanBan,
		main.LinhVuc AS LinhVuc,
		main.Kieu AS Kieu,
		main.UuTien AS UuTien,
		main.KetQuaGhiChu AS KetQuaGhiChu,
		CASE  
        WHEN main.loaicapcha = main.loaicapcha_dvgiao THEN
                'Nhiệm vụ nội bộ'
        ELSE
                'Nhiệm vụ ngoài khối'
    END AS NhomPhamViNhiemVu,
		NULL AS NhomCauTrucNhiemVu,
		CASE
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Đã hoàn thành' THEN
					CONCAT(main.TinhTrang,' đúng hạn')
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Chưa hoàn thành' THEN
					CONCAT(main.TinhTrang,' trong hạn')
				ELSE
					main.TrangThai
		END AS TrangThai,
    CASE
        WHEN main.TrangThai = 'Đã hoàn thành đúng hạn' THEN 'HT đúng hạn'
        WHEN main.TrangThai = 'Đã hoàn thành quá hạn' THEN 'HT quá hạn'
        WHEN main.TrangThai = 'Chưa hoàn thành trong hạn' THEN 'Chưa HT trong hạn'
        WHEN main.TrangThai = 'Chưa hoàn thành quá hạn' THEN 'Chưa HT quá hạn'
				WHEN main.TrangThai = 'Chưa hoàn thành sắp quá hạn'THEN 'Chưa HT sắp quá hạn'
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Đã hoàn thành' THEN 'HT đúng hạn'
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Chưa hoàn thành' THEN 'Chưa HT trong hạn'
        ELSE 'Chưa xác định'
    END AS TrangThaiVietTat,
		CASE
        WHEN main.TrangThai = 'Đã hoàn thành đúng hạn' THEN 'Đã hoàn thành'
        WHEN main.TrangThai = 'Đã hoàn thành quá hạn' THEN 'Đã hoàn thành'
        WHEN main.TrangThai = 'Chưa hoàn thành trong hạn' THEN 'Chưa HT trong hạn'
        WHEN main.TrangThai = 'Chưa hoàn thành quá hạn' THEN 'Chưa HT quá hạn'
				WHEN main.TrangThai = 'Chưa hoàn thành sắp quá hạn' THEN 'Chưa HT sắp quá hạn'
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Đã hoàn thành' THEN 'Đã hoàn thành'
				WHEN main.TrangThai IN ( 'Không xác định', 'Chưa xác định') AND main.TinhTrang = 'Chưa hoàn thành' THEN 'Chưa HT trong hạn'
        ELSE 'Chưa xác định'
    END AS TrangThaiVietTat2,
		NULL AS TenNhiemVu_Mobile,
		'${sync_ts}' AS syncdate
FROM (
    SELECT
        /* 01 - monthkey: lấy theo ExpireDate dạng YYYYMM */
        DATE_FORMAT( COALESCE( t.CompletedDate, t.ExpireDate, t.CreatedDate), '%Y%m') + 0 AS monthkey,
        DATE_FORMAT( COALESCE( t.CompletedDate, t.ExpireDate, t.CreatedDate), '%Y%m%d') + 0 AS `date`,
				DATE_FORMAT( COALESCE( t.CompletedDate, t.ExpireDate, t.CreatedDate), '%m/%Y') AS `month`,
        DATE_FORMAT( COALESCE( t.CompletedDate, t.ExpireDate, t.CreatedDate), '%Y') + 0 AS `year`,
        /* 04 - Group + VB */
        /* COALESCE(rg4.ResolutionGroupId, rg3.ResolutionGroupId, rg2.ResolutionGroupId, rg1.ResolutionGroupId, rg.ResolutionGroupId) AS nhomvb_ma,
				CASE 
						WHEN COALESCE(rg4.`Name`, rg3.`Name`, rg2.`Name`, rg1.`Name`, rg.`Name`) = 'Văn bản chỉ đạo theo NQ 57' THEN 'Nghị quyết 57'
						ELSE COALESCE(rg4.`Name`, rg3.`Name`, rg2.`Name`, rg1.`Name`, rg.`Name`)
				END AS nhomvb, */
        rg.ResolutionGroupId AS nhomvb_ma,
				CASE 
						WHEN rg.`Name` = 'Văn bản chỉ đạo theo NQ 57' THEN 'Nghị quyết 57'
						ELSE  rg.`Name`
				END AS nhomvb,
				t.NameGroup AS NhomNhiemVu,
        r.DocCode AS ma_vb,
        r.Compendium AS vb,
				
        /* 05 - Mã nhiệm vụ */
				t.`Code` AS `Code`,
        t.TaskId AS Ma,
				t.ParentId AS ma_nv_cha,


        /* 06 - Tên nhiệm vụ */
        CASE 
						WHEN t.Title LIKE '%<script>%' THEN TRIM(SUBSTRING_INDEX(t.Title, '<script>', 1))
						ELSE t.Title
				END AS TenNhiemVu,
        NULL AS SanPhamChuYeu,

        /* 07 - Thời hạn hoàn thành */
        t.ExpireDate AS ThoiHanHoanThanh,
				COALESCE(t.CompletedDate,t.ApprovedDate) AS NgayHoanThanh,

        /* 08 - Tình trạng */
        CASE 
            WHEN t.Status IN (3,4) THEN 'Đã hoàn thành'
            ELSE 'Chưa hoàn thành'
        END AS TinhTrang,
				nvcd.nhiem_vu_cho_duyet AS nhiem_vu_cho_duyet,

        /* 09 - Tiến độ hoàn thành */
        CONCAT(t.Progress, '%') AS TienDoHoanThanh,

        /* 10 - Số ngày quá hạn */
        CASE 
            WHEN t.Status NOT IN (3,4) AND t.ExpireDate < NOW() 
                THEN DATEDIFF(NOW(), t.ExpireDate)
            WHEN t.Status IN (3,4) AND t.CompletedDate > t.ExpireDate
                THEN DATEDIFF(t.CompletedDate, t.ExpireDate)
            ELSE NULL
        END AS songayquahan,

        /* 11 - Đơn vị */
				CAST(
				CASE
						WHEN t.AssignDepartment IS NULL OR t.AssignDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  dv_giao.Level = 1 THEN dv_giao.DepartmentName
						WHEN dv_giao1.Level = 1 THEN dv_giao1.DepartmentName
						WHEN dv_giao2.Level = 1 THEN dv_giao2.DepartmentName
						WHEN dv_giao3.Level = 1 THEN dv_giao3.DepartmentName
						WHEN dv_giao4.Level = 1 THEN dv_giao4.DepartmentName
						ELSE NULL
				END AS CHAR(255)) AS don_vi_cap_01_dvgiao,
				CAST(
				CASE
						WHEN t.AssignDepartment IS NULL OR t.AssignDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  dv_giao.Level = 2 THEN dv_giao.DepartmentName
						WHEN dv_giao1.Level = 2 THEN dv_giao1.DepartmentName
						WHEN dv_giao2.Level = 2 THEN dv_giao2.DepartmentName
						WHEN dv_giao3.Level = 2 THEN dv_giao3.DepartmentName
						WHEN dv_giao4.Level = 2 THEN dv_giao4.DepartmentName
						ELSE NULL
				END AS CHAR(255)) AS loaicapcha_dvgiao,
				CAST(
				CASE
						WHEN t.AssignDepartment IS NULL OR t.AssignDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  dv_giao.Level = 3 THEN dv_giao.DepartmentName
						WHEN dv_giao1.Level = 3 THEN dv_giao1.DepartmentName
						WHEN dv_giao2.Level = 3 THEN dv_giao2.DepartmentName
						WHEN dv_giao3.Level = 3 THEN dv_giao3.DepartmentName
						WHEN dv_giao4.Level = 3 THEN dv_giao4.DepartmentName
						ELSE NULL
				END AS CHAR(255)) AS loaicap_dvgiao,
				dv_giao.DepartmentId AS iddv_dvgiao,
				IFNULL(dv_giao.DepartmentName, 'Chưa xác định') AS donvi_dvgiao,
				IFNULL(dv_giao.DepartmentShortName, 'Chưa xác định')  AS tenviettat_dvgiao,
				dv_giao.ParentId AS iddv_captren_dvgiao,
				t.AssignUser AS NguoiGiaoNhiemVuID,
				IFNULL(u_giao.FullName, 'Chưa xác định') AS NguoiGiaoNhiemVu,
				
				CASE
						WHEN t.TargetDepartment IS NULL OR t.TargetDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  d.Level = 1 THEN d.DepartmentName
						WHEN d1.Level = 1 THEN d1.DepartmentName
						WHEN d2.Level = 1 THEN d2.DepartmentName
						WHEN d3.Level = 1 THEN d3.DepartmentName
						WHEN d4.Level = 1 THEN d4.DepartmentName
						ELSE NULL
				END AS don_vi_cap_01,
				
				CASE
						WHEN t.TargetDepartment IS NULL OR t.TargetDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  d.Level = 2 THEN d.DepartmentName
						WHEN d1.Level = 2 THEN d1.DepartmentName
						WHEN d2.Level = 2 THEN d2.DepartmentName
						WHEN d3.Level = 2 THEN d3.DepartmentName
						WHEN d4.Level = 2 THEN d4.DepartmentName
						ELSE NULL
				END AS loaicapcha,
				CASE
						WHEN t.TargetDepartment IS NULL OR t.TargetDepartment = 'Chưa xác định'
								THEN 'Chưa xác định'
						WHEN  d.Level = 3 THEN d.DepartmentName
						WHEN d1.Level = 3 THEN d1.DepartmentName
						WHEN d2.Level = 3 THEN d2.DepartmentName
						WHEN d3.Level = 3 THEN d3.DepartmentName
						WHEN d4.Level = 3 THEN d4.DepartmentName
						ELSE NULL
				END AS loaicap,
				d.DepartmentId AS iddv,
				IFNULL(d.DepartmentName ,'Chưa xác định') AS donvi,
				IFNULL(d.DepartmentShortName ,'Chưa xác định')  AS tenviettat,
				d.ParentId AS iddv_captren,
				t.TargetUser AS NguoiThucHienID,
				IFNULL(u_thuchien.FullName, 'Chưa xác định') AS NguoiThucHien,
        NULL AS DonViPhoiHop,
				NULL AS iddv_dvchutri,
				NULL AS DonViChuTri,
				/* Bên tạo nhiệm vụ */
				IFNULL(u_taonv.don_vi_cap_01, 'Chưa xác định') AS don_vi_cap_01_dvtaonv,
				IFNULL(u_taonv.loaicapcha, 'Chưa xác định') AS loaicapcha_dvtaonv,
				IFNULL(u_taonv.loaicap, 'Chưa xác định') AS loaicap_dvtaonv,
				u_taonv.iddv AS iddv_dvtaonv,
				IFNULL(u_taonv.donvi, 'Chưa xác định') AS donvi_dvtaonv,
				IFNULL(u_taonv.tenviettat, 'Chưa xác định')  AS tenviettat_dvtaonv,
				u_taonv.iddv_captren AS iddv_captren_dvtaonv,
				t.CreateUser AS NguoiTaoNhiemVuID,
				IFNULL(u_taonv.canbo_hoten, 'Chưa xác định') AS NguoiTaoNhiemVu,

        /* 12 - Văn bản giao */
        CASE
            WHEN t.DocCode LIKE "Số %" THEN REPLACE(t.DocCode ,"Số ", "")
						WHEN t.DocCode IS NOT NULL AND t.DocCode <> "" AND t.DocCode <> " " THEN t.DocCode
            ELSE 'Chưa xác định'
        END AS VanBanGiaoNhiemVu,
				r.StartDate AS NgayVanBan,
				IFNULL(s.SectorName, 'Chưa xác định') AS LinhVuc,

        /* 13 - Ghi chú */
        NULL AS KetQuaGhiChu,

        /* 14 - Trạng thái chi tiết */
        CASE
						WHEN t.Status IN (3,4) AND DATE( COALESCE(t.CompletedDate, t.ApprovedDate) )  <= DATE(t.ExpireDate)
								THEN 'Đã hoàn thành đúng hạn'
						WHEN t.Status IN (3,4) AND DATE(COALESCE(t.CompletedDate, t.ApprovedDate) )  > DATE(t.ExpireDate)
								THEN 'Đã hoàn thành quá hạn'
						WHEN t.Status IN (-1,0,1,2) AND DATE(t.ExpireDate) >= DATE( NOW() ) AND DATEDIFF(t.ExpireDate, NOW() ) > 5 
								THEN 'Chưa hoàn thành trong hạn'
						WHEN t.Status IN (-1,0,1,2) AND DATE(t.ExpireDate) < DATE( NOW() )
								THEN 'Chưa hoàn thành quá hạn'
						WHEN t.Status IN (-1,0,1,2) AND DATE(t.ExpireDate) >= DATE( NOW() ) AND DATEDIFF(t.ExpireDate, NOW() ) <= 5 
								THEN 'Chưa hoàn thành sắp quá hạn'
						ELSE 'Chưa xác định'
				END AS TrangThai,
				
				CASE
						WHEN t.Status IN (3,4) THEN
								DATEDIFF(
										COALESCE(t.CompletedDate, t.ApprovedDate),
										t.CreatedDate
								)
						ELSE NULL
				END AS tongtg_daxuly,
				DATEDIFF(
						t.ExpireDate,
						t.CreatedDate
				) AS tongtg_canxuly,
				CASE
						WHEN r.Type = 1  THEN 'Chỉ thị'
						WHEN r.Type = 2  THEN 'Nghị quyết'
						WHEN r.Type = 3  THEN 'Công văn'
						WHEN r.Type = 4  THEN 'Kết luận'
						WHEN r.Type = 5  THEN 'Thông báo'
						WHEN r.Type = 6  THEN 'Đề nghị'
						WHEN r.Type = 7  THEN 'Quyết định'
						WHEN r.Type = 8  THEN 'Báo cáo'
						WHEN r.Type = 9  THEN 'Quy định'
						WHEN r.Type = 10 THEN 'Hợp đồng'
						WHEN r.Type = 11 THEN 'Đăng ký'
						WHEN r.Type = 12 THEN 'Biên bản'
						WHEN r.Type = 13 THEN 'Quy trình'
						WHEN r.Type = 14 THEN 'Hướng dẫn'
						WHEN r.Type = 15 THEN 'Kiến nghị'
						WHEN r.Type = 16 THEN 'Thanh tra'
						WHEN r.Type = 17 THEN 'Tờ trình'
						WHEN r.Type = 18 THEN 'Giấy phép'
						WHEN r.Type = 19 THEN 'Giấy mời'
						WHEN r.Type = 20 THEN 'Danh sách'
						WHEN r.Type = 21 THEN 'Kế hoạch'
						WHEN r.Type = 22 THEN 'Chương trình'
						WHEN r.Type = 23 THEN 'Giấy uỷ quyền'
						WHEN r.Type = 24 THEN 'Đề án'
						WHEN r.Type = 25 THEN 'Thông tư'
						WHEN r.Type = 26 THEN 'Quy chế'
						ELSE 'Chưa xác định'
				END AS Kieu,
				CASE
            WHEN t.Priority = 3 THEN 'Hỏa tốc'
            WHEN t.Priority = 2 THEN 'Thượng khẩn'
						WHEN t.Priority = 1 THEN 'Khẩn'
            ELSE 'Thường'
        END AS UuTien

    FROM ( SELECT * FROM db_theodoinv_hn.qlnv_task WHERE `Status` <> 5 AND DeletedDate IS NULL ) t
    LEFT JOIN datamart_hanoi.department d 
           ON d.DepartmentIdExt = t.TargetDepartment
		LEFT JOIN datamart_hanoi.department d1
				ON d1.DepartmentId = d.ParentId
		/* Cha */
		LEFT JOIN datamart_hanoi.department d2
				ON d2.DepartmentId = d1.ParentId
		/* Ông */
		LEFT JOIN datamart_hanoi.department d3
				ON d3.DepartmentId = d2.ParentId
		/* Cụ */
		LEFT JOIN datamart_hanoi.department d4
				ON d4.DepartmentId = d3.ParentId

		LEFT JOIN datamart_hanoi.department dv_giao
        ON dv_giao.DepartmentIdExt = t.AssignDepartment
		LEFT JOIN datamart_hanoi.department dv_giao1
				ON dv_giao1.DepartmentId = dv_giao.ParentId
		/* Cha */
		LEFT JOIN datamart_hanoi.department dv_giao2
				ON dv_giao2.DepartmentId = dv_giao1.ParentId
		/* Ông */
		LEFT JOIN datamart_hanoi.department dv_giao3
				ON dv_giao3.DepartmentId = dv_giao2.ParentId
		/* Cụ */
		LEFT JOIN datamart_hanoi.department dv_giao4
				ON dv_giao4.DepartmentId = dv_giao3.ParentId
				
		/* Người giao nhiệm vụ */
		LEFT JOIN egov_hanoi.user u_giao
           ON u_giao.UserId = t.AssignUser
 		/* Người nhận nhiệm vụ */
		LEFT JOIN egov_hanoi.user u_thuchien
           ON u_thuchien.UserId = t.TargetUser
 		/* Người tạo nhiệm vụ */
		LEFT JOIN datamart_hanoi.dm_user u_taonv
           ON u_taonv.canbo_id = t.CreateUser
					 
    LEFT JOIN db_theodoinv_hn.qlnv_resolution r 
           ON t.ResolutionId = r.ResolutionId
		LEFT JOIN db_theodoinv_hn.qlnv_sector s
           ON s.SectorId = r.SectorId
    LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg
           ON r.ResolutionGroupId = rg.ResolutionGroupId
    LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_nhiem_vu_cho_duyet_copy nvcd
           ON nvcd.taskid = t.Taskid
	 /*
    WHERE 
        t.Status <> 5
        AND t.DeletedDate IS NULL
		*/
) main
-- WHERE main.TinhTrang ='Đã hoàn thành'
WHERE (
		(main.loaicapcha_dvgiao = 'UBND Thành phố'
		AND main.iddv_dvgiao NOT IN (1307, 1310, 1841) -- [cách A 16/11] chỉ loại đúng nút Sở ngành / Xã, Phường / Nhóm Sở ngành MR
		)
		OR
		(main.loaicapcha_dvgiao = 'Thành ủy Hà Nội'
		AND main.iddv_dvgiao <> 1558 -- [cách A 16/11] chỉ loại đúng nút Đảng bộ trực thuộc
		)
		OR
		(
		main.loaicapcha_dvgiao = 'HĐND Thành phố'
		)
		OR
		(
		main.loaicapcha_dvgiao = 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
		) )
		-- OR ( main.don_vi_cap_01 = 'BAN TỔ CHỨC TRUNG ƯƠNG')
ON DUPLICATE KEY UPDATE
    `monthkey` = VALUES(`monthkey`),
    `date` = VALUES(`date`),
    `month` = VALUES(`month`),
    `year` = VALUES(`year`),
    `nhomvb_ma` = VALUES(`nhomvb_ma`),
    `nhomvb` = VALUES(`nhomvb`),
    `NhomNhiemVu` = VALUES(`NhomNhiemVu`),
    `ma_nv_cha` = VALUES(`ma_nv_cha`),
    `Code` = VALUES(`Code`),
    `idnv` = VALUES(`idnv`),
    `tennv_viettat` = VALUES(`tennv_viettat`),
    `TenNhiemVu` = VALUES(`TenNhiemVu`),
    `SanPhamChuYeu` = VALUES(`SanPhamChuYeu`),
    `ThoiHanHoanThanh` = VALUES(`ThoiHanHoanThanh`),
    `NgayHoanThanh` = VALUES(`NgayHoanThanh`),
    `TinhTrang` = VALUES(`TinhTrang`),
    `nhiem_vu_cho_duyet` = VALUES(`nhiem_vu_cho_duyet`),
    `TienDoHoanThanh` = VALUES(`TienDoHoanThanh`),
    `songayquahan` = VALUES(`songayquahan`),
    `tongtg_canxuly` = VALUES(`tongtg_canxuly`),
    `tongtg_daxuly` = VALUES(`tongtg_daxuly`),
    `don_vi_cap_01_dvgiao` = VALUES(`don_vi_cap_01_dvgiao`),
    `loaicapcha_dvgiao` = VALUES(`loaicapcha_dvgiao`),
    `loaicap_dvgiao` = VALUES(`loaicap_dvgiao`),
    `iddv_dvgiao` = VALUES(`iddv_dvgiao`),
    `donvi_dvgiao` = VALUES(`donvi_dvgiao`),
    `tenviettat_dvgiao` = VALUES(`tenviettat_dvgiao`),
    `iddv_captren_dvgiao` = VALUES(`iddv_captren_dvgiao`),
    `NguoiGiaoNhiemVuID` = VALUES(`NguoiGiaoNhiemVuID`),
    `NguoiGiaoNhiemVu` = VALUES(`NguoiGiaoNhiemVu`),
    `don_vi_cap_01` = VALUES(`don_vi_cap_01`),
    `loaicapcha` = VALUES(`loaicapcha`),
    `loaicap` = VALUES(`loaicap`),
    `iddv` = VALUES(`iddv`),
    `donvi` = VALUES(`donvi`),
    `tenviettat` = VALUES(`tenviettat`),
    `iddv_captren` = VALUES(`iddv_captren`),
    `NguoiThucHienID` = VALUES(`NguoiThucHienID`),
    `NguoiThucHien` = VALUES(`NguoiThucHien`),
    `DonViPhoiHop` = VALUES(`DonViPhoiHop`),
    `don_vi_cap_01_dvtaonv` = VALUES(`don_vi_cap_01_dvtaonv`),
    `loaicapcha_dvtaonv` = VALUES(`loaicapcha_dvtaonv`),
    `loaicap_dvtaonv` = VALUES(`loaicap_dvtaonv`),
    `iddv_dvtaonv` = VALUES(`iddv_dvtaonv`),
    `donvi_dvtaonv` = VALUES(`donvi_dvtaonv`),
    `tenviettat_dvtaonv` = VALUES(`tenviettat_dvtaonv`),
    `iddv_captren_dvtaonv` = VALUES(`iddv_captren_dvtaonv`),
    `NguoiTaoNhiemVuID` = VALUES(`NguoiTaoNhiemVuID`),
    `NguoiTaoNhiemVu` = VALUES(`NguoiTaoNhiemVu`),
    `VanBanGiaoNhiemVu` = VALUES(`VanBanGiaoNhiemVu`),
    `NgayVanBan` = VALUES(`NgayVanBan`),
    `LinhVuc` = VALUES(`LinhVuc`),
    `Kieu` = VALUES(`Kieu`),
    `UuTien` = VALUES(`UuTien`),
    `KetQuaGhiChu` = VALUES(`KetQuaGhiChu`),
    `NhomPhamViNhiemVu` = VALUES(`NhomPhamViNhiemVu`),
    `TrangThai` = VALUES(`TrangThai`),
    `TrangThaiVietTat` = VALUES(`TrangThaiVietTat`),
    `TrangThaiVietTat2` = VALUES(`TrangThaiVietTat2`),
    `TenNhiemVu_Mobile` = VALUES(`TenNhiemVu_Mobile`),
    `syncdate` = VALUES(`syncdate`);
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan
SELECT d.* FROM (
    SELECT n.* FROM opt_tiepnhan n LEFT JOIN datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan o ON o.Ma = n.Ma
    WHERE o.Ma IS NULL OR NOT (
        n.`monthkey` <=> o.`monthkey`
        AND n.`date` <=> o.`date`
        AND BINARY n.`month` <=> BINARY o.`month`
        AND n.`year` <=> o.`year`
        AND BINARY n.`nhomvb_ma` <=> BINARY o.`nhomvb_ma`
        AND BINARY n.`nhomvb` <=> BINARY o.`nhomvb`
        AND BINARY n.`NhomNhiemVu` <=> BINARY o.`NhomNhiemVu`
        AND n.`ma_nv_cha` <=> o.`ma_nv_cha`
        AND BINARY n.`Code` <=> BINARY o.`Code`
        AND BINARY n.`idnv` <=> BINARY o.`idnv`
        AND BINARY n.`tennv_viettat` <=> BINARY o.`tennv_viettat`
        AND BINARY n.`TenNhiemVu` <=> BINARY o.`TenNhiemVu`
        AND BINARY n.`SanPhamChuYeu` <=> BINARY o.`SanPhamChuYeu`
        AND n.`ThoiHanHoanThanh` <=> o.`ThoiHanHoanThanh`
        AND n.`NgayHoanThanh` <=> o.`NgayHoanThanh`
        AND BINARY n.`TinhTrang` <=> BINARY o.`TinhTrang`
        AND BINARY n.`nhiem_vu_cho_duyet` <=> BINARY o.`nhiem_vu_cho_duyet`
        AND BINARY n.`TienDoHoanThanh` <=> BINARY o.`TienDoHoanThanh`
        AND n.`songayquahan` <=> o.`songayquahan`
        AND n.`tongtg_canxuly` <=> o.`tongtg_canxuly`
        AND n.`tongtg_daxuly` <=> o.`tongtg_daxuly`
        AND BINARY n.`don_vi_cap_01_dvgiao` <=> BINARY o.`don_vi_cap_01_dvgiao`
        AND BINARY n.`loaicapcha_dvgiao` <=> BINARY o.`loaicapcha_dvgiao`
        AND BINARY n.`loaicap_dvgiao` <=> BINARY o.`loaicap_dvgiao`
        AND n.`iddv_dvgiao` <=> o.`iddv_dvgiao`
        AND BINARY n.`donvi_dvgiao` <=> BINARY o.`donvi_dvgiao`
        AND BINARY n.`tenviettat_dvgiao` <=> BINARY o.`tenviettat_dvgiao`
        AND n.`iddv_captren_dvgiao` <=> o.`iddv_captren_dvgiao`
        AND n.`NguoiGiaoNhiemVuID` <=> o.`NguoiGiaoNhiemVuID`
        AND BINARY n.`NguoiGiaoNhiemVu` <=> BINARY o.`NguoiGiaoNhiemVu`
        AND BINARY n.`don_vi_cap_01` <=> BINARY o.`don_vi_cap_01`
        AND BINARY n.`loaicapcha` <=> BINARY o.`loaicapcha`
        AND BINARY n.`loaicap` <=> BINARY o.`loaicap`
        AND n.`iddv` <=> o.`iddv`
        AND BINARY n.`donvi` <=> BINARY o.`donvi`
        AND BINARY n.`tenviettat` <=> BINARY o.`tenviettat`
        AND n.`iddv_captren` <=> o.`iddv_captren`
        AND n.`NguoiThucHienID` <=> o.`NguoiThucHienID`
        AND BINARY n.`NguoiThucHien` <=> BINARY o.`NguoiThucHien`
        AND BINARY n.`DonViPhoiHop` <=> BINARY o.`DonViPhoiHop`
        AND BINARY n.`don_vi_cap_01_dvtaonv` <=> BINARY o.`don_vi_cap_01_dvtaonv`
        AND BINARY n.`loaicapcha_dvtaonv` <=> BINARY o.`loaicapcha_dvtaonv`
        AND BINARY n.`loaicap_dvtaonv` <=> BINARY o.`loaicap_dvtaonv`
        AND n.`iddv_dvtaonv` <=> o.`iddv_dvtaonv`
        AND BINARY n.`donvi_dvtaonv` <=> BINARY o.`donvi_dvtaonv`
        AND BINARY n.`tenviettat_dvtaonv` <=> BINARY o.`tenviettat_dvtaonv`
        AND n.`iddv_captren_dvtaonv` <=> o.`iddv_captren_dvtaonv`
        AND n.`NguoiTaoNhiemVuID` <=> o.`NguoiTaoNhiemVuID`
        AND BINARY n.`NguoiTaoNhiemVu` <=> BINARY o.`NguoiTaoNhiemVu`
        AND BINARY n.`VanBanGiaoNhiemVu` <=> BINARY o.`VanBanGiaoNhiemVu`
        AND n.`NgayVanBan` <=> o.`NgayVanBan`
        AND BINARY n.`LinhVuc` <=> BINARY o.`LinhVuc`
        AND BINARY n.`Kieu` <=> BINARY o.`Kieu`
        AND BINARY n.`UuTien` <=> BINARY o.`UuTien`
        AND BINARY n.`KetQuaGhiChu` <=> BINARY o.`KetQuaGhiChu`
        AND BINARY n.`NhomPhamViNhiemVu` <=> BINARY o.`NhomPhamViNhiemVu`
        AND BINARY n.`TrangThai` <=> BINARY o.`TrangThai`
        AND BINARY n.`TrangThaiVietTat` <=> BINARY o.`TrangThaiVietTat`
        AND BINARY n.`TrangThaiVietTat2` <=> BINARY o.`TrangThaiVietTat2`
        AND BINARY n.`TenNhiemVu_Mobile` <=> BINARY o.`TenNhiemVu_Mobile`
    )
) d
ON DUPLICATE KEY UPDATE
    `monthkey` = VALUES(`monthkey`),
    `date` = VALUES(`date`),
    `month` = VALUES(`month`),
    `year` = VALUES(`year`),
    `nhomvb_ma` = VALUES(`nhomvb_ma`),
    `nhomvb` = VALUES(`nhomvb`),
    `NhomNhiemVu` = VALUES(`NhomNhiemVu`),
    `ma_nv_cha` = VALUES(`ma_nv_cha`),
    `Code` = VALUES(`Code`),
    `idnv` = VALUES(`idnv`),
    `tennv_viettat` = VALUES(`tennv_viettat`),
    `TenNhiemVu` = VALUES(`TenNhiemVu`),
    `SanPhamChuYeu` = VALUES(`SanPhamChuYeu`),
    `ThoiHanHoanThanh` = VALUES(`ThoiHanHoanThanh`),
    `NgayHoanThanh` = VALUES(`NgayHoanThanh`),
    `TinhTrang` = VALUES(`TinhTrang`),
    `nhiem_vu_cho_duyet` = VALUES(`nhiem_vu_cho_duyet`),
    `TienDoHoanThanh` = VALUES(`TienDoHoanThanh`),
    `songayquahan` = VALUES(`songayquahan`),
    `tongtg_canxuly` = VALUES(`tongtg_canxuly`),
    `tongtg_daxuly` = VALUES(`tongtg_daxuly`),
    `don_vi_cap_01_dvgiao` = VALUES(`don_vi_cap_01_dvgiao`),
    `loaicapcha_dvgiao` = VALUES(`loaicapcha_dvgiao`),
    `loaicap_dvgiao` = VALUES(`loaicap_dvgiao`),
    `iddv_dvgiao` = VALUES(`iddv_dvgiao`),
    `donvi_dvgiao` = VALUES(`donvi_dvgiao`),
    `tenviettat_dvgiao` = VALUES(`tenviettat_dvgiao`),
    `iddv_captren_dvgiao` = VALUES(`iddv_captren_dvgiao`),
    `NguoiGiaoNhiemVuID` = VALUES(`NguoiGiaoNhiemVuID`),
    `NguoiGiaoNhiemVu` = VALUES(`NguoiGiaoNhiemVu`),
    `don_vi_cap_01` = VALUES(`don_vi_cap_01`),
    `loaicapcha` = VALUES(`loaicapcha`),
    `loaicap` = VALUES(`loaicap`),
    `iddv` = VALUES(`iddv`),
    `donvi` = VALUES(`donvi`),
    `tenviettat` = VALUES(`tenviettat`),
    `iddv_captren` = VALUES(`iddv_captren`),
    `NguoiThucHienID` = VALUES(`NguoiThucHienID`),
    `NguoiThucHien` = VALUES(`NguoiThucHien`),
    `DonViPhoiHop` = VALUES(`DonViPhoiHop`),
    `don_vi_cap_01_dvtaonv` = VALUES(`don_vi_cap_01_dvtaonv`),
    `loaicapcha_dvtaonv` = VALUES(`loaicapcha_dvtaonv`),
    `loaicap_dvtaonv` = VALUES(`loaicap_dvtaonv`),
    `iddv_dvtaonv` = VALUES(`iddv_dvtaonv`),
    `donvi_dvtaonv` = VALUES(`donvi_dvtaonv`),
    `tenviettat_dvtaonv` = VALUES(`tenviettat_dvtaonv`),
    `iddv_captren_dvtaonv` = VALUES(`iddv_captren_dvtaonv`),
    `NguoiTaoNhiemVuID` = VALUES(`NguoiTaoNhiemVuID`),
    `NguoiTaoNhiemVu` = VALUES(`NguoiTaoNhiemVu`),
    `VanBanGiaoNhiemVu` = VALUES(`VanBanGiaoNhiemVu`),
    `NgayVanBan` = VALUES(`NgayVanBan`),
    `LinhVuc` = VALUES(`LinhVuc`),
    `Kieu` = VALUES(`Kieu`),
    `UuTien` = VALUES(`UuTien`),
    `KetQuaGhiChu` = VALUES(`KetQuaGhiChu`),
    `NhomPhamViNhiemVu` = VALUES(`NhomPhamViNhiemVu`),
    `TrangThai` = VALUES(`TrangThai`),
    `TrangThaiVietTat` = VALUES(`TrangThaiVietTat`),
    `TrangThaiVietTat2` = VALUES(`TrangThaiVietTat2`),
    `TenNhiemVu_Mobile` = VALUES(`TenNhiemVu_Mobile`),
    `syncdate` = VALUES(`syncdate`);
DELETE o FROM datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan o LEFT JOIN opt_tiepnhan n ON n.Ma = o.Ma WHERE n.Ma IS NULL;
DROP TEMPORARY TABLE IF EXISTS opt_tiepnhan;