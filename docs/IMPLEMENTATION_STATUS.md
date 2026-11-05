# IMPLEMENTATION STATUS — ĐẠO TÀN: VẠN KIẾP

**Phiên bản hiện tại:** 0.1.0 (Phase 1 Vertical Slice)  
**Cập nhật lần cuối:** 03/11/2026  
**Trạng thái kiểm thử:** Phase 1 ĐẠT 100% (35/35 Unit Tests PASS + 7 Screenshots)

---

## Bảng theo dõi tiến độ theo Phase

| Module / Tính năng | Phạm vi Phase | Trạng thái | Bằng chứng kiểm thử / Ghi chú |
| :--- | :---: | :---: | :--- |
| **Môi trường Godot 4.7.2** | Phase 0 | **DONE** | Godot 4.7.2 stable official cài tại `tools/godot/` & test headless pass |
| **Workspace & Tài liệu nền** | Phase 0 | **DONE** | Đầy đủ IMPLEMENTATION_PLAN, STATUS, ISSUES, CHANGELOG, .gitignore |
| **Project Configuration** | Phase 0 | **DONE** | `project.godot` cấu hình 1920x1080 canvas_items, input map WASD/Arrows |
| **Autoload Services** | Phase 0 | **DONE** | EventBus, GameClock, RNGService, SaveService, ContentRegistry, GameSession |
| **Save/Load System** | Phase 0 | **DONE** | Atomic save, schema_version 1, meta & backup file, schema validator |
| **Main Menu & Settings** | Phase 0 | **DONE** | New Game (Seed/Name), Continue (Meta info), Settings, Quit |
| **World Map & Movement** | Phase 0 | **DONE** | Grid map theo seed, Player CharacterBody2D 8 hướng, Camera2D, HUD |
| **In-game Pause Menu** | Phase 0 | **DONE** | Resume, Save Game (Slot 1), Settings, Back to Menu |
| **Giao diện Túi Trữ Vật (Inventory)** | Phase 1 | **DONE** | `InventoryPanel` lưới 2 cột, quản lý Linh Thạch, Tụ Khí Đan, Hồi Xuân Đan, Linh Thảo |
| **Hồ Sơ Nhân Vật & Đột Phá** | Phase 1 | **DONE** | `CharacterPanel` hiển thị Tu Vi 100/100, điều kiện Tụ Khí Đan, Bế Quan lên Luyện Khí Tầng 1 |
| **Thị Trấn Thanh Trì (Town View)** | Phase 1 | **DONE** | `TownView` với 5 công trình, tương tác 6 NPC, phím tắt ra bản đồ |
| **Hội Thoại & Hảo Cảm NPC (6 NPC)** | Phase 1 | **DONE** | `DialogueModal` tương tác Mạc Tư Viễn, Thư Nguyệt, Kỷ Hoàn, Đoàn Vĩnh, Lâm Du, Bạch San |
| **Nhiệm Vụ Chính Tuyến (`q_first_spirit_vein`)** | Phase 1 | **DONE** | Luồng 5 bước: Nhận quest -> Đi Vân Lĩnh -> Đấu boss -> Đột phá -> Trả thưởng |
| **Dịch Vụ Tông Môn (Thanh Vi Tông)** | Phase 1 | **DONE** | Cúng dường 50 Linh Thạch tăng hảo cảm +15, thỉnh giáo tâm pháp |
| **Đấu Trường Chiến Đấu (Combat Arena)** | Phase 1 | **DONE** | `CombatArena` 2D top-down, WASD, aim chuột, Trảm cơ bản, 3 Active Skills, Lướt né i-frame |
| **Yêu Thú & Boss Xích Kiếm Ma Thứu** | Phase 1 | **DONE** | 3 Waves, Boss 450 HP có Telegraph đỏ hình tròn (Kiếm Vũ) & tia thẳng (Lôi Điệp) |
| **Phần Thưởng Rơi & Thu Thập Chiến Lợi** | Phase 1 | **DONE** | Bảng chiến thắng phát thưởng Cổ Kiếm Tàn Phiến, 2x Tụ Khí Đan, 60 Linh Thạch, +50 Tu Vi |
| **Unit Test Suite** | Phase 0 & 1 | **DONE** | **35/35 tests passed 100%** trên Godot Headless Engine |
| **NPC Monthly Simulation** | Phase 2 | **SCOPE GUARD** | Chờ nghiệm thu Phase 1 trước khi triển khai |
| **Sect Wars & Dynamic Economy** | Phase 3 | **SCOPE GUARD** | Chưa triển khai |
