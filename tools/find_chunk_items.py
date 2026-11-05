import subprocess
import os
from pathlib import Path

ROOT = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT")
os.chdir(ROOT)

test_script = """extends Node

func _ready():
	var scn = load("res://scenes/world/province_world.tscn")
	var world = scn.instantiate()
	add_child(world)
	
	var cs = world.get_node("ChunkStreamer")
	var c32 = cs.get_node_or_null("Chunk_32_32")
	if c32:
		var ent = c32.get_node_or_null("Entities")
		if ent:
			print("=== ALL CHILDREN OF Entities ===")
			for ch in ent.get_children():
				print("Entity: %s (%s), pos: %s" % [ch.name, ch.get_class(), ch.position])
	get_tree().quit(0)
"""

(ROOT / "tests/unit/test_chunk_children.gd").write_text(test_script, encoding="utf-8")

cmd = [r"G:\Game tự làm\tools\godot\godot.cmd", "--headless", "--path", str(ROOT), "--scene", "res://tests/unit/test_chunk_children.tscn"]
res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
print(res.stdout)
