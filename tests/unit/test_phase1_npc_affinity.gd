extends RefCounted

## Test suite: Hệ thống 6 NPC, Hảo Cảm & Tông Môn (Phase 1)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array = []
	
	GameSession.start_new_game("Tán Tu Khách", 555333)
	
	var expected_npcs = [
		"npc_mac_tu_vien",
		"npc_lam_du",
		"npc_thu_nguyet",
		"npc_ky_hoan",
		"npc_bach_san",
		"npc_doan_vinh"
	]
	
	# Test 1: Kiểm tra đủ 6 NPC trong cơ sở dữ liệu
	var all_npcs_found = true
	for npc_id in expected_npcs:
		var def = ContentRegistry.get_npc(npc_id)
		if def.is_empty():
			all_npcs_found = false
			break
			
	if all_npcs_found:
		logs.append("✓ [Pass] Đăng ký đầy đủ 6 NPC thị trấn Thanh Trì trong ContentRegistry")
		passed += 1
	else:
		logs.append("✗ [Fail] Thiếu định nghĩa NPC trong ContentRegistry")
		failed += 1
		
	# Test 2: Kiểm tra hảo cảm khởi điểm bằng 0
	var aff_default = GameSession.get_npc_affinity("npc_mac_tu_vien")
	if aff_default == 0:
		logs.append("✓ [Pass] Hảo cảm khởi điểm với NPC bằng 0 (Trung Lập)")
		passed += 1
	else:
		logs.append("✗ [Fail] Hảo cảm khởi điểm sai khác 0")
		failed += 1
		
	# Test 3: Tăng hảo cảm thông qua tương tác / đàm đạo
	GameSession.modify_npc_affinity("npc_thu_nguyet", 15)
	if GameSession.get_npc_affinity("npc_thu_nguyet") == 15:
		logs.append("✓ [Pass] Tăng hảo cảm với Thư Nguyệt (+15) thành công")
		passed += 1
	else:
		logs.append("✗ [Fail] Cập nhật hảo cảm thất bại")
		failed += 1
		
	# Test 4: Giảm hảo cảm nếu có xung đột
	GameSession.modify_npc_affinity("npc_ky_hoan", -10)
	if GameSession.get_npc_affinity("npc_ky_hoan") == -10:
		logs.append("✓ [Pass] Ghi nhận hảo cảm âm (-10) với Kỷ Hoàn chính xác")
		passed += 1
	else:
		logs.append("✗ [Fail] Giảm hảo cảm không hoạt động")
		failed += 1
		
	# Test 5: Tông môn Thanh Vi Tông có đủ dịch vụ tiếp dẫn
	var sect_def = ContentRegistry.get_faction("sect_thanh_vi")
	var has_services = not sect_def.is_empty() and sect_def.has("services")
	if has_services:
		logs.append("✓ [Pass] Thanh Vi Tông được định nghĩa đầy đủ với các dịch vụ cúng dường & tiếp dẫn")
		passed += 1
	else:
		logs.append("✗ [Fail] Thiếu dữ liệu tông môn Thanh Vi Tông")
		failed += 1
		
	return {
		"name": "Phase 1 - NPCAffinity & Sect",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
