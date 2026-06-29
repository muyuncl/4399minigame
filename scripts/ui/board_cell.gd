class_name BoardCell
extends PanelContainer

signal card_dropped(hand_index: int, cell: Vector2i)

var cell: Vector2i = Vector2i.ZERO
var card_data: CardData = null
var drop_enabled: bool = true

var _center: CenterContainer
var _card_view: CardView
var _empty_label: Label


func _ready() -> void:
    custom_minimum_size = Vector2(116, 174)
    _ensure_children()
    _refresh()


func setup(board_cell: Vector2i) -> void:
    cell = board_cell
    tooltip_text = "第 %d 行，第 %d 列" % [cell.y + 1, cell.x + 1]


func set_card(card: CardData) -> void:
    card_data = card
    _ensure_children()
    _refresh()


func set_drop_enabled(enabled: bool) -> void:
    drop_enabled = enabled


func play_drop_event(event: Dictionary) -> void:
    if card_data == null or not _card_view.visible:
        return

    var tween := create_tween()
    tween.tween_property(_card_view, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(_card_view, "rotation", deg_to_rad(4.0), 0.08)
    await tween.finished

    var next_value := int(event.get("to", 0))
    if bool(event.get("removed", false)):
        _card_view.set_visual_value(0)
        var vanish := create_tween()
        vanish.tween_property(_card_view, "scale", Vector2(0.15, 0.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
        vanish.parallel().tween_property(_card_view, "modulate", Color(1, 1, 1, 0), 0.12)
        await vanish.finished
        card_data = null
        _card_view.visible = false
        _card_view.modulate.a = 1.0
        _card_view.scale = Vector2.ONE
        _empty_label.visible = true
        return
    else:
        _card_view.set_visual_value(next_value)

    var settle := create_tween()
    settle.tween_property(_card_view, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    settle.parallel().tween_property(_card_view, "rotation", 0.0, 0.09)
    await settle.finished


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return drop_enabled and card_data == null and typeof(data) == TYPE_DICTIONARY and data.get("source", "") == "hand"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
    if _can_drop_data(_at_position, data):
        card_dropped.emit(int(data.get("hand_index", -1)), cell)


func _ensure_children() -> void:
    if _card_view != null:
        return

    _empty_label = Label.new()
    _empty_label.text = "+"
    _empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _empty_label.add_theme_font_size_override("font_size", 26)
    _empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _center = CenterContainer.new()
    _center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_center)
    _center.add_child(_empty_label)

    _card_view = CardView.new()
    _card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _card_view.custom_minimum_size = CardView.CARD_SIZE
    _center.add_child(_card_view)


func _refresh() -> void:
    _apply_cell_style()
    if card_data == null:
        _empty_label.visible = true
        _card_view.visible = false
        _empty_label.add_theme_color_override("font_color", Color(0.57, 0.36, 0.21, 0.45))
    else:
        _empty_label.visible = false
        _card_view.visible = true
        _card_view.modulate.a = 1.0
        _card_view.scale = Vector2.ONE
        _card_view.rotation = 0.0
        _card_view.set_card(card_data, -1, false)


func _apply_cell_style() -> void:
    var style := StyleBoxFlat.new()
    var is_bonus := cell.x == 0 or cell.y == 0
    style.bg_color = Color(0.88, 0.58, 0.34)
    if cell.x == 0 or cell.y == 0:
        style.bg_color = Color(0.79, 0.48, 0.25)
    style.border_color = Color(0.77, 0.43, 0.22) if not is_bonus else Color(0.64, 0.32, 0.17)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 0
    style.corner_radius_top_right = 0
    style.corner_radius_bottom_left = 0
    style.corner_radius_bottom_right = 0
    add_theme_stylebox_override("panel", style)
