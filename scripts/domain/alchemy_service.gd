extends RefCounted
class_name AlchemyService

## AlchemyService — Hệ thống Luyện Đan Dược (Pill Crafting Domain)
## Xử lý giao dịch nguyên tử: tiêu hao dược liệu thảo dược + linh thạch -> xuất thành phẩm linh đan.

signal alchemy_crafted(recipe_id: String, output_item_id: String, count: int, success: bool)

static func get_available_recipes() -> Array:
	return ContentRegistry.get_all_recipes()

static func can_craft(recipe_id: String) -> Dictionary:
	var recipe = ContentRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return { "can_craft": false, "reason": "Đan phương không tồn tại!", "missing_materials": [], "missing_stones": 0 }
	
	# Kiểm tra cảnh giới tối thiểu
	var req_realm = recipe.get("required_realm", "realm_pham_nhan")
	if req_realm == "realm_luyen_khi_1" and GameSession.realm_id == "realm_pham_nhan":
		return { "can_craft": false, "reason": "Cảnh giới chưa đủ! Cần tối thiểu Luyện Khí Tầng 1 để khống chế đan hỏa.", "missing_materials": [], "missing_stones": 0 }
	
	# Kiểm tra linh thạch
	var cost_stones = recipe.get("cost_spirit_stones", 0)
	var current_stones = GameSession.get_item_count("item_linh_thach")
	var missing_stones = max(0, cost_stones - current_stones)
	
	# Kiểm tra nguyên liệu
	var missing_mats: Array = []
	var materials = recipe.get("materials", [])
	for mat in materials:
		var mat_id = mat.get("item_id", "")
		var req_count = mat.get("count", 1)
		var current_count = GameSession.get_item_count(mat_id)
		if current_count < req_count:
			missing_mats.append({
				"item_id": mat_id,
				"required": req_count,
				"current": current_count,
				"missing": req_count - current_count
			})
	
	var can_craft_val = (missing_stones == 0 and missing_mats.size() == 0)
	var reason_val = "Đủ điều kiện khai lò luyện đan." if can_craft_val else "Thiếu linh thạch hoặc nguyên liệu!"
	
	return {
		"can_craft": can_craft_val,
		"reason": reason_val,
		"missing_materials": missing_mats,
		"missing_stones": missing_stones
	}

static func craft_recipe(recipe_id: String) -> Dictionary:
	var check = can_craft(recipe_id)
	if not check["can_craft"]:
		return {
			"success": false,
			"reason": check["reason"],
			"recipe_id": recipe_id,
			"item_id": "",
			"count": 0
		}
	
	var recipe = ContentRegistry.get_recipe(recipe_id)
	var cost_stones = recipe.get("cost_spirit_stones", 0)
	var materials = recipe.get("materials", [])
	var out_id = recipe.get("output_item_id", "")
	var out_count = recipe.get("output_count", 1)
	var success_rate = recipe.get("success_rate", 1.0)
	
	# Tiêu hao nguyên tử: Trừ linh thạch và dược thảo
	if cost_stones > 0:
		var stone_deducted = GameSession.remove_item("item_linh_thach", cost_stones)
		if not stone_deducted:
			return { "success": false, "reason": "Giao dịch lỗi: Không đủ linh thạch!", "recipe_id": recipe_id, "item_id": "", "count": 0 }
	
	for mat in materials:
		var mat_id = mat.get("item_id", "")
		var req_count = mat.get("count", 1)
		var mat_deducted = GameSession.remove_item(mat_id, req_count)
		if not mat_deducted:
			return { "success": false, "reason": "Giao dịch lỗi: Không đủ nguyên liệu %s!" % mat_id, "recipe_id": recipe_id, "item_id": "", "count": 0 }
	
	# Kiểm tra tỉ lệ thành công
	var roll = RNGService.randf()
	if roll <= success_rate:
		GameSession.add_item(out_id, out_count)
		var item_def = ContentRegistry.get_item(out_id)
		var item_name = item_def.get("name", out_id)
		if EventBus:
			EventBus.notification_requested.emit("Khai lò viên mãn! Luyện thành công %dx %s!" % [out_count, item_name], "success")
		return {
			"success": true,
			"reason": "Luyện đan thành công!",
			"recipe_id": recipe_id,
			"item_id": out_id,
			"count": out_count
		}
	else:
		if EventBus:
			EventBus.notification_requested.emit("Đan hỏa bạo động! Lô đan bị cháy rụi thành phế đan!", "warning")
		return {
			"success": false,
			"reason": "Đan hỏa bất ổn định, dược liệu đã hóa thành tro!",
			"recipe_id": recipe_id,
			"item_id": "",
			"count": 0
		}
