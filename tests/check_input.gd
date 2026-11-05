extends SceneTree

func _init() -> void:
	print("--- ACTIONS IN INPUTMAP ---")
	for action in InputMap.get_actions():
		if action.begins_with("move_") or action.begins_with("ui_"):
			var events = InputMap.action_get_events(action)
			print(action, ": ", events.size(), " events")
			for e in events:
				if e is InputEventKey:
					print("  Key: keycode=", e.keycode, " physical_keycode=", e.physical_keycode, " key_label=", e.key_label)
	quit()
