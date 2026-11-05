# UI, art direction và âm thanh

## 1. Art direction
- Bản đồ 2D hand-painted / ink-wash xianxia, núi xanh xám, đám mây, ruộng, trấn, suối, cổ thành; không bắt chước exact visual của Tale of Immortal.
- Palette: trầm #101B21, ngọc #739C8A, giấy #E4DAC3, vàng cổ #C7A666, đỏ nghiệp #8A4249, xanh lôi #77B5D9.
- Tone game: tịch mịch, sinh tồn, có vẻ đẹp thiên nhiên; không phải MMORPG ánh sáng neon dày.
- Asset thật phải có nguồn quyền sử dụng; khi chưa có dùng placeholder do dự án tự tạo.

## 2. UX 6 màn hình chính
1. **Menu**: logo, silhouette núi, nút Start/Continue/Settings/Exit.
2. **World**: 70% bản đồ, mini-map/phong cảnh trên phải, panel quest có thể thu gọn, tài nguyên+thời gian ở thanh góc, bộ thông báo sự kiện cuối tháng.
3. **Combat**: 75–80% diện tích arena; thanh HP/MP/kiếp ngắn, 5 nút skill/cooldown lớn, boss HP+telegraph rõ, không quá rối.
4. **Cultivation**: giao diện vòng linh mạch, stage progression, vật liệu cần, chance & penalty mô tả dễ hiểu; xác nhận trước khi tiêu tài nguyên.
5. **NPC/social**: chân dung, cảnh giới, quan hệ, 3 hành động thông dụng và log âm-thù.
6. **Sect**: cống hiến, kho, bảng nhiệm vụ, chức vụ, tông môn địch và tài nguyên; ẩn chức năng quản lý tông trước late-phase.

## 3. Typography
- Font gợi ý: Noto Serif hỗ trợ tiếng Việt cho tiêu đề, Noto Sans cho UI, phải xác nhận giấy phép trước khi đóng gói. Tránh font không có dấu, text shader làm rỗng glyph.
- UI có scale 100/125/150%, keyboard focus và Tooltip cho thuật ngữ Hán Việt.

## 4. Sound design
- Nhạc nền original hoặc có giấy phép: đàn tranh/tiêu, gió, nước, trầm, bộ gõ ít; khu vực chiến đấu đánh nhịp mạnh nhưng vừa.
- Sound cues: bước chân, kiếm khí, lôi pháp, hồi chiêu, vật phẩm, đột phá, báo hiệu boss; slider Master/Music/SFX/Ambience.
- Không dùng OST của các game/phim tham chiếu trong build phân phối.

## 5. Asset checklist theo mức ưu tiên
- P0: player placeholder 4 hướng, 3 quái, 1 boss, tilemap 1 trấn + rừng, cursor/target, button panel, font Việt.
- P1: sprite player 4 hướng/đòn đánh, quái loại 1–3, skill slash/lightning/roots, 5 portrait NPC, 30 props, town/background.
- P2: biomes khác, portrait 50 NPC, 15 VFX, bộ dungeon, tông phái, animation boss.
- UI icons thiết kế riêng với consistency, không lấy thẳng icon game gốc.
