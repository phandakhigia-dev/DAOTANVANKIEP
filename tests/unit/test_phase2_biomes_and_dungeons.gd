extends RefCounted

## TestPhase2BiomesAndDungeons — Kiểm thử mở rộng Đa Phân Vùng & Hang Động Bí Cảnh (Phase 2)
## Kiểm thử: Rừng Trúc Vạn Lĩnh, Đầm Lầy Hắc Xà, Cổ Kiếm Trũng, Smart Objects, và Lộ trình Khiêu Chiến Boss

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	var BambooScene = load("res://scenes/biomes/bamboo_forest.tscn")
	var SwampScene = load("res://scenes/biomes/snake_swamp.tscn")
	var SwordGraveScene = load("res://scenes/biomes/sword_grave.tscn")
	var CombatArenaScene = load("res://scenes/combat/combat_arena.tscn")
	
	# --- T-01: Region POI Registry Check ---
	var reg = ContentRegistry.get_region("reg_thanh_tri")
	var pois = reg.get("pois", [])
	var found_bamboo = false
	var found_swamp = false
	var found_sword = false
	
	for poi in pois:
		var pid = poi.get("id", "")
		if pid == "poi_rung_truc":
			found_bamboo = true
		elif pid == "poi_dam_lay_hac_xa":
			found_swamp = true
		elif pid == "poi_co_kiem_trung":
			found_sword = true
			
	if found_bamboo and found_swamp and found_sword:
		passed += 1
		logs.append("✓ [Pass] Region POIs: Đầy đủ 3 địa danh phân vùng mới trong reg_thanh_tri (Rừng Trúc, Đầm Lầy, Kiếm Trũng)")
	else:
		failed += 1
		logs.append("✗ [Fail] Region POIs: Thiếu địa danh POI trong region_thanh_tri.json")

	# --- T-02: Biome Scenes Instantiation ---
	var bamboo_node = BambooScene.instantiate()
	var swamp_node = SwampScene.instantiate()
	var sword_node = SwordGraveScene.instantiate()
	
	var cur_scene = Engine.get_main_loop().current_scene
	if cur_scene:
		cur_scene.add_child(bamboo_node)
		cur_scene.add_child(swamp_node)
		cur_scene.add_child(sword_node)
		
	if bamboo_node != null and swamp_node != null and sword_node != null:
		passed += 1
		logs.append("✓ [Pass] Biomes Scenes: Khởi tạo thành công 3 Scene Node (BambooForest, SnakeSwamp, SwordGrave)")
	else:
		failed += 1
		logs.append("✗ [Fail] Biomes Scenes: Lỗi khởi tạo một trong các scene phân vùng")

	# --- T-03: Rừng Trúc Vạn Lĩnh — Thu hái thảo dược & Mở rương Thạch Động ---
	var initial_da_huong = GameSession.get_item_count("item_da_huong_thao")
	var initial_linh_thao = GameSession.get_item_count("item_linh_thao")
	var initial_tu_khi = GameSession.get_item_count("item_tu_khi_dan")
	var initial_stones = GameSession.get_item_count("item_linh_thach")
	
	bamboo_node._execute_nearby_action("herb1")
	var got_da_huong = GameSession.get_item_count("item_da_huong_thao") - initial_da_huong
	var got_linh_thao_1 = GameSession.get_item_count("item_linh_thao") - initial_linh_thao
	
	bamboo_node._execute_nearby_action("herb2")
	var got_linh_thao_2 = GameSession.get_item_count("item_linh_thao") - (initial_linh_thao + got_linh_thao_1)
	
	bamboo_node._execute_nearby_action("dungeon_cavern")
	var got_tu_khi = GameSession.get_item_count("item_tu_khi_dan") - initial_tu_khi
	var got_stones_cavern = GameSession.get_item_count("item_linh_thach") - initial_stones
	
	# Thu hái lần 2 để kiểm tra Idempotence
	bamboo_node._execute_nearby_action("herb1")
	bamboo_node._execute_nearby_action("dungeon_cavern")
	var after_repeat_stones = GameSession.get_item_count("item_linh_thach") - initial_stones
	
	if got_da_huong == 2 and got_linh_thao_1 == 1 and got_linh_thao_2 == 3 and got_tu_khi == 2 and got_stones_cavern == 80 and after_repeat_stones == 80:
		passed += 1
		logs.append("✓ [Pass] BambooForest: Thu hái 2x Dạ Hương Thảo, 4x Linh Thảo; Rương Thạch Động trao 80 Linh Thạch + 2 Tụ Khí Đan chuẩn xác")
	else:
		failed += 1
		logs.append("✗ [Fail] BambooForest: Lỗi số lượng tài nguyên thu hoạch hoặc mở rương")

	# --- T-04: Đầm Lầy Hắc Xà — Thu hái Bách Thảo Diệp & Tế Đàn Xà Cốt ---
	var initial_bach_thao = GameSession.get_item_count("item_bach_thao_diep")
	var initial_kim_sang = GameSession.get_item_count("item_kim_sang_duoc")
	GameSession.add_item("item_linh_thach", 50)
	var stones_before_altar = GameSession.get_item_count("item_linh_thach")
	
	swamp_node._execute_nearby_action("herb1")
	var got_bach_thao = GameSession.get_item_count("item_bach_thao_diep") - initial_bach_thao
	
	swamp_node._execute_nearby_action("serpent_altar")
	var stones_after_altar = GameSession.get_item_count("item_linh_thach")
	var got_kim_sang = GameSession.get_item_count("item_kim_sang_duoc") - initial_kim_sang
	
	# Thử kích hoạt lại tế đàn
	swamp_node._execute_nearby_action("serpent_altar")
	var stones_after_repeat = GameSession.get_item_count("item_linh_thach")
	
	if got_bach_thao == 3 and (stones_before_altar - stones_after_altar == 15) and got_kim_sang == 2 and stones_after_repeat == stones_after_altar:
		passed += 1
		logs.append("✓ [Pass] SnakeSwamp: Thu hoạch 3x Bách Thảo Diệp; Tế Đàn Xà Cốt hiến tế 15 LT đổi 2x Kim Sang Dược thành công")
	else:
		failed += 1
		logs.append("✗ [Fail] SnakeSwamp: Lỗi trừ phí hoặc trao thưởng tại Tế Đàn Xà Cốt")

	# --- T-05: Cổ Kiếm Trũng — Tàn Kiếm Bia & Cơ Quan Thạch Đài ---
	var initial_co_kiem = GameSession.get_item_count("item_co_kiem_tan_phien")
	GameSession.max_cultivation_xp = 1000 # Đảm bảo đủ trần tu vi không bị nghẽn
	GameSession.cultivation_xp = 100
	var xp_before = GameSession.cultivation_xp
	var stones_before_sword = GameSession.get_item_count("item_linh_thach")
	
	sword_node._execute_nearby_action("sword_stele")
	var xp_after = GameSession.cultivation_xp
	
	sword_node._execute_nearby_action("sword_mechanism")
	var got_co_kiem = GameSession.get_item_count("item_co_kiem_tan_phien") - initial_co_kiem
	var stones_after_sword = GameSession.get_item_count("item_linh_thach")
	
	# Thử giải đố lần 2
	sword_node._execute_nearby_action("sword_mechanism")
	var got_co_kiem_repeat = GameSession.get_item_count("item_co_kiem_tan_phien") - initial_co_kiem
	
	if (xp_after - xp_before == 50) and got_co_kiem == 2 and (stones_after_sword - stones_before_sword == 100) and got_co_kiem_repeat == got_co_kiem:
		passed += 1
		logs.append("✓ [Pass] SwordGrave: Tàn Kiếm Bia đốn ngộ +50 Tu Vi; Kiếm Trận Thạch Đài trao 2x Cổ Kiếm Tàn Phiến & 100 Linh Thạch")
	else:
		failed += 1
		logs.append("✗ [Fail] SwordGrave: Lỗi đốn ngộ bia đá hoặc giải đố cơ quan")

	# --- T-06: Dynamic Boss Targeting & Return Routing ---
	# Test Bamboo Forest Boss Trigger
	bamboo_node._execute_nearby_action("boss_lair")
	var b_target = GameSession.target_combat_boss
	var b_return = GameSession.return_scene_path
	
	# Test Swamp Boss Trigger
	swamp_node._execute_nearby_action("boss_lair")
	var s_target = GameSession.target_combat_boss
	var s_return = GameSession.return_scene_path
	
	# Test Sword Grave Boss Trigger
	sword_node._execute_nearby_action("boss_lair")
	var g_target = GameSession.target_combat_boss
	var g_return = GameSession.return_scene_path
	
	if b_target == "boss_xich_kiem_ma_thu" and b_return == "res://scenes/biomes/bamboo_forest.tscn" \
		and s_target == "boss_hac_linh_xa_vuong" and s_return == "res://scenes/biomes/snake_swamp.tscn" \
		and g_target == "boss_co_kiem_linh" and g_return == "res://scenes/biomes/sword_grave.tscn":
		passed += 1
		logs.append("✓ [Pass] Boss Routing: Thiết lập chính xác Boss Target và Return Scene cho cả 3 phân vùng")
	else:
		failed += 1
		logs.append("✗ [Fail] Boss Routing: Boss Target hoặc Return Scene bị sai cấu hình")

	# --- T-07: Combat Arena Boss Selection Dynamic Acceptance ---
	GameSession.target_combat_boss = "boss_hac_linh_xa_vuong"
	var arena_node = CombatArenaScene.instantiate()
	if cur_scene:
		cur_scene.add_child(arena_node)
		
	if arena_node.target_boss_id == "boss_hac_linh_xa_vuong":
		passed += 1
		logs.append("✓ [Pass] CombatArena: Tự động kế thừa Boss Target từ GameSession (%s)" % arena_node.target_boss_id)
	else:
		failed += 1
		logs.append("✗ [Fail] CombatArena: target_boss_id không khớp với GameSession")

	# Cleanup instantiated test nodes
	if cur_scene:
		cur_scene.remove_child(bamboo_node)
		cur_scene.remove_child(swamp_node)
		cur_scene.remove_child(sword_node)
		cur_scene.remove_child(arena_node)
	bamboo_node.queue_free()
	swamp_node.queue_free()
	sword_node.queue_free()
	arena_node.queue_free()

	return {
		"name": "Phase 2: Mở Rộng Đa Phân Vùng & Hang Động Bí Cảnh",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
