extends Node

## GameClock — Quản lý thời gian thế giới game Đạo Tàn: Vạn Kiếp (Co-op Ready)
## Quy chuẩn thế giới: 
##   - 30 ngày = 1 tháng, 12 tháng = 1 năm.
##   - 1 ngày in-game = 24 giờ = 12 Canh Giờ.
##   - Tỷ lệ thời gian thực (Co-op Pacing):
##       1 ngày 24h = 12 phút thực (720 giây).
##       1 giờ in-game = 30 giây thực.
##       1 canh giờ in-game (2h) = 60 giây thực.
##       1 giây thực = 120 giây in-game (Tỷ lệ 1:120).

const SECONDS_PER_DAY: float = 86400.0
const REAL_SECONDS_PER_DAY: float = 720.0 # 12 phút thực
const TIME_RATIO: float = 120.0 # 86400 / 720

const CANH_GIO_NAMES: Array[String] = [
	"Tý (23h - 01h)",  # 0
	"Sửu (01h - 03h)", # 1
	"Dần (03h - 05h)", # 2
	"Mão (05h - 07h)", # 3
	"Thìn (07h - 09h)", # 4
	"Tỵ (09h - 11h)",  # 5
	"Ngọ (11h - 13h)", # 6
	"Mùi (13h - 15h)", # 7
	"Thân (15h - 17h)", # 8
	"Dậu (17h - 19h)", # 9
	"Tuất (19h - 21h)", # 10
	"Hợi (21h - 23h)"  # 11
]

var current_year: int = 1
var current_month: int = 1
var current_day: int = 1
var total_days_elapsed: int = 0

# Tích lũy trong ngày: 0.0 -> 86400.0 (Bắt đầu lúc 6:00 sáng - Giờ Mão)
var second_in_day: float = 21600.0
var current_hour: int = 6
var current_minute: int = 0
var current_canh_gio_index: int = 3

var time_scale: float = 1.0 # 1.0 = bình thường, 20.0 = gia tốc khi bế quan
var is_realtime_ticking: bool = true
var is_paused: bool = false

func _ready() -> void:
	_update_time_components()

func _process(delta: float) -> void:
	if not is_realtime_ticking or is_paused:
		return
	# Nếu là Client trong phiên Co-op, nhịp thời gian hoàn toàn do Host điều khiển và phát sóng snapshot
	if SessionAuthority and SessionAuthority.current_role == SessionAuthority.NetworkRole.CLIENT:
		return
	
	advance_realtime_seconds(delta * time_scale)

func reset_clock() -> void:
	current_year = 1
	current_month = 1
	current_day = 1
	total_days_elapsed = 0
	second_in_day = 21600.0 # 6:00 AM
	time_scale = 1.0
	is_paused = false
	_update_time_components()

func set_time_scale(scale_val: float) -> void:
	if SessionAuthority and SessionAuthority.is_coop_session():
		if scale_val != 1.0:
			push_warning("[GameClock] Co-op: Khóa cứng time_scale = 1.0. Từ chối đổi sang %.1f" % scale_val)
			time_scale = 1.0
			return
	if SessionAuthority and not SessionAuthority.is_server_authoritative():
		push_warning("[GameClock] Client không có quyền thay đổi time_scale.")
		return
	time_scale = max(0.0, scale_val)
	if EventBus and EventBus.has_signal("time_scale_changed"):
		EventBus.time_scale_changed.emit(time_scale)

func set_paused(paused_val: bool) -> void:
	is_paused = paused_val

## Tiến thời gian theo số giây đời thực
func advance_realtime_seconds(real_seconds: float) -> void:
	if real_seconds <= 0.0:
		return
	
	var in_game_seconds = real_seconds * TIME_RATIO
	second_in_day += in_game_seconds
	
	var days_to_advance = int(second_in_day / SECONDS_PER_DAY)
	if days_to_advance > 0:
		second_in_day = fmod(second_in_day, SECONDS_PER_DAY)
		_advance_days_internal(days_to_advance)
	else:
		_check_time_transitions()

## Tiến số phút in-game (0.5 giây thực tế = 1 phút in-game)
func advance_minutes(mins: int) -> void:
	if mins <= 0:
		return
	if SessionAuthority and SessionAuthority.is_coop_session():
		push_warning("[GameClock] Co-op: Từ chối advance_minutes(%d). Giữ nhịp 720s thực tế / ngày." % mins)
		return
	if SessionAuthority and not SessionAuthority.is_server_authoritative():
		push_warning("[GameClock] Client không có quyền gọi advance_minutes.")
		return
	advance_realtime_seconds(float(mins) * 0.5)

## Tiến số giờ in-game (30 giây thực tế = 1 giờ in-game)
func advance_hours(hours: int) -> void:
	if hours <= 0:
		return
	if SessionAuthority and SessionAuthority.is_coop_session():
		push_warning("[GameClock] Co-op: Từ chối advance_hours(%d). Giữ nhịp 720s thực tế / ngày." % hours)
		return
	if SessionAuthority and not SessionAuthority.is_server_authoritative():
		push_warning("[GameClock] Client không có quyền gọi advance_hours.")
		return
	advance_realtime_seconds(float(hours) * 30.0)

## Tiến ngày gián đoạn (dùng cho bế quan hoặc test nhanh)
func advance_days(days: int) -> void:
	if days <= 0:
		return
	if SessionAuthority and SessionAuthority.is_coop_session():
		push_warning("[GameClock] Co-op: Từ chối thủ công advance_days(%d). Giữ nhịp 720s thực tế / ngày." % days)
		return
	if SessionAuthority and not SessionAuthority.is_server_authoritative():
		push_warning("[GameClock] Client không có quyền gọi advance_days.")
		return
	_advance_days_internal(days)

func _advance_days_internal(days: int) -> void:
	for i in range(days):
		current_day += 1
		total_days_elapsed += 1
		
		if current_day > 30:
			current_day = 1
			current_month += 1
			
			if current_month > 12:
				current_month = 1
				current_year += 1
			
			if EventBus:
				EventBus.month_advanced.emit(current_month, current_year)
		
		if EventBus:
			EventBus.day_advanced.emit(current_day, current_month, current_year)
	
	_check_time_transitions()

func _update_time_components() -> void:
	var total_sec = int(second_in_day)
	current_hour = (total_sec / 3600) % 24
	current_minute = (total_sec % 3600) / 60
	current_canh_gio_index = get_canh_gio_index_from_hour(current_hour)

func _check_time_transitions() -> void:
	var old_hour = current_hour
	var old_minute = current_minute
	var old_canh = current_canh_gio_index
	
	_update_time_components()
	
	if current_minute != old_minute:
		if EventBus and EventBus.has_signal("time_ticked"):
			EventBus.time_ticked.emit(current_hour, current_minute)
			
	if current_hour != old_hour:
		if EventBus and EventBus.has_signal("hour_advanced"):
			EventBus.hour_advanced.emit(current_hour, current_day)
			
	if current_canh_gio_index != old_canh:
		if EventBus and EventBus.has_signal("canh_gio_changed"):
			EventBus.canh_gio_changed.emit(get_canh_gio_name(), is_night())

func get_canh_gio_index_from_hour(hour: int) -> int:
	if hour >= 23 or hour < 1:
		return 0 # Tý
	elif hour >= 1 and hour < 3:
		return 1 # Sửu
	elif hour >= 3 and hour < 5:
		return 2 # Dần
	elif hour >= 5 and hour < 7:
		return 3 # Mão
	elif hour >= 7 and hour < 9:
		return 4 # Thìn
	elif hour >= 9 and hour < 11:
		return 5 # Tỵ
	elif hour >= 11 and hour < 13:
		return 6 # Ngọ
	elif hour >= 13 and hour < 15:
		return 7 # Mùi
	elif hour >= 15 and hour < 17:
		return 8 # Thân
	elif hour >= 17 and hour < 19:
		return 9 # Dậu
	elif hour >= 19 and hour < 21:
		return 10 # Tuất
	else:
		return 11 # Hợi

func get_canh_gio_name() -> String:
	return CANH_GIO_NAMES[current_canh_gio_index]

func get_canh_gio_short() -> String:
	return CANH_GIO_NAMES[current_canh_gio_index].split(" ")[0]

## Kiểm tra có phải ban đêm không (Giờ Tuất 19h đến hết Giờ Dần 5h sáng)
func is_night() -> bool:
	return current_hour >= 19 or current_hour < 5

func get_formatted_time() -> String:
	var period = "Ban Đêm (Âm)" if is_night() else "Ban Ngày (Dương)"
	return "%02d:%02d [%s • %s]" % [current_hour, current_minute, get_canh_gio_short(), period]

func get_formatted_date() -> String:
	return "Năm %d • Tháng %02d • Ngày %02d" % [current_year, current_month, current_day]

func get_formatted_full() -> String:
	return "%s — %s" % [get_formatted_date(), get_formatted_time()]

func to_dict() -> Dictionary:
	return {
		"year": current_year,
		"month": current_month,
		"day": current_day,
		"total_days_elapsed": total_days_elapsed,
		"second_in_day": second_in_day,
		"current_hour": current_hour,
		"current_minute": current_minute,
		"time_scale": time_scale
	}

func from_dict(data: Dictionary) -> void:
	current_year = data.get("year", 1)
	current_month = data.get("month", 1)
	current_day = data.get("day", 1)
	total_days_elapsed = data.get("total_days_elapsed", 0)
	second_in_day = data.get("second_in_day", 21600.0)
	if SessionAuthority and SessionAuthority.is_coop_session():
		time_scale = 1.0
	else:
		time_scale = clampf(data.get("time_scale", 1.0), 0.1, 20.0)
	_update_time_components()
