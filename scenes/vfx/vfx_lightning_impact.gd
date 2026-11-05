extends Node2D

## VFXLightningImpact — Lôi Bạo Điểm Giáng (Phase 4: Lightning Impact VFX)
## Vòng sóng xung kích lôi điện + tia sét nổ tung tại vị trí sét đánh

@onready var sparks: CPUParticles2D = $Sparks
@onready var shockwave: CPUParticles2D = $Shockwave

var lifetime: float = 0.5
var current_time: float = 0.0

func _ready() -> void:
	if sparks:
		sparks.emitting = true
	if shockwave:
		shockwave.emitting = true
	queue_redraw()

func _process(delta: float) -> void:
	current_time += delta
	queue_redraw()
	if current_time >= lifetime:
		queue_free()

func _draw() -> void:
	var progress = current_time / lifetime
	var alpha = (1.0 - progress) * 0.9
	
	# Vòng sóng xung kích điện trường mở rộng
	var radius = progress * 64.0
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.6, 0.8, 1.0, alpha), 3.0 * (1.0 - progress))
	draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU, 24, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0 * (1.0 - progress))
	
	# Lõi ánh sáng lôi điện
	if progress < 0.25:
		var flash_alpha = (1.0 - progress / 0.25)
		draw_circle(Vector2.ZERO, 20.0 * (1.0 - progress), Color(1.0, 1.0, 1.0, flash_alpha * 0.9))
