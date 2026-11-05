# THIẾT KẾ TÍCH HỢP: TINH HOA TIÊN NGHỊCH & ĐẠO TÀN: VẠN KIẾP
## Cẩm Nang Định Hướng Cốt Truyện, Cơ Chế Tu Luyện, Ý Cảnh & Nhân Quả
*Dành cho:* Đạo Tàn: Vạn Kiếp (Godot 4.7.2 GDScript Native Sandbox RPG)  
*Căn cứ tài liệu gốc:* `00_MASTER_PROMPT.md`, `02_GAME_VISION_GDD.md`, `03_WORLD_LORE.md`, `04_CULTIVATION_COMBAT.md`, `05_NPC_FACTION_SIMULATION.md`

---

## 1. NGUYÊN TẮC BẢN QUYỀN & TÔN CHỈ THIẾT KẾ (MASTER PROMPT GUARD)

> **Mệnh lệnh từ `00_MASTER_PROMPT.md`:**  
> *"Nhân vật, thế giới, nhiệm vụ, UI, asset đều **original**. Chỉ học cơ chế thiết kế từ Tale of Immortal và cảm giác thế giới khắc nghiệt của Tiên Nghịch; không copy tên riêng / đồ họa / lời thoại / tình tiết có bản quyền."*

Tài liệu này không sao chép nguyên mẫu Vương Lâm, Lý Mộ Uyển hay Chu Tước Tinh, mà **chắt lọc 5 tinh hoa cơ chế và triết lý sâu sắc nhất của Tiên Nghịch** để thổi hồn vào thế giới **Cửu Hoang Giới** của tựa game *Đạo Tàn: Vạn Kiếp*.

---

## 2. NĂM TRỤ CỘT TÍCH HỢP TỪ TIÊN NGHỊCH VÀO ĐẠO TÀN

```
                        ┌──────────────────────────────────────┐
                        │   ĐẠO TÀN: VẠN KIẾP (CỬU HOANG GIỚI)  │
                        │    Biến cố Đại Tĩnh Mạch • Đạo Tàn    │
                        └──────────────────┬───────────────────┘
                                           │
         ┌───────────────────┬─────────────┴───────┬────────────────────┐
         ▼                   ▼                     ▼                    ▼
┌─────────────────┐ ┌─────────────────┐ ┌──────────────────┐ ┌─────────────────┐
│ 1. ĐẠO TÂM &    │ │ 2. HÓA PHÀM     │ │ 3. SONG TU       │ │ 4. CẤM CHẾ      │
│ THẾ GIỚI KHẮC   │ │    Ý CẢNH       │ │    KHÍ - THỂ     │ │    CHI ĐẠO      │
│ NGHIỆT          │ │ (Ngộ Đạo Hóa    │ │ (Linh Pháp &     │ │ (Khắc Phù Văn   │
│ (Nghịch Tu Đạo) │ │  Thần Kỳ)       │ │  Cổ Hoang Thể)   │ │  Thời Gian/Phá) │
└─────────────────┘ └─────────────────┘ └──────────────────┘ └─────────────────┘
                                           │
                                           ▼
                        ┌──────────────────────────────────────┐
                        │ 5. NHÂN QUẢ TUYẾN & THẾ GIỚI BIẾT NHỚ │
                        │  (Ân oán lưu truyền • Báo ứng tháng)  │
                        └──────────────────────────────────────┘
```

---

### TRỤ CỘT 1: KHÔNG KHÍ THẾ GIỚI KHẮC NGHIỆT — "NGHỊCH THIÊN KHỞI NGUYÊN"

* **Triết lý Tiên Nghịch:** *"Thuận vi phàm, nghịch vi tiên, chỉ tại một niệm giữa sinh tử."*  
  Tiên đạo không có chuyện thiên vị; tài nguyên hữu hạn, thiên địa suy vi, kẻ muốn trường sinh buộc phải dẫm lên máu lửa và giữ vững đạo tâm.
* **Tích hợp vào Đạo Tàn:**
  * **Biến cố Đại Tĩnh Mạch:** Mạch linh khí thiên địa phân mảnh, cạn kiệt dần. Các đại phái (như Thanh Vi Tông) độc chiếm vùng lõi, đẩy phàm nhân và tán tu ra các vùng biên cằn cỗi (Thanh Trì Bình Nguyên, Rìa Vân Lĩnh).
  * **Đạo Tâm 4 Nhánh (`dao_path`):** Người chơi không bị gò bó vào chính/tà đơn giản mà định hình đạo lộ qua hành động:
    1. **Bảo Hộ:** Như Vương Lâm thủ hộ những người thân yêu cuối cùng, sẵn sàng vì người thân mà đối địch cả thiên hạ.
    2. **Truy Cầu:** Quyết tâm dòm ngó thiên đạo chân đế, bất chấp gian khổ.
    3. **Cân Bằng:** Thuận ứng tự nhiên, hóa giải ân oán.
    4. **Chấp Niệm:** Ôm giữ một tâm nguyện không dứt (báo thù tông môn, cứu người yêu, phục hưng gia tộc), tâm ma càng nặng thì chiến lực càng bùng nổ nhưng rủi ro tẩu hỏa nhập ma càng cao.

---

### TRỤ CỘT 2: CƠ CHẾ "HÓA PHÀM NGỘ ĐẠO" & HỆ THỐNG Ý CẢNH

* **Đặc sản Tiên Nghịch:** Đột phá Hóa Thần không thể chỉ cắn đan dược. Vương Lâm phải hóa phàm làm thợ khắc gỗ mấy chục năm, chứng kiến người phàm sinh lão bệnh tử mới ngộ ra *Sinh Tử Ý Cảnh*.
* **Tích hợp vào Đạo Tàn (Lộ trình Phase 3 - Phase 4):**
  * **Ải Đột Phá Nguyên Anh -> Hóa Thần:**
    * Khi tu vi chạm đỉnh Nguyên Anh, linh lực không thể tăng thêm bằng đan dược thông thường.
    * Người chơi mở tính năng **"Nhập Thế Hóa Phàm"**: Tự phong ấn 90% tu vi, quay trở về các khu dân cư phàm nhân (Thanh Trì Trấn hoặc thôn xóm phụ cận).
    * Nhận các công việc phàm tục qua hệ thống Life-Skill: Thợ mộc điêu khắc, Y sư bốc thuốc cứu người, Thầy đồ dạy chữ, Thợ săn rèn sắt.
  * **Tích lũy Điểm Cảm Ngộ (Comprehension Points):**
    * Khi chứng kiến một NPC bạn bè già đi qua đời -> Nhận cảm ngộ **Sinh Tử**.
    * Khi cứu giúp một gia đình khỏi nạn đói hoặc thú dữ -> Nhận cảm ngộ **Nhân Quả / Ân Tình**.
    * Khi chứng kiến cảnh tang thương hoang tàn sau thú triều -> Nhận cảm ngộ **Tịch Diệt / Luân Hồi**.
  * **Đúc Thành Ý Cảnh Độc Bản (Domain Aura):**
    * Khi cảm ngộ đủ 100%, người chơi thăng hoa lên **Hóa Thần Sơ Kỳ**, mở ra hào quang Ý Cảnh trong Đấu Trường Chiến Đấu:
      * *Ý Cảnh Sinh Tử:* Kẻ địch vào gần bị rút cạn sinh mệnh theo giây, người chơi hút máu hồi phục.
      * *Ý Cảnh Tịch Diệt:* Triệt tiêu hồi chiêu và làm suy giảm 40% giáp hộ thể của đối thủ.
      * *Ý Cảnh Luân Hồi:* Khi nhận đòn chí tử, có cơ hội chuyển hóa sát thương thành hồi sinh tức thì.

---

### TRỤ CỘT 3: SONG TU KHÍ - THỂ (LINH PHÁP & CỔ HOANG THỂ)

* **Ý tưởng Tiên Nghịch:** Vương Lâm song tu giữa Tiên Lực (pháp thuật, phi kiếm) và Nhục Thân Cổ Thần Cửu Tinh (sức mạnh bộc phá thể xác).
* **Tích hợp vào Đạo Tàn:**
  * Chia rõ 2 trường phái tu luyện có thể kết hợp:
    1. **Linh Tu (Khí Pháp):**
       - Tiêu hao Linh Lực (MP).
       - Tấn công tầm xa, phóng kiếm khí, lôi điện, mộc trói.
       - Thân thể yếu ớt, phụ thuộc vào cự ly và lướt né đòn.
    2. **Hoang Thể Tu (Cổ Tộc Luyện Thể):**
       - Dựa trên bí thuật của *Hoang Huyết Môn* và tàn tích *Cổ Hoang*.
       - Không tiêu hao MP mà tiêu hao **Khí Huyết (HP)** hoặc thanh **Kình Lực**.
       - Khai mở các khiếu huyệt trên cơ thể (Thập Nhị Kinh Mạch -> Cổ Hoang Thần Thể).
       - Kháng đòn đánh ngắt chiêu (Super Armor), áp sát đấm vỡ phi kiếm, tạo chấn động sóng xung kích diện rộng.
  * **Chiến thuật Song Tu:** Người chơi có thể build cân bằng: Vừa thả Kiếm Khí làm chậm, vừa dùng quyền kình Cổ Thể áp sát dứt điểm mục tiêu.

---

### TRỤ CỘT 4: CẤM CHẾ CHI ĐẠO (RESTRICTIONS SYSTEM)

* **Ý tưởng Tiên Nghịch:** Khác với Trận Pháp thông thường phải cắm cờ và rải đá, Cấm Chế là dùng ngón tay vẽ các đường cổ văn vô hình chồng chéo lên nhau để phong tỏa hoặc sát thương.
* **Tích hợp vào Đạo Tàn:**
  * **Trong chiến đấu:** Kỹ năng hệ Cấm Chế cho phép người chơi đặt các bẫy vô hình:
    * *Phá Diệt Cấm:* Khi kẻ địch giẫm vào sẽ kích nổ toàn bộ linh lực trong cơ thể chúng, gây sát thương tỉ lệ thuận với lượng MP của đối phương.
    * *Tuế Nguyệt Cấm:* Làm chậm 70% tốc độ di chuyển và thời gian thi triển kỹ năng của địch trong vùng ảnh hưởng.
    * *Tế Hạn Cấm:* Trói buộc linh hồn boss, ngăn chặn boss dùng chiêu thức cuồng nộ trong 3 giây.
  * **Trong thám hiểm:** Dùng cấm chế để giải phong ấn các Cổ Di Động thời tiền Tĩnh Mạch tại vùng núi Vân Lĩnh và sa mạc Huyết Sa Cốc.

---

### TRỤ CỘT 5: NHÂN QUẢ TUYẾN & THẾ GIỚI BIẾT NHỚ (DETERMINISTIC SIMULATION)

* **Ý tưởng Tiên Nghịch:** Ân oán rõ ràng; một ân tình trăm năm sau có người báo đáp, một mối thù ngàn dặm xa cũng bị truy tìm.
* **Tích hợp vào Đạo Tàn (`docs/05_NPC_FACTION_SIMULATION.md`):**
  * Dữ liệu quan hệ NPC có cấu trúc:
    `relationships[target_id] = { affinity, trust, fear, debt, grudge }`
  * **Hệ thống Nợ Nần (Karmic Debt):**
    * Khi người chơi tặng đan dược quý cứu sống NPC hoặc người thân của họ: NPC ghi nhận `debt > 0`.
    * Khi mô phỏng tháng (`AdvanceDays`), NPC có nợ sẽ ưu tiên tìm đến người chơi để dâng tặng khoáng thạch, báo tin bí cảnh hoặc đứng ra can ngăn tông môn truy sát người chơi.
  * **Hệ thống Oán Hận (Karmic Grudge):**
    * Nếu người chơi giết đệ tử tông môn có nhân chứng (`witness`), sự kiện `MemoryEvent` lan truyền. Thân nhân kẻ bị hại sẽ gom góp linh thạch thuê sát thủ Tán Tu Liên Hội truy sát người chơi tại dã ngoại.

---

## 3. LỘ TRÌNH ĐƯA TINH HOA TIÊN NGHỊCH VÀO CÁC PHASE

| Giai đoạn | Tính năng kế thừa từ Tiên Nghịch | Nội dung chi tiết |
| :---: | :--- | :--- |
| **Phase 1**<br>*(Đã xong)* | • Khắc nghiệt sinh tồn<br>• Telegraph cảnh báo boss<br>• Đột phá có điều kiện đan dược | • Đấu trường Vân Lĩnh, Boss Xích Kiếm Ma Thứu.<br>• Phàm Nhân -> Luyện Khí Tầng 1 đòi hỏi Tụ Khí Đan. |
| **Phase 2**<br>*(Kế tiếp)* | • Nhân quả tuyến (Karmic Debts)<br>• Mô phỏng tháng theo hạt giống<br>• Ân oán giang hồ & Tin đồn | • NPC tự di chuyển, bế quan, mua bán, thù hằn.<br>• Bảng tin thế giới mỗi tháng ghi nhận biến động nhân duyên. |
| **Phase 3** | • Hoang Thể Tu (Cổ Thể Luyện Thể)<br>• Cấm Chế Chi Đạo (Bẫy phù văn)<br>• Môn phái đối lập (Hoang Huyết Môn) | • Hệ thống điểm Khí Huyết và kỹ năng cận chiến quyền kình.<br>• Cấm chế giải phong ấn bí cảnh. |
| **Phase 4** | • Cơ chế "Hóa Phàm Lịch Lãm"<br>• Lĩnh ngộ Ý Cảnh (Hóa Thần)<br>• Thiên Kiếp & Ngũ Suy | • Nhập thế làm thợ mộc/y sư ngộ Sinh Tử/Nhân Quả.<br>• Đột phá Hóa Thần mở Hào Quang Ý Cảnh. |

---

## 4. KẾT LUẬN

Sự kết hợp giữa **tính triết lý, khắc nghiệt và sâu sắc của Tiên Nghịch** với **nền tảng kỹ thuật vững chắc, mô phỏng sandbox của Đạo Tàn: Vạn Kiếp** sẽ tạo nên một tựa game tiên hiệp Việt Nam độc đáo, không sáo rỗng, nơi mỗi người chơi tự viết nên con đường nghịch thiên tu đạo của riêng mình.
