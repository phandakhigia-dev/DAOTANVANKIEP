extends RefCounted

## SectService — Quản lý gia nhập Tông Môn, cống hiến, cấp bậc và học kinh sách
## (Phase 3: Sect & Library System)

const SECTS_PATH = "res://data/sects/sects.json"

static var _sects_cache: Dictionary = {}

# --- Trạng thái người chơi trong tông môn ---
# Lưu trong GameSession:
#   GameSession.player_sect_id: String       — tông môn đã gia nhập (hoặc "")
#   GameSession.sect_contribution: int       — điểm cống hiến tích lũy
#   GameSession.sect_rank: String            — cấp bậc hiện tại (rank_id)
#   GameSession.learned_library_skills: Array[String] — id các kinh sách đã học

static func load_sects() -> Dictionary:
	if not _sects_cache.is_empty():
		return _sects_cache
	var file = FileAccess.open(SECTS_PATH, FileAccess.READ)
	if not file:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return {}
	_sects_cache = parsed
	return _sects_cache

static func get_all_sects() -> Array:
	var d = load_sects()
	return d.get("sects", [])

static func get_sect(sect_id: String) -> Dictionary:
	for s in get_all_sects():
		if s.get("id", "") == sect_id:
			return s
	return {}

# --- Kiểm tra điều kiện gia nhập tông môn ---
static func can_join_sect(sect_id: String) -> Dictionary:
	if GameSession.player_sect_id != "":
		return { "can": false, "reason": "Ngươi đã là thành viên của %s. Không thể phục vụ hai chủ!" % _get_sect_name(GameSession.player_sect_id) }
	
	var sect = get_sect(sect_id)
	if sect.is_empty():
		return { "can": false, "reason": "Tông môn không tồn tại." }
	
	var req = sect.get("join_requirements", {})
	
	# Kiểm tra cảnh giới tối thiểu
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	var realm_tier = realm.get("tier", 0)
	if realm_tier < req.get("min_realm_tier", 1):
		return { "can": false, "reason": "Yêu cầu tối thiểu cảnh giới %s để gia nhập." % req.get("min_realm_name", "Luyện Khí") }
	
	# Kiểm tra thiện cảm NPC cần thiết
	var affinity_npc = req.get("min_affinity_npc", "")
	if affinity_npc != "":
		var current_aff = GameSession.npc_affinities.get(affinity_npc, 0)
		var req_aff = req.get("min_affinity_value", 0)
		if current_aff < req_aff:
			var npc = ContentRegistry.get_npc(affinity_npc)
			return { "can": false, "reason": "Thiện cảm với %s chưa đủ (%d/%d). Hãy tăng cường giao hảo trước." % [npc.get("name", "NPC"), current_aff, req_aff] }
	
	# Kiểm tra vật phẩm cống nạp
	var tribute_items = req.get("tribute_items", [])
	for item in tribute_items:
		var iid = item.get("item_id", "")
		var qty = item.get("qty", 1)
		if not GameSession.has_item(iid, qty):
			var idef = ContentRegistry.get_item(iid)
			return { "can": false, "reason": "Thiếu vật phẩm cống nạp: %dx %s" % [qty, idef.get("name", iid)] }
	
	return { "can": true, "reason": "Đủ điều kiện gia nhập tông môn!" }

static func join_sect(sect_id: String) -> bool:
	var check = can_join_sect(sect_id)
	if not check.get("can", false):
		if EventBus:
			EventBus.notification_requested.emit(check.get("reason", "Không thể gia nhập."), "error")
		return false
	
	var sect = get_sect(sect_id)
	var req = sect.get("join_requirements", {})
	
	# Tiêu hao vật phẩm cống nạp
	for item in req.get("tribute_items", []):
		GameSession.remove_item(item.get("item_id", ""), item.get("qty", 1))
	
	GameSession.player_sect_id = sect_id
	GameSession.sect_contribution = 0
	GameSession.sect_rank = "rank_ngoai_mon"
	
	var sect_name = sect.get("name", "Tông Môn")
	if EventBus:
		EventBus.notification_requested.emit("★ Chính thức trở thành đệ tử %s! Vinh quang tông môn gửi gắm vào ngươi!" % sect_name, "success")
	return true

# --- Cập nhật cấp bậc theo đóng góp ---
static func _refresh_rank() -> void:
	var sect = get_sect(GameSession.player_sect_id)
	if sect.is_empty():
		return
	var ranks = sect.get("ranks", [])
	var contrib = GameSession.sect_contribution
	var best_rank = "rank_ngoai_mon"
	for r in ranks:
		if contrib >= r.get("min_contribution", 0):
			best_rank = r.get("id", "rank_ngoai_mon")
	var old_rank = GameSession.sect_rank
	GameSession.sect_rank = best_rank
	if old_rank != best_rank:
		var rank_def = get_rank_def(sect, best_rank)
		if EventBus:
			EventBus.notification_requested.emit("★ Thăng cấp bậc tông môn: %s!" % rank_def.get("name", best_rank), "success")

static func get_rank_def(sect: Dictionary, rank_id: String) -> Dictionary:
	for r in sect.get("ranks", []):
		if r.get("id", "") == rank_id:
			return r
	return {}

static func get_current_rank_name() -> String:
	if GameSession.player_sect_id == "":
		return "Tán Tu"
	var sect = get_sect(GameSession.player_sect_id)
	var r = get_rank_def(sect, GameSession.sect_rank)
	return r.get("name", "Ngoại Môn")

# --- Thực hiện nhiệm vụ cống hiến ---
static func complete_contribution_quest(cq_id: String) -> Dictionary:
	if GameSession.player_sect_id == "":
		return { "success": false, "msg": "Chưa gia nhập tông môn nào." }
	
	var sect = get_sect(GameSession.player_sect_id)
	var cq_def: Dictionary = {}
	for cq in sect.get("contribution_quests", []):
		if cq.get("id", "") == cq_id:
			cq_def = cq
			break
	if cq_def.is_empty():
		return { "success": false, "msg": "Nhiệm vụ cống hiến không tồn tại." }
	
	# Kiểm tra điều kiện đặc biệt: boss đã hạ
	var req_boss = cq_def.get("req_boss_defeated", "")
	if req_boss != "" and not GameSession.defeated_bosses.has(req_boss):
		return { "success": false, "msg": "Chưa hoàn thành điều kiện: Hạ Boss [%s] trước." % req_boss }
	
	# Kiểm tra & tiêu hao vật phẩm
	var cost_items = cq_def.get("cost_items", [])
	for ci in cost_items:
		if not GameSession.has_item(ci.get("item_id", ""), ci.get("qty", 1)):
			var idef = ContentRegistry.get_item(ci.get("item_id", ""))
			return { "success": false, "msg": "Thiếu vật phẩm: %dx %s" % [ci.get("qty", 1), idef.get("name", ci.get("item_id", ""))] }
	
	for ci in cost_items:
		GameSession.remove_item(ci.get("item_id", ""), ci.get("qty", 1))
	
	# Cộng cống hiến và phần thưởng
	var contrib_gain = cq_def.get("reward_contribution", 10)
	var lt_gain = cq_def.get("reward_linh_thach", 0)
	
	GameSession.sect_contribution += contrib_gain
	if lt_gain > 0:
		GameSession.add_item("item_linh_thach", lt_gain)
	
	_refresh_rank()
	
	var msg = "Hoàn thành nhiệm vụ cống hiến! +%d Cống Hiến" % contrib_gain
	if lt_gain > 0:
		msg += ", +%d Linh Thạch" % lt_gain
	if EventBus:
		EventBus.notification_requested.emit(msg, "success")
	
	return { "success": true, "contrib_gain": contrib_gain, "lt_gain": lt_gain }

# --- Học kinh sách từ Tàng Kinh Các ---
static func can_learn_skill(lib_skill_id: String) -> Dictionary:
	if GameSession.player_sect_id == "":
		return { "can": false, "reason": "Chưa gia nhập tông môn nào." }
	if GameSession.learned_library_skills.has(lib_skill_id):
		return { "can": false, "reason": "Đã học kinh sách này rồi." }
	
	var sect = get_sect(GameSession.player_sect_id)
	var skill_def = _find_library_skill(sect, lib_skill_id)
	if skill_def.is_empty():
		return { "can": false, "reason": "Kinh sách không thuộc tông môn của ngươi." }
	
	var req_rank = skill_def.get("req_rank", "rank_ngoai_mon")
	var rank_order = ["rank_ngoai_mon", "rank_noi_mon", "rank_truc_cot", "rank_truong_lao"]
	var cur_idx = rank_order.find(GameSession.sect_rank)
	var req_idx = rank_order.find(req_rank)
	if cur_idx < req_idx:
		var rdef = get_rank_def(sect, req_rank)
		return { "can": false, "reason": "Yêu cầu cấp bậc tối thiểu: %s" % rdef.get("name", req_rank) }
	
	var cost = skill_def.get("cost_contribution", 0)
	if GameSession.sect_contribution < cost:
		return { "can": false, "reason": "Cống hiến không đủ (%d/%d)" % [GameSession.sect_contribution, cost] }
	
	return { "can": true, "reason": "Đủ điều kiện học kinh sách!" }

static func learn_library_skill(lib_skill_id: String) -> bool:
	var check = can_learn_skill(lib_skill_id)
	if not check.get("can", false):
		if EventBus:
			EventBus.notification_requested.emit(check.get("reason", ""), "error")
		return false
	
	var sect = get_sect(GameSession.player_sect_id)
	var skill_def = _find_library_skill(sect, lib_skill_id)
	var cost = skill_def.get("cost_contribution", 0)
	
	GameSession.sect_contribution -= cost
	GameSession.learned_library_skills.append(lib_skill_id)
	
	# Áp dụng hiệu ứng kinh sách
	_apply_library_skill_effect(skill_def)
	
	if EventBus:
		EventBus.notification_requested.emit("★ Học thành kinh sách: %s!" % skill_def.get("name", lib_skill_id), "success")
	return true

static func _apply_library_skill_effect(skill_def: Dictionary) -> void:
	var effect = skill_def.get("effect", {})
	var atk_bonus = effect.get("atk_bonus", 0)
	var range_bonus = effect.get("range_bonus", 0)
	
	if atk_bonus > 0:
		GameSession.attack_power += atk_bonus
	if range_bonus > 0:
		GameSession.lib_range_bonus = GameSession.get("lib_range_bonus") if GameSession.get("lib_range_bonus") != null else 0
		GameSession.lib_range_bonus += range_bonus
	
	# Tribulation resist bonus stored in GameSession
	var trib_bonus = effect.get("tribulation_resist_bonus", 0.0)
	if trib_bonus > 0.0:
		GameSession.tribulation_resist_bonus = GameSession.get("tribulation_resist_bonus") if GameSession.get("tribulation_resist_bonus") != null else 0.0
		GameSession.tribulation_resist_bonus += trib_bonus

static func _find_library_skill(sect: Dictionary, lib_id: String) -> Dictionary:
	for ls in sect.get("library_skills", []):
		if ls.get("id", "") == lib_id:
			return ls
	return {}

static func _get_sect_name(sect_id: String) -> String:
	var s = get_sect(sect_id)
	return s.get("name", sect_id)

# --- Tiện ích tra cứu ---
static func get_player_sect_summary() -> Dictionary:
	if GameSession.player_sect_id == "":
		return { "sect_name": "Tán Tu", "rank_name": "Vô Môn Tán Tu", "contribution": 0 }
	var sect = get_sect(GameSession.player_sect_id)
	var r = get_rank_def(sect, GameSession.sect_rank)
	return {
		"sect_name": sect.get("name", "?"),
		"rank_name": r.get("name", "?"),
		"contribution": GameSession.sect_contribution,
		"learned_skills": GameSession.learned_library_skills.duplicate()
	}
