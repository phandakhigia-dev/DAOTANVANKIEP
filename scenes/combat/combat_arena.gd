extends Node2D

## CombatArena — Đấu trường chiến đấu thời gian thực 2D (Top-down Real-time Action)
## Tích hợp 3 kỹ năng chủ động (Kiếm/Lôi/Mộc), né chiêu i-frame, cảnh báo Telegraph,
## 3 loại quái thường và 1 Boss (Xích Kiếm Ma Thứu) kèm hệ thống phần thưởng rơi (Loot).

# --- TỌA ĐỘ VÀ KÍCH THƯỚC ĐẤU TRƯỜNG ---
const ARENA_WIDTH: float = 1600.0
const ARENA_HEIGHT: float = 900.0
const ARENA_CENTER: Vector2 = Vector2(960.0, 540.0)

# --- TRẠNG THÁI NGƯỜI CHƠI TRONG COMBAT ---
var player_pos: Vector2 = ARENA_CENTER
var player_vel: Vector2 = Vector2.ZERO
var player_facing: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_dir: Vector2 = Vector2.RIGHT
var is_invulnerable: bool = false

# Cooldowns
var cd_basic: float = 0.0
var cd_skill_1: float = 0.0 # Kiếm Khí Sơ Khởi (2.5s)
var cd_skill_2: float = 0.0 # Lôi Quang Phá (4.0s)
var cd_skill_3: float = 0.0 # Thanh Mộc Trói (5.0s)

# Projectiles & Effects
const VFXSwordSlashScene = preload("res://scenes/vfx/vfx_sword_slash.tscn")
const VFXLightningImpactScene = preload("res://scenes/vfx/vfx_lightning_impact.tscn")
const SwordsmanScene = preload("res://wuxia/32/heroes/swordsman/swordsman.tscn")
const BanditScene = preload("res://wuxia/32/enemies/bandit/bandit.tscn")

var player_sprite: AnimatedSprite2D = null
var screen_shake_intensity: float = 0.0
var screen_shake_timer: float = 0.0

var player_projectiles: Array = [] # {pos, dir, speed, life, dmg, radius, color}
var enemy_projectiles: Array = []  # {pos, dir, speed, life, dmg, radius, color}
var vfx_list: Array = []           # {type, pos, radius, life, max_life, color}
var floating_texts: Array = []     # {pos, text, color, size, life, max_life, speed_y}

# --- QUẢN LÝ QUÁI VẬT & BOSS ---
var current_wave: int = 1
var enemies: Array = [] # Array of enemy dictionaries
var is_combat_over: bool = false
var is_victory: bool = false

# Boss specific
var boss_ref: Dictionary = {}
var target_boss_id: String = "boss_xich_kiem_ma_thu"

func set_target_boss(b_id: String) -> void:
	target_boss_id = b_id

# --- UI NODES ---
@onready var hud_combat: CanvasLayer = $HUDCombat
@onready var hp_bar_player: ProgressBar = $HUDCombat/Margin/BottomLeft/VBox/HPBar
@onready var label_hp_player: Label = $HUDCombat/Margin/BottomLeft/VBox/HPBar/LabelVal
@onready var mp_bar_player: ProgressBar = $HUDCombat/Margin/BottomLeft/VBox/MPBar
@onready var label_mp_player: Label = $HUDCombat/Margin/BottomLeft/VBox/MPBar/LabelVal

@onready var boss_hud: Control = $HUDCombat/BossBarContainer
@onready var boss_hp_bar: ProgressBar = $HUDCombat/BossBarContainer/BossHPBar
@onready var label_boss_name: Label = $HUDCombat/BossBarContainer/LabelBossName
@onready var label_wave: Label = $HUDCombat/Margin/TopCenter/LabelWave

# Skill Hotbar UI
@onready var slot_basic: Button = $HUDCombat/Margin/BottomCenter/Hotbar/SlotBasic
@onready var slot_1: Button = $HUDCombat/Margin/BottomCenter/Hotbar/Slot1
@onready var slot_2: Button = $HUDCombat/Margin/BottomCenter/Hotbar/Slot2
@onready var slot_3: Button = $HUDCombat/Margin/BottomCenter/Hotbar/Slot3
@onready var slot_dash: Button = $HUDCombat/Margin/BottomCenter/Hotbar/SlotDash

@onready var overlay_victory: Control = $HUDCombat/OverlayVictory
@onready var label_victory_loot: Label = $HUDCombat/OverlayVictory/Panel/Margin/VBox/LabelLoot
@onready var btn_victory_return: Button = $HUDCombat/OverlayVictory/Panel/Margin/VBox/BtnReturn

@onready var overlay_defeat: Control = $HUDCombat/OverlayDefeat
@onready var btn_defeat_return: Button = $HUDCombat/OverlayDefeat/Panel/Margin/VBox/BtnReturn

func _ready() -> void:
	btn_victory_return.pressed.connect(_on_return_to_world)
	btn_defeat_return.pressed.connect(_on_return_to_world)
	overlay_victory.visible = false
	overlay_defeat.visible = false
	boss_hud.visible = false
	
	player_pos = ARENA_CENTER
	_update_player_bars()
	
	if SwordsmanScene:
		player_sprite = SwordsmanScene.instantiate()
		add_child(player_sprite)
		player_sprite.position = player_pos
		player_sprite.z_index = 5
		if player_sprite.sprite_frames.has_animation("idle_south"):
			player_sprite.play("idle_south")
	
	if GameSession and "target_combat_boss" in GameSession and GameSession.target_combat_boss != "":
		target_boss_id = GameSession.target_combat_boss
		
	if AudioService:
		AudioService.play_bgm("bgm_tribulation")
		
	if CoopWorldSync:
		CoopWorldSync.coop_boss_hp_changed.connect(_on_coop_boss_hp_changed)
		CoopWorldSync.coop_boss_defeated.connect(_on_coop_boss_defeated)
		
	_start_wave(1)

func _process(delta: float) -> void:
	if screen_shake_timer > 0.0:
		screen_shake_timer -= delta
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * screen_shake_intensity
	else:
		position = Vector2.ZERO

	if is_combat_over:
		return
	
	_handle_input(delta)
	_update_cooldowns(delta)
	_update_projectiles(delta)
	_update_vfx(delta)
	_update_floating_texts(delta)
	_update_enemies(delta)
	_check_wave_cleared()
	queue_redraw()

func _handle_input(delta: float) -> void:
	# 1. Định hướng ngắm theo chuột
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - player_pos).normalized()
	if dir_to_mouse != Vector2.ZERO:
		player_facing = dir_to_mouse
	
	# 2. Di chuyển người chơi (WASD / Mũi tên / Phím vật lý chống Unikey)
	var move_input = Vector2.ZERO
	move_input.x = Input.get_axis("move_left", "move_right")
	move_input.y = Input.get_axis("move_up", "move_down")
	if is_zero_approx(move_input.x):
		move_input.x = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(move_input.y):
		move_input.y = Input.get_axis("ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_input.y += 1.0
	
	if is_dashing:
		dash_timer -= delta
		player_pos += dash_dir * 520.0 * delta
		if dash_timer <= 0.0:
			is_dashing = false
			is_invulnerable = false
	else:
		if move_input != Vector2.ZERO:
			move_input = move_input.normalized()
			var spd = GameSession.speed
			player_pos += move_input * spd * delta
	
	# Giới hạn trong đấu trường
	var min_x = ARENA_CENTER.x - (ARENA_WIDTH / 2.0) + 40.0
	var max_x = ARENA_CENTER.x + (ARENA_WIDTH / 2.0) - 40.0
	var min_y = ARENA_CENTER.y - (ARENA_HEIGHT / 2.0) + 40.0
	var max_y = ARENA_CENTER.y + (ARENA_HEIGHT / 2.0) - 40.0
	player_pos.x = clamp(player_pos.x, min_x, max_x)
	player_pos.y = clamp(player_pos.y, min_y, max_y)
	
	# Đồng bộ vị trí và hoạt ảnh kiếm tu
	if player_sprite:
		player_sprite.position = player_pos
		_update_player_sprite_anim(move_input != Vector2.ZERO, is_dashing)
	
	# 3. Kỹ năng & Tấn công
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		_try_dash(move_input if move_input != Vector2.ZERO else player_facing)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_basic_attack()
	
	if Input.is_key_pressed(KEY_1) or Input.is_key_pressed(KEY_Q):
		_try_skill_1()
		
	if Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_E):
		_try_skill_2(mouse_pos)
		
	if Input.is_key_pressed(KEY_3) or Input.is_key_pressed(KEY_R):
		_try_skill_3(mouse_pos)

func _update_cooldowns(delta: float) -> void:
	if cd_basic > 0.0: cd_basic -= delta
	if cd_skill_1 > 0.0: cd_skill_1 -= delta
	if cd_skill_2 > 0.0: cd_skill_2 -= delta
	if cd_skill_3 > 0.0: cd_skill_3 -= delta
	if dash_cooldown > 0.0: dash_cooldown -= delta
	
	# Cập nhật hiển thị Hotbar
	slot_basic.text = "LMB: Trảm\n(Sẵn sàng)" if cd_basic <= 0.0 else "LMB: Trảm\n(%.1fs)" % cd_basic
	slot_1.text = "1/Q: Kiếm Khí\n(Sẵn sàng)" if cd_skill_1 <= 0.0 else "1/Q: Kiếm Khí\n(%.1fs)" % cd_skill_1
	slot_2.text = "2/E: Lôi Quang\n(Sẵn sàng)" if cd_skill_2 <= 0.0 else "2/E: Lôi Quang\n(%.1fs)" % cd_skill_2
	slot_3.text = "3/R: Mộc Trói\n(Sẵn sàng)" if cd_skill_3 <= 0.0 else "3/R: Mộc Trói\n(%.1fs)" % cd_skill_3
	slot_dash.text = "Space: Lướt\n(Sẵn sàng)" if dash_cooldown <= 0.0 else "Space: Lướt\n(%.1fs)" % dash_cooldown

func _try_dash(dir: Vector2) -> void:
	if dash_cooldown <= 0.0 and not is_dashing:
		is_dashing = true
		is_invulnerable = true
		dash_timer = 0.25
		dash_cooldown = 1.2
		dash_dir = dir.normalized()
		# Tạo vfx bóng mờ
		vfx_list.append({
			"type": "ring",
			"pos": player_pos,
			"radius": 24.0,
			"life": 0.3,
			"max_life": 0.3,
			"color": Color(0.4, 0.9, 0.7, 0.8)
		})

func _try_basic_attack() -> void:
	if cd_basic <= 0.0:
		cd_basic = 0.32
		var dmg = 15 + GameSession.attack
		var is_crit = (RNGService.randf() <= 0.2)
		if is_crit:
			dmg = int(dmg * 1.5)
		var slash_center = player_pos + (player_facing * 45.0)
		
		# Âm thanh & VFX chém kiếm
		if AudioService:
			AudioService.play_sfx("sfx_sword_slash")
		if VFXSwordSlashScene:
			var slash_fx = VFXSwordSlashScene.instantiate()
			slash_fx.position = slash_center
			slash_fx.slash_angle = player_facing.angle()
			add_child(slash_fx)
		
		# VFX đường kiếm
		vfx_list.append({
			"type": "slash",
			"pos": slash_center,
			"dir": player_facing,
			"radius": 60.0,
			"life": 0.18,
			"max_life": 0.18,
			"color": Color(0.9, 0.85, 0.7, 0.9)
		})
		
		# Quét trúng địch
		for enemy in enemies:
			if enemy.alive and enemy.pos.distance_to(slash_center) <= 70.0:
				_damage_enemy(enemy, dmg, "physical", is_crit)

func _try_skill_1() -> void: # Kiếm Khí Sơ Khởi (Kim hệ)
	if cd_skill_1 <= 0.0:
		cd_skill_1 = 2.5
		var dmg = 36 + (GameSession.attack * 1.5)
		var is_crit = (RNGService.randf() <= 0.25)
		if is_crit:
			dmg = int(dmg * 1.6)
		
		if AudioService:
			AudioService.play_sfx("sfx_sword_slash", 1.25)
		
		player_projectiles.append({
			"pos": player_pos + (player_facing * 30.0),
			"dir": player_facing,
			"speed": 460.0,
			"life": 1.2,
			"dmg": dmg,
			"is_crit": is_crit,
			"radius": 22.0,
			"piercing": true,
			"hit_targets": [],
			"color": Color(1.0, 0.85, 0.3, 1.0)
		})
		
		vfx_list.append({
			"type": "ring",
			"pos": player_pos,
			"radius": 35.0,
			"life": 0.25,
			"max_life": 0.25,
			"color": Color(1.0, 0.85, 0.3, 0.8)
		})

func _try_skill_2(target_pos: Vector2) -> void: # Lôi Quang Phá (Lôi hệ)
	if cd_skill_2 <= 0.0:
		cd_skill_2 = 4.0
		var dmg = 52 + (GameSession.attack * 2.0)
		var is_crit = (RNGService.randf() <= 0.3)
		if is_crit:
			dmg = int(dmg * 1.7)
		
		if AudioService:
			AudioService.play_sfx("sfx_lightning_strike")
		
		# Khởi tạo hiệu ứng hạt lôi kiếp giáng lâm thực tế
		if VFXLightningImpactScene:
			var lightning_fx = VFXLightningImpactScene.instantiate()
			lightning_fx.position = target_pos
			add_child(lightning_fx)
		
		# Sấm sét giáng xuống điểm chuột
		vfx_list.append({
			"type": "lightning",
			"pos": target_pos,
			"radius": 85.0,
			"life": 0.4,
			"max_life": 0.4,
			"color": Color(0.4, 0.8, 1.0, 1.0)
		})
		
		for enemy in enemies:
			if enemy.alive and enemy.pos.distance_to(target_pos) <= 90.0:
				_damage_enemy(enemy, dmg, "thunder", is_crit)
				enemy.stun_timer = 1.0 # Choáng 1s

func _try_skill_3(target_pos: Vector2) -> void: # Thanh Mộc Trói (Mộc hệ)
	if cd_skill_3 <= 0.0:
		cd_skill_3 = 5.0
		var dmg = 24 + GameSession.attack
		var is_crit = (RNGService.randf() <= 0.15)
		if is_crit:
			dmg = int(dmg * 1.5)
		
		vfx_list.append({
			"type": "roots",
			"pos": target_pos,
			"radius": 110.0,
			"life": 0.5,
			"max_life": 0.5,
			"color": Color(0.3, 0.9, 0.5, 0.9)
		})
		
		for enemy in enemies:
			if enemy.alive and enemy.pos.distance_to(target_pos) <= 110.0:
				_damage_enemy(enemy, dmg, "wood", is_crit)
				enemy.root_timer = 2.5 # Trói chân 2.5s

func _update_projectiles(delta: float) -> void:
	# Đạn người chơi
	var alive_p_proj: Array = []
	for p in player_projectiles:
		p.life -= delta
		p.pos += p.dir * p.speed * delta
		
		# Va chạm địch
		for enemy in enemies:
			if enemy.alive and enemy.pos.distance_to(p.pos) <= (p.radius + enemy.radius):
				var p_crit = p.get("is_crit", false)
				if p.get("piercing", false):
					if not enemy.id in p.hit_targets:
						p.hit_targets.append(enemy.id)
						_damage_enemy(enemy, p.dmg, "spirit", p_crit)
				else:
					_damage_enemy(enemy, p.dmg, "spirit", p_crit)
					p.life = 0.0
					break
		
		if p.life > 0.0:
			alive_p_proj.append(p)
	player_projectiles = alive_p_proj
	
	# Đạn quái
	var alive_e_proj: Array = []
	for ep in enemy_projectiles:
		ep.life -= delta
		ep.pos += ep.dir * ep.speed * delta
		
		# Va chạm người chơi
		if ep.pos.distance_to(player_pos) <= (ep.radius + 16.0):
			_damage_player(ep.dmg)
			ep.life = 0.0
		
		if ep.life > 0.0:
			alive_e_proj.append(ep)
	enemy_projectiles = alive_e_proj

func _update_vfx(delta: float) -> void:
	var alive_vfx: Array = []
	for v in vfx_list:
		v.life -= delta
		if v.life > 0.0:
			alive_vfx.append(v)
	vfx_list = alive_vfx

func _update_floating_texts(delta: float) -> void:
	var alive_texts: Array = []
	for ft in floating_texts:
		ft.life -= delta
		ft.pos.y -= ft.get("speed_y", 45.0) * delta
		if ft.life > 0.0:
			alive_texts.append(ft)
	floating_texts = alive_texts

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 14) -> void:
	floating_texts.append({
		"pos": pos + Vector2(randf_range(-14.0, 14.0), randf_range(-8.0, 4.0)),
		"text": text,
		"color": color,
		"size": font_size,
		"life": 0.75,
		"max_life": 0.75,
		"speed_y": 48.0
	})

func _damage_enemy(enemy: Dictionary, dmg: int, _type: String, is_crit: bool = false) -> void:
	if enemy.get("is_boss", false) and SessionAuthority and SessionAuthority.is_coop_session():
		# Co-op: Gửi đòn đánh qua Host authoritative
		CoopWorldSync.request_attack_boss("basic", player_facing)
		return
		
	enemy.hp -= dmg
	enemy.hit_flash = 0.15
	_trigger_screen_shake(0.18 if is_crit else 0.12, 5.0 if is_crit else 3.5)
	
	# Sát thương bay (Floating Combat Text) theo cờ bạo kích thực tế
	var text_col = Color(1.0, 0.88, 0.25, 1.0) if is_crit else Color(1.0, 1.0, 1.0, 1.0)
	var prefix = "BẠO KÍCH! -" if is_crit else "-"
	spawn_floating_text(enemy.pos, "%s%d" % [prefix, dmg], text_col, 16 if is_crit else 13)
	
	if AudioService:
		AudioService.play_sfx("sfx_sword_slash", randf_range(1.2, 1.4) if is_crit else randf_range(0.95, 1.2), 1.0 if is_crit else -2.0)

	if enemy.hp <= 0:
		enemy.alive = false
		enemy.hp = 0
		# Vành nổ diệt địch
		vfx_list.append({
			"type": "ring",
			"pos": enemy.pos,
			"radius": enemy.radius * 1.8,
			"life": 0.35,
			"max_life": 0.35,
			"color": Color(1.0, 0.75, 0.2, 0.85) if enemy.get("is_boss", false) else Color(0.85, 0.3, 0.3, 0.7)
		})
		if enemy.get("is_boss", false):
			_on_boss_killed()
	
	# Cập nhật thanh máu boss nếu là boss
	if enemy.get("is_boss", false):
		boss_hp_bar.value = enemy.hp

func _on_coop_boss_hp_changed(curr_hp: int, max_h: int, dmg: int, is_crit: bool) -> void:
	if not boss_ref.is_empty():
		boss_ref["hp"] = curr_hp
		boss_ref["max_hp"] = max_h
		boss_ref["hit_flash"] = 0.15
		boss_hp_bar.max_value = max_h
		boss_hp_bar.value = curr_hp
		_trigger_screen_shake(0.18 if is_crit else 0.12, 5.0 if is_crit else 3.5)
		var text_col = Color(1.0, 0.88, 0.25, 1.0) if is_crit else Color(1.0, 1.0, 1.0, 1.0)
		var prefix = "BẠO KÍCH! -" if is_crit else "-"
		spawn_floating_text(boss_ref.get("pos", ARENA_CENTER), "%s%d" % [prefix, dmg], text_col, 16 if is_crit else 13)

func _on_coop_boss_defeated(boss_id: String) -> void:
	if not boss_ref.is_empty():
		boss_ref["alive"] = false
		boss_ref["hp"] = 0
		_on_boss_killed()

func _damage_player(dmg: int) -> void:
	if is_invulnerable or is_combat_over:
		return
	
	# Tính giảm thương từ phòng ngự
	var real_dmg = int(dmg * (100.0 / (100.0 + max(GameSession.defense, 0))))
	real_dmg = max(real_dmg, 4)
	GameSession.current_hp = max(0, GameSession.current_hp - real_dmg)
	_update_player_bars()
	_trigger_screen_shake(0.22, 7.5)
	
	# Sát thương người chơi nhận vào (Màu đỏ cảnh báo)
	spawn_floating_text(player_pos, "-%d" % real_dmg, Color(1.0, 0.25, 0.25, 1.0), 16)
	
	# Rung đỏ màn hình hoặc vfx
	vfx_list.append({
		"type": "ring",
		"pos": player_pos,
		"radius": 28.0,
		"life": 0.2,
		"max_life": 0.2,
		"color": Color(1.0, 0.2, 0.2, 0.7)
	})
	
	if GameSession.current_hp <= 0:
		_on_player_died()

func _update_player_bars() -> void:
	hp_bar_player.max_value = GameSession.max_hp
	hp_bar_player.value = GameSession.current_hp
	label_hp_player.text = "%d / %d" % [GameSession.current_hp, GameSession.max_hp]
	
	mp_bar_player.max_value = max(GameSession.max_mp, 1)
	mp_bar_player.value = GameSession.current_mp
	label_mp_player.text = "%d / %d" % [GameSession.current_mp, GameSession.max_mp]

# --- QUẢN LÝ QUÁI VẬT & WAVE ---
func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	enemies.clear()
	
	if wave_num == 1:
		label_wave.text = "ĐỢT 1/3: LINH HỒ DÒ ĐƯỜNG"
		_spawn_enemy("enemy_linh_ho", Vector2(ARENA_CENTER.x - 300, ARENA_CENTER.y - 180))
		_spawn_enemy("enemy_linh_ho", Vector2(ARENA_CENTER.x + 300, ARENA_CENTER.y + 180))
		
	elif wave_num == 2:
		label_wave.text = "ĐỢT 2/3: CỔ THÚ & ĐỘC XÀ"
		_spawn_enemy("enemy_bach_xuyen_thu", Vector2(ARENA_CENTER.x - 350, ARENA_CENTER.y))
		_spawn_enemy("enemy_bach_xuyen_thu", Vector2(ARENA_CENTER.x + 350, ARENA_CENTER.y))
		_spawn_enemy("enemy_hac_linh_xa", Vector2(ARENA_CENTER.x, ARENA_CENTER.y - 240))
		
	elif wave_num == 3:
		var b_def = ContentRegistry.get_enemy(target_boss_id)
		var b_name = b_def.get("name", "Ma Thú")
		label_wave.text = "ĐỢT 3/3: ĐẠI CHIẾN BOSS — " + b_name.to_upper()
		_spawn_boss()

func _spawn_enemy(type_id: String, pos: Vector2) -> void:
	var def = ContentRegistry.get_enemy(type_id)
	var e = {
		"id": "e_%d" % RNGService.randi_range(1000, 9999),
		"type": type_id,
		"name": def.get("name", "Yêu Thú"),
		"pos": pos,
		"max_hp": def.get("hp", def.get("max_hp", 60)),
		"hp": def.get("hp", def.get("max_hp", 60)),
		"speed": def.get("speed", def.get("move_speed", 120.0)),
		"atk": def.get("atk", def.get("attack", 10)),
		"radius": 22.0,
		"color": Color(0.9, 0.45, 0.3) if type_id.contains("linh_ho") else (Color(0.8, 0.8, 0.9) if type_id.contains("bach_xuyen") else Color(0.4, 0.8, 0.4)),
		"alive": true,
		"atk_cooldown": 1.5,
		"hit_flash": 0.0,
		"stun_timer": 0.0,
		"root_timer": 0.0,
		"is_boss": false,
		"telegraph": null
	}
	enemies.append(e)

func _spawn_boss() -> void:
	var def = ContentRegistry.get_enemy(target_boss_id)
	if def.is_empty():
		def = ContentRegistry.get_enemy("boss_xich_kiem_ma_thu")
		
	var hp_val = def.get("max_hp", def.get("hp", 450))
	var col_hex = def.get("color", "#e74c3c")
	var col_val = Color.from_string(col_hex, Color(0.85, 0.25, 0.2))
	
	var b = {
		"id": target_boss_id,
		"type": target_boss_id,
		"name": def.get("name", "Ma Thứu"),
		"zone_name": def.get("zone_name", "Vân Lĩnh"),
		"pos": Vector2(ARENA_CENTER.x, ARENA_CENTER.y - 200),
		"max_hp": hp_val,
		"hp": hp_val,
		"speed": def.get("speed", def.get("move_speed", 95.0)),
		"atk": def.get("atk", def.get("attack", 24)),
		"radius": 38.0,
		"color": col_val,
		"alive": true,
		"atk_cooldown": 2.0,
		"special_cd": 4.5,
		"hit_flash": 0.0,
		"stun_timer": 0.0,
		"root_timer": 0.0,
		"is_boss": true,
		"behavior": def.get("behavior", "boss_patterns"),
		"telegraph_type": def.get("telegraph_type", "circle"),
		"telegraph_delay": def.get("telegraph_delay", 1.2),
		"drops": def.get("drops", []),
		"telegraph": null
	}
	enemies.append(b)
	boss_ref = b
	
	# Hiện thanh Boss
	boss_hud.visible = true
	label_boss_name.text = "%s [%s]" % [b.name, b.zone_name]
	boss_hp_bar.max_value = b.max_hp
	boss_hp_bar.value = b.hp

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		if not enemy.alive:
			continue
		
		if enemy.hit_flash > 0.0:
			enemy.hit_flash -= delta
		if enemy.stun_timer > 0.0:
			enemy.stun_timer -= delta
			continue
		if enemy.root_timer > 0.0:
			enemy.root_timer -= delta
			# Đang bị trói thì không di chuyển nhưng vẫn có thể hành động nếu trong tầm
		
		var dist_to_player = enemy.pos.distance_to(player_pos)
		var dir_to_p = (player_pos - enemy.pos).normalized()
		
		# Di chuyển về phía người chơi nếu không bị trói
		if enemy.root_timer <= 0.0 and dist_to_player > (enemy.radius + 20.0):
			enemy.pos += dir_to_p * enemy.speed * delta
		
		# Boss AI đặc biệt với Telegraph
		if enemy.is_boss:
			_update_boss_ai(enemy, delta, dist_to_player, dir_to_p)
		else:
			_update_normal_enemy_ai(enemy, delta, dist_to_player, dir_to_p)

func _update_normal_enemy_ai(enemy: Dictionary, delta: float, dist_to_player: float, dir_to_p: Vector2) -> void:
	enemy.atk_cooldown -= delta
	
	if enemy.type == "enemy_hac_linh_xa":
		# Rắn phun độc tầm xa
		if enemy.atk_cooldown <= 0.0 and dist_to_player <= 320.0:
			enemy.atk_cooldown = 2.2
			enemy_projectiles.append({
				"pos": enemy.pos,
				"dir": dir_to_p,
				"speed": 260.0,
				"life": 1.8,
				"dmg": enemy.atk,
				"radius": 12.0,
				"color": Color(0.2, 0.9, 0.3, 1.0)
			})
	else:
		# Quái cào cận chiến
		if enemy.atk_cooldown <= 0.0 and dist_to_player <= (enemy.radius + 24.0):
			enemy.atk_cooldown = 1.4
			_damage_player(enemy.atk)

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var len_sq = ab.length_squared()
	if len_sq == 0.0:
		return p.distance_to(a)
	var t_val = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var proj = a + t_val * ab
	return p.distance_to(proj)

func _update_boss_ai(boss: Dictionary, delta: float, dist_to_player: float, dir_to_p: Vector2) -> void:
	# Cập nhật Telegraph đang thi triển
	if boss.telegraph != null:
		var t = boss.telegraph
		t.timer -= delta
		if t.timer <= 0.0:
			# Kích hoạt đòn đánh sau khi hết thời gian cảnh báo!
			if t.type == "circle":
				vfx_list.append({
					"type": "ring",
					"pos": t.pos,
					"radius": t.radius,
					"life": 0.35,
					"max_life": 0.35,
					"color": Color(1.0, 0.2, 0.2, 0.9)
				})
				if player_pos.distance_to(t.pos) <= t.radius:
					_damage_player(boss.atk + 8)
					if t.get("is_web", false):
						is_dashing = false
			elif t.type == "line":
				var old_pos = boss.pos
				boss.pos = t.target_pos
				vfx_list.append({
					"type": "slash",
					"pos": boss.pos,
					"dir": dir_to_p,
					"radius": 80.0,
					"life": 0.3,
					"max_life": 0.3,
					"color": Color(1.0, 0.8, 0.2, 0.95)
				})
				if _dist_to_segment(player_pos, old_pos, t.target_pos) <= t.get("width", 40.0):
					_damage_player(boss.atk + 12)
			elif t.type == "cone":
				vfx_list.append({
					"type": "ring",
					"pos": t.pos,
					"radius": t.radius * 0.8,
					"life": 0.4,
					"max_life": 0.4,
					"color": Color(0.2, 0.9, 0.3, 0.8)
				})
				var d = player_pos.distance_to(t.pos)
				var dp = (player_pos - t.pos).normalized()
				if d <= t.radius and dp.dot(t.dir) >= cos(t.angle / 2.0):
					_damage_player(boss.atk + 10)
			elif t.type == "cross":
				var c = t.target_pos
				var arm = t.radius
				vfx_list.append({
					"type": "lightning",
					"pos": c,
					"radius": 40.0,
					"life": 0.4,
					"max_life": 0.4,
					"color": Color(1.0, 0.85, 0.2, 0.9)
				})
				var hit_x = abs(player_pos.x - c.x) <= t.width and abs(player_pos.y - c.y) <= arm
				var hit_y = abs(player_pos.y - c.y) <= t.width and abs(player_pos.x - c.x) <= arm
				if hit_x or hit_y:
					_damage_player(boss.atk + 16)
			boss.telegraph = null
		return
	
	boss.atk_cooldown -= delta
	boss.special_cd -= delta
	
	# Khởi động Telegraph tùy theo Behavior của Boss
	var bh = boss.get("behavior", "boss_patterns")
	var t_delay = boss.get("telegraph_delay", 1.2)
	
	if bh == "cone_poison_spit":
		if boss.special_cd <= 0.0:
			boss.special_cd = 4.2
			boss.telegraph = {
				"type": "cone",
				"pos": boss.pos,
				"dir": dir_to_p,
				"radius": 240.0,
				"angle": PI * 0.45,
				"timer": t_delay,
				"max_timer": t_delay
			}
			return
	elif bh == "line_blood_dash":
		if boss.special_cd <= 0.0:
			boss.special_cd = 3.6
			boss.telegraph = {
				"type": "line",
				"pos": boss.pos,
				"target_pos": player_pos,
				"width": 50.0,
				"timer": t_delay,
				"max_timer": t_delay
			}
			return
	elif bh == "radial_web_blast":
		if boss.special_cd <= 0.0:
			boss.special_cd = 4.8
			boss.telegraph = {
				"type": "circle",
				"pos": boss.pos,
				"radius": 190.0,
				"is_web": true,
				"timer": t_delay,
				"max_timer": t_delay
			}
			return
	elif bh == "cross_sword_formation":
		if boss.special_cd <= 0.0:
			boss.special_cd = 5.0
			boss.telegraph = {
				"type": "cross",
				"pos": boss.pos,
				"target_pos": player_pos,
				"radius": 280.0,
				"width": 32.0,
				"timer": t_delay,
				"max_timer": t_delay
			}
			return
	else:
		# boss_patterns (Xích Kiếm Ma Thứu)
		if boss.special_cd <= 0.0:
			boss.special_cd = 5.5
			boss.telegraph = {
				"type": "circle",
				"pos": boss.pos,
				"radius": 150.0,
				"timer": t_delay,
				"max_timer": t_delay
			}
			return
		if boss.atk_cooldown <= 0.0 and dist_to_player > 120.0:
			boss.atk_cooldown = 3.5
			boss.telegraph = {
				"type": "line",
				"pos": boss.pos,
				"target_pos": player_pos,
				"width": 40.0,
				"timer": 1.0,
				"max_timer": 1.0
			}
			return
	
	# Đòn đánh cơ bản khi giáp lá cà
	if boss.atk_cooldown <= 0.0 and dist_to_player <= (boss.radius + 28.0):
		boss.atk_cooldown = 1.6
		_damage_player(boss.atk)

func _check_wave_cleared() -> void:
	if is_combat_over:
		return
		
	var any_alive = false
	for e in enemies:
		if e.alive:
			any_alive = true
			break
			
	if not any_alive:
		if current_wave < 3:
			_start_wave(current_wave + 1)

func _on_boss_killed() -> void:
	is_combat_over = true
	is_victory = true
	boss_hud.visible = false
	
	var def = ContentRegistry.get_enemy(target_boss_id)
	var drops = def.get("drops", [])
	var loot_lines: Array = []
	
	for drop in drops:
		var d_id = drop.get("item_id", "")
		var chance = drop.get("chance", 1.0)
		var min_qty = drop.get("min", 1)
		var max_qty = drop.get("max", 1)
		if RNGService.randf() <= chance:
			var qty = RNGService.randi_range(min_qty, max_qty)
			GameSession.add_item(d_id, qty)
			var it_def = ContentRegistry.get_item(d_id)
			var it_name = it_def.get("name", d_id)
			loot_lines.append("• %dx %s" % [qty, it_name])
			
	var exp_rew = def.get("exp_reward", 150)
	GameSession.add_cultivation(exp_rew)
	loot_lines.append("• +%d Điểm Tu Vi Tích Lũy" % exp_rew)
	
	if target_boss_id == "boss_xich_kiem_ma_thu" or target_boss_id == "boss_xich_kiem_ma_thuu":
		GameSession.advance_quest("q_first_spirit_vein", 3)
		loot_lines.append("\nNhiệm vụ: Hãy quay về Quán Trọ Thanh Trì báo tin cho Mạc Tư Viễn!")
		
	if not target_boss_id in GameSession.defeated_bosses:
		GameSession.defeated_bosses.append(target_boss_id)
		
	label_victory_loot.text = "Phần Thưởng Thu Được:\n" + "\n".join(loot_lines)
	overlay_victory.visible = true
	_trigger_screen_shake(0.45, 12.0)

func _on_player_died() -> void:
	is_combat_over = true
	is_victory = false
	# Hồi phục một phần máu theo luật Normal mode (không xóa save)
	GameSession.current_hp = int(GameSession.max_hp * 0.5)
	overlay_defeat.visible = true
	_trigger_screen_shake(0.3, 8.0)

func _on_return_to_world() -> void:
	if AudioService:
		AudioService.play_bgm("bgm_peaceful_town")
	var ret_path = "res://scenes/world/world_map.tscn"
	if GameSession and "return_scene_path" in GameSession and GameSession.return_scene_path != "":
		ret_path = GameSession.return_scene_path
	GameSession.target_combat_boss = ""
	get_tree().change_scene_to_file(ret_path)

func _trigger_screen_shake(duration: float, intensity: float) -> void:
	screen_shake_timer = duration
	screen_shake_intensity = intensity

func _update_player_sprite_anim(is_moving: bool, is_dash: bool) -> void:
	if not player_sprite:
		return
	if is_dash:
		if player_sprite.sprite_frames.has_animation("qinggong"):
			player_sprite.play("qinggong")
			return
	var dir_name = _get_dir_name(player_facing)
	var anim = ("walk_" if is_moving else "idle_") + dir_name
	if player_sprite.sprite_frames.has_animation(anim):
		if player_sprite.animation != anim:
			player_sprite.play(anim)

func _get_dir_name(dir: Vector2) -> String:
	var angle = dir.angle()
	var octant = roundi(8.0 * angle / TAU)
	match octant:
		0: return "east"
		1: return "south_east"
		2: return "south"
		3: return "south_west"
		4, -4: return "west"
		-3: return "north_west"
		-2: return "north"
		-1: return "north_east"
		_: return "south"

# --- VẼ ĐỒ HỌA INK-WASH VECTOR ---
func _draw() -> void:
	# 1. Vẽ ranh giới đấu trường (Ink arena border)
	var arena_rect = Rect2(ARENA_CENTER.x - (ARENA_WIDTH / 2.0), ARENA_CENTER.y - (ARENA_HEIGHT / 2.0), ARENA_WIDTH, ARENA_HEIGHT)
	draw_rect(arena_rect, Color(0.11, 0.13, 0.15, 1.0), true)
	draw_rect(arena_rect, Color(0.78, 0.65, 0.40, 0.8), false, 4.0)
	
	# Lưới bát quái mờ ở trung tâm
	draw_circle(ARENA_CENTER, 280.0, Color(0.14, 0.17, 0.2, 0.6))
	draw_arc(ARENA_CENTER, 280.0, 0, TAU, 48, Color(0.78, 0.65, 0.40, 0.35), 2.0)
	draw_arc(ARENA_CENTER, 140.0, 0, TAU, 32, Color(0.78, 0.65, 0.40, 0.25), 1.5)
	
	# 2. Vẽ Telegraph cảnh báo đỏ
	for enemy in enemies:
		if enemy.alive and enemy.get("telegraph", null) != null:
			var t = enemy.telegraph
			var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
			var tele_color = Color(1.0, 0.2, 0.2, 0.3 + 0.3 * pulse)
			
			if t.type == "circle":
				draw_circle(enemy.pos, t.radius, tele_color)
				draw_arc(enemy.pos, t.radius, 0, TAU, 36, Color(1.0, 0.3, 0.3, 0.9), 2.5)
			elif t.type == "line":
				var pts = PackedVector2Array([enemy.pos, t.target_pos])
				draw_polyline(pts, Color(1.0, 0.3, 0.3, 0.85), t.get("width", 18.0))
				draw_circle(t.target_pos, 22.0, tele_color)
			elif t.type == "cone":
				var angle_span = t.get("angle", PI * 0.45)
				var center_angle = t.get("dir", Vector2.RIGHT).angle()
				var start_ang = center_angle - (angle_span / 2.0)
				var end_ang = center_angle + (angle_span / 2.0)
				var poly_pts = PackedVector2Array([enemy.pos])
				var segments = 16
				for s in range(segments + 1):
					var a = start_ang + (end_ang - start_ang) * (float(s) / float(segments))
					poly_pts.append(enemy.pos + Vector2(cos(a), sin(a)) * t.radius)
				draw_polygon(poly_pts, [tele_color])
				draw_arc(enemy.pos, t.radius, start_ang, end_ang, 18, Color(0.2, 0.9, 0.4, 0.9), 2.5)
			elif t.type == "cross":
				var c_pos = t.get("target_pos", enemy.pos)
				var arm_len = t.get("radius", 240.0)
				var c_w = t.get("width", 24.0)
				var h_pts = PackedVector2Array([Vector2(c_pos.x - arm_len, c_pos.y), Vector2(c_pos.x + arm_len, c_pos.y)])
				var v_pts = PackedVector2Array([Vector2(c_pos.x, c_pos.y - arm_len), Vector2(c_pos.x, c_pos.y + arm_len)])
				draw_polyline(h_pts, Color(1.0, 0.7, 0.2, 0.8), c_w)
				draw_polyline(v_pts, Color(1.0, 0.7, 0.2, 0.8), c_w)
				draw_circle(c_pos, 16.0, tele_color)
	
	# 3. Vẽ Quái vật & Boss
	for enemy in enemies:
		if not enemy.alive:
			continue
		
		var e_col = Color.WHITE if enemy.hit_flash > 0.0 else enemy.color
		
		# Vòng bóng mờ
		draw_circle(enemy.pos + Vector2(0, 4), enemy.radius, Color(0, 0, 0, 0.35))
		# Thân yêu thú
		draw_circle(enemy.pos, enemy.radius, e_col)
		draw_arc(enemy.pos, enemy.radius, 0, TAU, 24, Color(0, 0, 0, 0.8), 2.0)
		
		# Thanh máu nhỏ trên đầu quái thường
		if not enemy.is_boss:
			var bar_w = 40.0
			var bar_h = 5.0
			var hp_ratio = float(enemy.hp) / float(enemy.max_hp)
			var bar_pos = enemy.pos + Vector2(-bar_w / 2.0, -enemy.radius - 12.0)
			draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0, 0, 0, 0.7), true)
			draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, bar_h)), Color(0.9, 0.3, 0.3, 0.9), true)
	
	# 4. Vẽ Đạn (Projectiles)
	for p in player_projectiles:
		draw_circle(p.pos, p.radius, p.color)
		draw_arc(p.pos, p.radius, 0, TAU, 16, Color(1, 1, 1, 0.9), 2.0)
		
	for ep in enemy_projectiles:
		draw_circle(ep.pos, ep.radius, ep.color)
	
	# 5. Vẽ Hiệu ứng VFX
	for v in vfx_list:
		var alpha = v.life / v.max_life
		var c = Color(v.color.r, v.color.g, v.color.b, v.color.a * alpha)
		if v.type == "ring":
			draw_arc(v.pos, v.radius * (1.0 + (1.0 - alpha)), 0, TAU, 32, c, 3.0)
		elif v.type == "slash":
			draw_arc(v.pos, v.radius, 0, PI * 0.7, 16, c, 5.0)
		elif v.type == "lightning":
			draw_circle(v.pos, v.radius, Color(c.r, c.g, c.b, 0.35 * alpha))
			draw_arc(v.pos, v.radius, 0, TAU, 24, c, 3.0)
		elif v.type == "roots":
			draw_circle(v.pos, v.radius, Color(0.2, 0.8, 0.4, 0.25 * alpha))
			draw_arc(v.pos, v.radius, 0, TAU, 28, c, 2.5)
	
	# 6. Vẽ Bóng & Chỉ Hướng Kiếm Ý Người Chơi
	draw_circle(player_pos + Vector2(0, 6), 18.0, Color(0, 0, 0, 0.4))
	
	# Nếu không có sprite, vẽ vòng tròn dự phòng
	if not player_sprite:
		var p_color = Color(0.45, 0.61, 0.54, 1.0)
		if is_invulnerable:
			p_color = Color(0.6, 0.9, 0.8, 0.6)
		draw_circle(player_pos, 16.0, p_color)
		draw_arc(player_pos, 16.0, 0, TAU, 32, Color(0.78, 0.65, 0.40, 1.0), 2.5)
		draw_circle(player_pos, 7.0, Color(0.89, 0.85, 0.76, 1.0))
	
	# Mũi nhọn Kiếm Ý định hướng mục tiêu
	var tip = player_pos + (player_facing * 30.0)
	draw_line(player_pos, tip, Color(0.82, 0.72, 0.45, 0.85), 2.2)
	draw_circle(tip, 3.5, Color(1.0, 0.85, 0.3, 0.95))

	# 7. Vẽ Chỉ Số Sát Thương Bay (Floating Combat Damage Text)
	for ft in floating_texts:
		var alpha = ft.life / ft.max_life
		var col = Color(ft.color.r, ft.color.g, ft.color.b, ft.color.a * alpha)
		var shadow_col = Color(0, 0, 0, 0.75 * alpha)
		var f_size = ft.get("size", 14)
		# Bóng đổ để hiển thị rõ nét trên mọi phông nền
		draw_string(ThemeDB.fallback_font, ft.pos + Vector2(1, 1), ft.text, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, shadow_col)
		draw_string(ThemeDB.fallback_font, ft.pos, ft.text, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, col)
