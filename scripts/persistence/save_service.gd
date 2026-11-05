extends Node

## SaveService — Hệ thống lưu trữ an toàn (Atomic Write + Schema Validation)
## Tuân thủ chuẩn kiến trúc docs/06_TECH_ARCHITECTURE.md

const SAVE_DIR: String = "user://saves"
const CURRENT_SCHEMA_VERSION: int = 2

func _ready() -> void:
	_ensure_save_directory()

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

func get_save_path(slot: int) -> String:
	return "%s/slot_%02d.json" % [SAVE_DIR, slot]

func get_meta_path(slot: int) -> String:
	return "%s/slot_%02d.meta.json" % [SAVE_DIR, slot]

func get_backup_path(slot: int) -> String:
	return "%s/slot_%02d.bak.json" % [SAVE_DIR, slot]

func get_temp_path(slot: int) -> String:
	return "%s/slot_%02d.tmp.json" % [SAVE_DIR, slot]

func has_save(slot: int = 1) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func save_game(slot: int = 1) -> bool:
	_ensure_save_directory()
	
	var data = GameSession.export_save_dict()
	data["schema_version"] = CURRENT_SCHEMA_VERSION
	data["saved_at_unix"] = Time.get_unix_time_from_system()
	data["saved_at_str"] = Time.get_datetime_string_from_system()
	
	var json_str = JSON.stringify(data, "  ")
	var temp_path = get_temp_path(slot)
	var final_path = get_save_path(slot)
	var backup_path = get_backup_path(slot)
	var meta_path = get_meta_path(slot)
	
	# 1. Ghi ra file tạm (Atomic Write)
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		push_error("[SaveService] Không thể mở file tạm để ghi: %s" % temp_path)
		return false
	
	file.store_string(json_str)
	file.flush()
	file.close()
	
	# 2. Tạo backup file cũ nếu đã tồn tại
	if FileAccess.file_exists(final_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		DirAccess.copy_absolute(final_path, backup_path)
	
	# 3. Đổi tên file tạm thành file chính (An toàn lỗi với backup phục hồi)
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)
	var err = DirAccess.rename_absolute(temp_path, final_path)
	if err != OK:
		push_error("[SaveService] Không thể đổi tên file tạm: mã lỗi %d. Khôi phục từ backup..." % err)
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(backup_path, final_path)
		return false
	
	# 4. Ghi metadata rút gọn để đọc nhanh ở màn hình Menu
	var meta_data = {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"player_name": GameSession.player_name,
		"realm_id": GameSession.realm_id,
		"realm_name": ContentRegistry.get_realm(GameSession.realm_id).get("name", "Phàm Nhân"),
		"date_str": GameClock.get_formatted_date(),
		"saved_at_str": data["saved_at_str"],
		"world_seed": GameSession.world_seed
	}
	var meta_file = FileAccess.open(meta_path, FileAccess.WRITE)
	if meta_file:
		meta_file.store_string(JSON.stringify(meta_data, "  "))
		meta_file.close()
	
	if EventBus:
		EventBus.game_saved.emit(slot, final_path)
		EventBus.notification_requested.emit("Đã lưu tiến trình thành công!", "success")
	
	return true

func load_game(slot: int = 1) -> bool:
	var final_path = get_save_path(slot)
	var backup_path = get_backup_path(slot)
	
	var data_dict = _read_and_validate_save(final_path)
	if data_dict.is_empty():
		# Thử khôi phục từ file backup nếu file chính lỗi hoặc mất
		push_warning("[SaveService] File chính hỏng hoặc thiếu, thử tải file backup...")
		if FileAccess.file_exists(backup_path):
			data_dict = _read_and_validate_save(backup_path)
			if not data_dict.is_empty():
				DirAccess.copy_absolute(backup_path, final_path)
				push_warning("[SaveService] Đã khôi phục thành công file save chính từ backup!")
	
	if data_dict.is_empty():
		push_error("[SaveService] Không thể tải dữ liệu hợp lệ từ slot %d" % slot)
		if EventBus:
			EventBus.game_loaded.emit(slot, false)
		return false
	
	var success = GameSession.import_save_dict(data_dict)
	if EventBus:
		EventBus.game_loaded.emit(slot, success)
		if success:
			EventBus.notification_requested.emit("Tải ván chơi thành công!", "info")
	
	return success

func _read_and_validate_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK or not (json.data is Dictionary):
		push_error("[SaveService] Parse JSON thất bại tại %s" % path)
		return {}
	
	var data: Dictionary = json.data
	if not validate_save_data(data):
		return {}
	
	return data

func validate_save_data(data: Dictionary) -> bool:
	var schema = data.get("schema_version", 0)
	if schema <= 0:
		push_error("[SaveService] Thiếu hoặc sai schema_version trong save")
		return false
	if schema > CURRENT_SCHEMA_VERSION:
		push_error("[SaveService] Phiên bản schema save (%d) không tương thích với phiên bản hiện tại (%d)" % [schema, CURRENT_SCHEMA_VERSION])
		return false
	
	if not data.has("player") or not data.has("clock") or not data.has("world_seed"):
		push_error("[SaveService] Thiếu trường dữ liệu bắt buộc (player/clock/world_seed)")
		return false
	
	var p = data.get("player")
	if not (p is Dictionary) or not p.has("name") or not p.has("realm_id"):
		push_error("[SaveService] Dữ liệu player không đầy đủ")
		return false
	
	return true

func get_slot_meta(slot: int = 1) -> Dictionary:
	var path = get_meta_path(slot)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var txt = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(txt) == OK and json.data is Dictionary:
				return json.data
	return {}
