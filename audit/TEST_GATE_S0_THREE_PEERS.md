# BÁO CÁO KIỂM THỬ CO-OP LIVE 3 TIẾN TRÌNH THẬT — GATE S0
**Thời điểm thực thi:** 2026-11-05 21:44:14  
**Scene mục tiêu:** `res://scenes/world/province_world.tscn` (Thế giới mở liền mạch Thanh Trì Huyện)  
**Cổng ENet:** 8990  
**Thời lượng thực thi:** 11.56s  
**Trạng thái tổng thể:** ✓ PASS (ĐẠT 100%)

---

## 1. Kết quả thực thi các tiến trình
| Vai trò tiến trình | Danh tính | Exit Code | Kết quả |
|---|---|---|---|
| **HOST SERVER** | Chủ Phòng Host (`guid_host_master`) | 0 | PASS |
| **CLIENT 1** | Đạo Hữu Tiêu Viêm (`guid_tieu_viem_01`) | 0 | PASS |
| **CLIENT 2** | Đạo Hữu Hàn Lập (`guid_han_lap_02`) | 0 | PASS |

---

## 2. Tiêu chí nghiệm thu Gate S0
1. **P0-01 (Remote Player Avatars in ProvinceWorld):** Host và Client nhận diện avatar của nhau qua `y_entities` trong `province_world.tscn`. [PASS]
2. **P0-02 (Host-Authoritative Unique Chest Claim):** Cuộc đua tranh giành `bamboo_cavern_chest` được Host giải quyết dứt khoát. Đúng 1 client nhận thưởng (+50 LT, +1 Tẩy Tủy Đan), client còn lại bị từ chối. [PASS]
3. **P1-03 (Reconnect Identity with player_guid):** Client 1 ngắt kết nối và kết nối lại bảo tồn hoàn toàn ví và vật phẩm. [PASS]
4. **P0-03 & P2-01 (Clock & Pause Invariants):** Đồng hồ cố định 720s thực/ngày, `time_scale = 1.0`, menu không làm đứng scene tree. [PASS]

---

## 3. Nhật ký tiến trình trích xuất
### Host Log:
```text
 Inventory cho Peer 2078318684.
[HOST] Nhận diện Client 2: Peer ID 2078318684
[CoopWorldSync] Đăng ký mới Peer 2078318684 với GUID 'guid_han_lap_02' (Ví: 225 LT).
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 2078318684 tại (682.3235, 462.529)
[CoopWorldSync] Host xác nhận thu hoạch 'bamboo_cavern_chest' cho Peer 1648983953: +50 LT, +{ "item_tay_tuy_dan": 1 }, +50 XP
[HOST] Rương bamboo_cavern_chest đã được Host xác nhận thẩm quyền! Danh sách thu hoạch: ["bamboo_cavern_chest"]
[CoopWorldSync] Từ chối claim entity 'bamboo_cavern_chest' tại chunk (32, 30) từ Peer 2078318684 (Đã bị thu hoạch trước đó!)
[SessionAuthority] Peer ngắt kết nối: 1648983953
[ProvinceWorld] Đã gỡ bỏ Remote Avatar của Peer 1648983953
[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: 1648983953 (Giữ nguyên authoritative ledger)
[HOST] Peer 1648983953 ngắt kết nối (Bảo tồn GUID ledger)
[SessionAuthority] Peer kết nối: 873455321
[CoopWorldSync] Đã gửi Full World Snapshot & Authoritative Inventory cho Peer 873455321.
[CoopWorldSync] Peer 873455321 tái kết nối với GUID 'guid_tieu_viem_01'. Khôi phục ví: 275 LT, 2 vật phẩm.
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 873455321 tại (682.3235, 462.529)
[SessionAuthority] Peer ngắt kết nối: 2078318684
[ProvinceWorld] Đã gỡ bỏ Remote Avatar của Peer 2078318684
[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: 2078318684 (Giữ nguyên authoritative ledger)
[HOST] Peer 2078318684 ngắt kết nối (Bảo tồn GUID ledger)
[SessionAuthority] Peer ngắt kết nối: 873455321
[ProvinceWorld] Đã gỡ bỏ Remote Avatar của Peer 873455321
[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: 873455321 (Giữ nguyên authoritative ledger)
[HOST] Peer 873455321 ngắt kết nối (Bảo tồn GUID ledger)
[HOST] ★ TẤT CẢ TIÊU CHÍ GATE S0 TRÊN HOST ĐÃ ĐẠT!
[HOST] 1. Đồng bộ Client avatar trong ProvinceWorld: PASS
[HOST] 2. Host-authoritative Unique Chest Claim: PASS
[HOST] 3. Reconnect GUID ledger bảo tồn tài sản: PASS
[HOST] 4. Time scale 1.0 và 720s/ngày: PASS

```

### Client 1 Log:
```text
 cho Peer 1 tại (66560.0, 66660.0)
[SessionAuthority] Peer kết nối: 2078318684
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 2078318684 tại (640.0, 420.0)
[CLIENT1] Gửi yêu cầu claim rương bamboo_cavern_chest lên Host...
[ProvinceWorld] Đã đồng bộ trạng thái thực thể 'bamboo_cavern_chest' bị thu hoạch tại chunk (32, 30).
[CLIENT1] Kết quả claim: true (Msg: Thu hoạch thành công!)
[CLIENT1] Đã chụp screenshot thực tế: G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/audit/graphics_after/coop_province_world_client1.png
[CLIENT1] Thử nghiệm ngắt kết nối (Disconnect)...
[SessionAuthority] Đã ngắt kết nối session, trở về chế độ Standalone.
[CLIENT1] Tái kết nối (Reconnect) với cùng GUID 'guid_tieu_viem_01'...
[SessionAuthority] Đã ngắt kết nối session, trở về chế độ Standalone.
[SessionAuthority] Đang kết nối tới host 127.0.0.1:8990 (Cố định time_scale = 1.0)...
[SessionAuthority] Kết nối thành công tới Server!
[CoopWorldSync] Đã kết nối tới Server, gửi handshake danh tính GUID...
[SessionAuthority] Peer kết nối: 1
[SessionAuthority] Peer kết nối: 2078318684
[CoopWorldSync] Đã tiếp nhận và áp dụng Full World State (kèm NPCs & Revision) từ Host.
[SessionAuthority] Peer ngắt kết nối: 2078318684
[ProvinceWorld] Đã gỡ bỏ Remote Avatar của Peer 2078318684
[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: 2078318684 (Giữ nguyên authoritative ledger)
[CLIENT1] Tái kết nối thành công! Số dư Linh Thạch hiện tại: 275 LT
[CLIENT1] ★ CLIENT 1 HOÀN TẤT KIỂM THỬ CO-OP XUẤT SẮC!

```

### Client 2 Log:
```text
hority] Đang kết nối tới host 127.0.0.1:8990 (Cố định time_scale = 1.0)...
[CLIENT2] Đang kết nối tới 127.0.0.1:8990 với GUID guid_han_lap_02...
[SessionAuthority] Kết nối thành công tới Server!
[CoopWorldSync] Đã kết nối tới Server, gửi handshake danh tính GUID...
[SessionAuthority] Peer kết nối: 1
[CLIENT2] Kết nối thành công tới Host!
[SessionAuthority] Peer kết nối: 1648983953
[CoopWorldSync] Đã tiếp nhận và áp dụng Full World State (kèm NPCs & Revision) từ Host.
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 1 tại (66560.0, 66660.0)
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 1648983953 tại (916.3101, 717.6581)
[CoopEconomy] Bỏ qua phản hồi trùng lặp/cũ (Rev 1 <= Local 1). Không cấp item lặp!
[ProvinceWorld] Đã đồng bộ trạng thái thực thể 'bamboo_cavern_chest' bị thu hoạch tại chunk (32, 30).
[CLIENT2] Gửi yêu cầu tranh claim rương bamboo_cavern_chest...
[CLIENT2] Kết quả tranh claim: false (Msg: Thực thể này đã bị thu hoạch trước đó!)
[CLIENT2] Đã chụp screenshot thực tế: G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/audit/graphics_after/coop_province_world_client2.png
[SessionAuthority] Peer ngắt kết nối: 1648983953
[ProvinceWorld] Đã gỡ bỏ Remote Avatar của Peer 1648983953
[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: 1648983953 (Giữ nguyên authoritative ledger)
[SessionAuthority] Peer kết nối: 873455321
[ProvinceWorld] Đã spawn Remote Avatar cho Peer 873455321 tại (640.0, 420.0)
[CLIENT2] ★ CLIENT 2 HOÀN TẤT KIỂM THỬ TRANH MUA & THỜI GIAN!

```
