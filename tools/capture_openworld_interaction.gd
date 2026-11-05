extends Node

## CaptureOpenWorldInteraction — Chụp ảnh kiểm thử runtime xác nhận tương tác NPC, Cổng thành & Bãi quái
## Lưu vào artifact directory và audit/

var step: int = 0
var timer: float = 0.0
var world_inst: Node = null
var artifact_dir: String = "C:/Users/ADMIN/.gemini/antigravity/brain/95e7b116-6ae8-49e1-b1e7-31bba77332ac"

func _ready() -> void:
	print("[SCREENSHOT] Bắt đầu kiểm thử runtime tương tác...")
	GameSession.start_new_game("Lâm Phong", 1337)
	GameSession.add_item("item_linh_thach", 500)
	
	var scn = load("res://scenes/world/province_world.tscn")
	world_inst = scn.instantiate()
	add_child(world_inst)
	_run_step()

func _process(delta: float) -> void:
	timer += delta
	if timer >= 0.35:
		timer = 0.0
		_capture_and_advance()

func _run_step() -> void:
	var player = world_inst.get_node_or_null("YEntities/Player")
	var cam = world_inst.get_node_or_null("Camera2D")
	
	match step:
		0:
			# Bước 1: Tiếp cận NPC Thư Nguyệt (Dược Sư) -> Hiển thị Prompt banner
			print("[STEP 0] Tiếp cận NPC Thư Nguyệt...")
			var target_pos = Vector2(66560, 66560) + Vector2(-340, -300) + Vector2(20, 20)
			if player:
				player.teleport_to(target_pos)
			if cam:
				cam.global_position = target_pos
			world_inst._check_poi_and_settlement_proximity()
			
		1:
			# Bước 2: Kích hoạt hội thoại với NPC Thư Nguyệt
			print("[STEP 1] Mở DialogueModal đàm đạo...")
			world_inst._execute_action("npc_npc_thu_nguyet")
			
		2:
			# Bước 3: Đóng dialogue, di chuyển đến Cổng Nam Thành Trì
			print("[STEP 2] Đến Cổng Nam Thành Trì...")
			var dlg = world_inst.get_node_or_null("HUD/DialogueModal")
			if dlg:
				dlg.close_dialogue()
			var south_gate_pos = Vector2(66560, 67136) + Vector2(0, -40)
			if player:
				player.teleport_to(south_gate_pos)
			if cam:
				cam.global_position = south_gate_pos
			world_inst._check_poi_and_settlement_proximity()
			
		3:
			# Bước 4: Di chuyển đến Bãi Quái Rừng Trúc Vạn Lĩnh
			print("[STEP 3] Đến Bãi Quái Rừng Trúc Vạn Lĩnh...")
			var bamboo_mob_pos = Vector2(66560, 62800)
			if player:
				player.teleport_to(bamboo_mob_pos)
			if cam:
				cam.global_position = bamboo_mob_pos
			if world_inst.streamer and world_inst.streamer.has_method("update_streamer_position"):
				world_inst.streamer.update_streamer_position(bamboo_mob_pos)
			world_inst._check_poi_and_settlement_proximity()

func _capture_and_advance() -> void:
	var img = get_viewport().get_texture().get_image()
	var filename = ""
	match step:
		0: filename = "thin_chau_npc_prompt.png"
		1: filename = "thin_chau_npc_dialogue.png"
		2: filename = "thin_chau_south_gate_prompt.png"
		3: filename = "thin_chau_mob_camp_prompt.png"
		
	if filename != "":
		var art_path = artifact_dir + "/" + filename
		img.save_png(art_path)
		print("  -> Đã lưu ảnh: %s" % art_path)
		
	step += 1
	if step <= 3:
		_run_step()
	else:
		print("Hoàn tất chụp ảnh tương tác!")
		get_tree().quit(0)
