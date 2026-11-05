"""
generate_building_scenes.py
Generates Godot .tscn scene files for all Wuxia buildings, nature, and landmark nodes.
"""

import os

def create_building_tscn(name, png_rel_path, width, height, collision_w, collision_h, collision_y_offset=0, two_flanks=False):
    offset_x = -width // 2
    offset_y = -height
    
    if two_flanks:
        # Gate with two side collision blocks and clear passage in center
        col_w = collision_w
        col_h = collision_h
        half_gap = 22
        left_x = -(half_gap + col_w / 2.0)
        right_x = half_gap + col_w / 2.0
        pos_y = -col_h / 2.0 + collision_y_offset
        content = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://{png_rel_path}" id="1_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_flank"]
size = Vector2({col_w}, {col_h})

[node name="{name}" type="StaticBody2D"]
texture_filter = 1
collision_layer = 1
collision_mask = 0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("1_tex")
offset = Vector2({offset_x}, {offset_y})
centered = false

[node name="CollisionLeft" type="CollisionShape2D" parent="."]
position = Vector2({left_x}, {pos_y})
shape = SubResource("RectangleShape2D_flank")

[node name="CollisionRight" type="CollisionShape2D" parent="."]
position = Vector2({right_x}, {pos_y})
shape = SubResource("RectangleShape2D_flank")
"""
    else:
        col_w = collision_w
        col_h = collision_h
        pos_y = -col_h / 2.0 + collision_y_offset
        content = f"""[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://{png_rel_path}" id="1_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_base"]
size = Vector2({col_w}, {col_h})

[node name="{name}" type="StaticBody2D"]
texture_filter = 1
collision_layer = 1
collision_mask = 0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("1_tex")
offset = Vector2({offset_x}, {offset_y})
centered = false

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, {pos_y})
shape = SubResource("RectangleShape2D_base")
"""
    return content

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    b_dir = os.path.join(base_dir, "wuxia", "32", "buildings")
    n_dir = os.path.join(base_dir, "wuxia", "32", "nature")

    buildings = [
        ("gate_tam_quan", "wuxia/32/buildings/gate_tam_quan.png", 160, 128, 42, 28, 0, True),
        ("sect_palace_hall", "wuxia/32/buildings/sect_palace_hall.png", 192, 160, 148, 36, -4, False),
        ("alchemy_hall", "wuxia/32/buildings/alchemy_hall.png", 144, 128, 114, 32, -4, False),
        ("tavern_inn", "wuxia/32/buildings/tavern_inn.png", 160, 144, 126, 36, -4, False),
        ("blacksmith_forge", "wuxia/32/buildings/blacksmith_forge.png", 144, 128, 112, 32, -4, False),
        ("market_pavilion", "wuxia/32/buildings/market_pavilion.png", 144, 128, 108, 30, -4, False),
        ("courtyard_house", "wuxia/32/buildings/courtyard_house.png", 128, 112, 98, 30, -4, False),
        ("moonlight_pavilion", "wuxia/32/buildings/moonlight_pavilion.png", 96, 96, 56, 24, -4, False)
    ]

    for name, rel, w, h, cw, ch, cy, flank in buildings:
        path = os.path.join(b_dir, f"{name}.tscn")
        with open(path, "w", encoding="utf-8") as f:
            f.write(create_building_tscn(name, rel, w, h, cw, ch, cy, flank))
        print(f"Created building scene: {path}")

    nature = [
        ("bamboo_cluster", "wuxia/32/nature/bamboo_cluster.png", 64, 96, 24, 16, 0, False),
        ("ancient_pine", "wuxia/32/nature/ancient_pine.png", 96, 112, 28, 20, 0, False),
        ("cavern_entrance", "wuxia/32/nature/cavern_entrance.png", 96, 80, 76, 28, 0, False),
        ("sword_monolith", "wuxia/32/nature/sword_monolith.png", 64, 96, 40, 24, 0, False),
        ("swamp_shrine", "wuxia/32/nature/swamp_shrine.png", 80, 80, 48, 26, 0, False)
    ]

    for name, rel, w, h, cw, ch, cy, flank in nature:
        path = os.path.join(n_dir, f"{name}.tscn")
        with open(path, "w", encoding="utf-8") as f:
            f.write(create_building_tscn(name, rel, w, h, cw, ch, cy, flank))
        print(f"Created nature scene: {path}")

if __name__ == "__main__":
    main()
