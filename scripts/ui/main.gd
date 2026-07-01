extends Control

const PLAYER_ONE := 0
const PLAYER_TWO := 1
const MAX_TURNS_PER_PLAYER := 10
const PLAYER_NAMES := ["P1 主播", "P2 主播"]

var _states: Array = [GameState.new(), GameState.new()]
var _turns_taken: Array = [0, 0]
var _active_player: int = PLAYER_ONE
var _match_over := false

var _board_views: Array = []
var _hand_views: Array = []
var _player_panels: Array = []
var _player_score_labels: Array = []
var _player_turn_labels: Array = []
var _score_label: Label
var _round_label: Label
var _message_label: Label
var _comment_label: Label
var _restart_button: Button

var _drag_card: CardView = null
var _drag_player: int = -1
var _drag_hand_index: int = -1
var _drag_original_parent: Node = null
var _drag_original_index: int = -1
var _drag_offset := Vector2.ZERO
var _animating := false


func _ready() -> void:
	_build_ui()
	_start_match()


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
	background.color = Color(0.12, 0.13, 0.16)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 14)
	add_child(root)

	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 10)
	root.add_child(main_box)

	main_box.add_child(_build_header())

	var arena := HBoxContainer.new()
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 12)
	main_box.add_child(arena)

	for player in [PLAYER_ONE, PLAYER_TWO]:
		_build_player_panel(player, arena)


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _make_style(Color(0.96, 0.91, 0.79), Color(0.35, 0.21, 0.12), 3, 6))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)

	var title := Label.new()
	title.text = "直播间才艺热度 PK"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.18, 0.1, 0.06))
	title_box.add_child(title)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_font_size_override("font_size", 16)
	_message_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.12))
	title_box.add_child(_message_label)

	_comment_label = Label.new()
	_comment_label.custom_minimum_size = Vector2(300, 54)
	_comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comment_label.add_theme_font_size_override("font_size", 15)
	_comment_label.add_theme_color_override("font_color", Color(0.2, 0.16, 0.12))
	row.add_child(_comment_label)

	var status_box := VBoxContainer.new()
	status_box.custom_minimum_size = Vector2(320, 0)
	row.add_child(status_box)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 28)
	_score_label.add_theme_color_override("font_color", Color(0.14, 0.08, 0.04))
	status_box.add_child(_score_label)

	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 16)
	_round_label.add_theme_color_override("font_color", Color(0.33, 0.2, 0.11))
	status_box.add_child(_round_label)

	_restart_button = Button.new()
	_restart_button.text = "重开 PK"
	_restart_button.custom_minimum_size = Vector2(120, 46)
	_restart_button.pressed.connect(_on_restart_pressed)
	row.add_child(_restart_button)

	return header


func _build_player_panel(player: int, parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	_player_panels.append(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var player_header := HBoxContainer.new()
	player_header.add_theme_constant_override("separation", 10)
	box.add_child(player_header)

	var name_label := Label.new()
	name_label.text = PLAYER_NAMES[player]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.15, 0.09, 0.05))
	player_header.add_child(name_label)

	var score_label := Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 23)
	score_label.add_theme_color_override("font_color", Color(0.28, 0.12, 0.06))
	player_header.add_child(score_label)
	_player_score_labels.append(score_label)

	var turn_label := Label.new()
	turn_label.add_theme_font_size_override("font_size", 15)
	turn_label.add_theme_color_override("font_color", Color(0.32, 0.21, 0.12))
	box.add_child(turn_label)
	_player_turn_labels.append(turn_label)

	var play_row := HBoxContainer.new()
	play_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_row.add_theme_constant_override("separation", 10)
	box.add_child(play_row)

	var board_box := VBoxContainer.new()
	board_box.alignment = BoxContainer.ALIGNMENT_CENTER
	board_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_box.add_theme_constant_override("separation", 5)
	play_row.add_child(board_box)

	var bonus_label := Label.new()
	bonus_label.text = "最上排 / 最左列入场 +1"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 13)
	bonus_label.add_theme_color_override("font_color", Color(0.32, 0.2, 0.1))
	board_box.add_child(bonus_label)

	var field_frame := PanelContainer.new()
	field_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	field_frame.add_theme_stylebox_override("panel", _make_style(Color(0.28, 0.16, 0.1), Color(0.12, 0.08, 0.05), 4, 0))
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
	field_margin.add_child(board_view)
	board_view.build()
	_board_views.append(board_view)

	var hand_panel := PanelContainer.new()
	hand_panel.custom_minimum_size = Vector2(128, 0)
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_panel.add_theme_stylebox_override("panel", _make_style(Color(0.91, 0.68, 0.43), Color(0.46, 0.25, 0.13), 3, 4))
	play_row.add_child(hand_panel)

	var hand_margin := MarginContainer.new()
	hand_margin.add_theme_constant_override("margin_left", 9)
	hand_margin.add_theme_constant_override("margin_top", 9)
	hand_margin.add_theme_constant_override("margin_right", 9)
	hand_margin.add_theme_constant_override("margin_bottom", 9)
	hand_panel.add_child(hand_margin)

	var hand_box := VBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 8)
	hand_margin.add_child(hand_box)

	var hand_title := Label.new()
	hand_title.text = "手牌"
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_title.add_theme_font_size_override("font_size", 19)
	hand_title.add_theme_color_override("font_color", Color(0.2, 0.11, 0.06))
	hand_box.add_child(hand_title)

	var hand_view := HandView.new()
	hand_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_view.card_drag_started.connect(_on_hand_card_drag_started.bind(player))
	hand_box.add_child(hand_view)
	_hand_views.append(hand_view)


func _start_match() -> void:
	for player in [PLAYER_ONE, PLAYER_TWO]:
		var state: GameState = _states[player]
		state.start_new_game()
		state.last_message = "%s 已进入直播间。" % PLAYER_NAMES[player]
		_turns_taken[player] = 0
	_active_player = PLAYER_ONE
	_match_over = false
	_animating = false
	_message_label.text = "%s 先手，10 次行动内拼最高热度。" % PLAYER_NAMES[_active_player]
	_comment_label.text = "高能弹幕：开播了开播了。"
	_refresh_all()


func _on_hand_card_drag_started(card_view: CardView, hand_index: int, grab_position: Vector2, player: int) -> void:
	if _drag_card != null or _match_over or _animating:
		return
	if player != _active_player:
		_message_label.text = "现在轮到 %s 行动。" % PLAYER_NAMES[_active_player]
		return

	_drag_card = card_view
	_drag_player = player
	_drag_hand_index = hand_index
	_drag_original_parent = card_view.get_parent()
	_drag_original_index = card_view.get_index()
	_drag_offset = grab_position - card_view.global_position

	_drag_original_parent.remove_child(card_view)
	add_child(card_view)
	card_view.stop_hover_idle()
	card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_view.z_index = 100
	card_view.modulate.a = 0.94
	card_view.size = CardView.CARD_SIZE
	_move_drag_card(grab_position)


func _move_drag_card(mouse_position: Vector2) -> void:
	_drag_card.global_position = mouse_position - _drag_offset


func _finish_manual_drag(mouse_position: Vector2) -> void:
	if _drag_player < 0:
		_restore_manual_drag_card()
		_refresh_all()
		return

	var board_view: BoardView = _board_views[_drag_player]
	var cell := board_view.get_cell_at_global_position(mouse_position)
	if cell.x >= 0:
		var visual_board := _make_visual_board_before_drop(_drag_player, _drag_hand_index, cell)
		var state: GameState = _states[_drag_player]
		var result := state.place_from_hand(_drag_hand_index, cell)
		if bool(result.get("ok", false)):
			_turns_taken[_drag_player] += 1
			_drag_card.queue_free()
			var played_player := _drag_player
			_clear_manual_drag()
			await _play_place_result(played_player, visual_board, result)
			_after_successful_turn(played_player)
			return
		_message_label.text = str(result.get("message", "放置失败。"))

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
	_drag_player = -1
	_drag_hand_index = -1
	_drag_original_parent = null
	_drag_original_index = -1
	_drag_offset = Vector2.ZERO


func _play_place_result(player: int, visual_board: Array, result: Dictionary) -> void:
	var events: Array = result.get("events", [])
	var state: GameState = _states[player]
	_message_label.text = "%s：%s" % [PLAYER_NAMES[player], state.last_message]
	_comment_label.text = _build_comment(player, int(result.get("gained", 0)), int(result.get("chains", 0)))

	if events.is_empty():
		_refresh_all()
		return

	_animating = true
	_board_views[player].refresh_board(visual_board, false)
	_hand_views[player].refresh(state.hand, true)
	await _board_views[player].play_drop_events(events)
	_animating = false
	_refresh_all()


func _after_successful_turn(player: int) -> void:
	var state: GameState = _states[player]
	if state.game_over and not state.has_empty_cell():
		_finish_match(1 - player, "%s 舞台排满，%s 提前获胜。" % [PLAYER_NAMES[player], PLAYER_NAMES[1 - player]])
		return

	if _turns_taken[PLAYER_ONE] >= MAX_TURNS_PER_PLAYER and _turns_taken[PLAYER_TWO] >= MAX_TURNS_PER_PLAYER:
		_finish_by_score()
		return

	var next_player := 1 - player
	if _turns_taken[next_player] >= MAX_TURNS_PER_PLAYER:
		next_player = player
	_active_player = next_player
	_message_label.text = "轮到 %s 行动。" % PLAYER_NAMES[_active_player]
	_refresh_all()


func _finish_by_score() -> void:
	var p1: GameState = _states[PLAYER_ONE]
	var p2: GameState = _states[PLAYER_TWO]
	if p1.score > p2.score:
		_finish_match(PLAYER_ONE, "%s WIN，热度领先 %d。" % [PLAYER_NAMES[PLAYER_ONE], p1.score - p2.score])
	elif p2.score > p1.score:
		_finish_match(PLAYER_TWO, "%s WIN，热度领先 %d。" % [PLAYER_NAMES[PLAYER_TWO], p2.score - p1.score])
	else:
		_finish_match(-1, "PK 平局，双方热度打平。")


func _finish_match(winner: int, message: String) -> void:
	_match_over = true
	_active_player = -1
	_message_label.text = message
	if winner >= 0:
		_comment_label.text = "高能弹幕：%s 拿下本场 PK！" % PLAYER_NAMES[winner]
	else:
		_comment_label.text = "高能弹幕：这把居然平了。"
	_refresh_all()


func _make_visual_board_before_drop(player: int, hand_index: int, cell: Vector2i) -> Array:
	var state: GameState = _states[player]
	var visual_board := _clone_board(state.board)
	if hand_index < 0 or hand_index >= state.hand.size():
		return visual_board

	var played: CardData = state.hand[hand_index].clone()
	if played.is_normal():
		if cell.x == 0 or cell.y == 0:
			played.value += 1
		visual_board[cell.y][cell.x] = played

	return visual_board


func _clone_board(source_board: Array) -> Array:
	var cloned := []
	for y in range(GameState.BOARD_ROWS):
		var row := []
		for x in range(GameState.BOARD_COLUMNS):
			var card: CardData = source_board[y][x]
			row.append(null if card == null else card.clone())
		cloned.append(row)
	return cloned


func _refresh_all() -> void:
	var p1: GameState = _states[PLAYER_ONE]
	var p2: GameState = _states[PLAYER_TWO]
	_score_label.text = "%04d  :  %04d" % [p1.score, p2.score]
	if _match_over:
		_round_label.text = "PK 结束"
	else:
		_round_label.text = "第 %d / %d 轮  %s 行动" % [_current_round(), MAX_TURNS_PER_PLAYER, PLAYER_NAMES[_active_player]]
	_restart_button.text = "再来一局" if _match_over else "重开 PK"

	for player in [PLAYER_ONE, PLAYER_TWO]:
		var state: GameState = _states[player]
		var can_act: bool = player == _active_player and not _match_over and not _animating
		_board_views[player].refresh_board(state.board, can_act)
		_hand_views[player].refresh(state.hand, not can_act)
		_player_score_labels[player].text = "热度 %04d" % state.score
		_player_turn_labels[player].text = "行动 %d / %d" % [_turns_taken[player], MAX_TURNS_PER_PLAYER]
		_apply_player_panel_style(player, can_act)


func _current_round() -> int:
	var highest_turn: int = int(max(_turns_taken[PLAYER_ONE], _turns_taken[PLAYER_TWO]))
	return int(clamp(highest_turn + 1, 1, MAX_TURNS_PER_PLAYER))


func _build_comment(player: int, gained: int, chains: int) -> String:
	if gained <= 0:
		return "高能弹幕：%s 在铺垫，先别急。" % PLAYER_NAMES[player]
	if chains >= 2:
		return "高能弹幕：%s 打出 %d 连锁，热度 +%d！" % [PLAYER_NAMES[player], chains, gained]
	return "高能弹幕：%s 热度 +%d。" % [PLAYER_NAMES[player], gained]


func _apply_player_panel_style(player: int, active: bool) -> void:
	var panel: PanelContainer = _player_panels[player]
	var bg := Color(0.94, 0.77, 0.49) if active else Color(0.72, 0.76, 0.78)
	var border := Color(0.95, 0.37, 0.14) if active else Color(0.35, 0.38, 0.4)
	panel.add_theme_stylebox_override("panel", _make_style(bg, border, 4, 6))


func _on_restart_pressed() -> void:
	if _drag_card != null:
		_drag_card.queue_free()
		_clear_manual_drag()
	_start_match()


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
