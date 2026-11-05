# ĐẠO TÀN: VẠN KIẾP — KIỂM TOÁN ĐỘC LẬP SOURCE ZIP

**Ngày kiểm tra:** 04/11/2026  
**Nguồn:** `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_20261104.zip` do người dùng cung cấp.  
**Phương pháp:** xác minh toàn vẹn ZIP, liệt kê nội dung, kiểm tra script/scene/dữ liệu/screenshot, rà soát tuyến gọi hàm và đối chiếu báo cáo Antigravity với source. **Không chạy được Godot trong môi trường đánh giá này** (không có executable Godot); mọi nhận xét về runtime được phân loại là rủi ro hoặc lỗi suy ra từ source, chưa phải kết quả tái hiện khi chơi.

## 1. Tóm tắt

- ZIP hợp lệ, `testzip()` không báo lỗi. 384 entry, dung lượng nén khoảng 3,82 MB (3,64 MiB); giải nén khoảng 5,00 MB.
- Có `project.godot`, 79 GDScript (`*.gd`), 56 scene (`*.tscn`), 17 JSON, 77 PNG (trong đó 40 ảnh screenshot trong tài liệu; **37 PNG là asset/bảng màu thực tế**), 21 unit-test suite, các script chụp ảnh, và các báo cáo audit.
- 36 NPC có dữ liệu trong `data/npcs/npcs.json`. Các cơ chế cốt lõi single-player có mã nguồn: bản đồ, đánh quái, boss, đột phá, cửa hàng, luyện đan, tông môn, AI theo tháng.
- **Chưa được xem là game co-op hoàn chỉnh**: có ENet connect và RPC clock, nhưng không thấy lớp network đồng bộ vị trí, inventory, combat, NPC, trade; chưa có scene/UI gọi `start_host()` hay `join_host()` từ gameplay.
- **Phase 4 đang ở giai đoạn mẫu/prototype**, 26 PNG trong `wuxia/32`, 10 icon game, palette, VFX procedural; 40 ảnh screenshot là bằng chứng về UI mẫu, không phải 40 bộ asset hình ảnh.

## 2. Điểm đã xác minh từ mã nguồn

| Hạng mục | Bằng chứng | Mức độ |
|---|---|---|
| Cấu trúc Godot | `project.godot`, `scenes/bootstrap/bootstrap.tscn`, autoload | Có thật; chưa chạy trên engine ở đây |
| Clock 720s/ngày | `scripts/core/game_clock.gd`: `REAL_SECONDS_PER_DAY = 720`, `TIME_RATIO = 120` | Có thật |
| ENet host/client | `scripts/network/session_authority.gd`: `create_server`, `create_client` | Chỉ tầng kết nối |
| Clock snapshot | `scripts/network/clock_replication.gd`: `@rpc sync_clock_snapshot` | Có code; chưa kiểm chứng qua 2 tiến trình |
| NPC | `data/npcs/npcs.json` chứa 36 NPC; `monthly_simulation_service.gd` | Mô phỏng theo tháng |
| Kinh tế | `scripts/domain/shop_service.gd` | Ký gửi và mua tự động bằng xác suất; chưa phải kinh tế NPC thực thụ |
| Gia tộc/truyền thừa | Chưa thấy cấu trúc gia phả, cha/mẹ/con, kế thừa tài sản hay hôn nhân trong source | Chưa triển khai đáng kể |
| Test | `tests/test_runner.gd` gọi 21 suite | Có test source, chưa chạy xác minh 147/147 |

## 3. Các lỗi và rủi ro ưu tiên

### P0-01 — Co-op time lock có thể bị vượt qua

- `scripts/network/clock_replication.gd:60-68`: RPC `request_time_scale_change` được `@rpc("any_peer")`; host chấp nhận `1.0` **hoặc `20.0`** mà không chặn khi có nhiều người chơi.
- `scenes/world/hud.gd:89-96`: phím X gọi trực tiếp `GameClock.set_time_scale(20.0)` trên máy cục bộ, không kiểm tra `SessionAuthority`.
- `scenes/towns/town_map_real.gd:258-261`: ghế trà gọi trực tiếp `GameClock.advance_hours(1)`.
- `scripts/core/game_clock.gd:50-54`: mỗi tiến trình chạy tick, kể cả client; clock replication chỉ hiệu chỉnh sau đó. `monthly_simulation_service.gd:32-34` không có guard host-only.

**Tác động:** người chơi có thể tua/chạy đồng hồ khác nhịp hoặc làm mô phỏng NPC khác nhau ở mỗi máy. **Yêu cầu:** server là nguồn chân lý duy nhất; co-op tốc độ cố định 1x (720 s/ngày); tu luyện cá nhân chỉ tăng tiến trình tu vi riêng, không tăng giờ thế giới; khóa mọi đường vòng gọi `set_time_scale` / `advance_hours`; mô phỏng tháng/ngày chỉ thực thi trên host.

### P0-02 — Co-op gameplay chưa triển khai

- `session_authority.gd` tạo ENet peer; không thấy `MultiplayerSpawner`, `MultiplayerSynchronizer`, hay RPC action/damage/trade trong scripts/scenes gameplay.
- Các lời gọi `start_host()`/`join_host()` chỉ xuất hiện trong chính `session_authority.gd`; chưa có menu/flow tạo và tham gia phòng.
- `scenes/world/player.gd` đọc input và tự cập nhật `GameSession.world_position` trên máy đang chạy.
- `tests/unit/test_coop_clock_sync.gd` **đổi `current_role` sang CLIENT trong cùng tiến trình**, sau đó gọi trực tiếp `sync_clock_snapshot`, không phải test host và client qua kết nối thật.

**Yêu cầu:** hai instance Godot thực (host/client), spawn avatar theo peer_id, authoritative action validation, state replication, join/rejoin/disconnect, đồng bộ world/NPC/combat/inventory.

### P0-03 — Kinh tế có rủi ro tạo/hủy tài sản bất hợp lệ

- `scripts/domain/shop_service.gd:127-158`: `buy_from_stall(item_id,count,buyer_wallet)` không kiểm tra `count > 0`; nhập số âm có thể làm tăng tồn sạp, giảm doanh thu và phát sinh số âm.
- `buyer_wallet` chỉ là số được truyền vào: hàm kiểm tra đủ tiền nhưng **không trừ ví người mua** và không cấp vật phẩm cho người mua. Không được coi là giao dịch player-to-player hoàn chỉnh.
- `simulate_npc_purchases()` dùng xác suất dựa vào giá niêm yết; không chọn NPC người mua cụ thể, không trừ ví cá nhân NPC. Do đó **chưa phải hệ kinh tế cung-cầu có dòng tiền bảo toàn**.

**Yêu cầu:** server-side validation `qty > 0`, id hợp lệ, price và balance hợp lệ; request idempotent; trừ tiền/cộng item và trừ kho/cộng doanh thu trong một transaction, rollback khi thất bại; sổ cái để kiểm toán bảo toàn tài sản.

### P0-04 — Tài sản sạp hàng chưa lưu trong save game chính

- `ShopService.to_dict()` và `.from_dict()` tồn tại (`scripts/domain/shop_service.gd:210-230`), nhưng **không thấy gọi** trong `GameSession.export_save_dict()` hoặc `import_save_dict()`.
- `scripts/core/game_session.gd:607-643` export `player`, `clock`, `world_npcs`, `world_factions`, `memory_events`, `monthly_summaries`, `market_modifiers` nhưng không export `shop`/`escrow`.

**Tác động:** tiền/doanh thu/vật phẩm đang ký gửi có nguy cơ không phục hồi sau khi tắt hoặc load game. **Yêu cầu:** thêm save state của shop, migration và test save→reload→đối soát kho+tiền.

### P1-01 — Schema save không nhất quán; tính nguyên tử chưa đủ

- `scripts/core/game_session.gd:609` export `schema_version: 2`, nhưng `scripts/persistence/save_service.gd:7` đặt `CURRENT_SCHEMA_VERSION = 1` và ghi đè thành 1 ở dòng 36.
- `save_service.gd:63-65` xóa file save cũ trước khi rename file tạm, tạo khoảng trống nếu quá trình bị ngắt. Có backup nhưng cần test khôi phục thực tế.

**Yêu cầu:** schema hiện hành duy nhất, migration rõ ràng v1→v2→v3; quản lý backup và thay thế file an toàn theo hệ điều hành; test corrupt/interruption.

### P1-02 — Chuyển cảnh ghi thuộc tính chưa khai báo

- `scenes/towns/town_map_real.gd:248,263` ghi `GameSession.town_position = player.global_position`.
- Không tìm thấy khai báo `town_position` trong `scripts/core/game_session.gd`.

**Tác động:** có khả năng lỗi runtime khi đi Cổng Bắc hoặc vào Tông Môn. **Yêu cầu:** bổ sung thuộc tính có kiểu và save/load, hoặc dùng API vị trí hiện có; test cả hai đường chuyển cảnh.

### P1-03 — Báo cáo test thiếu bằng chứng tương ứng

- `audit/TEST_RESULTS.md` khẳng định **147 PASS**, nhưng một số đường dẫn test trong bảng báo cáo **không tồn tại trong ZIP**: `tests/unit/test_monthly_simulation.gd`, `tests/unit/test_shop_escrow.gd`, `tests/unit/test_life_generator.gd`, `tests/unit/test_clan_karma.gd`, `tests/unit/test_clock_replication.gd`, `tests/unit/test_world_map.gd`...
- `tests/test_runner.gd` thực tế chạy 21 suite nhưng danh sách và nội dung khác bảng mô tả. Phần log trong báo cáo có dấu `...`, không phải raw log kiểm thử đầy đủ.
- Do không có executable Godot trong môi trường review, **147 PASS là tuyên bố của Antigravity, không phải số kiểm thử độc lập đã xác minh**.

**Yêu cầu:** lưu log stdout/stderr nguyên bản, file kết quả máy đọc được JSON/CSV, exit code, phiên bản Godot, hash ZIP/commit; test integration 2 instance.

### P1-04 — Tài nguyên và đường dẫn demo thiếu

- Trong `wuxia/demo/capture_demo.tscn` và `wuxia/demo/capture_demo.gd` có tham chiếu `res://demo/capture_demo.gd` và `res://demo/canal_corner.tscn` nhưng không thấy file tương ứng ở root `demo/` của ZIP.
- Nếu demo được sử dụng, cần sửa đường dẫn tương ứng `wuxia/demo/...` hoặc bổ sung file.

### P2-01 — Xã hội NPC ở mức prototype

- `data/npcs/npcs.json` có 36 NPC, thuộc tính, quan hệ, tiền và tuổi.
- `monthly_simulation_service.gd` tính intent `train/trade/quest/travel/relationship/fight/rest` theo tháng. `town_map_real.gd` đẩy NPC di chuyển ngẫu nhiên theo chu kỳ 10–16 giây thực.
- Chưa thấy lịch nghề nghiệp theo giờ, hộ gia đình, kinh doanh cửa hàng thực, tiền đi từ người mua sang người bán hay di cư/gia tộc có dữ liệu xuyên thế hệ.

**Yêu cầu:** không đánh dấu The Bustling World / Matchless Kungfu / Scroll of Taiwu đã được tích hợp toàn diện; viết vertical slice NPC có nghề → thu nhập → mua hàng → thay đổi quan hệ → tích lũy tài sản → lưu và đồng bộ.

### P2-02 — Phase 4 là nền thử nghiệm đồ họa

- Có 26 PNG dưới `wuxia/32`, 10 PNG icon game, 1 palette, 5 VFX scene và service âm thanh procedural.
- Có **40 screenshots 1280×720** trong `docs/TEST_REPORTS/screenshots/` (chỉ là bằng chứng hình ảnh).
- Quan sát ảnh: thế giới bản đồ nhiều ô lặp, thành trấn rất thưa công trình, đấu trường dạng hình khối đơn giản, hiệu ứng tu luyện còn nhỏ, thiếu nhân vật nhiều khung hình, GUI hội thoại khá đặc chữ.
- Chưa thể xác minh tuyên bố bản quyền asset “100% sạch” chỉ bằng ZIP; cần bảng nguồn gốc/giấy phép theo từng resource.

**Yêu cầu:** chốt hướng vẽ tay ink-wash 2D hay pixel 32px, chọn một style guide; tăng chất lượng art sau khi gameplay và save/network vững.

## 4. Sprint sửa khuyến nghị

| Thứ tự | Phạm vi | Điều kiện nghiệm thu |
|---|---|---|
| **S0 — Stability & Save** | P0-03, P0-04, P1-01, P1-02 | Chạy Godot sạch parse; chuyển cảnh không lỗi; save/load khôi phục đầy đủ shop; số âm không phá được sạp |
| **S1 — Clock Host-Only** | P0-01 | 2 instance; 720 giây/24h; mọi request x20, ghế trà, pause client không làm lệch giờ; NPC sim đúng một lần |
| **S2 — Basic Co-op** | P0-02 | Host/Join 2–4 người; cùng thấy vị trí; join/leave/rejoin; giao dịch và chiến đấu do host xác nhận |
| **S3 — Living Economy** | P2-01 | Có tối thiểu 10 NPC có nghề, ví tiền, nhu cầu, tồn kho; giao dịch có sổ cái và save/load |
| **S4 — Social & Dynasty** | P2-01 | Quan hệ gia đình, thừa kế tài sản/ân oán, truyền thừa; kiểm tra bế quan thời gian dài |
| **S5 — Art Phase 4** | P2-02 | Một thành trấn có cảm giác sống, nhân vật/animation/VFX/UI đồng nhất, không thiếu asset, đủ license |

## 5. Prompt cho Antigravity (dán nguyên khối)

> Bạn là Lead Godot Engineer và QA của ĐẠO TÀN: VẠN KIẾP. Đã có kiểm toán độc lập source `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_20261104.zip` và file `DAO_TAN_VAN_KIEP_INDEPENDENT_AUDIT_20261104.md`. **Không được viết lại game hoặc xóa tính năng.** Tạo nhánh Git `fix/audit-s0-stability` và bản backup trước khi sửa.
>
> **Chỉ thực hiện S0:** (1) xử lý validation và giao dịch an toàn cho ShopService, từ chối `count <= 0` và đảm bảo không nhân bản vật phẩm/tiền; (2) thêm state sạp hàng/escrow/revenue vào save/load bằng migration tương thích; (3) thống nhất schema version và kiểm tra cơ chế backup an toàn; (4) xử lý `GameSession.town_position` tại cổng Bắc và tông môn; (5) sửa các tham chiếu demo bị thiếu; (6) thêm test hồi quy cho mọi lỗi trên.
>
> **Không thay đổi cơ chế 1 ngày = 720 giây.** Lập kế hoạch S1 có kiểm thử co-op host/client thật để khóa toàn bộ lối tua x20 và sửa việc client tự tick world; chưa tự động triển khai S1 cho đến khi test S0 đạt.
>
> Đầu ra bắt buộc: `audit/FIX_IMPLEMENTATION.md`, `audit/REGRESSION_LOG_RAW.txt` (log thực, không tự viết), `audit/TEST_RESULTS.json`, `audit/FILES_CHANGED.md`, `audit/REMAINING_ISSUES.md`, ZIP source mới. Báo cáo rõ test nào không chạy được. Không tự ghi 100% PASS khi chưa thực thi Godot. Gửi đường dẫn ZIP và log.

## 6. Giới hạn đánh giá

- **Đã kiểm chứng:** toàn vẹn ZIP, sự hiện diện file, JSON parse, PNG đọc được, tuyến code và các lỗi thiết kế ghi bên trên.
- **Chưa kiểm chứng runtime:** parse toàn project trong Godot, 147 unit tests, FPS, gameplay thực tế, kết nối 2 máy, đồng bộ qua Internet, license và nguồn gốc assets.
- Không đánh đồng “có function/test” với “tính năng đã hoạt động với người chơi”.
