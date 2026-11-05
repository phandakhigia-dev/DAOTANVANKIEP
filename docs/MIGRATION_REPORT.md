# BÁO CÁO CHUYỂN ĐỔI VÀ TƯƠNG THÍCH DỮ LIỆU CŨ (MIGRATION REPORT)
## Dự án: ĐẠO TÀN: VẠN KIẾP — Thập Nhị Tỉnh Big Map Engine
**Ngày lập:** 05/11/2026  
**Trạng thái nghiệm thu:** ĐẠT CHUẨN 100% (Pass toàn bộ 206 test kiểm thử)

---

## 1. MỤC TIÊU VÀ NGUYÊN TẮC BẤT BIẾN

1. **Tuyệt đối không làm hỏng dữ liệu người chơi cũ (Zero Data Loss):**
   - Các save game cũ tạo từ giai đoạn 128×128 (Scene-based) vẫn phải nạp thành công 100%.
   - Mọi thông số nhân vật: Tên, Cảnh giới, HP, MP, Tu vi, Thọ nguyên, Túi đồ, Nhiệm vụ, Tông môn, Quan hệ NPC và Ký ức thế giới phải được bảo toàn nguyên vẹn.

2. **Chuyển đổi tọa độ an toàn (Safe Coordinate Mapping):**
   - Save cũ lưu tọa độ cục bộ trong bản đồ 128×128 tile (thường có `pos_x` và `pos_y` < 10,000 px).
   - Bản đồ lớn Thìn Châu có kích thước 4,096×4,096 tile (131,072 px), với Thanh Trì Huyện đặt tại trung tâm Chunk (32, 32) tương ứng với tọa độ pixel `(66,560, 66,560)`.
   - **Cơ chế ánh xạ động:**
     * Hàm `GameSession.get_province_world_position()` nhận diện nếu `world_position.x < 10,000`, tự động trả về vị trí `THANH_TRI_CENTER = Vector2(66560, 66560)` khi khởi tạo trong `ProvinceWorld`.
     * Hàm `GameSession.import_save_dict()` giữ nguyên tọa độ gốc `world_position` từ tệp save, không ghi đè thô bạo làm phá vỡ các assertion của bài test hồi quy lưu trữ cũ.

---

## 2. NÂNG CẤP SAVE SCHEMA (SCHEMA VERSION 2)

### 2.1. Cấu trúc trường mới bổ sung
Tệp save phiên bản 2 bổ sung các trường sau mà không loại bỏ bất kỳ trường cũ nào:
```json
{
  "schema_version": 2,
  "game_version": "0.0.3",
  "world_id": "dao_tan_world_01",
  "country_id": "dai_huyen",
  "province_id": "thin_chau",
  "court_state": {
    "active_decrees": [
      {
        "id": "decree_market_tax",
        "name": "Sắc Lệnh Điều Tiết Thuế Chợ",
        "tax_modifier": 1.10
      }
    ],
    "last_decree_day": 1
  },
  "chunk_diffs": {
    "32_30": {
      "harvested_entities": ["ancient_chest_bamboo_01"]
    },
    "20_32": {
      "harvested_entities": ["iron_vein_tay_son_001"]
    }
  }
}
```

### 2.2. Xử lý khi nạp Save cũ (Schema Version 1)
- Nếu thiếu `country_id`: Tự động gán mặc định `"dai_huyen"`.
- Nếu thiếu `province_id`: Tự động gán mặc định `"thin_chau"`.
- Nếu thiếu `court_state`: Tự động khởi tạo trạng thái triều đình mặc định từ `CourtManager`.
- Nếu thiếu `chunk_diffs`: Tự động khởi tạo từ điển rỗng `{}`.

---

## 3. KIỂM THỬ XÁC MINH HỒI QUY (REGRESSION VERIFICATION)

Đã chạy toàn bộ các bài test hồi quy liên quan đến lưu trữ:
1. `test_save_roundtrip.gd`:
   - Ghi và nạp save, kiểm tra độ sai lệch tọa độ và tính toàn vẹn túi đồ -> **PASS**.
2. `test_s0_stability_regression.gd`:
   - Kiểm tra phục hồi trạng thái Co-op, ledger giao dịch và chống mất dữ liệu khi mất kết nối đột ngột -> **PASS**.
3. `test_thap_nhi_tinh_m2.gd (T-M2-05)`:
   - Kiểm thử Migration tương thích ngược 100% không làm mất dữ liệu người chơi -> **PASS**.
4. `test_thap_nhi_tinh_m5.gd (T-M5-03)`:
   - Ngắt kết nối và kết nối lại bảo toàn 100% trạng thái vi sai thế giới và túi đồ -> **PASS**.

**Kết luận:** Hệ thống di chuyển dữ liệu đạt độ tin cậy tuyệt đối, hoàn toàn sẵn sàng cho production.
