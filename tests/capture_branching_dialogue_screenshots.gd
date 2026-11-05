extends Node

## CaptureBranchingDialogueScreenshots — Chụp ảnh kiểm thử Hệ thống Đối Thoại 3-5 Lựa Chọn & Kiến Tạo Thế Giới
## Gồm:
## 39_dialogue_branching_choices.png: Giao diện 5 nhánh lựa chọn vấn đạo (Chính Đạo, Ma Đạo, Thương Lộ, Đạo Duyên, Bình Thản)
## 40_dialogue_world_shaping_consequence.png: Phản hồi lời thoại NPC & Bảng tổng kết Ảnh Hưởng Thế Giới & Nhân Quả
## 41_procedural_npc_branching_dilemma.png: Tình huống tán tu dã ngoại thủ tục với 5 nhánh can thiệp số mệnh

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture Dialogue] Bắt đầu chụp ảnh kiểm thử Branching Dialogue & World Shaping...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.add_item("item_linh_thach", 100)
	GameSession.add_item("item_linh_thao", 10)
	GameSession.add_item("item_hoi_xuan_dan", 2)
	
	# Tạo nền thị trấn phía sau cho chân thực
	var town_scene = preload("res://scenes/towns/town_map_real.tscn").instantiate()
	add_child(town_scene)
	
	var ModalScene = preload("res://scenes/ui/dialogue_modal.tscn")
	var modal = ModalScene.instantiate()
	add_child(modal)
	
	# 1. Chụp 39: 5 Nhánh Lựa Chọn Vấn Đạo với Mạc Tư Viễn
	modal.open_for_npc("npc_mac_tu_vien")
	modal._open_scenario_view()
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("39_dialogue_branching_choices.png")
	
	# 2. Chụp 40: Thực thi lựa chọn [Chính Đạo] & Bảng Biến Động Thế Giới
	modal._on_scenario_choice_selected("mac_righteous")
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("40_dialogue_world_shaping_consequence.png")
	
	# 3. Chụp 41: Tán tu dã ngoại thủ tục với khát vọng Cứu Muội Muội Hoạn Nạn
	var wanderer_data = {
		"id": "npc_wanderer_sister_cure",
		"name": "Diệp Thanh Ca",
		"role": "Kiếm Sĩ Tán Tu",
		"realm_name": "Luyện Khí Tầng 2",
		"realm_stage": 2,
		"core_drive": {
			"id": "drive_save_kin",
			"title": "Cứu Muội Muội Hoạn Nạn",
			"desc": "Muội muội duy nhất trúng hàn độc kỳ dị, tìm linh dược cứu mạng."
		},
		"life_secret": {
			"title": "Nửa Khối Ngọc Bội",
			"desc": "Mang nửa khối ngọc bội tìm kiếm thân nhân thất lạc."
		},
		"quirk": { "name": "Uống Rượu Một Mình" },
		"location": "poi_thanh_tri_tran",
		"age_years": 23,
		"max_lifespan_years": 100
	}
	modal.open_for_custom_npc(wanderer_data)
	modal._open_scenario_view()
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("41_procedural_npc_branching_dilemma.png")
	
	remove_child(modal)
	modal.queue_free()
	remove_child(town_scene)
	town_scene.queue_free()
	
	print("[Capture Dialogue] Hoàn tất chụp 3 ảnh kiểm thử Branching Dialogue & World Shaping!")
	get_tree().quit()

func _save_screenshot(filename: String) -> void:
	var image = get_viewport().get_texture().get_image()
	var path = OUTPUT_DIR.path_join(filename)
	var err = image.save_png(path)
	if err == OK:
		print("  -> Đã lưu ảnh: ", path)
	else:
		push_error("Lỗi khi lưu ảnh: %s (Mã lỗi: %d)" % [path, err])
