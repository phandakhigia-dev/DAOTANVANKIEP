extends Node2D

## VFXCultivationAura — Hào Quang Linh Khí & Đột Phá (Phase 4: Cultivation Aura VFX)
## Các luồng linh khí hoàng kim & bích ngọc xoay quanh đan điền, vươn lên đỉnh đầu

@onready var aura_particles: CPUParticles2D = $AuraParticles
@onready var spark_particles: CPUParticles2D = $SparkParticles

var is_breakthrough: bool = false
var aura_duration: float = 3.0
var current_time: float = 0.0

func _ready() -> void:
	if aura_particles:
		aura_particles.emitting = true
	if spark_particles:
		spark_particles.emitting = true
	queue_redraw()

func setup_aura(breakthrough: bool = false, duration: float = 3.0) -> void:
	is_breakthrough = breakthrough
	aura_duration = duration
	if aura_particles:
		if is_breakthrough:
			aura_particles.color = Color(1.0, 0.85, 0.3, 0.9) # Hoàng Kim Đột Phá
			aura_particles.amount = 40
			aura_particles.initial_velocity_min = 60.0
			aura_particles.initial_velocity_max = 120.0
		else:
			aura_particles.color = Color(0.4, 0.9, 0.6, 0.8) # Bích Ngọc Tĩnh Tọa
			aura_particles.amount = 25

func _process(delta: float) -> void:
	current_time += delta
	queue_redraw()
	if current_time >= aura_duration:
		queue_free()

func _draw() -> void:
	# Vòng bát quái linh khí dưới chân nhân vật
	var progress = current_time / aura_duration
	var pulse = (sin(current_time * 6.0) * 0.5 + 0.5)
	var alpha = (1.0 - progress) * (0.4 + pulse * 0.3)
	
	var base_color = Color(1.0, 0.82, 0.2, alpha) if is_breakthrough else Color(0.4, 0.9, 0.6, alpha)
	var ring_radius = 28.0 + pulse * 6.0
	
	# Vòng tròn linh trận
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, base_color, 2.0)
	draw_arc(Vector2.ZERO, ring_radius * 0.65, 0, TAU, 24, Color(base_color.r, base_color.g, base_color.b, alpha * 0.7), 1.5)
	
	# 4 đốm sáng tứ tượng xoay quanh
	var rot_speed = current_time * 3.0
	for i in range(4):
		var ang = rot_speed + i * (PI * 0.5)
		var orb_pos = Vector2(cos(ang), sin(ang)) * ring_radius
		draw_circle(orb_pos, 3.5, Color(1.0, 1.0, 1.0, alpha * 0.9))
