#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Updater for Gate S1: Fun-to-move & Interact
1. Updates scenes/world/player.gd:
   - Smooth 8-direction movement without input stacking
   - Qinggong dash: Space key edge detection (no continuous spam)
   - Visual dash qi trail in _draw()
2. Updates scripts/world/chunk_streamer.gd:
   - Preload SignpostScene
   - Build 16-chunk (256x256 tile) Thanh Trì core layout with all 6 sub-zones
   - Branching road network connecting all sub-zones
   - Signposts at key intersections
3. Updates scenes/world/province_world.gd:
   - Exact coordinates for 6 sub-zones
   - Signpost interactions and directions
   - Cổ Đạo Quán meditation, Mỏ Tây Hốc mining, Đồng Nội farming
"""

from pathlib import Path

BLUEPRINT = Path(__file__).resolve().parent.parent

def update_player():
    p = BLUEPRINT / "scenes" / "world" / "player.gd"
    content = p.read_text(encoding="utf-8")
    
    # 1. Add _space_was_down variable
    if "var _space_was_down: bool" not in content:
        content = content.replace(
            "var qinggong_dir: Vector2 = Vector2.DOWN",
            "var qinggong_dir: Vector2 = Vector2.DOWN\nvar _space_was_down: bool = false"
        )
        
    # 2. Update movement and qinggong in _physics_process
    old_input = """	var input_vec = Vector2.ZERO
	
	# 1. Trục InputMap (WASD hoặc Phím mũi tên đã cấu hình)
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	
	# 2. Dự phòng trực tiếp trục UI (Mũi tên mặc định của Godot)
	if is_zero_approx(input_vec.x):
		input_vec.x = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(input_vec.y):
		input_vec.y = Input.get_axis("ui_up", "ui_down")
	
	# 3. Quét phím vật lý thô (Physical Scancodes) — Miễn nhiễm 100% với Unikey/Telex/EVKey
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vec.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vec.y += 1.0"""

    new_input = """	var input_vec = Vector2.ZERO
	
	# 1. Trục InputMap (WASD hoặc Phím mũi tên đã cấu hình)
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	
	# 2. Dự phòng trực tiếp trục UI (Mũi tên mặc định của Godot)
	if is_zero_approx(input_vec.x):
		input_vec.x = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(input_vec.y):
		input_vec.y = Input.get_axis("ui_up", "ui_down")
	
	# 3. Quét phím vật lý thô (Physical Scancodes) — Chỉ bù đắp nếu chưa nhận được trục
	var raw_phys_x = 0.0
	var raw_phys_y = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		raw_phys_x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		raw_phys_x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		raw_phys_y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		raw_phys_y += 1.0
		
	if is_zero_approx(input_vec.x):
		input_vec.x = raw_phys_x
	if is_zero_approx(input_vec.y):
		input_vec.y = raw_phys_y
		
	input_vec.x = clampf(input_vec.x, -1.0, 1.0)
	input_vec.y = clampf(input_vec.y, -1.0, 1.0)"""
    content = content.replace(old_input, new_input)

    # 3. Update Qinggong edge detection
    old_space = """	else:
		var space_pressed = (
			Input.is_action_just_pressed("qinggong") if InputMap.has_action("qinggong")
			else (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE))
		)
		if space_pressed and qinggong_cd <= 0.0:
			is_qinggong = true
			qinggong_timer = 0.22"""

    new_space = """	else:
		var space_is_down = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE) or (InputMap.has_action("qinggong") and Input.is_action_pressed("qinggong"))
		var space_just_pressed = (InputMap.has_action("qinggong") and Input.is_action_just_pressed("qinggong")) or (space_is_down and not _space_was_down)
		_space_was_down = space_is_down
		
		if space_just_pressed and qinggong_cd <= 0.0:
			is_qinggong = true
			qinggong_timer = 0.22"""
    content = content.replace(old_space, new_space)

    # 4. Add Qi trail in _draw()
    if "if is_qinggong:" not in content:
        target_draw = """func _draw() -> void:
	# 1. Bóng đổ mặt đất tinh tế cho nhân vật tại chân
	draw_ellipse_shadow(Vector2(0, 0), 14.0, 6.0, Color(0, 0, 0, 0.35))"""
        repl_draw = """func _draw() -> void:
	# 1. Bóng đổ mặt đất tinh tế cho nhân vật tại chân
	draw_ellipse_shadow(Vector2(0, 0), 14.0, 6.0, Color(0, 0, 0, 0.35))
	
	# Vệt khí lướt gió khi thi triển Khinh Công
	if is_qinggong:
		var trail_offset = -qinggong_dir * 18.0
		draw_circle(trail_offset, 10.0, Color(0.4, 0.8, 1.0, 0.35))
		draw_circle(trail_offset * 1.8, 6.0, Color(0.6, 0.9, 1.0, 0.2))"""
        content = content.replace(target_draw, repl_draw)

    p.write_text(content, encoding="utf-8")
    print("✓ Updated scenes/world/player.gd (Movement & Qinggong)")

def update_chunk_streamer():
    p = BLUEPRINT / "scripts" / "world" / "chunk_streamer.gd"
    content = p.read_text(encoding="utf-8")
    
    # 1. Preload SignpostScene
    if "SignpostScene" not in content:
        content = content.replace(
            'const StoneLanternScene = preload("res://wuxia/32/props/town/stone_lantern.tscn")',
            'const StoneLanternScene = preload("res://wuxia/32/props/town/stone_lantern.tscn")\nconst SignpostScene = preload("res://wuxia/32/props/town/signpost.tscn")'
        )
        
    # 2. Update chunk content routing in _build_chunk_content
    old_routing = """	# === LÕI ĐỊA HÌNH 512x512 TILE & CÁC TRỌNG TRẤN QUAN TRỌNG ===
	if coord.x == 32 and coord.y == 32:
		# CHUNK (32, 32): HUYỆN THÀNH THANH TRÌ — TRUNG TÂM GIAO THƯƠNG
		_populate_thanh_tri_settlement(entities_layer)
	elif coord.x == 32 and coord.y == 16:
		# CHUNK (32, 16): KINH ĐÔ LONG KINH — HOÀNG CUNG & LỤC BỘ
		_populate_long_kinh_capital(entities_layer)
	elif coord.x == 20 and coord.y == 32:
		# CHUNK (20, 32): TRẠI KHOÁNG MỎ TÂY SƠN & THỢ KHAI ĐÁ
		_populate_tay_son_mining(entities_layer)
	elif coord.x == 32 and coord.y == 31:
		# CHUNK (32, 31): KHU BẮC MÔN VÀ LÂM ĐẠO
		_populate_north_gate_and_road(entities_layer)
	elif coord.x == 32 and coord.y == 30:
		# CHUNK (32, 30): BÍ CẢNH RỪNG TRÚC VẠN LĨNH & THẠCH ĐỘNG
		_populate_bamboo_forest_biome(entities_layer)
	elif coord.x == 31 and coord.y == 33:
		# CHUNK (31, 33): ĐỘC TRẠCH HẮC XÀ & TẾ ĐÀN
		_populate_snake_swamp_biome(entities_layer)
	elif coord.x == 33 and coord.y == 32:
		# CHUNK (33, 32): CỔ KIẾM TRŨNG & CỰ KIẾM TÀN ĐÀI
		_populate_sword_grave_biome(entities_layer)
	elif coord.x == 31 and coord.y == 34:
		# CHUNK (31, 34): THÔN ĐỒNG NỘI — RUỘNG LÚA & NHÀ TRANH
		_populate_dong_noi_village(entities_layer)
	else:
		# CÁC CHUNK TỰ NHIÊN NGOẠI VI (SINH THỦ TỤC DỰA TRÊN SEED)
		_populate_wilderness_chunk(entities_layer, coord)"""

    new_routing = """	# === LÕI ĐỊA HÌNH 256x256 TILE THANH TRÌ (16 CHUNKS) & 6 TIỂU VÙNG CỐT LÕI ===
	if coord.x == 32 and coord.y == 32:
		# TIỂU VÙNG 1: HUYỆN THÀNH THANH TRÌ — PHỐ CHỢ, DƯỢC QUÁN, LÒ RÈN, QUÁN TRỌ
		_populate_thanh_tri_settlement(entities_layer)
	elif coord.x == 32 and coord.y == 31:
		# BẮC QUAN LỘ & CỔNG BẮC THANH TRÌ
		_populate_north_gate_and_road(entities_layer)
	elif coord.x == 32 and coord.y == 30:
		# TIỂU VÙNG 3 & 6: RỪNG TRÚC VẠN LĨNH & CỔ ĐỘNG (THẠCH ĐỘNG)
		_populate_bamboo_forest_biome(entities_layer)
	elif coord.x == 30 and coord.y == 32:
		# TIỂU VÙNG 4: MỎ TÂY HỐC — TRẠI KHAI KHOÁNG & LÁN THỢ MỎ (TRONG BÁN KÍNH 35S)
		_populate_tay_hoc_mining_core(entities_layer)
	elif coord.x == 31 and coord.y == 32:
		# TÂY QUAN LỘ & CẦU GỖ NGOẠI Ô (NỐI THANH TRÌ VÀI MỎ TÂY HỐC)
		_populate_west_road_and_bridge(entities_layer)
	elif coord.x == 33 and coord.y == 31:
		# TIỂU VÙNG 5: CỔ ĐẠO QUÁN — THANH HƯ ĐẠO QUÁN & NƠI TĨNH TỌA NGỘ ĐẠO
		_populate_daoist_shrine_biome(entities_layer)
	elif coord.x == 33 and coord.y == 32:
		# CỔ KIẾM TRŨNG & CỰ KIẾM TÀN ĐÀI
		_populate_sword_grave_biome(entities_layer)
	elif coord.x == 31 and coord.y == 33:
		# ĐỘC TRẠCH HẮC XÀ & TẾ ĐÀN
		_populate_snake_swamp_biome(entities_layer)
	elif coord.x == 32 and coord.y == 33:
		# CỔNG NAM & LỐI VÀO NAM THÔN ĐỒNG NỘI
		_populate_south_gate_dong_noi_approach(entities_layer)
	elif coord.x == 31 and coord.y == 34:
		# TIỂU VÙNG 2: THÔN ĐỒNG NỘI — NÔNG TRANG, RUỘNG LÚA & NHÀ TRANH
		_populate_dong_noi_village(entities_layer)
	elif coord.x == 32 and coord.y == 16:
		# KINH ĐÔ LONG KINH
		_populate_long_kinh_capital(entities_layer)
	elif coord.x == 20 and coord.y == 32:
		# TÂY SƠN XA
		_populate_tay_son_mining(entities_layer)
	else:
		# CÁC CHUNK TỰ NHIÊN NGOẠI VI TRONG LÕI 256x256 (KHÔNG ĐỂ TRỐNG)
		_populate_wilderness_chunk(entities_layer, coord)"""
    content = content.replace(old_routing, new_routing)

    # 3. Add helper functions for sub-zones and signposts
    new_methods = """
func _populate_tay_hoc_mining_core(parent: Node2D) -> void:
	# Cự Thạch Khai Khoáng Mỏ Tây Hốc
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 900))
	_spawn_instance(SignpostScene, parent, Vector2(1100, 1024))
	
	# Thiết Tượng Phác Lò Rèn Dã Chiến
	_spawn_instance(BlacksmithScene, parent, Vector2(1280, 1100))
	
	# Lán Trại Thợ Mỏ
	_spawn_instance(CourtyardHouseScene, parent, Vector2(750, 1100))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(750, 1340))
	
	# Đèn đá và tùng cổ thụ vách đá
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1100))
	_spawn_instance(AncientPineScene, parent, Vector2(600, 800))
	_spawn_instance(AncientPineScene, parent, Vector2(1400, 800))

func _populate_west_road_and_bridge(parent: Node2D) -> void:
	# Cây tùng bên đường
	_spawn_instance(AncientPineScene, parent, Vector2(850, 850))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 1200))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 960))
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1088))

func _populate_daoist_shrine_biome(parent: Node2D) -> void:
	# Thanh Hư Đạo Quán (Điện thờ Đạo Giáo)
	_spawn_instance(SectPalaceScene, parent, Vector2(1024, 750))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 1150))
	_spawn_instance(MoonlightPavilionScene, parent, Vector2(1380, 1024))
	
	# Tùng bách vây quanh đạo quán thanh tịnh
	_spawn_instance(AncientPineScene, parent, Vector2(850, 720))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 720))
	_spawn_instance(AncientPineScene, parent, Vector2(700, 1100))
	_spawn_instance(AncientPineScene, parent, Vector2(1340, 1250))
	
	# Đèn đá trang nghiêm trước đạo quán
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 1100))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 1100))

func _populate_south_gate_dong_noi_approach(parent: Node2D) -> void:
	# Cổng Tam Quan Ngoại Thành
	_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 400))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 700))
	_spawn_instance(AncientPineScene, parent, Vector2(850, 420))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 420))
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 760))
"""
    content = content.replace("func _populate_wilderness_chunk", new_methods + "\nfunc _populate_wilderness_chunk")

    # 4. Add Signpost in Thanh Trì, North Gate, Bamboo Forest
    content = content.replace(
        '_spawn_instance(WellScene, parent, Vector2(1024, 1024))\n\t_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1100))',
        '_spawn_instance(WellScene, parent, Vector2(1024, 1024))\n\t_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1100))\n\t_spawn_instance(SignpostScene, parent, Vector2(1024, 1160))'
    )
    content = content.replace(
        '_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 1800))\n\t_spawn_instance(AncientPineScene, parent, Vector2(880, 1780))',
        '_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 1800))\n\t_spawn_instance(SignpostScene, parent, Vector2(1024, 1200))\n\t_spawn_instance(AncientPineScene, parent, Vector2(880, 1780))'
    )
    content = content.replace(
        '_spawn_instance(CavernEntranceScene, parent, Vector2(1024, 800))\n\t_spawn_instance(AncientPineScene, parent, Vector2(880, 780))',
        '_spawn_instance(CavernEntranceScene, parent, Vector2(1024, 800))\n\t_spawn_instance(SignpostScene, parent, Vector2(1024, 950))\n\t_spawn_instance(AncientPineScene, parent, Vector2(880, 780))'
    )

    p.write_text(content, encoding="utf-8")
    print("✓ Updated scripts/world/chunk_streamer.gd (16-chunk grid & sub-zones)")

def update_province_world():
    p = BLUEPRINT / "scenes" / "world" / "province_world.gd"
    content = p.read_text(encoding="utf-8")
    
    # 1. Update coordinates
    old_coords = """# Vị trí trung tâm các phân vùng trọng điểm trong Thìn Châu:
const THANH_TRI_CENTER = Vector2(66560, 66560) # Chunk (32, 32)
const THANH_TRI_SPAWN = Vector2(66560, 66660)  # Quảng trường lộ thiên Nam Giếng Cổ (Tránh đè giếng & NPC)
const LONG_KINH_CENTER = Vector2(66560, 33792) # Chunk (32, 16)
const TAY_SON_CENTER = Vector2(41984, 66560)   # Chunk (20, 32)
const DONG_NOI_CENTER = Vector2(64512, 70656)  # Chunk (31, 34)"""

    new_coords = """# Vị trí trung tâm 6 phân vùng trọng điểm trong Thanh Trì Huyện (256x256 tile slice):
const THANH_TRI_CENTER = Vector2(66560, 66560) # Chunk (32, 32) — Phố Chợ & Thị Tứ
const THANH_TRI_SPAWN = Vector2(66560, 66660)  # Quảng trường Nam Giếng Cổ
const TAY_HOC_CENTER = Vector2(62464, 66560)   # Chunk (30, 32) — Mỏ Tây Hốc (Cận Tây, 35s di chuyển)
const DAO_QUAN_CENTER = Vector2(68608, 64512)  # Chunk (33, 31) — Thanh Hư Đạo Quán (Đông Bắc)
const BAMBOO_CAVERN_CENTER = Vector2(66560, 62200) # Chunk (32, 30) — Rừng Trúc & Cổ Động (Bắc)
const DONG_NOI_CENTER = Vector2(64512, 70656)  # Chunk (31, 34) — Thôn Đồng Nội (Nam)
const LONG_KINH_CENTER = Vector2(66560, 33792) # Chunk (32, 16) — Kinh Đô Xa"""
    content = content.replace(old_coords, new_coords)

    # 2. Update HUD location banner
    old_loc_check = """	if dist_to_thanh_tri < 900.0:
		label_location.text = "Huyện Thành Thanh Trì • Chợ Tán Tu"
	elif dist_to_long_kinh < 1200.0:
		label_location.text = "Kinh Đô Long Kinh • Hoàng Cung & Lục Bộ"
	elif dist_to_tay_son < 1000.0:
		label_location.text = "Tây Sơn • Trại Khai Khoáng & Thợ Mỏ"
	elif dist_to_dong_noi < 800.0:
		label_location.text = "Đồng Nội • Nông Trang Phàm Nhân"
	elif p_pos.y < THANH_TRI_CENTER.y - 1200.0:
		label_location.text = "Bắc Lâm • Bí Cảnh Rừng Trúc Vạn Lĩnh"
	elif p_pos.x < THANH_TRI_CENTER.x - 1200.0 and p_pos.y > THANH_TRI_CENTER.y + 600.0:
		label_location.text = "Nam Đầm • Độc Trạch Hắc Xà"
	elif p_pos.x > THANH_TRI_CENTER.x + 1200.0:
		label_location.text = "Đông Cốc • Cổ Kiếm Trũng"
	else:
		label_location.text = "Quan Lộ Thìn Châu • Ngoại Ô\""""

    new_loc_check = """	if dist_to_thanh_tri < 900.0:
		label_location.text = "Huyện Thành Thanh Trì • Chợ Tán Tu & Nha Môn"
	elif p_pos.distance_to(DAO_QUAN_CENTER) < 800.0:
		label_location.text = "Thanh Hư Đạo Quán • Nơi Tu Hành Tĩnh Tọa"
	elif p_pos.distance_to(TAY_HOC_CENTER) < 900.0:
		label_location.text = "Tây Hốc • Trại Khai Khoáng & Thợ Mỏ"
	elif dist_to_dong_noi < 800.0 or p_pos.distance_to(Vector2(66560, 68600)) < 700.0:
		label_location.text = "Đồng Nội • Nông Trang & Ruộng Lúa Phàm Nhân"
	elif dist_to_long_kinh < 1200.0:
		label_location.text = "Kinh Đô Long Kinh • Hoàng Cung & Lục Bộ"
	elif p_pos.distance_to(BAMBOO_CAVERN_CENTER) < 900.0:
		label_location.text = "Bắc Lâm • Rừng Trúc Vạn Lĩnh & Thạch Động Cổ"
	elif p_pos.x < THANH_TRI_CENTER.x - 1200.0 and p_pos.y > THANH_TRI_CENTER.y + 600.0:
		label_location.text = "Nam Đầm • Độc Trạch Hắc Xà"
	elif p_pos.x > THANH_TRI_CENTER.x + 1200.0:
		label_location.text = "Đông Cốc • Cổ Kiếm Trũng"
	else:
		label_location.text = "Quan Lộ Thìn Châu • Ngoại Ô\""""
    content = content.replace(old_loc_check, new_loc_check)

    # 3. Add Signpost & Sub-zone proximity checks
    signpost_checks = """
	# === 1.5. BIỂN CHỈ ĐƯỜNG & MỐC ĐỊA HÌNH QUAN LỘ ===
	# Biển Chỉ Dẫn Trung Tâm Thanh Trì
	var sp_center_pos = THANH_TRI_CENTER + Vector2(0, 100)
	if nearby_action == "" and p_pos.distance_to(sp_center_pos) < 90.0:
		nearby_action = "signpost_center"
		prompt_text = "[E: Biển Chỉ Dẫn • ↑ Bắc: Rừng Trúc | ← Tây: Mỏ Tây Hốc | → Đông: Đạo Quán | ↓ Nam: Đồng Nội]"

	# Biển Chỉ Dẫn Bắc Quan Lộ
	var sp_north_pos = Vector2(66560, 64736)
	if nearby_action == "" and p_pos.distance_to(sp_north_pos) < 90.0:
		nearby_action = "signpost_north"
		prompt_text = "[E: Biển Chỉ Dẫn • ↑ Rừng Trúc Vạn Lĩnh (15s) | → Đông Bắc: Cổ Đạo Quán (20s) | ↓ Thanh Trì]"

	# Biển Chỉ Dẫn Mỏ Tây Hốc
	var sp_west_pos = Vector2(62540, 66560)
	if nearby_action == "" and p_pos.distance_to(sp_west_pos) < 90.0:
		nearby_action = "signpost_west"
		prompt_text = "[E: Biển Chỉ Dẫn • ← Trại Mỏ Tây Hốc (Khai Khoáng) | → Trở Về Thanh Trì Huyện (35s)]"

	# Biển Chỉ Dẫn Cổ Đạo Quán
	var sp_dao_pos = DAO_QUAN_CENTER + Vector2(0, 120)
	if nearby_action == "" and p_pos.distance_to(sp_dao_pos) < 90.0:
		nearby_action = "signpost_daoist"
		prompt_text = "[E: Biển Chỉ Dẫn • Cổ Đạo Quán Thanh Hư • Nơi Tu Hành Tĩnh Tọa & Vấn Đạo]"

	# Điểm Tĩnh Tọa Cổ Đạo Quán
	if nearby_action == "" and p_pos.distance_to(DAO_QUAN_CENTER) < 90.0:
		nearby_action = "daoist_meditation"
		prompt_text = "[E: Bồ Đoàn Tĩnh Tọa • Vận Khí Chu Thiên Tĩnh Tâm (+15 Khí Huyết, +25 Tu Vi)]"

	# Điểm Khai Thác Mỏ Tây Hốc (Lõi 256x256)
	if nearby_action == "" and p_pos.distance_to(TAY_HOC_CENTER) < 100.0:
		nearby_action = "mine_tay_hoc"
		prompt_text = "[E: Mỏ Khoáng Tây Hốc • Khai Thác Khoáng Thạch & Sắt Thép (+Nguyên Liệu)]"

	# Điểm Chăm Sóc Ruộng Lúa Đồng Nội
	if nearby_action == "" and p_pos.distance_to(DONG_NOI_CENTER) < 100.0:
		nearby_action = "farm_dong_noi"
		prompt_text = "[E: Nông Trang Đồng Nội • Kiểm Tra Mùa Vụ Lúa Nước & Thu Hoạch Lương Thực]"
"""
    content = content.replace(
		"	# === 2. CỔNG THÀNH TRÌ & TRẠM GÁC LIÊN THÔNG ===",
		signpost_checks + "\n	# === 2. CỔNG THÀNH TRÌ & TRẠM GÁC LIÊN THÔNG ==="
	)

    # 4. Add action execution cases
    new_actions = """
		# --- BIỂN CHỈ ĐƯỜNG & TIỂU VÙNG vertical slice ---
		"signpost_center":
			if EventBus:
				EventBus.notification_requested.emit("Biển Chỉ Dẫn: ↑ Bắc (Rừng Trúc 25s) | ← Tây (Mỏ Tây Hốc 35s) | → Đông (Cổ Đạo Quán 30s) | ↓ Nam (Đồng Nội 20s)", "info")
		"signpost_north":
			if EventBus:
				EventBus.notification_requested.emit("Mốc Bắc Quan Lộ: ↑ Rừng Trúc Vạn Lĩnh & Thạch Động | → Lối rẽ Cổ Đạo Quán Thanh Hư", "info")
		"signpost_west":
			if EventBus:
				EventBus.notification_requested.emit("Mốc Tây Quan Lộ: ← Trại Mỏ Tây Hốc (Lò rèn, khoáng sản) | → Trở về Huyện Thành Thanh Trì", "info")
		"signpost_daoist":
			if EventBus:
				EventBus.notification_requested.emit("Thanh Hư Cổ Quán: Đạo pháp tự nhiên, bồ đoàn tĩnh tọa ngộ đạo, tiếp cận đan đạo sơ khởi.", "info")
		"daoist_meditation":
			if GameSession:
				GameSession.heal_player(15)
				GameSession.add_cultivation(25)
				if EventBus:
					EventBus.notification_requested.emit("Tĩnh tọa trước Cổ Đạo Quán: Tâm thần thanh tịnh, +15 Khí Huyết, +25 Tu Vi!", "success")
		"mine_tay_hoc":
			if GameSession:
				GameSession.add_item("item_linh_thach", 20)
				GameSession.add_cultivation(15)
				if EventBus:
					EventBus.notification_requested.emit("Khai khoáng Tây Hốc: Đào được 20 Linh Thạch và quặng khoáng sản!", "success")
		"farm_dong_noi":
			if GameSession:
				GameSession.add_cultivation(10)
				if EventBus:
					EventBus.notification_requested.emit("Chăm sóc đồng nội: Thóc lúa xanh tốt, nhận +10 Tu Vi thể nghiệm hồng trần!", "success")
"""
    content = content.replace('		# --- CỔNG THÀNH TRÌ ---', new_actions + '\n		# --- CỔNG THÀNH TRÌ ---')

    p.write_text(content, encoding="utf-8")
    print("✓ Updated scenes/world/province_world.gd (6 sub-zones & Signposts)")

if __name__ == "__main__":
    update_player()
    update_chunk_streamer()
    update_province_world()
