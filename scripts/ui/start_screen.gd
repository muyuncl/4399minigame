extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)

	var title := Label.new()
	title.text = "Minigame PVP Demo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Local two-player layout prototype"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	box.add_child(subtitle)

	var start_button := Button.new()
	start_button.text = "查看本地对战主界面"
	start_button.custom_minimum_size = UiLayoutConfig.START_BUTTON_SIZE
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.pressed.connect(_on_start_pressed)
	box.add_child(start_button)

	var test_button := Button.new()
	test_button.text = "测试入口：抢牌与放置"
	test_button.custom_minimum_size = UiLayoutConfig.START_BUTTON_SIZE
	test_button.add_theme_font_size_override("font_size", 28)
	test_button.pressed.connect(_on_test_pressed)
	box.add_child(test_button)

	var pvp_test_button := Button.new()
	pvp_test_button.text = "PVP测试入口"
	pvp_test_button.custom_minimum_size = UiLayoutConfig.START_BUTTON_SIZE
	pvp_test_button.add_theme_font_size_override("font_size", 28)
	pvp_test_button.pressed.connect(_on_pvp_test_pressed)
	box.add_child(pvp_test_button)

	var pvp_lan_button := Button.new()
	pvp_lan_button.text = "PVP双端联机"
	pvp_lan_button.custom_minimum_size = UiLayoutConfig.START_BUTTON_SIZE
	pvp_lan_button.add_theme_font_size_override("font_size", 28)
	pvp_lan_button.pressed.connect(_on_pvp_lan_pressed)
	box.add_child(pvp_lan_button)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/local_match.tscn")


func _on_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/card_flow_test.tscn")


func _on_pvp_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/pvp_network_test.tscn")


func _on_pvp_lan_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/pvp_lan_network.tscn")
