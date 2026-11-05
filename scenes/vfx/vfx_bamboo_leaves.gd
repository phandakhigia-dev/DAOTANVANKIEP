extends Node2D

## VFXBambooLeaves — Lá Trúc Rơi & Không Khí Bí Cảnh (Phase 4: Environmental Ambience VFX)
## Các phiến lá trúc màu lục biếc phiêu dạt nhẹ nhàng theo làn gió mộc linh

@onready var leaf_particles: CPUParticles2D = $LeafParticles
@onready var pollen_particles: CPUParticles2D = $PollenParticles

func _ready() -> void:
	if leaf_particles:
		leaf_particles.emitting = true
	if pollen_particles:
		pollen_particles.emitting = true
