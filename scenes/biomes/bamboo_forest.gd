extends Node2D

## BambooForest — Bí Cảnh Rừng Trúc Vạn Lĩnh (Emerald Bamboo Biome & Dungeons)
## Không gian 2.5D: Thu hái linh thảo, Thạch Động Ẩn Tàng (Rương báu cổ),
## Lối thông Cửa Bắc Thị Trấn Thanh Trì và Sào huyệt Xích Kiếm Ma Thứu.

@onready var player: CharacterBody2D = $YEntities/Player
@onready var prompt_banner: PanelContainer = $HUD/PromptBanner
@onready var label_prompt: Label = $HUD/PromptBanner/Margin/LabelPrompt

# Top HUD
@onready var label_zone_name: Label = $HUD/TopBar/Margin/HBox/PanelZone/HBox/LabelZoneName
@onready var label_clock: Label = $HUD/TopBar/Margin/HBox/PanelClock/HBox/LabelClock
@onready var label_player: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelPlayer
@onready var label_stones: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelStones

# Interactive Areas
@onready var south_exit: Area2D = $InteractiveAreas/SouthExit
@onready var dungeon_cavern: Area2D = $InteractiveAreas/DungeonCavern
@onready var boss_lair: Area2D = $InteractiveAreas/BossLair
@onready var herb_patch_1: Area2D = $InteractiveAreas/HerbPatch1
@onready var herb_patch_2: Area2D = $InteractiveAreas/HerbPatch2

const VFXBambooLeavesScene = preload("res://scenes/vfx/vfx_bamboo_leaves.tscn")

var current_nearby_action: String = ""
var herbs_collected: Dictionary = {"patch1": false, "patch2": false}
var cavern_chest_opened: bool = false

func _ready() -> void:
	prompt_banner.visible = false
	_connect_interactive_areas()
	_update_header()
	
	if AudioService:
		AudioService.play_bgm("bgm_bamboo_forest")
		
	if VFXBambooLeavesScene:
		var leaves = VFXBambooLeavesScene.instantiate()
		leaves.position = Vector2(512, 0)
		add_child(leaves)
	
	if player:
		player.teleport_to(Vector2(480, 560))
		
	if EventBus:
		EventBus.notification_requested.emit("Đã bước vào Rừng Trúc Vạn Lĩnh. Tiếng trúc rì rào trong gió, linh khí mộc hệ dồi dào.", "info")

func _process(_delta: float) -> void:
	_update_header()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		var phys = event.physical_keycode
		
		if key == KEY_E or phys == KEY_E or key == KEY_ENTER:
			if current_nearby_action != "":
				_execute_nearby_action(current_nearby_action)
				get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			_exit_to_town()
			get_viewport().set_input_as_handled()

func _connect_interactive_areas() -> void:
	if south_exit:
		south_exit.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("south_exit", "[E / Enter: Trở về Cửa Bắc Thị Trấn Thanh Trì]"))
		south_exit.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("south_exit"))
		
	if dungeon_cavern:
		dungeon_cavern.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("dungeon_cavern", "[E: Khám phá Thạch Động Ẩn Tàng (Rương Cổ Bí Cảnh)]"))
		dungeon_cavern.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("dungeon_cavern"))
		
	if boss_lair:
		boss_lair.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("boss_lair", "[E: Sào Huyệt Ma Thứu • Khiêu Chiến Boss Xích Kiếm Ma Thứu]"))
		boss_lair.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("boss_lair"))
		
	if herb_patch_1:
		herb_patch_1.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("herb1", "[E: Hái Bụi Dạ Hương Thảo Xanh Tốt]"))
		herb_patch_1.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("herb1"))
		
	if herb_patch_2:
		herb_patch_2.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("herb2", "[E: Hái Khóm Trúc Tiệp Thảo Lâu Năm]"))
		herb_patch_2.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("herb2"))

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
		"south_exit":
			_exit_to_town()
		"herb1":
			if not herbs_collected.get("patch1", false):
				herbs_collected["patch1"] = true
				GameSession.add_item("item_da_huong_thao", 2)
				GameSession.add_item("item_linh_thao", 1)
				if EventBus:
					EventBus.notification_requested.emit("Thu hoạch thành công: 2x Dạ Hương Thảo, 1x Linh Thảo!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Khóm linh thảo này đã được thu hái, cần thời gian tích tụ linh khí.", "info")
		"herb2":
			if not herbs_collected.get("patch2", false):
				herbs_collected["patch2"] = true
				GameSession.add_item("item_linh_thao", 3)
				if EventBus:
					EventBus.notification_requested.emit("Thu hoạch thành công: 3x Linh Thảo phẩm cấp tốt!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Khóm linh thảo này đã cạn dược lực.", "info")
		"dungeon_cavern":
			if not cavern_chest_opened:
				cavern_chest_opened = true
				GameSession.add_item("item_linh_thach", 80)
				GameSession.add_item("item_tu_khi_dan", 2)
				GameSession.add_cultivation_xp(40)
				if EventBus:
					EventBus.notification_requested.emit("Mở rương Thạch Động Thần Bí: Nhận 80 Linh Thạch, 2x Tụ Khí Đan, +40 Tu Vi!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Rương cổ trong Thạch Động đã trống không.", "info")
		"boss_lair":
			GameSession.target_combat_boss = "boss_xich_kiem_ma_thu"
			GameSession.return_scene_path = "res://scenes/biomes/bamboo_forest.tscn"
			var cur = Engine.get_main_loop().current_scene
			if not (cur and cur.name == "TestRunner"):
				get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")

func _exit_to_town() -> void:
	var cur = Engine.get_main_loop().current_scene
	if not (cur and cur.name == "TestRunner"):
		get_tree().change_scene_to_file("res://scenes/towns/town_map_real.tscn")

func _update_header() -> void:
	if not GameSession or not ContentRegistry or not GameClock:
		return
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	var realm_name = realm.get("name", "Phàm Nhân")
	label_player.text = "%s • %s" % [GameSession.player_name, realm_name]
	
	var stones = GameSession.get_item_count("item_linh_thach")
	label_stones.text = "Linh Thạch: %d" % stones
	
	var cur_canh = GameClock.get_canh_gio_name()
	var hour_str = "%02d:00" % GameClock.current_hour
	label_clock.text = "%s (%s) • Rừng Trúc Vân Lĩnh" % [cur_canh, hour_str]

func _draw() -> void:
	# Vẽ các khóm trúc trang trí xanh biếc và lối mòn dã ngoại
	var bg_color = Color(0.08, 0.18, 0.11, 1.0)
	var path_color = Color(0.20, 0.26, 0.18, 1.0)
	var bamboo_color = Color(0.18, 0.52, 0.28, 0.85)
	
	draw_rect(Rect2(0, 0, 1024, 704), bg_color, true)
	
	# Lối mòn đá cuội uốn lượn từ Cổng Nam lên Cổng Bắc
	var path_points = PackedVector2Array([
		Vector2(480, 704), Vector2(480, 520), Vector2(420, 360),
		Vector2(300, 260), Vector2(240, 180), Vector2(480, 100), Vector2(700, 200)
	])
	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i+1], path_color, 48.0)
		
	# Vẽ các thân trúc cao vút
	var rng = RandomNumberGenerator.new()
	rng.seed = 9988
	for i in range(45):
		var bx = rng.randf_range(40, 980)
		var by = rng.randf_range(40, 660)
		# Tránh vẽ đè ngay giữa đường mòn
		if abs(bx - 480) > 60 or by < 120 or by > 600:
			draw_circle(Vector2(bx, by), 14.0, bamboo_color)
			draw_line(Vector2(bx, by), Vector2(bx, by - 60), Color(0.25, 0.65, 0.35, 0.9), 6.0)
			draw_circle(Vector2(bx, by - 60), 22.0, Color(0.20, 0.55, 0.28, 0.6))
