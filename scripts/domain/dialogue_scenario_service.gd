class_name DialogueScenarioService
extends RefCounted

## DialogueScenarioService — Bộ máy Tình Huống Hội Thoại Phân Nhánh & Kiến Tạo Thế Giới
## Thiết kế theo nguyên lý "Cơ Duyên Bí Mật & Khó Lường" (Unpredictable & Secret Karma):
##   - Hoàn toàn KHÔNG hiển thị trước được gì mất gì trên các lựa chọn.
##   - Người chơi đưa ra quyết định dựa trên đạo tâm, lập trường và ngữ cảnh lời thoại.
##   - Hệ quả thực tế biến chuyển ngẫu nhiên và bí mật:
##       * Hảo cảm, Tín nhiệm, Thù hận, Kính sợ (Relationships)
##       * Ký ức thế giới (log_memory_event) lan truyền giang hồ
##       * Điều tiết thị trường kinh tế (market_modifiers)
##       * Đột phá tu vi, thay đổi số phận NPC
##       * Kỳ ngộ / Dị biến bất ngờ theo hạt giống thế giới

const CATEGORY_COLORS: Dictionary = {
	"righteous": Color(0.4, 0.9, 0.55),     # Xanh ngọc lục bảo (Chính Đạo / Hiệp Nghĩa)
	"demonic": Color(0.95, 0.35, 0.35),     # Đỏ huyết ma sát (Ma Đạo / Bá Đạo / Ép Giá)
	"pragmatic": Color(1.0, 0.85, 0.3),     # Hoàng kim hổ phách (Thương Lộ / Mưu Lược)
	"enlightenment": Color(0.35, 0.8, 1.0), # Lam thiên đạo duyên (Đạo Duyên / Chỉ Điểm)
	"aloof": Color(0.75, 0.75, 0.8)         # Bạch ngân thanh khiết (Bình Thản / Tiêu Diêu)
}

static func hash_string(text: String) -> int:
	var h: int = 5381
	for i in range(text.length()):
		h = ((h << 5) + h) + text.unicode_at(i)
		h = h & 0x7FFFFFFF
	return abs(h)

## Sinh tình huống hội thoại 3-5 lựa chọn cho NPC (Cốt truyện hoặc Tán tu ngẫu nhiên)
static func generate_scenario(npc_id: String, custom_data: Dictionary = {}) -> Dictionary:
	if not custom_data.is_empty():
		return _build_procedural_scenario(custom_data)
		
	return _build_canonical_scenario(npc_id)

## Kiểm tra điều kiện an toàn nội tại (không leak số liệu ra ngoài để giữ bí mật)
static func can_player_afford_choice(choice: Dictionary) -> Dictionary:
	var req_stones = choice.get("req_stones", 0)
	var req_items = choice.get("req_items", {})
	
	if req_stones > 0:
		var current_stones = GameSession.get_item_count("item_linh_thach")
		if current_stones < req_stones:
			return {
				"can_afford": false,
				"reason": "Chưa đủ điều kiện hành động (thiếu hụt linh tài phù hợp trong người)."
			}
			
	for item_id in req_items.keys():
		var need_count = req_items[item_id]
		var have_count = GameSession.get_item_count(item_id)
		if have_count < need_count:
			return {
				"can_afford": false,
				"reason": "Chưa đủ điều kiện hành động (thiếu vật phẩm cần thiết trong túi đồ)."
			}
			
	return { "can_afford": true, "reason": "" }

## Thực thi lựa chọn và kiến tạo nên biến động thế giới (Bí mật & Bất ngờ)
static func execute_choice(scenario: Dictionary, choice_id: String) -> Dictionary:
	var choice: Dictionary = {}
	for c in scenario.get("choices", []):
		if c.get("id", "") == choice_id:
			choice = c
			break
			
	if choice.is_empty():
		return { "success": false, "reason": "Lựa chọn không hợp lệ!" }
		
	var afford_check = can_player_afford_choice(choice)
	if not afford_check.get("can_afford", false):
		return { "success": false, "reason": afford_check.get("reason", "Chưa đủ điều kiện hành động!") }
		
	var npc_id = scenario.get("npc_id", "")
	var npc_name = scenario.get("npc_name", "NPC")
	var location_id = scenario.get("location_id", "poi_thanh_tri_tran")
	
	# Đảm bảo NPC có trong GameSession.world_npcs
	if not GameSession.world_npcs.has(npc_id):
		var custom_init = scenario.get("npc_data", {})
		if custom_init.is_empty():
			custom_init = ContentRegistry.get_npc(npc_id)
		if not custom_init.is_empty():
			GameSession.register_world_npc(custom_init)
			
	var consequence_summary: Array[String] = []
	var category = choice.get("category", "righteous")
	
	# 1. Trừ tài nguyên người chơi (nếu có hành động dâng nộp/cứu trợ)
	var req_stones = choice.get("req_stones", 0)
	if req_stones > 0:
		GameSession.remove_item("item_linh_thach", req_stones)
		consequence_summary.append("Tiêu hao: %d Linh Thạch" % req_stones)
		
	var req_items = choice.get("req_items", {})
	for item_id in req_items.keys():
		var count = req_items[item_id]
		GameSession.remove_item(item_id, count)
		var iname = ContentRegistry.get_item(item_id).get("name", item_id)
		consequence_summary.append("Trao tặng: %dx %s" % [count, iname])
		
	# 2. Thưởng tài nguyên / Chiến lợi phẩm thu hoạch (Bí mật xuất hiện sau khi chọn)
	var give_stones = choice.get("give_stones", 0)
	if give_stones > 0:
		GameSession.add_item("item_linh_thach", give_stones)
		consequence_summary.append("Thu hoạch bất ngờ: +%d Linh Thạch" % give_stones)
		
	var give_items = choice.get("give_items", {})
	for item_id in give_items.keys():
		var count = give_items[item_id]
		GameSession.add_item(item_id, count)
		var iname = ContentRegistry.get_item(item_id).get("name", item_id)
		consequence_summary.append("Nhận được tín vật bí mật: %dx %s" % [count, iname])
		
	# 3. Biến động Hảo cảm & Mối quan hệ
	var aff_delta = choice.get("affinity_delta", 0)
	if aff_delta != 0:
		GameSession.modify_npc_affinity(npc_id, aff_delta)
		var sign_str = "+%d" % aff_delta if aff_delta > 0 else "%d" % aff_delta
		consequence_summary.append("Hảo cảm với %s: %s (Hiện tại: %d)" % [npc_name, sign_str, GameSession.get_npc_affinity(npc_id)])
		
	var rel_delta = choice.get("relationship_delta", {})
	if not rel_delta.is_empty():
		GameSession.modify_npc_relationship(
			npc_id,
			"player",
			rel_delta.get("affinity", aff_delta),
			rel_delta.get("trust", 0),
			rel_delta.get("debt", 0),
			rel_delta.get("grudge", 0),
			rel_delta.get("fear", 0)
		)
		var rel_desc: Array[String] = []
		if rel_delta.get("trust", 0) > 0: rel_desc.append("Tín nhiệm +%d" % rel_delta["trust"])
		if rel_delta.get("debt", 0) > 0: rel_desc.append("Ân nợ +%d" % rel_delta["debt"])
		if rel_delta.get("grudge", 0) > 0: rel_desc.append("Thù hận +%d" % rel_delta["grudge"])
		if rel_delta.get("fear", 0) > 0: rel_desc.append("Kính sợ +%d" % rel_delta["fear"])
		if not rel_desc.is_empty():
			consequence_summary.append("Mối quan hệ nhân quả: " + ", ".join(rel_desc))
			
	# 4. Ghi nhận Ký Ức Thế Giới (World Chronicle Memory Event)
	var mem_data = choice.get("memory_event", {})
	if not mem_data.is_empty():
		var event_type = mem_data.get("event_type", "dialogue_decision")
		var severity = mem_data.get("severity", 1)
		var is_public = mem_data.get("is_public", true)
		GameSession.log_memory_event("player", npc_id, event_type, location_id, [], severity, is_public)
		var mem_label = mem_data.get("desc", "Sự kiện được ghi lại vào ký ức thế giới.")
		consequence_summary.append("Ký ức thế giới: " + mem_label)
		
	# 5. Biến động Kinh Tế & Thị Trường Trấn
	var market_mods = choice.get("market_modifiers", {})
	for cat in market_mods.keys():
		var mod_val = float(market_mods[cat])
		GameSession.set_market_modifier(cat, mod_val)
		var pct = int(round((mod_val - 1.0) * 100.0))
		var change_str = "tăng +%d%%" % pct if pct > 0 else "giảm %d%%" % abs(pct)
		var cat_name = "Hàng Hóa"
		if cat == "herbs": cat_name = "Linh Thảo / Dược Liệu"
		elif cat == "medicines": cat_name = "Đan Dược / Thuốc Men"
		elif cat == "weapons": cat_name = "Binh Khí / Khoáng Thiết"
		consequence_summary.append("Biến động thị trường: Giá %s tại trấn %s (Hệ số: %.2f)" % [cat_name, change_str, mod_val])
		
	# 6. Biến động Trực Tiếp Tu Vi / Cảnh Giới NPC
	var npc_xp_boost = choice.get("npc_xp_boost", 0)
	var did_breakthrough = false
	if GameSession.world_npcs.has(npc_id) and npc_xp_boost > 0:
		var n = GameSession.world_npcs[npc_id]
		var cur_xp = n.get("cultivation_xp", 0) + npc_xp_boost
		n["cultivation_xp"] = cur_xp
		if cur_xp >= 100:
			var stage = n.get("realm_stage", 1) + 1
			n["realm_stage"] = stage
			n["realm_name"] = "Luyện Khí Tầng %d" % stage
			n["cultivation_xp"] = cur_xp - 100
			did_breakthrough = true
			consequence_summary.append("Kỳ ngộ đột phá: %s đốn ngộ công pháp, lập tức đột phá lên [%s]!" % [npc_name, n["realm_name"]])
		else:
			consequence_summary.append("Tiến cảnh NPC: Tu vi của %s tăng trưởng +%d điểm." % [npc_name, npc_xp_boost])
			
	# 7. Tăng tu vi người chơi (nếu có đốn ngộ)
	var player_xp = choice.get("player_xp_boost", 0)
	if player_xp > 0:
		GameSession.cultivation_xp = mini(GameSession.max_cultivation_xp, GameSession.cultivation_xp + player_xp)
		consequence_summary.append("Đạo tâm khai ngộ: Bạn nhận được +%d Tu Vi!" % player_xp)
		
	# 8. Yếu tố ngẫu nhiên khó lường (Unpredictable Karmic Twist)
	var twist_roll = (GameClock.total_days_elapsed * 37 + GameSession.world_seed + hash_string(npc_id)) % 100
	if twist_roll < 35 and category == "righteous":
		var bonus_xp = 15
		GameSession.cultivation_xp = mini(GameSession.max_cultivation_xp, GameSession.cultivation_xp + bonus_xp)
		consequence_summary.append("Kỳ ngộ bí mật: Lòng hiệp nghĩa cảm thông trời đất, bạn bất ngờ đốn ngộ thêm +%d Tu Vi!" % bonus_xp)
	elif twist_roll < 30 and category == "demonic":
		consequence_summary.append("Dị biến bất ngờ: Hành vi tàn nhẫn đã lọt vào mắt một tán tu ẩn danh, gieo mầm hiểm họa mai sau!")
	elif twist_roll < 35 and category == "pragmatic":
		consequence_summary.append("Thị trường dao động: Tin tức thỏa thuận thương mại lan truyền, các thương lái bắt đầu điều chỉnh giá cả!")
	elif twist_roll < 35 and category == "enlightenment":
		consequence_summary.append("Huyền cơ cộng hưởng: Hai bên luận đạo cộng hưởng linh khí, dị tượng thiên địa thoáng hiện trên bầu trời!")

	# 9. Âm thanh hiệu ứng
	if AudioService:
		match category:
			"righteous":
				AudioService.play_sfx("sfx_alchemy_brew")
			"demonic":
				AudioService.play_sfx("sfx_sword_slash")
			"pragmatic":
				AudioService.play_sfx("sfx_button_click")
			"enlightenment":
				AudioService.play_sfx("sfx_pill_swallow")
			"aloof":
				AudioService.play_sfx("sfx_button_click")
				
	# 10. Thông báo toàn cục
	if EventBus:
		var toast_type = "info"
		if category == "righteous" or category == "enlightenment":
			toast_type = "success"
		elif category == "demonic":
			toast_type = "warning"
		EventBus.notification_requested.emit("Quyết định vấn đạo: %s — %s" % [choice.get("tag", ""), npc_name], toast_type)
		
	return {
		"success": true,
		"npc_id": npc_id,
		"npc_name": npc_name,
		"choice_id": choice_id,
		"choice_tag": choice.get("tag", ""),
		"npc_response": choice.get("npc_response", "Đạo hữu thật khiến ta phải suy ngẫm..."),
		"consequences": consequence_summary,
		"world_changes": {
			"affinity_delta": aff_delta,
			"market_modifiers": market_mods,
			"npc_breakthrough": did_breakthrough,
			"stones_paid": req_stones,
			"stones_received": give_stones
		}
	}

# ==============================================================================
# BỘ TÌNH HUỐNG CHO CÁC NPC CỐT TRUYỆN THANH TRÌ TRẤN
# (Lựa chọn hiển thị tự nhiên, không hé lộ trước được gì mất gì)
# ==============================================================================

static func _build_canonical_scenario(npc_id: String) -> Dictionary:
	match npc_id:
		"npc_mac_tu_vien":
			return {
				"npc_id": "npc_mac_tu_vien",
				"npc_name": "Mạc Tư Viễn",
				"location_id": "poi_thanh_tri_tran",
				"title": "Phong Vân Quán Trọ & Tàn Kiếm Tích Uy",
				"prompt": "Mạc Tư Viễn rót một chén rượu nhạt, sắc mặt trầm tư:\n\"Dạo gần đây ma khí Vân Lĩnh áp chế, linh tửu và đan dược nơi quán trọ đều cạn kiệt. Lũ yêu thứu cướp bóc khiến thương khách không dám ghé chân, quan phủ và tông môn lại rục rịch tăng thuế. Lão hủ thân cô thế cô, có khi phải đóng cửa quán trọ lánh nạn. Đạo hữu thấy ta nên ứng đối thế nào?\"",
				"choices": [
					{
						"id": "mac_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Chưởng quỹ an tâm, diệt trừ ma thú bảo hộ dân sinh vốn là bản phận kiếm tu! Ta xin san sẻ chút linh tài cùng quán trọ.\"",
						"req_stones": 20,
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 25, "debt": 0, "grudge": -10, "fear": 0 },
						"player_xp_boost": 30,
						"memory_event": {
							"event_type": "righteous_relief",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi trượng nghĩa cứu tế Quán Trọ Thanh Trì, nhận được sự kính trọng của Mạc Tư Viễn."
						},
						"npc_response": "Mạc Tư Viễn hai mắt đỏ hoe, run run nâng chén rượu:\n\"Đạo hữu quả là hiệp sĩ chân chính! Đã bao năm rồi ta chưa gặp người có tấm lòng son sắt như vậy. Đây là tâm đắc tàn chương năm xưa ta đúc kết từ Vạn Kiếm Quyết, xin tặng đạo hữu để trợ lực tu vi!\""
					},
					{
						"id": "mac_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Muốn an ổn kinh doanh giữa loạn thế thì phải biết điều, mau giao nộp ngân lượng bảo kê ra đây!\"",
						"give_stones": 40,
						"affinity_delta": -30,
						"relationship_delta": { "affinity": -30, "trust": -25, "debt": 0, "grudge": 35, "fear": 30 },
						"market_modifiers": { "general": 1.15 },
						"memory_event": {
							"event_type": "demonic_extort",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi ỷ mạnh hiếp yếu, bức ép Mạc Tư Viễn cống nạp linh thạch."
						},
						"npc_response": "Mạc Tư Viễn cắn răng, giấu ánh mắt oán độc, run rẩy móc ra túi linh thạch dâng lên:\n\"Các hạ... quả là thủ đoạn tàn nhẫn! Núi cao còn có núi cao hơn, món nợ này Mạc mỗ ghi khắc trong lòng!\""
					},
					{
						"id": "mac_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Nguy cơ cũng là thương cơ. Chi bằng đôi bên cùng ký kết giao ước cung ứng, quán trọ làm điểm tiêu thụ còn ta lo nguồn hàng?\"",
						"affinity_delta": 15,
						"relationship_delta": { "affinity": 15, "trust": 20, "debt": 20, "grudge": 0, "fear": 0 },
						"market_modifiers": { "medicines": 0.85, "general": 0.90 },
						"memory_event": {
							"event_type": "trade_partnership",
							"severity": 1,
							"is_public": true,
							"desc": "Thiết lập liên minh thương mại bình ổn thị trường cùng Quán Trọ Thanh Trì."
						},
						"npc_response": "Mạc Tư Viễn vỗ đùi khen ngợi:\n\"Diệu kế! Tán tu cần chỗ tiêu thụ, quán trọ ta có khách vãng lai. Có giao kèo này, dòng tiền linh thạch sẽ lưu thông trở lại, vật giá cũng dễ thở hơn nhiều!\""
					},
					{
						"id": "mac_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Kiếm tâm chưa tàn, sao chưởng quỹ vội buông tay? Hãy để kiếm ý dẫn lối, phá tan tâm ma mà tái xuất!\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 50,
						"give_items": { "item_co_kiem_tan_phien": 1 },
						"memory_event": {
							"event_type": "dao_enlightenment",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi điểm hóa giúp Mạc Tư Viễn phá vỡ tâm ma, thức tỉnh kiếm ý năm xưa."
						},
						"npc_response": "Mạc Tư Viễn toàn thân chấn động, linh khí quanh người ba động kịch liệt, đôi mắt mờ đục bỗng lóe lên kiếm quang:\n\"Kiếm tại tâm, tâm bất tử thì kiếm bất diệt! Lão hủ ẩn nhẫn mấy chục năm nay mới hiểu ra chân lý. Mảnh kiếm cổ này ta giữ bấy lâu, nay tặng lại cho người hữu duyên!\""
					},
					{
						"id": "mac_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Hồng trần vạn sự có số, thế sự đổi dời tùy duyên, tại hạ xin giữ đạo tâm thanh tịnh không dám can thiệp.\"",
						"player_xp_boost": 10,
						"affinity_delta": 5,
						"memory_event": {
							"event_type": "aloof_observation",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi giữ vững đạo tâm xuất thế, quan sát thời cuộc mà không can dự."
						},
						"npc_response": "Mạc Tư Viễn khẽ thở dài, nhưng cũng gật đầu khâm phục:\n\"Tùy duyên mà an... Đạo hữu giữ được đạo tâm thanh tĩnh giữa chốn hồng trần hỗn loạn này, thật là hiếm có.\""
					}
				]
			}
			
		"npc_thu_nguyet":
			return {
				"npc_id": "npc_thu_nguyet",
				"npc_name": "Thư Nguyệt",
				"location_id": "poi_thanh_tri_tran",
				"title": "Khủng Hoảng Dược Liệu & Hàn Độc Hoành Hành",
				"prompt": "Thư Nguyệt cau mày bên lò sắc thuốc, mồ hôi lấm tấm trên trán:\n\"Hàn khí từ U Minh Cốc tràn về khiến hơn mười tán tu nghèo quanh trấn trúng hàn độc. Thuốc giải cần Thanh Trì Linh Thảo tươi, nhưng thương nhân bên ngoài lại nâng giá gấp đôi. Ta gom hết tiền chỉ mua được vài gốc, không đủ cứu người... Đạo hữu có cách nào chăng?\"",
				"choices": [
					{
						"id": "thunguyet_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Tính mạng con người là trên hết, tại hạ xin dâng linh dược cùng cô nương cứu trợ dân nghèo qua kiếp nạn!\"",
						"req_items": { "item_linh_thao": 3 },
						"give_items": { "item_hoi_xuan_dan": 2 },
						"affinity_delta": 35,
						"relationship_delta": { "affinity": 35, "trust": 30, "debt": 20, "grudge": 0, "fear": 0 },
						"market_modifiers": { "medicines": 0.80 },
						"memory_event": {
							"event_type": "righteous_doctor_aid",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi hào hiệp dâng linh thảo cứu giúp dân nghèo khỏi dịch bệnh hàn độc."
						},
						"npc_response": "Thư Nguyệt rưng rưng cảm tạ, vội vã đưa linh thảo vào lò luyện:\n\"Đa tạ đạo hữu đại từ đại bi! Ba gốc dược thảo này như cam lộ cứu sống hàng chục mạng người. Ta vừa luyện xong hai viên Hồi Xuân Đan thượng phẩm này, xin người nhận lấy hộ thân!\""
					},
					{
						"id": "thunguyet_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Nước đục mới dễ thả câu. Chỗ thuốc giải sót lại này cứ để ta gom hết, nhân cơ hội này kiếm một món hời!\"",
						"give_stones": 50,
						"affinity_delta": -35,
						"relationship_delta": { "affinity": -35, "trust": -30, "debt": 0, "grudge": 40, "fear": 25 },
						"market_modifiers": { "medicines": 1.30 },
						"memory_event": {
							"event_type": "black_market_hoard",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi nhân lúc dịch bệnh đầu cơ trục lợi đan dược, bị dân chúng oán thán."
						},
						"npc_response": "Thư Nguyệt giận đến run người, đập bàn chỉ trích:\n\"Ngươi... nhân mạng đang ngàn cân treo sợi tóc, ngươi lại muốn hút máu đồng đạo kiếm linh thạch dơ bẩn sao?! Từ nay Dược Phẩm Các không hoan nghênh hạng người ma đạo như ngươi!\""
					},
					{
						"id": "thunguyet_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Khan hiếm là do độc quyền, ta có thể đứng ra ký kết bảo đảm chuỗi cung ứng dã ngoại lâu dài cho tiệm thuốc.\"",
						"give_stones": 25,
						"affinity_delta": 20,
						"relationship_delta": { "affinity": 20, "trust": 25, "debt": 15, "grudge": 0, "fear": 0 },
						"market_modifiers": { "herbs": 0.85 },
						"memory_event": {
							"event_type": "apothecary_supply_pact",
							"severity": 1,
							"is_public": true,
							"desc": "Ký kết giao ước cung ứng dược liệu bền vững cho Dược Phẩm Các."
						},
						"npc_response": "Thư Nguyệt thở phào nhẹ nhõm, ánh mắt tin cậy:\n\"Nếu có đạo hữu đảm bảo nguồn linh thảo từ Rừng Trúc với giá ổn định, hiệu thuốc sẽ không sợ thiếu nguyên liệu nữa. Ta xin tạm ứng trước số linh thạch này làm tín vật!\""
					},
					{
						"id": "thunguyet_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Y đạo cũng là tiên đạo, thuật luyện đan cốt ở điều hòa âm dương hỏa hầu, cô nương thử dẫn linh hỏa chậm ba nhịp xem sao?\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 40,
						"give_items": { "item_tu_khi_dan": 1 },
						"memory_event": {
							"event_type": "alchemy_guidance",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi truyền thụ tâm pháp phối dược huyền diệu giúp Thư Nguyệt thăng tiến thuật luyện đan."
						},
						"npc_response": "Thư Nguyệt bừng tỉnh đại ngộ, vỗ tay tấm tắc:\n\"Hóa ra dùng hỏa hầu nhu hòa kết hợp linh tuyền có thể tăng gấp ba dược tính, giảm lượng linh thảo cần thiết! Đạo hữu quả là bậc thầy đan đạo, đây là viên Tụ Khí Đan ta trân quý nhất, xin biếu tặng đạo hữu!\""
					},
					{
						"id": "thunguyet_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Thiên tai dịch bệnh là lẽ tuần hoàn, sức người có hạn, cô nương hãy đóng cửa hiệu thuốc bảo toàn thân mình trước đã.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "prudent_advice",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi khuyên Thư Nguyệt giữ mình an toàn trước sóng gió."
						},
						"npc_response": "Thư Nguyệt khẽ lắc đầu thở dài:\n\"Đạo hữu nói cũng có lý, tu giả trước hết phải giữ lấy mạng. Nhưng nhìn người hoạn nạn mà bó tay, lòng ta thật khó an ổn...\""
					}
				]
			}
			
		"npc_lam_du":
			return {
				"npc_id": "npc_lam_du",
				"npc_name": "Lâm Du",
				"location_id": "poi_thanh_tri_tran",
				"title": "Môn Quy Khắt Khe & Lệnh Tuần Sát Trấn Áp",
				"prompt": "Lâm Du đeo kiếm bên hông, vẻ mặt nửa kiêu hãnh nửa bối rối:\n\"Thanh Vi Tông phát lệnh thu phụ phí tuần tra 20 linh thạch với mỗi tu sĩ vãng lai. Lũ tán tu than vãn oán thán, cho rằng bổn tông ức hiếp. Sư môn ra lệnh phải nghiêm khắc răn đe, nhưng ta thấy nhiều người quả thực nghèo rớt mồng tơi... Đạo hữu nghĩ danh môn nên xử thế ra sao?\"",
				"choices": [
					{
						"id": "lamdu_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Danh môn chính phái nên lấy đức phục chúng, tại hạ xin nộp thay phần tán tu bần hàn để giữ lấy hòa khí đôi bên!\"",
						"req_stones": 25,
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 25, "debt": 15, "grudge": 0, "fear": 0 },
						"memory_event": {
							"event_type": "righteous_mediation",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi bỏ tiền túi lập quỹ tương tế, hóa giải mâu thuẫn giữa Thanh Vi Tông và tán tu."
						},
						"npc_response": "Lâm Du cảm kích ôm quyền:\n\"Đạo hữu lấy đại nghĩa làm trọng, khiến kẻ hậu bối như ta hổ thẹn! Ta sẽ bẩm báo sư môn dùng số linh thạch này mở trạm cấp phát phù chú miễn phí, giữ gìn uy danh chính phái!\""
					},
					{
						"id": "lamdu_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Mượn danh chính phái để bóc lột kẻ yếu! Có giỏi thì rút kiếm ra đây đọ xem thanh kiếm nào sắc hơn!\"",
						"affinity_delta": -30,
						"relationship_delta": { "affinity": -30, "trust": -25, "debt": 0, "grudge": 40, "fear": 35 },
						"memory_event": {
							"event_type": "sect_intimidation",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi công khai thị uy đối đầu với đệ tử tuần sát Thanh Vi Tông."
						},
						"npc_response": "Lâm Du mặt biến sắc, tay nắm chặt chuôi kiếm, sát khí bùng lên:\n\"Các hạ cuồng vọng dám lăng mạ Thanh Vi Tông! Nếu không phải đang phận sự tuần sát, ta đã rút kiếm thỉnh giáo sát chiêu của ngươi rồi!\""
					},
					{
						"id": "lamdu_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Thay vì ép nộp tiền mặt, cớ sao tông môn không cho phép tán tu quy đổi bằng nộp linh thảo hay quặng sắt dã ngoại?\"",
						"affinity_delta": 15,
						"relationship_delta": { "affinity": 15, "trust": 20, "debt": 0, "grudge": 0, "fear": 0 },
						"market_modifiers": { "general": 0.90, "herbs": 0.90 },
						"memory_event": {
							"event_type": "trade_policy_reform",
							"severity": 1,
							"is_public": true,
							"desc": "Đề xuất chính sách hoán đổi linh tài linh hoạt cho đệ tử Thanh Vi Tông."
						},
						"npc_response": "Lâm Du gật đầu lia lịa:\n\"Ý hay! Tông môn ta đang thiếu hụt dược liệu và quặng rèn kiếm. Thay vì đòi linh thạch tiền mặt, nhận linh tài vừa giúp tán tu đỡ áp lực vừa bổ sung kho của tông!\""
					},
					{
						"id": "lamdu_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Thanh Vi Kiếm Pháp cốt ở 'Kiếm Khí Hóa Nhận', thức thứ ba của huynh đài chuyển thế tựa hồ còn vướng nút thắt?\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 45,
						"give_items": { "item_co_kiem_tan_phien": 1 },
						"memory_event": {
							"event_type": "sword_technique_guidance",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi chỉ điểm kiếm quyết cao sâu giúp đệ tử danh môn khai thông kiếm đạo."
						},
						"npc_response": "Lâm Du kinh ngạc rút kiếm khẽ vung thử, kiếm khí xé gió ngân vang:\n\"Tuyệt diệu! Đúng là chiêu thứ ba của ta chuyển tiếp quá cứng nhắc. Được đạo hữu chỉ điểm, kiếm ý của ta đại tiến! Mảnh kiếm tàn này ta nhặt được nơi phế tích, xin kính tặng sư huynh!\""
					},
					{
						"id": "lamdu_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Môn quy đại phái ta là người ngoài không dám lạm bàn, xin cáo từ lui bước.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "aloof_departure",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi từ chối can thiệp nội bộ tông quy của Thanh Vi Tông."
						},
						"npc_response": "Lâm Du chắp tay tiễn khách:\n\"Đạo hữu thanh tâm quả dục, tại hạ không dám quấy rầy. Chúc đạo hữu thuận buồm xuôi gió trên đường tu tiên.\""
					}
				]
			}
			
		"npc_ky_hoan":
			return {
				"npc_id": "npc_ky_hoan",
				"npc_name": "Kỷ Hoàn",
				"location_id": "poi_thanh_tri_tran",
				"title": "Chuyến Hàng Buôn Lậu & Rủi Ro Huyết Cốc",
				"prompt": "Kỷ Hoàn lén lút kéo bạn vào góc hẻm, thì thầm to nhỏ:\n\"Ta vừa nhập được một chuyến khoáng thạch quý và linh thảo hiếm từ U Minh Huyết Cốc, nhưng bên ngoài đồn có thổ phỉ mai phục. Ta muốn thuê người hộ tống hoặc bán sang tay toàn bộ. Đạo hữu có hứng thú bắt tay kiếm món hời này không?\"",
				"choices": [
					{
						"id": "kyhoan_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Đoạn đường sơn mạch hiểm trở, tại hạ tình nguyện hộ tống chuyến hàng an toàn không màng thù lao!\"",
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 25, "debt": 20, "grudge": 0, "fear": 0 },
						"give_stones": 30,
						"give_items": { "item_thanh_tri_linh_thao": 1 },
						"memory_event": {
							"event_type": "convoy_protection",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi dũng cảm hộ tống thương đội vượt qua rủi ro cướp bóc."
						},
						"npc_response": "Kỷ Hoàn mừng rỡ ôm chầm lấy bạn:\n\"Có một vị kiếm tu trượng nghĩa như đạo hữu hộ vệ, lũ thảo khấu nào dám bén mảng! Đây là 30 linh thạch và gốc cổ thảo ta tự tay hái, xin đạo hữu nhận lấy!\""
					},
					{
						"id": "kyhoan_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Hàng hóa mờ ám này nếu để quan phủ hay tông môn biết thì khó giữ mạng, mau giao ra đây phân nửa làm phí im lặng!\"",
						"give_stones": 50,
						"affinity_delta": -35,
						"relationship_delta": { "affinity": -35, "trust": -30, "debt": 0, "grudge": 45, "fear": 40 },
						"market_modifiers": { "general": 1.20 },
						"memory_event": {
							"event_type": "blackmail_extort",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi tống tiền thương nhân gian xảo, cưỡng đoạt lợi nhuận buôn lậu."
						},
						"npc_response": "Kỷ Hoàn run rẩy quỳ sụp xuống, nghiến răng cay đắng:\n\"Đạo huynh tha mạng! Tiền đây... hàng đây! Ngươi thật tàn độc hơn cả lũ thổ phỉ! Ta... ta nhớ mặt ngươi rồi!\""
					},
					{
						"id": "kyhoan_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Chuyến buôn này ta thấy có triển vọng lớn, chi bằng ta góp vốn cùng người hùn hạp chia đôi lợi tức?\"",
						"req_stones": 20,
						"give_stones": 45,
						"affinity_delta": 20,
						"relationship_delta": { "affinity": 20, "trust": 25, "debt": 25, "grudge": 0, "fear": 0 },
						"market_modifiers": { "general": 0.85 },
						"memory_event": {
							"event_type": "venture_trade_success",
							"severity": 1,
							"is_public": true,
							"desc": "Hùn vốn thành công thương vụ mạo hiểm, đem lại lợi nhuận dồi dào."
						},
						"npc_response": "Kỷ Hoàn cười ha hả, đếm tiền trao tay:\n\"Đạo hữu quả là có con mắt kinh doanh sắc bén! Có vốn của đạo hữu xoay vòng, thương vụ thành công mỹ mãn. Đây là 45 linh thạch cả gốc lẫn lãi thuộc về người!\""
					},
					{
						"id": "kyhoan_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Linh thạch như mây khói phù vân, buôn bán ngược xuôi nguy hiểm tính mạng, chi bằng sớm quay về nẻo tu chân?\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 35,
						"give_items": { "item_thanh_tri_linh_thao": 1 },
						"memory_event": {
							"event_type": "merchant_reformation",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi cảm hóa thương nhân hám lợi, khuyên người quay về đường ngay."
						},
						"npc_response": "Kỷ Hoàn sững sờ hồi lâu rồi thở dài buông tay nải:\n\"Đạo hữu nói chí phải. Kiếm thêm linh thạch mà mất mạng thì cũng thành tro bụi. Ta quyết định quy ẩn tu hành. Tấm bản đồ đánh dấu dược thảo bí cảnh này xin gửi lại cho người!\""
					},
					{
						"id": "kyhoan_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Chuyện kinh doanh mờ ám hiểm nguy trùng trùng, tại hạ lực mỏng xin không dám dính dáng.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "aloof_refusal",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi cẩn trọng từ chối tham gia buôn lậu nguy hiểm."
						},
						"npc_response": "Kỷ Hoàn gượng cười lùi lại:\n\"Haha đạo hữu quả là thận trọng. Ta hiểu, cẩn tắc vô ưu. Coi như hôm nay ta chưa nói gì nhé!\""
					}
				]
			}
			
		"npc_moc_lao":
			return {
				"npc_id": "npc_moc_lao",
				"npc_name": "Mộc Lão",
				"location_id": "poi_thanh_tri_tran",
				"title": "Rèn Đúc Thần Binh & Hàn Thiết Cổ Kiếm",
				"prompt": "Mộc Lão gõ búa chan chát lên đe sắt, mồ hôi nhễ nhại:\n\"Cổ kiếm rèn từ Hàn Thiết ngàn năm vốn cần chân hỏa tinh thuần tôi luyện. Than củi thường không đủ nhiệt độ khiến kiếm thai sắp hỏng. Đạo hữu thân mang linh khí, có thể trợ giúp lão hủ một tay chăng?\"",
				"choices": [
					{
						"id": "moclao_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Lão trượng chớ lo, tại hạ xin vận linh khí trợ hỏa, cùng người tôi rèn thanh thần binh này!\"",
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 25, "debt": 20, "grudge": 0, "fear": 0 },
						"give_items": { "item_thanh_vi_phu": 1 },
						"memory_event": {
							"event_type": "forging_cooperation",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi hết lòng trợ giúp thợ rèn tôi luyện binh khí pháp bảo."
						},
						"npc_response": "Mộc Lão cười rạng rỡ, nhấc thanh bảo kiếm sáng loáng ra khỏi bồn nước:\n\"Thành rồi! Hàn Thiết dung hợp hoàn mỹ! Đạo hữu hiệp nghĩa nhiệt tình, lão hủ xin gia cố tấm hộ giáp và tặng đạo hữu phù hộ mệnh này!\""
					},
					{
						"id": "moclao_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Thanh phôi kiếm này rơi vào tay lão thợ rèn quê mùa thật uổng phí, giao nó cho ta mới phát huy chân chính uy lực!\"",
						"give_items": { "item_co_kiem_tan_phien": 1 },
						"affinity_delta": -30,
						"relationship_delta": { "affinity": -30, "trust": -25, "debt": 0, "grudge": 35, "fear": 30 },
						"market_modifiers": { "weapons": 1.25 },
						"memory_event": {
							"event_type": "forge_robbery",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi cưỡng đoạt phôi kiếm quý từ lò rèn của Mộc Lão."
						},
						"npc_response": "Mộc Lão ôm ngực đau đớn, trơ mắt nhìn bạn giật lấy phôi kiếm quý báu:\n\"Kẻ cướp... ngươi sẽ bị trời tru đất diệt! Cổ khí không có tâm thì chỉ là khối sắt gỉ mà thôi!\""
					},
					{
						"id": "moclao_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Nếu có nguồn quặng sắt dã ngoại dồi dào, lão trượng có thể mở rộng đúc kiếm đại trà cho các sạp hàng thị trấn được chăng?\"",
						"affinity_delta": 15,
						"relationship_delta": { "affinity": 15, "trust": 20, "debt": 15, "grudge": 0, "fear": 0 },
						"market_modifiers": { "weapons": 0.85 },
						"memory_event": {
							"event_type": "ore_supply_agreement",
							"severity": 1,
							"is_public": true,
							"desc": "Tổ chức mạng lưới cung ứng quặng sắt ổn định cho lò rèn Thanh Trì."
						},
						"npc_response": "Mộc Lão gật gù khen ngợi:\n\"Có nguồn quặng sắt dồi dào của đạo hữu, ta có thể rèn đại trà binh khí chất lượng cao cho tu sĩ trong trấn, giá kiếm đao cũng sẽ hạ nhiệt!\""
					},
					{
						"id": "moclao_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Đúc kiếm cũng như tu tâm, 'Khí quán binh khí' mới là cảnh giới tối cao của luyện khí thuật!\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 45,
						"give_items": { "item_co_kiem_tan_phien": 1 },
						"memory_event": {
							"event_type": "smithing_enlightenment",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi khai ngộ huyền cơ luyện khí thuật giúp thợ rèn danh trấn đột phá."
						},
						"npc_response": "Mộc Lão ngây người nhìn tia lửa bắn tung tóe rồi quỳ sụp tạ ơn:\n\"Hóa ra không phải dùng sức đập mà là dẫn thần thức vào từng thớ thép! Đạo hữu chính là ân sư của Mộc gia ta! Mảnh kiếm cổ này xin trao lại cho người!\""
					},
					{
						"id": "moclao_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Tay nghề lão trượng quả nhiên xuất quỷ nhập thần, tại hạ chỉ đứng ngoài thưởng ngoạn mà thôi.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "aloof_departure",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi giữ khoảng cách lễ độ với giới luyện khí."
						},
						"npc_response": "Mộc Lão cười xòa vẫy tay:\n\"Cảm ơn đạo hữu có lời khen. Khi nào rảnh cứ ghé uống hớp trà xem lão già này đập sắt!\""
					}
				]
			}
			
		_:
			return _build_generic_scenario(npc_id, "Đạo Hữu Cốt Truyện", "poi_thanh_tri_tran")

# ==============================================================================
# BỘ TÌNH HUỐNG CHO NPC THỦ TỤC DÃ NGOẠI / TÁN TU VÃNG LAI (PROCEDURAL NPCS)
# ==============================================================================

static func _build_procedural_scenario(data: Dictionary) -> Dictionary:
	var nid = data.get("id", "npc_procedural")
	var name = data.get("name", "Tán Tu Vô Danh")
	var drive = data.get("core_drive", {})
	var drive_id = drive.get("id", "")
	var location = data.get("location", "poi_thanh_tri_tran")
	
	match drive_id:
		"drive_save_kin":
			return {
				"npc_id": nid,
				"npc_name": name,
				"npc_data": data,
				"location_id": location,
				"title": "Cứu Muội Muội Hoạn Nạn & Hàn Độc Kỳ Dị",
				"prompt": "%s ánh mắt tuyệt vọng, giọng khàn đặc cầu xin:\n\"Đạo hữu cứu mạng! Muội muội duy nhất của ta trúng hàn độc kỳ dị, hơi thở như chỉ mành treo chuông. Ta đã bán hết gia sản vẫn thiếu đan dược cứu mạng... Cầu xin đạo hữu rủ lòng từ bi chỉ bảo một lối thoát!\"" % name,
				"choices": [
					{
						"id": "proc_save_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Cứu người như cứu hỏa! Mau cầm lấy số đan dược này mang về cứu muội muội đạo hữu!\"",
						"req_items": { "item_hoi_xuan_dan": 1 },
						"give_items": { "item_thanh_tri_linh_thao": 2 },
						"affinity_delta": 40,
						"relationship_delta": { "affinity": 40, "trust": 40, "debt": 50, "grudge": 0, "fear": 0 },
						"memory_event": {
							"event_type": "life_saving_deed",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi hào hiệp cứu mạng người thân của %s, gieo mầm đại thiện duyên." % name
						},
						"npc_response": "%s dập đầu tạ ơn, nước mắt lưng tròng:\n\"Đại ân đại đức này khác nào tái sinh cả nhà ta! Sau này dẫu phải nhảy vào dầu sôi lửa bỏng, %s ta cũng quyết không chối từ!\"" % [name, name]
					},
					{
						"id": "proc_save_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Đan dược cứu mạng không phải cho không, ký vào huyết khế làm thuộc hạ cho ta rồi tính!\"",
						"affinity_delta": -35,
						"relationship_delta": { "affinity": -35, "trust": -30, "debt": 0, "grudge": 45, "fear": 40 },
						"memory_event": {
							"event_type": "blood_contract_extort",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi thừa lúc nguy khốn ép buộc %s ký khế ước nô dịch." % name
						},
						"npc_response": "%s nắm chặt tay đến rướm máu, đôi mắt bốc lên ngọn lửa oán hận ngút trời:\n\"Ngươi... kẻ tiểu nhân bỉ ổi! Đợi đến ngày ta báo được thù, ta nhất định khiến ngươi hối hận!\"" % name
					},
					{
						"id": "proc_save_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Ta có thể xuất linh thạch cứu cấp cho đạo hữu, nhưng quy tắc giang hồ vay mượn phải có lãi suất sòng phẳng.\"",
						"req_stones": 25,
						"affinity_delta": 15,
						"relationship_delta": { "affinity": 15, "trust": 20, "debt": 35, "grudge": 0, "fear": 0 },
						"market_modifiers": { "general": 0.92 },
						"memory_event": {
							"event_type": "urgent_loan_issued",
							"severity": 1,
							"is_public": true,
							"desc": "Người chơi cho %s vay linh thạch khẩn cấp để trang trải viện phí." % name
						},
						"npc_response": "%s run rẩy nhận linh thạch và ký chỉ điểm vào văn tự nợ:\n\"Đa tạ đạo hữu cứu cấp kịp thời! Ta thề làm lụng gom góp trả đủ cả vốn lẫn lời cho người!\"" % name
					},
					{
						"id": "proc_save_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Hàn độc tuy hiểm nhưng cốt ở mộc khí ôn dưỡng, ta truyền cho đạo hữu khẩu quyết Bách Thảo tự thân điều hòa!\"",
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 35, "debt": 25, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 50,
						"memory_event": {
							"event_type": "sect_referral_guidance",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi chỉ điểm công pháp Mộc Linh, dẫn lối %s bước vào tông môn." % name
						},
						"npc_response": "%s thần sắc phấn chấn, kinh mạch khai thông:\n\"Đạo hữu dẫn dắt mộc khí thần diệu quá! Ta đã nắm được khẩu quyết Bách Thảo, muội muội tự vận khí áp chế được hàn độc rồi! Ta sẽ đưa muội muội lên núi bái sư!\"" % name
					},
					{
						"id": "proc_save_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Sinh lão bệnh tử là kiếp số của nhân gian, tại hạ thật lòng lực bất tòng tâm.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "aloof_destiny_observation",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi tôn trọng quy luật sinh tử thiên mệnh, không can thiệp nghiệp duyên."
						},
						"npc_response": "%s rũ mi mắt quỳ gối im lặng:\n\"Thiên mệnh vô tình... Lời đạo hữu không sai, có lẽ mệnh nhà ta đã tận...\"" % name
					}
				]
			}
			
		"drive_revenge":
			return {
				"npc_id": nid,
				"npc_name": name,
				"npc_data": data,
				"location_id": location,
				"title": "Báo Thù Huyết Hải & Mối Hận Trùng Phùng",
				"prompt": "%s nắm chặt chuôi kiếm, đôi mắt đỏ ngầu sát ý:\n\"Ta vừa phát hiện tung tích kẻ thù diệt môn năm xưa đang lẩn trốn trong rặng núi. Nhưng tu vi ta chưa đủ, lâm trận có thể lành ít dữ nhiều. Đạo hữu tung hoành giang hồ, xin cho ta một lời khuyên sáng suốt!\"" % name,
				"choices": [
					{
						"id": "proc_rev_righteous",
						"tag": "[Chính Đạo]",
						"category": "righteous",
						"text": "1. [Chính Đạo] \"Oan oan tương báo khi nào dứt? Hãy để ta giúp đạo hữu điều tra chân tướng trừng trị đúng người!\"",
						"affinity_delta": 25,
						"relationship_delta": { "affinity": 25, "trust": 30, "debt": 15, "grudge": 0, "fear": 0 },
						"memory_event": {
							"event_type": "justice_investigation_pledge",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi cam kết điều tra chân tướng oan án, ngăn chặn thảm sát mù quáng."
						},
						"npc_response": "%s thở dốc, kiếm khí dần thu liễm:\n\"Đạo hữu nói phải, nếu giết lầm kẻ vô tội thì ta khác nào ma đầu năm xưa? Ta tin tưởng đạo huynh sẽ giúp ta rửa sạch oan khuất!\"" % name
					},
					{
						"id": "proc_rev_demonic",
						"tag": "[Ma Đạo]",
						"category": "demonic",
						"text": "2. [Ma Đạo] \"Nợ máu phải trả bằng máu! Cứ dùng độc dược và sát chiêu tàn sát sạch sẽ không để sót kẻ nào!\"",
						"give_stones": 30,
						"affinity_delta": -15,
						"relationship_delta": { "affinity": -15, "trust": 15, "debt": 0, "grudge": 20, "fear": 30 },
						"memory_event": {
							"event_type": "demonic_vengeance_incited",
							"severity": 3,
							"is_public": true,
							"desc": "Người chơi xúi giục %s thực hiện cuộc báo thù đẫm máu tàn sát." % name
						},
						"npc_response": "%s cười man dại, sát khí bùng phát dữ dội:\n\"Ha ha ha! Đúng vậy! Nợ máu phải trả bằng máu! Ta sẽ biến cả sơn trang chúng nó thành biển máu!\"" % name
					},
					{
						"id": "proc_rev_pragmatic",
						"tag": "[Thương Lộ]",
						"category": "pragmatic",
						"text": "3. [Thương Lộ] \"Cừu địch thế lực không nhỏ, chi bằng ta và đạo hữu liên thủ giăng bẫy mượn đao diệt kẻ thù, bảo vật chia đôi?\"",
						"affinity_delta": 20,
						"relationship_delta": { "affinity": 20, "trust": 25, "debt": 20, "grudge": 0, "fear": 0 },
						"give_items": { "item_co_kiem_tan_phien": 1 },
						"memory_event": {
							"event_type": "ambush_pact_formed",
							"severity": 2,
							"is_public": false,
							"desc": "Người chơi cùng %s thiết lập liên minh mai phục tiêu diệt kẻ thù chung." % name
						},
						"npc_response": "%s gật đầu tán thành mưu kế:\n\"Mưu lược này rất kín kẽ! Vừa diệt được kẻ thù vừa đoạt tài nguyên bồi dưỡng thực lực, xin cạn chén thề minh!\"" % name
					},
					{
						"id": "proc_rev_enlightenment",
						"tag": "[Đạo Duyên]",
						"category": "enlightenment",
						"text": "4. [Đạo Duyên] \"Tâm mang sát khí thì kiếm chiêu ắt loạn, ta truyền cho đạo hữu tâm pháp sát phạt ngưng tụ kiếm ý!\"",
						"affinity_delta": 30,
						"relationship_delta": { "affinity": 30, "trust": 35, "debt": 30, "grudge": 0, "fear": 0 },
						"npc_xp_boost": 50,
						"memory_event": {
							"event_type": "dao_empowerment_revenge",
							"severity": 2,
							"is_public": true,
							"desc": "Người chơi khai sáng kiếm đạo chân truyền giúp %s đột phá cảnh giới để tự lực báo thù." % name
						},
						"npc_response": "%s quanh thân kiếm ý rít gào, đột phá trói buộc tâm cảnh:\n\"Đa tạ ân sư truyền pháp! Nay ta đã khai ngộ cảnh giới mới, có thể quang minh chính đại quyết đấu báo thù!\"" % name
					},
					{
						"id": "proc_rev_aloof",
						"tag": "[Bình Thản]",
						"category": "aloof",
						"text": "5. [Bình Thản] \"Ân oán giang hồ như sóng cuộn cát bụi, đạo hữu tự mình cân nhắc, tại hạ không can dự.\"",
						"player_xp_boost": 10,
						"affinity_delta": 0,
						"memory_event": {
							"event_type": "aloof_karmic_detachment",
							"severity": 1,
							"is_public": false,
							"desc": "Người chơi đứng ngoài vòng xoáy ân oán hận thù của giới tu chân."
						},
						"npc_response": "%s ngẫm nghĩ một thoáng rồi quay lưng bước đi:\n\"Mỗi người một đạo... Lựa chọn của đạo hữu ta tôn trọng, đường của ta, ta tự bước đi.\"" % name
					}
				]
			}
			
		_:
			return _build_generic_scenario(nid, name, location)

static func _build_generic_scenario(nid: String, name: String, location: String) -> Dictionary:
	return {
		"npc_id": nid,
		"npc_name": name,
		"location_id": location,
		"title": "Cơ Duyên Đàm Đạo & Khảo Nghiệm Đạo Tâm",
		"prompt": "%s dừng bước, chắp tay nhìn bạn với ánh mắt tò mò:\n\"Đạo hữu bôn ba giang hồ, ngộ ra điều gì về thiên địa đạo lý? Giữa danh lợi, sức mạnh và trường sinh, đâu mới là chân lý tối thượng?\"" % name,
		"choices": [
			{
				"id": "gen_righteous",
				"tag": "[Chính Đạo]",
				"category": "righteous",
				"text": "1. [Chính Đạo] \"Tiên lộ mênh mông nhưng lòng trượng nghĩa giúp đời mới là cội nguồn của chính đạo.\"",
				"affinity_delta": 30,
				"relationship_delta": { "affinity": 30, "trust": 25, "debt": 10, "grudge": 0, "fear": 0 },
				"memory_event": {
					"event_type": "righteous_philosophy_shared",
					"severity": 1,
					"is_public": true,
					"desc": "Người chơi chia sẻ đạo lý hiệp nghĩa, tạo dựng thanh danh uy tín."
				},
				"npc_response": "%s tấm tắc gật đầu khâm phục:\n\"Chí lý! Người tu tiên nếu không cứu giúp kẻ yếu thì khác gì gỗ đá vô tri! Đạo hữu quả có phong thái đại hiệp!\"" % name
			},
			{
				"id": "gen_demonic",
				"tag": "[Ma Đạo]",
				"category": "demonic",
				"text": "2. [Ma Đạo] \"Cá lớn nuốt cá bé là chân lý thiên địa, chỉ có kẻ nắm giữ sức mạnh tuyệt đối mới sinh tồn!\"",
				"affinity_delta": -25,
				"relationship_delta": { "affinity": -25, "trust": -20, "debt": 0, "grudge": 20, "fear": 35 },
				"memory_event": {
					"event_type": "demonic_threat_proclaimed",
					"severity": 1,
					"is_public": true,
					"desc": "Người chơi thể hiện triết lý bá đạo tàn nhẫn, gieo rắc e sợ."
				},
				"npc_response": "%s rùng mình lùi lại nửa bước, ánh mắt cảnh giác cao độ:\n\"Các hạ... sát khí bức người quá. Đạo bất đồng bất tương vi mưu, xin thứ lỗi không tiếp chuyện nữa!\"" % name
			},
			{
				"id": "gen_pragmatic",
				"tag": "[Thương Lộ]",
				"category": "pragmatic",
				"text": "3. [Thương Lộ] \"Tu hành mà thiếu tài nguyên linh thạch thì chỉ là mộng ảo, tích lũy của cải mới là gốc rễ!\"",
				"affinity_delta": 15,
				"relationship_delta": { "affinity": 15, "trust": 20, "debt": 10, "grudge": 0, "fear": 0 },
				"market_modifiers": { "general": 0.95 },
				"memory_event": {
					"event_type": "pragmatic_deal_discussed",
					"severity": 1,
					"is_public": true,
					"desc": "Người chơi trao đổi kinh nghiệm khai thác tài nguyên và tích lũy linh thạch."
				},
				"npc_response": "%s vỗ tay cười sảng khoái:\n\"Thực tế! Rất thực tế! Không có linh thạch mua đan dược thì nói chuyện trường sinh chỉ là viển vông!\"" % name
			},
			{
				"id": "gen_enlightenment",
				"tag": "[Đạo Duyên]",
				"category": "enlightenment",
				"text": "4. [Đạo Duyên] \"Vạn vật đồng nguyên, âm dương luân chuyển, đạo hữu hãy thử lắng nghe linh khí đất trời nơi này.\"",
				"affinity_delta": 25,
				"relationship_delta": { "affinity": 25, "trust": 30, "debt": 0, "grudge": 0, "fear": 0 },
				"npc_xp_boost": 40,
				"give_items": { "item_linh_thao": 1 },
				"memory_event": {
					"event_type": "spiritual_communion",
					"severity": 2,
					"is_public": true,
					"desc": "Người chơi cùng %s luận bàn đại đạo, cộng hưởng chân khí đốn ngộ."
				},
				"npc_response": "%s nhắm mắt trầm ngâm rồi thở ra một luồng trọc khí, thần quang sáng rực:\n\"Đa tạ đạo hữu điểm hóa! Chân lý thiên đạo hóa ra giản dị đến vậy. Gốc linh thảo này ta giữ đã lâu, xin tặng đạo hữu làm kỷ niệm!\"" % name
			},
			{
				"id": "gen_aloof",
				"tag": "[Bình Thản]",
				"category": "aloof",
				"text": "5. [Bình Thản] \"Đạo khả đạo phi thường đạo, nói nhiều cũng vô ích, lặng lẽ cảm ngộ mới là chân tu.\"",
				"player_xp_boost": 10,
				"affinity_delta": 5,
				"memory_event": {
					"event_type": "silent_contemplation",
					"severity": 1,
					"is_public": false,
					"desc": "Người chơi giữ tâm như mặt nước hồ thu, bất động trước tranh luận."
				},
				"npc_response": "%s mỉm cười khẽ gật đầu:\n\"Tĩnh lặng thắng táo động... Đạo hữu quả có phong thái cao nhân ẩn sĩ.\"" % name
			}
		]
	}
