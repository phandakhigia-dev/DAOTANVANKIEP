# ĐẠO TÀN: VẠN KIẾP — HƯỚNG DẪN DÀNH CHO CHATGPT (PROJECT ARCHITECTURE & CONTEXT MANUAL)

> **Dành cho ChatGPT / AI Assistant:** Đây là tài liệu định hướng toàn diện về kiến trúc, mã nguồn, dữ liệu và trạng thái phát triển của dự án game **ĐẠO TÀN: VẠN KIẾP**. Khi người dùng tải file ZIP này lên, hãy đọc tài liệu này trước tiên để nắm bắt toàn bộ ngữ cảnh mà không cần phải đoán.

---

## 1. TỔNG QUAN DỰ ÁN
- **Tên trò chơi:** Đạo Tàn: Vạn Kiếp (*Tao's End: Ten Thousand Kalpas*)
- **Thể loại:** Wuxia / Xianxia Open World Sandbox RPG (Kiếm hiệp - Tiên hiệp thế giới mở, góc nhìn Top-Down 2D kết hợp nhịp điệu sinh tồn, buôn bán, tu chân, gia tộc và triều đình).
- **Game Engine:** **Godot Engine v4.7.2 (Renderer: Compatibility, Target: Windows PC)**.
- **Ngôn ngữ lập trình:** **GDScript 2.0 (Bắt buộc Static Typing chặt chẽ)**.
- **Tiêu chuẩn chất lượng:** **100% Test Pass Rate** (Hiện tại: **211/211 tests ĐẠT across 30 suites**, 0 test FAIL).
- **GitHub Repository:** `https://github.com/phandakhigia-dev/DAOTANVANKIEP.git`

---

## 2. CẤU TRÚC THƯ MỤC CHÍNH
```text
DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/
├── project.godot               # Cấu hình dự án Godot (Pixel snapping, Input map, Autoloads)
├── CHATGPT_INSTRUCTION_MANUAL.md # Chính là file tài liệu này
├── data/                       # Hệ thống Database Data-driven (toàn bộ là JSON)
│   ├── items/                  # Dữ liệu vật phẩm, trang bị, đan dược, nguyên liệu
│   ├── skills/                 # Võ công, bí kíp, tâm pháp, chiêu thức
│   ├── enemies/                # Quái vật, dã thú, boss, bang phái thù địch
│   ├── recipes/                # Công thức luyện đan, rèn đúc, nấu nướng
│   ├── npcs/                   # Dữ liệu NPC, hội thoại, quan chức, thương nhân
│   └── world/                  # Cấu trúc địa lý thế giới
│       ├── world_registry.json # Cấu hình quốc gia và tỉnh playable
│       ├── countries/dai_huyen/# Quốc gia Đại Huyền (Luật triều đình, sắc lệnh, thuế)
│       └── provinces/          # Thập Nhị Tỉnh (12 Tỉnh theo 12 Địa Chi)
│           ├── thin_chau/      # Thìn Châu (Tỉnh trung tâm, đã hoàn thiện chi tiết)
│           │   ├── province.json
│           │   ├── settlements.json
│           │   ├── fast_travel_stations.json
│           │   ├── landmarks.json
│           │   └── roads_rivers.json
│           ├── ty_chau/, suu_chau/, dan_chau/, mao_chau/, ty_ran_chau/,
│           ├── ngo_chau/, mui_chau/, than_chau/, dau_chau/, tuat_chau/, hoi_chau/
│           └── (Mỗi tỉnh đều có 5 file JSON chuẩn hóa tương tự)
├── scripts/                    # Toàn bộ mã nguồn GDScript
│   ├── singletons/             # Hệ thống Autoload toàn cục:
│   │   ├── game_clock.gd       # Đồng hồ thế giới (1 ngày = 720 giây thực)
│   │   ├── game_session.gd     # Trạng thái session, lưu/tải game, diffs thế giới
│   │   ├── content_registry.gd # Registry tra cứu vật phẩm, kỹ năng
│   │   ├── combat_manager.gd   # Quản lý chiến đấu, sát thương, bạo kích
│   │   ├── network_manager.gd  # Quản lý mạng P2P / Host-Client, RPC
│   │   └── trade_ledger.gd     # Sổ cái Authoritative chống gian lận & duping
│   ├── world/                  # Hệ sinh thái thế giới mở:
│   │   ├── world_registry.gd   # Quản lý dữ liệu 12 tỉnh, nạp data-driven
│   │   ├── chunk_streamer.gd   # Hệ thống nạp động Chunk 64x64 tiles (radius 1: 3x3 chunks)
│   │   ├── court_system.gd     # Hệ thống triều đình, sắc lệnh, ảnh hưởng kinh tế
│   │   └── ...
│   ├── ui/                     # Giao diện người dùng:
│   │   ├── minimap.gd          # Bản đồ thu nhỏ góc phải màn hình
│   │   ├── world_map_modal.gd  # Bản đồ toàn tỉnh/quốc gia phóng to (Phím N)
│   │   ├── shop_ui.gd          # Giao diện thương nhân, thuê sạp, buôn bán
│   │   ├── combat_arena_ui.gd  # Giao diện võ đài chiến đấu
│   │   └── hud.gd              # HUD thanh máu, thể lực, linh lực, thời gian
│   └── entities/               # Player, NPC, dã thú, quái vật
├── scenes/                     # Toàn bộ Scene Godot (.tscn)
│   ├── world/province_world.tscn # Màn hình thế giới chính (World, Camera2D, ChunkStreamer)
│   ├── world/player.tscn       # Nhân vật người chơi
│   ├── ui/minimap.tscn, world_map_modal.tscn, hud.tscn, etc.
│   └── combat/combat_arena.tscn
├── tests/                      # 30 Bộ test tự động (GUT / Custom Test Runner)
│   ├── unit/                   # Test độc lập: GameClock, Content, Economy, Combat...
│   ├── integration/            # Test tích hợp: Streamer, WorldRegistry, Court, Co-op...
│   └── run_all_tests.gd        # Entrypoint chạy 211 tests
└── tools/                      # Công cụ Python hỗ trợ dev
    ├── run_tests_capture_raw.py # Chạy test Godot không đầu (headless) và xuất JSON
    ├── export_audit_zip.py     # Đóng gói zip kiểm định
    └── generate_all_provinces.py # Sinh dữ liệu chuẩn 12 tỉnh
```

---

## 3. CÁC QUY TẮC BẤT BIẾN (CORE INVARIANTS)
Khi đề xuất code hoặc chỉnh sửa dự án, **bắt buộc tuân thủ**:
1. **Quy tắc Thời Gian (Time Invariant):**
   - `1 game day = 720 real seconds` (12 giờ thực tế = 1 năm ingame gồm 60 ngày hoặc 12 tháng x 30 ngày).
   - Trong chế độ nhiều người chơi (Co-op / Multiplayer), `time_scale = 1.0` tuyệt đối, không được phép pause hoặc tăng tốc tùy tiện.
2. **Quy tắc Thế Giới & Chunk Streaming (No OOM Invariant):**
   - Mỗi tỉnh có kích thước **4096 x 4096 tiles** (tương đương 131,072 x 131,072 px ở cỡ tile 32x32px).
   - **TUYỆT ĐỐI KHÔNG** khởi tạo toàn bộ 16.8 triệu tiles cùng lúc lên bộ nhớ.
   - Luôn sử dụng `ChunkStreamer` phân giải theo ô **64 x 64 tiles**, nạp động cửa sổ 3x3 quanh người chơi (bán kính 1 chunk = 9 chunks hoạt động cùng lúc), tự động giải phóng chunk nằm ngoài tầm nhìn.
   - Tài nguyên thu hoạch (gỗ, quặng, thảo dược) lưu dạng vi sai thưa thớt (`chunk_diffs` trong `GameSession`).
3. **Quy tắc Mạng & Kinh Tế (Host Authoritative Invariant):**
   - Toàn bộ giao dịch linh thạch, mua bán, kho hàng, chuyển tỉnh phải được **Host thẩm định và xác nhận qua RPC** (`TradeLedger`).
   - Khách (Peer/Client) chỉ gửi yêu cầu; không tự ý chỉnh sửa ví tiền hay túi đồ trên máy khách để ngăn chặn hoàn toàn lỗi trùng lặp vật phẩm (Duping) hoặc mất dữ liệu khi rớt mạng.
4. **Quy tắc Đồ Họa & Camera (Pixel Crisp Invariant):**
   - `position_smoothing_enabled = false` trên Camera2D để triệt tiêu bóng mờ / phân thân (ghosting).
   - `snap_2d_transforms_to_pixel = true` và `snap_2d_vertices_to_pixel = true` trong `project.godot`.

---

## 4. HỆ THỐNG 12 TỈNH (THẬP NHỊ ĐỊA CHI)
Đại Huyền Quốc gồm 12 Tỉnh tương ứng với 12 con giáp và các chủ đề đặc trưng:
1. **Thìn Châu (Rồng - Playable Lõi):** Kinh Đô Long Kinh, Huyện Thanh Trì, Trại Mỏ Tây Sơn, Cổ Kiếm Trũng, Rừng Trúc Vạn Lĩnh, Độc Trạch Hắc Xà.
2. **Tý Châu (Chuột):** Vùng duyên hải, sông ngòi chằng chịt, Cảng Thủy Kính, Chợ Vạn Ngư, Thủy Vân Tông.
3. **Sửu Châu (Trâu):** Đồng bằng phì nhiêu, vựa lúa quốc gia, Huyện Thành Phong Hòa, Trại Linh Ngưu, Bách Thảo Môn Phân Viện.
4. **Dần Châu (Hổ):** Rừng rậm nguyên sinh, hẻm núi hiểm trở, Sơn Trấn Hổ Khiếu, Trại Thợ Săn, Phách Đao Môn.
5. **Mão Châu (Mèo/Thỏ):** Rừng ngọc trúc thanh tao, y đạo học thuật, Hàn Lâm Thành, Dược Vương Cốc, Đan Hà Tông.
6. **Tỵ Châu (Rắn):** Vạn Độc Trạch, chướng khí tím, U Hồn Trấn, Ma Đạo tà tu, Ngũ Độc Giáo.
7. **Ngọ Châu (Ngựa):** Thảo nguyên mênh mông, vó ngựa thần tốc, Phong Mã Thành, Hãn Huyết Trấn, Thiên Lý Mã Trại.
8. **Mùi Châu (Dê):** Vùng đồi núi đá vôi, suối nước khoáng, Vân Sơn Trấn, Điêu Khắc Làng Nghề, Lãm Thạch Phái.
9. **Thân Châu (Khỉ):** Hoa Quả Sơn, vách đá cheo leo, Viên Vương Thành, Hiệp Cốc Kỳ Ngộ, Linh Hầu Cốc.
10. **Dậu Châu (Gà):** Bình nguyên rực rỡ, trang trại và lò gốm sứ tinh xảo, Kim Kê Trấn, Nghệ Nhân Thôn.
11. **Tuất Châu (Chó):** Biên ải phương Bắc, thành quách hiểm yếu chống ngoại xâm, Nhạn Môn Quan, Thiết Huyết Quân Doanh.
12. **Hợi Châu (Lợn):** Đầm sen mênh mông, thủy lộ thông thương, Thủy Nguyệt Thành, Bích Ba Đảo Tiên Cung.

Tất cả 12 tỉnh đã có đầy đủ 5 file JSON chuẩn hóa và được `WorldRegistry.gd` nạp thành công vào hệ thống.

---

## 5. BẢNG TIẾN ĐỘ & ROADMAP HIỆN TẠI
- [x] **Phase 1: Nền tảng Thế giới 12 Tỉnh (Thập Nhị Địa Chi)**
  - Sinh cấu trúc dữ liệu 5 file JSON cho toàn bộ 11 tỉnh còn lại.
  - Cập nhật `WorldRegistry.gd` hỗ trợ nạp 12 tỉnh.
  - Giữ vững 211/211 bài test PASS.
- [ ] **Phase 2: Chiều sâu Nội thất & Công trình của Thìn Châu**
  - Dựng nội cảnh bên trong: Nha Môn Thanh Trì, Kiếm Các Thanh Vi, Tiệm Đan Dược Bách Thảo, Tửu Lầu Say Rồng.
  - Cửa ra vào chuyển cảnh nội/ngoại mượt mà (Door Teleport / Interior Sub-scenes).
- [ ] **Phase 3: Hệ thống Triều Đình & Pháp Tội**
  - Bảng truy nã quan phủ, lính tuần tra, hệ thống đo lường tội trạng (Sát sinh, Trộm cắp, Buôn lậu).
  - Nhà lao và cơ chế chuộc tội / vượt ngục.
- [ ] **Phase 4: Gia Tộc & Truyền Thừa Đa Thế Hệ**
  - Cây phả hệ gia tộc, truyền thừa công pháp và di sản cho con cháu khi nhân vật tử nạn.
- [ ] **Phase 5: Đồ Họa & Nâng cấp Mạng Co-op Nâng Cao**
  - Tối ưu hóa chuyển tỉnh liền mạch cho mạng nhiều người chơi.
  - Hiệu ứng đổ bóng, chu kỳ thời tiết mưa bão / sương mù động.

---

## 6. HƯỚNG DẪN DÀNH CHO BẠN (CHATGPT KHI TRẢ LỜI NGƯỜI DÙNG)
1. **Không xáo trộn mã nguồn đang hoạt động:** Toàn bộ hệ thống test 211 tests đang chạy ổn định; khi viết thêm tính năng, hãy viết kèm unit test và kiểm tra tương thích ngược.
2. **Kiểu dữ liệu:** Luôn khai báo tường minh kiểu trong GDScript (ví dụ: `var target_pos: Vector2`, `func get_province(id: String) -> Dictionary`).
3. **Phong cách giao tiếp:** Ngắn gọn, súc tích, đậm chất kiếm hiệp/tiên hiệp theo phong cách của dự án. Trả lời bằng tiếng Việt chuẩn mực.
