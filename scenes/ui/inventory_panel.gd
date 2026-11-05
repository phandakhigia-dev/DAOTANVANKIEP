extends Control

## InventoryPanel — Giao diện Túi Trữ Vật của Tu Sĩ
## Quản lý vật phẩm, dược đan, linh thạch và sử dụng tài nguyên

@onready var grid_container: GridContainer = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/ScrollContainer/GridContainer
@onready var label_spirit_stones: Label = $PanelContainer/MarginContainer/HBoxContainer/LeftBox/HeaderBox/LabelStones
@onready var label_item_name: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/DetailVBox/LabelItemName
@onready var label_item_type: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/DetailVBox/LabelItemType
@onready var label_item_desc: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/DetailVBox/LabelItemDesc
@onready var label_item_val: Label = $PanelContainer/MarginContainer/HBoxContainer/RightBox/DetailVBox/LabelItemVal
@onready var btn_use: Button = $PanelContainer/MarginContainer/HBoxContainer/RightBox/DetailVBox/BtnUse
@onready var btn_close: Button = $PanelContainer/MarginContainer/HBoxContainer/RightBox/BtnClose

var _selected_item_id: String = ""

func _ready() -> void:
	btn_close.pressed.connect(close_panel)
	btn_use.pressed.connect(_on_use_pressed)
	if EventBus:
		EventBus.inventory_changed.connect(_on_inventory_changed)
	refresh_inventory()

func open_panel() -> void:
	visible = true
	refresh_inventory()

func close_panel() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_I)):
		close_panel()
		get_viewport().set_input_as_handled()

func refresh_inventory() -> void:
	if not label_spirit_stones:
		return
	var stones = GameSession.get_item_count("item_linh_thach")
	label_spirit_stones.text = "Linh Thạch: %d viên" % stones
	
	# Xóa các slot cũ
	for child in grid_container.get_children():
		child.queue_free()
	
	var items = GameSession.inventory # Array of {"id": item_id, "count": count}
	if items.is_empty():
		_select_item("")
		var empty_lbl = Label.new()
		empty_lbl.text = "Túi rỗng, chưa có vật phẩm..."
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		grid_container.add_child(empty_lbl)
		return
	
	for entry in items:
		var item_id = entry.get("id", "")
		var count = entry.get("count", 1)
		var item_def = ContentRegistry.get_item(item_id)
		var item_name = item_def.get("name", item_id)
		
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(210, 52)
		slot_btn.text = "%s\nx%d" % [item_name, count]
		slot_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Tô màu theo phẩm chất
		var rarity = item_def.get("rarity", "common")
		if rarity == "rare":
			slot_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif rarity == "legendary":
			slot_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			slot_btn.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
			
		var captured_id = item_id
		slot_btn.pressed.connect(func(): _select_item(captured_id))
		grid_container.add_child(slot_btn)
	
	# Nếu chưa chọn hoặc item được chọn không còn trong túi, chọn item đầu tiên
	if _selected_item_id == "" or not GameSession.has_item(_selected_item_id):
		_select_item(items[0].get("id", ""))
	else:
		_select_item(_selected_item_id)

func _select_item(item_id: String) -> void:
	_selected_item_id = item_id
	if item_id == "":
		label_item_name.text = "Chưa chọn vật phẩm"
		label_item_type.text = ""
		label_item_desc.text = "Hãy chọn một vật phẩm trong túi để xem chi tiết công hiệu."
		label_item_val.text = ""
		btn_use.disabled = true
		return
	
	var item_def = ContentRegistry.get_item(item_id)
	label_item_name.text = item_def.get("name", "Vật phẩm lạ")
	var type_str = "Vật liệu / Khác"
	match item_def.get("type", ""):
		"pill": type_str = "Đan Dược (Có thể sử dụng)"
		"currency": type_str = "Tiền Tệ Tu Chân"
		"material": type_str = "Linh Tài / Dược Thảo"
		"quest": type_str = "Vật Phẩm Nhiệm Vụ"
	label_item_type.text = "Loại: " + type_str
	label_item_desc.text = item_def.get("description", "Không có mô tả.")
	var buy_price = item_def.get("price_buy", item_def.get("price", 0))
	var sell_price = item_def.get("price_sell", int(buy_price * 0.6))
	label_item_val.text = "Giá mua: %d Linh thạch | Bán: %d Linh thạch" % [buy_price, sell_price]
	
	var is_usable = item_def.get("type", "") == "pill" or item_def.has("effect")
	btn_use.disabled = not is_usable
	btn_use.text = "Sử Dụng" if is_usable else "Không Thể Dùng"

func _on_use_pressed() -> void:
	if _selected_item_id == "":
		return
	var item_def = ContentRegistry.get_item(_selected_item_id)
	var item_name = item_def.get("name", _selected_item_id)
	var success = GameSession.use_item(_selected_item_id)
	if success:
		if AudioService:
			AudioService.play_sfx("sfx_pill_swallow", 1.0)
		if EventBus:
			EventBus.notification_requested.emit("Đã sử dụng: %s" % item_name, "success")
		refresh_inventory()
	else:
		if EventBus:
			EventBus.notification_requested.emit("Không thể sử dụng %s lúc này!" % item_name, "warning")

func _on_inventory_changed(_item_id: String, _new_count: int) -> void:
	if visible:
		refresh_inventory()
