extends Node

func _ready() -> void:
	var demo = preload("res://wuxia/demo/canal_corner.tscn").instantiate()
	add_child(demo)
	await get_tree().create_timer(0.4).timeout
	var img = get_viewport().get_texture().get_image()
	if img:
		img.save_png("user://jianghu_demo_capture.png")
		print("[Demo] Screenshot saved successfully to user://jianghu_demo_capture.png!")
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0)
