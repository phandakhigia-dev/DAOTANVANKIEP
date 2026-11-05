# ĐẠO TÀN: VẠN KIẾP — THẬP NHỊ TỈNH / BIG MAP MASTER PLAN V1

**Mục đích:** Tài liệu thay đổi kiến trúc và lệnh Antigravity để biến bản đồ hiện có thành **một tỉnh open world liên tục**, nằm trong một quốc gia có 12 tỉnh theo 12 địa chi; về sau thêm tỉnh và quốc gia mà không cần làm lại hệ thống bản đồ hoặc phá Save/Load, co-op.

**Mức độ:** Đề xuất thiết kế (proposed). Chưa kiểm tra source build mới nhất khi soạn tài liệu này. Không coi các tính năng co-op đã hoàn thiện chỉ vì có mã hoặc log test.

**Nguyên tắc gốc:** Giữ Tiên Nghịch làm tinh thần tu tiên, Tale of Immortal làm nền gameplay, Where Winds Meet cho khám phá, xã hội–kinh tế–gia tộc vận hành trong nền; không ép người chơi theo Guiding Arc.

## 1. Tầm nhìn thế giới

- Vũ trụ > lĩnh giới > đại lục > quốc gia > tỉnh > phủ/huyện > trấn/thôn > địa điểm > chunk.
- Một quốc gia `dai_huyen` tên tạm là **Đại Huyền Quốc**, có **12 tỉnh/Châu** theo Thập nhị Địa Chi.
- Triều đình (một hoàng đế, một trung ương, luật quốc gia, quốc khố, quân đội, lệnh, thuế) điều hành cả 12 tỉnh. Mỗi tỉnh có tỉnh quan và bộ máy địa phương. Tông môn có mức tự trị riêng nhưng vẫn chịu tác động của pháp luật, thuế, ngoại giao.
- Tỉnh đầu tiên `thin_chau` là **Thìn Châu**. Đề xuất bố trí kinh đô **Long Kinh** ở Thìn Châu để vừa có xã hội phàm nhân, vừa có triều đình thực sự xuất hiện trong bản đồ đầu. Các tên đều là placeholder có thể sửa trong data.
- Không sinh 12 world map hoàn chỉnh khi mới bắt đầu. Chỉ định nghĩa metadata quốc gia/tỉnh và các tuyến thông thương, để sau này có thể nạp từng tỉnh mở rộng.
- Mỗi province có định danh, hệ tọa độ, seed, biome, kinh tế, quan phủ, tông môn, NPC và trạng thái riêng. Cấu trúc world không mặc định có đúng 1 quốc gia.

## 2. Định danh 12 tỉnh (data-driven, chủ đề đề xuất)

| ID | Tên | Bản sắc / tài nguyên chủ đạo | Trạng thái V1 |
|---|---|---|---|
| ty_chau | Tý Châu | Sông ngòi, cảng, mậu dịch thủy | metadata |
| suu_chau | Sửu Châu | Đồng bằng, lương thực, chăn nuôi | metadata |
| dan_chau | Dần Châu | Sơn lâm, săn thú, khoáng sản | metadata |
| mao_chau | Mão Châu | Trúc lâm, dược thảo, học viện | metadata |
| thin_chau | **Thìn Châu** | Kinh đô, đồng bằng, núi, linh mạch | **PLAYABLE — MAP ĐẦU TIÊN** |
| ty_ran_chau | Tỵ Châu | Đầm lầy, độc thảo, đan dược | metadata |
| ngo_chau | Ngọ Châu | Thảo nguyên, ngựa, thương đội | metadata |
| mui_chau | Mùi Châu | Cao nguyên, nông trại, mục trường | metadata |
| than_chau | Thân Châu | Núi sâu, cơ quan, di tích | metadata |
| dau_chau | Dậu Châu | Phường thủ công, chợ đầu mối | metadata |
| tuat_chau | Tuất Châu | Biên ải, quân doanh, phòng tuyến | metadata |
| hoi_chau | Hợi Châu | Hồ lớn, ruộng nước, thủy sản | metadata |

Lưu ý: `ty_chau` (Tý) và `ty_ran_chau` (Tỵ) cần dùng slug riêng, tuyệt đối không dùng tên không dấu dễ xung đột. Đây là bản sắc đề xuất, không nhằm mô phỏng chính xác văn hóa 12 con giáp.

## 3. Quy mô Thìn Châu, big map thực sự

**Tổng phạm vi logical province:** 4.096 × 4.096 tile; một tile logic 32 × 32 px (chỉ là đơn vị kỹ thuật, không gán bằng mét thực tế).

- Bề ngang pixel logic = 131.072 px.
- Tổng ô tiềm năng = 16.777.216 tile. **Không** tạo hoặc vẽ 16,7 triệu tile trong một TileMapLayer/scene duy nhất.
- Chuẩn chunk: 64 × 64 tile = 2.048 × 2.048 logical px/chunk.
- Số chunk trên mỗi chiều: 64; toàn tỉnh 64 × 64 = 4.096 chunk tiềm năng.
- Khu outdoor của tỉnh **liền mạch**: đi bộ xuyên vùng không bắt buộc hiện loading screen. Thay vào đó streamer nạp chunk theo camera/người chơi.
- Tòa nhà, hầm mỏ nhiều tầng, bí cảnh/phó bản có thể dùng scene/instance riêng.
- Client tải chunk quanh người chơi, dự kiến bán kính hiển thị thử nghiệm 2 chunk, collision/AI gần 1 chunk; phải đo FPS/RAM trước khi khóa giá trị. Host mô phỏng trạng thái quan trọng ngoài màn hình bằng dữ liệu gọn.
- TileMapLayer Godot có giới hạn tọa độ serial hóa 16-bit signed trong *một layer*; chia chunk thành scene/layer nhỏ tránh va giới hạn và giảm số cập nhật. Không mặc định hỗ trợ liền mạch 16 triệu tile nếu chưa đo hiệu năng.

**Ước lượng thời gian đi ngang 4.096 tile, đường thẳng:**
- Chạy 160 px/s → 819,2 s = 13 phút 39 giây thực ≈ 1,14 ngày game.
- Linh thú 360 px/s → 364,1 s ≈ 6 phút 04 giây.
- Phi hành 480 px/s → 273,1 s ≈ 4 phút 33 giây.
- Đây là ngang một cạnh, không phải đi đường thực tế; đường núi, sông, địch và điểm dừng làm thời gian dài hơn.

**Quy tắc di chuyển / pacing:**
- Đi bộ 100 px/s; chạy mặc định 160 px/s; chạy nhanh 220 px/s có stamina; khinh công 320 px/s có tiêu hao/cooldown; linh thú 360; phi hành 480 hoặc tăng theo cảnh giới. Tất cả cần playtest, không hardcode thành chân lý.
- Đi trong thành: nhà → chợ 10–25 s; trung tâm → cổng 20–60 s; đi giữa các huyện 1–4 phút có tùy chọn xe ngựa.
- Không để tốc độ phi hành phá collision, qua cổng, xuyên nhà hoặc qua vùng cấm: dùng movement mode và movement graph phù hợp.
- Xe ngựa/trạm dịch là fast travel theo **tuyến đã khám phá**, tiêu tiền và thời gian game; truyền tống cao cấp có vật phẩm/vị trí điều kiện. Đi bộ vẫn hữu dụng để tìm cơ duyên.
- Không sử dụng cổng di chuyển tức thì tùy tiện để che một world trống.

## 4. Bố cục địa lý có chủ đích cho tỉnh đầu

Phân tỉnh thành các **địa hạt** định danh, không đồng nghĩa chunk. Các ranh giới mềm theo sông/núi/đường lớn.

1. **Long Kinh** — kinh đô và hoàng cung; trung tâm luật pháp, hoàng thành, phố thương mại, phường thợ, đấu giá, nha môn, thương hội.
2. **Đồng Nội** — thôn phàm nhân, ruộng, nghề nông, nhà thuê, hạ tầng sinh tồn; có thể là điểm sinh ra ngẫu nhiên.
3. **Đông Thị** — chợ lớn, trạm dịch, sạp hàng, nghiệp đoàn, nguồn tin, NPC kinh doanh.
4. **Tây Sơn** — khai thác đá/quặng, núi và sơn tặc; hang mỏ nhiều tầng.
5. **Bắc Lâm** — rừng cổ, săn thú, linh thảo và các cơ duyên theo điều kiện.
6. **Nam Giang** — sông, thuyền, cảng và vận chuyển hàng hóa.
7. **Thanh Vân Sơn Môn** — tông môn độc lập, có điều kiện gia nhập nhưng **không bắt buộc**.
8. **U Cốc** — vùng nguy hiểm, yêu thú và bí cảnh (level danger, không khóa cứng người chơi).

**Mục tiêu nội dung phiên bản tỉnh hoàn chỉnh (sau nhiều milestone, không bắt làm tất cả trong một lượt):** một kinh đô, 3–5 thị trấn/huyện thành, 12–20 thôn, 2–3 tông môn, nhiều cánh rừng/ruộng/mỏ/sông, khoảng 8–12 địa điểm cơ duyên có cấu trúc, nội thất tương tác, hệ NPC kinh tế xã hội. Các lượng này là mục tiêu thiết kế sẽ điều chỉnh theo playtest và năng lực sản xuất.

**Nguyên tắc tránh bản đồ lớn nhưng rỗng:** đường chính phải có điểm tương tác mỗi 20–40 giây di chuyển, vùng hoang có nhịp thưa hơn nhưng phải có tài nguyên, sinh vật, dấu vết, điều kiện thời tiết và tin đồn dẫn khám phá. Không đặt vật phẩm hiếm ngẫu nhiên quá dày.

## 5. Triều đình — quản lý MỘT quốc gia, không phải 12 chính quyền trung ương

**Cấu trúc:**
- Emperor / CentralCourt (`country_id`): đế vương, quốc khố, pháp điển, quân lực, quốc sách, quan hệ ngoại giao, sắc lệnh, lịch lễ tiết.
- SixMinistries (lục bộ, có thể giản lược V1 thành quản trị dữ liệu): Lại (bổ nhiệm), Hộ (thuế, dân), Lễ (lễ nghi/thi cử), Binh (quân), Hình (pháp luật), Công (hạ tầng).
- ProvinceGovernor (`province_id`): thu ngân sách, duy trì an ninh, bổ nhiệm huyện, ảnh hưởng đến giá, cướp bóc, thế lực.
- Magistrate (`county_id`): thuế địa phương, điều tra hành vi phạm pháp, quản lý chợ, tranh chấp.
- Guard/Army: bảo vệ thành, trấn áp cướp, canh cổng, phản ứng theo mức truy nã.
- Sect: chính sách riêng và quan hệ ngoại giao với triều đình; có thể nộp thuế, nhận đặc quyền hoặc đối kháng, không phải nhánh triều đình.

**Luồng vận hành giai đoạn đầu:** Triều đình ban sắc lệnh theo đợt; tỉnh quan thi hành; thành/trấn thay đổi thuế và an ninh; NPC và người chơi chịu hậu quả. Ở V1 giới hạn 2–3 loại sắc lệnh test được (ví dụ thuế chợ, truy nã yêu tặc, trợ cấp lương thực), tránh tạo hàng trăm luật chỉ nằm trên giấy.

**Tránh biến thành game chính trị bắt buộc:** người chơi làm ruộng, kinh doanh, săn yêu thú, tán tu hoặc gia nhập tông môn đều có thể bỏ qua chính trị, chỉ chịu ảnh hưởng xã hội một cách hợp lý. Không có Guiding Arc bắt buộc vào triều đình.

## 6. Xuất thân tự do trong một tỉnh lớn

Người chơi mới có thể sinh tại các thôn/ngoại ô/trấn/nhà trọ hợp lệ. Xuất thân, tài sản đầu, nghề nghiệp sơ cấp, linh căn tiềm ẩn và mối quan hệ gia đình có seed riêng; do host/server xác nhận và lưu bền vững.

- Ví dụ bắt đầu: tá điền, học đồ thuốc, tiều phu, ngư dân, kẻ lang thang, thợ mỏ, con nhà thương nhân.
- Không ép săn tàn kiếm → gia nhập tông → cống hiến → luyện đan → đột phá. Chuyển Guiding Arc cũ thành chuỗi câu chuyện thế giới tùy chọn nếu tương thích dữ liệu.
- Linh căn có thể hiển lộ, ẩn, yếu hoặc không có; vẫn tồn tại đường tìm cơ duyên, thể tu, y đạo, linh dược, nhưng phải có sự đánh đổi và độ khó tương xứng.
- Hướng dẫn theo ngữ cảnh có thể tắt, không khóa tiến trình.

## 7. Co-op 12 phút/ngày — world time thống nhất

- **Quy tắc bất biến:** 1 ngày game = 720 giây thực ở x1. Một giờ game = 30 giây thực. Đồng hồ thế giới thuộc host/server, không thuộc từng client.
- Khi có hơn một người chơi, không cho một client tự nâng tốc độ, nhảy ngày hoặc nhân đôi giao dịch.
- NPC gần người chơi: AI di chuyển, tương tác, combat. NPC trong cùng tỉnh nhưng xa: update nghề nghiệp, giao dịch, trạng thái theo batch ở tick ngày. NPC ở tỉnh chưa mở: chỉ có dữ liệu tổng hợp nếu cần giao thương/chiếu chỉ, tuyệt đối không tạo giả mô phỏng chi tiết.
- Người chơi trong các chunk khác nhau không cần nhận toàn bộ vị trí NPC và quái ở nơi xa. Chỉ replicates trong phạm vi quan tâm, đồng bộ world events, sắc lệnh, economy index toàn tỉnh ở tần suất thấp.
- Cùng một cây/quặng/vật phẩm/thương vụ chỉ có một chủ sở hữu và một lần ghi nhận giao dịch. Dùng entity ID, request ID và xử lý idempotent trên host.
- Nếu host ngắt, trạng thái world save được flush nhất quán trước khi dừng; migration host là việc mở rộng sau, không tự hứa V1 có.
- Bế quan dài hạn của cá nhân KHÔNG khiến đồng hồ thế giới tua nhanh khi bạn chơi co-op. Tích lũy tiến trình tu luyện cá nhân phải mô tả rõ; nhảy năm toàn server chỉ theo cơ chế đồng thuận/đúng điều kiện, không mặc định triển khai.
- Vấn đề tuổi thọ: với lịch 360 ngày/năm, 1 năm = 72 giờ thực khi chạy liên tục, 100 năm = 300 ngày thực. Truyền thừa nhiều thế hệ cần cơ chế đại sự/nhảy thời đại đồng thuận, hoặc thời gian server vận hành lâu dài; không giả định diễn ra trong vài buổi chơi.

## 8. Dữ liệu / API ranh giới cần cố định trước khi dựng map

**Tạo registries và identifiers ổn định:**

```json
{
  "world_id": "dao_tan_world_01",
  "continent_id": "mortal_continent_01",
  "country_id": "dai_huyen",
  "country_display_name": "Đại Huyền Quốc",
  "country_capital_province_id": "thin_chau",
  "province_ids": ["ty_chau", "suu_chau", "dan_chau", "mao_chau", "thin_chau", "ty_ran_chau", "ngo_chau", "mui_chau", "than_chau", "dau_chau", "tuat_chau", "hoi_chau"],
  "playable_province_id": "thin_chau",
  "server_clock_real_seconds_per_day": 720,
  "world_seed": 12345678
}
```

```json
{
  "province_id": "thin_chau",
  "display_name": "Thìn Châu",
  "size_tiles": [4096, 4096],
  "tile_size_px": 32,
  "chunk_size_tiles": 64,
  "generation_revision": 1,
  "status": "playable_in_progress",
  "capital_city_id": "long_kinh",
  "governor_npc_id": "thin_governor_001",
  "entry_points": ["dong_noi_spawn", "long_kinh_south_gate"],
  "neighbor_province_ids": ["ty_chau", "dan_chau", "ngo_chau"],
  "persistent_world_diffs": true
}
```

**Entity state keys:** stable `entity_uid` / `location = {country_id, province_id, chunk_xy, local_tile_xy}`. Tài sản/sạp hàng/cây đào/quặng/NPC/ruộng có ownership và revision; save world chung và save từng người theo world_id; migrate schema cũ có bản sao dự phòng.

**Chunk pipeline:** quy hoạch địa hình (world seed + biomes + hydrology) → đường/sông/đô thị được khóa vị trí thủ công → terrain procedural quanh các điểm neo → spawn NPC/tài nguyên theo điều kiện → ghi player changes trong chunk diff. Seed thế giới không được đổi ngẫu nhiên khi load lại.

**Phải có công cụ chỉnh tay:** Province Editor trong Godot hoặc tool data-driven để chuyển vùng biome, vẽ đường, sông, thành, thôn, spawn, teleport route, encounter marker. Tính chỉnh sửa được quan trọng hơn random tất cả.

## 9. Cấu trúc thư mục đề xuất

```text
world/
  world_registry.json
  countries/dai_huyen/country.json
  countries/dai_huyen/court_rules.json
  provinces/thin_chau/province.json
  provinces/thin_chau/biomes.json
  provinces/thin_chau/roads_rivers.json
  provinces/thin_chau/settlements.json
  provinces/thin_chau/landmarks.json
  provinces/thin_chau/generated_chunks/   # cache, có thể tái tạo
  provinces/thin_chau/world_diffs/         # trạng thái bền vững, không xóa
  province_templates/
scenes/world/chunks/
scripts/world/world_registry.gd
scripts/world/province_manager.gd
scripts/world/chunk_streamer.gd
scripts/world/procedural_generation.gd
scripts/world/interest_manager.gd
scripts/politics/court_manager.gd
scripts/politics/province_government.gd
scripts/save/world_migration.gd
```

Chỉ là đề xuất: Antigravity phải đối chiếu các module hiện có và TÁI SỬ DỤNG thay vì tạo bộ song song gây xung đột.

## 10. Kế hoạch triển khai có thứ tự

### M0 — Audit & impact report (bắt buộc trước khi sửa)
- Đọc `project.godot`, main scene, world_map, TileMapLayers, scene transitions, GameClock, Save/Load, Multiplayer, NPC/Economy/Quest/Assets.
- Liệt kê module và data schemas đang dùng, lỗi đã biết từ audit trước; không được tự tuyên bố co-op đã đầy đủ nếu chưa test.
- Lập migration plan và định nghĩa interface ổn định. Backup branch/tag và bản sao save.

### M1 — National registry & courts skeleton
- WorldCountry, ProvinceDefinition, CourtState, Governor, CountyState ở dạng dữ liệu.
- 12 tỉnh xuất hiện trên **bản đồ hành chính**, nhưng chỉ `thin_chau` là playable.
- Không sinh full scene của 11 tỉnh chưa phát triển.

### M2 — Province streaming vertical slice
- Tạo lưới 4.096×4.096 logic + chunk 64×64; streaming quanh player.
- Làm thật và đẹp lõi 512×512 tile (bao gồm một thôn, 1 trấn nhỏ, ruộng, rừng, mỏ và đường kết nối). Các vùng khác có terrain cơ bản, chưa gắn nhãn hoàn thành.
- Telemetry RAM/FPS/frametime và lỗi cạnh chunk; thử khi 2 client ở xa nhau.

### M3 — Hoàn thiện tỉnh theo cụm chức năng
- Dựng Long Kinh, phố chợ, huyện thành, dân cư, tuyến xe ngựa, quân đội, sông, núi, 2 tông môn; quy hoạch hình khối trước, thay art Phase 4 khi đã xác nhận style.
- Sạp hàng, farm, khai khoáng, giao thương, NPC life/market + sự kiện ngẫu nhiên thực sự kết nối với server.
- Địa điểm tu luyện, cơ duyên, bí cảnh không theo chuỗi tuyến tính.

### M4 — Government gameplay & systems
- Kiểm chứng một sắc lệnh thuế chợ, một sự kiện truy nã, một chu kỳ thương đội. Player có thể không tham gia nhưng thấy thay đổi hợp lý.
- Save/Load world state theo chunk, court, tỉnh, NPC, ruộng/sạp hàng. Migrate từ save cũ.

### M5 — Stress test và gói audit
- 2–4 tiến trình thật, host + client ở khác chunk và khác huyện: vẫn đồng hồ 720s/day và cùng sự kiện world.
- Chặt cây, đào quặng, mua 1 vật phẩm trên 2 client cùng lúc: chỉ 1 lần ghi nhận.
- Logout/Join, reconnect, save/load: không respawn tài nguyên khai thác, không mất nhà/đất/tiền.
- FPS mục tiêu ban đầu 60 trên máy cấu hình mục tiêu do chủ dự án xác nhận; không tuyên bố đạt nếu không có kết quả đo.
- Xuất screenshot gameplay thật, log test, `FEATURE_STATUS.md`, `WORLD_MAP_DESIGN.md`, `MIGRATION_REPORT.md`, và ZIP audit; báo cáo DONE/PARTIAL/NOT_TESTED trung thực.

## 11. Điều kiện nghiệm thu quan trọng

1. Người mới vào Thìn Châu có thể đi từ thôn tới trấn, rừng, mỏ, ngoại thành mà **không phải hoàn thành một nhiệm vụ chính**.
2. Khu outdoor liền mạch, không load toàn tỉnh cùng lúc, không khựng quá mức khi vượt cạnh chunk.
3. Người A ở Long Kinh, người B ở Tây Sơn: vẫn cùng world clock và tồn kho tài nguyên đúng với server.
4. Người chơi rời chunk/thoát game/đăng nhập lại: cây/quặng đã khai thác, hàng bán, tiền và tài sản không nhân đôi hoặc phục hồi sai.
5. Triều đình quốc gia có sắc lệnh tác động tới Thìn Châu và tỉnh quan áp dụng; kiến trúc sẵn sàng cho province_id thứ hai.
6. Hệ thống 12 tỉnh chỉ là metadata + các đường biên/travel links chưa mở; không ghi nhãn 11 tỉnh là playable.
7. V1 chưa được coi là 'đủ toàn tỉnh' nếu chỉ có vùng lõi 512×512 hoạt động; báo cáo phần địa lý chưa hoàn thiện rõ ràng.

## 12. PROMPT CHÍNH THỨC DÁN ANTIGRAVITY

> Bạn là Lead Godot Engineer + Systems Designer của dự án ĐẠO TÀN: VẠN KIẾP. Đọc toàn bộ file `DAO_TAN_THAP_NHI_TINH_BIG_MAP_MASTER_PLAN_V1.md` trước khi làm.
>
> **THAY ĐỔI MỤC TIÊU WORLD MAP:** Không tiếp tục làm các khu 128×128 rời rạc làm đại thế giới. Dựng một tỉnh open-world ngoài trời liền mạch là **Thìn Châu**, phạm vi logical **4.096×4.096 tile**, chia **chunk 64×64**, tải động, có hệ đăng ký quốc gia **Đại Huyền Quốc** và metadata 12 tỉnh theo 12 địa chi. Mỗi tỉnh sẽ có thể phát triển thành bản đồ tương đương về sau. Triều đình quốc gia quản lý các tỉnh, không tạo 12 hoàng đế. Long Kinh đặt tại Thìn Châu là kinh đô đề xuất và có thể cấu hình lại bằng data.
>
> **GIỮ NGUYÊN** hệ tu luyện, combat, NPC, co-op, kinh tế, save, quest, assets hiện có; mọi thay đổi phải có migration. **LOẠI BỎ TÍNH BẮT BUỘC** của Guiding Arc, biến nó thành nội dung tùy chọn nếu giữ được.
>
> **CO-OP:** 1 ngày game = 720 giây thực; host/server quyết định world time, NPC, chiến đấu, khai thác, giao dịch, world seed và chunk-diffs. Client không được gửi tài nguyên/tọa độ/số tiền như nguồn sự thật. Co-op khác chunk khác huyện phải đồng bộ đúng. Không nhảy thời gian toàn server vì một người đang bế quan.
>
> **QUY TRÌNH LÀM:** Bước 1 audit source thực tế, ghi `MAP_RESTRUCTURE_IMPACT.md` với đường dẫn code và migration trước. Bước 2 thực hiện M1–M2 có bản chơi được, kết quả đo FPS và test 2 tiến trình. Bước 3 hoàn thiện M3–M5 theo milestone, từng mốc chỉ đánh dấu DONE khi test thực tế đạt. Có thể dùng dữ liệu procedural nhưng phải có editor/data-driven để bố trí thủ công đường, sông, thành, thôn và tông môn. Không vẽ hoặc instantiate 16,8 triệu tile cùng lúc. Không tạo toàn tỉnh rỗng rồi tuyên bố hoàn thành.
>
> **BÀN GIAO:** source + 1 tỉnh có thể mở rộng + registry 12 tỉnh + court skeleton + test logs + ảnh chụp gameplay thật + tài liệu cấu trúc + `FEATURE_STATUS.md` + ZIP audit mới. Ghi đúng những mục chưa kiểm thử. Không tái tạo project, không xóa save, không ghi đè bản cũ trước khi backup.

---

## 13. Nguồn tài liệu kỹ thuật

- Godot 4, TileMapLayer class: https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html
- Godot Using TileMaps: https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html
- Godot High-Level Multiplayer: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- Godot MultiplayerSynchronizer: https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html

**Ghi chú phạm vi:** Đây là game design spec và chỉ dẫn thay đổi; không phải xác nhận số liệu benchmark cho build hiện tại.
