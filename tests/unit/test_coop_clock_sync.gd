extends RefCounted

## Unit test: Co-op Authoritative Clock Synchronization (Sprint S1)
## Tuân thủ chuẩn mực docs/10_COOP_SOCIAL_ECONOMY_DYNASTY.md:
##   - T-01: 720s thực / ngày (ở speed x1).
##   - T-02: 30s thực / giờ.
##   - T-03: Phân quyền máy chủ (Host-Authoritative).
##   - T-04: Đồng bộ snapshot thời gian giữa Server và Client.
##   - T-05: Khóa tính năng Time-skip ở Sprint S1.

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	GameClock.reset_clock()
	SessionAuthority.stop_session()
	
	# Test 1: T-01 & T-02 Kiểm tra tỷ lệ thời gian chuẩn (30s = 1h, 720s = 1 ngày)
	if GameClock.SECONDS_PER_DAY == 86400.0 and GameClock.REAL_SECONDS_PER_DAY == 720.0 and GameClock.TIME_RATIO == 120.0:
		passed += 1
		logs.append("✓ [Pass] [T-01/T-02] Tỷ lệ thời gian chuẩn xác: 720s thực = 24h game (1:120, 30s thực = 1h game)")
	else:
		failed += 1
		logs.append("✗ [Fail] Tỷ lệ thời gian không đúng: %f" % GameClock.TIME_RATIO)
		
	# Test 2: T-03 Quyền lực máy chủ (Host-Authoritative)
	if SessionAuthority.is_server_authoritative():
		passed += 1
		logs.append("✓ [Pass] [T-03] Chế độ Standalone mặc định có quyền Authoritative Server")
	else:
		failed += 1
		logs.append("✗ [Fail] Standalone không có quyền Authoritative!")
		
	# Giả lập chuyển sang Client
	SessionAuthority.current_role = SessionAuthority.NetworkRole.CLIENT
	if not SessionAuthority.is_server_authoritative():
		passed += 1
		logs.append("✓ [Pass] [T-03] Client bị tước quyền Authoritative (không được tự sửa giờ thế giới)")
	else:
		failed += 1
		logs.append("✗ [Fail] Client vẫn còn quyền Authoritative!")
		
	# Test 3: T-04 Đồng bộ Snapshot từ Host sang Client
	# Server gửi: Năm 2, Tháng 3, Ngày 15, Giờ 14:00 (50400.0s), scale 1.0
	ClockReplication.sync_clock_snapshot(2, 3, 15, 50400.0, 1.0)
	if GameClock.current_year == 2 and GameClock.current_month == 3 and GameClock.current_day == 15 and GameClock.current_hour == 14:
		passed += 1
		logs.append("✓ [Pass] [T-04] Client nhận snapshot Server và đồng bộ chính xác: Năm 2, Tháng 03, Ngày 15 — 14:00")
	else:
		failed += 1
		logs.append("✗ [Fail] Client không đồng bộ đúng snapshot: Năm %d, Tháng %d, Ngày %d, Giờ %d" % [
			GameClock.current_year, GameClock.current_month, GameClock.current_day, GameClock.current_hour
		])
		
	# Test 4: T-05 Kiểm soát trôi dạt (Soft Reconciliation khi lệch nhỏ)
	# Giả lập client lệch 120 giây in-game (chỉ 1 giây thực tế)
	GameClock.second_in_day = 50400.0
	ClockReplication.sync_clock_snapshot(2, 3, 15, 50520.0, 1.0)
	# Hiệu chỉnh mềm lerp(50400, 50520, 0.4) = 50448.0
	if abs(GameClock.second_in_day - 50448.0) < 1.0:
		passed += 1
		logs.append("✓ [Pass] [T-05] Hiệu chỉnh mềm (Soft Reconciliation) thành công, khử giật hình khi lệch mạng nhỏ")
	else:
		failed += 1
		logs.append("✗ [Fail] Hiệu chỉnh mềm không đúng: %f" % GameClock.second_in_day)
		
	# Test 5: T-06 Khóa tính năng Time-skip ở Sprint S1
	var skip_result = ClockReplication.request_time_skip(30)
	if not skip_result:
		passed += 1
		logs.append("✓ [Pass] [T-06] Tính năng Time-skip bị khóa nghiêm ngặt theo đúng đặc tả Sprint S1")
	else:
		failed += 1
		logs.append("✗ [Fail] Time-skip không bị khóa ở Sprint S1!")
		
	# Dọn dẹp trạng thái sau test
	SessionAuthority.stop_session()
	GameClock.reset_clock()
	
	return {
		"name": "Co-op Authoritative Clock Sync (S1)",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
