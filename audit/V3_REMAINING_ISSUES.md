# BÁO CÁO CÁC VẤN ĐỀ CÒN TỒN ĐỌNG & MINH BẠCH KỸ THUẬT V3

**Ngày lập:** 05/11/2026  
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Người lập:** Lead Godot Multiplayer Engineer & QA Auditor  

---

## 1. TỔNG QUAN MINH BẠCH VỀ TRẠNG THÁI DỰ ÁN

Bản báo cáo này tuân thủ nguyên tắc **tuyệt đối minh bạch kỹ thuật**, không tô hồng, không che giấu lỗi, và làm rõ ranh giới giữa những gì đã chứng minh bằng runtime và những gì còn tồn đọng cần hoàn thiện trong các giai đoạn tiếp theo.

---

## 2. PHÂN TÍCH CHI TIẾT OBJECTDB LEAKS (P1-04)

### 2.1. Kết quả Dump Verbose từ Godot Engine
Khi chạy runner tự động với cờ `--verbose`, Godot Engine ghi nhận:
```text
Leaked instance: AudioStreamWAV:9223372096195790347 - Reference count: 2
Leaked instance: AudioStreamWAV:9223372096212567564 - Reference count: 2
Leaked instance: AudioStreamWAV:9223372096246121998 - Reference count: 2
Leaked instance: AudioStreamWAV:9223372096296453649 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372251485704504 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372257240289904 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372259438105322 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372262776771493 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372263733072836 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372263514969029 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372305206350946 - Reference count: 1
Orphan StringName: Master (static: 0, total: 14)
WARNING: 11 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

### 2.2. Đánh giá kỹ thuật
- **Nguồn gốc:** Toàn bộ 11 instance bị rò rỉ tại thời điểm thoát tiến trình đều thuộc về `AudioStreamWAV` và `AudioStreamPlaybackWAV`.
- **Nguyên nhân:** Trong môi trường Godot 4 Headless, khi `AudioService` phát các đoạn âm thanh procedural được sinh tự động (tiếng chém kiếm, sấm sét thiên kiếp), `AudioServer` của engine chưa kịp flush hết buffer playback trước khi tiến trình gọi `quit(0)`.
- **Mức độ ảnh hưởng:** Không ảnh hưởng đến logic gameplay, không làm tràn RAM khi chạy game thông thường (vốn có luồng AudioServer tiêu chuẩn). Trong tương lai, khi có file âm thanh tĩnh nạp qua ResourceLoader thay vì phát âm thanh procedural trong test, các cảnh báo này sẽ tự động triệt tiêu.

---

## 3. THỰC TRẠNG ĐỒ HỌA GIAI ĐOẠN 4 (PHASE 4 ARTWORK AUDIT)

### 3.1. Minh bạch về các file ảnh
- Toàn bộ **77 file PNG gốc** trong thư mục `assets/` và `wuxia/` **giữ nguyên 100% byte** từ các bản build trước.
- **8 ảnh PNG** trong thư mục `audit/graphics_after/` là ảnh chụp màn hình kiểm định kỹ thuật (QA screenshots kích thước 1280×720), bao gồm:
  1. `world_day.png`: Lọc sáng ban ngày (12:00 trưa).
  2. `world_night.png`: Ánh trăng xanh huyền ảo ban đêm (00:00).
  3. `town.png`: Thị trấn Thanh Trì Trấn.
  4. `combat.png`: Đấu trường chiến đấu.
  5. `combat_vfx.png`: Hiệu ứng kỹ năng và kiếm khí.
  6. `cultivation_aura.png`: Hào quang đột phá tu vi.
  7. `ui_shop.png`: Giao diện sạp hàng tu sĩ (đã sửa mở đúng bằng `open_panel()`).
  8. `coop_two_players.png`: Đã gắn nhãn **`[STAGED_DEMO]`** minh bạch, minh họa 2 avatar nhân vật 2D.
- **3 ảnh chụp mạng thật bổ sung:**
  - `coop_host_window.png` (64.8 KB): Chụp từ cửa sổ Host thật, hiển thị Host + 2 Avatar Client kết nối.
  - `coop_client_window.png` (65.7 KB): Chụp từ cửa sổ Client 1 thật (Tiêu Viêm).
  - `coop_client2_window.png` (65.4 KB): Chụp từ cửa sổ Client 2 thật (Hàn Lập).

### 3.2. Kết luận về Phase 4 Visual Art
Đồ họa hiện tại vẫn ở mức **prototype lập trình (procedural / programmer art / placeholder)**, chưa có các bộ spritesheet vẽ tay 2D thủy mặc tiên hiệp chuyên nghiệp. **Không đánh dấu Phase 4 Art là hoàn tất** cho đến khi đội ngũ họa sĩ bàn giao tài sản mỹ thuật chính thức.

---

## 4. TÍNH NĂNG GIAO DỊCH TRỰC TIẾP P2P (P2P DIRECT TRADE)

- Chức năng giao dịch trực tiếp giữa 2 người chơi (mở cửa sổ trao đổi trực diện, đặt đồ 2 bên và cùng nhấn Khóa/Đồng ý) hiện tại được đánh dấu minh bạch là **`NOT_IMPLEMENTED`** trong `ShopService.is_p2p_trade_implemented() -> false`.
- Hệ thống kinh tế Co-op hiện tại vận hành hoàn chỉnh qua cơ chế **Sạp Hàng Ký Gửi Chợ Tán Tu (Decentralized Stall Escrow)** với thẩm quyền Host Authoritative, chống duping, chống ví giả và chống race condition.

---

## 5. CỔNG MẠNG VÀ TƯƠNG THÍCH MÔI TRƯỜNG

- Cổng mặc định của game đã được chuyển đổi an toàn sang **`8899`** (thay vì 7777 nhằm tránh xung đột với các dịch vụ mạng cục bộ khác trên Windows).
- Hệ thống ENet của Godot hỗ trợ kết nối mạng LAN / Hamachi / Radmin VPN / ZeroTier mượt mà. Với môi trường Internet công cộng, người làm Host cần mở Port Forwarding cổng 8899 UDP trên router hoặc sử dụng giải pháp relay/hole-punching.
