# BÁO CÁO NGHIỆM THU PHASE 3 & CO-OP TOWN LIFE (SPRINT S2/S3)
**Dự án:** ĐẠO TÀN: VẠN KIẾP (Xianxia Sandbox RPG • Windows PC Native • Godot 4.7.2)  
**Tùy chọn:** Option C — Chiều sâu nội dung Thế giới (Phase 3) & Đời sống Thị trấn / Sạp hàng ký gửi & Luyện đan (Sprint S2/S3)  
**Ngày nghiệm thu:** 04/11/2026  
**Trạng thái kiểm thử:** **79/79 PASS (100%)** — Không có lỗi hồi quy (Zero Regressions).

---

## 1. TỔNG QUAN TÍNH NĂNG HOÀN THIỆN TRONG OPTION C

### A. Hệ Thống Luyện Đan Dược (Alchemy Domain & UI)
- **Data-driven recipes:** Định nghĩa 5 đan phương hoàn chỉnh trong `data/recipes/recipes.json`:
  1. *Tụ Khí Đan:* Hỗ trợ đột phá Luyện Khí.
  2. *Hồi Xuân Đan:* Trị thương thông dụng (+50 HP).
  3. *Kim Sàng Dược:* Thần dược cầm máu thượng hạng (+120 HP).
  4. *Thanh Tâm Đan:* Trừ tà độc, phục hồi Linh Lực (+45 MP).
  5. *Tẩy Tủy Đan:* Đan dược cực phẩm tẩy rửa kinh mạch, trợ lực Trúc Cơ.
- **AlchemyService (`scripts/domain/alchemy_service.gd`):**
  - Giao dịch nguyên tử: Khấu trừ đồng bộ linh thạch và dược thảo.
  - Thẩm định cảnh giới tối thiểu (phàm nhân không được luyện đan Luyện Khí).
  - Tỉ lệ thành đan (Roll success rate với phế đan fallback).
- **AlchemyModal (`scenes/ui/alchemy_modal.tscn` & `.gd`):**
  - Tích hợp tại Dược Phẩm Các với phím tắt `[K]`.
  - Danh mục đan phương trực quan, checklist nguyên liệu (xanh lá/đỏ), nút Khai Lò Luyện Đan.

### B. Hệ Thống Sạp Hàng Tu Sĩ Ký Gửi (Player Stall & Town Economy - Sprint S2/S3)
- **ShopService (`scripts/domain/shop_service.gd`):**
  - Hợp đồng thuê sạp chu kỳ 3 ngày (50 Linh Thạch).
  - Kho ký gửi sạp hàng vật lý (Physical Stock Escrow): Người chơi chuyển vật phẩm từ túi vào kho sạp, đặt đơn giá (LT/món).
  - Giao dịch nguyên tử: Khách mua (NPC vãng lai hoặc người chơi co-op) khấu trừ tiền, giảm tồn kho sạp, cộng dồn doanh thu sạp.
  - Quyết toán doanh thu (`withdraw_revenue()`): Chuyển tiền tích lũy về túi đồ bất cứ lúc nào.
  - Serialization: Hỗ trợ `to_dict()` và `from_dict()` lưu trữ nguyên vẹn theo save game.
- **PlayerShopModal (`scenes/ui/player_shop_modal.tscn` & `.gd`):**
  - Tích hợp tại Chợ Tán Tu Thanh Trì với phím tắt `[M]`.
  - Quản lý hạn thuê, ký gửi số lượng/đơn giá, rút hàng về túi, rút doanh thu.

### C. Mở Rộng Hệ Thống Boss & Đa Dạng Hình Học Telegraph
- **Mở rộng 5 Boss Đạo Tàn trong `data/enemies/enemies.json`:**
  1. *Xích Kiếm Ma Thứu* (Rừng Trúc Vân Lĩnh) — HP: 450, Vòng xoáy Kiếm Vũ & Lướt chém.
  2. *Hắc Linh Xà Vương* (Đầm Lầy Hắc Linh) — HP: 650, Phun Quạt Độc hình nón (Cone Telegraph).
  3. *Huyết Ma Khôi Lỗi* (U Minh Cổ Mộ) — HP: 900, Vệt Huyết Sát xung phong (Line Dash Telegraph).
  4. *Bách Độc Chu Hoàng* (Bách Độc Động) — HP: 750, Mạng nhện bát phương bộc phát (Radial Web Circle Telegraph).
  5. *Cổ Kiếm Linh* (Kiếm Chủng Thần Bí) — HP: 1100, Thập Tự Kiếm Trận (Cross Sword Formation Telegraph).
- **CombatArena (`scenes/combat/combat_arena.gd`):**
  - Tích hợp thuật toán hình học va chạm:
    - *Cone (Quạt Độc):* Khoảng cách và góc vector `dir.dot(dir_to_player) >= cos(angle / 2)`.
    - *Cross (Thập Tự):* Va chạm dọc theo 2 chùm tia vuông góc tâm tại điểm mục tiêu.
    - *Line (Vệt Kiếm/Lướt):* Chiếu điểm lên đoạn thẳng `_dist_to_segment(p, a, b) <= width`.
    - *Circle (Bộc Phá):* Bán kính nổ tròn truyền thống.
  - Bảng phần thưởng rơi động theo loot table của từng Boss.

### D. Lịch Trình Sinh Hoạt 12 Canh Giờ Của Thị Trấn (Town Life Routine)
- **TownView (`scenes/towns/town_view.gd` & `.tscn`):**
  - Thanh hiển thị Canh Giờ trung tâm kèm số lượng tu sĩ vãng lai theo thời khắc (ví dụ: Giờ Thìn 07:00 • 18 Tu Sĩ Vãng Lai).
  - Thuật toán phân bổ vị trí sinh hoạt của 36 NPC:
    - *05:00 - 09:00 (Mão - Thìn):* Buôn bán, thu mua tại Chợ & Dược Phẩm Các.
    - *09:00 - 15:00 (Tỵ - Mùi):* Giờ cao điểm, bái tông môn Thanh Vi & săn thú rừng trúc.
    - *15:00 - 19:00 (Thân - Dậu):* Chiều tà, tụ hội đàm đạo tại Quán Trọ.
    - *19:00 - 05:00 (Tuất - Dần):* Đêm thanh tịnh, bế quan tĩnh tọa và giao dịch ngầm.
  - Khách vãng lai định kỳ mua sắm tại sạp hàng của người chơi theo chu kỳ canh giờ!

---

## 2. KẾT QUẢ KIỂM THỬ TỰ ĐỘNG (16 BỘ TEST SUITES)

```
=======================================================
  ĐẠO TÀN: VẠN KIẾP — BỘ KIỂM THỬ TỰ ĐỘNG (PHASE 0, 1, 2, 3 & S1-S3)
  Môi trường: Godot 4.7.2 Headless Engine (Full Autoloads)
=======================================================

--- Bộ test: GameClock --- (5/5 PASS)
--- Bộ test: GameClock Realtime Co-op --- (6/6 PASS)
--- Bộ test: DeterministicSeed --- (3/3 PASS)
--- Bộ test: SaveRoundtrip --- (5/5 PASS)
--- Bộ test: Phase 1 - InventorySystem --- (6/6 PASS)
--- Bộ test: Phase 1 - BreakthroughEngine --- (6/6 PASS)
--- Bộ test: Phase 1 - QuestFlow --- (5/5 PASS)
--- Bộ test: Phase 1 - NPCAffinity & Sect --- (5/5 PASS)
--- Bộ test: Phase 2 - DeterministicSimulation --- (3/3 PASS)
--- Bộ test: Phase 2 - NPCSocialGraph --- (5/5 PASS)
--- Bộ test: Phase 2 - NPCLifecycle --- (4/4 PASS)
--- Bộ test: Phase 2 - HeadlessStressTest --- (3/3 PASS)
--- Bộ test: Co-op Authoritative Clock Sync (S1) --- (6/6 PASS)
--- Bộ test: Phase 3 - AlchemySystem --- (5/5 PASS)
--- Bộ test: Phase 3 - Bosses & Telegraphs --- (5/5 PASS)
--- Bộ test: Phase 3 & S2/S3 - PlayerStallSystem --- (7/7 PASS)
-------------------------------------------------------
TỔNG KẾT: 79 ĐẠT (PASS) | 0 THẤT BẠI (FAIL)
=======================================================
[SUCCESS] Tất cả các tiêu chí nghiệm thu vượt qua 100%!
```

---

## 3. DANH SÁCH ẢNH CHỤP KIỂM THỬ THỰC TẾ (SCREENSHOTS 19 - 23)

1. `19_town_view_dynamic_routine.png`: Cảnh Thị Trấn Thanh Trì với thanh 12 Canh Giờ, số lượng tu sĩ vãng lai hoạt động và phím tắt `[K]` Luyện Đan, `[M]` Sạp Hàng.
2. `20_alchemy_modal_crafting.png`: Giao diện Luyện Đan Các với danh mục 5 đan phương, checklist tiêu hao dược liệu/linh thạch và nút Khai Lò.
3. `21_player_stall_escrow.png`: Giao diện Sạp Hàng Tu Sĩ ký gửi tại Chợ Tán Tu, chu kỳ thuê 3 ngày, kho ký gửi và doanh thu bán đan dược.
4. `22_combat_boss_hac_linh_xa_vuong.png`: Đấu trường chiến đấu với Boss Hắc Linh Xà Vương đang thi triển Telegraph Quạt Độc (Cone Poison Spit).
5. `23_combat_boss_co_kiem_linh.png`: Đấu trường chiến đấu với Boss Cổ Kiếm Linh đang bao vây người chơi bằng Thập Tự Kiếm Trận (Cross Sword Formation).
