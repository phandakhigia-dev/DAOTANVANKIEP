# BÁO CÁO ĐÁNH GIÁ TÁC ĐỘNG TÁI CẤU TRÚC BẢN ĐỒ (MAP RESTRUCTURE IMPACT REPORT)
## DỰ ÁN: ĐẠO TÀN: VẠN KIẾP — THẬP NHỊ TỈNH / BIG MAP MASTER PLAN V1

**Thời gian lập:** 2026-11-05  
**Tác giả:** Lead Godot Engineer & Systems Architect  
**Mục tiêu:** Đánh giá toàn diện các module, data schemas, save/load, co-op hiện hữu trước khi tiến hành chuyển đổi từ kiến trúc màn chơi nhỏ rời rạc sang **Tỉnh Mở Liền Mạch (Thìn Châu - 4096×4096 tile)** thuộc **Đại Huyền Quốc (12 Tỉnh)**.

---

### I. HIỆN TRẠNG KIẾN TRÚC & CÁC MODULE LIÊN QUAN

| Thành phần hiện hữu | Đường dẫn mã nguồn | Trạng thái hiện tại | Tác động khi chuyển sang Thập Nhị Tỉnh |
|---|---|---|---|
| **Đại Bản Đồ (WorldMap)** | `scenes/world/world_map.gd` | Lưới 50×40 cell (3200×2560 px), vẽ trực tiếp bằng `_draw()`, click [E] để chuyển sang các scene con rời rạc. | Chuyển đổi thành bộ nạp động (Chunk Streamer 64×64) hiển thị Thìn Châu (4096×4096 tile). Giữ nguyên logic POI nhưng mở rộng thành tọa độ toàn tỉnh. |
| **Thanh Trì Trấn** | `scenes/towns/town_map_real.gd` | Scene 32×22 tile (1024×704 px) độc lập với 8 tòa nhà võ hiệp, sạp hàng, NPC. | Tích hợp thành Huyện Thành Thanh Trì nằm liền mạch tại cụm Chunk trung tâm của Thìn Châu; không còn màn hình loading khi bước qua cổng thành. |
| **Các Vùng Bí Cảnh** | `scenes/biomes/bamboo_forest.gd`, `snake_swamp.gd`, `sword_grave.gd` | Các scene độc lập 1024×704 px. | Tích hợp thành các phân khu tự nhiên (Bắc Lâm, Nam Đầm, Tây Cốc) nằm trên đại bản đồ Thìn Châu. |
| **Đăng ký Dữ liệu** | `scripts/core/content_registry.gd` | Nạp `regions/region_thanh_tri.json`. | Mở rộng nạp `data/world/world_registry.json`, `data/world/countries/`, `data/world/provinces/` song song, không làm gãy các hàm cũ `get_region()`. |
| **Quản lý Phiên Chơi** | `scripts/core/game_session.gd` | Lưu `current_region_id: "reg_thanh_tri"`, `world_position`, `town_position`. | Bổ sung `current_province_id: "thin_chau"`, `chunk_diffs: {}`. Migration tự động nhận diện save v2 để gán giá trị mặc định. |
| **Lưu Trữ Bền Vững** | `scripts/persistence/save_service.gd` | Schema Version 2, Atomic write `.tmp` $\rightarrow$ `.json` kèm `.bak.json`. | Nâng cấp Schema Version 3, duy trì tương thích ngược 100% với Schema v1 và v2. |
| **Mạng & Đồng Bộ Co-op** | `scripts/network/coop_world_sync.gd` | Host-Authoritative, ENet RPCs, chống duping, ví tiền/kho sạp hàng do Host kiểm soát. | Giữ nguyên quy chuẩn 720s/ngày thực, bổ sung lọc tầm nhìn (Interest Management theo Chunk) để giảm tải băng thông mạng khi người chơi ở xa nhau. |

---

### II. NGUYÊN TẮC THIẾT KẾ & KHÔNG GÂY ĐỔ VỠ (NON-BREAKING CONTRACTS)

1. **Bảo tồn toàn bộ hệ thống Gameplay cốt lõi:**
   - Hệ thống tu luyện 10 tầng cảnh giới, đột phá Lôi Kiếp, tuổi thọ và thọ nguyên giữ nguyên 100%.
   - Hệ thống chiến đấu Action Top-Down (Trảm kiếm, Kiếm khí Kim hệ, Lôi quang phá, Khinh công Dash i-frame) giữ nguyên 100%.
   - Kinh tế sạp hàng chợ Tán Tu (Escrow, Idempotency, Host Wallet Revision) giữ nguyên 100%.
   - 179/179 Unit Tests hiện có phải tiếp tục PASS mà không sửa đổi mock để che lỗi.

2. **Quy chuẩn Không Gian & Tọa Độ Thìn Châu:**
   - **Tỉnh Thìn Châu:** $4.096 \times 4.096$ tile logical, tile $32 \times 32$ px = $131.072 \times 131.072$ px logical.
   - **Chunk Chuẩn:** $64 \times 64$ tile = $2.048 \times 2.048$ px. Tổng cộng $64 \times 64 = 4.096$ Chunk.
   - **Tọa độ Trung tâm Huyện Thanh Trì:** Tọa độ tile $(2048, 2048)$ tương ứng Chunk $(32, 32)$.
   - **Bán kính nạp động (Streaming Window):** Nạp bán kính 1–2 chunk quanh camera người chơi (tối đa 9–16 chunk hiển thị đồng thời), giữ RAM $\le 300\text{ MB}$, tránh lỗi tràn int16 của Godot và tụt FPS.

3. **Kế hoạch Di Cư Dữ Liệu Save (Save Migration Matrix):**
   - Save cũ (Schema v1, v2):
     - `region_id == "reg_thanh_tri"` $\rightarrow$ Tự động map sang `province_id = "thin_chau"`.
     - `world_position` cũ $\rightarrow$ Tự động chuyển đổi sang tọa độ thế giới mới tại Thanh Trì Huyện.
     - `chunk_diffs` $\rightarrow$ Khởi tạo dictionary rỗng `{}`.
   - Không xóa, không làm hỏng file save cũ của người chơi; luôn lưu file dự phòng `.bak.json`.

---

### III. LỘ TRÌNH THỰC THI (MILESTONE EXECUTION PLAN)

- **M1:** Xây dựng National Registry & Court Skeleton (12 tỉnh metadata, Đại Huyền Quốc, sắc lệnh triều đình, unit test 100% pass).
- **M2:** Xây dựng Chunk Streamer $64 \times 64$ và lát lõi trung tâm $512 \times 512$ tile (Thanh Trì, Rừng Trúc, Đầm Lầy, Kiếm Trũng liền mạch không màn hình chuyển cảnh).
- **M3:** Hoàn thiện hạ tầng Long Kinh, mạng lưới đường lộ, trạm dịch xe ngựa, 2 môn phái và các điểm cơ duyên mở.
- **M4:** Tích hợp Sắc Lệnh Triều Đình vận hành thực tế (thuế chợ, truy nã) và hệ thống lưu trữ Sparse Chunk Diffs.
- **M5:** Stress test đa tiến trình Co-op (Host + Clients ở khác Chunk), đo đạc RAM/FPS, cập nhật tài liệu và đóng gói ZIP kiểm toán mới.
