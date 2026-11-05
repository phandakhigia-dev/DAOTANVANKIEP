# DANH SÁCH TẬP TIN THAY ĐỔI (FILES CHANGED)
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Tài liệu:** `audit/FILES_CHANGED.md`  
**Ngày cập nhật:** 04/11/2026  
**Trạng thái kiểm thử:** 161/161 PASS (100%) across 22 test suites trên Godot v4.7.2 Headless.

---

### Bảng Tổng Hợp Thay Đổi Mã Nguồn

| Tập tin | Dòng sửa đổi | Mục đích / Tính năng nâng cấp |
|---|---|---|
| `scripts/domain/shop_service.gd` | Lines 69–165, 296–320 | **P0-03 (Fix)**: Thẩm tra chặn `count <= 0`, chặn ID rỗng, chặn `buyer_wallet < 0`; thêm hàm `player_buy_from_stall` có rollback hai chiều an toàn; khử số âm khi `from_dict`. |
| `scripts/core/game_session.gd` | Lines 33, 137, 631, 679, 736 | **P0-04 & P1-02 (Fix)**: Khai báo `town_position`; thêm `town_position` và `ShopService.to_dict()` vào `export_save_dict()`; khôi phục `town_position` và `ShopService.from_dict()` trong `import_save_dict()`; reset biến trong `start_new_game()`. |
| `scripts/persistence/save_service.gd` | Lines 7, 21–25, 140–180 | **P1-01 (Fix)**: Thống nhất `CURRENT_SCHEMA_VERSION = 2`; thêm cơ chế tự động khôi phục dữ liệu từ `.bak.json` khi file chính bị thiếu hoặc lỗi; thẩm định schema an toàn. |
| `wuxia/demo/capture_demo.tscn` | Line 10 | **P1-04 (Fix)**: Sửa đường dẫn tham chiếu gãy từ `res://demo/...` thành `res://wuxia/demo/...`. |
| `wuxia/demo/capture_demo.gd` | Line 18 | **P1-04 (Fix)**: Sửa đường dẫn nạp texture từ `res://demo/wuxia_sheet.png` thành `res://wuxia/demo/wuxia_sheet.png`. |
| `scripts/network/clock_replication.gd` | Lines 61–77 | **P0-01 (Security)**: Khóa cứng `time_scale = 1.0` trong phòng Co-op, từ chối lệnh tua nhanh x20 từ mọi peer để bảo vệ quy tắc bất biến 1 ngày game = 720 giây thực. |
| `scripts/domain/monthly_simulation_service.gd` | Lines 33–35 | **P0-01 (Authority)**: Bổ sung guard `SessionAuthority.is_server_authoritative()` — chỉ Server/Host mới thực thi mô phỏng hàng tháng, triệt tiêu nguy cơ desync giữa Client và Server. |
| `scenes/world/hud.gd` | Lines 90–105 | **P0-01 (QoL)**: Phím X hiển thị cảnh báo không thể thay đổi tốc độ thời gian khi đang trong phòng Co-op nhiều người. |
| `scenes/towns/town_map_real.gd` | Lines 71–85, 230–245 | **P1-02 & Visual/Audio**: Khôi phục tọa độ `town_position` người chơi an toàn; thêm hạt lá trúc bay `VFXBambooLeavesScene`; phát BGM `bgm_peaceful_town`; ghế uống trà phục hồi 20 HP không tua thời gian trong Co-op. |
| `scenes/combat/combat_arena.gd` | Lines 38, 91–98, 105–110, 370–415, 821, 966–978 | **Visual & Audio Upgrade**: Tích hợp nhân vật hoạt ảnh `SwordsmanScene` (8 hướng, khinh công, chém kiếm); Screen shake khi va chạm / diệt boss; Sát thương bay `Floating Combat Text` (vàng cho bạo kích, trắng cho đánh thường, đỏ khi bị đánh); Vành nổ diệt địch; Tự động phát `bgm_tribulation` và hoàn trả BGM thế giới khi rời sàn đấu. |
| `scenes/world/player.gd` | Lines 12, 76–100 | **Gameplay/Visual Upgrade**: Kích hoạt Khinh Công (Qinggong Dash) bằng phím Space: tăng tốc độ di chuyển 1.5x trong 0.22s, thời gian hồi chiêu 0.9s, âm thanh xé gió `sfx_sword_slash`, hoạt ảnh `qinggong`. |
| `scenes/world/world_map.gd` | Lines 16, 21–25, 64–82 | **Visual/Audio Upgrade**: Tích hợp ánh sáng ngày đêm thích ứng `WorldDayNightModulate` (CanvasModulate) chuyển sắc thái mượt mà theo 720s game clock (bình minh hồng kim, ban ngày trong trẻo, hoàng hôn hổ phách, ban đêm xanh huyền ảo); phát BGM `bgm_bamboo_forest`. |
| `scenes/ui/inventory_panel.gd` | Lines 121–125 | **Audio Upgrade**: Gọi `AudioService.play_sfx("sfx_pill_swallow")` khi người chơi nuốt đan dược / linh quả. |
| `scenes/ui/character_panel.gd` | Lines 25, 115–125 | **Visual/Audio Upgrade**: Sinh hiệu ứng linh khí đan điền `VFXCultivationAura` (Hoàng Kim Đột Phá) và phát chuông đốn ngộ `sfx_breakthrough_gong` khi đột phá cảnh giới thành công. |
| `tests/unit/test_s0_stability_regression.gd` | Lines 1–266 | **Automated Tests**: 14 ca kiểm thử hồi quy bao quát toàn diện P0-01, P0-03, P0-04, P1-01, P1-02, P1-04, Khinh công, Floating damage numbers, và Day/Night tinting. |
| `tests/test_runner.gd` | Lines 41, 65 | **Test Infrastructure**: Đăng ký `test_s0_stability_regression.gd` vào danh sách runner chính thức. |
| `tools/run_tests_capture_raw.py` | Toàn bộ script | **Testing Tool**: Công cụ Python tự động thực thi Godot Headless, trích xuất log thô UTF-8 vào `audit/REGRESSION_LOG_RAW.txt` và tổng hợp kết quả JSON `audit/TEST_RESULTS.json`. |
