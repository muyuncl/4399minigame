extends Control

const PLAYER_SELF := 0
const PLAYER_REMOTE := 1
const MODE_SINGLE := 0
const MODE_ONLINE := 1

var _self_state := GameState.new()
var _remote_state := GameState.new()
var _self_board_view: BoardView
var _remote_board_view: BoardView
var _self_hand_view: HandView
var _remote_hand_view: HandView
var _score_label: Label
var _message_label: Label
var _network_status_label: Label
var _local_ip_label: Label
var _address_input: LineEdit
var _network = null
var _game_mode := MODE_SINGLE
var _ai_rng := RandomNumberGenerator.new()
var _single_button: Button
var _online_button: Button
var _self_restart_button: Button
var _remote_restart_button: Button
var _drag_card: CardView = null
var _drag_hand_index: int = -1
var _drag_original_parent: Node = null
var _drag_original_index: int = -1
var _drag_offset := Vector2.ZERO
var _animating := false


func _ready() -> void:
    _ai_rng.randomize()
    _network = get_node("/root/NetworkManager")
    _connect_network_signals()
    _build_ui()
    _self_state.start_new_game()
    _remote_state.start_new_game()
    _remote_state.last_message = "单机对手已准备，会随机放牌。"
    _refresh_all()
    _refresh_mode_buttons()
    _refresh_network_status(_network.get_status())


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


func _connect_network_signals() -> void:
    _network.status_changed.connect(_refresh_network_status)
    _network.connection_ready.connect(_on_network_connection_ready)
    _network.remote_state_received.connect(_on_remote_state_received)
    _network.network_closed.connect(_on_network_closed)


func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color(0.42, 0.68, 0.28)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var root := MarginContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("margin_left", 14)
    root.add_theme_constant_override("margin_top", 14)
    root.add_theme_constant_override("margin_right", 14)
    root.add_theme_constant_override("margin_bottom", 14)
    add_child(root)

    var main_box := VBoxContainer.new()
    main_box.add_theme_constant_override("separation", 10)
    root.add_child(main_box)

    main_box.add_child(_build_header())

    var content := HBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    main_box.add_child(content)

    _self_hand_view = _build_hand_panel(PLAYER_SELF, "我的手牌", content)

    var board_panel := _make_panel(Color(0.49, 0.74, 0.36), Color(0.37, 0.24, 0.15), 6)
    board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(board_panel)

    var board_margin := MarginContainer.new()
    board_margin.add_theme_constant_override("margin_left", 10)
    board_margin.add_theme_constant_override("margin_top", 18)
    board_margin.add_theme_constant_override("margin_right", 10)
    board_margin.add_theme_constant_override("margin_bottom", 18)
    board_panel.add_child(board_margin)

    var boards_row := HBoxContainer.new()
    boards_row.alignment = BoxContainer.ALIGNMENT_CENTER
    boards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    boards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    boards_row.add_theme_constant_override("separation", 14)
    board_margin.add_child(boards_row)

    _self_board_view = _build_board_column("我的舞台", boards_row, PLAYER_SELF)
    _remote_board_view = _build_board_column("对方舞台", boards_row, PLAYER_REMOTE)

    _remote_hand_view = _build_hand_panel(PLAYER_REMOTE, "对方手牌", content)


func _build_hand_panel(player: int, title_text: String, parent: Container) -> HandView:
    var side_panel := _make_panel(Color(0.48, 0.73, 0.34), Color(0.28, 0.47, 0.2), 4)
    side_panel.custom_minimum_size = Vector2(168, 0)
    side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(side_panel)

    var side_margin := MarginContainer.new()
    side_margin.add_theme_constant_override("margin_left", 10)
    side_margin.add_theme_constant_override("margin_top", 12)
    side_margin.add_theme_constant_override("margin_right", 10)
    side_margin.add_theme_constant_override("margin_bottom", 12)
    side_panel.add_child(side_margin)

    var side_box := VBoxContainer.new()
    side_box.add_theme_constant_override("separation", 8)
    side_margin.add_child(side_box)

    var hand_title := Label.new()
    hand_title.text = title_text
    hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hand_title.add_theme_font_size_override("font_size", 22)
    hand_title.add_theme_color_override("font_color", Color(0.16, 0.1, 0.06))
    side_box.add_child(hand_title)

    var hand_view := HandView.new()
    hand_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    if player == PLAYER_SELF:
        hand_view.card_drag_started.connect(_on_hand_card_drag_started)
    side_box.add_child(hand_view)

    var restart_button := Button.new()
    restart_button.custom_minimum_size = Vector2(0, 36)
    side_box.add_child(restart_button)

    if player == PLAYER_SELF:
        _self_restart_button = restart_button
        restart_button.pressed.connect(_on_restart_pressed)
    else:
        _remote_restart_button = restart_button
        restart_button.disabled = true
        restart_button.text = "等待同步"

    return hand_view


func _build_board_column(title_text: String, parent: Container, player: int) -> BoardView:
    var board_box := VBoxContainer.new()
    board_box.alignment = BoxContainer.ALIGNMENT_CENTER
    board_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    board_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_box.add_theme_constant_override("separation", 8)
    parent.add_child(board_box)

    var board_title := Label.new()
    board_title.text = title_text
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
    field_margin.add_theme_constant_override("margin_left", 8)
    field_margin.add_theme_constant_override("margin_top", 8)
    field_margin.add_theme_constant_override("margin_right", 8)
    field_margin.add_theme_constant_override("margin_bottom", 8)
    field_frame.add_child(field_margin)

    var board_view := BoardView.new()
    board_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    board_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    if player == PLAYER_SELF:
        board_view.card_dropped.connect(_on_card_dropped)
    field_margin.add_child(board_view)
    board_view.build()
    return board_view


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
    _message_label.add_theme_font_size_override("font_size", 16)
    _message_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
    title_box.add_child(_message_label)

    header.add_child(_build_network_panel())

    _score_label = Label.new()
    _score_label.custom_minimum_size = Vector2(300, 58)
    _score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _score_label.add_theme_font_size_override("font_size", 30)
    _score_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
    header.add_child(_score_label)

    return header


func _build_network_panel() -> Control:
    var panel := VBoxContainer.new()
    panel.custom_minimum_size = Vector2(430, 0)
    panel.add_theme_constant_override("separation", 4)

    _network_status_label = Label.new()
    _network_status_label.text = "离线"
    _network_status_label.add_theme_font_size_override("font_size", 14)
    _network_status_label.add_theme_color_override("font_color", Color(0.14, 0.09, 0.05))
    panel.add_child(_network_status_label)

    _local_ip_label = Label.new()
    _local_ip_label.text = "本机 IP：" + _network.get_local_ip_hint()
    _local_ip_label.add_theme_font_size_override("font_size", 12)
    _local_ip_label.add_theme_color_override("font_color", Color(0.22, 0.13, 0.07))
    panel.add_child(_local_ip_label)

    var mode_row := HBoxContainer.new()
    mode_row.add_theme_constant_override("separation", 6)
    panel.add_child(mode_row)

    _single_button = Button.new()
    _single_button.text = "单机"
    _single_button.toggle_mode = true
    _single_button.custom_minimum_size = Vector2(74, 30)
    _single_button.pressed.connect(_on_single_mode_pressed)
    mode_row.add_child(_single_button)

    _online_button = Button.new()
    _online_button.text = "联机"
    _online_button.toggle_mode = true
    _online_button.custom_minimum_size = Vector2(74, 30)
    _online_button.pressed.connect(_on_online_mode_pressed)
    mode_row.add_child(_online_button)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    panel.add_child(row)

    var host_button := Button.new()
    host_button.text = "开房"
    host_button.custom_minimum_size = Vector2(64, 32)
    host_button.pressed.connect(_on_host_pressed)
    row.add_child(host_button)

    _address_input = LineEdit.new()
    _address_input.placeholder_text = "房主 IP"
    _address_input.text = "127.0.0.1"
    _address_input.custom_minimum_size = Vector2(150, 32)
    row.add_child(_address_input)

    var join_button := Button.new()
    join_button.text = "加入"
    join_button.custom_minimum_size = Vector2(64, 32)
    join_button.pressed.connect(_on_join_pressed)
    row.add_child(join_button)

    var close_button := Button.new()
    close_button.text = "断开"
    close_button.custom_minimum_size = Vector2(64, 32)
    close_button.pressed.connect(_on_disconnect_pressed)
    row.add_child(close_button)

    return panel


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


func _on_host_pressed() -> void:
    _set_game_mode(MODE_ONLINE, false)
    _network.host_game()


func _on_join_pressed() -> void:
    _set_game_mode(MODE_ONLINE, false)
    _network.join_game(_address_input.text)


func _on_disconnect_pressed() -> void:
    _network.close_connection()


func _on_single_mode_pressed() -> void:
    _set_game_mode(MODE_SINGLE)


func _on_online_mode_pressed() -> void:
    _set_game_mode(MODE_ONLINE)


func _set_game_mode(mode: int, reset_states: bool = true) -> void:
    _game_mode = mode
    if mode == MODE_SINGLE:
        _network.close_connection(false)
        if reset_states:
            _self_state.start_new_game()
            _remote_state.start_new_game()
        _remote_state.last_message = "单机对手已准备，会随机放牌。"
    else:
        if reset_states:
            _self_state.start_new_game()
            _remote_state.start_new_game()
        _remote_state.last_message = "等待附近玩家加入。"

    _refresh_mode_buttons()
    _refresh_all()


func _refresh_mode_buttons() -> void:
    if _single_button == null or _online_button == null:
        return
    _single_button.button_pressed = _game_mode == MODE_SINGLE
    _online_button.button_pressed = _game_mode == MODE_ONLINE


func _on_network_connection_ready() -> void:
    _send_self_snapshot()


func _on_remote_state_received(snapshot: Dictionary) -> void:
    if _game_mode != MODE_ONLINE:
        return
    _remote_state.apply_snapshot(snapshot)
    var advanced := _try_start_next_round()
    _refresh_all()
    if advanced:
        _send_self_snapshot()


func _on_network_closed() -> void:
    if _game_mode != MODE_ONLINE:
        return
    _remote_state.start_new_game()
    _remote_state.last_message = "对方未连接。"
    _refresh_all()


func _refresh_network_status(message: String) -> void:
    if _network_status_label == null:
        return
    _network_status_label.text = message
    if _local_ip_label != null:
        _local_ip_label.text = "本机 IP：" + _network.get_local_ip_hint()


func _on_card_dropped(hand_index: int, cell: Vector2i) -> void:
    var result := _self_state.place_from_hand(hand_index, cell)
    if not bool(result.get("ok", false)):
        _self_state.last_message = str(result.get("message", "放置失败。"))
        _refresh_all()
        return
    _after_self_successful_play()


func _on_hand_card_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2) -> void:
    if _drag_card != null or _self_state.game_over or _animating:
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
    var cell := _self_board_view.get_cell_at_global_position(mouse_position)
    if cell.x >= 0:
        var visual_board := _make_visual_board_before_drop(_drag_hand_index, cell)
        var result := _self_state.place_from_hand(_drag_hand_index, cell)
        if bool(result.get("ok", false)):
            _drag_card.queue_free()
            _clear_manual_drag()
            await _play_place_result(visual_board, result)
            _after_self_successful_play()
            return
        _self_state.last_message = str(result.get("message", "放置失败。"))

    _restore_manual_drag_card()
    _refresh_all()


func _after_self_successful_play() -> void:
    _send_self_snapshot()
    if _game_mode == MODE_SINGLE:
        _play_singleplayer_opponent()
    var advanced := _try_start_next_round()
    _refresh_all()
    if advanced:
        _send_self_snapshot()


func _play_singleplayer_opponent() -> void:
    if _remote_state.game_over or _remote_state.hand.is_empty():
        return

    var moves_to_play := 1
    if _self_state.hand.is_empty():
        moves_to_play = _remote_state.hand.size()

    for _i in range(moves_to_play):
        if not _play_one_ai_card():
            break


func _play_one_ai_card() -> bool:
    if _remote_state.hand.is_empty() or _remote_state.game_over:
        return false

    var empty_cells := _remote_state.get_empty_cells()
    if empty_cells.is_empty():
        return false

    var hand_index := _ai_rng.randi_range(0, _remote_state.hand.size() - 1)
    var cell: Vector2i = empty_cells[_ai_rng.randi_range(0, empty_cells.size() - 1)]
    var result := _remote_state.place_from_hand(hand_index, cell)
    if not bool(result.get("ok", false)):
        _remote_state.last_message = str(result.get("message", "电脑放置失败。"))
        return false
    return true


func _try_start_next_round() -> bool:
    if not _self_state.is_round_done() or not _remote_state.is_round_done():
        return false

    var advanced := _self_state.start_next_round()
    if _game_mode == MODE_SINGLE:
        advanced = _remote_state.start_next_round() or advanced
    return advanced


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
    _refresh_header()
    _self_hand_view.refresh(_self_state.hand, _self_state.game_over, true)

    if events.is_empty():
        _refresh_all()
        return

    _animating = true
    _self_board_view.refresh_board(visual_board, false)
    await _self_board_view.play_drop_events(events)
    _animating = false
    _refresh_all()


func _make_visual_board_before_drop(hand_index: int, cell: Vector2i) -> Array:
    var visual_board := _clone_board(_self_state.board)
    if hand_index < 0 or hand_index >= _self_state.hand.size():
        return visual_board

    var played: CardData = _self_state.hand[hand_index].clone()
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
    _self_state.restart()
    if _game_mode == MODE_SINGLE:
        _remote_state.restart()
        _remote_state.last_message = "单机对手已准备，会随机放牌。"
    _refresh_all()
    _send_self_snapshot()


func _send_self_snapshot() -> void:
    _network.send_player_snapshot(_self_state.to_snapshot())


func _refresh_all() -> void:
    _refresh_player(PLAYER_SELF)
    _refresh_player(PLAYER_REMOTE)
    _refresh_header()


func _refresh_player(player: int) -> void:
    var is_self := player == PLAYER_SELF
    var state := _self_state if is_self else _remote_state
    var board_view := _self_board_view if is_self else _remote_board_view
    var hand_view := _self_hand_view if is_self else _remote_hand_view
    board_view.refresh_board(state.board, is_self and not state.game_over and not state.hand.is_empty())
    hand_view.refresh(state.hand, state.game_over, is_self)
    if is_self:
        _self_restart_button.text = "再开一局" if state.game_over else "重新开播"
    else:
        _remote_restart_button.text = "电脑对手" if _game_mode == MODE_SINGLE else "只读同步"


func _refresh_header() -> void:
    _score_label.text = "我 %04d    对方 %04d" % [_self_state.score, _remote_state.score]
    _message_label.text = "第 %d 轮 | 我剩 %d 张，对方剩 %d 张\n我：%s\n对方：%s" % [
        _self_state.round_index,
        _self_state.hand.size(),
        _remote_state.hand.size(),
        _self_state.last_message,
        _remote_state.last_message
    ]
