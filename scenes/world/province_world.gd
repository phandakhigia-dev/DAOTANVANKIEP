extends Node2D

## ProvinceWorld — Thế Giới Mở Liền Mạch Tỉnh Thìn Châu (Seamless Province World)
## Kế thừa toàn bộ hệ thống Gameplay: Tu luyện, Túi đồ, Sạp hàng, Lò đan, Co-op.
## Sử dụng ChunkStreamer để nạp động 4096×4096 tile mà không cần màn hình loading.

const ChunkStreamerScript = preload("res://scripts/world/chunk_streamer.gd")
const PlayerScene = preload("res://scenes/world/player.tscn")
const NPCCharacterScene = preload("res://scenes/towns/npc_character.tscn")
const LifeGenerator = preload("res://scripts/domain/life_generator.gd")

@onready var streamer: Node2D = $ChunkStreamer
@onready var y_entities: Node2D = $YEntities
@onready var player: CharacterBody2D = $YEntities/Player
@onready var camera: Camera2D = $Camera2D

# HUD elements
@onready var label_province: Label = $HUD/TopBar/Margin/HBox/PanelProvince/HBox/LabelProvince
@onready var label_location: Label = $HUD/TopBar/Margin/HBox/PanelLocation/HBox/LabelLocation
@onready var label_clock: Label = $HUD/TopBar/Margin/HBox/PanelClock/HBox/LabelClock
@onready var label_player: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelPlayer
@onready var label_stones: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelStones

@onready var prompt_banner: PanelContainer = $HUD/PromptBanner
@onready var label_prompt: Label = $HUD/PromptBanner/Margin/LabelPrompt

# Modals
@onready var dialogue_modal: Control = $HUD/DialogueModal
@onready var inventory_panel: Control = $HUD/InventoryPanel
@onready var character_panel: Control = $HUD/CharacterPanel
@onready var alchemy_modal: Control = $HUD/AlchemyModal
@onready var player_shop_modal: Control = $HUD/PlayerShopModal
@onready var sect_panel: Control = $HUD/SectPanel
@onready var coop_modal: Control = $HUD/CoopMenuModal
@onready var pause_menu: Control = $HUD/PauseMenu
@onready var minimap: Control = $HUD/MiniMap
@onready var world_map_modal: Control = $HUD/WorldMapModal

var current_nearby_action: String = ""
var spawned_npcs: Array[Node] = []
var day_night_modulate: CanvasModulate = null

# Zoom camera thế giới mở
var target_camera_zoom: float = 1.0
const MIN_CAMERA_ZOOM: float = 0.55
const MAX_CAMERA_ZOOM: float = 1.85

# Vị trí trung tâm các phân vùng trọng điểm trong Thìn Châu:
const THANH_TRI_CENTER = Vector2(66560, 66560) # Chunk (32, 32)
const THANH_TRI_SPAWN = Vector2(66560, 66660)  # Quảng trường lộ thiên Nam Giếng Cổ (Tránh đè giếng & NPC)
const LONG_KINH_CENTER = Vector2(66560, 33792) # Chunk (32, 16)
const TAY_SON_CENTER = Vector2(41984, 66560)   # Chunk (20, 32)
const DONG_NOI_CENTER = Vector2(64512, 70656)  # Chunk (31, 34)

func _ready() -> void:
	day_night_modulate = CanvasModulate.new()
	day_night_modulate.name = "DayNightModulate"
	add_child(day_night_modulate)
	
	if AudioService:
		AudioService.play_bgm("bgm_peaceful_town")
		
	# Định vị người chơi tại Thanh Trì Huyện (Quảng trường Nam Giếng Cổ)
	var spawn_pt = THANH_TRI_SPAWN
	if player:
		if GameSession and GameSession.world_position != Vector2.ZERO and GameSession.world_position.x > 10000 and GameSession.world_position != THANH_TRI_CENTER:
			spawn_pt = GameSession.world_position
		player.teleport_to(spawn_pt)
		if GameSession:
			GameSession.world_position = spawn_pt
			
	# Thiết lập Camera2D khóa trực tiếp theo người chơi (Zero-Lag, chống bóng mờ & phân thân)
	if camera:
		camera.position_smoothing_enabled = false
		camera.global_position = player.global_position if player else spawn_pt
		camera.make_current()
	if player and player.has_node("Camera2D"):
		var p_cam = player.get_node("Camera2D")
		if p_cam:
			p_cam.position_smoothing_enabled = false
			p_cam.enabled = false
				
	# Khởi tạo Streamer quanh vị trí người chơi
	if streamer and streamer.has_method("update_streamer_position"):
		streamer.update_streamer_position(player.global_position)
		
	_spawn_core_settlement_npcs()
	_connect_hud_signals()
	prompt_banner.visible = false
	_update_header()
	# Cập nhật minimap lần đầu
	if minimap and minimap.has_method("update_player_pos"):
		minimap.update_player_pos(player.global_position if player else THANH_TRI_SPAWN)

func _physics_process(_delta: float) -> void:
	# Khóa vị trí Camera2D đồng bộ tuyệt đối với Player theo từng nhịp Physics (Triệt tiêu rung giật 100%)
	if player and camera:
		camera.global_position = player.global_position

func _process(delta: float) -> void:
	if player:
		# Cập nhật camera bám theo player & co giãn zoom mượt mà
		if camera:
			camera.global_position = player.global_position
			camera.zoom = camera.zoom.lerp(Vector2(target_camera_zoom, target_camera_zoom), delta * 8.0)
			
		# Cập nhật Chunk Streamer
		if streamer and streamer.has_method("update_streamer_position"):
			streamer.update_streamer_position(player.global_position)
			
		_check_poi_and_settlement_proximity()
		# Cập nhật minimap & world map theo vị trí player mỗi frame
		if minimap and minimap.has_method("update_player_pos"):
			minimap.update_player_pos(player.global_position)
		if world_map_modal and world_map_modal.visible and world_map_modal.has_method("update_player_pos"):
			world_map_modal.update_player_pos(player.global_position)
	
	_update_header()
	_update_day_night(delta)

func _spawn_core_settlement_npcs() -> void:
	# Spawn 5 NPC cốt lõi tại Thanh Trì Huyện với vị trí quy hoạch rõ ràng, không trùng điểm spawn người chơi
	_spawn_npc("npc_mac_tu_vien", THANH_TRI_CENTER + Vector2(-300, 320), "swordsman") # Quán trọ / Tây Nam
	_spawn_npc("npc_thu_nguyet", THANH_TRI_CENTER + Vector2(-340, -300), "swordsman") # Dược Quán / Tây Bắc
	_spawn_npc("npc_ky_hoan", THANH_TRI_CENTER + Vector2(360, 320), "bandit") # Tiệm Rèn / Đông Nam
	_spawn_npc("npc_doan_vinh", THANH_TRI_CENTER + Vector2(360, -300), "swordsman") # Kiếm Điện / Đông Bắc
	_spawn_npc("npc_lam_du", THANH_TRI_CENTER + Vector2(280, -240), "swordsman") # Tiếp Dẫn Đệ Tử / Trước Kiếm Điện

func _spawn_npc(npc_id: String, world_pos: Vector2, sprite_type: String) -> void:
	if not NPCCharacterScene:
		return
	var npc = NPCCharacterScene.instantiate()
	npc.npc_id = npc_id
	npc.sprite_type = sprite_type
	y_entities.add_child(npc)
	npc.global_position = world_pos
	if npc.has_method("_load_npc_data"):
		npc._load_npc_data()
	if npc.has_method("_update_labels"):
		npc._update_labels()
	npc.interacted.connect(func(data): _on_npc_interacted(data))
	spawned_npcs.append(npc)

func _check_poi_and_settlement_proximity() -> void:
	var p_pos = player.global_position
	var dist_to_thanh_tri = p_pos.distance_to(THANH_TRI_CENTER)
	var dist_to_long_kinh = p_pos.distance_to(LONG_KINH_CENTER)
	var dist_to_tay_son = p_pos.distance_to(TAY_SON_CENTER)
	var dist_to_dong_noi = p_pos.distance_to(DONG_NOI_CENTER)
	
	# Xác định phân vùng địa hạt hiển thị trên HUD
	if dist_to_thanh_tri < 900.0:
		label_location.text = "Huyện Thành Thanh Trì • Chợ Tán Tu"
	elif dist_to_long_kinh < 1200.0:
		label_location.text = "Kinh Đô Long Kinh • Hoàng Cung & Lục Bộ"
	elif dist_to_tay_son < 1000.0:
		label_location.text = "Tây Sơn • Trại Khai Khoáng & Thợ Mỏ"
	elif dist_to_dong_noi < 800.0:
		label_location.text = "Đồng Nội • Nông Trang Phàm Nhân"
	elif p_pos.y < THANH_TRI_CENTER.y - 1200.0:
		label_location.text = "Bắc Lâm • Bí Cảnh Rừng Trúc Vạn Lĩnh"
	elif p_pos.x < THANH_TRI_CENTER.x - 1200.0 and p_pos.y > THANH_TRI_CENTER.y + 600.0:
		label_location.text = "Nam Đầm • Độc Trạch Hắc Xà"
	elif p_pos.x > THANH_TRI_CENTER.x + 1200.0:
		label_location.text = "Đông Cốc • Cổ Kiếm Trũng"
	else:
		label_location.text = "Quan Lộ Thìn Châu • Ngoại Ô"

	# Kiểm tra tương tác với các cơ sở hạ tầng, NPC, Cổng thành & Bãi quái
	var nearby_action = ""
	var prompt_text = ""
	
	# === 1. TƯƠNG TÁC NGƯỜI DÂN & NPC GẦN NHẤT ===
	for npc in spawned_npcs:
		if is_instance_valid(npc):
			if p_pos.distance_to(npc.global_position) < 85.0:
				var n_name = npc.npc_data.get("name", "Nhân Vật")
				var n_role = npc.npc_data.get("role", "Tán Tu")
				nearby_action = "npc_" + npc.npc_id
				prompt_text = "[E: Đàm Đạo Với %s (%s)]" % [n_name, n_role]
				break

	# === 2. CỔNG THÀNH TRÌ & TRẠM GÁC LIÊN THÔNG ===
	# Cổng Nam Thanh Trì (world pos ~ Vector2(66560, 67136))
	var south_gate_pos = Vector2(66560, 67136)
	if nearby_action == "" and p_pos.distance_to(south_gate_pos) < 130.0:
		nearby_action = "gate_thanh_tri_south"
		prompt_text = "[E: Cổng Nam Thanh Trì • Ra Ngoại Ô Đi Thôn Đồng Nội & Trại Mỏ Tây Sơn | N: Bản Đồ]"
		
	# Cổng Bắc Thanh Trì (world pos ~ Vector2(66560, 65288))
	var north_gate_pos = Vector2(66560, 65288)
	if nearby_action == "" and (p_pos.distance_to(north_gate_pos) < 140.0 or p_pos.distance_to(THANH_TRI_CENTER + Vector2(0, -600)) < 120.0):
		nearby_action = "gate_thanh_tri_north"
		prompt_text = "[E: Cổng Bắc Thanh Trì • Tiến Vào Bắc Quan Lộ & Rừng Trúc Vạn Lĩnh (Vùng Quái Cấp 1)]"
		
	# Cổng Nam Long Kinh (world pos ~ Vector2(66560, 34568))
	var long_kinh_gate = Vector2(66560, 34568)
	if nearby_action == "" and p_pos.distance_to(long_kinh_gate) < 130.0:
		nearby_action = "gate_long_kinh_south"
		prompt_text = "[E: Cổng Nam Hoàng Thành Long Kinh • Tiến Vào Hoàng Cung & Lục Bộ Nha Môn]"

	# === 3. CƠ SỞ HẠ TẦNG TRONG THÀNH PHỐ ===
	# Lò luyện đan (Tây Bắc Trấn)
	var alc_pos = THANH_TRI_CENTER + Vector2(-340, -300)
	if nearby_action == "" and p_pos.distance_to(alc_pos) < 90.0:
		nearby_action = "alchemy"
		prompt_text = "[K hoặc E: Dược Phẩm Các • Khai Lò Luyện Đan Dược]"
		
	# Sạp hàng tu sĩ (Đông Trấn)
	var stall_pos = THANH_TRI_CENTER + Vector2(360, 0)
	if nearby_action == "" and p_pos.distance_to(stall_pos) < 90.0:
		nearby_action = "shop"
		prompt_text = "[M hoặc E: Vạn Bảo Lâu • Quản lý Sạp Hàng Đạo Tàn]"
		
	# Phân điện Thanh Vi (Đông Bắc Trấn)
	var sect_pos = THANH_TRI_CENTER + Vector2(360, -300)
	if nearby_action == "" and p_pos.distance_to(sect_pos) < 90.0:
		nearby_action = "sect"
		prompt_text = "[G hoặc E: Thanh Vi Kiếm Điện • Môn Phái & Tàng Kinh Các]"
		
	# Giếng nước cổ (Trung tâm Thanh Trì)
	if nearby_action == "" and dist_to_thanh_tri < 60.0:
		nearby_action = "well"
		prompt_text = "[E: Giếng Cổ • Múc Linh Tuyền Hồi Phục Khí Huyết]"
		
	# Dịch Trạm Thanh Trì (Tây Nam Thanh Trì)
	var st_thanh_tri = THANH_TRI_CENTER + Vector2(-260, 240)
	if nearby_action == "" and p_pos.distance_to(st_thanh_tri) < 100.0:
		nearby_action = "travel_to_long_kinh"
		prompt_text = "[T hoặc E: Dịch Trạm Thanh Trì • Thuê Xe Ngựa Đến Long Kinh (25 LT / 4 Giờ)]"
		
	# Ngự Mã Dịch Trạm Long Kinh
	var st_long_kinh = LONG_KINH_CENTER + Vector2(0, 700)
	if nearby_action == "" and p_pos.distance_to(st_long_kinh) < 120.0:
		nearby_action = "travel_to_thanh_tri"
		prompt_text = "[T hoặc E: Ngự Mã Trạm Long Kinh • Đi Xe Ngựa Về Thanh Trì Huyện (10 LT / 4 Giờ)]"

	# === 4. BÃI QUÁI & SÀO HUYỆT BOSS NGOẠI Ô ===
	# --- RỪNG TRÚC VẠN LĨNH (Bắc Lâm - Chunk 32, 30) ---
	# Bãi quái Linh Hồ & Dã thú
	var bamboo_mob_pos = Vector2(66560, 62800)
	if nearby_action == "" and p_pos.distance_to(bamboo_mob_pos) < 120.0:
		nearby_action = "combat_mob_bamboo"
		prompt_text = "[E: Bãi Quái Rừng Trúc • Trảm Linh Hồ Hoang Dã & Bạch Xuyên Thú (Luyện Võ)]"
		
	# Sào huyệt Boss Xích Kiếm Ma Thứu
	var boss_xich_kiem_pos = Vector2(67000, 62200)
	if nearby_action == "" and p_pos.distance_to(boss_xich_kiem_pos) < 130.0:
		nearby_action = "combat_boss_xich_kiem"
		prompt_text = "[E: Sào Huyệt Ma Thứu • KHIÊU CHIẾN BOSS XÍCH KIẾM MA THỨU (Cấp 1)]"
		
	# Thạch Động Cổ
	var cavern_pos = Vector2(66560, 62200)
	if nearby_action == "" and p_pos.distance_to(cavern_pos) < 100.0:
		nearby_action = "cavern"
		prompt_text = "[E: Thạch Động Cổ • Khám Phá Rương Báu Bí Cảnh]"
		
	# Thu hái dược liệu Rừng Trúc
	var bamboo_herb_pos = Vector2(66100, 62600)
	if nearby_action == "" and p_pos.distance_to(bamboo_herb_pos) < 100.0:
		nearby_action = "harvest_bamboo_herbs"
		prompt_text = "[E: Khóm Linh Thảo • Thu Hái Dạ Hương Thảo & Linh Thảo Rừng Trúc]"

	# --- ĐỘC TRẠCH HẮC XÀ (Nam Đầm Lầy - Chunk 31, 33) ---
	# Bãi quái Hắc Linh Xà
	var snake_mob_pos = Vector2(64100, 68608)
	if nearby_action == "" and p_pos.distance_to(snake_mob_pos) < 120.0:
		nearby_action = "combat_mob_snake"
		prompt_text = "[E: Ổ Xà Độc • Tiễu Trừ Hắc Linh Xà Đầm Lầy (Thu Thập Mật Rắn & Linh Thạch)]"
		
	# Sào huyệt Boss Hắc Linh Xà Vương
	var boss_snake_pos = Vector2(64512, 68200)
	if nearby_action == "" and p_pos.distance_to(boss_snake_pos) < 130.0:
		nearby_action = "combat_boss_hac_linh_xa"
		prompt_text = "[E: Hắc Xà Ma Động • KHIÊU CHIẾN BOSS HẮC LINH XÀ VƯƠNG (Cấp 2)]"
		
	# Tế Đàn Xà Cốt
	var snake_altar_pos = Vector2(64512, 68608)
	if nearby_action == "" and p_pos.distance_to(snake_altar_pos) < 100.0:
		nearby_action = "altar_snake"
		prompt_text = "[E: Tế Đàn Xà Cốt • Hiến Tế 15 Linh Thạch Tịnh Hóa Độc Khí (+Tu Vi)]"

	# --- CỔ KIẾM TRŨNG (Đông Cốc - Chunk 33, 32) ---
	# Bãi quái Kiếm Nô
	var sword_mob_pos = Vector2(68200, 66560)
	if nearby_action == "" and p_pos.distance_to(sword_mob_pos) < 120.0:
		nearby_action = "combat_mob_sword"
		prompt_text = "[E: Tàn Kiếm Trận • Đấu Kiếm Với Kiếm Nô Tàn Linh (Luyện Kiếm Thu Kiếm Mảnh)]"
		
	# Sào huyệt Boss Cổ Kiếm Linh
	var boss_sword_pos = Vector2(68608, 66100)
	if nearby_action == "" and p_pos.distance_to(boss_sword_pos) < 130.0:
		nearby_action = "combat_boss_co_kiem"
		prompt_text = "[E: Phong Ấn Đàn • KHIÊU CHIẾN BOSS CỔ KIẾM LINH (Cấp 3)]"
		
	# Tàn Kiếm Bia
	var sword_stele_pos = Vector2(69000, 66800)
	if nearby_action == "" and p_pos.distance_to(sword_stele_pos) < 100.0:
		nearby_action = "stele_sword"
		prompt_text = "[E: Tàn Kiếm Bia • Tĩnh Tâm Lĩnh Ngộ Kiếm Ý Cổ (+30 Tu Vi)]"

	# --- TRẠI MỎ TÂY SƠN (Tây Lĩnh - Chunk 20, 32) ---
	# Bãi quái Sơn Tặc Khoáng Phỉ
	var bandit_mob_pos = Vector2(41600, 66560)
	if nearby_action == "" and p_pos.distance_to(bandit_mob_pos) < 120.0:
		nearby_action = "combat_mob_bandit"
		prompt_text = "[E: Trại Thổ Phỉ Tây Sơn • Tiễu Trừ Sơn Tặc Trộm Mỏ Quặng]"
		
	# Mỏ quặng Tây Sơn
	var mine_ore_pos = Vector2(42300, 66560)
	if nearby_action == "" and p_pos.distance_to(mine_ore_pos) < 100.0:
		nearby_action = "mine_tay_son"
		prompt_text = "[E: Mỏ Quặng Tây Sơn • Đào Khoáng Thạch & Sắt Thép (+Nguyên Liệu)]"

	# --- THÔN ĐỒNG NỘI & NGOẠI Ô NAM (Chunk 31, 34) ---
	# Bãi Sói Hoang
	var wolf_mob_pos = Vector2(65200, 69000)
	if nearby_action == "" and p_pos.distance_to(wolf_mob_pos) < 120.0:
		nearby_action = "combat_mob_wolf"
		prompt_text = "[E: Bãi Sói Hoang Nam Trấn • Trảm Sói Hoang Bảo Vệ Dân Làng]"

	current_nearby_action = nearby_action
	if prompt_text != "":
		label_prompt.text = prompt_text
		prompt_banner.visible = true
	else:
		prompt_banner.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_modal.visible or inventory_panel.visible or character_panel.visible or alchemy_modal.visible or player_shop_modal.visible or (sect_panel and sect_panel.visible) or (coop_modal and coop_modal.visible):
		return
	# World map modal có _unhandled_input nội bộ, chặn khi mở
	if world_map_modal and world_map_modal.visible:
		return
		
	# Zoom camera thế giới bằng cuộn chuột hoặc phím +/-
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_zoom = clamp(target_camera_zoom + 0.1, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_zoom = clamp(target_camera_zoom - 0.1, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
			get_viewport().set_input_as_handled()
			return
			
	if event is InputEventKey and event.pressed:
		var k = event.keycode
		var pk = event.physical_keycode
		
		if k == KEY_EQUAL or pk == KEY_EQUAL: # Phím +
			target_camera_zoom = clamp(target_camera_zoom + 0.15, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
			get_viewport().set_input_as_handled()
			return
		elif k == KEY_MINUS or pk == KEY_MINUS: # Phím -
			target_camera_zoom = clamp(target_camera_zoom - 0.15, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
			get_viewport().set_input_as_handled()
			return
		
		if k == KEY_I or pk == KEY_I:
			inventory_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif k == KEY_C or pk == KEY_C:
			character_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif k == KEY_K or pk == KEY_K:
			alchemy_modal.open_panel()
			get_viewport().set_input_as_handled()
		elif k == KEY_M or pk == KEY_M:
			player_shop_modal.open_panel()
			get_viewport().set_input_as_handled()
		elif k == KEY_G or pk == KEY_G:
			if sect_panel:
				sect_panel.open_panel()
				get_viewport().set_input_as_handled()
		elif k == KEY_O or pk == KEY_O:
			if coop_modal:
				coop_modal.open_modal()
				get_viewport().set_input_as_handled()
		elif k == KEY_N or pk == KEY_N:
			# Mở/đóng Bản đồ Tổng quan Thìn Châu
			if world_map_modal:
				if world_map_modal.visible:
					world_map_modal.close_map()
				else:
					if player:
						world_map_modal.update_player_pos(player.global_position)
					world_map_modal.open_map()
				get_viewport().set_input_as_handled()
		elif k == KEY_T or pk == KEY_T:
			if current_nearby_action.begins_with("travel_"):
				_execute_action(current_nearby_action)
				get_viewport().set_input_as_handled()
		elif k == KEY_E or pk == KEY_E or k == KEY_ENTER:
			if current_nearby_action != "":
				_execute_action(current_nearby_action)
				get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE:
			if pause_menu:
				pause_menu.open_menu()
				get_viewport().set_input_as_handled()

func _start_combat_encounter(boss_id: String) -> void:
	if not GameSession:
		return
	GameSession.target_combat_boss = boss_id
	GameSession.return_scene_path = "res://scenes/world/province_world.tscn"
	GameSession.world_position = player.global_position if player else THANH_TRI_SPAWN
	var cur = Engine.get_main_loop().current_scene
	if not (cur and cur.name == "TestRunner"):
		get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")

func _execute_action(action: String) -> void:
	# 1. Tương tác với NPC
	if action.begins_with("npc_"):
		var nid = action.trim_prefix("npc_")
		for npc in spawned_npcs:
			if is_instance_valid(npc) and npc.npc_id == nid:
				_on_npc_interacted(npc.npc_data)
				return
		return

	# 2. Các hành động cụ thể
	match action:
		"alchemy":
			alchemy_modal.open_panel()
		"shop":
			player_shop_modal.open_panel()
		"sect":
			if sect_panel:
				sect_panel.open_panel()
		"well":
			if GameSession:
				GameSession.heal_player(30)
				if EventBus:
					EventBus.notification_requested.emit("Uống nước giếng cổ thanh khiết, hồi phục 30 Khí Huyết!", "success")
					
		# --- CỔNG THÀNH TRÌ ---
		"gate_thanh_tri_south":
			if player:
				if player.global_position.y < 67136.0:
					player.teleport_to(Vector2(66560, 67250))
					if EventBus:
						EventBus.notification_requested.emit("Đã xuất Cổng Nam Thành Trì, tiến vào vùng ngoại ô Thìn Châu!", "info")
				else:
					player.teleport_to(Vector2(66560, 67020))
					if EventBus:
						EventBus.notification_requested.emit("Đã bước qua Cổng Nam, trở về Huyện Thành Thanh Trì an toàn!", "info")
				GameSession.world_position = player.global_position
				
		"gate_thanh_tri_north":
			if player:
				if player.global_position.y > 65300.0:
					player.teleport_to(Vector2(66560, 65150))
					if EventBus:
						EventBus.notification_requested.emit("Đã vượt Cổng Bắc Thanh Trì, tiến vào Bắc Quan Lộ hướng về Rừng Trúc!", "info")
				else:
					player.teleport_to(Vector2(66560, 65450))
					if EventBus:
						EventBus.notification_requested.emit("Đã bước qua Cổng Bắc, trở về Huyện Thành Thanh Trì!", "info")
				GameSession.world_position = player.global_position
				
		"gate_long_kinh_south":
			if player:
				if player.global_position.y > 34568.0:
					player.teleport_to(Vector2(66560, 34420))
					if EventBus:
						EventBus.notification_requested.emit("Đã tiến vào Hoàng Thành Kinh Đô Long Kinh uy nghiêm!", "info")
				else:
					player.teleport_to(Vector2(66560, 34720))
					if EventBus:
						EventBus.notification_requested.emit("Đã rời Hoàng Thành Long Kinh ra ngoại thành!", "info")
				GameSession.world_position = player.global_position

		# --- BÃI QUÁI & CHIẾN ĐẤU (COMBAT ARENA) ---
		"combat_mob_bamboo":
			_start_combat_encounter("boss_xich_kiem_ma_thu")
		"combat_boss_xich_kiem":
			_start_combat_encounter("boss_xich_kiem_ma_thu")
		"combat_mob_snake":
			_start_combat_encounter("boss_hac_linh_xa_vuong")
		"combat_boss_hac_linh_xa":
			_start_combat_encounter("boss_hac_linh_xa_vuong")
		"combat_mob_sword":
			_start_combat_encounter("boss_co_kiem_linh")
		"combat_boss_co_kiem":
			_start_combat_encounter("boss_co_kiem_linh")
		"combat_mob_bandit":
			_start_combat_encounter("boss_xich_kiem_ma_thu")
		"combat_mob_wolf":
			_start_combat_encounter("boss_xich_kiem_ma_thu")

		# --- THU HOẠCH & CƠ DUYÊN THẾ GIỚI ---
		"harvest_bamboo_herbs":
			if GameSession:
				GameSession.add_item("item_da_huong_thao", 2)
				GameSession.add_item("item_linh_thao", 2)
				if EventBus:
					EventBus.notification_requested.emit("Thu hoạch thành công: 2x Dạ Hương Thảo, 2x Linh Thảo!", "success")
					
		"altar_snake":
			if GameSession:
				if GameSession.get_item_count("item_linh_thach") >= 15:
					GameSession.remove_item("item_linh_thach", 15)
					GameSession.add_cultivation_xp(35)
					if EventBus:
						EventBus.notification_requested.emit("Hiến tế 15 Linh Thạch lên Tế Đàn Xà Cốt: Tịnh hóa độc chướng, +35 Tu Vi!", "success")
				else:
					if EventBus:
						EventBus.notification_requested.emit("Cần 15 Linh Thạch để hiến tế tịnh hóa độc chướng!", "error")
						
		"stele_sword":
			if GameSession:
				GameSession.add_cultivation_xp(30)
				GameSession.add_item("item_co_kiem_tan_phien", 1)
				if EventBus:
					EventBus.notification_requested.emit("Tĩnh tọa lĩnh ngộ Tàn Kiếm Bia: Nhận +30 Tu Vi và 1x Cổ Kiếm Tàn Phiến!", "success")
					
		"mine_tay_son":
			if GameSession:
				GameSession.add_item("item_linh_thach", 20)
				if EventBus:
					EventBus.notification_requested.emit("Khai khoáng Tây Sơn: Khai thác được 20 Linh Thạch và khoáng sản quý!", "success")

		"cavern":
			if GameSession:
				var chunk_coord = Vector2i(32, 30)
				if streamer and streamer.is_entity_harvested(chunk_coord, "bamboo_cavern_chest"):
					if EventBus:
						EventBus.notification_requested.emit("Rương Thạch Động đã bị thu hoạch, cần chờ cơ duyên luân hồi!", "info")
				else:
					if streamer:
						streamer.mark_entity_harvested(chunk_coord, "bamboo_cavern_chest")
					GameSession.add_item("item_tay_tuy_dan", 1)
					GameSession.add_item("item_linh_thach", 50)
					if EventBus:
						EventBus.notification_requested.emit("Khai mở Thạch Động Cổ: Thu hoạch 1x Tẩy Tủy Đan & 50 Linh Thạch!", "success")
						
		"travel_to_long_kinh":
			if GameSession.get_item_count("item_linh_thach") < 25:
				if EventBus:
					EventBus.notification_requested.emit("Thiếu Linh Thạch! Cần 25 Linh Thạch để thuê xe ngựa tới Long Kinh.", "error")
				return
			GameSession.remove_item("item_linh_thach", 25)
			if GameClock:
				GameClock.advance_hours(4)
			var target_pos = LONG_KINH_CENTER + Vector2(0, 650)
			player.teleport_to(target_pos)
			GameSession.world_position = target_pos
			if streamer and streamer.has_method("update_streamer_position"):
				streamer.update_streamer_position(target_pos)
			if EventBus:
				EventBus.notification_requested.emit("Ngồi xe ngựa vượt 4 giờ quan lộ, đã đến cổng Nam Kinh Đô Long Kinh!", "success")
				
		"travel_to_thanh_tri":
			if GameSession.get_item_count("item_linh_thach") < 10:
				if EventBus:
					EventBus.notification_requested.emit("Thiếu Linh Thạch! Cần 10 Linh Thạch để thuê xe ngựa về Thanh Trì.", "error")
				return
			GameSession.remove_item("item_linh_thach", 10)
			if GameClock:
				GameClock.advance_hours(4)
			var target_pos = THANH_TRI_CENTER + Vector2(-200, 200)
			player.teleport_to(target_pos)
			GameSession.world_position = target_pos
			if streamer and streamer.has_method("update_streamer_position"):
				streamer.update_streamer_position(target_pos)
			if EventBus:
				EventBus.notification_requested.emit("Xe ngựa trở về Huyện Thành Thanh Trì an toàn!", "success")

func _on_npc_interacted(data: Dictionary) -> void:
	if not dialogue_modal:
		return
	var nid = data.get("id", "")
	if nid != "" and ContentRegistry and ContentRegistry.get_npc(nid).size() > 0:
		if dialogue_modal.has_method("open_for_npc"):
			dialogue_modal.open_for_npc(nid)
		elif dialogue_modal.has_method("open_dialogue"):
			dialogue_modal.open_dialogue(nid)
	else:
		if dialogue_modal.has_method("open_for_custom_npc"):
			dialogue_modal.open_for_custom_npc(data)
		elif dialogue_modal.has_method("open_dialogue"):
			dialogue_modal.open_dialogue(data)

func _update_header() -> void:
	if not GameClock or not GameSession:
		return
	label_province.text = "★ THÌN CHÂU • ĐẠI HUYỀN ★"
	label_clock.text = "%s (%02d:%02d) • Ngày %d" % [GameClock.get_canh_gio_short(), GameClock.current_hour, GameClock.current_minute, GameClock.current_day]
	label_player.text = "%s • %s" % [GameSession.player_name, ContentRegistry.get_realm(GameSession.realm_id).get("name", "Phàm Nhân")]
	label_stones.text = "Linh Thạch: %d" % GameSession.get_item_count("item_linh_thach")

func _update_day_night(delta: float) -> void:
	if not day_night_modulate or not GameClock:
		return
	var h = GameClock.current_hour
	var target = Color(1.0, 1.0, 1.0, 1.0)
	if h >= 19 or h < 5:
		target = Color(0.46, 0.50, 0.70, 1.0)
	elif h >= 5 and h < 7:
		target = Color(0.92, 0.82, 0.72, 1.0)
	elif h >= 17 and h < 19:
		target = Color(0.88, 0.70, 0.55, 1.0)
	day_night_modulate.color = day_night_modulate.color.lerp(target, clamp(delta * 2.0, 0.05, 1.0))

func _connect_hud_signals() -> void:
	if EventBus:
		EventBus.inventory_changed.connect(func(_i, _c): _update_header())
		EventBus.player_realm_changed.connect(func(_r): _update_header())
	if world_map_modal and world_map_modal.has_signal("map_fast_travel_requested"):
		world_map_modal.map_fast_travel_requested.connect(func(action): _execute_action(action))
