extends Node2D

## TownView — Cảnh Thị Trấn Thanh Trì (Town Hub)
## Tích hợp Luyện Đan (Dược Phẩm Các), Quản lý Sạp Hàng (Chợ Tán Tu),
## Lịch trình sinh hoạt 12 Canh Giờ và 36 NPC tuần hoàn sinh thái.

const ShopService = preload("res://scripts/domain/shop_service.gd")

@onready var label_town_title: Label = $CanvasLayer/HUDTop/PanelTown/HBox/LabelTownName
@onready var label_clock: Label = $CanvasLayer/HUDTop/PanelClock/HBox/LabelClock
@onready var label_player_info: Label = $CanvasLayer/HUDTop/PanelPlayer/HBox/LabelPlayer
@onready var label_stones: Label = $CanvasLayer/HUDTop/PanelPlayer/HBox/LabelStones

@onready var btn_leave_town: Button = $CanvasLayer/HUDBottom/HBox/BtnLeaveTown
@onready var btn_open_inv: Button = $CanvasLayer/HUDBottom/HBox/BtnInventory
@onready var btn_open_char: Button = $CanvasLayer/HUDBottom/HBox/BtnCharacter
@onready var btn_open_alchemy: Button = $CanvasLayer/HUDBottom/HBox/BtnAlchemy
@onready var btn_open_shop: Button = $CanvasLayer/HUDBottom/HBox/BtnShop

@onready var dialogue_modal: Control = $CanvasLayer/DialogueModal
@onready var inventory_panel: Control = $CanvasLayer/InventoryPanel
@onready var character_panel: Control = $CanvasLayer/CharacterPanel
@onready var alchemy_modal: Control = $CanvasLayer/AlchemyModal
@onready var player_shop_modal: Control = $CanvasLayer/PlayerShopModal

func _ready() -> void:
	btn_leave_town.pressed.connect(_on_leave_town)
	btn_open_inv.pressed.connect(func(): inventory_panel.open_panel())
	btn_open_char.pressed.connect(func(): character_panel.open_panel())
	btn_open_alchemy.pressed.connect(func(): alchemy_modal.open_panel())
	btn_open_shop.pressed.connect(func(): player_shop_modal.open_panel())
	
	_connect_building_buttons()
	_update_header()
	_update_clock_and_npc_routine()
	
	if EventBus:
		EventBus.inventory_changed.connect(func(_i, _c): _update_header())
		EventBus.player_realm_changed.connect(func(_r): _update_header())
		if EventBus.has_signal("hour_changed"):
			EventBus.hour_changed.connect(func(_h): _on_hour_ticked())

func _process(_delta: float) -> void:
	_update_clock_and_npc_routine()

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_modal.visible or inventory_panel.visible or character_panel.visible or alchemy_modal.visible or player_shop_modal.visible:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			inventory_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			character_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			alchemy_modal.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			player_shop_modal.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_leave_town()
			get_viewport().set_input_as_handled()

func _update_header() -> void:
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	var realm_name = realm.get("name", "Phàm Nhân")
	label_player_info.text = "%s • %s" % [GameSession.player_name, realm_name]
	
	var stones = GameSession.get_item_count("item_linh_thach")
	label_stones.text = "Linh Thạch: %d" % stones

func _on_hour_ticked() -> void:
	# Mô phỏng khách mua hàng tại sạp nếu có
	ShopService.simulate_npc_purchases()
	_update_clock_and_npc_routine()

func _update_clock_and_npc_routine() -> void:
	var cur_canh = GameClock.get_canh_gio_name()
	var hour_str = "%02d:00" % GameClock.current_hour
	var visitors = get_active_town_visitors()
	
	label_clock.text = "%s (%s) • %d Tu Sĩ Vãng Lai Tại Trấn" % [cur_canh, hour_str, visitors.size()]

func get_active_town_visitors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var h = GameClock.current_hour
	var all_npcs = ContentRegistry.get_all_npcs()
	
	for npc in all_npcs:
		var nid = npc.get("id", "")
		# Xác định vị trí sinh hoạt của NPC theo 12 Canh Giờ
		var active_here = false
		if h >= 5 and h < 9:
			# Giờ Mão - Giờ Thìn: Tập trung tại Chợ & Dược Phẩm Các
			active_here = (nid.hash() % 3 == 0 or npc.get("role", "").contains("Tán Tu") or npc.get("role", "").contains("Dược"))
		elif h >= 9 and h < 15:
			# Giờ Tỵ - Giờ Mùi: Giờ cao điểm, buôn bán và bái tông môn
			active_here = (nid.hash() % 2 == 0 or npc.get("role", "").contains("Đệ Tử") or npc.get("role", "").contains("Thương"))
		elif h >= 15 and h < 19:
			# Giờ Thân - Giờ Dậu: Chiều tà, tụ họp đàm đạo quán trọ
			active_here = (nid.hash() % 3 != 0)
		else:
			# Giờ Tuất - Giờ Dần: Đêm, quán trọ hoặc bế quan tĩnh tọa
			active_here = (nid.hash() % 4 == 0 or npc.get("role", "").contains("Lão"))
			
		if active_here:
			result.append(npc)
			
	return result

func _connect_building_buttons() -> void:
	# 1. Quán Trọ (Mạc Tư Viễn)
	var btn_inn = $BuildingsContainer/BuildingInn/BtnInteract
	btn_inn.pressed.connect(func(): dialogue_modal.open_for_npc("npc_mac_tu_vien"))
	
	# 2. Dược Phẩm Các (Thư Nguyệt & Khai Lò Luyện Đan)
	var btn_alchemy_talk = $BuildingsContainer/BuildingAlchemy/AlchemyHBox/BtnInteract
	btn_alchemy_talk.pressed.connect(func(): dialogue_modal.open_for_npc("npc_thu_nguyet"))
	var btn_alchemy_craft = $BuildingsContainer/BuildingAlchemy/AlchemyHBox/BtnCraft
	btn_alchemy_craft.pressed.connect(func(): alchemy_modal.open_panel())
	
	# 3. Chợ Tán Tu (Kỷ Hoàn & Quản Lý Sạp Hàng)
	var btn_market_talk = $BuildingsContainer/BuildingMarket/MarketHBox/BtnInteract
	btn_market_talk.pressed.connect(func(): dialogue_modal.open_for_npc("npc_ky_hoan"))
	var btn_market_stall = $BuildingsContainer/BuildingMarket/MarketHBox/BtnStall
	btn_market_stall.pressed.connect(func(): player_shop_modal.open_panel())
	
	# 4. Thanh Vi Tông Phân Điện (Đoàn Vĩnh & Lâm Du)
	var btn_sect_elder = $BuildingsContainer/BuildingSect/HBox/BtnElder
	btn_sect_elder.pressed.connect(func(): dialogue_modal.open_for_npc("npc_doan_vinh"))
	var btn_sect_disciple = $BuildingsContainer/BuildingSect/HBox/BtnDisciple
	btn_sect_disciple.pressed.connect(func(): dialogue_modal.open_for_npc("npc_lam_du"))
	
	# 5. Cổng Rừng Trúc (Bạch San)
	var btn_gate = $BuildingsContainer/BuildingGate/BtnInteract
	btn_gate.pressed.connect(func(): dialogue_modal.open_for_npc("npc_bach_san"))

func _on_leave_town() -> void:
	if EventBus:
		EventBus.notification_requested.emit("Rời trấn, quay trở lại Bản Đồ Thế Giới...", "info")
	get_tree().change_scene_to_file("res://scenes/world/world_map.tscn")
