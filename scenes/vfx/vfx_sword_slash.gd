extends Node2D

## VFXSwordSlash — Hiệu ứng Kiếm Khí Xé Gió (Phase 4: Sword Slash VFX)
## Vệt chém hình vòng cung màu lam kim + tia lửa kiếm ý (CPUParticles2D)

@onready var particles: CPUParticles2D = $Sparks
var slash_angle: float = 0.0
var slash_color: Color = Color(0.4, 0.85, 1.0, 1.0)
var lifetime: float = 0.35
var current_time: float = 0.0

func _ready() -> void:
	if particles:
		particles.emitting = true
	queue_redraw()

func _process(delta: float) -> void:
	current_time += delta
	queue_redraw()
	if current_time >= lifetime:
		queue_free()

func _draw() -> void:
	var progress = current_time / lifetime
	var alpha = (1.0 - progress) * 0.95
	var outer_color = Color(slash_color.r, slash_color.g, slash_color.b, alpha)
	var core_color = Color(1.0, 1.0, 1.0, alpha)
	
	# Vẽ vòng cung kiếm khí
	var center = Vector2.ZERO
	var radius = 48.0 + progress * 24.0
	var start_angle = -PI * 0.45
	var end_angle = PI * 0.45
	var segments = 16
	
	var points_outer: Array[Vector2] = []
	var points_inner: Array[Vector2] = []
	
	for i in range(segments + 1):
		var a = lerpf(start_angle, end_angle, float(i) / float(segments))
		var dir = Vector2(cos(a), sin(a)).rotated(slash_angle)
		var thickness = sin(float(i) / float(segments) * PI) * (8.0 * (1.0 - progress * 0.5))
		points_outer.append(center + dir * (radius + thickness))
		points_inner.append(center + dir * (radius - thickness))
		
	# Vẽ thân kiếm khí rực sáng
	for i in range(segments):
		var poly = PackedVector2Array([
			points_outer[i], points_outer[i+1],
			points_inner[i+1], points_inner[i]
		])
		draw_colored_polygon(poly, outer_color)
		
	# Lõi sáng trắng chính giữa vòng cung
	for i in range(segments):
		draw_line(points_outer[i] * 0.5 + points_inner[i] * 0.5,
				  points_outer[i+1] * 0.5 + points_inner[i+1] * 0.5,
				  core_color, 2.5 * (1.0 - progress))
