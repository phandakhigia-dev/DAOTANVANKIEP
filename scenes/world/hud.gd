extends CanvasLayer

## HUD — Giao diện hiển thị thông tin trực tiếp trên màn hình bản đồ (Phase 2)
## Hiển thị thời gian số đếm tự động (12 phút/ngày), 12 Canh giờ, Sổ Nhân Duyên, Đại Sự Ký.

@onready var label_player_name: Label = $MarginContainer/HBoxHeader/PanelPlayer/VBox/LabelPlayerName
@onready var label_realm: Label = $MarginContainer/HBoxHeader/PanelPlayer/VBox/LabelRealm
@onready var hp_bar: ProgressBar = $MarginContainer/HBoxHeader/PanelPlayer/VBox/HPBar
@onready var label_hp_val: Label = $MarginContainer/HBoxHeader/PanelPlayer/VBox/HPBar/LabelHPVal

@onready var label_date: Label = $MarginContainer/HBoxHeader/PanelWorld/VBox/LabelDate
@onready var label_coords: Label = $MarginContainer/HBoxHeader/PanelWorld/VBox/LabelCoords
@onready var label_seed: Label = $MarginContainer/HBoxHeader/PanelWorld/VBox/LabelSeed

@onready var btn_open_char: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnCharacter
@onready var btn_open_inv: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnInventory
@onready var btn_open_soc: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnSocial
@onready var btn_open_gazette: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnGazette
@onready var btn_meditate: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnMeditate
@onready var btn_coop: Button = $MarginContainer/HBoxHeader/CenterButtons/BtnCoop

@onready var label_toast: Label = $ToastContainer/LabelToast
@onready var toast_container: Control = $ToastContainer

@onready var prompt_container: PanelContainer = $PromptContainer
@onready var label_prompt: Label = $PromptContainer/LabelPrompt

@onready var inventory_panel: Control = $InventoryPanel
@onready var character_panel: Control = $CharacterPanel
@onready var social_panel: Control = $SocialPanel
@onready var monthly_summary_modal: Control = $MonthlySummaryModal
@onready var coop_menu_modal: Control = $CoopMenuModal

var _toast_timer: float = 0.0

func _ready() -> void:
	prompt_container.visible = false
	for btn in [btn_open_char, btn_open_inv, btn_open_soc, btn_open_gazette, btn_meditate, btn_coop]:
		btn.focus_mode = Control.FOCUS_NONE
	btn_open_char.pressed.connect(func(): character_panel.open_panel())
	btn_open_inv.pressed.connect(func(): inventory_panel.open_panel())
	btn_open_soc.pressed.connect(func(): social_panel.open_panel())
	btn_open_gazette.pressed.connect(func(): monthly_summary_modal.open_modal())
	btn_meditate.pressed.connect(_toggle_meditation)
	btn_coop.pressed.connect(func(): coop_menu_modal.open_panel())
	
	_connect_signals()
	_update_player_info()
	_update_world_info()

func _connect_signals() -> void:
	if EventBus:
		EventBus.day_advanced.connect(_on_day_advanced)
		EventBus.player_hp_changed.connect(_on_hp_changed)
		EventBus.player_realm_changed.connect(_on_realm_changed)
		EventBus.player_moved.connect(_on_player_moved)
		EventBus.notification_requested.connect(show_toast)
		if EventBus.has_signal("time_scale_changed"):
			EventBus.time_scale_changed.connect(_on_time_scale_changed)

func _process(delta: float) -> void:
	# Cập nhật thời gian dòng chảy số đếm liên tục
	label_date.text = GameClock.get_formatted_full()
	
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_container.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Nếu đang mở bất kỳ panel nào thì không nhận hotkey mở panel khác
	if inventory_panel.visible or character_panel.visible or social_panel.visible or monthly_summary_modal.visible or coop_menu_modal.visible:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			inventory_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			character_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J:
			social_panel.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L:
			monthly_summary_modal.open_modal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_O:
			coop_menu_modal.open_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_X:
			_toggle_meditation()
			get_viewport().set_input_as_handled()

func _toggle_meditation() -> void:
	if SessionAuthority and SessionAuthority.is_coop_session():
		show_toast("✦ Trong phòng Co-op: Tốc độ thời gian cố định 1x theo máy chủ Host!", "warning")
		return
		
	if GameClock.time_scale <= 1.0:
		GameClock.set_time_scale(20.0)
		btn_meditate.text = "[X] Xuất Định"
		show_toast("✦ Nhập Định Tĩnh Tọa: Thời gian gia tốc x20!", "info")
	else:
		GameClock.set_time_scale(1.0)
		btn_meditate.text = "[X] Tĩnh Tọa"
		show_toast("✦ Xuất Định: Thời gian trở lại bình thường (12 phút/ngày).", "info")

func _on_time_scale_changed(scale_val: float) -> void:
	if scale_val > 1.0:
		btn_meditate.text = "[X] Xuất Định"
	else:
		btn_meditate.text = "[X] Tĩnh Tọa"

func show_interaction_prompt(msg: String) -> void:
	if msg == "":
		prompt_container.visible = false
	else:
		label_prompt.text = msg
		prompt_container.visible = true

func _update_player_info() -> void:
	label_player_name.text = GameSession.player_name
	var realm = ContentRegistry.get_realm(GameSession.realm_id)
	label_realm.text = "Cảnh giới: " + realm.get("name", "Phàm Nhân")
	
	hp_bar.max_value = GameSession.max_hp
	hp_bar.value = GameSession.current_hp
	label_hp_val.text = "%d / %d" % [GameSession.current_hp, GameSession.max_hp]

func _update_world_info() -> void:
	label_date.text = GameClock.get_formatted_full()
	label_coords.text = "Tọa độ: (%d, %d)" % [int(GameSession.world_position.x / 64.0), int(GameSession.world_position.y / 64.0)]
	label_seed.text = "Hạt giống thế giới: %d" % GameSession.world_seed

func _on_day_advanced(_d: int, _m: int, _y: int) -> void:
	label_date.text = GameClock.get_formatted_full()

func _on_hp_changed(curr: int, m_hp: int) -> void:
	hp_bar.max_value = m_hp
	hp_bar.value = curr
	label_hp_val.text = "%d / %d" % [curr, m_hp]

func _on_realm_changed(new_realm: String) -> void:
	var realm = ContentRegistry.get_realm(new_realm)
	label_realm.text = "Cảnh giới: " + realm.get("name", "Phàm Nhân")

func _on_player_moved(pos: Vector2) -> void:
	label_coords.text = "Tọa độ: (%d, %d)" % [int(pos.x / 64.0), int(pos.y / 64.0)]

func show_toast(msg: String, _type: String = "info") -> void:
	label_toast.text = msg
	toast_container.visible = true
	_toast_timer = 3.0
