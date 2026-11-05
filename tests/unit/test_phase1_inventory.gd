extends RefCounted

## Test suite: Hệ thống Túi Đồ & Tiêu Dùng Vật Phẩm (Phase 1)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array = []
	
	# Chuẩn bị dữ liệu mẫu và dọn sạch túi để kiểm thử độc lập
	GameSession.start_new_game("Kiểm Thử Giả", 123456)
	GameSession.inventory.clear()
	
	# Test 1: Thêm vật phẩm và kiểm tra số lượng
	GameSession.add_item("item_linh_thach", 50)
	var stones = GameSession.get_item_count("item_linh_thach")
	if stones == 50:
		logs.append("✓ [Pass] Thêm 50 viên Linh Thạch vào túi thành công")
		passed += 1
	else:
		logs.append("✗ [Fail] Số lượng Linh Thạch kỳ vọng 50, thực tế %d" % stones)
		failed += 1
	
	# Test 2: Thêm tiếp vật phẩm cùng loại để kiểm tra cộng dồn (Stacking)
	GameSession.add_item("item_linh_thach", 25)
	if GameSession.get_item_count("item_linh_thach") == 75:
		logs.append("✓ [Pass] Cơ chế cộng dồn (Stacking) hoạt động chính xác (75 Linh Thạch)")
		passed += 1
	else:
		logs.append("✗ [Fail] Cộng dồn Linh Thạch thất bại")
		failed += 1
		
	# Test 3: Trừ vật phẩm
	var remove_ok = GameSession.remove_item("item_linh_thach", 30)
	if remove_ok and GameSession.get_item_count("item_linh_thach") == 45:
		logs.append("✓ [Pass] Trừ 30 Linh Thạch thành công, còn lại 45 viên")
		passed += 1
	else:
		logs.append("✗ [Fail] Trừ Linh Thạch thất bại")
		failed += 1
		
	# Test 4: Trừ quá số lượng hiện có phải bị từ chối và trả về false
	var over_remove = GameSession.remove_item("item_linh_thach", 100)
	if not over_remove and GameSession.get_item_count("item_linh_thach") == 45:
		logs.append("✓ [Pass] Giao dịch an toàn: Từ chối trừ khi số lượng không đủ")
		passed += 1
	else:
		logs.append("✗ [Fail] Lỗi cho phép trừ âm số lượng vật phẩm")
		failed += 1
		
	# Test 5: Sử dụng Đan Dược Tụ Khí Đan tăng Tu Vi
	GameSession.cultivation_xp = 10
	GameSession.add_item("item_tu_khi_dan", 2)
	var use_ok = GameSession.use_item("item_tu_khi_dan")
	if use_ok and GameSession.get_item_count("item_tu_khi_dan") == 1 and GameSession.cultivation_xp == 35:
		logs.append("✓ [Pass] Sử dụng Tụ Khí Đan: Tiêu hao 1 đan và tăng chính xác +25 Tu Vi (10 -> 35)")
		passed += 1
	else:
		logs.append("✗ [Fail] Sử dụng Tụ Khí Đan không đúng kết quả kỳ vọng")
		failed += 1
		
	# Test 6: Sử dụng Hồi Xuân Đan hồi phục Khí Huyết
	GameSession.current_hp = 40
	GameSession.max_hp = 100
	GameSession.add_item("item_hoi_xuan_dan", 1)
	var heal_ok = GameSession.use_item("item_hoi_xuan_dan")
	if heal_ok and GameSession.current_hp == 90 and GameSession.get_item_count("item_hoi_xuan_dan") == 0:
		logs.append("✓ [Pass] Sử dụng Hồi Xuân Đan: Hồi phục +50 HP (40 -> 90) và tiêu thụ đan dược")
		passed += 1
	else:
		logs.append("✗ [Fail] Sử dụng Hồi Xuân Đan thất bại: HP=%d, Count=%d" % [GameSession.current_hp, GameSession.get_item_count("item_hoi_xuan_dan")])
		failed += 1
		
	return {
		"name": "Phase 1 - InventorySystem",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
