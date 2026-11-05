extends Node

## WorldRegistry — Quản lý đăng ký thế giới, quốc gia và 12 tỉnh (Thập Nhị Địa Chi)
## Cung cấp API tra cứu data-driven cho hệ thống Open World và Triều Đình.

var world_data: Dictionary = {}
var country_data: Dictionary = {}
var provinces_data: Dictionary = {}
var court_rules_data: Dictionary = {}

var province_roads: Dictionary = {}
var province_settlements: Dictionary = {}
var province_stations: Dictionary = {}
var province_landmarks: Dictionary = {}

var is_loaded: bool = false

func _ready() -> void:
	load_all_world_data()

func load_all_world_data() -> void:
	_load_world_registry()
	_load_country()
	_load_court_rules()
	_load_provinces()
	_load_detailed_province_data()
	is_loaded = true

func _load_detailed_province_data() -> void:
	# Nạp dữ liệu mở rộng cho Thìn Châu
	var r_data = _load_json_file("res://data/world/provinces/thin_chau/roads_rivers.json")
	if r_data is Dictionary:
		province_roads["thin_chau"] = r_data
		
	var s_data = _load_json_file("res://data/world/provinces/thin_chau/settlements.json")
	if s_data is Dictionary:
		province_settlements["thin_chau"] = s_data.get("settlements", [])
		
	var st_data = _load_json_file("res://data/world/provinces/thin_chau/fast_travel_stations.json")
	if st_data is Dictionary:
		province_stations["thin_chau"] = st_data.get("stations", [])
		
	var lm_data = _load_json_file("res://data/world/provinces/thin_chau/landmarks.json")
	if lm_data is Dictionary:
		province_landmarks["thin_chau"] = lm_data.get("landmarks", [])

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
			push_error("[WorldRegistry] Lỗi phân tích JSON tại %s: %s" % [path, json.get_error_message()])
	return null

func _load_world_registry() -> void:
	var data = _load_json_file("res://data/world/world_registry.json")
	if data is Dictionary:
		world_data = data
	else:
		world_data = {
			"world_id": "dao_tan_world_01",
			"country_id": "dai_huyen",
			"playable_province_id": "thin_chau",
			"server_clock_real_seconds_per_day": 720
		}

func _load_country() -> void:
	var data = _load_json_file("res://data/world/countries/dai_huyen/country.json")
	if data is Dictionary:
		country_data = data

func _load_court_rules() -> void:
	var data = _load_json_file("res://data/world/countries/dai_huyen/court_rules.json")
	if data is Dictionary:
		court_rules_data = data

func _load_provinces() -> void:
	provinces_data.clear()
	# Nạp tỉnh chính chơi được
	var thin_data = _load_json_file("res://data/world/provinces/thin_chau/province.json")
	if thin_data is Dictionary:
		provinces_data["thin_chau"] = thin_data
		
	# Nạp 11 tỉnh metadata
	var other_ids = ["ty_chau", "suu_chau", "dan_chau", "mao_chau", "ty_ran_chau", "ngo_chau", "mui_chau", "than_chau", "dau_chau", "tuat_chau", "hoi_chau"]
	for pid in other_ids:
		var p_data = _load_json_file("res://data/world/provinces/%s.json" % pid)
		if p_data is Dictionary:
			provinces_data[pid] = p_data

func get_world_info() -> Dictionary:
	return world_data

func get_country(country_id: String = "dai_huyen") -> Dictionary:
	if country_id == "dai_huyen":
		return country_data
	return {}

func get_province(province_id: String) -> Dictionary:
	return provinces_data.get(province_id, {})

func get_all_provinces() -> Array:
	return provinces_data.values()

func get_playable_province_id() -> String:
	return world_data.get("playable_province_id", "thin_chau")

func get_playable_province() -> Dictionary:
	return get_province(get_playable_province_id())

func get_settlement(province_id: String, settlement_id: String) -> Dictionary:
	var list = province_settlements.get(province_id, [])
	for s in list:
		if s.get("id") == settlement_id:
			return s
	var prov = get_province(province_id)
	for s in prov.get("settlements", []):
		if s.get("id") == settlement_id:
			return s
	return {}

func get_settlements(province_id: String) -> Array:
	if province_settlements.has(province_id) and not province_settlements[province_id].is_empty():
		return province_settlements[province_id]
	var prov = get_province(province_id)
	return prov.get("settlements", [])

func get_roads_and_rivers(province_id: String) -> Dictionary:
	return province_roads.get(province_id, {})

func get_fast_travel_stations(province_id: String) -> Array:
	return province_stations.get(province_id, [])

func get_fast_travel_station(province_id: String, station_id: String) -> Dictionary:
	for st in get_fast_travel_stations(province_id):
		if st.get("id") == station_id:
			return st
	return {}

func get_landmarks(province_id: String) -> Array:
	return province_landmarks.get(province_id, [])

func get_landmark(province_id: String, landmark_id: String) -> Dictionary:
	for lm in get_landmarks(province_id):
		if lm.get("id") == landmark_id:
			return lm
	return {}
