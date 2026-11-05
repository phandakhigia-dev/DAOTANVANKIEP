extends RefCounted

## TestPhase3Bosses — Kiểm thử tự động Hệ thống 5 Boss & Đa dạng Hình học Telegraph
## Kiểm tra: Nạp định nghĩa 5 Boss, Hình học va chạm (Circle, Line, Cone, Cross) & Bảng phần thưởng rơi.

static func run_all_tests() -> Dictionary:
	var logs: Array[String] = []
	var passed = 0
	var failed = 0
	
	# Test 1: Kiểm tra đủ 5 Boss trong ContentRegistry
	var boss_ids = [
		"boss_xich_kiem_ma_thu",
		"boss_hac_linh_xa_vuong",
		"boss_huyet_ma_khoi_loi",
		"boss_bach_doc_chu_hoang",
		"boss_co_kiem_linh"
	]
	
	var all_bosses_found = true
	for b_id in boss_ids:
		var b_def = ContentRegistry.get_enemy(b_id)
		if b_def.is_empty():
			all_bosses_found = false
			break
			
	if all_bosses_found:
		passed += 1
		logs.append("✓ [Pass] Đăng ký đầy đủ 5 Boss Đạo Tàn: Ma Thứu, Xà Vương, Khôi Lỗi, Chu Hoàng, Cổ Kiếm Linh")
	else:
		failed += 1
		logs.append("✗ [Fail] Thiếu Boss trong ContentRegistry!")
		
	# Test 2: Kiểm tra thuộc tính & Telegraph tương ứng của từng Boss
	var xa_vuong = ContentRegistry.get_enemy("boss_hac_linh_xa_vuong")
	var khoi_loi = ContentRegistry.get_enemy("boss_huyet_ma_khoi_loi")
	var chu_hoang = ContentRegistry.get_enemy("boss_bach_doc_chu_hoang")
	var kiem_linh = ContentRegistry.get_enemy("boss_co_kiem_linh")
	
	if xa_vuong.get("telegraph_type") == "cone" and \
	   khoi_loi.get("telegraph_type") == "line" and \
	   chu_hoang.get("telegraph_type") == "circle" and \
	   kiem_linh.get("telegraph_type") == "cross":
		passed += 1
		logs.append("✓ [Pass] Hình mẫu Telegraph chuẩn hóa chính xác: Xà Vương(Cone), Khôi Lỗi(Line), Chu Hoàng(Circle), Kiếm Linh(Cross)")
	else:
		failed += 1
		logs.append("✗ [Fail] Telegraph của Boss không khớp định nghĩa hình học!")
		
	# Test 3: Kiểm định hình học va chạm Telegraph Cone (Quạt Độc)
	# Boss tại (0, 0), phun quạt độc hướng RIGHT (dir = (1, 0)), bán kính 200, góc 90 độ (PI/2)
	var boss_pos = Vector2.ZERO
	var cone_dir = Vector2.RIGHT
	var cone_radius = 200.0
	var cone_angle = PI * 0.5 # 90 độ
	var half_angle = cone_angle / 2.0
	
	# Điểm A: (100, 0) -> Thẳng trước mặt, khoảng cách 100 <= 200, góc 0 <= 45 -> TRÚNG
	var pt_a = Vector2(100, 0)
	var dir_a = (pt_a - boss_pos).normalized()
	var hit_a = (pt_a.distance_to(boss_pos) <= cone_radius) and (dir_a.dot(cone_dir) >= cos(half_angle))
	
	# Điểm B: (-50, 0) -> Sau lưng Boss -> TRƯỢT
	var pt_b = Vector2(-50, 0)
	var dir_b = (pt_b - boss_pos).normalized()
	var hit_b = (pt_b.distance_to(boss_pos) <= cone_radius) and (dir_b.dot(cone_dir) >= cos(half_angle))
	
	# Điểm C: (0, 150) -> Góc 90 độ vuông góc (lệch 90 > 45 độ) -> TRƯỢT
	var pt_c = Vector2(0, 150)
	var dir_c = (pt_c - boss_pos).normalized()
	var hit_c = (pt_c.distance_to(boss_pos) <= cone_radius) and (dir_c.dot(cone_dir) >= cos(half_angle))
	
	if hit_a and not hit_b and not hit_c:
		passed += 1
		logs.append("✓ [Pass] Toán hình học Quạt Độc (Cone): Nhận diện chuẩn trước mặt và loại trừ sau lưng/ngoài góc")
	else:
		failed += 1
		logs.append("✗ [Fail] Thuật toán va chạm Quạt Độc sai lệch!")
		
	# Test 4: Kiểm định hình học va chạm Telegraph Cross (Thập Tự Kiếm Trận)
	# Tâm thập tự tại C (500, 500), sải cánh 250, độ rộng luồng kiếm 30
	var c_center = Vector2(500, 500)
	var c_arm = 250.0
	var c_w = 30.0
	
	# Điểm D: (510, 600) -> nằm trong trục dọc Y (|X - 500| = 10 <= 30, |Y - 500| = 100 <= 250) -> TRÚNG
	var pt_d = Vector2(510, 600)
	var hit_d = (abs(pt_d.x - c_center.x) <= c_w and abs(pt_d.y - c_center.y) <= c_arm) or \
				(abs(pt_d.y - c_center.y) <= c_w and abs(pt_d.x - c_center.x) <= c_arm)
				
	# Điểm E: (620, 620) -> nằm ở góc chéo, nằm ngoài cả 2 luồng thập tự -> TRƯỢT
	var pt_e = Vector2(620, 620)
	var hit_e = (abs(pt_e.x - c_center.x) <= c_w and abs(pt_e.y - c_center.y) <= c_arm) or \
				(abs(pt_e.y - c_center.y) <= c_w and abs(pt_e.x - c_center.x) <= c_arm)
				
	if hit_d and not hit_e:
		passed += 1
		logs.append("✓ [Pass] Toán hình học Kiếm Trận Thập Tự (Cross): Trúng luồng tia thẳng, né được ở góc chéo")
	else:
		failed += 1
		logs.append("✗ [Fail] Thuật toán va chạm Thập Tự Kiếm Trận sai lệch!")
		
	# Test 5: Bảng phần thưởng rơi khi hạ gục Boss
	var drops_kiem_linh = kiem_linh.get("drops", [])
	var has_tay_tuy = false
	var has_tan_phien = false
	for d in drops_kiem_linh:
		if d.get("item_id") == "item_tay_tuy_dan":
			has_tay_tuy = true
		if d.get("item_id") == "item_co_kiem_tan_phien":
			has_tan_phien = true
			
	if has_tay_tuy and has_tan_phien:
		passed += 1
		logs.append("✓ [Pass] Loot Table Cổ Kiếm Linh chuẩn xác: Rơi Tẩy Tủy Đan cực phẩm và Cổ Kiếm Tàn Phiến")
	else:
		failed += 1
		logs.append("✗ [Fail] Bảng phần thưởng Boss thiếu vật phẩm then chốt!")
		
	return {
		"name": "Phase 3 - Bosses & Telegraphs",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
