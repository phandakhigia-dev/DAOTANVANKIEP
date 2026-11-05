extends RefCounted

## Test suite: Hệ thống Bế Quan Đột Phá Cảnh Giới (Phase 1)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array = []
	
	GameSession.start_new_game("Đạo Hữu Thí Nghiệm", 777888)
	
	# Test 1: Ban đầu là Phàm Nhân, chưa đủ tu vi thì can_breakthrough phải trả về false
	GameSession.cultivation_xp = 20
	if not GameSession.can_breakthrough():
		logs.append("✓ [Pass] Từ chối đột phá khi Tu Vi chưa chạm đỉnh (20 / 100)")
		passed += 1
	else:
		logs.append("✗ [Fail] Cho phép đột phá sai khi chưa đủ Tu Vi")
		failed += 1
		
	# Test 2: Đủ 100 Tu Vi nhưng thiếu đan dược Tụ Khí Đan -> vẫn phải từ chối
	GameSession.cultivation_xp = 100
	GameSession.inventory.clear() # Đảm bảo không có đan
	if not GameSession.can_breakthrough():
		logs.append("✓ [Pass] Từ chối đột phá khi thiếu dược đan trợ lực (Tụ Khí Đan = 0)")
		passed += 1
	else:
		logs.append("✗ [Fail] Cho phép đột phá mà không cần đan dược bảo đảm")
		failed += 1
		
	# Test 3: Đủ 100 Tu Vi và sở hữu Tụ Khí Đan -> can_breakthrough phải trả về true
	GameSession.add_item("item_tu_khi_dan", 1)
	if GameSession.can_breakthrough():
		logs.append("✓ [Pass] Đủ điều kiện đột phá: 100 Tu Vi + 1x Tụ Khí Đan hợp lệ")
		passed += 1
	else:
		logs.append("✗ [Fail] can_breakthrough trả về false dù đã đủ mọi điều kiện")
		failed += 1
		
	# Test 4: Thực hiện bế quan đột phá
	var initial_dan_count = GameSession.get_item_count("item_tu_khi_dan")
	var bt_success = GameSession.breakthrough_to_next_realm()
	if bt_success and GameSession.realm_id == "realm_luyen_khi_1":
		logs.append("✓ [Pass] Đột phá thành công chuyển từ Phàm Nhân lên Luyện Khí Tầng 1")
		passed += 1
	else:
		logs.append("✗ [Fail] Đột phá thất bại hoặc sai cảnh giới")
		failed += 1
		
	# Test 5: Kiểm tra tiêu hao nguyên liệu đan dược
	if GameSession.get_item_count("item_tu_khi_dan") == (initial_dan_count - 1):
		logs.append("✓ [Pass] Giao dịch nguyên tử: Đã tiêu hao chính xác 1 viên Tụ Khí Đan")
		passed += 1
	else:
		logs.append("✗ [Fail] Số lượng Tụ Khí Đan sau đột phá không đổi")
		failed += 1
		
	# Test 6: Kiểm tra chỉ số cơ bản sau đột phá tăng trưởng theo bảng balance
	var hp_ok = GameSession.max_hp == 160
	var mp_ok = GameSession.max_mp == 50
	var atk_ok = GameSession.attack == 18
	var def_ok = GameSession.defense == 10
	var spd_ok = GameSession.speed == 190.0
	
	if hp_ok and mp_ok and atk_ok and def_ok and spd_ok:
		logs.append("✓ [Pass] Thuộc tính tăng trưởng chính xác theo data: HP(160), MP(50), Công(18), Thủ(10), Thân pháp(190)")
		passed += 1
	else:
		logs.append("✗ [Fail] Thuộc tính sau đột phá sai: HP=%d, MP=%d, ATK=%d, DEF=%d, SPD=%f" % [
			GameSession.max_hp, GameSession.max_mp, GameSession.attack, GameSession.defense, GameSession.speed
		])
		failed += 1
		
	return {
		"name": "Phase 1 - BreakthroughEngine",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
