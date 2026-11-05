extends Node

## CourtManager — Quản lý Triều Đình Đại Huyền và Sắc Lệnh Quốc Gia
## Tác động đến kinh tế (thuế chợ, giá cả), an ninh và bố cáo ngoại ô toàn tỉnh.

const WorldRegistryScript = preload("res://scripts/world/world_registry.gd")

var active_decrees: Array[Dictionary] = [] # [{ "id": String, "issued_day": int, "duration_days": int }]
var treasury_gold: int = 10000000
var national_tax_rate: float = 0.05
var market_tax_multiplier: float = 1.0
var monster_bounty_multiplier: float = 1.0
var medicine_price_discount: float = 0.0

func _ready() -> void:
	reset_court_state()

func reset_court_state() -> void:
	active_decrees.clear()
	treasury_gold = 10000000
	national_tax_rate = 0.05
	market_tax_multiplier = 1.0
	monster_bounty_multiplier = 1.0
	medicine_price_discount = 0.0

func issue_decree(decree_id: String, duration_days: int = 30) -> bool:
	# Tra cứu định nghĩa chiếu chỉ từ file json
	var rules_file = "res://data/world/countries/dai_huyen/court_rules.json"
	var rules = _load_json(rules_file)
	if not rules or not rules.has("decrees"):
		return false
		
	var target_decree: Dictionary = {}
	for d in rules["decrees"]:
		if d.get("id") == decree_id:
			target_decree = d
			break
			
	if target_decree.is_empty():
		push_warning("[CourtManager] Không tìm thấy chiếu chỉ: " + decree_id)
		return false
		
	# Hủy chiếu chỉ cũ cùng id nếu có
	cancel_decree(decree_id)
	
	var current_day = GameClock.total_days_elapsed if GameClock else 1
	var decree_entry = {
		"id": decree_id,
		"title": target_decree.get("title", ""),
		"effects": target_decree.get("effects", {}),
		"issued_day": current_day,
		"duration_days": duration_days
	}
	active_decrees.append(decree_entry)
	_recalculate_modifiers()
	
	if EventBus and EventBus.has_signal("notification_requested"):
		EventBus.notification_requested.emit("📜 [TRIỀU ĐÌNH ĐẠI HUYỀN] Ban bố: %s" % target_decree.get("title", ""), "info")
	
	return true

func cancel_decree(decree_id: String) -> void:
	for i in range(active_decrees.size() - 1, -1, -1):
		if active_decrees[i].get("id") == decree_id:
			active_decrees.remove_at(i)
	_recalculate_modifiers()

func _recalculate_modifiers() -> void:
	# Reset về giá trị mặc định
	market_tax_multiplier = 1.0
	monster_bounty_multiplier = 1.0
	medicine_price_discount = 0.0
	
	for entry in active_decrees:
		var eff = entry.get("effects", {})
		if eff.has("stall_lease_multiplier"):
			market_tax_multiplier *= eff["stall_lease_multiplier"]
		if eff.has("monster_bounty_multiplier"):
			monster_bounty_multiplier *= eff["monster_bounty_multiplier"]
		if eff.has("medicine_price_discount"):
			medicine_price_discount = maxf(medicine_price_discount, eff["medicine_price_discount"])
		if eff.has("treasury_delta"):
			treasury_gold += int(eff["treasury_delta"])

func get_active_decrees() -> Array[Dictionary]:
	return active_decrees

func is_decree_active(decree_id: String) -> bool:
	for d in active_decrees:
		if d.get("id") == decree_id:
			return true
	return false

func export_court_dict() -> Dictionary:
	var dup_decrees: Array[Dictionary] = []
	for d in active_decrees:
		dup_decrees.append(d.duplicate(true))
	return {
		"treasury_gold": treasury_gold,
		"active_decrees": dup_decrees,
		"market_tax_multiplier": market_tax_multiplier,
		"monster_bounty_multiplier": monster_bounty_multiplier,
		"medicine_price_discount": medicine_price_discount
	}

func to_dict() -> Dictionary:
	return export_court_dict()

func import_court_dict(data: Dictionary) -> void:
	treasury_gold = int(data.get("treasury_gold", 10000000))
	active_decrees.clear()
	var raw_decrees = data.get("active_decrees", [])
	for d in raw_decrees:
		if d is Dictionary:
			active_decrees.append(Dictionary(d))
	_recalculate_modifiers()

func from_dict(data: Dictionary) -> void:
	import_court_dict(data)

func _load_json(path: String) -> Variant:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			return json.data
	return null
