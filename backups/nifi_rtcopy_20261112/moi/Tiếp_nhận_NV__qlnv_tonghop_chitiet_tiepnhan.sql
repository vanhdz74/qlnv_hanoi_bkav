/* [RT 12/11] staging + RENAME swap: IOC không bao giờ thấy bảng rỗng/đang sửa dở */
CREATE TABLE IF NOT EXISTS datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg LIKE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan;
TRUNCATE TABLE datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
INSERT INTO datamart_hanoi.qlnv_tonghop_chitiet_tiepnhan__stg 

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
		NOW() AS syncdate
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
				
		/* Đơn vị tạo nhiệm vụ */
		LEFT JOIN datamart_hanoi.department dv_taonv
        ON dv_taonv.DepartmentIdExt = t.CreateUserDepartment
		LEFT JOIN datamart_hanoi.department dv_taonv1
				ON dv_taonv1.DepartmentId = dv_taonv.ParentId
		/* Cha */
		LEFT JOIN datamart_hanoi.department dv_taonv2
				ON dv_taonv2.DepartmentId = dv_taonv1.ParentId
		/* Ông */
		LEFT JOIN datamart_hanoi.department dv_taonv3
				ON dv_taonv3.DepartmentId = dv_taonv2.ParentId
		/* Cụ */
		LEFT JOIN datamart_hanoi.department dv_taonv4
				ON dv_taonv4.DepartmentId = dv_taonv3.ParentId
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
		LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg1 ON rg1.ResolutionGroupId = rg.ParentGroupId 
		AND rg1.IsRoot = 0 -- mức 2: cha của cha
		LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg2 ON rg2.ResolutionGroupId = rg1.ParentGroupId 
		AND rg2.IsRoot = 0 -- mức 3: cha của cha
		LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg3 ON rg3.ResolutionGroupId = rg2.ParentGroupId 
		AND rg3.IsRoot = 0 -- mức 4: cha của cha
		LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg4 ON rg4.ResolutionGroupId = rg3.ParentGroupId 
		AND rg4.IsRoot = 0
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
		AND ( ( main.loaicap_dvgiao NOT IN ('Sở ngành', 'Xã, Phường', 'Nhóm Sở ngành mở rộng') ) OR main.loaicap_dvgiao IS NULL )
		)
		OR
		(main.loaicapcha_dvgiao = 'Thành ủy Hà Nội'
		AND main.loaicap_dvgiao <> 'Đảng bộ trực thuộc'
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
ORDER BY 
    main.`year`,
    main.monthkey,
    main.`date`,
    main.Ma
;