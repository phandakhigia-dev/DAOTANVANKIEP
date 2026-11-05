extends Node

## CapturePhase3SectsScreenshots — Chụp ảnh kiểm thử Hệ Thống Tông Môn & Thiên Kiếp
## Gồm:
## 31_sect_hall_thanh_vi.png: Phân Điện Thanh Vi Kiếm Tông
## 32_tang_kinh_cac_skills.png: Tàng Kinh Các & Công Pháp
## 33_tribulation_lightning.png: Thiên Kiếp Lôi Đình Đột Phá Trúc Cơ
## 34_sect_rank_promotion.png: Thăng Cấp Nội Môn & Hồ Sơ Nhân Vật

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture Phase 3] Bắt đầu chụp ảnh kiểm thử Tông Môn, Tàng Kinh Các & Thiên Kiếp...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.add_item("item_linh_thach", 500)
	GameSession.add_item("item_co_kiem_tan_phien", 2)
	GameSession.add_item("item_tay_tuy_dan", 2)
	GameSession.npc_affinities["npc_doan_vinh"] = 35
	
	var SectService = load("res://scripts/domain/sect_service.gd")
	
	# 1. Chụp Phân Điện Thanh Vi Kiếm Tông
	var hall_scene = preload("res://scenes/sects/sect_hall.tscn").instantiate()
	add_child(hall_scene)
	var hall_player = hall_scene.get_node_or_null("YEntities/Player")
	if hall_player:
		hall_player.position = Vector2(300, 380) # Gần Bia Đăng Ký Môn Phái
	hall_scene._set_nearby_prompt("sect_stone", "[E: Bia Đăng Ký • Nhập Môn Thanh Vi Kiếm Tông & Khảo Thí]")
	await get_tree().create_timer(0.5).timeout
	_save_screenshot("31_sect_hall_thanh_vi.png")
	
	# 2. Gia nhập tông môn và chụp Tàng Kinh Các (Library Panel)
	SectService.join_sect("sect_thanh_vi")
	GameSession.sect_contribution = 150
	SectService.learn_library_skill("lib_thanh_vi_jian_fa")
	
	var sect_panel = hall_scene.get_node_or_null("HUD/SectPanel")
	if sect_panel:
		sect_panel.open_panel()
	await get_tree().create_timer(0.5).timeout
	_save_screenshot("32_tang_kinh_cac_skills.png")
	
	if sect_panel:
		sect_panel.close_panel()
	remove_child(hall_scene)
	hall_scene.queue_free()
	
	# 3. Chụp Thiên Kiếp Lôi Đình (Tribulation Arena)
	GameSession.realm_id = "realm_luyen_khi_9"
	GameSession.cultivation_xp = 900
	GameSession.max_cultivation_xp = 900
	GameSession.pending_tribulation = true
	GameSession.current_hp = 480
	GameSession.max_hp = 480
	
	var trib_scene = preload("res://scenes/cultivation/tribulation_arena.tscn").instantiate()
	add_child(trib_scene)
	# Giả lập sét đánh tạo hiệu ứng đồ họa
	trib_scene._strike_lightning(40)
	await get_tree().create_timer(0.5).timeout
	_save_screenshot("33_tribulation_lightning.png")
	remove_child(trib_scene)
	trib_scene.queue_free()
	
	# 4. Chụp Hồ Sơ Nhân Vật Thăng Cấp Nội Môn & Đột Phá
	GameSession.complete_truc_co_tribulation(true)
	GameSession.sect_contribution = 450
	SectService._refresh_rank()
	
	var char_panel = preload("res://scenes/ui/character_panel.tscn").instantiate()
	add_child(char_panel)
	char_panel.open_panel()
	await get_tree().create_timer(0.5).timeout
	_save_screenshot("34_sect_rank_promotion.png")
	remove_child(char_panel)
	char_panel.queue_free()
	
	print("[Capture Phase 3] Hoàn tất chụp toàn bộ 4 ảnh kiểm thử Phase 3!")
	get_tree().quit()

func _save_screenshot(filename: String) -> void:
	var image = get_viewport().get_texture().get_image()
	var path = OUTPUT_DIR.path_join(filename)
	var err = image.save_png(path)
	if err == OK:
		print("  -> Đã lưu ảnh: ", path)
	else:
		push_error("Lỗi khi lưu ảnh kiểm thử: %s (Mã lỗi: %d)" % [path, err])
