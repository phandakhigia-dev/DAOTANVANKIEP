extends Node2D

## TribulationArena — Thiên Kiếp Lôi Đình (Heavenly Tribulation Arena)
## Người chơi phải sống sót 3 đợt sét đánh để đột phá Trúc Cơ Sơ Kỳ.
## - 3 waves, mỗi wave tăng dần cường độ
## - Có tribulation_resist_bonus từ lib_kiep_lei_jue để giảm sát thương
## - Thắng: complete_truc_co_tribulation(true) → đột phá
## - Thua: complete_truc_co_tribulation(false) → thất bại

signal tribulation_complete(survived: bool)

# --- Trạng thái chiến đấu ---
var current_wave: int = 0
var total_waves: int = 3
var player_hp: int = 0
var player_max_hp: int = 0
var is_active: bool = false
var wave_timer: float = 0.0
var lightning_timer: float = 0.0
var lightning_interval: float = 2.0
var lightning_flashes: Array[Dictionary] = []  # { pos, age, max_age }

# Wave config: [num_strikes, damage_per_strike, interval]
const WAVE_CONFIG = [
	{ "strikes": 3, "damage": 40, "interval": 2.5, "desc": "Đợt 1: Khí Lôi Thức Tỉnh" },
	{ "strikes": 5, "damage": 65, "interval": 2.0, "desc": "Đợt 2: Huyết Lôi Trận Pháp" },
	{ "strikes": 7, "damage": 90, "interval": 1.5, "desc": "Đợt 3: Thiên Lôi Chí Cực — Vượt Kiếp Trường Sinh!" }
]
var current_strike: int = 0
var wave_desc: String = ""

# UI refs
@onready var label_title: Label = $HUD/VBox/LabelTitle
@onready var label_wave: Label = $HUD/VBox/LabelWave
@onready var label_hp: Label = $HUD/VBox/LabelHP
@onready var label_resist: Label = $HUD/VBox/LabelResist
@onready var label_msg: Label = $HUD/VBox/LabelMsg
@onready var progress_hp: ProgressBar = $HUD/VBox/ProgressHP
@onready var btn_dodge: Button = $HUD/VBox/BtnDodge

const VFXLightningImpactScene = preload("res://scenes/vfx/vfx_lightning_impact.tscn")

func _ready() -> void:
	if not GameSession.pending_tribulation:
		# Không có tribulation đang chờ → quay lại ngay
		_finish(false)
		return
	
	if AudioService:
		AudioService.play_bgm("bgm_tribulation")
		
	player_hp = GameSession.current_hp
	player_max_hp = GameSession.max_hp
	is_active = true
	current_wave = 0
	
	_update_ui()
	_start_wave(0)

func _start_wave(wave_idx: int) -> void:
	current_wave = wave_idx
	current_strike = 0
	wave_timer = 0.0
	var cfg = WAVE_CONFIG[wave_idx]
	wave_desc = cfg["desc"]
	lightning_interval = cfg["interval"]
	
	if label_wave:
		label_wave.text = "Đợt %d/%d — %s" % [wave_idx + 1, total_waves, wave_desc]
	if label_msg:
		label_msg.text = "⚡ Thiên lôi đang tích tụ... Hãy né tránh!"
	_update_ui()

func _process(delta: float) -> void:
	if not is_active:
		return
	
	wave_timer += delta
	
	var cfg = WAVE_CONFIG[current_wave]
	
	if wave_timer >= lightning_interval:
		wave_timer = 0.0
		if current_strike < cfg["strikes"]:
			_strike_lightning(cfg["damage"])
			current_strike += 1
		else:
			# Wave kết thúc
			if current_wave + 1 < total_waves:
				_start_wave(current_wave + 1)
			else:
				# Tất cả wave xong → chiến thắng
				is_active = false
				_finish(player_hp > 0)
	
	# Cập nhật flash
	for i in range(lightning_flashes.size() - 1, -1, -1):
		lightning_flashes[i]["age"] += delta
		if lightning_flashes[i]["age"] >= lightning_flashes[i]["max_age"]:
			lightning_flashes.remove_at(i)
	queue_redraw()

func _strike_lightning(base_damage: int) -> void:
	# Tính sát thương sau khi áp dụng tribulation resist
	var resist = GameSession.tribulation_resist_bonus
	var actual_damage = int(base_damage * (1.0 - resist))
	actual_damage = maxi(actual_damage, 5)  # tối thiểu 5 HP
	
	player_hp -= actual_damage
	if player_hp <= 0:
		player_hp = 0
		is_active = false
		if label_msg:
			label_msg.text = "⚡ KHÍ HUYẾT TAN VỠ! Thiên Kiếp thất bại — tu vi sụp đổ!"
		_finish(false)
		return
	
	# Flash hiệu ứng
	var vp = get_viewport_rect()
	var flash_x = randf_range(vp.size.x * 0.2, vp.size.x * 0.8)
	var impact_pos = Vector2(flash_x, vp.size.y * 0.6)
	
	lightning_flashes.append({
		"pos": Vector2(flash_x, 0),
		"age": 0.0,
		"max_age": 0.5,
		"damage": actual_damage
	})
	
	# Âm thanh & VFX Lôi Bạo
	if AudioService:
		AudioService.play_sfx("sfx_lightning_strike")
	
	if VFXLightningImpactScene:
		var vfx = VFXLightningImpactScene.instantiate()
		vfx.position = impact_pos
		add_child(vfx)
	
	var resist_pct = int(resist * 100)
	if label_msg:
		if resist > 0:
			label_msg.text = "⚡ Sét đánh! -%d HP (Giảm %d%% nhờ Thiên Kiếp Lôi Quyết)" % [actual_damage, resist_pct]
		else:
			label_msg.text = "⚡ SÉT ĐÁNH! -%d HP — Khí huyết dao động mạnh!" % actual_damage
	
	_update_ui()

func _draw() -> void:
	# Vẽ nền tối kiểu tu luyện
	var vp = get_viewport_rect()
	draw_rect(vp, Color(0.04, 0.02, 0.1, 0.9))
	
	# Vẽ các tia sét
	for flash in lightning_flashes:
		var alpha = 1.0 - (flash["age"] / flash["max_age"])
		var color = Color(0.7, 0.9, 1.0, alpha)
		var bright = Color(1.0, 1.0, 1.0, alpha * 0.6)
		var x = flash["pos"].x
		# Tia sét chính
		draw_line(Vector2(x, 0), Vector2(x + randf_range(-20, 20), vp.size.y * 0.4), color, 3.0)
		draw_line(Vector2(x + randf_range(-20, 20), vp.size.y * 0.4), Vector2(x + randf_range(-30, 30), vp.size.y * 0.7), bright, 4.0)
		draw_line(Vector2(x + randf_range(-30, 30), vp.size.y * 0.7), Vector2(x + randf_range(-15, 15), vp.size.y), color, 2.5)
		# Ánh sáng lan rộng
		draw_circle(Vector2(x, vp.size.y * 0.6), 25.0 * alpha, Color(0.5, 0.7, 1.0, alpha * 0.3))

func _update_ui() -> void:
	if label_title:
		label_title.text = "⚡ THIÊN KIẾP LÔI ĐÌNH — TẠO HOÁ THỬ THÁCH ⚡"
	if label_hp:
		label_hp.text = "Khí Huyết: %d / %d" % [player_hp, player_max_hp]
	if progress_hp:
		progress_hp.max_value = player_max_hp
		progress_hp.value = player_hp
	if label_resist:
		var r = GameSession.tribulation_resist_bonus
		if r > 0:
			label_resist.text = "Thiên Kiếp Lôi Quyết: Giảm %d%% sát thương sét" % int(r * 100)
		else:
			label_resist.text = "Không có kháng lôi — cẩn thận!"

func _on_btn_dodge_pressed() -> void:
	# Né tránh thủ công: giảm sát thương đợt tiếp theo thêm 20%
	if is_active and label_msg:
		label_msg.text = "🏃 Thân pháp né tránh! Sẵn sàng đối phó đòn tiếp theo..."

func _finish(survived: bool) -> void:
	if survived and AudioService:
		AudioService.play_sfx("sfx_breakthrough_bell")
		
	GameSession.complete_truc_co_tribulation(survived)
	tribulation_complete.emit(survived)
	
	await get_tree().create_timer(2.5).timeout
	
	var rsp = GameSession.return_scene_path
	if rsp == "" or not ResourceLoader.exists(rsp):
		rsp = "res://scenes/towns/town_map_real.tscn"
	get_tree().change_scene_to_file(rsp)
