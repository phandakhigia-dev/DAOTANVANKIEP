import json
import os

provinces = [
    ("ty_chau", "Tý Châu", "Sông ngòi, cảng biển, mậu dịch thủy", ["thin_chau", "suu_chau", "hoi_chau"]),
    ("suu_chau", "Sửu Châu", "Đồng bằng phì nhiêu, nông nghiệp, kho lương", ["ty_chau", "dan_chau", "thin_chau"]),
    ("dan_chau", "Dần Châu", "Sơn lâm hiểm trở, săn thú, khoáng mạch", ["suu_chau", "mao_chau", "thin_chau"]),
    ("mao_chau", "Mão Châu", "Trúc lâm thanh tịnh, y dược, học viện", ["dan_chau", "thin_chau", "ty_ran_chau"]),
    ("ty_ran_chau", "Tỵ Châu", "Đầm lầy độc chướng, độc thảo, đan dược hắc thị", ["mao_chau", "thin_chau", "ngo_chau"]),
    ("ngo_chau", "Ngọ Châu", "Thảo nguyên bao la, tuấn mã, thương đội thảo nguyên", ["ty_ran_chau", "thin_chau", "mui_chau"]),
    ("mui_chau", "Mùi Châu", "Cao nguyên gió lộng, mục trường, thổ phỉ", ["ngo_chau", "thin_chau", "than_chau"]),
    ("than_chau", "Thân Châu", "Vạn trùng sơn sâu thẳm, cơ quan thuật, phế tích cổ", ["mui_chau", "thin_chau", "dau_chau"]),
    ("dau_chau", "Dậu Châu", "Phường thủ công, lò rèn pháp bảo, thương hội đấu giá", ["than_chau", "thin_chau", "tuat_chau"]),
    ("tuat_chau", "Tuất Châu", "Biên ải hùng quan, đồn trú quân doanh, phòng tuyến ma đạo", ["dau_chau", "thin_chau", "hoi_chau"]),
    ("hoi_chau", "Hợi Châu", "Vạn khoảnh đại hồ, ngư nghiệp, thủy quái và linh tuyền", ["tuat_chau", "thin_chau", "ty_chau"])
]

out_dir = r"G:\Game tự làm\DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT\data\world\provinces"
os.makedirs(out_dir, exist_ok=True)

for pid, name, theme, neighbors in provinces:
    data = {
        "province_id": pid,
        "display_name": name,
        "country_id": "dai_huyen",
        "theme": theme,
        "status": "metadata_only",
        "size_tiles": [4096, 4096],
        "tile_size_px": 32,
        "chunk_size_tiles": 64,
        "neighbor_provinces": neighbors
    }
    p_path = os.path.join(out_dir, f"{pid}.json")
    with open(p_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Created {p_path}")

print("Successfully generated 11 metadata provinces.")
