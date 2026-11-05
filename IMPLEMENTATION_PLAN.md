# IMPLEMENTATION PLAN — PHASE 0: FOUNDATION (ĐẠO TÀN: VẠN KIẾP)

**Mục tiêu:** Xây dựng nền móng kỹ thuật chuẩn Godot 4.7.x GDScript theo kiến trúc data-driven của blueprint.
**Phạm vi:** Chỉ Phase 0. Không làm trước hệ thống chiến đấu phức tạp hay mô phỏng NPC của Phase 1+.

---

## Danh sách Task chi tiết

### Task 1: Thiết lập cấu trúc thư mục & Quản lý dự án
- **Target:** `project.godot`, `docs/IMPLEMENTATION_STATUS.md`, `docs/KNOWN_ISSUES.md`, `docs/CHANGELOG.md`, `docs/TEST_REPORTS/`
- **Nội dung:** Khởi tạo project file của Godot 4.7.2, cấu hình display 1920x1080 (canvas_items / keep), cấu hình Autoloads, action inputs (WASD, pause, interact).
- **DoD:** Godot headless parse project không báo lỗi.

### Task 2: Core Domain & Services (Data-Driven Architecture)
- **Target:**
  - `scripts/core/event_bus.gd`: Các signals toàn cục phục vụ giao tiếp giữa các tầng.
  - `scripts/core/game_clock.gd`: Quản lý thời gian game (30 ngày = 1 tháng, năm, ngày, chuyển ngày deterministic).
  - `scripts/core/rng_service.gd`: Sinh số ngẫu nhiên theo seed xác định cho thế giới.
  - `scripts/core/content_registry.gd`: Load và validate dữ liệu tĩnh từ JSON (`data/`).
  - `scripts/core/game_session.gd`: Quản lý runtime world state (seed, player data, world map state).
  - `scripts/persistence/save_service.gd`: Lưu/tải game atomic (ghi qua file `.tmp` rồi đổi tên), quản lý `schema_version = 1`, file meta, backup `.bak`.
- **DoD:** Viết unit test độc lập kiểm chứng Save/Load roundtrip, GameClock tính ngày tháng, RNG seed deterministic.

### Task 3: Data Layer & Templates
- **Target:**
  - `data/balance.json`: Định nghĩa cảnh giới tu vi khởi đầu (Phàm Nhân, Luyện Khí), chỉ số cơ bản.
  - `data/regions/region_thanh_tri.json`: Dữ liệu vùng Thanh Trì Trấn, danh sách POI (Thanh Trì Trấn, Sen Hồ, Vân Lĩnh Biên, Rừng Trúc).
- **DoD:** `ContentRegistry` load hợp lệ và validate không thiếu trường bắt buộc.

### Task 4: UI & Màn hình Menu (Presentation Layer)
- **Target:**
  - `scenes/bootstrap/bootstrap.tscn` + `bootstrap.gd`: Màn hình nạp tài nguyên ban đầu và chuyển cảnh.
  - `scenes/menu/main_menu.tscn` + `main_menu.gd`: Menu chính chuẩn tiếng Việt: Khởi Đầu Mới, Tiếp Tục, Cài Đặt, Thoát.
  - `scenes/menu/settings_modal.tscn` + `settings_modal.gd`: Cài đặt âm lượng, độ phân giải màn hình.
  - `scenes/menu/new_game_modal.tscn` + `new_game_modal.gd`: Tạo nhân vật, chọn / random seed thế giới.
- **DoD:** Mở menu mượt mà, chuyển qua lại không rò rỉ bộ nhớ, nút Continue tự disable nếu chưa có save.

### Task 5: Bản đồ Thế giới & Điều khiển Nhân vật (World Map & Player Movement)
- **Target:**
  - `scenes/world/world_map.tscn` + `world_map.gd`: Bản đồ sandbox khởi đầu dạng lưới được sinh theo seed.
  - `scenes/world/player.tscn` + `player.gd`: CharacterBody2D di chuyển 8 hướng mượt mà, va chạm vật lý, camera 2D theo dõi nhân vật.
  - `scenes/world/hud.tscn` + `hud.gd`: Hiển thị tên nhân vật, cảnh giới, thanh HP, thời gian (Năm - Tháng - Ngày), Tọa độ, Seed.
  - `scenes/world/pause_menu.tscn` + `pause_menu.gd`: Tạm dừng game, Lưu game, Thiết lập, Thoát về Menu.
- **DoD:** Người chơi di chuyển tự do bằng phím WASD / Mũi tên; phím ESC mở menu tạm dừng không kẹt phím; bấm Lưu game ghi dữ liệu đúng vị trí nhân vật và ngày hiện tại.

### Task 6: Kiểm thử tự động & Báo cáo QA
- **Target:**
  - `tests/runner.gd`: Bộ điều phối test chạy headless.
  - `tests/unit/test_save_roundtrip.gd`
  - `tests/unit/test_deterministic_seed.gd`
  - `tests/unit/test_game_clock.gd`
  - `docs/TEST_REPORTS/PHASE_00.md`
- **DoD:** Lệnh `godot --headless -s tests/runner.gd --quit` chạy 100% pass; `godot --headless --quit-after 120` khởi chạy game không crash.
