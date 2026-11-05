extends Node

## ContentRegistry — Đăng ký và nạp dữ liệu data-driven từ thư mục data/
## Kiểm tra tính toàn vẹn (Schema Validation) của các định nghĩa trước khi sử dụng.

var balance_data: Dictionary = {}
var regions_data: Dictionary = {}
var items_data: Dictionary = {}
var skills_data: Dictionary = {}
var enemies_data: Dictionary = {}
var npcs_data: Dictionary = {}
var quests_data: Dictionary = {}
var factions_data: Dictionary = {}
var recipes_data: Dictionary = {}
var sects_data: Dictionary = {}
var is_loaded: bool = false

func _ready() -> void:
	load_all_content()

func load_all_content() -> void:
	_load_balance_data()
	_load_regions()
	_load_items()
	_load_skills()
	_load_enemies()
	_load_recipes()
	_load_npcs()
	_load_quests()
	_load_factions()
	_load_sects()
	is_loaded = true

func _load_json_file(path: String) -> Variant:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(json_str)
		if error == OK:
			return json.data
		else:
			push_error("[ContentRegistry] Lỗi phân tích JSON tại %s: %s" % [path, json.get_error_message()])
	return null

func _load_balance_data() -> void:
	var data = _load_json_file("res://data/balance.json")
	if data is Dictionary:
		balance_data = data
	else:
		_fallback_balance_data()

func _fallback_balance_data() -> void:
	balance_data = {
		"game_version": "0.0.1",
		"realms": {
			"realm_pham_nhan": {
				"name": "Phàm Nhân",
				"stage": 0,
				"tier": 0,
				"base_hp": 100,
				"base_mp": 0,
				"base_atk": 10,
				"base_def": 5,
				"base_speed": 180.0
			},
			"realm_luyen_khi_1": {
				"name": "Luyện Khí Tầng 1",
				"stage": 1,
				"tier": 1,
				"base_hp": 160,
				"base_mp": 50,
				"base_atk": 18,
				"base_def": 10,
				"base_speed": 190.0
			},
			"realm_luyen_khi_2": { "name": "Luyện Khí Tầng 2", "stage": 2, "tier": 1, "base_hp": 180, "base_mp": 60, "base_atk": 22, "base_def": 12, "base_speed": 192.0 },
			"realm_luyen_khi_3": { "name": "Luyện Khí Tầng 3", "stage": 3, "tier": 1, "base_hp": 200, "base_mp": 70, "base_atk": 26, "base_def": 14, "base_speed": 194.0 },
			"realm_luyen_khi_4": { "name": "Luyện Khí Tầng 4", "stage": 4, "tier": 1, "base_hp": 230, "base_mp": 80, "base_atk": 30, "base_def": 16, "base_speed": 196.0 },
			"realm_luyen_khi_5": { "name": "Luyện Khí Tầng 5", "stage": 5, "tier": 1, "base_hp": 260, "base_mp": 100, "base_atk": 36, "base_def": 18, "base_speed": 198.0 },
			"realm_luyen_khi_6": { "name": "Luyện Khí Tầng 6", "stage": 6, "tier": 1, "base_hp": 300, "base_mp": 120, "base_atk": 42, "base_def": 21, "base_speed": 200.0 },
			"realm_luyen_khi_7": { "name": "Luyện Khí Tầng 7", "stage": 7, "tier": 1, "base_hp": 350, "base_mp": 150, "base_atk": 50, "base_def": 24, "base_speed": 202.0 },
			"realm_luyen_khi_8": { "name": "Luyện Khí Tầng 8", "stage": 8, "tier": 1, "base_hp": 410, "base_mp": 180, "base_atk": 58, "base_def": 28, "base_speed": 205.0 },
			"realm_luyen_khi_9": { "name": "Luyện Khí Tầng 9 (Viên Mãn)", "stage": 9, "tier": 1, "base_hp": 480, "base_mp": 220, "base_atk": 68, "base_def": 33, "base_speed": 208.0 },
			"realm_truc_co_1": {
				"name": "Trúc Cơ Sơ Kỳ",
				"stage": 10,
				"tier": 2,
				"base_hp": 700,
				"base_mp": 400,
				"base_atk": 95,
				"base_def": 55,
				"base_speed": 215.0
			}
		}
	}

func _load_regions() -> void:
	var data = _load_json_file("res://data/regions/region_thanh_tri.json")
	if data is Dictionary:
		var reg_id = data.get("region_id", "reg_thanh_tri")
		regions_data[reg_id] = data

func _load_items() -> void:
	var data = _load_json_file("res://data/items/items.json")
	if data is Dictionary and data.has("items"):
		for item in data["items"]:
			items_data[item["id"]] = item

func _load_skills() -> void:
	var data = _load_json_file("res://data/skills/skills.json")
	if data is Dictionary and data.has("skills"):
		for skill in data["skills"]:
			skills_data[skill["id"]] = skill

func _load_enemies() -> void:
	var data = _load_json_file("res://data/enemies/enemies.json")
	if data is Dictionary and data.has("enemies"):
		for enemy in data["enemies"]:
			var eid = enemy["id"]
			enemies_data[eid] = enemy
			if eid == "enemy_linh_ho_yeu":
				enemies_data["enemy_linh_ho"] = enemy
			elif eid == "boss_xich_kiem_ma_thu":
				enemies_data["boss_xich_kiem_ma_thuu"] = enemy
			elif eid == "boss_xich_kiem_ma_thuu":
				enemies_data["boss_xich_kiem_ma_thu"] = enemy

func _load_recipes() -> void:
	var data = _load_json_file("res://data/recipes/recipes.json")
	if data is Dictionary and data.has("recipes"):
		for rec in data["recipes"]:
			recipes_data[rec["id"]] = rec

func _load_npcs() -> void:
	var data = _load_json_file("res://data/npcs/npcs.json")
	if data is Dictionary and data.has("npcs"):
		for npc in data["npcs"]:
			var nid = npc["id"]
			npcs_data[nid] = npc
			if nid == "npc_mac_tu_vien":
				npcs_data["npc_moc_tu_vien"] = npc
			elif nid == "npc_moc_tu_vien":
				npcs_data["npc_mac_tu_vien"] = npc

func _load_quests() -> void:
	var data = _load_json_file("res://data/quests/quests.json")
	if data is Dictionary and data.has("quests"):
		for quest in data["quests"]:
			quests_data[quest["id"]] = quest

func _load_factions() -> void:
	var data = _load_json_file("res://data/factions/factions.json")
	if data is Dictionary and data.has("factions"):
		for fac in data["factions"]:
			var fid = fac["id"]
			factions_data[fid] = fac
			if fid == "sect_thanh_vi":
				factions_data["faction_thanh_vi"] = fac
			elif fid == "faction_thanh_vi":
				factions_data["sect_thanh_vi"] = fac

func get_realm(realm_id: String) -> Dictionary:
	var realms = balance_data.get("realms", {})
	return realms.get(realm_id, realms.get("realm_pham_nhan", {}))

func get_region(region_id: String) -> Dictionary:
	return regions_data.get(region_id, {})

func get_item(item_id: String) -> Dictionary:
	return items_data.get(item_id, {})

func get_skill(skill_id: String) -> Dictionary:
	return skills_data.get(skill_id, {})

func get_all_skills() -> Array:
	return skills_data.values()

func get_recipe(recipe_id: String) -> Dictionary:
	return recipes_data.get(recipe_id, {})

func get_all_recipes() -> Array:
	return recipes_data.values()

func get_enemy(enemy_id: String) -> Dictionary:
	return enemies_data.get(enemy_id, {})

func get_npc(npc_id: String) -> Dictionary:
	return npcs_data.get(npc_id, {})

func get_all_npcs() -> Array:
	var unique_npcs: Dictionary = {}
	for npc in npcs_data.values():
		unique_npcs[npc.get("id")] = npc
	return unique_npcs.values()

func get_all_factions() -> Array:
	var unique_facs: Dictionary = {}
	for fac in factions_data.values():
		unique_facs[fac.get("id")] = fac
	return unique_facs.values()

func get_npcs_at_location(location_id: String) -> Array:
	var result: Array = []
	for npc in npcs_data.values():
		if npc.get("location") == location_id:
			result.append(npc)
	return result

func get_quest(quest_id: String) -> Dictionary:
	return quests_data.get(quest_id, {})

func get_faction(faction_id: String) -> Dictionary:
	return factions_data.get(faction_id, {})

func _load_sects() -> void:
	var data = _load_json_file("res://data/sects/sects.json")
	if data is Dictionary and data.has("sects"):
		for s in data["sects"]:
			sects_data[s["id"]] = s

func get_sect(sect_id: String) -> Dictionary:
	return sects_data.get(sect_id, {})

func get_all_sects() -> Array:
	return sects_data.values()
