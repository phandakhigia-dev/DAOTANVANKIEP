# ĐẠO TÀN: VẠN KIẾP — ĐÁNH GIÁ ĐỘC LẬP V3

**Bản kiểm tra:** `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_AFTER_V2_FIX_20261105.zip`  
**Đối chiếu:** `DAO_TAN_VAN_KIEP_FULL_SOURCE_AUDIT_20261104_GRAPHICS_UPGRADED.zip`  
**Ngày kiểm tra:** 05/11/2026  
**Phạm vi xác minh:** đọc file ZIP, kiểm tra toàn vẹn, so sánh SHA-256 file, đọc mã nguồn GDScript, test, log và 8 ảnh PNG đính kèm. **Không chạy Godot trong môi trường kiểm toán** vì không có binary Godot.

## 1. Kết quả tổng quan

- ZIP mới hợp lệ (`testzip() == None`), **412 file**, khoảng **4,17 MiB / 4,37 MB**.
- So với bản GRAPHICS_UPGRADED: **+21 file**, **14 file thay đổi**, **0 file bị xóa**.
- 8 PNG mới đều nằm ở `audit/graphics_after/`. Toàn bộ **77 PNG gameplay/asset sẵn có giữ nguyên byte**; chưa thay spritesheet/tileset mỹ thuật.
- Antigravity khai báo **172/172 unit tests PASS** và **18/18 bước test hai tiến trình PASS**. Những log và runner có trong ZIP, nhưng không phải bằng chứng game thường đã có hai avatar thật đồng bộ. Không thể xác thực độc lập kết quả runtime.

### Trạng thái theo tính năng

| Chức năng | Đánh giá độc lập | Bằng chứng |
|---|---|---|
| Loại xung đột Space → nhảy ngày | FIXED IN CODE | `scenes/world/world_map.gd:120–158` không còn nhánh Space/advance_days |
| Vận tốc khinh công đường chéo | FIXED IN CODE | `scenes/world/player.gd:85–105`, `raw_dir.normalized()` |
| Khởi tạo co-op ép 1x | FIXED IN CODE | `scripts/network/session_authority.gd:36–81` |
| 1 ngày game = 720 giây thực | FIXED IN CODE | `scripts/core/game_clock.gd:13–15` |
| Kết nối ENet hai process theo script | EVIDENCE IN BUNDLED LOG; NOT RE-RUN | `audit/TEST_TWO_PEERS.md`, `tools/test_coop_two_peers.py` |
| Remote avatar trong gameplay thật | NOT INTEGRATED / NOT VERIFIED | Không thấy scene gameplay đăng ký `remote_player_updated` để spawn/cập nhật remote avatar |
| Combat boss co-op trong gameplay | NOT INTEGRATED | Combat sync ở `coop_world_sync.gd`; combat arena không gọi nó |
| Giao dịch sạp co-op chống duping | **P0 FAIL IN CODE** | Xem phát hiện P0-01, P0-02 |
| Snapshot NPC/world | PARTIAL | Client chỉ lưu summary; chưa áp dụng đầy đủ world_npcs |
| Save/Load multiplayer sau reconnect | PARTIAL | SaveService giữ GameSession/Shop; chưa có lưu toàn bộ session/peer/pending transactions |
| Phase 4 ảnh | LIMITED IMPROVEMENT | 8 ảnh QA mới; 77 PNG asset gốc không đổi |

## 2. LỖI P0 — PHẢI SỬA TRƯỚC KHI CHƠI CO-OP THẬT

### P0-01 — Client có thể được cấp vật phẩm nhiều lần từ cùng giao dịch

**Vị trí:** `scripts/network/coop_world_sync.gd:317–322`, `381–393`.

Server nhớ `processed_transactions[request_id]` và trả lại **kết quả `success=true` cũ** mỗi khi request trùng. Tuy nhiên, phía client `sync_stall_trade_response(...)` **trừ tiền và cộng vật phẩm MỖI LẦN** nhận phản hồi `success`, không có bộ chống áp dụng response trùng. Kết quả: nếu cùng request được gửi lại, phần kho và doanh thu server không lặp, **nhưng phần cấp vật phẩm phía client có thể lặp**. `GameSession.remove_item(...)` không được kiểm tra kết quả trước khi gọi `GameSession.add_item(...)`, vì vậy khi thiếu tiền vẫn có đường cộng vật phẩm trên client. Đây là lỗi logic có thể xác định từ code; cần test runtime để định lượng ảnh hưởng.

**Fix bắt buộc:** thực hiện server-authoritative inventory/ledger theo peer; response có `transaction_id` duy nhất và `version`; phía client chỉ **reconcile state**, không tự cộng vật phẩm khi nhận thông báo; giao dịch trùng phải không thay đổi **cả hai phía**. Thêm test gửi cùng request 3 lần và một lần sau reconnect.

### P0-02 — Server tin vào số dư do client tự khai

**Vị trí:** `scripts/network/coop_world_sync.gd:301–317`, `346–363`.

Client truyền `buyer_wallet` lên trong RPC. Server chỉ xác minh `buyer_wallet >= total_cost`, không đọc số dư **do server lưu cho peer đó**. Với peer ID khác host, server cũng không có thao tác trừ tiền authoritative; việc trừ tiền được để cho client tự thực hiện khi nhận response. Đây chưa phải mô hình chống gian lận/nhân đồ.

**Fix bắt buộc:** bỏ `buyer_wallet` khỏi API client RPC; trên host lưu `peer_id → inventory/wallet`, validate và commit cùng lúc; từ chối peer chưa join, giá/quantity không hợp lệ, giới hạn số lượng, request quá lớn; khóa request ID theo `(peer_id, request_id)`.

### P0-03 — Gameplay chính chưa gọi cơ chế multiplayer vừa test

**Bằng chứng:** `scenes/menu/main_menu.gd` chỉ có New/Continue/Settings/Quit; các scene gameplay không gọi `CoopWorldSync` hoặc kết nối signal `remote_player_updated`. `scenes/combat/combat_arena.gd` không sử dụng `CoopWorldSync.request_attack_boss` để xử lý cú đánh trong trận bình thường. `scenes/ui/player_shop_modal.gd` thao tác trực tiếp với `ShopService` và `GameSession`, không gửi intent qua host. Bài `tests/integration/coop_two_peers_runner.gd` tự gọi RPC với tọa độ mẫu `(650, 420)`, gửi skill và giao dịch thử.

**Hệ quả:** test chứng minh một bộ RPC prototype có thể giao tiếp trên localhost (theo log), **không đủ kết luận hai người mở game, thấy nhau, cùng đánh boss và mua hàng được**.

**Fix bắt buộc:** menu Host/Join/Disconnect, tạo remote player scene từ `network_players`, subscribe `remote_player_updated`, scene combat nhận intent và cập nhật HP world-state thực, modal sạp thực hiện RPC giao dịch; test vào game thật bằng 2 tiến trình với điều khiển hoặc bot input.

## 3. LỖI P1 / CHẤT LƯỢNG TEST

### P1-01 — Host chưa xác thực đòn đánh theo gameplay

`coop_world_sync.gd:209–270` trừ HP boss ngay khi nhận `skill_id`; chưa thấy xác minh khoảng cách, thời gian hồi chiêu, mana, trạng thái sống, tầm ảnh hưởng, hitbox hoặc chặn RPC gửi quá tần suất. Chỉ có một `coop_boss_state` cố định. Client có thể liên tục gửi intent; cần xác thực toàn bộ ở host, sau đó đồng bộ kết quả.

### P1-02 — Snapshot tháng chưa đồng bộ trạng thái NPC đầy đủ

`monthly_simulation_service.gd:32–39` cho host chạy mô phỏng và broadcast summary; `coop_world_sync.gd:406–416` ở client chỉ lưu `latest_world_snapshot` rồi phát signal, **không cập nhật `GameSession.world_npcs`**. Full world snapshot lúc join (`coop_world_sync.gd:102–107`) chỉ gồm players, boss, shop, clock. Cần broadcast NPC diff/state có revision và áp dụng theo thứ tự.

### P1-03 — Save có thể ghi đè time_scale co-op

`scripts/core/game_clock.gd:240–247` `from_dict` gán trực tiếp `time_scale` từ save, không kiểm tra role. Nếu tải một save có `time_scale=20` ngay khi đang host, thời gian có thể tạm/tiếp tục chạy sai x20 cho đến khi ép lại. Cần đảm bảo tất cả lối nhập save/network/setting được clamp về 1x khi co-op.

### P1-04 — Regression báo PASS nhưng log có ERROR

`audit/REGRESSION_LOG_RAW.txt` có `ERROR: Trying to call an RPC while no multiplayer peer is active.` khi unit test gọi xử lý giao dịch trực tiếp trong chế độ không có mạng. Đây có thể là lỗi trong fixture unit test, nhưng vẫn cần tách **expected errors** / **unexpected errors**, không tuyên bố log sạch. Log còn ghi `18 ObjectDB instances were leaked at exit`. Báo cáo Antigravity gán nguyên nhân cho từng instance nhưng chưa có dump ObjectDB verbose để xác thực nguyên nhân chính xác.

### P1-05 — Test hai tiến trình chưa kiểm tra tranh mua thật giữa hai client

Runner `tests/integration/coop_two_peers_runner.gd` chỉ chạy **một host và một client**. Sau khi client đầu mua hàng, nó gửi **một request mới từ cùng client**, không có client số 2 thực sự cùng tranh món cuối. Test chống race hiện chỉ xác minh xử lý sau khi hàng đã cạn, chưa có tranh chấp cùng lúc giữa hai client. Bổ sung host + 2 clients với yêu cầu cùng một frame / cùng cửa sổ thời gian.

### P1-06 — `coop_two_players.png` không xác minh co-op thật

`tools/capture_graphics_after.gd:118–144` tự `instantiate()` một `player.tscn` thứ hai, tự tô màu và tạo nhãn `[Đạo Hữu] ... (Client)`. Không có cuộc gọi `SessionAuthority.start_host()` / `join_host()` trong bước capture, không có remote peer data. **Ảnh này là minh họa 2 avatar trong một scene, không phải ảnh chứng minh 2 client đã đồng bộ.** Cần chụp độc lập cửa sổ Host và Client sau khi kết nối thật, kèm peer ID và timestamp.

### P1-07 — `ui_shop.png` có thể chưa chụp được modal cửa hàng

`tools/capture_graphics_after.gd:111–116` chỉ gọi nếu modal `has_method("open_shop")`. Tuy nhiên method trong `scenes/ui/player_shop_modal.gd:37` là `open_panel()`, không có `open_shop()`. Do đó code capture không thực hiện mở modal, giải thích việc ảnh `ui_shop.png` đang chủ yếu hiển thị giao diện town chứ không phải cửa sổ sạp. Cần sửa capture và chụp lại.

### P2 — Thiếu bằng chứng dữ liệu save multiplayer sau reconnect

Save roundtrip test dùng `SaveService.save_game(99)` với một `GameSession` trên host nhưng không xác thực authoritative inventory của từng peer, pending/replied transaction, trạng thái hoạt động của người chơi quay lại và idempotency xuyên phiên. Đây là phần cần thiết trước khi mở server lâu dài.

## 4. Đồ họa Phase 4

- 8 ảnh test có thật và có kích thước **1280×720**, gồm world ngày/đêm, town, combat, VFX, aura, UI và ảnh minh họa hai avatar.
- Hai ảnh world ngày/đêm có khác biệt pixel rõ ràng; đã có lọc màu sáng tối.
- **Không có spritesheet, tileset hay PNG đồ họa gameplay nào mới/thay đổi** so với ZIP trước. Toàn bộ 8 PNG mới là ảnh chụp audit.
- Vẫn là **prototype pixel/procedural**, chưa đạt phong cách tranh vẽ tay 2D tiên hiệp mục tiêu. Chưa nên đánh dấu Phase 4 Visual Art hoàn tất.
- Xem contact sheet: `DAO_TAN_AFTER_V2_GRAPHICS_CONTACT_SHEET.jpg` (file riêng đính kèm).

## 5. Tiêu chuẩn nghiệm thu vòng sửa tiếp theo

1. **P0 giao dịch:** host giữ số dư/túi đồ theo peer, client không tự cấp item; gửi cùng request 3 lần → chỉ thay đổi tài sản một lần; request ví giả 0/1 tỷ linh thạch không qua được; mỗi giao dịch có ledger và hoàn tác an toàn.
2. **Co-op gameplay:** có Host/Join trong menu; hai cửa sổ game (không phải runner headless) thấy avatar nhau chuyển động, có thể vào cùng town/arena, boss HP và loot khớp; thử host + 2 client cùng mua món cuối.
3. **Time:** vào phòng từ solo x20 → 1x; load save có `time_scale=20` ở host → vẫn 1x; chạy thật đủ 720s host/client qua mốc ngày mới; disconnect/reconnect không sai lệch lịch.
4. **NPC:** host mô phỏng tháng duy nhất; client nhận và apply bản ghi NPC / world revision; join late đồng bộ đầy đủ nhân vật, thị trường và thời gian.
5. **Audit/test:** log không còn unexpected ERROR, hoặc phải giải thích và xử lý test fixture; lưu unit raw logs và host/client **tách file gốc**, có mã thoát và timestamp; screenshot từ phiên multiplayer thực (mỗi cửa sổ).
6. **Đồ họa:** chụp sạp thực bằng `open_panel()`, đưa vào sprites/tilesets thật với asset manifest và giấy phép; đối chiếu BEFORE/AFTER cùng cảnh.

## 6. Đánh giá cuối

**Tiến bộ thật về code và kiểm thử nội bộ:** có; đặc biệt nhánh Space/time, script host/client, GDScript network sync và ảnh day/night. **Co-op đủ an toàn để 2–4 người chơi chính thức:** chưa. **Chống nhân đồ:** chưa đạt. **Phase 4 thay mỹ thuật:** chưa đạt. **Godot 172 PASS + 18 PASS:** là kết quả mà ZIP báo cáo, không phải bài kiểm thử tôi đã chạy lại.

Thứ tự tiếp theo nên là **P0 giao dịch → tích hợp co-op vào gameplay → test 2–3 client thật → đồng bộ NPC & save → cải thiện asset Phase 4**.
