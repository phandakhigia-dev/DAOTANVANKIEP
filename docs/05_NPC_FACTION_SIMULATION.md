# NPC AI, tông môn, kinh tế, nhân quả và world simulation

## 1. NPC data model
```
NPC { id, name, age_days, lifespan_days, position, home_id, sect_id, role,
      realm_tier, realm_stage, skills[], inventory[], money,
      traits{caution,greed,mercy,ambition,honor}, goals[], relationships{},
      memories[], schedule, alive, last_simulated_month, quest_flags{} }
```
NPC quan hệ `relationships[target_id]={affinity:-100..100, trust, fear, debt, grudge}`. **Không** lưu ma trận all-to-all; chỉ tạo cạnh quan hệ có ý nghĩa.

## 2. Memory & reputation
- `MemoryEvent`: actor_id, target_id, event_type, location_id, month, witnesses[], severity, is_public.
- Truy sát chỉ xuất hiện khi kẻ thù biết thông tin, có đường tác động hay đủ sức/tài nguyên.
- Tố cáo / cứu người / phản bội tạo cập nhật mối quan hệ theo witness + mức độ tin cậy tin đồn.
- Tin đồn có xác suất bị bóp méo, nhưng log debug lưu sự thật và nguồn tin để giải thích cơ chế.
- NPC có thể tha thứ sau thời gian, thiện chí hay bồi thường; một số tính cách cực đoan giữ thù lâu.

## 3. Mô phỏng tháng deterministic
```
AdvanceDays(days):
  if crossing_month_boundary:
     monthly_seed = hash(world_seed, year, month)
     for active_or_relevant_npc sorted by id:
        update needs + age + wound + cultivation
        choose ONE main intent (train/trade/quest/travel/relationship/fight/rest)
        resolve outcome by deterministic RNG + rules
     update faction economy + territories + open incidents
     apply consequential NPC event queue
     save MonthlySummary
```
Không dùng RNG toàn cục khó tái lập; mỗi NPC stream lấy `hash(seed, month, npc_id)`. Không tác động NPC chết hoặc bị giam giữ.

## 4. Utility AI
Ví dụ `score(action) = goal_weight + personality_modifier + opportunity - travel_cost - risk - cooldown`.
- Greed cao tăng trade, cướp hoặc mua tin nhưng vẫn bị ràng buộc vì sợ chết.
- Mercy cao giúp người gặp nạn; Ambition cao tranh quyền; Caution cao né đối thủ hơn 2 realm.
- Một NPC không thực hiện hai sự kiện mâu thuẫn cùng tháng; một lượt chính và các phản ứng thụ động.
- Khi NPC quest quan trọng chết: nhánh fail-state/recovery quest, không để cờ mục tiêu bất khả thi.

## 5. Phân cấp tính toán
- `Near` (cùng vùng): tick theo tương tác + theo tháng, pathfinding hợp lệ.
- `Far` (vùng khác): simulation aggregate chỉ theo tháng, không tạo sprite/node.
- `Dormant` (vùng khóa): chỉ cập nhật sự kiện nền được định nghĩa, tránh spawn vật phẩm vào vùng chưa có nội dung.
- Goal Alpha: 30–50 NPC / 12 tháng mô phỏng không freeze rõ; scale test 500–1,000 NPC ở headless không phải scope gameplay Alpha.

## 6. Tông môn
`Faction`: id, leader_id, school, territory_ids[], treasury, inventory, disciples[], relations{}, objectives[], reputation.
- Vai trò: khách khanh, đệ tử ngoại môn, nội môn, trưởng lão, chưởng môn; các cấp cao chỉ xuất hiện khi hệ quản lý đã làm.
- Vòng lặp: nhận nhiệm vụ -> lấy cống hiến -> đổi tài nguyên/bí kíp -> thi đấu -> nhận chức -> tác động quyền lực.
- Chiến tranh tông môn không phải click-to-win; tiêu hao lực lượng, ngân khố, hạ tầng và gây event quan hệ.
- Alpha: **1 tông môn hoạt động**, 2 phe còn lại dùng dữ liệu định nghĩa và sự kiện mô phỏng.

## 7. Kinh tế
- Linh thạch dùng mua bán; vật liệu có `base_price`, `scarcity`, `quality`, `region_modifier`.
- `price = base * scarcity_index * region_factor * reputation_discount` (clamp để tránh giá âm).
- Chợ tạo hàng từ supply pool và có giới hạn refresh theo tháng; tránh trò bán-mua vòng lặp vô hạn kiếm tiền.
- Dược liệu có provenance `source_id`, rarity, crafting requirements.

## 8. Kiểm thử tình huống AI
1. Người chơi cứu NPC -> tin cậy tăng và nhật ký ghi sự kiện.
2. Player giết NPC có người chứng kiến -> thân nhân nhận tin và thù tăng; không chứng kiến -> chỉ phát sinh tin khi có logic báo tin.
3. NPC thiếu tài nguyên -> không tự tạo item để đột phá.
4. Cùng seed, cùng hành động player -> 12 lần AdvanceMonth tạo cùng kết quả.
5. NPC chết -> remove schedule/interaction/active quests; mở fallback đúng trạng thái.
6. Một NPC không vừa chết vừa đến thăm trấn trong tháng.
7. Faction treasury không âm; chiến tranh và trade là transactions.
