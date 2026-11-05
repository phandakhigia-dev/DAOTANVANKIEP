# MA TRẬN KIỂM THỬ TOÀN DIỆN V3 — ĐẠO TÀN: VẠN KIẾP

**Ngày thực hiện:** 05/11/2026  
**Tổng số Unit Tests:** 179/179 PASS (100%)  
**Tổng số Integration Tests Mạng:** 2 Tiến Trình (10/10 PASS) + 3 Tiến Trình (Race Condition PASS)  

---

## 1. MA TRẬN CÁC BỘ KIỂM THỬ ĐƠN VỊ (UNIT TEST SUITES)

| STT | Tên Suite | File GDScript | Số Test | Kết quả | Mô tả nội dung kiểm thử |
|:---:|---|---|:---:|:---:|---|
| 1 | **GameClock** | `test_game_clock.gd` | 5 | **PASS** | Khởi tạo ngày/tháng/năm, chu kỳ 30 ngày/tháng, 12 tháng/năm, tính toán Canh giờ |
| 2 | **GameClock Realtime** | `test_game_clock_realtime.gd` | 4 | **PASS** | Chuẩn hóa 1 ngày in-game = 720 giây thực (12 phút), tỉ lệ 1:120, advance realtime |
| 3 | **Deterministic Seed** | `test_deterministic_seed.gd` | 4 | **PASS** | Kiểm tra tính xác định của seed thế giới, cùng seed cho cùng kết quả RNG |
| 4 | **Save Roundtrip** | `test_save_roundtrip.gd` | 5 | **PASS** | Ghi/đọc file save JSON nguyên tử, schema version 2, cơ chế backup phục hồi an toàn |
| 5 | **Phase 1 Inventory** | `test_phase1_inventory.gd` | 5 | **PASS** | Thêm, bớt vật phẩm, kiểm tra số lượng, xếp chồng (stacking) và lọc loại vật phẩm |
| 6 | **Phase 1 Breakthrough** | `test_phase1_breakthrough.gd` | 5 | **PASS** | Đột phá Luyện Khí Tầng 1 đến Tầng 9, cập nhật thuộc tính HP/MP/Atk/Def theo cảnh giới |
| 7 | **Phase 1 Quest Flow** | `test_phase1_quest_flow.gd` | 5 | **PASS** | Nhận, tiến triển và hoàn thành nhiệm vụ, phát thưởng linh thạch và vật phẩm |
| 8 | **Phase 1 NPC Affinity** | `test_phase1_npc_affinity.gd` | 5 | **PASS** | Thay đổi điểm thiện cảm NPC, kiểm tra các mốc quan hệ (Bằng Hữu, Túc Địch) |
| 9 | **Phase 2 Deterministic Sim**| `test_phase2_deterministic_simulation.gd` | 6 | **PASS** | Mô phỏng tháng theo hash kết hợp, tính xác định tuyệt đối qua 12 tháng liên tiếp |
| 10| **Phase 2 NPC Social Graph** | `test_phase2_npc_social_graph.gd` | 6 | **PASS** | Mạng lưới quan hệ xã hội NPC, tương tác ơn oán (debt/grudge) và nhân chứng |
| 11| **Phase 2 NPC Lifecycle** | `test_phase2_npc_lifecycle.gd` | 6 | **PASS** | Vòng đời NPC: tuổi thọ, lão hóa, đột phá cảnh giới, thương tật và tử vong |
| 12| **Phase 2 Headless Stress** | `test_phase2_headless_stress.gd` | 4 | **PASS** | Stress test mô phỏng 500 đến 1,000 NPC không giao diện, đo thời gian xử lý (<150ms) |
| 13| **Co-op Clock Sync** | `test_coop_clock_sync.gd` | 5 | **PASS** | Đồng bộ đồng hồ giữa Host và Client, Client không tự ý tua thời gian trong co-op |
| 14| **Phase 3 Alchemy** | `test_phase3_alchemy.gd` | 6 | **PASS** | Luyện đan dược (Hồi Xuân Đan, Tẩy Tủy Đan), kiểm tra công thức, dược liệu và tỉ lệ |
| 15| **Phase 3 Bosses** | `test_phase3_bosses.gd` | 6 | **PASS** | Cơ chế Boss Xích Kiếm Ma Thứu: máu, giai đoạn cuồng bạo, kỹ năng telegraph và loot |
| 16| **Phase 3 Shop** | `test_phase3_shop.gd` | 6 | **PASS** | Thuê sạp hàng chợ tán tu 3 ngày, ký gửi hàng hóa vào escrow, rút hàng và quyết toán |
| 17| **Living Town & NPC** | `test_living_town_and_procedural_npc.gd` | 7 | **PASS** | Thị trấn sống động: lịch trình NPC theo canh giờ, hội thoại đa dạng, mua bán sạp |
| 18| **Phase 2 Biomes & Dungeons**| `test_phase2_biomes_and_dungeons.gd` | 8 | **PASS** | Khám phá 4 biome (Rừng Trúc, Đầm Lầy, Kiếm Mộ, Núi Tuyết) và dungeon bí cảnh |
| 19| **Phase 3 Sects & Tribulation**| `test_phase3_sects_and_tribulation.gd`| 10 | **PASS** | Gia nhập tông môn Thanh Vi Kiếm Tông, Tàng Kinh Các, Thiên Kiếp Lôi Đình Trúc Cơ |
| 20| **Phase 4 Audio & VFX** | `test_phase4_audio_and_vfx.gd` | 8 | **PASS** | Âm thanh SFX/BGM, hiệu ứng kiếm khí, sấm sét thiên kiếp, hào quang tu vi (Aura) |
| 21| **Branching Dialogue** | `test_branching_dialogue_and_world_shaping.gd` | 8 | **PASS** | Cây hội thoại phân nhánh 3-5 lựa chọn, tạo hệ quả bí mật kiến tạo thế giới |
| 22| **Sprint S0 Stability** | `test_s0_stability_regression.gd` | 14 | **PASS** | Hồi quy độ ổn định tổng thể, chống crash khi nạp scene, quản lý bộ nhớ |
| 23| **P0 V2 Regression** | `test_p0_v2_regression.gd` | 11 | **PASS** | Khóa time_scale 1x, loại bỏ phím Space nhảy ngày, ranh giới 23:59/tháng/năm |
| 24| **P0 V3 Authoritative Economy**| `test_p0_v3_authoritative_economy.gd` | 7 | **PASS** | Chống duping, ví giả, RPC retry 3x, race condition 2 client, reconnect |

**TỔNG CỘNG:** **179/179 TESTS PASS (100%)**

---

## 2. MA TRẬN TEST CHI TIẾT S0 — KINH TẾ AUTHORITATIVE & CHỐNG DUPING

| Mã Test | Mục Tiêu Kiểm Thử | Tình Huống Kích Hoạt | Kết Quả Mong Đợi | Kết Quả Thực Tế |
|---|---|---|---|---|
| **T-V3-01** | Duplicate Response 3x | Client nhận 3 lần response `success` từ cùng 1 transaction | Tài sản chỉ áp dụng đúng 1 lần; 2 lần sau bị loại bỏ do `rev <= local_rev` | **PASS** (Ví 170 LT, Item x1) |
| **T-V3-02** | RPC Retry 3x | Client bị lag mạng gửi 3 lần cùng 1 `request_id` lên Host | Host chỉ trừ tiền và trừ kho đúng 1 lần duy nhất qua Idempotency | **PASS** (Ví -50 LT, Kho -1) |
| **T-V3-03** | Chống Gian Lận Ví | Client khai có 999 triệu LT, ví Authoritative chỉ có 30 LT | Host từ chối giao dịch mua món 80 LT, không tin client | **PASS** (Bị từ chối an toàn) |
| **T-V3-04** | Race Condition 2 Client | 2 Client gửi request đồng thời mua món hàng cuối cùng | Đúng 1 client mua được, client kia nhận thông báo hết hàng, kho cạn về 0 không âm | **PASS** (Kho = 0, Rev = +150 LT) |
| **T-V3-05** | Disconnect & Reconnect | Client mua hàng xong ngắt kết nối rồi kết nối lại | Sổ cái Authoritative trên Host bảo lưu toàn vẹn tài sản của Client | **PASS** (Bảo lưu 60 LT và 2 Đan) |
| **T-V3-06** | Rollback An Toàn | Mua item không tồn tại trong sạp | Kho hàng và doanh thu Host được bảo lưu 100%, không phát sinh biến đổi | **PASS** (Doanh thu không đổi) |
| **T-V3-07** | Boundary Checks | Gửi số lượng âm (-5), bằng 0, tràn số (9,999,999), item rỗng | Host chặn đứng 100% các giá trị dị thường, không ghi nhận giao dịch | **PASS** (Chặn toàn bộ 4 ca) |

---

## 3. MA TRẬN KIỂM THỬ CO-OP ĐA TIẾN TRÌNH THỰC TẾ

| Kịch Bản | Cấu Hình Tiến Trình | Cổng | Kiểm Tra Trọng Tâm | Kết Quả |
|---|---|---|---|---|
| **2 Tiến Trình (Host + Client)** | `coop_two_peers_runner.tscn` | 8899 | Khóa 1x time_scale, đồng bộ avatar, sát thương boss, mua sạp, snapshot tháng, disconnect/reconnect | **10/10 BƯỚC PASS** (Exit 0) |
| **3 Tiến Trình (Host + Client 1 + Client 2)** | `coop_multi_client_live.tscn` | 8899 | 3 cửa sổ đồ họa thật, render 3 avatar đồng đạo trên WorldMap, tranh mua món cuối (Race Condition) đồng thời | **3/3 TIẾN TRÌNH PASS** (Exit 0, 3 ảnh chụp thật) |

---

## 4. LỆNH TÁI HIỆN VÀ CHẠY TOÀN BỘ KIỂM THỬ

```powershell
# 1. Chạy toàn bộ 179 Unit Tests và lưu log thô:
python tools/run_tests_capture_raw.py

# 2. Chạy kiểm thử Co-op 2 tiến trình độc lập:
python tools/test_coop_two_peers.py

# 3. Chạy kiểm thử Co-op 3 cửa sổ thật & Race Condition:
python tools/test_coop_gameplay_live.py

# 4. Chụp toàn bộ 8 ảnh nghiệm thu đồ họa (kèm UI Shop thật):
& "tools\godot\godot.cmd" --path . --scene res://tools/capture_graphics_after.tscn
```
