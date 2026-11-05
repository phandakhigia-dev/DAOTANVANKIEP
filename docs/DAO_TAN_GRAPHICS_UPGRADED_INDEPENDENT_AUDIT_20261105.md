# ĐẠO TÀN: VẠN KIẾP — INDEPENDENT AUDIT V2

**Ngày kiểm tra:** 05/11/2026  
**Nguồn:** `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_20261104_GRAPHICS_UPGRADED.zip`  
**Đối chiếu:** `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_20261104.zip`  
**Phương pháp:** đọc ZIP, so sánh SHA-256 từng file, đọc code GDScript/scene/tài liệu, kiểm tra file PNG bằng Pillow, đọc raw engine log. **Môi trường kiểm tra không có executable Godot**, vì vậy không xác nhận trực tiếp việc game chạy hoặc chạy co-op 2 tiến trình. Các kết quả headless là log do người phát triển đóng gói, không phải phép thử độc lập của báo cáo này.

## 1. Kết quả tóm tắt

| Chỉ tiêu | Bản cũ | Bản GRAPHICS_UPGRADED |
|---|---:|---:|
| Số file | 384 | 391 |
| Kích thước ZIP | ~3.82 MB | 3,908,652 byte (~3.73 MiB) |
| File thêm | — | 7 |
| File nội dung thay đổi | — | 19 |
| File bị xóa | — | 0 |
| PNG trong ZIP | 77 | 77 |
| PNG thay đổi hoặc mới | — | **0** |
| Screenshot báo cáo trong ZIP | 40 | 40; **không thay đổi** |
| Sprite/PNG khác screenshot | 37 | 37; **không thay đổi** |
| Kiểm tra giải nén ZIP | — | PASS |
| PNG đọc và verify bằng Pillow | — | 77/77 PASS |
| Log test đóng gói | 147 PASS (báo cáo bản trước) | **161 PASS / 0 FAIL, 22 suites (theo log)** |

**Kết luận:** Có thay đổi thực trong logic và cách hiển thị (đặc biệt gọi animation, VFX, audio, floating text và ánh sáng ngày/đêm). Tuy nhiên không hề có ảnh asset mới/thay đổi, cũng không có screenshot hậu nâng cấp để kiểm chứng diện mạo. Đây là **graphics polish qua code**, chưa phải thay toàn bộ mỹ thuật 2D.

## 2. Lỗi trước đây đã được xử lý ở mức mã nguồn

1. `scripts/domain/shop_service.gd`: chặn `count <= 0`, ID rỗng, ví mua âm; thêm `player_buy_from_stall` và `to_dict`/`from_dict`; trường dữ liệu âm được lọc trong `from_dict`. Bản sửa rõ ràng; logic local chưa đủ bảo đảm an toàn mạng.
2. `scripts/core/game_session.gd`: thêm `town_position`, reset và serialize; thêm trường `shop` vào save; đọc lại từ save cũ với fallback.
3. `scripts/persistence/save_service.gd`: thống nhất `CURRENT_SCHEMA_VERSION=2`; phục hồi bản sao `.bak.json` khi file chính hỏng hoặc mất; từ chối schema tương lai.
4. `wuxia/demo/capture_demo.gd` và `.tscn`: đường dẫn tài nguyên đã đổi về `res://wuxia/demo/`.
5. `scripts/network/clock_replication.gd`: từ chối RPC yêu cầu gia tốc x20 khi phiên co-op đang hoạt động.
6. `scripts/domain/monthly_simulation_service.gd`: chỉ host/standalone chạy mô phỏng tháng trong callback `month_advanced`.

**Trạng thái xác minh:** xác nhận sự có mặt và logic cơ bản của bản sửa bằng code; log test đầu vào có case thử tốt. Chưa chạy kiểm thử engine độc lập.

## 3. VẤN ĐỀ NGHIÊM TRỌNG CÒN TỒN TẠI

### P0-A — Phím Space vừa khinh công vừa nhảy nguyên một ngày

**Bằng chứng:**
- `scenes/world/player.gd:84-99`: nhấn `KEY_SPACE` bắt đầu khinh công (Qinggong).
- `scenes/world/world_map.gd:158-163`: cùng `KEY_SPACE` gọi **thẳng** `GameClock.advance_days(1)`; không kiểm tra `SessionAuthority`, không gọi API thống nhất khóa time-skip.

**Hậu quả:** Nhấn Space khi di chuyển trên world map có thể đồng thời khinh công và tăng 1 ngày trong game. Host có thể bỏ qua quy định 1 ngày = 720 giây thực, tác động đến mô phỏng NPC và client co-op. Client cũng có thể tự làm nhảy thời gian cục bộ trước khi nhận snapshot sửa lại.

**Sửa bắt buộc:** Bỏ hoàn toàn time skip tại `KEY_SPACE`; chỉ dùng action `qinggong`. Tách nghỉ/bế quan sang action + UI riêng, mọi yêu cầu đổi thời gian phải được host thẩm định tại một điểm duy nhất. Trong co-op tạm cấm mọi skip.

**Acceptance test:** 100 lần nhấn Space trong world map ở standalone/host/client không làm tăng ngày; khinh công vẫn hoạt động; solo nếu hỗ trợ nghỉ thì có UI xác nhận và input khác; co-op không ai đổi được `time_scale`/ngày qua UI/keyboard hoặc RPC.

### P0-B — Co-op vẫn chưa có gameplay replication

**Bằng chứng:** chỉ thấy RPC đồng hồ trong `scripts/network/clock_replication.gd`; không có `MultiplayerSpawner`, `MultiplayerSynchronizer`, RPC đồng bộ vị trí/hit/damage/inventory trong scripts/scenes. `scripts/network/session_authority.gd` đang là lớp tạo ENet host/client, theo dõi peers và roles.

**Hậu quả:** Có khung kết nối và đồng hồ nhưng chưa chứng minh 2-4 người cùng thấy các nhân vật, đánh cùng boss, dùng vật phẩm, nhận tiền, nhặt chiến lợi phẩm và lưu thế giới nhất quán. Không nên ghi 'co-op hoàn thành'.

**Sửa bắt buộc:** Thực hiện vertical slice 2 phiên Godot: host + client, cả hai thấy avatar di chuyển, 1 quái, HP/boss đồng bộ, 1 túi vật phẩm/giao dịch do host xử lý, disconnect/reconnect và save trên host. Kiểm thử bằng 2 tiến trình độc lập và log kết quả.

### P0-C — Có thể mang tốc độ x20 từ solo vào khi host tạo phòng

**Bằng chứng:** `scripts/core/game_clock.gd:69-72` cho phép gán time scale tùy ý; `scripts/network/session_authority.gd:36-54` chuyển sang host nhưng **không reset hoặc cưỡng chế** `GameClock.time_scale = 1`. `clock_replication.gd:65-73` chỉ chặn RPC thay đổi từ xa trong co-op, không bảo vệ mọi đường gán trực tiếp hoặc trạng thái cũ.

**Sửa bắt buộc:** Khi `start_host`/`join_host` và `load_game` trong phiên co-op, force speed 1 và lock clock; mọi thay đổi giờ/ngày qua API `WorldTimeAuthority` hoặc `GameClock` có kiểm tra role. Test: solo x20 → tạo phòng → speed phải 1 → 720s thực/1 ngày.

### P1-A — Mô phỏng thời gian của client thiếu sự kiện và trạng thái xã hội

`game_clock.gd:50-57` dừng tick ở client (đúng hướng host authoritative). Nhưng `clock_replication.gd:31-57` chỉ cập nhật năm/tháng/ngày/giây và `_update_time_components()`, **không phát** `hour_advanced`, `day_advanced` hoặc snapshot NPC/faction/market. `monthly_simulation_service.gd:32-37` không chạy trên client nhưng cũng chưa có broadcast kết quả tháng. Điều này có thể làm hiển thị/AI client không cập nhật tương ứng host.

**Sửa:** Đồng bộ snapshot trạng thái (NPC positions/status, market, factions, world event) từ host; client render theo data được replicated, không tự chạy simulation; thêm test qua ranh giới 23:59→00:00, tháng, năm khi hai tiến trình kết nối.

### P1-B — Kinh tế sạp chỉ an toàn trong một GameSession cục bộ

`shop_service.gd:179-234` thao tác trực tiếp `GameSession` (inventory và linh thạch máy cục bộ), không có RPC/transaction ID/peer ownership của người mua và chủ sạp. Logic đồng bộ local cải thiện, nhưng **chưa phải giao dịch nguyên tử giữa 2 player trên mạng**; `buy_from_stall` nhận `buyer_wallet` tham số mà không trừ ví thực của peer trong cùng hàm (đây có thể là hàm mô phỏng NPC, không nên dùng cho P2P).

**Sửa:** Chuyển giao dịch co-op thành server-authoritative command, xác minh peer, sở hữu sạp, giá, lượng, ví, request ID chống gửi lặp; commit đúng một lần, phát snapshot kết quả về tất cả client; thử hai người mua cùng món cuối.

### P1-C — Bộ kiểm thử hiện tại chưa đủ chứng minh các tuyên bố mạnh

- `tests/unit/test_s0_stability_regression.gd:161-190` mô phỏng co-op bằng cách **gán biến role trong cùng một tiến trình**, chưa mở hai peer thật.
- T-10 kiểm tra `is_server_authoritative()` theo role, không phát sự kiện `month_advanced` trên client và quan sát state sau tháng thực tế.
- T-11 nạp được scene, không kiểm tra animation/VFX thể hiện đúng pixel trên màn hình.
- `audit/REGRESSION_LOG_RAW.txt` có lỗi/cảnh báo chủ đích trong test dữ liệu không hợp lệ, và kết thúc có `WARNING: 18 ObjectDB instances were leaked at exit`. Do đó ghi '0 warning' trong báo cáo implementation là không chính xác; cần phân biệt expected warnings với leak chưa xử lý.

### P2-A — Sai khác giữa tài liệu và tốc độ khinh công

`scenes/world/player.gd:87` tính `velocity = qinggong_dir * (sprint_speed * 1.5)` với `sprint_speed=520`, tức **780 px/s** trước khi xét vector chuẩn hóa, trong khi một số tài liệu ghi tốc độ khinh công 520 px/s. Khi kích hoạt, `qinggong_dir` có thể dùng `input_vec` chưa chuẩn hóa nên tốc độ theo đường chéo thay đổi. Cần chuẩn hóa và định nghĩa rõ tốc độ duy nhất.

### P2-B — Gọi "bạo kích" theo mốc sát thương

`scenes/combat/combat_arena.gd` dùng `is_crit = (dmg >= 35)` để chọn chữ `BẠO KÍCH!`. Đây không phải flag crit thật; mọi đòn có sát thương lớn đều bị gắn nhãn chí mạng. Nên lấy crit từ kết quả tính sát thương.

### P2-C — Chưa có ảnh sau nâng cấp

Toàn bộ 40 PNG screenshot trong `docs/TEST_REPORTS/screenshots/` và 37 PNG asset khác **giữ nguyên byte** so với ZIP cũ. Không thể đánh giá bằng mắt chất lượng của những hiệu ứng code mới (screen shake, lá trúc, day/night, aura, chữ sát thương) từ ZIP này.

**Yêu cầu:** chụp mới tối thiểu 8 ảnh: world day/night, thị trấn, combat đánh thường/crit, kiếm khí, đột phá, cửa hàng/UI, co-op 2 avatar. Có thể bổ sung video 30-60s. Lưu vào `audit/graphics_after/`.

## 4. Thực trạng đồ họa Phase 4

**Xác nhận thay đổi code:** `combat_arena.gd` tạo `SwordsmanScene` cũ, thêm floating damage, ring burst, screen shake; `player.gd` thêm qinggong; `world_map.gd` thêm CanvasModulate và phát nhạc; `town_map_real.gd` phát nhạc và gọi VFX lá trúc; `inventory_panel.gd` và `character_panel.gd` gọi audio/VFX vốn có từ trước.

**Không thay đổi:** Không có sprite/tileset/PNG mới, không tăng chi tiết phố phường, NPC ngoại hình hay mô hình 2D. Đa số map vẫn vẽ nền lập trình/procedural. Asset pipeline Phase 4 chưa đạt mục tiêu nâng cấp mỹ thuật như game tham chiếu.

**Ưu tiên sau P0:** Chốt art direction top-down (pixel art hoặc hand-painted, không trộn); lắp tilemap thật cho một thành trấn mẫu; đồng nhất scale player/NPC/building; thêm animations đầy đủ; UI tiên hiệp; kiểm tra license/nguồn asset từng bộ; chụp screenshot thực tế để duyệt.

## 5. Kiểm tra đóng gói và tài liệu

- ZIP hợp lệ, không có lỗi CRC.
- 7 file mới gồm audit, raw log, JSON test report, test S0, Python runner.
- 19 file chỉnh sửa không chứa PNG hoặc file tileset; chỉ một scene demo `.tscn` đổi đường dẫn.
- Tổng 22 suite / 161 case / 0 fail trong JSON nhất quán với báo cáo log, nhưng **không thay thế xác minh độc lập trên máy hiện tại**.
- Scanner tĩnh không thấy đường dẫn `res://` thiếu trong nguồn thật; duy nhất chuỗi `res://demo/...` là lời mô tả trong test, không phải đường dẫn được nạp.
- Không có file game chạy độc lập Windows trong ZIP (đúng vì đây là source audit).

## 6. Thứ tự sửa tiếp

1. **S0.1 (P0):** bỏ Space → advance_days; khóa mọi đường tua thời gian khi co-op và force time_scale=1 khi vào phòng.
2. **S0.2 (P0):** 2-process host/client vertical slice cho di chuyển, combat, NPC nhìn thấy nhau và reconnect.
3. **S0.3 (P1):** server-authoritative inventory/economy, RPC có transaction id, đồng bộ world state và tháng.
4. **S0.4 (P1):** bổ sung integration test 2 phiên, boundary tests, sửa leak 18 ObjectDB instances hoặc làm rõ nguồn.
5. **P4.1 (đồ họa):** chụp gameplay hậu nâng cấp, đổi tilesets thật, xây Thanh Trì Trấn hoàn chỉnh và làm bộ ảnh so sánh trước/sau.

## 7. Gate nghiệm thu

- [ ] Nhấn Space 100 lần không đổi ngày/tháng/năm trong chế độ solo và co-op.
- [ ] Từ solo time_scale=20 mở host → tự về 1x trước frame gameplay đầu tiên.
- [ ] Host/client 2 tiến trình với 1 ngày = 720s thực, biến động nhỏ, hoạt ảnh ngày/đêm thống nhất.
- [ ] Cả hai thấy hai avatar, va chạm, combat và HP boss cùng trạng thái.
- [ ] Client không thể tự trừ/cộng tiền, mua trùng món cuối, hoặc kích hoạt mô phỏng tháng riêng.
- [ ] Co-op tháng mới: trạng thái NPC/faction/market trên client bằng snapshot host.
- [ ] Test nhiều peer, disconnect/reconnect và Host Save/Load.
- [ ] Engine headless test exit code 0; báo riêng warning mong đợi và warning bất thường.
- [ ] Screenshots hậu nâng cấp thực tế có timestamp/build hash, không tái sử dụng screenshot cũ.

## 8. Kết luận

Bản mới **đã cải thiện ổn định gameplay đơn** và bổ sung các hiệu ứng vận hành bằng code. Tuy nhiên **chưa đủ điều kiện tuyên bố hoàn thành co-op hoặc nâng cấp mỹ thuật Phase 4**. Đặc biệt lỗi **KEY_SPACE vừa khinh công vừa skip 1 ngày** phải sửa trước mọi công việc mới. **Không cần xây lại project**: cần ưu tiên sửa vào các module hiện có và tăng test thực tế.
