extends Node

## CapturePhase4Screenshots — Chụp ảnh kiểm thử Thành Trì Nhập Vai Thực Tế & NPC Thủ Tục
## Gồm: Toàn cảnh TownMapReal, Đối thoại Chiều Sâu Nhân Sinh, và Khung cảnh Thị trấn ban đêm với Đèn lồng phát sáng.

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"
const ShopService = preload("res://scripts/domain/shop_service.gd")
const LifeGenerator = preload("res://scripts/domain/life_generator.gd")

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture Phase 4] Bắt đầu chụp ảnh kiểm thử Thành Trì Nhập Vai & NPC Thủ Tục...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.add_item("item_linh_thach", 450)
	GameSession.add_item("item_linh_thao", 10)
	GameSession.add_item("item_tu_khi_dan", 5)
	
	# Thuê sạp và ký gửi hàng
	ShopService.lease_stall(1)
	ShopService.deposit_item("item_tu_khi_dan", 3, 25)
	ShopService.accumulated_revenue = 75
	ShopService.total_sales_count = 3
	
	# 1. Chụp Toàn Cảnh TownMapReal Ban Ngày
	var town_scene = preload("res://scenes/towns/town_map_real.tscn").instantiate()
	add_child(town_scene)
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("25_living_town_real_map.png")
	
	# 2. Chụp Đối Thoại Chiều Sâu Nhân Sinh với NPC Thủ Tục
	var dlg_modal = town_scene.get_node_or_null("HUD/DialogueModal")
	if dlg_modal and town_scene.procedural_npcs.size() > 0:
		var sample_npc = town_scene.procedural_npcs[0].npc_data
		dlg_modal.open_for_custom_npc(sample_npc)
		dlg_modal._on_custom_chat_pressed()
		await get_tree().create_timer(0.4).timeout
		_save_screenshot("26_procedural_npc_dialogue_depth.png")
		dlg_modal.close_dialogue()
		
	# 3. Chụp Thị Trấn Ban Đêm (Giờ Tuất 20:00 - CanvasModulate & Đèn Lồng Rực Rỡ)
	GameClock.advance_hours(14)
	town_scene._update_atmosphere()
	town_scene._update_header()
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("27_town_night_lanterns.png")
	
	remove_child(town_scene)
	town_scene.queue_free()
	
	print("[Capture Phase 4] Hoàn tất chụp toàn bộ ảnh kiểm thử!")
	get_tree().quit()

func _save_screenshot(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	var global_path = ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	var err = img.save_png(global_path)
	if err == OK:
		print("  ✓ Đã lưu ảnh: %s" % filename)
	else:
		push_error("Lỗi lưu ảnh %s: %d" % [filename, err])
