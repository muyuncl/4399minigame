extends Control

const PlayerBoardStateScript := preload("res://scripts/core/player_board_state.gd")
const GameBalanceConfigScript := preload("res://scripts/config/game_balance_config.gd")
const LocalPropViewScript := preload("res://scripts/ui/local_prop_view.gd")

enum Phase {
	ROUND_START,
	CLAIM,
	PLACE
}

const POOL_SIZE := 10
const POOL_COLUMNS := 2
const BASKET_SIZE := 4
const HEAT_BAR_RECT := Rect2(40, 32, 1840, 64)
const HEAT_FULL_SWING_SCORE := 200.0
const CLAIM_DURATION := 15.0
const PLACE_DURATION := 30.0
const ROUND_DROP_DURATION := 1.0
const ROUND_START_DURATION := 2.0
const ROUND_UNLOCK_DURATION := 1.0
const POOL_CARD_SPAWN_Y := -108.0
const POOL_CARD_ROW_GAP := 118.0
const POOL_COVER_POSITION := Vector2.ZERO
const POOL_COVER_OFFSCREEN_POSITION := Vector2(0, -608)
const LATENCY_SAMPLE_INTERVAL := 1.0
const LATENCY_TIMEOUT_MS := 3000
const PROP_DEFINITIONS := [
	{"id": "remove", "label": "消", "name": "消除一张卡牌"},
	{"id": "plus_one", "label": "+1", "name": "目标卡牌数值 +1"},
	{"id": "minus_one", "label": "-1", "name": "目标卡牌数值 -1"}
]

var _design_root: Control
var _rng := RandomNumberGenerator.new()
var _local_side := 1
var _phase: Phase = Phase.ROUND_START
var _phase_time_left := 0.0
var _last_phase_sync_second := -1
var _round := 1
var _pool_cards: Array = []
var _last_new_pool_slots: Array[int] = []
var _last_pool_move_map: Dictionary = {}
var _pool_animation_id := 0
var _received_pool_animation_id := 0
var _last_played_pool_animation_id := -1
var _last_rendered_phase := -1
var _baskets := {1: [], 2: []}
var _props := {1: [], 2: []}
var _props_ready := {1: false, 2: false}
var _board_states := {
	1: PlayerBoardStateScript.new(),
	2: PlayerBoardStateScript.new()
}
var _scores := {1: 0, 2: 0}
var _match_started := false
var _last_action_message := ""
var _drag_sync_active := false
var _drag_sync_index := -1
var _drag_sync_source := ""
var _last_drag_sync_pos := Vector2.INF
var _latency_sample_timer := 0.0
var _latency_probe_id := 0
var _latency_pending := {}
var _latency_ms := -1
var _latency_last_sample_msec := 0

var _round_label: Label
var _phase_label: Label
var _p1_score_label: Label
var _p2_score_label: Label
var _public_pool_label: Label
var _status_label: Label
var _latency_label: Label
var _heat_left_fill: ColorRect
var _heat_right_fill: ColorRect
var _heat_center_marker: ColorRect
var _public_pool_container: Control
var _public_pool_cards_layer: Control
var _pool_lock_cover: ColorRect
var _p1_basket_container: Control
var _p2_basket_container: Control
var _p1_prop_item_layer: Control
var _p2_prop_item_layer: Control
var _p1_board_view: LocalBoardView
var _p2_board_view: LocalBoardView
var _remote_drag_ghost: LocalCardView
var _pool_cover_tween: Tween
var _prop_selection_dialog: ConfirmationDialog
var _prop_selection_checks: Array[CheckBox] = []
var _prop_selection_error_label: Label


func _ready() -> void:
	_rng.randomize()
	_local_side = _get_local_side()
	_build_ui()
	_build_prop_selection_dialog()
	_connect_multiplayer_signals()
	for side in [1, 2]:
		_board_states[side].reset()
	_status_label.text = "请选择 2 个本局道具。"
	resized.connect(_apply_design_scale)
	_apply_design_scale()
	call_deferred("_show_prop_selection_dialog")


func _process(delta: float) -> void:
	_update_latency_probe(delta)
	if _match_started and multiplayer.is_server() and _phase_time_left > 0.0:
		_phase_time_left = maxf(_phase_time_left - delta, 0.0)
		var current_second := int(ceil(_phase_time_left))
		if current_second != _last_phase_sync_second:
			_last_phase_sync_second = current_second
			_broadcast_state()
		if _phase_time_left <= 0.0:
			_on_host_phase_timer_finished()
	if _drag_sync_active:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drag_sync_active = false
			_remote_drag_end.rpc(_local_side)
			return
		var mouse_pos := get_global_mouse_position()
		if mouse_pos.distance_to(_last_drag_sync_pos) >= 10.0:
			_last_drag_sync_pos = mouse_pos
			_remote_drag_update.rpc(_local_side, _global_to_design_position(mouse_pos))


func _build_ui() -> void:
	var letterbox := ColorRect.new()
	letterbox.color = Color.BLACK
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(letterbox)

	_design_root = Control.new()
	_design_root.size = UiLayoutConfig.DESIGN_SIZE
	add_child(_design_root)

	var background := ColorRect.new()
	background.color = UiLayoutConfig.BACKGROUND_COLOR
	background.size = UiLayoutConfig.DESIGN_SIZE
	_design_root.add_child(background)

	_build_top_bar()
	_build_player_info()
	_build_lower_area()


func _build_top_bar() -> void:
	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(36, 28)
	top_bar.size = Vector2(1848, 72)
	top_bar.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.BLACK, UiLayoutConfig.LINE_COLOR, 4, 8))
	_design_root.add_child(top_bar)

	_heat_left_fill = ColorRect.new()
	_heat_left_fill.color = Color(0.95, 0.18, 0.12, 0.58)
	_heat_left_fill.position = Vector2(HEAT_BAR_RECT.position.x + HEAT_BAR_RECT.size.x * 0.5, HEAT_BAR_RECT.position.y)
	_heat_left_fill.size = Vector2.ZERO
	_design_root.add_child(_heat_left_fill)

	_heat_right_fill = ColorRect.new()
	_heat_right_fill.color = Color(0.16, 0.42, 0.96, 0.58)
	_heat_right_fill.position = Vector2(HEAT_BAR_RECT.position.x + HEAT_BAR_RECT.size.x * 0.5, HEAT_BAR_RECT.position.y)
	_heat_right_fill.size = Vector2.ZERO
	_design_root.add_child(_heat_right_fill)

	_heat_center_marker = ColorRect.new()
	_heat_center_marker.color = Color.WHITE
	_heat_center_marker.position = Vector2(HEAT_BAR_RECT.position.x + HEAT_BAR_RECT.size.x * 0.5 - 2, HEAT_BAR_RECT.position.y - 4)
	_heat_center_marker.size = Vector2(4, HEAT_BAR_RECT.size.y + 8)
	_design_root.add_child(_heat_center_marker)

	_p1_score_label = _make_label("0", 24, HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	_p1_score_label.position = Vector2(56, 48)
	_p1_score_label.size = Vector2(160, 34)
	_design_root.add_child(_p1_score_label)

	_p2_score_label = _make_label("0", 24, HORIZONTAL_ALIGNMENT_RIGHT, Color.WHITE)
	_p2_score_label.position = Vector2(1704, 48)
	_p2_score_label.size = Vector2(160, 34)
	_design_root.add_child(_p2_score_label)

	_round_label = _make_label("PK 01回合", 28, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_round_label.position = Vector2(850, 38)
	_round_label.size = Vector2(220, 52)
	_design_root.add_child(_round_label)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.position = Vector2(36, 112)
	back_button.size = Vector2(110, 36)
	back_button.pressed.connect(_on_back_pressed)
	_design_root.add_child(back_button)


func _build_player_info() -> void:
	var divider := ColorRect.new()
	divider.color = UiLayoutConfig.LINE_COLOR
	divider.position = Vector2(959, 100)
	divider.size = Vector2(2, 376)
	_design_root.add_child(divider)

	_add_player_name("P1 Host", Vector2(60, 116), false)
	_add_player_name("P2 Client", Vector2(1640, 116), true)
	_add_avatar(Vector2(416, 166))
	_add_avatar(Vector2(1414, 166))
	_add_prop_slots(Vector2(48, 304))
	_add_prop_slots(Vector2(1692, 304))

	_p1_prop_item_layer = Control.new()
	_p1_prop_item_layer.position = Vector2(48, 304)
	_p1_prop_item_layer.size = Vector2(180, 58)
	_design_root.add_child(_p1_prop_item_layer)

	_p2_prop_item_layer = Control.new()
	_p2_prop_item_layer.position = Vector2(1692, 304)
	_p2_prop_item_layer.size = Vector2(180, 58)
	_design_root.add_child(_p2_prop_item_layer)

	_phase_label = _make_label("", 36, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_phase_label.position = Vector2(720, 164)
	_phase_label.size = Vector2(480, 52)
	_design_root.add_child(_phase_label)

	_status_label = _make_label("", 20, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_status_label.position = Vector2(650, 228)
	_status_label.size = Vector2(620, 36)
	_design_root.add_child(_status_label)

	_latency_label = _make_label("RTT --", 18, HORIZONTAL_ALIGNMENT_CENTER, Color(0.72, 0.92, 1.0))
	_latency_label.position = Vector2(760, 264)
	_latency_label.size = Vector2(400, 30)
	_design_root.add_child(_latency_label)


func _build_lower_area() -> void:
	var lower_area := Control.new()
	lower_area.name = "LowerArea"
	lower_area.position = Vector2(0, 430)
	lower_area.size = Vector2(1920, 650)
	_design_root.add_child(lower_area)

	lower_area.add_child(_make_panel(Vector2(36, 28), Vector2(760, 612)))
	lower_area.add_child(_make_panel(Vector2(1124, 28), Vector2(760, 612)))
	lower_area.add_child(_make_panel(Vector2(806, 32), Vector2(308, 608)))

	_p1_board_view = LocalBoardView.new()
	_p1_board_view.position = Vector2(64, 50)
	_p1_board_view.size = Vector2(528, 552)
	_p1_board_view.card_dropped.connect(_on_p1_board_card_dropped)
	_p1_board_view.prop_dropped.connect(_on_p1_board_prop_dropped)
	lower_area.add_child(_p1_board_view)

	_p2_board_view = LocalBoardView.new()
	_p2_board_view.position = Vector2(1328, 50)
	_p2_board_view.size = Vector2(528, 552)
	_p2_board_view.card_dropped.connect(_on_p2_board_card_dropped)
	_p2_board_view.prop_dropped.connect(_on_p2_board_prop_dropped)
	lower_area.add_child(_p2_board_view)

	_p1_basket_container = Control.new()
	_p1_basket_container.position = Vector2(666, 134)
	_p1_basket_container.size = Vector2(78, 464)
	lower_area.add_child(_p1_basket_container)

	_p2_basket_container = Control.new()
	_p2_basket_container.position = Vector2(1176, 134)
	_p2_basket_container.size = Vector2(78, 464)
	lower_area.add_child(_p2_basket_container)

	_public_pool_label = _make_label("公共牌池 10", 20, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_public_pool_label.position = Vector2(855, -8)
	_public_pool_label.size = Vector2(214, 28)
	lower_area.add_child(_public_pool_label)

	_public_pool_container = Control.new()
	_public_pool_container.position = Vector2(806, 32)
	_public_pool_container.size = Vector2(308, 608)
	_public_pool_container.clip_contents = true
	lower_area.add_child(_public_pool_container)

	_public_pool_cards_layer = Control.new()
	_public_pool_cards_layer.size = _public_pool_container.size
	_public_pool_container.add_child(_public_pool_cards_layer)

	_pool_lock_cover = ColorRect.new()
	_pool_lock_cover.position = POOL_COVER_OFFSCREEN_POSITION
	_pool_lock_cover.size = _public_pool_container.size
	_pool_lock_cover.color = Color(0.05, 0.05, 0.05, 0.48)
	_pool_lock_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_pool_lock_cover.visible = false
	_public_pool_container.add_child(_pool_lock_cover)

	_remote_drag_ghost = LocalCardView.new()
	_remote_drag_ghost.size = Vector2(78, 104)
	_remote_drag_ghost.modulate = Color(1, 1, 1, 0.55)
	_remote_drag_ghost.visible = false
	_design_root.add_child(_remote_drag_ghost)


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _build_prop_selection_dialog() -> void:
	_prop_selection_dialog = ConfirmationDialog.new()
	_prop_selection_dialog.title = "选择 PVP 道具"
	_prop_selection_dialog.ok_button_text = "确认"
	_prop_selection_dialog.cancel_button_text = "返回"
	_prop_selection_dialog.exclusive = true
	_prop_selection_dialog.confirmed.connect(_on_prop_selection_confirmed)
	_prop_selection_dialog.canceled.connect(_on_back_pressed)
	_prop_selection_dialog.close_requested.connect(_on_back_pressed)
	add_child(_prop_selection_dialog)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 230)
	box.add_theme_constant_override("separation", 10)
	_prop_selection_dialog.add_child(box)

	var title_label := _make_label("选择 2 个本局可用道具", 22, HORIZONTAL_ALIGNMENT_LEFT, UiLayoutConfig.TEXT_COLOR)
	title_label.custom_minimum_size = Vector2(400, 36)
	box.add_child(title_label)

	_prop_selection_checks.clear()
	for prop_data in PROP_DEFINITIONS:
		var prop: Dictionary = prop_data
		var check := CheckBox.new()
		check.text = "%s  %s" % [str(prop["label"]), str(prop["name"])]
		check.add_theme_font_size_override("font_size", 18)
		check.toggled.connect(_on_prop_selection_toggled)
		box.add_child(check)
		_prop_selection_checks.append(check)

	_prop_selection_error_label = _make_label("还需要选择 2 个道具。", 16, HORIZONTAL_ALIGNMENT_LEFT, Color(0.65, 0.1, 0.1))
	_prop_selection_error_label.custom_minimum_size = Vector2(400, 28)
	box.add_child(_prop_selection_error_label)
	_update_prop_selection_state()


func _show_prop_selection_dialog() -> void:
	if _prop_selection_dialog == null:
		return
	_phase_label.text = "选择道具"
	_status_label.text = "请选择 2 个本局道具。"
	_prop_selection_dialog.popup_centered(Vector2(460, 300))
	_update_prop_selection_state()


func _on_prop_selection_toggled(_enabled: bool) -> void:
	_update_prop_selection_state()


func _update_prop_selection_state() -> void:
	if _prop_selection_dialog == null:
		return
	var selected_count := 0
	for check in _prop_selection_checks:
		if check.button_pressed:
			selected_count += 1
	var ready := selected_count == 2
	if _prop_selection_dialog.get_ok_button() != null:
		_prop_selection_dialog.get_ok_button().disabled = not ready
	if _prop_selection_error_label != null:
		if selected_count > 2:
			_prop_selection_error_label.text = "只能选择 2 个道具。"
		else:
			_prop_selection_error_label.text = "还需要选择 %d 个道具。" % max(2 - selected_count, 0)
		_prop_selection_error_label.visible = not ready


func _on_prop_selection_confirmed() -> void:
	var selected_ids := _selected_prop_ids_from_checks()
	if selected_ids.size() != 2:
		_show_prop_selection_dialog()
		return
	_props[_local_side] = _props_from_ids(selected_ids)
	_props_ready[_local_side] = true
	_refresh_prop_bars()
	if multiplayer.is_server():
		_host_set_player_props(_local_side, selected_ids)
	else:
		_status_label.text = "已选择道具，等待房主开局。"
		_request_set_player_props.rpc_id(1, _local_side, selected_ids)


func _selected_prop_ids_from_checks() -> Array[String]:
	var result: Array[String] = []
	for i in range(_prop_selection_checks.size()):
		if _prop_selection_checks[i].button_pressed:
			var prop: Dictionary = PROP_DEFINITIONS[i]
			result.append(str(prop["id"]))
	return result


@rpc("any_peer", "reliable")
func _request_set_player_props(side: int, prop_ids: Array) -> void:
	if multiplayer.is_server():
		_host_set_player_props(side, _string_array_from_wire(prop_ids))


func _host_set_player_props(side: int, prop_ids: Array[String]) -> void:
	if not multiplayer.is_server() or not _is_valid_side(side):
		return
	var selected_props := _props_from_ids(prop_ids)
	if selected_props.size() != 2:
		return
	_props[side] = selected_props
	_props_ready[side] = true

	if _is_solo_direct_scene() and side == 1 and not bool(_props_ready[2]):
		_props[2] = []
		_props_ready[2] = true

	if bool(_props_ready[1]) and bool(_props_ready[2]) and not _match_started:
		_host_start_match()
	else:
		_broadcast_state()


func _host_start_match() -> void:
	_match_started = true
	_round = 1
	_pool_cards.clear()
	for side in [1, 2]:
		_baskets[side] = []
		_board_states[side].reset()
		_scores[side] = 0
	_host_start_round()


func _host_start_round() -> void:
	_phase = Phase.ROUND_START
	_phase_time_left = ROUND_DROP_DURATION + ROUND_START_DURATION + ROUND_UNLOCK_DURATION
	_last_phase_sync_second = int(ceil(_phase_time_left))
	_last_new_pool_slots = _refill_pool_to_full()
	_last_pool_move_map = {}
	_pool_animation_id += 1
	_received_pool_animation_id = _pool_animation_id
	_broadcast_state()


func _on_host_phase_timer_finished() -> void:
	match _phase:
		Phase.ROUND_START:
			_host_begin_claim_phase()
		Phase.CLAIM:
			_host_auto_fill_baskets_from_pool()
			_host_begin_place_phase()
		Phase.PLACE:
			_host_auto_place_remaining_cards()
			if (_baskets[1] as Array).is_empty() and (_baskets[2] as Array).is_empty():
				_round += 1
				_host_start_round()
			else:
				_broadcast_state()


func _host_begin_claim_phase() -> void:
	_phase = Phase.CLAIM
	_phase_time_left = CLAIM_DURATION
	_last_phase_sync_second = int(ceil(_phase_time_left))
	_last_action_message = "抢牌阶段开始"
	_broadcast_state()


func _host_begin_place_phase() -> void:
	_phase = Phase.PLACE
	_phase_time_left = PLACE_DURATION
	_last_phase_sync_second = int(ceil(_phase_time_left))
	_last_action_message = "放牌阶段开始"
	_broadcast_state()


func _refill_pool_to_full() -> Array[int]:
	while _pool_cards.size() < POOL_SIZE:
		_pool_cards.append(null)
	var new_slots: Array[int] = []
	for i in range(POOL_SIZE):
		if _pool_cards[i] == null:
			_pool_cards[i] = _draw_card()
			new_slots.append(i)
	return new_slots


func _remove_pool_card_with_gravity(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _pool_cards.size() or _pool_cards[slot_index] == null:
		return {}
	var claimed_card: PvpCardData = _pool_cards[slot_index]
	var column := slot_index % POOL_COLUMNS
	var row := floori(float(slot_index) / float(POOL_COLUMNS))
	var move_map := {}
	for y in range(row, 0, -1):
		var from_index := (y - 1) * POOL_COLUMNS + column
		var to_index := y * POOL_COLUMNS + column
		_pool_cards[to_index] = _pool_cards[from_index]
		if _pool_cards[to_index] != null:
			move_map[to_index] = from_index
	_pool_cards[column] = null
	return {
		"card": claimed_card,
		"move_map": move_map
	}


func _draw_card() -> PvpCardData:
	return GameBalanceConfigScript.roll_card(_rng, _round)


func _host_auto_fill_baskets_from_pool() -> void:
	if not multiplayer.is_server():
		return
	var changed := false
	for side in [1, 2]:
		var basket: Array = _baskets[side]
		while basket.size() < BASKET_SIZE:
			var occupied_slots := _get_occupied_pool_slots()
			if occupied_slots.is_empty():
				break
			var pool_index: int = occupied_slots[_rng.randi_range(0, occupied_slots.size() - 1)]
			var removal := _remove_pool_card_with_gravity(pool_index)
			if removal.is_empty():
				break
			var claimed_card: PvpCardData = removal["card"]
			basket.append(claimed_card.clone())
			_last_pool_move_map = removal["move_map"]
			changed = true
	if changed:
		_last_new_pool_slots = []
		_pool_animation_id += 1
		_received_pool_animation_id = _pool_animation_id
		_last_action_message = "抢牌时间结束，系统补足篮子"


func _host_auto_place_remaining_cards() -> void:
	if not multiplayer.is_server():
		return
	var changed := false
	for side in [1, 2]:
		var basket: Array = _baskets[side]
		var state: Variant = _board_states[side]
		while not basket.is_empty():
			var target_cell := _find_first_empty_cell(state)
			if target_cell.x < 0:
				basket.clear()
				changed = true
				break
			var result: Dictionary = state.place_card(basket[0], target_cell)
			if not bool(result.get("ok", false)):
				basket.remove_at(0)
				changed = true
				continue
			basket.remove_at(0)
			_scores[side] = state.score
			changed = true
	if changed:
		_last_action_message = "放牌时间结束，系统处理剩余卡牌"


func _get_occupied_pool_slots() -> Array[int]:
	var slots: Array[int] = []
	for i in range(_pool_cards.size()):
		if _pool_cards[i] != null:
			slots.append(i)
	return slots


func _find_first_empty_cell(state: Variant) -> Vector2i:
	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			if state.board[y][x] == null:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _send_claim_request(pool_index: int) -> void:
	if multiplayer.is_server():
		_host_claim_card(_local_side, pool_index)
	else:
		_request_claim_card.rpc_id(1, _local_side, pool_index)


@rpc("any_peer", "reliable")
func _request_claim_card(side: int, pool_index: int) -> void:
	if multiplayer.is_server():
		_host_claim_card(side, pool_index)


func _host_claim_card(side: int, pool_index: int) -> void:
	if _phase != Phase.CLAIM or not _is_valid_side(side):
		return
	var basket: Array = _baskets[side]
	if basket.size() >= BASKET_SIZE:
		return
	var removal := _remove_pool_card_with_gravity(pool_index)
	if removal.is_empty():
		return
	var claimed_card: PvpCardData = removal["card"]
	basket.append(claimed_card.clone())
	_last_new_pool_slots = []
	_last_pool_move_map = removal["move_map"]
	_pool_animation_id += 1
	_received_pool_animation_id = _pool_animation_id
	if (_baskets[1] as Array).size() >= BASKET_SIZE and (_baskets[2] as Array).size() >= BASKET_SIZE:
		_host_begin_place_phase()
	else:
		_broadcast_state()


func _send_place_request(card_index: int, cell: Vector2i) -> void:
	if multiplayer.is_server():
		_host_place_card(_local_side, card_index, cell)
	else:
		_request_place_card.rpc_id(1, _local_side, card_index, cell)


@rpc("any_peer", "reliable")
func _request_place_card(side: int, card_index: int, cell: Vector2i) -> void:
	if multiplayer.is_server():
		_host_place_card(side, card_index, cell)


func _host_place_card(side: int, card_index: int, cell: Vector2i) -> void:
	if _phase != Phase.PLACE or not _is_valid_side(side):
		return
	var basket: Array = _baskets[side]
	if card_index < 0 or card_index >= basket.size():
		return
	var state: Variant = _board_states[side]
	var result: Dictionary = state.place_card(basket[card_index], cell)
	if not bool(result.get("ok", false)):
		return
	basket.remove_at(card_index)
	_scores[side] = state.score
	if (_baskets[1] as Array).is_empty() and (_baskets[2] as Array).is_empty():
		_round += 1
		_host_start_round()
		return
	_broadcast_state()


func _broadcast_state() -> void:
	if not multiplayer.is_server():
		return
	_apply_state.rpc(_make_state_snapshot())


@rpc("any_peer", "call_local", "reliable")
func _apply_state(snapshot: Dictionary) -> void:
	_local_side = _get_local_side()
	_round = int(snapshot.get("round", 1))
	_phase = int(snapshot.get("phase", Phase.CLAIM))
	_phase_time_left = float(snapshot.get("phase_time_left", 0.0))
	_scores[1] = int(snapshot.get("p1_score", 0))
	_scores[2] = int(snapshot.get("p2_score", 0))
	_match_started = bool(snapshot.get("match_started", false))
	_props_ready[1] = bool(snapshot.get("p1_props_ready", false))
	_props_ready[2] = bool(snapshot.get("p2_props_ready", false))
	_props[1] = _props_from_ids(_string_array_from_wire(snapshot.get("p1_props", [])))
	_props[2] = _props_from_ids(_string_array_from_wire(snapshot.get("p2_props", [])))
	_last_action_message = str(snapshot.get("last_action_message", ""))
	_received_pool_animation_id = int(snapshot.get("pool_animation_id", 0))
	_last_new_pool_slots = _int_array_from_wire(snapshot.get("new_pool_slots", []))
	_last_pool_move_map = _move_map_from_wire(snapshot.get("pool_move_map", {}))
	_pool_cards = _cards_from_wire(snapshot.get("pool", []))
	_baskets[1] = _cards_from_wire(snapshot.get("p1_basket", []))
	_baskets[2] = _cards_from_wire(snapshot.get("p2_basket", []))
	_board_states[1].board = _board_from_wire(snapshot.get("p1_board", []))
	_board_states[1].score = _scores[1]
	_board_states[2].board = _board_from_wire(snapshot.get("p2_board", []))
	_board_states[2].score = _scores[2]
	_refresh_all()


func _make_state_snapshot() -> Dictionary:
	return {
		"round": _round,
		"phase": int(_phase),
		"phase_time_left": _phase_time_left,
		"match_started": _match_started,
		"p1_score": int(_scores[1]),
		"p2_score": int(_scores[2]),
		"p1_props_ready": bool(_props_ready[1]),
		"p2_props_ready": bool(_props_ready[2]),
		"p1_props": _props_to_wire(_props[1]),
		"p2_props": _props_to_wire(_props[2]),
		"last_action_message": _last_action_message,
		"pool_animation_id": _pool_animation_id,
		"new_pool_slots": _last_new_pool_slots,
		"pool_move_map": _last_pool_move_map,
		"pool": _cards_to_wire(_pool_cards),
		"p1_basket": _cards_to_wire(_baskets[1]),
		"p2_basket": _cards_to_wire(_baskets[2]),
		"p1_board": _board_to_wire(_board_states[1].board),
		"p2_board": _board_to_wire(_board_states[2].board)
	}


func _refresh_all() -> void:
	if not _match_started:
		_round_label.text = "PK READY"
		_phase_label.text = "选择道具"
		_status_label.text = "等待双方选择道具 | P1 %s P2 %s" % [
			"OK" if bool(_props_ready[1]) else "--",
			"OK" if bool(_props_ready[2]) else "--"
		]
		_p1_score_label.text = str(_scores[1])
		_p2_score_label.text = str(_scores[2])
		_public_pool_label.text = "公共牌池 %d" % _pool_card_count()
		_refresh_heat_bar()
		_refresh_pool()
		_refresh_baskets()
		_refresh_prop_bars()
		_p1_board_view.refresh_board(_board_states[1].board)
		_p2_board_view.refresh_board(_board_states[2].board)
		_p1_board_view.set_drop_enabled(false)
		_p2_board_view.set_drop_enabled(false)
		_refresh_pool_cover()
		return
	_round_label.text = "PK %02d回合" % _round
	match _phase:
		Phase.ROUND_START:
			_phase_label.text = "回合开始 锁定 %.0fs" % ceil(_phase_time_left)
		Phase.CLAIM:
			_phase_label.text = "抢牌阶段 %.0fs" % ceil(_phase_time_left)
		Phase.PLACE:
			_phase_label.text = "放牌阶段 %.0fs" % ceil(_phase_time_left)
	var role_text := "Client 加入端"
	if multiplayer.is_server():
		role_text = "Host 权威端"
	_status_label.text = "你是 P%d | %s | P1篮:%d P2篮:%d" % [
		_local_side,
		role_text,
		(_baskets[1] as Array).size(),
		(_baskets[2] as Array).size()
	]
	_p1_score_label.text = str(_scores[1])
	_p2_score_label.text = str(_scores[2])
	_public_pool_label.text = "公共牌池 %d" % _pool_card_count()
	_refresh_heat_bar()
	_refresh_pool()
	_refresh_baskets()
	_refresh_prop_bars()
	_p1_board_view.refresh_board(_board_states[1].board)
	_p2_board_view.refresh_board(_board_states[2].board)
	_p1_board_view.set_drop_enabled(_phase == Phase.PLACE and _local_side == 1)
	_p2_board_view.set_drop_enabled(_phase == Phase.PLACE and _local_side == 2)
	_refresh_pool_cover()


func _refresh_heat_bar() -> void:
	var delta := float(int(_scores[1]) - int(_scores[2]))
	var swing_ratio: float = clampf(delta / HEAT_FULL_SWING_SCORE, -1.0, 1.0)
	var left_edge: float = HEAT_BAR_RECT.position.x
	var right_edge: float = HEAT_BAR_RECT.position.x + HEAT_BAR_RECT.size.x
	var center_x: float = left_edge + HEAT_BAR_RECT.size.x * (0.5 + swing_ratio * 0.5)
	_heat_left_fill.position = HEAT_BAR_RECT.position
	_heat_left_fill.size = Vector2(maxf(center_x - left_edge, 0.0), HEAT_BAR_RECT.size.y)
	_heat_right_fill.position = Vector2(center_x, HEAT_BAR_RECT.position.y)
	_heat_right_fill.size = Vector2(maxf(right_edge - center_x, 0.0), HEAT_BAR_RECT.size.y)
	_heat_center_marker.position = Vector2(center_x - 2.0, HEAT_BAR_RECT.position.y - 4.0)


func _refresh_pool() -> void:
	var should_play_pool_animation := _received_pool_animation_id != _last_played_pool_animation_id
	for child in _public_pool_cards_layer.get_children():
		child.queue_free()
	for i in range(_pool_cards.size()):
		if _pool_cards[i] == null:
			continue
		var card: PvpCardData = _pool_cards[i]
		var card_view := LocalCardView.new()
		card_view.position = _get_pool_card_position(i)
		card_view.size = Vector2(76, 98)
		card_view.set_card(card, true)
		card_view.set_interaction(_phase == Phase.CLAIM and (_baskets[_local_side] as Array).size() < BASKET_SIZE, false, "pvp_pool", i)
		card_view.card_clicked.connect(_on_pool_card_clicked)
		_public_pool_cards_layer.add_child(card_view)

		var target_position := _get_pool_card_position(i)
		if should_play_pool_animation and _last_pool_move_map.has(i):
			card_view.position = _get_pool_card_position(int(_last_pool_move_map[i]))
			var fall_tween := create_tween()
			fall_tween.tween_property(card_view, "position", target_position, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		elif should_play_pool_animation and i in _last_new_pool_slots:
			card_view.position = _get_pool_card_spawn_position(i, _last_new_pool_slots)
			var fall_tween := create_tween()
			fall_tween.tween_property(card_view, "position", target_position, ROUND_DROP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if should_play_pool_animation:
		_last_played_pool_animation_id = _received_pool_animation_id


func _pool_card_count() -> int:
	var count := 0
	for card in _pool_cards:
		if card != null:
			count += 1
	return count


func _refresh_pool_cover() -> void:
	if _pool_lock_cover == null:
		return

	if _phase != Phase.ROUND_START:
		if _last_rendered_phase == Phase.ROUND_START and _pool_lock_cover.visible:
			if _pool_cover_tween != null and _pool_cover_tween.is_running():
				_pool_cover_tween.kill()
			_pool_cover_tween = create_tween()
			_pool_cover_tween.tween_property(_pool_lock_cover, "position", POOL_COVER_OFFSCREEN_POSITION, ROUND_UNLOCK_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_pool_cover_tween.tween_callback(func() -> void: _pool_lock_cover.visible = false)
		else:
			_pool_lock_cover.position = POOL_COVER_OFFSCREEN_POSITION
			_pool_lock_cover.visible = false
		_last_rendered_phase = int(_phase)
		return

	_pool_lock_cover.visible = true
	if _last_rendered_phase != Phase.ROUND_START:
		if _pool_cover_tween != null and _pool_cover_tween.is_running():
			_pool_cover_tween.kill()
		_pool_lock_cover.position = POOL_COVER_OFFSCREEN_POSITION
		_pool_cover_tween = create_tween()
		_pool_cover_tween.tween_property(_pool_lock_cover, "position", POOL_COVER_POSITION, ROUND_DROP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_last_rendered_phase = int(_phase)


func _refresh_prop_bars() -> void:
	_refresh_prop_layer(_p1_prop_item_layer, _props[1], _local_side == 1)
	_refresh_prop_layer(_p2_prop_item_layer, _props[2], _local_side == 2)


func _refresh_prop_layer(layer: Control, props_value: Variant, interactive: bool) -> void:
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()
	var props: Array = props_value
	for i in range(3):
		var prop_view: Variant = LocalPropViewScript.new()
		prop_view.position = Vector2(i * 64, 0)
		prop_view.size = UiLayoutConfig.PROP_SLOT_SIZE
		layer.add_child(prop_view)
		if i < props.size():
			var prop: Dictionary = props[i]
			prop_view.set_prop(str(prop["id"]), str(prop["label"]), i, interactive and _match_started, "pvp_prop")
		else:
			prop_view.clear_prop()


func _refresh_baskets() -> void:
	_refresh_basket_layer(_p1_basket_container, 1)
	_refresh_basket_layer(_p2_basket_container, 2)


func _refresh_basket_layer(layer: Control, side: int) -> void:
	for child in layer.get_children():
		child.queue_free()
	var basket: Array = _baskets[side]
	for i in range(basket.size()):
		var card_view := LocalCardView.new()
		card_view.position = Vector2(0, i * 120)
		card_view.size = Vector2(78, 104)
		card_view.set_card(basket[i], false)
		card_view.set_interaction(false, _phase == Phase.PLACE and side == _local_side, "pvp_basket", i)
		card_view.card_drag_started.connect(_on_local_card_drag_started)
		layer.add_child(card_view)


func _on_pool_card_clicked(card_view: LocalCardView) -> void:
	_send_claim_request(card_view.card_index)


func _on_p1_board_card_dropped(card_index: int, cell: Vector2i) -> void:
	if _local_side == 1:
		_send_place_request(card_index, cell)


func _on_p2_board_card_dropped(card_index: int, cell: Vector2i) -> void:
	if _local_side == 2:
		_send_place_request(card_index, cell)


func _on_p1_board_prop_dropped(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if _local_side == 1:
		_send_prop_request(prop_id, prop_index, cell)


func _on_p2_board_prop_dropped(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if _local_side == 2:
		_send_prop_request(prop_id, prop_index, cell)


func _send_prop_request(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if multiplayer.is_server():
		_host_use_prop(_local_side, prop_id, prop_index, cell)
	else:
		_request_use_prop.rpc_id(1, _local_side, prop_id, prop_index, cell)


@rpc("any_peer", "reliable")
func _request_use_prop(side: int, prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if multiplayer.is_server():
		_host_use_prop(side, prop_id, prop_index, cell)


func _host_use_prop(side: int, prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if not _match_started or not _is_valid_side(side):
		return
	var props: Array = _props[side]
	if prop_index < 0 or prop_index >= props.size():
		return
	var prop: Dictionary = props[prop_index]
	if str(prop.get("id", "")) != prop_id:
		return
	var state: Variant = _board_states[side]
	var result: Dictionary = state.apply_prop(prop_id, cell)
	if not bool(result.get("ok", false)):
		return
	props.remove_at(prop_index)
	_scores[side] = state.score
	_last_action_message = "P%d used %s" % [side, str(prop.get("label", ""))]
	_broadcast_state()


func _on_local_card_drag_started(source: String, index: int, mouse_global_position: Vector2) -> void:
	if source != "pvp_basket":
		return
	var basket: Array = _baskets[_local_side]
	if index < 0 or index >= basket.size():
		return
	_drag_sync_active = true
	_drag_sync_index = index
	_drag_sync_source = source
	_last_drag_sync_pos = mouse_global_position
	_remote_drag_start.rpc(_local_side, index, _card_to_wire(basket[index]), _global_to_design_position(mouse_global_position))


@rpc("any_peer", "call_remote", "unreliable")
func _remote_drag_start(side: int, _index: int, card_data: Dictionary, design_position: Vector2) -> void:
	if side == _local_side:
		return
	_remote_drag_ghost.set_card(_card_from_wire(card_data), false)
	_remote_drag_ghost.position = design_position - _remote_drag_ghost.size * 0.5
	_remote_drag_ghost.visible = true


@rpc("any_peer", "call_remote", "unreliable")
func _remote_drag_update(side: int, design_position: Vector2) -> void:
	if side == _local_side:
		return
	_remote_drag_ghost.position = design_position - _remote_drag_ghost.size * 0.5
	_remote_drag_ghost.visible = true


@rpc("any_peer", "call_remote", "unreliable")
func _remote_drag_end(side: int) -> void:
	if side == _local_side:
		return
	_remote_drag_ghost.visible = false


func _update_latency_probe(delta: float) -> void:
	_latency_sample_timer -= delta
	if _latency_sample_timer <= 0.0:
		_latency_sample_timer = LATENCY_SAMPLE_INTERVAL
		_send_latency_probe()
	_refresh_latency_label()


func _send_latency_probe() -> void:
	var target_peer_id := _get_latency_target_peer_id()
	if target_peer_id <= 0:
		_latency_ms = -1
		_latency_pending.clear()
		return
	_latency_probe_id += 1
	var sent_msec := Time.get_ticks_msec()
	_latency_pending[_latency_probe_id] = sent_msec
	_latency_ping.rpc_id(target_peer_id, _latency_probe_id, sent_msec)

	var stale_ids := []
	for probe_id in _latency_pending.keys():
		if sent_msec - int(_latency_pending[probe_id]) > LATENCY_TIMEOUT_MS:
			stale_ids.append(probe_id)
	for probe_id in stale_ids:
		_latency_pending.erase(probe_id)
	if _latency_pending.size() > 0 and Time.get_ticks_msec() - _latency_last_sample_msec > LATENCY_TIMEOUT_MS:
		_latency_ms = -2


@rpc("any_peer", "call_remote", "unreliable")
func _latency_ping(probe_id: int, sent_msec: int) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 0:
		return
	_latency_pong.rpc_id(sender_id, probe_id, sent_msec)


@rpc("any_peer", "call_remote", "unreliable")
func _latency_pong(probe_id: int, sent_msec: int) -> void:
	if not _latency_pending.has(probe_id):
		return
	_latency_pending.erase(probe_id)
	_latency_ms = max(0, Time.get_ticks_msec() - sent_msec)
	_latency_last_sample_msec = Time.get_ticks_msec()
	_refresh_latency_label()


func _refresh_latency_label() -> void:
	if _latency_label == null:
		return
	var target_peer_id := _get_latency_target_peer_id()
	if target_peer_id <= 0:
		_latency_label.text = "RTT --"
		_latency_label.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
		return
	if _latency_ms == -2:
		_latency_label.text = "RTT Timeout"
		_latency_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.3))
		return
	if _latency_ms < 0:
		_latency_label.text = "RTT measuring..."
		_latency_label.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
		return
	_latency_label.text = "RTT %d ms" % _latency_ms
	var color := Color(0.52, 1.0, 0.58)
	if _latency_ms >= 120:
		color = Color(1.0, 0.42, 0.3)
	elif _latency_ms >= 60:
		color = Color(1.0, 0.86, 0.32)
	_latency_label.add_theme_color_override("font_color", color)


func _get_latency_target_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return -1
	if multiplayer.is_server():
		var peers := multiplayer.get_peers()
		if peers.is_empty():
			return -1
		return int(peers[0])
	return 1


func _get_pool_card_position(index: int) -> Vector2:
	return Vector2(56 + (index % POOL_COLUMNS) * 120, 20 + floori(float(index) / float(POOL_COLUMNS)) * POOL_CARD_ROW_GAP)


func _get_pool_card_spawn_position(index: int, new_slots: Array[int]) -> Vector2:
	var target_position := _get_pool_card_position(index)
	var column := index % POOL_COLUMNS
	var column_queue_index := 0
	for slot in new_slots:
		if slot == index:
			break
		if slot % POOL_COLUMNS == column:
			column_queue_index += 1
	return Vector2(target_position.x, POOL_CARD_SPAWN_Y - column_queue_index * POOL_CARD_ROW_GAP)


func _cards_to_wire(cards: Array) -> Array:
	var result := []
	for card in cards:
		if card == null:
			result.append(null)
		else:
			result.append(_card_to_wire(card))
	return result


func _cards_from_wire(data: Array) -> Array:
	var result := []
	for card_data in data:
		if card_data == null:
			result.append(null)
		else:
			result.append(_card_from_wire(card_data))
	return result


func _props_to_wire(props_value: Variant) -> Array:
	var result := []
	var props: Array = props_value
	for prop_value in props:
		var prop: Dictionary = prop_value
		result.append(str(prop.get("id", "")))
	return result


func _props_from_ids(prop_ids: Array[String]) -> Array:
	var result: Array[Dictionary] = []
	for prop_id in prop_ids:
		var prop := _find_prop_definition(prop_id)
		if not prop.is_empty():
			result.append(prop)
	return result


func _find_prop_definition(prop_id: String) -> Dictionary:
	for prop_value in PROP_DEFINITIONS:
		var prop: Dictionary = prop_value
		if str(prop.get("id", "")) == prop_id:
			return prop.duplicate()
	return {}


func _string_array_from_wire(data: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(data) != TYPE_ARRAY:
		return result
	for value in data:
		result.append(str(value))
	return result


func _int_array_from_wire(data: Array) -> Array[int]:
	var result: Array[int] = []
	for value in data:
		result.append(int(value))
	return result


func _move_map_from_wire(data: Dictionary) -> Dictionary:
	var result := {}
	for key in data.keys():
		result[int(key)] = int(data[key])
	return result


func _card_to_wire(card: PvpCardData) -> Dictionary:
	if card == null:
		return {}
	return {
		"type_id": card.type_id,
		"label": card.label,
		"short_label": card.short_label,
		"value": card.value,
		"color": card.color,
		"art_path": card.art_path
	}


func _card_from_wire(data: Dictionary) -> PvpCardData:
	return PvpCardData.create(
		str(data.get("type_id", "")),
		str(data.get("label", "")),
		str(data.get("short_label", "")),
		int(data.get("value", 1)),
		data.get("color", Color.WHITE),
		str(data.get("art_path", ""))
	)


func _board_to_wire(board: Array) -> Array:
	var result := []
	for y in range(UiLayoutConfig.BOARD_ROWS):
		var row := []
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			if board[y][x] == null:
				row.append(null)
			else:
				row.append(_card_to_wire(board[y][x]))
		result.append(row)
	return result


func _board_from_wire(data: Array) -> Array:
	var result := []
	for y in range(UiLayoutConfig.BOARD_ROWS):
		var row := []
		var source_row: Array = []
		if y < data.size():
			source_row = data[y]
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			var cell_data = null
			if x < source_row.size():
				cell_data = source_row[x]
			if cell_data == null:
				row.append(null)
			else:
				row.append(_card_from_wire(cell_data))
		result.append(row)
	return result


func _is_valid_side(side: int) -> bool:
	return side == 1 or side == 2


func _is_solo_direct_scene() -> bool:
	return multiplayer.multiplayer_peer == null


func _get_local_side() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	if multiplayer.get_unique_id() == 1:
		return 1
	return 2


func _global_to_design_position(mouse_global_position: Vector2) -> Vector2:
	var canvas_transform := _design_root.get_global_transform_with_canvas()
	return canvas_transform.affine_inverse() * mouse_global_position


func _add_player_name(text: String, pos: Vector2, align_right: bool) -> void:
	var label := _make_label(text, 26, HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	label.position = pos
	label.size = Vector2(260, 34)
	_design_root.add_child(label)

	var line := ColorRect.new()
	line.color = UiLayoutConfig.LINE_COLOR
	line.position = Vector2(pos.x + (80 if align_right else 0), pos.y + 40)
	line.size = Vector2(140, 3)
	_design_root.add_child(line)


func _add_avatar(pos: Vector2) -> void:
	var head := PanelContainer.new()
	head.position = pos
	head.size = UiLayoutConfig.AVATAR_HEAD_SIZE
	head.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.WHITE, Color.WHITE, 0, 64))
	_design_root.add_child(head)

	var body := Polygon2D.new()
	body.color = Color.WHITE
	body.polygon = PackedVector2Array([Vector2(pos.x + 20, pos.y + 134), Vector2(pos.x + 90, pos.y + 134), Vector2(pos.x + 55, pos.y + 39)])
	_design_root.add_child(body)


func _add_prop_slots(pos: Vector2) -> void:
	for i in range(3):
		var slot := PanelContainer.new()
		slot.position = pos + Vector2(i * 64, 0)
		slot.size = UiLayoutConfig.PROP_SLOT_SIZE
		slot.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.WHITE, Color.WHITE, 0, 32))
		_design_root.add_child(slot)


func _make_panel(pos: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color(1, 1, 1, 0.18), UiLayoutConfig.LINE_COLOR, 3, 8))
	return panel


func _apply_design_scale() -> void:
	if _design_root == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(
		viewport_size.x / UiLayoutConfig.DESIGN_SIZE.x,
		viewport_size.y / UiLayoutConfig.DESIGN_SIZE.y
	)
	_design_root.scale = Vector2(scale_factor, scale_factor)
	_design_root.position = (viewport_size - UiLayoutConfig.DESIGN_SIZE * scale_factor) * 0.5


func _make_label(text: String, font_size: int, alignment: HorizontalAlignment, color: Color = UiLayoutConfig.TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_peer_disconnected(_peer_id: int) -> void:
	_status_label.text = "对方已断开。"


func _on_back_pressed() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
