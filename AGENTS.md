# Workspace Rules — ĐẠO TÀN: VẠN KIẾP

Bạn là Lead Game Engineer + Gameplay Designer phát triển dự án Godot 4.7.x GDScript. Đọc `README_START_HERE.md` rồi `docs/02_GAME_VISION_GDD.md`, `docs/06_TECH_ARCHITECTURE.md` và `docs/07_ROADMAP_TESTS.md` trước khi viết code.

## Invariants
1. Offline single-player Windows-first. Godot 4.7.x stable. Không tạo phụ thuộc cloud, API key hay tài khoản.
2. Một project riêng, không xóa/sửa mã nguồn dự án khác. Có Git và commit theo milestone; không ghi đè save khi thiếu migration.
3. Không sao chép asset, giao diện, địa danh, nhân vật, lời thoại, cốt truyện của Tiên Nghịch hoặc Tale of Immortal. Tham khảo cơ chế phổ quát; tạo nội dung nguyên bản.
4. Logic thế giới, chiến đấu, RPG dùng lớp service / domain riêng và dữ liệu JSON/Resources; UI không chứa logic lõi.
5. RNG có seed duy nhất và deterministic cho world gen + lượt NPC; combat dùng RNG phù hợp nhưng lưu seed khi cần replay/debug.
6. Mọi entity có ID ổn định; tham chiếu bằng ID, không bằng tên hiển thị hoặc node path của scene.
7. Save JSON versioned (`schema_version`) ghi atomically (tmp + replace), tách save/meta, backup trước migration. Không lưu toàn bộ Node scene tree.
8. Tương tác và NPC simulation có event log; không sinh xung đột vô hạn, không xóa NPC của quest chính mà không có tuyến phục hồi.
9. Mỗi lần làm việc phải cập nhật `docs/IMPLEMENTATION_STATUS.md`, `docs/KNOWN_ISSUES.md`, `docs/CHANGELOG.md` nếu đã được tạo.
10. Nếu chưa có asset gốc: dùng **placeholder tự tạo** ghi rõ. Không download hình từ IP khác để nhét vào bản phát hành.
11. Không dùng code mẫu untested để đánh dấu `done`. Dùng headless Godot parse/run, kiểm thử thủ công gameplay, chụp minh chứng khi có thể.
12. Giao diện bằng tiếng Việt (UTF-8 Unicode); dùng font có bản quyền phù hợp và hỗ trợ dấu.
13. Dùng `docs/07_ROADMAP_TESTS.md` làm tiêu chí nghiệm thu; không vượt phase khi chưa hoàn thành phase hiện tại.
14. Sau mỗi phase, xuất: danh sách file chỉnh sửa, log kiểm thử, ảnh/video gameplay thực tế nếu có, blocker, và prompt giai đoạn kế tiếp.

## Scope guard
- Phase 0: project, input, state machine, seed map, UI skeleton, save/load, smoke tests.
- Phase 1: playable loop end-to-end; chỉ 1 vùng, 1 trấn, 1 tông, 6 NPC, 3 kỹ năng, 3 địch, 1 boss, 1 nhiệm vụ, 2 mốc cảnh giới.
- Không thêm multiplayer, 3D, voice AI runtime, backend, cloud save, Steam Workshop, mod downloader trước khi bản cốt lõi ổn định.
