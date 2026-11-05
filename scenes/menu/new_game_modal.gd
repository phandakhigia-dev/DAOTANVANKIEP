extends Control

## NewGameModal — Khởi tạo nhân vật mới và sinh thế giới theo Seed

@onready var edit_name: LineEdit = $PanelContainer/VBoxContainer/GridContainer/EditName
@onready var edit_seed: SpinBox = $PanelContainer/VBoxContainer/GridContainer/HBoxSeed/SpinBoxSeed
@onready var btn_random_seed: Button = $PanelContainer/VBoxContainer/GridContainer/HBoxSeed/ButtonRandomSeed
@onready var btn_start: Button = $PanelContainer/VBoxContainer/HBoxButtons/ButtonStart
@onready var btn_cancel: Button = $PanelContainer/VBoxContainer/HBoxButtons/ButtonCancel

func _ready() -> void:
	_apply_ink_style()
	edit_name.text = "Lâm Phong"
	_on_random_seed()
	
	btn_random_seed.pressed.connect(_on_random_seed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

func _apply_ink_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.15, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(0.78, 0.65, 0.40, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	$PanelContainer.add_theme_stylebox_override("panel", style)

func _on_random_seed() -> void:
	edit_seed.value = RNGService.generate_random_seed()

func _on_start_pressed() -> void:
	var p_name = edit_name.text.strip_edges()
	if p_name == "":
		p_name = "Kẻ Vô Danh"
	var p_seed = int(edit_seed.value)
	
	GameSession.start_new_game(p_name, p_seed)
	get_tree().change_scene_to_file("res://scenes/world/province_world.tscn")

func _on_cancel_pressed() -> void:
	visible = false
