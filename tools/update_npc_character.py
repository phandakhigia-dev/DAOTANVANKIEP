from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scenes/towns/npc_character.gd")
content = path.read_text(encoding="utf-8")

old_code = """@export var move_speed: float = 120.0
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
		npc_data = LifeGenerator.generate_character(seed_val, npc_id.hash())"""

new_code = """@export var move_speed: float = 120.0
@export var npc_id: String = "":
	set(val):
		npc_id = val
		_load_npc_data()
		_update_labels()
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
	if npc_id == "":
		return
	var def: Dictionary = {}
	var cr = get_node_or_null("/root/ContentRegistry")
	if cr and cr.has_method("get_npc"):
		def = cr.get_npc(npc_id)
	if not def.is_empty():
		npc_data = def
	elif is_procedural:
		var gs = get_node_or_null("/root/GameSession")
		var seed_val: int = gs.world_seed if (gs and "world_seed" in gs) else 1337
		npc_data = LifeGenerator.generate_character(seed_val, npc_id.hash())"""

content_norm = content.replace("\r\n", "\n")
old_norm = old_code.replace("\r\n", "\n")
new_norm = new_code.replace("\r\n", "\n")

assert old_norm in content_norm, "Target not found in npc_character.gd!"
content_norm = content_norm.replace(old_norm, new_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully updated npc_character.gd!")
