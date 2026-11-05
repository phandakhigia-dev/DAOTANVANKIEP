# ĐẶC TẢ HỆ THỐNG MỸ THUẬT TIÊN HIỆP PIXEL ART (WUXIA ART DESIGN SYSTEM)
**Dự án:** ĐẠO TÀN: VẠN KIẾP (2D Xianxia Sandbox RPG • Godot 4.7.2)  
**Tiêu chuẩn đồ họa cốt lõi:** Dựa trên cấu trúc chuẩn *Jianghu Top-Down Pixel Art (32x32)*.  
**Mục đích:** Tài liệu kim chỉ nam (Art Bible) định chuẩn tỷ lệ lưới, bảng màu, nguyên lý neo chân (Foot Anchoring), quy chuẩn hoạt ảnh 8 hướng và kiến trúc tòa nhà cho toàn bộ nhân vật, NPC, Boss và bối cảnh về sau.

---

## 1. HỆ THỐNG LƯỚI & GÓC NHÌN (GRID & PERSPECTIVE)

- **Đơn vị ô lưới cơ sở (Base Tile Grid):** `32 x 32` pixels.
- **Góc nhìn (Camera Perspective):** **Top-Down Oblique 2.5D** (góc nghiêng $60^\circ$ truyền thống của game nhập vai cổ điển).
  - Trục ngang $X$: Tỷ lệ 1:1.
  - Trục dọc $Y$: Tỷ lệ chiều sâu nén nhẹ; mặt đất nhìn từ trên xuống, vách tường và nhân vật thể hiện mặt diện đứng.
  - Độ sâu hiển thị (**Y-Sort**): Bắt buộc bật `y_sort_enabled = true` trên mọi CanvasItem trong thế giới.
- **Quy tắc Bộ lọc (Texture Filter):** Luôn đặt **`Nearest`** (`texture_filter = 1`) để giữ nét pixel sắc cạnh, tuyệt đối không dùng bộ lọc làm mờ (Bilinear/Linear).

---

## 2. BẢNG MÀU CHUẨN 43 MÀU (THE 43-COLOR WUXIA PALETTE)

Toàn bộ nhân vật, trang bị, địa hình và tòa nhà phải tuân thủ nghiêm ngặt 43 mã màu trong `assets/palette.hex`:

```
================================================================================
NHÓM MÀU                    MÃ HEX (TỪ SÁNG ĐẾN TỐI)
================================================================================
1. Mực / Viền tối           #5b5e68  ->  #40424c  ->  #3a3440  ->  #24202a
2. Đá phiến / Giấy cổ / Vách #e8dcc4  ->  #d2c4a8  ->  #b8aa8f  ->  #9d9079  ->  #837665  ->  #6b5f52
3. Gỗ trầm / Đất cằn        #9a7352  ->  #6e5039
4. Mộc Linh / Trúc diệp     #9bb07a  ->  #80995f  ->  #68834e  ->  #557046  ->  #46603f
5. Thủy Linh / Kênh nước    #a9c4c6  ->  #8aaeb3  ->  #6f97a0  ->  #58818c  ->  #456b78
6. Bạch Y / Mây mù          #e4e6e0  ->  #bcc5c8  ->  #8f9ca6
7. Chu Sa / Huyết Sát / Lửa  #e07b5f  ->  #c8483a  ->  #8e2f2a  ->  #5f2126
8. Ngọc Bích / Linh Mạch    #90c6aa  ->  #5fa58c  ->  #3f7a68
9. Kim Quang / Hoàng Phù    #fff0b8  ->  #f0cf7c  ->  #f5a95b  ->  #d8a84a  ->  #a8772f
10. Da người / Huyết sắc    #f0c9a2  ->  #d29f79  ->  #a5705a
11. Dạ Hành / Đạo bào đêm   #5d668a  ->  #414968  ->  #2d3149
================================================================================
```

---

## 3. QUY CHUẨN THIẾT KẾ NHÂN VẬT (CHARACTER DESIGN SPECIFICATION)

### 3.1. Kích Thước Bounding Box & Điểm Neo Chân (Foot Anchoring)
Để nhân vật di chuyển và tương tác xuyên suốt các địa hình mà không bị hiện tượng "chân trôi nổi" hoặc lỗi vẽ đè Y-Sort:
- Tọa độ `(0, 0)` của Node `CharacterBody2D` hoặc `AnimatedSprite2D` luôn là **vị trí tiếp xúc giữa hai bàn chân với mặt đất** (Foot Position).
- Sprite Offset được tính theo công thức: `offset = Vector2(-foot_x, -foot_y)`.

| Hành động | Kích thước Cell | Điểm Neo Chân `(foot_x, foot_y)` | Offset Cấu Hình Trong Godot | Số Frames | Tốc độ (fps) | Vòng lặp (Loop) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Đứng (`idle`)** | $40 \times 40$ px | `(20, 38)` | `Vector2(-20, -38)` | 4 | 5 | Có |
| **Chạy / Đi (`walk`)** | $40 \times 40$ px | `(20, 38)` | `Vector2(-20, -38)` | 6 | 9 | Có |
| **Trúng đòn (`hurt`)** | $56 \times 56$ px | `(28, 48)` | `Vector2(-28, -48)` | 6 | 10 | Không |
| **Tử vong (`death`)** | $56 \times 56$ px | `(28, 48)` | `Vector2(-28, -48)` | 8 | 8 | Giữ frame cuối 1200ms |
| **Tấn công thường (`attack`)** | $72 \times 72$ px | `(36, 58)` | `Vector2(-36, -58)` | 10 | 12 | Giữ frame cuối 200ms |
| **Khinh công / Lướt né (`qinggong`)** | $72 \times 72$ px | `(36, 58)` | `Vector2(-36, -58)` | 14 | 12 | Không (i-frame) |
| **Tuyệt kỹ / Combo (`combo`)** | $72 \times 72$ px | `(36, 58)` | `Vector2(-36, -58)` | 16 | 14 | Giữ frame cuối 200ms |
| **Tĩnh tọa (`meditate`)** | $40 \times 40$ px | `(20, 38)` | `Vector2(-20, -38)` | 4 | 4 | Có (hít thở linh khí) |

### 3.2. Thứ Tự 8 Hướng Trong Sprite Sheet (Rows Order)
Mọi Sprite Sheet hoạt ảnh nhiều hướng đều xếp theo đúng thứ tự 8 hàng từ trên xuống dưới:
- **Hàng 0:** Hướng Nam (`south` - nhìn thẳng xuống dưới)
- **Hàng 1:** Hướng Đông Nam (`south_east`)
- **Hàng 2:** Hướng Đông (`east` - nhìn ngang phải)
- **Hàng 3:** Hướng Đông Bắc (`north_east`)
- **Hàng 4:** Hướng Bắc (`north` - nhìn lưng lên trên)
- **Hàng 5:** Hướng Tây Bắc (`north_west`)
- **Hàng 6:** Hướng Tây (`west` - nhìn ngang trái)
- **Hàng 7:** Hướng Tây Nam (`south_west`)

### 3.3. Danh Mục Thiết Kế Nhân Vật Đạo Tàn
1. **Lâm Phong (Nhân vật chính):** Dựa trên `swordsman`. Thân khoác đạo bào lam xám, tóc búi kiếm hiệp, sau lưng mang vỏ kiếm gỗ đào hoặc kiếm sắt.
2. **Thư Nguyệt (Dược Sư):** Nữ tu áo xanh ngọc bích (`#90c6aa`), đai lưng lụa trắng, tay cầm phất trần hoặc giỏ linh thảo.
3. **Kỷ Hoàn (Thương Nhân Tán Tu):** Áo ngắn nâu sẫm (`#6e5039`), dáng người nhanh nhẹn, thắt lưng đính bàn tính và túi vải trữ vật.
4. **Mạc Tư Viễn (Lão Tán Tu):** Râu tóc bạc phơ (`#e8dcc4`), trường bào xám cổ phong, chống gậy trúc xanh (`#80995f`).
5. **Đoàn Vĩnh & Lâm Du (Thanh Vi Tông):** Đạo bào Thanh Vi tông màu lam trắng đặc trưng (`#a9c4c6`, `#e4e6e0`), phù hiệu vân mây trên ngực.
6. **Bạch San (Thợ Săn Yêu Thú):** Trang phục da thú gọn gàng (`#9a7352`), đeo cung tên sau lưng, ủng da cổ cao.
7. **5 Đại Boss:**
   - *Hắc Linh Xà Vương:* Mãng xà khổng lồ vảy tím đen (`#24202a`, `#5f2126`), mắt đỏ rực.
   - *Huyết Ma Khôi Lỗi:* Khôi lỗi đá to lớn (cell $96 \times 96$), phù văn huyết sắc khắc chìm trên ngực.
   - *Bách Độc Chu Hoàng:* Nhện chúa 8 chân gai góc, hoa văn độc nhãn phát sáng.
   - *Cổ Kiếm Linh:* Linh thể kiếm tiên mờ ảo ánh kim hoàng (`#fff0b8`, `#f0cf7c`), chân không chạm đất.

---

## 4. QUY CHUẨN THIẾT KẾ KIẾN TRÚC & TÒA NHÀ (BUILDINGS & PROPS)

### 4.1. Quy Chuẩn Kích Thước Tòa Nhà (Building Footprints)
Mỗi công trình trong game được thiết kế theo bội số của ô $32 \times 32$ px:

| Loại Công Trình | Kích Thước Lưới | Kích Thước Pixel | Chiều Cao Mái Hiên | Vị Trí Điểm Đặt (Footprint Anchor) |
| :--- | :---: | :---: | :---: | :--- |
| **Sạp Hàng / Chòi Trà / Miếu Nhỏ** | $2 \times 2$ ô | $64 \times 64$ px | 1 tầng ($48$ px) | Đáy giữa: `Vector2(-32, -63)` |
| **Dược Quán / Nhà Dân / Thợ Rèn** | $4 \times 3$ ô | $128 \times 96$ px | 1 tầng ($80$ px) | Đáy giữa chân tường mặt tiền |
| **Quán Trọ Thanh Trì / Lầu Gác** | $6 \times 4$ ô | $192 \times 128$ px | 2 tầng ($140$ px) | Đáy giữa hiên trước cửa chính |
| **Thanh Vi Tông Phân Điện** | $8 \times 5$ ô | $256 \times 160$ px | 2 tầng uy nghi | Đáy bậc tam cấp đá trắng |
| **Sơn Môn / Cổng Trấn Rừng Trúc** | $4 \times 2$ ô | $128 \times 64$ px | Mái vòm cổng | Đáy giữa lối đi |

### 4.2. Nguyên Lý Phân Lớp Y-Sort Của Tòa Nhà
```
           +-----------------------------+
           |        MÁI NGÓI CONG        |   <- Cao vượt lên trên (Y âm)
           |    (Overhang / Roof Eaves)  |   <- Nhân vật đứng sau nhà sẽ bị che
           +-----------------------------+
           |    VÁCH TƯỜNG / CỬA SỔ      |
===========+=============================+===========  <- ĐIỂM TIẾP ĐẤT (Y = 0)
           |   Chân tường & Hiên nhà     |   <- Node Origin đặt tại đây!
           |   (Collision Box chân nhà)  |   <- Nhân vật đi trước hiên sẽ đè lên
```

### 4.3. Ngôn Ngữ Hình Học Cổ Phong (Architectural Details)
1. **Mái ngói phi đao (Curved Eaves):** Đầu hồi uốn cong nhẹ lên trên theo phong cách kiến trúc thời Đường - Tống, ngói màu xám trầm (`#40424c`) hoặc lam tím tông môn (`#414968`).
2. **Hệ khung gỗ (Timber Framing):** Cột trụ tròn bằng gỗ mun (`#6e5039`), xà gồ đỡ mái vững chãi.
3. **Cửa song gỗ & Giấy dán:** Cửa trượt gỗ ô vuông dán giấy mờ (`#e8dcc4`), buổi tối hắt ánh đèn vàng ấm áp (`#f0cf7c`).
4. **Bậc thềm & Tường bao:** Xây bằng đá tảng đục đẽo (`#9d9079`, `#b8aa8f`), rêu phong bám chân tường (`#557046`).
5. **Chi tiết trang trí ngoại cảnh:**
   - Đèn lồng đỏ (`pole_lantern`): Treo trước hiên quán trọ và chợ.
   - Sọt đan & bao gạo (`baskets`, `rice_sacks`): Đặt dọc lối đi chợ tán tu.
   - Chum nước & thùng gỗ (`water_jar`, `barrel`): Đặt góc tường tạo cảm giác sinh hoạt đời thường.
   - Đèn đá tu tiên (`stone_lantern`): Đặt lối vào phân điện Thanh Vi Tông.

---

## 5. QUY CHUẨN THIẾT KẾ BIỂU TƯỢNG VẬT PHẨM (32x32 ICONS SPECIFICATION)

- Toàn bộ Icon trang bị, đan dược, tài liệu được vẽ trên khung vuông trong suốt **$32 \times 32$ px**.
- Viền bao quanh ngoài (Outlines):
  - Vật phẩm thông thường: Viền mực tối `#24202a` hoặc `#3a3440` (1 pixel).
  - Trạng thái bùa lợi (Buff): Viền ngọc bích `#90c6aa` 1px bo góc.
  - Trạng thái bất lợi / Độc tố (Debuff): Viền chu sa `#c8483a` 1px bo góc.
- Tâm điểm của hình vẽ luôn căn chính giữa ô canvas (Center Aligned).

---

## 6. HƯỚNG DẪN DÀNH CHO SUBAGENT & HỌA SĨ

Khi được yêu cầu tạo thêm Sprite nhân vật hoặc kiến trúc mới:
1. Đọc tệp bảng màu `assets/palette.hex` — **tuyệt đối không dùng màu ngoài bảng này**.
2. Chọn đúng kích thước cell theo bảng quy chuẩn mục 3.1 hoặc 4.1.
3. Xác định rõ tọa độ **Foot Position `(foot_x, foot_y)`** và ghi nhận vào tệp metadata `.json` tương tự mẫu `swordsman/characters.json`.
4. Đảm bảo xuất texture định dạng PNG trong suốt (RGBA 8-bit), không có blur/anti-aliasing mờ đục.
