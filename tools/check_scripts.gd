extends SceneTree

func _init() -> void:
	var scripts = [
		"res://scenes/ui/dialogue_modal.gd",
		"res://scenes/towns/npc_character.gd",
		"res://scripts/world/chunk_streamer.gd",
		"res://scenes/world/province_world.gd",
		"res://tests/unit/test_openworld_interactions_and_mobs.gd"
	]
	for s_path in scripts:
		var res = load(s_path)
		if res == null:
			print("FAIL LOAD: ", s_path)
		elif not res.can_instantiate() and not res.has_method("run_all_tests"):
			print("LOADED BUT INVALID: ", s_path)
		else:
			print("OK: ", s_path)
	quit()
