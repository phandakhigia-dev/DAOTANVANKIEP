extends Node

## SessionAuthority — Quản lý quyền lực mạng (Host-Authoritative) cho Co-op 2–4 người
## Định nghĩa vai trò: STANDALONE (chơi đơn), HOST_SERVER (chủ phòng), CLIENT (người chơi tham gia).

enum NetworkRole {
	STANDALONE,
	HOST_SERVER,
	CLIENT
}

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4

var current_role: NetworkRole = NetworkRole.STANDALONE
var peer: ENetMultiplayerPeer = null
var connected_peers: Dictionary = {} # peer_id: int -> Dictionary

signal peer_joined(peer_id: int, player_info: Dictionary)
signal peer_left(peer_id: int)
signal connection_state_changed(role: NetworkRole)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_server_authoritative() -> bool:
	return current_role == NetworkRole.STANDALONE or current_role == NetworkRole.HOST_SERVER

func is_coop_session() -> bool:
	return current_role == NetworkRole.HOST_SERVER or current_role == NetworkRole.CLIENT

func start_host(port: int = DEFAULT_PORT, max_clients: int = MAX_PLAYERS, bind_ip: String = "0.0.0.0") -> Error:
	stop_session()
	peer = ENetMultiplayerPeer.new()
	if bind_ip != "":
		peer.set_bind_ip(bind_ip)
	var err = peer.create_server(port, max_clients)
	if err != OK:
		push_error("[SessionAuthority] Lỗi khởi tạo host server trên port %d: %d" % [port, err])
		peer = null
		return err
		
	multiplayer.multiplayer_peer = peer
	current_role = NetworkRole.HOST_SERVER
	connected_peers[1] = {
		"peer_id": 1,
		"name": GameSession.player_name if GameSession else "Chủ Phòng",
		"is_host": true
	}
	
	# P0-C: Cưỡng chế time_scale = 1.0 ngay khi khởi tạo phòng Co-op
	if GameClock:
		GameClock.time_scale = 1.0
		GameClock.set_time_scale(1.0)
		
	connection_state_changed.emit(current_role)
	print("[SessionAuthority] Host Server khởi chạy thành công trên port %d (Cố định time_scale = 1.0, 720s thực/ngày)" % port)
	return OK

func join_host(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	stop_session()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err != OK:
		push_error("[SessionAuthority] Lỗi kết nối tới host %s:%d: %d" % [address, port, err])
		peer = null
		return err
		
	# P0-C: Cưỡng chế time_scale = 1.0 ngay khi client tham gia phòng (trước khi đổi role sang CLIENT)
	if GameClock:
		GameClock.time_scale = 1.0
		GameClock.set_time_scale(1.0)
		
	multiplayer.multiplayer_peer = peer
	current_role = NetworkRole.CLIENT
	connection_state_changed.emit(current_role)
	print("[SessionAuthority] Đang kết nối tới host %s:%d (Cố định time_scale = 1.0)..." % [address, port])
	return OK

func stop_session() -> void:
	if peer:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	current_role = NetworkRole.STANDALONE
	connected_peers.clear()
	if GameClock:
		GameClock.time_scale = 1.0
		GameClock.set_time_scale(1.0)
	current_role = NetworkRole.STANDALONE
	connected_peers.clear()
	connection_state_changed.emit(current_role)
	print("[SessionAuthority] Đã ngắt kết nối session, trở về chế độ Standalone.")

func _on_peer_connected(id: int) -> void:
	print("[SessionAuthority] Peer kết nối: %d" % id)
	if is_server_authoritative():
		connected_peers[id] = {
			"peer_id": id,
			"name": "Đạo Hữu #%d" % id,
			"is_host": false
		}
		peer_joined.emit(id, connected_peers[id])

func _on_peer_disconnected(id: int) -> void:
	print("[SessionAuthority] Peer ngắt kết nối: %d" % id)
	connected_peers.erase(id)
	peer_left.emit(id)

func _on_connected_to_server() -> void:
	print("[SessionAuthority] Kết nối thành công tới Server!")

func _on_connection_failed() -> void:
	push_error("[SessionAuthority] Kết nối tới Server thất bại!")
	stop_session()

func _on_server_disconnected() -> void:
	print("[SessionAuthority] Server đã đóng hoặc mất kết nối.")
	stop_session()
