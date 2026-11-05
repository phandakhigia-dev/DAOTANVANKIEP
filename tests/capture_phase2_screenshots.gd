extends Node

## CapturePhase2Screenshots — Chụp ảnh kiểm thử thực tế các UI và hệ thống của Phase 2

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture] Bắt đầu chụp ảnh kiểm thử Phase 2 (Living-World & NPC AI)...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.modify_npc_relationship("npc_mac_tu_vien", "player", 25, 40, 20, 0)
	GameSession.modify_npc_relationship("npc_thu_nguyet", "player", 35, 50, 0, 0)
	GameSession.modify_npc_relationship("npc_doan_vinh", "player", -20, 0, 0, 45)
	GameSession.log_memory_event("player", "npc_mac_tu_vien", "rescue", "poi_rung_truc", ["npc_bach_san"], 2, true)
	GameSession.log_memory_event("player", "npc_thu_nguyet", "gift_linh_thao", "poi_thanh_tri_tran", [], 1, false)
	
	# Mô phỏng 1 tháng để sinh sự kiện thế giới thực tế
	var summary = MonthlySimulationService.simulate_month(2, 1)
	
	# 1. World Map với HUD thời gian thực (Canh giờ & các nút Phase 2)
	var world_map = preload("res://scenes/world/world_map.tscn").instantiate()
	add_child(world_map)
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("14_hud_realtime_clock.png")
	
	var hud = world_map.get_node_or_null("HUD")
	if hud:
		# 2. Sổ Nhân Duyên (Social Panel)
		var soc = hud.get_node_or_null("SocialPanel")
		if soc:
			soc.open_panel()
			soc._select_npc("npc_mac_tu_vien")
			await get_tree().create_timer(0.25).timeout
			_save_screenshot("15_social_panel_all.png")
			
			# 3. Sổ Nhân Duyên lọc theo Môn Phái Thanh Vi
			soc._set_filter("sect")
			await get_tree().create_timer(0.2).timeout
			_save_screenshot("16_social_panel_sect.png")
			soc.close_panel()
			
		# 4. Đại Sự Ký Thế Giới (Monthly Summary Modal) Tab Đột Phá
		var gazette = hud.get_node_or_null("MonthlySummaryModal")
		if gazette:
			gazette.open_modal(summary)
			await get_tree().create_timer(0.25).timeout
			_save_screenshot("17_monthly_summary_breakthrough.png")
			
			# 5. Đại Sự Ký Tab Thị Trường & Tin Đồn
			var tab_container = gazette.get_node_or_null("PanelContainer/Margin/VBox/TabContainer")
			if tab_container:
				tab_container.current_tab = 3 # Tab Thị Trường & Tin Đồn
			await get_tree().create_timer(0.25).timeout
			_save_screenshot("18_monthly_summary_market.png")
			gazette.close_modal()
	
	remove_child(world_map)
	world_map.queue_free()
	
	print("[Capture] Hoàn tất toàn bộ ảnh kiểm thử Phase 2!")
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
