/* Bảng phân quyền người dùng: đồng bộ từ qlnv_user + tên phòng ban.
   Cột permission (danh sách quyền dạng chuỗi JSON) mặc định = [DepartmentPath] của người dùng,
   chỉ điền khi đang NULL => quyền nhập tay sau này KHÔNG bị ghi đè. */
CREATE TABLE IF NOT EXISTS `datamart_hanoi`.`qlnv_phanquyen_user` (
    user_id              VARCHAR(36)  NOT NULL,
    user_name            VARCHAR(255),
    egov_user_id         INT,
    ho_ten               VARCHAR(255),
    email                VARCHAR(255),
    chuc_vu              VARCHAR(255),
    chuc_vu_level        INT,
    department_path      VARCHAR(255),
    phong_ban_id         BIGINT,
    ten_phong_ban        VARCHAR(255),
    duong_dan_phong_ban  VARCHAR(1000),
    is_super_admin       TINYINT(1),
    permission           TEXT NULL,
    sync_date            DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    KEY idx_user_name (user_name),
    KEY idx_egov_user_id (egov_user_id),
    KEY idx_phong_ban_id (phong_ban_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `datamart_hanoi`.`qlnv_phanquyen_user` (
    user_id, user_name, egov_user_id, ho_ten, email, chuc_vu, chuc_vu_level,
    department_path, phong_ban_id, ten_phong_ban, duong_dan_phong_ban,
    is_super_admin, permission, sync_date
)
SELECT
    u.Id                    AS user_id,
    u.UserName              AS user_name,
    u.eGovUserId            AS egov_user_id,
    u.eGovUserFullname      AS ho_ten,
    u.Email                 AS email,
    u.eGovUserPositionName  AS chuc_vu,
    u.eGovUserPositionLevel AS chuc_vu_level,
    u.DepartmentPath        AS department_path,
    d.id                    AS phong_ban_id,
    d.name                  AS ten_phong_ban,
    d.departmentpath        AS duong_dan_phong_ban,
    u.IsSuperAdmin          AS is_super_admin,
    CASE WHEN COALESCE(u.DepartmentPath, '') <> ''
         THEN CONCAT('["', u.DepartmentPath, '"]')
    END                     AS permission,
    '${sync_ts}'            AS sync_date
FROM `db_theodoinv_hn`.`qlnv_user` u

/* PHÒNG BAN CỦA NGƯỜI DÙNG = ID CUỐI CỦA DepartmentPath (vd 490.695.701.710 -> 710) */
LEFT JOIN `db_theodoinv_hn`.`department` d
       ON d.id = CASE
            WHEN SUBSTRING_INDEX(u.DepartmentPath, '.', -1) REGEXP '^[0-9]+$'
            THEN CAST(SUBSTRING_INDEX(u.DepartmentPath, '.', -1) AS UNSIGNED)
            ELSE NULL
          END

ON DUPLICATE KEY UPDATE
    user_name           = VALUES(user_name),
    egov_user_id        = VALUES(egov_user_id),
    ho_ten              = VALUES(ho_ten),
    email               = VALUES(email),
    chuc_vu             = VALUES(chuc_vu),
    chuc_vu_level       = VALUES(chuc_vu_level),
    department_path     = VALUES(department_path),
    phong_ban_id        = VALUES(phong_ban_id),
    ten_phong_ban       = VALUES(ten_phong_ban),
    duong_dan_phong_ban = VALUES(duong_dan_phong_ban),
    is_super_admin      = VALUES(is_super_admin),
    permission          = COALESCE(permission, VALUES(permission)),
    sync_date           = VALUES(sync_date);
