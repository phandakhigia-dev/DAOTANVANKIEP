from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/scenes/towns/npc_character.gd")
content = path.read_text(encoding="utf-8")

old_code = """func _load_npc_data() -> void:
	if npc_id == "":
		return
	var def: Dictionary = {}
	var cr = get_node_or_null("/root/ContentRegistry")
	if cr and cr.has_method("get_npc"):
		def = cr.get_npc(npc_id)
	if not def.is_empty():
		npc_data = def
	elif is_procedural:
		var gs = get_node_or_null("/root/GameSession")
		var seed_val: int = gs.world_seed if (gs and "world_seed" in gs) else 1337
		npc_data = LifeGenerator.generate_character(seed_val, npc_id.hash())"""

new_code = """func _load_npc_data() -> void:
	if npc_id == "":
		return
	var def: Dictionary = {}
	var cr = null
	if Engine.get_main_loop() and Engine.get_main_loop().root and Engine.get_main_loop().root.has_node("ContentRegistry"):
		cr = Engine.get_main_loop().root.get_node("ContentRegistry")
	elif is_inside_tree():
		cr = get_node_or_null("/root/ContentRegistry")
	if cr and cr.has_method("get_npc"):
		def = cr.get_npc(npc_id)
	if not def.is_empty():
		npc_data = def
	elif is_procedural:
		var seed_val: int = 1337
		if Engine.get_main_loop() and Engine.get_main_loop().root and Engine.get_main_loop().root.has_node("GameSession"):
			seed_val = Engine.get_main_loop().root.get_node("GameSession").world_seed
		elif is_inside_tree():
			var gs = get_node_or_null("/root/GameSession")
			if gs and "world_seed" in gs:
				seed_val = gs.world_seed
		npc_data = LifeGenerator.generate_character(seed_val, npc_id.hash())"""

content_norm = content.replace("\r\n", "\n")
old_norm = old_code.replace("\r\n", "\n")
new_norm = new_code.replace("\r\n", "\n")

assert old_norm in content_norm, "Target not found in npc_character.gd!"
content_norm = content_norm.replace(old_norm, new_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully updated _load_npc_data in npc_character.gd!")
