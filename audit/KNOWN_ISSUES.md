# DANH SÁCH LỖI & RỦI RO KỸ THUẬT TỒN ĐỌNG (KNOWN ISSUES & TECHNICAL RISKS)
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Thời điểm Audit:** 04/11/2026  
**Mục tiêu:** *Cung cấp góc nhìn minh bạch, trung thực tuyệt đối cho việc thẩm định và lập kế hoạch nâng cấp.*

---

## 1. BẢNG TỔNG HỢP VẤN ĐỀ TỒN ĐỌNG

| Mã Vấn Đề | Tên Vấn Đề | Mức Độ | Module / File Ảnh Hưởng | Trạng Thái |
| :--- | :--- | :---: | :--- | :--- |
| **ISSUE-01** | Cảnh báo ObjectDB Leak khi thoát Headless Engine | **THẤP (Info/Warning)** | Godot 4.7 Core (`cleanup`) | Đã cô lập, không ảnh hưởng gameplay |
| **ISSUE-02** | Giới hạn NavMesh AI quái vật trong Combat Arena | **TRUNG BÌNH** | `scenes/combat/combat_arena.gd` | Boss dùng khoảng cách Vector2, chưa né chướng ngại |
| **ISSUE-03** | Khóa tua nhanh thời gian (Time-Skip) trong Co-op | **THIẾT KẾ CỐ Ý** | `scripts/network/clock_replication.gd` | Chủ động khóa để bảo toàn tính đồng bộ |
| **ISSUE-04** | Hoạt ảnh nhân vật (Character Animation) dạng cơ bản | **TRUNG BÌNH** | `scenes/world/player.gd` | Sử dụng frame tĩnh & xoay hướng nội suy |
| **ISSUE-05** | Đồng bộ di chuyển thực thể Co-op (Entity Replication) | **TRUNG BÌNH** | `scripts/network/session_authority.gd` | Đã xong tầng Clock, đang chờ triển khai Peer Net |

---

## 2. CHI TIẾT TỪNG VẤN ĐỀ & PHÂN TÍCH NGUYÊN NHÂN

### ISSUE-01: Cảnh báo ObjectDB Instances Leak khi đóng Engine
- **Mức độ:** Thấp (Warning).
- **Hiện tượng:** Khi chạy bộ test tự động headless đến bước cuối cùng (`get_tree().quit(0)`), Godot in ra cảnh báo:
  ```
  WARNING: 21 ObjectDB instances were leaked at exit (run with `--verbose` for details).
     at: cleanup (core/object/object.cpp:2536)
  ```
- **File liên quan:** `core/object/object.cpp`, `test_runner.gd`.
- **Nguyên nhân phân tích:** Trong các bài test UI (`DialogueModal`, `TownMapReal`, `CombatArena`), các Node được khởi tạo thông qua `instantiate()` và đưa vào SceneTree tạm thời để kiểm thử logic. Mặc dù test suite đã gọi `queue_free()` hoặc `remove_child()`, trong chế độ headless việc gọi `get_tree().quit(0)` ngay trong cùng frame khiến bộ thu gom rác (Garbage Collector) của Godot 4.7 chưa kịp xả sạch ObjectDB trước khi tiến trình hệ điều hành bị chấm dứt.
- **Tác động:** Không gây memory leak trong quá trình chơi game bình thường (vì runtime diễn ra liên tục qua nhiều frame và bộ dọn rác hoạt động đều đặn).
- **Biện pháp khắc phục kiến nghị:** Trong các bài test tích hợp UI, chèn một frame trễ `await get_tree().process_frame` trước khi gọi lệnh `quit()`.

---

### ISSUE-02: Hành vi điều hướng Boss AI trong Combat Arena
- **Mức độ:** Trung bình.
- **Hiện tượng:** Trong `scenes/combat/combat_arena.gd`, Boss (`boss_xich_kiem_ma_thu` và `boss_hac_linh_xa_vuong`) di chuyển tiếp cận người chơi bằng phép toán vectơ khoảng cách thẳng (`global_position.direction_to(player.global_position)`).
- **File liên quan:** `scenes/combat/combat_arena.gd:160-210`.
- **Nguyên nhân phân tích:** Chưa tích hợp hệ thống bản đồ điều hướng `NavigationAgent2D` hoặc `AStar2D` vào scene đấu trường.
- **Tác động:** Đấu trường hiện tại là không gian mở hình tròn/chữ nhật nên việc di chuyển thẳng hoạt động rất mượt mà. Tuy nhiên nếu trong tương lai bổ sung các cột đá lớn, hồ dung nham hoặc vật cản phức tạp trong đấu trường, Boss có thể bị vướng vào mép chướng ngại vật.
- **Biện pháp khắc phục kiến nghị:** Nâng cấp đấu trường với `NavigationRegion2D` và gán `NavigationAgent2D` cho các thực thể quái vật trong Phase kế tiếp.

---

### ISSUE-03: Khóa chức năng Tĩnh Tọa Gia Tốc x20 khi Co-op
- **Mức độ:** Thiết kế an toàn có chủ đích (By Design).
- **Hiện tượng:** Khi có từ 2 người chơi tham gia phiên mạng, nút "Tĩnh Tọa" (Time-Skip) bị từ chối với thông báo:
  ```
  [ClockReplication] Time-skip bị khóa nghiêm ngặt trong Sprint S1 cho tới khi Sprint S5 được duyệt.
  ```
- **File liên quan:** `scripts/network/clock_replication.gd:22`.
- **Nguyên nhân phân tích:** Trong game Multiplayer thời gian thực, nếu một người chơi bấm tua nhanh x20 mà người kia vẫn đang di chuyển hoặc câu cá, việc đồng bộ vị trí thực thể và nhịp thời gian thế giới sẽ bị xung đột nghiêm trọng nếu không có hệ thống "Bầu chọn tập thể" (Vote to Sleep/Meditate).
- **Biện pháp khắc phục kiến nghị:** Khi triển khai Phase 1 Multiplayer đầy đủ, xây dựng cơ chế "Đồng thuận Tĩnh Tọa" (tất cả người chơi cùng bấm Tĩnh Tọa thì thời gian thế giới mới gia tốc x20).

---

### ISSUE-04: Đồ họa Hoạt Ảnh Nhân Vật & Kỹ Năng
- **Mức độ:** Trung bình.
- **Hiện tượng:** Nhân vật người chơi và quái vật hiện tại đang sử dụng các sprite 32x32 và xoay lật hướng (`flip_h`) kết hợp hiệu ứng rung chấn hoặc co giãn nhẹ (Scale Tweens), chưa có bộ spritesheet hoạt cảnh 8 hướng đa khung hình (Run, Idle, Attack, Cast Spell riêng biệt).
- **File liên quan:** `scenes/world/player.gd`, `scenes/towns/npc_character.gd`.
- **Nguyên nhân phân tích:** Dự án tập trung hoàn thiện hệ thống cơ chế Sandbox, Mô phỏng toán học, Logic xã hội, Tông môn và Cảnh giới trước, sử dụng bộ asset mẫu của Phase 4.
- **Biện pháp khắc phục kiến nghị:** Bổ sung AnimationPlayer và tích hợp các bộ Sprite Sheet Animation hoàn chỉnh vào giai đoạn sản xuất nội dung đồ họa chuyên sâu.
