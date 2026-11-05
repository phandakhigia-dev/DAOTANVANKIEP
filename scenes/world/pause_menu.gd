extends Control

## PauseMenu — Trình đơn tạm dừng trong thế giới tu chân

@onready var btn_resume: Button = $PanelContainer/VBox/ButtonResume
@onready var btn_save: Button = $PanelContainer/VBox/ButtonSave
@onready var btn_settings: Button = $PanelContainer/VBox/ButtonSettings
@onready var btn_to_menu: Button = $PanelContainer/VBox/ButtonToMenu
@onready var settings_modal: Control = $SettingsModal

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_ink_style()
	
	btn_resume.pressed.connect(resume_game)
	btn_save.pressed.connect(_on_save_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_to_menu.pressed.connect(_on_to_menu_pressed)

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

func open_menu() -> void:
	visible = true
	get_tree().paused = true

func resume_game() -> void:
	visible = false
	get_tree().paused = false

func _on_save_pressed() -> void:
	SaveService.save_game(1)

func _on_settings_pressed() -> void:
	settings_modal.visible = true

func _on_to_menu_pressed() -> void:
	# Lưu tự động trước khi thoát ra Menu chính
	SaveService.save_game(1)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
