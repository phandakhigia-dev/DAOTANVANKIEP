from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scripts/world/chunk_streamer.gd")
content = path.read_text(encoding="utf-8")

old_code = """func _populate_bamboo_forest_biome(parent: Node2D) -> void:
	# Thạch Động Cổ Bí Cảnh
	_spawn_instance(CavernEntranceScene, parent, Vector2(1024, 800))
	_spawn_instance(AncientPineScene, parent, Vector2(880, 780))
	_spawn_instance(AncientPineScene, parent, Vector2(1160, 780))
	
	# Rừng trúc bạt ngàn
	var bamboo_spots = [
		Vector2(400, 400), Vector2(700, 350), Vector2(1400, 450), Vector2(1700, 380),
		Vector2(350, 900), Vector2(600, 1100), Vector2(1450, 1050), Vector2(1650, 850),
		Vector2(500, 1500), Vector2(800, 1600), Vector2(1300, 1550), Vector2(1600, 1450)
	]
	for p in bamboo_spots:
		_spawn_instance(BambooClusterScene, parent, p)

func _populate_snake_swamp_biome(parent: Node2D) -> void:
	# Tế Đàn Độc Xà
	_spawn_instance(SwampShrineScene, parent, Vector2(1024, 1024))
	_spawn_instance(AncientPineScene, parent, Vector2(850, 980))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 980))

func _populate_sword_grave_biome(parent: Node2D) -> void:
	# Cổ Kiếm Tàn Đài
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 1024))
	_spawn_instance(SwordMonolithScene, parent, Vector2(600, 800))
	_spawn_instance(SwordMonolithScene, parent, Vector2(1450, 1200))"""

new_code = """func _populate_bamboo_forest_biome(parent: Node2D) -> void:
	# Thạch Động Cổ Bí Cảnh
	_spawn_instance(CavernEntranceScene, parent, Vector2(1024, 800))
	_spawn_instance(AncientPineScene, parent, Vector2(880, 780))
	_spawn_instance(AncientPineScene, parent, Vector2(1160, 780))
	
	# Sào Huyệt Boss Xích Kiếm Ma Thứu (Đông Bắc)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1464, 736))
	_spawn_instance(StoneLanternScene, parent, Vector2(1400, 750))
	_spawn_instance(StoneLanternScene, parent, Vector2(1520, 750))
	
	# Bãi Quái Rừng Trúc (Linh Hồ & Bạch Xuyên Thú - Nam)
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1336))
	_spawn_instance(AncientPineScene, parent, Vector2(960, 1336))
	
	# Rừng trúc bạt ngàn
	var bamboo_spots = [
		Vector2(400, 400), Vector2(700, 350), Vector2(1400, 450), Vector2(1700, 380),
		Vector2(350, 900), Vector2(600, 1100), Vector2(1450, 1050), Vector2(1650, 850),
		Vector2(500, 1500), Vector2(800, 1600), Vector2(1300, 1550), Vector2(1600, 1450)
	]
	for p in bamboo_spots:
		_spawn_instance(BambooClusterScene, parent, p)

func _populate_snake_swamp_biome(parent: Node2D) -> void:
	# Tế Đàn Độc Xà (Trung tâm)
	_spawn_instance(SwampShrineScene, parent, Vector2(1024, 1024))
	_spawn_instance(AncientPineScene, parent, Vector2(850, 980))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 980))
	
	# Sào Huyệt Boss Hắc Linh Xà Vương (Bắc)
	_spawn_instance(SwampShrineScene, parent, Vector2(1024, 616))
	_spawn_instance(StoneLanternScene, parent, Vector2(940, 640))
	_spawn_instance(StoneLanternScene, parent, Vector2(1100, 640))
	
	# Ổ Quái Hắc Linh Xà (Tây)
	_spawn_instance(StoneLanternScene, parent, Vector2(612, 1024))
	_spawn_instance(AncientPineScene, parent, Vector2(580, 1000))

func _populate_sword_grave_biome(parent: Node2D) -> void:
	# Cổ Kiếm Tàn Đài (Trung tâm)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 1024))
	
	# Sào Huyệt Boss Cổ Kiếm Linh (Bắc)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 564))
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 580))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 580))
	
	# Bãi Quái Kiếm Nô Tàn Linh (Tây)
	_spawn_instance(SwordMonolithScene, parent, Vector2(616, 1024))
	
	# Tàn Kiếm Bia Lĩnh Ngộ Kiếm Ý (Đông Nam)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1416, 1264))
	_spawn_instance(StoneLanternScene, parent, Vector2(1360, 1264))"""

content_norm = content.replace("\r\n", "\n")
old_norm = old_code.replace("\r\n", "\n")
new_norm = new_code.replace("\r\n", "\n")

assert old_norm in content_norm, "Target not found in chunk_streamer.gd!"
content_norm = content_norm.replace(old_norm, new_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully updated chunk_streamer.gd with monster camps & boss markers!")
