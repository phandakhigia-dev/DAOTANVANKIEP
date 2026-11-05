class_name LifeGenerator
extends RefCounted

## LifeGenerator — Bộ máy phát sinh cuộc đời độc bản cho NPC (Procedural Fate Engine)
## Kiến tạo chiều sâu nhân vật: Khát vọng cốt lõi, Dị duyên/Bí mật, Thói quen cá nhân, Thọ nguyên ngắn/dài.

const SURNAMES: Array[String] = [
	"Lâm", "Diệp", "Tiêu", "Sở", "Cố", "Thẩm", "Tần", "Vương", "Lý", "Trần",
	"Hạ", "Mạc", "Bạch", "Bùi", "Đoàn", "Lục", "Tống", "Khương", "Nhan", "Ân",
	"Vũ", "Nghiêm", "Chúc", "Phó", "Hàn", "Kỷ", "Triệu", "Hứa", "Chung", "Phùng"
]

const MIDDLE_MALE: Array[String] = [
	"Thanh", "Phong", "Huyền", "Vân", "Minh", "Nhược", "Trực", "Bá", "Đạo", "Trần",
	"Trường", "Nhất", "Chí", "Duy", "Hạo", "Vĩnh", "Tử", "Tuấn", "Kỳ", "Thiên"
]

const MIDDLE_FEMALE: Array[String] = [
	"Tuyết", "Nguyệt", "Thanh", "Nhược", "Như", "Uyển", "Mộng", "Linh", "Thư", "Tố",
	"Ngọc", "Hàn", "Gia", "Yến", "Tiêu", "Phương", "Diệu", "Tâm", "Thu", "Lam"
]

const FIRST_MALE: Array[String] = [
	"Phong", "Vũ", "Hạo", "Lăng", "Thần", "Nham", "Kiếm", "Kình", "Khang", "Tùng",
	"Dương", "Nguyên", "Cơ", "Hằng", "Tiêu", "Kính", "Bình", "Cương", "Liệt", "Quang"
]

const FIRST_FEMALE: Array[String] = [
	"Dao", "Nguyệt", "Tuyết", "Nhi", "Sương", "Quyên", "Linh", "Hoa", "Vân", "Điệp",
	"Tâm", "Thường", "Dung", "Chi", "Trúc", "Khê", "Liên", "Cúc", "Vận", "Thương"
]

const CORE_DRIVES: Array[Dictionary] = [
	{
		"id": "drive_revenge",
		"title": "Báo Thù Huyết Hải",
		"desc": "Gia tộc bị tàn sát năm xưa, quyết tâm tu luyện chỉ vì tìm kiếm tung tích kẻ thù.",
		"dialogue": "Mối thù xưa chưa rửa, ta sao có thể dừng bước kiếm đạo?"
	},
	{
		"id": "drive_save_kin",
		"title": "Cứu Muội Muội Hoạn Nạn",
		"desc": "Muội muội duy nhất trúng hàn độc kỳ dị, luôn gom góp từng linh thạch tìm linh dược cứu mạng.",
		"dialogue": "Chỉ cần gom đủ linh thạch mua đan giải độc, muội muội ta sẽ bình an..."
	},
	{
		"id": "drive_immortality",
		"title": "Cầu Trường Sinh Vô Thượng",
		"desc": "Chứng kiến người phàm ngắn ngủi cát bụi, khát khao phá bỏ gông cùm thọ nguyên của trời đất.",
		"dialogue": "Trời cho ta mạng sống, ta quyết không cam lòng thành nắm tro tàn trong trăm năm!"
	},
	{
		"id": "drive_sword_mastery",
		"title": "Độc Cô Kiếm Khách",
		"desc": "Si mê kiếm thuật đến cuồng nhiệt, chỉ tìm kiếm đối thủ xứng tầm để mài giũa kiếm ý.",
		"dialogue": "Kiếm là tri kỷ, gió là bạn đường. Các hạ có hứng thú đọ một chiêu kiếm?"
	},
	{
		"id": "drive_wealth",
		"title": "Thương Lộ Thiên Hạ",
		"desc": "Xuất thân cơ hàn, tin rằng linh thạch và tài nguyên mới là gốc rễ của mọi con đường đại đạo.",
		"dialogue": "Không có linh thạch lót đường, thiên phú cao đến đâu cũng chỉ là phàm phu tục tử."
	},
	{
		"id": "drive_protect_love",
		"title": "Bảo Hộ Đạo Lữ",
		"desc": "Đã tìm được tri kỷ cuộc đời, mọi phấn đấu chỉ nhằm bảo bọc người thương giữa thời loạn thế.",
		"dialogue": "Tu tiên tranh đoạt làm chi, giữ được người bên cạnh bình an đã là đại phúc."
	}
]

const LIFE_SECRETS: Array[Dictionary] = [
	{
		"id": "secret_ancient_soul",
		"title": "Tàn Hồn Thượng Cổ",
		"desc": "Trong thức hải có một tàn hồn đại năng thượng cổ thỉnh thoảng tỉnh giấc truyền thụ khẩu quyết."
	},
	{
		"id": "secret_jade_token",
		"title": "Nửa Khối Ngọc Bội Định Tình",
		"desc": "Đang mang nửa miếng ngọc bội cổ xưa, tìm kiếm tung tích người thân thất lạc từ thuở ấu thơ."
	},
	{
		"id": "secret_expelled",
		"title": "Môn Quy Truất Xuất",
		"desc": "Từng là đệ tử danh môn nhưng bị kẻ ác vu oan trộm đan phương, phải dạt về làm tán tu lang bạt."
	},
	{
		"id": "secret_scar",
		"title": "Vết Sẹo Kiếm Chí Mạng",
		"desc": "Nơi ngực trái có vết kiếm sẹo sâu hoắm, vết tích của một lần suýt bỏ mạng tại Vân Lĩnh sơn mạch."
	},
	{
		"id": "secret_hidden_blood",
		"title": "Ẩn Tàng Huyết Mạch",
		"desc": "Thỉnh thoảng kinh mạch phát sốt, dường như mang một dòng máu dị tộc cổ xưa chưa thức tỉnh."
	}
]

const QUIRKS: Array[Dictionary] = [
	{
		"id": "quirk_sunset_wine",
		"title": "Rượu Chiều Hoàng Hôn",
		"desc": "Cứ giờ Dậu (chiều tà) là mang bầu rượu ra bờ kênh đào ngồi uống một mình ngắm ráng chiều.",
		"pref_object": "canal_bank"
	},
	{
		"id": "quirk_stingy_generous",
		"title": "Bủn Xỉn Nhưng Trọng Tình",
		"desc": "Mặc cả từng viên linh thạch ở chợ, nhưng sẵn sàng tặng bảo vật gia truyền cho tri kỷ vào sinh ra tử.",
		"pref_object": "market_stall"
	},
	{
		"id": "quirk_fear_thunder",
		"title": "Úy Lôi Kỵ Vũ",
		"desc": "Sợ sấm sét lôi kiếp do từng bị sét đánh cháy xém da thịt lúc nhỏ, trời mưa là núp trong quán trọ.",
		"pref_object": "bench"
	},
	{
		"id": "quirk_herb_collector",
		"title": "Tầm Thảo Si",
		"desc": "Thích sưu tập các nhành cỏ lạ ven đường, hay đi thơ thẩn gần giếng nước và gốc liễu.",
		"pref_object": "well"
	},
	{
		"id": "quirk_lantern_gazer",
		"title": "Thích Ngắm Đèn Đêm",
		"desc": "Đến đêm thích đứng trầm ngâm dưới ánh đèn lồng đá, nói rằng ánh sáng giúp lòng thanh tịnh.",
		"pref_object": "stone_lantern"
	}
]

## Sinh ngẫu nhiên một nhân vật hoàn chỉnh có số phận độc bản
static func generate_character(seed_val: int, index: int, role_hint: String = "") -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val + (index * 7919) # Dùng số nguyên tố để tạo entropy cao
	
	var is_female = (rng.randi() % 2 == 1)
	var surname = SURNAMES[rng.randi() % SURNAMES.size()]
	var mid = (MIDDLE_FEMALE if is_female else MIDDLE_MALE)[rng.randi() % (MIDDLE_FEMALE.size() if is_female else MIDDLE_MALE.size())]
	var first = (FIRST_FEMALE if is_female else FIRST_MALE)[rng.randi() % (FIRST_FEMALE.size() if is_female else FIRST_MALE.size())]
	var full_name = "%s %s %s" % [surname, mid, first]
	
	# Xác định dạng đời người (Cuộc đời ngắn vs Cuộc đời dài)
	var span_roll = rng.randf()
	var lifespan_type = "short"
	var max_lifespan = 40
	var current_age = 20
	var realm_id = "realm_pham_nhan"
	var realm_name = "Phàm Nhân"
	
	if span_roll < 0.45:
		# 1. Đoản Mệnh (45% dân số tán tu dã ngoại)
		lifespan_type = "short"
		max_lifespan = rng.randi_range(28, 48)
		current_age = rng.randi_range(16, max_lifespan - 4)
		realm_id = "realm_pham_nhan" if rng.randf() < 0.5 else "realm_luyen_khi_1"
		realm_name = "Phàm Nhân" if realm_id == "realm_pham_nhan" else "Luyện Khí Tầng 1"
	elif span_roll < 0.85:
		# 2. Thăng Trầm Trung Niên (40% thương nhân, tu sĩ ổn định)
		lifespan_type = "medium"
		max_lifespan = rng.randi_range(65, 110)
		current_age = rng.randi_range(24, 60)
		realm_id = "realm_luyen_khi_2" if rng.randf() < 0.6 else "realm_luyen_khi_3"
		realm_name = "Luyện Khí Tầng 2" if realm_id == "realm_luyen_khi_2" else "Luyện Khí Tầng 3"
	else:
		# 3. Trường Thọ / Ẩn Sĩ (15% cao thủ, đan sư, bô lão)
		lifespan_type = "long"
		max_lifespan = rng.randi_range(160, 280)
		current_age = rng.randi_range(50, 140)
		realm_id = "realm_truc_co_so_ky"
		realm_name = "Trúc Cơ Sơ Kỳ"
		
	var role = role_hint
	if role == "":
		var roles = ["Tán Tu Kiếm Khách", "Tiểu Thương Dạo", "Dược Đồng Tầm Thảo", "Thợ Săn Dã Ngoại", "Tu Sĩ Du Lịch", "Lão Tán Tu"]
		role = roles[rng.randi() % roles.size()]
		
	var drive = CORE_DRIVES[rng.randi() % CORE_DRIVES.size()]
	var secret = LIFE_SECRETS[rng.randi() % LIFE_SECRETS.size()]
	var quirk = QUIRKS[rng.randi() % QUIRKS.size()]
	
	# Sinh nhật ký biến cố đời người
	var chronicle: Array[String] = []
	chronicle.append("Năm %d tuổi: Rời quê nhà bước chân vào giang hồ Thanh Trì." % int(current_age * 0.4))
	chronicle.append("Năm %d tuổi: %s." % [int(current_age * 0.7), secret.title])
	if current_age > 28:
		chronicle.append("Năm %d tuổi: Lĩnh ngộ đạo tâm, lập chí '%s'." % [int(current_age * 0.85), drive.title])

	return {
		"id": "npc_gen_%d_%d" % [seed_val % 10000, index],
		"name": full_name,
		"gender": "female" if is_female else "male",
		"role": role,
		"realm_id": realm_id,
		"realm_name": realm_name,
		"lifespan_type": lifespan_type,
		"age_years": current_age,
		"max_lifespan_years": max_lifespan,
		"core_drive": drive,
		"life_secret": secret,
		"quirk": quirk,
		"chronicle": chronicle,
		"stones": rng.randi_range(15, 120),
		"pills": rng.randi_range(0, 3)
	}
