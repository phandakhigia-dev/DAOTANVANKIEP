extends Node

## CapturePhase4VFXScreenshots — Chụp ảnh kiểm thử Hiệu Ứng Hình Ảnh & Âm Thanh Võ Hiệp
## Gồm:
## 35_vfx_sword_slash_combat.png: Kiếm Khí Xé Gió & Tia Lửa Kiếm Ý
## 36_vfx_cultivation_aura_breakthrough.png: Linh Trận & Hào Quang Hoàng Kim Đột Phá
## 37_vfx_bamboo_leaves_ambience.png: Trúc Diệp Phiêu Dao & Mộc Linh Phấn Hoa
## 38_vfx_tribulation_lightning_impact.png: Lôi Bạo Điểm Giáng & Sóng Xung Kích Điện Trường

const OUTPUT_DIR: String = "res://docs/TEST_REPORTS/screenshots"

func _ready() -> void:
	call_deferred("_run_all_captures")

func _run_all_captures() -> void:
	var dir = DirAccess.open("res://docs/TEST_REPORTS")
	if dir and not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	print("[Capture Phase 4] Bắt đầu chụp ảnh kiểm thử VFX & Audio Polish...")
	GameSession.start_new_game("Lâm Phong", 1337)
	
	# 1. Chụp VFX Kiếm Khí Xé Gió (VFXSwordSlash)
	var slash_scene = preload("res://scenes/vfx/vfx_sword_slash.tscn").instantiate()
	slash_scene.position = Vector2(960, 540)
	slash_scene.slash_angle = -PI * 0.25
	slash_scene.slash_color = Color(0.4, 0.85, 1.0, 1.0)
	add_child(slash_scene)
	
	# Giả lập nền tối chiến đấu để nổi bật kiếm khí
	await get_tree().create_timer(0.15).timeout
	_save_screenshot("35_vfx_sword_slash_combat.png")
	remove_child(slash_scene)
	slash_scene.queue_free()
	
	# 2. Chụp VFX Hào Quang Đột Phá Hoàng Kim (VFXCultivationAura)
	var aura_scene = preload("res://scenes/vfx/vfx_cultivation_aura.tscn").instantiate()
	aura_scene.position = Vector2(960, 540)
	aura_scene.setup_aura(true, 4.0)
	add_child(aura_scene)
	await get_tree().create_timer(0.4).timeout
	_save_screenshot("36_vfx_cultivation_aura_breakthrough.png")
	remove_child(aura_scene)
	aura_scene.queue_free()
	
	# 3. Chụp VFX Môi Trường Lá Trúc Rơi Trên Rừng Trúc Vạn Lĩnh
	var bamboo_scene = preload("res://scenes/biomes/bamboo_forest.tscn").instantiate()
	add_child(bamboo_scene)
	await get_tree().create_timer(0.5).timeout
	_save_screenshot("37_vfx_bamboo_leaves_ambience.png")
	remove_child(bamboo_scene)
	bamboo_scene.queue_free()
	
	# 4. Chụp VFX Lôi Bạo Điểm Giáng (VFXLightningImpact) Trong Thiên Kiếp
	var trib_scene = preload("res://scenes/cultivation/tribulation_arena.tscn").instantiate()
	add_child(trib_scene)
	var impact_scene = preload("res://scenes/vfx/vfx_lightning_impact.tscn").instantiate()
	impact_scene.position = Vector2(960, 540)
	add_child(impact_scene)
	await get_tree().create_timer(0.2).timeout
	_save_screenshot("38_vfx_tribulation_lightning_impact.png")
	remove_child(impact_scene)
	impact_scene.queue_free()
	remove_child(trib_scene)
	trib_scene.queue_free()
	
	print("[Capture Phase 4] Hoàn tất chụp toàn bộ 4 ảnh kiểm thử Phase 4!")
	get_tree().quit()

func _save_screenshot(filename: String) -> void:
	var image = get_viewport().get_texture().get_image()
	var path = OUTPUT_DIR.path_join(filename)
	var err = image.save_png(path)
	if err == OK:
		print("  -> Đã lưu ảnh: ", path)
	else:
		push_error("Lỗi khi lưu ảnh kiểm thử: %s (Mã lỗi: %d)" % [path, err])
