class_name TestThapNhiTinhM1
extends RefCounted

## TestThapNhiTinhM1 — Kiểm thử Milestone M1: National Registry & 12 Provinces Metadata + Court Skeleton
## Bao gồm:
##   1. T-M1-01: Load World Registry & 12 Tỉnh (Thập Nhị Địa Chi).
##   2. T-M1-02: Kiến trúc Tỉnh Thìn Châu (4096×4096 tile, chunk 64, 5 khu định cư).
##   3. T-M1-03: Triều Đình Đại Huyền & Cơ chế Sắc Lệnh Quốc Gia (Thuế, Trảm Yêu, Bình Ổn Giá).
##   4. T-M1-04: Đóng gói và Khôi phục Court State Serialization.
##   5. T-M1-05: Đảm bảo tương thích ngược không xung đột ContentRegistry cũ.

const WorldRegistryScript = preload("res://scripts/world/world_registry.gd")
const CourtManagerScript = preload("res://scripts/politics/court_manager.gd")

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []

	var world_reg = WorldRegistryScript.new()
	world_reg.load_all_world_data()

	var court = CourtManagerScript.new()
	court.reset_court_state()

	# ==============================================================================
	# 1. TEST T-M1-01: LOAD WORLD REGISTRY & 12 TỈNH
	# ==============================================================================
	var winfo = world_reg.get_world_info()
	var all_provinces = world_reg.get_all_provinces()
	var prov_count = all_provinces.size()
	var playable_id = world_reg.get_playable_province_id()

	if prov_count == 12 and playable_id == "thin_chau" and winfo.get("country_id") == "dai_huyen":
		passed += 1
		logs.append("✓ [T-M1-01] Nạp thành công World Registry: Đại Huyền Quốc gồm đúng 12 tỉnh, Thìn Châu là tỉnh playable.")
	else:
		failed += 1
		logs.append("✗ [T-M1-01] Thất bại: Đếm được %d/12 tỉnh, playable_id = %s" % [prov_count, playable_id])

	# ==============================================================================
	# 2. TEST T-M1-02: KIẾN TRÚC TỈNH THÌN CHÂU
	# ==============================================================================
	var thin_chau = world_reg.get_playable_province()
	var size_tiles = thin_chau.get("size_tiles", [])
	var chunk_size = thin_chau.get("chunk_size_tiles", 0)
	var settlements = thin_chau.get("settlements", [])
	var has_thanh_tri = false
	var has_long_kinh = false

	for s in settlements:
		if s.get("id") == "settlement_thanh_tri":
			has_thanh_tri = true
		elif s.get("id") == "settlement_long_kinh":
			has_long_kinh = true

	if size_tiles.size() == 2 and size_tiles[0] == 4096 and size_tiles[1] == 4096 and chunk_size == 64 and has_thanh_tri and has_long_kinh:
		passed += 1
		logs.append("✓ [T-M1-02] Kiến trúc Thìn Châu chuẩn hóa: 4096×4096 tile, Chunk 64×64, có Huyện Thành Thanh Trì & Kinh Đô Long Kinh.")
	else:
		failed += 1
		logs.append("✗ [T-M1-02] Thất bại: Thìn Châu sai thông số hoặc thiếu settlements. Size: %s, Chunk: %d" % [str(size_tiles), chunk_size])

	# ==============================================================================
	# 3. TEST T-M1-03: TRIỀU ĐÌNH ĐẠI HUYỀN & SẮC LỆNH
	# ==============================================================================
	court.reset_court_state()
	var ok_tax = court.issue_decree("decree_market_tax", 30)
	var mult_tax = court.market_tax_multiplier
	var ok_bounty = court.issue_decree("decree_bounty_monsters", 30)
	var mult_bounty = court.monster_bounty_multiplier
	var ok_subsidy = court.issue_decree("decree_grain_subsidy", 15)
	var disc_medicine = court.medicine_price_discount

	if ok_tax and ok_bounty and ok_subsidy and is_equal_approx(mult_tax, 1.1) and is_equal_approx(mult_bounty, 1.25) and is_equal_approx(disc_medicine, 0.15):
		passed += 1
		logs.append("✓ [T-M1-03] Triều Đình Đại Huyền vận hành chuẩn: Ban bố thành công 3 sắc lệnh (Thuế chợ x1.1, Trảm yêu x1.25, Chiết khấu đan dược 15%).")
	else:
		failed += 1
		logs.append("✗ [T-M1-03] Thất bại: Sắc lệnh không tính toán đúng hệ số. Tax: %f, Bounty: %f, Disc: %f" % [mult_tax, mult_bounty, disc_medicine])

	# ==============================================================================
	# 4. TEST T-M1-04: COURT SERIALIZATION ROUND-TRIP
	# ==============================================================================
	var exported_court = court.export_court_dict()
	var court2 = CourtManagerScript.new()
	court2.import_court_dict(exported_court)

	if court2.get_active_decrees().size() == 3 and is_equal_approx(court2.market_tax_multiplier, 1.1) and is_equal_approx(court2.monster_bounty_multiplier, 1.25):
		passed += 1
		logs.append("✓ [T-M1-04] Lưu trữ trạng thái Triều Đình bền vững: Export và Import round-trip chính xác.")
	else:
		failed += 1
		logs.append("✗ [T-M1-04] Thất bại: Import court dict không bảo toàn dữ liệu.")

	# ==============================================================================
	# 5. TEST T-M1-05: TƯƠNG THÍCH NGƯỢC KHÔNG XUNG ĐỘT
	# ==============================================================================
	var reg_thanh_tri = ContentRegistry.get_region("reg_thanh_tri")
	var item_check = ContentRegistry.get_item("item_hoi_xuan_dan")
	var skill_check = ContentRegistry.get_skill("skill_basic_slash")

	if not reg_thanh_tri.is_empty() and not item_check.is_empty() and not skill_check.is_empty():
		passed += 1
		logs.append("✓ [T-M1-05] Tương thích ngược toàn vẹn: ContentRegistry nạp dữ liệu cũ bình thường, không xung đột module.")
	else:
		failed += 1
		logs.append("✗ [T-M1-05] Thất bại: ContentRegistry bị ảnh hưởng hoặc thiếu dữ liệu cũ.")

	return {
		"name": "Thập Nhị Tỉnh M1: National Registry & 12 Provinces Metadata + Court Skeleton",
		"passed": passed,
		"failed": failed,
		"total": passed + failed,
		"logs": logs
	}
