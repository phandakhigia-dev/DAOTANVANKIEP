# BÁO CÁO KIỂM THỬ CO-OP 3 TIẾN TRÌNH THẬT & RACE CONDITION V3

**Ngày kiểm thử:** 05/11/2026 10:31:15  
**Môi trường:** Godot Engine v4.7.2.stable.official.ed1daf0bf trên Windows  
**Giao thức:** ENet Multiplayer (Host-Authoritative)  
**Cổng (Port):** 8899  

## 1. Kết quả thực thi các tiến trình độc lập

| Tiến trình | Vai trò | Exit Code | Trạng thái | Log thô |
|---|---|---|---|---|
| **Process 1** | Host Server (Chủ Phòng) | `0` | PASS | [`audit/host_raw.log`](host_raw.log) |
| **Process 2** | Client 1 (Đạo Hữu Tiêu Viêm) | `0` | PASS | [`audit/client1_raw.log`](client1_raw.log) |
| **Process 3** | Client 2 (Đạo Hữu Hàn Lập) | `0` | PASS | [`audit/client2_raw.log`](client2_raw.log) |

## 2. Xác thực cuộc đua giao dịch món cuối (Race Condition)

- **Số lượng tồn kho ban đầu:** 1x Tẩy Tủy Đan (Giá 150 Linh Thạch).
- **Hành vi kiểm tra:** Client 1 và Client 2 cùng gửi yêu cầu mua `item_tay_tuy_dan` (1 món) đồng thời qua RPC.
- **Kết quả cam kết trên Host:**
  - Client 1 đến trước được chấp thuận (`success=true`). Authoritative wallet bị trừ 150 LT, nhận 1x Tẩy Tủy Đan.
  - Client 2 đến sau lập tức bị từ chối an toàn (`success=false`, `"Hàng trong sạp đã hết hoặc không đủ số lượng!"`). Số dư của Client 2 không bị trừ.
  - Tồn kho sạp hàng cạn về đúng `0` (không bao giờ âm).
  - Doanh thu sạp tăng đúng `150` Linh Thạch (không bị tính trùng 300).

## 3. Bằng chứng Screenshot thực tế từ 3 cửa sổ độc lập

- **Host Window:** `audit/graphics_after/coop_host_window.png` (64828 bytes)
- **Client 1 Window:** `audit/graphics_after/coop_client_window.png` (65722 bytes)
- **Client 2 Window:** `audit/graphics_after/coop_client2_window.png` (65442 bytes)

Tất cả các ảnh chụp trên được lưu trực tiếp từ bộ đệm của GPU trong phiên chạy thật, không phải mockup vẽ lại.
