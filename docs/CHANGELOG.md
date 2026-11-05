# CHANGELOG — ĐẠO TÀN: VẠN KIẾP

All notable changes to this project will be documented in this file.

## [0.1.0] - Phase 1 Vertical Slice - 2026-11-03
### Added
- **Vòng lặp hoàn chỉnh Vertical Slice:** Khởi tạo nhân vật -> Vào Thanh Trì Trấn -> Nhận nhiệm vụ từ NPC Mạc Tư Viễn -> Di chuyển ra Vân Lĩnh Rìa -> Tiến vào Bí Cảnh Đấu Trường -> Hạ 3 đợt yêu thú & Boss Xích Kiếm Ma Thứu -> Nhặt chiến lợi phẩm (Cổ Kiếm Tàn Phiến, Tụ Khí Đan, Linh Thạch) -> Bế quan đột phá Luyện Khí Tầng 1 -> Báo cáo hoàn thành nhiệm vụ -> Lưu/Tải ván chơi an toàn.
- **Tầng dữ liệu Data-Driven:** `items.json`, `skills.json`, `enemies.json`, `npcs.json`, `quests.json`, `factions.json`.
- **Giao diện Túi Trữ Vật (`scenes/ui/inventory_panel.tscn`):** Quản lý Linh Thạch, dược đan, phân loại màu theo phẩm chất, xem chi tiết và sử dụng đan dược trực tiếp.
- **Giao diện Hồ Sơ Tu Sĩ (`scenes/ui/character_panel.tscn`):** Cảnh giới, thanh tiến độ Tu Vi, tuổi thọ, thuộc tính cơ bản và cơ chế "Bế Quan Đột Phá" kiểm tra điều kiện nghiêm ngặt.
- **Cảnh Thị Trấn Thanh Trì (`scenes/towns/town_view.tscn`):** 5 địa danh (Quán Trọ, Dược Phẩm Các, Chợ Tán Tu, Thanh Vi Phân Điện, Cổng Rừng Trúc) với 6 NPC tương tác sống động.
- **Giao diện Hội Thoại NPC (`scenes/ui/dialogue_modal.tscn`):** Cấp bậc hảo cảm động, đàm đạo tin tức giang hồ, sạp buôn đan dược và dịch vụ cúng dường môn phái Thanh Vi Tông.
- **Đấu Trường Chiến Đấu Thời Gian Thực (`scenes/combat/combat_arena.tscn`):** Top-down 2D action, ngắm chuột, Trảm cơ bản [LMB], 3 Active Skills ([1/Q] Kiếm Khí, [2/E] Lôi Quang, [3/R] Mộc Trói), lướt né đòn i-frame [Space], cảnh báo Telegraph đỏ của Boss và bảng tổng kết chiến thắng rơi đồ.
- **Bộ Kiểm Thử Tự Động:** Mở rộng lên 35/35 Unit Tests (100% Pass) chạy headless hoàn hảo.
- **Bằng chứng thực tế:** 7 ảnh chụp màn hình 1080p kiểm thử GPU tại `docs/TEST_REPORTS/screenshots/`.

## [0.0.1] - Phase 0 Setup - 2026-11-03
### Added
- Khởi tạo môi trường phát triển Godot 4.7.2 stable (Windows PC).
- Thiết lập workspace tài liệu, kiến trúc kỹ thuật data-driven và các quy tắc kiểm thử.
- Cấu hình dự án `project.godot` với hệ thống phím điều khiển, màn hình 1920x1080 baseline.
- Dịch vụ nền tảng: `EventBus`, `GameClock`, `RNGService`, `ContentRegistry`, `SaveService`, `GameSession`.
- Giao diện: Bootstrap, Main Menu, New Game Modal, Settings Modal, In-game HUD, Pause Menu.
- Bản đồ thế giới cơ bản (World Map) sinh theo seed cố định với CharacterBody2D điều khiển mượt mà.
- Bộ kiểm thử tự động headless: test save/load roundtrip, test clock tick, test seed deterministic.
