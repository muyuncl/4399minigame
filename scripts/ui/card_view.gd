class_name CardView
extends PanelContainer

signal manual_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2)

const CARD_SIZE := Vector2(88, 120)

var card_data: CardData = null
var hand_index: int = -1
var draggable: bool = true

var _title_label: Label
var _value_label: Label
var _hint_label: Label
var _hover_tween: Tween = null


func _ready() -> void:
    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = CARD_SIZE
    _ensure_children()
    _refresh()
    pivot_offset = CARD_SIZE * 0.5
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)


func set_card(card: CardData, index: int = -1, can_drag: bool = true) -> void:
    card_data = card
    hand_index = index
    draggable = can_drag
    mouse_default_cursor_shape = Control.CURSOR_DRAG if draggable else Control.CURSOR_ARROW
    _ensure_children()
    _refresh()


func _gui_input(event: InputEvent) -> void:
    if not draggable or card_data == null:
        return
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            manual_drag_started.emit(self, hand_index, get_global_mouse_position())
            accept_event()


func set_visual_value(value: int) -> void:
    if card_data == null:
        return
    card_data.value = value
    _refresh()


func stop_hover_idle() -> void:
    if _hover_tween != null:
        _hover_tween.kill()
        _hover_tween = null
    rotation = 0.0
    scale = Vector2.ONE


func _ensure_children() -> void:
    if _title_label != null:
        return

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 2)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(box)

    _title_label = Label.new()
    _title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title_label.add_theme_font_size_override("font_size", 28)
    _title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(_title_label)

    _value_label = Label.new()
    _value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _value_label.add_theme_font_size_override("font_size", 36)
    _value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(_value_label)

    _hint_label = Label.new()
    _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint_label.add_theme_font_size_override("font_size", 14)
    _hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(_hint_label)


func _refresh() -> void:
    if card_data == null:
        _title_label.text = ""
        _value_label.text = ""
        _hint_label.text = ""
        _apply_empty_style()
        return

    _title_label.text = card_data.short_label
    _value_label.text = str(card_data.value)
    if card_data.is_warehouse():
        _hint_label.text = "同数字收纳"
    else:
        _hint_label.text = card_data.label
    _apply_card_style(Color.html(card_data.color_hex), card_data.is_warehouse())


func _apply_card_style(base_color: Color, is_special: bool) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.93, 0.66, 0.42) if not is_special else Color(0.78, 0.48, 0.28)
    style.border_color = base_color.lightened(0.22) if not is_special else Color(0.38, 0.22, 0.14)
    style.border_width_left = 4
    style.border_width_top = 4
    style.border_width_right = 4
    style.border_width_bottom = 4
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    style.shadow_color = Color(0.18, 0.12, 0.08, 0.45)
    style.shadow_size = 3
    style.content_margin_left = 6
    style.content_margin_right = 6
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    add_theme_stylebox_override("panel", style)

    _title_label.add_theme_color_override("font_color", base_color.lightened(0.95))
    _value_label.add_theme_color_override("font_color", Color(0.34, 0.18, 0.14))
    _hint_label.add_theme_color_override("font_color", Color(0.38, 0.2, 0.15))


func _on_mouse_entered() -> void:
    if not draggable or card_data == null:
        return
    stop_hover_idle()
    _hover_tween = create_tween()
    _hover_tween.set_loops()
    _hover_tween.tween_property(self, "rotation", deg_to_rad(3.0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _hover_tween.tween_property(self, "rotation", deg_to_rad(-3.0), 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _hover_tween.tween_property(self, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_mouse_exited() -> void:
    if _hover_tween != null:
        _hover_tween.kill()
        _hover_tween = null
    var tween := create_tween()
    tween.parallel().tween_property(self, "rotation", 0.0, 0.12)
    tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)


func _apply_empty_style() -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.8, 0.53, 0.34)
    style.border_color = Color(0.38, 0.22, 0.14)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    add_theme_stylebox_override("panel", style)
