extends Node

## CapturePhase0Screenshots — Chụp ảnh màn hình kiểm thử thực tế các UI và Scene của Phase 0

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	
	print("[Capture] Bắt đầu quy trình chụp ảnh kiểm thử Phase 0...")
	
	# 1. Main Menu
	var menu_scene = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(menu_scene)
	await get_tree().create_timer(0.2).timeout
	_save_screenshot("01_main_menu.png")
	
	# 2. New Game Modal
	var new_game_modal = menu_scene.get_node_or_null("NewGameModal")
	if new_game_modal:
		new_game_modal.visible = true
		await get_tree().create_timer(0.1).timeout
		_save_screenshot("02_new_game_modal.png")
		new_game_modal.visible = false
	
	# 3. Settings Modal
	var settings_modal = menu_scene.get_node_or_null("SettingsModal")
	if settings_modal:
		settings_modal.visible = true
		await get_tree().create_timer(0.1).timeout
		_save_screenshot("03_settings_modal.png")
		settings_modal.visible = false
	
	remove_child(menu_scene)
	menu_scene.queue_free()
	
	# 4. World Map (Khởi tạo phiên chơi mới với Seed 1337)
	GameSession.start_new_game("Lâm Phong", 1337)
	var world_scene = preload("res://scenes/world/world_map.tscn").instantiate()
	add_child(world_scene)
	await get_tree().create_timer(0.2).timeout
	_save_screenshot("04_world_map.png")
	
	# 5. Pause Menu
	var pause_menu = world_scene.get_node_or_null("HUD/PauseMenu")
	if pause_menu:
		pause_menu.visible = true
		await get_tree().create_timer(0.1).timeout
		_save_screenshot("05_world_paused.png")
	
	remove_child(world_scene)
	world_scene.queue_free()
	
	# 6. Main Menu with Save slot
	SaveService.save_game(1)
	var menu_with_save = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(menu_with_save)
	await get_tree().create_timer(0.2).timeout
	_save_screenshot("06_main_menu_with_save.png")
	remove_child(menu_with_save)
	menu_with_save.queue_free()
	
	print("[Capture] Hoàn tất toàn bộ chuỗi chụp ảnh kiểm thử!")
	get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var path = "%s/%s" % [OUTPUT_DIR, filename]
		var err = img.save_png(path)
		if err == OK:
			print("  ✓ Đã lưu ảnh: %s" % path)
		else:
			print("  ✗ Lỗi lưu ảnh %s: mã lỗi %d" % [path, err])
