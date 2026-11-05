extends Node2D

## ChunkStreamer — Bộ nạp động thế giới mở không gián đoạn (Seamless Province Streamer)
## Quản lý các Chunk 64×64 tile (2048×2048 px) của Tỉnh Thìn Châu (4096×4096 tile).
## Nạp theo bán kính camera người chơi, giải phóng vùng ngoài tầm nhìn để tối ưu RAM và FPS.

const TILE_SIZE: int = 32
const CHUNK_SIZE: int = 64 # 64x64 tiles
const CHUNK_PIXEL_SIZE: int = CHUNK_SIZE * TILE_SIZE # 2048 px

const PROVINCE_TILES: int = 4096
const TOTAL_CHUNKS_AXIS: int = 64 # 4096 / 64

# Bán kính nạp động: 1 chunk quanh người chơi (Lưới 3x3 chunk = 6144x6144 px)
@export var load_radius: int = 1

# Dictionary lưu trữ các chunk đang hoạt động: Vector2i(chunk_x, chunk_y) -> Node2D
var active_chunks: Dictionary = {}
var current_player_chunk: Vector2i = Vector2i(-999, -999)
var world_seed: int = 1337

# Preload các scenes công trình & cảnh quan
const GateTamQuanScene = preload("res://wuxia/32/buildings/gate_tam_quan.tscn")
const SectPalaceScene = preload("res://wuxia/32/buildings/sect_palace_hall.tscn")
const AlchemyHallScene = preload("res://wuxia/32/buildings/alchemy_hall.tscn")
const TavernInnScene = preload("res://wuxia/32/buildings/tavern_inn.tscn")
const BlacksmithScene = preload("res://wuxia/32/buildings/blacksmith_forge.tscn")
const MarketPavilionScene = preload("res://wuxia/32/buildings/market_pavilion.tscn")
const CourtyardHouseScene = preload("res://wuxia/32/buildings/courtyard_house.tscn")
const MoonlightPavilionScene = preload("res://wuxia/32/buildings/moonlight_pavilion.tscn")

const BambooClusterScene = preload("res://wuxia/32/nature/bamboo_cluster.tscn")
const AncientPineScene = preload("res://wuxia/32/nature/ancient_pine.tscn")
const CavernEntranceScene = preload("res://wuxia/32/nature/cavern_entrance.tscn")
const SwordMonolithScene = preload("res://wuxia/32/nature/sword_monolith.tscn")
const SwampShrineScene = preload("res://wuxia/32/nature/swamp_shrine.tscn")

const WellScene = preload("res://wuxia/32/props/town/well.tscn")
const MarketStallScene = preload("res://wuxia/32/props/town/market_stall.tscn")
const StoneLanternScene = preload("res://wuxia/32/props/town/stone_lantern.tscn")
const SignpostScene = preload("res://wuxia/32/props/town/signpost.tscn")

signal chunk_loaded(chunk_coord: Vector2i)
signal chunk_unloaded(chunk_coord: Vector2i)

func _ready() -> void:
	if GameSession:
		world_seed = GameSession.world_seed

func update_streamer_position(world_pos: Vector2) -> void:
	var player_chunk = world_pos_to_chunk(world_pos)
	if player_chunk != current_player_chunk:
		current_player_chunk = player_chunk
		_refresh_chunks_around(player_chunk)

func world_pos_to_chunk(world_pos: Vector2) -> Vector2i:
	var cx = clampi(int(floor(world_pos.x / CHUNK_PIXEL_SIZE)), 0, TOTAL_CHUNKS_AXIS - 1)
	var cy = clampi(int(floor(world_pos.y / CHUNK_PIXEL_SIZE)), 0, TOTAL_CHUNKS_AXIS - 1)
	return Vector2i(cx, cy)

func chunk_to_world_pos(chunk_coord: Vector2i) -> Vector2:
	return Vector2(chunk_coord.x * CHUNK_PIXEL_SIZE, chunk_coord.y * CHUNK_PIXEL_SIZE)

func _refresh_chunks_around(center: Vector2i) -> void:
	var needed_coords: Array[Vector2i] = []
	for dy in range(-load_radius, load_radius + 1):
		for dx in range(-load_radius, load_radius + 1):
			var cx = center.x + dx
			var cy = center.y + dy
			if cx >= 0 and cx < TOTAL_CHUNKS_AXIS and cy >= 0 and cy < TOTAL_CHUNKS_AXIS:
				needed_coords.append(Vector2i(cx, cy))
				
	# Gỡ bỏ các chunk ngoài tầm nhìn
	var to_remove: Array[Vector2i] = []
	for coord in active_chunks.keys():
		if not coord in needed_coords:
			to_remove.append(coord)
			
	for coord in to_remove:
		_unload_chunk(coord)
		
	# Nạp các chunk mới cần thiết
	for coord in needed_coords:
		if not active_chunks.has(coord):
			_load_chunk(coord)

func _load_chunk(coord: Vector2i) -> void:
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk_node.position = chunk_to_world_pos(coord)
	chunk_node.y_sort_enabled = true
	add_child(chunk_node)
	
	_build_chunk_content(chunk_node, coord)
	active_chunks[coord] = chunk_node
	chunk_loaded.emit(coord)

func _unload_chunk(coord: Vector2i) -> void:
	if active_chunks.has(coord):
		var node = active_chunks[coord]
		if is_instance_valid(node):
			node.queue_free()
		active_chunks.erase(coord)
		chunk_unloaded.emit(coord)

func _build_chunk_content(chunk_node: Node2D, coord: Vector2i) -> void:
	# 1. Vẽ nền địa hình cho Chunk
	var ground = _create_chunk_ground(coord)
	chunk_node.add_child(ground)
	
	# 2. Sinh các công trình và cảnh quan đặc thù theo tọa độ
	var entities_layer = Node2D.new()
	entities_layer.name = "Entities"
	entities_layer.y_sort_enabled = true
	chunk_node.add_child(entities_layer)
	
	# === LÕI ĐỊA HÌNH 256x256 TILE THANH TRÌ (16 CHUNKS) & 6 TIỂU VÙNG CỐT LÕI ===
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
		_populate_wilderness_chunk(entities_layer, coord)

func _create_chunk_ground(coord: Vector2i) -> Node2D:
	var ground = Node2D.new()
	ground.name = "Ground"
	ground.z_index = -2
	
	# Xác định biome màu chủ đạo cho chunk
	var bg_color = Color(0.14, 0.22, 0.16) # Đồng bằng xanh
	if coord.y <= 30:
		bg_color = Color(0.10, 0.25, 0.14) # Rừng trúc sẫm
	elif coord.x <= 31 and coord.y >= 33:
		bg_color = Color(0.12, 0.14, 0.16) # Đầm lầy độc
	elif coord.x >= 33:
		bg_color = Color(0.19, 0.18, 0.20) # Kiếm trũng đá xám
		
	# Tạo mặt đất nền 2048x2048 px
	var bg_rect = ColorRect.new()
	bg_rect.size = Vector2(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE)
	bg_rect.color = bg_color
	ground.add_child(bg_rect)
	
	# Lát đường quan lộ nối liền mạch
	if coord.x == 32:
		# Con đường đá chạy dọc Bắc - Nam (rộng 128 px)
		var road_v = ColorRect.new()
		road_v.position = Vector2(1024 - 64, 0)
		road_v.size = Vector2(128, CHUNK_PIXEL_SIZE)
		road_v.color = Color(0.40, 0.36, 0.28, 0.8)
		ground.add_child(road_v)
		
	if coord.y == 32:
		# Con đường đá chạy ngang Đông - Tây
		var road_h = ColorRect.new()
		road_h.position = Vector2(0, 1024 - 64)
		road_h.size = Vector2(CHUNK_PIXEL_SIZE, 128)
		road_h.color = Color(0.40, 0.36, 0.28, 0.8)
		ground.add_child(road_h)
		
	return ground

# --- CÁC PHÂN VÙNG LÕI 512x512 TILE ---
func _populate_thanh_tri_settlement(parent: Node2D) -> void:
	# Cổng Nam Thành
	_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 1600))
	
	# Thanh Vi Kiếm Điện (Đông Bắc Trấn)
	_spawn_instance(SectPalaceScene, parent, Vector2(1380, 720))
	_spawn_instance(AncientPineScene, parent, Vector2(1250, 700))
	_spawn_instance(AncientPineScene, parent, Vector2(1510, 700))
	
	# Dược Phẩm Các & Lò Đan (Tây Bắc Trấn)
	_spawn_instance(AlchemyHallScene, parent, Vector2(680, 720))
	_spawn_instance(AncientPineScene, parent, Vector2(560, 700))
	
	# Vạn Bảo Lâu (Chợ Tán Tu - Phía Đông)
	_spawn_instance(MarketPavilionScene, parent, Vector2(1380, 1024))
	_spawn_instance(MarketStallScene, parent, Vector2(1260, 1040))
	_spawn_instance(MarketStallScene, parent, Vector2(1480, 1040))
	
	# Vô Ưu Tửu Quán (Phía Tây)
	_spawn_instance(TavernInnScene, parent, Vector2(680, 1024))
	
	# Thiết Tượng Phác (Lò Rèn Kỷ Hoàn - Đông Nam)
	_spawn_instance(BlacksmithScene, parent, Vector2(1380, 1340))
	
	# Vọng Nguyệt Đình (Tây Nam)
	_spawn_instance(MoonlightPavilionScene, parent, Vector2(680, 1340))
	
	# Nhà Dân Cổ
	_spawn_instance(CourtyardHouseScene, parent, Vector2(860, 840))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(1180, 840))
	
	# Quảng Trường Giếng Cổ & Đèn Lồng
	_spawn_instance(WellScene, parent, Vector2(1024, 1024))
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1100))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 1160))
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 1560))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 1560))

func _populate_north_gate_and_road(parent: Node2D) -> void:
	# Cổng Bắc Thanh Trì Trấn
	_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 1800))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 1200))
	_spawn_instance(AncientPineScene, parent, Vector2(880, 1780))
	_spawn_instance(AncientPineScene, parent, Vector2(1160, 1780))
	
	# Các cụm trúc xanh bắt đầu rải rác bên lề đường về phương Bắc
	for y in range(400, 1600, 300):
		_spawn_instance(BambooClusterScene, parent, Vector2(750, y))
		_spawn_instance(BambooClusterScene, parent, Vector2(1290, y))

func _populate_bamboo_forest_biome(parent: Node2D) -> void:
	# Thạch Động Cổ Bí Cảnh
	_spawn_instance(CavernEntranceScene, parent, Vector2(1024, 800))
	_spawn_instance(SignpostScene, parent, Vector2(1024, 950))
	_spawn_instance(AncientPineScene, parent, Vector2(880, 780))
	_spawn_instance(AncientPineScene, parent, Vector2(1160, 780))
	
	# Sào Huyệt Boss Xích Kiếm Ma Thứu (Đông Bắc)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1464, 736))
	_spawn_instance(StoneLanternScene, parent, Vector2(1400, 750))
	_spawn_instance(StoneLanternScene, parent, Vector2(1520, 750))
	
	# Bãi Quái Rừng Trúc (Linh Hồ & Bạch Xuyên Thú - Nam)
	_spawn_instance(StoneLanternScene, parent, Vector2(1024, 1336))
	_spawn_instance(AncientPineScene, parent, Vector2(960, 1336))
	
	# Rừng trúc bạt ngàn
	var bamboo_spots = [
		Vector2(400, 400), Vector2(700, 350), Vector2(1400, 450), Vector2(1700, 380),
		Vector2(350, 900), Vector2(600, 1100), Vector2(1450, 1050), Vector2(1650, 850),
		Vector2(500, 1500), Vector2(800, 1600), Vector2(1300, 1550), Vector2(1600, 1450)
	]
	for p in bamboo_spots:
		_spawn_instance(BambooClusterScene, parent, p)

func _populate_snake_swamp_biome(parent: Node2D) -> void:
	# Tế Đàn Độc Xà (Trung tâm)
	_spawn_instance(SwampShrineScene, parent, Vector2(1024, 1024))
	_spawn_instance(AncientPineScene, parent, Vector2(850, 980))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 980))
	
	# Sào Huyệt Boss Hắc Linh Xà Vương (Bắc)
	_spawn_instance(SwampShrineScene, parent, Vector2(1024, 616))
	_spawn_instance(StoneLanternScene, parent, Vector2(940, 640))
	_spawn_instance(StoneLanternScene, parent, Vector2(1100, 640))
	
	# Ổ Quái Hắc Linh Xà (Tây)
	_spawn_instance(StoneLanternScene, parent, Vector2(612, 1024))
	_spawn_instance(AncientPineScene, parent, Vector2(580, 1000))

func _populate_sword_grave_biome(parent: Node2D) -> void:
	# Cổ Kiếm Tàn Đài (Trung tâm)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 1024))
	
	# Sào Huyệt Boss Cổ Kiếm Linh (Bắc)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 564))
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 580))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 580))
	
	# Bãi Quái Kiếm Nô Tàn Linh (Tây)
	_spawn_instance(SwordMonolithScene, parent, Vector2(616, 1024))
	
	# Tàn Kiếm Bia Lĩnh Ngộ Kiếm Ý (Đông Nam)
	_spawn_instance(SwordMonolithScene, parent, Vector2(1416, 1264))
	_spawn_instance(StoneLanternScene, parent, Vector2(1360, 1264))

func _populate_dong_noi_village(parent: Node2D) -> void:
	# Cụm nhà dân thôn Đồng Nội
	_spawn_instance(CourtyardHouseScene, parent, Vector2(800, 800))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(1200, 800))
	_spawn_instance(WellScene, parent, Vector2(1024, 900))
	_spawn_instance(AncientPineScene, parent, Vector2(1024, 700))


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

func _populate_wilderness_chunk(parent: Node2D, coord: Vector2i) -> void:
	# Sinh thủ tục cây cối ngẫu nhiên dựa trên hash tọa độ chunk và seed
	var hash_val = int(abs(sin(coord.x * 37.0 + coord.y * 73.0 + world_seed) * 10000.0))
	var count = 3 + (hash_val % 4)
	for i in range(count):
		var rx = 200 + ((hash_val * (i + 1) * 31) % (CHUNK_PIXEL_SIZE - 400))
		var ry = 200 + ((hash_val * (i + 1) * 67) % (CHUNK_PIXEL_SIZE - 400))
		if (hash_val + i) % 2 == 0:
			_spawn_instance(AncientPineScene, parent, Vector2(rx, ry))
		else:
			_spawn_instance(BambooClusterScene, parent, Vector2(rx, ry))

func _spawn_instance(scene: PackedScene, parent: Node2D, local_pos: Vector2) -> Node2D:
	if scene:
		var inst = scene.instantiate()
		inst.position = local_pos
		parent.add_child(inst)
		return inst
	return null

func get_active_chunk_count() -> int:
	return active_chunks.size()

func is_chunk_active(coord: Vector2i) -> bool:
	return active_chunks.has(coord)

func _populate_long_kinh_capital(parent: Node2D) -> void:
	# Cổng Nam Hoàng Thành
	_spawn_instance(GateTamQuanScene, parent, Vector2(1024, 1800))
	_spawn_instance(AncientPineScene, parent, Vector2(850, 1780))
	_spawn_instance(AncientPineScene, parent, Vector2(1200, 1780))
	
	# Hoàng Cung Càn Ninh Điện (Trung tâm phía Bắc)
	_spawn_instance(SectPalaceScene, parent, Vector2(1024, 600))
	
	# Lục Bộ Nha Môn (Phía Tây)
	_spawn_instance(CourtyardHouseScene, parent, Vector2(600, 750))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(600, 1050))
	
	# Cấm Vệ Doanh (Phía Đông)
	_spawn_instance(CourtyardHouseScene, parent, Vector2(1440, 750))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(1440, 1050))
	
	# Phố Chợ Hoàng Thành & Đấu Giá Đường
	_spawn_instance(MarketPavilionScene, parent, Vector2(1024, 1200))
	_spawn_instance(MarketStallScene, parent, Vector2(860, 1220))
	_spawn_instance(MarketStallScene, parent, Vector2(1180, 1220))
	
	# Lò Rèn Ngự Dụng
	_spawn_instance(BlacksmithScene, parent, Vector2(700, 1400))
	
	# Tửu Điếm Thăng Long
	_spawn_instance(TavernInnScene, parent, Vector2(1340, 1400))
	
	# Đèn đá hoàng gia
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 1760))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 1760))
	_spawn_instance(StoneLanternScene, parent, Vector2(960, 1160))
	_spawn_instance(StoneLanternScene, parent, Vector2(1088, 1160))

func _populate_tay_son_mining(parent: Node2D) -> void:
	# Cự Thạch Khai Khoáng Bia
	_spawn_instance(SwordMonolithScene, parent, Vector2(1024, 900))
	
	# Thiết Tượng Phác Tây Sơn
	_spawn_instance(BlacksmithScene, parent, Vector2(1200, 1100))
	
	# Lán Trại Thợ Mỏ
	_spawn_instance(CourtyardHouseScene, parent, Vector2(800, 1100))
	_spawn_instance(CourtyardHouseScene, parent, Vector2(750, 1300))
	
	# Cây tùng cổ thụ vách đá
	_spawn_instance(AncientPineScene, parent, Vector2(600, 800))
	_spawn_instance(AncientPineScene, parent, Vector2(1400, 800))
	_spawn_instance(AncientPineScene, parent, Vector2(1024, 1400))

func is_entity_harvested(chunk_coord: Vector2i, entity_id: String) -> bool:
	if not GameSession:
		return false
	var key = "%d_%d" % [chunk_coord.x, chunk_coord.y]
	if GameSession.chunk_diffs.has(key):
		var diff = GameSession.chunk_diffs[key]
		var harvested = diff.get("harvested_entities", [])
		return entity_id in harvested
	return false

func mark_entity_harvested(chunk_coord: Vector2i, entity_id: String) -> void:
	if not GameSession:
		return
	var key = "%d_%d" % [chunk_coord.x, chunk_coord.y]
	if not GameSession.chunk_diffs.has(key):
		GameSession.chunk_diffs[key] = { "harvested_entities": [] }
	var harvested = GameSession.chunk_diffs[key].get("harvested_entities", [])
	if not entity_id in harvested:
		harvested.append(entity_id)
		GameSession.chunk_diffs[key]["harvested_entities"] = harvested


func _build_single_chunk(cx: int, cy: int) -> Node2D:
	var chunk_node = Node2D.new()
	chunk_node.name = 'Chunk_%d_%d' % [cx, cy]
	chunk_node.position = chunk_to_world_pos(Vector2i(cx, cy))
	_build_chunk_content(chunk_node, Vector2i(cx, cy))
	return chunk_node

func get_subzone_name(cx: int, cy: int) -> String:
	if cx == 32 and cy == 32:
		return 'Huyện Thành Thanh Trì'
	elif cx == 32 and cy == 31:
		return 'Bắc Quan Lộ'
	elif cx == 32 and cy == 30:
		return 'Rừng Trúc Vạn Lĩnh'
	elif cx == 30 and cy == 32:
		return 'Mỏ Tây Hốc'
	elif cx == 31 and cy == 32:
		return 'Tây Quan Lộ'
	elif cx == 33 and cy == 31:
		return 'Thanh Hư Đạo Quán'
	elif cx == 33 and cy == 32:
		return 'Cổ Kiếm Trũng'
	elif cx == 31 and cy == 33:
		return 'Độc Trạch Hắc Xà'
	elif cx == 32 and cy == 33:
		return 'Cổng Nam Quan Lộ'
	elif cx == 31 and cy == 34:
		return 'Thôn Đồng Nội'
	elif cx == 32 and cy == 16:
		return 'Kinh Đô Long Kinh'
	return 'Ngoại Ô'
