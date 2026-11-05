from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scenes/ui/dialogue_modal.gd")
content = path.read_text(encoding="utf-8")

old_code = """func open_for_npc(npc_id: String) -> void:"""

new_code = """func open_dialogue(param: Variant = null) -> void:
	if param is String:
		open_for_npc(param)
	elif param is Dictionary:
		var nid = param.get("id", "")
		if nid != "" and ContentRegistry and ContentRegistry.get_npc(nid).size() > 0:
			open_for_npc(nid)
		else:
			open_for_custom_npc(param)
	else:
		visible = true
		_refresh_display()

func open_for_npc(npc_id: String) -> void:"""

content_norm = content.replace("\r\n", "\n")
old_norm = old_code.replace("\r\n", "\n")
new_norm = new_code.replace("\r\n", "\n")

assert old_norm in content_norm, "Target not found in dialogue_modal.gd!"
content_norm = content_norm.replace(old_norm, new_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully added open_dialogue to dialogue_modal.gd!")
