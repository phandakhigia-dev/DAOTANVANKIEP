from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scenes/ui/dialogue_modal.gd")
content = path.read_text(encoding="utf-8")

old_code = """func _rebuild_action_buttons() -> void:
	# Xóa nút cũ
	for child in actions_container.get_children():"""

new_code = """func _rebuild_action_buttons() -> void:
	if not actions_container:
		actions_container = (
			get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			if has_node("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			else get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ActionsContainer")
		)
	if not actions_container:
		return
	# Xóa nút cũ
	for child in actions_container.get_children():"""

content_norm = content.replace("\r\n", "\n")
old_norm = old_code.replace("\r\n", "\n")
new_norm = new_code.replace("\r\n", "\n")

assert old_norm in content_norm, "Target not found in dialogue_modal.gd!"
content_norm = content_norm.replace(old_norm, new_norm, 1)

old_custom = """func _rebuild_custom_npc_actions() -> void:
	for child in actions_container.get_children():"""

new_custom = """func _rebuild_custom_npc_actions() -> void:
	if not actions_container:
		actions_container = (
			get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			if has_node("PanelContainer/MarginContainer/VBoxContainer/ScrollActions/ActionsContainer")
			else get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ActionsContainer")
		)
	if not actions_container:
		return
	for child in actions_container.get_children():"""

old_custom_norm = old_custom.replace("\r\n", "\n")
new_custom_norm = new_custom.replace("\r\n", "\n")

assert old_custom_norm in content_norm, "Target custom not found in dialogue_modal.gd!"
content_norm = content_norm.replace(old_custom_norm, new_custom_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully safeguarded actions_container in dialogue_modal.gd!")
