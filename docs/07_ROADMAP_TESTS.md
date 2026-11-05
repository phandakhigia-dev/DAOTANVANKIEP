# Roadmap phát triển theo phase + tiêu chí nghiệm thu (Definition of Done)

> Đây là các milestone kỹ thuật, **không phải cam kết ngày/giờ hoàn thành**. Thứ tự ưu tiên giúp tránh dự án phình to.

## PHASE 0 — Technical foundation
**Build:** Godot khởi động -> main menu -> new game -> map placeholder -> di chuyển nhân vật -> menu setting -> save/load -> quit.
- Workspace rules, Git, docs status, các scene và service nền, data validator, file save có schema version.
- Một world seed cố định render cùng vị trí POI mỗi lần load.
- Phím không kẹt khi pause, đổi menu không duplicate Player.
- **DoD:** headless import/parse pass; GUI chạy được; save rồi load khớp seed, vị trí, ngày, HP; log không lỗi nghiêm trọng; QA report.

## PHASE 1 — First playable vertical slice
**Build:** một trấn, một vùng ngoài trấn, 6 NPC, 1 tông, 1 nhiệm vụ nhiều bước, 1 dungeon, 3 enemy types, 1 boss, 3 active skills, 2 thành tựu cảnh giới, looting, tu luyện, breakthrough, lưu/tải.
- Scene combat top-down riêng có cooldown và telegraph boss.
- Quay lại world map sau battle với inventory và đồng hồ đúng.
- Quest sau kill nhận thưởng, đủ material để đột phá; có fail state và replay route.
- **DoD:** người kiểm thử làm trọn vòng lặp không dùng console; boss kill xong có thưởng; save/load đủ state; không có nút giả.

## PHASE 2 — Living-world systems
**Build:** NPC tháng, quan hệ/ân oán, 30–50 NPC, 3 tông (1 fully interactive), random rumors, reputation, market supply.
- Monthly simulation deterministic khi cùng seed.
- NPC có phản ứng với cứu/giết/trộm với witness/rumor.
- **DoD:** seed + chuỗi hành động như nhau cho monthly log như nhau qua 12 tháng; 1000 NPC headless stress thử; không vượt mục tiêu pause time thiết lập trong profile.

## PHASE 3 — Game depth
**Build:** 3–4 biome, 8–12 skills, 5 boss, crafting pill/artifact cơ bản, world events, branch quests, mô tả lore phong phú.
- Tăng độ phong phú build; 2 kiểu tiến progression khác ngoài farm boss.
- **DoD:** 3 loại build thắng được boss đầu theo chiến thuật riêng; không softlock 2 đường nhiệm vụ chính; đo time-to-progression.

## PHASE 4 — UX, visuals, stability
- Handpainted original art pass, VFX, shader mist, âm thanh, 60FPS optimization, font Việt, remap, tutorial, accessibility.
- Save migrations, config, support multiple slots, QA full run, bug bash.
- **DoD:** có bản build nội bộ Windows `.exe` được test trên máy khác; không thiếu resource; 60 FPS target khi đo trên cấu hình test ghi rõ.

## PHASE 5 — Alpha content expansion (chỉ nếu Phase 4 ổn)
- Thành lập tông, chiến tranh toàn vùng, cao cảnh giới, hệ thống Đạo, truyền thừa, world layer thứ 2, side endings.
- Không cam kết đầy đủ quy mô Tale of Immortal; kiểm soát phạm vi theo playtest.

## Các kiểm thử bắt buộc mọi phase
1. `Godot import/parse` không lỗi.
2. New Game / Save / Load / Quit / Resume.
3. UI trong 1280x720 và 1920x1080 không tràn, không text clipping.
4. Chạy thực tế với keyboard + mouse (headless là chưa đủ).
5. Không reference null khi scene transition; battle reward atomic.
6. NPC relationship, world seed và inventory không bị reset khi qua vùng.
7. Thử load save phiên bản trước sau mỗi lần thay đổi schema.
8. Tài nguyên/cửa hàng không có exploit giao dịch mua-bán lặp vô hạn.
9. Nội dung chưa có phải bị ẩn/đánh dấu đang phát triển, không lừa người chơi bằng nút có UI mà không có logic.
10. Cập nhật Changelog + Known Issues + Test Report trước khi báo xong.

## Báo cáo sau mỗi milestone
```
PHASE:
IMPLEMENTED: (file paths + mô tả chức năng)
NOT_IMPLEMENTED:
TEST COMMANDS + RESULT:
PLAYTEST SCENARIOS + OBSERVED RESULT:
KNOWN BUGS + severity:
SCREENSHOT / VIDEO proof paths:
NEXT PHASE RECOMMENDATION:
```
