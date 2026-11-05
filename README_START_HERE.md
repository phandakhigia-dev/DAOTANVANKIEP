# ĐẠO TÀN: VẠN KIẾP — Bộ blueprint phát triển game

**Trạng thái:** Game Design / Pre-production v0.1 | **Ngày nghiên cứu:** 03/11/2026 | **Ngôn ngữ:** tiếng Việt | **Tên game:** tên tạm, có thể đổi.

## Tóm tắt
- Game **2D top-down, single-player, offline trên Windows**, kết hợp bản đồ sandbox, chiến đấu real-time trong đấu trường và mô phỏng xã hội tu chân theo tháng.
- Cảm hứng cảm xúc: Tiên Nghịch — sự khắc nghiệt, thế giới mở rộng từng lớp, ngộ đạo, nhân quả và cái giá của trường sinh.
- Cảm hứng lối chơi: Tale of Immortal — khám phá bản đồ, đột phá cảnh giới, công pháp, tông môn, NPC, lựa chọn và sự kiện.
- **Không** tái sử dụng tên riêng, cốt truyện, bản đồ, diện mạo nhân vật, nhạc, hình ảnh, UI hay tài sản bản quyền của hai IP trên. Toàn bộ lore, artwork và nhiệm vụ là nguyên bản.

## Sử dụng với Antigravity
1. Tạo **thư mục dự án MỚI** `dao-tan-van-kiep/` (tránh ghi đè các project khác).
2. Chép toàn bộ nội dung gói này vào thư mục đó (gồm `AGENTS.md`, `docs/`, `prompts/`, `data_examples/`).
3. Cài **Godot 4.7.x stable** (ưu tiên 4.7.2 stable tại ngày nghiên cứu) và xác nhận lệnh `godot --version` hoặc chỉ rõ đường dẫn thực thi.
4. Trong Antigravity mở workspace thư mục này. Dán nội dung `prompts/00_MASTER_PROMPT.md` vào Agent.
5. Chỉ phê duyệt **PHASE 0**, yêu cầu xuất log kiểm thử, cấu trúc file và video/ảnh chụp gameplay thực tế. Sau khi đạt DoD mới chuyển `PHASE 1`.
6. Không yêu cầu Agent tạo full game trong một lệnh. Mỗi phase có hạng mục hoàn thành và yêu cầu kiểm thử riêng.

## Cấu trúc tài liệu
- `AGENTS.md`: luật nền được Antigravity đọc trong workspace (theo tài liệu Rules chính thức).
- `docs/01_RESEARCH.md`: nghiên cứu, nguồn và giới hạn xác minh.
- `docs/02_GAME_VISION_GDD.md`: Game Design Document tổng thể.
- `docs/03_WORLD_LORE.md`: vũ trụ, vùng đất, phe phái, tông môn, cốt truyện nguyên bản.
- `docs/04_CULTIVATION_COMBAT.md`: cảnh giới, tu luyện, ngộ đạo, kỹ năng, chiến đấu.
- `docs/05_NPC_FACTION_SIMULATION.md`: AI NPC, tương tác, kinh tế, mô phỏng tháng.
- `docs/06_TECH_ARCHITECTURE.md`: engine, cấu trúc code, save, dữ liệu, đồng bộ logic.
- `docs/07_ROADMAP_TESTS.md`: từng phase và tiêu chí chấp nhận.
- `docs/08_UI_ART_SOUND.md`: bố cục màn hình và tiêu chuẩn hình ảnh/âm thanh.
- `docs/09_DECISIONS_AND_RISKS.md`: lựa chọn mặc định & rủi ro.
- `prompts/00_MASTER_PROMPT.md`: prompt triển khai tổng.
- `prompts/01_PHASE0_SETUP.md`: prompt cho phase 0.
- `prompts/02_PHASE1_VERTICAL_SLICE.md`: prompt cho bản có thể chơi đầu tiên.
- `data_examples/*.json`: seed data tham khảo; **mới là mock design**, không phải dữ liệu gameplay đã được kiểm chứng.

## Mục tiêu bản demo đầu tiên (Vertical Slice)
Một nhân vật có thể tạo hồ sơ -> bắt đầu ở trấn Thanh Trì -> đi bản đồ -> nhận nhiệm vụ -> vào khu vực chiến đấu -> đánh quái -> nhận tài nguyên -> tu luyện -> đột phá Luyện Khí -> mở UI quan hệ NPC -> lưu/tải đúng trạng thái.

## Ràng buộc chất lượng
- Không dùng biểu tượng hoặc nút giả: nút thấy được phải hoạt động, hoặc đánh dấu `Not implemented` ở menu debug không xuất hiện trong build demo.
- Không tạo hệ thống lớn chỉ có hình minh họa; ưu tiên 1 luồng chơi thật end-to-end.
- Không sử dụng API trả phí / kết nối mạng để gameplay chạy.
- Không làm hỏng save cũ; dùng `schema_version` và migration.
- Không tự tuyên bố hoàn tất nếu không chạy lệnh kiểm tra/đoạn thử thực tế.
