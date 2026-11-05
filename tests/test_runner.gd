extends Node

## TestRunner — Chạy toàn bộ test suites của Phase 0 và Phase 1
## Môi trường: Godot 4.7.2 Headless Engine (Full Autoloads)

func _ready() -> void:
	print("\n=======================================================")
	print("  ĐẠO TÀN: VẠN KIẾP — BỘ KIỂM THỬ TỰ ĐỘNG (PHASE 0 & 1)")
	print("  Môi trường: Godot 4.7.2 Headless Engine (Full Autoloads)")
	print("=======================================================\n")
	
	var total_passed = 0
	var total_failed = 0
	
	# Phase 0 suites
	var test_clock = load("res://tests/unit/test_game_clock.gd")
	var test_clock_realtime = load("res://tests/unit/test_game_clock_realtime.gd")
	var test_seed = load("res://tests/unit/test_deterministic_seed.gd")
	var test_save = load("res://tests/unit/test_save_roundtrip.gd")
	
	# Phase 1 suites
	var test_inventory = load("res://tests/unit/test_phase1_inventory.gd")
	var test_breakthrough = load("res://tests/unit/test_phase1_breakthrough.gd")
	var test_quest = load("res://tests/unit/test_phase1_quest_flow.gd")
	var test_npc = load("res://tests/unit/test_phase1_npc_affinity.gd")
	
	# Phase 2 suites
	var test_p2_deterministic = load("res://tests/unit/test_phase2_deterministic_simulation.gd")
	var test_p2_social = load("res://tests/unit/test_phase2_npc_social_graph.gd")
	var test_p2_lifecycle = load("res://tests/unit/test_phase2_npc_lifecycle.gd")
	var test_p2_stress = load("res://tests/unit/test_phase2_headless_stress.gd")
	
	# Co-op Expansion Sprint S1 suites
	var test_coop_clock = load("res://tests/unit/test_coop_clock_sync.gd")
	
	# Option C: Phase 3 & S2/S3 suites
	var test_p3_alchemy = load("res://tests/unit/test_phase3_alchemy.gd")
	var test_p3_bosses = load("res://tests/unit/test_phase3_bosses.gd")
	var test_p3_shop = load("res://tests/unit/test_phase3_shop.gd")
	
	# Phase 4 suites: Living Town & Deep Procedural NPCs
	var test_living_town = load("res://tests/unit/test_living_town_and_procedural_npc.gd")
	
	# Phase 2 Expansion suites: Biomes & Dungeons Exploration
	var test_p2_biomes = load("res://tests/unit/test_phase2_biomes_and_dungeons.gd")
	
	# Phase 3 Expansion suites: Sects, Library & Truc Co Tribulation
	var test_p3_sects = load("res://tests/unit/test_phase3_sects_and_tribulation.gd")
	
	# Phase 4 suites: Wuxia Audio & VFX Polish
	var test_p4_audio_vfx = load("res://tests/unit/test_phase4_audio_and_vfx.gd")
	
	# Branching Dialogue & World Shaping System (3-5 Lựa chọn & Kiến tạo thế giới)
	var test_dialogue_shaping = load("res://tests/unit/test_branching_dialogue_and_world_shaping.gd")
	
	# Sprint S0 — Stability & Save Regression Suite
	var test_s0_stability = load("res://tests/unit/test_s0_stability_regression.gd")
	
	# P0 & P1 Independent Audit V2 Regression Suite (TimeScale, Space Key, Clock Boundaries, Idempotency, Crit)
	var test_p0_v2 = load("res://tests/unit/test_p0_v2_regression.gd")
	
	# P0 Independent Audit V3 Suite (Authoritative Economy, Anti-Duping, 2-Client Race, Reconnect)
	var test_p0_v3 = load("res://tests/unit/test_p0_v3_authoritative_economy.gd")
	
	# Thập Nhị Tỉnh Milestone M1: National Registry & 12 Provinces Metadata + Court Skeleton
	var test_m1 = load("res://tests/unit/test_thap_nhi_tinh_m1.gd")
	
	# Thập Nhị Tỉnh Milestone M2: Seamless Province Streaming & Core Slice 512x512
	var test_m2 = load("res://tests/unit/test_thap_nhi_tinh_m2.gd")
	
	# Thập Nhị Tỉnh Milestone M3: Functional Settlements, Roads, Fast Travel & POI Landmarks
	var test_m3 = load("res://tests/unit/test_thap_nhi_tinh_m3.gd")
	
	# Thập Nhị Tỉnh Milestone M4: Government Gameplay, Decrees Impact & World State Persistence
	var test_m4 = load("res://tests/unit/test_thap_nhi_tinh_m4.gd")
	
	# Thập Nhị Tỉnh Milestone M5: Multi-Chunk Co-op Stress Test, Anti-Duping & Performance Telemetry
	var test_m5 = load("res://tests/unit/test_thap_nhi_tinh_m5.gd")
	
	# MiniMap & WorldMap Modal Suite
	var test_map = load("res://tests/unit/test_ui_world_map.gd")
	var test_ow_mobs = load("res://tests/unit/test_openworld_interactions_and_mobs.gd")
	
	var suites = [
		test_clock.run_all_tests(),
		test_clock_realtime.run_all_tests(),
		test_seed.run_all_tests(),
		test_save.run_all_tests(),
		test_inventory.run_all_tests(),
		test_breakthrough.run_all_tests(),
		test_quest.run_all_tests(),
		test_npc.run_all_tests(),
		test_p2_deterministic.run_all_tests(),
		test_p2_social.run_all_tests(),
		test_p2_lifecycle.run_all_tests(),
		test_p2_stress.run_all_tests(),
		test_coop_clock.run_all_tests(),
		test_p3_alchemy.run_all_tests(),
		test_p3_bosses.run_all_tests(),
		test_p3_shop.run_all_tests(),
		test_living_town.run_all_tests(),
		test_p2_biomes.run_all_tests(),
		test_p3_sects.run_all_tests(),
		test_p4_audio_vfx.run_all_tests(),
		test_dialogue_shaping.run_all_tests(),
		test_s0_stability.run_all_tests(),
		test_p0_v2.run_all_tests(),
		test_p0_v3.run_all_tests(),
		test_m1.run_all_tests(),
		test_m2.run_all_tests(),
		test_m3.run_all_tests(),
		test_m4.run_all_tests(),
		test_m5.run_all_tests(),
		test_map.run_all_tests(),
		test_ow_mobs.run_all_tests()
	]
	
	for suite in suites:
		var s_name = suite.get("name", "Unknown Suite")
		print("--- Bộ test: %s ---" % s_name)
		for l in suite.get("logs", []):
			print("  " + l)
		total_passed += suite.get("passed", 0)
		total_failed += suite.get("failed", 0)
		print("")
	
	print("-------------------------------------------------------")
	print("TỔNG KẾT: %d ĐẠT (PASS) | %d THẤT BẠI (FAIL)" % [total_passed, total_failed])
	print("=======================================================\n")
	
	if total_failed == 0:
		print("[SUCCESS] Tất cả các tiêu chí nghiệm thu Phase 0 và Phase 1 đã vượt qua 100%!")
		get_tree().quit(0)
	else:
		print("[FAILURE] Có bài kiểm thử thất bại!")
		get_tree().quit(1)
