extends Node

## CapturePhase1Screenshots — Chụp ảnh màn hình kiểm thử thực tế các UI và Scene của Phase 1

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
	
	print("[Capture] Bắt đầu quy trình chụp ảnh kiểm thử Phase 1...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.add_item("item_tu_khi_dan", 2)
	GameSession.add_item("item_linh_thach", 120)
	GameSession.add_item("item_linh_thao", 5)
	
	# 1. Town View (Thị trấn Thanh Trì)
	var town_scene = preload("res://scenes/towns/town_view.tscn").instantiate()
	add_child(town_scene)
	await get_tree().create_timer(0.25).timeout
	_save_screenshot("07_town_view.png")
	
	# 2. Dialogue Modal với NPC Mạc Tư Viễn
	var dlg = town_scene.get_node_or_null("CanvasLayer/DialogueModal")
	if dlg:
		dlg.open_for_npc("npc_mac_tu_vien")
		await get_tree().create_timer(0.2).timeout
		_save_screenshot("08_dialogue_modal.png")
		dlg.close_dialogue()
	
	# 3. Inventory Panel
	var inv = town_scene.get_node_or_null("CanvasLayer/InventoryPanel")
	if inv:
		inv.open_panel()
		await get_tree().create_timer(0.2).timeout
		_save_screenshot("09_inventory_panel.png")
		inv.close_panel()
	
	# 4. Character Panel & Breakthrough UI
	var char_panel = town_scene.get_node_or_null("CanvasLayer/CharacterPanel")
	if char_panel:
		GameSession.cultivation_xp = 100
		char_panel.open_panel()
		await get_tree().create_timer(0.2).timeout
		_save_screenshot("10_character_panel.png")
		char_panel.close_panel()
	
	remove_child(town_scene)
	town_scene.queue_free()
	
	# 5. Combat Arena (Wave 1: Linh Hồ)
	var combat_scene = preload("res://scenes/combat/combat_arena.tscn").instantiate()
	add_child(combat_scene)
	await get_tree().create_timer(0.25).timeout
	_save_screenshot("11_combat_arena.png")
	
	# 6. Boss Fight & Telegraph (Wave 3: Boss Xích Kiếm Ma Thứu)
	combat_scene._start_wave(3)
	if combat_scene.boss_ref:
		combat_scene.boss_ref.telegraph = {
			"type": "circle",
			"pos": combat_scene.boss_ref.pos,
			"radius": 150.0,
			"timer": 1.0,
			"max_timer": 1.2
		}
	combat_scene.queue_redraw()
	await get_tree().create_timer(0.25).timeout
	_save_screenshot("12_boss_fight_telegraph.png")
	
	# 7. Combat Victory Overlay
	combat_scene._on_boss_killed()
	await get_tree().create_timer(0.25).timeout
	_save_screenshot("13_combat_victory.png")
	
	remove_child(combat_scene)
	combat_scene.queue_free()
	
	print("[Capture] Hoàn tất chụp toàn bộ ảnh kiểm thử Phase 1!")
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var target_path = OUTPUT_DIR + "/" + filename
		var err = img.save_png(target_path)
		if err == OK:
			print("  [Screenshot] Đã lưu ảnh thành công: %s" % target_path)
		else:
			print("  [Screenshot] Lỗi lưu ảnh: %d" % err)
	else:
		print("  [Screenshot] Lỗi lấy viewport image.")
