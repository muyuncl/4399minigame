extends Control

var _state := GameState.new()
var _board_view: BoardView
var _hand_view: HandView
var _score_label: Label
var _message_label: Label
var _restart_button: Button
var _drag_card: CardView = null
var _drag_hand_index: int = -1
var _drag_original_parent: Node = null
var _drag_original_index: int = -1
var _drag_offset := Vector2.ZERO
var _animating := false


func _ready() -> void:
    _build_ui()
    _state.start_new_game()
    _refresh_all()


func _process(_delta: float) -> void:
    if _drag_card != null:
        _move_drag_card(get_global_mouse_position())


func _input(event: InputEvent) -> void:
    if _drag_card == null:
        return
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
            _finish_manual_drag(get_global_mouse_position())
            get_viewport().set_input_as_handled()


func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color(0.42, 0.68, 0.28)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var root := MarginContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 22)
    root.add_theme_constant_override("margin_top", 14)
    root.add_theme_constant_override("margin_right", 22)
    root.add_theme_constant_override("margin_bottom", 14)
    add_child(root)

    var main_box := VBoxContainer.new()
    main_box.add_theme_constant_override("separation", 10)
    root.add_child(main_box)

    main_box.add_child(_build_header())

    var content := HBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 18)
    main_box.add_child(content)

    var board_panel := _make_panel(Color(0.49, 0.74, 0.36), Color(0.37, 0.24, 0.15), 6)
    board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(board_panel)

    var board_margin := MarginContainer.new()
    board_margin.add_theme_constant_override("margin_left", 24)
    board_margin.add_theme_constant_override("margin_top", 18)
    board_margin.add_theme_constant_override("margin_right", 24)
    board_margin.add_theme_constant_override("margin_bottom", 18)
    board_panel.add_child(board_margin)

    var board_box := VBoxContainer.new()
    board_box.alignment = BoxContainer.ALIGNMENT_CENTER
    board_box.add_theme_constant_override("separation", 8)
    board_margin.add_child(board_box)

    var board_title := Label.new()
    board_title.text = "才艺舞台"
    board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    board_title.add_theme_font_size_override("font_size", 22)
    board_title.add_theme_color_override("font_color", Color(0.2, 0.11, 0.07))
    board_box.add_child(board_title)

    var bonus_label := Label.new()
    bonus_label.text = "最上排 / 最左列入场 +1"
    bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bonus_label.add_theme_font_size_override("font_size", 14)
    bonus_label.add_theme_color_override("font_color", Color(0.38, 0.22, 0.09))
    board_box.add_child(bonus_label)

    var field_frame := PanelContainer.new()
    field_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    field_frame.add_theme_stylebox_override("panel", _make_style(Color(0.42, 0.22, 0.12), Color(0.23, 0.12, 0.07), 4, 0))
    board_box.add_child(field_frame)

    var field_margin := MarginContainer.new()
    field_margin.add_theme_constant_override("margin_left", 10)
    field_margin.add_theme_constant_override("margin_top", 10)
    field_margin.add_theme_constant_override("margin_right", 10)
    field_margin.add_theme_constant_override("margin_bottom", 10)
    field_frame.add_child(field_margin)

    _board_view = BoardView.new()
    _board_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _board_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _board_view.card_dropped.connect(_on_card_dropped)
    field_margin.add_child(_board_view)
    _board_view.build()

    var side_panel := _make_panel(Color(0.48, 0.73, 0.34), Color(0.28, 0.47, 0.2), 4)
    side_panel.custom_minimum_size = Vector2(330, 0)
    content.add_child(side_panel)

    var side_margin := MarginContainer.new()
    side_margin.add_theme_constant_override("margin_left", 14)
    side_margin.add_theme_constant_override("margin_top", 12)
    side_margin.add_theme_constant_override("margin_right", 14)
    side_margin.add_theme_constant_override("margin_bottom", 12)
    side_panel.add_child(side_margin)

    var side_box := VBoxContainer.new()
    side_box.add_theme_constant_override("separation", 8)
    side_margin.add_child(side_box)

    var hand_title := Label.new()
    hand_title.text = "手牌"
    hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hand_title.add_theme_font_size_override("font_size", 24)
    hand_title.add_theme_color_override("font_color", Color(0.16, 0.1, 0.06))
    side_box.add_child(hand_title)

    _hand_view = HandView.new()
    _hand_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _hand_view.card_drag_started.connect(_on_hand_card_drag_started)
    side_box.add_child(_hand_view)

    _restart_button = Button.new()
    _restart_button.text = "重新开播"
    _restart_button.custom_minimum_size = Vector2(0, 36)
    _restart_button.pressed.connect(_on_restart_pressed)
    side_box.add_child(_restart_button)


func _build_header() -> Control:
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 16)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    var title := Label.new()
    title.text = "直播间才艺热度"
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.86))
    title.add_theme_color_override("font_shadow_color", Color(0.16, 0.1, 0.06, 0.7))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    title_box.add_child(title)

    _message_label = Label.new()
    _message_label.text = ""
    _message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message_label.add_theme_font_size_override("font_size", 17)
    _message_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
    title_box.add_child(_message_label)

    _score_label = Label.new()
    _score_label.custom_minimum_size = Vector2(210, 58)
    _score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _score_label.add_theme_font_size_override("font_size", 34)
    _score_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
    header.add_child(_score_label)

    return header


func _make_panel(bg_color: Color, border_color: Color, radius: int) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 4, radius))
    return panel


func _make_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    return style


func _on_card_dropped(hand_index: int, cell: Vector2i) -> void:
    var result := _state.place_from_hand(hand_index, cell)
    if not bool(result.get("ok", false)):
        _state.last_message = str(result.get("message", "放置失败。"))
    _refresh_all()


func _on_hand_card_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2) -> void:
    if _drag_card != null or _state.game_over or _animating:
        return

    _drag_card = card_view
    _drag_hand_index = hand_index
    _drag_original_parent = card_view.get_parent()
    _drag_original_index = card_view.get_index()
    _drag_offset = grab_position - card_view.global_position

    _drag_original_parent.remove_child(card_view)
    add_child(card_view)
    card_view.stop_hover_idle()
    card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card_view.z_index = 100
    card_view.modulate.a = 0.92
    card_view.size = CardView.CARD_SIZE
    _move_drag_card(grab_position)


func _move_drag_card(mouse_position: Vector2) -> void:
    _drag_card.global_position = mouse_position - _drag_offset


func _finish_manual_drag(mouse_position: Vector2) -> void:
    var cell := _board_view.get_cell_at_global_position(mouse_position)
    if cell.x >= 0:
        var visual_board := _make_visual_board_before_drop(_drag_hand_index, cell)
        var result := _state.place_from_hand(_drag_hand_index, cell)
        if bool(result.get("ok", false)):
            _drag_card.queue_free()
            _clear_manual_drag()
            await _play_place_result(visual_board, result)
            return
        _state.last_message = str(result.get("message", "放置失败。"))

    _restore_manual_drag_card()
    _refresh_all()


func _restore_manual_drag_card() -> void:
    if _drag_card == null:
        return
    remove_child(_drag_card)
    if _drag_original_parent != null:
        _drag_original_parent.add_child(_drag_card)
        var target_index: int = int(min(_drag_original_index, _drag_original_parent.get_child_count() - 1))
        _drag_original_parent.move_child(_drag_card, target_index)
    _drag_card.mouse_filter = Control.MOUSE_FILTER_STOP
    _drag_card.z_index = 0
    _drag_card.modulate.a = 1.0
    _drag_card.size = CardView.CARD_SIZE
    _clear_manual_drag()


func _clear_manual_drag() -> void:
    _drag_card = null
    _drag_hand_index = -1
    _drag_original_parent = null
    _drag_original_index = -1
    _drag_offset = Vector2.ZERO


func _play_place_result(visual_board: Array, result: Dictionary) -> void:
    var events: Array = result.get("events", [])
    _score_label.text = "热度 %04d" % _state.score
    _message_label.text = _state.last_message
    _hand_view.refresh(_state.hand, _state.game_over)

    if events.is_empty():
        _refresh_all()
        return

    _animating = true
    _board_view.refresh_board(visual_board, false)
    await _board_view.play_drop_events(events)
    _animating = false
    _refresh_all()


func _make_visual_board_before_drop(hand_index: int, cell: Vector2i) -> Array:
    var visual_board := _clone_board(_state.board)
    if hand_index < 0 or hand_index >= _state.hand.size():
        return visual_board

    var played: CardData = _state.hand[hand_index].clone()
    if played.is_normal():
        if cell.x == 0 or cell.y == 0:
            played.value += 1
        visual_board[cell.y][cell.x] = played

    return visual_board


func _clone_board(source_board: Array) -> Array:
    var cloned := []
    for y in range(GameState.BOARD_SIZE):
        var row := []
        for x in range(GameState.BOARD_SIZE):
            var card: CardData = source_board[y][x]
            row.append(null if card == null else card.clone())
        cloned.append(row)
    return cloned


func _on_restart_pressed() -> void:
    if _drag_card != null:
        _drag_card.queue_free()
        _clear_manual_drag()
    _animating = false
    _state.restart()
    _refresh_all()


func _refresh_all() -> void:
    _score_label.text = "热度 %04d" % _state.score
    _message_label.text = _state.last_message
    _board_view.refresh(_state)
    _hand_view.refresh(_state.hand, _state.game_over)
    _restart_button.text = "再开一局" if _state.game_over else "重新开播"
