extends Node

## AudioService — Quản lý Âm Thanh & Nhạc Nền Võ Hiệp (Phase 4: Wuxia Audio System)
## Quản lý Bus: Master, BGM, SFX, Ambience
## Tự tổng hợp âm thanh thủ tục (Procedural Xianxia Audio Synthesis):
## - Kiếm khí xé gió (Sword Slash)
## - Thiên Kiếp Lôi Đình (Lightning Strike)
## - Chuông Đồng Đốn Ngộ (Breakthrough Bell)
## - Nuốt Đan Dược (Pill Swallow)
## - Đan Lô Sôi Sục (Alchemy Bubble)
## - Thu Hái Linh Thảo (Herb Chime)
## - Chuông Môn Phái (Sect Gong)
## - Nhạc Nền Cổ Phong (Guzheng & Xiao Flute Pentatonic Ambient)

signal bgm_changed(track_id: String)
signal sfx_played(sound_id: String)

const SAMPLE_RATE: int = 22050

var master_volume: float = 0.8
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8
var ambience_volume: float = 0.6

var current_bgm_id: String = ""
var bgm_player: AudioStreamPlayer
var bgm_fade_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

# Pool các AudioStreamPlayer cho SFX
var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 12
var _pool_index: int = 0

# Cache âm thanh đã tổng hợp
var sound_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_synthesize_all_sounds()
	_connect_event_bus()

func _setup_audio_players() -> void:
	# BGM player chính
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	add_child(bgm_player)
	
	# BGM crossfade player phụ
	bgm_fade_player = AudioStreamPlayer.new()
	bgm_fade_player.name = "BGMFadePlayer"
	bgm_fade_player.bus = "Master"
	bgm_fade_player.volume_db = -80.0
	add_child(bgm_fade_player)
	
	# Ambience player
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.bus = "Master"
	ambience_player.volume_db = linear_to_db(ambience_volume * master_volume)
	add_child(ambience_player)
	
	# SFX Pool
	sfx_pool.clear()
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		p.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(p)
		sfx_pool.append(p)

func _connect_event_bus() -> void:
	if not EventBus:
		return
	
	if EventBus.has_signal("player_realm_changed"):
		EventBus.player_realm_changed.connect(func(_r): play_sfx("sfx_breakthrough_bell", 1.0, 3.0))
	
	if EventBus.has_signal("notification_requested"):
		EventBus.notification_requested.connect(func(_msg, type):
			if type == "success":
				play_sfx("sfx_herb_pickup", 1.1, -2.0)
			elif type == "error":
				play_sfx("sfx_footstep", 0.7, 0.0)
		)

# ==============================================================================
# PHÁT ÂM THANH (SFX & BGM API)
# ==============================================================================

func play_sfx(sound_id: String, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> AudioStreamPlayer:
	if not sound_cache.has(sound_id):
		# Nếu chưa có trong cache, thử tổng hợp tức thì
		_synthesize_sound(sound_id)
		
	if not sound_cache.has(sound_id):
		return null
		
	var stream: AudioStream = sound_cache[sound_id]
	var player = _get_available_sfx_player()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sfx_volume * master_volume) + volume_offset_db
	player.play()
	
	sfx_played.emit(sound_id)
	return player

func play_bgm(track_id: String, _fade_duration: float = 1.0) -> void:
	if current_bgm_id == track_id and bgm_player.playing:
		return
		
	current_bgm_id = track_id
	if not sound_cache.has(track_id):
		_synthesize_sound(track_id)
		
	if sound_cache.has(track_id):
		bgm_player.stream = sound_cache[track_id]
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()
		bgm_changed.emit(track_id)

func stop_bgm() -> void:
	current_bgm_id = ""
	if bgm_player:
		bgm_player.stop()

func play_ambience(track_id: String) -> void:
	if not sound_cache.has(track_id):
		_synthesize_sound(track_id)
		
	if sound_cache.has(track_id) and ambience_player:
		ambience_player.stream = sound_cache[track_id]
		ambience_player.volume_db = linear_to_db(ambience_volume * master_volume)
		ambience_player.play()

func stop_ambience() -> void:
	if ambience_player:
		ambience_player.stop()

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_update_all_volumes()

func set_bgm_volume(vol: float) -> void:
	bgm_volume = clampf(vol, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_update_all_volumes()

func set_ambience_volume(vol: float) -> void:
	ambience_volume = clampf(vol, 0.0, 1.0)
	if ambience_player:
		ambience_player.volume_db = linear_to_db(ambience_volume * master_volume)

func _update_all_volumes() -> void:
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	if ambience_player:
		ambience_player.volume_db = linear_to_db(ambience_volume * master_volume)
	for p in sfx_pool:
		if is_instance_valid(p):
			p.volume_db = linear_to_db(sfx_volume * master_volume)

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Tìm player đang rảnh trong pool
	for p in sfx_pool:
		if not p.playing:
			return p
	# Nếu tất cả đang bận, cướp vòng lặp
	var p = sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % SFX_POOL_SIZE
	return p

# ==============================================================================
# BỘ TỔNG HỢP ÂM THANH THỦ TỤC VÕ HIỆP (PROCEDURAL AUDIO SYNTHESIS)
# ==============================================================================

func _synthesize_all_sounds() -> void:
	var sound_list = [
		"sfx_sword_slash",
		"sfx_lightning_strike",
		"sfx_breakthrough_bell",
		"sfx_pill_swallow",
		"sfx_alchemy_bubble",
		"sfx_herb_pickup",
		"sfx_sect_chime",
		"sfx_footstep",
		"bgm_peaceful_town",
		"bgm_bamboo_forest",
		"bgm_tribulation"
	]
	for s_id in sound_list:
		_synthesize_sound(s_id)

func _synthesize_sound(sound_id: String) -> void:
	if sound_cache.has(sound_id):
		return
		
	var wav: AudioStreamWAV = null
	match sound_id:
		"sfx_sword_slash":
			wav = _generate_sword_slash_wav()
		"sfx_lightning_strike":
			wav = _generate_lightning_strike_wav()
		"sfx_breakthrough_bell":
			wav = _generate_bell_chime_wav()
		"sfx_pill_swallow":
			wav = _generate_pill_swallow_wav()
		"sfx_alchemy_bubble":
			wav = _generate_alchemy_bubble_wav()
		"sfx_herb_pickup":
			wav = _generate_herb_pickup_wav()
		"sfx_sect_chime":
			wav = _generate_sect_gong_wav()
		"sfx_footstep":
			wav = _generate_footstep_wav()
		"bgm_peaceful_town":
			wav = _generate_peaceful_town_bgm()
		"bgm_bamboo_forest":
			wav = _generate_bamboo_forest_bgm()
		"bgm_tribulation":
			wav = _generate_tribulation_bgm()
			
	if wav:
		sound_cache[sound_id] = wav

# --- 1. Tiếng Kiếm Khí Xé Gió (Metallic Slash) ---
func _generate_sword_slash_wav() -> AudioStreamWAV:
	var duration = 0.22
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		# Tần số quét nhanh từ 1400Hz xuống 280Hz
		var freq = lerpf(1400.0, 280.0, t / duration)
		phase += 2.0 * PI * freq / float(SAMPLE_RATE)
		# Tiếng rít kiếm kim loại + chút nhiễu gió
		var tone = sin(phase) * 0.7 + sin(phase * 2.3) * 0.3
		var noise = (randf() * 2.0 - 1.0) * 0.25
		var env = exp(-t * 18.0) * (1.0 - t / duration)
		var s = (tone + noise) * env * 0.8
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 2. Tiếng Thiên Kiếp Lôi Đình (Thunder & Crackle) ---
func _generate_lightning_strike_wav() -> AudioStreamWAV:
	var duration = 0.75
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var rumble_phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		rumble_phase += 2.0 * PI * 65.0 / float(SAMPLE_RATE)
		# Sấm trầm + tia chớp nổ
		var rumble = sin(rumble_phase) * exp(-t * 4.5)
		var crackle = 0.0
		if t < 0.15:
			# Tiếng nổ xé toạc bầu trời ở đầu
			crackle = (randf() * 2.0 - 1.0) * (1.0 - t / 0.15) * 1.0
		else:
			crackle = (randf() * 2.0 - 1.0) * exp(-t * 6.0) * 0.4
		var s = (rumble * 0.6 + crackle * 0.7) * 0.9
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 3. Tiếng Chuông Đồng Đốn Ngộ (Resonant Bronze Bell) ---
func _generate_bell_chime_wav() -> AudioStreamWAV:
	var duration = 1.8
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p1: float = 0.0
	var p2: float = 0.0
	var p3: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		# Hòa âm chuông đồng: 528Hz (tần số chữa lành), 1056Hz, 1584Hz
		p1 += 2.0 * PI * 528.0 / float(SAMPLE_RATE)
		p2 += 2.0 * PI * 1056.0 / float(SAMPLE_RATE)
		p3 += 2.0 * PI * 1584.0 / float(SAMPLE_RATE)
		var wave = sin(p1) * 0.6 + sin(p2) * 0.25 + sin(p3) * 0.15
		var env = exp(-t * 2.2)
		var s = wave * env * 0.85
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 4. Tiếng Nuốt Đan Dược (Pill Swallow Chime) ---
func _generate_pill_swallow_wav() -> AudioStreamWAV:
	var duration = 0.28
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var freq = lerpf(380.0, 720.0, t / duration)
		p += 2.0 * PI * freq / float(SAMPLE_RATE)
		var wave = sin(p) * 0.8 + sin(p * 2.0) * 0.2
		var env = sin(t / duration * PI) * exp(-t * 4.0)
		var s = wave * env * 0.75
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 5. Tiếng Đan Lô Sôi Sục (Alchemy Bubble) ---
func _generate_alchemy_bubble_wav() -> AudioStreamWAV:
	var duration = 0.35
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var freq = 320.0 + sin(t * 45.0) * 160.0
		p += 2.0 * PI * freq / float(SAMPLE_RATE)
		var wave = sin(p)
		var env = (1.0 - t / duration) * (sin(t * 80.0) * 0.5 + 0.5)
		var s = wave * env * 0.6
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 6. Tiếng Hái Dược / Nhặt Bảo Vật (Herb Chime) ---
func _generate_herb_pickup_wav() -> AudioStreamWAV:
	var duration = 0.25
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		p1 += 2.0 * PI * 880.0 / float(SAMPLE_RATE)
		p2 += 2.0 * PI * 1320.0 / float(SAMPLE_RATE)
		var wave = sin(p1) * 0.6 + sin(p2) * 0.4
		var env = exp(-t * 12.0)
		var s = wave * env * 0.7
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 7. Tiếng Chuông Môn Phái Ngân Vang (Sect Gong) ---
func _generate_sect_gong_wav() -> AudioStreamWAV:
	var duration = 2.2
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		p1 += 2.0 * PI * 330.0 / float(SAMPLE_RATE)
		p2 += 2.0 * PI * 660.0 / float(SAMPLE_RATE)
		var wave = sin(p1) * 0.7 + sin(p2) * 0.3
		var env = exp(-t * 1.8)
		var s = wave * env * 0.8
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 8. Tiếng Bước Chân Trên Phiến Đá (Footstep) ---
func _generate_footstep_wav() -> AudioStreamWAV:
	var duration = 0.08
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var p: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		p += 2.0 * PI * 140.0 / float(SAMPLE_RATE)
		var tone = sin(p) * 0.4
		var noise = (randf() * 2.0 - 1.0) * 0.6
		var env = 1.0 - (t / duration)
		var s = (tone + noise) * env * 0.5
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, false)

# --- 9. Nhạc Nền Thị Trấn Thanh Trì (Guzheng Pentatonic) ---
func _generate_peaceful_town_bgm() -> AudioStreamWAV:
	var duration = 6.0 # Lặp 6 giây âm điệu ngũ cung
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	# Điệu thức Ngũ Cung: D (293Hz), E (329Hz), F# (369Hz), A (440Hz), B (493Hz)
	var notes = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33]
	var note_dur = 0.75
	
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = int(t / note_dur) % notes.size()
		var note_t = fmod(t, note_dur)
		var freq = notes[note_idx]
		
		var p = 2.0 * PI * freq * note_t
		var tone = sin(p) * 0.6 + sin(p * 2.0) * 0.25 + sin(p * 3.0) * 0.15
		var env = exp(-note_t * 3.5)
		var s = tone * env * 0.35
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, true)

# --- 10. Nhạc Nền Rừng Trúc Vạn Lĩnh (Xiao Bamboo Flute) ---
func _generate_bamboo_forest_bgm() -> AudioStreamWAV:
	var duration = 6.0
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var notes = [329.63, 369.99, 440.0, 493.88, 659.25]
	var note_dur = 1.2
	
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_idx = int(t / note_dur) % notes.size()
		var note_t = fmod(t, note_dur)
		var freq = notes[note_idx]
		
		# Âm thanh sáo trúc: sóng sin mềm + rung nhẹ vibrato
		var vibrato = sin(note_t * 30.0) * 4.0
		var p = 2.0 * PI * (freq + vibrato) * note_t
		var breath = (randf() * 2.0 - 1.0) * 0.08 # Hơi thở sáo
		var tone = sin(p) * 0.75 + sin(p * 2.0) * 0.15 + breath
		var env = sin(note_t / note_dur * PI)
		var s = tone * env * 0.3
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, true)

# --- 11. Nhạc Nền Thiên Kiếp / Chiến Đấu Tinh Anh (Drums & Low Drone) ---
func _generate_tribulation_bgm() -> AudioStreamWAV:
	var duration = 4.0
	var num_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	var drum_interval = 0.5
	
	for i in range(num_samples):
		var t = float(i) / float(SAMPLE_RATE)
		var drum_t = fmod(t, drum_interval)
		
		# Tiếng trống trận dồn dập
		var drum_freq = lerpf(90.0, 45.0, drum_t / drum_interval)
		var drum_p = 2.0 * PI * drum_freq * drum_t
		var drum = sin(drum_p) * exp(-drum_t * 12.0)
		
		# Tiếng drone u trầm huyền bí
		var drone = sin(2.0 * PI * 55.0 * t) * 0.25
		var s = (drum * 0.6 + drone * 0.3) * 0.5
		_write_s16(bytes, i * 2, s)
		
	return _create_wav_from_bytes(bytes, true)

# ==============================================================================
# HÀM BỔ TRỢ GHI BYTE PCM
# ==============================================================================

func _write_s16(bytes: PackedByteArray, offset: int, float_val: float) -> void:
	var clamped = clampf(float_val, -1.0, 1.0)
	var sample_int = int(clamped * 32767.0)
	var b0 = sample_int & 0xFF
	var b1 = (sample_int >> 8) & 0xFF
	bytes[offset] = b0
	bytes[offset + 1] = b1

func _create_wav_from_bytes(bytes: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = bytes.size() / 2
	else:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav
