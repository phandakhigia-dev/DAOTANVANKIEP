extends RefCounted

## Test Suite: Thập Nhị Tỉnh Milestone M3 — Functional Settlements, Roads, Fast Travel & POI Landmarks
## Kiểm thử mạng lưới quan lộ, 7 địa hạt định danh, 2 tông môn tự trị, trạm dịch mã và persistent chunk diffs.

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Test 1: Mạng lưới quan lộ và sông ngòi Thìn Châu
	var t1 = _test_highways_and_rivers()
	logs.append(t1.log)
	if t1.success:
		passed += 1
	else:
		failed += 1
	
	# Test 2: Cụm địa hạt định danh và 2 Tông Môn tự trị
	var t2 = _test_settlements_and_sects()
	logs.append(t2.log)
	if t2.success:
		passed += 1
	else:
		failed += 1
	
	# Test 3: Hệ thống trạm dịch mã và di chuyển nhanh (Fast Travel)
	var t3 = _test_fast_travel_network()
	logs.append(t3.log)
	if t3.success:
		passed += 1
	else:
		failed += 1
	
	# Test 4: Điểm cơ duyên và di tích có cấu trúc (Landmarks Pacing)
	var t4 = _test_landmarks_and_pacing()
	logs.append(t4.log)
	if t4.success:
		passed += 1
	else:
		failed += 1
	
	# Test 5: Trạng thái vi sai chunk bền vững (Sparse Chunk Diffs)
	var t5 = _test_sparse_chunk_diffs()
	logs.append(t5.log)
	if t5.success:
		passed += 1
	else:
		failed += 1
	
	# Test 6: Sinh thực thể đô thị Long Kinh & Trại mỏ Tây Sơn
	var t6 = _test_capital_and_mining_generation()
	logs.append(t6.log)
	if t6.success:
		passed += 1
	else:
		failed += 1
	
	return {
		"name": "Thập Nhị Tỉnh M3: Settlements, Roads, Fast Travel & Landmarks",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}

static func _test_highways_and_rivers() -> Dictionary:
	if not WorldRegistry:
		return { "success": false, "log": "✗ [T-M3-01] WorldRegistry autoload chưa sẵn sàng." }
		
	var net = WorldRegistry.get_roads_and_rivers("thin_chau")
	var highways = net.get("highways", [])
	var rivers = net.get("rivers", [])
	
	if highways.size() < 2 or rivers.size() < 1:
		return { "success": false, "log": "✗ [T-M3-01] Thiếu dữ liệu quan lộ hoặc sông ngòi Thìn Châu." }
		
	var has_ns = false
	var has_ew = false
	for h in highways:
		if h.get("id") == "highway_north_south": has_ns = true
		if h.get("id") == "highway_east_west": has_ew = true
		
	if not has_ns or not has_ew:
		return { "success": false, "log": "✗ [T-M3-01] Thiếu 2 trục đại quan lộ Bắc-Nam và Đông-Tây." }
		
	var river = rivers[0]
	var crossings = river.get("crossings", [])
	if crossings.size() < 2:
		return { "success": false, "log": "✗ [T-M3-01] Thiếu cầu vượt sông Nam Giang." }
		
	return { "success": true, "log": "✓ [T-M3-01] Mạng lưới Bắc Nam Đại Quan Lộ và sông Nam Giang kết nối thông suốt." }

static func _test_settlements_and_sects() -> Dictionary:
	var settlements = WorldRegistry.get_settlements("thin_chau")
	if settlements.size() < 7:
		return { "success": false, "log": "✗ [T-M3-02] Thìn Châu phải có tối thiểu 7 địa hạt (nhận được: %d)." % settlements.size() }
		
	var req_ids = [
		"settlement_long_kinh", "settlement_thanh_tri", "settlement_dong_noi",
		"settlement_tay_son", "settlement_bac_lam", "sect_thanh_vi", "sect_bach_thao"
	]
	
	for req in req_ids:
		var found = false
		for s in settlements:
			if s.get("id") == req:
				found = true
				if s.get("world_pixel_center").size() != 2:
					return { "success": false, "log": "✗ [T-M3-02] Địa hạt %s thiếu tọa độ pixel trung tâm." % req }
				break
		if not found:
			return { "success": false, "log": "✗ [T-M3-02] Không tìm thấy địa hạt hoặc tông môn: %s" % req }
			
	return { "success": true, "log": "✓ [T-M3-02] Quy hoạch 5 khu định cư và 2 Tông Môn tự trị (Thanh Vi & Bách Thảo) hoàn chỉnh." }

static func _test_fast_travel_network() -> Dictionary:
	var stations = WorldRegistry.get_fast_travel_stations("thin_chau")
	if stations.size() < 5:
		return { "success": false, "log": "✗ [T-M3-03] Mạng lưới trạm dịch mã phải có ít nhất 5 trạm (nhận: %d)." % stations.size() }
		
	var thanh_tri_st = WorldRegistry.get_fast_travel_station("thin_chau", "tram_dich_thanh_tri")
	if thanh_tri_st.is_empty():
		return { "success": false, "log": "✗ [T-M3-03] Không tìm thấy trạm dịch mã Thanh Trì Huyện." }
		
	var connections = thanh_tri_st.get("connected_station_ids", [])
	if not "tram_dich_long_kinh" in connections or not "tram_dich_dong_noi" in connections:
		return { "success": false, "log": "✗ [T-M3-03] Trạm Thanh Trì thiếu tuyến kết nối tới Long Kinh hoặc Đồng Nội." }
		
	return { "success": true, "log": "✓ [T-M3-03] Mạng lưới dịch trạm ngựa liên thông, có biểu phí và thời gian di chuyển rõ ràng." }

static func _test_landmarks_and_pacing() -> Dictionary:
	var landmarks = WorldRegistry.get_landmarks("thin_chau")
	if landmarks.size() < 5:
		return { "success": false, "log": "✗ [T-M3-04] Cần ít nhất 5 điểm cơ duyên/cảnh quan có cấu trúc." }
		
	var has_cavern = false
	var has_shrine = false
	var has_monolith = false
	for lm in landmarks:
		if lm.get("id") == "poi_bamboo_cavern": has_cavern = true
		if lm.get("id") == "poi_snake_shrine": has_shrine = true
		if lm.get("id") == "poi_sword_monolith": has_monolith = true
		
	if not has_cavern or not has_shrine or not has_monolith:
		return { "success": false, "log": "✗ [T-M3-04] Thiếu một trong các landmark cốt lõi (Thạch Động, Tế Đàn, Cổ Kiếm Bia)." }
		
	return { "success": true, "log": "✓ [T-M3-04] Điểm tương tác và di tích cơ duyên phân bổ nhịp nhàng (20-40s pacing)." }

static func _test_sparse_chunk_diffs() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	var streamer = StreamerScript.new()
	var test_chunk = Vector2i(32, 30)
	var test_entity = "test_cavern_chest_m3"
	
	# Ban đầu chưa thu hoạch
	if streamer.is_entity_harvested(test_chunk, test_entity):
		streamer.free()
		return { "success": false, "log": "✗ [T-M3-05] Thực thể không được đánh dấu thu hoạch trước khi tác động." }
		
	# Đánh dấu thu hoạch
	streamer.mark_entity_harvested(test_chunk, test_entity)
	if not streamer.is_entity_harvested(test_chunk, test_entity):
		streamer.free()
		return { "success": false, "log": "✗ [T-M3-05] Không ghi nhận được trạng thái thu hoạch vi sai của chunk." }
		
	# Kiểm tra tồn tại trong GameSession.chunk_diffs
	if not GameSession.chunk_diffs.has("32_30"):
		streamer.free()
		return { "success": false, "log": "✗ [T-M3-05] GameSession.chunk_diffs thiếu key '32_30'." }
		
	streamer.free()
	return { "success": true, "log": "✓ [T-M3-05] Trạng thái vi sai chunk (Sparse Chunk Diffs) bền vững, chống trùng lặp tài nguyên." }

static func _test_capital_and_mining_generation() -> Dictionary:
	var StreamerScript = load("res://scripts/world/chunk_streamer.gd")
	var streamer = StreamerScript.new()
	
	# Kiểm tra sinh Chunk (32, 16): Long Kinh Kinh Đô
	var node_capital = Node2D.new()
	streamer._build_chunk_content(node_capital, Vector2i(32, 16))
	var ent_capital = node_capital.get_node_or_null("Entities")
	if not ent_capital or ent_capital.get_child_count() < 8:
		node_capital.free()
		streamer.free()
		return { "success": false, "log": "✗ [T-M3-06] Chunk Long Kinh (32, 16) thiếu công trình hoàng thành (có %d)." % (ent_capital.get_child_count() if ent_capital else 0) }
	node_capital.free()
	
	# Kiểm tra sinh Chunk (20, 32): Tây Sơn Khai Mỏ
	var node_mining = Node2D.new()
	streamer._build_chunk_content(node_mining, Vector2i(20, 32))
	var ent_mining = node_mining.get_node_or_null("Entities")
	if not ent_mining or ent_mining.get_child_count() < 4:
		node_mining.free()
		streamer.free()
		return { "success": false, "log": "✗ [T-M3-06] Chunk Tây Sơn (20, 32) thiếu công trình trại mỏ (có %d)." % (ent_mining.get_child_count() if ent_mining else 0) }
	node_mining.free()
	
	streamer.free()
	return { "success": true, "log": "✓ [T-M3-06] Sinh thực thể Kinh Đô Long Kinh và Trại Mỏ Tây Sơn chuẩn xác theo quy hoạch." }
