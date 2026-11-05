extends Control

## CoopMenuModal — Giao diện Điều Khiển Phòng Co-op Đồng Đạo (Host/Join/Disconnect)
## Hiển thị vai trò mạng, địa chỉ IP, cổng, Peer ID, số người chơi và khóa thời gian 1.0x.

@onready var label_role: Label = $PanelContainer/Margin/VBox/InfoGrid/LabelRole
@onready var label_peer_id: Label = $PanelContainer/Margin/VBox/InfoGrid/LabelPeerID
@onready var label_status: Label = $PanelContainer/Margin/VBox/InfoGrid/LabelStatus
@onready var label_time_lock: Label = $PanelContainer/Margin/VBox/InfoGrid/LabelTimeLock
@onready var label_peer_count: Label = $PanelContainer/Margin/VBox/InfoGrid/LabelPeerCount

@onready var line_ip: LineEdit = $PanelContainer/Margin/VBox/InputGrid/LineIP
@onready var line_port: LineEdit = $PanelContainer/Margin/VBox/InputGrid/LinePort

@onready var btn_host: Button = $PanelContainer/Margin/VBox/ActionButtons/BtnHost
@onready var btn_join: Button = $PanelContainer/Margin/VBox/ActionButtons/BtnJoin
@onready var btn_disconnect: Button = $PanelContainer/Margin/VBox/ActionButtons/BtnDisconnect
@onready var btn_close: Button = $PanelContainer/Margin/VBox/Bottom/BtnClose

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_panel)
	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_disconnect.pressed.connect(_on_disconnect_pressed)
	
	line_ip.text = "127.0.0.1"
	line_port.text = "8899"
	
	if SessionAuthority:
		SessionAuthority.connection_state_changed.connect(func(_r): _refresh_ui())
		SessionAuthority.peer_joined.connect(func(_id, _info): _refresh_ui())
		SessionAuthority.peer_left.connect(func(_id): _refresh_ui())

func open_panel() -> void:
	visible = true
	_refresh_ui()

func close_panel() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_panel()
		get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
	if not is_inside_tree():
		return
		
	var role = SessionAuthority.current_role if SessionAuthority else SessionAuthority.NetworkRole.STANDALONE
	match role:
		SessionAuthority.NetworkRole.HOST_SERVER:
			label_role.text = "Chủ Phòng (HOST)"
			label_role.modulate = Color(1.0, 0.85, 0.3)
			label_status.text = "ĐANG MỞ CỔNG PHÒNG"
			label_status.modulate = Color(0.4, 0.9, 0.4)
			btn_host.disabled = true
			btn_join.disabled = true
			btn_disconnect.disabled = false
		SessionAuthority.NetworkRole.CLIENT:
			label_role.text = "Khách Tham Gia (CLIENT)"
			label_role.modulate = Color(0.4, 0.8, 1.0)
			label_status.text = "ĐÃ KẾT NỐI MÁY CHỦ"
			label_status.modulate = Color(0.4, 0.9, 0.4)
			btn_host.disabled = true
			btn_join.disabled = true
			btn_disconnect.disabled = false
		_:
			label_role.text = "Chơi Đơn (STANDALONE)"
			label_role.modulate = Color(0.8, 0.8, 0.8)
			label_status.text = "CHƯA KẾT NỐI"
			label_status.modulate = Color(0.8, 0.5, 0.5)
			btn_host.disabled = false
			btn_join.disabled = false
			btn_disconnect.disabled = true

	var peer_id = 1
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		peer_id = multiplayer.get_unique_id()
	elif role == SessionAuthority.NetworkRole.STANDALONE:
		peer_id = 0
		
	label_peer_id.text = str(peer_id) if peer_id != 0 else "N/A"
	label_time_lock.text = "720s thực/ngày [Khóa 1.0x]"
	
	var count = SessionAuthority.connected_peers.size() if SessionAuthority else 1
	label_peer_count.text = "%d người chơi" % maxi(1, count)

func _on_host_pressed() -> void:
	var port = int(line_port.text)
	if port <= 1024 or port > 65535:
		port = 8899
	var err = SessionAuthority.start_host(port, 4)
	if err == OK:
		if EventBus:
			EventBus.notification_requested.emit("Đã khởi tạo phòng Co-op Host trên port %d (1x Lock)!" % port, "success")
	else:
		if EventBus:
			EventBus.notification_requested.emit("Khởi tạo phòng thất bại: mã lỗi %d" % err, "error")
	_refresh_ui()

func _on_join_pressed() -> void:
	var ip = line_ip.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var port = int(line_port.text)
	if port <= 1024 or port > 65535:
		port = 8899
	var err = SessionAuthority.join_host(ip, port)
	if err == OK:
		if EventBus:
			EventBus.notification_requested.emit("Đang kết nối tới host %s:%d..." % [ip, port], "info")
	else:
		if EventBus:
			EventBus.notification_requested.emit("Lỗi kết nối tới host: mã lỗi %d" % err, "error")
	_refresh_ui()

func _on_disconnect_pressed() -> void:
	SessionAuthority.stop_session()
	if EventBus:
		EventBus.notification_requested.emit("Đã ngắt kết nối phòng Co-op, trở về Chơi Đơn.", "info")
	_refresh_ui()
