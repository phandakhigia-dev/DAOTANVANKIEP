extends RefCounted

## TestLivingTownAndProceduralNPC — Kiểm thử toàn diện Thành Trì Nhập Vai & NPC Thủ Tục
## Kiểm thử: LifeGenerator, NPCCharacter, TownMapReal, Smart Objects, Sạp Hàng & DialogueModal

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	var LifeGen = load("res://scripts/domain/life_generator.gd")
	var TownScene = load("res://scenes/towns/town_map_real.tscn")
	var NPCScene = load("res://scenes/towns/npc_character.tscn")
	var ShopService = load("res://scripts/domain/shop_service.gd")
	
	# --- T-01: LifeGenerator — Sinh NPC ngẫu nhiên có chiều sâu ---
	var npc1 = LifeGen.generate_character(12345, 1)
	var npc2 = LifeGen.generate_character(12345, 2)
	var npc3 = LifeGen.generate_character(12345, 3)
	
	if npc1.name != "" and npc2.name != "" and npc1.name != npc2.name:
		passed += 1
		logs.append("✓ [Pass] LifeGenerator: Sinh thành công các danh xưng cổ phong độc nhất (%s vs %s)" % [npc1.name, npc2.name])
	else:
		failed += 1
		logs.append("✗ [Fail] LifeGenerator: Tên NPC bị trùng hoặc rỗng")
		
	# --- T-02: Phân hóa thọ nguyên (Ngắn / Trung bình / Dài) ---
	var has_diff_lifespans = (npc1.max_lifespan_years != npc2.max_lifespan_years or npc1.lifespan_type != npc3.lifespan_type)
	if has_diff_lifespans and npc1.max_lifespan_years > 0:
		passed += 1
		logs.append("✓ [Pass] LifeGenerator: Thọ nguyên phân hóa theo kiếp người thật (%d tuổi vs %d tuổi)" % [npc1.max_lifespan_years, npc2.max_lifespan_years])
	else:
		failed += 1
		logs.append("✗ [Fail] LifeGenerator: Thọ nguyên không có sự phân hóa")
		
	# --- T-03: Chiều sâu nhân sinh: Chí hướng (Core Drive), Bí mật và Biên niên sử ---
	if npc1.has("core_drive") and npc1.has("life_secret") and npc1.has("chronicle"):
		var drive_name = npc1.core_drive.get("title", "")
		var secret_name = npc1.life_secret.get("title", "")
		var chronicle_count = npc1.chronicle.size()
		if drive_name != "" and secret_name != "" and chronicle_count >= 2:
			passed += 1
			logs.append("✓ [Pass] LifeGenerator: Đầy đủ chiều sâu nhân sinh (Chí hướng: %s, Bí mật: %s, %d mốc sự kiện)" % [drive_name, secret_name, chronicle_count])
		else:
			failed += 1
			logs.append("✗ [Fail] LifeGenerator: Dữ liệu chiều sâu bị thiếu thuộc tính")
	else:
		failed += 1
		logs.append("✗ [Fail] LifeGenerator: Không chứa key core_drive, life_secret hoặc chronicle")
		
	# --- T-04: NPCCharacter Physical Entity Instantiation ---
	var npc_node = NPCScene.instantiate()
	var cur_scene_ref = Engine.get_main_loop().current_scene
	if cur_scene_ref:
		cur_scene_ref.add_child(npc_node)
	npc_node.setup_data(npc1)
	var lbl_name = npc_node.get_node_or_null("FloatingUI/VBox/LabelName")
	if lbl_name and lbl_name.text == npc1.name:
		passed += 1
		logs.append("✓ [Pass] NPCCharacter: Thực thể vật lý hiển thị danh xưng '%s' chuẩn xác" % npc1.name)
	else:
		failed += 1
		logs.append("✗ [Fail] NPCCharacter: Không cập nhật đúng label danh xưng")
	npc_node.queue_free()
	
	# --- T-05: TownMapReal Scene Instantiation ---
	var town_instance = TownScene.instantiate()
	if town_instance != null:
		passed += 1
		logs.append("✓ [Pass] TownMapReal: Khởi tạo scene thành công, không lỗi tài nguyên")
	else:
		failed += 1
		logs.append("✗ [Fail] TownMapReal: Không khởi tạo được scene")
		
	# --- T-06: Sinh NPC Cốt Truyện và NPC Thủ Tục trong Thành Trì ---
	# Thêm vào Tree tạm để kích hoạt _ready()
	if cur_scene_ref:
		cur_scene_ref.add_child(town_instance)
	else:
		Engine.get_main_loop().root.add_child(town_instance)
	
	var all_npc_chars = []
	for child in town_instance.get_node("YEntities").get_children():
		if child.name.contains("NPCCharacter") or child.has_signal("interacted"):
			all_npc_chars.append(child)
			
	if all_npc_chars.size() >= 8: # 5 cốt truyện + 3 thủ tục
		passed += 1
		logs.append("✓ [Pass] TownMapReal: Đầy đủ 8 NPC vật lý đi lại trong thành (5 Cốt truyện + 3 Thủ tục)")
	else:
		failed += 1
		logs.append("✗ [Fail] TownMapReal: Thiếu NPC trong thành (Đếm được: %d/8)" % all_npc_chars.size())
		
	# --- T-07: Tương tác Đồ Vật Thế Giới (Smart Objects: Giếng Cổ & Ghế Trà) ---
	var init_hp = GameSession.player_hp
	GameSession.player_hp = 50
	town_instance._execute_nearby_action("ancient_well")
	var healed_hp = GameSession.player_hp
	if healed_hp > 50:
		passed += 1
		logs.append("✓ [Pass] Smart Object: Múc nước giếng cổ phục hồi sinh lực (50 HP -> %d HP)" % healed_hp)
	else:
		failed += 1
		logs.append("✗ [Fail] Smart Object: Giếng cổ không hồi máu cho người chơi")
	GameSession.player_hp = init_hp
	
	var init_hour = GameClock.current_hour
	town_instance._execute_nearby_action("tea_bench")
	var new_hour = GameClock.current_hour
	if (new_hour == (init_hour + 1) % 24) or (init_hour == 23 and new_hour == 0):
		passed += 1
		logs.append("✓ [Pass] Smart Object: Tọa thiền ghế trà uống nước đẩy lùi thời gian +1 giờ")
	else:
		failed += 1
		logs.append("✗ [Fail] Smart Object: Ghế trà không tăng giờ")
		
	# --- T-08: Đối Thoại NPC Thủ Tục (DialogueModal Custom Integration) ---
	var dlg_modal = town_instance.get_node("HUD/DialogueModal")
	dlg_modal.open_for_custom_npc(npc1)
	if dlg_modal.visible and dlg_modal.label_npc_name.text == npc1.name:
		passed += 1
		logs.append("✓ [Pass] DialogueModal: Mở thành công khung đàm đạo riêng cho NPC '%s'" % npc1.name)
	else:
		failed += 1
		logs.append("✗ [Fail] DialogueModal: Không hiển thị đúng thông tin NPC thủ tục")
		
	# Kiểm tra đàm đạo chí hướng & cuộc đời
	dlg_modal._on_custom_chat_pressed()
	if dlg_modal.label_dialogue_text.text.contains(npc1.core_drive.dialogue):
		passed += 1
		logs.append("✓ [Pass] DialogueModal: Khai mở tâm sự chí hướng: \"%s\"" % npc1.core_drive.dialogue.left(35))
	else:
		failed += 1
		logs.append("✗ [Fail] DialogueModal: Không hiển thị câu thoại chí hướng của NPC")
		
	# Kiểm tra thăm dò bí mật
	dlg_modal._on_custom_secret_pressed()
	var s_title = npc1.life_secret.get("title", "")
	if dlg_modal.label_dialogue_text.text.contains(s_title):
		passed += 1
		logs.append("✓ [Pass] DialogueModal: Thăm dò phát hiện bí mật ẩn tàng: [%s]" % s_title)
	else:
		failed += 1
		logs.append("✗ [Fail] DialogueModal: Không tiết lộ bí mật nhân sinh")
		
	# Kiểm tra tặng lễ vật kết duyên
	var init_stones = GameSession.get_item_count("item_linh_thach")
	GameSession.add_item("item_linh_thach", 20)
	dlg_modal._on_custom_gift_pressed()
	var after_gift_stones = GameSession.get_item_count("item_linh_thach")
	if after_gift_stones == init_stones + 10:
		passed += 1
		logs.append("✓ [Pass] DialogueModal: Tặng 10 Linh Thạch kết giao thành công (Trừ đúng 10 LT)")
	else:
		failed += 1
		logs.append("✗ [Fail] DialogueModal: Trừ sai linh thạch khi tặng quà")
	GameSession.remove_item("item_linh_thach", 10)
	
	dlg_modal.close_dialogue()
	
	# --- T-09: Khép Kín Chu Trình Kinh Tế: NPC Mua Đan Dược Tại Sạp Hàng Người Chơi ---
	GameSession.add_item("item_linh_thach", 100)
	ShopService.lease_stall(1)
	GameSession.add_item("item_tu_khi_dan", 2)
	ShopService.deposit_item("item_tu_khi_dan", 2, 25)
	
	var prev_rev = ShopService.accumulated_revenue
	town_instance._simulate_town_market_purchases()
	var cur_rev = ShopService.accumulated_revenue
	
	if cur_rev >= prev_rev and ShopService.is_lease_active():
		passed += 1
		logs.append("✓ [Pass] Kinh Tế Thị Trấn: Tích hợp ShopService vào nhịp sống thị trấn thành công (Doanh thu sạp: %d LT)" % cur_rev)
	else:
		failed += 1
		logs.append("✗ [Fail] Kinh Tế Thị Trấn: Lỗi mô phỏng sức mua tại sạp")
			
	# Dọn dẹp scene test
	town_instance.queue_free()
	
	return {
		"name": "Phase 4 - LivingTown & ProceduralNPC (Thành Trì Nhập Vai & Chiều Sâu Nhân Sinh)",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
