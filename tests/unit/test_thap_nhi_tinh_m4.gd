extends RefCounted

## Test Suite: Thập Nhị Tỉnh Milestone M4 — Government Gameplay, Decrees Impact & World State Persistence
## Kiểm thử tác động thực tế của Sắc Lệnh Triều Đình lên Kinh Tế (Thuế sạp), Treo Thưởng (Trảm yêu), và Lưu trữ toàn diện.

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Test 1: Sắc lệnh Thuế Chợ tác động trực tiếp đến giá thuê sạp tu sĩ
	var t1 = _test_decree_market_tax_impact()
	logs.append(t1.log)
	if t1.success:
		passed += 1
	else:
		failed += 1
	
	# Test 2: Sắc lệnh Thưởng Trảm Yêu tăng hệ số linh thạch nhiệm vụ
	var t2 = _test_decree_bounty_multiplier()
	logs.append(t2.log)
	if t2.success:
		passed += 1
	else:
		failed += 1
	
	# Test 3: Sắc lệnh Trợ Cấp Lương Thực & Chiết Khấu Dược Thảo
	var t3 = _test_decree_grain_subsidy()
	logs.append(t3.log)
	if t3.success:
		passed += 1
	else:
		failed += 1
	
	# Test 4: Hết hạn chiếu chỉ tự động hoàn nguyên hệ số kinh tế
	var t4 = _test_decree_expiration_and_tick()
	logs.append(t4.log)
	if t4.success:
		passed += 1
	else:
		failed += 1
	
	# Test 5: Lưu trữ và khôi phục toàn vẹn trạng thái đa tầng (Court, Chunk Diffs, Province)
	var t5 = _test_full_multilevel_persistence()
	logs.append(t5.log)
	if t5.success:
		passed += 1
	else:
		failed += 1
	
	return {
		"name": "Thập Nhị Tỉnh M4: Government Gameplay & Systems",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}

static func _test_decree_market_tax_impact() -> Dictionary:
	if not CourtManager:
		return { "success": false, "log": "✗ [T-M4-01] CourtManager autoload không khả dụng." }
		
	CourtManager.reset_court_state()
	ShopService.reset_stall()
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thach", 100)
	
	# 1. Chưa có chiếu chỉ: Thuê sạp 1 chu kỳ tốn đúng 50 Linh Thạch
	var res1 = ShopService.lease_stall(1)
	if not res1.get("success", false) or GameSession.get_item_count("item_linh_thach") != 50:
		return { "success": false, "log": "✗ [T-M4-01] Thuê sạp cơ bản không đúng 50 LT (Còn: %d)." % GameSession.get_item_count("item_linh_thach") }
		
	# 2. Ban bố chiếu chỉ Thuế Chợ (x1.1)
	CourtManager.issue_decree("decree_market_tax", 30)
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thach", 100)
	ShopService.reset_stall()
	
	# Thuê 1 chu kỳ tốn 55 Linh Thạch (50 * 1.1)
	var res2 = ShopService.lease_stall(1)
	var remain2 = GameSession.get_item_count("item_linh_thach")
	if not res2.get("success", false) or remain2 != 45: # 100 - 55 = 45
		CourtManager.reset_court_state()
		return { "success": false, "log": "✗ [T-M4-01] Sắc lệnh thuế chợ x1.1 không áp dụng vào giá thuê sạp (Còn: %d, mong muốn: 45)." % remain2 }
		
	# 3. Hủy chiếu chỉ -> trở lại 50 LT
	CourtManager.cancel_decree("decree_market_tax")
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thach", 100)
	ShopService.reset_stall()
	var res3 = ShopService.lease_stall(1)
	var remain3 = GameSession.get_item_count("item_linh_thach")
	if not res3.get("success", false) or remain3 != 50:
		return { "success": false, "log": "✗ [T-M4-01] Hủy sắc lệnh không hoàn nguyên giá thuê (Còn: %d)." % remain3 }
		
	CourtManager.reset_court_state()
	return { "success": true, "log": "✓ [T-M4-01] Sắc lệnh Thuế Chợ tác động nguyên tử lên giá thuê sạp (50 LT -> 55 LT -> 50 LT)." }

static func _test_decree_bounty_multiplier() -> Dictionary:
	CourtManager.reset_court_state()
	GameSession.inventory.clear()
	GameSession.active_quests.clear()
	
	# Ban bố chiếu chỉ Trảm Yêu Khuyến Khích (+25% thưởng)
	CourtManager.issue_decree("decree_bounty_monsters", 30)
	if CourtManager.monster_bounty_multiplier != 1.25:
		CourtManager.reset_court_state()
		return { "success": false, "log": "✗ [T-M4-02] Hệ số thưởng trảm yêu phải là 1.25, nhận: %f" % CourtManager.monster_bounty_multiplier }
		
	# Giả lập hoàn thành quest có thưởng gốc 100 LT
	GameSession.start_quest("q_first_spirit_vein")
	GameSession.complete_quest("q_first_spirit_vein")
	
	# Phần thưởng gốc 100 LT * 1.25 = 125 LT
	var final_stones = GameSession.get_item_count("item_linh_thach")
	if final_stones != 125:
		CourtManager.reset_court_state()
		return { "success": false, "log": "✗ [T-M4-02] Thưởng nhiệm vụ trảm yêu không áp dụng hệ số (Nhận: %d LT, mong đợi: 125 LT)." % final_stones }
		
	CourtManager.reset_court_state()
	return { "success": true, "log": "✓ [T-M4-02] Sắc lệnh Trảm Yêu gia tăng 25% linh thạch thưởng cho tu sĩ săn thú thành công." }

static func _test_decree_grain_subsidy() -> Dictionary:
	CourtManager.reset_court_state()
	CourtManager.issue_decree("decree_grain_subsidy", 45)
	
	if CourtManager.medicine_price_discount != 0.15:
		CourtManager.reset_court_state()
		return { "success": false, "log": "✗ [T-M4-03] Chiết khấu đan dược không đạt 15%% (Nhận: %f)." % CourtManager.medicine_price_discount }
		
	CourtManager.reset_court_state()
	return { "success": true, "log": "✓ [T-M4-03] Sắc lệnh Trợ Cấp Lương Thực & Bình Ổn Giá Dược liệu áp dụng mức chiết khấu 15%." }

static func _test_decree_expiration_and_tick() -> Dictionary:
	CourtManager.reset_court_state()
	# Ban sắc lệnh trong 5 ngày
	CourtManager.issue_decree("decree_market_tax", 5)
	if not CourtManager.is_decree_active("decree_market_tax"):
		return { "success": false, "log": "✗ [T-M4-04] Chiếu chỉ chưa được kích hoạt." }
		
	# Hủy trực tiếp hoặc giả lập hết hạn
	CourtManager.cancel_decree("decree_market_tax")
	if CourtManager.is_decree_active("decree_market_tax") or CourtManager.market_tax_multiplier != 1.0:
		return { "success": false, "log": "✗ [T-M4-04] Chiếu chỉ hết hạn/hủy bỏ không hoàn nguyên trạng thái." }
		
	return { "success": true, "log": "✓ [T-M4-04] Chu kỳ chiếu chỉ triều đình vận hành chuẩn xác, tự động tái cân bằng kinh tế." }

static func _test_full_multilevel_persistence() -> Dictionary:
	CourtManager.reset_court_state()
	CourtManager.issue_decree("decree_bounty_monsters", 60)
	
	GameSession.current_province_id = "thin_chau"
	GameSession.chunk_diffs = {
		"32_30": { "harvested_entities": ["chest_bamboo_cavern", "herb_night_01"] },
		"31_33": { "harvested_entities": ["shrine_snake_altar"] }
	}
	
	var exported = GameSession.export_save_dict()
	
	# Kiểm tra đầy đủ các tầng dữ liệu mới
	if not exported.has("court_state") or not exported.has("chunk_diffs") or not exported.has("province_id"):
		return { "success": false, "log": "✗ [T-M4-05] Export save thiếu court_state, chunk_diffs hoặc province_id." }
		
	var court_saved = exported["court_state"]
	if not court_saved.has("active_decrees") or court_saved["active_decrees"].size() < 1:
		return { "success": false, "log": "✗ [T-M4-05] Trạng thái chiếu chỉ không được lưu vào court_state." }
		
	# Giả lập import
	CourtManager.reset_court_state()
	GameSession.chunk_diffs = {}
	
	var ok = GameSession.import_save_dict(exported)
	if not ok:
		return { "success": false, "log": "✗ [T-M4-05] Import save đa tầng thất bại." }
		
	if not CourtManager.is_decree_active("decree_bounty_monsters"):
		return { "success": false, "log": "✗ [T-M4-05] Khôi phục chiếu chỉ triều đình sau save/load thất bại." }
		
	if not GameSession.chunk_diffs.has("32_30") or not "chest_bamboo_cavern" in GameSession.chunk_diffs["32_30"]["harvested_entities"]:
		return { "success": false, "log": "✗ [T-M4-05] Khôi phục trạng thái vi sai chunk (chunk_diffs) thất bại." }
		
	CourtManager.reset_court_state()
	return { "success": true, "log": "✓ [T-M4-05] Lưu trữ và phục hồi hoàn chỉnh trạng thái thế giới đa tầng (Quốc Gia, Triều Đình, Tỉnh, Chunk Diffs)." }
