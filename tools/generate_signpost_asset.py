#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate pixel art signpost for Wuxia theme (32x48 px)
"""

from PIL import Image, ImageDraw
from pathlib import Path

BLUEPRINT = Path(__file__).resolve().parent.parent
TARGET_PNG = BLUEPRINT / "wuxia" / "32" / "props" / "town" / "signpost.png"
TARGET_TSCN = BLUEPRINT / "wuxia" / "32" / "props" / "town" / "signpost.tscn"

def generate_signpost():
    TARGET_PNG.parent.mkdir(parents=True, exist_ok=True)
    
    # 32x48 pixel art canvas (transparent)
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Color palette (Rustic wuxia wood)
    wood_dark = (58, 41, 28, 255)
    wood_med = (112, 79, 54, 255)
    wood_light = (165, 124, 89, 255)
    wood_high = (206, 168, 128, 255)
    gold_ink = (212, 175, 55, 255)
    base_stone = (75, 75, 80, 255)
    
    # 1. Base stone / dirt mound (y: 42 to 46)
    draw.ellipse([8, 41, 23, 46], fill=base_stone)
    
    # 2. Main wooden post (x: 14 to 17, y: 10 to 44)
    draw.rectangle([14, 10, 17, 44], fill=wood_med)
    draw.rectangle([14, 10, 14, 44], fill=wood_light) # Highlight left
    draw.rectangle([17, 10, 17, 44], fill=wood_dark)  # Shadow right
    
    # Post cap roof (small pyramidal cap on top)
    draw.polygon([(12, 10), (19, 10), (16, 6)], fill=wood_dark)
    draw.polygon([(13, 10), (16, 7), (16, 10)], fill=wood_light)
    
    # 3. Top sign board pointing Left (West) (y: 12 to 20)
    # Pointing to the left: arrow point at (4, 16)
    draw.polygon([(4, 16), (10, 12), (24, 12), (24, 20), (10, 20)], fill=wood_med)
    draw.line([(4, 16), (10, 12), (24, 12)], fill=wood_high, width=1)
    draw.line([(4, 16), (10, 20), (24, 20)], fill=wood_dark, width=1)
    # Wuxia calligraphy strokes in gold ink
    draw.rectangle([12, 15, 14, 17], fill=gold_ink)
    draw.rectangle([17, 15, 19, 17], fill=gold_ink)
    
    # 4. Lower sign board pointing Right (East) (y: 22 to 30)
    # Pointing to the right: arrow point at (27, 26)
    draw.polygon([(8, 22), (22, 22), (27, 26), (22, 30), (8, 30)], fill=wood_med)
    draw.line([(8, 22), (22, 22), (27, 26)], fill=wood_high, width=1)
    draw.line([(8, 30), (22, 30), (27, 26)], fill=wood_dark, width=1)
    # Gold ink strokes
    draw.rectangle([11, 25, 13, 27], fill=gold_ink)
    draw.rectangle([16, 25, 18, 27], fill=gold_ink)
    
    img.save(TARGET_PNG)
    print(f"✓ Generated {TARGET_PNG}")
    
    # Create Godot scene
    tscn_content = """[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://wuxia/32/props/town/signpost.png" id="1_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_base"]
size = Vector2(16, 10)

[node name="signpost" type="StaticBody2D"]
texture_filter = 1
collision_layer = 1
collision_mask = 0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("1_tex")
centered = false
offset = Vector2(-16, -44)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, -5)
shape = SubResource("RectangleShape2D_base")
"""
    TARGET_TSCN.write_text(tscn_content, encoding="utf-8")
    print(f"✓ Generated {TARGET_TSCN}")

if __name__ == "__main__":
    generate_signpost()
