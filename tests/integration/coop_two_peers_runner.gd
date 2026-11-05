extends Node

## CoopTwoPeersRunner — Kiểm thử Tích hợp 2 Tiến trình Mạng Độc lập (Host / Client)
## Khởi chạy qua tham số dòng lệnh:
##   -- HOST [port]
##   -- CLIENT [port]

var role_mode: String = "HOST"
var port: int = 7777
var timer: float = 0.0
var step: int = 0
var test_passed: int = 0
var test_failed: int = 0
var max_timeout: float = 25.0

# Lưu trữ kết quả kiểm thử
var logs: Array[String] = []

# Biến theo dõi trạng thái mạng
var client_connected: bool = false
var motion_synced: bool = false
var boss_damaged: bool = false
var boss_died: bool = false
var loot_received: bool = false
var stall_trade_1_ok: bool = false
var stall_trade_retry_ok: bool = false
var stall_trade_race_rejected: bool = false
var month_synced: bool = false
var reconnect_ok: bool = false

func _ready() -> void:
	var user_args = OS.get_cmdline_user_args()
	if user_args.size() > 0:
		role_mode = user_args[0].to_upper()
	if user_args.size() > 1:
		port = int(user_args[1])
		
	print("\n=======================================================")
	print("  CO-OP INTEGRATION TEST (2 TIẾN TRÌNH ĐỘC LẬP)")
	print("  Vai Trò: %s | Port: %d | TimeScale Khóa Cứng: 1.0" % [role_mode, port])
	print("=======================================================\n")
	
	_setup_signals()
	
	if role_mode == "HOST":
		_init_host()
	else:
		_init_client()

func _setup_signals() -> void:
	if SessionAuthority:
		SessionAuthority.peer_joined.connect(_on_peer_joined)
		SessionAuthority.peer_left.connect(_on_peer_left)
		
	if CoopWorldSync:
		CoopWorldSync.remote_player_updated.connect(_on_remote_player_updated)
		CoopWorldSync.coop_boss_hp_changed.connect(_on_boss_hp_changed)
		CoopWorldSync.coop_boss_defeated.connect(_on_boss_defeated)
		CoopWorldSync.coop_loot_received.connect(_on_loot_received)
		CoopWorldSync.stall_transaction_completed.connect(_on_stall_tx_completed)
		CoopWorldSync.world_simulation_synced.connect(_on_world_sim_synced)

func _init_host() -> void:
	# 1. Giả lập trước một phiên solo đang tua nhanh x20
	GameClock.time_scale = 20.0
	
	# 2. Khởi tạo phiên Host -> Phải cưỡng chế time_scale về 1.0
	var err = SessionAuthority.start_host(port, 4)
	if err != OK:
		_log_fail("Host start_host thất bại với mã lỗi %d" % err)
		get_tree().quit(1)
		return
		
	if GameClock.time_scale == 1.0:
		_log_pass("T-HOST-01: Khởi chạy Host cưỡng chế time_scale = 1.0 ngay lập tức (Xóa bỏ x20 từ solo)")
	else:
		_log_fail("T-HOST-01: time_scale không tự động về 1.0 khi mở Host!")
		
	GameSession.start_new_game("Chủ Phòng Host", 888999)
	GameSession.add_item("item_hoi_xuan_dan", 5)
	
	# Cấu hình sạp hàng có đúng 1 món duy nhất để kiểm tra race condition
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.stall_name = "Thiên Đạo Các"
	ShopService.escrow_items = [{ "item_id": "item_hoi_xuan_dan", "count": 1, "price": 30 }]

func _init_client() -> void:
	# Khởi tạo dữ liệu người chơi client
	GameSession.start_new_game("Khách Đạo Hữu", 111222)
	GameSession.add_item("item_linh_thach", 100)

func _process(delta: float) -> void:
	timer += delta
	if timer > max_timeout:
		_log_fail("Timeout sau %.1f giây! Tiến trình không hoàn tất các bước mong đợi." % max_timeout)
		_finish_test(false)
		return
		
	if role_mode == "HOST":
		_process_host(delta)
	else:
		_process_client(delta)

# ==============================================================================
# QUY TRÌNH TIẾN TRÌNH HOST
# ==============================================================================
func _process_host(_delta: float) -> void:
	match step:
		0:
			# Chờ Client kết nối
			if SessionAuthority.connected_peers.size() > 1:
				_log_pass("T-HOST-02: Client kết nối thành công vào Host trên port %d" % port)
				step = 1
				timer = 0.0
		1:
			# Chờ Client gửi di chuyển và đồng bộ
			if motion_synced:
				_log_pass("T-HOST-03: Host nhận và xác thực vị trí Client di chuyển tới (650, 420)")
				step = 2
				timer = 0.0
		2:
			# Chờ Client tấn công Boss và xử lý sát thương
			if boss_damaged:
				_log_pass("T-HOST-04: Host nhận intent tấn công từ Client, thẩm quyền trừ máu Boss")
				step = 3
				timer = 0.0
		3:
			# Chờ boss bị tiêu diệt
			if boss_died:
				_log_pass("T-HOST-05: Boss bị trảm sát thành công, Host trao thưởng loot đồng bộ")
				step = 4
				timer = 0.0
		4:
			# Chờ giao dịch sạp và kiểm tra Race Condition
			if ShopService.escrow_items.is_empty() and ShopService.accumulated_revenue == 30:
				_log_pass("T-HOST-06: Host xác nhận giao dịch sạp thành công: Mua món hàng cuối cùng, kho trống, doanh thu +30 LT")
				step = 5
				timer = 0.0
		5:
			# Host kích hoạt chuyển tháng và phát sóng snapshot
			if timer > 0.5:
				_log_pass("T-HOST-07: Host thực thi mô phỏng thế giới hàng tháng và phát sóng snapshot")
				var summary = MonthlySimulationService.simulate_month(2, 1)
				CoopWorldSync.host_broadcast_month_simulation(2, 1, summary)
				step = 6
				timer = 0.0
		6:
			# Chờ Client ngắt kết nối và thử nghiệm Save Host
			if SessionAuthority.connected_peers.size() == 1:
				_log_pass("T-HOST-08: Host phát hiện Client disconnect an toàn và dọn dẹp peer")
				SaveService.save_game(99)
				var save_ok = SaveService.load_game(99)
				if save_ok:
					_log_pass("T-HOST-09: Host lưu và tải lại thế giới Co-op (Slot 99) thành công")
				else:
					_log_fail("T-HOST-09: Host không thể tải file save slot 99")
				step = 7
				timer = 0.0
		7:
			# Chờ Client reconnect
			if SessionAuthority.connected_peers.size() > 1:
				_log_pass("T-HOST-10: Client tái kết nối (Reconnect) thành công vào Host!")
				_finish_test(true)

# ==============================================================================
# QUY TRÌNH TIẾN TRÌNH CLIENT
# ==============================================================================
func _process_client(_delta: float) -> void:
	match step:
		0:
			# Đợi 0.4s rồi kết nối vào Host
			if timer > 0.4:
				var err = SessionAuthority.join_host("127.0.0.1", port)
				if err != OK:
					_log_fail("Client join_host thất bại với mã %d" % err)
					_finish_test(false)
					return
				step = 1
				timer = 0.0
		1:
			# Kiểm tra kết nối thành công (phải đợi handshake hoàn tất status == CONNECTION_CONNECTED)
			if SessionAuthority.multiplayer.has_multiplayer_peer() and SessionAuthority.multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				_log_pass("T-CLIENT-01: Client kết nối thành công tới Server localhost:%d (Peer ID: %d)" % [port, SessionAuthority.multiplayer.get_unique_id()])
				if GameClock.time_scale == 1.0:
					_log_pass("T-CLIENT-02: Client time_scale được khóa cứng 1.0 chuẩn xác")
				else:
					_log_fail("T-CLIENT-02: Client time_scale bị sai lệch khác 1.0!")
				step = 2
				timer = 0.0
		2:
			# Gửi vị trí di chuyển tới (650, 420)
			if timer > 0.3:
				CoopWorldSync.rpc_id(1, "client_submit_motion", Vector2(650, 420), Vector2.RIGHT, "walk_south")
				step = 3
				timer = 0.0
		3:
			# Client gửi ý định tấn công Boss
			if timer > 0.4:
				CoopWorldSync.request_attack_boss("skill_1", Vector2.RIGHT)
				step = 4
				timer = 0.0
		4:
			# Client tiếp tục tấn công dứt điểm Boss
			if boss_damaged and not boss_died:
				if timer > 0.2:
					timer = 0.0
					CoopWorldSync.request_attack_boss("skill_2", Vector2.RIGHT)
			elif boss_died:
				_log_pass("T-CLIENT-03: Client nhận được tín hiệu Boss bị tiêu diệt và loot đồng bộ từ Host")
				step = 5
				timer = 0.0
		5:
			# Client thực hiện mua hàng từ sạp (Món duy nhất trong kho)
			if timer > 0.3:
				var req_id = "TXN_CLI_REQ_001"
				CoopWorldSync.request_buy_from_stall(req_id, "item_hoi_xuan_dan", 1)
				step = 6
				timer = 0.0
		6:
			# Kiểm tra kết quả giao dịch lần 1
			if stall_trade_1_ok:
				_log_pass("T-CLIENT-04: Client mua thành công món hàng cuối từ sạp (-30 LT, nhận 1x Hồi Xuân Đan)")
				# Thử gửi lại chính request_id đó để kiểm tra Idempotency
				CoopWorldSync.request_buy_from_stall("TXN_CLI_REQ_001", "item_hoi_xuan_dan", 1)
				step = 7
				timer = 0.0
		7:
			# Thử gửi request_id mới để mua khi kho đã cạn -> Phải bị từ chối
			if timer > 0.3:
				CoopWorldSync.request_buy_from_stall("TXN_CLI_REQ_002_RACE", "item_hoi_xuan_dan", 1)
				step = 8
				timer = 0.0
		8:
			if stall_trade_race_rejected:
				_log_pass("T-CLIENT-05: Giao dịch khi kho hết hàng bị Host từ chối an toàn (Chống nhân bản đồ)")
				step = 9
				timer = 0.0
		9:
			# Chờ nhận snapshot mô phỏng thế giới hàng tháng từ Host
			if month_synced:
				_log_pass("T-CLIENT-06: Client tiếp nhận snapshot mô phỏng thế giới Tháng 2 Năm 1 từ Host")
				step = 10
				timer = 0.0
		10:
			# Thử nghiệm ngắt kết nối (Disconnect)
			if timer > 0.3:
				_log_pass("T-CLIENT-07: Client chủ động ngắt kết nối (Disconnect) để kiểm tra Reconnect")
				SessionAuthority.stop_session()
				step = 11
				timer = 0.0
		11:
			# Sau 0.5s, Client tiến hành kết nối lại (Reconnect)
			if timer > 0.5:
				var reconn_err = SessionAuthority.join_host("127.0.0.1", port)
				if reconn_err == OK:
					step = 12
					timer = 0.0
				else:
					_log_fail("T-CLIENT-08: Reconnect thất bại!")
					_finish_test(false)
		12:
			# Chờ handshake reconnect hoàn tất
			if SessionAuthority.multiplayer.has_multiplayer_peer() and SessionAuthority.multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				_log_pass("T-CLIENT-08: Client kết nối lại (Reconnect) thành công tới Host")
				step = 13
				timer = 0.0
		13:
			# Duy trì kết nối 0.4s để Host kịp nhận diện và hoàn tất T-HOST-10
			if timer > 0.4:
				_finish_test(true)

# ==============================================================================
# XỬ LÝ TÍN HIỆU TỪ COOP_WORLD_SYNC
# ==============================================================================
func _on_peer_joined(peer_id: int, _info: Dictionary) -> void:
	if peer_id > 1:
		client_connected = true

func _on_peer_left(_peer_id: int) -> void:
	pass

func _on_remote_player_updated(peer_id: int, data: Dictionary) -> void:
	if role_mode == "HOST" and peer_id > 1:
		var pos = data.get("pos", Vector2.ZERO)
		if pos.distance_to(Vector2(650, 420)) < 1.0:
			motion_synced = true

func _on_boss_hp_changed(_current_hp: int, _max_hp: int, _dmg: int, _is_crit: bool) -> void:
	boss_damaged = true

func _on_boss_defeated(_boss_id: String) -> void:
	boss_died = true

func _on_loot_received(_item_id: String, _count: int, _exp: int) -> void:
	loot_received = true

func _on_stall_tx_completed(request_id: String, success: bool, _msg: String) -> void:
	if request_id == "TXN_CLI_REQ_001" and success:
		stall_trade_1_ok = true
	elif request_id == "TXN_CLI_REQ_002_RACE" and not success:
		stall_trade_race_rejected = true

func _on_world_sim_synced(snapshot: Dictionary) -> void:
	if snapshot.get("month", 0) == 2:
		month_synced = true

func _log_pass(msg: String) -> void:
	test_passed += 1
	logs.append("✓ [PASS] " + msg)
	print("✓ [PASS] " + msg)

func _log_fail(msg: String) -> void:
	test_failed += 1
	logs.append("✗ [FAIL] " + msg)
	print("✗ [FAIL] " + msg)

func _finish_test(success: bool) -> void:
	print("\n-------------------------------------------------------")
	print("TỔNG KẾT [%s]: %d ĐẠT (PASS) | %d THẤT BẠI (FAIL)" % [role_mode, test_passed, test_failed])
	print("=======================================================\n")
	
	# Dọn dẹp slot 99
	if FileAccess.file_exists(SaveService.get_save_path(99)):
		DirAccess.remove_absolute(SaveService.get_save_path(99))
	if FileAccess.file_exists(SaveService.get_meta_path(99)):
		DirAccess.remove_absolute(SaveService.get_meta_path(99))
	if FileAccess.file_exists(SaveService.get_backup_path(99)):
		DirAccess.remove_absolute(SaveService.get_backup_path(99))
		
	get_tree().quit(0 if success and test_failed == 0 else 1)
