from pathlib import Path

path = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT/tests/test_runner.gd")
content = path.read_text(encoding="utf-8")

old_code = """	# MiniMap & WorldMap Modal Suite
	var test_map = load("res://tests/unit/test_ui_world_map.gd")
	
	var suites = ["""

new_code = """	# MiniMap & WorldMap Modal Suite
	var test_map = load("res://tests/unit/test_ui_world_map.gd")
	var test_ow_mobs = load("res://tests/unit/test_openworld_interactions_and_mobs.gd")
	
	var suites = ["""

old_suite_list = """		test_m5.run_all_tests(),
		test_map.run_all_tests()
	]"""

new_suite_list = """		test_m5.run_all_tests(),
		test_map.run_all_tests(),
		test_ow_mobs.run_all_tests()
	]"""

content_norm = content.replace("\r\n", "\n")
old_code_norm = old_code.replace("\r\n", "\n")
new_code_norm = new_code.replace("\r\n", "\n")
old_sl_norm = old_suite_list.replace("\r\n", "\n")
new_sl_norm = new_suite_list.replace("\r\n", "\n")

assert old_code_norm in content_norm, "old_code not found!"
assert old_sl_norm in content_norm, "old_suite_list not found!"

content_norm = content_norm.replace(old_code_norm, new_code_norm, 1)
content_norm = content_norm.replace(old_sl_norm, new_sl_norm, 1)

if "\r\n" in content:
    path.write_text(content_norm.replace("\n", "\r\n"), encoding="utf-8")
else:
    path.write_text(content_norm, encoding="utf-8")

print("Successfully updated test_runner.gd with test_ow_mobs suite!")
