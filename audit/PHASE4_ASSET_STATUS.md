# BÁO CÁO HIỆN TRẠNG TÀI NGUYÊN ĐỒ HỌA & ÂM THANH (PHASE 4 ASSET STATUS)
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Thời điểm Audit:** 04/11/2026  
**Chuẩn phong cách nghệ thuật:** *Thủy Mặc Cổ Phong (Ink-Wash Dark Xianxia), Palette 32 màu cổ điển.*

---

## 1. PHONG CÁCH NGHỆ THUẬT & BẢNG MÀU CHUẨN

Toàn bộ thế giới được thiết kế dựa trên phong cách nghệ thuật thủy mặc võ hiệp phương Đông kết hợp pixel art chuẩn mực:
- **Tập tin Palette chuẩn:** `assets/palette.hex` và `assets/palette.png`.
- **Số lượng màu chủ đạo:** 32 màu chọn lọc kỹ lưỡng, chia thành 4 nhóm gam:
  1. *Thanh Mộc & Thủy Mặc:* Xanh lục trúc, xanh rêu cổ mộc, lam tuyền đầm lầy.
  2. *Huyền Thiết & Nham Thạch:* Xám đá Vân Lĩnh, đen mực tàu, bạc kiếm ý.
  3. *Huyết Sa & Đan Hỏa:* Đỏ son lò đan, huyết hồng U Minh, hổ phách kinh tế.
  4. *Hoàng Kim & Nguyệt Quang:* Vàng kim đột phá thiên kiếp, bạch ngân ánh trăng.

---

## 2. DANH MỤC TÀI NGUYÊN HIỆN CÓ

### A. Bộ Tileset Địa Hình & Công Trình Thị Trấn (Props / Modular Tiles):
Vị trí thư mục: `wuxia/32/` (Kích thước chuẩn: `32x32` pixels).

| Tên Tài Nguyên | File PNG | Scene Tương Ứng | Kích Thước | Công Dụng Trong Game |
| :--- | :--- | :--- | :---: | :--- |
| **Gạch Địa Hình** | `wuxia/32/tiles/terrain.png` | `town_map_real.tscn` | 32x32 | Nền đường lát đá, đất dã ngoại, thềm nhà |
| **Thùng Gỗ** | `wuxia/32/props/town/barrel.png` | `barrel.tscn` | 32x32 | Vật cản, trang trí quán trọ, sạp hàng |
| **Giỏ Tre / Sọt** | `wuxia/32/props/town/baskets.png` | `baskets.tscn` | 32x32 | Đựng linh thảo chợ tán tu |
| **Ghế Trà Gỗ** | `wuxia/32/props/town/bench.png` | `bench.tscn` | 32x32 | **Smart Object:** Ngồi uống trà đẩy thời gian +1h |
| **Rương Báu Đóng** | `wuxia/32/props/town/chest_closed.png` | `chest_closed.tscn`| 32x32 | Rương thạch động bí cảnh Rừng Trúc Vạn Lĩnh |
| **Chum Rượu Lớn** | `wuxia/32/props/town/jar_large.png` | `jar_large.tscn` | 32x32 | Trang trí Quán Trọ Mạc Tư Viễn |
| **Hũ Gốm Nhỏ** | `wuxia/32/props/town/jar_small.png` | `jar_small.tscn` | 32x32 | Trang trí tiệm thuốc Dược Phẩm Các |
| **Sạp Hàng Gỗ** | `wuxia/32/props/town/market_stall.png` | `market_stall.tscn`| 32x64 | **Sạp Hàng Tu Sĩ** (Player Stall Escrow System) |
| **Đèn Lồng Cột Cao**| `wuxia/32/props/town/pole_lantern.png`| `pole_lantern.tscn`| 32x64 | Chiếu sáng ban đêm tại ngã tư thị trấn |
| **Bao Gạo / Lương** | `wuxia/32/props/town/rice_sacks.png` | `rice_sacks.tscn` | 32x32 | Lương thực dân gian tại kho thị trấn |
| **Đèn Lồng Đá** | `wuxia/32/props/town/stone_lantern.png`| `stone_lantern.tscn`| 32x32 | Đèn đá cổ kính bên hồ Thanh Trì |
| **Bình Nước Linh Tuyền**| `wuxia/32/props/town/water_jar.png` | `water_jar.tscn` | 32x32 | Bình chứa nước suối tinh khiết |
| **Giếng Cổ Trấn** | `wuxia/32/props/town/well.png` | `well.tscn` | 32x32 | **Smart Object:** Múc nước giếng cổ hồi +30 HP |

### B. Bộ Biểu Tượng Vật Phẩm & UI (Icons):
Vị trí thư mục: `assets/sprites/icons/` (Kích thước chuẩn: `16x16` đến `32x32` pixels).

- **Trang bị (Armour):** `robe_white.png` (Bạch y đạo bào đệ tử).
- **Đan dược (Elixirs):** `gourd_wine.png` (Hồ lô linh tửu), `pill_red.png` (Hồi Xuân Đan / Tụ Khí Đan).
- **Thực phẩm (Food):** `steamed_bun.png` (Bánh bao lót dạ).
- **Kinh thư (Manuals):** `manual_blue.png` (Tâm pháp kiếm quyết Tàng Kinh Các).
- **Linh tài & Tiền tệ (Materials):** `copper_coin.png` (Linh thạch / Đồng tiền).
- **Trạng thái (Status):** `poison.png` (Trúng độc hàn khí U Minh).
- **Bùa chú (Talismans):** `talisman_yellow.png` (Thanh Vi Hộ Mệnh Phù).
- **Vũ khí (Weapons):** `dao_broad.png` (Trảm Ma Đao), `jian_plain.png` (Thanh Phong Kiếm).

### C. Bộ Hiệu Ứng Hình Ảnh Võ Hiệp (VFX Scenes):
Vị trí thư mục: `scenes/vfx/`

1. `vfx_sword_slash.tscn` / `.gd`: Vòng cung kiếm quang bán nguyệt màu lam thiên (`#66ddff`) xé rách không gian, kèm tia lửa kiếm ý tóe ra khi trúng đích.
2. `vfx_cultivation_aura.tscn` / `.gd`: Hào quang hoàng kim (`#ffd700`) tụ khí đan điền, linh trụ bốc cao khi đột phá cảnh giới.
3. `vfx_lightning_impact.tscn` / `.gd`: Sét đánh điểm giáng màu tím lam (`#c084fc`), sóng xung kích nổ tung và tia điện hồ quang trong Thiên Kiếp Trúc Cơ.
4. `vfx_bamboo_leaves.tscn` / `.gd`: Hạt lá trúc rơi phiêu lãng và bụi phấn mộc linh nhẹ nhàng trôi theo gió tại Rừng Trúc Vạn Lĩnh.
5. `vfx_alchemy_glow.tscn` / `.gd`: Đan khí màu tía tím cuồn cuộn bốc lên từ lò luyện đan, phát sáng khi đan dược xuất lô thành công.

### D. Hệ Thống Âm Thanh Võ Hiệp (Procedural Audio Engine):
Vị trí thư mục: `scripts/core/audio_service.gd`

- **Công nghệ:** Tự động tổng hợp sóng âm dạng số 16-bit PCM (Linear PCM AudioStreamWAV) tại thời điểm khởi động. Không lo thiếu file mp3/wav khi chuyển dọn project.
- **8 Hiệu ứng võ hiệp (SFX):**
  - `sfx_sword_slash`: Tiếng kiếm khí xé gió vút qua.
  - `sfx_sword_deflect`: Tiếng đao kiếm va chạm kim loại đanh thép.
  - `sfx_pill_swallow`: Tiếng nuốt đan dược và vận hành khí tức ấm áp.
  - `sfx_alchemy_brew`: Tiếng đan lò sôi sục linh hỏa bùng phát.
  - `sfx_herb_pickup`: Tiếng hái linh thảo xào xạc thanh tao.
  - `sfx_button_click`: Tiếng gõ mõ gỗ cổ phong bấm nút giao diện.
  - `sfx_lightning_strike`: Tiếng sét nổ rền vang rung chuyển đất trời.
  - `sfx_monster_growl`: Tiếng gầm trầm đục của yêu thú hung hãn.
- **3 Nhạc nền cổ phong lặp tuần hoàn (Procedural BGM):**
  - `bgm_peaceful_town`: Khúc nhạc thanh bình gảy đàn cổ cầm ngũ cung.
  - `bgm_combat_tension`: Tiết tấu dồn dập căng thẳng trong đấu trường.
  - `bgm_tribulation_ambient`: Gió rít và tiếng chuông tĩnh mịch trong lôi kiếp.

---

## 3. NGUỒN GỐC & GIẤY PHÉP TÀI NGUYÊN (LICENSE & PROVENANCE)

1. **Nguồn gốc:** Toàn bộ sprites, tilesets, icons, mã nguồn shader, code procedural audio và dữ liệu JSON đều được tạo lập nội sinh trong khuôn khổ dự án "ĐẠO TÀN: VẠN KIẾP".
2. **Bản quyền bên thứ ba:** Không sử dụng bất kỳ thư viện tài nguyên lậu, không có binary vi phạm bản quyền thương mại.
3. **Mức độ an toàn pháp lý:** Hoàn toàn sạch và an toàn 100% để lưu trữ, chia sẻ hoặc xuất bản.
