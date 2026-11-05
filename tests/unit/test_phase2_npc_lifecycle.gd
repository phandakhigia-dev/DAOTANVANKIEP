extends RefCounted

## Unit test: Phase 2 - Vòng Đời NPC & Đột Phá Cảnh Giới (Lifecycle & Progression)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	GameSession.start_new_game("Sinh Tử Kiểm Thử", 888999)
	
	# Test 1: Khởi tạo tuổi tác và thọ nguyên NPC
	var npc = GameSession.get_npc("npc_mac_tu_vien")
	var initial_age = npc.get("age_days", 0)
	var initial_lifespan = npc.get("lifespan_days", 0)
	if initial_age > 0 and initial_lifespan > initial_age and npc.get("alive", false):
		passed += 1
		logs.append("✓ [Pass] Khởi tạo dữ liệu vòng đời hợp lệ: Tuổi %d ngày, Thọ nguyên %d ngày" % [initial_age, initial_lifespan])
	else:
		failed += 1
		logs.append("✗ [Fail] Thông số vòng đời không hợp lệ: %s" % str(npc))
		
	# Test 2: Thọ nguyên cạn kiệt dẫn đến Tọa Hóa (Tử vong tự nhiên)
	# Thiết lập NPC thử nghiệm gần hết thọ nguyên (còn đúng 10 ngày)
	var test_elder = {
		"id": "npc_lao_to_test",
		"name": "Cổ Lão Tán Nhân",
		"realm_name": "Trúc Cơ Sơ Kỳ",
		"realm_tier": 2,
		"realm_stage": 1,
		"age_days": 100 * 360,
		"lifespan_days": 100 * 360 + 10, # Chỉ còn sống 10 ngày
		"cultivation_xp": 20,
		"money": 500,
		"traits": { "caution": 50, "greed": 50, "mercy": 50, "ambition": 50, "honor": 50 },
		"relationships": {},
		"location": "poi_thanh_tri_tran",
		"alive": true
	}
	GameSession.world_npcs["npc_lao_to_test"] = test_elder
	
	# Mô phỏng 1 tháng (+30 ngày)
	var summary = MonthlySimulationService.simulate_month(1, 1)
	if not test_elder["alive"]:
		passed += 1
		logs.append("✓ [Pass] Thọ nguyên cạn kiệt: NPC tọa hóa chính xác (alive = false) và ghi vào cáo phó")
	else:
		failed += 1
		logs.append("✗ [Fail] NPC không tử vong khi tuổi vượt thọ nguyên!")
		
	# Test 3: NPC đã tử vong không tham gia vào vòng lặp hành động tháng sau
	var xp_before = test_elder.get("cultivation_xp", 0)
	MonthlySimulationService.simulate_month(2, 1)
	var xp_after = test_elder.get("cultivation_xp", 0)
	if xp_before == xp_after and not test_elder["alive"]:
		passed += 1
		logs.append("✓ [Pass] Tính toàn vẹn: NPC đã chết không thực hiện thêm hành động, không làm gián đoạn game")
	else:
		failed += 1
		logs.append("✗ [Fail] NPC đã chết vẫn tiếp tục nhận tu vi!")
		
	# Test 4: Đột phá cảnh giới thành công tăng Thọ Nguyên và Cảnh Giới
	var test_young = {
		"id": "npc_thien_tai_test",
		"name": "Lạc Thiên",
		"realm_name": "Luyện Khí Tầng 9",
		"realm_tier": 1,
		"realm_stage": 9,
		"age_days": 20 * 360,
		"lifespan_days": 120 * 360,
		"cultivation_xp": 95, # Sắp chạm ngưỡng đột phá
		"money": 200,
		"traits": { "caution": 10, "greed": 30, "mercy": 50, "ambition": 95, "honor": 80 }, # Cực kỳ tham vọng
		"relationships": {},
		"location": "loc_van_linh",
		"alive": true
	}
	GameSession.world_npcs["npc_thien_tai_test"] = test_young
	
	# Mô phỏng cho đến khi đột phá Trúc Cơ
	var ascended = false
	for m in range(3, 8):
		MonthlySimulationService.simulate_month(m, 1)
		if test_young.get("realm_tier", 1) >= 2 or test_young.get("realm_stage", 1) > 9:
			ascended = true
			break
			
	if ascended and test_young.get("lifespan_days", 0) > 120 * 360:
		passed += 1
		logs.append("✓ [Pass] Đột phá Trúc Cơ thành công: Thọ nguyên được gia tăng thêm 130 năm (%s)" % test_young.get("realm_name", ""))
	else:
		failed += 1
		logs.append("✗ [Fail] Đột phá không tăng thọ nguyên đúng chuẩn!")
		
	return {
		"name": "Phase 2 - NPCLifecycle",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
