"""
generate_wuxia_graphics.py
Synthesizes authentic 2D Top-Down / 2.5D Wuxia Pixel Art Buildings, Props and Landmarks
for ĐẠO TÀN: VẠN KIẾP using the 43-color palette.
"""

import os
from PIL import Image, ImageDraw

# 43-color Wuxia palette mapping
PALETTE = {
    "dark_bg": (0x24, 0x20, 0x2a, 255),
    "dark_wood": (0x3a, 0x34, 0x40, 255),
    "cream_light": (0xe8, 0xdc, 0xc4, 255),
    "cream": (0xd2, 0xc4, 0xa8, 255),
    "stone_light": (0xb8, 0xaa, 0x8f, 255),
    "stone_mid": (0x9d, 0x90, 0x79, 255),
    "stone_dark": (0x83, 0x76, 0x65, 255),
    "timber_dark": (0x6b, 0x5f, 0x52, 255),
    "wood_warm": (0x9a, 0x73, 0x52, 255),
    "wood_deep": (0x6e, 0x50, 0x39, 255),
    "slate_light": (0x5b, 0x5e, 0x68, 255),
    "slate_dark": (0x40, 0x42, 0x4c, 255),
    "bamboo_light": (0x9b, 0xb0, 0x7a, 255),
    "bamboo_mid": (0x80, 0x99, 0x5f, 255),
    "bamboo_green": (0x68, 0x83, 0x4e, 255),
    "forest_mid": (0x55, 0x70, 0x46, 255),
    "forest_dark": (0x46, 0x60, 0x3f, 255),
    "azure_highlight": (0xa9, 0xc4, 0xc6, 255),
    "azure_light": (0x8a, 0xae, 0xb3, 255),
    "azure_mid": (0x6f, 0x97, 0xa0, 255),
    "azure_dark": (0x58, 0x81, 0x8c, 255),
    "azure_deep": (0x45, 0x6b, 0x78, 255),
    "white_cloth": (0xe4, 0xe6, 0xe0, 255),
    "grey_cloth": (0xbc, 0xc5, 0xc8, 255),
    "shadow_cloth": (0x8f, 0x9c, 0xa6, 255),
    "coral_light": (0xe0, 0x7b, 0x5f, 255),
    "red_lacquer": (0xc8, 0x48, 0x3a, 255),
    "red_crimson": (0x8e, 0x2f, 0x2a, 255),
    "red_shadow": (0x5f, 0x21, 0x26, 255),
    "jade_light": (0x90, 0xc6, 0xaa, 255),
    "jade_mid": (0x5f, 0xa5, 0x8c, 255),
    "jade_dark": (0x3f, 0x7a, 0x68, 255),
    "gold_bright": (0xf0, 0xcf, 0x7c, 255),
    "gold_mid": (0xd8, 0xa8, 0x4a, 255),
    "gold_shadow": (0xa8, 0x77, 0x2f, 255),
    "skin_light": (0xf0, 0xc9, 0xa2, 255),
    "skin_mid": (0xd2, 0x9f, 0x79, 255),
    "skin_shadow": (0xa5, 0x70, 0x5a, 255),
    "night_sky": (0x5d, 0x66, 0x8a, 255),
    "night_shadow": (0x41, 0x49, 0x68, 255),
    "void_dark": (0x2d, 0x31, 0x49, 255),
    "lantern_light": (0xff, 0xf0, 0xb8, 255),
    "lantern_glow": (0xf5, 0xa9, 0x5b, 255),
    "trans": (0, 0, 0, 0)
}

def create_transparent(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def draw_curved_roof(draw, x_center, y_top, width, height, roof_color, highlight_color, shadow_color, ridge_gold=False):
    """Draws an authentic Chinese/Wuxia curved flared roof with upturned eaves."""
    hw = width // 2
    # Roof trapezoid with flared wings
    points = [
        (x_center - hw + 8, y_top + height),     # bottom left base
        (x_center - hw, y_top + height - 6),     # bottom left flared eave tip
        (x_center - hw + 16, y_top + 8),         # slope left
        (x_center - 12, y_top),                  # ridge left
        (x_center + 12, y_top),                  # ridge right
        (x_center + hw - 16, y_top + 8),         # slope right
        (x_center + hw, y_top + height - 6),     # bottom right flared eave tip
        (x_center + hw - 8, y_top + height)      # bottom right base
    ]
    draw.polygon(points, fill=roof_color)
    
    # Roof tiles lines (shingle ribs)
    num_ribs = max(4, width // 10)
    for i in range(-num_ribs // 2, num_ribs // 2 + 1):
        x_base = x_center + i * 9
        if abs(x_base - x_center) < hw - 8:
            x_top = x_center + int(i * 9 * 0.45)
            y_b = y_top + height - 1
            draw.line([(x_top, y_top + 2), (x_base, y_b)], fill=shadow_color, width=1)
            draw.line([(x_top + 1, y_top + 2), (x_base + 1, y_b)], fill=highlight_color, width=1)
            
    # Eave rim underline
    draw.line([(x_center - hw, y_top + height - 6), (x_center - hw + 8, y_top + height),
               (x_center + hw - 8, y_top + height), (x_center + hw, y_top + height - 6)], fill=PALETTE["dark_wood"], width=2)
    # Eave edge highlight
    draw.line([(x_center - hw, y_top + height - 7), (x_center + hw, y_top + height - 7)], fill=highlight_color, width=1)

    # Ridge beam
    ridge_col = PALETTE["gold_mid"] if ridge_gold else shadow_color
    draw.rectangle([x_center - 14, y_top - 2, x_center + 14, y_top + 2], fill=ridge_col)
    if ridge_gold:
        draw.rectangle([x_center - 12, y_top - 3, x_center + 12, y_top - 1], fill=PALETTE["gold_bright"])
        # Eave bird/dragon finials
        draw.polygon([(x_center - hw - 2, y_top + height - 10), (x_center - hw + 2, y_top + height - 4), (x_center - hw - 3, y_top + height - 5)], fill=PALETTE["gold_bright"])
        draw.polygon([(x_center + hw + 2, y_top + height - 10), (x_center + hw - 2, y_top + height - 4), (x_center + hw + 3, y_top + height - 5)], fill=PALETTE["gold_bright"])

def draw_wooden_pillar(draw, x, y, width, height):
    draw.rectangle([x, y, x + width - 1, y + height - 1], fill=PALETTE["red_lacquer"])
    draw.line([(x, y), (x, y + height - 1)], fill=PALETTE["coral_light"])
    draw.line([(x + width - 1, y), (x + width - 1, y + height - 1)], fill=PALETTE["red_crimson"])
    # Stone plinth base
    draw.rectangle([x - 1, y + height - 4, x + width, y + height], fill=PALETTE["stone_light"])
    draw.line([(x - 1, y + height), (x + width, y + height)], fill=PALETTE["stone_dark"])

def draw_lantern(draw, x, y):
    draw.line([(x, y - 4), (x, y)], fill=PALETTE["timber_dark"], width=1)
    draw.ellipse([x - 4, y, x + 4, y + 8], fill=PALETTE["red_lacquer"], outline=PALETTE["red_shadow"])
    draw.rectangle([x - 2, y + 2, x + 2, y + 6], fill=PALETTE["lantern_glow"])
    draw.rectangle([x - 1, y + 3, x + 1, y + 5], fill=PALETTE["lantern_light"])
    draw.line([(x, y + 9), (x, y + 12)], fill=PALETTE["gold_bright"], width=1)

def draw_stone_steps(draw, x, y, width, steps_count=3):
    step_h = 4
    for s in range(steps_count):
        sw = width + s * 4
        sx = x - s * 2
        sy = y + s * step_h
        draw.rectangle([sx, sy, sx + sw, sy + step_h - 1], fill=PALETTE["stone_light"])
        draw.line([(sx, sy), (sx + sw, sy)], fill=PALETTE["cream_light"])
        draw.line([(sx, sy + step_h - 1), (sx + sw, sy + step_h - 1)], fill=PALETTE["stone_dark"])

# ==============================================================================
# 1. CỔNG TAM QUAN THÀNH MÔN (160x128)
# ==============================================================================
def gen_gate_tam_quan():
    img = create_transparent(160, 128)
    draw = ImageDraw.Draw(img)
    
    # 1. Stone fortress base on flanks
    draw.rectangle([10, 60, 42, 122], fill=PALETTE["stone_mid"])
    draw.rectangle([118, 60, 150, 122], fill=PALETTE["stone_mid"])
    # Stone bricks lines
    for by in range(62, 122, 6):
        draw.line([(10, by), (42, by)], fill=PALETTE["stone_dark"])
        draw.line([(118, by), (150, by)], fill=PALETTE["stone_dark"])
    for bx in [20, 32]:
        draw.line([(bx, 62), (bx, 122)], fill=PALETTE["stone_light"])
        draw.line([(bx + 108, 62), (bx + 108, 122)], fill=PALETTE["stone_light"])
        
    # Stone battlements (parapets)
    for bx in range(10, 40, 8):
        draw.rectangle([bx, 54, bx + 5, 60], fill=PALETTE["stone_light"])
    for bx in range(118, 148, 8):
        draw.rectangle([bx, 54, bx + 5, 60], fill=PALETTE["stone_light"])

    # 2. Central Arch Gateway Walls
    draw.rectangle([42, 50, 118, 122], fill=PALETTE["red_crimson"])
    draw.rectangle([46, 54, 114, 120], fill=PALETTE["red_lacquer"])
    
    # Arched passages
    # Main center archway (x: 64..96, y: 72..122)
    draw.rectangle([64, 76, 96, 122], fill=PALETTE["dark_bg"])
    draw.ellipse([64, 66, 96, 86], fill=PALETTE["dark_bg"])
    draw.arc([63, 65, 97, 87], 180, 360, fill=PALETTE["stone_light"], width=2)
    # Iron-studded gates (half-opened)
    draw.rectangle([65, 78, 77, 122], fill=PALETTE["timber_dark"])
    draw.rectangle([83, 78, 95, 122], fill=PALETTE["timber_dark"])
    for gy in range(82, 120, 8):
        draw.point([(70, gy), (89, gy)], fill=PALETTE["gold_mid"])
        
    # Side arches
    # Left side arch (x: 20..34, y: 86..122)
    draw.rectangle([20, 90, 34, 122], fill=PALETTE["dark_bg"])
    draw.ellipse([20, 82, 34, 98], fill=PALETTE["dark_bg"])
    draw.arc([19, 81, 35, 99], 180, 360, fill=PALETTE["stone_light"], width=1)
    # Right side arch (x: 126..140, y: 86..122)
    draw.rectangle([126, 90, 140, 122], fill=PALETTE["dark_bg"])
    draw.ellipse([126, 82, 140, 98], fill=PALETTE["dark_bg"])
    draw.arc([125, 81, 141, 99], 180, 360, fill=PALETTE["stone_light"], width=1)

    # 3. Wooden Pillars on main archway
    draw_wooden_pillar(draw, 44, 52, 6, 70)
    draw_wooden_pillar(draw, 56, 52, 5, 70)
    draw_wooden_pillar(draw, 99, 52, 5, 70)
    draw_wooden_pillar(draw, 110, 52, 6, 70)

    # 4. Signboard Plaque
    draw.rectangle([62, 54, 98, 64], fill=PALETTE["red_crimson"], outline=PALETTE["gold_bright"], width=1)
    draw.line([(68, 59), (92, 59)], fill=PALETTE["gold_bright"], width=2) # "THANH TRÌ" golden calligraphy stroke

    # 5. Lower side roofs over the towers
    draw_curved_roof(draw, 26, 46, 52, 16, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])
    draw_curved_roof(draw, 134, 46, 52, 16, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])

    # 6. Upper Central Pavillion on Gate
    draw.rectangle([54, 26, 106, 50], fill=PALETTE["red_lacquer"])
    for px in [56, 70, 88, 102]:
        draw_wooden_pillar(draw, px, 26, 4, 24)
    # Upper window lattices
    draw.rectangle([74, 30, 86, 44], fill=PALETTE["dark_bg"])
    draw.line([(80, 30), (80, 44)], fill=PALETTE["wood_warm"])
    draw.line([(74, 37), (86, 37)], fill=PALETTE["wood_warm"])

    # 7. Grand Main Curved Roof
    draw_curved_roof(draw, 80, 10, 116, 26, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"], ridge_gold=True)

    # 8. Hanging Red Lanterns
    draw_lantern(draw, 48, 58)
    draw_lantern(draw, 112, 58)

    # 9. Ground Stone Step
    draw_stone_steps(draw, 54, 122, 52, 2)
    return img

# ==============================================================================
# 2. THANH VI KIẾM TÔNG PHÂN ĐIỆN (192x160)
# ==============================================================================
def gen_sect_palace_hall():
    img = create_transparent(192, 160)
    draw = ImageDraw.Draw(img)

    # 1. Foundation Podium
    draw.rectangle([16, 138, 176, 154], fill=PALETTE["stone_mid"])
    draw.line([(16, 138), (176, 138)], fill=PALETTE["stone_light"])
    draw.line([(16, 154), (176, 154)], fill=PALETTE["stone_dark"])
    draw_stone_steps(draw, 72, 144, 48, 3)

    # 2. Ground Floor Hall (x: 28..164, y: 84..140)
    draw.rectangle([28, 84, 164, 140], fill=PALETTE["red_crimson"])
    draw.rectangle([34, 88, 158, 138], fill=PALETTE["red_lacquer"])

    # Double Palace Doors with brass knockers
    draw.rectangle([78, 96, 114, 140], fill=PALETTE["timber_dark"])
    draw.line([(96, 96), (96, 140)], fill=PALETTE["dark_wood"], width=2)
    draw.ellipse([88, 114, 92, 118], fill=PALETTE["gold_mid"])
    draw.ellipse([100, 114, 104, 118], fill=PALETTE["gold_mid"])
    
    # Ornate Lattice Windows
    for wx in [44, 126]:
        draw.rectangle([wx, 98, wx + 20, 128], fill=PALETTE["dark_bg"])
        draw.rectangle([wx + 2, 100, wx + 18, 126], fill=PALETTE["wood_deep"])
        for ly in range(104, 126, 5):
            draw.line([(wx + 2, ly), (wx + 18, ly)], fill=PALETTE["gold_shadow"])
        draw.line([(wx + 10, 100), (wx + 10, 126)], fill=PALETTE["gold_shadow"])

    # 6 Massive Vermilion Pillars on Ground Floor
    pillars_x = [30, 58, 74, 116, 132, 160]
    for px in pillars_x:
        draw_wooden_pillar(draw, px, 84, 6, 56)

    # 3. Lower Tier Azure Glazed Roof
    draw_curved_roof(draw, 96, 62, 172, 26, PALETTE["azure_deep"], PALETTE["azure_mid"], PALETTE["azure_dark"])

    # 4. Upper Level Pavilion (x: 48..144, y: 34..66)
    draw.rectangle([48, 36, 144, 66], fill=PALETTE["red_lacquer"])
    # Balustrade railing
    draw.rectangle([44, 58, 148, 64], fill=PALETTE["wood_warm"])
    for bx in range(46, 148, 6):
        draw.line([(bx, 58), (bx, 64)], fill=PALETTE["timber_dark"])
    # Upper pillars
    for upx in [50, 76, 114, 140]:
        draw_wooden_pillar(draw, upx, 36, 4, 26)
    # Upper Gold Plaque: "THANH VI PHÂN ĐIỆN"
    draw.rectangle([74, 40, 118, 52], fill=PALETTE["red_crimson"], outline=PALETTE["gold_bright"], width=1)
    draw.line([(80, 46), (112, 46)], fill=PALETTE["gold_bright"], width=2)
    # Upper windows
    draw.rectangle([56, 40, 70, 54], fill=PALETTE["night_shadow"])
    draw.rectangle([122, 40, 136, 54], fill=PALETTE["night_shadow"])

    # 5. Grand Top Tier Azure Glazed Roof with Golden Ridge
    draw_curved_roof(draw, 96, 10, 148, 28, PALETTE["azure_deep"], PALETTE["azure_mid"], PALETTE["azure_dark"], ridge_gold=True)

    # 6. Hanging Sect Lanterns (Cyan Spirit Glow)
    for lx in [38, 66, 124, 154]:
        draw.line([(lx, 86), (lx, 90)], fill=PALETTE["timber_dark"])
        draw.ellipse([lx - 3, 90, lx + 3, 98], fill=PALETTE["azure_dark"])
        draw.rectangle([lx - 1, 92, lx + 1, 96], fill=PALETTE["azure_highlight"])
        draw.line([(lx, 99), (lx, 102)], fill=PALETTE["gold_mid"])

    return img

# ==============================================================================
# 3. DƯỢC PHẨM CÁC / LÒ LUYỆN ĐAN (144x128)
# ==============================================================================
def gen_alchemy_hall():
    img = create_transparent(144, 128)
    draw = ImageDraw.Draw(img)

    # 1. Timber Foundation
    draw.rectangle([12, 116, 132, 124], fill=PALETTE["timber_dark"])
    draw_stone_steps(draw, 50, 118, 36, 2)

    # 2. Apothecary Main Building (x: 20..106, y: 56..118)
    draw.rectangle([20, 56, 106, 118], fill=PALETTE["wood_deep"])
    draw.rectangle([24, 60, 102, 116], fill=PALETTE["wood_warm"])
    
    # Wooden counter window
    draw.rectangle([34, 76, 70, 104], fill=PALETTE["dark_bg"])
    # Medicine drawers behind counter
    for dy in range(78, 102, 6):
        draw.line([(36, dy), (68, dy)], fill=PALETTE["timber_dark"])
    for dx in range(42, 68, 7):
        draw.line([(dx, 78), (dx, 102)], fill=PALETTE["timber_dark"])
    draw.rectangle([32, 98, 72, 106], fill=PALETTE["wood_warm"], outline=PALETTE["timber_dark"]) # Counter ledge

    # Entrance door
    draw.rectangle([78, 76, 98, 116], fill=PALETTE["timber_dark"])
    draw.line([(88, 76), (88, 116)], fill=PALETTE["dark_wood"])

    # Signboard: "BÁCH THẢO ĐƯỜNG"
    draw.rectangle([36, 62, 88, 72], fill=PALETTE["dark_wood"], outline=PALETTE["bamboo_light"], width=1)
    draw.line([(42, 67), (82, 67)], fill=PALETTE["bamboo_light"], width=2)

    # Wooden Pillars
    for px in [22, 74, 102]:
        draw_wooden_pillar(draw, px, 56, 4, 62)

    # 3. Weathered Jade/Green Tile Roof
    draw_curved_roof(draw, 64, 26, 118, 32, PALETTE["jade_dark"], PALETTE["jade_mid"], PALETTE["forest_dark"])

    # 4. Attached Side Porch with Alchemy Furnace on right (x: 104..140)
    draw.rectangle([106, 80, 136, 118], fill=PALETTE["stone_mid"])
    draw.line([(106, 80), (136, 80)], fill=PALETTE["stone_light"])
    
    # Bronze Alchemy Cauldron (Lò Luyện Đan)
    # Tripod legs
    draw.line([(114, 114), (111, 122)], fill=PALETTE["timber_dark"], width=2)
    draw.line([(128, 114), (131, 122)], fill=PALETTE["timber_dark"], width=2)
    # Cauldron belly
    draw.ellipse([110, 96, 132, 116], fill=PALETTE["gold_shadow"], outline=PALETTE["timber_dark"])
    draw.ellipse([113, 98, 129, 112], fill=PALETTE["gold_mid"])
    # Cauldron handles (Tai đỉnh)
    draw.arc([108, 98, 114, 108], 90, 270, fill=PALETTE["gold_shadow"], width=2)
    draw.arc([128, 98, 134, 108], 270, 90, fill=PALETTE["gold_shadow"], width=2)
    # Cauldron lid with jewel finial
    draw.chord([114, 90, 128, 100], 180, 360, fill=PALETTE["gold_shadow"])
    draw.ellipse([119, 87, 123, 91], fill=PALETTE["jade_light"])
    # Spiraling Turquoise Spirit Smoke
    draw.arc([118, 76, 126, 88], 0, 180, fill=PALETTE["jade_light"], width=2)
    draw.arc([120, 68, 130, 80], 180, 360, fill=PALETTE["azure_highlight"], width=2)
    draw.point([(124, 64), (127, 62), (122, 60)], fill=PALETTE["azure_highlight"])

    # Green Herb Hanging Lantern
    draw.line([(28, 62), (28, 66)], fill=PALETTE["timber_dark"])
    draw.ellipse([25, 66, 31, 74], fill=PALETTE["jade_dark"])
    draw.rectangle([27, 68, 29, 72], fill=PALETTE["jade_light"])

    return img

# ==============================================================================
# 4. VÔ ƯU TỬU QUÁN / QUÁN TRỌ (160x144)
# ==============================================================================
def gen_tavern_inn():
    img = create_transparent(160, 144)
    draw = ImageDraw.Draw(img)

    # 1. Base Stone Foundation
    draw.rectangle([16, 130, 144, 138], fill=PALETTE["stone_dark"])
    draw_stone_steps(draw, 64, 132, 40, 2)

    # 2. Ground Floor (x: 22..138, y: 78..132)
    draw.rectangle([22, 78, 138, 132], fill=PALETTE["wood_deep"])
    draw.rectangle([26, 82, 134, 130], fill=PALETTE["wood_warm"])
    
    # Sliding lattice wooden entrance
    draw.rectangle([68, 88, 100, 130], fill=PALETTE["dark_bg"])
    draw.line([(84, 88), (84, 130)], fill=PALETTE["timber_dark"], width=2)
    # Warmly lit paper windows
    for wx in [32, 108]:
        draw.rectangle([wx, 92, wx + 20, 118], fill=PALETTE["lantern_glow"])
        draw.line([(wx + 10, 92), (wx + 10, 118)], fill=PALETTE["wood_deep"])
        draw.line([(wx, 105), (wx + 20, 105)], fill=PALETTE["wood_deep"])

    # Stack of Wine Jugs on the side (x: 122..136)
    for jx, jy in [(124, 122), (130, 122), (127, 115)]:
        draw.ellipse([jx, jy, jx + 6, jy + 7], fill=PALETTE["stone_mid"], outline=PALETTE["timber_dark"])
        draw.rectangle([jx + 1, jy - 1, jx + 5, jy + 1], fill=PALETTE["red_lacquer"]) # Red cloth lid

    # Ground floor pillars
    for px in [24, 62, 104, 136]:
        draw_wooden_pillar(draw, px, 78, 4, 54)

    # 3. Intermediate Roof Eaves
    draw_curved_roof(draw, 80, 58, 142, 22, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])

    # 4. Second Floor Tavern Balcony (x: 32..128, y: 26..60)
    draw.rectangle([32, 28, 128, 60], fill=PALETTE["wood_warm"])
    # Wooden Balcony Railing
    draw.rectangle([28, 52, 132, 58], fill=PALETTE["timber_dark"])
    for rx in range(30, 132, 5):
        draw.line([(rx, 52), (rx, 58)], fill=PALETTE["wood_deep"])
    # 2nd Floor Paper Lantern Windows
    for wx in [40, 68, 96]:
        draw.rectangle([wx, 34, wx + 16, 48], fill=PALETTE["lantern_glow"])
        draw.line([(wx + 8, 34), (wx + 8, 48)], fill=PALETTE["wood_deep"])
        draw.line([(wx, 41), (wx + 16, 41)], fill=PALETTE["wood_deep"])
    for upx in [34, 62, 98, 126]:
        draw_wooden_pillar(draw, upx, 28, 3, 30)

    # Hanging Wine Flag Banner: "TỬU" (x: 20..30, y: 34..70)
    draw.line([(22, 34), (22, 70)], fill=PALETTE["timber_dark"], width=2) # Bamboo pole
    draw.polygon([(24, 40), (36, 40), (32, 64), (24, 60)], fill=PALETTE["red_lacquer"])
    draw.rectangle([26, 46, 32, 54], fill=PALETTE["white_cloth"]) # "TỬU" badge

    # 5. Top Curved Roof
    draw_curved_roof(draw, 80, 8, 132, 24, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])

    # 6. Hanging Red Lanterns
    draw_lantern(draw, 42, 60)
    draw_lantern(draw, 118, 60)

    return img

# ==============================================================================
# 5. THIẾT TƯỢNG PHÁC / LÒ RÈN KỶ HOÀN (144x128)
# ==============================================================================
def gen_blacksmith_forge():
    img = create_transparent(144, 128)
    draw = ImageDraw.Draw(img)

    # 1. Dirt/Stone Base
    draw.rectangle([10, 118, 134, 124], fill=PALETTE["stone_dark"])
    
    # 2. Main Workshop (x: 16..96, y: 62..120)
    draw.rectangle([16, 62, 96, 120], fill=PALETTE["stone_dark"])
    draw.rectangle([20, 66, 92, 118], fill=PALETTE["timber_dark"])
    # Open front workshop bay
    draw.rectangle([28, 76, 84, 118], fill=PALETTE["dark_bg"])
    
    # Tool and Weapon Display Rack inside
    draw.line([(34, 82), (34, 114)], fill=PALETTE["stone_light"], width=2) # Spear
    draw.polygon([(32, 80), (36, 80), (34, 76)], fill=PALETTE["white_cloth"]) # Spearhead
    draw.line([(42, 88), (42, 112)], fill=PALETTE["white_cloth"], width=2) # Broadsword blade
    draw.line([(40, 112), (44, 112)], fill=PALETTE["gold_mid"]) # Crossguard

    # Anvil on Wooden Stump (x: 58..74, y: 100..118)
    draw.rectangle([62, 108, 70, 118], fill=PALETTE["wood_deep"]) # Stump
    draw.polygon([(58, 102), (74, 102), (72, 108), (60, 108)], fill=PALETTE["stone_light"]) # Anvil body
    draw.rectangle([56, 102, 60, 105], fill=PALETTE["white_cloth"]) # Horn

    # 3. Stone Smelting Furnace & Chimney on Right (x: 94..132, y: 38..120)
    draw.rectangle([94, 72, 132, 120], fill=PALETTE["stone_mid"])
    for by in range(74, 120, 6):
        draw.line([(94, by), (132, by)], fill=PALETTE["stone_dark"])
    # Blazing Furnace Mouth
    draw.arc([102, 90, 124, 116], 180, 360, fill=PALETTE["stone_light"], width=2)
    draw.ellipse([104, 94, 122, 116], fill=PALETTE["coral_light"])
    draw.ellipse([108, 98, 118, 112], fill=PALETTE["lantern_light"]) # White-hot core
    # Stone Chimney
    draw.rectangle([108, 38, 124, 74], fill=PALETTE["stone_mid"])
    draw.rectangle([106, 36, 126, 40], fill=PALETTE["stone_light"]) # Chimney rim
    # Smoke particles
    draw.ellipse([110, 26, 118, 34], fill=PALETTE["shadow_cloth"])
    draw.ellipse([114, 16, 124, 24], fill=PALETTE["grey_cloth"])
    draw.ellipse([118, 8, 128, 16], fill=PALETTE["white_cloth"])

    # 4. Water Quenching Trough
    draw.rectangle([14, 104, 26, 118], fill=PALETTE["timber_dark"])
    draw.rectangle([16, 106, 24, 116], fill=PALETTE["azure_mid"])

    # 5. Workshop Slate Roof
    draw_curved_roof(draw, 56, 38, 108, 26, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])

    return img

# ==============================================================================
# 6. VẠN BẢO LÂU / CHỢ TÁN TU SẠP ĐIẾM (144x128)
# ==============================================================================
def gen_market_pavilion():
    img = create_transparent(144, 128)
    draw = ImageDraw.Draw(img)

    # 1. Base Platform
    draw.rectangle([14, 118, 130, 124], fill=PALETTE["stone_mid"])
    draw_stone_steps(draw, 54, 120, 36, 2)

    # 2. Open Commercial Pavilion Body (x: 22..122, y: 64..120)
    draw.rectangle([22, 64, 122, 120], fill=PALETTE["timber_dark"])
    draw.rectangle([28, 70, 116, 118], fill=PALETTE["dark_bg"])

    # Display Counter Tables draped in Golden-trimmed Red Silk
    draw.rectangle([34, 94, 110, 116], fill=PALETTE["red_crimson"])
    draw.line([(34, 94), (110, 94)], fill=PALETTE["gold_bright"], width=2)
    # Spiritual wares displayed on table:
    # Jade Pill Bottle
    draw.rectangle([42, 86, 48, 94], fill=PALETTE["jade_light"])
    draw.point([(45, 85)], fill=PALETTE["red_lacquer"])
    # Spirit Ore Crystal
    draw.polygon([(64, 94), (68, 84), (72, 94)], fill=PALETTE["azure_light"])
    # Ancient Scroll Box
    draw.rectangle([84, 88, 102, 94], fill=PALETTE["gold_shadow"], outline=PALETTE["gold_mid"])

    # Merchant Banner: "BẢO"
    draw.rectangle([60, 68, 84, 82], fill=PALETTE["red_lacquer"], outline=PALETTE["gold_bright"])
    draw.line([(64, 75), (80, 75)], fill=PALETTE["gold_bright"], width=2)

    # Corner Wooden Pillars
    for px in [24, 48, 96, 120]:
        draw_wooden_pillar(draw, px, 64, 4, 56)

    # 3. Flared Golden Eave Pavilion Roof
    draw_curved_roof(draw, 72, 28, 132, 38, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"], ridge_gold=True)

    # 4. Hanging Red Lanterns
    draw_lantern(draw, 34, 68)
    draw_lantern(draw, 110, 68)

    return img

# ==============================================================================
# 7. NHÀ CỔ DÂN CƯ / TỨ HỢP VIỆN (128x112)
# ==============================================================================
def gen_courtyard_house():
    img = create_transparent(128, 112)
    draw = ImageDraw.Draw(img)

    # 1. Base
    draw.rectangle([12, 104, 116, 110], fill=PALETTE["stone_dark"])
    draw_stone_steps(draw, 48, 106, 32, 2)

    # 2. Main Wall (White plaster / grey brick)
    draw.rectangle([18, 54, 110, 106], fill=PALETTE["cream"])
    draw.rectangle([20, 56, 108, 104], fill=PALETTE["cream_light"])
    # Timber framing
    draw.line([(18, 54), (110, 54)], fill=PALETTE["timber_dark"], width=2)
    draw.line([(18, 104), (110, 104)], fill=PALETTE["timber_dark"], width=2)
    for tx in [18, 44, 84, 110]:
        draw.line([(tx, 54), (tx, 104)], fill=PALETTE["timber_dark"], width=2)

    # Wooden Double Door in Center
    draw.rectangle([52, 68, 76, 104], fill=PALETTE["wood_warm"])
    draw.line([(64, 68), (64, 104)], fill=PALETTE["timber_dark"], width=2)
    draw.point([(58, 86), (70, 86)], fill=PALETTE["gold_mid"]) # Door rings

    # Traditional Round Moon Window on Left
    draw.ellipse([26, 68, 38, 80], fill=PALETTE["dark_bg"], outline=PALETTE["timber_dark"], width=1)
    draw.line([(32, 68), (32, 80)], fill=PALETTE["wood_warm"])
    draw.line([(26, 74), (38, 74)], fill=PALETTE["wood_warm"])

    # Square Window on Right
    draw.rectangle([90, 70, 102, 82], fill=PALETTE["lantern_glow"], outline=PALETTE["timber_dark"])
    draw.line([(96, 70), (96, 82)], fill=PALETTE["timber_dark"])
    draw.line([(90, 76), (102, 76)], fill=PALETTE["timber_dark"])

    # 3. Curved Tile Roof
    draw_curved_roof(draw, 64, 18, 116, 38, PALETTE["slate_dark"], PALETTE["slate_light"], PALETTE["dark_bg"])

    return img

# ==============================================================================
# 8. VỌNG NGUYỆT ĐÌNH (96x96)
# ==============================================================================
def gen_moonlight_pavilion():
    img = create_transparent(96, 96)
    draw = ImageDraw.Draw(img)

    # 1. Octagonal Stone Base
    draw.polygon([(18, 84), (32, 92), (64, 92), (78, 84), (78, 80), (18, 80)], fill=PALETTE["stone_mid"])
    draw.line([(32, 92), (64, 92)], fill=PALETTE["stone_light"])

    # 2. Slender Wooden Pillars
    pillars = [24, 38, 58, 72]
    for px in pillars:
        draw_wooden_pillar(draw, px, 44, 3, 38)

    # Stone Railing
    draw.line([(24, 70), (72, 70)], fill=PALETTE["stone_light"], width=2)

    # Circular Stone Tea Table & Stools in center
    draw.ellipse([42, 66, 54, 74], fill=PALETTE["stone_light"], outline=PALETTE["stone_dark"])
    draw.ellipse([34, 70, 38, 74], fill=PALETTE["stone_mid"])
    draw.ellipse([58, 70, 62, 74], fill=PALETTE["stone_mid"])
    # Tea pot & cup
    draw.ellipse([46, 68, 50, 72], fill=PALETTE["jade_mid"])

    # 3. Peaked Conical Hexagonal Roof
    hw = 44
    draw.polygon([(48, 8), (4, 46), (12, 48), (84, 48), (92, 46)], fill=PALETTE["slate_dark"])
    # Shading ribs
    draw.line([(48, 8), (4, 46)], fill=PALETTE["slate_light"], width=2)
    draw.line([(48, 8), (92, 46)], fill=PALETTE["slate_light"], width=2)
    draw.line([(48, 8), (32, 48)], fill=PALETTE["dark_bg"], width=1)
    draw.line([(48, 8), (64, 48)], fill=PALETTE["dark_bg"], width=1)
    # Golden Finial Spire on apex
    draw.rectangle([46, 4, 50, 10], fill=PALETTE["gold_bright"])
    draw.ellipse([45, 1, 51, 6], fill=PALETTE["gold_mid"])

    return img

# ==============================================================================
# 9. NATURE & LANDMARKS
# ==============================================================================
def gen_bamboo_cluster():
    """Lush cluster of green bamboo stalks with dense layers of leaves."""
    img = create_transparent(64, 96)
    draw = ImageDraw.Draw(img)

    stalks = [(18, 92, 14), (28, 94, 8), (38, 92, 10), (48, 94, 16)]
    for sx, sy, h_top in stalks:
        # Bamboo stalk with joint segments
        for y in range(sy, h_top, -8):
            draw.line([(sx, y), (sx, y - 6)], fill=PALETTE["bamboo_mid"], width=3)
            draw.line([(sx - 1, y - 7), (sx + 1, y - 7)], fill=PALETTE["bamboo_light"], width=1) # Joint ring
            draw.line([(sx - 1, y - 6), (sx + 1, y - 6)], fill=PALETTE["forest_dark"], width=1)

    # Pointed Bamboo Leaves in dense clumps
    leaf_clusters = [
        (18, 20), (28, 14), (38, 18), (48, 24),
        (14, 36), (32, 32), (44, 40), (22, 50), (40, 52)
    ]
    for lx, ly in leaf_clusters:
        # Fan of 4-5 pointed leaves
        for dx, dy in [(-8, 4), (-12, 10), (0, 8), (8, 6), (12, 12)]:
            draw.polygon([(lx, ly), (lx + dx, ly + dy), (lx + dx // 2, ly + dy // 2 + 2)], fill=PALETTE["bamboo_light"])
            draw.line([(lx, ly), (lx + dx, ly + dy)], fill=PALETTE["bamboo_green"], width=1)

    return img

def gen_ancient_pine():
    """Gnarled wuxia ancient pine tree with twisting trunk and needle pads."""
    img = create_transparent(96, 112)
    draw = ImageDraw.Draw(img)

    # Gnarled twisting trunk
    trunk_pts = [(48, 110), (46, 96), (52, 82), (44, 68), (56, 52), (48, 36)]
    for i in range(len(trunk_pts) - 1):
        draw.line([trunk_pts[i], trunk_pts[i + 1]], fill=PALETTE["wood_deep"], width=7 - i)
        draw.line([(trunk_pts[i][0] - 1, trunk_pts[i][1]), (trunk_pts[i + 1][0] - 1, trunk_pts[i + 1][1])], fill=PALETTE["timber_dark"], width=2)
    # Side branches
    draw.line([(46, 80), (24, 72)], fill=PALETTE["wood_deep"], width=3)
    draw.line([(54, 64), (78, 56)], fill=PALETTE["wood_deep"], width=3)
    draw.line([(48, 48), (28, 40)], fill=PALETTE["wood_deep"], width=2)

    # Cloud-like pine needle pads (horizontal tiered ovals)
    pads = [
        (22, 70, 20, 10), (80, 54, 22, 12),
        (26, 38, 24, 12), (70, 36, 26, 14),
        (48, 24, 30, 16), (48, 12, 22, 12)
    ]
    for px, py, pw, ph in pads:
        draw.ellipse([px - pw // 2, py - ph // 2, px + pw // 2, py + ph // 2], fill=PALETTE["forest_dark"])
        draw.ellipse([px - pw // 2 + 2, py - ph // 2 + 1, px + pw // 2 - 2, py + ph // 2 - 3], fill=PALETTE["forest_mid"])
        draw.ellipse([px - pw // 2 + 4, py - ph // 2 + 2, px + pw // 2 - 4, py + ph // 2 - 6], fill=PALETTE["bamboo_green"])

    return img

def gen_cavern_entrance():
    """Ancient mossy stone cavern entrance with spirit crystal glow."""
    img = create_transparent(96, 80)
    draw = ImageDraw.Draw(img)

    # Rock cliff face
    draw.polygon([(8, 76), (14, 28), (48, 10), (82, 28), (88, 76)], fill=PALETTE["stone_dark"])
    draw.polygon([(14, 76), (20, 32), (48, 14), (76, 32), (82, 76)], fill=PALETTE["stone_mid"])
    
    # Dark cavern mouth
    draw.ellipse([26, 32, 70, 78], fill=PALETTE["dark_bg"])
    draw.rectangle([26, 52, 70, 78], fill=PALETTE["dark_bg"])

    # Overgrown hanging vines & moss
    for vx in range(20, 76, 8):
        vh = 6 + (vx % 7) * 2
        draw.line([(vx, 32), (vx, 32 + vh)], fill=PALETTE["bamboo_green"], width=2)

    # Glowing Cyan Spirit Crystals near mouth
    crystals = [(20, 68), (24, 62), (72, 66), (76, 72)]
    for cx, cy in crystals:
        draw.polygon([(cx, cy), (cx + 3, cy - 6), (cx + 6, cy)], fill=PALETTE["azure_light"])
        draw.line([(cx + 3, cy - 6), (cx + 3, cy)], fill=PALETTE["azure_highlight"])

    return img

def gen_sword_monolith():
    """Giant ancient broken sword embedded into shattered stone rock."""
    img = create_transparent(64, 96)
    draw = ImageDraw.Draw(img)

    # Shattered rock altar
    draw.polygon([(8, 92), (18, 68), (46, 68), (56, 92)], fill=PALETTE["stone_mid"])
    draw.polygon([(14, 92), (22, 72), (42, 72), (50, 92)], fill=PALETTE["stone_light"])
    for rx in [26, 38]:
        draw.line([(rx, 72), (rx - 4, 92)], fill=PALETTE["stone_dark"])

    # Giant Mythical Sword (embedded at slight angle)
    # Blade plunged into rock
    draw.polygon([(26, 72), (36, 72), (34, 30), (28, 30)], fill=PALETTE["slate_light"])
    draw.line([(31, 72), (31, 30)], fill=PALETTE["white_cloth"], width=1) # Fuller/edge
    # Glowing ancient runes on blade
    for ry in [60, 50, 40]:
        draw.point([(31, ry), (30, ry - 1), (32, ry + 1)], fill=PALETTE["gold_bright"])
    # Broad crossguard
    draw.rectangle([22, 26, 40, 30], fill=PALETTE["gold_shadow"], outline=PALETTE["gold_bright"])
    # Grip & Pommel
    draw.rectangle([29, 12, 33, 26], fill=PALETTE["red_crimson"])
    draw.ellipse([27, 8, 35, 14], fill=PALETTE["gold_mid"]) # Pommel ring with red tassel
    draw.line([(31, 14), (31, 20)], fill=PALETTE["coral_light"], width=2)

    return img

def gen_swamp_shrine():
    """Ancient serpent stone altar with toxic purple flame urn."""
    img = create_transparent(80, 80)
    draw = ImageDraw.Draw(img)

    # Mossy tiered altar base
    draw.rectangle([12, 64, 68, 76], fill=PALETTE["stone_dark"])
    draw.rectangle([16, 60, 64, 66], fill=PALETTE["stone_mid"])
    draw.rectangle([24, 48, 56, 60], fill=PALETTE["stone_dark"])
    
    # Coiling Serpent Statues flanking altar
    draw.arc([16, 40, 28, 60], 90, 270, fill=PALETTE["stone_mid"], width=3)
    draw.arc([52, 40, 64, 60], 270, 90, fill=PALETTE["stone_mid"], width=3)

    # Central Toxic Cauldron / Urn
    draw.ellipse([32, 40, 48, 50], fill=PALETTE["stone_dark"])
    # Toxic Purple Fire & Fumes
    draw.polygon([(36, 42), (40, 28), (44, 42)], fill=PALETTE["void_dark"])
    draw.polygon([(38, 42), (40, 32), (42, 42)], fill=PALETTE["night_sky"])
    draw.point([(40, 24), (38, 20), (43, 18)], fill=PALETTE["azure_highlight"]) # Miasma sparks

    return img

# ==============================================================================
# 10. MINIATURE WORLD MAP POI ICONS (48x48)
# ==============================================================================
def gen_wm_thanh_tri_tran():
    img = create_transparent(48, 48)
    draw = ImageDraw.Draw(img)
    # Miniature walled town with gate & pagoda roofs
    draw.rectangle([6, 24, 42, 44], fill=PALETTE["stone_mid"], outline=PALETTE["stone_dark"])
    # Gate arch
    draw.ellipse([20, 32, 28, 44], fill=PALETTE["dark_bg"])
    # Pagoda roofs
    draw.polygon([(8, 24), (24, 14), (40, 24)], fill=PALETTE["slate_dark"])
    draw.polygon([(14, 15), (24, 8), (34, 15)], fill=PALETTE["slate_dark"])
    draw.point([(24, 6)], fill=PALETTE["gold_bright"])
    # Red flags
    draw.line([(10, 24), (10, 18)], fill=PALETTE["timber_dark"])
    draw.polygon([(10, 18), (14, 20), (10, 22)], fill=PALETTE["red_lacquer"])
    return img

def gen_wm_bamboo_forest():
    img = create_transparent(48, 48)
    draw = ImageDraw.Draw(img)
    for bx in [12, 22, 32, 26]:
        draw.line([(bx, 42), (bx, 12)], fill=PALETTE["bamboo_mid"], width=2)
        draw.ellipse([bx - 6, 10, bx + 6, 22], fill=PALETTE["bamboo_light"])
    return img

def gen_wm_snake_swamp():
    img = create_transparent(48, 48)
    draw = ImageDraw.Draw(img)
    # Murky purple water
    draw.ellipse([6, 24, 42, 44], fill=PALETTE["void_dark"], outline=PALETTE["night_shadow"])
    # Serpent skull/coils
    draw.arc([16, 26, 32, 40], 0, 180, fill=PALETTE["stone_light"], width=3)
    draw.point([(22, 28), (26, 28)], fill=PALETTE["coral_light"]) # Glowing eyes
    return img

def gen_wm_sword_grave():
    img = create_transparent(48, 48)
    draw = ImageDraw.Draw(img)
    # Crag mountain
    draw.polygon([(8, 44), (24, 20), (40, 44)], fill=PALETTE["stone_dark"])
    # Broken swords plunged into summit
    draw.line([(24, 10), (24, 30)], fill=PALETTE["white_cloth"], width=2)
    draw.line([(21, 16), (27, 16)], fill=PALETTE["gold_mid"])
    draw.line([(16, 22), (20, 34)], fill=PALETTE["slate_light"], width=2)
    return img

def gen_wm_combat_peak():
    img = create_transparent(48, 48)
    draw = ImageDraw.Draw(img)
    # Soaring Peak with Lightning
    draw.polygon([(4, 44), (24, 12), (44, 44)], fill=PALETTE["azure_deep"])
    draw.polygon([(12, 44), (24, 16), (36, 44)], fill=PALETTE["azure_mid"])
    # Lightning flash
    draw.line([(22, 8), (25, 18), (21, 22), (26, 30)], fill=PALETTE["lantern_light"], width=2)
    return img

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    buildings_dir = os.path.join(base_dir, "wuxia", "32", "buildings")
    nature_dir = os.path.join(base_dir, "wuxia", "32", "nature")
    landmarks_dir = os.path.join(base_dir, "wuxia", "32", "landmarks")

    os.makedirs(buildings_dir, exist_ok=True)
    os.makedirs(nature_dir, exist_ok=True)
    os.makedirs(landmarks_dir, exist_ok=True)

    targets = [
        # Buildings
        (gen_gate_tam_quan, os.path.join(buildings_dir, "gate_tam_quan.png")),
        (gen_sect_palace_hall, os.path.join(buildings_dir, "sect_palace_hall.png")),
        (gen_alchemy_hall, os.path.join(buildings_dir, "alchemy_hall.png")),
        (gen_tavern_inn, os.path.join(buildings_dir, "tavern_inn.png")),
        (gen_blacksmith_forge, os.path.join(buildings_dir, "blacksmith_forge.png")),
        (gen_market_pavilion, os.path.join(buildings_dir, "market_pavilion.png")),
        (gen_courtyard_house, os.path.join(buildings_dir, "courtyard_house.png")),
        (gen_moonlight_pavilion, os.path.join(buildings_dir, "moonlight_pavilion.png")),
        
        # Nature & Dungeon
        (gen_bamboo_cluster, os.path.join(nature_dir, "bamboo_cluster.png")),
        (gen_ancient_pine, os.path.join(nature_dir, "ancient_pine.png")),
        (gen_cavern_entrance, os.path.join(nature_dir, "cavern_entrance.png")),
        (gen_sword_monolith, os.path.join(nature_dir, "sword_monolith.png")),
        (gen_swamp_shrine, os.path.join(nature_dir, "swamp_shrine.png")),

        # World Map Landmarks
        (gen_wm_thanh_tri_tran, os.path.join(landmarks_dir, "wm_thanh_tri_tran.png")),
        (gen_wm_bamboo_forest, os.path.join(landmarks_dir, "wm_bamboo_forest.png")),
        (gen_wm_snake_swamp, os.path.join(landmarks_dir, "wm_snake_swamp.png")),
        (gen_wm_sword_grave, os.path.join(landmarks_dir, "wm_sword_grave.png")),
        (gen_wm_combat_peak, os.path.join(landmarks_dir, "wm_combat_peak.png"))
    ]

    print(f"Generating {len(targets)} Wuxia pixel art graphics...")
    for gen_fn, out_path in targets:
        img = gen_fn()
        img.save(out_path, "PNG")
        print(f"  -> Generated {out_path} ({img.size[0]}x{img.size[1]})")

    print("[SUCCESS] All Wuxia graphics successfully synthesized!")

if __name__ == "__main__":
    main()
