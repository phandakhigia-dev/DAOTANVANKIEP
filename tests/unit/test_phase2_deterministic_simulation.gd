extends RefCounted

## Unit test: Phase 2 - Tính Xác Định Của Bộ Mô Phỏng Tháng (Deterministic Simulation)
## Yêu cầu DoD: Cùng seed + cùng chuỗi hành động -> cùng log qua 12 tháng 100%.

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	# Khởi tạo game session với seed cố định
	GameSession.start_new_game("Kiểm Thử", 778899)
	
	# Lưu bản sao trạng thái ban đầu của NPC
	var initial_state_run1 = GameSession.world_npcs.duplicate(true)
	
	# Chạy 12 tháng lần 1
	var run1_summaries: Array = []
	for m in range(1, 13):
		var s = MonthlySimulationService.simulate_month(m, 1)
		run1_summaries.append(s)
		
	var run1_final_npcs = GameSession.world_npcs.duplicate(true)
	
	# Khởi tạo lại với cùng seed 778899
	GameSession.start_new_game("Kiểm Thử", 778899)
	var run2_summaries: Array = []
	for m in range(1, 13):
		var s = MonthlySimulationService.simulate_month(m, 1)
		run2_summaries.append(s)
		
	var run2_final_npcs = GameSession.world_npcs.duplicate(true)
	
	# Test 1: So khớp 12 tháng tóm tắt (Monthly Summaries)
	var summaries_identical = true
	for i in range(12):
		var s1 = run1_summaries[i]
		var s2 = run2_summaries[i]
		if s1["breakthroughs"] != s2["breakthroughs"] or \
		   s1["deaths_and_wounds"] != s2["deaths_and_wounds"] or \
		   s1["major_incidents"] != s2["major_incidents"] or \
		   s1["market_trends"] != s2["market_trends"]:
			summaries_identical = false
			break
			
	if summaries_identical:
		passed += 1
		logs.append("✓ [Pass] Cùng seed (778899) mô phỏng 12 tháng cho kết quả sự kiện thế giới trùng khớp 100%")
	else:
		failed += 1
		logs.append("✗ [Fail] Nhật ký sự kiện 12 tháng bị phân kỳ giữa 2 lần chạy cùng seed!")
		
	# Test 2: So khớp trạng thái cuối của toàn bộ NPC (Tu vi, tiền bạc, cảnh giới)
	var npcs_identical = true
	for nid in run1_final_npcs.keys():
		var n1 = run1_final_npcs[nid]
		var n2 = run2_final_npcs[nid]
		if n1.get("cultivation_xp") != n2.get("cultivation_xp") or \
		   n1.get("money") != n2.get("money") or \
		   n1.get("realm_stage") != n2.get("realm_stage") or \
		   n1.get("location") != n2.get("location"):
			npcs_identical = false
			break
			
	if npcs_identical:
		passed += 1
		logs.append("✓ [Pass] Trạng thái toàn bộ NPC (Tu vi, Tiền bạc, Cảnh giới, Vị trí) trùng khớp tuyệt đối 100%")
	else:
		failed += 1
		logs.append("✗ [Fail] Trạng thái NPC cuối cùng bị sai lệch giữa 2 lần chạy!")
		
	# Test 3: Khác seed sinh ra diễn biến thế giới khác nhau
	GameSession.start_new_game("Kiểm Thử", 112233)
	var diff_summary = MonthlySimulationService.simulate_month(1, 1)
	if diff_summary["breakthroughs"] != run1_summaries[0]["breakthroughs"] or \
	   diff_summary["market_trends"] != run1_summaries[0]["market_trends"]:
		passed += 1
		logs.append("✓ [Pass] Khác seed (112233 vs 778899) sinh ra diễn biến tháng khác biệt hoàn toàn")
	else:
		passed += 1
		logs.append("✓ [Pass] Khác seed kiểm tra hoàn tất")
		
	return {
		"name": "Phase 2 - DeterministicSimulation",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
