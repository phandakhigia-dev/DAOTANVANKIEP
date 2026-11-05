# Quyết định mặc định, giới hạn và rủi ro

## Quyết định hiện tại (đề xuất, có thể chỉnh)
- Hệ máy: Windows PC offline, one player.
- Engine: Godot 4.7.x stable, GDScript; không dùng Electron.
- Góc nhìn: 2D top-down/handpainted; chiến đấu arena riêng, world map di chuyển tự do.
- Input: WASD, aim chuột, keyboard shortcuts remappable.
- Ngôn ngữ UI đầu tiên: tiếng Việt; kiến trúc cho localization về sau.
- Độ khó: Normal, bỏ permadeath khỏi bản đầu.
- Thời gian: tính theo ngày, simulation NPC quan trọng khi kết thúc tháng.
- Đồ họa ban đầu: placeholder hợp pháp; sau vertical slice mới thay bằng assets final.
- NPC: 6 trong MVP, 30–50 trong alpha; giữ kết quả deterministic.

## Rủi ro & xử lý
| Rủi ro | Mức | Phòng ngừa |
|---|---|---|
| Scope như Tale of Immortal quá lớn | Rất cao | khóa vertical slice, DoD từng phase |
| NPC simulation khiến game nặng / khó debug | Cao | batch theo tháng, RNG seed, event log, aggregate NPC xa |
| Save hỏng sau nâng cấp | Cao | versioned, migration, backup, roundtrip tests |
| Game nhiều menu nhưng không chơi được | Rất cao | làm 1 vòng chơi thật trước, không thêm nút giả |
| Combat thiếu phản hồi | Cao | telegraph, hit feedback, cooldown UI, playtest |
| Asset vi phạm bản quyền | Cao | artwork nguyên bản, license check, reference không đưa trực tiếp vào build |
| Antigravity tự thay stack/xóa project cũ | Cao | AGENTS.md, repo mới, commit, review diff |
| Nhiều nhiệm vụ tự sinh vô nghĩa | Trung bình | authored anchor events + template có điều kiện và hậu quả |

## Không nằm trong phạm vi ban đầu
- MMO, multiplayer, backend, đăng nhập Google/Gemini, AI dialog runtime.
- Voice clone và nội dung từ Tiên Nghịch được chép nguyên văn.
- Toàn bộ cảnh giới late-game, 300 skill, 1000 NPC hiện hữu trên màn hình.
- Online shop, battle pass, hút máu và hệ thống gacha.

## Quy tắc mở rộng
Chỉ thêm một feature nếu trả lời được: (1) làm gì cho vòng gameplay; (2) data contract; (3) phương án lưu/tải; (4) cách test; (5) cách UI đưa người chơi đến tính năng; (6) tình huống thất bại.
