extends Control

## SectPanel — Bảng điều khiển Tông Môn (Môn Phái)
## Hiển thị: Thông tin tông môn, cấp bậc, nhiệm vụ cống hiến, Tàng Kinh Các
## Phím tắt: G (Môn Phái) trong town_map_real.gd

signal panel_closed

@onready var panel_root: PanelContainer = $PanelRoot
@onready var label_title: Label = $PanelRoot/MarginContainer/HBox/LeftPane/LabelTitle
@onready var label_sect_name: Label = $PanelRoot/MarginContainer/HBox/LeftPane/LabelSectName
@onready var label_rank: Label = $PanelRoot/MarginContainer/HBox/LeftPane/LabelRank
@onready var label_contrib: Label = $PanelRoot/MarginContainer/HBox/LeftPane/LabelContrib
@onready var progress_contrib: ProgressBar = $PanelRoot/MarginContainer/HBox/LeftPane/ProgressContrib
@onready var label_join_hint: Label = $PanelRoot/MarginContainer/HBox/LeftPane/LabelJoinHint
@onready var quest_list: VBoxContainer = $PanelRoot/MarginContainer/HBox/MiddlePane/ScrollQuests/QuestList
@onready var library_list: VBoxContainer = $PanelRoot/MarginContainer/HBox/RightPane/ScrollLibrary/LibraryList
@onready var label_no_sect: Label = $PanelRoot/MarginContainer/HBox/MiddlePane/LabelNoSect

var SectServiceClass = null

func _ready() -> void:
	SectServiceClass = load("res://scripts/domain/sect_service.gd")
	visible = false

func open_panel() -> void:
	visible = true
	_refresh_panel()

func close_panel() -> void:
	visible = false
	panel_closed.emit()

func _refresh_panel() -> void:
	if GameSession.player_sect_id == "":
		_show_no_sect_ui()
	else:
		_show_sect_ui()

func _show_no_sect_ui() -> void:
	if label_title:
		label_title.text = "✦ TÔNG MÔN ✦"
	if label_sect_name:
		label_sect_name.text = "Tán Tu — Vô Môn Phái"
	if label_rank:
		label_rank.text = "Cấp bậc: Chưa gia nhập"
	if label_contrib:
		label_contrib.text = "Cống hiến: 0"
	if label_join_hint:
		label_join_hint.text = "Hãy giao hảo với Trưởng Lão và mang vật phẩm cống nạp để gia nhập tông môn."
		label_join_hint.visible = true
	if label_no_sect:
		label_no_sect.text = "Chưa gia nhập tông môn — Gặp Trưởng Lão Tông Môn để nộp đơn!"
		label_no_sect.visible = true
	# Xóa danh sách quest và kinh sách
	_clear_children(quest_list)
	_clear_children(library_list)

func _show_sect_ui() -> void:
	var summary = SectServiceClass.get_player_sect_summary()
	var sect = SectServiceClass.get_sect(GameSession.player_sect_id)
	var ranks = sect.get("ranks", [])
	var contrib = GameSession.sect_contribution
	
	if label_title:
		label_title.text = "✦ TÔNG MÔN: %s ✦" % summary.get("sect_name", "?")
	if label_sect_name:
		label_sect_name.text = summary.get("sect_name", "?")
	if label_rank:
		label_rank.text = "Cấp bậc: %s" % summary.get("rank_name", "?")
	if label_contrib:
		label_contrib.text = "Cống hiến tích lũy: %d điểm" % contrib
	if label_join_hint:
		label_join_hint.visible = false
	if label_no_sect:
		label_no_sect.visible = false
	
	# Thanh tiến độ cống hiến
	if progress_contrib:
		var next_rank_min = _get_next_rank_min(ranks, GameSession.sect_rank)
		progress_contrib.max_value = next_rank_min if next_rank_min > 0 else 10000
		progress_contrib.value = contrib
	
	# Danh sách nhiệm vụ cống hiến
	_clear_children(quest_list)
	for cq in sect.get("contribution_quests", []):
		_add_quest_row(cq)
	
	# Danh sách kinh sách Tàng Kinh Các
	_clear_children(library_list)
	for ls in sect.get("library_skills", []):
		_add_library_row(ls)

func _add_quest_row(cq: Dictionary) -> void:
	if not quest_list:
		return
	var row = HBoxContainer.new()
	
	var lbl = Label.new()
	lbl.text = "[%s] %s" % [cq.get("id", "?"), cq.get("name", "?")]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "+%d CH" % cq.get("reward_contribution", 0)
	btn.custom_minimum_size = Vector2(80, 0)
	btn.pressed.connect(_on_quest_complete.bind(cq.get("id", "")))
	row.add_child(btn)
	
	quest_list.add_child(row)

func _add_library_row(ls: Dictionary) -> void:
	if not library_list:
		return
	var row = HBoxContainer.new()
	var is_learned = GameSession.learned_library_skills.has(ls.get("id", ""))
	
	var lbl = Label.new()
	var icon = "✓ " if is_learned else "📖 "
	lbl.text = "%s%s (%d CH)" % [icon, ls.get("name", "?"), ls.get("cost_contribution", 0)]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	if is_learned:
		lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	row.add_child(lbl)
	
	if not is_learned:
		var btn = Button.new()
		btn.text = "Học"
		btn.custom_minimum_size = Vector2(60, 0)
		btn.pressed.connect(_on_learn_skill.bind(ls.get("id", "")))
		row.add_child(btn)
	
	library_list.add_child(row)

func _on_quest_complete(cq_id: String) -> void:
	var SectService = load("res://scripts/domain/sect_service.gd")
	var result = SectService.complete_contribution_quest(cq_id)
	if result.get("success", false):
		_refresh_panel()

func _on_learn_skill(ls_id: String) -> void:
	var SectService = load("res://scripts/domain/sect_service.gd")
	if SectService.learn_library_skill(ls_id):
		_refresh_panel()

func _get_next_rank_min(ranks: Array, current_rank: String) -> int:
	var found = false
	for r in ranks:
		if found:
			return r.get("min_contribution", 0)
		if r.get("id", "") == current_rank:
			found = true
	return 0

func _clear_children(node: Node) -> void:
	if not node:
		return
	for c in node.get_children():
		c.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_G:
			close_panel()
