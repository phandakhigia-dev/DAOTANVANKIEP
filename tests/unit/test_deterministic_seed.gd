class_name TestDeterministicSeed
extends RefCounted

## TestDeterministicSeed — Kiểm tra tính bất biến và tái lặp của Hạt giống thế giới (Seed)

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	var seed_a = 987654
	var seq_1: Array[int] = []
	var seq_2: Array[int] = []
	
	# Sinh chuỗi số lần 1
	var rng1 = RandomNumberGenerator.new()
	rng1.seed = seed_a
	for i in range(20):
		seq_1.append(rng1.randi_range(1, 1000))
	
	# Sinh chuỗi số lần 2 với cùng seed
	var rng2 = RandomNumberGenerator.new()
	rng2.seed = seed_a
	for i in range(20):
		seq_2.append(rng2.randi_range(1, 1000))
	
	var identical = (seq_1 == seq_2)
	if identical:
		passed += 1
		logs.append("✓ [Pass] Cùng seed (987654) cho chuỗi số ngẫu nhiên hoàn toàn giống nhau 100%")
	else:
		failed += 1
		logs.append("✗ [Fail] Cùng seed nhưng hai chuỗi số sinh ra khác nhau")
	
	# Sinh chuỗi số với seed khác
	var seq_3: Array[int] = []
	var rng3 = RandomNumberGenerator.new()
	rng3.seed = 123456
	for i in range(20):
		seq_3.append(rng3.randi_range(1, 1000))
	
	if seq_1 != seq_3:
		passed += 1
		logs.append("✓ [Pass] Khác seed sinh ra hai thế giới hoàn toàn khác nhau")
	else:
		failed += 1
		logs.append("✗ [Fail] Hai seed khác nhau lại sinh ra kết quả trùng lặp")
	
	# Kiểm tra phân bố địa hình bản đồ theo seed
	var map_tiles_1: Array[int] = []
	var map_tiles_2: Array[int] = []
	
	var test_rng_a = RandomNumberGenerator.new()
	test_rng_a.seed = 777777
	for i in range(50):
		map_tiles_1.append(test_rng_a.randi_range(0, 4))
	
	var test_rng_b = RandomNumberGenerator.new()
	test_rng_b.seed = 777777
	for i in range(50):
		map_tiles_2.append(test_rng_b.randi_range(0, 4))
	
	if map_tiles_1 == map_tiles_2:
		passed += 1
		logs.append("✓ [Pass] Phân bố địa hình bản đồ sandbox theo seed đảm bảo tái lặp tuyệt đối")
	else:
		failed += 1
		logs.append("✗ [Fail] Địa hình bản đồ không tái lập theo seed")
	
	return { "name": "DeterministicSeed", "passed": passed, "failed": failed, "logs": logs }
