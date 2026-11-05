extends RefCounted

## TestPhase3Shop — Kiểm thử tự động Hệ thống Sạp Hàng Tu Sĩ & Kinh Tế Ký Gửi (Sprint S2/S3)
## Kiểm tra: Thuê sạp 3 ngày, Ký gửi kho vật phẩm (Escrow), Giao dịch nguyên tử, Quyết toán doanh thu & Serialization.

const ShopService = preload("res://scripts/domain/shop_service.gd")

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Khởi tạo phiên chơi sạch
	GameSession.start_new_game("Tán Tu Buôn Bán", 771122)
	ShopService.reset_stall()
	
	# Test 1: Từ chối thuê sạp khi thiếu linh thạch
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thach", 30) # Chỉ có 30/50 LT
	
	var lease_fail = ShopService.lease_stall(1)
	if not lease_fail["success"] and not ShopService.is_lease_active():
		passed += 1
		logs.append("✓ [Pass] Từ chối thuê sạp khi thiếu linh thạch (30/50 LT)")
	else:
		failed += 1
		logs.append("✗ [Fail] Cho phép thuê sạp khi không đủ tiền!")
		
	# Test 2: Thuê sạp thành công (Chu kỳ 3 ngày, trừ 50 LT)
	GameSession.add_item("item_linh_thach", 100) # Thêm 100 LT (tổng 130 LT)
	var lease_ok = ShopService.lease_stall(1)
	var rem_stones_after_lease = GameSession.get_item_count("item_linh_thach")
	
	if lease_ok["success"] and ShopService.is_lease_active() and rem_stones_after_lease == 80:
		passed += 1
		logs.append("✓ [Pass] Thuê sạp 3 ngày thành công: Trừ 50 LT (còn 80 LT) và kích hoạt sạp hàng")
	else:
		failed += 1
		logs.append("✗ [Fail] Thuê sạp thất bại hoặc trừ sai số tiền!")
		
	# Test 3: Ký gửi vật phẩm vào Kho sạp hàng (Escrow Deposit)
	# Người chơi có 5x Hồi Xuân Đan, ký gửi 3x vào sạp với giá 25 LT/viên
	GameSession.add_item("item_hoi_xuan_dan", 5)
	var dep_res = ShopService.deposit_item("item_hoi_xuan_dan", 3, 25)
	var inv_count = GameSession.get_item_count("item_hoi_xuan_dan")
	
	if dep_res["success"] and inv_count == 2 and ShopService.escrow_items.size() == 1:
		var slot = ShopService.escrow_items[0]
		if slot["count"] == 3 and slot["price"] == 25:
			passed += 1
			logs.append("✓ [Pass] Ký gửi kho sạp (Escrow): Trừ 3 đan trong túi (còn 2), lưu 3 đan vào kho với giá 25 LT")
		else:
			failed += 1
			logs.append("✗ [Fail] Dữ liệu trong kho sạp không khớp!")
	else:
		failed += 1
		logs.append("✗ [Fail] Ký gửi vật phẩm thất bại!")
		
	# Test 4: Rút hàng về túi đồ (Escrow Withdrawal)
	# Rút 1x Hồi Xuân Đan về lại túi đồ
	var withdraw_item_res = ShopService.withdraw_item("item_hoi_xuan_dan", 1, 25)
	var inv_after_withdraw = GameSession.get_item_count("item_hoi_xuan_dan")
	var escrow_after_withdraw = ShopService.escrow_items[0]["count"]
	
	if withdraw_item_res["success"] and inv_after_withdraw == 3 and escrow_after_withdraw == 2:
		passed += 1
		logs.append("✓ [Pass] Rút vật phẩm từ sạp: Túi đồ tăng lên 3, kho sạp giảm còn 2")
	else:
		failed += 1
		logs.append("✗ [Fail] Rút vật phẩm từ sạp sai lệch!")
		
	# Test 5: Giao dịch nguyên tử khi có khách mua hàng (Atomic Purchase)
	# Khách hàng có 60 LT ví tiền, mua 2x Hồi Xuân Đan (tổng 50 LT)
	var buyer_wallet = 60
	var buy_res = ShopService.buy_from_stall("item_hoi_xuan_dan", 2, buyer_wallet)
	
	if buy_res["success"] and ShopService.escrow_items.size() == 0 and ShopService.accumulated_revenue == 50:
		passed += 1
		logs.append("✓ [Pass] Giao dịch nguyên tử sạp hàng: Bán sạch 2 đan, doanh thu sạp ghi nhận chính xác +50 LT")
	else:
		failed += 1
		logs.append("✗ [Fail] Giao dịch mua hàng tại sạp thất bại!")
		
	# Test 6: Quyết toán và rút doanh thu (Settlement & Revenue Withdrawal)
	var stones_before_settle = GameSession.get_item_count("item_linh_thach")
	var withdrawn_rev = ShopService.withdraw_revenue()
	var stones_after_settle = GameSession.get_item_count("item_linh_thach")
	
	if withdrawn_rev == 50 and ShopService.accumulated_revenue == 0 and stones_after_settle == (stones_before_settle + 50):
		passed += 1
		logs.append("✓ [Pass] Quyết toán doanh thu: Rút trọn 50 LT về túi đồ, reset doanh thu sạp về 0")
	else:
		failed += 1
		logs.append("✗ [Fail] Quyết toán doanh thu thất bại!")
		
	# Test 7: Serialization to_dict / from_dict
	ShopService.deposit_item("item_hoi_xuan_dan", 1, 30)
	var saved_dict = ShopService.to_dict()
	ShopService.reset_stall()
	ShopService.from_dict(saved_dict)
	
	if ShopService.is_leased and ShopService.escrow_items.size() == 1 and ShopService.escrow_items[0]["price"] == 30:
		passed += 1
		logs.append("✓ [Pass] Khôi phục trạng thái sạp hàng (to_dict / from_dict) nguyên vẹn 100%")
	else:
		failed += 1
		logs.append("✗ [Fail] Serialization sạp hàng thất bại!")
		
	return {
		"name": "Phase 3 & S2/S3 - PlayerStallSystem",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
