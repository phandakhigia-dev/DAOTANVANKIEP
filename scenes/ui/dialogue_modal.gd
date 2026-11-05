extends Control

## DialogueModal — Giao diện Đối thoại, Giao dịch và Nhận/Trả Nhiệm vụ với NPC
## Hỗ trợ 6 NPC của Thanh Trì Trấn với hệ thống hảo cảm, hội thoại động và nhánh sự kiện.

const DialogueScenarioService = preload("res://scripts/domain/dialogue_scenario_service.gd")

signal dialogue_closed

@onready var label_npc_name: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/VBox/LabelNPCName
@onready var label_npc_title: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/VBox/LabelNPCTitle
@onready var label_affinity: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/LabelAffinity

@onready var label_dialogue_text: Label = $PanelContainer/MarginContainer/VBoxContainer/DialogueBox/Margin/LabelDialogue
@onready var label_choice_header: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelChoiceHeader
@onready var actions_container: VBoxContainer = (
	get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
	if has_node("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
	else get_node("PanelContainer/MarginContainer/VBoxContainer/ActionsContainer")
)

var _current_npc_id: String = ""
var _custom_npc_data: Dictionary = {}
var _chatted_this_session: bool = false
var _current_scenario: Dictionary = {}

func _ready() -> void:
	visible = false

func open_dialogue(param: Variant = null) -> void:
	if param is String:
		open_for_npc(param)
	elif param is Dictionary:
		var nid = param.get("id", "")
		if nid != "" and ContentRegistry and ContentRegistry.get_npc(nid).size() > 0:
			open_for_npc(nid)
		else:
			open_for_custom_npc(param)
	else:
		visible = true
		_refresh_display()

func open_for_npc(npc_id: String) -> void:
	_custom_npc_data = {}
	_current_npc_id = npc_id
	_chatted_this_session = false
	visible = true
	_refresh_display()

func open_for_custom_npc(data: Dictionary) -> void:
	_custom_npc_data = data
	_current_npc_id = data.get("id", "")
	_chatted_this_session = false
	visible = true
	_refresh_display()

func close_dialogue() -> void:
	visible = false
	_current_npc_id = ""
	_custom_npc_data = {}
	dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_dialogue()
		get_viewport().set_input_as_handled()

func _refresh_display() -> void:
	if label_choice_header:
		label_choice_header.text = "Chọn cách ứng xử / hành động:"
	if not _custom_npc_data.is_empty():
		var c_name = _custom_npc_data.get("name", "Vô Danh")
		var c_role = _custom_npc_data.get("role", "Tán Tu")
		var c_realm = _custom_npc_data.get("realm_name", "Phàm Nhân")
		var c_drive = _custom_npc_data.get("core_drive", {})
		label_npc_name.text = c_name
		label_npc_title.text = "[%s] • Cảnh giới: %s" % [c_role, c_realm]
		label_affinity.text = "Hảo cảm: Trung Lập (0)"
		label_affinity.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		label_dialogue_text.text = c_drive.get("dialogue", "Đạo hữu cũng tới Thanh Trì tìm kiếm cơ duyên?")
		_rebuild_custom_npc_actions()
		return

	var npc = ContentRegistry.get_npc(_current_npc_id)
	if npc.is_empty():
		label_npc_name.text = "Nhân vật bí ẩn"
		label_npc_title.text = "Không rõ lai lịch"
		label_affinity.text = "Hảo cảm: 0"
		label_dialogue_text.text = "..."
		_rebuild_action_buttons()
		return
	
	label_npc_name.text = npc.get("name", "NPC")
	label_npc_title.text = "[%s] • %s" % [npc.get("role", "Cư Dân"), npc.get("location_name", "Thanh Trì")]
	
	var aff = GameSession.get_npc_affinity(_current_npc_id)
	var aff_str = "Trung Lập"
	var aff_col = Color(0.8, 0.8, 0.8)
	if aff >= 50:
		aff_str = "Kính Trọng (+%d)" % aff
		aff_col = Color(0.4, 0.9, 0.5)
	elif aff >= 20:
		aff_str = "Thân Thiết (+%d)" % aff
		aff_col = Color(0.5, 0.8, 1.0)
	elif aff >= 5:
		aff_str = "Hữu Hảo (+%d)" % aff
		aff_col = Color(0.7, 0.85, 0.7)
	elif aff < 0:
		aff_str = "Lạnh Nhạt (%d)" % aff
		aff_col = Color(0.9, 0.4, 0.4)
	
	label_affinity.text = "Hảo cảm: %s" % aff_str
	label_affinity.add_theme_color_override("font_color", aff_col)
	
	# Hội thoại mặc định
	var dlgs = npc.get("dialogues", {})
	label_dialogue_text.text = dlgs.get("greeting", "Chào đạo hữu...")
	
	_rebuild_action_buttons()

func _rebuild_action_buttons() -> void:
	if not actions_container:
		actions_container = (
			get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			if has_node("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			else get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ActionsContainer")
		)
	if not actions_container:
		return
	# Xóa nút cũ
	for child in actions_container.get_children():
		child.queue_free()
	
	var npc = ContentRegistry.get_npc(_current_npc_id)
	var dlgs = npc.get("dialogues", {})
	
	# 0. Nút Nhiệm vụ (nếu có logic quest)
	_add_quest_buttons()
	
	# 1. Nút Vấn Đạo Luận Thế (Nhánh Hội Thoại & Vận Mệnh Thế Giới)
	var btn_scenario = Button.new()
	btn_scenario.custom_minimum_size = Vector2(0, 44)
	btn_scenario.text = "★ [Vấn Đạo Luận Thế] Khảo Nghiệm Đạo Tâm (3 - 5 Nhánh Lựa Chọn)"
	btn_scenario.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	btn_scenario.pressed.connect(_open_scenario_view)
	actions_container.add_child(btn_scenario)
	
	# 2. Nút Trò chuyện
	var btn_chat = Button.new()
	btn_chat.custom_minimum_size = Vector2(0, 42)
	btn_chat.text = "1. Trò chuyện & Thăm dò tin tức"
	btn_chat.pressed.connect(_on_chat_pressed)
	actions_container.add_child(btn_chat)
	
	# 3. Nút Dịch vụ / Mua bán
	if npc.has("shop_inventory"):
		var btn_shop = Button.new()
		btn_shop.custom_minimum_size = Vector2(0, 42)
		btn_shop.text = "2. Giao dịch / Mua bán linh dược"
		btn_shop.pressed.connect(_on_shop_pressed)
		actions_container.add_child(btn_shop)
	
	# 4. Nút Tông môn (Thanh Vi Tông)
	if npc.get("sect_id", "") == "sect_thanh_vi":
		var btn_sect = Button.new()
		btn_sect.custom_minimum_size = Vector2(0, 42)
		btn_sect.text = "3. Thỉnh giáo Thanh Vi Tông (Gia nhập / Nạp cống hiến)"
		btn_sect.pressed.connect(_on_sect_service_pressed)
		actions_container.add_child(btn_sect)
	
	# 5. Nút Cáo từ
	var btn_leave = Button.new()
	btn_leave.custom_minimum_size = Vector2(0, 38)
	btn_leave.text = "Cáo từ (Rời đi)"
	btn_leave.pressed.connect(close_dialogue)
	actions_container.add_child(btn_leave)

func _add_quest_buttons() -> void:
	var q_state = GameSession.get_quest_state("q_first_spirit_vein")
	var status = q_state.get("status", "not_started")
	var step = q_state.get("current_step", 0)
	
	if _current_npc_id == "npc_mac_tu_vien":
		if status == "not_started":
			var btn_q = Button.new()
			btn_q.custom_minimum_size = Vector2(0, 44)
			btn_q.text = "★ [Nhiệm Vụ] Nhận ủy thác: Khám phá Linh Mạch Vân Lĩnh"
			btn_q.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			btn_q.pressed.connect(func():
				GameSession.start_quest("q_first_spirit_vein")
				label_dialogue_text.text = "Mạc Tư Viễn vuốt râu mỉm cười:\n\"Đạo hữu quả là người dũng khí! Vùng rìa Vân Lĩnh linh khí hỗn loạn, có đàn Linh Thú và một con Xích Kiếm Ma Thứu chiếm cứ. Hãy tiến về Vân Lĩnh Rìa trên bản đồ, tiêu diệt nó và thu hồi Cổ Kiếm Tàn Phiến mang về cho ta!\""
				if EventBus:
					EventBus.notification_requested.emit("Đã nhận nhiệm vụ: Khám phá Linh Mạch Vân Lĩnh!", "info")
				_refresh_display()
			)
			actions_container.add_child(btn_q)
		
		elif status == "active":
			if step >= 3 or GameSession.has_item("item_co_kiem_tan_phien"):
				var btn_turnin = Button.new()
				btn_turnin.custom_minimum_size = Vector2(0, 44)
				btn_turnin.text = "★ [Nhiệm Vụ] Giao nộp Cổ Kiếm Tàn Phiến & Nhận Thưởng"
				btn_turnin.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
				btn_turnin.pressed.connect(func():
					GameSession.advance_quest("q_first_spirit_vein", 4)
					var completed = GameSession.complete_quest("q_first_spirit_vein")
					if completed:
						label_dialogue_text.text = "Mạc Tư Viễn kinh ngạc thốt lên:\n\"Thật không ngờ đạo hữu lại chém chết được hung điểu Ma Thứu! Đây chính là mảnh vỡ của Cổ Kiếm trận pháp ngàn năm trước. Xin hãy nhận 100 Linh Thạch và 2 viên Tụ Khí Đan này để xung kích đột phá Luyện Khí!\""
						if EventBus:
							EventBus.notification_requested.emit("Nhiệm vụ hoàn thành! Nhận 100 Linh Thạch, 2x Tụ Khí Đan!", "success")
					_refresh_display()
				)
				actions_container.add_child(btn_turnin)
			else:
				var btn_hint = Button.new()
				btn_hint.custom_minimum_size = Vector2(0, 40)
				btn_hint.text = "Hỏi về tiến độ nhiệm vụ Vân Lĩnh"
				btn_hint.pressed.connect(func():
					label_dialogue_text.text = "Mạc Tư Viễn nhắc nhở:\n\"Vân Lĩnh Rìa nằm ở phía Đông Bắc bản đồ (biểu tượng núi đá). Hãy đến đó, bước vào Bí Cảnh khiêu chiến ma thú! Cẩn thận chiêu thức càn quét của Xích Kiếm Ma Thứu!\""
				)
				actions_container.add_child(btn_hint)

func _on_chat_pressed() -> void:
	var npc = ContentRegistry.get_npc(_current_npc_id)
	var dlgs = npc.get("dialogues", {})
	if not _chatted_this_session:
		_chatted_this_session = true
		GameSession.modify_npc_affinity(_current_npc_id, 3)
		var chat_text = dlgs.get("gossip", "Gần đây linh khí thiên địa có dấu hiệu ba động lạ...")
		label_dialogue_text.text = "%s\n\n(Hảo cảm với %s tăng +3 điểm)" % [chat_text, npc.get("name", "")]
		if EventBus:
			EventBus.notification_requested.emit("Hảo cảm với %s tăng +3!" % npc.get("name", ""), "info")
		_refresh_display()
	else:
		label_dialogue_text.text = "Hai bên hàn huyên vui vẻ một hồi, tình cảm đôi bên thêm gắn bó."

func _on_shop_pressed() -> void:
	var npc = ContentRegistry.get_npc(_current_npc_id)
	var shop = npc.get("shop_inventory", [])
	if shop.is_empty():
		label_dialogue_text.text = "Hiện tại ta không có vật phẩm nào để bán."
		return
	
	# Hiển thị danh sách mua bán
	for child in actions_container.get_children():
		child.queue_free()
	
	label_dialogue_text.text = "%s mở rương bảo vật:\n\"Mời đạo hữu xem qua đan dược linh thảo, giá cả công đạo!\"" % npc.get("name", "")
	
	for item_id in shop:
		var item_def = ContentRegistry.get_item(item_id)
		var item_name = item_def.get("name", item_id)
		var price = item_def.get("price_buy", 50)
		
		var btn_buy = Button.new()
		btn_buy.custom_minimum_size = Vector2(0, 42)
		btn_buy.text = "Mua %s — %d Linh Thạch" % [item_name, price]
		var captured_id = item_id
		var captured_price = price
		var captured_name = item_name
		btn_buy.pressed.connect(func():
			var stones = GameSession.get_item_count("item_linh_thach")
			if stones >= captured_price:
				GameSession.remove_item("item_linh_thach", captured_price)
				GameSession.add_item(captured_id, 1)
				if EventBus:
					EventBus.notification_requested.emit("Đã mua thành công 1x %s!" % captured_name, "success")
				label_dialogue_text.text = "Giao dịch thành công! Nhận được %s." % captured_name
			else:
				if EventBus:
					EventBus.notification_requested.emit("Linh thạch không đủ! Cần %d viên." % captured_price, "error")
				label_dialogue_text.text = "Đạo hữu không đủ linh thạch rồi!"
		)
		actions_container.add_child(btn_buy)
	
	var btn_back = Button.new()
	btn_back.custom_minimum_size = Vector2(0, 38)
	btn_back.text = "Quay lại hội thoại"
	btn_back.pressed.connect(_rebuild_action_buttons)
	actions_container.add_child(btn_back)

func _on_sect_service_pressed() -> void:
	for child in actions_container.get_children():
		child.queue_free()
	
	label_dialogue_text.text = "Đại biểu Thanh Vi Tông nghiêm trang nói:\n\"Thanh Vi Tông ta là chính đạo danh môn của Thanh Trì. Tán tu muốn gia nhập hoặc thỉnh cầu che chở cần thể hiện lòng thành hoặc dâng nạp linh tài.\""
	
	var btn_donate = Button.new()
	btn_donate.custom_minimum_size = Vector2(0, 42)
	btn_donate.text = "Cúng dường 50 Linh Thạch (Tăng uy vọng tông môn & hảo cảm)"
	btn_donate.pressed.connect(func():
		var stones = GameSession.get_item_count("item_linh_thach")
		if stones >= 50:
			GameSession.remove_item("item_linh_thach", 50)
			GameSession.modify_npc_affinity(_current_npc_id, 15)
			label_dialogue_text.text = "Đoàn Vĩnh gật đầu tán thưởng:\n\"Thiện tai! Tông môn ghi nhận công đức của đạo hữu. Tương lai vào tông sẽ được ưu ái!\""
			if EventBus:
				EventBus.notification_requested.emit("Đã cúng dường 50 Linh Thạch! Hảo cảm +15!", "success")
		else:
			label_dialogue_text.text = "Đạo hữu mang theo không đủ 50 Linh Thạch!"
	)
	actions_container.add_child(btn_donate)
	
	var btn_blessing = Button.new()
	btn_blessing.custom_minimum_size = Vector2(0, 42)
	btn_blessing.text = "Thỉnh thụ Thanh Vi Trúc Cơ Tâm Pháp (Khuyên tu)"
	btn_blessing.pressed.connect(func():
		label_dialogue_text.text = "Lâm Du chỉ điểm:\n\"Đạo hữu chớ nóng vội. Hãy ngưng luyện khí tức, dùng Tụ Khí Đan xung khai đan điền đạt Luyện Khí Tầng 1 trước, sau đó mới có thể lĩnh hội kiếm ý chân truyền của bổn tông.\""
	)
	actions_container.add_child(btn_blessing)
	
	var btn_back = Button.new()
	btn_back.custom_minimum_size = Vector2(0, 38)
	btn_back.text = "Quay lại hội thoại"
	btn_back.pressed.connect(_rebuild_action_buttons)
	actions_container.add_child(btn_back)

# --- CÁC HÀNH ĐỘNG DÀNH CHO NPC THỦ TỤC DÃ NGOẠI / VÃNG LAI (PROCEDURAL NPCS) ---

func _rebuild_custom_npc_actions() -> void:
	if not actions_container:
		actions_container = (
			get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			if has_node("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			else get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ActionsContainer")
		)
	if not actions_container:
		return
	for child in actions_container.get_children():
		child.queue_free()
	
	# 0. Nút Vấn Đạo Luận Thế dã ngoại
	var btn_scenario = Button.new()
	btn_scenario.custom_minimum_size = Vector2(0, 44)
	btn_scenario.text = "★ [Vấn Đạo Luận Thế] Can Thiệp Vận Mệnh & Dị Duyên (3 - 5 Nhánh Lựa Chọn)"
	btn_scenario.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	btn_scenario.pressed.connect(_open_scenario_view)
	actions_container.add_child(btn_scenario)
	
	var btn_talk = Button.new()
	btn_talk.custom_minimum_size = Vector2(0, 42)
	btn_talk.text = "1. Đàm đạo về chí hướng & cuộc đời"
	btn_talk.pressed.connect(_on_custom_chat_pressed)
	actions_container.add_child(btn_talk)
	
	var btn_secret = Button.new()
	btn_secret.custom_minimum_size = Vector2(0, 42)
	btn_secret.text = "2. Thăm dò bí mật nhân sinh & cơ duyên ẩn tàng"
	btn_secret.pressed.connect(_on_custom_secret_pressed)
	actions_container.add_child(btn_secret)
	
	var btn_trade = Button.new()
	btn_trade.custom_minimum_size = Vector2(0, 42)
	btn_trade.text = "3. Trao đổi linh tài / Mua bán tạp vật"
	btn_trade.pressed.connect(_on_custom_trade_pressed)
	actions_container.add_child(btn_trade)
	
	var btn_gift = Button.new()
	btn_gift.custom_minimum_size = Vector2(0, 42)
	btn_gift.text = "4. Tặng 10 Linh Thạch kết duyên giao hảo"
	btn_gift.pressed.connect(_on_custom_gift_pressed)
	actions_container.add_child(btn_gift)
	
	var btn_leave = Button.new()
	btn_leave.custom_minimum_size = Vector2(0, 38)
	btn_leave.text = "Cáo từ (Rời đi)"
	btn_leave.pressed.connect(close_dialogue)
	actions_container.add_child(btn_leave)

func _on_custom_chat_pressed() -> void:
	var c_name = _custom_npc_data.get("name", "Vô Danh")
	var c_drive = _custom_npc_data.get("core_drive", {})
	var c_quirk = _custom_npc_data.get("quirk", {})
	var c_chronicle = _custom_npc_data.get("chronicle", [])
	var age = _custom_npc_data.get("age_years", 25)
	var max_age = _custom_npc_data.get("max_lifespan_years", 80)
	var lifespan_type = _custom_npc_data.get("lifespan_type", "medium")
	
	var lifespan_desc = "Thọ nguyên phàm trần (~%d tuổi)" % max_age
	if lifespan_type == "short":
		lifespan_desc = "Đoản mệnh nan y / tử kiếp rình rập (~%d tuổi)" % max_age
	elif lifespan_type == "long":
		lifespan_desc = "Trường sinh căn cốt dồi dào (~%d tuổi)" % max_age
	
	var text = "%s thở dài, ánh mắt xa xăm:\n\"%s\"\n\n" % [c_name, c_drive.get("dialogue", "")]
	text += "• Tuổi tác: %d tuổi | %s\n" % [age, lifespan_desc]
	text += "• Thói quen: %s\n" % c_quirk.get("desc", c_quirk.get("name", "Bình dị"))
	text += "• Biên niên sử nhân sinh:\n"
	for event in c_chronicle:
		text += "  - %s\n" % event
		
	label_dialogue_text.text = text

func _on_custom_secret_pressed() -> void:
	var c_name = _custom_npc_data.get("name", "Vô Danh")
	var c_secret = _custom_npc_data.get("life_secret", {})
	var secret_name = c_secret.get("title", c_secret.get("name", "Không có bí mật đặc biệt"))
	var secret_detail = c_secret.get("desc", c_secret.get("detail", "Người này hành sự cẩn mật, chưa chịu hé lộ thêm."))
	
	label_dialogue_text.text = "%s nhìn quanh bốn phía, khẽ truyền âm mật thuật:\n\"Bí mật này ta chưa từng nói với ai: [%s]\n%s\"" % [c_name, secret_name, secret_detail]
	if EventBus:
		EventBus.notification_requested.emit("Đã phát hiện bí mật nhân sinh của %s!" % c_name, "info")

func _on_custom_trade_pressed() -> void:
	for child in actions_container.get_children():
		child.queue_free()
		
	var c_name = _custom_npc_data.get("name", "Vô Danh")
	label_dialogue_text.text = "%s mở tay nải:\n\"Ta đi nhiều nơi, góp nhặt được chút ít linh tài dã ngoại. Đạo hữu xem có vừa mắt món nào chăng?\"" % c_name
	
	# Mua Linh Thảo (8 Linh Thạch)
	var btn_buy_herb = Button.new()
	btn_buy_herb.custom_minimum_size = Vector2(0, 42)
	btn_buy_herb.text = "Mua 1x Linh Thảo [Giá: 8 Linh Thạch]"
	btn_buy_herb.pressed.connect(func():
		var stones = GameSession.get_item_count("item_linh_thach")
		if stones >= 8:
			GameSession.remove_item("item_linh_thach", 8)
			GameSession.add_item("item_linh_thao", 1)
			label_dialogue_text.text = "%s trao cho bạn 1 gốc linh thảo tươi tốt.\n\"Đa tạ đạo hữu hạ cố ủng hộ!\"" % c_name
			if EventBus:
				EventBus.notification_requested.emit("Đã mua 1x Linh Thảo (8 LT)!", "success")
		else:
			label_dialogue_text.text = "\"Đạo hữu không đủ 8 linh thạch rồi!\""
	)
	actions_container.add_child(btn_buy_herb)
	
	# Bán Linh Thảo lấy 5 Linh Thạch
	var btn_sell_herb = Button.new()
	btn_sell_herb.custom_minimum_size = Vector2(0, 42)
	btn_sell_herb.text = "Bán 1x Linh Thảo [Thu về: 5 Linh Thạch]"
	btn_sell_herb.pressed.connect(func():
		var herbs = GameSession.get_item_count("item_linh_thao")
		if herbs >= 1:
			GameSession.remove_item("item_linh_thao", 1)
			GameSession.add_item("item_linh_thach", 5)
			label_dialogue_text.text = "%s nhận lấy linh thảo và đếm trả 5 viên linh thạch sáng bóng." % c_name
			if EventBus:
				EventBus.notification_requested.emit("Đã bán 1x Linh Thảo nhận 5 LT!", "success")
		else:
			label_dialogue_text.text = "\"Trong túi đạo hữu không có linh thảo để bán!\""
	)
	actions_container.add_child(btn_sell_herb)
	
	var btn_back = Button.new()
	btn_back.custom_minimum_size = Vector2(0, 38)
	btn_back.text = "Quay lại đàm đạo"
	btn_back.pressed.connect(_rebuild_custom_npc_actions)
	actions_container.add_child(btn_back)

func _on_custom_gift_pressed() -> void:
	var c_name = _custom_npc_data.get("name", "Vô Danh")
	var stones = GameSession.get_item_count("item_linh_thach")
	if stones >= 10:
		GameSession.remove_item("item_linh_thach", 10)
		label_dialogue_text.text = "%s xúc động chắp tay:\n\"Đạo hữu khẳng khái trượng nghĩa! Tấm chân tình này tại hạ ghi lòng tạc dạ, sau này tất có báo đáp!\"" % c_name
		label_affinity.text = "Hảo cảm: Hữu Hảo (+15)"
		label_affinity.add_theme_color_override("font_color", Color(0.5, 0.9, 0.6))
		if EventBus:
			EventBus.notification_requested.emit("Tặng 10 Linh Thạch thành công! Giao tình gia tăng!", "success")
	else:
		label_dialogue_text.text = "\"Đạo hữu không đủ 10 Linh Thạch để kết lễ!\""

# --- PHÂN NHÁNH HỘI THOẠI 3-5 LỰA CHỌN & KIẾN TẠO THẾ GIỚI (VẤN ĐẠO LUẬN THẾ) ---

func _open_scenario_view() -> void:
	for child in actions_container.get_children():
		child.queue_free()
		
	if label_choice_header:
		label_choice_header.text = "Khảo nghiệm đạo tâm — Lựa chọn 1 trong các nhánh ứng đối thế giới:"
		
	_current_scenario = DialogueScenarioService.generate_scenario(_current_npc_id, _custom_npc_data)
	var title = _current_scenario.get("title", "Khảo Nghiệm")
	var prompt = _current_scenario.get("prompt", "...")
	var choices = _current_scenario.get("choices", [])
	
	label_npc_title.text = "[Vấn Đạo Luận Thế] • %s" % title
	label_dialogue_text.text = prompt
	
	for choice in choices:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		# Tuyệt đối không hiển thị trước được gì mất gì — giữ trọn bí mật, ngẫu nhiên & khó lường
		btn.text = choice.get("text", "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var cat = choice.get("category", "righteous")
		var cat_color = DialogueScenarioService.CATEGORY_COLORS.get(cat, Color(1, 1, 1))
		btn.add_theme_color_override("font_color", cat_color)
		
		var afford_check = DialogueScenarioService.can_player_afford_choice(choice)
		if not afford_check.get("can_afford", true):
			btn.disabled = true
			btn.tooltip_text = afford_check.get("reason", "Chưa đủ điều kiện")
			btn.text += " (Chưa đủ điều kiện)"
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			var cid = choice.get("id", "")
			btn.pressed.connect(func(): _on_scenario_choice_selected(cid))
			
		actions_container.add_child(btn)
		
	var btn_back = Button.new()
	btn_back.custom_minimum_size = Vector2(0, 38)
	btn_back.text = "← Quay lại hội thoại"
	btn_back.pressed.connect(func():
		_refresh_display()
	)
	actions_container.add_child(btn_back)

func _on_scenario_choice_selected(choice_id: String) -> void:
	var res = DialogueScenarioService.execute_choice(_current_scenario, choice_id)
	if not res.get("success", false):
		label_dialogue_text.text = "Không thể thực hiện lựa chọn: %s" % res.get("reason", "Lỗi không xác định")
		return
		
	for child in actions_container.get_children():
		child.queue_free()
		
	if label_choice_header:
		label_choice_header.text = "Kết quả lựa chọn & Biến động thế giới:"
		
	var text = "%s đáp lời:\n\"%s\"\n\n" % [res.get("npc_name", "NPC"), res.get("npc_response", "")]
	text += "═════════════ ẢNH HƯỞNG THẾ GIỚI & NHÂN QUẢ ═════════════\n"
	for line in res.get("consequences", []):
		text += "• %s\n" % line
		
	label_dialogue_text.text = text
	
	# Cập nhật hiển thị hảo cảm tức thì
	var aff = GameSession.get_npc_affinity(_current_npc_id)
	var aff_str = "Trung Lập"
	var aff_col = Color(0.8, 0.8, 0.8)
	if aff >= 50:
		aff_str = "Kính Trọng (+%d)" % aff
		aff_col = Color(0.4, 0.9, 0.5)
	elif aff >= 20:
		aff_str = "Thân Thiết (+%d)" % aff
		aff_col = Color(0.5, 0.8, 1.0)
	elif aff >= 5:
		aff_str = "Hữu Hảo (+%d)" % aff
		aff_col = Color(0.7, 0.85, 0.7)
	elif aff < 0:
		aff_str = "Lạnh Nhạt (%d)" % aff
		aff_col = Color(0.9, 0.4, 0.4)
	label_affinity.text = "Hảo cảm: %s" % aff_str
	label_affinity.add_theme_color_override("font_color", aff_col)
	
	var btn_continue = Button.new()
	btn_continue.custom_minimum_size = Vector2(0, 42)
	btn_continue.text = "◆ Đạo tâm thông suốt — Tiếp tục đàm đạo"
	btn_continue.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	btn_continue.pressed.connect(_refresh_display)
	actions_container.add_child(btn_continue)
	
	var btn_leave = Button.new()
	btn_leave.custom_minimum_size = Vector2(0, 38)
	btn_leave.text = "Cáo từ (Rời đi)"
	btn_leave.pressed.connect(close_dialogue)
	actions_container.add_child(btn_leave)

