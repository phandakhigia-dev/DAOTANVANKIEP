extends RefCounted

## TestPhase3Alchemy — Kiểm thử tự động Hệ thống Luyện Đan Dược
## Đảm bảo tính toán toàn vẹn: Data loading, điều kiện tiên quyết, giao dịch nguyên tử & thành đan.

const AlchemyService = preload("res://scripts/domain/alchemy_service.gd")

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Test 1: Đăng ký và nạp đan phương
	var all_recipes = AlchemyService.get_available_recipes()
	if all_recipes.size() >= 5:
		passed += 1
		logs.append("✓ [Pass] Nạp thành công %d đan phương từ recipes.json" % all_recipes.size())
	else:
		failed += 1
		logs.append("✗ [Fail] Số lượng đan phương không đủ! (Chỉ có %d)" % all_recipes.size())
		
	# Test 2: Thẩm định điều kiện can_craft khi thiếu nguyên liệu
	GameSession.start_new_game("Kiểm Thử Đan Sư", 45678)
	GameSession.inventory.clear() # Làm rỗng túi đồ
	
	var check_empty = AlchemyService.can_craft("recipe_tu_khi_dan")
	if not check_empty["can_craft"] and check_empty["missing_materials"].size() > 0:
		passed += 1
		logs.append("✓ [Pass] can_craft từ chối chính xác khi túi đồ rỗng (Thiếu linh thảo & linh thạch)")
	else:
		failed += 1
		logs.append("✗ [Fail] can_craft không phát hiện thiếu nguyên liệu!")
		
	# Test 3: Thẩm định giới hạn cảnh giới
	GameSession.realm_id = "realm_pham_nhan"
	GameSession.add_item("item_linh_thach", 1000)
	GameSession.add_item("item_bach_thao_diep", 10)
	GameSession.add_item("item_linh_thao", 10)
	var check_realm = AlchemyService.can_craft("recipe_thanh_tam_dan")
	if not check_realm["can_craft"] and check_realm["reason"].contains("Cảnh giới"):
		passed += 1
		logs.append("✓ [Pass] can_craft chặn phàm nhân luyện chế đan dược Luyện Khí (Thanh Tâm Đan)")
	else:
		failed += 1
		logs.append("✗ [Fail] can_craft không kiểm tra cảnh giới tối thiểu!")
		
	# Test 4: Giao dịch nguyên tử (Atomic Crafting Execution)
	# Chuẩn bị nguyên liệu cho Tụ Khí Đan: 2x linh thảo, 10x linh thạch
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thao", 2)
	GameSession.add_item("item_linh_thach", 20)
	
	var craft_res = AlchemyService.craft_recipe("recipe_tu_khi_dan")
	var remaining_herbs = GameSession.get_item_count("item_linh_thao")
	var remaining_stones = GameSession.get_item_count("item_linh_thach")
	var gained_pills = GameSession.get_item_count("item_tu_khi_dan")
	
	if craft_res["success"] and remaining_herbs == 0 and remaining_stones == 10 and gained_pills == 1:
		passed += 1
		logs.append("✓ [Pass] Giao dịch nguyên tử hoàn hảo: Trừ đúng 2x Linh Thảo, 10x Linh Thạch -> Tạo 1x Tụ Khí Đan")
	else:
		failed += 1
		logs.append("✗ [Fail] Giao dịch nguyên tử sai lệch! Thảo: %d, Thạch: %d, Đan: %d" % [remaining_herbs, remaining_stones, gained_pills])
		
	# Test 5: Luyện đan cấp cao khi đã đột phá Luyện Khí
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.add_item("item_bach_thao_diep", 2)
	GameSession.add_item("item_linh_thao", 2)
	GameSession.add_item("item_linh_thach", 50)
	
	var craft_high = AlchemyService.craft_recipe("recipe_thanh_tam_dan")
	var gained_thanh_tam = GameSession.get_item_count("item_thanh_tam_dan")
	if craft_high["success"] and gained_thanh_tam == 1:
		passed += 1
		logs.append("✓ [Pass] Tu sĩ Luyện Khí khai lò thành công luyện chế Thanh Tâm Đan")
	else:
		failed += 1
		logs.append("✗ [Fail] Luyện chế Thanh Tâm Đan thất bại!")
		
	return {
		"name": "Phase 3 - AlchemySystem",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
