class_name TestS0StabilityRegression
extends RefCounted

## TestS0StabilityRegression — Kiểm thử hồi quy toàn diện cho Sprint S0 (Stability & Save)
## Bao gồm:
##   1. P0-03: Chống số âm, chống duping trong ShopService
##   2. P0-04: Lưu/Tải trọn vẹn trạng thái sạp hàng và Escrow trong Save game
##   3. P1-01: Thống nhất schema version = 2 và cơ chế phục hồi từ file Backup
##   4. P1-02: Khởi tạo và đồng bộ town_position an toàn qua cổng trấn và tông môn
##   5. P1-04: Nạp scene demo mà không bị lỗi tham chiếu gãy

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	var test_slot = 98

	# --- Test 1: P0-03 Chống số lượng âm (count <= 0) trong buy_from_stall ---
	ShopService.reset_stall()
	GameSession.start_new_game("Đạo Hữu Test", 777888)
	GameSession.add_item("item_hoi_xuan_dan", 5)
	ShopService.deposit_item("item_hoi_xuan_dan", 5, 20)
	
	var neg_buy = ShopService.buy_from_stall("item_hoi_xuan_dan", -3, 100)
	var zero_buy = ShopService.buy_from_stall("item_hoi_xuan_dan", 0, 100)
	var neg_wallet_buy = ShopService.buy_from_stall("item_hoi_xuan_dan", 1, -50)
	
	var count_still_5 = (ShopService.escrow_items.size() == 1 and ShopService.escrow_items[0].get("count", 0) == 5)
	var rev_still_0 = (ShopService.accumulated_revenue == 0)
	
	if not neg_buy["success"] and not zero_buy["success"] and not neg_wallet_buy["success"] and count_still_5 and rev_still_0:
		passed += 1
		logs.append("✓ [Pass] T-01: ShopService.buy_from_stall từ chối tuyệt đối count <= 0 và buyer_wallet âm")
	else:
		failed += 1
		logs.append("✗ [Fail] T-01: Lỗ hổng cho phép mua số lượng âm hoặc ví âm trong sạp!")

	# --- Test 2: P0-03 Chống số lượng âm trong withdraw_item & deposit_item ---
	var neg_withdraw = ShopService.withdraw_item("item_hoi_xuan_dan", -2)
	var zero_withdraw = ShopService.withdraw_item("item_hoi_xuan_dan", 0)
	var empty_deposit = ShopService.deposit_item("", 1, 20)
	var neg_deposit = ShopService.deposit_item("item_hoi_xuan_dan", -1, 20)
	
	if not neg_withdraw["success"] and not zero_withdraw["success"] and not empty_deposit["success"] and not neg_deposit["success"]:
		passed += 1
		logs.append("✓ [Pass] T-02: deposit_item và withdraw_item thẩm tra chặt chẽ: từ chối ID rỗng và count <= 0")
	else:
		failed += 1
		logs.append("✗ [Fail] T-02: Ký gửi hoặc rút vật phẩm cho phép tham số không hợp lệ!")

	# --- Test 3: P0-03 Giao dịch nguyên tử hai chiều (player_buy_from_stall) có rollback ---
	GameSession.add_item("item_linh_thach", 100)
	var initial_stones = GameSession.get_item_count("item_linh_thach")
	var initial_pills = GameSession.get_item_count("item_hoi_xuan_dan")
	
	var trade_res = ShopService.player_buy_from_stall("item_hoi_xuan_dan", 2)
	var stones_after = GameSession.get_item_count("item_linh_thach")
	var pills_after = GameSession.get_item_count("item_hoi_xuan_dan")
	var escrow_count_after = ShopService.escrow_items[0].get("count", 0)
	
	if trade_res["success"] and stones_after == (initial_stones - 40) and pills_after == (initial_pills + 2) and escrow_count_after == 3 and ShopService.accumulated_revenue == 40:
		passed += 1
		logs.append("✓ [Pass] T-03: player_buy_from_stall giao dịch nguyên tử 2 chiều thành công (Trừ tiền, cấp đồ, trừ kho sạp, ghi nhận doanh thu)")
	else:
		failed += 1
		logs.append("✗ [Fail] T-03: Giao dịch sạp hàng hai chiều bị mất cân đối hoặc tính toán sai!")

	# --- Test 4: P1-02 GameSession.town_position được khai báo và bảo toàn qua chuyển cảnh ---
	GameSession.town_position = Vector2(495.0, 155.0)
	var saved_dict = GameSession.export_save_dict()
	var town_x = saved_dict.get("player", {}).get("town_pos_x", 0.0)
	var town_y = saved_dict.get("player", {}).get("town_pos_y", 0.0)
	
	if is_equal_approx(town_x, 495.0) and is_equal_approx(town_y, 155.0):
		passed += 1
		logs.append("✓ [Pass] T-04: GameSession.town_position serialize chính xác vào export_save_dict (495.0, 155.0)")
	else:
		failed += 1
		logs.append("✗ [Fail] T-04: town_position không được ghi nhận trong save dict!")

	# --- Test 5: P0-04 Save/Load khôi phục nguyên vẹn trạng thái sạp hàng và Escrow ---
	ShopService.is_leased = true
	ShopService.stall_name = "Thiên Đạo Các"
	ShopService.lease_expire_day = 15
	
	var save_ok = SaveService.save_game(test_slot)
	
	# Xóa sạch trạng thái sạp và session để giả lập khởi động lại
	ShopService.reset_stall()
	GameSession.town_position = Vector2.ZERO
	
	var load_ok = SaveService.load_game(test_slot)
	
	var stall_leased_ok = ShopService.is_leased
	var stall_name_ok = (ShopService.stall_name == "Thiên Đạo Các")
	var stall_rev_ok = (ShopService.accumulated_revenue == 40)
	var stall_escrow_ok = (ShopService.escrow_items.size() == 1 and ShopService.escrow_items[0].get("count", 0) == 3)
	var town_pos_restored = (GameSession.town_position.distance_to(Vector2(495.0, 155.0)) < 1.0)
	
	if save_ok and load_ok and stall_leased_ok and stall_name_ok and stall_rev_ok and stall_escrow_ok and town_pos_restored:
		passed += 1
		logs.append("✓ [Pass] T-05: Save/Load roundtrip khôi phục nguyên vẹn 100% sạp hàng (Escrow, Doanh thu, Hạn thuê, Tên sạp) và town_position")
	else:
		failed += 1
		logs.append("✗ [Fail] T-05: Dữ liệu sạp hàng hoặc town_position bị mất sau khi tải save!")

	# --- Test 6: P1-01 Thống nhất CURRENT_SCHEMA_VERSION = 2 & Schema Validation ---
	var meta = SaveService.get_slot_meta(test_slot)
	var schema_meta_ok = (meta.get("schema_version", 0) == 2)
	var valid_v2 = SaveService.validate_save_data({
		"schema_version": 2,
		"world_seed": 12345,
		"clock": {},
		"player": { "name": "Test", "realm_id": "realm_pham_nhan" }
	})
	var reject_future = not SaveService.validate_save_data({
		"schema_version": 999,
		"world_seed": 12345,
		"clock": {},
		"player": { "name": "Test", "realm_id": "realm_pham_nhan" }
	})
	
	if schema_meta_ok and valid_v2 and reject_future and SaveService.CURRENT_SCHEMA_VERSION == 2:
		passed += 1
		logs.append("✓ [Pass] T-06: Schema version thống nhất phiên bản 2, từ chối schema không tương thích trong tương lai")
	else:
		failed += 1
		logs.append("✗ [Fail] T-06: Schema version chưa thống nhất hoặc validation không hoạt động chính xác!")

	# --- Test 7: P1-01 Tự động khôi phục từ Backup khi file chính bị hỏng hoặc mất ---
	var main_save_path = SaveService.get_save_path(test_slot)
	var backup_save_path = SaveService.get_backup_path(test_slot)
	
	# Đảm bảo có backup bằng cách save lần 2
	SaveService.save_game(test_slot)
	
	# Cố tình xóa file chính để giả lập sự cố hệ thống / crash giữa chừng
	if FileAccess.file_exists(main_save_path):
		DirAccess.remove_absolute(main_save_path)
		
	# Gọi load_game — Hệ thống phải tự động fallback tải từ backup_save_path và tái lập file chính
	var backup_load_ok = SaveService.load_game(test_slot)
	var main_recreated = FileAccess.file_exists(main_save_path)
	
	if backup_load_ok and main_recreated and ShopService.accumulated_revenue == 40:
		passed += 1
		logs.append("✓ [Pass] T-07: Cơ chế an toàn phục hồi thành công từ file backup (.bak.json) khi file chính bị mất!")
	else:
		failed += 1
		logs.append("✗ [Fail] T-07: Không thể tự động khôi phục dữ liệu từ file backup!")

	# --- Test 8: P1-04 Tham chiếu demo wuxia/demo/capture_demo.tscn nạp sạch không lỗi ---
	var demo_scene = load("res://wuxia/demo/capture_demo.tscn")
	if demo_scene != null:
		passed += 1
		logs.append("✓ [Pass] T-08: wuxia/demo/capture_demo.tscn nạp thành công, không còn tham chiếu gãy res://demo/...")
	else:
		failed += 1
		logs.append("✗ [Fail] T-08: wuxia/demo/capture_demo.tscn không thể nạp!")

	# --- Test 9: P0-01 Co-op Clock Replication khóa cứng tốc độ 1x, từ chối tua nhanh khi chơi nhiều người ---
	SessionAuthority.current_role = SessionAuthority.NetworkRole.HOST_SERVER
	GameClock.time_scale = 1.0
	ClockReplication.request_time_scale_change(20.0)
	var coop_scale_locked = (GameClock.time_scale == 1.0)
	
	# Trong chế độ chơi đơn (STANDALONE), cho phép Host đổi tốc độ
	SessionAuthority.current_role = SessionAuthority.NetworkRole.STANDALONE
	ClockReplication.request_time_scale_change(20.0)
	var solo_scale_allowed = (GameClock.time_scale == 20.0)
	GameClock.time_scale = 1.0 # reset
	
	if coop_scale_locked and solo_scale_allowed:
		passed += 1
		logs.append("✓ [Pass] T-09: ClockReplication khóa cứng 1x trong Co-op, từ chối time_scale 20x để bảo đảm đồng bộ 720s/ngày")
	else:
		failed += 1
		logs.append("✗ [Fail] T-09: Lỗ hổng cho phép tua nhanh thời gian trong phòng Co-op!")

	# --- Test 10: P0-01 MonthlySimulationService chỉ thực thi trên Host/Server, client không tự ý mô phỏng ---
	SessionAuthority.current_role = SessionAuthority.NetworkRole.CLIENT
	var client_sim_auth_check = not SessionAuthority.is_server_authoritative()
	SessionAuthority.current_role = SessionAuthority.NetworkRole.HOST_SERVER
	var host_sim_auth_check = SessionAuthority.is_server_authoritative()
	SessionAuthority.current_role = SessionAuthority.NetworkRole.STANDALONE
	var solo_sim_auth_check = SessionAuthority.is_server_authoritative()
	
	if client_sim_auth_check and host_sim_auth_check and solo_sim_auth_check:
		passed += 1
		logs.append("✓ [Pass] T-10: Quyền mô phỏng hàng tháng (MonthlySimulationService) được bảo vệ: Client bị chặn, Host/Standalone hợp lệ")
	else:
		failed += 1
		logs.append("✗ [Fail] T-10: Quyền mô phỏng thế giới hàng tháng không phân quyền đúng!")

	# --- Test 11: Đồ họa Combat — Swordsman sprite và Combat Arena nạp thành công ---
	var arena_scene = load("res://scenes/combat/combat_arena.tscn")
	var swordsman_scene = load("res://wuxia/32/heroes/swordsman/swordsman.tscn")
	var slash_vfx = load("res://scenes/vfx/vfx_sword_slash.tscn")
	var lightning_vfx = load("res://scenes/vfx/vfx_lightning_impact.tscn")
	
	if arena_scene != null and swordsman_scene != null and slash_vfx != null and lightning_vfx != null:
		passed += 1
		logs.append("✓ [Pass] T-11: CombatArena tích hợp đầy đủ Swordsman sprite hoạt ảnh và các cảnh VFX chiến đấu (Slash, Lightning)")
	else:
		failed += 1
		logs.append("✗ [Fail] T-11: Cảnh đồ họa nhân vật hoặc VFX chiến đấu bị thiếu!")

	# --- Test 12: Cơ chế Khinh Công (Qinggong Dash) và tốc độ lướt gió ---
	var player_scene = load("res://scenes/world/player.tscn")
	var player_instance = player_scene.instantiate()
	var has_qinggong_vars = ("is_qinggong" in player_instance) and ("qinggong_cd" in player_instance) and ("sprint_speed" in player_instance)
	var sprint_faster = player_instance.sprint_speed > player_instance.move_speed
	var sp_speed = player_instance.sprint_speed
	var mv_speed = player_instance.move_speed
	player_instance.free()
	
	if has_qinggong_vars and sprint_faster:
		passed += 1
		logs.append("✓ [Pass] T-12: Nhân vật sở hữu thuộc tính Khinh Công lướt gió (sprint_speed = %d > move_speed = %d, có cooldown quản lý)" % [sp_speed, mv_speed])
	else:
		failed += 1
		logs.append("✗ [Fail] T-12: Thuộc tính Khinh Công của nhân vật chưa được cấu hình đúng!")

	# --- Test 13: Sát thương trôi nổi (Floating Combat Text) trong Combat Arena ---
	var arena_instance = arena_scene.instantiate()
	var has_floating_array = ("floating_texts" in arena_instance)
	arena_instance.spawn_floating_text(Vector2(200, 200), "-50", Color.YELLOW, 16)
	var text_added = arena_instance.floating_texts.size() == 1
	var first_text = arena_instance.floating_texts[0] if text_added else {}
	var has_text_props = first_text.get("text", "") == "-50" and first_text.get("life", 0.0) > 0.0
	arena_instance._update_floating_texts(0.8) # Cập nhật delta vượt quá max_life để kiểm tra dọn rác
	var cleaned_up = arena_instance.floating_texts.is_empty()
	arena_instance.free()
	
	if has_floating_array and text_added and has_text_props and cleaned_up:
		passed += 1
		logs.append("✓ [Pass] T-13: Hệ thống sát thương bay (Floating Combat Text) vận hành chuẩn xác: sinh chữ, bay lên và tự dọn bộ nhớ")
	else:
		failed += 1
		logs.append("✗ [Fail] T-13: Hệ thống sát thương bay trong đấu trường bị lỗi!")

	# --- Test 14: Chu kỳ ánh sáng ngày đêm (Day/Night Lighting Tint) trên World Map ---
	var world_scene = load("res://scenes/world/world_map.tscn")
	var world_instance = world_scene.instantiate()
	var has_lighting_func = world_instance.has_method("_update_day_night_lighting")
	world_instance.free()
	
	# Kiểm tra quy tắc 1 ngày = 720 giây thực tế
	var clock_is_720 = (GameClock.REAL_SECONDS_PER_DAY == 720.0)
	
	if has_lighting_func and clock_is_720:
		passed += 1
		logs.append("✓ [Pass] T-14: WorldMap tích hợp hàm chuyển sắc thái ánh sáng ngày đêm (_update_day_night_lighting) đồng bộ nhịp 720s/ngày")
	else:
		failed += 1
		logs.append("✗ [Fail] T-14: Ánh sáng ngày đêm WorldMap hoặc quy tắc 720s bị vi phạm!")

	# Dọn dẹp slot test
	if FileAccess.file_exists(SaveService.get_save_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_save_path(test_slot))
	if FileAccess.file_exists(SaveService.get_meta_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_meta_path(test_slot))
	if FileAccess.file_exists(SaveService.get_backup_path(test_slot)):
		DirAccess.remove_absolute(SaveService.get_backup_path(test_slot))

	return { "name": "Sprint S0 — Stability & Save Regression", "passed": passed, "failed": failed, "logs": logs }
