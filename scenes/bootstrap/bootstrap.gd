extends Control

## Bootstrap — Khởi tạo hệ thống ban đầu và chuyển cảnh vào Menu chính

@onready var label_status: Label = $CenterContainer/VBoxContainer/LabelStatus
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	_init_game_sequence()

func _init_game_sequence() -> void:
	label_status.text = "Đang nạp định nghĩa thế giới..."
	progress_bar.value = 30
	await get_tree().create_timer(0.1).timeout
	
	ContentRegistry.load_all_content()
	progress_bar.value = 70
	label_status.text = "Đang kiểm tra dữ liệu lưu trữ..."
	await get_tree().create_timer(0.1).timeout
	
	progress_bar.value = 100
	label_status.text = "Khởi tạo thành công!"
	await get_tree().create_timer(0.1).timeout
	
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
