extends RefCounted

## TestPhase4AudioAndVFX — Kiểm thử toàn diện Hệ thống Âm Thanh & Hiệu Ứng Hình Ảnh Võ Hiệp
## Phase 4 — ĐẠO TÀN: VẠN KIẾP

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	# ===== NHÓM 1: KHỞI TẠO AUDIOSERVICE & CẤU HÌNH BUS =====
	
	# T-01: Kiểm tra AudioService tồn tại và hoạt động
	var audio_srv = Engine.get_main_loop().root.get_node_or_null("AudioService")
	if audio_srv != null:
		passed += 1
		logs.append("✓ [T-01] AudioService: Autoload đăng ký và khởi tạo thành công trên SceneTree")
	else:
		failed += 1
		logs.append("✗ [T-01] AudioService: Không tìm thấy node Autoload trên SceneTree")
		return { "name": "Phase 4 - Audio & VFX Polish", "passed": passed, "failed": failed, "logs": logs }
	
	# T-02: Kiểm tra cấu hình âm lượng mặc định
	if is_equal_approx(audio_srv.master_volume, 0.8) and is_equal_approx(audio_srv.bgm_volume, 0.7) and is_equal_approx(audio_srv.sfx_volume, 0.8):
		passed += 1
		logs.append("✓ [T-02] AudioService: Giá trị âm lượng mặc định chuẩn (Master: 0.8, BGM: 0.7, SFX: 0.8)")
	else:
		failed += 1
		logs.append("✗ [T-02] AudioService: Giá trị âm lượng mặc định sai lệch")
	
	# T-03: Điều chỉnh âm lượng & chuyển đổi dB tuyến tính
	var old_vol = audio_srv.master_volume
	audio_srv.set_master_volume(0.5)
	if is_equal_approx(audio_srv.master_volume, 0.5):
		passed += 1
		logs.append("✓ [T-03] set_master_volume: Cập nhật âm lượng tuyến tính chính xác (0.5)")
	else:
		failed += 1
		logs.append("✗ [T-03] set_master_volume: Thất bại khi gán âm lượng")
	audio_srv.set_master_volume(old_vol)
	
	# ===== NHÓM 2: BỘ TỔNG HỢP ÂM THANH THỦ TỤC VÕ HIỆP =====
	
	# T-04: Kiểm tra tổng hợp kho hiệu ứng âm thanh (SFX)
	var expected_sfx = [
		"sfx_sword_slash", "sfx_lightning_strike", "sfx_breakthrough_bell",
		"sfx_pill_swallow", "sfx_alchemy_bubble", "sfx_herb_pickup",
		"sfx_sect_chime", "sfx_footstep"
	]
	var sfx_all_ok = true
	for s_id in expected_sfx:
		if not audio_srv.sound_cache.has(s_id):
			sfx_all_ok = false
			break
		var stream = audio_srv.sound_cache[s_id]
		if not (stream is AudioStreamWAV) or stream.data.size() == 0:
			sfx_all_ok = false
			break
			
	if sfx_all_ok:
		passed += 1
		logs.append("✓ [T-04] Procedural Synthesis: Tổng hợp thành công đầy đủ 8 mẫu SFX võ hiệp (16-bit PCM)")
	else:
		failed += 1
		logs.append("✗ [T-04] Procedural Synthesis: Thiếu hoặc lỗi dữ liệu trong kho SFX")
	
	# T-05: Kiểm tra tổng hợp nhạc nền cổ phong (BGM Ngũ Cung & Sáo Trúc)
	var expected_bgm = ["bgm_peaceful_town", "bgm_bamboo_forest", "bgm_tribulation"]
	var bgm_all_ok = true
	for b_id in expected_bgm:
		if not audio_srv.sound_cache.has(b_id):
			bgm_all_ok = false
			break
		var stream = audio_srv.sound_cache[b_id]
		if not (stream is AudioStreamWAV) or stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			bgm_all_ok = false
			break
			
	if bgm_all_ok:
		passed += 1
		logs.append("✓ [T-05] Procedural BGM: Tạo thành công 3 khúc nhạc cổ phong lặp tuần hoàn (Cổ Cầm & Sáo Trúc)")
	else:
		failed += 1
		logs.append("✗ [T-05] Procedural BGM: Nhạc nền thiếu thuộc tính loop hoặc rỗng")
	
	# T-06: Phát SFX từ Pool AudioStreamPlayer
	var p = audio_srv.play_sfx("sfx_sword_slash", 1.1, -1.0)
	if p != null and p.stream != null:
		passed += 1
		logs.append("✓ [T-06] play_sfx: Lấy thành công player từ pool và gán AudioStream (%s)" % p.name)
	else:
		failed += 1
		logs.append("✗ [T-06] play_sfx: Không thể phát âm thanh")
	
	# T-07: Chuyển bài BGM chính xác
	audio_srv.play_bgm("bgm_peaceful_town")
	if audio_srv.current_bgm_id == "bgm_peaceful_town" and audio_srv.bgm_player.stream != null:
		passed += 1
		logs.append("✓ [T-07] play_bgm: Chuyển nhạc nền sang 'bgm_peaceful_town' thành công")
	else:
		failed += 1
		logs.append("✗ [T-07] play_bgm: Gán track BGM thất bại")
		
	# ===== NHÓM 3: KHỞI TẠO CÁC HIỆU ỨNG HÌNH ẢNH (VFX SCENES) =====
	
	# T-08: VFX Kiếm Khí Xé Gió (VFXSwordSlash)
	var SlashScene = load("res://scenes/vfx/vfx_sword_slash.tscn")
	if SlashScene != null:
		var slash_inst = SlashScene.instantiate()
		var has_sparks = slash_inst.get_node_or_null("Sparks") != null
		if has_sparks:
			passed += 1
			logs.append("✓ [T-08] VFXSwordSlash: Khởi tạo thành công vòng cung kiếm quang & tia lửa kiếm ý")
		else:
			failed += 1
			logs.append("✗ [T-08] VFXSwordSlash: Thiếu node Sparks")
		slash_inst.queue_free()
	else:
		failed += 1
		logs.append("✗ [T-08] VFXSwordSlash: Không tải được scene")
	
	# T-09: VFX Hào Quang Linh Khí & Đột Phá (VFXCultivationAura)
	var AuraScene = load("res://scenes/vfx/vfx_cultivation_aura.tscn")
	if AuraScene != null:
		var aura_inst = AuraScene.instantiate()
		aura_inst.setup_aura(true, 2.5) # Thiết lập chế độ hoàng kim đột phá
		var has_aura = aura_inst.get_node_or_null("AuraParticles") != null
		var has_sparks = aura_inst.get_node_or_null("SparkParticles") != null
		if has_aura and has_sparks and aura_inst.is_breakthrough:
			passed += 1
			logs.append("✓ [T-09] VFXCultivationAura: Khởi tạo linh khí đan điền & chế độ Hoàng Kim Đột Phá")
		else:
			failed += 1
			logs.append("✗ [T-09] VFXCultivationAura: Cấu hình hạt linh khí không khớp")
		aura_inst.queue_free()
	else:
		failed += 1
		logs.append("✗ [T-09] VFXCultivationAura: Không tải được scene")
	
	# T-10: VFX Lôi Bạo Điểm Giáng (VFXLightningImpact)
	var LightScene = load("res://scenes/vfx/vfx_lightning_impact.tscn")
	if LightScene != null:
		var light_inst = LightScene.instantiate()
		var has_shockwave = light_inst.get_node_or_null("Shockwave") != null
		var has_sparks = light_inst.get_node_or_null("Sparks") != null
		if has_shockwave and has_sparks:
			passed += 1
			logs.append("✓ [T-10] VFXLightningImpact: Sóng xung kích lôi điện & hạt nổ điện trường hoàn chỉnh")
		else:
			failed += 1
			logs.append("✗ [T-10] VFXLightningImpact: Thiếu node Shockwave hoặc Sparks")
		light_inst.queue_free()
	else:
		failed += 1
		logs.append("✗ [T-10] VFXLightningImpact: Không tải được scene")
	
	# T-11: VFX Môi Trường Lá Trúc Rơi (VFXBambooLeaves)
	var LeavesScene = load("res://scenes/vfx/vfx_bamboo_leaves.tscn")
	if LeavesScene != null:
		var leaves_inst = LeavesScene.instantiate()
		var has_leaves = leaves_inst.get_node_or_null("LeafParticles") != null
		var has_pollen = leaves_inst.get_node_or_null("PollenParticles") != null
		if has_leaves and has_pollen:
			passed += 1
			logs.append("✓ [T-11] VFXBambooLeaves: Khởi tạo thành công hạt lá trúc rơi & phấn hoa mộc linh")
		else:
			failed += 1
			logs.append("✗ [T-11] VFXBambooLeaves: Thiếu cấu hình hạt lá trúc")
		leaves_inst.queue_free()
	else:
		failed += 1
		logs.append("✗ [T-11] VFXBambooLeaves: Không tải được scene")
	
	# T-12: VFX Đan Lô Sôi Sục & Kim Đan Xuất Lô (VFXAlchemyGlow)
	var AlcGlowScene = load("res://scenes/vfx/vfx_alchemy_glow.tscn")
	if AlcGlowScene != null:
		var alc_inst = AlcGlowScene.instantiate()
		var has_smoke = alc_inst.get_node_or_null("CauldronSmoke") != null
		var has_sparks = alc_inst.get_node_or_null("GoldenSparks") != null
		if has_smoke and has_sparks:
			passed += 1
			logs.append("✓ [T-12] VFXAlchemyGlow: Đan khí tím tía bốc cao & tia sáng kim đan xuất lô")
		else:
			failed += 1
			logs.append("✗ [T-12] VFXAlchemyGlow: Thiếu node khói hoặc ánh sáng kim đan")
		alc_inst.queue_free()
	else:
		failed += 1
		logs.append("✗ [T-12] VFXAlchemyGlow: Không tải được scene")
		
	# ===== NHÓM 4: TÍCH HỢP TƯƠNG TÁC GAME VỚI HỆ THỐNG ÂM THANH =====
	
	# T-13: Tiêu thụ đan dược kích hoạt SFX nuốt đan
	GameSession.add_item("item_hoi_xuan_dan", 2)
	GameSession.current_hp = 30
	var tracker = { "sounds": [] }
	var on_sfx = func(s): tracker["sounds"].append(s)
	audio_srv.sfx_played.connect(on_sfx)
	
	GameSession.use_item("item_hoi_xuan_dan")
	audio_srv.sfx_played.disconnect(on_sfx)
	
	if tracker["sounds"].has("sfx_pill_swallow"):
		passed += 1
		logs.append("✓ [T-13] Tích Hợp GameSession: Nuốt đan dược tự động kích hoạt 'sfx_pill_swallow' (Lịch sử SFX: %s)" % str(tracker["sounds"]))
	else:
		failed += 1
		logs.append("✗ [T-13] GameSession: Không kích hoạt âm thanh nuốt đan (got: %s)" % str(tracker["sounds"]))
	
	return {
		"name": "Phase 4 — Tinh Chỉnh Hiệu Ứng Hình Ảnh & Âm Thanh Võ Hiệp (VFX & Audio Polish)",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
