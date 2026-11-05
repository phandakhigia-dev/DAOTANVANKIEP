# DANH MỤC VẤN ĐỀ VÀ TIẾN ĐỘ KHẮC PHỤC (REMAINING ISSUES TRACKER)
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Tài liệu:** `audit/REMAINING_ISSUES.md`  
**Ngày cập nhật:** 04/11/2026 (Sau khi hoàn tất Sửa lỗi S0 và Nâng cấp Đồ họa / Âm thanh)  
**Trạng thái kiểm thử:** 161/161 PASS (100% ĐẠT across 22 test suites)  

---

## 1. CÁC VẤN ĐỀ ĐÃ KHẮC PHỤC TRIỆT ĐỂ (RESOLVED)

| Mã vấn đề | Phân loại | Tình trạng | Bằng chứng kiểm thử & Mã nguồn |
|---|---|---|---|
| **P0-01** | Lỗ hổng Client tự ý tua nhanh thời gian Co-op & Desync hàng tháng | **RESOLVED** | Test T-09, T-10 trong `test_s0_stability_regression.gd`. Khóa cứng `time_scale = 1.0` trong Co-op tại `clock_replication.gd`; chỉ Server/Host mới có quyền chạy `monthly_simulation_service.gd`. |
| **P0-03** | Lỗ hổng số lượng âm & nhân bản tài sản trong sạp hàng (`ShopService`) | **RESOLVED** | Test T-01, T-02, T-03. Chặn tuyệt đối `count <= 0`, chặn ID rỗng, chặn ví âm, giao dịch hai chiều nguyên tử `player_buy_from_stall` có cơ chế rollback. |
| **P0-04** | Dữ liệu sạp hàng, kho Escrow và doanh thu không lưu vào save | **RESOLVED** | Test T-05. Tích hợp `ShopService.to_dict()` & `from_dict()` vào `GameSession` save/load roundtrip nguyên vẹn. |
| **P1-01** | Bất nhất `schema_version` (1 vs 2) và nguy cơ mất save do không có dự phòng | **RESOLVED** | Test T-06, T-07. Thống nhất `CURRENT_SCHEMA_VERSION = 2`, cơ chế phục hồi tự động từ `.bak.json` khi file chính mất hoặc hỏng. |
| **P1-02** | Thiếu biến `town_position` gây lỗi chuyển cảnh giữa WorldMap và Town | **RESOLVED** | Test T-04. Khai báo `town_position` trên `GameSession`, serialize vào save và khôi phục an toàn trong `town_map_real.gd`. |
| **P1-04** | Tham chiếu scene gãy `res://demo/...` trong demo Wuxia | **RESOLVED** | Test T-08. Hiệu chỉnh toàn bộ đường dẫn thành `res://wuxia/demo/...`, nạp scene sạch lỗi 100%. |

---

## 2. CÁC NÂNG CẤP ĐỒ HỌA & TRẢI NGHIỆM ĐÃ TRIỂN KHAI THÀNH CÔNG

1. **Nhân vật chiến đấu hoạt ảnh 8 hướng (`SwordsmanScene`):** Thay thế hình tròn placeholder bằng kiếm tu võ hiệp có đầy đủ chuyển động đi lại, đứng thở, chém kiếm và lướt gió.
2. **Sát thương trôi nổi (Floating Combat Text):** Hiển thị số sát thương bay lên trên đầu mục tiêu, có phân màu bạo kích vàng, sát thương thường trắng và sát thương nhận vào màu đỏ.
3. **Ánh sáng ngày đêm thích ứng trên World Map:** Tích hợp `CanvasModulate` chuyển sắc thái mượt mà theo 720 giây thực tế (bình minh hồng kim, ban ngày trong trẻo, hoàng hôn hổ phách, ban đêm xanh huyền ảo).
4. **Khinh Công (Qinggong Dash):** Phím `Space` lướt gió tốc độ cao x1.5 (520 px/s) có thời gian hồi chiêu và hiệu ứng âm thanh xé gió.
5. **Âm thanh võ hiệp sống động:** Phát BGM `bgm_tribulation` khi chiến đấu, `bgm_bamboo_forest` khi phiêu lưu thế giới mở, `bgm_peaceful_town` trong thị trấn; phát âm thanh nuốt đan `sfx_pill_swallow` và tiếng chuông đốn ngộ `sfx_breakthrough_gong`.
6. **Thị trấn sống động (Living Town):** Hạt lá trúc rơi và phấn hoa linh khí bồng bềnh phủ bóng lên các ngõ phố Thanh Trì Trấn.

---

## 3. LỘ TRÌNH NÂNG CẤP TIẾP THEO (FUTURE SPRINTS)

Theo lộ trình thiết kế trong blueprint, các tính năng tiếp theo có thể triển khai ở các Sprint kế tiếp:
- **Sprint S2 (Biomes & Dungeons Advanced):** Thêm cơ chế giải đố cơ quan trong Cổ Kiếm Trũng và Đầm Lầy Hắc Xà.
- **Sprint S3 (Sects & Higher Tribulation):** Mở rộng hệ thống lôi kiếp cho Kim Đan và Nguyên Anh, gia nhập các phân đà bí truyền.
- **Sprint S4 (Living Jianghu Simulation):** Mở rộng mạng lưới quan hệ gia tộc, truyền thừa huyết mạch và kết hôn đạo lữ sâu rộng hơn.
- **Sprint S5 (Full Co-op Multi-peer Optimization):** Kiểm thử môi trường mạng thực tế 4 người chơi cùng máy chủ chuyên dụng (Dedicated Server headless).
