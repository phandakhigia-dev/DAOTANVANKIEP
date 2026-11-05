extends Node

## ClockReplication — Đồng bộ đồng hồ thời gian thực giữa Host và Client (Co-op 2–4 người)
## Chu kỳ phát: 0.5 giây thực (1 phút in-game).
## Kiểm soát trôi dạt (Drift Control): Dung sai tối đa cho phép là 2 phút in-game (1 giây thực).

const SYNC_INTERVAL_SEC: float = 0.5
var _sync_timer: float = 0.0

signal clock_synced_from_server(year: int, month: int, day: int, second_in_day: float)

func _process(delta: float) -> void:
	if SessionAuthority and SessionAuthority.current_role == SessionAuthority.NetworkRole.HOST_SERVER:
		_sync_timer += delta
		if _sync_timer >= SYNC_INTERVAL_SEC:
			_sync_timer = 0.0
			_broadcast_clock_snapshot()

func _broadcast_clock_snapshot() -> void:
	if not GameClock:
		return
		
	sync_clock_snapshot.rpc(
		GameClock.current_year,
		GameClock.current_month,
		GameClock.current_day,
		GameClock.second_in_day,
		GameClock.time_scale
	)

@rpc("authority", "call_remote", "unreliable")
func sync_clock_snapshot(y: int, m: int, d: int, sec: float, scale_val: float) -> void:
	if not GameClock or not SessionAuthority:
		return
		
	# Chỉ Client mới tiếp nhận và điều chỉnh theo Server
	if SessionAuthority.current_role != SessionAuthority.NetworkRole.CLIENT:
		return
		
	var old_year = GameClock.current_year
	var old_month = GameClock.current_month
	var old_day = GameClock.current_day
	var old_hour = GameClock.current_hour
	var old_minute = GameClock.current_minute
	var old_canh = GameClock.current_canh_gio_index
		
	var day_drift = (y != GameClock.current_year or m != GameClock.current_month or d != GameClock.current_day)
	var sec_drift = abs(sec - GameClock.second_in_day)
	
	# Trong Co-op: Luôn cưỡng chế time_scale = 1.0
	var final_scale = 1.0 if SessionAuthority.is_coop_session() else scale_val
	
	# Nếu lệch ngày hoặc lệch quá 4 giây thực (tương đương 480s in-game / 8 phút game), snap ngay lập tức
	if day_drift or sec_drift > 480.0:
		GameClock.current_year = y
		GameClock.current_month = m
		GameClock.current_day = d
		GameClock.second_in_day = sec
		GameClock.time_scale = final_scale
		GameClock._update_time_components()
	else:
		# Hiệu chỉnh mềm (Soft Reconciliation)
		GameClock.second_in_day = lerp(GameClock.second_in_day, sec, 0.4)
		GameClock.time_scale = final_scale
		GameClock._update_time_components()
		
	# Phát các sự kiện ranh giới thời gian (Boundary Events) cho Client UI & Lighting
	if EventBus:
		if GameClock.current_minute != old_minute and EventBus.has_signal("time_ticked"):
			EventBus.time_ticked.emit(GameClock.current_hour, GameClock.current_minute)
		if GameClock.current_hour != old_hour and EventBus.has_signal("hour_advanced"):
			EventBus.hour_advanced.emit(GameClock.current_hour, GameClock.current_day)
		if GameClock.current_canh_gio_index != old_canh and EventBus.has_signal("canh_gio_changed"):
			EventBus.canh_gio_changed.emit(GameClock.get_canh_gio_name(), GameClock.is_night())
		if (d != old_day or day_drift) and EventBus.has_signal("day_advanced"):
			EventBus.day_advanced.emit(GameClock.current_day, GameClock.current_month, GameClock.current_year)
		if (m != old_month or y != old_year) and EventBus.has_signal("month_advanced"):
			EventBus.month_advanced.emit(GameClock.current_month, GameClock.current_year)
		
	clock_synced_from_server.emit(y, m, d, GameClock.second_in_day)

## Yêu cầu thay đổi tỷ lệ thời gian (Client gửi intent lên Host)
@rpc("any_peer", "call_remote", "reliable")
func request_time_scale_change(requested_scale: float) -> void:
	if not SessionAuthority.is_server_authoritative():
		return
		
	# Trong phiên Co-op nhiều người chơi: Khóa cứng tốc độ 1x, từ chối tua nhanh x20 để bảo đảm đồng bộ
	if SessionAuthority.is_coop_session():
		if requested_scale != 1.0:
			push_warning("[ClockReplication] Co-op: Host từ chối time_scale %.1f. Khóa cứng 1x trong phòng nhiều người." % requested_scale)
			return
		
	# Host thẩm định chế độ chơi đơn: Cho phép gia tốc x20 khi thiền hoặc x1 bình thường
	if requested_scale == 1.0 or requested_scale == 20.0:
		GameClock.set_time_scale(requested_scale)
		print("[ClockReplication] Host chấp thuận đổi time_scale = %.1f" % requested_scale)
	else:
		push_warning("[ClockReplication] Host từ chối time_scale không hợp lệ: %.2f" % requested_scale)

## Yêu cầu Time-skip (Khóa hoàn toàn trong Sprint S1 theo spec)
func request_time_skip(_days: int) -> bool:
	print("[ClockReplication] Time-skip bị khóa nghiêm ngặt trong Sprint S1 cho tới khi Sprint S5 được duyệt.")
	return false
