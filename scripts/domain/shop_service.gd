extends RefCounted
class_name ShopService

## ShopService — Dịch vụ Quản lý Sạp Hàng Tu Sĩ (Chợ Tán Tu)
## Đáp ứng Sprint S2/S3: Thuê sạp 3 ngày, Ký gửi kho vật phẩm (Escrow), Giao dịch nguyên tử & Quyết toán.
## GHI CHÚ BẢO MẬT & CO-OP:
##   - Giao dịch P2P trực tiếp (Trade Window 1-1): Trạng thái NOT_IMPLEMENTED.
##   - Giao dịch mạng nhiều người chơi đi qua CoopWorldSync với Idempotency request_id chống duping và race condition.

static func is_p2p_trade_implemented() -> bool:
	return false # Trạng thái NOT_IMPLEMENTED, trung thực không tự nhận đã xong

static var is_leased: bool = false
static var lease_expire_day: int = 0
static var lease_cost_per_cycle: int = 50
static var lease_cycle_days: int = 3
static var stall_name: String = "Sạp Hàng Lâm Phong"
static var escrow_items: Array[Dictionary] = [] # [{ "item_id": String, "count": int, "price": int }]
static var accumulated_revenue: int = 0
static var total_sales_count: int = 0

static func reset_stall() -> void:
	is_leased = false
	lease_expire_day = 0
	stall_name = "Sạp Hàng Tu Sĩ"
	escrow_items = []
	accumulated_revenue = 0
	total_sales_count = 0

static func is_lease_active() -> bool:
	if not is_leased:
		return false
	var total_days = (GameClock.current_year - 1) * 360 + (GameClock.current_month - 1) * 30 + GameClock.current_day
	return total_days <= lease_expire_day

static func get_remaining_lease_days() -> int:
	if not is_leased:
		return 0
	var total_days = (GameClock.current_year - 1) * 360 + (GameClock.current_month - 1) * 30 + GameClock.current_day
	return maxi(0, lease_expire_day - total_days)

static func lease_stall(cycles: int = 1) -> Dictionary:
	if cycles <= 0:
		return { "success": false, "reason": "Chu kỳ thuê không hợp lệ!" }
		
	var base_cost = lease_cost_per_cycle * cycles
	var tax_mult = CourtManager.market_tax_multiplier if CourtManager else 1.0
	var total_cost = roundi(base_cost * tax_mult)
	var current_stones = GameSession.get_item_count("item_linh_thach")
	if current_stones < total_cost:
		return {
			"success": false,
			"reason": "Không đủ linh thạch thuê sạp! Cần %d viên (Hiện có: %d)." % [total_cost, current_stones]
		}
		
	var deducted = GameSession.remove_item("item_linh_thach", total_cost)
	if not deducted:
		return { "success": false, "reason": "Lỗi giao dịch trừ linh thạch!" }
		
	var total_days = (GameClock.current_year - 1) * 360 + (GameClock.current_month - 1) * 30 + GameClock.current_day
	if is_lease_active():
		lease_expire_day += cycles * lease_cycle_days
	else:
		lease_expire_day = total_days + (cycles * lease_cycle_days)
	is_leased = true
	
	if EventBus:
		EventBus.notification_requested.emit("Thuê sạp thành công! Thời hạn sạp tăng thêm %d ngày." % (cycles * lease_cycle_days), "success")
		
	return {
		"success": true,
		"reason": "Thuê sạp thành công!",
		"expire_day": lease_expire_day,
		"cost": total_cost
	}

static func deposit_item(item_id: String, count: int, unit_price: int) -> Dictionary:
	var clean_id = item_id.strip_edges()
	if clean_id.is_empty():
		return { "success": false, "reason": "Mã vật phẩm không được để trống!" }
	if count <= 0 or unit_price <= 0:
		return { "success": false, "reason": "Số lượng và đơn giá phải lớn hơn 0!" }
		
	var has_qty = GameSession.get_item_count(clean_id)
	if has_qty < count:
		return { "success": false, "reason": "Túi đồ không đủ vật phẩm để ký gửi!" }
		
	var removed = GameSession.remove_item(clean_id, count)
	if not removed:
		return { "success": false, "reason": "Lỗi trừ vật phẩm khỏi túi đồ!" }
		
	# Tìm xem món hàng đã có trong escrow chưa
	var found = false
	for slot in escrow_items:
		if slot.get("item_id", "") == clean_id and slot.get("price", 0) == unit_price:
			slot["count"] = slot.get("count", 0) + count
			found = true
			break
			
	if not found:
		escrow_items.append({
			"item_id": clean_id,
			"count": count,
			"price": unit_price
		})
		
	var item_def = ContentRegistry.get_item(clean_id)
	var item_name = item_def.get("name", clean_id)
	if EventBus:
		EventBus.notification_requested.emit("Đã ký gửi %dx %s vào sạp (Giá: %d linh thạch/món)." % [count, item_name, unit_price], "info")
		
	return { "success": true, "reason": "Ký gửi vật phẩm thành công!", "item_id": clean_id, "count": count, "price": unit_price }

static func withdraw_item(item_id: String, count: int, unit_price: int = -1) -> Dictionary:
	var clean_id = item_id.strip_edges()
	if clean_id.is_empty():
		return { "success": false, "reason": "Mã vật phẩm không được để trống!" }
	if count <= 0:
		return { "success": false, "reason": "Số lượng rút phải lớn hơn 0!" }
		
	for i in range(escrow_items.size()):
		var slot = escrow_items[i]
		if slot.get("item_id", "") == clean_id and (unit_price == -1 or slot.get("price", 0) == unit_price):
			var cur_count = slot.get("count", 0)
			if cur_count >= count:
				var remain = cur_count - count
				slot["count"] = remain
				if remain == 0:
					escrow_items.remove_at(i)
				GameSession.add_item(clean_id, count)
				var item_def = ContentRegistry.get_item(clean_id)
				var item_name = item_def.get("name", clean_id)
				if EventBus:
					EventBus.notification_requested.emit("Đã rút %dx %s về túi đồ." % [count, item_name], "info")
				return { "success": true, "reason": "Rút vật phẩm thành công!", "item_id": clean_id, "count": count }
			else:
				return { "success": false, "reason": "Số lượng trong sạp không đủ!" }
				
	return { "success": false, "reason": "Không tìm thấy vật phẩm trong sạp hàng!" }

static func buy_from_stall(item_id: String, count: int, buyer_wallet: int) -> Dictionary:
	var clean_id = item_id.strip_edges()
	if clean_id.is_empty():
		return { "success": false, "reason": "Mã vật phẩm không được để trống!", "cost": 0 }
	if count <= 0:
		return { "success": false, "reason": "Số lượng mua phải lớn hơn 0!", "cost": 0 }
	if buyer_wallet < 0:
		return { "success": false, "reason": "Số dư người mua không hợp lệ!", "cost": 0 }

	for i in range(escrow_items.size()):
		var slot = escrow_items[i]
		if slot.get("item_id", "") == clean_id:
			var cur_count = slot.get("count", 0)
			var price = slot.get("price", 1)
			if price <= 0:
				price = 1
			var total_cost = price * count
			
			if cur_count < count:
				return { "success": false, "reason": "Sạp hàng không còn đủ số lượng!", "cost": 0 }
			if buyer_wallet < total_cost:
				return { "success": false, "reason": "Người mua không đủ linh thạch!", "cost": 0 }
				
			# Khấu trừ nguyên tử
			var remain = cur_count - count
			slot["count"] = remain
			if remain == 0:
				escrow_items.remove_at(i)
				
			accumulated_revenue += total_cost
			total_sales_count += count
			
			return {
				"success": true,
				"reason": "Giao dịch sạp hàng thành công!",
				"item_id": clean_id,
				"count": count,
				"total_cost": total_cost,
				"unit_price": price,
				"remaining_buyer_wallet": buyer_wallet - total_cost
			}
			
	return { "success": false, "reason": "Vật phẩm không tồn tại trong sạp!", "cost": 0 }

## Giao dịch hai chiều hoàn chỉnh cho người chơi mua hàng từ sạp (Player-to-Stall Transaction)
## Đảm bảo tính nguyên tử: Trừ tiền người mua, cấp vật phẩm cho người mua, trừ kho sạp và ghi nhận doanh thu.
static func player_buy_from_stall(item_id: String, count: int) -> Dictionary:
	var clean_id = item_id.strip_edges()
	if clean_id.is_empty():
		return { "success": false, "reason": "Mã vật phẩm không được để trống!" }
	if count <= 0:
		return { "success": false, "reason": "Số lượng mua phải lớn hơn 0!" }
		
	# Tìm slot hàng
	var target_slot_idx = -1
	var unit_price = 0
	var cur_count = 0
	for i in range(escrow_items.size()):
		if escrow_items[i].get("item_id", "") == clean_id:
			target_slot_idx = i
			unit_price = escrow_items[i].get("price", 1)
			cur_count = escrow_items[i].get("count", 0)
			break
			
	if target_slot_idx == -1:
		return { "success": false, "reason": "Mặt hàng không tồn tại trong sạp!" }
	if cur_count < count:
		return { "success": false, "reason": "Sạp hàng không còn đủ số lượng yêu cầu!" }
		
	var total_cost = unit_price * count
	var player_stones = GameSession.get_item_count("item_linh_thach")
	if player_stones < total_cost:
		return { "success": false, "reason": "Linh thạch trong túi không đủ để thanh toán!" }
		
	# Giao dịch nguyên tử có rollback
	var stones_deducted = GameSession.remove_item("item_linh_thach", total_cost)
	if not stones_deducted:
		return { "success": false, "reason": "Lỗi giao dịch trừ linh thạch!" }
		
	var item_added = GameSession.add_item(clean_id, count)
	if not item_added:
		# Rollback hoàn lại linh thạch nếu add_item thất bại
		GameSession.add_item("item_linh_thach", total_cost)
		return { "success": false, "reason": "Lỗi giao dịch cấp vật phẩm vào túi!" }
		
	# Cập nhật trạng thái sạp
	var remain = cur_count - count
	escrow_items[target_slot_idx]["count"] = remain
	if remain == 0:
		escrow_items.remove_at(target_slot_idx)
		
	accumulated_revenue += total_cost
	total_sales_count += count
	
	return {
		"success": true,
		"reason": "Giao dịch thành công!",
		"item_id": clean_id,
		"count": count,
		"total_cost": total_cost,
		"unit_price": unit_price
	}

static func simulate_npc_purchases() -> int:
	if not is_lease_active() or escrow_items.size() == 0:
		return 0
		
	var items_sold = 0
	for i in range(escrow_items.size() - 1, -1, -1):
		var slot = escrow_items[i]
		var i_id = slot.get("item_id", "")
		var count = slot.get("count", 0)
		var price = slot.get("price", 1)
		
		var item_def = ContentRegistry.get_item(i_id)
		var base_price = item_def.get("price", 20)
		
		# NPC mua nếu giá hợp lý (không quá 150% giá gốc)
		var price_ratio = float(price) / float(maxi(base_price, 1))
		var buy_chance = 0.6
		if price_ratio <= 1.0:
			buy_chance = 0.85
		elif price_ratio <= 1.5:
			buy_chance = 0.5
		else:
			buy_chance = 0.15
			
		if RNGService.randf() <= buy_chance and count > 0:
			var qty_to_buy = mini(count, RNGService.randi_range(1, 2))
			var cost = qty_to_buy * price
			slot["count"] = count - qty_to_buy
			if slot["count"] == 0:
				escrow_items.remove_at(i)
			accumulated_revenue += cost
			total_sales_count += qty_to_buy
			items_sold += qty_to_buy
			
	if items_sold > 0 and EventBus:
		EventBus.notification_requested.emit("Khách tán tu đã mua %d món hàng tại sạp của bạn!" % items_sold, "info")
		
	return items_sold

static func withdraw_revenue() -> int:
	var rev = accumulated_revenue
	if rev <= 0:
		return 0
		
	GameSession.add_item("item_linh_thach", rev)
	accumulated_revenue = 0
	if EventBus:
		EventBus.notification_requested.emit("Đã kết toán doanh thu sạp! Thu về +%d Linh Thạch." % rev, "success")
	return rev

static func to_dict() -> Dictionary:
	return {
		"is_leased": is_leased,
		"lease_expire_day": lease_expire_day,
		"stall_name": stall_name,
		"escrow_items": escrow_items.duplicate(true),
		"accumulated_revenue": accumulated_revenue,
		"total_sales_count": total_sales_count
	}

static func from_dict(data: Dictionary) -> void:
	is_leased = data.get("is_leased", false)
	lease_expire_day = maxi(0, int(data.get("lease_expire_day", 0)))
	stall_name = str(data.get("stall_name", "Sạp Hàng Tu Sĩ"))
	escrow_items = []
	var raw_items = data.get("escrow_items", [])
	if raw_items is Array:
		for it in raw_items:
			if it is Dictionary:
				var i_id = str(it.get("item_id", "")).strip_edges()
				var i_count = int(it.get("count", 0))
				var i_price = int(it.get("price", 0))
				if not i_id.is_empty() and i_count > 0 and i_price > 0:
					escrow_items.append({
						"item_id": i_id,
						"count": i_count,
						"price": i_price
					})
	accumulated_revenue = maxi(0, int(data.get("accumulated_revenue", 0)))
	total_sales_count = maxi(0, int(data.get("total_sales_count", 0)))
