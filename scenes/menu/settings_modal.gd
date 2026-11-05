extends Control

## SettingsModal — Điều chỉnh cấu hình hiển thị và âm thanh

@onready var slider_master: HSlider = $PanelContainer/VBoxContainer/GridContainer/SliderMaster
@onready var slider_music: HSlider = $PanelContainer/VBoxContainer/GridContainer/SliderMusic
@onready var slider_sfx: HSlider = $PanelContainer/VBoxContainer/GridContainer/SliderSFX
@onready var check_fullscreen: CheckBox = $PanelContainer/VBoxContainer/GridContainer/CheckFullscreen
@onready var option_res: OptionButton = $PanelContainer/VBoxContainer/GridContainer/OptionResolution
@onready var btn_close: Button = $PanelContainer/VBoxContainer/ButtonClose

func _ready() -> void:
	_apply_ink_style()
	_populate_resolutions()
	_load_current_settings()
	
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	option_res.item_selected.connect(_on_res_selected)
	btn_close.pressed.connect(_on_close_pressed)

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

func _populate_resolutions() -> void:
	option_res.clear()
	option_res.add_item("1920 x 1080 (Chuẩn)", 0)
	option_res.add_item("1600 x 900", 1)
	option_res.add_item("1280 x 720", 2)
	option_res.select(0)

func _load_current_settings() -> void:
	slider_master.value = 80
	slider_music.value = 70
	slider_sfx.value = 80
	check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_master_changed(val: float) -> void:
	_set_bus_volume("Master", val)

func _on_music_changed(val: float) -> void:
	_set_bus_volume("Music", val)

func _on_sfx_changed(val: float) -> void:
	_set_bus_volume("SFX", val)

func _set_bus_volume(bus_name: String, percent: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		if percent <= 0.01:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = linear_to_db(percent / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_res_selected(index: int) -> void:
	var size = Vector2i(1920, 1080)
	match index:
		0: size = Vector2i(1920, 1080)
		1: size = Vector2i(1600, 900)
		2: size = Vector2i(1280, 720)
	DisplayServer.window_set_size(size)

func _on_close_pressed() -> void:
	visible = false
