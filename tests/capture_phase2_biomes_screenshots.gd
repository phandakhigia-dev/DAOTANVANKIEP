extends Node

## CapturePhase2BiomesScreenshots — Chụp ảnh kiểm thử Đa Phân Vùng & Hang Động Bí Cảnh
## Gồm: Rừng Trúc Vạn Lĩnh (28), Đầm Lầy Hắc Xà (29), và Cổ Kiếm Trũng (30).

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture Phase 2] Bắt đầu chụp ảnh kiểm thử Đa Phân Vùng & Bí Cảnh...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.add_item("item_linh_thach", 300)
	GameSession.add_item("item_tu_khi_dan", 4)
	GameSession.add_item("item_linh_thao", 6)
	
	# 1. Chụp Rừng Trúc Vạn Lĩnh (Emerald Bamboo Biome & Cavern)
	var bamboo_scene = preload("res://scenes/biomes/bamboo_forest.tscn").instantiate()
	add_child(bamboo_scene)
	var bamboo_player = bamboo_scene.get_node_or_null("YEntities/Player")
	if bamboo_player:
		bamboo_player.position = Vector2(240, 240) # Gần Thạch Động Ẩn Tàng
	bamboo_scene._set_nearby_prompt("dungeon_cavern", "[E: Khám phá Thạch Động Ẩn Tàng (Rương Cổ Bí Cảnh)]")
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("28_bamboo_forest_biome.png")
	remove_child(bamboo_scene)
	bamboo_scene.queue_free()
	
	# 2. Chụp Đầm Lầy Hắc Xà (Murky Poison Swamp & Serpent Altar)
	var swamp_scene = preload("res://scenes/biomes/snake_swamp.tscn").instantiate()
	add_child(swamp_scene)
	var swamp_player = swamp_scene.get_node_or_null("YEntities/Player")
	if swamp_player:
		swamp_player.position = Vector2(500, 300) # Gần Tế Đàn Xà Cốt
	swamp_scene._set_nearby_prompt("serpent_altar", "[E: Tế Đàn Xà Cốt • Hiến tế 15 Linh Thạch đổi Kim Sang Dược]")
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("29_snake_swamp_biome.png")
	remove_child(swamp_scene)
	swamp_scene.queue_free()
	
	# 3. Chụp Cổ Kiếm Trũng (Ancient Sword Grave Crags & Sword Stele)
	var sword_scene = preload("res://scenes/biomes/sword_grave.tscn").instantiate()
	add_child(sword_scene)
	var sword_player = sword_scene.get_node_or_null("YEntities/Player")
	if sword_player:
		sword_player.position = Vector2(260, 320) # Gần Tàn Kiếm Bia
	sword_scene._set_nearby_prompt("sword_stele", "[E: Tàn Kiếm Bia • Đốn ngộ kiếm ngân cổ đại +50 Tu Vi]")
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("30_sword_grave_biome.png")
	remove_child(sword_scene)
	sword_scene.queue_free()
	
	print("[Capture Phase 2] Hoàn tất chụp toàn bộ ảnh kiểm thử!")
	get_tree().quit()

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	var global_path = ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	var err = img.save_png(global_path)
	if err == OK:
		print("  ✓ Đã lưu ảnh: %s" % filename)
	else:
		push_error("Lỗi lưu ảnh %s: %d" % [filename, err])
