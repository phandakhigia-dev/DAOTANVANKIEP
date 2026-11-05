extends Control

## WorldMapModal — Bản đồ tổng quan Tỉnh Thìn Châu
## Hỗ trợ: Phím N để mở/đóng, Phóng to/Thu nhỏ (Zoom In/Out), Kéo chuột (Pan), chống chằng chịt theo cấp độ phóng to (LOD)

signal map_fast_travel_requested(destination_id: String)

const WORLD_SIZE := Vector2(131072.0, 131072.0)

# Tọa độ trung tâm nhìn chuẩn bao phủ Thìn Châu
const VIEW_CENTER := Vector2(60000.0, 55000.0)
const VIEW_W := 90000.0
const VIEW_H := 72000.0

# Tất cả địa danh & khu vực
const LOCATIONS := [
	{
		"id": "long_kinh",
		"pos": Vector2(66560, 33792),
		"color": Color(0.95, 0.35, 0.35, 1.0),
		"size": 13.0,
		"name": "Kinh Đô Long Kinh",
		"desc": "Hoàng cung Đại Huyền Quốc & Lục Bộ Nha Môn",
		"type": "capital",
		"is_hub": true
	},
	{
		"id": "thanh_tri",
		"pos": Vector2(66560, 66560),
		"color": Color(1.0, 0.85, 0.3, 1.0),
		"size": 10.0,
		"name": "Huyện Thành Thanh Trì",
		"desc": "Chợ Tán Tu, Phố cổ & Lò Luyện Đan",
		"type": "city",
		"is_hub": true
	},
	{
		"id": "tay_son",
		"pos": Vector2(41984, 66560),
		"color": Color(0.6, 0.82, 0.4, 1.0),
		"size": 8.0,
		"name": "Trại Mỏ Tây Sơn",
		"desc": "Mỏ Thiết Khoáng, Lò Rèn & Dân Phu",
		"type": "camp",
		"is_hub": true
	},
	{
		"id": "dong_noi",
		"pos": Vector2(64512, 70656),
		"color": Color(0.5, 0.9, 0.5, 1.0),
		"size": 7.0,
		"name": "Thôn Đồng Nội",
		"desc": "Đồng lúa phàm nhân & bến sông Nam Giang",
		"type": "village",
		"is_hub": false,
		"side": "bottom"
	},
	{
		"id": "sword_grave",
		"pos": Vector2(68608, 66560),
		"color": Color(0.75, 0.75, 1.0, 1.0),
		"size": 7.0,
		"name": "Cổ Kiếm Trũng",
		"desc": "Tàn đài táng kiếm cổ & kiếm khí tàn dư",
		"type": "dungeon",
		"is_hub": false,
		"side": "right"
	},
	{
		"id": "snake_swamp",
		"pos": Vector2(64512, 68608),
		"color": Color(0.4, 0.9, 0.8, 1.0),
		"size": 7.0,
		"name": "Độc Trạch Hắc Xà",
		"desc": "Đầm lầy độc khí, dị thú xà tộc & tế đàn cổ",
		"type": "dungeon",
		"is_hub": false,
		"side": "left"
	},
	{
		"id": "bamboo",
		"pos": Vector2(66560, 62464),
		"color": Color(0.35, 0.85, 0.5, 1.0),
		"size": 7.0,
		"name": "Rừng Trúc Vạn Lĩnh",
		"desc": "Bí Cảnh linh mộc & Thạch Động Cổ",
		"type": "biome",
		"is_hub": false,
		"side": "right"
	},
	{
		"id": "north_gate",
		"pos": Vector2(66560, 64512),
		"color": Color(0.8, 0.75, 0.55, 1.0),
		"size": 5.0,
		"name": "Bắc Môn",
		"desc": "Cổng kiểm soát Bắc Cảnh Thanh Trì",
		"type": "landmark",
		"is_hub": false,
		"hover_only": true
	},
	{
		"id": "cavern",
		"pos": Vector2(66560, 63000),
		"color": Color(0.7, 0.5, 0.9, 1.0),
		"size": 5.0,
		"name": "Thạch Động",
		"desc": "Động tiên cổ tịch, tàng trữ đan dược & linh thạch",
		"type": "dungeon",
		"is_hub": false,
		"hover_only": true
	},
]

# Dịch trạm ngựa
const STATIONS := [
	{
		"id": "st_thanh_tri",
		"pos": Vector2(66300, 66800),
		"name": "Dịch Trạm Thanh Trì",
		"desc": "Tuyến ngựa trạm tốc hành tới Long Kinh (Phí: 25 Linh Thạch • Nhấp để đi)",
		"fast_travel_id": "travel_to_long_kinh"
	},
	{
		"id": "st_long_kinh",
		"pos": Vector2(66560, 34492),
		"name": "Ngự Mã Trạm Long Kinh",
		"desc": "Tuyến xe ngựa trở về Huyện Thành Thanh Trì (Phí: 10 Linh Thạch • Nhấp để đi)",
		"fast_travel_id": "travel_to_thanh_tri"
	},
]

# Tuyến đường lớn
const ROADS := [
	{
		"name": "Bắc Nam Đại Quan Lộ",
		"pts": [ Vector2(66560, 71500), Vector2(66560, 33500) ]
	},
	{
		"name": "Đường Tây Sơn",
		"pts": [ Vector2(66560, 66560), Vector2(41984, 66560) ]
	},
	{
		"name": "Đường Đồng Nội",
		"pts": [ Vector2(66560, 66560), Vector2(64512, 70656) ]
	},
]

# Sông Nam Giang
const RIVERS := [
	{
		"name": "Sông Nam Giang",
		"pts": [ Vector2(25000, 70500), Vector2(42000, 69400), Vector2(66560, 68600), Vector2(92000, 70500) ],
		"label_pos": Vector2(78000, 69600)
	}
]

# Hệ số Zoom & Pan
var map_zoom: float = 1.0
var map_pan: Vector2 = Vector2.ZERO
const MIN_ZOOM: float = 0.85
const MAX_ZOOM: float = 3.5

var is_panning: bool = false
var pan_last_mouse: Vector2 = Vector2.ZERO

var player_world_pos: Vector2 = Vector2(66560, 66560)
var hovered_location: Dictionary = {}

@onready var map_draw: Control = $BG/VBox/MapArea/MapDraw
@onready var title_label: Label = $BG/VBox/TitleBar/Title
@onready var close_btn: Button = $BG/VBox/TitleBar/CloseBtn
@onready var tooltip_label: Label = $BG/VBox/BottomBar/Tooltip
@onready var legend_label: Label = $BG/VBox/BottomBar/HBoxBottom/Legend
@onready var key_hint: Label = $BG/VBox/BottomBar/HBoxBottom/KeyHint

@onready var btn_zoom_in: Button = $BG/VBox/TitleBar/BtnZoomIn if has_node("BG/VBox/TitleBar/BtnZoomIn") else null
@onready var btn_zoom_out: Button = $BG/VBox/TitleBar/BtnZoomOut if has_node("BG/VBox/TitleBar/BtnZoomOut") else null
@onready var btn_reset: Button = $BG/VBox/TitleBar/BtnReset if has_node("BG/VBox/TitleBar/BtnReset") else null

func _ready() -> void:
	visible = false
	if map_draw:
		map_draw.draw.connect(_draw_world_map)
		map_draw.gui_input.connect(_on_map_gui_input)
		map_draw.mouse_exited.connect(func():
			hovered_location = {}
			is_panning = false
			if tooltip_label:
				tooltip_label.text = "Rê chuột vào địa danh để xem chi tiết • Cuộn chuột để phóng to/thu nhỏ • Kéo chuột để di chuyển"
			map_draw.queue_redraw()
		)
	if close_btn:
		close_btn.pressed.connect(close_map)
	if btn_zoom_in:
		btn_zoom_in.pressed.connect(zoom_in)
	if btn_zoom_out:
		btn_zoom_out.pressed.connect(zoom_out)
	if btn_reset:
		btn_reset.pressed.connect(reset_view)

func zoom_in() -> void:
	map_zoom = clamp(map_zoom * 1.25, MIN_ZOOM, MAX_ZOOM)
	if map_draw:
		map_draw.queue_redraw()

func zoom_out() -> void:
	map_zoom = clamp(map_zoom / 1.25, MIN_ZOOM, MAX_ZOOM)
	if map_draw:
		map_draw.queue_redraw()

func reset_view() -> void:
	map_zoom = 1.0
	map_pan = Vector2.ZERO
	if map_draw:
		map_draw.queue_redraw()

func open_map() -> void:
	visible = true
	if map_draw:
		map_draw.queue_redraw()

func close_map() -> void:
	visible = false
	is_panning = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		var k = event.keycode
		var pk = event.physical_keycode
		if k == KEY_N or pk == KEY_N or k == KEY_ESCAPE:
			close_map()
			get_viewport().set_input_as_handled()
		elif k == KEY_R or pk == KEY_R:
			reset_view()
			get_viewport().set_input_as_handled()

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# Zoom hướng về con trỏ chuột
			var mouse_pos = map_draw.get_local_mouse_position()
			var center = map_draw.size * 0.5
			var old_zoom = map_zoom
			map_zoom = clamp(map_zoom * 1.2, MIN_ZOOM, MAX_ZOOM)
			var scale_change = map_zoom / old_zoom
			map_pan = (map_pan + center - mouse_pos) * scale_change - (center - mouse_pos)
			map_draw.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var mouse_pos = map_draw.get_local_mouse_position()
			var center = map_draw.size * 0.5
			var old_zoom = map_zoom
			map_zoom = clamp(map_zoom / 1.2, MIN_ZOOM, MAX_ZOOM)
			var scale_change = map_zoom / old_zoom
			map_pan = (map_pan + center - mouse_pos) * scale_change - (center - mouse_pos)
			map_draw.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_panning = true
				pan_last_mouse = event.position
				# Nhấp chuột kích hoạt fast travel nếu bấm trúng trạm
				if not hovered_location.is_empty() and hovered_location.has("fast_travel_id"):
					map_fast_travel_requested.emit(hovered_location["fast_travel_id"])
					close_map()
			else:
				is_panning = false
	elif event is InputEventMouseMotion:
		if is_panning:
			map_pan += event.relative
		map_draw.queue_redraw()

func _draw_world_map() -> void:
	var sz = map_draw.size
	if sz.x < 20 or sz.y < 20:
		return

	var font = ThemeDB.fallback_font

	# 1. Nền bản đồ phong cách thư tịch cổ
	map_draw.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.08, 0.07, 0.05, 1.0))
	map_draw.draw_rect(Rect2(Vector2(2, 2), sz - Vector2(4, 4)), Color(0.14, 0.12, 0.08, 0.98))

	# 2. Lưới kinh vĩ cổ phong (co giãn theo zoom & pan)
	var gc = Color(0.32, 0.28, 0.18, 0.18)
	var gstep_x = (sz.x / 10.0) * map_zoom
	var gstep_y = (sz.y / 10.0) * map_zoom
	if gstep_x > 5.0 and gstep_y > 5.0:
		var off_x = fposmod(map_pan.x, gstep_x)
		var gx = off_x
		while gx <= sz.x:
			map_draw.draw_line(Vector2(gx, 0), Vector2(gx, sz.y), gc, 0.5)
			gx += gstep_x
		var off_y = fposmod(map_pan.y, gstep_y)
		var gy = off_y
		while gy <= sz.y:
			map_draw.draw_line(Vector2(0, gy), Vector2(sz.x, gy), gc, 0.5)
			gy += gstep_y

	# 3. Phương vị tứ hải (cố định ở 4 mép)
	map_draw.draw_string(font, Vector2(sz.x * 0.5 - 12, 20), "BẮC", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.9, 0.45, 0.35, 0.85))
	map_draw.draw_string(font, Vector2(sz.x * 0.5 - 12, sz.y - 8), "NAM", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.75, 0.7, 0.55, 0.8))
	map_draw.draw_string(font, Vector2(10, sz.y * 0.5 + 4), "TÂY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.7, 0.55, 0.8))
	map_draw.draw_string(font, Vector2(sz.x - 34, sz.y * 0.5 + 4), "ĐÔNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.7, 0.55, 0.8))

	# 4. Vẽ sông ngòi
	for riv in RIVERS:
		var pts: PackedVector2Array = PackedVector2Array()
		for wp in riv["pts"]:
			pts.append(_w2m(wp, sz))
		map_draw.draw_polyline(pts, Color(0.25, 0.48, 0.78, 0.8), clamp(3.0 * map_zoom, 2.0, 6.0))
		if riv.has("label_pos"):
			var riv_lbl_pt = _w2m(riv["label_pos"], sz) + Vector2(-45, -6)
			if _in_bounds(riv_lbl_pt, sz, 30):
				map_draw.draw_string(font, riv_lbl_pt, "≈ %s ≈" % riv["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.72, 0.96, 0.85))

	# 5. Vẽ đường sá quan lộ
	for rd in ROADS:
		var a = _w2m(rd["pts"][0], sz)
		var b = _w2m(rd["pts"][1], sz)
		map_draw.draw_line(a, b, Color(0.72, 0.60, 0.36, 0.65), clamp(1.8 * map_zoom, 1.2, 4.0))
		for t in [0.25, 0.5, 0.75]:
			var pt = a.lerp(b, t)
			if _in_bounds(pt, sz, 10):
				map_draw.draw_circle(pt, 1.5 * clamp(map_zoom, 0.9, 2.0), Color(0.85, 0.75, 0.5, 0.75))

	# 6. Kiểm tra chuột hover
	var mouse_mp = map_draw.get_local_mouse_position()
	hovered_location = {}

	# 7. Vẽ dịch trạm ngựa (ngôi sao vàng ★)
	for st in STATIONS:
		var mp = _w2m(st["pos"], sz)
		if _in_bounds(mp, sz, 20):
			var is_h = mp.distance_to(mouse_mp) < 14.0
			if is_h:
				hovered_location = st
				map_draw.draw_arc(mp, 13.0, 0, TAU, 24, Color(1, 0.9, 0.4, 0.95), 2.0)
			var box_r = 5.0 * clamp(map_zoom, 0.9, 1.6)
			map_draw.draw_rect(Rect2(mp - Vector2(box_r, box_r), Vector2(box_r * 2, box_r * 2)), Color(0.95, 0.78, 0.2, 0.95))
			map_draw.draw_rect(Rect2(mp - Vector2(box_r, box_r), Vector2(box_r * 2, box_r * 2)), Color(1, 1, 1, 0.95), false, 1.0)
			map_draw.draw_string(font, mp + Vector2(-3, 4), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.1, 0.1, 0.1, 1.0))
			# Chỉ vẽ nhãn chữ trạm khi zoom đủ sâu hoặc hover
			if map_zoom >= 1.6 or is_h:
				map_draw.draw_string(font, mp + Vector2(10, 4), st["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.6, 0.9))

	# 8. Vẽ các địa danh theo cấp độ chi tiết (LOD Anti-Clutter)
	var is_zoomed_in = (map_zoom >= 1.35)

	for loc in LOCATIONS:
		var mp = _w2m(loc["pos"], sz)
		if not _in_bounds(mp, sz, 30):
			continue
		var r = loc["size"] * clamp(map_zoom, 0.85, 1.8)
		var is_hovered = mp.distance_to(mouse_mp) < r + 10.0
		if is_hovered:
			hovered_location = loc

		match loc["type"]:
			"capital":
				map_draw.draw_circle(mp, r + 4.0, Color(loc["color"].r, loc["color"].g, loc["color"].b, 0.25))
				map_draw.draw_circle(mp, r, loc["color"])
				map_draw.draw_circle(mp, r * 0.45, Color(1, 1, 1, 0.95))
				if is_hovered:
					map_draw.draw_arc(mp, r + 6, 0, TAU, 32, Color(1, 0.9, 0.4, 1.0), 2.0)
			"city":
				map_draw.draw_circle(mp, r + 3.0, Color(loc["color"].r, loc["color"].g, loc["color"].b, 0.25))
				map_draw.draw_circle(mp, r, loc["color"])
				map_draw.draw_circle(mp, r * 0.35, Color(1, 1, 1, 0.9))
				if is_hovered:
					map_draw.draw_arc(mp, r + 5, 0, TAU, 32, Color(1, 0.9, 0.4, 1.0), 2.0)
			"dungeon":
				var pts = PackedVector2Array([
					mp + Vector2(0, -r),
					mp + Vector2(r, 0),
					mp + Vector2(0, r),
					mp + Vector2(-r, 0)
				])
				map_draw.draw_colored_polygon(pts, loc["color"])
				if is_hovered:
					map_draw.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1, 1, 1, 0.9), 2.0)
			_:
				map_draw.draw_circle(mp, r, loc["color"])
				if is_hovered:
					map_draw.draw_arc(mp, r + 4, 0, TAU, 24, Color(1, 1, 1, 0.9), 1.5)

		# QUY TẮC CHỐNG CHẰNG CHỊT (LOD):
		var should_draw_label = false
		if loc.get("hover_only", false):
			should_draw_label = is_hovered
		elif loc.get("is_hub", false):
			should_draw_label = true
		else:
			should_draw_label = is_zoomed_in or is_hovered

		if should_draw_label:
			var str_sz = font.get_string_size(loc["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
			var side = loc.get("side", "bottom")
			var text_pos = mp
			if side == "right":
				text_pos = mp + Vector2(r + 8.0, 4.0)
			elif side == "left":
				text_pos = mp + Vector2(-str_sz.x - r - 8.0, 4.0)
			elif side == "top":
				text_pos = mp + Vector2(-str_sz.x * 0.5, -r - 12.0)
			else: # bottom
				text_pos = mp + Vector2(-str_sz.x * 0.5, r + 15.0)

			var text_color = Color(1.0, 0.88, 0.4, 1.0) if loc["type"] == "capital" else (Color(0.95, 0.9, 0.75, 1.0) if loc["type"] == "city" else Color(0.85, 0.82, 0.75, 0.9))
			map_draw.draw_string(font, text_pos, loc["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, text_color)

	# 9. Vị trí người chơi (ngọn lửa xanh lam nổi bật)
	var player_mp = _w2m(player_world_pos, sz)
	if _in_bounds(player_mp, sz, 10):
		var pr = 7.5 * clamp(map_zoom, 0.9, 1.6)
		map_draw.draw_circle(player_mp, pr, Color(0.2, 0.65, 1.0, 0.95))
		map_draw.draw_circle(player_mp, pr * 0.45, Color(1.0, 1.0, 1.0, 1.0))
		map_draw.draw_arc(player_mp, pr + 4.0, 0, TAU, 32, Color(0.4, 0.8, 1.0, 0.7), 1.5)
		map_draw.draw_string(font, player_mp + Vector2(-15, -12), "(Bạn)", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.85, 1.0, 1.0))

	# 10. Viền đồng cổ bản đồ
	map_draw.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.6, 0.5, 0.28, 0.95), false, 2.0)

	# 11. Cập nhật Tooltip Label
	if tooltip_label:
		if not hovered_location.is_empty():
			var loc_name = hovered_location.get("name", "")
			var loc_desc = hovered_location.get("desc", "")
			tooltip_label.text = "【%s】 — %s" % [loc_name, loc_desc]
		else:
			var zoom_pct = int(map_zoom * 100)
			tooltip_label.text = "Tỷ lệ phóng to: %d%% • Cuộn chuột để Zoom • Kéo chuột để Di chuyển • Rê chuột vào địa danh để xem chi tiết" % zoom_pct

func _w2m(world_pos: Vector2, sz: Vector2) -> Vector2:
	var rel = world_pos - VIEW_CENTER
	var base_mp = Vector2(
		sz.x * 0.5 + (rel.x / VIEW_W) * sz.x,
		sz.y * 0.5 + (rel.y / VIEW_H) * sz.y
	)
	var center = sz * 0.5
	return (base_mp - center) * map_zoom + center + map_pan

func _in_bounds(pt: Vector2, sz: Vector2, margin: float = 0) -> bool:
	return pt.x >= -margin and pt.x <= sz.x + margin and pt.y >= -margin and pt.y <= sz.y + margin

func update_player_pos(world_pos: Vector2) -> void:
	player_world_pos = world_pos
	if visible and map_draw:
		map_draw.queue_redraw()
