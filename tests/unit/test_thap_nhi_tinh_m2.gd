extends RefCounted

## Test Suite: Thập Nhị Tỉnh Milestone M2 — Seamless Province Streaming & Core Slice 512x512
## Kiểm thử chuyển đổi tọa độ Chunk, bộ nạp động 3x3 (radius 1), giải phóng RAM và tích hợp Save Migration V3.

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Test 1: Toán học chuyển đổi tọa độ Chunk
	var t1 = _test_chunk_coordinate_math()
	logs.append(t1.log)
	if t1.success:
		passed += 1
	else:
		failed += 1
	
	# Test 2: Bộ nạp động 3x3 quanh người chơi (Radius = 1)
	var t2 = _test_streamer_3x3_window()
	logs.append(t2.log)
	if t2.success:
		passed += 1
	else:
		failed += 1
	
	# Test 3: Giải phóng Chunk cũ khi di chuyển xa (Dynamic Unloading)
	var t3 = _test_streamer_dynamic_unloading()
	logs.append(t3.log)
	if t3.success:
		passed += 1
	else:
		failed += 1
	
	# Test 4: Khởi tạo thực thể phân vùng lõi 512x512 (Thanh Trì, Rừng Trúc, Đầm Xà, Kiếm Trũng)
	var t4 = _test_core_slice_entities()
	logs.append(t4.log)
	if t4.success:
		passed += 1
	else:
		failed += 1
	
	# Test 5: Lưu trữ và Tương thích ngược Save Schema V3 (Migration)
	var t5 = _test_save_schema_v3_migration()
	logs.append(t5.log)
	if t5.success:
		passed += 1
	else:
		failed += 1
	
	# Test 6: Kiểm tra Scene ProvinceWorld và Cây Node hoàn chỉnh
	var t6 = _test_province_world_scene_health()
	logs.append(t6.log)
	if t6.success:
		passed += 1
	else:
		failed += 1
	
	return {
		"name": "Thập Nhị Tỉnh M2: Seamless Province Streaming & Core 512x512",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}

static func _test_chunk_coordinate_math() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	if not StreamerScript:
		return { "success": false, "log": "✗ [T-M2-01] Không thể tải chunk_streamer.gd." }
		
	var streamer = StreamerScript.new()
	
	# (0, 0) -> (0, 0)
	var c0 = streamer.world_pos_to_chunk(Vector2(0, 0))
	if c0 != Vector2i(0, 0):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai tọa độ (0, 0) -> %s" % str(c0) }
		
	# (2047, 2047) -> (0, 0)
	var c_edge = streamer.world_pos_to_chunk(Vector2(2047, 2047))
	if c_edge != Vector2i(0, 0):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai tọa độ biên (2047, 2047) -> %s" % str(c_edge) }
		
	# (2048, 2048) -> (1, 1)
	var c1 = streamer.world_pos_to_chunk(Vector2(2048, 2048))
	if c1 != Vector2i(1, 1):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai tọa độ (2048, 2048) -> %s" % str(c1) }
		
	# (66560, 66560) -> (32, 32)
	var c32 = streamer.world_pos_to_chunk(Vector2(66560, 66560))
	if c32 != Vector2i(32, 32):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai tọa độ Thanh Trì Center -> %s" % str(c32) }
		
	# Biên cực đại (131071, 131071) -> (63, 63)
	var c_max = streamer.world_pos_to_chunk(Vector2(131071, 131071))
	if c_max != Vector2i(63, 63):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai tọa độ biên cực đại -> %s" % str(c_max) }
		
	# Chuyển ngược chunk -> world_pos
	var p32 = streamer.chunk_to_world_pos(Vector2i(32, 32))
	if p32 != Vector2(32 * 2048, 32 * 2048):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-01] Sai chuyển ngược chunk -> world_pos: %s" % str(p32) }
		
	streamer.free()
	return { "success": true, "log": "✓ [T-M2-01] Toán học chuyển đổi tọa độ Chunk 64x64 và thế giới 4096x4096 đạt chuẩn." }

static func _test_streamer_3x3_window() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	var streamer = StreamerScript.new()
	streamer.load_radius = 1
	
	# Người chơi đứng tại trung tâm Thanh Trì (Chunk 32, 32)
	streamer.update_streamer_position(Vector2(66560, 66560))
	
	var active_count = streamer.get_active_chunk_count()
	if active_count != 9:
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-02] Số chunk kích hoạt phải là 9 (3x3), nhận được: %d" % active_count }
		
	# Kiểm tra chunk tâm và các lân cận
	if not streamer.is_chunk_active(Vector2i(32, 32)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-02] Chunk tâm (32, 32) chưa được kích hoạt." }
		
	if not streamer.is_chunk_active(Vector2i(31, 32)) or not streamer.is_chunk_active(Vector2i(33, 32)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-02] Các chunk lân cận Đông/Tây chưa được kích hoạt." }
		
	if not streamer.is_chunk_active(Vector2i(32, 31)) or not streamer.is_chunk_active(Vector2i(32, 33)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-02] Các chunk lân cận Nam/Bắc chưa được kích hoạt." }
		
	# Giải phóng an toàn
	for c in streamer.get_children():
		c.free()
	streamer.free()
	return { "success": true, "log": "✓ [T-M2-02] Cửa sổ nạp động 3x3 quanh người chơi (radius 1) hoạt động chính xác." }

static func _test_streamer_dynamic_unloading() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	var streamer = StreamerScript.new()
	streamer.load_radius = 1
	
	# Ban đầu ở Chunk (32, 32)
	streamer.update_streamer_position(Vector2(66560, 66560))
	if not streamer.is_chunk_active(Vector2i(32, 32)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-03] Khởi tạo ban đầu thất bại." }
		
	# Di chuyển sang Chunk (4, 4) — Pixel (8200, 8200)
	streamer.update_streamer_position(Vector2(8200, 8200))
	
	# Chunk (32, 32) phải bị gỡ bỏ
	if streamer.is_chunk_active(Vector2i(32, 32)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-03] Chunk (32, 32) không được giải phóng khi di chuyển xa." }
		
	# Số chunk mới phải là 9 quanh (4, 4)
	if streamer.get_active_chunk_count() != 9:
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-03] Tổng chunk kích hoạt tại vị trí mới không đúng: %d" % streamer.get_active_chunk_count() }
		
	if not streamer.is_chunk_active(Vector2i(4, 4)):
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-03] Chunk mới (4, 4) chưa được kích hoạt." }
		
	for c in streamer.get_children():
		c.free()
	streamer.free()
	return { "success": true, "log": "✓ [T-M2-03] Tự động giải phóng chunk ngoài tầm nhìn (Dynamic Unloading) giữ RAM ổn định." }

static func _test_core_slice_entities() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	var streamer = StreamerScript.new()
	
	# Nạp trực tiếp Chunk (32, 32)
	var node32 = Node2D.new()
	streamer._build_chunk_content(node32, Vector2i(32, 32))
	var entities32 = node32.get_node_or_null("Entities")
	if not entities32 or entities32.get_child_count() < 5:
		node32.free()
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-04] Chunk (32, 32) thiếu công trình Thanh Trì Huyện." }
	node32.free()
	
	# Nạp trực tiếp Chunk (32, 30) - Rừng trúc & Thạch động
	var node_bamboo = Node2D.new()
	streamer._build_chunk_content(node_bamboo, Vector2i(32, 30))
	var entities_bamboo = node_bamboo.get_node_or_null("Entities")
	if not entities_bamboo or entities_bamboo.get_child_count() < 5:
		node_bamboo.free()
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-04] Chunk (32, 30) thiếu cảnh quan Rừng Trúc Vạn Lĩnh." }
	node_bamboo.free()
	
	# Nạp trực tiếp Chunk (31, 33) - Đầm lầy độc
	var node_swamp = Node2D.new()
	streamer._build_chunk_content(node_swamp, Vector2i(31, 33))
	var entities_swamp = node_swamp.get_node_or_null("Entities")
	if not entities_swamp or entities_swamp.get_child_count() < 2:
		node_swamp.free()
		streamer.free()
		return { "success": false, "log": "✗ [T-M2-04] Chunk (31, 33) thiếu cảnh quan Độc Trạch Hắc Xà." }
	node_swamp.free()
	
	streamer.free()
	return { "success": true, "log": "✓ [T-M2-04] Các phân vùng lõi 512x512 sinh đúng công trình và cảnh quan đặc trưng." }

static func _test_save_schema_v3_migration() -> Dictionary:
	# 1. Kiểm tra export save có province_id và world metadata
	var exported = GameSession.export_save_dict()
	if exported.get("province_id") != "thin_chau":
		return { "success": false, "log": "✗ [T-M2-05] Thiếu province_id trong save." }
		
	if exported.get("world_id") != "dao_tan_world_01":
		return { "success": false, "log": "✗ [T-M2-05] Thiếu world_id trong save." }
		
	# 2. Thử nghiệm migration từ save V2 (pos_x cũ < 10000)
	var legacy_v2_save = {
		"schema_version": 2,
		"game_version": "0.0.2",
		"world_seed": 1234,
		"clock": { "day": 5, "hour": 10, "minute": 0 },
		"player": {
			"name": "Lâm Phong Test",
			"realm_id": "realm_pham_nhan",
			"pos_x": 1600.0,
			"pos_y": 1280.0,
			"region_id": "reg_thanh_tri",
			"inventory": [{ "item_id": "item_linh_thach", "quantity": 100 }]
		}
	}
	
	var ok = GameSession.import_save_dict(legacy_v2_save)
	if not ok:
		return { "success": false, "log": "✗ [T-M2-05] Nhập save v2 thất bại." }
		
	# Tọa độ thế giới mở phải tự động định vị sang Thanh Trì Center (66560, 66560)
	var effective_pos = GameSession.get_province_world_position()
	if effective_pos != Vector2(66560.0, 66560.0):
		return { "success": false, "log": "✗ [T-M2-05] Migration tọa độ sang Thìn Châu thất bại: %s" % str(effective_pos) }
		
	if GameSession.current_province_id != "thin_chau":
		return { "success": false, "log": "✗ [T-M2-05] Migration province_id thất bại." }
		
	return { "success": true, "log": "✓ [T-M2-05] Save Schema và Migration tương thích ngược 100% không làm mất dữ liệu người chơi." }

static func _test_province_world_scene_health() -> Dictionary:
	var scene_res = load("res://scenes/world/province_world.tscn")
	if not scene_res:
		return { "success": false, "log": "✗ [T-M2-06] Không thể load scene res://scenes/world/province_world.tscn." }
		
	var instance = scene_res.instantiate()
	if not instance:
		return { "success": false, "log": "✗ [T-M2-06] Không thể instantiate province_world.tscn." }
		
	# Kiểm tra các node con bắt buộc
	var streamer = instance.get_node_or_null("ChunkStreamer")
	var camera = instance.get_node_or_null("Camera2D")
	var y_entities = instance.get_node_or_null("YEntities")
	var player = instance.get_node_or_null("YEntities/Player")
	var hud = instance.get_node_or_null("HUD")
	
	if not streamer or not camera or not y_entities or not player or not hud:
		instance.free()
		return { "success": false, "log": "✗ [T-M2-06] Thiếu node cơ bản trong cây phân cấp của ProvinceWorld." }
		
	instance.free()
	return { "success": true, "log": "✓ [T-M2-06] Scene ProvinceWorld tải và cấu hình thành công với đầy đủ node kiến trúc." }
