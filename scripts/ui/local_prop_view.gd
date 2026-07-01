class_name LocalPropView
extends PanelContainer

var prop_id: String = ""
var prop_label: String = ""
var prop_index: int = -1
var drag_enabled: bool = false
var drag_source: String = "test_prop"

var _label: Label
var _hint_label: Label


func _ready() -> void:
	_ensure_children()
	_refresh()


func set_prop(id: String, label_text: String, index: int, enabled: bool = true, source: String = "test_prop") -> void:
	prop_id = id
	prop_label = label_text
	prop_index = index
	drag_enabled = enabled
	drag_source = source
	mouse_filter = Control.MOUSE_FILTER_STOP if drag_enabled and prop_id != "" else Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	_refresh()


func clear_prop() -> void:
	prop_id = ""
	prop_label = ""
	prop_index = -1
	drag_enabled = false
	drag_source = "test_prop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	_refresh()


func _ensure_children() -> void:
	if _label != null:
		return

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", UiLayoutConfig.TEXT_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_label)

	_hint_label = Label.new()
	_hint_label.text = "道具"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.65))
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hint_label)


func _refresh() -> void:
	var border_color := Color.WHITE if prop_id != "" else Color(1, 1, 1, 0.55)
	var bg_color := Color(1, 1, 1, 0.88) if prop_id != "" else Color(1, 1, 1, 0.3)
	add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(bg_color, border_color, 2, 32))
	_label.text = prop_label
	_hint_label.visible = prop_id != ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not drag_enabled or prop_id == "":
		return null

	var preview_root := Control.new()
	preview_root.size = Vector2.ZERO
	var preview := LocalPropView.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.position = -size * 0.5
	preview.set_prop(prop_id, prop_label, prop_index, false, drag_source)
	preview_root.add_child(preview)
	set_drag_preview(preview_root)

	return {
		"source": drag_source,
		"prop_id": prop_id,
		"prop_index": prop_index
	}
