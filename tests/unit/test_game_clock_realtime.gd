extends RefCounted

## Unit test: GameClock chế độ đếm tự động thời gian thực (12 phút/ngày - Co-op Ready)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	GameClock.reset_clock()
	
	# Test 1: Khởi điểm 6:00 sáng (Giờ Mão, Ban Ngày)
	if GameClock.current_hour == 6 and GameClock.current_minute == 0 and not GameClock.is_night() and "Mão" in GameClock.get_canh_gio_name():
		passed += 1
		logs.append("✓ [Pass] Khởi đầu ngày lúc 06:00 sáng (Giờ Mão • Ban Ngày)")
	else:
		failed += 1
		logs.append("✗ [Fail] Sai mốc khởi điểm: %s" % GameClock.get_formatted_time())
	
	# Test 2: Tỷ lệ thời gian: 30s thực = 1 giờ in-game (3600s in-game)
	GameClock.advance_realtime_seconds(30.0)
	if GameClock.current_hour == 7 and GameClock.current_minute == 0 and "Thìn" in GameClock.get_canh_gio_name():
		passed += 1
		logs.append("✓ [Pass] Tiến đúng 30 giây thực tế -> Đạt chính xác 07:00 (Giờ Thìn)")
	else:
		failed += 1
		logs.append("✗ [Fail] 30s thực không đạt 07:00: %s" % GameClock.get_formatted_time())
		
	# Test 3: Tiến đến ban đêm (19:00 - Giờ Tuất)
	# Từ 7:00 đến 19:00 là 12 tiếng in-game = 12 * 30s thực = 360s thực
	GameClock.advance_realtime_seconds(360.0)
	if GameClock.current_hour == 19 and GameClock.is_night() and "Tuất" in GameClock.get_canh_gio_name():
		passed += 1
		logs.append("✓ [Pass] Tiến 360 giây thực -> 19:00 (Giờ Tuất • Ban Đêm âm khí thịnh)")
	else:
		failed += 1
		logs.append("✗ [Fail] Sai trạng thái ban đêm: %s" % GameClock.get_formatted_time())
		
	# Test 4: Tròn 1 ngày (12 phút thực = 720 giây thực) chuyển sang Ngày 2
	# Hiện tại là 19:00 (đã đi 390s thực). Còn thiếu 330s thực để tròn ngày.
	GameClock.advance_realtime_seconds(330.0)
	if GameClock.current_day == 2 and GameClock.current_hour == 6:
		passed += 1
		logs.append("✓ [Pass] Đủ 720 giây thực (12 phút) -> Chuyển sang Ngày 2 lúc 06:00 sáng")
	else:
		failed += 1
		logs.append("✗ [Fail] Không chuyển đúng ngày sau 720s thực: Ngày %d, Giờ %d" % [GameClock.current_day, GameClock.current_hour])
		
	# Test 5: Gia tốc thời gian (time_scale = 20.0 khi bế quan)
	GameClock.set_time_scale(20.0)
	# Ở scale 20.0, 1.5 giây thực = 30 giây thực ở scale 1.0 = 1 giờ in-game!
	GameClock.advance_realtime_seconds(1.5 * GameClock.time_scale)
	if GameClock.current_hour == 7:
		passed += 1
		logs.append("✓ [Pass] Tĩnh tọa gia tốc x20: 1.5 giây thực tế lướt qua đúng 1 giờ in-game")
	else:
		failed += 1
		logs.append("✗ [Fail] Gia tốc time_scale sai lệch: Giờ %d" % GameClock.current_hour)
	GameClock.set_time_scale(1.0)
	
	# Test 6: Roundtrip to_dict / from_dict khôi phục thời khắc chi tiết
	var saved_dict = GameClock.to_dict()
	GameClock.reset_clock()
	GameClock.from_dict(saved_dict)
	if GameClock.current_day == 2 and GameClock.current_hour == 7:
		passed += 1
		logs.append("✓ [Pass] Lưu/Tải khôi phục chính xác thời khắc trong ngày (Ngày 2, 07:00)")
	else:
		failed += 1
		logs.append("✗ [Fail] Khôi phục thời khắc thất bại: Ngày %d, Giờ %d" % [GameClock.current_day, GameClock.current_hour])
		
	GameClock.reset_clock()
	
	return {
		"name": "GameClock Realtime Co-op",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
