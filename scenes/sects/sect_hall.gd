extends Node2D

## SectHall — Thanh Vi Kiếm Tông Phân Điện (Sect Headquarters & Library)
## Điểm tập kết đệ tử môn phái:
## - Bia Đăng Ký Môn Phái (Join Sect)
## - Tàng Kinh Các (Library & Skills)
## - Bảng Nhiệm Vụ Cống Hiến (Quests & Promotion)
## - Trưởng Lão Đoàn Vĩnh (Elder interaction)
## - Cổng rời phân điện trở lại Thanh Trì Trấn

const SectService = preload("res://scripts/domain/sect_service.gd")

@onready var player: CharacterBody2D = $YEntities/Player
@onready var prompt_banner: PanelContainer = $HUD/PromptBanner
@onready var label_prompt: Label = $HUD/PromptBanner/Margin/LabelPrompt

# Top HUD
@onready var label_zone_name: Label = $HUD/TopBar/Margin/HBox/PanelZone/HBox/LabelZoneName
@onready var label_clock: Label = $HUD/TopBar/Margin/HBox/PanelClock/HBox/LabelClock
@onready var label_player: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelPlayer
@onready var label_contrib: Label = $HUD/TopBar/Margin/HBox/PanelPlayer/HBox/LabelContrib

# Interactive Areas
@onready var exit_gate: Area2D = $InteractiveAreas/ExitGate
@onready var sect_stone: Area2D = $InteractiveAreas/SectStone
@onready var library_portal: Area2D = $InteractiveAreas/LibraryPortal
@onready var quest_board: Area2D = $InteractiveAreas/QuestBoard
@onready var elder_area: Area2D = $InteractiveAreas/ElderArea

# Modals
@onready var sect_panel: Control = $HUD/SectPanel

var current_nearby_action: String = ""

func _ready() -> void:
	prompt_banner.visible = false
	_connect_interactive_areas()
	_update_header()
	
	if player:
		player.teleport_to(Vector2(500, 560))
		
	if EventBus:
		EventBus.notification_requested.emit("Đã bước vào Thanh Vi Kiếm Tông Phân Điện. Kiếm ý lăng lệ, chuông đồng ngân vang.", "info")

func _process(_delta: float) -> void:
	_update_header()

func _unhandled_input(event: InputEvent) -> void:
	if sect_panel and sect_panel.visible:
		return
		
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		var phys = event.physical_keycode
		
		if key == KEY_G or phys == KEY_G:
			if sect_panel:
				sect_panel.open_panel()
				get_viewport().set_input_as_handled()
		elif key == KEY_E or phys == KEY_E or key == KEY_ENTER:
			if current_nearby_action != "":
				_execute_nearby_action(current_nearby_action)
				get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			_exit_to_town()
			get_viewport().set_input_as_handled()

func _connect_interactive_areas() -> void:
	if exit_gate:
		exit_gate.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("exit_gate", "[E / Enter: Rời Phân Điện • Trở về Thị Trấn]"))
		exit_gate.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("exit_gate"))
		
	if sect_stone:
		sect_stone.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("sect_stone", "[E: Bia Đăng Ký • Nhập Môn & Khảo Thí]"))
		sect_stone.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("sect_stone"))
		
	if library_portal:
		library_portal.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("library_portal", "[E / G: Tàng Kinh Các • Nghiên Cứu Công Pháp]"))
		library_portal.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("library_portal"))
		
	if quest_board:
		quest_board.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("quest_board", "[E / G: Bảng Cống Hiến • Nhận & Báo Công]"))
		quest_board.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("quest_board"))
		
	if elder_area:
		elder_area.body_entered.connect(func(b): if b.name == "Player": _set_nearby_prompt("elder_area", "[E: Yết Kiến Tiếp Dẫn Trưởng Lão Đoàn Vĩnh]"))
		elder_area.body_exited.connect(func(b): if b.name == "Player": _clear_nearby_prompt("elder_area"))

func _set_nearby_prompt(action_id: String, text: String) -> void:
	current_nearby_action = action_id
	label_prompt.text = text
	prompt_banner.visible = true

func _clear_nearby_prompt(action_id: String) -> void:
	if current_nearby_action == action_id:
		current_nearby_action = ""
		prompt_banner.visible = false

func _execute_nearby_action(action: String) -> void:
	match action:
		"exit_gate":
			_exit_to_town()
		"sect_stone":
			_interact_sect_stone()
		"library_portal", "quest_board":
			if sect_panel:
				sect_panel.open_panel()
		"elder_area":
			_interact_elder()

func _interact_sect_stone() -> void:
	if GameSession.player_sect_id == "sect_thanh_vi":
		if EventBus:
			EventBus.notification_requested.emit("Bia đá khắc tên ngươi: [%s] — Thuộc Thanh Vi Kiếm Tông!" % GameSession.player_name, "info")
		if sect_panel:
			sect_panel.open_panel()
		return
	elif GameSession.player_sect_id != "":
		if EventBus:
			EventBus.notification_requested.emit("Ngươi đã là môn hạ phái khác, bia đá kiếm khí cự tuyệt!", "warning")
		return
		
	var check = SectService.can_join_sect("sect_thanh_vi")
	if check.get("can", false):
		SectService.join_sect("sect_thanh_vi")
		_update_header()
		if sect_panel:
			sect_panel.open_panel()
	else:
		if EventBus:
			EventBus.notification_requested.emit("Chưa đủ điều kiện: " + check.get("reason", ""), "warning")

func _interact_elder() -> void:
	if GameSession.player_sect_id == "sect_thanh_vi":
		var rank_name = SectService.get_current_rank_name()
		if EventBus:
			EventBus.notification_requested.emit("Đoàn Vĩnh: 'Đệ tử %s, kiếm đạo vô nhai, hãy siêng năng tích lũy cống hiến!'" % rank_name, "info")
		if sect_panel:
			sect_panel.open_panel()
	else:
		var aff = GameSession.get_npc_affinity("npc_doan_vinh")
		if EventBus:
			EventBus.notification_requested.emit("Đoàn Vĩnh: 'Muốn vào Thanh Vi Tông? Hãy chứng minh thực lực (Hạ Ma Thứu lấy Tàn Kiếm) và đạt cảnh giới Luyện Khí!' (Thiện cảm: %d/20)" % aff, "info")

func _exit_to_town() -> void:
	if EventBus:
		EventBus.notification_requested.emit("Rời khỏi Thanh Vi Phân Điện, trở về nhịp sống Thanh Trì Trấn.", "info")
	get_tree().change_scene_to_file("res://scenes/towns/town_map_real.tscn")

func _update_header() -> void:
	if label_zone_name:
		label_zone_name.text = "Thanh Vi Kiếm Tông • Phân Điện"
	if label_clock:
		var cur_canh = GameClock.get_canh_gio_name()
		var hour_str = "%02d:00" % GameClock.current_hour
		label_clock.text = "%s (%s) • Phân Điện Môn Phái" % [cur_canh, hour_str]
	if label_player:
		var r_name = ContentRegistry.get_realm(GameSession.realm_id).get("name", "Phàm Nhân")
		var s_rank = SectService.get_current_rank_name()
		label_player.text = "%s • %s [%s]" % [GameSession.player_name, r_name, s_rank]
	if label_contrib:
		label_contrib.text = "Cống Hiến: %d | Linh Thạch: %d" % [GameSession.sect_contribution, GameSession.get_item_count("item_linh_thach")]

func _draw() -> void:
	# Nền phân điện tông môn phong cách kiếm tông cổ phong
	var bg_color = Color(0.08, 0.07, 0.12, 1.0)
	var floor_tile = Color(0.14, 0.12, 0.18, 1.0)
	var carpet_color = Color(0.25, 0.12, 0.18, 0.9)
	var border_gold = Color(0.65, 0.55, 0.32, 0.8)
	
	draw_rect(Rect2(0, 0, 1024, 704), bg_color, true)
	# Phiến đá lớn giữa điện
	draw_rect(Rect2(120, 120, 784, 520), floor_tile, true)
	draw_rect(Rect2(120, 120, 784, 520), border_gold, false, 2.0)
	# Thảm đỏ tiếp dẫn trung tâm điện
	draw_rect(Rect2(440, 140, 144, 480), carpet_color, true)
	draw_rect(Rect2(440, 140, 144, 480), border_gold, false, 1.5)

