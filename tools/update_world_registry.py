from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/world/world_registry.gd")
content = path.read_text(encoding="utf-8")

# 1. Update _load_provinces
old_p = """func _load_provinces() -> void:
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
			provinces_data[pid] = p_data"""

new_p = """func _load_provinces() -> void:
	provinces_data.clear()
	var all_ids = ["thin_chau", "ty_chau", "suu_chau", "dan_chau", "mao_chau", "ty_ran_chau", "ngo_chau", "mui_chau", "than_chau", "dau_chau", "tuat_chau", "hoi_chau"]
	for pid in all_ids:
		var p_data = _load_json_file("res://data/world/provinces/%s/province.json" % pid)
		if not p_data is Dictionary:
			p_data = _load_json_file("res://data/world/provinces/%s.json" % pid)
		if p_data is Dictionary:
			provinces_data[pid] = p_data"""

# 2. Update _load_detailed_province_data
old_d = """func _load_detailed_province_data() -> void:
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
		province_landmarks["thin_chau"] = lm_data.get("landmarks", [])"""

new_d = """func _load_detailed_province_data() -> void:
	var all_pids = ["thin_chau", "ty_chau", "suu_chau", "dan_chau", "mao_chau", "ty_ran_chau", "ngo_chau", "mui_chau", "than_chau", "dau_chau", "tuat_chau", "hoi_chau"]
	for pid in all_pids:
		var r_data = _load_json_file("res://data/world/provinces/%s/roads_rivers.json" % pid)
		if r_data is Dictionary:
			province_roads[pid] = r_data
		var s_data = _load_json_file("res://data/world/provinces/%s/settlements.json" % pid)
		if s_data is Dictionary:
			province_settlements[pid] = s_data.get("settlements", [])
		var st_data = _load_json_file("res://data/world/provinces/%s/fast_travel_stations.json" % pid)
		if st_data is Dictionary:
			province_stations[pid] = st_data.get("stations", [])
		var lm_data = _load_json_file("res://data/world/provinces/%s/landmarks.json" % pid)
		if lm_data is Dictionary:
			province_landmarks[pid] = lm_data.get("landmarks", [])"""

# Normalize CRLF
content_norm = content.replace("\r\n", "\n")
old_p_norm = old_p.replace("\r\n", "\n")
new_p_norm = new_p.replace("\r\n", "\n")
old_d_norm = old_d.replace("\r\n", "\n")
new_d_norm = new_d.replace("\r\n", "\n")

assert old_p_norm in content_norm, "old_p_norm not found!"
assert old_d_norm in content_norm, "old_d_norm not found!"

content_norm = content_norm.replace(old_p_norm, new_p_norm)
content_norm = content_norm.replace(old_d_norm, new_d_norm)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("SUCCESSFULLY UPDATED WorldRegistry.gd!")
