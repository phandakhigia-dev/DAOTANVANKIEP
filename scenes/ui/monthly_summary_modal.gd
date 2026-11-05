extends Control

## MonthlySummaryModal — Bảng Tin Đại Sự Ký Giang Hồ (Quá Nguyệt)
## Tự động xuất hiện mỗi khi bước sang tháng mới hoặc người chơi tra cứu (phím L).

@onready var label_title: Label = $PanelContainer/Margin/VBox/Header/LabelTitle
@onready var label_subtitle: Label = $PanelContainer/Margin/VBox/Header/LabelSubtitle
@onready var text_breakthroughs: RichTextLabel = $PanelContainer/Margin/VBox/TabContainer/DotPha/Scroll/TextBreakthroughs
@onready var text_deaths: RichTextLabel = $PanelContainer/Margin/VBox/TabContainer/SinhTu/Scroll/TextDeaths
@onready var text_incidents: RichTextLabel = $PanelContainer/Margin/VBox/TabContainer/DaiSu/Scroll/TextIncidents
@onready var text_market: RichTextLabel = $PanelContainer/Margin/VBox/TabContainer/ThiTruong/Scroll/TextMarket
@onready var btn_close: Button = $PanelContainer/Margin/VBox/Footer/BtnClose

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_modal)
	if EventBus and EventBus.has_signal("open_monthly_summary_requested"):
		EventBus.open_monthly_summary_requested.connect(open_modal)
	if EventBus and EventBus.has_signal("monthly_simulation_completed"):
		EventBus.monthly_simulation_completed.connect(func(_m, _y, summary): open_modal(summary))

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_L or event.keycode == KEY_ESCAPE)):
		close_modal()
		get_viewport().set_input_as_handled()

func open_modal(summary_data: Dictionary = {}) -> void:
	var data = summary_data
	if data.is_empty():
		data = GameSession.get_latest_monthly_summary()
	if data.is_empty():
		# Nếu chưa có tháng nào trôi qua, tạo dữ liệu mẫu đầu game
		data = {
			"month": GameClock.current_month,
			"year": GameClock.current_year,
			"breakthroughs": ["Thế giới Cửu Hoang tĩnh lặng, các đạo hữu đang tích lũy linh khí."],
			"deaths_and_wounds": ["Chưa có tin tức tử thương lớn nào trong vùng."],
			"major_incidents": ["Hồ Thanh Trì sương mù cuồn cuộn, dị tượng Đại Tĩnh Mạch rục rịch."],
			"market_trends": ["Thị trường dược liệu và khoáng thạch tại Thanh Trì Trấn duy trì ổn định."],
			"rumors_and_gossip": ["Nghe đồn nơi Vân Lĩnh có tàn tích cổ kiếm bảo tàng."]
		}
	
	var m = data.get("month", GameClock.current_month)
	var y = data.get("year", GameClock.current_year)
	label_title.text = "📜 ĐẠI SỰ KÝ CỬU HOANG GIỚI"
	label_subtitle.text = "Biến Động Thiên Địa • Tháng %02d Năm %d" % [m, y]
	
	# 1. Đột phá
	var bt_list = data.get("breakthroughs", [])
	if bt_list.is_empty():
		text_breakthroughs.text = "[color=#888888]Tháng này không có ai đột phá đại cảnh giới.[/color]"
	else:
		var bt_str = ""
		for item in bt_list:
			bt_str += "[color=#44ff88]✦ %s[/color]\n\n" % str(item)
		text_breakthroughs.text = bt_str
		
	# 2. Sinh tử & Tọa hóa
	var d_list = data.get("deaths_and_wounds", [])
	if d_list.is_empty():
		text_deaths.text = "[color=#888888]Không có ghi nhận đạo hữu nào tọa hóa hoặc trọng thương.[/color]"
	else:
		var d_str = ""
		for item in d_list:
			d_str += "[color=#ff6666]☠ %s[/color]\n\n" % str(item)
		text_deaths.text = d_str
		
	# 3. Đại sự & Trảm yêu
	var inc_list = data.get("major_incidents", [])
	if inc_list.is_empty():
		text_incidents.text = "[color=#888888]Đại lục bình yên, không có biến cố xung đột lớn.[/color]"
	else:
		var inc_str = ""
		for item in inc_list:
			inc_str += "[color=#e0c068]⚔ %s[/color]\n\n" % str(item)
		text_incidents.text = inc_str
		
	# 4. Thị trường & Tin đồn
	var m_list = data.get("market_trends", [])
	var r_list = data.get("rumors_and_gossip", [])
	var combined_str = ""
	for item in m_list:
		combined_str += "[color=#66ccff]💹 [Thị Trường] %s[/color]\n\n" % str(item)
	for item in r_list:
		combined_str += "[color=#cc99ff]🗣 [Tin Đồn] %s[/color]\n\n" % str(item)
	if combined_str == "":
		combined_str = "[color=#888888]Thị trường bình ổn, không có lời đồn đại đặc sắc.[/color]"
	text_market.text = combined_str
	
	visible = true

func close_modal() -> void:
	visible = false
