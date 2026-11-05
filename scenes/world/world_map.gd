extends Node2D

## WorldMap — Bản đồ thế giới sandbox sinh theo hạt giống (Deterministic World Grid)
## Quản lý vùng Thanh Trì Trấn và các điểm POI khởi đầu.

const CELL_SIZE: int = 64
const MAP_WIDTH: int = 50
const MAP_HEIGHT: int = 40

const TEX_WM_TOWN = preload("res://wuxia/32/landmarks/wm_thanh_tri_tran.png")
const TEX_WM_BAMBOO = preload("res://wuxia/32/landmarks/wm_bamboo_forest.png")
const TEX_WM_SWAMP = preload("res://wuxia/32/landmarks/wm_snake_swamp.png")
const TEX_WM_SWORD = preload("res://wuxia/32/landmarks/wm_sword_grave.png")
const TEX_WM_PEAK = preload("res://wuxia/32/landmarks/wm_combat_peak.png")

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: Control = $HUD/PauseMenu

var terrain_grid: Array = []
var nearby_poi: Dictionary = {}
var day_night_modulate: CanvasModulate = null
var remote_avatars: Dictionary = {} # peer_id: int -> Node2D

func _ready() -> void:
	_generate_deterministic_world()
	
	if CoopWorldSync:
		CoopWorldSync.remote_player_updated.connect(_on_remote_player_updated)
		CoopWorldSync.remote_player_removed.connect(_on_remote_player_removed)
	
	day_night_modulate = CanvasModulate.new()
	day_night_modulate.name = "WorldDayNightModulate"
	add_child(day_night_modulate)
	
	if AudioService:
		AudioService.play_bgm("bgm_bamboo_forest")
		
	queue_redraw()

func _generate_deterministic_world() -> void:
	terrain_grid.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = GameSession.world_seed
	
	# Sinh lưới địa hình theo seed
	for y in range(MAP_HEIGHT):
		var row: Array = []
		for x in range(MAP_WIDTH):
			var dist_to_mountain = Vector2(x, y).distance_to(Vector2(40, 10))
			var dist_to_lake = Vector2(x, y).distance_to(Vector2(15, 12))
			var dist_to_forest = Vector2(x, y).distance_to(Vector2(10, 30))
			var dist_to_swamp = Vector2(x, y).distance_to(Vector2(16, 36))
			var dist_to_sword_grave = Vector2(x, y).distance_to(Vector2(44, 28))
			
			var tile_type = 0 # 0: Đồng bằng (Plains)
			if dist_to_swamp < 4.0:
				tile_type = 5 # 5: Đầm lầy độc (Swamp)
			elif dist_to_sword_grave < 4.5:
				tile_type = 6 # 6: Kiếm trũng hoang mạc (Sword Grave)
			elif dist_to_lake < 4.5:
				tile_type = 1 # 1: Hồ nước (Water)
			elif dist_to_mountain < 6.0:
				tile_type = 2 # 2: Núi đá (Mountain)
			elif dist_to_forest < 5.0:
				tile_type = 3 # 3: Rừng trúc (Forest)
			else:
				var r = rng.randf()
				if r < 0.08:
					tile_type = 4 # 4: Đồi thoải (Hills)
			
			row.append(tile_type)
		terrain_grid.append(row)

func _process(delta: float) -> void:
	_check_poi_proximity()
	_update_day_night_lighting(delta)
	_update_remote_avatars(delta)

func _update_remote_avatars(delta: float) -> void:
	for p_id in remote_avatars.keys():
		var av = remote_avatars[p_id]
		if not is_instance_valid(av):
			continue
		var target_pos = av.get_meta("target_pos", av.global_position)
		av.global_position = av.global_position.lerp(target_pos, clampf(delta * 12.0, 0.05, 1.0))
		
		var spr = av.get_node_or_null("Sprite")
		var anim = av.get_meta("anim", "idle_south")
		if spr and spr.has_method("play") and spr.sprite_frames.has_animation(anim):
			if spr.animation != anim:
				spr.play(anim)

func _on_remote_player_updated(peer_id: int, data: Dictionary) -> void:
	var my_id = multiplayer.get_unique_id() if (multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED) else 1
	if peer_id == my_id:
		return # Avatar cục bộ do Player tự điều khiển
	
	if not peer_id in remote_avatars or not is_instance_valid(remote_avatars[peer_id]):
		_spawn_remote_avatar(peer_id, data)
		
	var av = remote_avatars[peer_id]
	av.set_meta("target_pos", data.get("pos", av.global_position))
	av.set_meta("anim", data.get("anim", "idle_south"))
	av.set_meta("facing", data.get("facing", Vector2.DOWN))

func _spawn_remote_avatar(peer_id: int, data: Dictionary) -> void:
	var swordsman_scene = load("res://wuxia/32/heroes/swordsman/swordsman.tscn")
	var av = Node2D.new()
	av.name = "RemotePlayer_%d" % peer_id
	av.global_position = data.get("pos", Vector2(600, 420))
	av.set_meta("target_pos", av.global_position)
	av.set_meta("anim", "idle_south")
	av.set_meta("facing", Vector2.DOWN)
	
	if swordsman_scene:
		var spr = swordsman_scene.instantiate()
		spr.name = "Sprite"
		spr.modulate = Color(0.7, 0.9, 1.0, 1.0) # Sắc xanh lam phân biệt đồng đạo
		av.add_child(spr)
		if spr.sprite_frames.has_animation("idle_south"):
			spr.play("idle_south")
			
	var lbl = Label.new()
	lbl.name = "NameLabel"
	lbl.text = "[Đạo Hữu] %s (#%d)" % [data.get("name", "Đồng Đạo"), peer_id]
	lbl.position = Vector2(-70, -42)
	lbl.modulate = Color(0.4, 0.9, 1.0)
	av.add_child(lbl)
	
	add_child(av)
	remote_avatars[peer_id] = av
	print("[WorldMap] Đã spawn Remote Avatar cho Peer %d tại %s" % [peer_id, av.global_position])

func _on_remote_player_removed(peer_id: int) -> void:
	if peer_id in remote_avatars:
		var av = remote_avatars[peer_id]
		if is_instance_valid(av):
			av.queue_free()
		remote_avatars.erase(peer_id)
		print("[WorldMap] Đã gỡ bỏ Remote Avatar của Peer %d" % peer_id)

func _update_day_night_lighting(delta: float) -> void:
	if not day_night_modulate or not GameClock:
		return
	
	var target_col = Color(1.0, 1.0, 1.0, 1.0)
	var h = GameClock.current_hour
	# Khớp tuyệt đối với chu kỳ 1 ngày = 720 giây thực tế
	if h >= 19 or h < 5:
		target_col = Color(0.46, 0.50, 0.70, 1.0) # Ánh trăng huyền ảo ban đêm
	elif h >= 5 and h < 7:
		target_col = Color(0.92, 0.82, 0.72, 1.0) # Bình minh rực rỡ
	elif h >= 17 and h < 19:
		target_col = Color(0.88, 0.70, 0.55, 1.0) # Hoàng hôn tà dương
	else:
		target_col = Color(1.0, 1.0, 1.0, 1.0)    # Ban ngày quang đãng
		
	day_night_modulate.color = day_night_modulate.color.lerp(target_col, clamp(delta * 2.5, 0.05, 1.0))

func _check_poi_proximity() -> void:
	if not player or not hud:
		return
	
	var reg = ContentRegistry.get_region(GameSession.current_region_id)
	var pois = reg.get("pois", [])
	var p_pos = player.global_position
	
	var found_poi: Dictionary = {}
	for poi in pois:
		var target = Vector2(poi.get("x", 0) * CELL_SIZE, poi.get("y", 0) * CELL_SIZE)
		if p_pos.distance_to(target) <= 90.0:
			found_poi = poi
			break
			
	nearby_poi = found_poi
	if not nearby_poi.is_empty():
		var p_name = nearby_poi.get("name", "")
		var p_id = nearby_poi.get("id", "")
		if p_id == "poi_thanh_tri_tran":
			hud.show_interaction_prompt("Nhấn [E] hoặc [Enter] để vào %s" % p_name)
		elif p_id == "poi_van_linh_bien":
			hud.show_interaction_prompt("Nhấn [E] hoặc [Enter] để vào Bí Cảnh %s (Chiến Đấu)" % p_name)
		elif p_id == "poi_rung_truc":
			hud.show_interaction_prompt("Nhấn [E] hoặc [Enter] để vào %s (Bí Cảnh & Thạch Động)" % p_name)
		elif p_id == "poi_dam_lay_hac_xa":
			hud.show_interaction_prompt("Nhấn [E] hoặc [Enter] để thám hiểm %s (Độc Đầm & Tế Đàn)" % p_name)
		elif p_id == "poi_co_kiem_trung":
			hud.show_interaction_prompt("Nhấn [E] hoặc [Enter] để bước vào %s (Kiếm Trận & Kiếm Mộ)" % p_name)
		else:
			hud.show_interaction_prompt("Đang ở gần %s [E: Khám phá]" % p_name)
	else:
		hud.show_interaction_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if pause_menu.visible:
			pause_menu.resume_game()
		else:
			pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E or event.keycode == KEY_ENTER:
			if not nearby_poi.is_empty():
				var p_id = nearby_poi.get("id", "")
				if p_id == "poi_thanh_tri_tran":
					GameSession.world_position = player.global_position
					get_tree().change_scene_to_file("res://scenes/towns/town_map_real.tscn")
					get_viewport().set_input_as_handled()
				elif p_id == "poi_van_linh_bien":
					GameSession.target_combat_boss = "boss_xich_kiem_ma_thu"
					GameSession.return_scene_path = "res://scenes/world/world_map.tscn"
					get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")
					get_viewport().set_input_as_handled()
				elif p_id == "poi_rung_truc":
					GameSession.world_position = player.global_position
					get_tree().change_scene_to_file("res://scenes/biomes/bamboo_forest.tscn")
					get_viewport().set_input_as_handled()
				elif p_id == "poi_dam_lay_hac_xa":
					GameSession.world_position = player.global_position
					get_tree().change_scene_to_file("res://scenes/biomes/snake_swamp.tscn")
					get_viewport().set_input_as_handled()
				elif p_id == "poi_co_kiem_trung":
					GameSession.world_position = player.global_position
					get_tree().change_scene_to_file("res://scenes/biomes/sword_grave.tscn")
					get_viewport().set_input_as_handled()
				else:
					if EventBus:
						EventBus.notification_requested.emit("Nơi đây linh khí phẳng lặng, không có biến động.", "info")
					get_viewport().set_input_as_handled()

func _draw() -> void:
	# 1. Vẽ nền gạch địa hình
	var color_plains = Color(0.14, 0.22, 0.18, 1.0)
	var color_plains_alt = Color(0.12, 0.19, 0.16, 1.0)
	var color_water = Color(0.12, 0.24, 0.32, 1.0)
	var color_mountain = Color(0.24, 0.28, 0.26, 1.0)
	var color_forest = Color(0.09, 0.28, 0.15, 1.0)
	var color_hills = Color(0.18, 0.26, 0.19, 1.0)
	var color_swamp = Color(0.11, 0.13, 0.15, 1.0)
	var color_sword_crags = Color(0.22, 0.20, 0.23, 1.0)
	
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var tile_type = terrain_grid[y][x] if y < terrain_grid.size() and x < terrain_grid[y].size() else 0
			var c = color_plains if ((x + y) % 2 == 0) else color_plains_alt
			
			match tile_type:
				1: c = color_water
				2: c = color_mountain
				3: c = color_forest
				4: c = color_hills
				5: c = color_swamp
				6: c = color_sword_crags
			
			draw_rect(rect, c, true)
			draw_rect(rect, Color(0, 0, 0, 0.12), false, 1.0)
			
			# Họa tiết địa hình mỹ thuật
			if tile_type == 1:
				# Gợn sóng nước lăn tăn
				draw_line(Vector2(rect.position.x + 12, rect.position.y + 20), Vector2(rect.position.x + 36, rect.position.y + 20), Color(0.35, 0.6, 0.8, 0.35), 1.0)
				draw_line(Vector2(rect.position.x + 28, rect.position.y + 42), Vector2(rect.position.x + 52, rect.position.y + 42), Color(0.35, 0.6, 0.8, 0.35), 1.0)
			elif tile_type == 3:
				# Cụm mầm trúc xanh
				draw_circle(Vector2(rect.position.x + 24, rect.position.y + 24), 5.0, Color(0.2, 0.5, 0.28, 0.45))
				draw_circle(Vector2(rect.position.x + 44, rect.position.y + 38), 4.0, Color(0.2, 0.5, 0.28, 0.45))
			elif tile_type == 6:
				# Tàn kiếm cắm trên đất
				draw_line(Vector2(rect.position.x + 32, rect.position.y + 18), Vector2(rect.position.x + 32, rect.position.y + 46), Color(0.7, 0.65, 0.55, 0.4), 2.0)
				draw_line(Vector2(rect.position.x + 26, rect.position.y + 26), Vector2(rect.position.x + 38, rect.position.y + 26), Color(0.8, 0.75, 0.4, 0.5), 1.5)
	
	# 2. Vẽ biên giới vùng đất
	var total_w = MAP_WIDTH * CELL_SIZE
	var total_h = MAP_HEIGHT * CELL_SIZE
	draw_rect(Rect2(0, 0, total_w, total_h), Color(0.78, 0.65, 0.40, 0.8), false, 4.0)
	
	# 3. Vẽ các địa danh POI
	var reg = ContentRegistry.get_region(GameSession.current_region_id)
	var pois = reg.get("pois", [])
	
	for poi in pois:
		var px = poi.get("x", 0) * CELL_SIZE
		var py = poi.get("y", 0) * CELL_SIZE
		var p_name = poi.get("name", "Địa Danh")
		var p_type = poi.get("type", "town")
		
		var poi_color = Color(0.89, 0.85, 0.76, 1.0)
		var icon_tex: Texture2D = null
		match p_type:
			"town":
				poi_color = Color(0.78, 0.65, 0.40, 1.0)
				icon_tex = TEX_WM_TOWN
			"water":
				poi_color = Color(0.47, 0.71, 0.85, 1.0)
				icon_tex = TEX_WM_PEAK
			"mountain":
				poi_color = Color(0.65, 0.65, 0.65, 1.0)
				icon_tex = TEX_WM_PEAK
			"forest":
				poi_color = Color(0.45, 0.75, 0.54, 1.0)
				icon_tex = TEX_WM_BAMBOO
			"swamp":
				poi_color = Color(0.68, 0.42, 0.82, 1.0)
				icon_tex = TEX_WM_SWAMP
			"sword_grave":
				poi_color = Color(0.82, 0.62, 0.38, 1.0)
				icon_tex = TEX_WM_SWORD
		
		# Vòng tròn ánh sáng POI
		draw_circle(Vector2(px, py), 34.0, Color(poi_color.r, poi_color.g, poi_color.b, 0.22))
		draw_arc(Vector2(px, py), 26.0, 0, TAU, 32, poi_color, 1.5)
		
		if icon_tex:
			draw_texture(icon_tex, Vector2(px - 24, py - 24))
		else:
			draw_circle(Vector2(px, py), 16.0, poi_color)
		
		# Nhãn địa danh có nền tối tương phản cao
		var text_size = p_name.length() * 8.5
		var tag_rect = Rect2(px - (text_size / 2.0) - 8, py + 26, text_size + 16, 22)
		draw_rect(tag_rect, Color(0.06, 0.10, 0.12, 0.85), true)
		draw_rect(tag_rect, Color(0.78, 0.65, 0.40, 0.7), false, 1.0)
		
		var str_pos = Vector2(px - (text_size / 2.0), py + 40)
		draw_string(ThemeDB.fallback_font, str_pos, p_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.92, 0.85, 1.0))
