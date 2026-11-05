extends Node

## CapturePhase3Screenshots — Chụp ảnh kiểm thử thực tế Phase 3 & Sprint S2/S3
## Gồm: TownView 12 Canh Giờ, Luyện Đan Các, Sạp Hàng Tu Sĩ Ký Gửi, Boss Xà Vương & Boss Cổ Kiếm Linh.

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"
const ShopService = preload("res://scripts/domain/shop_service.gd")

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture] Bắt đầu chụp ảnh kiểm thử Phase 3 & S2/S3...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.realm_id = "realm_luyen_khi_1" # Đã đột phá Luyện Khí
	GameSession.add_item("item_linh_thach", 350)
	GameSession.add_item("item_linh_thao", 6)
	GameSession.add_item("item_da_huong_thao", 4)
	GameSession.add_item("item_bach_thao_diep", 5)
	GameSession.add_item("item_hoi_xuan_dan", 4)
	
	# Thuê sạp và ký gửi hàng sẵn
	ShopService.lease_stall(1)
	ShopService.deposit_item("item_hoi_xuan_dan", 2, 25)
	ShopService.accumulated_revenue = 50
	ShopService.total_sales_count = 2
	
	# 1. Chụp Town View với thanh 12 Canh Giờ & Tu Sĩ Vãng Lai
	var town_scene = preload("res://scenes/towns/town_view.tscn").instantiate()
	add_child(town_scene)
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("19_town_view_dynamic_routine.png")
	
	# 2. Chụp Giao diện Luyện Đan (Alchemy Modal)
	var alc_modal = town_scene.get_node_or_null("CanvasLayer/AlchemyModal")
	if alc_modal:
		alc_modal.open_panel()
		alc_modal._selected_recipe_id = "recipe_tu_khi_dan"
		alc_modal._refresh_ui()
		await get_tree().create_timer(0.3).timeout
		_save_screenshot("20_alchemy_modal_crafting.png")
		alc_modal.close_panel()
		
	# 3. Chụp Giao diện Sạp Hàng Tu Sĩ Ký Gửi (Player Stall Modal)
	var shop_modal = town_scene.get_node_or_null("CanvasLayer/PlayerShopModal")
	if shop_modal:
		shop_modal.open_panel()
		await get_tree().create_timer(0.3).timeout
		_save_screenshot("21_player_stall_escrow.png")
		shop_modal.close_panel()
		
	remove_child(town_scene)
	town_scene.queue_free()
	
	# 4. Chụp Combat Arena với Boss Hắc Linh Xà Vương (Cone Poison Spit Telegraph)
	var arena_scene = preload("res://scenes/combat/combat_arena.tscn").instantiate()
	arena_scene.set_target_boss("boss_hac_linh_xa_vuong")
	add_child(arena_scene)
	await get_tree().create_timer(0.15).timeout
	# Bỏ qua wave thường, gọi thẳng boss wave
	arena_scene._start_wave(3)
	await get_tree().create_timer(0.15).timeout
	
	# Giả lập Telegraph Quạt Độc đang chuẩn bị phun
	if arena_scene.boss_ref:
		arena_scene.boss_ref.telegraph = {
			"type": "cone",
			"pos": arena_scene.boss_ref.pos,
			"dir": (arena_scene.player_pos - arena_scene.boss_ref.pos).normalized(),
			"radius": 240.0,
			"angle": PI * 0.45,
			"timer": 1.0,
			"max_timer": 1.3
		}
	arena_scene.queue_redraw()
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("22_combat_boss_hac_linh_xa_vuong.png")
	
	remove_child(arena_scene)
	arena_scene.queue_free()
	
	# 5. Chụp Combat Arena với Boss Cổ Kiếm Linh (Cross Sword Formation Telegraph)
	var arena_kiem = preload("res://scenes/combat/combat_arena.tscn").instantiate()
	arena_kiem.set_target_boss("boss_co_kiem_linh")
	add_child(arena_kiem)
	await get_tree().create_timer(0.15).timeout
	arena_kiem._start_wave(3)
	await get_tree().create_timer(0.15).timeout
	
	# Giả lập Telegraph Thập Tự Kiếm Trận
	if arena_kiem.boss_ref:
		arena_kiem.boss_ref.telegraph = {
			"type": "cross",
			"pos": arena_kiem.boss_ref.pos,
			"target_pos": arena_kiem.player_pos,
			"radius": 280.0,
			"width": 32.0,
			"timer": 1.1,
			"max_timer": 1.4
		}
	arena_kiem.queue_redraw()
	await get_tree().create_timer(0.3).timeout
	_save_screenshot("23_combat_boss_co_kiem_linh.png")
	
	remove_child(arena_kiem)
	arena_kiem.queue_free()
	
	print("[Capture] Hoàn tất toàn bộ ảnh kiểm thử Phase 3 & S2/S3!")
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
