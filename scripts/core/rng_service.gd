extends Node

## RNGService — Quản lý phát sinh số ngẫu nhiên có kiểm soát (Deterministic Seed)
## Đảm bảo world generation và simulation tái lặp chính xác theo cùng một seed.

var current_seed: int = 1337
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	init_with_seed(current_seed)

func init_with_seed(seed_val: int) -> void:
	current_seed = seed_val
	_rng.seed = seed_val

func get_seed() -> int:
	return current_seed

func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

func randi() -> int:
	return _rng.randi()

func randf() -> float:
	return _rng.randf()

func generate_random_seed() -> int:
	var sys_rng = RandomNumberGenerator.new()
	sys_rng.randomize()
	return sys_rng.randi_range(100000, 999999)
