extends Control

## MainMenu — Giao diện thực đơn chính của Đạo Tàn: Vạn Kiếp

@onready var btn_new_game: Button = $VBoxCenter/VBoxButtons/ButtonNewGame
@onready var btn_continue: Button = $VBoxCenter/VBoxButtons/ButtonContinue
@onready var label_continue_meta: Label = $VBoxCenter/VBoxButtons/LabelContinueMeta
@onready var btn_settings: Button = $VBoxCenter/VBoxButtons/ButtonSettings
@onready var btn_quit: Button = $VBoxCenter/VBoxButtons/ButtonQuit
@onready var new_game_modal: Control = $NewGameModal
@onready var settings_modal: Control = $SettingsModal

func _ready() -> void:
	_check_save_status()
	
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _check_save_status() -> void:
	var can_continue = SaveService.has_save(1)
	btn_continue.disabled = not can_continue
	
	if can_continue:
		var meta = SaveService.get_slot_meta(1)
		var p_name = meta.get("player_name", "Kẻ Vô Danh")
		var r_name = meta.get("realm_name", "Phàm Nhân")
		var d_str = meta.get("date_str", "")
		label_continue_meta.text = "• %s (%s) • %s" % [p_name, r_name, d_str]
		label_continue_meta.visible = true
	else:
		label_continue_meta.visible = false

func _on_new_game_pressed() -> void:
	new_game_modal.visible = true

func _on_continue_pressed() -> void:
	if SaveService.load_game(1):
		get_tree().change_scene_to_file("res://scenes/world/province_world.tscn")

func _on_settings_pressed() -> void:
	settings_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
