extends Control

## AlchemyModal — Giao diện Luyện Đan Dược (Dược Phẩm Các)
## Cho phép tu sĩ khai lò luyện chế các loại thần đan từ thảo dược và linh thạch.

const AlchemyService = preload("res://scripts/domain/alchemy_service.gd")

signal alchemy_closed

@onready var recipe_list_container: VBoxContainer = $PanelContainer/Margin/HBox/LeftPane/Scroll/RecipeList
@onready var label_title: Label = $PanelContainer/Margin/HBox/RightPane/Header/LabelTitle
@onready var label_desc: Label = $PanelContainer/Margin/HBox/RightPane/LabelDesc
@onready var label_realm_req: Label = $PanelContainer/Margin/HBox/RightPane/ReqBox/LabelRealm
@onready var label_cost_stones: Label = $PanelContainer/Margin/HBox/RightPane/ReqBox/LabelStones
@onready var label_success_rate: Label = $PanelContainer/Margin/HBox/RightPane/ReqBox/LabelRate
@onready var materials_box: VBoxContainer = $PanelContainer/Margin/HBox/RightPane/MaterialsContainer/VBox
@onready var btn_craft: Button = $PanelContainer/Margin/HBox/RightPane/BottomBox/BtnCraft
@onready var btn_close: Button = $PanelContainer/Margin/HBox/RightPane/BottomBox/BtnClose
@onready var label_status: Label = $PanelContainer/Margin/HBox/RightPane/LabelStatus
@onready var label_player_stones: Label = $PanelContainer/Margin/HBox/LeftPane/LabelPlayerStones

var _selected_recipe_id: String = ""

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_panel)
	btn_craft.pressed.connect(_on_craft_pressed)
	if EventBus:
		EventBus.inventory_changed.connect(func(_i, _c): _refresh_ui())

func open_panel() -> void:
	visible = true
	var recipes = AlchemyService.get_available_recipes()
	if recipes.size() > 0 and _selected_recipe_id == "":
		_selected_recipe_id = recipes[0].get("id", "")
	_refresh_ui()

func close_panel() -> void:
	visible = false
	alchemy_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_panel()
		get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
	_update_recipe_list()
	_update_recipe_details()

func _update_recipe_list() -> void:
	for child in recipe_list_container.get_children():
		child.queue_free()
		
	var stones = GameSession.get_item_count("item_linh_thach")
	label_player_stones.text = "Linh Thạch Hiện Có: %d" % stones
	
	var recipes = AlchemyService.get_available_recipes()
	for r in recipes:
		var rid = r.get("id", "")
		var r_name = r.get("name", "Đan Phương")
		var out_id = r.get("output_item_id", "")
		var out_def = ContentRegistry.get_item(out_id)
		var out_name = out_def.get("name", out_id)
		
		var btn = Button.new()
		btn.text = "%s (%s)" % [r_name, out_name]
		btn.custom_minimum_size = Vector2(240, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if rid == _selected_recipe_id:
			btn.modulate = Color(1.2, 1.2, 0.8)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)
			
		btn.pressed.connect(func():
			_selected_recipe_id = rid
			_refresh_ui()
		)
		recipe_list_container.add_child(btn)

func _update_recipe_details() -> void:
	for child in materials_box.get_children():
		child.queue_free()
		
	if _selected_recipe_id == "":
		label_title.text = "Chọn Đan Phương"
		label_desc.text = "Hãy chọn một đan phương bên trái để bắt đầu luyện đan."
		btn_craft.disabled = true
		return
		
	var recipe = ContentRegistry.get_recipe(_selected_recipe_id)
	if recipe.is_empty():
		return
		
	var out_id = recipe.get("output_item_id", "")
	var out_count = recipe.get("output_count", 1)
	var out_def = ContentRegistry.get_item(out_id)
	var out_name = out_def.get("name", out_id)
	
	label_title.text = "%s [Sản lượng: %dx %s]" % [recipe.get("name", ""), out_count, out_name]
	label_desc.text = recipe.get("description", "")
	
	var req_realm = recipe.get("required_realm", "realm_pham_nhan")
	var realm_def = ContentRegistry.get_realm(req_realm)
	var realm_name = realm_def.get("name", req_realm)
	var is_realm_ok = not (req_realm == "realm_luyen_khi_1" and GameSession.realm_id == "realm_pham_nhan")
	
	label_realm_req.text = "Yêu Cầu Cảnh Giới: %s (%s)" % [realm_name, "Đạt" if is_realm_ok else "Chưa Đạt"]
	label_realm_req.modulate = Color(0.4, 0.9, 0.4) if is_realm_ok else Color(0.9, 0.4, 0.4)
	
	var cost_stones = recipe.get("cost_spirit_stones", 0)
	var cur_stones = GameSession.get_item_count("item_linh_thach")
	var is_stone_ok = cur_stones >= cost_stones
	label_cost_stones.text = "Tiêu Hao Linh Thạch: %d / %d" % [cost_stones, cur_stones]
	label_cost_stones.modulate = Color(0.4, 0.9, 0.4) if is_stone_ok else Color(0.9, 0.4, 0.4)
	
	var rate = int(recipe.get("success_rate", 1.0) * 100)
	label_success_rate.text = "Tỉ Lệ Thành Đan: %d%%" % rate
	
	# Danh sách dược liệu
	var materials = recipe.get("materials", [])
	for mat in materials:
		var mid = mat.get("item_id", "")
		var req_c = mat.get("count", 1)
		var cur_c = GameSession.get_item_count(mid)
		var m_def = ContentRegistry.get_item(mid)
		var m_name = m_def.get("name", mid)
		
		var lbl = Label.new()
		var ok = cur_c >= req_c
		lbl.text = "• %s: %d / %d (%s)" % [m_name, cur_c, req_c, "Đủ" if ok else "Thiếu %d" % (req_c - cur_c)]
		lbl.modulate = Color(0.4, 0.9, 0.4) if ok else Color(0.9, 0.4, 0.4)
		materials_box.add_child(lbl)
		
	var check = AlchemyService.can_craft(_selected_recipe_id)
	btn_craft.disabled = not check["can_craft"]
	label_status.text = check["reason"]
	label_status.modulate = Color(0.4, 0.9, 0.4) if check["can_craft"] else Color(0.9, 0.5, 0.3)

func _on_craft_pressed() -> void:
	if _selected_recipe_id == "":
		return
	var res = AlchemyService.craft_recipe(_selected_recipe_id)
	if res["success"]:
		if AudioService:
			AudioService.play_sfx("sfx_alchemy_bubble")
		label_status.text = "Thành công: %s" % res["reason"]
		label_status.modulate = Color(0.3, 1.0, 0.4)
	else:
		label_status.text = "Thất bại: %s" % res["reason"]
		label_status.modulate = Color(1.0, 0.3, 0.3)
	_refresh_ui()
