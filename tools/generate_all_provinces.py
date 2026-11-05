import json
import os
from pathlib import Path

root = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT")
provinces_dir = root / "data/world/provinces"

provinces_def = {
    "ty_chau": {
        "display_name": "Tý Châu",
        "theme": "Sông ngòi, cảng biển, mậu dịch thủy",
        "capital": "Cảng Thủy Kính",
        "governor": "npc_ty_quan_01",
        "neighbors": ["thin_chau", "suu_chau", "hoi_chau"],
        "bg_color": [0.08, 0.22, 0.24],
        "water_color": [0.15, 0.35, 0.50],
        "sect": "Thủy Vân Tông",
        "settlements": [
            {"id": "settlement_thuy_kinh", "name": "Cảng Thủy Kính", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_van_ngu", "name": "Chợ Vạn Ngư", "type": "town", "chunk": [24, 32], "pos": [1024, 1024]},
            {"id": "settlement_hai_phong", "name": "Huyện Hải Phong", "type": "county", "chunk": [32, 20], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_thuy_kinh", "name": "Bến Thuyền Thủy Kính", "chunk": [32, 32], "pos": [900, 1100], "cost": 15, "target": "thin_chau"},
            {"id": "st_van_ngu", "name": "Dịch Trạm Vạn Ngư", "chunk": [24, 32], "pos": [900, 1100], "cost": 10, "target": "ty_chau"}
        ],
        "landmarks": [
            {"id": "lm_thuy_ngoc_dao", "name": "Thủy Ngọc Đảo Bí Cảnh", "chunk": [32, 28], "type": "sanctuary"},
            {"id": "lm_tram_tich_hai_vuc", "name": "Trầm Tích Hải Vực", "chunk": [40, 32], "type": "danger"}
        ]
    },
    "suu_chau": {
        "display_name": "Sửu Châu",
        "theme": "Đồng bằng phì nhiêu, lương thực, chăn nuôi",
        "capital": "Huyện Thành Phong Hòa",
        "governor": "npc_suu_quan_01",
        "neighbors": ["thin_chau", "ty_chau", "dan_chau"],
        "bg_color": [0.22, 0.26, 0.14],
        "water_color": [0.18, 0.32, 0.40],
        "sect": "Bách Thảo Môn Phân Viện",
        "settlements": [
            {"id": "settlement_phong_hoa", "name": "Huyện Thành Phong Hòa", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_linh_nguu", "name": "Trại Nuôi Linh Ngưu", "type": "town", "chunk": [32, 40], "pos": [1024, 1024]},
            {"id": "settlement_dong_dien", "name": "Thôn Đồng Điền", "type": "village", "chunk": [26, 32], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_phong_hoa", "name": "Ngựa Trạm Phong Hòa", "chunk": [32, 32], "pos": [900, 1100], "cost": 15, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_thao_nguyen_linh_mach", "name": "Linh Mạch Ruộng Lúa Vàng", "chunk": [30, 30], "type": "resource"}
        ]
    },
    "dan_chau": {
        "display_name": "Dần Châu",
        "theme": "Sơn lâm, săn bắn dã thú, quặng sắt",
        "capital": "Sơn Trấn Hổ Khiếu",
        "governor": "npc_dan_quan_01",
        "neighbors": ["thin_chau", "suu_chau", "mao_chau"],
        "bg_color": [0.18, 0.16, 0.12],
        "water_color": [0.15, 0.28, 0.35],
        "sect": "Phách Đao Môn",
        "settlements": [
            {"id": "settlement_ho_khieu", "name": "Sơn Trấn Hổ Khiếu", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_tho_san", "name": "Trại Thợ Săn Lĩnh Nam", "type": "village", "chunk": [22, 32], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_ho_khieu", "name": "Dịch Trạm Hổ Khiếu", "chunk": [32, 32], "pos": [900, 1100], "cost": 20, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_ho_khieu_nhai", "name": "Hổ Khiếu Nhai Thần Vực", "chunk": [32, 24], "type": "danger"}
        ]
    },
    "mao_chau": {
        "display_name": "Mão Châu",
        "theme": "Rừng ngọc trúc, hàn lâm viện học thuật, đan dược",
        "capital": "Hàn Lâm Thành",
        "governor": "npc_mao_quan_01",
        "neighbors": ["thin_chau", "dan_chau", "ngo_chau"],
        "bg_color": [0.08, 0.24, 0.12],
        "water_color": [0.12, 0.30, 0.45],
        "sect": "Đan Hà Tông",
        "settlements": [
            {"id": "settlement_han_lam", "name": "Hàn Lâm Thành", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_duoc_vuong", "name": "Dược Vương Cốc Trấn", "type": "town", "chunk": [32, 22], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_han_lam", "name": "Trạm Ngựa Hàn Lâm", "chunk": [32, 32], "pos": [900, 1100], "cost": 20, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_ngoc_truc_van_lam", "name": "Ngọc Trúc Vạn Lâm Trận", "chunk": [30, 26], "type": "sanctuary"}
        ]
    },
    "ty_ran_chau": {
        "display_name": "Tỵ Châu",
        "theme": "Vạn Độc Trạch, sương mù tím, ma đạo tà tu",
        "capital": "U Hồn Trấn",
        "governor": "npc_ty_ran_quan_01",
        "neighbors": ["thin_chau", "ngo_chau", "mui_chau"],
        "bg_color": [0.16, 0.10, 0.20],
        "water_color": [0.25, 0.12, 0.35],
        "sect": "Thiên Độc Môn",
        "settlements": [
            {"id": "settlement_u_hon", "name": "U Hồn Trấn", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_doc_mon", "name": "Độc Đan Các", "type": "town", "chunk": [32, 42], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_u_hon", "name": "Dịch Trạm U Hồn", "chunk": [32, 32], "pos": [900, 1100], "cost": 25, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_xa_than_co_mieu", "name": "Miếu Xà Thần Cổ Tế Đàn", "chunk": [34, 30], "type": "danger"}
        ]
    },
    "ngo_chau": {
        "display_name": "Ngọ Châu",
        "theme": "Thảo nguyên mênh mông, ngựa chiến, thương đội",
        "capital": "Phong Mã Thành",
        "governor": "npc_ngo_quan_01",
        "neighbors": ["thin_chau", "mao_chau", "ty_ran_chau"],
        "bg_color": [0.14, 0.28, 0.14],
        "water_color": [0.14, 0.32, 0.48],
        "sect": "Phi Yến Môn",
        "settlements": [
            {"id": "settlement_phong_ma", "name": "Phong Mã Thành", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_thien_ma_trang", "name": "Thiên Mã Trang", "type": "town", "chunk": [22, 32], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_phong_ma", "name": "Ngự Mã Dịch Phong Mã", "chunk": [32, 32], "pos": [900, 1100], "cost": 20, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_thao_nguyen_dien_vo", "name": "Thảo Nguyên Diễn Võ Đài", "chunk": [28, 28], "type": "sanctuary"}
        ]
    },
    "mui_chau": {
        "display_name": "Mùi Châu",
        "theme": "Cao nguyên đất đỏ, tuyết dương mục trường",
        "capital": "Lạc Hà Trấn",
        "governor": "npc_mui_quan_01",
        "neighbors": ["thin_chau", "ty_ran_chau", "than_chau"],
        "bg_color": [0.24, 0.16, 0.12],
        "water_color": [0.20, 0.28, 0.38],
        "sect": "Tuyết Sơn Các",
        "settlements": [
            {"id": "settlement_lac_ha", "name": "Lạc Hà Trấn", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_bach_duong", "name": "Bạch Dương Thôn", "type": "village", "chunk": [40, 32], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_lac_ha", "name": "Dịch Trạm Lạc Hà", "chunk": [32, 32], "pos": [900, 1100], "cost": 25, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_ngoc_son_dinh", "name": "Ngọc Sơn Đỉnh Thần Điện", "chunk": [32, 20], "type": "sanctuary"}
        ]
    },
    "than_chau": {
        "display_name": "Thân Châu",
        "theme": "Núi non mây phủ, tàn tích cơ quan, di chỉ cổ",
        "capital": "Thiên Cơ Thành",
        "governor": "npc_than_quan_01",
        "neighbors": ["thin_chau", "mui_chau", "dau_chau"],
        "bg_color": [0.18, 0.18, 0.22],
        "water_color": [0.16, 0.26, 0.40],
        "sect": "Vô Cực Cơ Quan Các",
        "settlements": [
            {"id": "settlement_thien_co", "name": "Thiên Cơ Thành", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_hau_vuong", "name": "Hầu Vương Cốc", "type": "town", "chunk": [32, 42], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_thien_co", "name": "Dịch Trạm Thiên Cơ", "chunk": [32, 32], "pos": [900, 1100], "cost": 25, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_co_quan_tran_phue_tich", "name": "Phế Tích Cổ Cơ Quan Trận", "chunk": [24, 32], "type": "danger"}
        ]
    },
    "dau_chau": {
        "display_name": "Dậu Châu",
        "theme": "Đô thị phường thợ, tiệm rèn bách binh, chợ ngọc",
        "capital": "Vạn Giác Phủ",
        "governor": "npc_dau_quan_01",
        "neighbors": ["thin_chau", "than_chau", "tuat_chau"],
        "bg_color": [0.22, 0.20, 0.16],
        "water_color": [0.18, 0.30, 0.42],
        "sect": "Luyện Khí Tông",
        "settlements": [
            {"id": "settlement_van_giac", "name": "Vạn Giác Phủ", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_kim_tinh", "name": "Kim Tinh Lâu Đô Thị", "type": "town", "chunk": [32, 22], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_van_giac", "name": "Dịch Trạm Vạn Giác", "chunk": [32, 32], "pos": [900, 1100], "cost": 20, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_van_kiem_lo", "name": "Vạn Kiếm Lò Thần Hỏa", "chunk": [34, 34], "type": "resource"}
        ]
    },
    "tuat_chau": {
        "display_name": "Tuất Châu",
        "theme": "Sa mạc biên ải, quan ải chiến lũy, phòng tuyến quân doanh",
        "capital": "Nhạn Môn Quan",
        "governor": "npc_tuat_quan_01",
        "neighbors": ["thin_chau", "dau_chau", "hoi_chau"],
        "bg_color": [0.30, 0.25, 0.16],
        "water_color": [0.20, 0.28, 0.32],
        "sect": "Thiết Huyết Quân Doanh",
        "settlements": [
            {"id": "settlement_nhan_mon", "name": "Nhạn Môn Quan", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_tran_bien", "name": "Trấn Biên Doanh", "type": "town", "chunk": [24, 32], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_nhan_mon", "name": "Chiến Mã Trạm Nhạn Môn", "chunk": [32, 32], "pos": [900, 1100], "cost": 30, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_bach_lang_coc", "name": "Bạch Lang Cốc Hung Hiểm", "chunk": [32, 18], "type": "danger"}
        ]
    },
    "hoi_chau": {
        "display_name": "Hợi Châu",
        "theme": "Vùng hồ lớn mênh mông, đảo sen hồng, thủy sản",
        "capital": "Thủy Nguyệt Thành",
        "governor": "npc_hoi_quan_01",
        "neighbors": ["thin_chau", "tuat_chau", "ty_chau"],
        "bg_color": [0.10, 0.22, 0.26],
        "water_color": [0.12, 0.40, 0.58],
        "sect": "Bích Ba Đảo Tiên Cung",
        "settlements": [
            {"id": "settlement_thuy_nguyet", "name": "Thủy Nguyệt Thành", "type": "capital", "chunk": [32, 32], "pos": [1024, 1024]},
            {"id": "settlement_phong_lo", "name": "Bến Phong Lộ", "type": "town", "chunk": [32, 42], "pos": [1024, 1024]}
        ],
        "stations": [
            {"id": "st_thuy_nguyet", "name": "Ngự Thuyền Trạm Thủy Nguyệt", "chunk": [32, 32], "pos": [900, 1100], "cost": 20, "target": "thin_chau"}
        ],
        "landmarks": [
            {"id": "lm_thai_ho_dao", "name": "Thái Hồ Liên Hoa Đảo", "chunk": [30, 30], "type": "sanctuary"}
        ]
    }
}

for pid, pdata in provinces_def.items():
    pdir = provinces_dir / pid
    pdir.mkdir(parents=True, exist_ok=True)
    
    # 1. province.json
    pjson = {
        "province_id": pid,
        "display_name": pdata["display_name"],
        "country_id": "dai_huyen",
        "theme": pdata["theme"],
        "status": "playable",
        "size_tiles": [4096, 4096],
        "tile_size_px": 32,
        "chunk_size_tiles": 64,
        "capital_city_id": pdata["settlements"][0]["id"],
        "governor_npc_id": pdata["governor"],
        "sect_name": pdata["sect"],
        "neighbor_provinces": pdata["neighbors"],
        "bg_color": pdata["bg_color"],
        "water_color": pdata["water_color"],
        "persistent_world_diffs": True
    }
    with open(pdir / "province.json", "w", encoding="utf-8") as f:
        json.dump(pjson, f, ensure_ascii=False, indent=2)
        
    # 2. settlements.json
    with open(pdir / "settlements.json", "w", encoding="utf-8") as f:
        json.dump({"province_id": pid, "settlements": pdata["settlements"]}, f, ensure_ascii=False, indent=2)
        
    # 3. fast_travel_stations.json
    with open(pdir / "fast_travel_stations.json", "w", encoding="utf-8") as f:
        json.dump({"province_id": pid, "stations": pdata["stations"]}, f, ensure_ascii=False, indent=2)
        
    # 4. landmarks.json
    with open(pdir / "landmarks.json", "w", encoding="utf-8") as f:
        json.dump({"province_id": pid, "landmarks": pdata["landmarks"]}, f, ensure_ascii=False, indent=2)
        
    # 5. roads_rivers.json
    rjson = {
        "province_id": pid,
        "main_roads": [
            {"name": "Trục Quan Lộ Trung Tâm", "axis": "x", "chunk": 32, "width_px": 128},
            {"name": "Đại Đạo Liên Huyện", "axis": "y", "chunk": 32, "width_px": 128}
        ],
        "rivers": [
            {"name": "Thủy Lưu Liên Châu", "start": [0, 68000], "end": [131072, 69000], "width_px": 220}
        ]
    }
    with open(pdir / "roads_rivers.json", "w", encoding="utf-8") as f:
        json.dump(rjson, f, ensure_ascii=False, indent=2)
        
    # Remove old flat json file if exists
    old_flat = provinces_dir / f"{pid}.json"
    if old_flat.exists():
        old_flat.unlink()
        
    print(f"Generated full data for {pid} ({pdata['display_name']})")

print("ALL 11 PROVINCES GENERATED SUCCESSFULLY!")
