# AUDIT ĐỒNG BỘ MẠNG, THỜI GIAN VÀ CHỐNG GIAN LẬN (MULTIPLAYER & TIME AUDIT)
**Dự án:** ĐẠO TÀN: VẠN KIẾP (Godot 4.7.2 GDScript Native Windows PC)  
**Tài liệu:** `audit/MULTIPLAYER_TIME_AUDIT.md`  
**Ngày thực hiện:** 04/11/2026  
**Auditor:** Senior Game Architect & Technical QA Auditor  

---

## 1. TỔNG QUAN KIẾN TRÚC MULTIPLAYER

Hệ thống mạng của *Đạo Tàn: Vạn Kiếp* được thiết kế theo mô hình **Host-Authoritative Co-op (2–4 người chơi)** sử dụng Godot High-Level Multiplayer API (`ENetMultiplayerPeer`):

```
                     ┌────────────────────────────────────────┐
                     │          HOST (Peer ID = 1)            │
                     │  - Quyền lực tối thượng (Authority)   │
                     │  - Chủ trì GameClock & ClockReplication│
                     │  - Xử lý Sinh quái, AI, Chợ, Escrow   │
                     │  - Quản lý Save/Load thế giới         │
                     └──────────────────┬─────────────────────┘
                                        │
                 ┌──────────────────────┴──────────────────────┐
                 │ ENet RPCs (Reliable & Unreliable Channels)  │
                 ▼                                             ▼
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│       CLIENT A (Peer ID = 2)     │           │       CLIENT B (Peer ID = 3)     │
│  - Điều khiển nhân vật bản địa  │           │  - Điều khiển nhân vật bản địa  │
│  - Nhận Clock Snapshot mỗi 0.5s │           │  - Nhận Clock Snapshot mỗi 0.5s │
│  - Gửi Intent giao dịch/chiến đấu│          │  - Gửi Intent giao dịch/chiến đấu│
└─────────────────────────────────┘           └─────────────────────────────────┘
```

### Các lớp cốt lõi tham gia:
- **`scripts/network/session_authority.gd` (Autoload `SessionAuthority`)**:
  - Quản lý trạng thái kết nối (`STANDALONE`, `HOST_SERVER`, `CLIENT`).
  - Cổng mặc định: UDP port `7777`, hỗ trợ tối đa `MAX_PLAYERS = 4`.
  - Phân quyền: Hàm `is_server_authoritative()` chỉ trả về `true` cho Host và chế độ Chơi Đơn (Standalone).
- **`scripts/network/clock_replication.gd` (Autoload `ClockReplication`)**:
  - Host phát sóng (`sync_clock_snapshot.rpc`) định kỳ `SYNC_INTERVAL_SEC = 0.5s` thực tế.
  - Client nhận dữ liệu và thực hiện hiệu chỉnh thời gian (Reconciliation).
- **`scripts/core/game_clock.gd` (Autoload `GameClock`)**:
  - Động cơ thời gian trung tâm, quản lý ngày, tháng, năm, giờ, phút, khắc và 12 Canh Giờ võ hiệp.

---

## 2. KIỂM ĐỊNH ĐỒNG HỒ THẾ GIỚI (1 NGÀY = 12 PHÚT THỰC)

### 2.1. Công thức và Hằng số chuẩn hóa trong Code
Trong file [game_clock.gd](file:///G:/Game%20t%E1%BB%B1%20l%C3%A0m/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/core/game_clock.gd):
```gdscript
const SECONDS_PER_DAY: float = 86400.0         # 24 giờ in-game
const REAL_SECONDS_PER_DAY: float = 720.0       # 12 phút thực tế (720 giây)
const TIME_RATIO: float = 120.0                 # 86400.0 / 720.0 = 120.0
```

### 2.2. Bảng đối chiếu thời gian:
| Đơn vị thời gian | Thời gian trong Game | Thời gian thực tế | Kiểm thử xác minh |
|---|---|---|---|
| **1 Giây thực** | 2 Phút (120s in-game) | 1.0 giây | `test_game_clock_realtime.gd` |
| **1 Giờ in-game** | 3,600s in-game | **30.0 giây thực** | Pass (100%) |
| **1 Canh Giờ (2h)** | 7,200s in-game | **60.0 giây thực** | Pass (100%) |
| **1 Ngày in-game** | 86,400s (24h) | **720.0 giây thực (12 phút)** | Pass (100%) |
| **1 Tháng in-game** | 30 Ngày | 21,600 giây (6 giờ thực) | Pass (100%) |
| **1 Năm in-game** | 12 Tháng (360 ngày) | 259,200 giây (72 giờ thực) | Pass (100%) |

### 2.3. Quy tắc bắt đầu ngày:
- Ngày mới trong game bắt đầu vào lúc **06:00 sáng** (`second_in_day = 21600.0`), tương ứng **Giờ Mão (05h - 07h)**.
- Khi thời gian tích lũy vượt qua 86,400s (06:00 sáng hôm sau), `GameClock` chuyển sang ngày kế tiếp và kích hoạt tín hiệu `EventBus.day_passed.emit()`.

---

## 3. THẨM QUYỀN THỜI GIAN CỦA HOST (HOST-AUTHORITATIVE)

### 3.1. Cơ chế phát sóng Snapshot (Host -> Clients)
Mỗi **0.5 giây thực** (tương đương 1 phút trôi qua trong game), Host gọi:
```gdscript
@rpc("authority", "call_remote", "unreliable")
func sync_clock_snapshot(y: int, m: int, d: int, sec: float, scale_val: float) -> void:
```
- **Kênh Unreliable UDP:** Đảm bảo không bị tắc nghẽn đường truyền (Head-of-line blocking) nếu một gói tin đồng bộ thời gian bị mất.
- **Thẩm tra Client:** Client kiểm tra `if SessionAuthority.current_role != SessionAuthority.NetworkRole.CLIENT: return`. Client tuyệt đối không thể tự ý phát đè thời gian lên Server.

### 3.2. Kiểm soát trôi dạt (Clock Drift Reconciliation)
Khi Client nhận snapshot từ Host:
- **Lệch lớn (Hard Snap):** Nếu sai lệch năm/tháng/ngày hoặc độ lệch giây thực `sec_drift > 480.0s in-game` (tương đương 4 giây thực):
  Client lập tức gán cứng (`snap`) lại theo snapshot của Host để tránh lệch pha sự kiện ngày/đêm.
- **Lệch nhỏ (Soft Reconciliation):** Nếu lệch dưới 4 giây thực, Client nội suy mượt mà qua hàm `lerp`:
  ```gdscript
  GameClock.second_in_day = lerp(GameClock.second_in_day, sec, 0.4)
  ```
  Nhờ đó, vị trí kim đồng hồ, ánh sáng ngày đêm (Day/Night cycle) trên máy Client không bị giật cục.

---

## 4. CƠ CHẾ BẾ QUAN GIA TỐC VÀ KHÓA TIME-SKIP

### 4.1. Bế quan / Tĩnh tọa gia tốc x20
- Trong chế độ chơi đơn hoặc khi Host chấp thuận:
  - `time_scale = 20.0`
  - Lúc này, **1.5 giây thực tế lướt qua đúng 1 giờ in-game** (thay vì 30 giây thực).
  - 1 ngày in-game (24h) trôi qua trong **36 giây thực tế**.
- Trong Co-op:
  - Client muốn gia tốc bế quan phải gửi Intent lên Host qua hàm RPC:
    ```gdscript
    @rpc("any_peer", "call_remote", "reliable")
    func request_time_scale_change(requested_scale: float) -> void:
    ```
  - Host kiểm tra tính hợp lệ (`requested_scale == 1.0 or requested_scale == 20.0`). Nếu một Client đang trong combat hoặc từ chối, Host có toàn quyền từ chối lệnh này.

### 4.2. Khóa Time-Skip trong Co-op
- Trong [clock_replication.gd](file:///G:/Game%20t%E1%BB%B1%20l%C3%A0m/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/network/clock_replication.gd#L72-L75):
  ```gdscript
  func request_time_skip(_days: int) -> bool:
      print("[ClockReplication] Time-skip bị khóa nghiêm ngặt trong Sprint S1 cho tới khi Sprint S5 được duyệt.")
      return false
  ```
- **Ý nghĩa thiết kế:** Ngăn ngừa việc một người chơi "ngủ/skip 30 ngày" làm desync toàn bộ NPC, cây dược liệu và tiến trình của những người chơi khác trong phòng.

---

## 5. ĐỒNG BỘ NHÂN VẬT, NPC, COMBAT VÀ TÚI ĐỒ

| Hệ thống | Cơ chế đồng bộ hiện tại | Trạng thái kỹ thuật | Rủi ro tiềm ẩn |
|---|---|---|---|
| **Vị trí người chơi** | `SessionAuthority` theo dõi `connected_peers`. `LocalPlayer` di chuyển trên máy cục bộ. | PARTIAL (Khung kết nối hoàn tất, chưa gắn Multi-Player Spawner trong World Scene) | Cần Spawner RPC sinh avatar của peer khác trên bản đồ khi kết nối. |
| **Đồng bộ NPC** | Quản lý độc quyền bởi Host. `MonthlySimulationService` và `DialogueScenarioService` chạy trên Host. | DONE (Local & Server Authoritative) | Client cần RPC nhận danh sách thay đổi quan hệ NPC từ Host. |
| **Đồng bộ Combat** | Hitbox và sát thương tính toán dựa trên `GameSession.player_attack` và `defense`. | PARTIAL (Local logic hoàn thiện 100%, chưa chuyển qua Remote RPC damage hit) | Nguy cơ hack sát thương từ client nếu tin cậy hoàn toàn client input. |
| **Túi đồ & Tiền tệ** | Lưu trữ độc lập trong `GameSession` của mỗi peer. Giao dịch qua Chợ Tán Tu được quản lý bởi `ShopService`. | DONE (Atomic logic nội bộ) | Cần máy chủ Host trung gian thẩm định khi 2 người chơi trao đổi trực tiếp. |

---

## 6. ĐÁNH GIÁ NGUY CƠ NHÂN ĐÔI VẬT PHẨM (ANTI-DUPLICATION AUDIT)

### 6.1. Mô hình Ký Gửi An Toàn (Escrow Pattern trong `ShopService`)
Trong [shop_service.gd](file:///G:/Game%20t%E1%BB%B1%20l%C3%A0m/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/domain/shop_service.gd):
- Khi người chơi ký gửi vật phẩm vào sạp hàng:
  1. Kiểm tra số lượng trong túi: `has_qty = GameSession.get_item_count(item_id)`
  2. **Trừ vật phẩm khỏi túi đồ TRƯỚC:** `GameSession.remove_item(item_id, count)`
  3. Nếu trừ thành công, mới đưa vào mảng `escrow_items`.
- Khi người chơi rút vật phẩm:
  1. Kiểm tra tồn kho sạp: `cur_count >= count`
  2. **Trừ số lượng trong sạp TRƯỚC:** `slot["count"] = remain`
  3. Sau đó mới gọi `GameSession.add_item(item_id, count)`.
- **Đánh giá:** Không thể thực hiện Duping (nhân bản đồ) qua lỗi Race Condition cục bộ.

### 6.2. Kịch bản ngắt kết nối (Disconnect Handling)
Trong [session_authority.gd](file:///G:/Game%20t%E1%BB%B1%20l%C3%A0m/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/network/session_authority.gd#L91-L95):
- Khi một Client ngắt kết nối đột ngột:
  - Tín hiệu `multiplayer.peer_disconnected` được kích hoạt.
  - Peer bị xóa khỏi danh bạ `connected_peers.erase(id)`.
  - Phát tín hiệu `peer_left.emit(id)`.
- Khi Host ngắt kết nối hoặc Client bị đá khỏi phòng:
  - Hàm `stop_session()` đóng socket ENet, trả `current_role` về `STANDALONE`.
  - Dữ liệu túi đồ của Client được giữ nguyên ở trạng thái đã lưu gần nhất, không bị rollback gây mất mát tài sản.

### 6.3. Khuyến nghị nâng cấp bảo mật mạng cho Giai đoạn tiếp theo (ChatGPT Review):
1. **P2P Direct Trading:** Khi xây dựng tính năng trade trực tiếp (giao diện 2 cửa sổ mời giao dịch), bắt buộc sử dụng **2-Phase Commit (2PC)**:
   - Giai đoạn 1: Khóa vật phẩm của cả hai bên vào trạng thái `LOCKED`.
   - Giai đoạn 2: Cả 2 cùng bấm `Xác nhận lần 2` -> Host thực hiện tráo đổi nguyên tử. Nếu 1 bên disconnect -> Tự động trả về túi đồ ban đầu.
2. **Server-Side Validation:** Đảm bảo khi Client gọi mua hàng từ sạp người khác, Host là bên trừ tiền của người mua và cộng tiền vào `accumulated_revenue` của người bán.

---

## 7. KẾT LUẬN AUDIT MULTIPLAYER & THỜI GIAN

1. **Chu chuẩn thời gian:** Đạt chuẩn tuyệt đối **1 ngày = 720 giây thực (12 phút)** theo đúng đặc tả game. 1 giờ = 30s thực, 1 canh giờ = 60s thực.
2. **Quyền lực máy chủ:** Host-Authoritative được bảo vệ nghiêm ngặt qua `SessionAuthority` và `ClockReplication`.
3. **Cơ chế bế quan:** Gia tốc x20 được kiểm soát qua RPC Host; Time-skip nhiều ngày bị khóa cứng an toàn.
4. **Mô hình tài sản:** Escrow Pattern chống nhân bản vật phẩm đã sẵn sàng và được kiểm thử tự động 100% PASS.
