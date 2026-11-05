extends Node2D

## TownMapReal — Thành Trì Nhập Vai Thực Tế (Enterable Living Town)
## Bản đồ 2.5D sống động: NPC thủ tục có chiều sâu nhân sinh (LifeGenerator),
## sạp hàng kinh tế tự động (ShopService), lò luyện đan (AlchemyService),
## chu kỳ 12 Canh Giờ ngày/đêm và tương tác đồ vật thế giới (Smart Objects).

const LifeGenerator = preload("res://scripts/domain/life_generator.gd")
const ShopService = preload("res://scripts/domain/shop_service.gd")
const NPCCharacterScene = preload("res://scenes/towns/npc_character.tscn")

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $YEntities/Player
@onready var y_entities: Node2D = $YEntities
@onready var night_modulate: CanvasModulate = $NightModulate

# Top HUD
@onready var label_town_name: Label = $HUD/TopBar/Margin/HBox/PanelTown/HBox/LabelTownName
@onready var label_clock: Label = $HUD/TopBar/Margin/HBox/PanelClock/HBox/LabelClock
@onready var label_player_info: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelPlayer
@onready var label_stones: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelStones

# Bottom Prompt & Quick Buttons
@onready var prompt_banner: PanelContainer = $HUD/PromptBanner
@onready var label_prompt: Label = $HUD/PromptBanner/Margin/LabelPrompt

# Modals
@onready var dialogue_modal: Control = $HUD/DialogueModal
@onready var inventory_panel: Control = $HUD/InventoryPanel
@onready var character_panel: Control = $HUD/CharacterPanel
@onready var alchemy_modal: Control = $HUD/AlchemyModal
@onready var player_shop_modal: Control = $HUD/PlayerShopModal
@onready var sect_panel: Control = $HUD/SectPanel

# Interactive Areas
@onready var south_gate: Area2D = $InteractiveAreas/SouthGate
@onready var north_gate: Area2D = $InteractiveAreas/NorthGate
@onready var player_stall_area: Area2D = $InteractiveAreas/PlayerStallArea
@onready var alchemy_area: Area2D = $InteractiveAreas/AlchemyArea
@onready var well_area: Area2D = $InteractiveAreas/WellArea
@onready var bench_area: Area2D = $InteractiveAreas/BenchArea
@onready var sect_hall_area: Area2D = $InteractiveAreas/SectHallArea

var current_nearby_action: String = ""
var procedural_npcs: Array[Node] = []
var town_lanterns: Array[Node2D] = []

var _routine_timer: float = 8.0
var _sales_check_timer: float = 14.0

# Các điểm đến thông minh trong trấn
const WAYPOINTS = [
	Vector2(730, 390), # Sạp hàng người chơi & Vạn Bảo Lâu
	Vector2(512, 400), # Giếng nước cổ quảng trường
	Vector2(240, 200), # Dược Phẩm Các / Lò luyện đan
	Vector2(230, 530), # Quán trà / Vọng Nguyệt Đình
	Vector2(512, 570), # Cổng Nam
	Vector2(512, 110), # Cổng Bắc
	Vector2(512, 300), # Quảng trường trung tâm
	Vector2(780, 530)  # Lò rèn Thiết Tượng Phác
]

const VFXBambooLeavesScene = preload("res://scenes/vfx/vfx_bamboo_leaves.tscn")

func _ready() -> void:
	_build_town_ground()
	_collect_lanterns()
	_spawn_canonical_npcs()
	_spawn_procedural_wanderers()
	_connect_interactive_areas()
	_connect_hud_signals()
	
	# Bổ sung hiệu ứng môi trường võ hiệp: Lá trúc & Linh khí bồng bềnh
	if VFXBambooLeavesScene:
		var leaves_fx = VFXBambooLeavesScene.instantiate()
		leaves_fx.position = Vector2(512, 20)
		leaves_fx.z_index = 8
		add_child(leaves_fx)
		
	if AudioService:
		AudioService.play_bgm("bgm_peaceful_town")
	
	# Định vị người chơi: khôi phục town_position nếu có, hoặc xuất hiện từ Cổng Nam
	if player:
		if GameSession and GameSession.town_position != Vector2.ZERO:
			player.teleport_to(GameSession.town_position)
			GameSession.town_position = Vector2.ZERO
		else:
			player.teleport_to(Vector2(512, 570))
		
	prompt_banner.visible = false
	_update_header()
	_update_atmosphere()

func _process(delta: float) -> void:
	_update_header()
	_update_atmosphere()
	
	# Định kỳ kích hoạt lịch trình sinh hoạt của NPC dạo phố
	_routine_timer -= delta
	if _routine_timer <= 0.0:
		_routine_timer = randf_range(10.0, 16.0)
		_trigger_random_npc_routine()
		
	# Định kỳ mô phỏng sức mua tại sạp hàng
	_sales_check_timer -= delta
	if _sales_check_timer <= 0.0:
		_sales_check_timer = 20.0
		_simulate_town_market_purchases()

func _unhandled_input(event: InputEvent) -> void:
	# Nếu đang mở bảng/hội thoại, không bắt phím tắt bản đồ
	if dialogue_modal.visible or inventory_panel.visible or character_panel.visible or alchemy_modal.visible or player_shop_modal.visible or (sect_panel and sect_panel.visible):
		return
		
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		var phys = event.physical_keycode
		
		# Phím I: Túi đồ
		if key == KEY_I or phys == KEY_I:
			inventory_panel.open_panel()
			get_viewport().set_input_as_handled()
		# Phím C: Nhân vật
		elif key == KEY_C or phys == KEY_C:
			character_panel.open_panel()
			get_viewport().set_input_as_handled()
		# Phím K: Luyện đan
		elif key == KEY_K or phys == KEY_K:
			alchemy_modal.open_panel()
			get_viewport().set_input_as_handled()
		# Phím M: Sạp hàng
		elif key == KEY_M or phys == KEY_M:
			player_shop_modal.open_panel()
			get_viewport().set_input_as_handled()
		# Phím G: Tông Môn / Môn Phái
		elif key == KEY_G or phys == KEY_G:
			if sect_panel:
				sect_panel.open_panel()
				get_viewport().set_input_as_handled()
		# Phím E / Enter: Tương tác vật thể gần nhất
		elif key == KEY_E or phys == KEY_E or key == KEY_ENTER:
			if current_nearby_action != "":
				_execute_nearby_action(current_nearby_action)
				get_viewport().set_input_as_handled()
		# Phím Escape: Rời thành trở lại thế giới
		elif key == KEY_ESCAPE:
			_exit_to_world_map()
			get_viewport().set_input_as_handled()

func _build_town_ground() -> void:
	if not ground:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = GameSession.world_seed
	
	# Lát gạch phiến đá toàn bộ vùng thị trấn (32x22 ô gạch = 1024x704 px)
	for y in range(0, 22):
		for x in range(0, 32):
			# Ven mép ngoài là cỏ tự nhiên
			if x == 0 or x == 31 or y == 0 or y == 21:
				ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0)) # cỏ
			# Kênh nước nhỏ bên góc trái (x: 1..3, y: 3..17)
			elif x >= 1 and x <= 3 and y >= 3 and y <= 17:
				ground.set_cell(Vector2i(x, y), 0, Vector2i(4, 0)) # nước kênh
			# Trục lộ Bắc - Nam nối Cổng Bắc và Cổng Nam
			elif (x == 15 or x == 16) and (y >= 1 and y <= 20):
				ground.set_cell(Vector2i(x, y), 0, Vector2i(2, 5)) # đá phiến đại lộ
			# Trục lộ Đông - Tây nối các phân điện và phố buôn bán
			elif (y == 11 or y == 12) and (x >= 4 and x <= 27):
				ground.set_cell(Vector2i(x, y), 0, Vector2i(2, 5)) # đá phiến đại lộ
			else:
				# Gạch phiến đá có biến thể hoa văn ngẫu nhiên
				var slab_idx = rng.randi_range(0, 5)
				ground.set_cell(Vector2i(x, y), 0, Vector2i(slab_idx, 5))

func _collect_lanterns() -> void:
	town_lanterns.clear()
	for child in get_tree().get_nodes_in_group("town_lanterns"):
		if child is Node2D:
			town_lanterns.append(child)

func _spawn_canonical_npcs() -> void:
	# 1. Mạc Tư Viễn (Trấn Trưởng - Vọng Nguyệt Đình bên kênh nước)
	_spawn_npc_entity("npc_mac_tu_vien", Vector2(270, 530), "swordsman")
	# 2. Thư Nguyệt (Đan Sư - Dược Phẩm Các)
	_spawn_npc_entity("npc_thu_nguyet", Vector2(230, 200), "swordsman")
	# 3. Kỷ Hoàn (Thợ Rèn - Thiết Tượng Phác)
	_spawn_npc_entity("npc_ky_hoan", Vector2(770, 530), "bandit")
	# 4. Đoàn Vĩnh (Tiếp Dẫn Thanh Vi Tông - Thanh Vi Điện)
	_spawn_npc_entity("npc_doan_vinh", Vector2(800, 200), "swordsman")
	# 5. Bạch San (Tán Tu Thám Hiểm - Giếng Cổ Trung Tâm)
	_spawn_npc_entity("npc_bach_san", Vector2(460, 400), "swordsman")

func _spawn_procedural_wanderers() -> void:
	var seed_val = GameSession.world_seed
	# Sinh 3 NPC thủ tục độc nhất vô nhị
	var wanderer_configs = [
		{"offset": 101, "pos": Vector2(570, 340), "sprite": "swordsman"},
		{"offset": 202, "pos": Vector2(360, 440), "sprite": "bandit"},
		{"offset": 303, "pos": Vector2(680, 450), "sprite": "swordsman"}
	]
	
	for cfg in wanderer_configs:
		var p_data = LifeGenerator.generate_character(seed_val, cfg.offset)
		var p_node = NPCCharacterScene.instantiate()
		y_entities.add_child(p_node)
		p_node.global_position = cfg.pos
		p_node.setup_data(p_data)
		p_node.interacted.connect(func(data): _on_npc_interacted(data))
		procedural_npcs.append(p_node)

func _spawn_npc_entity(id: String, pos: Vector2, sprite: String) -> void:
	var node = NPCCharacterScene.instantiate()
	y_entities.add_child(node)
	node.global_position = pos
	node.npc_id = id
	node.sprite_type = sprite
	node.interacted.connect(func(data): _on_npc_interacted(data))

func _connect_interactive_areas() -> void:
	if south_gate:
		south_gate.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("south_gate", "[E / Enter: Xuất Thành ra Đại Bản Đồ]"))
		south_gate.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("south_gate"))
	
	if north_gate:
		north_gate.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("north_gate", "[E: Cửa Bắc • Khám phá Rừng Trúc Vạn Lĩnh]"))
		north_gate.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("north_gate"))
		
	if player_stall_area:
		player_stall_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("player_stall", "[M hoặc E: Quản lý Sạp Hàng Đạo Tàn & Quyết toán]"))
		player_stall_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("player_stall"))
		
	if alchemy_area:
		alchemy_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("alchemy_furnace", "[K hoặc E: Khai Lò Luyện Đan Dược]"))
		alchemy_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("alchemy_furnace"))
		
	if well_area:
		well_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("ancient_well", "[E: Giếng Cổ • Múc Linh Tuyền Phục Hồi Thể Lực]"))
		well_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("ancient_well"))
		
	if bench_area:
		bench_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("tea_bench", "[E: Quán Trà • Ngồi Tĩnh Tọa Lắng Nghe Tin Tức]"))
		bench_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("tea_bench"))
		
	if sect_hall_area:
		sect_hall_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("sect_hall", "[E / G: Thanh Vi Tông Phân Điện • Môn Phái & Tàng Kinh Các]"))
		sect_hall_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("sect_hall"))

func _connect_hud_signals() -> void:
	if EventBus:
		EventBus.inventory_changed.connect(func(_i, _c): _update_header())
		EventBus.player_realm_changed.connect(func(_r): _update_header())

func _set_nearby_prompt(action: String, text: String) -> void:
	current_nearby_action = action
	label_prompt.text = text
	prompt_banner.visible = true

func _clear_nearby_prompt(action: String) -> void:
	if current_nearby_action == action:
		current_nearby_action = ""
		prompt_banner.visible = false

func _execute_nearby_action(action: String) -> void:
	match action:
		"south_gate":
			_exit_to_world_map()
		"north_gate":
			GameSession.town_position = player.global_position
			get_tree().change_scene_to_file("res://scenes/biomes/bamboo_forest.tscn")
		"player_stall":
			player_shop_modal.open_panel()
		"alchemy_furnace":
			alchemy_modal.open_panel()
		"ancient_well":
			GameSession.heal_player(30)
			if EventBus:
				EventBus.notification_requested.emit("Múc ngụm nước linh tuyền mát lạnh, sinh lực hồi phục +30 HP!", "success")
		"tea_bench":
			if SessionAuthority and SessionAuthority.is_coop_session():
				GameSession.heal_player(20)
				if EventBus:
					EventBus.notification_requested.emit("Uống chén trà xanh... Sinh lực phục hồi +20 HP! [Co-op: Không tua thời gian]", "info")
			else:
				GameClock.advance_hours(1)
				if EventBus:
					EventBus.notification_requested.emit("Tĩnh tọa uống chén trà xanh... Thời gian trôi qua 1 canh giờ.", "info")
		"sect_hall":
			GameSession.town_position = player.global_position
			get_tree().change_scene_to_file("res://scenes/sects/sect_hall.tscn")

func _exit_to_world_map() -> void:
	get_tree().change_scene_to_file("res://scenes/world/world_map.tscn")

func _on_npc_interacted(data: Dictionary) -> void:
	var nid = data.get("id", "")
	# Nếu là NPC cốt truyện được đăng ký trong ContentRegistry
	if ContentRegistry.get_npc(nid).size() > 0:
		dialogue_modal.open_for_npc(nid)
	else:
		# NPC thủ tục sinh ngẫu nhiên theo hạt giống
		dialogue_modal.open_for_custom_npc(data)

func _trigger_random_npc_routine() -> void:
	if procedural_npcs.is_empty():
		return
	var npc = procedural_npcs.pick_random()
	if not is_instance_valid(npc):
		return
		
	var target = WAYPOINTS.pick_random()
	npc.move_to_pos(target)
	
	# Nếu tiến gần đến sạp người chơi
	if target.distance_to(Vector2(680, 230)) < 30.0:
		var speeches = [
			"Sạp hàng này có bán Tụ Khí Đan không?",
			"Hương đan dược thật thanh khiết, phẩm giai không tầm thường!",
			"Chủ sạp này nghe nói là đan đạo kỳ tài mới tới Thanh Trì...",
			"Để ta kiểm tra bảo đan này xem giá cả ra sao..."
		]
		npc.say(speeches.pick_random())

func _simulate_town_market_purchases() -> void:
	if not ShopService.is_lease_active():
		return
	if ShopService.escrow_items.is_empty():
		return
		
	var before_rev = ShopService.accumulated_revenue
	ShopService.simulate_npc_purchases()
	var after_rev = ShopService.accumulated_revenue
	
	if after_rev > before_rev:
		var earned = after_rev - before_rev
		if EventBus:
			EventBus.notification_requested.emit("★ [Sạp Hàng] Một vị tán tu vừa mua đan dược! Thu về +%d Linh Thạch!" % earned, "success")
		# NPC gần sạp nói lời cảm tạ
		for npc in procedural_npcs:
			if is_instance_valid(npc) and npc.global_position.distance_to(Vector2(680, 230)) < 120.0:
				npc.say("Bảo đan quả nhiên danh bất hư truyền! Ta lấy viên này!", 4.0)
				break

func _update_header() -> void:
	if not GameSession or not ContentRegistry or not GameClock:
		return
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	var realm_name = realm.get("name", "Phàm Nhân")
	label_player_info.text = "%s • %s" % [GameSession.player_name, realm_name]
	
	var stones = GameSession.get_item_count("item_linh_thach")
	label_stones.text = "Linh Thạch: %d" % stones
	
	var cur_canh = GameClock.get_canh_gio_name()
	var hour_str = "%02d:00" % GameClock.current_hour
	var n_visitors = 5 + procedural_npcs.size()
	label_clock.text = "%s (%s) • %d Cư Dân & Tu Sĩ Trong Trấn" % [cur_canh, hour_str, n_visitors]

func _update_atmosphere() -> void:
	var h = GameClock.current_hour
	var is_night = (h >= 19 or h < 5)
	var is_dusk = (h >= 17 and h < 19)
	
	if night_modulate:
		if is_night:
			night_modulate.color = Color(0.48, 0.52, 0.72, 1.0) # Ánh trăng huyền ảo
		elif is_dusk:
			night_modulate.color = Color(0.85, 0.72, 0.60, 1.0) # Hoàng hôn tà dương
		else:
			night_modulate.color = Color(1.0, 1.0, 1.0, 1.0)    # Ban ngày quang đãng
			
	# Bật/tắt ánh sáng đèn lồng
	for lantern in town_lanterns:
		if is_instance_valid(lantern) and lantern.has_node("PointLight2D"):
			lantern.get_node("PointLight2D").visible = is_night or is_dusk
