extends Node2D

## SwordGrave — Cổ Kiếm Trũng (Ancient Sword Grave Biome & Sword Spirit Array)
## Không gian 2.5D: Tàn Kiếm Bia ngộ đạo, Cơ quan Kiếm Trận, Thu hoạch Cổ Kiếm Tàn Phiến & Boss Cổ Kiếm Linh.

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
@onready var sword_stele: Area2D = $InteractiveAreas/SwordStele
@onready var sword_mechanism: Area2D = $InteractiveAreas/SwordMechanism
@onready var boss_lair: Area2D = $InteractiveAreas/BossLair

var current_nearby_action: String = ""
var stele_comprehended: bool = false
var mechanism_solved: bool = false

func _ready() -> void:
	prompt_banner.visible = false
	_connect_interactive_areas()
	_update_header()
	
	if player:
		player.teleport_to(Vector2(500, 560))
		
	if EventBus:
		EventBus.notification_requested.emit("Đã bước vào Cổ Kiếm Trũng. Tiếng kiếm ngân lạnh buốt trong gió rít, tàn kiếm ngút ngàn cắm vào vách đá.", "info")

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
			_exit_to_world()
			get_viewport().set_input_as_handled()

func _connect_interactive_areas() -> void:
	if south_exit:
		south_exit.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("south_exit", "[E / Enter: Trở về Đại Bản Đồ Thế Giới]"))
		south_exit.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("south_exit"))
		
	if sword_stele:
		sword_stele.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("sword_stele", "[E: Tàn Kiếm Bia • Tĩnh tâm lĩnh ngộ kiếm ý tàn quyển (+Tu Vi)]"))
		sword_stele.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("sword_stele"))
		
	if sword_mechanism:
		sword_mechanism.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("sword_mechanism", "[E: Kiếm Trận Thạch Đài • Xoay chuyển phù văn giải mã kiếm trận]"))
		sword_mechanism.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("sword_mechanism"))
		
	if boss_lair:
		boss_lair.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("boss_lair", "[E: Kiếm Linh Phong Ấn Đàn • Khiêu Chiến Boss Cổ Kiếm Linh]"))
		boss_lair.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("boss_lair"))

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
			_exit_to_world()
		"sword_stele":
			if not stele_comprehended:
				stele_comprehended = true
				GameSession.add_cultivation_xp(50)
				if EventBus:
					EventBus.notification_requested.emit("Quan sát vết kiếm chém trên đá cổ, đạo tâm sáng tỏ: Tu Vi +50!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Kiếm ý trên bia đá đã hoàn toàn dung hòa vào thức hải của bạn.", "info")
		"sword_mechanism":
			if not mechanism_solved:
				mechanism_solved = true
				GameSession.add_item("item_co_kiem_tan_phien", 2)
				GameSession.add_item("item_linh_thach", 100)
				if EventBus:
					EventBus.notification_requested.emit("Kiếm trận cơ quan chuyển động, nhả ra: 2x Cổ Kiếm Tàn Phiến và 100 Linh Thạch!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Trận đài kiếm khí đã ngưng hoạt động.", "info")
		"boss_lair":
			GameSession.target_combat_boss = "boss_co_kiem_linh"
			GameSession.return_scene_path = "res://scenes/biomes/sword_grave.tscn"
			var cur = Engine.get_main_loop().current_scene
			if not (cur and cur.name == "TestRunner"):
				get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")

func _exit_to_world() -> void:
	var cur = Engine.get_main_loop().current_scene
	if not (cur and cur.name == "TestRunner"):
		get_tree().change_scene_to_file("res://scenes/world/world_map.tscn")

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
	label_clock.text = "%s (%s) • Cổ Kiếm Trũng Hoang Thạch" % [cur_canh, hour_str]

func _draw() -> void:
	# Nền sa thạch xám đồng & đá nứt
	var ground_color = Color(0.18, 0.17, 0.16, 1.0)
	var stone_plate = Color(0.26, 0.24, 0.22, 1.0)
	var sword_steel = Color(0.70, 0.72, 0.78, 0.9)
	var sword_glow = Color(0.95, 0.80, 0.35, 0.3)
	
	draw_rect(Rect2(0, 0, 1024, 704), ground_color, true)
	
	# Các phiến đá tế đài bát giác
	draw_circle(Vector2(500, 240), 130.0, stone_plate)
	draw_arc(Vector2(500, 240), 130.0, 0, TAU, 8, Color(0.78, 0.65, 0.40, 0.8), 3.0)
	
	draw_circle(Vector2(260, 280), 80.0, stone_plate)
	draw_circle(Vector2(760, 280), 90.0, stone_plate)
	
	# Vẽ các thanh cự kiếm cắm ngập vào mặt đất
	var sword_positions = [
		Vector2(180, 160), Vector2(340, 140), Vector2(500, 110),
		Vector2(660, 140), Vector2(820, 160), Vector2(200, 420),
		Vector2(800, 420)
	]
	for pos in sword_positions:
		# Lưỡi kiếm cắm xuống
		draw_line(Vector2(pos.x, pos.y), Vector2(pos.x, pos.y - 70), sword_steel, 8.0)
		# Chuôi kiếm
		draw_line(Vector2(pos.x - 14, pos.y - 50), Vector2(pos.x + 14, pos.y - 50), Color(0.78, 0.65, 0.40, 1.0), 4.0)
		# Hào quang kiếm khí
		draw_circle(pos, 22.0, sword_glow)
