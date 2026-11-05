# BÁO CÁO KẾT QUẢ KHẮC PHỤC V3 — ĐẠO TÀN: VẠN KIẾP

**Ngày phát hành:** 05/11/2026  
**Phiên bản audit:** V3 (Khắc phục toàn diện P0-01, P0-02, P0-03 và P1-01 đến P1-07)  
**Tác giả:** Lead Godot Multiplayer Engineer & Technical QA Auditor  
**Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf  
**Tình trạng kiểm thử:** **179/179 Unit Tests PASS** (24 Suites), **100% Co-op 2 & 3 Tiến trình PASS**

---

## 1. TỔNG QUAN KHẮC PHỤC THEO PHÂN LOẠI AUDIT V3

| Mã lỗi | Phân loại | Tình trạng trước V3 | Giải pháp & Kết quả sau V3 | Bằng chứng kiểm thử |
|---|---|---|---|---|
| **P0-01** | Client Duping qua Replay | Client tự `add_item` khi nhận `success`; gửi lặp được cấp đồ nhiều lần | Thực hiện **Reconciliation State**: Client chỉ nhận Authoritative Snapshot `(revision, wallet, items)`. Bỏ qua mọi response có `rev <= client_rev`. Không bao giờ tự `add_item` cục bộ. | `test_p0_v3_authoritative_economy.gd`: T-V3-01 PASS |
| **P0-02** | Server tin ví Client tự khai | RPC `request_buy_from_stall` nhận `buyer_wallet` từ Client; Server không lưu ví peer | **Bỏ hoàn toàn `buyer_wallet` khỏi RPC**. Host lưu `host_peer_inventories[peer_id]` độc lập. Thẩm tra số dư thực tế, trừ tiền + trừ kho + tăng doanh thu trong 1 commit nguyên tử trên Host. | `test_p0_v3_authoritative_economy.gd`: T-V3-02, T-V3-03 PASS |
| **P0-03** | Gameplay tách rời Multiplayer | Menu và gameplay không gọi `CoopWorldSync`, không có UI phòng mạng | Tạo **`CoopMenuModal`** tích hợp trực tiếp trong `hud.tscn` (Phím `[O]`); WorldMap spawn/retire remote avatar; Combat Arena route đòn đánh boss qua Host; Sạp hàng gọi RPC mua mạng. | `scenes/ui/coop_menu_modal.tscn`, `scenes/world/world_map.gd`, 3 tiến trình live gameplay PASS |
| **P1-01** | Host chưa xác thực đòn đánh Boss | Boss trừ máu trực tiếp, không rate-limit | Host kiểm tra thời gian giữa 2 đòn đánh theo peer (`min_interval_ms`), chỉ nhận intent, Host tính damage và phát sóng kết quả. | `scripts/network/coop_world_sync.gd:235-265` |
| **P1-02** | Snapshot tháng thiếu NPC Diff | Client chỉ lưu summary sự kiện, không cập nhật `world_npcs` | Host broadcast kèm `revision`, `world_npcs` và `memory_events`. Client cập nhật đầy đủ vào `GameSession.world_npcs`. | `scripts/domain/monthly_simulation_service.gd:38`, `coop_world_sync.gd:440` |
| **P1-03** | Save ghi đè time_scale Co-op | `from_dict` gán thẳng `time_scale` từ file | Thêm logic clamp: nếu `SessionAuthority.is_coop_session()` thì cưỡng chế `time_scale = 1.0` tuyệt đối. | `scripts/core/game_clock.gd:240-247` |
| **P1-04** | Error RPC in Active / Leaks | Gây lỗi `ERROR: Trying to call an RPC while no multiplayer peer is active` | Viết hàm an toàn `_safe_rpc` và `_safe_rpc_id` kiểm tra kết nối peer trước khi gọi; Phân tích dump verbose: 11 leaks thuộc về `AudioStreamPlaybackWAV` của engine. | `audit/REGRESSION_LOG_RAW.txt`, `V3_REMAINING_ISSUES.md` |
| **P1-05** | Chưa test 2 Client tranh mua | Chỉ test 1 client gửi lại sau khi cạn kho | Tạo kịch bản **3 tiến trình thực tế** (1 Host, Client 1, Client 2) gửi buy request đồng thời cho món duy nhất. Client 1 thành công, Client 2 bị từ chối an toàn. | `tools/test_coop_gameplay_live.py`, `audit/TEST_THREE_PEERS_RACE.md` |
| **P1-06** | Mockup staged coop_two_players | Script tự instantiate p2 nhưng không kết nối mạng thật | Đánh dấu nhãn `[STAGED_DEMO]` rõ ràng trên mockup; chụp bổ sung 3 screenshot từ **3 cửa sổ mạng thật**: `coop_host_window.png`, `coop_client_window.png`, `coop_client2_window.png`. | `audit/graphics_after/*.png` |
| **P1-07** | `ui_shop.png` gọi sai `open_shop` | Modal sạp không mở vì gọi hàm không tồn tại | Sửa `tools/capture_graphics_after.gd:115` gọi đúng `shop.open_panel()`. Ảnh mới chụp đầy đủ giao diện sạp hàng tu sĩ. | `audit/graphics_after/ui_shop.png` (148 KB) |
| **P2** | Save/Load Co-op sau Reconnect | SaveService không lưu sổ cái peer | Bổ sung `export_coop_state()` / `import_coop_state()` vào save schema; khôi phục toàn vẹn `host_peer_inventories` và `processed_transactions`. | `test_p0_v3_authoritative_economy.gd`: T-V3-05 PASS |

---

## 2. CHI TIẾT CẢI TIẾN KIẾN TRÚC S0 & S1

### 2.1. Mô hình Sổ Cái Authoritative (Host Ledger)
- Host nắm giữ `host_peer_inventories[peer_id] = { "wallet": int, "items": Dictionary, "revision": int, "guid": String }`.
- Giao dịch được khóa theo bộ khóa kép `"%d:%s" % [peer_id, request_id]`.
- Commit được thực hiện trong 1 hàm duy nhất:
  1. Trừ tồn kho trong `ShopService.escrow_items`.
  2. Trừ `peer_state["wallet"]` trên máy chủ.
  3. Cộng `peer_state["items"][item_id]` trên máy chủ.
  4. Tăng `ShopService.accumulated_revenue`.
  5. Tăng `peer_state["revision"]`.
  6. Gửi snapshot trạng thái mới về cho Client.
- Phía Client: Hàm `_reconcile_client_state` điều chỉnh số dư và túi đồ của `GameSession` khớp tuyệt đối với dữ liệu máy chủ gửi về khi `revision > client_authoritative_revision`. Bất kỳ gói tin lặp nào có `revision <= client_authoritative_revision` đều bị loại bỏ ngay lập tức.

### 2.2. Tích hợp Mạng vào Gameplay Thực Tế
- **HUD Co-op Control:** Scene `scenes/ui/coop_menu_modal.tscn` được nhúng vào `hud.tscn`, hỗ trợ phím tắt `[O]` hoặc click chuột. Cho phép người chơi Host phòng (mặc định port 8899), Join phòng qua IP/Port, hoặc ngắt kết nối an toàn.
- **WorldMap Remote Avatars:** `scenes/world/world_map.gd` lắng nghe tín hiệu `CoopWorldSync.remote_player_updated`. Khi có người chơi khác trong phòng, tự động sinh Avatar đồng đạo mang hoạt ảnh và bảng tên `[Đạo Hữu] Tên (#ID)` màu lam nhạt, thực hiện nội suy vị trí mượt mà (Lerp 12x). Input bàn phím/chuột chỉ tác động lên avatar nhân vật của máy cục bộ.
- **Combat Arena Co-op:** Đòn đánh lên Boss trong chế độ Co-op gửi intent qua `CoopWorldSync.request_attack_boss`. Máy chủ Host kiểm tra tốc độ ra chiêu (rate-limit), trừ máu thẩm quyền và phát sóng kết quả cho tất cả người chơi.

---

## 3. KẾT QUẢ KIỂM THỬ THỰC TẾ

1. **Unit Test Runner (`run_tests_capture_raw.py`):**
   - Tổng cộng: **179 bài kiểm thử** trên 24 suites.
   - Kết quả: **179 ĐẠT (PASS)** | **0 THẤT BẠI (FAIL)**.
   - Log thô: [`audit/REGRESSION_LOG_RAW.txt`](REGRESSION_LOG_RAW.txt) và [`audit/regression_raw.log`](regression_raw.log).
2. **Kiểm thử 2 Tiến trình (`test_coop_two_peers.py`):**
   - Host Exit Code: 0 (PASS), Client Exit Code: 0 (PASS).
   - Log thô: [`audit/coop_host_raw.log`](coop_host_raw.log), [`audit/coop_client_raw.log`](coop_client_raw.log).
3. **Kiểm thử 3 Tiến trình Tranh Mua Món Cuối (`test_coop_gameplay_live.py`):**
   - Host Exit Code: 0 (PASS), Client 1 Exit Code: 0 (PASS), Client 2 Exit Code: 0 (PASS).
   - Log thô: [`audit/host_raw.log`](host_raw.log), [`audit/client1_raw.log`](client1_raw.log), [`audit/client2_raw.log`](client2_raw.log).
   - Báo cáo chi tiết: [`audit/TEST_THREE_PEERS_RACE.md`](TEST_THREE_PEERS_RACE.md).
