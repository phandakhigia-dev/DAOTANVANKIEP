# Tu luyện, ngộ đạo, cảnh giới và chiến đấu

## 1. Cảnh giới dự kiến (game riêng; cấp tham chiếu cho thiết kế)
| Tier | Cảnh giới | Unlock chính | Yêu cầu dạng thức |
|---|---|---|---|
| 0 | Phàm Nhân | hướng dẫn, tiếp xúc linh khí | duyên khởi / cơ hội |
| 1 | Luyện Khí | dùng thuật cơ bản | tích lũy linh khí + tĩnh tâm |
| 2 | Trúc Cơ | mở bộ công pháp và thể chất | linh dược + định mạch + thí luyện |
| 3 | Kết Đan | thêm kỹ năng chủ động, pháp bảo | đan nguyên + ải tông/tâm ma |
| 4 | Nguyên Anh | nguyên thần, phân thân tạm | linh hồn + đại kiếp |
| 5 | Hóa Thần | xây ý cảnh, thần thức | chọn một nhánh đạo tâm |
| 6 | Vấn Đạo | vực lực, lĩnh vực | 3 chứng cứ trải nghiệm cuộc đời |
| 7 | Hợp Đạo | tái cấu trúc kỹ năng | khế ước quy tắc + thử thách |
| 8 | Phá Giới | mở đường hư không | thiên môn + linh mạch |
| 9 | Chân Tiên | đoạn kết mở, hậu duệ | cốt truyện + nhân quả |

Các tên Luyện Khí/Trúc Cơ/Kết Đan... là thuật ngữ tiên hiệp phổ biến; hệ ngộ đạo/kiếp/đạo lộ của game được viết mới. **Phase 1 chỉ làm Phàm Nhân -> Luyện Khí -> Trúc Cơ sơ kỳ**, chưa làm cây late-game.

## 2. Mỗi cảnh giới có 4 pha
- `early`, `middle`, `late`, `peak` (đầu/giữa/cuối/viên mãn); chi phí tăng nhưng không nhân quá cao.
- Các chỉ số tách `realm_tier`, `realm_stage`, `cultivation_xp`, `foundation_quality`, `lifespan`, `heart_demon`.
- Chỉ `peak` được đột phá; thiếu điều kiện thì UI hiện lý do, vật phẩm cần và vị trí gợi ý tìm vật phẩm.
- Đột phá bằng nghi thức trong UI; thất bại làm trọng thương / tiêu hao nguyên liệu / tăng tâm ma (chế độ thường); không mất toàn bộ progress.

## 3. Thiên phú và đạo tâm
- 5 hệ Kim Mộc Thủy Hỏa Thổ + 2 thuộc tính thể chất/thiên tính (Lôi, Huyết) là trường phái hiếm; player build 2 trục thiên phú + sở trường.
- `dao_path`: **Bảo Hộ**, **Truy Cầu**, **Cân Bằng**, **Chấp Niệm**; lựa chọn nảy sinh từ cách hành xử, không chỉ click chọn.
- `comprehension`: tích từ trải nghiệm (cứu người, quan sát mùa, mất người quen, tham quan cổ di tích); không bán như XP đơn thuần.
- **Nghiệp duyên**: `debts` liên kết entity A -> B với `reason` và `strength`; không chỉ cộng điểm Karma.

## 4. Tăng trưởng tuổi thọ
- Mọi NPC và Player có tuổi thật / tuổi thọ tối đa, thời gian tăng theo lịch.
- Thọ mệnh tự nhiên tăng qua cảnh giới, đan dược quý có giới hạn dùng; thương tích nặng có thể giảm thọ nguyên.
- Alpha: không thực thi chết tuổi già cho NPC quest-critical khi chưa có cơ chế người kế nhiệm; có countdown + event migration.

## 5. Thiết kế combat
- **Real-time 2D action** trong arena tách khỏi world map, camera top-down, vật cản, báo hiệu vùng đánh boss.
- Move WASD; aim mouse; LMB basic; RMB special; Q/E kỹ năng; R ultimate (late); Space né; Tab target; Esc pause. Remappable.
- Thời gian thực; i-frame dash ngắn, cooldown rõ, damage event-based.
- Skill data: `id`, `school`, `element`, `cost`, `cooldown`, `cast_time`, `range`, `area`, `projectile_speed`, `effects`, `tags`, `upgrade_curve`, `visual_ref`.
- Phân lớp damage: physical, spirit, true (late); status: burn, slow, bleed, shield, silence (late), stagger.
- Enemies có state machine Idle/Chase/Attack/Windup/Recover/Retreat/Dead; không tự động teleport đến người chơi; cảm giác đánh phải phản hồi hit flash/camera shake nhẹ/audio.

## 6. Các trường phái và combo
- **Kiếm:** phi kiếm, kiếm khí, kiếm trận; combo critical + dấu ấn, tầm trung.
- **Lôi:** chuỗi lôi, bùng nổ, tốc độ; đổi bằng linh lực và hồi chiêu dài.
- **Mộc:** trói, hồi phục/độc, triệu hồi rễ; kiểm soát.
- Các hệ Thủy, Hỏa, Thổ, Huyết/Thể tu để mở sau.
- Các pháp bảo có `active_effect`, `passive_effect` và `cost` riêng; artifact không gây power creep không kiểm soát.

## 7. Balance nền cho demo (giá trị gợi ý, cần playtest)
- Người mới 100 HP / 60 MP; quái thường 45 HP, 6-9 damage/hit; boss 500 HP, 5 mẫu tấn công telegraph.
- Đánh 1 quái 10–20s; boss khoảng 90–180s với build đúng cấp.
- Chu kỳ 1 nhiệm vụ + 1 dungeon + 1 lần tu luyện cho cảm giác tiến bộ rõ; không bắt buộc grind cùng boss quá 3 lần để lấy 1 nguyên liệu chính.
- XP tăng theo cách tính có diminishing returns; không dùng level scaling vô tội vạ làm mọi khu vực ngang nhau.
- Kẻ địch cấp cao cảnh báo bằng màu biểu tượng và lời thoại; escape route luôn rõ.

## 8. Công thức định hướng (chưa khóa balance)
- `damage = base_power * (1 + atk_rating/(atk_rating + K)) * element_modifier * crit_modifier * defense_reduction`.
- `defense_reduction = 100/(100 + max(defense, 0))` là ví dụ chống miễn thương tuyệt đối.
- `breakthrough_chance = clamp(base + quality_bonus - injury_penalty - heart_demon_penalty, min, max)`; có trạng thái guaranteed-safe nếu người chơi thực hiện thêm tuyến chuẩn bị hiếm.
- Đặt K và bonus trong `balance.json` thay vì hardcode.

## 9. Bảo vệ game khỏi softlock
- Không tiêu thụ vật liệu trước khi xác nhận UI; atomic transaction khi breakthrough.
- Sau fail luôn có cách tìm lại nguyên liệu; NPC quest có phương án thay thế.
- Người chơi chết trong Normal: quay về trấn, mất linh thạch/tu vi có giới hạn, không xóa save.
