extends RefCounted

## Test suite: Luồng Nhiệm Vụ & Giao Nhận Thưởng (Phase 1)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array = []
	
	GameSession.start_new_game("Kiếm Tu Tập Sự", 999111)
	
	# Test 1: Kiểm tra trạng thái ban đầu của nhiệm vụ
	var initial_state = GameSession.get_quest_state("q_first_spirit_vein")
	if initial_state.get("status", "") == "not_started":
		logs.append("✓ [Pass] Nhiệm vụ ban đầu ở trạng thái chưa kích hoạt (not_started)")
		passed += 1
	else:
		logs.append("✗ [Fail] Trạng thái nhiệm vụ khởi tạo sai")
		failed += 1
		
	# Test 2: Nhận nhiệm vụ từ Mạc Tư Viễn
	var start_ok = GameSession.start_quest("q_first_spirit_vein")
	var active_state = GameSession.get_quest_state("q_first_spirit_vein")
	if start_ok and active_state.get("status", "") == "active" and active_state.get("current_step", 0) == 1:
		logs.append("✓ [Pass] Kích hoạt nhiệm vụ thành công: Chuyển sang active và bước 1 (Tiến về Vân Lĩnh)")
		passed += 1
	else:
		logs.append("✗ [Fail] Nhận nhiệm vụ thất bại")
		failed += 1
		
	# Test 3: Tiến trình nhiệm vụ qua các bước
	GameSession.advance_quest("q_first_spirit_vein", 2)
	GameSession.advance_quest("q_first_spirit_vein", 3)
	var step3_state = GameSession.get_quest_state("q_first_spirit_vein")
	if step3_state.get("current_step", 0) == 3:
		logs.append("✓ [Pass] Tiến trình nhiệm vụ ghi nhận chính xác đến bước 3 (Đã hạ Ma Thứu)")
		passed += 1
	else:
		logs.append("✗ [Fail] Cập nhật tiến độ nhiệm vụ thất bại")
		failed += 1
		
	# Test 4: Hoàn thành nhiệm vụ và nhận thưởng
	var old_stones = GameSession.get_item_count("item_linh_thach")
	var old_dan = GameSession.get_item_count("item_tu_khi_dan")
	var old_aff = GameSession.get_npc_affinity("npc_mac_tu_vien")
	
	var complete_ok = GameSession.complete_quest("q_first_spirit_vein")
	var end_state = GameSession.get_quest_state("q_first_spirit_vein")
	
	var stones_added = GameSession.get_item_count("item_linh_thach") - old_stones
	var dan_added = GameSession.get_item_count("item_tu_khi_dan") - old_dan
	var aff_added = GameSession.get_npc_affinity("npc_mac_tu_vien") - old_aff
	
	if complete_ok and end_state.get("status", "") == "completed" and stones_added == 100 and dan_added == 2 and aff_added == 25:
		logs.append("✓ [Pass] Báo cáo nhiệm vụ thành công: Nhận đúng 100 Linh Thạch, 2x Tụ Khí Đan, Hảo cảm Mạc Tư Viễn +25")
		passed += 1
	else:
		logs.append("✗ [Fail] Phần thưởng nhiệm vụ không khớp kỳ vọng (Stones=%d, Dan=%d, Aff=%d)" % [
			stones_added, dan_added, aff_added
		])
		failed += 1
		
	# Test 5: Không thể hoàn thành lặp lại để farm thưởng
	var double_complete = GameSession.complete_quest("q_first_spirit_vein")
	if not double_complete:
		logs.append("✓ [Pass] Chống trục lợi: Từ chối hoàn thành trùng lặp nhiệm vụ đã hoàn tất")
		passed += 1
	else:
		logs.append("✗ [Fail] Cho phép hoàn thành 2 lần cùng một nhiệm vụ")
		failed += 1
		
	return {
		"name": "Phase 1 - QuestFlow",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
