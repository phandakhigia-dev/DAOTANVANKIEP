extends RefCounted

## TestBranchingDialogueAndWorldShaping — Kiểm thử Hệ Thống Đối Thoại 3-5 Lựa Chọn & Kiến Tạo Thế Giới
## Nghiệm thu:
##   1. Đầy đủ 3 tới 5 nhánh lựa chọn (Chính Đạo, Ma Đạo, Thương Lộ, Đạo Duyên, Bình Thản)
##   2. Biến động nhân quả: Hảo cảm, Tín nhiệm, Thù hận, Kính sợ
##   3. Ghi nhận Ký ức thế giới (log_memory_event) lan truyền biên niên sử
##   4. Biến động kinh tế thị trường (market_modifiers: herbs, medicines, weapons)
##   5. Thúc đẩy đột phá tu vi, thay đổi số phận NPC và tương tác an toàn túi đồ
##   6. Tích hợp UI DialogueModal với hiển thị trực quan

const DialogueScenarioService = preload("res://scripts/domain/dialogue_scenario_service.gd")

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []

	# Khởi tạo phiên thử nghiệm sạch
	GameSession.start_new_game("Kiếm Khách Vô Danh", 999999)

	# --- T-01: Scenario Generation & Structure ---
	var sc_mac = DialogueScenarioService.generate_scenario("npc_mac_tu_vien")
	if not sc_mac.is_empty() and sc_mac.has("choices") and sc_mac.has("prompt") and sc_mac.has("title"):
		passed += 1
		logs.append("✓ [Pass] T-01: Sinh kịch bản vấn đạo cho Mạc Tư Viễn thành công đầy đủ tiêu đề và bối cảnh")
	else:
		failed += 1
		logs.append("✗ [Fail] T-01: Lỗi cấu trúc kịch bản đối thoại")

	# --- T-02: Boundary Check: Always 3 to 5 Choices ---
	var canonical_ids = ["npc_mac_tu_vien", "npc_thu_nguyet", "npc_lam_du", "npc_ky_hoan", "npc_moc_lao"]
	var all_canonical_valid = true
	for cid in canonical_ids:
		var sc = DialogueScenarioService.generate_scenario(cid)
		var n_choices = sc.get("choices", []).size()
		if n_choices < 3 or n_choices > 5:
			all_canonical_valid = false
			break
			
	var proc_drives = ["drive_save_kin", "drive_revenge", "drive_immortality", "drive_sword_mastery", "drive_wealth"]
	var all_proc_valid = true
	for d in proc_drives:
		var p_data = {
			"id": "npc_wanderer_" + d,
			"name": "Tán Tu " + d,
			"core_drive": { "id": d },
			"location": "poi_thanh_tri_tran"
		}
		var sc_proc = DialogueScenarioService.generate_scenario("", p_data)
		var n_choices = sc_proc.get("choices", []).size()
		if n_choices < 3 or n_choices > 5:
			all_proc_valid = false
			break
			
	if all_canonical_valid and all_proc_valid:
		passed += 1
		logs.append("✓ [Pass] T-02: Tiêu chuẩn 3 tới 5 câu trả lời đạt 100% cho mọi NPC cốt truyện và tán tu dã ngoại")
	else:
		failed += 1
		logs.append("✗ [Fail] T-02: Số lượng lựa chọn vi phạm khoảng [3, 5]")

	# --- T-03: Choice Philosophy & Archetype Diversity ---
	var categories_found: Dictionary = {}
	for c in sc_mac.get("choices", []):
		categories_found[c.get("category", "")] = true
		
	var has_all_paths = categories_found.has("righteous") and categories_found.has("demonic") and categories_found.has("pragmatic") and categories_found.has("enlightenment") and categories_found.has("aloof")
	if has_all_paths:
		passed += 1
		logs.append("✓ [Pass] T-03: Đầy đủ 5 triết lý tu chân: Chính Đạo, Ma Đạo, Thương Lộ, Đạo Duyên, Bình Thản")
	else:
		failed += 1
		logs.append("✗ [Fail] T-03: Thiếu một trong các nhánh ứng đối triết đạo")

	# --- T-04: Righteous Path Execution & World Memory Logging ---
	GameSession.add_item("item_linh_thach", 100)
	var prev_affinity = GameSession.get_npc_affinity("npc_mac_tu_vien")
	var prev_stones = GameSession.get_item_count("item_linh_thach")
	var prev_mems_count = GameSession.memory_events.size()
	
	var res_r = DialogueScenarioService.execute_choice(sc_mac, "mac_righteous")
	var new_affinity = GameSession.get_npc_affinity("npc_mac_tu_vien")
	var new_stones = GameSession.get_item_count("item_linh_thach")
	var new_mems_count = GameSession.memory_events.size()
	
	var rel_mac = GameSession.get_npc_relationship("npc_mac_tu_vien", "player")
	var righteous_pass = (
		res_r.get("success", false) and
		new_affinity == prev_affinity + 30 and
		new_stones == prev_stones - 20 and
		new_mems_count == prev_mems_count + 1 and
		rel_mac.get("trust", 0) >= 25
	)
	if righteous_pass:
		passed += 1
		logs.append("✓ [Pass] T-04: Nhánh [Chính Đạo] tăng 30 Hảo cảm, 25 Tín nhiệm, trừ 20 Linh Thạch và ghi nhận Ký ức thế giới")
	else:
		failed += 1
		logs.append("✗ [Fail] T-04: Lỗi thực thi nhánh Chính Đạo")

	# --- T-05: Demonic Path Execution & Grudge / Fear Repercussions ---
	var sc_mac_2 = DialogueScenarioService.generate_scenario("npc_mac_tu_vien")
	var stones_before_demonic = GameSession.get_item_count("item_linh_thach")
	var aff_before_demonic = GameSession.get_npc_affinity("npc_mac_tu_vien")
	
	var res_d = DialogueScenarioService.execute_choice(sc_mac_2, "mac_demonic")
	var aff_after_demonic = GameSession.get_npc_affinity("npc_mac_tu_vien")
	var stones_after_demonic = GameSession.get_item_count("item_linh_thach")
	var rel_after_demonic = GameSession.get_npc_relationship("npc_mac_tu_vien", "player")
	
	var demonic_pass = (
		res_d.get("success", false) and
		aff_after_demonic == aff_before_demonic - 30 and
		stones_after_demonic == stones_before_demonic + 40 and
		rel_after_demonic.get("grudge", 0) >= 35 and
		rel_after_demonic.get("fear", 0) >= 30
	)
	if demonic_pass:
		passed += 1
		logs.append("✓ [Pass] T-05: Nhánh [Ma Đạo] cướp 40 Linh Thạch, giảm 30 Hảo cảm, tăng 35 Thù hận và 30 Kính sợ")
	else:
		failed += 1
		logs.append("✗ [Fail] T-05: Lỗi phản ứng nhánh Ma Đạo")

	# --- T-06: Economic Market Shaping (Market Modifiers) ---
	var sc_thu = DialogueScenarioService.generate_scenario("npc_thu_nguyet")
	GameSession.add_item("item_linh_thao", 10)
	
	# Chọn Chính Đạo: Dâng thảo dược cứu nạn -> Giá thuốc giảm 20%
	var res_thu_r = DialogueScenarioService.execute_choice(sc_thu, "thunguyet_righteous")
	var med_mod_low = GameSession.get_market_modifier("medicines")
	var price_cheap = GameSession.get_modified_item_price("item_hoi_xuan_dan", 50)
	
	# Chọn Ma Đạo: Đầu cơ tích trữ -> Giá thuốc tăng vọt 30%
	var res_thu_d = DialogueScenarioService.execute_choice(sc_thu, "thunguyet_demonic")
	var med_mod_high = GameSession.get_market_modifier("medicines")
	var price_expensive = GameSession.get_modified_item_price("item_hoi_xuan_dan", 50)
	
	if med_mod_low == 0.80 and med_mod_high == 1.30 and price_cheap < 50 and price_expensive > 50:
		passed += 1
		logs.append("✓ [Pass] T-06: Quyết định đối thoại trực tiếp điều tiết kinh tế trấn (Giá thuốc: %d LT -> %d LT)" % [price_cheap, price_expensive])
	else:
		failed += 1
		logs.append("✗ [Fail] T-06: Lỗi biến động thị trường từ lựa chọn đối thoại")

	# --- T-07: NPC Cultivation Progression & Breakthrough ---
	var wanderer_data = {
		"id": "test_npc_breakthrough",
		"name": "Lâm Tiêu Dao",
		"realm_name": "Luyện Khí Tầng 1",
		"realm_stage": 1,
		"cultivation_xp": 70,
		"core_drive": { "id": "drive_save_kin" },
		"location": "poi_thanh_tri_tran"
	}
	GameSession.register_world_npc(wanderer_data)
	
	var sc_break = DialogueScenarioService.generate_scenario("test_npc_breakthrough", wanderer_data)
	var res_break = DialogueScenarioService.execute_choice(sc_break, "proc_save_enlightenment")
	var updated_npc = GameSession.world_npcs["test_npc_breakthrough"]
	
	var did_advance = updated_npc.get("realm_stage", 1) == 2 and updated_npc.get("realm_name", "").contains("Tầng 2")
	if res_break.get("success", false) and did_advance:
		passed += 1
		logs.append("✓ [Pass] T-07: Chỉ điểm đạo duyên kích phát NPC đột phá từ Luyện Khí Tầng 1 lên Tầng 2 ngay trong đối thoại")
	else:
		failed += 1
		logs.append("✗ [Fail] T-07: NPC không đột phá cảnh giới khi tích lũy đủ XP")

	# --- T-08: Resource Gate & Safe Transaction Validation ---
	var sc_gate = DialogueScenarioService.generate_scenario("npc_thu_nguyet")
	# Xóa sạch linh thảo
	var cur_herbs = GameSession.get_item_count("item_linh_thao")
	if cur_herbs > 0:
		GameSession.remove_item("item_linh_thao", cur_herbs)
		
	var afford_res = DialogueScenarioService.can_player_afford_choice(sc_gate["choices"][0])
	var reject_exec = DialogueScenarioService.execute_choice(sc_gate, "thunguyet_righteous")
	
	if afford_res.get("can_afford", true) == false and reject_exec.get("success", true) == false:
		passed += 1
		logs.append("✓ [Pass] T-08: Cơ chế khóa lựa chọn an toàn từ chối thực hiện khi túi đồ thiếu tài nguyên")
	else:
		failed += 1
		logs.append("✗ [Fail] T-08: Lỗi bảo vệ giao dịch tài nguyên đối thoại")

	# --- T-09: UI DialogueModal Integration & Dynamic Choice Rendering ---
	var ModalScene = load("res://scenes/ui/dialogue_modal.tscn")
	var modal_instance = ModalScene.instantiate()
	var cur_scene = Engine.get_main_loop().current_scene
	if cur_scene:
		cur_scene.add_child(modal_instance)
		
	modal_instance.open_for_npc("npc_mac_tu_vien")
	var actions_box = modal_instance.actions_container
	var found_scenario_btn = false
	for btn in actions_box.get_children():
		if btn is Button and btn.text.contains("Vấn Đạo Luận Thế"):
			found_scenario_btn = true
			break
			
	modal_instance._open_scenario_view()
	var choice_buttons_count = 0
	var has_spoilers = false
	for btn in actions_box.get_children():
		if btn is Button and (btn.text.contains("[Chính Đạo]") or btn.text.contains("[Ma Đạo]") or btn.text.contains("[Thương Lộ]") or btn.text.contains("[Đạo Duyên]") or btn.text.contains("[Bình Thản]")):
			choice_buttons_count += 1
			# Xác minh bí mật: Tuyệt đối không leak trước các chỉ số được/mất
			if btn.text.contains("Tiêu ") or btn.text.contains("Hảo cảm +") or btn.text.contains("Cướp ") or btn.text.contains("Tu Vi)"):
				has_spoilers = true
			
	if found_scenario_btn and choice_buttons_count == 5 and not has_spoilers:
		passed += 1
		logs.append("✓ [Pass] T-09: DialogueModal kết nối trơn tru, hiển thị 5 nhánh lựa chọn tự nhiên bí mật, không hé lộ trước được/mất")
	else:
		failed += 1
		logs.append("✗ [Fail] T-09: Lỗi hiển thị nhánh lựa chọn trên giao diện DialogueModal hoặc rò rỉ spoiler (Đếm được: %d/5, Spoiler: %s)" % [choice_buttons_count, str(has_spoilers)])

	# --- T-10: Complete UI Selection Flow & Post-Choice World Consequence Display ---
	modal_instance._on_scenario_choice_selected("mac_enlightenment")
	var dialogue_text = modal_instance.label_dialogue_text.text
	var has_consequence_header = dialogue_text.contains("ẢNH HƯỞNG THẾ GIỚI & NHÂN QUẢ")
	var has_feedback_points = dialogue_text.contains("Ký ức thế giới:")
	
	if has_consequence_header and has_feedback_points:
		passed += 1
		logs.append("✓ [Pass] T-10: Giao diện phản hồi sinh động: Lời thoại NPC kèm Bảng Tóm Tắt Biến Động Thế Giới hoàn chỉnh")
	else:
		failed += 1
		logs.append("✗ [Fail] T-10: Thiếu bảng phản hồi biến động thế giới trên UI")

	# Dọn dẹp modal test
	if cur_scene:
		cur_scene.remove_child(modal_instance)
	modal_instance.queue_free()

	return {
		"name": "Phase 4 - Branching Dialogue & World Shaping System (3-5 Lựa Chọn & Kiến Tạo Thế Giới)",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
