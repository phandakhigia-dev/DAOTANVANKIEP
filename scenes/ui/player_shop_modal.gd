extends Control

## PlayerShopModal — Giao diện Sạp Hàng Tu Sĩ tại Chợ Tán Tu
## Cho phép tu sĩ thuê sạp hàng 3 ngày, ký gửi kho hàng (escrow), đặt giá và quyết toán doanh thu.

const ShopService = preload("res://scripts/domain/shop_service.gd")

signal shop_closed

@onready var label_lease_status: Label = $PanelContainer/Margin/VBox/HeaderBox/LabelLeaseStatus
@onready var label_revenue: Label = $PanelContainer/Margin/VBox/HeaderBox/LabelRevenue
@onready var btn_lease: Button = $PanelContainer/Margin/VBox/HeaderBox/BtnLease
@onready var btn_withdraw_rev: Button = $PanelContainer/Margin/VBox/HeaderBox/BtnWithdrawRev

@onready var inv_list_container: VBoxContainer = $PanelContainer/Margin/VBox/ContentHBox/InvPane/Scroll/VBox
@onready var stall_list_container: VBoxContainer = $PanelContainer/Margin/VBox/ContentHBox/StallPane/Scroll/VBox

@onready var spin_deposit_count: SpinBox = $PanelContainer/Margin/VBox/ContentHBox/MiddlePane/SpinCount
@onready var spin_deposit_price: SpinBox = $PanelContainer/Margin/VBox/ContentHBox/MiddlePane/SpinPrice
@onready var btn_deposit: Button = $PanelContainer/Margin/VBox/ContentHBox/MiddlePane/BtnDeposit
@onready var label_selected_item: Label = $PanelContainer/Margin/VBox/ContentHBox/MiddlePane/LabelSelectedItem

@onready var btn_close: Button = $PanelContainer/Margin/VBox/BottomBox/BtnClose

var _selected_inv_item_id: String = ""

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_panel)
	btn_lease.pressed.connect(_on_lease_pressed)
	btn_withdraw_rev.pressed.connect(_on_withdraw_rev_pressed)
	btn_deposit.pressed.connect(_on_deposit_pressed)
	
	if EventBus:
		EventBus.inventory_changed.connect(func(_i, _c): _refresh_ui())
	if CoopWorldSync:
		CoopWorldSync.stall_transaction_completed.connect(func(_r, _s, _m): _refresh_ui())

func open_panel() -> void:
	visible = true
	_selected_inv_item_id = ""
	_refresh_ui()

func close_panel() -> void:
	visible = false
	shop_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_panel()
		get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
	# 1. Trạng thái sạp hàng & doanh thu
	var is_active = ShopService.is_lease_active()
	var remaining_days = ShopService.get_remaining_lease_days()
	
	if is_active:
		label_lease_status.text = "Trạng Thái: Đang Hoạt Động (Còn lại %d ngày)" % remaining_days
		label_lease_status.modulate = Color(0.4, 0.9, 0.4)
		btn_lease.text = "Gia Hạn 3 Ngày (50 LT)"
	else:
		label_lease_status.text = "Trạng Thái: Chưa Thuê Sạp / Hết Hạn"
		label_lease_status.modulate = Color(0.9, 0.4, 0.4)
		btn_lease.text = "Thuê Sạp 3 Ngày (50 LT)"
		
	var stones = GameSession.get_item_count("item_linh_thach")
	btn_lease.disabled = (stones < 50)
	
	label_revenue.text = "Doanh Thu Tích Lũy: %d Linh Thạch | Đã Bán: %d món" % [ShopService.accumulated_revenue, ShopService.total_sales_count]
	btn_withdraw_rev.disabled = (ShopService.accumulated_revenue <= 0)
	
	# 2. Túi đồ người chơi
	for c in inv_list_container.get_children():
		c.queue_free()
		
	for slot in GameSession.inventory:
		var i_id = slot.get("item_id", slot.get("id", ""))
		var count = slot.get("quantity", slot.get("count", 0))
		if count <= 0 or i_id == "item_linh_thach":
			continue
			
		var i_def = ContentRegistry.get_item(i_id)
		var i_name = i_def.get("name", i_id)
		var btn = Button.new()
		btn.text = "%s (x%d)" % [i_name, count]
		btn.custom_minimum_size = Vector2(200, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if i_id == _selected_inv_item_id:
			btn.modulate = Color(1.2, 1.2, 0.8)
			
		btn.pressed.connect(func():
			_selected_inv_item_id = i_id
			_refresh_ui()
		)
		inv_list_container.add_child(btn)
		
	# 3. Món đang chọn để ký gửi
	if _selected_inv_item_id != "":
		var sel_def = ContentRegistry.get_item(_selected_inv_item_id)
		var sel_name = sel_def.get("name", _selected_inv_item_id)
		var cur_count = GameSession.get_item_count(_selected_inv_item_id)
		label_selected_item.text = "Món chọn: %s (Có: %d)" % [sel_name, cur_count]
		spin_deposit_count.max_value = cur_count
		spin_deposit_count.value = mini(1, cur_count)
		spin_deposit_price.value = sel_def.get("price", 10)
		btn_deposit.disabled = (not is_active or cur_count <= 0)
	else:
		label_selected_item.text = "Chưa chọn món hàng"
		btn_deposit.disabled = true
		
	# 4. Danh sách hàng trong sạp
	for c in stall_list_container.get_children():
		c.queue_free()
		
	if ShopService.escrow_items.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "Sạp hàng hiện đang trống..."
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		stall_list_container.add_child(empty_lbl)
	else:
		for slot in ShopService.escrow_items:
			var s_id = slot.get("item_id", "")
			var count = slot.get("count", 0)
			var price = slot.get("price", 0)
			var s_def = ContentRegistry.get_item(s_id)
			var s_name = s_def.get("name", s_id)
			
			var row = HBoxContainer.new()
			row.custom_minimum_size = Vector2(240, 36)
			
			var lbl = Label.new()
			lbl.size_flags_horizontal = SIZE_EXPAND_FILL
			lbl.text = "%s x%d [%d LT/món]" % [s_name, count, price]
			row.add_child(lbl)
			
			var btn_buy = Button.new()
			btn_buy.text = "Mua 1"
			btn_buy.pressed.connect(func():
				_on_buy_item_pressed(s_id, 1, price)
			)
			row.add_child(btn_buy)
			
			var btn_ret = Button.new()
			btn_ret.text = "Rút Hàng"
			btn_ret.pressed.connect(func():
				ShopService.withdraw_item(s_id, 1, price)
				_refresh_ui()
			)
			row.add_child(btn_ret)
			stall_list_container.add_child(row)

func _on_buy_item_pressed(item_id: String, count: int, unit_price: int) -> void:
	if SessionAuthority and SessionAuthority.is_coop_session():
		var peer_id = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
		var req_id = "req_buy_%d_%d" % [peer_id, Time.get_ticks_msec()]
		CoopWorldSync.request_buy_from_stall(req_id, item_id, count)
	else:
		# Solo local purchase
		var total_cost = unit_price * count
		if GameSession.get_item_count("item_linh_thach") >= total_cost:
			GameSession.remove_item("item_linh_thach", total_cost)
			GameSession.add_item(item_id, count)
			for it in ShopService.escrow_items:
				if it.get("item_id", "") == item_id:
					it["count"] -= count
					if it["count"] <= 0:
						ShopService.escrow_items.erase(it)
					break
			ShopService.accumulated_revenue += total_cost
			ShopService.total_sales_count += count
			_refresh_ui()
			if EventBus:
				EventBus.notification_requested.emit("Mua thành công 1x %s (-%d LT)" % [item_id, total_cost], "success")
		else:
			if EventBus:
				EventBus.notification_requested.emit("Không đủ Linh Thạch!", "warning")

func _on_lease_pressed() -> void:
	ShopService.lease_stall(1)
	_refresh_ui()

func _on_withdraw_rev_pressed() -> void:
	ShopService.withdraw_revenue()
	_refresh_ui()

func _on_deposit_pressed() -> void:
	if _selected_inv_item_id == "":
		return
	var count = int(spin_deposit_count.value)
	var price = int(spin_deposit_price.value)
	ShopService.deposit_item(_selected_inv_item_id, count, price)
	_refresh_ui()
