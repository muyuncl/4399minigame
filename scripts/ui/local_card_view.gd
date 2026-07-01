class_name LocalCardView
extends PanelContainer

signal card_clicked(card_view: LocalCardView)
signal card_drag_started(source: String, index: int, mouse_global_position: Vector2)

var card_data: PvpCardData = null
var compact: bool = false
var card_index: int = -1
var click_enabled: bool = false
var drag_enabled: bool = false
var drag_source: String = ""

var _art_rect: TextureRect
var _short_label: Label
var _value_label: Label
var _type_label: Label


func _ready() -> void:
	_ensure_children()
	_refresh()


func set_card(card: PvpCardData, use_compact_layout: bool = false) -> void:
	card_data = card
	compact = use_compact_layout
	custom_minimum_size = UiLayoutConfig.PUBLIC_POOL_CARD_SIZE if compact else UiLayoutConfig.BASKET_CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP if click_enabled or drag_enabled else Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	_refresh()


func set_visual_value(value: int) -> void:
	if card_data == null:
		return
	card_data.value = value
	_refresh()


func clear_card() -> void:
	card_data = null
	click_enabled = false
	drag_enabled = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	_refresh()


func set_interaction(clickable: bool, draggable: bool, source: String = "", index: int = -1) -> void:
	click_enabled = clickable
	drag_enabled = draggable
	drag_source = source
	card_index = index
	mouse_filter = Control.MOUSE_FILTER_STOP if click_enabled or drag_enabled else Control.MOUSE_FILTER_IGNORE


func _ensure_children() -> void:
	if _short_label != null:
		return

	mouse_filter = Control.MOUSE_FILTER_STOP if click_enabled or drag_enabled else Control.MOUSE_FILTER_IGNORE

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)

	_art_rect = TextureRect.new()
	_art_rect.custom_minimum_size = Vector2(44, 18)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_art_rect)

	_short_label = Label.new()
	_short_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_short_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_short_label.add_theme_font_size_override("font_size", 24)
	_short_label.add_theme_color_override("font_color", UiLayoutConfig.TEXT_COLOR)
	_short_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_short_label)

	_value_label = Label.new()
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_size_override("font_size", 26)
	_value_label.add_theme_color_override("font_color", UiLayoutConfig.TEXT_COLOR)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_value_label)

	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_type_label.add_theme_font_size_override("font_size", 14)
	_type_label.add_theme_color_override("font_color", UiLayoutConfig.TEXT_COLOR)
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_type_label)


func _refresh() -> void:
	var style := UiLayoutConfig.make_panel_style(UiLayoutConfig.CARD_COLOR, UiLayoutConfig.MUTED_LINE_COLOR, 1, 6)

	if card_data == null:
		add_theme_stylebox_override("panel", style)
		_short_label.text = ""
		_value_label.text = ""
		_type_label.text = ""
		return

	style.border_color = card_data.color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	add_theme_stylebox_override("panel", style)

	_short_label.text = card_data.short_label
	_value_label.text = str(card_data.value)
	_type_label.text = card_data.label
	_short_label.add_theme_color_override("font_color", card_data.color.darkened(0.25))

	if card_data.art_path != "" and ResourceLoader.exists(card_data.art_path):
		_art_rect.texture = load(card_data.art_path)
		_art_rect.visible = true
	else:
		_art_rect.texture = null
		_art_rect.visible = false


func _gui_input(event: InputEvent) -> void:
	if not click_enabled or card_data == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_clicked.emit(self)
			accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not drag_enabled or card_data == null:
		return null

	var preview_root := Control.new()
	preview_root.size = Vector2.ZERO
	var preview := LocalCardView.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.position = -size * 0.5
	preview.set_card(card_data.clone(), compact)
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	card_drag_started.emit(drag_source, card_index, get_global_mouse_position())

	return {
		"source": drag_source,
		"card_index": card_index,
		"card": card_data.clone()
	}
