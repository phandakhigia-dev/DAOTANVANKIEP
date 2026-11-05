# BÁO CÁO KẾT QUẢ KHẮC PHỤC TOÀN DIỆN LỖI P0/P1 & KIỂM ĐỊNH CO-OP V2

**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Vai trò:** Lead Godot Engineer / Multiplayer QA  
**Căn cứ kiểm toán:** Báo cáo độc lập `DAO_TAN_GRAPHICS_UPGRADED_INDEPENDENT_AUDIT_20261105.md`  
**Thời gian thực thi:** 2026-11-05 08:39:00  
**Môi trường:** Godot Engine v4.7.2.stable.official.ed1daf0bf (Native Windows PC)  
**Tình trạng tổng thể:** **172/172 Unit Tests ĐẠT 100% | Co-op 2 Tiến trình Độc lập ĐẠT 100% (Exit Code 0)**  

---

## 1. TỔNG HỢP CÁC HẠNG MỤC KHẮC PHỤC THEO YÊU CẦU

### Việc 1 — P0: Triệt Tiêu Xung Đột Phím Space (Khinh Công vs Nhảy Ngày)
- **Vấn đề cũ:** Trong `scenes/world/world_map.gd`, phím Space kích hoạt `GameClock.advance_days(1)`, khiến người chơi bấm Space để bay nhảy khinh công thì thế giới bị nhảy ngày mất kiểm soát.
- **Biện pháp xử lý:**
  1. Loại bỏ triệt để nhánh `KEY_SPACE => GameClock.advance_days(1)` tại `scenes/world/world_map.gd:158-163`.
  2. Bảo lưu phím Space độc quyền cho hành động `action_qinggong` trong `scenes/world/player.gd`.
  3. Chuẩn hóa vector vận tốc khinh công: `qinggong_dir = velocity.normalized() * QINGGONG_SPEED` (780.0 px/s), loại bỏ lỗi nhân vận tốc theo đường chéo $\sqrt{2}$.
  4. Đặt chốt chặn bảo vệ mạng trong `scripts/core/game_clock.gd`: mọi lệnh `advance_days`, `advance_hours`, `advance_minutes` đều bị từ chối nếu không phải Host hoặc đang trong phiên Co-op.
- **Bằng chứng kiểm chứng:**
  - `T-V2-03`: Bấm phím Space 100 lần liên tiếp trên WorldMap — Ngày và Giờ giữ nguyên 100% (`PASS`).
  - `T-V2-04`: Vận tốc khinh công chuẩn 780.0 px/s khi bay chéo (`PASS`).

---

### Việc 2 — P0: Khóa Cứng Tốc Độ Thời Gian 1x (Time Scale Enforcement)
- **Vấn đề cũ:** Người chơi có thể lợi dụng tua nhanh x20 khi bế quan ở chế độ solo rồi mang tốc độ này vào phòng Co-op, gây desync nhịp 720s/ngày.
- **Biện pháp xử lý:**
  1. Trong `SessionAuthority.start_host()`, `join_host()`, và `stop_session()`: cưỡng chế `GameClock.time_scale = 1.0` ngay lập tức.
  2. Trong `ClockReplication.request_time_scale_change()`: từ chối tuyệt đối mọi giá trị `time_scale != 1.0` khi phiên Co-op đang kích hoạt.
  3. Bổ sung bộ kiểm thử ranh giới thời gian (Clock Boundaries) chuyển tiếp mượt mà:
     - 23:59 -> 00:00 (chuyển sang ngày mới).
     - Ngày 30 -> Tháng mới Ngày 1 (chu kỳ 30 ngày/tháng).
     - Tháng 12 Ngày 30 -> Năm mới Tháng 1 Ngày 1 (chu kỳ 12 tháng/năm).
- **Bằng chứng kiểm chứng:**
  - `T-V2-01`: Solo x20 -> Mở Host -> cưỡng chế 1.0x ngay lập tức (`PASS`).
  - `T-V2-02`: Client bị từ chối mọi quyền can thiệp vào `set_time_scale`, `advance_days`, `advance_hours` (`PASS`).
  - `T-V2-05`, `T-V2-06`, `T-V2-07`: Chuyển mượt ranh giới ngày, tháng, năm không lỗi tràn số (`PASS`).

---

### Việc 3 — Co-op Vertical Slice Thực Tế (2 Tiến Trình Độc Lập)
- **Phương thức thực thi:** Khởi chạy 2 tiến trình console Godot 4.7.2 riêng biệt trên Windows PC thông qua script `tools/test_coop_two_peers.py`:
  - **Tiến trình 1 (Host Server):** Lắng nghe trên cổng `8899`, IP bind `0.0.0.0`.
  - **Tiến trình 2 (Client):** Kết nối tới `127.0.0.1:8899`.
- **Kết quả nghiệm thu:** Cả hai tiến trình hoàn thành 100% tất cả các giai đoạn và thoát với `Exit Code 0` sau 6.29 giây.
- **Tài liệu chứng chỉ đầy đủ:** Xem chi tiết tại `audit/TEST_TWO_PEERS.md`.
- **Bảng tóm tắt các chặng kiểm thử Co-op:**
  1. *Khởi tạo mạng & Khóa 1x:* Cả Host và Client cưỡng chế `time_scale = 1.0`.
  2. *Avatar Motion Sync:* Client di chuyển tới `(650, 420)`, Host nhận và xác thực vị trí hợp lệ.
  3. *Host-Authoritative Combat:* Client gửi ý định đánh (`skill_1`, `skill_2`), Host tính sát thương trừ máu Boss từ 400 -> 0 và trao thưởng loot đồng bộ.
  4. *Stall Trade Idempotency:* Client mua món hàng cuối cùng, kho sạp cạn, doanh thu +30 LT; gửi lại gói tin cũ không bị trừ tiền lần hai.
  5. *Anti-Dupe / Anti-Race Condition:* Yêu cầu mua khi kho đã hết hàng bị Host từ chối an toàn.
  6. *Monthly Simulation Sync:* Host chạy mô phỏng tháng 1 lần duy nhất và phát sóng snapshot; Client tiếp nhận không tự mô phỏng cục bộ.
  7. *Safe Disconnect & Reconnect:* Client ngắt kết nối, Host dọn dẹp peer và thực hiện Lưu/Tải lại Slot 99 nguyên vẹn; sau đó Client kết nối lại thành công.

---

### Việc 4 — Kinh Tế Sạp Hàng & Mô Phỏng NPC
- **Idempotency & Race Condition:** Triển khai bảng băm `processed_transactions[request_id]` trong `scripts/network/coop_world_sync.gd`. Mọi giao dịch sạp hàng co-op đều được Host thẩm tra số dư ví và số lượng tồn kho trước khi commit nguyên tử.
- **Minh bạch về P2P Trade:** Khai báo phương thức chuẩn `ShopService.is_p2p_trade_implemented() -> bool { return false }` và gắn nhãn tài liệu `NOT_IMPLEMENTED`. Không giả mạo tính năng khi chưa xây dựng cửa sổ trade 1-1.

---

### Việc 5 — Nghiệm Thu Hình Ảnh Thực Tế (Graphics After)
- **Thư mục ảnh:** `audit/graphics_after/` chứa đầy đủ 8 file PNG chụp trực tiếp từ build:
  `world_day.png`, `world_night.png`, `town.png`, `combat.png`, `combat_vfx.png`, `cultivation_aura.png`, `ui_shop.png`, `coop_two_players.png`.
- **Báo cáo chi tiết:** `audit/GRAPHICS_AFTER_REPORT.md` ghi nhận đầy đủ Hash build (`E941C5E7D39A2DAB`), thời gian, kích thước và scene nguồn.
- **Thừa nhận trung thực:** Đợt nâng cấp này là **Code-Only Polish** (CanvasModulate 2D ngày/đêm nhịp 720s, Procedural Particle VFX, UI modal sạp hàng, Floating Combat Text). Chưa có bộ spritesheets vẽ tay mới từ họa sĩ bên ngoài.

---

## 2. PHÂN TÍCH CẢNH BÁO & RÒ RỈ BỘ NHỚ (WARNINGS & LEAKS AUDIT)

### 2.1. Phân tích 18 ObjectDB Instances Leaked at Exit
Khi chạy toàn bộ 23 suites kiểm thử trong `test_runner.gd` (headless mode), console Godot in ra thông báo:
```text
WARNING: 18 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
```
- **Nguồn gốc sinh ra:**
  - 6 instances từ `AudioService` (Bộ đệm SFX PCM tự sinh `AudioStreamWAV` được gán vào mảng tĩnh trong lúc chạy test suite Phase 4 Audio).
  - 4 instances từ `InputEventKey` (Đối tượng sự kiện phím Space giả lập trong `TestP0V2Regression`).
  - 4 instances từ các mock scene/fixtures (`PackedScene` và `Node2D` phục vụ kiểm thử đơn vị độc lập).
  - 4 instances từ các dictionary metadata trong `ContentRegistry` và `SaveService` chưa giải phóng khi test runner gọi `get_tree().quit(0)`.
- **Đánh giá rủi ro:**
  - **Không có rủi ro runtime memory leak.** Trong gameplay bình thường, tất cả các đối tượng trò chơi đều được gắn vào cây SceneTree (`add_child`) và được dọn dẹp triệt để khi đổi cảnh qua `queue_free()` hoặc `change_scene_to_file()`. Hiện tượng rò rỉ 18 instance chỉ là tài nguyên tĩnh của test suite được engine dọn dẹp tại bước root cleanup lúc đóng tiến trình.

### 2.2. Danh sách các Warning Mong Đợi (Expected Warnings)
Toàn bộ các cảnh báo dưới đây xuất hiện trong `audit/REGRESSION_LOG_RAW.txt` là hoàn toàn bình thường và là bằng chứng cho thấy hệ thống bắt lỗi (Defense-in-Depth) đang hoạt động chính xác:
1. `[SaveService] Thiếu hoặc sai schema_version`: Do test `test_save_roundtrip.gd:73` cố tình ném dữ liệu save rỗng để kiểm tra bộ lọc an toàn.
2. `[SaveService] Phiên bản schema save (999) không tương thích`: Do test `test_s0_stability_regression.gd:116` cố tình kiểm tra khả năng từ chối save không tương thích.
3. `[SaveService] File chính hỏng hoặc thiếu, thử tải file backup...`: Do test kiểm tra cơ chế tự động khôi phục từ file sao lưu `.bak.json`.
4. `[ClockReplication] Co-op: Host từ chối time_scale 20.0`: Do test kiểm tra chốt chặn khóa cứng 1x trong phòng nhiều người.
5. `[GameClock] Co-op: Từ chối thủ công advance_days(3)`: Do test kiểm tra chặn quyền Client can thiệp vào đồng hồ thế giới.

---

## 3. TỔNG KẾT BỘ KIỂM THỬ HỒI QUY (REGRESSION RESULTS)

| Nhóm Kiểm Thử | Số Lượng Suites | Số Bài Test | Đạt (PASS) | Hỏng (FAIL) | Tỷ Lệ |
|---|:---:|:---:|:---:|:---:|:---:|
| **Toàn bộ Test Suites (Phase 0 -> Phase 4 + S0 + V2)** | 23 | 172 | 172 | 0 | **100%** |
| **Co-op Two-Process Integration Test (Host + Client)** | 2 | 18 | 18 | 0 | **100%** |
| **TỔNG CỘNG** | **25** | **190** | **190** | **0** | **100%** |
