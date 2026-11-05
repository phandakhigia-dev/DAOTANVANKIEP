extends RefCounted

## Test Suite: UI MiniMap & WorldMapModal (Bản đồ con & Bản đồ tổng quan Thìn Châu)
## Kiểm tra khởi tạo cảnh UI, cấu trúc nút, chuyển đổi tọa độ, mở/đóng modal và tín hiệu di chuyển nhanh.

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0

	var t1 = _test_minimap_scene_instantiation_and_structure()
	logs.append(t1.log)
	if t1.success:
		passed += 1
	else:
		failed += 1

	var t2 = _test_world_map_modal_instantiation_and_structure()
	logs.append(t2.log)
	if t2.success:
		passed += 1
	else:
		failed += 1

	var t3 = _test_world_map_modal_open_close_api()
	logs.append(t3.log)
	if t3.success:
		passed += 1
	else:
		failed += 1

	var t4 = _test_world_map_coordinate_projection_and_bounds()
	logs.append(t4.log)
	if t4.success:
		passed += 1
	else:
		failed += 1

	var t5 = _test_world_map_fast_travel_signal_and_locations()
	logs.append(t5.log)
	if t5.success:
		passed += 1
	else:
		failed += 1

	return {
		"name": "UI: MiniMap & WorldMapModal (Bản đồ Thìn Châu)",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}

static func _test_minimap_scene_instantiation_and_structure() -> Dictionary:
	var scn = load("res://scenes/ui/minimap.tscn")
	if not scn:
		return { "success": false, "log": "T-MAP-01 [FAIL]: Không thể tải cảnh minimap.tscn" }

	var mm = scn.instantiate()
	if not mm:
		return { "success": false, "log": "T-MAP-01 [FAIL]: Không thể khởi tạo instance MiniMap" }

	var map_panel = mm.get_node_or_null("MapPanel")
	var map_draw = mm.get_node_or_null("MapPanel/MapDraw")
	var title = mm.get_node_or_null("MapPanel/Title")

	if not map_panel or not map_draw or not title:
		mm.free()
		return { "success": false, "log": "T-MAP-01 [FAIL]: Thiếu node con thiết yếu trong MiniMap (MapPanel, MapDraw, Title)" }

	# Kiểm tra update vị trí player
	var test_pos = Vector2(66560, 66560)
	mm.update_player_pos(test_pos)
	if mm.player_world_pos != test_pos:
		mm.free()
		return { "success": false, "log": "T-MAP-01 [FAIL]: update_player_pos không lưu đúng tọa độ player" }

	# Kiểm tra hàm chiếu _world_to_map
	var sz = Vector2(160, 160)
	var mapped_center = mm._world_to_map(mm.VIEW_CENTER, sz)
	if (mapped_center - Vector2(80, 80)).length() > 0.01:
		mm.free()
		return { "success": false, "log": "T-MAP-01 [FAIL]: VIEW_CENTER không được ánh xạ vào tâm của minimap" }

	mm.free()
	return { "success": true, "log": "T-MAP-01 [PASS]: MiniMap khởi tạo hoàn hảo, đúng cây node, chiếu tọa độ tâm chính xác" }

static func _test_world_map_modal_instantiation_and_structure() -> Dictionary:
	var scn = load("res://scenes/ui/world_map_modal.tscn")
	if not scn:
		return { "success": false, "log": "T-MAP-02 [FAIL]: Không thể tải cảnh world_map_modal.tscn" }

	var wmap = scn.instantiate()
	if not wmap:
		return { "success": false, "log": "T-MAP-02 [FAIL]: Không thể khởi tạo instance WorldMapModal" }

	# Node tree kiểm tra
	var map_draw = wmap.get_node_or_null("BG/VBox/MapArea/MapDraw")
	var title_label = wmap.get_node_or_null("BG/VBox/TitleBar/Title")
	var close_btn = wmap.get_node_or_null("BG/VBox/TitleBar/CloseBtn")
	var tooltip_label = wmap.get_node_or_null("BG/VBox/BottomBar/Tooltip")
	var legend_label = wmap.get_node_or_null("BG/VBox/BottomBar/HBoxBottom/Legend")
	var key_hint = wmap.get_node_or_null("BG/VBox/BottomBar/HBoxBottom/KeyHint")

	if not map_draw or not title_label or not close_btn or not tooltip_label or not legend_label or not key_hint:
		wmap.free()
		return { "success": false, "log": "T-MAP-02 [FAIL]: Thiếu cấu trúc thành phần UI trong WorldMapModal" }

	wmap.free()
	return { "success": true, "log": "T-MAP-02 [PASS]: WorldMapModal cấu trúc nút VBox/BottomBar chuẩn hóa, đầy đủ title, map, tooltip, legend, keyhint" }

static func _test_world_map_modal_open_close_api() -> Dictionary:
	var scn = load("res://scenes/ui/world_map_modal.tscn")
	var wmap = scn.instantiate()

	# Khởi đầu ở trạng thái ẩn sau _ready
	wmap._ready()
	if wmap.visible:
		wmap.free()
		return { "success": false, "log": "T-MAP-03 [FAIL]: WorldMapModal phải ẩn (visible=false) khi khởi tạo" }

	# Mở bản đồ
	wmap.open_map()
	if not wmap.visible:
		wmap.free()
		return { "success": false, "log": "T-MAP-03 [FAIL]: open_map() không chuyển visible thành true" }

	# Cập nhật tọa độ
	var new_pos = Vector2(41984, 66560)
	wmap.update_player_pos(new_pos)
	if wmap.player_world_pos != new_pos:
		wmap.free()
		return { "success": false, "log": "T-MAP-03 [FAIL]: update_player_pos không cập nhật vị trí mới" }

	# Đóng bản đồ
	wmap.close_map()
	if wmap.visible:
		wmap.free()
		return { "success": false, "log": "T-MAP-03 [FAIL]: close_map() không ẩn modal" }

	wmap.free()
	return { "success": true, "log": "T-MAP-03 [PASS]: WorldMapModal API open_map/close_map hoạt động đúng trạng thái hiển thị" }

static func _test_world_map_coordinate_projection_and_bounds() -> Dictionary:
	var scn = load("res://scenes/ui/world_map_modal.tscn")
	var wmap = scn.instantiate()

	var sz = Vector2(900.0, 600.0)

	var p_thanh_tri = wmap._w2m(Vector2(66560, 66560), sz)
	var p_long_kinh = wmap._w2m(Vector2(66560, 33792), sz)
	var p_tay_son   = wmap._w2m(Vector2(41984, 66560), sz)

	# Kiểm tra tính hợp lệ về mặt không gian địa lý:
	# 1. Long Kinh ở phía Bắc của Thanh Trì -> Tọa độ Y trên màn hình phải NHỎ HƠN Thanh Trì
	if p_long_kinh.y >= p_thanh_tri.y:
		wmap.free()
		return { "success": false, "log": "T-MAP-04 [FAIL]: Long Kinh (Bắc) phải có Y nhỏ hơn Thanh Trì trên màn hình" }

	# 2. Tây Sơn ở phía Tây của Thanh Trì -> Tọa độ X trên màn hình phải NHỎ HƠN Thanh Trì
	if p_tay_son.x >= p_thanh_tri.x:
		wmap.free()
		return { "success": false, "log": "T-MAP-04 [FAIL]: Tây Sơn (Tây) phải có X nhỏ hơn Thanh Trì trên màn hình" }

	# 3. Tất cả tọa độ phải nằm trong khung hiển thị bản đồ
	if not wmap._in_bounds(p_thanh_tri, sz) or not wmap._in_bounds(p_long_kinh, sz) or not wmap._in_bounds(p_tay_son, sz):
		wmap.free()
		return { "success": false, "log": "T-MAP-04 [FAIL]: Các địa danh cốt lõi bị văng ra khỏi khung bản đồ" }

	wmap.free()
	return { "success": true, "log": "T-MAP-04 [PASS]: Phép chiếu tọa độ _w2m giữ đúng hướng địa lý phương vị (Bắc-Nam-Đông-Tây) trong khung hình" }

static func _test_world_map_fast_travel_signal_and_locations() -> Dictionary:
	var scn = load("res://scenes/ui/world_map_modal.tscn")
	var wmap = scn.instantiate()

	# Kiểm tra danh sách địa danh
	if wmap.LOCATIONS.size() < 7:
		wmap.free()
		return { "success": false, "log": "T-MAP-05 [FAIL]: Danh sách LOCATIONS quá ít địa danh (%d)" % wmap.LOCATIONS.size() }

	# Kiểm tra danh sách dịch trạm
	if wmap.STATIONS.size() < 2:
		wmap.free()
		return { "success": false, "log": "T-MAP-05 [FAIL]: Thiếu dịch trạm trong STATIONS" }

	var has_thanh_tri_st = false
	var has_long_kinh_st = false
	for st in wmap.STATIONS:
		if st.get("fast_travel_id") == "travel_to_long_kinh":
			has_thanh_tri_st = true
		elif st.get("fast_travel_id") == "travel_to_thanh_tri":
			has_long_kinh_st = true

	if not has_thanh_tri_st or not has_long_kinh_st:
		wmap.free()
		return { "success": false, "log": "T-MAP-05 [FAIL]: Dịch trạm thiếu fast_travel_id tương ứng với các tuyến xe ngựa" }

	# Kiểm tra tín hiệu map_fast_travel_requested
	var received = [""]
	wmap.map_fast_travel_requested.connect(func(dest_id): received[0] = dest_id)
	wmap.map_fast_travel_requested.emit("travel_to_long_kinh")
	if received[0] != "travel_to_long_kinh":
		wmap.free()
		return { "success": false, "log": "T-MAP-05 [FAIL]: map_fast_travel_requested không phát tín hiệu đúng" }

	wmap.free()
	return { "success": true, "log": "T-MAP-05 [PASS]: Dữ liệu địa danh, dịch trạm và tín hiệu Fast Travel đồng bộ hoàn chỉnh" }
