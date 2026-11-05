extends CharacterBody2D

## NPCCharacter — Nhân vật NPC vật lý trong bản đồ thành trì 2.5D
## Có thân xác, hoạt ảnh bước đi, hiển thị danh xưng, bong bóng thoại và lịch trình sinh hoạt.

signal interacted(npc_data: Dictionary)

const LifeGenerator = preload("res://scripts/domain/life_generator.gd")

@export var move_speed: float = 120.0
@export var npc_id: String = ""
@export var is_procedural: bool = false
@export var sprite_type: String = "swordsman" # "swordsman" hoặc "bandit"

@onready var label_name: Label = $FloatingUI/VBox/LabelName
@onready var label_role: Label = $FloatingUI/VBox/LabelRole
@onready var prompt_e: PanelContainer = $FloatingUI/PromptE
@onready var speech_bubble: PanelContainer = $FloatingUI/SpeechBubble
@onready var label_speech: Label = $FloatingUI/SpeechBubble/Margin/LabelSpeech
@onready var interact_area: Area2D = $InteractArea
@onready var sprite_node: AnimatedSprite2D = $swordsman if has_node("swordsman") else ($bandit if has_node("bandit") else null)

var npc_data: Dictionary = {}
var target_pos: Vector2 = Vector2.ZERO
var has_target: bool = false
var facing_dir: Vector2 = Vector2.DOWN
var is_player_nearby: bool = false
var _speech_timer: float = 0.0

func _ready() -> void:
	prompt_e.visible = false
	speech_bubble.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	if npc_id != "":
		_load_npc_data()
	_update_labels()
	queue_redraw()

func setup_data(data: Dictionary) -> void:
	npc_data = data
	npc_id = data.get("id", "")
	_update_labels()

func _load_npc_data() -> void:
	var def: Dictionary = {}
	var cr = get_node_or_null("/root/ContentRegistry")
	if cr and cr.has_method("get_npc"):
		def = cr.get_npc(npc_id)
	if not def.is_empty():
		npc_data = def
	elif is_procedural:
		var gs = get_node_or_null("/root/GameSession")
		var seed_val: int = gs.world_seed if (gs and "world_seed" in gs) else 1337
		npc_data = LifeGenerator.generate_character(seed_val, npc_id.hash())

func _update_labels() -> void:
	var l_name = label_name if label_name else get_node_or_null("FloatingUI/VBox/LabelName")
	var l_role = label_role if label_role else get_node_or_null("FloatingUI/VBox/LabelRole")
	if not l_name or not l_role:
		return
	var n_name = npc_data.get("name", "Vô Danh")
	var n_role = npc_data.get("role", "Tán Tu")
	var n_realm = npc_data.get("realm_name", "")
	
	l_name.text = n_name
	if n_realm != "":
		l_role.text = "• %s (%s) •" % [n_role, n_realm]
	else:
		l_role.text = "• %s •" % n_role

func say(text: String, duration: float = 3.5) -> void:
	var bubble = speech_bubble if speech_bubble else get_node_or_null("FloatingUI/SpeechBubble")
	var lbl = label_speech if label_speech else get_node_or_null("FloatingUI/SpeechBubble/Margin/LabelSpeech")
	if lbl and bubble:
		lbl.text = text
		bubble.visible = true
		_speech_timer = duration

func move_to_pos(pos: Vector2) -> void:
	target_pos = pos
	has_target = true

func _physics_process(delta: float) -> void:
	if _speech_timer > 0.0:
		_speech_timer -= delta
		if _speech_timer <= 0.0:
			speech_bubble.visible = false
			
	if has_target:
		var dist = global_position.distance_to(target_pos)
		if dist > 8.0:
			var dir = (target_pos - global_position).normalized()
			facing_dir = dir
			velocity = dir * move_speed
			move_and_slide()
			_update_animation(true)
		else:
			has_target = false
			velocity = Vector2.ZERO
			_update_animation(false)
	else:
		velocity = Vector2.ZERO
		_update_animation(false)

func _update_animation(is_moving: bool) -> void:
	if not sprite_node:
		return
	var dir_name = _get_dir_name(facing_dir)
	var anim_name = ("walk_" if is_moving else "idle_") + dir_name
	if sprite_node.sprite_frames.has_animation(anim_name) and sprite_node.animation != anim_name:
		sprite_node.play(anim_name)

func _get_dir_name(dir: Vector2) -> String:
	var angle = dir.angle()
	var octant = roundi(8.0 * angle / TAU)
	match octant:
		0: return "east"
		1: return "south_east"
		2: return "south"
		3: return "south_west"
		4, -4: return "west"
		-3: return "north_west"
		-2: return "north"
		-1: return "north_east"
		_: return "south"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_nearby = true
		prompt_e.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_nearby = false
		prompt_e.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_player_nearby and event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_ENTER:
			interacted.emit(npc_data)
			get_viewport().set_input_as_handled()

func _draw() -> void:
	# Bóng đổ mặt đất tinh tế
	var points = PackedVector2Array()
	var n_segs = 16
	for i in range(n_segs):
		var theta = i * TAU / n_segs
		points.append(Vector2(cos(theta) * 12.0, sin(theta) * 5.0))
	draw_colored_polygon(points, Color(0, 0, 0, 0.35))
