extends SceneTree

## Runner — Test Harness chạy tự động các Unit Tests của Đạo Tàn: Vạn Kiếp trong môi trường Headless

const TEST_GAME_CLOCK = preload("res://tests/unit/test_game_clock.gd")
const TEST_DETERMINISTIC_SEED = preload("res://tests/unit/test_deterministic_seed.gd")
const TEST_SAVE_ROUNDTRIP = preload("res://tests/unit/test_save_roundtrip.gd")

func _init() -> void:
	print("\n=======================================================")
	print("  ĐẠO TÀN: VẠN KIẾP — BỘ KIỂM THỬ TỰ ĐỘNG (PHASE 0)")
	print("  Môi trường: Godot 4.7.2 Headless Engine")
	print("=======================================================\n")
	
	var total_passed = 0
	var total_failed = 0
	
	var suites = [
		TEST_GAME_CLOCK.run_all_tests(),
		TEST_DETERMINISTIC_SEED.run_all_tests(),
		TEST_SAVE_ROUNDTRIP.run_all_tests()
	]
	
	for suite in suites:
		print("--- Bộ test: %s ---" % suite["name"])
		for l in suite["logs"]:
			print("  " + l)
		total_passed += suite["passed"]
		total_failed += suite["failed"]
		print("")
	
	print("-------------------------------------------------------")
	print("TỔNG KẾT: %d ĐẠT (PASS) | %d THẤT BẠI (FAIL)" % [total_passed, total_failed])
	print("=======================================================\n")
	
	if total_failed == 0:
		print("[SUCCESS] Tất cả các tiêu chí nghiệm thu Phase 0 đã vượt qua 100%!")
		quit(0)
	else:
		print("[FAILURE] Có bài kiểm thử thất bại!")
		quit(1)
