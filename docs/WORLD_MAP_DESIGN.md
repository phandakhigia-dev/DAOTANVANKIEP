# TÀI LIỆU THIẾT KẾ ĐẠI BẢN ĐỒ THẬP NHỊ TỈNH ĐẠI HUYỀN QUỐC
## (WORLD MAP ARCHITECTURE & SPATIAL SPECIFICATIONS)
**Dự án:** ĐẠO TÀN: VẠN KIẾP  
**Phiên bản kiến trúc:** Seamless World Engine v1.0 (Godot 4.7.2)  
**Tỉnh thí điểm đầu tiên:** Thìn Châu (Dragon Province — Trung Tâm Văn Hiến & Đô Hội)

---

## 1. TỔNG QUAN KHÔNG GIAN ĐẠI HUYỀN QUỐC

Đại Huyền Quốc là một liên bang tu tiên - triều đình gồm **12 Tỉnh** tương ứng với **Thập Nhị Địa Chi**:
- **Tý Châu:** Bắc Cực Băng Nguyên (Cực hàn, băng phách, Tông môn Băng Phách Cung).
- **Sửu Châu:** Canh Nông Thảo Nguyên (Đất đai màu mỡ, ngự thú, chăn thả linh thú).
- **Dần Châu:** Hổ Khiếu Sơn Lâm (Rừng rậm nguyên sinh, linh mộc nghìn năm).
- **Mão Châu:** Dược Thảo Thung Lũng (Thánh địa dược thảo, Bách Thảo Môn tổng đàn).
- **Thìn Châu (Đương kim kinh kỳ):** Trung tâm chính trị, văn hiến, kinh đô Long Kinh & đại thương cảng.
- **Tỵ Châu:** U Minh Đầm Lầy (Độc trùng, chướng khí, hắc xà cổ địa).
- **Ngọ Châu:** Xích Diễm Hoang Mạc (Cực nhiệt, hỏa linh, núi lửa hoạt động).
- **Mùi Châu:** Thanh Phong Sơn Lĩnh (Vách đá cheo leo, linh dương, ngọc bích phong thủy).
- **Thân Châu:** Hầu Viên Hoa Quả (Rừng tiên đào, vượn trắng thông linh).
- **Dậu Châu:** Kim Kê Cương Lĩnh (Khoáng mạch hoàng kim, huyền thiết ngút ngàn).
- **Tuất Châu:** Khuyển Nha Cổ Thành (Biên ải hiểm trở, trận pháp phòng thủ biên cương).
- **Hợi Châu:** Trạch Thủy Nam Hải (Vùng sông nước, hải đảo, giao long xuất hiện).

---

## 2. QUY CHUẨN KỸ THUẬT VÀ TOÁN HỌC KHÔNG GIAN

### 2.1. Đơn vị đo đạc
- **1 Tile:** 32 × 32 pixels.
- **1 Chunk:** 64 × 64 tiles = 2,048 × 2,048 pixels.
- **1 Tỉnh (Province):** 64 × 64 chunks = 4,096 × 4,096 tiles = 131,072 × 131,072 pixels.
- **Tốc độ di chuyển người chơi:** 160 px/giây (khoảng 5 tile/giây). Đi bộ xuyên suốt 1 chunk mất ~12.8 giây. Đi xuyên một tỉnh mất ~13.6 phút thực.

### 2.2. Công thức chuyển đổi tọa độ (Spatial Coordinate Mapping)
Hệ thống sử dụng các hàm chuyển đổi toán học nguyên tử không phân mảnh:
```gdscript
# Pixel thế giới -> Tọa độ Chunk
func world_to_chunk(pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(pos.x / (64.0 * 32.0))),
        int(floor(pos.y / (64.0 * 32.0)))
    )

# Tọa độ Chunk -> Pixel gốc góc trên-trái của Chunk
func chunk_to_world(chunk_coord: Vector2i) -> Vector2:
    return Vector2(
        float(chunk_coord.x * 64 * 32),
        float(chunk_coord.y * 64 * 32)
    )

# Tọa độ Tile -> Pixel thế giới
func tile_to_world(tile_x: int, tile_y: int) -> Vector2:
    return Vector2(tile_x * 32.0 + 16.0, tile_y * 32.0 + 16.0)
```

---

## 3. CƠ CHẾ NẠP ĐỘNG LIỀN MẠCH (SEAMLESS CHUNK STREAMING)

### 3.1. Cửa sổ nạp 3×3 Active Window
- `ChunkStreamer` giám sát vị trí người chơi theo chu kỳ ngắn.
- Xác định chunk hiện tại của người chơi: `current_chunk`.
- Duy trì cố định **9 Chunks (cửa sổ 3×3 quanh người chơi)**:
  ```
  [cx - 1, cy - 1]  [cx, cy - 1]  [cx + 1, cy - 1]
  [cx - 1, cy    ]  [cx, cy    ]  [cx + 1, cy    ]
  [cx - 1, cy + 1]  [cx, cy + 1]  [cx + 1, cy + 1]
  ```
- Khi người chơi bước qua ranh giới chunk:
  - 3 Chunk phía sau lưng được `queue_free()` tự động để dọn dẹp RAM.
  - 3 Chunk phía trước được tải tức thời và gán vào cây Node.
  - **Số node hoạt động luôn duy trì ~100 - 200 nodes**, tiêu thụ RAM dưới **180 MB**, đạt chuẩn **60 FPS** ổn định trên mọi cấu hình.

### 3.2. Lưu trạng thái vi sai (Sparse Chunk Diffs)
Để đảm bảo thế giới 4096×4096 không gây phình to dung lượng tệp Save:
- Chỉ lưu lại các thay đổi thực tế so với mẫu gốc (đã hái thảo dược, đã mở rương cổ, đã đào quặng).
- Cấu trúc: `GameSession.chunk_diffs[chunk_key] = { "harvested_entities": ["ore_01", "chest_02"] }`.
- Khi chunk được nạp lại (hoặc người chơi reconnect trong Co-op), hệ thống kiểm tra vi sai và ẩn đi các thực thể đã tiêu thụ, ngăn chặn triệt để hiện tượng duping và khai thác tài nguyên vô hạn.

---

## 4. QUY HOẠCH CÁC VÙNG ĐẶC TRƯNG TẠI THÌN CHÂU

| Tọa độ Chunk | Tên Khu Vực / Địa Danh | Loại Địa Hình | Công Trình & Điểm Tương Tác |
| :---: | :--- | :--- | :--- |
| **(32, 32)** | **Huyện Thành Thanh Trì** | Đô thị cổ | Phố chợ, Lầu các, Trạm ngựa, Sạp tu sĩ, Lò luyện đan |
| **(32, 16)** | **Kinh Đô Long Kinh** | Hoàng thành | Hoàng Cung Đại Huyền, Lục Bộ Nha Môn, Cấm Vệ Doanh, Đấu Giá Đường |
| **(20, 32)** | **Trại Mỏ Tây Sơn** | Vách đá khoáng thạch | Lò rèn Tây Sơn, Lán thợ mỏ, Quặng huyền thiết, Cự thạch bia |
| **(32, 30)** | **Bí Cảnh Rừng Trúc Vạn Lĩnh**| Rừng trúc thạch động | Trúc già, Thạch động, Rương cổ bí cảnh |
| **(31, 33)** | **Độc Trạch Hắc Xà** | Đầm lầy độc khí | Cổ mộc mục nát, Tế đàn xà vương, Thảo dược u minh |
| **(33, 32)** | **Cổ Kiếm Trũng** | Chiến trường xưa | Tàn đài, Cự kiếm gãy, Kiếm bia đốn ngộ tu vi |
| **(31, 34)** | **Thôn Đồng Nội** | Nông thôn thanh bình | Nhà tranh, Thửa ruộng lúa nước, Giếng làng, Cây đa cổ |

---

## 5. MẠNG LƯỚI GIAO THÔNG VÀ DỊCH TRẠM NGỰA

1. **Bắc Nam Đại Quan Lộ (North-South Imperial Highway):**
   - Rộng 4 tile, lát đá xanh nhẵn.
   - Nối liền từ Thôn Đồng Nội -> Huyện Thành Thanh Trì -> Trúc Lâm -> Kinh Đô Long Kinh.
   - Người chơi di chuyển trên đường lộ không bị giảm tốc độ bởi chướng ngại vật tự nhiên.

2. **Dịch Trạm Ngựa (Horse Relay Stations):**
   - Đặt tại Thanh Trì, Long Kinh, Tây Sơn, Đồng Nội.
   - Cho phép di chuyển nhanh có thu phí linh thạch và tiêu tốn thời gian in-game (mô phỏng lộ trình thực tế, không teleport tức thời phi logic).
   - Bảng cước phí:
     * Thanh Trì <-> Long Kinh: 25 Linh Thạch, 4 giờ in-game.
     * Thanh Trì <-> Tây Sơn: 15 Linh Thạch, 2.5 giờ in-game.
     * Thanh Trì <-> Đồng Nội: 5 Linh Thạch, 1 giờ in-game.

---

## 6. SẮC LỆNH TRIỀU ĐÌNH & KINH TẾ QUỐC GIA

Mỗi tỉnh chịu sự điều phối chung của Hoàng Triều Đại Huyền:
- **Sắc lệnh Thuế Chợ:** Điều chỉnh mức phí thuê sạp của tu sĩ (50 LT -> 55 LT khi tăng 10% thuế).
- **Sắc lệnh Trảm Yêu:** Tăng 25% linh thạch thưởng cho các nhiệm vụ săn quái trừ tà trên toàn bờ cõi.
- **Sắc lệnh Bình Ổn Dược Liệu & Lương Thực:** Chiết khấu 15% khi giao thương cứu trợ thiên tai.
- Chu kỳ triều đình tự động ban bố sắc lệnh mới sau mỗi 6 tháng in-game dựa trên biến động kinh tế và thiên tai dị tượng của các châu quận.
