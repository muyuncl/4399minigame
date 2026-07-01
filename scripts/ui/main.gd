extends Control

const PLAYER_SELF := 0
const PLAYER_REMOTE := 1
const MODE_SINGLE := 0
const MODE_ONLINE := 1
const DRAFT_POOL_SIZE := 10
const ROUND_SECONDS := 30.0
const DraftPoolViewScript := preload("res://scripts/ui/draft_pool_view.gd")

var _self_state := GameState.new()
var _remote_state := GameState.new()
var _self_board_view: BoardView
var _remote_board_view: BoardView
var _self_hand_view: HandView
var _remote_hand_view: HandView
var _draft_pool_view
var _score_label: Label
var _message_label: Label
var _timer_label: Label
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
var _draft_pool: Array = []
var _self_claimed_count := 0
var _remote_claimed_count := 0
var _self_selected_draft_index := -1
var _remote_selected_draft_index := -1
var _round_time_left := ROUND_SECONDS
var _round_timer_running := false


func _ready() -> void:
    _ai_rng.randomize()
    _network = get_node("/root/NetworkManager")
    _connect_network_signals()
    _build_ui()
    _start_new_match()
    _refresh_network_status(_network.get_status())


func _process(delta: float) -> void:
    if _drag_card != null:
        _move_drag_card(get_global_mouse_position())
    if _round_timer_running:
        _round_time_left = max(0.0, _round_time_left - delta)
        _refresh_timer()
        if _round_time_left <= 0.0:
            _round_timer_running = false
            _on_round_timer_finished()


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

    var play_panel := _make_panel(Color(0.49, 0.74, 0.36), Color(0.37, 0.24, 0.15), 6)
    play_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    play_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_box.add_child(play_panel)

    var play_margin := MarginContainer.new()
    play_margin.add_theme_constant_override("margin_left", 10)
    play_margin.add_theme_constant_override("margin_top", 14)
    play_margin.add_theme_constant_override("margin_right", 10)
    play_margin.add_theme_constant_override("margin_bottom", 14)
    play_panel.add_child(play_margin)

    var play_row := HBoxContainer.new()
    play_row.alignment = BoxContainer.ALIGNMENT_CENTER
    play_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    play_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    play_row.add_theme_constant_override("separation", 10)
    play_margin.add_child(play_row)

    _self_board_view = _build_board_column("我的舞台", play_row, true)
    _self_hand_view = _build_hand_panel("我的手牌", play_row, true)
    _draft_pool_view = _build_draft_panel(play_row)
    _remote_hand_view = _build_hand_panel("对方手牌", play_row, false)
    _remote_board_view = _build_board_column("对方舞台", play_row, false)


func _build_hand_panel(title_text: String, parent: Container, can_operate: bool) -> HandView:
    var side_panel := _make_panel(Color(0.48, 0.73, 0.34), Color(0.28, 0.47, 0.2), 4)
    side_panel.custom_minimum_size = Vector2(132, 0)
    side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(side_panel)

    var side_margin := MarginContainer.new()
    side_margin.add_theme_constant_override("margin_left", 8)
    side_margin.add_theme_constant_override("margin_top", 10)
    side_margin.add_theme_constant_override("margin_right", 8)
    side_margin.add_theme_constant_override("margin_bottom", 10)
    side_panel.add_child(side_margin)

    var side_box := VBoxContainer.new()
    side_box.add_theme_constant_override("separation", 8)
    side_margin.add_child(side_box)

    var hand_title := Label.new()
    hand_title.text = title_text
    hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hand_title.add_theme_font_size_override("font_size", 20)
    hand_title.add_theme_color_override("font_color", Color(0.16, 0.1, 0.06))
    side_box.add_child(hand_title)

    var hand_view := HandView.new()
    hand_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    if can_operate:
        hand_view.card_drag_started.connect(_on_hand_card_drag_started)
    side_box.add_child(hand_view)

    var restart_button := Button.new()
    restart_button.custom_minimum_size = Vector2(0, 34)
    side_box.add_child(restart_button)

    if can_operate:
        _self_restart_button = restart_button
        restart_button.pressed.connect(_on_restart_pressed)
    else:
        _remote_restart_button = restart_button
        restart_button.disabled = true
        restart_button.text = "只读"

    return hand_view


func _build_board_column(title_text: String, parent: Container, can_drop: bool) -> BoardView:
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
    if can_drop:
        board_view.card_dropped.connect(_on_card_dropped)
    field_margin.add_child(board_view)
    board_view.build()
    return board_view


func _build_draft_panel(parent: Container) -> Control:
    var draft_panel := _make_panel(Color(0.57, 0.79, 0.42), Color(0.2, 0.12, 0.07), 4)
    draft_panel.custom_minimum_size = Vector2(190, 0)
    draft_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(draft_panel)

    var draft_margin := MarginContainer.new()
    draft_margin.add_theme_constant_override("margin_left", 10)
    draft_margin.add_theme_constant_override("margin_top", 10)
    draft_margin.add_theme_constant_override("margin_right", 10)
    draft_margin.add_theme_constant_override("margin_bottom", 10)
    draft_panel.add_child(draft_margin)

    var draft_box := VBoxContainer.new()
    draft_box.alignment = BoxContainer.ALIGNMENT_CENTER
    draft_box.add_theme_constant_override("separation", 8)
    draft_margin.add_child(draft_box)

    var title := Label.new()
    title.text = "抢手牌区"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
    draft_box.add_child(title)

    var callout := Label.new()
    callout.text = "抢！"
    callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    callout.add_theme_font_size_override("font_size", 42)
    callout.add_theme_color_override("font_color", Color(0.04, 0.02, 0.01))
    draft_box.add_child(callout)

    var draft_view = DraftPoolViewScript.new()
    draft_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    draft_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    draft_view.card_clicked.connect(_on_draft_card_clicked)
    draft_box.add_child(draft_view)
    return draft_view


func _build_header() -> Control:
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 16)

    var title_box := VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_box)

    var title := Label.new()
    title.text = "直播间才艺热度"
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.86))
    title.add_theme_color_override("font_shadow_color", Color(0.16, 0.1, 0.06, 0.7))
    title.add_theme_constant_override("shadow_offset_x", 2)
    title.add_theme_constant_override("shadow_offset_y", 2)
    title_box.add_child(title)

    _message_label = Label.new()
    _message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _message_label.add_theme_font_size_override("font_size", 15)
    _message_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08))
    title_box.add_child(_message_label)

    _timer_label = Label.new()
    _timer_label.custom_minimum_size = Vector2(150, 58)
    _timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _timer_label.add_theme_font_size_override("font_size", 42)
    _timer_label.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02))
    header.add_child(_timer_label)

    header.add_child(_build_network_panel())

    _score_label = Label.new()
    _score_label.custom_minimum_size = Vector2(260, 58)
    _score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _score_label.add_theme_font_size_override("font_size", 28)
    _score_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
    header.add_child(_score_label)

    return header


func _build_network_panel() -> Control:
    var panel := VBoxContainer.new()
    panel.custom_minimum_size = Vector2(410, 0)
    panel.add_theme_constant_override("separation", 4)

    _network_status_label = Label.new()
    _network_status_label.text = "离线"
    _network_status_label.add_theme_font_size_override("font_size", 13)
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
    _single_button.custom_minimum_size = Vector2(70, 30)
    _single_button.pressed.connect(_on_single_mode_pressed)
    mode_row.add_child(_single_button)

    _online_button = Button.new()
    _online_button.text = "联机"
    _online_button.toggle_mode = true
    _online_button.custom_minimum_size = Vector2(70, 30)
    _online_button.pressed.connect(_on_online_mode_pressed)
    mode_row.add_child(_online_button)

    var host_button := Button.new()
    host_button.text = "开房"
    host_button.custom_minimum_size = Vector2(62, 30)
    host_button.pressed.connect(_on_host_pressed)
    mode_row.add_child(host_button)

    _address_input = LineEdit.new()
    _address_input.placeholder_text = "房主 IP"
    _address_input.text = "127.0.0.1"
    _address_input.custom_minimum_size = Vector2(130, 30)
    mode_row.add_child(_address_input)

    var join_button := Button.new()
    join_button.text = "加入"
    join_button.custom_minimum_size = Vector2(62, 30)
    join_button.pressed.connect(_on_join_pressed)
    mode_row.add_child(join_button)

    var close_button := Button.new()
    close_button.text = "断开"
    close_button.custom_minimum_size = Vector2(62, 30)
    close_button.pressed.connect(_on_disconnect_pressed)
    mode_row.add_child(close_button)

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


func _start_new_match() -> void:
    _self_state.start_new_game()
    _remote_state.start_new_game()
    _remote_state.last_message = "单机对手已准备，会随机抢牌。"
    _self_claimed_count = 0
    _remote_claimed_count = 0
    _clear_draft_selections()
    _refresh_draft_pool()
    _refresh_mode_buttons()
    _refresh_all()


func _refresh_draft_pool() -> void:
    _draft_pool.clear()
    for _i in range(DRAFT_POOL_SIZE):
        _draft_pool.append(_self_state.draw_card())
    _clear_draft_selections()
    _round_time_left = ROUND_SECONDS
    _round_timer_running = true


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
        _start_new_match()
    else:
        _refresh_mode_buttons()
        _refresh_all()
    if mode == MODE_ONLINE:
        _remote_state.last_message = "等待附近玩家加入。"
    elif mode == MODE_SINGLE:
        _remote_state.last_message = "单机对手已准备，会随机抢牌。"
    _refresh_all()


func _refresh_mode_buttons() -> void:
    if _single_button == null or _online_button == null:
        return
    _single_button.button_pressed = _game_mode == MODE_SINGLE
    _online_button.button_pressed = _game_mode == MODE_ONLINE


func _on_network_connection_ready() -> void:
    _send_match_snapshot()


func _on_remote_state_received(snapshot: Dictionary) -> void:
    if _game_mode != MODE_ONLINE:
        return

    var message_type := str(snapshot.get("type", "state"))
    if message_type == "select":
        _remote_state.apply_snapshot(snapshot.get("player", {}))
        _remote_claimed_count = int(snapshot.get("claimed_count", _remote_claimed_count))
        var requested_index := int(snapshot.get("draft_index", -1))
        _remote_selected_draft_index = requested_index if _can_remote_select(requested_index) else -1
        _sanitize_draft_selections()
        _refresh_all()
        if _network.is_host():
            _send_match_snapshot()
        return

    if message_type == "claim":
        if _network.is_host():
            var draft_index := int(snapshot.get("draft_index", -1))
            var claim_allowed := draft_index >= 0 and draft_index < _draft_pool.size() and _draft_pool[draft_index] != null and _self_selected_draft_index != draft_index
            if claim_allowed:
                _remote_state.apply_snapshot(snapshot.get("player", {}))
                _remote_claimed_count = int(snapshot.get("claimed_count", _remote_claimed_count))
                _draft_pool[draft_index] = null
                _remote_selected_draft_index = -1
                var advanced_claim := _try_start_next_round()
                _sanitize_draft_selections()
                _refresh_all()
                _send_match_snapshot()
                if advanced_claim:
                    _send_match_snapshot()
            else:
                _send_match_snapshot()
        return

    if message_type == "player_state":
        _remote_state.apply_snapshot(snapshot.get("player", {}))
        _remote_claimed_count = int(snapshot.get("claimed_count", _remote_claimed_count))
        if snapshot.has("selected_index"):
            var player_selected_index := int(snapshot.get("selected_index", -1))
            _remote_selected_draft_index = player_selected_index if _can_remote_select(player_selected_index) else -1
        var advanced_player := _try_start_next_round()
        _sanitize_draft_selections()
        _refresh_all()
        if _network.is_host() or advanced_player:
            _send_match_snapshot()
        return

    var player_snapshot: Dictionary = snapshot.get("player", snapshot)
    _remote_state.apply_snapshot(player_snapshot)
    _remote_claimed_count = int(snapshot.get("claimed_count", _remote_claimed_count))

    if snapshot.has("draft_pool") and _network.is_client():
        _draft_pool = _cards_from_snapshot(snapshot.get("draft_pool", []))
    if snapshot.has("self_claimed_count") and _network.is_client():
        _self_claimed_count = int(snapshot.get("self_claimed_count", _self_claimed_count))
    if snapshot.has("round_time_left") and _network.is_client():
        _round_time_left = float(snapshot.get("round_time_left", _round_time_left))
    if snapshot.has("self_selected_index") and _network.is_client():
        _self_selected_draft_index = int(snapshot.get("self_selected_index", _self_selected_draft_index))
    if snapshot.has("remote_selected_index") and _network.is_client():
        _remote_selected_draft_index = int(snapshot.get("remote_selected_index", _remote_selected_draft_index))

    var advanced := _try_start_next_round()
    _sanitize_draft_selections()
    _refresh_all()
    if advanced:
        _send_match_snapshot()


func _on_network_closed() -> void:
    if _game_mode != MODE_ONLINE:
        return
    _remote_state.start_new_game()
    _remote_state.last_message = "对方未连接。"
    _remote_claimed_count = 0
    _remote_selected_draft_index = -1
    _refresh_all()


func _refresh_network_status(message: String) -> void:
    if _network_status_label == null:
        return
    _network_status_label.text = message
    if _local_ip_label != null:
        _local_ip_label.text = "本机 IP：" + _network.get_local_ip_hint()


func _on_draft_card_clicked(index: int) -> void:
    if _self_selected_draft_index == index:
        _confirm_draft_card(index)
        return
    if not _can_select_self(index):
        return
    _self_selected_draft_index = index
    _sanitize_draft_selections()
    _refresh_all()
    _send_selection_update()


func _confirm_draft_card(index: int) -> void:
    if not _can_claim_self(index):
        return
    var card: CardData = _draft_pool[index]
    if not _self_state.claim_card(card):
        return
    _draft_pool[index] = null
    _self_claimed_count += 1
    _self_selected_draft_index = -1

    if _game_mode == MODE_SINGLE:
        _ai_claim_cards(_self_claimed_count - _remote_claimed_count)

    _sanitize_draft_selections()
    _refresh_all()
    _send_claim_update(index)


func _can_select_self(index: int) -> bool:
    if _animating or _self_state.game_over:
        return false
    if _self_claimed_count >= GameState.HAND_SIZE or _self_state.hand.size() >= GameState.HAND_SIZE:
        return false
    if index < 0 or index >= _draft_pool.size():
        return false
    if _draft_pool[index] == null:
        return false
    return _remote_selected_draft_index != index


func _can_claim_self(index: int) -> bool:
    return _self_selected_draft_index == index and _can_select_self(index)


func _can_remote_select(index: int) -> bool:
    if index == -1:
        return true
    if index < 0 or index >= _draft_pool.size():
        return false
    if _draft_pool[index] == null:
        return false
    if _self_selected_draft_index == index:
        return false
    if _remote_claimed_count >= GameState.HAND_SIZE or _remote_state.hand.size() >= GameState.HAND_SIZE:
        return false
    return true


func _clear_draft_selections() -> void:
    _self_selected_draft_index = -1
    _remote_selected_draft_index = -1


func _sanitize_draft_selections() -> void:
    _self_selected_draft_index = _normalize_draft_selection(_self_selected_draft_index)
    _remote_selected_draft_index = _normalize_draft_selection(_remote_selected_draft_index)
    if _self_selected_draft_index != -1 and _self_selected_draft_index == _remote_selected_draft_index:
        if _network != null and _network.is_host():
            _remote_selected_draft_index = -1
        else:
            _self_selected_draft_index = -1


func _normalize_draft_selection(index: int) -> int:
    if index < 0 or index >= _draft_pool.size():
        return -1
    if _draft_pool[index] == null:
        return -1
    return index


func _ai_claim_cards(count: int) -> void:
    var claimed := 0
    while claimed < count and _remote_state.can_claim_card():
        var indexes := _available_draft_indexes(_self_selected_draft_index)
        if indexes.is_empty():
            return
        var index: int = indexes[_ai_rng.randi_range(0, indexes.size() - 1)]
        var card: CardData = _draft_pool[index]
        if _remote_state.claim_card(card):
            _draft_pool[index] = null
            _remote_claimed_count += 1
            claimed += 1


func _available_draft_indexes(blocked_index: int = -1) -> Array[int]:
    var indexes: Array[int] = []
    for i in range(_draft_pool.size()):
        if _draft_pool[i] != null and i != blocked_index:
            indexes.append(i)
    return indexes


func _on_round_timer_finished() -> void:
    _self_state.last_message = "30 秒到，未抢满的手牌会自动补齐。"
    _clear_draft_selections()
    _auto_claim_missing_for_self()
    if _game_mode == MODE_SINGLE:
        _ai_claim_cards(GameState.HAND_SIZE - _remote_claimed_count)
    _refresh_all()
    _send_match_snapshot()


func _send_claim_update(index: int) -> void:
    if _game_mode != MODE_ONLINE or not _network.has_remote_peer():
        return
    if _network.is_client():
        _network.send_player_snapshot({
            "type": "claim",
            "draft_index": index,
            "player": _self_state.to_snapshot(),
            "claimed_count": _self_claimed_count,
            "selected_index": _self_selected_draft_index
        })
    else:
        _send_match_snapshot()


func _send_selection_update() -> void:
    if _game_mode != MODE_ONLINE or not _network.has_remote_peer():
        return
    if _network.is_client():
        _network.send_player_snapshot({
            "type": "select",
            "draft_index": _self_selected_draft_index,
            "player": _self_state.to_snapshot(),
            "claimed_count": _self_claimed_count
        })
    else:
        _send_match_snapshot()


func _auto_claim_missing_for_self() -> void:
    while _self_state.can_claim_card():
        var indexes := _available_draft_indexes(_remote_selected_draft_index)
        if indexes.is_empty():
            return
        var index: int = indexes[_ai_rng.randi_range(0, indexes.size() - 1)]
        if _self_state.claim_card(_draft_pool[index]):
            _draft_pool[index] = null
            _self_claimed_count += 1


func _on_card_dropped(hand_index: int, cell: Vector2i) -> void:
    var result := _self_state.place_from_hand(hand_index, cell)
    if not bool(result.get("ok", false)):
        _self_state.last_message = str(result.get("message", "放置失败。"))
        _refresh_all()
        return
    _after_self_successful_play()


func _on_hand_card_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2) -> void:
    if _drag_card != null or _self_state.game_over or _self_state.hand.is_empty() or _animating:
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
    if _game_mode == MODE_SINGLE:
        _play_singleplayer_opponent()
    var advanced := _try_start_next_round()
    _refresh_all()
    _send_match_snapshot()
    if advanced:
        _send_match_snapshot()


func _play_singleplayer_opponent() -> void:
    if _remote_state.game_over:
        return
    if _remote_claimed_count < GameState.HAND_SIZE:
        _ai_claim_cards(GameState.HAND_SIZE - _remote_claimed_count)
    if _remote_state.hand.is_empty():
        return
    _play_one_ai_card()
    if _self_round_done():
        while not _remote_state.hand.is_empty():
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
    if not _self_round_done() or not _remote_round_done():
        return false
    if _game_mode == MODE_ONLINE and _network.is_client():
        return false

    var advanced := _self_state.start_next_round()
    _remote_state.start_next_round()
    _self_claimed_count = 0
    _remote_claimed_count = 0
    _refresh_draft_pool()
    return advanced


func _self_round_done() -> bool:
    return _self_state.game_over or (_self_claimed_count >= GameState.HAND_SIZE and _self_state.hand.is_empty())


func _remote_round_done() -> bool:
    return _remote_state.game_over or (_remote_claimed_count >= GameState.HAND_SIZE and _remote_state.hand.is_empty())


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
    _start_new_match()
    _send_match_snapshot()


func _send_match_snapshot() -> void:
    if _game_mode == MODE_ONLINE and _network.is_client():
        _network.send_player_snapshot({
            "type": "player_state",
            "player": _self_state.to_snapshot(),
            "claimed_count": _self_claimed_count,
            "selected_index": _self_selected_draft_index
        })
        return

    _network.send_player_snapshot({
        "type": "state",
        "player": _self_state.to_snapshot(),
        "claimed_count": _self_claimed_count,
        "self_claimed_count": _remote_claimed_count,
        "self_selected_index": _remote_selected_draft_index,
        "remote_selected_index": _self_selected_draft_index,
        "draft_pool": _cards_to_snapshot(_draft_pool),
        "round_time_left": _round_time_left
    })


func _cards_to_snapshot(cards: Array) -> Array:
    var result := []
    for card in cards:
        result.append(null if card == null else card.to_snapshot())
    return result


func _cards_from_snapshot(cards: Variant) -> Array:
    var result := []
    if typeof(cards) != TYPE_ARRAY:
        return result
    for card_data in cards:
        result.append(null if typeof(card_data) != TYPE_DICTIONARY else CardData.from_snapshot(card_data))
    return result


func _refresh_all() -> void:
    _refresh_player(PLAYER_SELF)
    _refresh_player(PLAYER_REMOTE)
    _refresh_draft_view()
    _refresh_header()
    _refresh_timer()


func _refresh_player(player: int) -> void:
    var is_self := player == PLAYER_SELF
    var state := _self_state if is_self else _remote_state
    var board_view := _self_board_view if is_self else _remote_board_view
    var hand_view := _self_hand_view if is_self else _remote_hand_view
    board_view.refresh_board(state.board, is_self and not state.game_over and not state.hand.is_empty())
    hand_view.refresh(state.hand, state.game_over, is_self)
    if is_self:
        _self_restart_button.text = "重开"
    else:
        _remote_restart_button.text = "电脑" if _game_mode == MODE_SINGLE else "只读"


func _refresh_draft_view() -> void:
    if _draft_pool_view == null:
        return
    _sanitize_draft_selections()
    _draft_pool_view.refresh(_draft_pool, _game_mode == MODE_SINGLE or _network.has_remote_peer(), _self_selected_draft_index, _remote_selected_draft_index)


func _refresh_header() -> void:
    _score_label.text = "我 %04d    对方 %04d" % [_self_state.score, _remote_state.score]
    _message_label.text = "第 %d 轮 | 我抢 %d/%d，手牌 %d | 对方抢 %d/%d，手牌 %d\n我：%s\n对方：%s" % [
        _self_state.round_index,
        _self_claimed_count,
        GameState.HAND_SIZE,
        _self_state.hand.size(),
        _remote_claimed_count,
        GameState.HAND_SIZE,
        _remote_state.hand.size(),
        _self_state.last_message,
        _remote_state.last_message
    ]


func _refresh_timer() -> void:
    if _timer_label == null:
        return
    var seconds := int(ceil(_round_time_left))
    _timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
