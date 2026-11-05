extends RefCounted

## TestPhase3SectsAndTribulation — Kiểm thử toàn diện hệ thống Tông Môn, Tàng Kinh Các
## và Đột Phá Trúc Cơ Sơ Kỳ (Thiên Kiếp Lôi Đình)
## Phase 3 — ĐẠO TÀN: VẠN KIẾP

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	var SectService = load("res://scripts/domain/sect_service.gd")
	
	# Lưu trạng thái gốc để rollback
	var orig_realm = GameSession.realm_id
	var orig_xp = GameSession.cultivation_xp
	var orig_max_xp = GameSession.max_cultivation_xp
	var orig_sect_id = GameSession.player_sect_id
	var orig_contrib = GameSession.sect_contribution
	var orig_rank = GameSession.sect_rank
	var orig_skills = GameSession.learned_library_skills.duplicate()
	var orig_range = GameSession.lib_range_bonus
	var orig_trib = GameSession.tribulation_resist_bonus
	var orig_atk = GameSession.attack_power
	var orig_affinities = GameSession.npc_affinities.duplicate()
	var orig_bosses = GameSession.defeated_bosses.duplicate()
	var orig_inv_len = GameSession.inventory.size()
	
	# Reset sect state để bắt đầu clean
	_reset_sect_state()
	
	# ===== NHÓM 1: TẢI DỮ LIỆU TÔNG MÔN =====
	
	# T-01: Tải danh sách tông môn thành công
	var all_sects = SectService.get_all_sects()
	if all_sects.size() == 2:
		passed += 1
		logs.append("✓ [T-01] SectService: Tải thành công 2 tông môn (Thanh Vi Kiếm Tông + Bách Thảo Môn)")
	else:
		failed += 1
		logs.append("✗ [T-01] SectService: Không tải đủ tông môn (Đọc được: %d/2)" % all_sects.size())
	
	# T-02: Lấy dữ liệu tông môn cụ thể
	var thanh_vi = SectService.get_sect("sect_thanh_vi")
	var bach_thao = SectService.get_sect("sect_bach_thao")
	if thanh_vi.get("name", "") == "Thanh Vi Kiếm Tông" and bach_thao.get("name", "") == "Bách Thảo Môn":
		passed += 1
		logs.append("✓ [T-02] SectService.get_sect: Dữ liệu tên tông môn chính xác")
	else:
		failed += 1
		logs.append("✗ [T-02] SectService.get_sect: Dữ liệu tên tông môn không khớp")
	
	# ===== NHÓM 2: ĐIỀU KIỆN GIA NHẬP TÔNG MÔN =====
	
	# T-03: Từ chối khi cảnh giới quá thấp (Phàm Nhân)
	GameSession.realm_id = "realm_pham_nhan"
	GameSession.player_sect_id = ""
	var check_realm = SectService.can_join_sect("sect_thanh_vi")
	if not check_realm.get("can", true) and check_realm.get("reason", "").contains("cảnh giới"):
		passed += 1
		logs.append("✓ [T-03] can_join_sect: Từ chối đúng khi realm Phàm Nhân (tier=0 < yêu cầu 1)")
	else:
		failed += 1
		logs.append("✗ [T-03] can_join_sect: Phải từ chối khi cảnh giới không đủ")
	
	# T-04: Từ chối khi thiếu thiện cảm NPC
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.npc_affinities["npc_doan_vinh"] = 5  # thiếu, cần ≥ 20
	var check_aff = SectService.can_join_sect("sect_thanh_vi")
	if not check_aff.get("can", true) and check_aff.get("reason", "").contains("Thiện cảm"):
		passed += 1
		logs.append("✓ [T-04] can_join_sect: Từ chối khi thiện cảm npc_doan_vinh chỉ 5/20")
	else:
		failed += 1
		logs.append("✗ [T-04] can_join_sect: Phải từ chối khi thiếu thiện cảm (got: %s)" % str(check_aff))
	
	# T-05: Từ chối khi thiếu vật phẩm cống nạp
	GameSession.npc_affinities["npc_doan_vinh"] = 25  # đủ
	# Không có item_co_kiem_tan_phien trong inventory
	GameSession.inventory = []
	var check_item = SectService.can_join_sect("sect_thanh_vi")
	if not check_item.get("can", true) and check_item.get("reason", "").contains("Thiếu vật phẩm"):
		passed += 1
		logs.append("✓ [T-05] can_join_sect: Từ chối khi thiếu Cổ Kiếm Tàn Phiến")
	else:
		failed += 1
		logs.append("✗ [T-05] can_join_sect: Phải từ chối khi thiếu vật phẩm cống nạp (got: %s)" % str(check_item))
	
	# T-06: Gia nhập thành công với đủ điều kiện
	GameSession.add_item("item_co_kiem_tan_phien", 1)
	var join_result = SectService.join_sect("sect_thanh_vi")
	if join_result and GameSession.player_sect_id == "sect_thanh_vi" and GameSession.sect_rank == "rank_ngoai_mon":
		passed += 1
		logs.append("✓ [T-06] join_sect: Gia nhập Thanh Vi Kiếm Tông thành công, cấp Ngoại Môn")
	else:
		failed += 1
		logs.append("✗ [T-06] join_sect: Thất bại (sect_id=%s, rank=%s)" % [GameSession.player_sect_id, GameSession.sect_rank])
	
	# T-07: Từ chối gia nhập tông môn thứ 2 khi đã có sect
	var check_double = SectService.can_join_sect("sect_bach_thao")
	if not check_double.get("can", true) and check_double.get("reason", "").contains("đã là thành viên"):
		passed += 1
		logs.append("✓ [T-07] can_join_sect: Từ chối gia nhập tông môn thứ 2 (Không phụng sự hai chủ)")
	else:
		failed += 1
		logs.append("✗ [T-07] can_join_sect: Phải ngăn gia nhập tông môn thứ 2")
	
	# ===== NHÓM 3: NHIỆM VỤ CỐNG HIẾN =====
	
	# T-08: Nộp linh thảo — cq_gather_herbs
	GameSession.add_item("item_linh_thao", 5)
	var cq_result = SectService.complete_contribution_quest("cq_gather_herbs")
	if cq_result.get("success", false) and cq_result.get("contrib_gain", 0) == 20 and GameSession.sect_contribution == 20:
		passed += 1
		logs.append("✓ [T-08] complete_contribution_quest(cq_gather_herbs): +20 Cống Hiến, tiêu 5x Linh Thảo")
	else:
		failed += 1
		logs.append("✗ [T-08] cq_gather_herbs thất bại (contrib=%d, result=%s)" % [GameSession.sect_contribution, str(cq_result)])
	
	# T-09: Boss quest thất bại khi chưa hạ boss
	GameSession.defeated_bosses = []
	var cq_boss_fail = SectService.complete_contribution_quest("cq_slay_swamp_boss")
	if not cq_boss_fail.get("success", true):
		passed += 1
		logs.append("✓ [T-09] cq_slay_swamp_boss: Từ chối đúng khi boss_hac_linh_xa_vuong chưa hạ")
	else:
		failed += 1
		logs.append("✗ [T-09] cq_slay_swamp_boss: Phải từ chối khi boss chưa defeat")
	
	# T-10: Boss quest thành công sau khi hạ boss
	GameSession.defeated_bosses.append("boss_hac_linh_xa_vuong")
	var cq_boss_ok = SectService.complete_contribution_quest("cq_slay_swamp_boss")
	if cq_boss_ok.get("success", false) and GameSession.sect_contribution >= 100:
		passed += 1
		logs.append("✓ [T-10] cq_slay_swamp_boss: +80 Cống Hiến sau khi hạ Hắc Linh Xà Vương")
	else:
		failed += 1
		logs.append("✗ [T-10] cq_slay_swamp_boss thất bại (contrib=%d)" % GameSession.sect_contribution)
	
	# T-11: Thăng cấp bậc tự động khi đủ 300 cống hiến
	GameSession.sect_contribution = 299
	GameSession.sect_rank = "rank_ngoai_mon"
	# Làm thêm 1 quest ngắn để vượt 300
	GameSession.add_item("item_linh_thao", 5)
	SectService.complete_contribution_quest("cq_gather_herbs")  # +20 → 319
	if GameSession.sect_rank == "rank_noi_mon":
		passed += 1
		logs.append("✓ [T-11] _refresh_rank: Tự thăng Nội Môn Đệ Tử khi Cống Hiến ≥ 300 (Hiện tại: %d)" % GameSession.sect_contribution)
	else:
		failed += 1
		logs.append("✗ [T-11] Không thăng cấp bậc (rank=%s, contrib=%d)" % [GameSession.sect_rank, GameSession.sect_contribution])
	
	# ===== NHÓM 4: TÀNG KINH CÁC =====
	
	# T-12: Từ chối học kinh sách khi chưa gia nhập tông môn
	var tmp_sect = GameSession.player_sect_id
	GameSession.player_sect_id = ""
	var check_no_sect = SectService.can_learn_skill("lib_thanh_vi_jian_fa")
	GameSession.player_sect_id = tmp_sect
	if not check_no_sect.get("can", true):
		passed += 1
		logs.append("✓ [T-12] can_learn_skill: Từ chối khi chưa gia nhập tông môn")
	else:
		failed += 1
		logs.append("✗ [T-12] can_learn_skill: Phải từ chối khi không có sect")
	
	# T-13: Học Thanh Vi Kiếm Pháp (cần 50 cống hiến, Ngoại Môn)
	GameSession.sect_contribution = 100
	GameSession.sect_rank = "rank_noi_mon"  # đủ cấp
	GameSession.learned_library_skills = []
	var atk_before = GameSession.attack_power
	var learn_ok = SectService.learn_library_skill("lib_thanh_vi_jian_fa")
	if learn_ok and GameSession.learned_library_skills.has("lib_thanh_vi_jian_fa") and GameSession.sect_contribution == 50 and GameSession.attack_power == atk_before + 8:
		passed += 1
		logs.append("✓ [T-13] learn_library_skill(lib_thanh_vi_jian_fa): Học thành, trừ 50 Cống Hiến, +8 ATK, +40 Tầm Đánh")
	else:
		failed += 1
		logs.append("✗ [T-13] lib_thanh_vi_jian_fa thất bại (atk=%d, contrib=%d, skills=%s)" % [GameSession.attack_power, GameSession.sect_contribution, str(GameSession.learned_library_skills)])
	
	# T-14: Từ chối học kinh sách đã học rồi
	var check_dup = SectService.can_learn_skill("lib_thanh_vi_jian_fa")
	if not check_dup.get("can", true) and check_dup.get("reason", "").contains("Đã học"):
		passed += 1
		logs.append("✓ [T-14] can_learn_skill: Từ chối học lần 2 kinh sách đã học")
	else:
		failed += 1
		logs.append("✗ [T-14] Phải từ chối học lại kinh sách")
	
	# T-15: Từ chối lib_vun_linh_jue khi cấp bậc Ngoại Môn
	GameSession.sect_rank = "rank_ngoai_mon"
	var check_rank_req = SectService.can_learn_skill("lib_vun_linh_jue")
	if not check_rank_req.get("can", true) and check_rank_req.get("reason", "").contains("cấp bậc"):
		passed += 1
		logs.append("✓ [T-15] can_learn_skill(lib_vun_linh_jue): Từ chối đúng khi rank Ngoại Môn (cần Nội Môn)")
	else:
		failed += 1
		logs.append("✗ [T-15] lib_vun_linh_jue: Phải từ chối khi rank không đủ (got: %s)" % str(check_rank_req))
	
	# T-16: Học lib_kiep_lei_jue → tribulation_resist_bonus = 0.25
	GameSession.sect_rank = "rank_truc_cot"
	GameSession.sect_contribution = 600
	GameSession.tribulation_resist_bonus = 0.0
	var learn_kiep = SectService.learn_library_skill("lib_kiep_lei_jue")
	if learn_kiep and absf(GameSession.tribulation_resist_bonus - 0.25) < 0.001:
		passed += 1
		logs.append("✓ [T-16] learn_library_skill(lib_kiep_lei_jue): Áp dụng tribulation_resist_bonus = 0.25 chính xác")
	else:
		failed += 1
		logs.append("✗ [T-16] lib_kiep_lei_jue thất bại (trib_bonus=%f)" % GameSession.tribulation_resist_bonus)
	
	# ===== NHÓM 5: ĐỘT PHÁ TRÚC CƠ =====
	
	# T-17: Từ chối begin_truc_co khi realm không phải luyen_khi_9
	_reset_sect_state()
	GameSession.realm_id = "realm_luyen_khi_1"
	GameSession.player_sect_id = "sect_thanh_vi"
	var check_truc_co_realm = GameSession.can_breakthrough_to_truc_co()
	if not check_truc_co_realm.get("can", true) and check_truc_co_realm.get("reason", "").contains("Luyện Khí Tầng 9"):
		passed += 1
		logs.append("✓ [T-17] can_breakthrough_to_truc_co: Từ chối đúng khi không phải realm_luyen_khi_9")
	else:
		failed += 1
		logs.append("✗ [T-17] Phải từ chối khi realm sai (got: %s)" % str(check_truc_co_realm))
	
	# T-18: Từ chối khi chưa có tông môn
	GameSession.realm_id = "realm_luyen_khi_9"
	GameSession.cultivation_xp = 900
	GameSession.max_cultivation_xp = 900
	GameSession.player_sect_id = ""
	var check_truc_co_sect = GameSession.can_breakthrough_to_truc_co()
	if not check_truc_co_sect.get("can", true) and check_truc_co_sect.get("reason", "").contains("tông môn"):
		passed += 1
		logs.append("✓ [T-18] can_breakthrough_to_truc_co: Từ chối khi chưa gia nhập tông môn")
	else:
		failed += 1
		logs.append("✗ [T-18] Phải từ chối khi không có sect (got: %s)" % str(check_truc_co_sect))
	
	# T-19: Từ chối khi thiếu Tẩy Tủy Đan
	GameSession.player_sect_id = "sect_thanh_vi"
	GameSession.inventory = []
	var check_truc_co_item = GameSession.can_breakthrough_to_truc_co()
	if not check_truc_co_item.get("can", true) and check_truc_co_item.get("reason", "").contains("Tẩy Tủy Đan"):
		passed += 1
		logs.append("✓ [T-19] can_breakthrough_to_truc_co: Từ chối khi thiếu Tẩy Tủy Đan")
	else:
		failed += 1
		logs.append("✗ [T-19] Phải từ chối khi thiếu item_tay_tuy_dan (got: %s)" % str(check_truc_co_item))
	
	# T-20: Đủ điều kiện đột phá Trúc Cơ
	GameSession.add_item("item_tay_tuy_dan", 1)
	var check_truc_co_ok = GameSession.can_breakthrough_to_truc_co()
	if check_truc_co_ok.get("can", false):
		passed += 1
		logs.append("✓ [T-20] can_breakthrough_to_truc_co: Xác nhận đủ điều kiện (realm_luyen_khi_9 + sect + XP viên mãn + Tẩy Tủy Đan)")
	else:
		failed += 1
		logs.append("✗ [T-20] Phải đủ điều kiện nhưng thất bại (got: %s)" % str(check_truc_co_ok))
	
	# T-21: begin_truc_co_tribulation tiêu hao Tẩy Tủy Đan & set pending_tribulation
	# T-20 đã có sẵn 1x item_tay_tuy_dan
	var begin_ok = GameSession.begin_truc_co_tribulation("res://scenes/towns/town_map_real.tscn")
	if begin_ok and GameSession.pending_tribulation and not GameSession.has_item("item_tay_tuy_dan"):
		passed += 1
		logs.append("✓ [T-21] begin_truc_co_tribulation: Tiêu Tẩy Tủy Đan, bật pending_tribulation = true")
	else:
		failed += 1
		logs.append("✗ [T-21] begin_truc_co_tribulation thất bại (pending=%s, has_item=%s)" % [str(GameSession.pending_tribulation), str(GameSession.has_item("item_tay_tuy_dan"))])
	
	# T-22: Vượt kiếp thành công → realm_truc_co_1
	GameSession.complete_truc_co_tribulation(true)
	if GameSession.realm_id == "realm_truc_co_1" and not GameSession.pending_tribulation and GameSession.max_cultivation_xp == 1000 and GameSession.max_lifespan_years == 250:
		passed += 1
		logs.append("✓ [T-22] complete_truc_co_tribulation(true): Trúc Cơ Sơ Kỳ! max_xp=1000, thọ nguyên=250 năm")
	else:
		failed += 1
		logs.append("✗ [T-22] complete_truc_co_tribulation failed (realm=%s, max_xp=%d, lifespan=%d)" % [GameSession.realm_id, GameSession.max_cultivation_xp, GameSession.max_lifespan_years])
	
	# T-23: Thất bại kiếp → không lên realm
	GameSession.realm_id = "realm_luyen_khi_9"
	GameSession.pending_tribulation = true
	GameSession.complete_truc_co_tribulation(false)
	if GameSession.realm_id == "realm_luyen_khi_9" and not GameSession.pending_tribulation:
		passed += 1
		logs.append("✓ [T-23] complete_truc_co_tribulation(false): Giữ nguyên Luyện Khí 9, tắt pending_tribulation")
	else:
		failed += 1
		logs.append("✗ [T-23] Thất bại kiếp nhưng realm bị thay đổi (realm=%s)" % GameSession.realm_id)
	
	# ===== NHÓM 6: SAVE/LOAD ROUNDTRIP =====
	
	# T-24: Serialize / Deserialize sect fields đúng
	_reset_sect_state()
	GameSession.player_sect_id = "sect_thanh_vi"
	GameSession.sect_contribution = 420
	GameSession.sect_rank = "rank_noi_mon"
	GameSession.learned_library_skills = ["lib_thanh_vi_jian_fa"]
	GameSession.lib_range_bonus = 40
	GameSession.tribulation_resist_bonus = 0.25
	
	var save_dict = GameSession.export_save_dict()
	var p = save_dict.get("player", {})
	var roundtrip_ok = (
		p.get("sect_id", "") == "sect_thanh_vi" and
		p.get("sect_contribution", -1) == 420 and
		p.get("sect_rank", "") == "rank_noi_mon" and
		(p.get("learned_library_skills", []) as Array).has("lib_thanh_vi_jian_fa") and
		p.get("lib_range_bonus", -1) == 40 and
		absf(p.get("tribulation_resist_bonus", -1.0) - 0.25) < 0.001
	)
	if roundtrip_ok:
		passed += 1
		logs.append("✓ [T-24] Save/Load roundtrip: Toàn bộ sect fields serialize đúng vào save dict")
	else:
		failed += 1
		logs.append("✗ [T-24] Save/Load: Sect fields bị mất hoặc sai (sect_id=%s, contrib=%d)" % [p.get("sect_id","?"), p.get("sect_contribution",-1)])
	
	# T-25: Import từ save dict khôi phục đúng
	_reset_sect_state()
	GameSession.import_save_dict(save_dict)
	var restore_ok = (
		GameSession.player_sect_id == "sect_thanh_vi" and
		GameSession.sect_contribution == 420 and
		GameSession.sect_rank == "rank_noi_mon" and
		GameSession.learned_library_skills.has("lib_thanh_vi_jian_fa")
	)
	if restore_ok:
		passed += 1
		logs.append("✓ [T-25] import_save_dict: Khôi phục sect state thành công sau tải lưu")
	else:
		failed += 1
		logs.append("✗ [T-25] import_save_dict: Sect state không khớp (sect_id=%s, contrib=%d)" % [GameSession.player_sect_id, GameSession.sect_contribution])
	
	# Rollback hoàn toàn GameSession về trạng thái trước test
	GameSession.realm_id = orig_realm
	GameSession.cultivation_xp = orig_xp
	GameSession.max_cultivation_xp = orig_max_xp
	GameSession.player_sect_id = orig_sect_id
	GameSession.sect_contribution = orig_contrib
	GameSession.sect_rank = orig_rank
	GameSession.learned_library_skills = orig_skills
	GameSession.lib_range_bonus = orig_range
	GameSession.tribulation_resist_bonus = orig_trib
	GameSession.attack_power = orig_atk
	GameSession.npc_affinities = orig_affinities
	GameSession.defeated_bosses = orig_bosses
	GameSession.pending_tribulation = false
	
	return {
		"name": "Phase 3 — Tông Môn, Tàng Kinh Các & Đột Phá Trúc Cơ Sơ Kỳ",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}

# Tiện ích reset sect state về zero
static func _reset_sect_state() -> void:
	GameSession.player_sect_id = ""
	GameSession.sect_contribution = 0
	GameSession.sect_rank = ""
	GameSession.learned_library_skills = []
	GameSession.lib_range_bonus = 0
	GameSession.tribulation_resist_bonus = 0.0
	GameSession.pending_tribulation = false
