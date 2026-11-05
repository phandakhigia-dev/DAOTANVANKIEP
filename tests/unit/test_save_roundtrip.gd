class_name TestSaveRoundtrip
extends RefCounted

## TestSaveRoundtrip — Kiểm thử toàn diện hệ thống lưu/tải game an toàn (Atomic Save + Schema Validation)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	var test_slot = 99
	
	# 1. Khởi tạo một phiên chơi giả lập với các chỉ số riêng biệt
	var original_name = "Thẩm Thanh Thu"
	var original_seed = 889900
	GameSession.start_new_game(original_name, original_seed)
	GameSession.world_position = Vector2(1234.0, 5678.0)
	GameSession.current_hp = 85
	GameSession.max_hp = 120
	GameClock.advance_days(42) # Tháng 2, Ngày 13
	
	# 2. Lưu vào slot thử nghiệm
	var save_res = SaveService.save_game(test_slot)
	if save_res and SaveService.has_save(test_slot):
		passed += 1
		logs.append("✓ [Pass] Lưu thành công game vào slot 99 (Atomic Write)")
	else:
		failed += 1
		logs.append("✗ [Fail] Ghi file save vào slot 99 thất bại")
	
	# 3. Kiểm tra file metadata
	var meta = SaveService.get_slot_meta(test_slot)
	if meta.get("player_name") == original_name and meta.get("world_seed") == original_seed:
		passed += 1
		logs.append("✓ [Pass] Metadata slot 99 ghi nhận chính xác tên và seed")
	else:
		failed += 1
		logs.append("✗ [Fail] Metadata slot 99 bị sai lệch hoặc không đọc được")
	
	# 4. Thay đổi dữ liệu trong bộ nhớ để giả lập reset
	GameSession.player_name = "Kẻ Giả Mạo"
	GameSession.world_seed = 111111
	GameSession.world_position = Vector2.ZERO
	GameSession.current_hp = 1
	GameClock.reset_clock()
	
	# 5. Tải lại từ slot 99
	var load_res = SaveService.load_game(test_slot)
	if load_res:
		passed += 1
		logs.append("✓ [Pass] Gọi SaveService.load_game(99) thành công")
	else:
		failed += 1
		logs.append("✗ [Fail] Tải game từ slot 99 thất bại")
	
	# 6. Kiểm tra tính toàn vẹn của dữ liệu sau khi tải
	var name_ok = (GameSession.player_name == original_name)
	var seed_ok = (GameSession.world_seed == original_seed)
	var hp_ok = (GameSession.current_hp == 85 and GameSession.max_hp == 120)
	var pos_ok = (GameSession.world_position.distance_to(Vector2(1234.0, 5678.0)) < 1.0)
	var date_ok = (GameClock.current_month == 2 and GameClock.current_day == 13)
	
	if name_ok and seed_ok and hp_ok and pos_ok and date_ok:
		passed += 1
		logs.append("✓ [Pass] Dữ liệu roundtrip khớp 100%: Tên, Seed, HP, Vị trí (X, Y), Ngày/Tháng")
	else:
		failed += 1
		logs.append("✗ [Fail] Sai lệch dữ liệu sau roundtrip: Name=%s, Seed=%d, HP=%d, Date=%s" % [
			GameSession.player_name, GameSession.world_seed, GameSession.current_hp, GameClock.get_formatted_date()
		])
	
	# 7. Kiểm tra cơ chế Schema Validation từ chối dữ liệu hỏng
	var corrupt_data = { "invalid": true }
	if not SaveService.validate_save_data(corrupt_data):
		passed += 1
		logs.append("✓ [Pass] Bộ thẩm định Schema Validation từ chối payload không hợp lệ")
	else:
		failed += 1
		logs.append("✗ [Fail] Thẩm định dữ liệu không phát hiện ra file hỏng")
	
	# 8. Dọn dẹp các file thử nghiệm slot 99
	if FileAccess.file_exists(SaveService.get_save_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_save_path(test_slot))
	if FileAccess.file_exists(SaveService.get_meta_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_meta_path(test_slot))
	if FileAccess.file_exists(SaveService.get_backup_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_backup_path(test_slot))
	
	return { "name": "SaveRoundtrip", "passed": passed, "failed": failed, "logs": logs }
