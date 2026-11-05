extends Control

## CharacterPanel — Giao diện Hồ Sơ Tu Sĩ và Bế Quan Đột Phá
## Hiển thị thuộc tính nhân vật, tuổi thọ, công pháp và cơ chế tiến giai cảnh giới

@onready var label_name: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/HeaderBox/LabelName
@onready var label_realm: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/HeaderBox/LabelRealm
@onready var label_lifespan: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/HeaderBox/LabelLifespan

@onready var bar_cultivation: ProgressBar = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/CultivationBox/BarCultivation
@onready var label_cultivation_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/CultivationBox/BarCultivation/LabelVal

@onready var label_hp_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/StatsGrid/LabelHPVal
@onready var label_mp_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/StatsGrid/LabelMPVal
@onready var label_atk_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/StatsGrid/LabelATKVal
@onready var label_def_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/StatsGrid/LabelDEFVal
@onready var label_spd_val: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/StatsGrid/LabelSPDVal

@onready var label_breakthrough_title: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/LabelBTTitle
@onready var label_breakthrough_reqs: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/LabelBTReqs
@onready var label_breakthrough_status: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/LabelBTStatus
@onready var btn_breakthrough: Button = $PanelContainer/MarginContainer/HBoxContainer/RightBox/BtnBreakthrough
@onready var btn_close: Button = $PanelContainer/MarginContainer/HBoxContainer/RightBox/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(close_panel)
	btn_breakthrough.pressed.connect(_on_breakthrough_pressed)
	if EventBus:
		EventBus.player_realm_changed.connect(func(_r): refresh_data())
		EventBus.player_hp_changed.connect(func(_c, _m): refresh_data())
		EventBus.inventory_changed.connect(func(_i, _c): refresh_data())
	refresh_data()

func open_panel() -> void:
	visible = true
	refresh_data()

func close_panel() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_C)):
		close_panel()
		get_viewport().set_input_as_handled()

func refresh_data() -> void:
	if not label_name:
		return
	
	label_name.text = GameSession.player_name
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	var realm_name = realm.get("name", "Phàm Nhân")
	label_realm.text = "Cảnh giới: " + realm_name
	label_lifespan.text = "Thọ mệnh: %d / %d Năm" % [GameSession.lifespan_years, GameSession.max_lifespan_years]
	
	# Tu vi
	bar_cultivation.max_value = GameSession.max_cultivation_xp
	bar_cultivation.value = GameSession.cultivation_xp
	label_cultivation_val.text = "%d / %d Tu Vi" % [GameSession.cultivation_xp, GameSession.max_cultivation_xp]
	
	# Thuộc tính cơ bản
	label_hp_val.text = "%d / %d" % [GameSession.current_hp, GameSession.max_hp]
	label_mp_val.text = "%d / %d" % [GameSession.current_mp, GameSession.max_mp]
	label_atk_val.text = "%d Điểm" % GameSession.attack
	label_def_val.text = "%d Điểm" % GameSession.defense
	label_spd_val.text = "%d Điểm" % int(GameSession.speed)
	
	# Kiểm tra đột phá
	_update_breakthrough_info()

func _update_breakthrough_info() -> void:
	if GameSession.realm_id == "realm_truc_co_1":
		label_breakthrough_title.text = "TRÚC CƠ SƠ KỲ — ĐẠO CƠ ĐÃ THÀNH"
		label_breakthrough_reqs.text = "Ngươi đã vượt qua Thiên Kiếp Lôi Đình, thoát thai hoán cốt!\n• Thọ nguyên tăng lên 250 năm\n• Khí hải hóa dịch, thần thức sơ thành."
		label_breakthrough_status.text = "Trạng thái: Đạo Cơ Viên Mãn"
		label_breakthrough_status.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		btn_breakthrough.disabled = true
		btn_breakthrough.text = "Đã Đạt Trúc Cơ"
		return
	
	var info = GameSession.get_breakthrough_info()
	var target_name = info.get("target_realm_name", "Cảnh Giới Mới")
	label_breakthrough_title.text = "BẾ QUAN XUNG KÍCH: %s" % target_name.to_upper()
	
	if GameSession.realm_id == "realm_pham_nhan":
		label_breakthrough_reqs.text = "Yêu cầu đột phá Luyện Khí Tầng 1:\n• Tu Vi tích lũy: %d / %d\n• Linh Đan trợ lực: 1x Tụ Khí Đan (Hiện có: %d)" % [
			GameSession.cultivation_xp,
			GameSession.max_cultivation_xp,
			GameSession.get_item_count("item_tu_khi_dan")
		]
	elif GameSession.realm_id == "realm_luyen_khi_9":
		var sect_name = "Chưa gia nhập"
		if GameSession.player_sect_id != "":
			var SectService = load("res://scripts/domain/sect_service.gd")
			var s_def = SectService.get_sect(GameSession.player_sect_id)
			sect_name = s_def.get("name", GameSession.player_sect_id)
		
		label_breakthrough_reqs.text = "Yêu cầu Thiên Kiếp Trúc Cơ:\n• Tu Vi Viên Mãn: %d / %d\n• Môn Phái: %s (Bắt buộc)\n• Trợ Lực: 1x Tẩy Tủy Đan (Hiện có: %d)\n• Thử Thách: Vượt qua 3 đợt Thiên Lôi" % [
			GameSession.cultivation_xp,
			GameSession.max_cultivation_xp,
			sect_name,
			GameSession.get_item_count("item_tay_tuy_dan")
		]
	else:
		label_breakthrough_reqs.text = "Tiến giai %s:\n• Tu Vi cần: %d / %d\n• Vận chuyển chu thiên, khai thông kinh mạch." % [
			target_name,
			GameSession.cultivation_xp,
			GameSession.max_cultivation_xp
		]
	
	var can_bt = info.get("can", false)
	if can_bt:
		if GameSession.realm_id == "realm_luyen_khi_9":
			label_breakthrough_status.text = "⚡ Đủ điều kiện! Nhấn để bước vào Thiên Kiếp Lôi Đình!"
			label_breakthrough_status.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
			btn_breakthrough.disabled = false
			btn_breakthrough.text = "⚡ Đối Mặt Thiên Kiếp!"
		else:
			label_breakthrough_status.text = "★ Điều kiện hội tụ đầy đủ! Sẵn sàng khai mở đan điền."
			label_breakthrough_status.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			btn_breakthrough.disabled = false
			btn_breakthrough.text = "Bắt Đầu Đột Phá!"
	else:
		label_breakthrough_status.text = info.get("reason", "Chưa đủ điều kiện.")
		label_breakthrough_status.add_theme_color_override("font_color", Color(0.85, 0.5, 0.4))
		btn_breakthrough.disabled = true
		btn_breakthrough.text = "Chưa Đủ Điều Kiện"

func _on_breakthrough_pressed() -> void:
	if GameSession.realm_id == "realm_luyen_khi_9":
		var current_scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else "res://scenes/towns/town_map_real.tscn"
		var success = GameSession.begin_truc_co_tribulation(current_scene_path)
		if success:
			close_panel()
			get_tree().change_scene_to_file("res://scenes/cultivation/tribulation_arena.tscn")
		return
	
	var success = GameSession.breakthrough_to_next_realm()
	if success:
		if AudioService:
			AudioService.play_sfx("sfx_breakthrough_gong")
		var aura_scene = preload("res://scenes/vfx/vfx_cultivation_aura.tscn")
		if aura_scene:
			var aura = aura_scene.instantiate()
			aura.position = Vector2(320, 240)
			aura.setup_aura(true, 3.5)
			add_child(aura)
		refresh_data()
