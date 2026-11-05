# Game Design Document (GDD) v0.1

## 1. Elevator pitch
**ĐẠO TÀN: VẠN KIẾP** là game nhập vai tu tiên sandbox 2D góc nhìn từ trên xuống, chơi đơn offline PC. Người chơi xuất thân phàm nhân ở một vùng biên, tu luyện, thăm dò bí cảnh, học công pháp, gia nhập hoặc lập tông môn, kết thân hay trả thù NPC, khám phá bí mật thiên địa. Một tháng trôi qua, thế giới đổi thay dù nhân vật chính có tham dự hay không.

### 4 trụ cột
1. **Tu tiên có cái giá:** cảnh giới gắn tài nguyên, thời gian, tâm ma, tuổi thọ, thiên kiếp.
2. **Thế giới biết nhớ:** NPC ghi nhớ ân oán và hành động, tông môn đổi chủ, quan hệ gây hệ quả.
3. **Tự do dựng đạo:** tạo build bằng linh căn, pháp thuật, pháp bảo, công pháp, ngộ đạo; nhiều cách vượt khó.
4. **Khám phá nhiều tầng:** từ một trấn lên lục địa, vực không gian, thế giới cao tầng; mỗi vùng mới tiết lộ sự thật khác.

## 2. Đối tượng và trải nghiệm
- Windows desktop, keyboard/mouse, độ phân giải 1920x1080 baseline (scale từ 1280x720); chế độ cửa sổ/toàn màn hình.
- Single-player offline, native app; chưa tích hợp online store.
- Camera top-down/2.5D 2D (không giả lập 3D). Vẽ nền tiên hiệp mực tàu/handpainted tối, UI ngọc bội + giấy cổ hiện đại, hiệu ứng pháp thuật sắc nét.
- Chơi tự do, không bắt buộc tuyến chính sau hướng dẫn. Difficulty: Thường / Sinh Tử (chế độ permadeath để về sau).

## 3. Core loop (mỗi lượt 5–15 phút thời gian thực)
Khám phá vùng / thu thập tin đồn -> chọn mục tiêu -> di chuyển / đàm phán / chiến đấu -> lấy tài nguyên và quan hệ -> tu luyện và học skill -> chế tạo / nâng trang bị -> chuẩn bị đột phá -> giải quyết hệ quả -> vào vùng nguy hiểm hơn.

## 4. Time loop
- Thời gian trong game theo **ngày**, quy đổi 30 ngày = 1 tháng; khám phá / nghỉ ngơi / tu luyện / di chuyển đẩy lịch tùy hoạt động.
- Trong chiến đấu instanced, thời gian thế giới **tạm dừng**; sau khi kết thúc áp dụng một số ngày hao tổn theo nội dung.
- Ở mốc chuyển tháng, NPC và phe phái chạy mô phỏng theo seed; event log hiển thị các việc quan trọng.
- Không được cộng dồn năm vô hạn khi reload hoặc chạy FPS cao: sử dụng một nguồn thời gian gameplay, tách thời gian thật.

## 5. Tạo nhân vật
- Tên, giới tính/hình dạng trang phục, tuổi 16–35, xuất thân (hàn môn / học sĩ / kẻ tha hương / hậu duệ tông môn suy tàn).
- Linh căn 5 hệ Kim, Mộc, Thủy, Hỏa, Thổ; độ phù hợp 0–100, một sở trường chính, điểm yếu phụ; có cơ chế chênh lệch phẩm chất không khiến run vô dụng.
- Tính cách: chính/trung/dị; lời thề ban đầu (cứu người, vô cầu, báo thù, hộ đạo); thiên phú mỗi người khác nhau nhưng có ràng buộc tradeoff.
- Không buộc nhân vật phải giống bất cứ nhân vật IP nào.

## 6. Các lớp progression
1. **Thân thể:** HP, khí huyết, thân pháp, phòng ngự, thể chất, độc kháng.
2. **Linh lực:** MP, hồi linh lực, trữ lượng, linh căn phù hợp.
3. **Nguyên thần/Đạo tâm:** kháng tâm ma, thần thức, giác ngộ qua biến cố.
4. **Công pháp:** thụ động và kỹ năng đánh nhau theo vũ khí/hệ.
5. **Pháp bảo:** tăng khả năng hỗ trợ, không thay thế skill.
6. **Danh vọng / nhân quả:** ảnh hưởng giá mua, cầu viện, truy sát và truyện.

## 7. Game modes/screens
- Main Menu: New / Continue / Load / Settings / Exit.
- World Map: camera tự do, fog of war, POI, biomes, event, thời gian, đường an toàn/nguy hiểm.
- Town: shop, inn, market, apothecary, tea shop, NPC, tông môn nearby.
- Sect: bảng nhiệm vụ, sư môn, cống hiến, học bí kíp, bảng quan hệ, quản lý sau này.
- Combat Arena: top-down arena 16:9, real-time skill/dash/tấn công boss telegraph; thắng/thua có hệ quả.
- Character: cảnh giới, sức khỏe, tuổi thọ, linh căn, kỹ năng, pháp bảo, tồn kho.
- Cultivation: thiền định (cost time), cảm ngộ, bế quan, prepare breakthrough.
- Social: sổ nhân duyên, NPC profile, ân oán, danh vọng, thư tín.
- Journal: quests, thế giới đại sự, thông báo hành động tháng.

## 8. Tương tác với thế giới
- Mọi quyết định nguy hiểm có cảnh báo trước (đánh NPC cảnh giới cao, đột phá thiếu vật tư).
- Người chơi có thể bỏ lỡ sự kiện nhưng không được softlock tuyến cốt lõi.
- Hệ quả nhân quả không phải điểm thiện/ác tuyệt đối: NPC biết dựa trên chứng kiến/tin đồn; hệ quả được tính theo danh tiếng, bằng chứng, quan hệ.

## 9. Độ ưu tiên
**MVP**: 1 vùng, 1 trấn, 1 tông, 6 NPC, 3 skill, 3 loại địch, 1 boss, 1 dungeon, 1 tài nguyên đột phá, 1 quest, 2 mốc cảnh giới, save/load.
**Alpha**: 3–4 vùng, 30–50 NPC, 3 tông, 8–12 skill, 5 boss, crafting cơ bản, social event.
**Sau Alpha**: các tầng giới, tông chiến lớn, linh thú, pháp bảo phức tạp, lãnh địa, late-game dao lĩnh vực, soundtrack, gamepad, Việt/Anh.

## 10. Tiêu chuẩn thiết kế
- Có ít nhất 3 chiến lược tiến triển: đánh boss, trao đổi/đấu giá, làm việc cho tông.
- Boss phải có telegraph rõ; không random one-shot thiếu cảnh báo.
- Thất bại tu luyện gây thương/tâm ma/lùi thời gian, **không làm mất save hay vĩnh viễn vô vọng** ở Normal.
- Tối ưu cho người chơi không đọc hướng dẫn ngoài game.
