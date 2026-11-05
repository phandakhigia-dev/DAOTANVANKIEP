extends Node

## MonthlySimulationService — Bộ máy mô phỏng thế giới và NPC tự hành theo tháng
## Tuân thủ chuẩn mực:
##   - Deterministic Seed Stream: hash(world_seed, year, month, npc_id).
##   - Cùng seed + cùng lựa chọn -> cùng kết quả 100% qua 12 tháng.
##   - Mô phỏng vòng đời (tuổi thọ, đột phá, thương tật, tử vong).
##   - Utility AI: 7 ý định (train, trade, quest, travel, relationship, fight, rest).
##   - Ký ức, nhân chứng, ân oán (debt, grudge) và tin đồn.
##   - Hỗ trợ stress test headless 500 - 1,000 NPC đo thời gian xử lý.

const LOCATIONS: Array[String] = [
	"poi_thanh_tri_tran",
	"poi_rung_truc",
	"loc_van_linh",
	"loc_u_minh_coc",
	"loc_bach_thao_linh"
]

const LOCATION_NAMES: Dictionary = {
	"poi_thanh_tri_tran": "Thị Trấn Thanh Trì",
	"poi_rung_truc": "Rừng Trúc U Tịch",
	"loc_van_linh": "Rặng Núi Vân Lĩnh",
	"loc_u_minh_coc": "U Minh Huyết Cốc",
	"loc_bach_thao_linh": "Bách Thảo Lĩnh"
}

func _ready() -> void:
	if EventBus and EventBus.has_signal("month_advanced"):
		EventBus.month_advanced.connect(_on_month_advanced)

func _on_month_advanced(month: int, year: int) -> void:
	# Chỉ Server/Host mới thực thi mô phỏng thế giới hàng tháng, tránh client desync
	if SessionAuthority and not SessionAuthority.is_server_authoritative():
		return
	if GameSession and GameSession.is_session_active:
		var summary = simulate_month(month, year)
		if CoopWorldSync and SessionAuthority.is_coop_session():
			CoopWorldSync.host_broadcast_month_simulation(month, year, {
				"summary": summary,
				"world_npcs": GameSession.world_npcs,
				"memory_events": GameSession.memory_events
			})

## Hàm băm xác định số nguyên (Deterministic 64-bit Hash)
static func hash_combine(seed_val: int, a: int, b: int, c: int = 0) -> int:
	var h = (seed_val ^ (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) & 0x7FFFFFFF
	h = ((h >> 16) ^ h) * 0x45d9f3b
	h = ((h >> 16) ^ h) * 0x45d9f3b
	h = (h >> 16) ^ h
	return abs(h)

static func hash_string(text: String) -> int:
	var h: int = 5381
	for i in range(text.length()):
		h = ((h << 5) + h) + text.unicode_at(i)
		h = h & 0x7FFFFFFF
	return abs(h)

## Chạy mô phỏng chính cho 1 tháng
func simulate_month(month: int, year: int, custom_npcs: Dictionary = {}) -> Dictionary:
	var npcs_map = custom_npcs if not custom_npcs.is_empty() else GameSession.world_npcs
	var world_seed = GameSession.world_seed if GameSession else 1337
	var month_seed = hash_combine(world_seed, year, month, 101)
	
	var summary: Dictionary = {
		"month": month,
		"year": year,
		"breakthroughs": [],
		"deaths_and_wounds": [],
		"major_incidents": [],
		"rumors_and_gossip": [],
		"market_trends": []
	}
	
	# Thu thập và sắp xếp NPC theo id để thứ tự xử lý là 100% Deterministic
	var sorted_npc_ids: Array = npcs_map.keys()
	sorted_npc_ids.sort()
	
	var npcs_to_simulate: Array[Dictionary] = []
	for nid in sorted_npc_ids:
		var npc = npcs_map[nid]
		if npc.get("alive", true):
			npcs_to_simulate.append(npc)
	
	for npc in npcs_to_simulate:
		var nid = npc.get("id", "")
		var npc_seed = hash_combine(month_seed, hash_string(nid), 202)
		
		# 1. Cập nhật tuổi tác & Thọ nguyên
		var age_days = npc.get("age_days", 30 * 360) + 30
		npc["age_days"] = age_days
		var lifespan_days = npc.get("lifespan_days", 120 * 360)
		
		if age_days >= lifespan_days:
			npc["alive"] = false
			var death_msg = "Đạo hữu %s (%s) thọ nguyên cạn kiệt, an tường tọa hóa tại %s." % [
				npc.get("name", "Vô Danh"),
				npc.get("realm_name", "Phàm Nhân"),
				LOCATION_NAMES.get(npc.get("location", ""), "Sơn Dã")
			]
			summary["deaths_and_wounds"].append(death_msg)
			if GameSession:
				GameSession.log_memory_event(nid, "", "death_old_age", npc.get("location", ""), [], 2, true)
			continue
			
		# 2. Tiến trình Tu Vi & Đột phá cảnh giới
		var traits = npc.get("traits", { "caution": 50, "greed": 50, "mercy": 50, "ambition": 50, "honor": 50 })
		var cur_xp = npc.get("cultivation_xp", 0)
		var gain_xp = 10 + int((traits.get("ambition", 50) * 0.15)) + (npc_seed % 10)
		cur_xp += gain_xp
		
		if cur_xp >= 100:
			# Thử nghiệm Đột Phá Cảnh Giới
			var success_rate = clampi(45 + int(traits.get("ambition", 50) * 0.3) - int(traits.get("caution", 50) * 0.1), 25, 85)
			var roll = npc_seed % 100
			if roll < success_rate:
				# Đột phá thành công
				cur_xp = 0
				var old_stage = npc.get("realm_stage", 1)
				var new_stage = old_stage + 1
				npc["realm_stage"] = new_stage
				
				# Nâng cấp tên cảnh giới
				var tier = npc.get("realm_tier", 1)
				if new_stage > 9 and tier == 1:
					npc["realm_tier"] = 2
					npc["realm_stage"] = 1
					npc["realm_name"] = "Trúc Cơ Sơ Kỳ"
					npc["lifespan_days"] += 130 * 360 # Tăng thêm 130 năm thọ nguyên
				else:
					if tier == 1:
						npc["realm_name"] = "Luyện Khí Tầng %d" % new_stage
					elif tier == 2:
						var stage_names = ["Sơ Kỳ", "Trung Kỳ", "Hậu Kỳ", "Viên Mãn"]
						var s_idx = clampi(new_stage - 1, 0, 3)
						npc["realm_name"] = "Trúc Cơ %s" % stage_names[s_idx]
						
				var bt_msg = "Đạo hữu %s (%s) cảm ngộ thiên địa, đột phá thành công lên %s!" % [
					npc.get("name", ""),
					npc.get("title", ""),
					npc.get("realm_name", "")
				]
				summary["breakthroughs"].append(bt_msg)
				if GameSession:
					GameSession.log_memory_event(nid, "", "breakthrough", npc.get("location", ""), [], 1, true)
			else:
				# Đột phá thất bại -> Tẩu hỏa nhập ma nhẹ
				cur_xp = 40
				if traits.get("caution", 50) < 30 and (npc_seed % 10 < 3):
					summary["deaths_and_wounds"].append("Đạo hữu %s cưỡng cầu đột phá thất bại, kinh mạch bị hao tổn nhẹ." % npc.get("name", ""))
		npc["cultivation_xp"] = cur_xp
		
		# 3. Utility AI: Lựa chọn 1 Ý Định Chính (ONE Main Intent)
		var chosen_intent = _decide_npc_intent(npc, npc_seed)
		_execute_npc_intent(npc, chosen_intent, npc_seed, summary, npcs_map)
	
	# 4. Cập nhật nền kinh tế môn phái & biến động thị trường
	_update_faction_economy(month_seed, summary)
	_update_market_trends(month_seed, summary)
	
	# 5. Lưu trữ bản tóm tắt vào GameSession
	if GameSession:
		GameSession.add_monthly_summary(summary)
		
	return summary

## Tính điểm Utility AI cho 7 ý định: train, trade, quest, travel, relationship, fight, rest
func _decide_npc_intent(npc: Dictionary, seed_val: int) -> String:
	var traits = npc.get("traits", { "caution": 50, "greed": 50, "mercy": 50, "ambition": 50, "honor": 50 })
	var caution = traits.get("caution", 50)
	var greed = traits.get("greed", 50)
	var mercy = traits.get("mercy", 50)
	var ambition = traits.get("ambition", 50)
	var honor = traits.get("honor", 50)
	
	var scores: Dictionary = {
		"train": ambition * 0.8 + caution * 0.4,
		"trade": greed * 0.9 + (100 - caution) * 0.2,
		"quest": ambition * 0.5 + greed * 0.5 - caution * 0.4 + 15,
		"travel": (100 - caution) * 0.5 + 10,
		"relationship": honor * 0.6 + mercy * 0.6 + 10,
		"fight": 0,
		"rest": caution * 0.6 + (100 - ambition) * 0.3
	}
	
	# Kiểm tra cừu hận (Grudge)
	var relationships = npc.get("relationships", {})
	var max_grudge = 0
	for target_id in relationships.keys():
		var r = relationships[target_id]
		if r.get("grudge", 0) > max_grudge:
			max_grudge = r.get("grudge", 0)
			
	if max_grudge >= 40:
		scores["fight"] = max_grudge * 1.1 - caution * 0.5 + (100 - mercy) * 0.4
		
	# Thêm một chút biến thiên ngẫu nhiên theo seed (nhưng deterministic)
	var intents = scores.keys()
	var best_intent = "train"
	var best_score = -999.0
	
	for i in range(intents.size()):
		var intent = intents[i]
		var noise = ((seed_val + i * 17) % 20) - 10 # -10 đến +9
		var final_score = scores[intent] + noise
		if final_score > best_score:
			best_score = final_score
			best_intent = intent
			
	return best_intent

## Thực thi kết quả ý định của NPC
func _execute_npc_intent(npc: Dictionary, intent: String, seed_val: int, summary: Dictionary, npcs_map: Dictionary) -> void:
	var nid = npc.get("id", "")
	var name = npc.get("name", "Tán Tu")
	var loc = npc.get("location", "poi_thanh_tri_tran")
	
	match intent:
		"train":
			npc["cultivation_xp"] = npc.get("cultivation_xp", 0) + 15
		"trade":
			var profit = 20 + (seed_val % 50)
			npc["money"] = npc.get("money", 100) + profit
			if profit > 55 and (seed_val % 4 == 0):
				summary["market_trends"].append("Thương nhân %s vừa hoàn tất thương vụ buôn bán khoáng thạch, lời hơn %d linh thạch." % [name, profit])
		"quest":
			npc["cultivation_xp"] = npc.get("cultivation_xp", 0) + 10
			npc["money"] = npc.get("money", 100) + 30
			if seed_val % 7 == 0:
				var incident = "%s tại %s chém giết một đầu yêu thú quấy nhiễu dân lành, được người đời ngợi khen." % [name, LOCATION_NAMES.get(loc, "Ngoại Vi")]
				summary["major_incidents"].append(incident)
				if GameSession:
					GameSession.log_memory_event(nid, "", "quest_slay", loc, [], 1, true)
		"travel":
			var loc_idx = (seed_val % LOCATIONS.size())
			var new_loc = LOCATIONS[loc_idx]
			if new_loc != loc:
				npc["location"] = new_loc
				npc["location_name"] = LOCATION_NAMES.get(new_loc, "Ngoại Vi")
				if seed_val % 6 == 0:
					summary["rumors_and_gossip"].append("%s đã rời địa bàn cũ, chu du đến %s tầm tìm đạo hữu." % [name, npc["location_name"]])
		"relationship":
			# Tìm một NPC khác hoặc người chơi để tăng tình hảo hữu
			var other_ids = npcs_map.keys()
			if other_ids.size() > 1:
				var target_idx = (seed_val % other_ids.size())
				var target_id = other_ids[target_idx]
				if target_id != nid:
					var target_npc = npcs_map[target_id]
					if not npc.has("relationships"):
						npc["relationships"] = {}
					if not npc["relationships"].has(target_id):
						npc["relationships"][target_id] = { "affinity": 0, "trust": 0, "fear": 0, "debt": 0, "grudge": 0 }
					var r = npc["relationships"][target_id]
					r["affinity"] = clampi(r.get("affinity", 0) + 10, -100, 100)
					r["trust"] = clampi(r.get("trust", 0) + 15, 0, 100)
					if seed_val % 8 == 0:
						summary["rumors_and_gossip"].append("%s và %s kết thành bạn hữu đàm đạo, uống trà luận kiếm." % [name, target_npc.get("name", "Đạo Hữu")])
		"fight":
			# Tìm kẻ thù có grudge
			var relationships = npc.get("relationships", {})
			for tid in relationships.keys():
				var r = relationships[tid]
				if r.get("grudge", 0) >= 40:
					var target_name = "Cừu Nhân"
					if npcs_map.has(tid):
						target_name = npcs_map[tid].get("name", "Cừu Nhân")
					elif tid == "player":
						target_name = "nhân vật chính"
						
					var fight_msg = "%s mang mối hận cũ, tìm kiếm %s để tính sổ ân oán tại %s!" % [name, target_name, LOCATION_NAMES.get(loc, "Ngoại Vi")]
					summary["major_incidents"].append(fight_msg)
					r["grudge"] = maxi(0, r["grudge"] - 20)
					if GameSession:
						GameSession.log_memory_event(nid, tid, "revenge_attempt", loc, [], 2, true)
					break
		"rest":
			# An dưỡng hồi phục
			pass

## Cập nhật kinh tế các môn phái
func _update_faction_economy(seed_val: int, summary: Dictionary) -> void:
	if not GameSession or GameSession.world_factions.is_empty():
		return
		
	for fac_id in GameSession.world_factions.keys():
		var fac = GameSession.world_factions[fac_id]
		var treasury = fac.get("treasury", 10000)
		var income = 500 + (seed_val % 300)
		treasury += income
		fac["treasury"] = treasury
		
		# Sự kiện môn phái thỉnh thoảng
		if seed_val % 11 == 0 and fac_id == "sect_thanh_vi":
			summary["major_incidents"].append("Thanh Vi Kiếm Tông phát lệnh chiêu mộ đệ tử ngoại môn, thưởng lớn cho ai dâng nộp yêu đan.")
		elif seed_val % 13 == 0 and fac_id == "sect_bach_thao":
			summary["market_trends"].append("Bách Thảo Môn vừa luyện chế thành công mười lò Thanh Tâm Đan, giá linh thảo hạ nhiệt nhẹ.")

## Cập nhật xu hướng thị trường & vật giá
func _update_market_trends(seed_val: int, summary: Dictionary) -> void:
	if not GameSession:
		return
		
	var herb_mod = 1.0 + float((seed_val % 30) - 15) / 100.0 # 0.85 -> 1.15
	GameSession.market_modifiers["herbs"] = herb_mod
	if herb_mod > 1.10:
		summary["market_trends"].append("Dạo này sương mù độc khí dâng cao, nguồn cung Dược Liệu khan hiếm khiến giá thuốc tăng 10%.")
	elif herb_mod < 0.90:
		summary["market_trends"].append("Tán tu rộ mùa thu hoạch thảo dược tại Rừng Trúc, giá linh thảo giảm 10%.")

## Headless Stress Test: Mô phỏng 500 - 1,000 NPC qua 12 tháng để đo hiệu năng
func run_headless_stress_test(npc_count: int = 500, months_count: int = 12) -> Dictionary:
	var start_time_usec = Time.get_ticks_usec()
	var test_npcs: Dictionary = {}
	
	# Sinh nhanh danh sách NPC giả lập
	for i in range(npc_count):
		var test_id = "test_npc_%04d" % i
		test_npcs[test_id] = {
			"id": test_id,
			"name": "Tán Tu #%d" % i,
			"realm_name": "Luyện Khí Tầng %d" % ((i % 9) + 1),
			"realm_tier": 1,
			"realm_stage": (i % 9) + 1,
			"age_days": (20 + (i % 50)) * 360,
			"lifespan_days": 120 * 360,
			"cultivation_xp": i % 80,
			"money": 100 + (i % 500),
			"traits": {
				"caution": (i * 13) % 100,
				"greed": (i * 29) % 100,
				"mercy": (i * 47) % 100,
				"ambition": (i * 71) % 100,
				"honor": (i * 89) % 100
			},
			"relationships": {},
			"location": LOCATIONS[i % LOCATIONS.size()],
			"alive": true
		}
		
	# Chạy liên tục qua số tháng yêu cầu
	var total_breakthroughs = 0
	var total_deaths = 0
	
	for m in range(1, months_count + 1):
		var sim_res = simulate_month(m, 1, test_npcs)
		total_breakthroughs += sim_res["breakthroughs"].size()
		total_deaths += sim_res["deaths_and_wounds"].size()
		
	var end_time_usec = Time.get_ticks_usec()
	var elapsed_ms = float(end_time_usec - start_time_usec) / 1000.0
	var avg_ms_per_month = elapsed_ms / float(months_count)
	
	return {
		"npc_count": npc_count,
		"months_simulated": months_count,
		"total_time_ms": elapsed_ms,
		"avg_ms_per_month": avg_ms_per_month,
		"total_breakthroughs": total_breakthroughs,
		"total_deaths": total_deaths,
		"pass_benchmark": avg_ms_per_month < 100.0 # Mục tiêu: < 100ms mỗi tháng cho 500-1000 NPC
	}
