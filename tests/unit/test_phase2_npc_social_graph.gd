extends RefCounted

## Unit test: Phase 2 - Mạng Lưới Xã Hội NPC, Ân Oán & Ký Ức (Social Graph & Memory)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	GameSession.start_new_game("Đạo Nhân", 555666)
	
	# Test 1: Khởi tạo quan hệ rỗng trả về thông số mặc định an toàn
	var rel_init = GameSession.get_npc_relationship("npc_mac_tu_vien", "player")
	if rel_init["affinity"] == 0 and rel_init["trust"] == 0 and rel_init["debt"] == 0 and rel_init["grudge"] == 0:
		passed += 1
		logs.append("✓ [Pass] Khởi tạo quan hệ rỗng trả về cấu trúc chuẩn (Affinity=0, Trust=0, Debt=0, Grudge=0)")
	else:
		failed += 1
		logs.append("✗ [Fail] Cấu trúc quan hệ ban đầu không chuẩn: %s" % str(rel_init))
		
	# Test 2: Tình huống Cứu Người (Player cứu NPC) -> Tăng ân tình (Debt) và tin cậy (Trust)
	GameSession.modify_npc_relationship("npc_mac_tu_vien", "player", 30, 40, 50, 0)
	var rel_saved = GameSession.get_npc_relationship("npc_mac_tu_vien", "player")
	if rel_saved["debt"] == 50 and rel_saved["trust"] == 40 and rel_saved["affinity"] == 30:
		passed += 1
		logs.append("✓ [Pass] Cứu giúp NPC: Ghi nhận Ơn Nghĩa (Debt=50) và Lòng Tin (Trust=40) chính xác")
	else:
		failed += 1
		logs.append("✗ [Fail] Cập nhật Ơn nghĩa thất bại: %s" % str(rel_saved))
		
	# Test 3: Ghi nhận sự kiện Ký ức (MemoryEvent) có nhân chứng (Witnesses)
	var mem = GameSession.log_memory_event(
		"player",
		"npc_mac_tu_vien",
		"rescue",
		"poi_rung_truc",
		["npc_bach_san", "npc_trieu_phu"],
		2,
		true
	)
	if mem["actor_id"] == "player" and mem["target_id"] == "npc_mac_tu_vien" and mem["witnesses"].size() == 2:
		passed += 1
		logs.append("✓ [Pass] Ghi nhật ký MemoryEvent chuẩn xác: Có 2 nhân chứng chứng kiến tại Rừng Trúc")
	else:
		failed += 1
		logs.append("✗ [Fail] Ghi nhật ký MemoryEvent không đúng chuẩn!")
		
	# Test 4: Gây thù chuốc oán (Grudge) khi đả thương môn đồ
	# Player đả thương một đệ tử Thanh Vi Tông -> Trưởng lão Đoàn Vĩnh ghi nhận Grudge
	GameSession.modify_npc_relationship("npc_doan_vinh", "player", -40, -50, 0, 75)
	var rel_grudge = GameSession.get_npc_relationship("npc_doan_vinh", "player")
	if rel_grudge["grudge"] == 75 and rel_grudge["affinity"] == -40:
		passed += 1
		logs.append("✓ [Pass] Hệ thống Cừu Hận (Grudge=75) ghi nhận chính xác khi phát sinh xung đột môn phái")
	else:
		failed += 1
		logs.append("✗ [Fail] Ghi nhận Grudge sai lệch: %s" % str(rel_grudge))
		
	# Test 5: Giới hạn thuộc tính quan hệ (Clamping: Affinity [-100, 100], Trust/Debt/Grudge [0, 100])
	GameSession.modify_npc_relationship("npc_doan_vinh", "player", -200, -200, 300, 300)
	var rel_clamped = GameSession.get_npc_relationship("npc_doan_vinh", "player")
	if rel_clamped["affinity"] == -100 and rel_clamped["trust"] == 0 and rel_clamped["grudge"] == 100:
		passed += 1
		logs.append("✓ [Pass] Ranh giới an toàn (Clamping): Affinity kẹp chuẩn [-100..100], Trust/Grudge kẹp [0..100]")
	else:
		failed += 1
		logs.append("✗ [Fail] Lỗi kẹp giá trị quan hệ: %s" % str(rel_clamped))
		
	return {
		"name": "Phase 2 - NPCSocialGraph",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
