# Nghiên cứu tham chiếu — nguồn và cách áp dụng
Cập nhật: 03/11/2026. **Trang https://thungtruyen.com/truyen/tien-nghich hiện chặn truy cập tự động**, nên không khẳng định đã đọc toàn bộ tác phẩm ở trang đó. Phần Tiên Nghịch dưới đây tổng hợp từ các bài nghiên cứu công khai và không thay thế việc đối chiếu nguyên tác.

## A. Tiên Nghịch (Xian Ni / Renegade Immortal)
- Nhân vật chính từ phàm nhân tiến vào thế giới tu tiên cạnh tranh tài nguyên, có quan hệ nhân quả và những biến cố tâm lý sâu sắc.
- Quy mô thế giới từng bước chuyển từ quốc gia -> tinh cầu -> tinh vực -> tầng thế giới cao hơn.
- Cảnh giới tăng trưởng có bước chuyển từ tích lũy tu vi sang **ý cảnh / ngộ đạo / bản nguyên / quy tắc**; không nên giản lược thành một thang cấp độ.
- Cảm giác cốt lõi để học hỏi: sinh tồn khó khăn, tuổi thọ và thời gian, giá trị của lựa chọn, nhân quả quá khứ tác động tương lai.
- Không dùng hệ địa danh Triệu Quốc, Chu Tước Tinh, La Thiên, Tiên Cương; không dùng Vương Lâm, Thiên Nghịch Châu, các nhân vật và arc gốc trong game.

Nguồn tham khảo thứ cấp:
1. https://doctieuthuyet.com/tien-nghich-wiki/
2. https://doctieuthuyet.com/ban-do-tien-nghich/
3. https://doctieuthuyet.com/canh-gioi-tien-nghich/
4. https://tintuc.tv360.vn/blog/tien-nghich-toan-thu/
5. https://xianlore.com/knowledge/renegade-immortal-xian-ni-world-characters-explained

## B. Tale of Immortal / Quỷ Cốc Bát Hoang
Các cơ chế đã được xác minh từ Steam, wiki và guide cộng đồng:
- Sandbox open-world theo thần thoại Trung Hoa; lựa chọn, khám phá và tu luyện là vòng lặp cốt lõi.
- Hệ thống đột phá cần nguyên liệu/điều kiện riêng, không đơn giản chỉ XP.
- NPC có tiểu sử và mô phỏng các hành động theo tháng; có quan hệ bạn-bè, tông môn, giúp đỡ, chiến đấu.
- Kỹ năng, bí kíp, pháp bảo, vận mệnh, tu luyện, tông môn, nhiệm vụ và chiến đấu thời gian thực tạo nhiều build.
- Một số hệ thống late-game phức tạp; không ép triển khai toàn bộ trong MVP.

Nguồn:
1. Steam official: https://store.steampowered.com/app/1468810/
2. Developer announcements: https://steamcommunity.com/app/1468810/announcements/?l=english
3. Breakthrough guide (community): https://taleofimmortal.com/guides/breakthrough
4. NPC wiki (community): https://tale-of-immortal.fandom.com/wiki/NPC
5. Quest guide (community): https://taleofimmortal.com/guides/quests

## C. Công nghệ
- Godot 4.7.2 stable xuất hiện trong bản phát hành chính thức tháng 8/2026; chọn nhánh stable 4.7.x thay vì 4.8 beta.
- Godot CLI hỗ trợ `--headless` và `--export-release` (cần preset/export templates).
- Antigravity hỗ trợ workspace rules qua `AGENTS.md`/`GEMINI.md` và agent thao tác editor/terminal. Tham chiếu API docs khi thực thi vì chức năng có thể thay đổi.

Nguồn:
- https://github.com/godotengine/godot/releases
- https://docs.godotengine.org/en/stable/about/release_policy.html
- https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html
- https://antigravity.google/docs/rules/
- https://antigravity.google/docs/ide/overview/

## D. Tách nguồn và sáng tạo
- **Thông tin tham chiếu:** nguyên tắc thế giới phân tầng; có NPC mô phỏng theo thời gian; nguyên liệu đột phá; game sandbox.
- **Đề xuất sáng tạo của dự án:** tên bản đồ, tông môn, tài nguyên, nhân vật, quy tắc nhân quả, công thức progression, kích thước bản đồ, toàn bộ thông số định lượng.
- **Mọi con số gameplay** trong blueprint là đề xuất để cân bằng sau playtest, tuyệt đối không phải số liệu gốc của hai tác phẩm.
