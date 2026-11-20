ALTER TABLE `datamart_hanoi`.`nq57_bao_cao`
  ADD COLUMN han_nop_luc DATETIME NULL COMMENT 'giờ VN, hạn có giờ do hệ thống tính',
  ADD COLUMN den_han INT NULL,
  ADD COLUMN nhap_dau_luc DATETIME NULL COMMENT 'giờ VN',
  ADD COLUMN gui_duyet_luc DATETIME NULL COMMENT 'giờ VN',
  ADD COLUMN so_lan_lanh_dao_khong_duyet BIGINT NULL,
  ADD COLUMN so_lan_tra_lai BIGINT NULL,
  ADD COLUMN so_lan_huy_tiep_nhan BIGINT NULL,
  ADD COLUMN so_bieu_phai_nop BIGINT NULL,
  ADD COLUMN so_bieu_da_tiep_nhan BIGINT NULL,
  ADD COLUMN lech_han_phut INT NULL,
  ADD COLUMN nap_lui TINYINT NULL COMMENT '1 = nạp lùi (nhập bù), không xét hạn'
