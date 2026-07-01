class_name LocalBoardCell
extends PanelContainer

signal card_dropped(card_index: int, cell: Vector2i)
signal prop_dropped(prop_id: String, prop_index: int, cell: Vector2i)

var cell: Vector2i = Vector2i.ZERO
var card_data: PvpCardData = null
var drop_enabled: bool = false

var _card_view: LocalCardView
var _bonus_label: Label


func setup(cell_value: Vector2i) -> void:
	cell = cell_value
	_build_children()
	_apply_style()


func set_drop_enabled(enabled: bool) -> void:
	drop_enabled = enabled


func set_card(card: PvpCardData) -> void:
	card_data = card
	_build_children()
	if card_data == null:
		_card_view.clear_card()
		_card_view.visible = false
	else:
		_card_view.visible = true
		_card_view.set_card(card_data, true)
		_card_view.set_interaction(false, false)


func play_drop_event(event: Dictionary) -> void:
	if card_data == null or not _card_view.visible:
		return

	_card_view.set_visual_value(int(event.get("from", card_data.value)))
	_card_view.pivot_offset = _card_view.size * 0.5
	var punch := create_tween()
	punch.tween_property(_card_view, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.parallel().tween_property(_card_view, "modulate", Color(1.25, 1.25, 1.25, 1), 0.08)
	await punch.finished

	var next_value: int = int(event.get("to", 0))
	if bool(event.get("removed", false)):
		_card_view.set_visual_value(0)
		var vanish := create_tween()
		vanish.tween_property(_card_view, "scale", Vector2(0.1, 0.1), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		vanish.parallel().tween_property(_card_view, "modulate", Color(1, 1, 1, 0), 0.14)
		await vanish.finished
		card_data = null
		_card_view.visible = false
		_card_view.scale = Vector2.ONE
		_card_view.modulate = Color.WHITE
		return

	_card_view.set_visual_value(next_value)
	var settle := create_tween()
	settle.tween_property(_card_view, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.parallel().tween_property(_card_view, "modulate", Color.WHITE, 0.1)
	await settle.finished


func _build_children() -> void:
	if _card_view != null:
		return

	_bonus_label = Label.new()
	_bonus_label.text = "+1"
	_bonus_label.position = Vector2(8, 8)
	_bonus_label.add_theme_font_size_override("font_size", 16)
	_bonus_label.add_theme_color_override("font_color", Color(0.24, 0.24, 0.24, 0.65))
	_bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bonus_label)

	_card_view = LocalCardView.new()
	_card_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_view.visible = false
	_card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_view)


func _apply_style() -> void:
	var is_bonus: bool = cell.x == 0 or cell.y == 0
	var bg: Color = UiLayoutConfig.BOARD_BONUS_COLOR if is_bonus else UiLayoutConfig.BOARD_EMPTY_COLOR
	add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(bg, UiLayoutConfig.MUTED_LINE_COLOR, 1, 0))
	_bonus_label.visible = is_bonus


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var source := str(data.get("source", ""))
	if source in ["test_basket", "pvp_basket"]:
		return drop_enabled and card_data == null
	if source in ["test_prop", "pvp_prop"]:
		return card_data != null
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var source := str(data.get("source", ""))
	if source in ["test_prop", "pvp_prop"]:
		prop_dropped.emit(str(data.get("prop_id", "")), int(data.get("prop_index", -1)), cell)
	else:
		card_dropped.emit(int(data.get("card_index", -1)), cell)
