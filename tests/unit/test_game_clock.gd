class_name TestGameClock
extends RefCounted

## TestGameClock — Kiểm tra tính đúng đắn của chu kỳ thời gian (30 ngày/tháng, 12 tháng/năm)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	# Test 1: Khởi tạo mặc định
	GameClock.reset_clock()
	if GameClock.current_year == 1 and GameClock.current_month == 1 and GameClock.current_day == 1:
		passed += 1
		logs.append("✓ [Pass] Khởi tạo đồng hồ mặc định (Năm 1, Tháng 1, Ngày 1)")
	else:
		failed += 1
		logs.append("✗ [Fail] Khởi tạo đồng hồ sai giá trị")
	
	# Test 2: Tiến 15 ngày
	GameClock.advance_days(15)
	if GameClock.current_day == 16 and GameClock.current_month == 1 and GameClock.current_year == 1:
		passed += 1
		logs.append("✓ [Pass] Tiến 15 ngày hợp lệ -> Ngày 16")
	else:
		failed += 1
		logs.append("✗ [Fail] Tiến 15 ngày sai: Ngày %d, Tháng %d" % [GameClock.current_day, GameClock.current_month])
	
	# Test 3: Tiến tiếp 15 ngày -> Sang tháng 2 ngày 1
	GameClock.advance_days(15)
	if GameClock.current_day == 1 and GameClock.current_month == 2 and GameClock.current_year == 1:
		passed += 1
		logs.append("✓ [Pass] Tiến tiếp 15 ngày -> Chuyển đúng sang Tháng 2 Ngày 1")
	else:
		failed += 1
		logs.append("✗ [Fail] Chuyển tháng sai: Ngày %d, Tháng %d" % [GameClock.current_day, GameClock.current_month])
	
	# Test 4: Chuyển năm (tiến 330 ngày để đủ 1 năm)
	GameClock.advance_days(330)
	if GameClock.current_day == 1 and GameClock.current_month == 1 and GameClock.current_year == 2:
		passed += 1
		logs.append("✓ [Pass] Tiến 330 ngày -> Chuyển đúng sang Năm 2 Tháng 1 Ngày 1")
	else:
		failed += 1
		logs.append("✗ [Fail] Chuyển năm sai: Năm %d, Tháng %d, Ngày %d" % [GameClock.current_year, GameClock.current_month, GameClock.current_day])
	
	# Test 5: Serialization roundtrip
	var saved_dict = GameClock.to_dict()
	GameClock.reset_clock()
	GameClock.from_dict(saved_dict)
	if GameClock.current_year == 2 and GameClock.current_month == 1 and GameClock.current_day == 1:
		passed += 1
		logs.append("✓ [Pass] GameClock to_dict / from_dict khôi phục nguyên vẹn")
	else:
		failed += 1
		logs.append("✗ [Fail] GameClock serialization không khớp")
	
	GameClock.reset_clock()
	return { "name": "GameClock", "passed": passed, "failed": failed, "logs": logs }
