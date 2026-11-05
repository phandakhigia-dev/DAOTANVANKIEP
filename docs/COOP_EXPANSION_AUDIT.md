# BÁO CÁO KIỂM KÊ VÀ ĐÁNH GIÁ KIẾN TRÚC HIỆN TẠI
## CO-OP EXPANSION AUDIT — ĐẠO TÀN: VẠN KIẾP
*Căn cứ tài liệu:* `docs/10_COOP_SOCIAL_ECONOMY_DYNASTY.md`  
*Thời điểm thực hiện:* 04/11/2026  
*Môi trường:* Godot 4.7.2-stable official (Windows x64)  
*Thư mục làm việc:* `G:\Game tự làm\DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT`  
*Bản lưu an toàn (Backup):* `G:\Game tự làm\DAO_TAN_VAN_KIEP_BACKUP_PHASE2`

---

## 1. TỔNG QUAN TÌNH TRẠNG DỰ ÁN

| Hạng mục | Hiện trạng thực tế | Đánh giá |
| :--- | :--- | :--- |
| **Giai đoạn đã hoàn thành** | Phase 0 (Nền tảng), Phase 1 (Vertical Slice), Phase 2 (Mô phỏng tháng & 36 NPC) | Hoạt động ổn định, 56/56 bài test tự động đạt 100% |
| **Đồng hồ thời gian** | `GameClock` đã hỗ trợ chu kỳ 12 phút / ngày (720s), 12 Canh Giờ, tỷ lệ 1:120 | Đã chuẩn bị sẵn cơ sở thời gian thực cho Co-op |
| **Mạng (Networking)** | Chưa có lớp mạng; game hiện chạy local offline single-player | **Cần xây dựng mới (MISSING):** `SessionAuthority` & `ClockReplication` |
| **Dữ liệu NPC** | 36 NPC định danh, 3 môn phái, traits, quan hệ (debt, grudge), memories | Sẵn sàng mở rộng lịch làm việc (Schedule POI) ở S2 |
| **Hệ thống Save** | `SaveService` schema v2, hỗ trợ atomic write và backward migration từ v1 | Sẵn sàng mở rộng session metadata cho Co-op |

---

## 2. BẢNG ĐÁNH GIÁ MODULE (EXISTING / NEEDS ADAPTER / MISSING / RISK)

| Module / Hệ thống | Trạng thái | Đánh giá chi tiết & Định hướng triển khai | Mức độ rủi ro |
| :--- | :---: | :--- | :---: |
| `GameClock` | **EXISTING & ADAPTER** | Đã có: 720s/ngày, second_in_day, 12 Canh Giờ, time_scale. <br>Cần thêm: RPC broadcast từ Server sang Clients, cơ chế nội suy chống drift thời gian giữa các máy. | **Thấp** |
| `Multiplayer / Network` | **MISSING** | Chưa có Godot High-Level Multiplayer (`ENetMultiplayerPeer`). <br>Cần tạo: Module `scripts/network/session_authority.gd` và `clock_replication.gd` cho mô hình Host-Authoritative (2–4 người chơi). | **Trung bình** |
| `SaveService` | **EXISTING & ADAPTER** | Đã có: Lưu metadata, schema validation v2, clock, player, npcs, memories. <br>Cần thêm: Lưu session mode (`coop_hosted`), danh sách người chơi kết nối, cờ đóng băng khi không có người online. | **Thấp** |
| `GameSession` | **EXISTING** | Quản lý state nhân vật, túi đồ, nhiệm vụ, quan hệ NPC, ân oán. <br>Giữ nguyên vẹn, đảm bảo không hồi quy tính năng tu luyện và đột phá. | **Thấp** |
| `NPC & Social Graph` | **EXISTING** | 36 NPC có 5 tính cách (`caution`, `greed`, `mercy`, `ambition`, `honor`), nợ ơn (`debt`), thù oán (`grudge`). <br>Sẵn sàng cho Sprint S2 tích hợp lịch sinh hoạt theo giờ (Schedule POI). | **Thấp** |
| `Town & Buildings` | **EXISTING** | `town_view.tscn` đã có 5 kiến trúc: Quán Trọ, Dược Phẩm Các, Chợ Tán Tu, Thanh Vi Phân Điện, Cổng Rừng Trúc. | **Thấp** |
| `Economy & Shop` | **NEEDS ADAPTER** | Đã có mua bán cơ bản ở Phase 1. <br>S3 sẽ bổ sung: Shop do người chơi thuê/sở hữu, kho hàng vật lý, sổ cái kế toán chống nhân bản vật phẩm (no duplicate). | **Trung bình** |
| `Combat Arena` | **EXISTING** | Đấu trường ARPG top-down, WASD, chuột, 3 skill, lướt i-frame, Boss Telegraph. <br>Giữ nguyên tuyệt đối; chỉ chạy cục bộ khi người chơi vào ải chiến đấu. | **Rất thấp** |

---

## 3. PHÂN TÍCH DI CHUYỂN (MIGRATION STRATEGY): SINGLE-PLAYER → CO-OP HOST-AUTHORITATIVE

1. **Quyền Tối Thượng Của Server (Host-Authoritative):**
   - Host (người tạo phòng) đóng vai trò là Authoritative Server.
   - Client gửi các yêu cầu dạng **Intent** (ví dụ: `request_join`, `request_action`), Server thẩm định hợp lệ rồi mới cập nhật state và phát tán kết quả.
   - Không cho phép Client tự gửi các gói tin "tự cộng tiền" hay "tự chỉnh giờ".

2. **Chính Sách Dừng Game (Pause Policy):**
   - Trong chế độ chơi đơn (Solo): Cho phép `is_paused = true` khi mở Pause Menu hoặc cài đặt.
   - Trong chế độ Co-op: Mở túi đồ `[I]`, nhân vật `[C]`, sổ nhân duyên `[J]` **KHÔNG** làm dừng thế giới. Thế giới tiếp tục trôi tự nhiên với tốc độ 12 phút / ngày.

3. **Chính Sách Bế Quan & Tua Nhanh Thời Gian:**
   - **Bế quan cá nhân:** Người chơi vào trạng thái nhập định chỉ tăng tốc độ nhận tu vi cá nhân và chuyển sang ngồi thiền; thời gian thế giới vẫn chảy ở nhịp chuẩn x1 để người khác tiếp tục chơi.
   - **Tua nhanh thế giới (Time-skip):** Khóa hoàn toàn ở giai đoạn S1; chỉ mở ở S5 khi có cơ chế biểu quyết đồng thuận 100% người chơi đang online.

---

## 4. KẾ HOẠCH BẢO VỆ VÀ TEST BASELINE

- **56 / 56 bài test hiện tại** (`test_runner.tscn`) là chốt chặn an toàn (regression gate). Mọi chỉnh sửa mã nguồn phải vượt qua 100% bộ test này.
- Mọi schema save mới phải có hàm migration tương thích ngược, không bao giờ làm hỏng save cũ của người chơi.
- Bản sao lưu nguyên vẹn toàn bộ dự án đã được tạo tại: `G:\Game tự làm\DAO_TAN_VAN_KIEP_BACKUP_PHASE2`.
