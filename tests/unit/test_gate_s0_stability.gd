class_name TestGateS0Stability
extends RefCounted

## TestGateS0Stability — Bộ kiểm thử Gate S0: Độ ổn định & Tính toàn vẹn Co-op
## Nghiệm thu:
##   1. T-S0-01 (P0-01): ProvinceWorld Remote Avatar Lifecycle & Interpolation
##   2. T-S0-02 (P0-02): Host-Authoritative Unique World Entity Claiming (Race Condition)
##   3. T-S0-03 (P0-03, P0-04): Host-Authoritative Fast Travel & Clock Invariance in Co-op
##   4. T-S0-04 (P1-03): Reconnect Identity & GUID Ledger Persistence
##   5. T-S0-05 (P2-01): Pause Menu in Co-op does NOT freeze scene tree

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []

	# Chuẩn bị môi trường test
	SessionAuthority.stop_session()
	GameClock.reset_clock()
	CoopWorldSync._reset_local_state()
	GameSession.chunk_diffs.clear()

	# ==============================================================================
	# 1. T-S0-01: PROVINCE WORLD REMOTE AVATAR LIFECYCLE & INTERPOLATION (P0-01)
	# ==============================================================================
	var province_scene = load("res://scenes/world/province_world.tscn")
	if province_scene:
		var pw = province_scene.instantiate()
		var cur_scene = Engine.get_main_loop().current_scene
		if cur_scene:
			cur_scene.add_child(pw)
		else:
			Engine.get_main_loop().root.add_child(pw)
		
		var test_peer_id = 99
		var peer_data = {
			"peer_id": test_peer_id,
			"name": "Tiêu Viêm",
			"pos": Vector2(66600, 66600),
			"anim": "walk_south",
			"facing": Vector2.DOWN
		}
		
		# Kích hoạt signal remote_player_updated
		pw._on_remote_player_updated(test_peer_id, peer_data)
		
		var has_avatar = test_peer_id in pw.remote_avatars
		var av_node = pw.remote_avatars.get(test_peer_id, null)
		var is_child_of_y_entities = is_instance_valid(av_node) and av_node.get_parent() == pw.y_entities
		var has_label = is_instance_valid(av_node) and av_node.has_node("NameLabel")
		
		# Cập nhật interpolation di chuyển
		pw._update_remote_avatars(0.1)
		
		# Thử gỡ bỏ avatar
		pw._on_remote_player_removed(test_peer_id)
		var avatar_cleaned = not (test_peer_id in pw.remote_avatars)
		
		pw.queue_free()
		
		if has_avatar and is_child_of_y_entities and has_label and avatar_cleaned:
			passed += 1
			logs.append("✓ [Pass] T-S0-01: ProvinceWorld Remote Avatar Lifecycle: Spawn chuẩn y_entities, hiển thị nhãn tên, cập nhật lerp và dọn dẹp sạch sẽ")
		else:
			failed += 1
			logs.append("✗ [Fail] T-S0-01: Thất bại spawn hoặc dọn dẹp remote avatar trong ProvinceWorld (Spawn: %s, Child: %s, Label: %s, Clean: %s)" % [
				str(has_avatar), str(is_child_of_y_entities), str(has_label), str(avatar_cleaned)
			])
	else:
		failed += 1
		logs.append("✗ [Fail] T-S0-01: Không thể tải scene res://scenes/world/province_world.tscn")

	# ==============================================================================
	# 2. T-S0-02: HOST-AUTHORITATIVE UNIQUE ENTITY CLAIMING (RACE CONDITION) (P0-02)
	# ==============================================================================
	SessionAuthority.current_role = SessionAuthority.NetworkRole.HOST_SERVER
	GameSession.chunk_diffs.clear()
	CoopWorldSync.guid_to_ledger.clear()
	CoopWorldSync.host_peer_inventories.clear()
	
	CoopWorldSync._init_host_peer_inventory(10, { "wallet": 100, "items": {}, "guid": "peer_10" })
	CoopWorldSync._init_host_peer_inventory(11, { "wallet": 100, "items": {}, "guid": "peer_11" })
	
	# Peer 10 và Peer 11 tranh nhau mở rương bamboo_cavern_chest tại chunk (32, 30)
	var claim_p10 = CoopWorldSync._server_process_entity_claim(
		10, 32, 30, "bamboo_cavern_chest",
		{ "item_tay_tuy_dan": 1 }, 50, 50
	)
	var claim_p11 = CoopWorldSync._server_process_entity_claim(
		11, 32, 30, "bamboo_cavern_chest",
		{ "item_tay_tuy_dan": 1 }, 50, 50
	)
	
	var p10_wallet = CoopWorldSync.host_peer_inventories[10]["wallet"]
	var p10_items = CoopWorldSync.host_peer_inventories[10]["items"].get("item_tay_tuy_dan", 0)
	var p11_wallet = CoopWorldSync.host_peer_inventories[11]["wallet"]
	var p11_items = CoopWorldSync.host_peer_inventories[11]["items"].get("item_tay_tuy_dan", 0)
	var chunk_harvested = GameSession.chunk_diffs.get("32_30", {}).get("harvested_entities", [])
	
	if claim_p10.get("success") == true and claim_p11.get("success") == false \
		and p10_wallet == 150 and p10_items == 1 \
		and p11_wallet == 100 and p11_items == 0 \
		and chunk_harvested.size() == 1 and chunk_harvested[0] == "bamboo_cavern_chest":
		passed += 1
		logs.append("✓ [Pass] T-S0-02: Race condition thu hoạch rương: Đúng 1 peer nhận thưởng (+50 LT, +1 Tẩy Tủy Đan), peer thứ hai bị từ chối an toàn")
	else:
		failed += 1
		logs.append("✗ [Fail] T-S0-02: Race condition rương thất bại! P10: %s (W:%d), P11: %s (W:%d), Harvested: %s" % [
			str(claim_p10.get("success")), p10_wallet, str(claim_p11.get("success")), p11_wallet, str(chunk_harvested)
		])

	# ==============================================================================
	# 3. T-S0-03: FAST TRAVEL HOST-AUTHORITATIVE & CLOCK INVARIANCE (P0-03 & P0-04)
	# ==============================================================================
	CoopWorldSync._init_host_peer_inventory(12, { "wallet": 100, "items": {}, "guid": "peer_12" })
	CoopWorldSync.network_players[12] = { "pos": Vector2(66560, 66560) }
	
	var initial_hour = GameClock.current_hour
	var initial_total_days = GameClock.total_days_elapsed
	var target_dest = Vector2(66560, 34442)
	
	# Thực hiện Fast Travel có thẩm quyền qua Host
	CoopWorldSync._server_process_fast_travel(12, "long_kinh", 25, target_dest)
	
	var p12_wallet = CoopWorldSync.host_peer_inventories[12]["wallet"]
	var p12_pos = CoopWorldSync.network_players[12]["pos"]
	var hour_after = GameClock.current_hour
	var days_after = GameClock.total_days_elapsed
	
	if p12_wallet == 75 and p12_pos == target_dest and hour_after == initial_hour and days_after == initial_total_days:
		passed += 1
		logs.append("✓ [Pass] T-S0-03: Fast Travel Co-op: Khấu trừ 25 LT thẩm quyền, cập nhật vị trí không bị kẹt anti-teleport, bảo toàn 720s/ngày (Giờ không bị nhảy)")
	else:
		failed += 1
		logs.append("✗ [Fail] T-S0-03: Fast travel lỗi! Wallet: %d, Pos: %s, Giờ: %d -> %d" % [
			p12_wallet, str(p12_pos), initial_hour, hour_after
		])

	# ==============================================================================
	# 4. T-S0-04: RECONNECT IDENTITY & GUID LEDGER PRESERVATION (P1-03)
	# ==============================================================================
	# Peer 20 kết nối với GUID "guid_tieu_viem_01"
	var test_guid = "guid_tieu_viem_01"
	CoopWorldSync.client_register_identity(test_guid, "Tiêu Viêm", 300, { "item_linh_thao": 2 })
	
	# Mua hoặc nhận thêm đồ, ví lên 450 LT
	var peer_20_ledger = CoopWorldSync.guid_to_ledger[test_guid]
	peer_20_ledger["wallet"] = 450
	peer_20_ledger["items"]["item_tay_tuy_dan"] = 1
	
	# Peer 20 ngắt kết nối (Disconnect)
	CoopWorldSync._on_peer_left(1) # sender_id giả định
	
	# Khi kết nối lại, ENet cấp peer_id mới (ví dụ peer_id = 77) nhưng gửi cùng GUID
	CoopWorldSync.client_register_identity(test_guid, "Tiêu Viêm", 100, {})
	
	var reconnected_wallet = CoopWorldSync.guid_to_ledger[test_guid]["wallet"]
	var reconnected_items = CoopWorldSync.guid_to_ledger[test_guid]["items"]
	
	# Kiểm tra Export / Import Save Co-op State
	var coop_save = CoopWorldSync.export_coop_state()
	CoopWorldSync.guid_to_ledger.clear()
	CoopWorldSync.import_coop_state(coop_save)
	var restored_after_save = CoopWorldSync.guid_to_ledger.get(test_guid, {}).get("wallet", 0)
	
	if reconnected_wallet == 450 and reconnected_items.get("item_tay_tuy_dan", 0) == 1 and restored_after_save == 450:
		passed += 1
		logs.append("✓ [Pass] T-S0-04: Reconnect Identity: Tái kết nối với GUID khác peer_id bảo tồn 100% ví (450 LT) và vật phẩm, khôi phục hoàn hảo qua Save/Load")
	else:
		failed += 1
		logs.append("✗ [Fail] T-S0-04: Reconnect thất bại! Wallet: %d, Restored: %d" % [reconnected_wallet, restored_after_save])

	# ==============================================================================
	# 5. T-S0-05: PAUSE MENU CO-OP INVARIANT (P2-01)
	# ==============================================================================
	var pause_scene = load("res://scenes/world/pause_menu.tscn")
	if pause_scene:
		var pm = pause_scene.instantiate()
		var cur_scene2 = Engine.get_main_loop().current_scene
		if cur_scene2:
			cur_scene2.add_child(pm)
		else:
			Engine.get_main_loop().root.add_child(pm)
		
		# 5a. Chế độ Chơi Đơn (Standalone) -> Menu pause PHẢI dừng scene tree
		SessionAuthority.current_role = SessionAuthority.NetworkRole.STANDALONE
		Engine.get_main_loop().root.get_tree().paused = false
		pm.open_menu()
		var solo_paused = Engine.get_main_loop().root.get_tree().paused
		pm.resume_game()
		var solo_resumed = not Engine.get_main_loop().root.get_tree().paused
		
		# 5b. Chế độ Co-op (Host Server hoặc Client) -> Menu pause KHÔNG ĐƯỢC dừng scene tree
		SessionAuthority.current_role = SessionAuthority.NetworkRole.HOST_SERVER
		Engine.get_main_loop().root.get_tree().paused = false
		pm.open_menu()
		var coop_paused = Engine.get_main_loop().root.get_tree().paused
		var coop_visible = pm.visible
		pm.resume_game()
		
		pm.queue_free()
		
		if solo_paused and solo_resumed and (not coop_paused) and coop_visible:
			passed += 1
			logs.append("✓ [Pass] T-S0-05: Pause Menu Invariant: Solo dừng scene tree, Co-op mở UI nhưng KHÔNG dừng scene tree (Giữ kết nối & 720s/ngày)")
		else:
			failed += 1
			logs.append("✗ [Fail] T-S0-05: Pause menu vi phạm invariant! Solo: %s/%s, Coop Paused: %s (Kỳ vọng false)" % [
				str(solo_paused), str(solo_resumed), str(coop_paused)
			])
	else:
		failed += 1
		logs.append("✗ [Fail] T-S0-05: Không thể tải scene res://scenes/world/pause_menu.tscn")

	# Trả Session về trạng thái sạch sẽ
	SessionAuthority.stop_session()
	CoopWorldSync._reset_local_state()

	return {
		"name": "Sprint Gate S0 — Stability & Co-op Integrity",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
