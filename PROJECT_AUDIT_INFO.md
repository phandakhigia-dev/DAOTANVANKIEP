# TÀI LIỆU TOÀN DIỆN AUDIT DỰ ÁN (PROJECT AUDIT INFO)
**Dự án:** ĐẠO TÀN: VẠN KIẾP (Dao Tan: Van Kiep)  
**Phiên bản dự án:** `0.0.1` (Schema v2)  
**Ngày thực hiện Audit:** 04/11/2026  
**Chuyên gia thực hiện:** Senior Game Developer, Godot Architect & Technical QA Auditor  

---

## 1. TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)

"ĐẠO TÀN: VẠN KIẾP" là tựa game **2D Top-down Xianxia Sandbox RPG** được phát triển độc quyền bằng engine mã nguồn mở **Godot 4.7.2** trên nền tảng **Windows PC Native**.

### Triết lý thiết kế cốt lõi:
1. **Thế Giới Tu Chân Xác Định (Deterministic Sandbox):** Vận hành trên một luồng hạt giống toàn cục (`world_seed`), đảm bảo mọi quy luật thời tiết, quặng khoáng, phân bố yêu thú và chu kỳ mùa màng có tính tái lặp tuyệt đối.
2. **Sinh Lão Bệnh Tử & Nhân Sinh Độc Bản (Dynamic Mortality & Living Ecology):** NPC không phải bù nhìn đứng yên; họ có tuổi thọ giới hạn, kinh mạch, khát vọng sống (`core_drive`), bí mật dị duyên (`life_secret`), thói quen cá nhân (`quirk`), quan hệ xã hội (ái, ố, ân, oán) và tiến trình tu vi tự hành theo tháng (`MonthlySimulationService`).
3. **Vấn Đạo Luận Thế (Branching World-Shaping Dialogue):** Đối thoại 5 nhánh triết lý tu chân (Chính Đạo, Ma Đạo, Thương Lộ, Đạo Duyên, Bình Thản) với cơ chế nhân quả bí mật, không gợi ý số liệu trước, tác động trực tiếp lên kinh tế thị trấn (`market_modifiers`), ký ức thế giới (`log_memory_event`) và đột phá tu vi NPC.
4. **Đồng Hồ Thời Gian Thực Đồng Bộ (Authoritative World Clock):** **1 ngày trong game = 720 giây thực tế (12 phút)**. Hỗ trợ chu kỳ 12 Canh Giờ âm dương ngày đêm, gia tốc tĩnh tọa x20 và khóa chặt thời gian trong chế độ Co-op Multiplayer.

---

## 2. ENGINE & DEPENDENCIES

- **Game Engine:** Godot Engine `v4.7.2.stable.official.ed1daf0bf`.
- **Ngôn ngữ lập trình:** GDScript 4 (tận dụng Static Typing, Signals, Callables, Match pattern, Class_name).
- **Backend Đồ họa (Renderer):** `gl_compatibility` (OpenGL 3.3 / WebGL tương thích cao, tối ưu cho đồ họa 2D Pixel / Ink-wash).
- **Độ phân giải chuẩn (Viewport):** `1920x1080` (Full HD), override cửa sổ `1280x720`, Stretch Mode `canvas_items` với Aspect `keep`.
- **Dependencies ngoài:** **0 dependency C++ ngoài**. Toàn bộ mã nguồn, dịch vụ âm thanh procedural PCM, shader hạt VFX và thuật toán mô phỏng đều thuần GDScript nội sinh, đảm bảo mở là chạy ngay trên bất kỳ máy tính cài đặt Godot 4.7+.

---

## 3. CẤU TRÚC THƯ MỤC DỰ ÁN (DIRECTORY STRUCTURE)

```
DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/
├── project.godot                     # File cấu hình engine, autoloads, input map, display
├── AGENTS.md                         # Quy tắc và hướng dẫn pair-programming của dự án
├── IMPLEMENTATION_PLAN.md            # Lộ trình kỹ thuật các Phase & Sprint
├── README_START_HERE.md              # Tài liệu khởi động dự án
├── PROJECT_AUDIT_INFO.md             # [Audit] Tổng quan dự án, kiến trúc & hướng dẫn chạy
├── FEATURE_STATUS.md                 # [Audit] Bảng ma trận trạng thái tất cả các tính năng
├── audit/                            # [Audit] Thư mục chứa toàn bộ báo cáo chuyên sâu
│   ├── KNOWN_ISSUES.md               # Danh sách lỗi tồn đọng, rủi ro kỹ thuật & cách xử lý
│   ├── PHASE4_ASSET_STATUS.md        # Thống kê hiện trạng Sprites, Tilesets, VFX, Audio
│   ├── MULTIPLAYER_TIME_AUDIT.md     # Thẩm định thời gian, kiến trúc Co-op, chống dup đồ
│   ├── TEST_RESULTS.md               # Nhật ký kết quả 147 test tự động (100% PASS)
│   └── FILE_MANIFEST.csv             # Bảng kiểm kê mã băm SHA-256 toàn bộ file đóng gói
├── audit_exports/                    # Thư mục chứa gói ZIP xuất bản hoàn chỉnh
├── assets/                           # Tài nguyên đồ họa biểu tượng và bảng màu
│   ├── palette.hex / palette.png     # Bảng màu 32 màu cổ phong thủy mặc wuxia
│   └── sprites/icons/                # 20+ icons trang bị, đan dược, phù lục, linh tài
├── audio/                            # Tài nguyên âm thanh (kèm bộ tổng hợp procedural)
├── data/                             # Cơ sở dữ liệu JSON định hình thế giới
│   ├── balance.json                  # Bảng chỉ số căn bản 10 tầng cảnh giới
│   ├── enemies/                      # Dữ liệu quái vật thường và Boss
│   ├── factions/                     # Danh sách môn phái và thế lực
│   ├── items/                        # Kho vật phẩm, dược thảo, khoáng thạch, đan dược
│   ├── npcs/                         # Hồ sơ chi tiết 6 NPC cốt truyện Thanh Trì
│   ├── quests/                       # Chuỗi nhiệm vụ chính tuyến & ủy thác
│   ├── recipes/                      # Đan phương luyện chế lò đan
│   ├── regions/                      # Bản đồ vùng đất và danh mục POI
│   ├── sects/                        # Dữ liệu môn phái, nhiệm vụ cống hiến, tàng kinh các
│   └── skills/                       # Kỹ năng võ công và chiêu thức kiếm pháp
├── docs/                             # Tài liệu GDD, World Lore, Combat & Test Reports
├── scenes/                           # Cây Scene phân tầng theo ngữ cảnh
│   ├── biomes/                       # 3 Phân vùng dã ngoại (Rừng Trúc, Đầm Lầy, Kiếm Trũng)
│   ├── bootstrap/                    # Scene khởi động kiểm tra hệ thống
│   ├── combat/                       # Đấu trường chiến đấu thời gian thực Combat Arena
│   ├── cultivation/                  # Đấu trường lôi kiếp Thiên Kiếp Đột Phá
│   ├── menu/                         # Menu chính, New Game Modal, Cài đặt âm thanh
│   ├── sects/                        # Đại Điện Tông Môn Thanh Vi Tông
│   ├── towns/                        # Bản đồ Thị Trấn Thanh Trì & NPC vật lý
│   ├── ui/                           # Toàn bộ Modal (Túi đồ, Đan đạo, Sạp hàng, Hội thoại)
│   ├── vfx/                          # 5 Scene hiệu ứng kiếm khí, đột phá, sấm sét, lá trúc
│   └── world/                        # Bản đồ thế giới World Map, Player, HUD
├── scripts/                          # Mã nguồn GDScript phân tách lớp chặt chẽ
│   ├── core/                         # Autoload lõi (GameClock, GameSession, ContentRegistry...)
│   ├── domain/                       # Logic nghiệp vụ (LifeGenerator, Alchemy, Shop, Dialogue...)
│   ├── network/                      # Mạng Co-op (SessionAuthority, ClockReplication)
│   └── persistence/                  # Lưu trữ Atomic Save/Load (SaveService)
├── tests/                            # Bộ kiểm thử tự động toàn diện (147 Tests PASS)
│   ├── unit/                         # 21 test suites đơn vị và tích hợp
│   ├── test_runner.gd / .tscn        # Headless Test Runner chính thức
│   └── capture_*.gd                  # Các kịch bản chụp ảnh kiểm thử giao diện
└── wuxia/                            # Bộ tileset và props 32x32 cổ phong phong cách thủy mặc
```

---

## 4. ENTRY POINT & CÁCH VẬN HÀNH

### A. Khởi chạy Game:
- **Main Entry Scene:** `res://scenes/bootstrap/bootstrap.tscn`.
- Bootstrap scene tự động kiểm tra tính sẵn sàng của `ContentRegistry`, khởi tạo hạt giống `GameSession`, và chuyển mượt mà tới `res://scenes/menu/main_menu.tscn`.

### B. Danh sách Autoloads (Đăng ký trong `project.godot`):
1. `ContentRegistry` (`scripts/core/content_registry.gd`): Tải và tra cứu dữ liệu JSON toàn bộ thế giới (vật phẩm, NPC, quái vật, kỹ năng, đan phương, môn phái).
2. `EventBus` (`scripts/core/event_bus.gd`): Cầu nối tín hiệu toàn cục Decoupled Event Architecture.
3. `GameClock` (`scripts/core/game_clock.gd`): Đồng hồ thế giới thời gian thực (1 ngày = 720s, Canh giờ, Tĩnh tọa gia tốc).
4. `RNGService` (`scripts/core/rng_service.gd`): Máy sinh số ngẫu nhiên có hạt giống xác định.
5. `SaveService` (`scripts/persistence/save_service.gd`): Hệ thống lưu/tải tệp nguyên tử (Atomic Write `.tmp` -> Rename) chống hỏng save.
6. `GameSession` (`scripts/core/game_session.gd`): Trạng thái runtime của phiên chơi (Nhân vật, Túi đồ, Hảo cảm, Quan hệ, Ký ức, Thị trường).
7. `MonthlySimulationService` (`scripts/domain/monthly_simulation_service.gd`): Bộ máy mô phỏng thế giới hàng tháng (Vòng đời, Utility AI, Đột phá, Tin đồn).
8. `SessionAuthority` (`scripts/network/session_authority.gd`): Quản lý quyền lực máy chủ / máy khách trong phiên Co-op.
9. `ClockReplication` (`scripts/network/clock_replication.gd`): Đồng bộ thời gian qua mạng và thực thi khóa Time-Skip nghiêm ngặt.
10. `AudioService` (`scripts/core/audio_service.gd`): Dịch vụ phát âm thanh và nhạc nền tổng hợp trực tiếp bằng sóng âm 16-bit PCM.

### C. Cách chạy Kiểm Thử Tự Động (Headless Test Runner):
Chạy lệnh sau tại thư mục gốc dự án:
```powershell
& "path/to/godot.cmd" --headless --path . --scene "res://tests/test_runner.tscn"
```
*Kết quả hiện tại:* **147 ĐẠT (PASS) | 0 THẤT BẠI (FAIL) | 100% SUCCESS**.

---

## 5. KIẾN TRÚC HỆ THỐNG GAME (ARCHITECTURE OVERVIEW)

Kiến trúc được xây dựng theo mô hình **Domain-Driven Layered Architecture**:
1. **Core / Platform Layer:** Quản lý vòng đời ứng dụng, sự kiện, thời gian, lưu trữ file hệ thống.
2. **Domain Service Layer:** Chứa toàn bộ nghiệp vụ thuần túy không gắn chặt với UI (kinh tế sạp hàng, thuật luyện đan, tạo dựng nhân sinh, mô phỏng thế giới, kịch bản hội thoại).
3. **Data Layer:** Dữ liệu bất biến lưu trữ dưới dạng JSON sạch (`data/`), cho phép modding hoặc cân bằng chỉ số dễ dàng mà không cần sửa mã nguồn.
4. **Presentation / Scene Layer:** Các Node 2D, TileMap, Viewport, Control Nodes được tách biệt. Mọi giao tiếp với tầng Domain đều thông qua API Service hoặc EventBus.
5. **Network Layer:** Thiết kế theo mô hình **Host-Authoritative**. Host đóng vai trò Server điều phối thời gian thế giới và quyết toán giao dịch.

---

## 6. TÌNH TRẠNG KẾT NỐI CO-OP MULTIPLAYER

- **Đã hoàn thành (Sprint S1):**
  - Đồng bộ đồng hồ thế giới host-authoritative: Host làm chuẩn, Client nội suy delta.
  - Cơ chế khóa chặt `is_time_skip_locked`: Khi phát hiện có từ 2 người chơi trong session, tính năng tua nhanh thời gian (tĩnh tọa x20) lập tức bị vô hiệu hóa để ngăn ngừa desync.
  - Ngắt kết nối an toàn: Tự động đưa game về chế độ Standalone khi mất kết nối mạng.
- **Đã hoàn thành (Sprint S2/S3):**
  - Chợ Tán Tu & Sạp Hàng Tu Sĩ (`ShopService`): Ký gửi kho vật phẩm (Escrow pattern), giao dịch nguyên tử mua/bán, quyết toán doanh thu chống nhân đôi tài sản.
- **Kế hoạch tiếp theo (Phase 1 Roadmap):**
  - Triển khai ENetMultiplayerPeer / WebSocket hoàn chỉnh cho peer entity replication, chat đồng đội và phối hợp khiêu chiến bí cảnh.

---

## 7. CÁC THAY ĐỔI LỚN SO VỚI BLUEPRINT BAN ĐẦU

1. **Mở Rộng Đa Phân Vùng Bí Cảnh (Phase 2):** Thay vì chỉ có thị trấn và dã ngoại chung chung, dự án đã xây dựng trọn vẹn 3 phân vùng với cơ chế Smart Objects độc đáo: Rừng Trúc Vạn Lĩnh (thu hái mộc linh, rương thạch động), Đầm Lầy Hắc Xà (tế đàn hiến tế xà cốt), Cổ Kiếm Trũng (bia kiếm đốn ngộ tu vi, kiếm trận thạch đài).
2. **Tông Môn & Thiên Kiếp Lôi Phạt (Phase 3):** Bổ sung hệ thống Tông Môn hoàn chỉnh (Thanh Vi Tông & Bách Thảo Môn), thăng cấp đệ tử ngoại môn -> nội môn dựa trên cống hiến, học võ học tại Tàng Kinh Các, và **Đấu trường Lôi Kiếp 9 đợt sấm sét** khi xung kích Trúc Cơ Sơ Kỳ.
3. **Thủy Mặc Võ Hiệp & Audio Sinh Học (Phase 4):** Xây dựng bộ hiệu ứng kiếm khí, linh trận hoàng kim, lôi bạo điểm giáng, đan khí xuất lô và hệ thống tự động tổng hợp 8 hiệu ứng âm thanh PCM 16-bit võ hiệp mà không phụ thuộc file âm thanh bên ngoài.
4. **Vấn Đạo Luận Thế 5 Nhánh Ẩn:** Mở rộng hệ thống hội thoại thành 5 nhánh triết lý tu chân thuần lời thoại, ẩn hoàn toàn thông tin được/mất nhằm kích thích cảm giác kỳ ngộ bí mật khó lường theo yêu cầu người chơi.
