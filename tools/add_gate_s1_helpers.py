#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path

BLUEPRINT = Path(__file__).resolve().parent.parent

def main():
    p = BLUEPRINT / "scenes" / "world" / "province_world.gd"
    text = p.read_text(encoding="utf-8")

    helpers = """

func get_signpost_guide(signpost_id: String) -> String:
	match signpost_id:
		"signpost_center":
			return "Biển Chỉ Dẫn: ↑ Bắc (Rừng Trúc 25s) | ← Tây (Mỏ Tây Hốc 35s) | → Đông (Cổ Đạo Quán 30s) | ↓ Nam (Đồng Nội 20s)"
		"signpost_north":
			return "Mốc Bắc Quan Lộ: ↑ Bắc: Rừng Trúc Vạn Lĩnh và Thạch Động | → Đông: Lối rẽ Cổ Đạo Quán Thanh Hư | ↓ Nam: Về Thanh Trì Huyện"
		"signpost_west":
			return "Mốc Tây Quan Lộ: ← Tây: Trại Mỏ Tây Hốc (Lò rèn, khoáng sản) | → Đông: Trở về Huyện Thành Thanh Trì"
		"signpost_east":
			return "Mốc Đông Quan Lộ: → Đông: Cổ Kiếm Trũng (Tàn Kiếm Bia) | ↑ Bắc: Cổ Đạo Quán | ← Tây: Về Thanh Trì"
		"signpost_south":
			return "Mốc Nam Quan Lộ: ↓ Nam: Thôn Đồng Nội và Độc Trạch Hắc Xà | ↑ Bắc: Về Thanh Trì Huyện"
		"signpost_daoist":
			return "Thanh Hư Cổ Quán: Đạo pháp tự nhiên, bồ đoàn tĩnh tọa ngộ đạo, tiếp cận đan đạo sơ khởi."
	return ""

func _execute_subzone_action(action_id: String) -> void:
	match action_id:
		"meditation_cushion", "daoist_meditation":
			if GameSession:
				GameSession.heal_player(15)
				GameSession.add_cultivation(25)
				if EventBus:
					EventBus.notification_requested.emit("Tĩnh tọa bồ đoàn Cổ Đạo Quán: Khí hải ngưng tụ, +15 Khí Huyết, +25 Tu Vi!", "success")
		"mine_iron_ore", "mine_tay_hoc":
			if GameSession:
				GameSession.add_item("iron_ore", 2)
				GameSession.add_item("item_linh_thach", 20)
				GameSession.add_cultivation(15)
				if EventBus:
					EventBus.notification_requested.emit("Khai khoáng Tây Hốc: Đào được 2 Quặng Sắt và 20 Linh Thạch!", "success")
		"harvest_rice", "farm_dong_noi":
			if GameSession:
				GameSession.add_item("rice_grain", 3)
				GameSession.add_cultivation(10)
				if EventBus:
					EventBus.notification_requested.emit("Thu hoạch lúa Đồng Nội: Gặt được 3 Bó Lúa và +10 Tu Vi thể nghiệm hồng trần!", "success")
"""

    if "func get_signpost_guide" not in text:
        text += helpers
        p.write_text(text, encoding="utf-8")
        print("Added get_signpost_guide and _execute_subzone_action to province_world.gd")
    else:
        print("Already present in province_world.gd")

if __name__ == "__main__":
    main()
