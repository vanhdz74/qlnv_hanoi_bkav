TRUNCATE TABLE datamart_hanoi.qlnv_th_tongquan_donvi_tiepnhan;
INSERT INTO datamart_hanoi.qlnv_th_tongquan_donvi_tiepnhan 
SELECT
main.monthkey AS monthkey,
main.loaicapcha_dvgiao AS loaicapcha_dvgiao,
main.loaicap_dvgiao AS loaicap_dvgiao,
main.iddv_dvgiao AS iddv_dvgiao,
main.donvi_dvgiao AS donvi_dvgiao,
main.tenviettat_dvgiao AS tenviettat_dvgiao,
main.loaicapcha AS loaicapcha,
main.loaicap AS loaicap,
main.iddv AS iddv,
main.donvi AS donvi,
main.tenviettat AS tenviettat,
main.VanBanGiaoNhiemVu AS VanBanGiaoNhiemVu,
main.LinhVuc AS LinhVuc,
main.Kieu AS Kieu,
main.tongso AS tongso,
main.daht AS daht,
main.daht_dh AS daht_dh,
main.daht_qh AS daht_qh,
main.daht_kh AS daht_kh,
main.dangth AS dangth,
main.dangth_th AS dangth_th,
main.dangth_qh AS dangth_qh,
main.dangth_sqh AS dangth_sqh,
main.dangth_kh AS dangth_kh,
main.nhomvb_ma AS nhomvb_ma,
main.nhomvb AS nhomvb,
main.syncdate AS syncdate

FROM (
SELECT 
    DATE_FORMAT(COALESCE(t.CompletedDate,t.ExpireDate,t.CreatedDate), '%Y%m') + 0 AS monthkey,
		CASE
				WHEN t.AssignDepartment LIKE '490.695%'  THEN 'Thành ủy Hà Nội'
				WHEN t.AssignDepartment LIKE '490.1775%' THEN 'HĐND Thành phố'
				WHEN t.AssignDepartment LIKE '490.1790%' THEN 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
				WHEN t.AssignDepartment LIKE '490.698%'  THEN 'UBND Thành phố'
				ELSE 'Khác'
		END AS loaicapcha_dvgiao,
		NULL AS loaicap_dvgiao,
    dv_giao.DepartmentId AS iddv_dvgiao,
    IFNULL(dv_giao.DepartmentName ,'Chưa xác định') AS donvi_dvgiao,
    
		IFNULL(dv_giao.DepartmentShortName ,'Chưa xác định')  AS tenviettat_dvgiao,
		
		CASE
				WHEN t.TargetDepartment LIKE '490.695%'  THEN 'Thành ủy Hà Nội'
				WHEN t.TargetDepartment LIKE '490.1775%' THEN 'HĐND Thành phố'
				WHEN t.TargetDepartment LIKE '490.1790%' THEN 'Ủy ban MTTQ Việt Nam thành phố Hà Nội'
				WHEN t.TargetDepartment LIKE '490.698%'  THEN 'UBND Thành phố'
				ELSE 'Khác'
		END AS loaicapcha,
		NULL AS loaicap,
    d.DepartmentId AS iddv,
    IFNULL(d.DepartmentName ,'Chưa xác định') AS donvi,
    
		IFNULL(d.DepartmentShortName ,'Chưa xác định')  AS tenviettat,
		CASE
        WHEN t.DocCode LIKE "Số %" THEN REPLACE(t.DocCode,"Số ","")
				WHEN t.DocCode IS NOT NULL AND t.DocCode <> "" AND t.DocCode <> " " THEN t.DocCode
        ELSE 'Không xác định'
    END AS VanBanGiaoNhiemVu,
		s.SectorName AS LinhVuc,
		CASE
        WHEN r.Type = 1 THEN 'Chỉ thị'
        WHEN r.Type = 2 THEN 'Nghị quyết'
				WHEN r.Type = 3 THEN 'Công văn'
				WHEN r.Type = 4 THEN 'Kết luận'
				WHEN r.Type = 5 THEN 'Thông báo'
        ELSE 'Không xác định'
    END AS Kieu,

    /* Tổng số */
    COUNT(*) AS tongso,

    /* Nhóm đã hoàn thành (Status = 4) */
    SUM(CASE WHEN t.Status IN (3,4) THEN 1 ELSE 0 END) AS daht,
    SUM(CASE WHEN t.Status IN (3,4) AND COALESCE(t.CompletedDate, t.ApprovedDate)  <= t.ExpireDate THEN 1 ELSE 0 END) AS daht_dh,
    SUM(CASE WHEN t.Status IN (3,4) AND COALESCE(t.CompletedDate, t.ApprovedDate)  > t.ExpireDate THEN 1 ELSE 0 END) AS daht_qh,
		NULL as daht_kh,
    /* Nhóm đang thực hiện (Status in -1,0,1,2,3) */
    SUM(CASE WHEN t.Status IN (-1,0,1,2) THEN 1 ELSE 0 END) AS dangth,
    SUM(CASE WHEN t.Status IN (-1,0,1,2) AND t.ExpireDate >= NOW() AND DATEDIFF(t.ExpireDate, NOW()) > 1 THEN 1 ELSE 0 END) AS dangth_th,
    SUM(CASE WHEN t.Status IN (-1,0,1,2) AND t.ExpireDate < NOW() THEN 1 ELSE 0 END) AS dangth_qh,
		SUM(CASE WHEN t.Status IN (-1,0,1,2) AND t.ExpireDate >= NOW() AND DATEDIFF(t.ExpireDate, NOW()) <= 1 THEN 1 ELSE 0 END) AS dangth_sqh,
		NULL AS dangth_kh,
		
		COALESCE(rg4.ResolutionGroupId,rg3.ResolutionGroupId,rg2.ResolutionGroupId,rg1.ResolutionGroupId,rg.ResolutionGroupId) AS nhomvb_ma,
		COALESCE(rg4.Name,rg3.Name,rg2.Name,rg1.Name,rg.Name)  AS nhomvb,
		NOW() AS syncdate

FROM db_theodoinv_hn.qlnv_task t
	LEFT JOIN datamart_hanoi.department d ON d.DepartmentIdExt = t.TargetDepartment
	LEFT JOIN datamart_hanoi.department dv_giao ON dv_giao.DepartmentIdExt = t.AssignDepartment
	LEFT JOIN db_theodoinv_hn.qlnv_resolution r ON t.ResolutionId = r.ResolutionId
	LEFT JOIN db_theodoinv_hn.qlnv_sector s ON s.SectorId = r.SectorId
	LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg ON r.ResolutionGroupId = rg.ResolutionGroupId -- mức 1: cha
	LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg1 ON rg1.ResolutionGroupId = rg.ParentGroupId 
	AND rg1.IsRoot = 0 -- mức 2: cha của cha
	LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg2 ON rg2.ResolutionGroupId = rg1.ParentGroupId 
	AND rg2.IsRoot = 0 -- mức 3: cha của cha
	LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg3 ON rg3.ResolutionGroupId = rg2.ParentGroupId 
	AND rg3.IsRoot = 0 -- mức 4: cha của cha
	LEFT JOIN db_theodoinv_hn.qlnv_resolution_group rg4 ON rg4.ResolutionGroupId = rg3.ParentGroupId 
	AND rg4.IsRoot = 0
WHERE
    t.Status <> 5
    AND t.DeletedDate IS NULL
GROUP BY 
    DATE_FORMAT(COALESCE(t.CompletedDate,t.ExpireDate,t.CreatedDate), '%Y%m'),
		t.AssignDepartment,
    t.TargetDepartment,
		t.DocCode
		) main
ORDER BY 
    monthkey,
    iddv;