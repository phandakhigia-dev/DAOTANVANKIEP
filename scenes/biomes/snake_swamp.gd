extends Node2D

## SnakeSwamp — Đầm Lầy Hắc Xà (Toxic Swamp Biome & Serpent Lair)
## Không gian 2.5D: Độc thủy, Tế Đàn Xà Cốt, Thu hái Bách Thảo Diệp & Sào huyệt Hắc Linh Xà Vương.

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
@onready var serpent_altar: Area2D = $InteractiveAreas/SerpentAltar
@onready var boss_lair: Area2D = $InteractiveAreas/BossLair
@onready var herb_patch_1: Area2D = $InteractiveAreas/HerbPatch1

var current_nearby_action: String = ""
var herb_collected: bool = false
var altar_activated: bool = false

func _ready() -> void:
	prompt_banner.visible = false
	_connect_interactive_areas()
	_update_header()
	
	if player:
		player.teleport_to(Vector2(500, 560))
		
	if EventBus:
		EventBus.notification_requested.emit("Đã bước vào Đầm Lầy Hắc Xà. Mùi độc chướng thoang thoảng, tiếng rắn rít trong lau sậy.", "info")

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
		
	if serpent_altar:
		serpent_altar.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("serpent_altar", "[E: Tế Đàn Xà Cốt • Hiến tế 15 Linh Thạch thanh tẩy độc chướng]"))
		serpent_altar.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("serpent_altar"))
		
	if boss_lair:
		boss_lair.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("boss_lair", "[E: Hắc Xà Ma Động • Khiêu Chiến Boss Hắc Linh Xà Vương]"))
		boss_lair.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("boss_lair"))
		
	if herb_patch_1:
		herb_patch_1.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("herb1", "[E: Thu hái Bụi Bách Thảo Diệp Đầm Lầy]"))
		herb_patch_1.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("herb1"))

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
		"herb1":
			if not herb_collected:
				herb_collected = true
				GameSession.add_item("item_bach_thao_diep", 3)
				GameSession.add_item("item_linh_thao", 2)
				if EventBus:
					EventBus.notification_requested.emit("Thu hoạch thành công: 3x Bách Thảo Diệp, 2x Linh Thảo!", "success")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Bụi độc thảo đã bị hái hết.", "info")
		"serpent_altar":
			if not altar_activated:
				var stones = GameSession.get_item_count("item_linh_thach")
				if stones >= 15:
					GameSession.remove_item("item_linh_thach", 15)
					altar_activated = true
					GameSession.add_item("item_kim_sang_duoc", 2)
					GameSession.add_cultivation_xp(35)
					if EventBus:
						EventBus.notification_requested.emit("Tế Đàn Xà Cốt khai mở: Nhận được 2x Kim Sang Dược cực phẩm và +35 Tu Vi!", "success")
				else:
					if EventBus:
						EventBus.notification_requested.emit("Cần tối thiểu 15 Linh Thạch để kích hoạt tế đàn!", "error")
			else:
				if EventBus:
					EventBus.notification_requested.emit("Tế Đàn Xà Cốt đã được thanh tẩy hoàn toàn.", "info")
		"boss_lair":
			GameSession.target_combat_boss = "boss_hac_linh_xa_vuong"
			GameSession.return_scene_path = "res://scenes/biomes/snake_swamp.tscn"
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
	label_clock.text = "%s (%s) • Đầm Lầy Hắc Xà" % [cur_canh, hour_str]

func _draw() -> void:
	# Nền đầm lầy tím sẫm & nước độc
	var swamp_water = Color(0.12, 0.10, 0.18, 1.0)
	var swamp_mud = Color(0.18, 0.16, 0.15, 1.0)
	var toxic_glow = Color(0.35, 0.20, 0.50, 0.35)
	
	draw_rect(Rect2(0, 0, 1024, 704), swamp_water, true)
	
	# Các gò đất bùn nhô lên khỏi nước độc
	draw_circle(Vector2(500, 560), 120.0, swamp_mud)
	draw_circle(Vector2(500, 240), 140.0, swamp_mud)
	draw_circle(Vector2(260, 320), 110.0, swamp_mud)
	draw_circle(Vector2(780, 240), 120.0, swamp_mud)
	
	# Cầu ván gỗ nối các đảo bùn
	draw_line(Vector2(500, 560), Vector2(500, 240), Color(0.30, 0.24, 0.20, 0.9), 28.0)
	draw_line(Vector2(500, 360), Vector2(260, 320), Color(0.30, 0.24, 0.20, 0.9), 24.0)
	draw_line(Vector2(500, 240), Vector2(780, 240), Color(0.30, 0.24, 0.20, 0.9), 26.0)
	
	# Vòng xoáy khí độc quanh sào huyệt xà vương
	draw_circle(Vector2(780, 240), 60.0, toxic_glow)
	draw_arc(Vector2(780, 240), 75.0, 0, TAU, 32, Color(0.6, 0.25, 0.75, 0.6), 2.0)
