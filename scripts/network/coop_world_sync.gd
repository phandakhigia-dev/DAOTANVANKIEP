extends Node

## CoopWorldSync — Hệ thống Đồng Bộ Thực Thể Mạng & Gameplay Co-op (Host-Authoritative V3)
## Quản lý toàn diện:
##   1. Đồng bộ Avatar người chơi (Vị trí, hướng nhìn, hoạt ảnh di chuyển/khinh công).
##   2. Thẩm quyền sát thương & Boss (Host xác thực damage, cooldown, range, HP boss, phát loot).
##   3. Kinh tế sạp hàng phi tập trung Host-Authoritative (Chống duping, chống ví giả, chống race condition).
##   4. Đồng bộ sự kiện thế giới & mô phỏng NPC hàng tháng (Snapshot replication + diff).
##   5. Quản lý trạng thái kết nối, ngắt kết nối (Disconnect), tái kết nối (Reconnect) và Save/Load Host.

const POSITION_TICK_RATE: float = 0.05 # 20 Hz
var _tick_timer: float = 0.0

# Dữ liệu người chơi trên mạng (Host quản lý toàn quyền)
# peer_id: int -> { "peer_id": int, "pos": Vector2, "facing": Vector2, "anim": String, "hp": int, "max_hp": int, "name": String }
var network_players: Dictionary = {}

# S0: Kho ví & Túi đồ Thẩm Quyền Máy Chủ (Host-Authoritative Peer Inventories)
# peer_id: int -> { "wallet": int, "items": Dictionary (item_id -> count), "revision": int, "guid": String }
var host_peer_inventories: Dictionary = {}

# S0: Revision thẩm quyền hiện tại của Client cục bộ (Reconciliation version tracking)
var client_authoritative_revision: int = 0

# Trạng thái Boss chiến đấu (Host-Authoritative)
var coop_boss_state: Dictionary = {
	"id": "boss_xich_kiem_ma_thu",
	"hp": 400,
	"max_hp": 400,
	"pos": Vector2(640, 360),
	"is_alive": true,
	"telegraph": null
}

# Cache Idempotency cho các giao dịch sạp hàng: "%d:%s" % [peer_id, request_id] -> Dictionary
var processed_transactions: Dictionary = {}

# Lịch sử đòn đánh để kiểm tra cooldown / rate-limit trên Host: peer_id: int -> last_attack_time: int (ms)
var _peer_last_attack_time: Dictionary = {}

# Snapshot mô phỏng thế giới mới nhất nhận được từ Host (Dành cho Client)
var latest_world_snapshot: Dictionary = {}
var latest_sim_revision: int = 0

# Tín hiệu thông báo cho UI và các Scene
signal remote_player_updated(peer_id: int, data: Dictionary)
signal remote_player_removed(peer_id: int)
signal coop_boss_hp_changed(current_hp: int, max_hp: int, dmg: int, is_crit: bool)
signal coop_boss_defeated(boss_id: String)
signal coop_loot_received(item_id: String, count: int, exp: int)
signal stall_transaction_completed(request_id: String, success: bool, msg: String)
signal world_simulation_synced(snapshot: Dictionary)

func _ready() -> void:
	if SessionAuthority:
		SessionAuthority.peer_joined.connect(_on_peer_joined)
		SessionAuthority.peer_left.connect(_on_peer_left)
		SessionAuthority.connection_state_changed.connect(_on_role_changed)
	
	_reset_local_state()

func _reset_local_state() -> void:
	network_players.clear()
	host_peer_inventories.clear()
	processed_transactions.clear()
	_peer_last_attack_time.clear()
	client_authoritative_revision = 0
	latest_sim_revision = 0
	coop_boss_state = {
		"id": "boss_xich_kiem_ma_thu",
		"hp": 400,
		"max_hp": 400,
		"pos": Vector2(640, 360),
		"is_alive": true,
		"telegraph": null
	}

# Safe RPC wrappers — Ngăn ngừa triệt để lỗi "Trying to call an RPC while no multiplayer peer is active"
func _can_rpc() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _safe_rpc(method_name: String, args: Array = []) -> void:
	if not _can_rpc():
		return
	match args.size():
		0: rpc(method_name)
		1: rpc(method_name, args[0])
		2: rpc(method_name, args[0], args[1])
		3: rpc(method_name, args[0], args[1], args[2])
		4: rpc(method_name, args[0], args[1], args[2], args[3])
		5: rpc(method_name, args[0], args[1], args[2], args[3], args[4])
		6: rpc(method_name, args[0], args[1], args[2], args[3], args[4], args[5])
		_: push_warning("Quá nhiều tham số cho _safe_rpc")

func _safe_rpc_id(peer_id: int, method_name: String, args: Array = []) -> void:
	if not _can_rpc():
		return
	match args.size():
		0: rpc_id(peer_id, method_name)
		1: rpc_id(peer_id, method_name, args[0])
		2: rpc_id(peer_id, method_name, args[0], args[1])
		3: rpc_id(peer_id, method_name, args[0], args[1], args[2])
		4: rpc_id(peer_id, method_name, args[0], args[1], args[2], args[3])
		5: rpc_id(peer_id, method_name, args[0], args[1], args[2], args[3], args[4])
		6: rpc_id(peer_id, method_name, args[0], args[1], args[2], args[3], args[4], args[5])
		_: push_warning("Quá nhiều tham số cho _safe_rpc_id")

func _process(delta: float) -> void:
	if not SessionAuthority or not SessionAuthority.is_coop_session():
		return
		
	_tick_timer += delta
	if _tick_timer >= POSITION_TICK_RATE:
		_tick_timer = 0.0
		_broadcast_or_send_motion()

func _on_role_changed(role: SessionAuthority.NetworkRole) -> void:
	_reset_local_state()
	if role == SessionAuthority.NetworkRole.HOST_SERVER:
		# Đăng ký Host (peer_id = 1) vào danh sách người chơi
		network_players[1] = {
			"peer_id": 1,
			"pos": Vector2(500, 500),
			"facing": Vector2.DOWN,
			"anim": "idle_south",
			"hp": GameSession.current_hp if GameSession else 100,
			"max_hp": GameSession.max_hp if GameSession else 100,
			"name": GameSession.player_name if GameSession else "Chủ Phòng"
		}
		# Khởi tạo túi đồ thẩm quyền của Host
		_init_host_peer_inventory(1, {
			"wallet": GameSession.get_item_count("item_linh_thach") if GameSession else 500,
			"items": _extract_session_items(),
			"guid": GameSession.player_name if GameSession else "host_1"
		})

func _extract_session_items() -> Dictionary:
	var res: Dictionary = {}
	if GameSession:
		for it in GameSession.inventory:
			var i_id = it.get("item_id", it.get("id", ""))
			if i_id != "" and i_id != "item_linh_thach":
				res[i_id] = it.get("quantity", it.get("count", 0))
	return res

func _init_host_peer_inventory(peer_id: int, initial_data: Dictionary) -> void:
	host_peer_inventories[peer_id] = {
		"wallet": initial_data.get("wallet", 500),
		"items": initial_data.get("items", {}).duplicate(true),
		"revision": initial_data.get("revision", 1),
		"guid": initial_data.get("guid", "peer_%d" % peer_id)
	}

func _on_peer_joined(peer_id: int, player_info: Dictionary) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
		
	# Khởi tạo vị trí và avatar mặc định cho Client mới
	network_players[peer_id] = {
		"peer_id": peer_id,
		"pos": Vector2(600.0 + (network_players.size() * 20.0), 420.0),
		"facing": Vector2.DOWN,
		"anim": "idle_south",
		"hp": 100,
		"max_hp": 100,
		"name": player_info.get("name", "Đạo Hữu #%d" % peer_id)
	}
	
	# Khởi tạo hoặc khôi phục túi đồ thẩm quyền cho peer này
	if not peer_id in host_peer_inventories:
		_init_host_peer_inventory(peer_id, {
			"wallet": player_info.get("initial_wallet", 500),
			"items": player_info.get("initial_items", {}),
			"guid": player_info.get("name", "client_%d" % peer_id)
		})
	
	# Gửi toàn bộ trạng thái thế giới hiện tại (Full World Snapshot) cho Client mới vừa kết nối
	var full_snapshot = {
		"players": network_players,
		"boss": coop_boss_state,
		"shop": ShopService.to_dict() if ShopService else {},
		"clock": GameClock.to_dict() if GameClock else {},
		"world_npcs": GameSession.world_npcs if GameSession else {},
		"sim_revision": latest_sim_revision
	}
	_safe_rpc_id(peer_id, "sync_full_world_state", [full_snapshot])
	
	# Đồng bộ túi đồ thẩm quyền ban đầu cho Client
	var p_inv = host_peer_inventories[peer_id]
	_safe_rpc_id(peer_id, "sync_authoritative_inventory", [
		"init_join",
		true,
		"Đồng bộ tài sản ban đầu từ Host",
		p_inv["revision"],
		p_inv["wallet"],
		p_inv["items"]
	])
	
	print("[CoopWorldSync] Đã gửi Full World Snapshot & Authoritative Inventory cho Peer %d." % peer_id)

func _on_peer_left(peer_id: int) -> void:
	network_players.erase(peer_id)
	_peer_last_attack_time.erase(peer_id)
	remote_player_removed.emit(peer_id)
	if SessionAuthority.is_server_authoritative():
		_safe_rpc("sync_player_disconnected", [peer_id])
	print("[CoopWorldSync] Đã dọn dẹp dữ liệu người chơi ngắt kết nối: %d (Giữ nguyên authoritative ledger)" % peer_id)

# ==============================================================================
# 1. ĐỒNG BỘ VỊ TRÍ & AVATAR NGƯỜI CHƠI (PLAYER REPLICATION)
# ==============================================================================

func _broadcast_or_send_motion() -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
		
	if SessionAuthority.current_role == SessionAuthority.NetworkRole.CLIENT:
		# Client gửi intent di chuyển của nhân vật cục bộ lên Host
		var local_player = _find_local_player()
		if not local_player or not is_instance_valid(local_player):
			return
			
		var local_pos = local_player.global_position
		var local_facing = local_player.facing_dir if "facing_dir" in local_player else Vector2.DOWN
		var local_anim = "idle_south"
		if "is_qinggong" in local_player and local_player.is_qinggong:
			local_anim = "qinggong"
		elif "velocity" in local_player and local_player.velocity.length() > 5.0:
			local_anim = "walk_south"
				
		_safe_rpc_id(1, "client_submit_motion", [local_pos, local_facing, local_anim])
		
	elif SessionAuthority.current_role == SessionAuthority.NetworkRole.HOST_SERVER:
		# Host cập nhật nhân vật local của Host
		var local_player = _find_local_player()
		if local_player and is_instance_valid(local_player):
			if 1 in network_players:
				network_players[1]["pos"] = local_player.global_position
				network_players[1]["facing"] = local_player.facing_dir if "facing_dir" in local_player else Vector2.DOWN
				network_players[1]["anim"] = "qinggong" if ("is_qinggong" in local_player and local_player.is_qinggong) else ("walk_south" if local_player.velocity.length() > 5.0 else "idle_south")
		
		# Phát sóng snapshot vị trí của mọi người chơi tới tất cả client
		_safe_rpc("sync_all_players_snapshot", [network_players])

func _find_local_player() -> Node2D:
	var tree = get_tree()
	if not tree or not tree.get_root():
		return null
	var current_scene = tree.current_scene
	if current_scene and current_scene.has_node("Player"):
		return current_scene.get_node("Player") as Node2D
	return tree.get_root().find_child("Player", true, false) as Node2D

@rpc("any_peer", "call_remote", "unreliable")
func client_submit_motion(pos: Vector2, facing: Vector2, anim: String) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
		
	if sender_id in network_players:
		var p_data = network_players[sender_id]
		# Kiểm tra chống hack tốc độ (Speed Hack / Teleport Clamp)
		var old_pos: Vector2 = p_data.get("pos", pos)
		var max_dist = 1200.0 * POSITION_TICK_RATE # Tốc độ tối đa 1200 px/s
		if old_pos.distance_to(pos) > 120.0 and old_pos != Vector2.ZERO:
			# Dịch chuyển quá xa trong 1 tick -> Kéo về vị trí hợp lệ
			p_data["pos"] = old_pos.move_toward(pos, max_dist)
		else:
			p_data["pos"] = pos
			
		p_data["facing"] = facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
		p_data["anim"] = anim
		remote_player_updated.emit(sender_id, p_data)

@rpc("authority", "call_remote", "unreliable")
func sync_all_players_snapshot(snapshot: Dictionary) -> void:
	if SessionAuthority.current_role == SessionAuthority.NetworkRole.HOST_SERVER:
		return # Host đã có dữ liệu gốc
		
	var my_id = multiplayer.get_unique_id()
	for p_id in snapshot.keys():
		var peer_int = int(p_id)
		var p_info = snapshot[p_id]
		network_players[peer_int] = p_info
		if peer_int != my_id:
			remote_player_updated.emit(peer_int, p_info)

@rpc("authority", "call_remote", "reliable")
func sync_player_disconnected(peer_id: int) -> void:
	network_players.erase(peer_id)
	remote_player_removed.emit(peer_id)

@rpc("authority", "call_remote", "reliable")
func sync_full_world_state(snapshot: Dictionary) -> void:
	network_players = snapshot.get("players", {})
	coop_boss_state = snapshot.get("boss", {})
	if "shop" in snapshot and ShopService:
		ShopService.from_dict(snapshot["shop"])
	if "clock" in snapshot and GameClock:
		GameClock.from_dict(snapshot["clock"])
	if "world_npcs" in snapshot and GameSession:
		GameSession.world_npcs = snapshot["world_npcs"]
	if "sim_revision" in snapshot:
		latest_sim_revision = snapshot["sim_revision"]
	print("[CoopWorldSync] Đã tiếp nhận và áp dụng Full World State (kèm NPCs & Revision) từ Host.")

# ==============================================================================
# 2. THẨM QUYỀN CHIẾN ĐẤU & SÁT THƯƠNG BOSS (HOST-AUTHORITATIVE COMBAT)
# ==============================================================================

## Client gửi ý định tấn công lên Server (Intent-Only)
func request_attack_boss(skill_id: String, aim_dir: Vector2) -> void:
	if SessionAuthority.is_server_authoritative():
		# Host tự xử lý trực tiếp
		_server_execute_attack(1, skill_id, aim_dir)
	else:
		_safe_rpc_id(1, "server_receive_attack_intent", [skill_id, aim_dir])

@rpc("any_peer", "call_remote", "reliable")
func server_receive_attack_intent(skill_id: String, aim_dir: Vector2) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	_server_execute_attack(sender_id, skill_id, aim_dir)

func _server_execute_attack(sender_id: int, skill_id: String, _aim_dir: Vector2) -> void:
	if not coop_boss_state.get("is_alive", false):
		return
		
	# P1-01: Kiểm tra Rate-limit / Cooldown đòn đánh theo peer_id
	var now_ms = Time.get_ticks_msec()
	var last_time = _peer_last_attack_time.get(sender_id, 0)
	var min_interval_ms = 180 # Tối thiểu 180ms giữa 2 đòn đánh
	if skill_id == "skill_1":
		min_interval_ms = 1500
	elif skill_id == "skill_2":
		min_interval_ms = 2500
		
	if (now_ms - last_time) < min_interval_ms and last_time != 0:
		print("[CoopCombat] Từ chối đòn đánh từ Peer %d (Cooldown vi phạm / Spam rate-limit)" % sender_id)
		return
	_peer_last_attack_time[sender_id] = now_ms

	# Tính toán sát thương thẩm quyền trên máy chủ
	var base_dmg = 20
	var crit_chance = 0.2
	match skill_id:
		"basic":
			base_dmg = 18
			crit_chance = 0.2
		"skill_1":
			base_dmg = 45
			crit_chance = 0.25
		"skill_2":
			base_dmg = 70
			crit_chance = 0.3
		_:
			base_dmg = 25
			
	var is_crit = (RNGService.randf() <= crit_chance) if RNGService else false
	var final_dmg = int(base_dmg * (1.6 if is_crit else 1.0))
	
	coop_boss_state["hp"] = max(0, coop_boss_state["hp"] - final_dmg)
	var boss_died = (coop_boss_state["hp"] <= 0)
	if boss_died:
		coop_boss_state["is_alive"] = false
		
	# Phát sóng kết quả sát thương cho tất cả Client và cập nhật Host cục bộ
	_safe_rpc("sync_boss_damage_result", [final_dmg, is_crit, coop_boss_state["hp"], coop_boss_state["max_hp"]])
	coop_boss_hp_changed.emit(coop_boss_state["hp"], coop_boss_state["max_hp"], final_dmg, is_crit)
	
	if boss_died:
		_safe_rpc("sync_boss_defeated_result", [coop_boss_state["id"]])
		coop_boss_defeated.emit(coop_boss_state["id"])
		if GameSession and not coop_boss_state["id"] in GameSession.defeated_bosses:
			GameSession.defeated_bosses.append(coop_boss_state["id"])
			
		# Trao thưởng đồng đều cho cả Host lẫn Client
		for p_id in network_players.keys():
			if p_id == 1:
				sync_award_loot("item_co_kiem_tan_phien", 1, 150)
			else:
				_safe_rpc_id(p_id, "sync_award_loot", ["item_co_kiem_tan_phien", 1, 150])
			
	print("[CoopCombat] Host xác nhận đòn đánh từ Peer %d: -%d HP (Crit: %s). Còn lại: %d/%d" % [
		sender_id, final_dmg, str(is_crit), coop_boss_state["hp"], coop_boss_state["max_hp"]
	])

@rpc("authority", "call_remote", "reliable")
func sync_boss_damage_result(dmg: int, is_crit: bool, remaining_hp: int, max_hp: int) -> void:
	coop_boss_state["hp"] = remaining_hp
	coop_boss_state["max_hp"] = max_hp
	if remaining_hp <= 0:
		coop_boss_state["is_alive"] = false
	coop_boss_hp_changed.emit(remaining_hp, max_hp, dmg, is_crit)

@rpc("authority", "call_remote", "reliable")
func sync_boss_defeated_result(boss_id: String) -> void:
	coop_boss_state["is_alive"] = false
	coop_boss_state["hp"] = 0
	coop_boss_defeated.emit(boss_id)
	if GameSession and not boss_id in GameSession.defeated_bosses:
		GameSession.defeated_bosses.append(boss_id)

@rpc("authority", "call_remote", "reliable")
func sync_award_loot(item_id: String, count: int, exp: int) -> void:
	if GameSession:
		GameSession.add_item(item_id, count)
		GameSession.add_cultivation(exp)
	coop_loot_received.emit(item_id, count, exp)
	if EventBus:
		EventBus.notification_requested.emit("★ Chiến lợi phẩm trảm ma: +%dx %s, +%d Tu Vi!" % [count, item_id, exp], "success")

# ==============================================================================
# 3. KINH TẾ SẠP HÀNG CO-OP HOST-AUTHORITATIVE & CHỐNG DUPING V3 (P0 FIXED)
# ==============================================================================

## Client gửi yêu cầu mua hàng từ sạp. KHÔNG gửi số dư tự khai (P0-02 FIXED)
func request_buy_from_stall(request_id: String, item_id: String, count: int) -> void:
	if SessionAuthority.is_server_authoritative():
		var res = _server_process_stall_trade(1, request_id, item_id, count)
		stall_transaction_completed.emit(request_id, res["success"], res.get("message", ""))
	else:
		_safe_rpc_id(1, "server_receive_stall_trade_request", [request_id, item_id, count])

@rpc("any_peer", "call_remote", "reliable")
func server_receive_stall_trade_request(request_id: String, item_id: String, count: int) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	var res = _server_process_stall_trade(sender_id, request_id, item_id, count)
	
	# Trả lời phản hồi authoritative cho người mua
	if res.get("success", false):
		_safe_rpc_id(sender_id, "sync_stall_trade_response", [
			request_id,
			true,
			res.get("message", "Thành công"),
			res.get("revision", 1),
			res.get("wallet", 0),
			res.get("items", {})
		])
	else:
		_safe_rpc_id(sender_id, "sync_stall_trade_response", [
			request_id,
			false,
			res.get("message", "Thất bại"),
			res.get("revision", 0),
			0,
			{}
		])

func _server_process_stall_trade(sender_id: int, request_id: String, item_id: String, count: int) -> Dictionary:
	var tx_key = "%d:%s" % [sender_id, request_id]
	
	# 1. Idempotency theo (peer_id, request_id): Trả về cached result, tuyệt đối không trừ tiền/cấp đồ lại
	if tx_key in processed_transactions:
		print("[CoopEconomy] Bỏ qua request_id trùng lặp: %s (Peer %d)" % [request_id, sender_id])
		return processed_transactions[tx_key]
		
	# 2. Thẩm tra tham số đầu vào (Boundary checks)
	if count <= 0 or count > 9999 or item_id == "":
		var err_res = {
			"success": false,
			"message": "Tham số giao dịch không hợp lệ (Số lượng <= 0, tràn hoặc item trống)!",
			"revision": host_peer_inventories.get(sender_id, {}).get("revision", 0)
		}
		processed_transactions[tx_key] = err_res
		return err_res
		
	# 3. Đảm bảo peer đã được Host đăng ký authoritative state
	if not sender_id in host_peer_inventories:
		if sender_id == 1 and GameSession:
			_init_host_peer_inventory(1, {
				"wallet": GameSession.get_item_count("item_linh_thach"),
				"items": _extract_session_items(),
				"guid": GameSession.player_name
			})
		else:
			var err_res = { "success": false, "message": "Peer chưa đăng ký thẩm quyền với Host!" }
			processed_transactions[tx_key] = err_res
			return err_res
			
	var peer_state: Dictionary = host_peer_inventories[sender_id]
		
	# 4. Kiểm tra tồn kho Escrow trong ShopService
	if not ShopService or not ShopService.is_leased:
		var err_res = {
			"success": false,
			"message": "Sạp hàng hiện không mở cửa hoặc chưa thuê!",
			"revision": peer_state["revision"]
		}
		processed_transactions[tx_key] = err_res
		return err_res
		
	var target_entry: Dictionary = {}
	for it in ShopService.escrow_items:
		if it.get("item_id", "") == item_id:
			target_entry = it
			break
			
	if target_entry.is_empty() or target_entry.get("count", 0) < count:
		var err_res = {
			"success": false,
			"message": "Hàng trong sạp đã hết hoặc không đủ số lượng!",
			"revision": peer_state["revision"]
		}
		processed_transactions[tx_key] = err_res
		return err_res
		
	# 5. Kiểm tra giá cả & Kiểm tra số dư LINH THẠCH AUTHORITATIVE CỦA HOST (P0-02 FIXED)
	var unit_price = target_entry.get("price", 0)
	if unit_price <= 0 or unit_price > 100000000:
		var err_res = {
			"success": false,
			"message": "Giá vật phẩm bất thường!",
			"revision": peer_state["revision"]
		}
		processed_transactions[tx_key] = err_res
		return err_res
		
	var total_cost = unit_price * count
	var author_wallet = peer_state.get("wallet", 0)
	if author_wallet < total_cost:
		var err_res = {
			"success": false,
			"message": "Số dư Linh Thạch không đủ (Host Authoritative Check thất bại)!",
			"revision": peer_state["revision"]
		}
		processed_transactions[tx_key] = err_res
		return err_res
		
	# 6. Cam kết giao dịch nguyên tử trên Host (Atomic Commit)
	# 6a. Trừ tồn kho sạp
	target_entry["count"] -= count
	if target_entry["count"] <= 0:
		ShopService.escrow_items.erase(target_entry)
		
	# 6b. Trừ tiền và cấp hàng trên Authoritative State
	peer_state["wallet"] -= total_cost
	var current_p_items: Dictionary = peer_state["items"]
	current_p_items[item_id] = current_p_items.get(item_id, 0) + count
	peer_state["revision"] += 1
	
	# 6c. Tăng doanh thu sạp
	ShopService.accumulated_revenue += total_cost
	ShopService.total_sales_count += count
	
	# 6d. Nếu người mua là Host cục bộ (peer_id = 1), đồng bộ GameSession
	if sender_id == 1 and GameSession:
		GameSession.remove_item("item_linh_thach", total_cost)
		GameSession.add_item(item_id, count)
		
	var success_res = {
		"success": true,
		"message": "Giao dịch thành công!",
		"item_id": item_id,
		"count": count,
		"total_cost": total_cost,
		"revision": peer_state["revision"],
		"wallet": peer_state["wallet"],
		"items": peer_state["items"].duplicate(true)
	}
	processed_transactions[tx_key] = success_res
	
	# Phát sóng kho hàng sạp mới nhất cho toàn bộ người chơi trong phòng
	_safe_rpc("sync_stall_inventory_to_all", [ShopService.escrow_items, ShopService.accumulated_revenue])
	
	print("[CoopEconomy] Host cam kết thành công cho Peer %d: -%d LT, +%dx %s (Rev: %d, Req: %s)" % [
		sender_id, total_cost, count, item_id, peer_state["revision"], request_id
	])
	return success_res

@rpc("authority", "call_remote", "reliable")
func sync_stall_trade_response(request_id: String, success: bool, msg: String, revision: int, auth_wallet: int, auth_items: Dictionary) -> void:
	if not success:
		if EventBus:
			EventBus.notification_requested.emit("Giao dịch thất bại: %s" % msg, "warning")
		stall_transaction_completed.emit(request_id, false, msg)
		return
		
	# P0-01 FIXED: Bỏ qua phản hồi trùng lặp hoặc đến chậm (Out-of-order / Replay Protection)
	if revision <= client_authoritative_revision:
		print("[CoopEconomy] Bỏ qua phản hồi trùng lặp/cũ (Rev %d <= Local %d). Không cấp item lặp!" % [
			revision, client_authoritative_revision
		])
		stall_transaction_completed.emit(request_id, true, msg)
		return
		
	# Cập nhật revision thẩm quyền mới nhất
	client_authoritative_revision = revision
	
	# Áp dụng Authoritative Snapshot Reconcile (Tuyệt đối không gọi add_item thủ công từng lần!)
	_reconcile_client_state(auth_wallet, auth_items)
	
	if EventBus:
		EventBus.notification_requested.emit("Giao dịch thành công! Số dư: %d LT" % auth_wallet, "success")
	stall_transaction_completed.emit(request_id, true, msg)

func _reconcile_client_state(auth_wallet: int, auth_items: Dictionary) -> void:
	if not GameSession:
		return
		
	# 1. Cập nhật số dư linh thạch
	var current_lt = GameSession.get_item_count("item_linh_thach")
	var diff_lt = auth_wallet - current_lt
	if diff_lt > 0:
		GameSession.add_item("item_linh_thach", diff_lt)
	elif diff_lt < 0:
		GameSession.remove_item("item_linh_thach", -diff_lt)
		
	# 2. Reconcile các vật phẩm trong túi
	for item_id in auth_items.keys():
		var target_count = auth_items[item_id]
		var cur_count = GameSession.get_item_count(item_id)
		if cur_count < target_count:
			GameSession.add_item(item_id, target_count - cur_count)
		elif cur_count > target_count:
			GameSession.remove_item(item_id, cur_count - target_count)
			
	if EventBus:
		EventBus.inventory_changed.emit("all", 0)

@rpc("authority", "call_remote", "reliable")
func sync_authoritative_inventory(request_id: String, success: bool, msg: String, revision: int, auth_wallet: int, auth_items: Dictionary) -> void:
	sync_stall_trade_response(request_id, success, msg, revision, auth_wallet, auth_items)

@rpc("authority", "call_remote", "reliable")
func sync_stall_inventory_to_all(items: Array, revenue: int) -> void:
	if ShopService:
		ShopService.escrow_items = items
		ShopService.accumulated_revenue = revenue
	print("[CoopEconomy] Client đã đồng bộ kho sạp hàng mới nhất từ Server.")

# ==============================================================================
# 4. MÔ PHỎNG NPC HÀNG THÁNG & SNAPSHOT THẾ GIỚI DIFF (P1-02 FIXED)
# ==============================================================================

## Host phát sóng kết quả mô phỏng tháng cho tất cả Client kèm revision và NPC state
func host_broadcast_month_simulation(month: int, year: int, snapshot_data: Dictionary) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
	latest_sim_revision += 1
	var payload = {
		"revision": latest_sim_revision,
		"month": month,
		"year": year,
		"summary": snapshot_data.get("summary", snapshot_data),
		"world_npcs": snapshot_data.get("world_npcs", GameSession.world_npcs if GameSession else {}),
		"memory_events": snapshot_data.get("memory_events", GameSession.memory_events if GameSession else [])
	}
	_safe_rpc("client_receive_month_simulation", [month, year, payload])

@rpc("authority", "call_remote", "reliable")
func client_receive_month_simulation(month: int, year: int, payload: Dictionary) -> void:
	var rev = payload.get("revision", 0)
	if rev <= latest_sim_revision and latest_sim_revision != 0:
		print("[CoopWorldSync] Bỏ qua snapshot mô phỏng cũ (Rev %d <= Local %d)" % [rev, latest_sim_revision])
		return
	latest_sim_revision = rev
	latest_world_snapshot = payload.get("summary", {})
	
	# P1-02 FIXED: Cập nhật đầy đủ GameSession.world_npcs và GameSession.memory_events
	if GameSession:
		if payload.has("world_npcs") and payload["world_npcs"] is Dictionary:
			GameSession.world_npcs = payload["world_npcs"]
		if payload.has("memory_events") and payload["memory_events"] is Array:
			GameSession.memory_events = payload["memory_events"]
			
	world_simulation_synced.emit(latest_world_snapshot)
	print("[CoopWorldSync] Client tiếp nhận snapshot mô phỏng thế giới Tháng %d Năm %d từ Host (Rev %d, %d NPCs)." % [
		month, year, rev, GameSession.world_npcs.size() if GameSession else 0
	])

# ==============================================================================
# 5. LƯU & KHÔI PHỤC CO-OP STATE CHO SAVE/LOAD (P2 FIXED)
# ==============================================================================

func export_coop_state() -> Dictionary:
	return {
		"host_peer_inventories": host_peer_inventories.duplicate(true),
		"processed_transactions": processed_transactions.duplicate(true),
		"coop_boss_state": coop_boss_state.duplicate(true),
		"latest_sim_revision": latest_sim_revision
	}

func import_coop_state(data: Dictionary) -> void:
	if data.has("host_peer_inventories") and data["host_peer_inventories"] is Dictionary:
		host_peer_inventories = data["host_peer_inventories"].duplicate(true)
	if data.has("processed_transactions") and data["processed_transactions"] is Dictionary:
		processed_transactions = data["processed_transactions"].duplicate(true)
	if data.has("coop_boss_state") and data["coop_boss_state"] is Dictionary:
		coop_boss_state = data["coop_boss_state"].duplicate(true)
	if data.has("latest_sim_revision"):
		latest_sim_revision = data["latest_sim_revision"]
	print("[CoopWorldSync] Đã khôi phục hoàn chỉnh Co-op state từ Save (%d peer ledgers, %d transactions)." % [
		host_peer_inventories.size(), processed_transactions.size()
	])
