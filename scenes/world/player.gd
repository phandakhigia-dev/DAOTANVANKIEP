extends CharacterBody2D

## Player — Điều khiển di chuyển nhân vật trong bản đồ thế giới 2D (Oblique 2.5D)
## Hỗ trợ đa lớp đầu vào: WASD (Chống Unikey), Mũi tên, Phím vật lý, Chuột (Click-to-Move)

@export var move_speed: float = 360.0
@export var sprint_speed: float = 520.0

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $swordsman if has_node("swordsman") else null

var facing_dir: Vector2 = Vector2.DOWN
var target_pos: Vector2 = Vector2.ZERO
var is_moving_to_target: bool = false
var _target_pulse: float = 0.0

# Khinh công lướt gió (Qinggong Dash)
const QINGGONG_SPEED: float = 780.0 # sprint_speed 520 * 1.5 = 780 px/s chuẩn xác
var is_qinggong: bool = false
var qinggong_timer: float = 0.0
var qinggong_cd: float = 0.0
var qinggong_dir: Vector2 = Vector2.DOWN
var _space_was_down: bool = false

@export var spawn_override: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Khởi tạo vị trí từ session hoặc spawn override
	if spawn_override != Vector2.ZERO:
		global_position = spawn_override
	else:
		global_position = GameSession.world_position
	target_pos = global_position
	_update_animation(false)
	queue_redraw()

func teleport_to(pos: Vector2) -> void:
	global_position = pos
	target_pos = pos
	is_moving_to_target = false
	velocity = Vector2.ZERO
	if camera:
		camera.reset_smoothing()

func _unhandled_input(event: InputEvent) -> void:
	# Nhấp chuột trái hoặc chuột phải trên bản đồ để di chuyển tới vị trí đó
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			target_pos = get_global_mouse_position()
			is_moving_to_target = true
			_target_pulse = 1.0
			queue_redraw()

func trigger_qinggong(dir: Vector2 = Vector2.ZERO) -> void:
	if qinggong_cd <= 0.0:
		is_qinggong = true
		qinggong_timer = 0.22
		qinggong_cd = 0.9
		var raw_dir = dir if dir != Vector2.ZERO else (velocity.normalized() if velocity != Vector2.ZERO else facing_dir)
		qinggong_dir = raw_dir.normalized() if raw_dir != Vector2.ZERO else Vector2.DOWN
		velocity = qinggong_dir * QINGGONG_SPEED
		if AudioService:
			AudioService.play_sfx("sfx_sword_slash", 1.6)

func _physics_process(delta: float) -> void:
	var input_vec = Vector2.ZERO
	
	# 1. Trục InputMap (WASD hoặc Phím mũi tên đã cấu hình)
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	
	# 2. Dự phòng trực tiếp trục UI (Mũi tên mặc định của Godot)
	if is_zero_approx(input_vec.x):
		input_vec.x = Input.get_axis("ui_left", "ui_right")
	if is_zero_approx(input_vec.y):
		input_vec.y = Input.get_axis("ui_up", "ui_down")
	
	# 3. Quét phím vật lý thô (Physical Scancodes) — Chỉ bù đắp nếu chưa nhận được trục
	var raw_phys_x = 0.0
	var raw_phys_y = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		raw_phys_x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		raw_phys_x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		raw_phys_y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		raw_phys_y += 1.0
		
	if is_zero_approx(input_vec.x):
		input_vec.x = raw_phys_x
	if is_zero_approx(input_vec.y):
		input_vec.y = raw_phys_y
		
	input_vec.x = clampf(input_vec.x, -1.0, 1.0)
	input_vec.y = clampf(input_vec.y, -1.0, 1.0)

	var cur_speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SHIFT):
		cur_speed = sprint_speed

	var is_moving = false

	if qinggong_cd > 0.0:
		qinggong_cd -= delta

	# 4. Kích hoạt Khinh Công lướt gió (Phím Space / Action qinggong)
	if is_qinggong:
		qinggong_timer -= delta
		velocity = qinggong_dir * QINGGONG_SPEED
		move_and_slide()
		is_moving = true
		if qinggong_timer <= 0.0:
			is_qinggong = false
	else:
		var space_is_down = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE) or (InputMap.has_action("qinggong") and Input.is_action_pressed("qinggong"))
		var space_just_pressed = (InputMap.has_action("qinggong") and Input.is_action_just_pressed("qinggong")) or (space_is_down and not _space_was_down)
		_space_was_down = space_is_down
		
		if space_just_pressed and qinggong_cd <= 0.0:
			is_qinggong = true
			qinggong_timer = 0.22
			qinggong_cd = 0.9
			# Chuẩn hóa vector hướng lướt để tránh tăng tốc bất thường khi đi chéo
			var raw_dir = input_vec if input_vec != Vector2.ZERO else facing_dir
			qinggong_dir = raw_dir.normalized() if raw_dir != Vector2.ZERO else Vector2.DOWN
			if AudioService:
				AudioService.play_sfx("sfx_sword_slash", 1.6)

		# Khi có phím bấm từ bàn phím -> Ưu tiên phím, hủy click-to-move
		if input_vec != Vector2.ZERO:
			is_moving_to_target = false
			input_vec = input_vec.normalized()
			facing_dir = input_vec
			velocity = input_vec * cur_speed
			move_and_slide()
			is_moving = true
		elif is_moving_to_target:
			# Di chuyển theo điểm nhấp chuột
			var dist = global_position.distance_to(target_pos)
			if dist > 8.0:
				var move_dir = (target_pos - global_position).normalized()
				facing_dir = move_dir
				velocity = move_dir * cur_speed
				move_and_slide()
				is_moving = true
			else:
				is_moving_to_target = false
				velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO

	# Cập nhật vị trí lưu vào GameSession
	if is_moving:
		GameSession.world_position = global_position
		if EventBus:
			EventBus.player_moved.emit(global_position)
		_update_animation(true)
	else:
		_update_animation(false)

	if is_moving_to_target or _target_pulse > 0.0:
		if _target_pulse > 0.0:
			_target_pulse = maxf(0.0, _target_pulse - delta * 2.0)
		queue_redraw()

func _update_animation(is_moving: bool) -> void:
	if not sprite:
		return
	if is_qinggong:
		if sprite.sprite_frames.has_animation("qinggong"):
			if sprite.animation != "qinggong":
				sprite.play("qinggong")
			return
	var dir_name = _get_dir_name(facing_dir)
	var anim_name = ("walk_" if is_moving else "idle_") + dir_name
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)

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

func _draw() -> void:
	# 1. Bóng đổ mặt đất tinh tế cho nhân vật tại chân
	draw_ellipse_shadow(Vector2(0, 0), 14.0, 6.0, Color(0, 0, 0, 0.35))
	
	# 2. Điểm đích nhấp chuột (Vòng tròn chỉ định Click-To-Move)
	if is_moving_to_target or _target_pulse > 0.0:
		var rel_target = to_local(target_pos)
		var ring_alpha = 0.6 * (_target_pulse if _target_pulse > 0.0 else 0.5)
		draw_circle(rel_target, 8.0, Color(0.45, 0.8, 0.65, ring_alpha * 0.4))
		draw_arc(rel_target, 12.0, 0, TAU, 24, Color(0.78, 0.65, 0.40, ring_alpha), 2.0)

func draw_ellipse_shadow(pos: Vector2, rx: float, ry: float, col: Color) -> void:
	var points = PackedVector2Array()
	var n_segs = 16
	for i in range(n_segs):
		var theta = i * TAU / n_segs
		points.append(pos + Vector2(cos(theta) * rx, sin(theta) * ry))
	draw_colored_polygon(points, col)
