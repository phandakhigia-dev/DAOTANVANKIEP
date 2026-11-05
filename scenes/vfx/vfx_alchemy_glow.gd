extends Node2D

## VFXAlchemyGlow — Kim Đan Xuất Lô & Đan Khí Bốc Cao (Phase 4: Alchemy Cauldron VFX)
## Đan khí màu tím tía bốc lên cùng hào quang vàng óng khi luyện đan thành công

@onready var smoke: CPUParticles2D = $CauldronSmoke
@onready var golden_sparks: CPUParticles2D = $GoldenSparks

func _ready() -> void:
	if smoke:
		smoke.emitting = true
	if golden_sparks:
		golden_sparks.emitting = true

func trigger_success_burst() -> void:
	if golden_sparks:
		golden_sparks.amount = 45
		golden_sparks.initial_velocity_min = 120.0
		golden_sparks.initial_velocity_max = 200.0
		golden_sparks.restart()
