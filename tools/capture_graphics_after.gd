extends Node

## CaptureGraphicsAfter — Chụp 8 ảnh thực tế từ build game runnable sau nâng cấp
## Lưu vào audit/graphics_after/

var step: int = 0
var timer: float = 0.0
var output_dir: String = "res://audit/graphics_after/"

var current_instance: Node = null

func _ready() -> void:
	print("[SCREENSHOT] Bắt đầu quy trình chụp 8 ảnh nghiệm thu đồ họa...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	GameSession.start_new_game("Lâm Phong", 888999)
	GameSession.add_item("item_hoi_xuan_dan", 10)
	GameSession.add_item("item_linh_thach", 500)
	_run_step()

func _process(delta: float) -> void:
	timer += delta
	if timer >= 0.2:
		timer = 0.0
		_capture_and_advance()

func _run_step() -> void:
	if current_instance:
		current_instance.queue_free()
		current_instance = null
		
	match step:
		0:
			# 1. world_day.png
			print("[SCREENSHOT 1/8] Chụp world_day.png...")
			GameClock.reset_clock()
			GameClock.second_in_day = 12.0 * 3600.0 # 12:00 Trưa
			GameClock._update_time_components()
			var scn = load("res://scenes/world/world_map.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
			if "day_night_modulate" in current_instance and current_instance.day_night_modulate:
				current_instance.day_night_modulate.color = Color(1.0, 1.0, 1.0, 1.0) # Ban ngày rực rỡ
		1:
			# 2. world_night.png
			print("[SCREENSHOT 2/8] Chụp world_night.png...")
			GameClock.reset_clock()
			GameClock.second_in_day = 0.0 # 00:00 Nửa đêm
			GameClock._update_time_components()
			var scn = load("res://scenes/world/world_map.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
			if "day_night_modulate" in current_instance and current_instance.day_night_modulate:
				current_instance.day_night_modulate.color = Color(0.42, 0.46, 0.68, 1.0) # Ánh trăng xanh huyền ảo ban đêm
		2:
			# 3. town.png
			print("[SCREENSHOT 3/8] Chụp town.png...")
			var scn = load("res://scenes/towns/town_map_real.tscn")
			if not scn:
				scn = load("res://scenes/towns/town_view.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
		3:
			# 4. combat.png
			print("[SCREENSHOT 4/8] Chụp combat.png...")
			var scn = load("res://scenes/combat/combat_arena.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
		4:
			# 5. combat_vfx.png
			print("[SCREENSHOT 5/8] Chụp combat_vfx.png...")
			var scn = load("res://scenes/combat/combat_arena.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
			
			# Thêm hiệu ứng chém kiếm quang và sấm sét
			var slash_scn = load("res://scenes/vfx/vfx_sword_slash.tscn")
			if slash_scn:
				var slash = slash_scn.instantiate()
				slash.position = Vector2(640, 360)
				current_instance.add_child(slash)
			var light_scn = load("res://scenes/vfx/vfx_lightning_impact.tscn")
			if light_scn:
				var light = light_scn.instantiate()
				light.position = Vector2(720, 320)
				current_instance.add_child(light)
		5:
			# 6. cultivation_aura.png
			print("[SCREENSHOT 6/8] Chụp cultivation_aura.png...")
			var scn = load("res://scenes/cultivation/tribulation_arena.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
			var aura_scn = load("res://scenes/vfx/vfx_cultivation_aura.tscn")
			if aura_scn:
				var aura = aura_scn.instantiate()
				aura.position = Vector2(640, 420)
				current_instance.add_child(aura)
		6:
			# 7. ui_shop.png
			print("[SCREENSHOT 7/8] Chụp ui_shop.png...")
			ShopService.reset_stall()
			ShopService.is_leased = true
			ShopService.stall_name = "Thiên Đạo Các (Lâm Phong)"
			ShopService.deposit_item("item_hoi_xuan_dan", 5, 25)
			ShopService.deposit_item("item_co_kiem_tan_phien", 2, 80)
			ShopService.accumulated_revenue = 150
			
			var bg_scn = load("res://scenes/towns/town_view.tscn")
			current_instance = bg_scn.instantiate()
			add_child(current_instance)
			
			var shop_scn = load("res://scenes/ui/player_shop_modal.tscn")
			if shop_scn:
				var shop = shop_scn.instantiate()
				current_instance.add_child(shop)
				if shop.has_method("open_panel"):
					shop.open_panel()
				elif shop.has_method("open_shop"):
					shop.open_shop()
		7:
			# 8. coop_two_players.png (Staged Demo mockup - Minh bạch)
			print("[SCREENSHOT 8/11] Chụp coop_two_players.png (STAGED_DEMO)...")
			var scn = load("res://scenes/world/world_map.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
			
			# Tạo thêm nhân vật người chơi thứ 2 (Đạo Hữu Khách)
			var player_scn = load("res://scenes/world/player.tscn")
			if player_scn:
				var p2 = player_scn.instantiate()
				p2.position = Vector2(620, 380)
				p2.modulate = Color(0.6, 0.9, 1.0) # Sắc lam nhạt phân biệt khách
				current_instance.add_child(p2)
				
				# Thêm nhãn tên Co-op
				var lbl = Label.new()
				lbl.text = "[STAGED_DEMO] Tiêu Viêm (Client)"
				lbl.position = Vector2(-80, -45)
				lbl.modulate = Color(0.4, 0.9, 1.0)
				p2.add_child(lbl)
				
			# Nhãn HUD hiển thị phòng Co-op
			var hud_lbl = Label.new()
			hud_lbl.text = "★ [STAGED_DEMO] 2 Avatar | Co-op 2 Cửa Sổ Thật Xem: coop_host_window.png & coop_client_window.png"
			hud_lbl.position = Vector2(40, 20)
			hud_lbl.modulate = Color(1.0, 0.85, 0.2)
			current_instance.add_child(hud_lbl)
		8:
			# 9. bamboo_forest.png
			print("[SCREENSHOT 9/11] Chụp bamboo_forest.png...")
			var scn = load("res://scenes/biomes/bamboo_forest.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
		9:
			# 10. snake_swamp.png
			print("[SCREENSHOT 10/11] Chụp snake_swamp.png...")
			var scn = load("res://scenes/biomes/snake_swamp.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)
		10:
			# 11. sword_grave.png
			print("[SCREENSHOT 11/11] Chụp sword_grave.png...")
			var scn = load("res://scenes/biomes/sword_grave.tscn")
			current_instance = scn.instantiate()
			add_child(current_instance)

func _capture_and_advance() -> void:
	var filenames = [
		"world_day.png",
		"world_night.png",
		"town.png",
		"combat.png",
		"combat_vfx.png",
		"cultivation_aura.png",
		"ui_shop.png",
		"coop_two_players.png",
		"bamboo_forest.png",
		"snake_swamp.png",
		"sword_grave.png"
	]
	
	var img = get_viewport().get_texture().get_image()
	if img:
		var target_file = output_dir + filenames[step]
		var abs_target = ProjectSettings.globalize_path(target_file)
		var err = img.save_png(abs_target)
		print("  -> Đã lưu %s (Lỗi: %d, Kích thước: %s)" % [filenames[step], err, str(img.get_size())])
	else:
		print("  -> LỖI: Không thể lấy get_image() từ viewport!")
		
	step += 1
	if step < filenames.size():
		_run_step()
	else:
		print("[SCREENSHOT] Hoàn tất chụp toàn bộ 8 ảnh nghiệm thu!")
		get_tree().quit(0)
