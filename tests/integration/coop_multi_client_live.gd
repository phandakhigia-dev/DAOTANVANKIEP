extends Node

## CoopMultiClientLive — Runner Tích Hợp 3 Cửa Sổ Thật (Host + Client 1 + Client 2)
## Thực hiện kiểm thử toàn diện:
##   1. Kết nối ENet 3 tiến trình đồng thời (1 Host, 2 Clients).
##   2. Đồng bộ Avatar và chuyển động của cả 3 nhân vật trên WorldMap thật.
##   3. Cuộc đua giao dịch (Race Condition) mua món hàng cuối cùng giữa 2 client.
##   4. Chụp screenshot thực tế độc lập từ cửa sổ Host và Client.

var role_mode: String = "HOST"
var port: int = 8899
var timer: float = 0.0
var step: int = 0
var max_timeout: float = 20.0

var world_map_node: Node2D = null
var output_dir: String = "res://audit/graphics_after/"

var client1_id: int = 0
var client2_id: int = 0

var motion_received_c1: bool = false
var motion_received_c2: bool = false
var race_processed: bool = false
var race_result_c1: Dictionary = {}
var race_result_c2: Dictionary = {}

func _ready() -> void:
	var user_args = OS.get_cmdline_user_args()
	if user_args.size() > 0:
		role_mode = user_args[0].to_upper()
	if user_args.size() > 1:
		port = int(user_args[1])
		
	print("\n=======================================================")
	print("  CO-OP 3-PROCESS LIVE GAMEPLAY TEST")
	print("  Tiến Trình: %s | Port: %d | Time: %s" % [role_mode, port, Time.get_datetime_string_from_system()])
	print("=======================================================\n")
	
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	
	_load_world_map()
	
	if role_mode == "HOST":
		_init_host()
	elif role_mode == "CLIENT1":
		_init_client(1)
	elif role_mode == "CLIENT2":
		_init_client(2)

func _load_world_map() -> void:
	var scn = load("res://scenes/world/world_map.tscn")
	if scn:
		world_map_node = scn.instantiate()
		add_child(world_map_node)
		print("[%s] Đã nạp thành công WorldMap scene." % role_mode)

func _init_host() -> void:
	GameSession.start_new_game("Chủ Phòng Host", 888999)
	GameSession.add_item("item_tay_tuy_dan", 5)
	
	# Khởi tạo sạp hàng có đúng 1 món duy nhất để test race condition
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.stall_name = "Thiên Đạo Các (Host)"
	ShopService.escrow_items = [{ "item_id": "item_tay_tuy_dan", "count": 1, "price": 150 }]
	
	var err = SessionAuthority.start_host(port, 4)
	if err != OK:
		print("[%s] start_host thất bại mã %d" % [role_mode, err])
		get_tree().quit(1)
		return
		
	SessionAuthority.peer_joined.connect(_on_host_peer_joined)
	CoopWorldSync.remote_player_updated.connect(_on_host_remote_player_updated)
	print("[%s] Host Server đang lắng nghe trên port %d (Cố định 720s thực/ngày)..." % [role_mode, port])

func _init_client(client_idx: int) -> void:
	var name = "Đạo Hữu Tiêu Viêm" if client_idx == 1 else "Đạo Hữu Hàn Lập"
	GameSession.start_new_game(name, 111000 + client_idx)
	GameSession.add_item("item_linh_thach", 500)
	
	CoopWorldSync.stall_transaction_completed.connect(_on_client_stall_tx_completed)
	CoopWorldSync.remote_player_updated.connect(_on_client_remote_player_updated)

func _process(delta: float) -> void:
	timer += delta
	if timer > max_timeout:
		print("[%s] TIMEOUT sau %.1f giây!" % [role_mode, max_timeout])
		get_tree().quit(1)
		return
		
	if role_mode == "HOST":
		_process_host(delta)
	elif role_mode == "CLIENT1":
		_process_client1(delta)
	elif role_mode == "CLIENT2":
		_process_client2(delta)

# ==============================================================================
# QUY TRÌNH HOST
# ==============================================================================
func _process_host(_delta: float) -> void:
	match step:
		0:
			# Chờ cả 2 Client kết nối (tổng peers = 3)
			if SessionAuthority.connected_peers.size() >= 3:
				print("[HOST] Cả 2 Client đã kết nối thành công! Peers: %s" % str(SessionAuthority.connected_peers.keys()))
				step = 1
				timer = 0.0
		1:
			# Chờ nhận chuyển động từ cả 2 client
			if motion_received_c1 and motion_received_c2:
				print("[HOST] Đã nhận và đồng bộ chuyển động của cả 2 Client trên WorldMap.")
				step = 2
				timer = 0.0
		2:
			# Đợi race condition request từ 2 clients
			if ShopService.escrow_items.is_empty() and ShopService.accumulated_revenue == 150:
				print("[HOST] ★ Race Condition Test Thành Công: Kho sạp cạn về 0, Doanh thu +150 LT, không bị âm!")
				step = 3
				timer = 0.0
		3:
			# Đợi 0.4s để khung hình hiển thị đầy đủ avatar của cả 3 nhân vật và chụp ảnh Host Window
			if timer > 0.4:
				_capture_screen("coop_host_window.png")
				print("[HOST] Đã chụp ảnh cửa sổ Host thật: coop_host_window.png")
				step = 4
				timer = 0.0
		4:
			if timer > 1.0:
				print("[HOST] Toàn bộ quy trình Host hoàn tất 100%!")
				get_tree().quit(0)

func _on_host_peer_joined(peer_id: int, info: Dictionary) -> void:
	print("[HOST] Peer tham gia: %d (%s)" % [peer_id, info.get("name", "")])
	if client1_id == 0:
		client1_id = peer_id
	elif client2_id == 0:
		client2_id = peer_id

func _on_host_remote_player_updated(peer_id: int, _data: Dictionary) -> void:
	if peer_id == client1_id:
		motion_received_c1 = true
	elif peer_id == client2_id:
		motion_received_c2 = true

# ==============================================================================
# QUY TRÌNH CLIENT 1 (Tiêu Viêm)
# ==============================================================================
func _process_client1(_delta: float) -> void:
	match step:
		0:
			if timer > 0.6:
				var err = SessionAuthority.join_host("127.0.0.1", port)
				if err == OK:
					print("[CLIENT 1] Đã gửi lệnh join_host.")
					step = 1
					timer = 0.0
				else:
					print("[CLIENT 1] join_host thất bại: %d" % err)
					get_tree().quit(1)
		1:
			if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				print("[CLIENT 1] Kết nối thành công! Peer ID: %d" % multiplayer.get_unique_id())
				step = 2
				timer = 0.0
		2:
			# Gửi di chuyển tới tọa độ (620, 380)
			if timer > 0.3:
				CoopWorldSync.rpc_id(1, "client_submit_motion", Vector2(620, 380), Vector2.RIGHT, "walk_south")
				step = 3
				timer = 0.0
		3:
			# Gửi yêu cầu mua món cuối cùng
			if timer > 0.5:
				print("[CLIENT 1] Gửi request mua món cuối: REQ_RACE_CLI1")
				CoopWorldSync.request_buy_from_stall("REQ_RACE_CLI1", "item_tay_tuy_dan", 1)
				step = 4
				timer = 0.0
		4:
			# Chờ nhận kết quả giao dịch và chụp ảnh cửa sổ Client 1
			if timer > 0.6:
				_capture_screen("coop_client_window.png")
				print("[CLIENT 1] Đã chụp ảnh cửa sổ Client 1 thật: coop_client_window.png")
				step = 5
				timer = 0.0
		5:
			if timer > 1.2:
				print("[CLIENT 1] Hoàn tất tiến trình Client 1.")
				get_tree().quit(0)

# ==============================================================================
# QUY TRÌNH CLIENT 2 (Hàn Lập)
# ==============================================================================
func _process_client2(_delta: float) -> void:
	match step:
		0:
			if timer > 0.8:
				var err = SessionAuthority.join_host("127.0.0.1", port)
				if err == OK:
					print("[CLIENT 2] Đã gửi lệnh join_host.")
					step = 1
					timer = 0.0
				else:
					print("[CLIENT 2] join_host thất bại: %d" % err)
					get_tree().quit(1)
		1:
			if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				print("[CLIENT 2] Kết nối thành công! Peer ID: %d" % multiplayer.get_unique_id())
				step = 2
				timer = 0.0
		2:
			# Gửi di chuyển tới tọa độ (660, 440)
			if timer > 0.3:
				CoopWorldSync.rpc_id(1, "client_submit_motion", Vector2(660, 440), Vector2.LEFT, "walk_south")
				step = 3
				timer = 0.0
		3:
			# Gửi yêu cầu mua đồng thời món cuối cùng
			if timer > 0.5:
				print("[CLIENT 2] Gửi request mua món cuối: REQ_RACE_CLI2")
				CoopWorldSync.request_buy_from_stall("REQ_RACE_CLI2", "item_tay_tuy_dan", 1)
				step = 4
				timer = 0.0
		4:
			if timer > 0.6:
				_capture_screen("coop_client2_window.png")
				print("[CLIENT 2] Đã chụp ảnh cửa sổ Client 2 thật: coop_client2_window.png")
				step = 5
				timer = 0.0
		5:
			if timer > 1.2:
				print("[CLIENT 2] Hoàn tất tiến trình Client 2.")
				get_tree().quit(0)

func _on_client_stall_tx_completed(request_id: String, success: bool, msg: String) -> void:
	print("[%s] Kết quả giao dịch %s: success=%s, msg=%s" % [role_mode, request_id, str(success), msg])

func _on_client_remote_player_updated(peer_id: int, data: Dictionary) -> void:
	pass

func _capture_screen(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var full_path = output_dir + filename
		var err = img.save_png(full_path)
		print("[%s] Lưu screenshot %s (Kích thước: %s, Mã lỗi: %d)" % [
			role_mode, full_path, img.get_size(), err
		])
