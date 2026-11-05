extends Control

## SocialPanel — Sổ Nhân Duyên & Ân Oán Giang Hồ (phím J)
## Quản lý quan hệ xã hội NPC, tính cách nội tại, ơn nghĩa và cừu hận.

@onready var npc_list_container: VBoxContainer = $PanelContainer/Margin/HBox/LeftPane/Scroll/NPCList
@onready var btn_filter_all: Button = $PanelContainer/Margin/HBox/LeftPane/FilterBar/BtnAll
@onready var btn_filter_friends: Button = $PanelContainer/Margin/HBox/LeftPane/FilterBar/BtnFriends
@onready var btn_filter_enemies: Button = $PanelContainer/Margin/HBox/LeftPane/FilterBar/BtnEnemies
@onready var btn_filter_sect: Button = $PanelContainer/Margin/HBox/LeftPane/FilterBar/BtnSect

@onready var label_npc_name: Label = $PanelContainer/Margin/HBox/RightPane/Header/LabelName
@onready var label_npc_title: Label = $PanelContainer/Margin/HBox/RightPane/Header/LabelTitle
@onready var label_npc_meta: Label = $PanelContainer/Margin/HBox/RightPane/Header/LabelMeta

@onready var bar_caution: ProgressBar = $PanelContainer/Margin/HBox/RightPane/TraitsBox/Margin/VBox/Grid/BarCaution
@onready var bar_greed: ProgressBar = $PanelContainer/Margin/HBox/RightPane/TraitsBox/Margin/VBox/Grid/BarGreed
@onready var bar_mercy: ProgressBar = $PanelContainer/Margin/HBox/RightPane/TraitsBox/Margin/VBox/Grid/BarMercy
@onready var bar_ambition: ProgressBar = $PanelContainer/Margin/HBox/RightPane/TraitsBox/Margin/VBox/Grid/BarAmbition
@onready var bar_honor: ProgressBar = $PanelContainer/Margin/HBox/RightPane/TraitsBox/Margin/VBox/Grid/BarHonor

@onready var label_affinity_val: Label = $PanelContainer/Margin/HBox/RightPane/RelationsBox/Margin/VBox/Grid/LabelAffinityVal
@onready var label_trust_val: Label = $PanelContainer/Margin/HBox/RightPane/RelationsBox/Margin/VBox/Grid/LabelTrustVal
@onready var label_debt_val: Label = $PanelContainer/Margin/HBox/RightPane/RelationsBox/Margin/VBox/Grid/LabelDebtVal
@onready var label_grudge_val: Label = $PanelContainer/Margin/HBox/RightPane/RelationsBox/Margin/VBox/Grid/LabelGrudgeVal

@onready var text_memories: RichTextLabel = $PanelContainer/Margin/HBox/RightPane/MemoriesBox/TextMemories
@onready var btn_gift: Button = $PanelContainer/Margin/HBox/RightPane/ActionFooter/BtnGift
@onready var btn_close: Button = $PanelContainer/Margin/HBox/RightPane/ActionFooter/BtnClose

var _current_filter: String = "all"
var _selected_npc_id: String = ""

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_panel)
	btn_filter_all.pressed.connect(func(): _set_filter("all"))
	btn_filter_friends.pressed.connect(func(): _set_filter("friends"))
	btn_filter_enemies.pressed.connect(func(): _set_filter("enemies"))
	btn_filter_sect.pressed.connect(func(): _set_filter("sect"))
	btn_gift.pressed.connect(_on_gift_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_J or event.keycode == KEY_ESCAPE)):
		close_panel()
		get_viewport().set_input_as_handled()

func open_panel() -> void:
	visible = true
	_refresh_npc_list()

func close_panel() -> void:
	visible = false

func _set_filter(f: String) -> void:
	_current_filter = f
	_refresh_npc_list()

func _refresh_npc_list() -> void:
	for child in npc_list_container.get_children():
		child.queue_free()
		
	var npcs = GameSession.get_all_active_npcs()
	# Sắp xếp theo id
	npcs.sort_custom(func(a, b): return a.get("id", "") < b.get("id", ""))
	
	var first_matching_id = ""
	for npc in npcs:
		var nid = npc.get("id", "")
		var rel = GameSession.get_npc_relationship(nid, "player")
		var aff = rel.get("affinity", 0)
		var grudge = rel.get("grudge", 0)
		
		# Lọc
		if _current_filter == "friends" and aff <= 10:
			continue
		elif _current_filter == "enemies" and grudge < 30 and aff >= 0:
			continue
		elif _current_filter == "sect" and npc.get("sect_id", "") != "sect_thanh_vi":
			continue
			
		if first_matching_id == "":
			first_matching_id = nid
			
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(360, 48)
		btn.text = "%s [%s] • %s" % [
			npc.get("name", "Vô Danh"),
			npc.get("realm_name", "Phàm Nhân"),
			"Thiện Cảm: %+d" % aff if grudge < 30 else "Cừu Thù: %d" % grudge
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _select_npc(nid))
		npc_list_container.add_child(btn)
		
	if _selected_npc_id == "" or not GameSession.world_npcs.has(_selected_npc_id):
		if first_matching_id != "":
			_select_npc(first_matching_id)
		else:
			_clear_npc_details()
	else:
		_select_npc(_selected_npc_id)

func _select_npc(npc_id: String) -> void:
	_selected_npc_id = npc_id
	var npc = GameSession.get_npc(npc_id)
	if npc.is_empty():
		return
		
	label_npc_name.text = npc.get("name", "Vô Danh")
	label_npc_title.text = "%s • %s" % [npc.get("title", "Tán Tu"), npc.get("realm_name", "Phàm Nhân")]
	
	var age = int(npc.get("age_days", 0) / 360)
	var lifespan = int(npc.get("lifespan_days", 0) / 360)
	label_npc_meta.text = "Tuổi thọ: %d / %d năm  |  Linh thạch: %d  |  Vị trí: %s" % [
		age, lifespan, npc.get("money", 0), npc.get("location_name", "Sơn Dã")
	]
	
	# Tính cách
	var traits = npc.get("traits", { "caution": 50, "greed": 50, "mercy": 50, "ambition": 50, "honor": 50 })
	bar_caution.value = traits.get("caution", 50)
	bar_greed.value = traits.get("greed", 50)
	bar_mercy.value = traits.get("mercy", 50)
	bar_ambition.value = traits.get("ambition", 50)
	bar_honor.value = traits.get("honor", 50)
	
	# Quan hệ với người chơi
	var rel = GameSession.get_npc_relationship(npc_id, "player")
	var aff = rel.get("affinity", 0)
	label_affinity_val.text = "%+d" % aff
	label_trust_val.text = "%d / 100" % rel.get("trust", 0)
	label_debt_val.text = "%d" % rel.get("debt", 0)
	label_grudge_val.text = "%d" % rel.get("grudge", 0)
	
	# Nhật ký Ký ức
	var mems = npc.get("memories", [])
	if mems.is_empty():
		text_memories.text = "[color=#888888]Chưa có sự kiện ân oán trực tiếp nào được ghi nhận.[/color]"
	else:
		var mem_str = ""
		for m in mems:
			var act = "Bạn" if m.get("actor_id") == "player" else m.get("actor_id")
			mem_str += "[color=#e0c068]• [%02d/%02d Năm %d][/color] %s đối với %s (%s)\n" % [
				m.get("day", 1), m.get("month", 1), m.get("year", 1),
				act, m.get("target_id"), m.get("event_type")
			]
		text_memories.text = mem_str

func _clear_npc_details() -> void:
	label_npc_name.text = "Chưa Chọn NPC"
	label_npc_title.text = "—"
	label_npc_meta.text = "—"
	text_memories.text = "[color=#888888]Không có dữ liệu.[/color]"

func _on_gift_pressed() -> void:
	if _selected_npc_id == "":
		return
	if GameSession.get_item_count("item_linh_thach") >= 10:
		GameSession.remove_item("item_linh_thach", 10)
		GameSession.modify_npc_relationship(_selected_npc_id, "player", 15, 10, 0, 0)
		GameSession.log_memory_event("player", _selected_npc_id, "gift_linh_thach", "poi_thanh_tri_tran", [], 1, false)
		if EventBus:
			EventBus.notification_requested.emit("Đã tặng 10 Linh Thạch! Thiện cảm tăng +15.", "success")
		_select_npc(_selected_npc_id)
		_refresh_npc_list()
	else:
		if EventBus:
			EventBus.notification_requested.emit("Không đủ 10 Linh Thạch để kết thiện duyên!", "warning")
