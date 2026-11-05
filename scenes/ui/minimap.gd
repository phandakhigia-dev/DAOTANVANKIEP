extends Control

## MiniMap — Bản đồ con góc dưới phải, bám theo tâm người chơi
## Hiển thị: Vị trí người chơi ở tâm, cảnh quan & địa danh cuộn theo bước chân, hỗ trợ Zoom In/Out, cắt tỉa viền tuyệt đối

const WORLD_SIZE := Vector2(131072.0, 131072.0)

const LANDMARKS := [
	{ "pos": Vector2(66560, 66560), "color": Color(1.0, 0.85, 0.3, 1.0),   "label": "Thanh Trì" },
	{ "pos": Vector2(66560, 33792), "color": Color(0.95, 0.4,  0.4, 1.0),   "label": "Long Kinh" },
	{ "pos": Vector2(41984, 66560), "color": Color(0.6,  0.8,  0.4, 1.0),   "label": "Tây Sơn" },
	{ "pos": Vector2(64512, 70656), "color": Color(0.6,  0.95, 0.6, 1.0),   "label": "Đồng Nội" },
	{ "pos": Vector2(68608, 66560), "color": Color(0.7,  0.7,  1.0, 1.0),   "label": "Kiếm Trũng" },
	{ "pos": Vector2(64512, 68608), "color": Color(0.5,  0.9,  0.8, 1.0),   "label": "Hắc Xà" },
	{ "pos": Vector2(66560, 62464), "color": Color(0.4,  0.9,  0.5, 1.0),   "label": "Trúc Lâm" },
]

# Tuyến quan lộ chính
const ROADS := [
	[ Vector2(66560, 71500), Vector2(66560, 33500) ],
	[ Vector2(66560, 66560), Vector2(41984, 66560) ],
	[ Vector2(66560, 66560), Vector2(64512, 70656) ],
]

# Sông Nam Giang
const RIVERS := [
	[ Vector2(25000, 70500), Vector2(42000, 69400), Vector2(66560, 68600), Vector2(92000, 70500) ],
]

# Bán kính quan sát cục bộ quanh người chơi (pixel thế giới)
var minimap_radius: float = 3500.0
const MIN_RADIUS: float = 1600.0
const MAX_RADIUS: float = 8500.0

var player_world_pos: Vector2 = Vector2(66560, 66560)

# Property tương thích với unit test
var VIEW_CENTER: Vector2:
	get: return player_world_pos

var VIEW_RADIUS: float:
	get: return minimap_radius

@onready var map_panel: Panel = $MapPanel
@onready var map_draw: Control = $MapPanel/MapDraw
@onready var label_title: Label = $MapPanel/Title
@onready var btn_zoom_in: Button = $MapPanel/BtnZoomIn if has_node("MapPanel/BtnZoomIn") else null
@onready var btn_zoom_out: Button = $MapPanel/BtnZoomOut if has_node("MapPanel/BtnZoomOut") else null

# Hằng số thuật toán cắt đoạn thẳng Cohen-Sutherland
const CODE_INSIDE: int = 0
const CODE_LEFT: int = 1
const CODE_RIGHT: int = 2
const CODE_BOTTOM: int = 4
const CODE_TOP: int = 8

func _ready() -> void:
	if map_draw:
		map_draw.draw.connect(_draw_map)
		map_draw.gui_input.connect(_on_map_gui_input)
	if btn_zoom_in:
		btn_zoom_in.pressed.connect(zoom_in)
	if btn_zoom_out:
		btn_zoom_out.pressed.connect(zoom_out)

func zoom_in() -> void:
	minimap_radius = clamp(minimap_radius * 0.8, MIN_RADIUS, MAX_RADIUS)
	if map_draw:
		map_draw.queue_redraw()

func zoom_out() -> void:
	minimap_radius = clamp(minimap_radius * 1.25, MIN_RADIUS, MAX_RADIUS)
	if map_draw:
		map_draw.queue_redraw()

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			get_viewport().set_input_as_handled()

func update_player_pos(world_pos: Vector2) -> void:
	player_world_pos = world_pos
	if map_draw:
		map_draw.queue_redraw()

func _draw_map() -> void:
	var sz = map_draw.size
	if sz.x < 10 or sz.y < 10:
		return

	var font = ThemeDB.fallback_font
	var center_px = sz * 0.5
	var map_rect = Rect2(Vector2.ZERO, sz)

	# 1. Nền bản đồ tối cổ kính
	map_draw.draw_rect(map_rect, Color(0.06, 0.08, 0.11, 0.95))

	# 2. Lưới chunk thế giới cuộn mượt mà theo bước chân (mỗi 2048 px)
	var grid_color = Color(0.24, 0.30, 0.38, 0.28)
	var chunk_px = (2048.0 / minimap_radius) * center_px.x
	if chunk_px > 4.0:
		var off_x = fposmod(player_world_pos.x, 2048.0)
		var start_x = center_px.x - (off_x / 2048.0) * chunk_px
		while start_x > 0: start_x -= chunk_px
		while start_x <= sz.x:
			map_draw.draw_line(Vector2(start_x, 0), Vector2(start_x, sz.y), grid_color, 0.5)
			start_x += chunk_px

		var off_y = fposmod(player_world_pos.y, 2048.0)
		var start_y = center_px.y - (off_y / 2048.0) * chunk_px
		while start_y > 0: start_y -= chunk_px
		while start_y <= sz.y:
			map_draw.draw_line(Vector2(0, start_y), Vector2(sz.x, start_y), grid_color, 0.5)
			start_y += chunk_px

	# 3. Vẽ sông ngòi trong tầm nhìn cục bộ (cắt tỉa chính xác trong khung bản đồ)
	for riv in RIVERS:
		for i in range(riv.size() - 1):
			var a = _world_to_map(riv[i], sz)
			var b = _world_to_map(riv[i + 1], sz)
			var clipped = _clip_line_to_rect(a, b, map_rect)
			if clipped.size() == 2:
				map_draw.draw_line(clipped[0], clipped[1], Color(0.25, 0.48, 0.78, 0.75), 3.0)

	# 4. Vẽ quan lộ trong tầm nhìn cục bộ (cắt tỉa chính xác trong khung bản đồ)
	for rd in ROADS:
		var a = _world_to_map(rd[0], sz)
		var b = _world_to_map(rd[1], sz)
		var clipped = _clip_line_to_rect(a, b, map_rect)
		if clipped.size() == 2:
			map_draw.draw_line(clipped[0], clipped[1], Color(0.72, 0.60, 0.36, 0.65), 2.0)

	# 5. Vẽ các địa danh trong tầm nhìn & Chỉ báo hướng ngoài mép
	for lm in LANDMARKS:
		var wp = lm["pos"]
		var mp = _world_to_map(wp, sz)

		if _in_bounds(mp, sz, 4):
			# Nằm trong khung nhìn minimap: vẽ điểm mốc + nhãn
			map_draw.draw_circle(mp, 4.5, lm["color"])
			map_draw.draw_circle(mp, 2.0, Color(1, 1, 1, 0.95))
			var label_str = lm["label"]
			var str_sz = font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
			map_draw.draw_string(font, mp + Vector2(-str_sz.x * 0.5, 12), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.9, 0.85, 0.7, 0.9))
		else:
			# Nằm ngoài khung nhìn: vẽ chỉ báo hướng tại viền mép bản đồ
			var dir = (wp - player_world_pos).normalized()
			var edge_pt = center_px + dir * (center_px.x - 8.0)
			edge_pt.x = clamp(edge_pt.x, 8.0, sz.x - 8.0)
			edge_pt.y = clamp(edge_pt.y, 8.0, sz.y - 8.0)
			map_draw.draw_circle(edge_pt, 3.0, lm["color"])

	# 6. Vị trí người chơi (LUÔN Ở TÂM BẢN ĐỒ)
	map_draw.draw_arc(center_px, 9.0, 0, TAU, 24, Color(0.2, 0.7, 1.0, 0.5), 1.5)
	map_draw.draw_circle(center_px, 5.0, Color(0.2, 0.75, 1.0, 0.95))
	map_draw.draw_circle(center_px, 2.0, Color(1, 1, 1, 1.0))

	# 7. Hướng Bắc [B] ở góc trên phải
	map_draw.draw_circle(Vector2(sz.x - 12, 12), 7.0, Color(0.15, 0.18, 0.22, 0.85))
	map_draw.draw_string(font, Vector2(sz.x - 16, 16), "B", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.95, 0.4, 0.3, 0.95))

	# 8. Viền đồng cổ bản đồ
	map_draw.draw_rect(map_rect, Color(0.55, 0.45, 0.28, 0.9), false, 1.5)

func _world_to_map(world_pos: Vector2, sz: Vector2) -> Vector2:
	var rel = world_pos - player_world_pos
	return sz * 0.5 + (rel / minimap_radius) * (sz.x * 0.5)

func _in_bounds(pt: Vector2, sz: Vector2, margin: float = 0) -> bool:
	return pt.x >= margin and pt.x <= sz.x - margin and pt.y >= margin and pt.y <= sz.y - margin

# Thuật toán Cohen-Sutherland cắt tỉa đoạn thẳng tuyệt đối trong hình chữ nhật r
func _compute_clip_code(p: Vector2, r: Rect2) -> int:
	var code = CODE_INSIDE
	if p.x < r.position.x:
		code |= CODE_LEFT
	elif p.x > r.end.x:
		code |= CODE_RIGHT
	if p.y < r.position.y:
		code |= CODE_TOP
	elif p.y > r.end.y:
		code |= CODE_BOTTOM
	return code

func _clip_line_to_rect(p1: Vector2, p2: Vector2, r: Rect2) -> Array[Vector2]:
	var c1 = _compute_clip_code(p1, r)
	var c2 = _compute_clip_code(p2, r)
	var accept = false
	var x1 = p1.x
	var y1 = p1.y
	var x2 = p2.x
	var y2 = p2.y

	while true:
		if (c1 | c2) == 0:
			accept = true
			break
		elif (c1 & c2) != 0:
			break
		else:
			var code_out = c1 if c1 != 0 else c2
			var x = 0.0
			var y = 0.0

			if (code_out & CODE_TOP) != 0:
				x = x1 + (x2 - x1) * (r.position.y - y1) / (y2 - y1)
				y = r.position.y
			elif (code_out & CODE_BOTTOM) != 0:
				x = x1 + (x2 - x1) * (r.end.y - y1) / (y2 - y1)
				y = r.end.y
			elif (code_out & CODE_RIGHT) != 0:
				y = y1 + (y2 - y1) * (r.end.x - x1) / (x2 - x1)
				x = r.end.x
			elif (code_out & CODE_LEFT) != 0:
				y = y1 + (y2 - y1) * (r.position.x - x1) / (x2 - x1)
				x = r.position.x

			if code_out == c1:
				x1 = x
				y1 = y
				c1 = _compute_clip_code(Vector2(x1, y1), r)
			else:
				x2 = x
				y2 = y
				c2 = _compute_clip_code(Vector2(x2, y2), r)

	if accept:
		return [Vector2(x1, y1), Vector2(x2, y2)]
	return []
