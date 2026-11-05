extends Node

## GameSession — Quản lý Runtime Session và State của người chơi
## Lưu trữ dữ liệu phiên chơi hiện tại độc lập với Scene Tree.

var player_name: String = "Lâm Phong"
var player_guid: String = ""
var realm_id: String = "realm_pham_nhan"
var current_hp: int = 100
var max_hp: int = 100
var current_mp: int = 0
var max_mp: int = 0

var attack_power: int = 10
var defense_power: int = 5
var move_speed: float = 180.0

var player_hp: int:
	get: return current_hp
	set(val): current_hp = val

func _ready() -> void:
	if player_guid == "":
		player_guid = "guid_%s_%d" % [player_name.to_snake_case(), randi() % 1000000]

func heal_player(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	if EventBus and EventBus.has_signal("player_hp_changed"):
		EventBus.player_hp_changed.emit(current_hp, max_hp)

var cultivation_xp: int = 0
var max_cultivation_xp: int = 100
var lifespan_years: int = 18
var max_lifespan_years: int = 80

var world_seed: int = 1337
var world_id: String = "dao_tan_world_01"
var country_id: String = "dai_huyen"
var current_province_id: String = "thin_chau"
var chunk_diffs: Dictionary = {} # { "chunk_x_y": Dictionary }
var world_position: Vector2 = Vector2(66560.0, 66560.0) # Thanh Trì Huyện trong Thìn Châu
var town_position: Vector2 = Vector2.ZERO # Vị trí ghi nhớ khi ra khỏi cổng trấn/tông môn
var current_region_id: String = "thin_chau"
var is_session_active: bool = false
var target_combat_boss: String = ""
var return_scene_path: String = "res://scenes/world/province_world.tscn"

# Phase 1 State Collections
var inventory: Array[Dictionary] = [] # [{ "item_id": String, "id": String, "quantity": int, "count": int }]
var active_quests: Dictionary = {}    # { quest_id: { "step_index": int, "state": "active"|"completed" } }
var npc_affinities: Dictionary = {}   # { npc_id: int }
var defeated_bosses: Array[String] = []

# Phase 2 Living-World State Collections
var world_npcs: Dictionary = {}        # { npc_id: Dictionary (full runtime state) }
var world_factions: Dictionary = {}    # { faction_id: Dictionary }
var memory_events: Array[Dictionary] = []
var monthly_summaries: Array[Dictionary] = []
var market_modifiers: Dictionary = {}

# Phase 3 Sect & Tribulation State
var player_sect_id: String = ""
var sect_contribution: int = 0
var sect_rank: String = ""
var learned_library_skills: Array[String] = []
var lib_range_bonus: int = 0
var tribulation_resist_bonus: float = 0.0
var pending_tribulation: bool = false

# Aliases cho thuộc tính
var attack: int:
	get: return attack_power
	set(val): attack_power = val

var defense: int:
	get: return defense_power
	set(val): defense_power = val

var speed: float:
	get: return move_speed
	set(val): move_speed = val

func start_new_game(p_name: String, p_seed: int) -> void:
	player_name = p_name if p_name.strip_edges() != "" else "Kẻ Vô Danh"
	player_guid = "guid_%s_%d" % [player_name.to_snake_case(), randi() % 1000000]
	world_seed = p_seed
	world_id = "dao_tan_world_01"
	country_id = "dai_huyen"
	current_province_id = "thin_chau"
	current_region_id = "thin_chau"
	chunk_diffs = {}
	cultivation_xp = 0
	max_cultivation_xp = 100
	lifespan_years = 18
	max_lifespan_years = 80
	
	_apply_realm_stats()
	current_hp = max_hp
	current_mp = max_mp
	world_position = Vector2(66560.0, 66560.0)
	town_position = Vector2(66560.0, 66560.0)
	
	# Khởi tạo túi đồ ban đầu
	inventory = []
	add_item("item_linh_thach", 25)
	add_item("item_hoi_xuan_dan", 2)
	
	active_quests = {}
	defeated_bosses = []
	
	# Khởi tạo thiện cảm NPC và thế giới Phase 2
	npc_affinities = {}
	world_npcs = {}
	for npc in ContentRegistry.get_all_npcs():
		var nid = npc.get("id", "")
		npc_affinities[nid] = 0
		var npc_clone = npc.duplicate(true)
		if not npc_clone.has("traits"):
			npc_clone["traits"] = { "caution": 50, "greed": 50, "mercy": 50, "ambition": 50, "honor": 50 }
		if not npc_clone.has("relationships"):
			npc_clone["relationships"] = {}
		if not npc_clone.has("memories"):
			npc_clone["memories"] = []
		if not npc_clone.has("alive"):
			npc_clone["alive"] = true
		if not npc_clone.has("cultivation_xp"):
			npc_clone["cultivation_xp"] = 0
		if not npc_clone.has("age_days"):
			npc_clone["age_days"] = npc_clone.get("age_years", 30) * 360
		if not npc_clone.has("lifespan_days"):
			npc_clone["lifespan_days"] = npc_clone.get("lifespan_years", 120) * 360
		world_npcs[nid] = npc_clone
		
	world_factions = {}
	for fac in ContentRegistry.get_all_factions():
		world_factions[fac.get("id", "")] = fac.duplicate(true)
		
	memory_events = []
	monthly_summaries = []
	market_modifiers = {}
	
	# Reset Phase 3 sect state
	player_sect_id = ""
	sect_contribution = 0
	sect_rank = ""
	learned_library_skills = []
	lib_range_bonus = 0
	tribulation_resist_bonus = 0.0
	pending_tribulation = false
	
	# Reset town position & Shop Service
	town_position = Vector2.ZERO
	ShopService.reset_stall()
	
	RNGService.init_with_seed(world_seed)
	GameClock.reset_clock()
	is_session_active = true
	
	if EventBus:
		EventBus.world_loaded.emit(world_seed)
		EventBus.inventory_changed.emit("all", 0)

func _apply_realm_stats() -> void:
	var realm = ContentRegistry.get_realm(realm_id)
	max_hp = realm.get("base_hp", 100)
	max_mp = realm.get("base_mp", 0)
	attack_power = realm.get("base_atk", 10)
	defense_power = realm.get("base_def", 5)
	move_speed = realm.get("base_speed", 180.0)

# --- Quản Lý Túi Đồ (Inventory) ---
func add_item(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	
	for slot in inventory:
		var slot_id = slot.get("item_id", slot.get("id", ""))
		if slot_id == item_id:
			var curr = slot.get("quantity", slot.get("count", 1))
			slot["quantity"] = curr + qty
			slot["count"] = curr + qty
			if EventBus:
				EventBus.inventory_changed.emit(item_id, slot["quantity"])
			return true
	
	inventory.append({
		"item_id": item_id,
		"id": item_id,
		"quantity": qty,
		"count": qty
	})
	if EventBus:
		EventBus.inventory_changed.emit(item_id, qty)
	return true

func remove_item(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	
	for i in range(inventory.size()):
		var slot = inventory[i]
		var slot_id = slot.get("item_id", slot.get("id", ""))
		if slot_id == item_id:
			var curr = slot.get("quantity", slot.get("count", 0))
			if curr >= qty:
				var remain = curr - qty
				slot["quantity"] = remain
				slot["count"] = remain
				if remain == 0:
					inventory.remove_at(i)
				if EventBus:
					EventBus.inventory_changed.emit(item_id, remain)
				return true
			else:
				return false
	return false

func has_item(item_id: String, qty: int = 1) -> bool:
	return get_item_count(item_id) >= qty

func get_item_count(item_id: String) -> int:
	for slot in inventory:
		var slot_id = slot.get("item_id", slot.get("id", ""))
		if slot_id == item_id:
			return slot.get("quantity", slot.get("count", 0))
	return 0

func add_cultivation(amount: int) -> void:
	cultivation_xp = mini(cultivation_xp + amount, max_cultivation_xp)
	if EventBus:
		EventBus.notification_requested.emit("Linh khí nhập thể! Tu vi tăng +%d điểm!" % amount, "info")

func add_cultivation_xp(amount: int) -> void:
	add_cultivation(amount)

func use_item(item_id: String) -> bool:
	var item_def = ContentRegistry.get_item(item_id)
	if item_def.is_empty():
		return false
	
	var eff = item_def.get("effect", {})
	var eff_type = eff.get("type", "")
	
	if eff_type == "heal_hp":
		var heal_val = eff.get("value", 50)
		if current_hp >= max_hp:
			if EventBus:
				EventBus.notification_requested.emit("Khí huyết đã dồi dào, không cần dùng đan dược!", "info")
			return false
		
		if remove_item(item_id, 1):
			current_hp = mini(current_hp + heal_val, max_hp)
			if AudioService:
				AudioService.play_sfx("sfx_pill_swallow")
			if EventBus:
				EventBus.player_hp_changed.emit(current_hp, max_hp)
				EventBus.notification_requested.emit("Dùng %s, hồi phục %d Khí Huyết!" % [item_def.get("name", "Đan Dược"), heal_val], "success")
			return true
	
	elif eff_type == "cultivation_xp" or item_id == "item_tu_khi_dan":
		var val = eff.get("value", 25)
		if remove_item(item_id, 1):
			cultivation_xp = mini(cultivation_xp + val, max_cultivation_xp)
			if AudioService:
				AudioService.play_sfx("sfx_pill_swallow")
			if EventBus:
				EventBus.notification_requested.emit("Nuốt %s, đan điền dâng trào +%d Tu Vi!" % [item_def.get("name", "Đan Dược"), val], "success")
			return true
			
	elif eff_type == "breakthrough_aid":
		return breakthrough_to_next_realm()
	
	return false

# --- Hệ Thống Đột Phá Cảnh Giới (Breakthrough) ---
func can_breakthrough() -> bool:
	if realm_id == "realm_pham_nhan":
		return cultivation_xp >= max_cultivation_xp and has_item("item_tu_khi_dan", 1)
	elif realm_id.begins_with("realm_luyen_khi_"):
		var stage_num = int(realm_id.trim_prefix("realm_luyen_khi_"))
		if stage_num >= 1 and stage_num < 9:
			return cultivation_xp >= max_cultivation_xp
		elif stage_num == 9:
			return can_breakthrough_to_truc_co().get("can", false)
	return false

func get_breakthrough_info() -> Dictionary:
	if realm_id == "realm_pham_nhan":
		var has_pill = has_item("item_tu_khi_dan", 1)
		var has_xp = cultivation_xp >= max_cultivation_xp
		return {
			"can": has_pill and has_xp,
			"target_realm_id": "realm_luyen_khi_1",
			"target_realm_name": "Luyện Khí Tầng 1",
			"req_item_id": "item_tu_khi_dan",
			"req_item_name": "Tụ Khí Đan",
			"reason": "Cần 100/100 Tu Vi và 1 viên Tụ Khí Đan." if not (has_pill and has_xp) else "Đã đủ điều kiện bế quan!"
		}
	elif realm_id.begins_with("realm_luyen_khi_"):
		var stage_num = int(realm_id.trim_prefix("realm_luyen_khi_"))
		if stage_num >= 1 and stage_num < 9:
			var next_stage = stage_num + 1
			var next_realm_id = "realm_luyen_khi_%d" % next_stage
			var next_realm = ContentRegistry.get_realm(next_realm_id)
			var has_xp = cultivation_xp >= max_cultivation_xp
			return {
				"can": has_xp,
				"target_realm_id": next_realm_id,
				"target_realm_name": next_realm.get("name", "Luyện Khí Tầng %d" % next_stage),
				"req_item_id": "",
				"req_item_name": "Không cần đan dược",
				"reason": "Cần tích lũy đủ %d/%d Tu Vi để xung kích kinh mạch." % [cultivation_xp, max_cultivation_xp] if not has_xp else "Khí hải tràn đầy, có thể bế quan tiến giai!"
			}
		elif stage_num == 9:
			var tc_check = can_breakthrough_to_truc_co()
			return {
				"can": tc_check.get("can", false),
				"target_realm_id": "realm_truc_co_1",
				"target_realm_name": "Trúc Cơ Sơ Kỳ (Đại Cảnh Giới)",
				"req_item_id": "item_tay_tuy_dan",
				"req_item_name": "Tẩy Tủy Đan",
				"reason": tc_check.get("reason", "")
			}
	elif realm_id == "realm_truc_co_1":
		return { "can": false, "reason": "Đã đắc đạo Trúc Cơ Sơ Kỳ! Đang củng cố đạo cơ." }
	return { "can": false, "reason": "Hiện tại đã đạt cực hạn cảnh giới của giai đoạn này." }

func breakthrough_to_next_realm() -> bool:
	if not can_breakthrough():
		if EventBus:
			EventBus.notification_requested.emit("Chưa đủ điều kiện đột phá cảnh giới!", "error")
		return false
	
	if realm_id == "realm_pham_nhan":
		if remove_item("item_tu_khi_dan", 1):
			realm_id = "realm_luyen_khi_1"
			_apply_realm_stats()
			current_hp = max_hp
			current_mp = max_mp
			cultivation_xp = 0
			max_cultivation_xp = 300
			max_lifespan_years = 120
			
			# Tự động đẩy tiến trình nhiệm vụ nếu đang ở bước đột phá
			if is_quest_active("q_first_spirit_vein"):
				if get_quest_step("q_first_spirit_vein") == 3:
					advance_quest("q_first_spirit_vein", 4)
			
			if EventBus:
				EventBus.player_realm_changed.emit(realm_id)
				EventBus.player_hp_changed.emit(current_hp, max_hp)
				EventBus.player_mp_changed.emit(current_mp, max_mp)
				EventBus.notification_requested.emit("Thiên địa linh khí quán đỉnh! Đột phá thành công Luyện Khí Tầng 1!", "success")
			return true
	elif realm_id.begins_with("realm_luyen_khi_"):
		var stage_num = int(realm_id.trim_prefix("realm_luyen_khi_"))
		if stage_num >= 1 and stage_num < 9:
			var next_stage = stage_num + 1
			realm_id = "realm_luyen_khi_%d" % next_stage
			_apply_realm_stats()
			current_hp = max_hp
			current_mp = max_mp
			cultivation_xp = 0
			var realm_def = ContentRegistry.get_realm(realm_id)
			var breq = realm_def.get("breakthrough_requirements", {})
			max_cultivation_xp = breq.get("qi_needed", 300 + next_stage * 50)
			
			if EventBus:
				EventBus.player_realm_changed.emit(realm_id)
				EventBus.player_hp_changed.emit(current_hp, max_hp)
				EventBus.player_mp_changed.emit(current_mp, max_mp)
				EventBus.notification_requested.emit("Linh khí quán thông! Đột phá thành công %s!" % realm_def.get("name", "Luyện Khí"), "success")
			return true
		elif stage_num == 9:
			return begin_truc_co_tribulation("res://scenes/towns/town_map_real.tscn")
	return false

# --- Đột phá Luyện Khí 9 → Trúc Cơ Sơ Kỳ (cần Thiên Kiếp Lôi Đình) ---
func can_breakthrough_to_truc_co() -> Dictionary:
	if realm_id != "realm_luyen_khi_9":
		return { "can": false, "reason": "Yêu cầu cảnh giới Luyện Khí Tầng 9 (Viên Mãn) để đột phá Trúc Cơ." }
	if cultivation_xp < max_cultivation_xp:
		return { "can": false, "reason": "Tu Vi chưa đạt Viên Mãn (%d/%d)." % [cultivation_xp, max_cultivation_xp] }
	if player_sect_id == "":
		return { "can": false, "reason": "Phải gia nhập tông môn trước khi đột phá Trúc Cơ Sơ Kỳ." }
	if not has_item("item_tay_tuy_dan", 1):
		return { "can": false, "reason": "Cần 1x Tẩy Tủy Đan để bước vào Thiên Kiếp Lôi Đình." }
	return { "can": true, "reason": "Đủ điều kiện! Hãy chuẩn bị đối mặt Thiên Kiếp Lôi Đình!" }

func begin_truc_co_tribulation(return_path: String) -> bool:
	var check = can_breakthrough_to_truc_co()
	if not check.get("can", false):
		if EventBus:
			EventBus.notification_requested.emit(check.get("reason", "Chưa đủ điều kiện."), "error")
		return false
	remove_item("item_tay_tuy_dan", 1)
	pending_tribulation = true
	return_scene_path = return_path
	if EventBus:
		EventBus.notification_requested.emit("★ Tiêu hao Tẩy Tủy Đan! Thiên Kiếp Lôi Đình đã mở — quyết chiến vì Trúc Cơ!", "success")
	return true

func complete_truc_co_tribulation(survived: bool) -> void:
	pending_tribulation = false
	if survived:
		realm_id = "realm_truc_co_1"
		_apply_realm_stats()
		current_hp = max_hp
		current_mp = max_mp
		cultivation_xp = 0
		max_cultivation_xp = 1000
		max_lifespan_years = 250
		if EventBus:
			EventBus.player_realm_changed.emit(realm_id)
			EventBus.player_hp_changed.emit(current_hp, max_hp)
			EventBus.player_mp_changed.emit(current_mp, max_mp)
			EventBus.notification_requested.emit("★★★ TRÚC CƠ THÀNH CÔNG! Vạn Kiếp Phong Vân, Trúc Cơ Sơ Kỳ — Chào mừng bước đầu trên đường trường sinh!", "success")
	else:
		if EventBus:
			EventBus.notification_requested.emit("Thiên Kiếp thất bại! Tu Vi tan vỡ — hãy dưỡng thương rồi lại thử!", "error")

# --- Quản Lý Nhiệm Vụ (Quests) ---
func start_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id):
		return false
	active_quests[quest_id] = { "step_index": 1, "state": "active" }
	if EventBus:
		EventBus.quest_updated.emit(quest_id, 1, "active")
		var q = ContentRegistry.get_quest(quest_id)
		EventBus.notification_requested.emit("Tiếp nhận nhiệm vụ: " + q.get("title", ""), "info")
	return true

func advance_quest(quest_id: String, next_step: int) -> bool:
	if active_quests.has(quest_id) and active_quests[quest_id].get("state") == "active":
		active_quests[quest_id]["step_index"] = next_step
		if EventBus:
			EventBus.quest_updated.emit(quest_id, next_step, "active")
			EventBus.notification_requested.emit("Tiến độ nhiệm vụ được cập nhật!", "info")
		return true
	return false

func complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	if active_quests[quest_id].get("state") == "completed":
		return false
		
	active_quests[quest_id]["state"] = "completed"
	var q = ContentRegistry.get_quest(quest_id)
	var rewards = q.get("reward", {})
	
	# Thưởng linh thạch (Áp dụng hệ số tiền thưởng trảm yêu nếu có chiếu chỉ triều đình)
	var money = rewards.get("money", 0)
	if money > 0:
		var cm = get_node_or_null("/root/CourtManager")
		var bounty_mult = cm.monster_bounty_multiplier if cm else 1.0
		var final_money = int(round(money * bounty_mult))
		add_item("item_linh_thach", final_money)
	
	# Thưởng vật phẩm
	for item_rew in rewards.get("items", []):
		add_item(item_rew.get("item_id", item_rew.get("id", "")), item_rew.get("quantity", item_rew.get("count", 1)))
	
	# Thưởng thiện cảm
	var aff_boost = rewards.get("affinity_boost", {})
	if not aff_boost.is_empty():
		modify_npc_affinity(aff_boost.get("npc_id", ""), aff_boost.get("value", 10))
	
	if EventBus:
		EventBus.quest_updated.emit(quest_id, 99, "completed")
		EventBus.notification_requested.emit("Hoàn thành nhiệm vụ: %s! Nhận thưởng lớn." % q.get("title", ""), "success")
	return true

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id) and active_quests[quest_id].get("state") == "active"

func is_quest_completed(quest_id: String) -> bool:
	return active_quests.has(quest_id) and active_quests[quest_id].get("state") == "completed"

func get_quest_step(quest_id: String) -> int:
	if active_quests.has(quest_id):
		return active_quests[quest_id].get("step_index", 0)
	return -1

func get_quest_state(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		var q = active_quests[quest_id]
		return {
			"status": q.get("state", "not_started"),
			"current_step": q.get("step_index", 0)
		}
	return {
		"status": "not_started",
		"current_step": 0
	}

# --- Quản Lý Thiện Cảm & Xã Hội NPC Phase 2 ---
func get_npc_affinity(npc_id: String) -> int:
	return npc_affinities.get(npc_id, 0)

func modify_npc_affinity(npc_id: String, delta: int) -> void:
	var curr = get_npc_affinity(npc_id)
	var new_val = clampi(curr + delta, -100, 100)
	npc_affinities[npc_id] = new_val
	if world_npcs.has(npc_id):
		world_npcs[npc_id]["affinity"] = new_val
	if EventBus:
		EventBus.npc_affinity_changed.emit(npc_id, new_val)

func get_npc(npc_id: String) -> Dictionary:
	if world_npcs.has(npc_id):
		return world_npcs[npc_id]
	return ContentRegistry.get_npc(npc_id)

func get_all_active_npcs() -> Array:
	var active_list: Array = []
	for npc in world_npcs.values():
		if npc.get("alive", true):
			active_list.append(npc)
	return active_list

func get_npc_relationship(npc_id: String, target_id: String) -> Dictionary:
	if world_npcs.has(npc_id):
		var rels = world_npcs[npc_id].get("relationships", {})
		if rels.has(target_id):
			return rels[target_id]
	return { "affinity": 0, "trust": 0, "fear": 0, "debt": 0, "grudge": 0 }

func modify_npc_relationship(npc_id: String, target_id: String, delta_affinity: int, delta_trust: int = 0, delta_debt: int = 0, delta_grudge: int = 0, delta_fear: int = 0) -> void:
	if not world_npcs.has(npc_id):
		return
	var npc = world_npcs[npc_id]
	if not npc.has("relationships"):
		npc["relationships"] = {}
	if not npc["relationships"].has(target_id):
		npc["relationships"][target_id] = { "affinity": 0, "trust": 0, "fear": 0, "debt": 0, "grudge": 0 }
	
	var r = npc["relationships"][target_id]
	r["affinity"] = clampi(r.get("affinity", 0) + delta_affinity, -100, 100)
	r["trust"] = clampi(r.get("trust", 0) + delta_trust, 0, 100)
	r["debt"] = clampi(r.get("debt", 0) + delta_debt, 0, 100)
	r["grudge"] = clampi(r.get("grudge", 0) + delta_grudge, 0, 100)
	r["fear"] = clampi(r.get("fear", 0) + delta_fear, 0, 100)
	
	if target_id == "player":
		npc_affinities[npc_id] = r["affinity"]
		if EventBus:
			EventBus.npc_affinity_changed.emit(npc_id, r["affinity"])

func register_world_npc(npc_data: Dictionary) -> void:
	var nid = npc_data.get("id", "")
	if nid.is_empty():
		return
	if not world_npcs.has(nid):
		world_npcs[nid] = npc_data.duplicate(true)
	else:
		for k in npc_data.keys():
			if not world_npcs[nid].has(k):
				world_npcs[nid][k] = npc_data[k]

func get_market_modifier(category: String) -> float:
	return market_modifiers.get(category, 1.0)

func set_market_modifier(category: String, value: float) -> void:
	market_modifiers[category] = clampf(value, 0.4, 3.0)
	if EventBus and EventBus.has_signal("market_trend_updated"):
		EventBus.market_trend_updated.emit(category, market_modifiers[category])

func get_modified_item_price(item_id: String, base_price: int, is_buying: bool = true) -> int:
	var item_def = ContentRegistry.get_item(item_id)
	var cat = item_def.get("category", "")
	var mod = 1.0
	if cat == "herb" or cat == "material" or item_id.contains("linh_thao") or item_id.contains("thao"):
		mod = get_market_modifier("herbs")
	elif cat == "pill" or cat == "medicine" or item_id.contains("dan") or item_id.contains("duoc"):
		mod = get_market_modifier("medicines")
	elif cat == "weapon" or cat == "armor" or item_id.contains("kiem") or item_id.contains("khieu"):
		mod = get_market_modifier("weapons")
	else:
		mod = get_market_modifier("general")
		
	var final_p = int(round(float(base_price) * mod))
	return maxi(1, final_p)

func log_memory_event(actor_id: String, target_id: String, event_type: String, location_id: String, witnesses: Array = [], severity: int = 1, is_public: bool = true) -> Dictionary:
	var mem: Dictionary = {
		"id": "mem_%d_%d" % [GameClock.total_days_elapsed, memory_events.size() + 1],
		"actor_id": actor_id,
		"target_id": target_id,
		"event_type": event_type,
		"location_id": location_id,
		"day": GameClock.current_day,
		"month": GameClock.current_month,
		"year": GameClock.current_year,
		"witnesses": witnesses,
		"severity": severity,
		"is_public": is_public
	}
	memory_events.append(mem)
	
	# Gắn ký ức vào actor và target nếu là NPC
	if world_npcs.has(actor_id):
		var n = world_npcs[actor_id]
		if not n.has("memories"):
			n["memories"] = []
		n["memories"].append(mem)
	if world_npcs.has(target_id):
		var t = world_npcs[target_id]
		if not t.has("memories"):
			t["memories"] = []
		t["memories"].append(mem)
		
	if EventBus and EventBus.has_signal("memory_event_logged"):
		EventBus.memory_event_logged.emit(mem)
		
	return mem

func add_monthly_summary(summary: Dictionary) -> void:
	monthly_summaries.append(summary)
	if EventBus and EventBus.has_signal("monthly_simulation_completed"):
		EventBus.monthly_simulation_completed.emit(GameClock.current_month, GameClock.current_year, summary)

func get_latest_monthly_summary() -> Dictionary:
	if monthly_summaries.size() > 0:
		return monthly_summaries[monthly_summaries.size() - 1]
	return {}

# --- Save & Load Serialization ---
func export_save_dict() -> Dictionary:
	var cm = get_node_or_null("/root/CourtManager")
	return {
		"schema_version": 2,
		"game_version": "0.0.3",
		"world_id": world_id,
		"country_id": country_id,
		"province_id": current_province_id,
		"world_seed": world_seed,
		"clock": GameClock.to_dict(),
		"player": {
			"name": player_name,
			"guid": player_guid,
			"realm_id": realm_id,
			"current_hp": current_hp,
			"max_hp": max_hp,
			"current_mp": current_mp,
			"max_mp": max_mp,
			"cultivation_xp": cultivation_xp,
			"max_cultivation_xp": max_cultivation_xp,
			"lifespan_years": lifespan_years,
			"max_lifespan_years": max_lifespan_years,
			"pos_x": world_position.x,
			"pos_y": world_position.y,
			"town_pos_x": town_position.x,
			"town_pos_y": town_position.y,
			"region_id": current_region_id,
			"province_id": current_province_id,
			"inventory": inventory,
			"active_quests": active_quests,
			"npc_affinities": npc_affinities,
			"defeated_bosses": defeated_bosses,
			"sect_id": player_sect_id,
			"sect_contribution": sect_contribution,
			"sect_rank": sect_rank,
			"learned_library_skills": learned_library_skills,
			"lib_range_bonus": lib_range_bonus,
			"tribulation_resist_bonus": tribulation_resist_bonus
		},
		"court_state": cm.to_dict() if cm else {},
		"chunk_diffs": chunk_diffs.duplicate(true),
		"shop": ShopService.to_dict(),
		"coop_state": CoopWorldSync.export_coop_state() if (CoopWorldSync and CoopWorldSync.has_method("export_coop_state")) else {},
		"world_npcs": world_npcs,
		"world_factions": world_factions,
		"memory_events": memory_events,
		"monthly_summaries": monthly_summaries,
		"market_modifiers": market_modifiers
	}

func get_province_world_position() -> Vector2:
	if world_position.x < 10000.0:
		return Vector2(66560.0, 66560.0)
	return world_position

func import_save_dict(data: Dictionary) -> bool:
	if not data.has("player") or not data.has("clock"):
		push_error("[GameSession] Dữ liệu save không hợp lệ!")
		return false
	
	world_id = data.get("world_id", "dao_tan_world_01")
	country_id = data.get("country_id", "dai_huyen")
	current_province_id = data.get("province_id", "thin_chau")
	chunk_diffs = data.get("chunk_diffs", {}).duplicate(true)
	
	var cm = get_node_or_null("/root/CourtManager")
	if data.has("court_state") and data["court_state"] is Dictionary:
		if cm and cm.has_method("import_court_dict"):
			cm.import_court_dict(data["court_state"])
		elif CourtManager and CourtManager.has_method("import_court_dict"):
			CourtManager.import_court_dict(data["court_state"])
	
	world_seed = data.get("world_seed", 1337)
	RNGService.init_with_seed(world_seed)
	GameClock.from_dict(data.get("clock", {}))
	
	var p_data = data.get("player", {})
	player_name = p_data.get("name", "Kẻ Vô Danh")
	player_guid = p_data.get("guid", "")
	if player_guid == "":
		player_guid = "guid_%s_%d" % [player_name.to_snake_case(), randi() % 1000000]
	realm_id = p_data.get("realm_id", "realm_pham_nhan")
	_apply_realm_stats()
	
	max_hp = p_data.get("max_hp", max_hp)
	current_hp = p_data.get("current_hp", max_hp)
	max_mp = p_data.get("max_mp", max_mp)
	current_mp = p_data.get("current_mp", max_mp)
	cultivation_xp = p_data.get("cultivation_xp", 0)
	max_cultivation_xp = p_data.get("max_cultivation_xp", 100)
	lifespan_years = p_data.get("lifespan_years", 18)
	max_lifespan_years = p_data.get("max_lifespan_years", 80)
	
	world_position = Vector2(p_data.get("pos_x", 66560.0), p_data.get("pos_y", 66560.0))
	town_position = Vector2(p_data.get("town_pos_x", 0.0), p_data.get("town_pos_y", 0.0))
	current_region_id = p_data.get("region_id", "thin_chau")
	
	inventory = []
	for slot in p_data.get("inventory", []):
		var s_id = slot.get("item_id", slot.get("id", ""))
		var s_qty = slot.get("quantity", slot.get("count", 1))
		inventory.append({
			"item_id": s_id,
			"id": s_id,
			"quantity": s_qty,
			"count": s_qty
		})
	
	active_quests = p_data.get("active_quests", {})
	npc_affinities = p_data.get("npc_affinities", {})
	defeated_bosses = []
	for b in p_data.get("defeated_bosses", []):
		defeated_bosses.append(str(b))
	
	# Khôi phục Phase 3 sect state
	player_sect_id = p_data.get("sect_id", "")
	sect_contribution = p_data.get("sect_contribution", 0)
	sect_rank = p_data.get("sect_rank", "")
	learned_library_skills = []
	for ls in p_data.get("learned_library_skills", []):
		learned_library_skills.append(str(ls))
	lib_range_bonus = p_data.get("lib_range_bonus", 0)
	tribulation_resist_bonus = p_data.get("tribulation_resist_bonus", 0.0)
	pending_tribulation = false
	
	# Khôi phục dữ liệu Phase 2
	world_npcs = data.get("world_npcs", {})
	if world_npcs.is_empty():
		# Migration từ save Phase 1: Tạo world_npcs từ ContentRegistry
		for npc in ContentRegistry.get_all_npcs():
			var nid = npc.get("id", "")
			var npc_clone = npc.duplicate(true)
			npc_clone["affinity"] = npc_affinities.get(nid, 0)
			world_npcs[nid] = npc_clone
			
	world_factions = data.get("world_factions", {})
	if world_factions.is_empty():
		for fac in ContentRegistry.get_all_factions():
			world_factions[fac.get("id", "")] = fac.duplicate(true)
			
	memory_events = []
	for m in data.get("memory_events", []):
		memory_events.append(m)
		
	monthly_summaries = []
	for s in data.get("monthly_summaries", []):
		monthly_summaries.append(s)
		
	market_modifiers = data.get("market_modifiers", {})
	
	# Khôi phục hoặc khởi tạo sạp hàng tu sĩ (ShopService Escrow)
	if data.has("shop") and data["shop"] is Dictionary:
		ShopService.from_dict(data["shop"])
	else:
		ShopService.reset_stall()
		
	# Khôi phục dữ liệu mạng Co-op nếu có
	if data.has("coop_state") and data["coop_state"] is Dictionary and CoopWorldSync and CoopWorldSync.has_method("import_coop_state"):
		CoopWorldSync.import_coop_state(data["coop_state"])
	
	is_session_active = true
	
	if EventBus:
		EventBus.world_loaded.emit(world_seed)
		EventBus.player_hp_changed.emit(current_hp, max_hp)
		EventBus.player_mp_changed.emit(current_mp, max_mp)
		EventBus.player_realm_changed.emit(realm_id)
		EventBus.inventory_changed.emit("all", 0)
	
	return true
