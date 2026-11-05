extends RefCounted

## Unit test: Phase 2 - Kiểm Thử Chịu Tải Headless 500 - 1,000 NPC (Stress Test Baseline)
## Tiêu chuẩn DoD: Mô phỏng nền không làm đơ game (Benchmark < 100ms mỗi tháng).

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	# Test 1: Kiểm thử áp lực 500 NPC qua 12 tháng liên tục
	var res_500 = MonthlySimulationService.run_headless_stress_test(500, 12)
	var avg_ms_500 = res_500["avg_ms_per_month"]
	var total_bt_500 = res_500["total_breakthroughs"]
	var total_d_500 = res_500["total_deaths"]
	
	if res_500["pass_benchmark"] and avg_ms_500 < 100.0:
		passed += 1
		logs.append("✓ [Pass] Stress test 500 NPC x 12 tháng: Trung bình %.2f ms/tháng (Mục tiêu < 100ms, Đột phá: %d, Tử vong: %d)" % [
			avg_ms_500, total_bt_500, total_d_500
		])
	else:
		failed += 1
		logs.append("✗ [Fail] Hiệu năng 500 NPC vượt ngưỡng cho phép: %.2f ms/tháng" % avg_ms_500)
		
	# Test 2: Thử thách cực đại 1,000 NPC qua 3 tháng
	var res_1000 = MonthlySimulationService.run_headless_stress_test(1000, 3)
	var avg_ms_1000 = res_1000["avg_ms_per_month"]
	
	if avg_ms_1000 < 150.0:
		passed += 1
		logs.append("✓ [Pass] Stress test cực đại 1,000 NPC x 3 tháng: Đạt %.2f ms/tháng (Vượt qua thử thách quy mô lớn)" % avg_ms_1000)
	else:
		failed += 1
		logs.append("✗ [Fail] Hiệu năng 1000 NPC quá chậm: %.2f ms/tháng" % avg_ms_1000)
		
	# Test 3: Ngân khố môn phái và chỉ số kinh tế không bị âm
	var factions_safe = true
	for fac in GameSession.world_factions.values():
		if fac.get("treasury", 0) < 0:
			factions_safe = false
			break
			
	if factions_safe:
		passed += 1
		logs.append("✓ [Pass] Toàn vẹn kinh tế: Ngân khố các môn phái luôn dương (No negative treasury)")
	else:
		failed += 1
		logs.append("✗ [Fail] Có môn phái bị âm ngân khố sau mô phỏng!")
		
	return {
		"name": "Phase 2 - HeadlessStressTest",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
