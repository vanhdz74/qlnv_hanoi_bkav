========================================================================================================================
                                             TẦNG NGƯỜI DÙNG & TỔ CHỨC (CLIENTS)
========================================================================================================================
             [ Khách Hàng Cá Nhân ]                                    [ Khách Hàng Doanh Nghiệp (Tenants) ]
         (Role: individual_user, Solo Plan)                        (Công ty A, B... | Role: org_admin, org_member)
                         │                                                                │
                         └───────────────────────────────┬────────────────────────────────┘
                                                         │ HTTPS / DNS Root (.yourdomain.com)
                                                         ▼
========================================================================================================================
                                        TẦNG GIAO DIỆN HỢP NHẤT (UNIFIED APP SHELL)
========================================================================================================================
 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │  NEXT.JS CENTRAL HUB PORTAL (portal.yourdomain.com | Port 3000)                                                    │
 │                                                                                                                    │
 │  ┌───────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐  ┌───────────────────────────┐  │
 │  │      SSO LOGIN        │  │     APP LAUNCHER       │  │   BILLING & LICENSES   │  │   QUẢN TRỊ TỔ CHỨC        │  │
 │  │  • PKCE OAuth2 Flow   │  │  • Grid Icon dịch vụ   │  │  • Gói Solo / Combo    │  │  • Mời thành viên qua mail│  │
 │  │  • Nhận JWT Token     │  │  • Bật/Tắt theo License│  │  • Gói Seat Doanh Nghiệp│ │  • Gán quyền phòng ban    │  │
 │  └───────────────────────┘  └────────────────────────┘  └────────────────────────┘  └───────────────────────────┘  │
 └─────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┘
                                           │ Request kèm Bearer JWT Token
                                           ▼
========================================================================================================================
                                    TẦNG ĐIỀU PHỐI & DỊCH VỤ NỀN TẢNG (PLATFORM CORE)
========================================================================================================================
 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 │  CENTRAL API GATEWAY (Kong / Traefik / Nginx Reverse Proxy)                                                        │
 │  • Giải mã & Thẩm định tính hợp lệ của JWT              • Rate Limiting & Routing theo Context Path/Subdomain      │
 └─────────────┬───────────────────────────────────┬──────────────────────────────────┬───────────────────────────────┘
               │                                   │                                  │
               ▼                                   ▼                                  ▼
 ┌───────────────────────────┐       ┌───────────────────────────┐      ┌─────────────────────────────────────────────┐
 │    KEYCLOAK IAM & SSO     │       │    BILLING & ENTITLEMENT  │      │              SHARED EVENT BUS               │
 │  (Port 8080 / PostgreSQL) │       │          SERVICE          │      │             (Kafka / RabbitMQ)              │
 │ • Realm: ecosystem-realm  │◄─────►│ • Tạo gói, thanh toán     │◄────►│ • Đồng bộ Tenant tạo mới                    │
 │ • Quản lý User & Tenant   │ API   │ • Kích hoạt User License  │Event │ • Sự kiện: LicenseUpdated, UserInvited      │
 │ • Cấp Token chứa Claims   │       │ • Đồng bộ attribute IAM   │      │ • Giao tiếp bất đồng bộ giữa các Spoke      │
 └─────────────┬─────────────┘       └───────────────────────────┘      └──────────────────────┬──────────────────────┘
               │ Public Keys (JWKS URI)                                                        │ Lắng nghe
               └───────────────────────────────────┬───────────────────────────────────────────┘ Sự kiện
                                                   │
                                                   ▼
========================================================================================================================
                                 TẦNG DỊCH VỤ THÀNH VIÊN (SPOKES / RESOURCE SERVERS)
========================================================================================================================
        ┌───────────────────────────────────────────┐                   ┌───────────────────────────────────────────┐
        │        SPOKE 1: COURSEDEMY                │                   │         SPOKE 2: VIHOTASK                 │
        │   (courses.yourdomain.com | Port 3001)    │                   │    (tasks.yourdomain.com | Port 3002)     │
        ├───────────────────────────────────────────┤                   ├───────────────────────────────────────────┤
        │ • Frontend: Next.js App                   │                   │ • Frontend: Next.js App                   │
        │ • Backend:  Java Spring Boot (Port 8081)  │                   │ • Backend:  Quarkus Native (Port 8082)    │
        │ • Auth:     spring-boot-oauth2-resource   │                   │ • Auth:     quarkus-oidc                  │
        │ • Security Filter:                        │                   │ • Security Filter:                        │
        │     - Kiểm tra claim: "coursedemy"        │                   │     - Kiểm tra claim: "vihotask"          │
        │     - Tách "tenant_id" cho DB Queries     │                   │     - Tách "tenant_id" cho DB Queries     │
        │ • Database: Course DB (Multi-tenant Data) │                   │ • Database: Task DB (Multi-tenant Data)   │
        └───────────────────────────────────────────┘                   └───────────────────────────────────────────┘
                                           ▲                                     ▲
                                           │                                     │
                                           └──────────────────┬──────────────────┘
                                                              │ Cắm thêm ứng dụng mới
                                                              ▼
                                                ┌───────────────────────────┐
                                                │    SPOKE N (PLUG & PLAY)  │
                                                │ (CRM / Chat / HRM...)     │
                                                │ • Chuẩn OIDC + Manifest   │
                                                └───────────────────────────┘