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
const POOL_ROWS := 5
const BASKET_SIZE := 4
const ROUND_START_DURATION := 2.0
const CLAIM_DURATION := 15.0
const PLACE_DURATION := 30.0
const ROUND_DROP_DURATION := 1.0
const ROUND_UNLOCK_DURATION := 1.0
const POOL_CARD_SPAWN_Y := -108.0
const POOL_CARD_ROW_GAP := 118.0
const POOL_COVER_POSITION := Vector2.ZERO
const POOL_COVER_OFFSCREEN_POSITION := Vector2(0, -608)
const HEAT_BAR_RECT := Rect2(40, 32, 1840, 64)
const HEAT_FULL_SWING_SCORE := 200.0
const COMEBACK_TRIGGER_RATIO := 0.3
const PROP_DEFINITIONS := [
	{"id": "remove", "label": "消", "name": "消除一张卡牌"},
	{"id": "plus_one", "label": "+1", "name": "目标卡牌数值 +1"},
	{"id": "minus_one", "label": "-1", "name": "目标卡牌数值 -1"}
]

var _design_root: Control
var _pool_cards: Array[PvpCardData] = []
var _basket_cards: Array[PvpCardData] = []
var _board_state: Variant = PlayerBoardStateScript.new()
var _p2_props: Array[Dictionary] = []
var _phase: Phase = Phase.ROUND_START
var _phase_time_left: float = 0.0
var _round: int = 1
var _p2_score: int = 0
var _rng := RandomNumberGenerator.new()
var _game_over: bool = false
var _is_resolving: bool = false
var _prop_use_in_progress: bool = false
var _p1_comeback_awarded: bool = false
var _p2_comeback_awarded: bool = false

var _round_label: Label
var _timer_label: Label
var _center_message_label: Label
var _p1_score_label: Label
var _p2_score_label: Label
var _public_pool_label: Label
var _heat_left_fill: ColorRect
var _heat_right_fill: ColorRect
var _heat_center_marker: ColorRect
var _comeback_notice_label: Label
var _public_pool_container: Control
var _public_pool_cards_layer: Control
var _basket_container: Control
var _opponent_basket_container: Control
var _prop_item_layer: Control
var _pool_lock_cover: ColorRect
var _board_view: LocalBoardView
var _opponent_board_view: LocalBoardView
var _game_over_dialog: AcceptDialog
var _prop_selection_dialog: ConfirmationDialog
var _prop_selection_checks: Array[CheckBox] = []
var _prop_selection_error_label: Label
var _selected_props: Array[Dictionary] = []
var _initial_selected_prop_ids: Array[String] = []
var _opponent_prop_item_layer: Control
var _heat_tween: Tween


func _ready() -> void:
	_rng.randomize()
	_board_state.reset()
	_build_ui()
	_build_prop_selection_dialog()
	resized.connect(_apply_design_scale)
	_apply_design_scale()
	call_deferred("_show_prop_selection_dialog")


func _process(delta: float) -> void:
	if _game_over or _is_resolving:
		return
	if _phase_time_left <= 0.0:
		return

	_phase_time_left = maxf(_phase_time_left - delta, 0.0)
	_update_timer_label()
	if _phase_time_left <= 0.0:
		_on_phase_timer_finished()


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
	_build_game_over_dialog()


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

	_round_label = _make_label("PK 00回合", 28, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_round_label.position = Vector2(850, 38)
	_round_label.size = Vector2(220, 52)
	_design_root.add_child(_round_label)

	_comeback_notice_label = _make_label("", 22, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.92, 0.35))
	_comeback_notice_label.position = Vector2(720, 100)
	_comeback_notice_label.size = Vector2(480, 34)
	_comeback_notice_label.visible = false
	_design_root.add_child(_comeback_notice_label)

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

	_add_player_name("P1 昵称", Vector2(60, 116), false)
	_add_player_name("P2 昵称", Vector2(1640, 116), true)
	_add_avatar(Vector2(416, 166), false)
	_add_avatar(Vector2(1414, 166), true)
	_add_prop_slots(Vector2(48, 304))
	_add_prop_slots(Vector2(1692, 304))
	_prop_item_layer = Control.new()
	_prop_item_layer.position = Vector2(48, 304)
	_prop_item_layer.size = Vector2(180, 58)
	_design_root.add_child(_prop_item_layer)
	_opponent_prop_item_layer = Control.new()
	_opponent_prop_item_layer.position = Vector2(1692, 304)
	_opponent_prop_item_layer.size = Vector2(180, 58)
	_design_root.add_child(_opponent_prop_item_layer)
	_refresh_prop_bar()

	var p1_barrage := _make_label("高能弹幕", 20, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	p1_barrage.position = Vector2(270, 246)
	p1_barrage.size = Vector2(180, 28)
	_design_root.add_child(p1_barrage)

	var p2_barrage := _make_label("高能弹幕", 20, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	p2_barrage.position = Vector2(1470, 246)
	p2_barrage.size = Vector2(180, 28)
	_design_root.add_child(p2_barrage)

	_timer_label = _make_label("00:00", 72, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_timer_label.position = Vector2(770, 162)
	_timer_label.size = Vector2(380, 96)
	_design_root.add_child(_timer_label)

	_center_message_label = _make_label("", 20, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	_center_message_label.position = Vector2(720, 264)
	_center_message_label.size = Vector2(480, 38)
	_design_root.add_child(_center_message_label)

	var p1_gift := _make_label("xxx\n送xxx x个", 16, HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	p1_gift.position = Vector2(108, 186)
	p1_gift.size = Vector2(160, 58)
	_design_root.add_child(p1_gift)

	var p2_gift := _make_label("xxx\n送xxx x个", 16, HORIZONTAL_ALIGNMENT_RIGHT, Color.WHITE)
	p2_gift.position = Vector2(1652, 186)
	p2_gift.size = Vector2(160, 58)
	_design_root.add_child(p2_gift)


func _build_lower_area() -> void:
	var lower_area := Control.new()
	lower_area.name = "LowerArea"
	lower_area.position = Vector2(0, 430)
	lower_area.size = Vector2(1920, 650)
	_design_root.add_child(lower_area)

	var p1_area := _make_panel(Vector2(36, 28), Vector2(760, 612))
	lower_area.add_child(p1_area)
	var p2_area := _make_panel(Vector2(1124, 28), Vector2(760, 612))
	lower_area.add_child(p2_area)
	var pool_panel := _make_panel(Vector2(806, 32), Vector2(308, 608))
	lower_area.add_child(pool_panel)

	_board_view = LocalBoardView.new()
	_board_view.position = Vector2(64, 50)
	_board_view.size = Vector2(528, 552)
	_board_view.set_drop_enabled(false)
	_board_view.card_dropped.connect(_on_board_card_dropped)
	_board_view.prop_dropped.connect(_on_board_prop_dropped)
	lower_area.add_child(_board_view)

	_opponent_board_view = LocalBoardView.new()
	_opponent_board_view.position = Vector2(1328, 50)
	_opponent_board_view.size = Vector2(528, 552)
	_opponent_board_view.set_drop_enabled(false)
	lower_area.add_child(_opponent_board_view)

	_basket_container = Control.new()
	_basket_container.position = Vector2(666, 134)
	_basket_container.size = Vector2(78, 464)
	lower_area.add_child(_basket_container)

	_opponent_basket_container = Control.new()
	_opponent_basket_container.position = Vector2(1176, 134)
	_opponent_basket_container.size = Vector2(78, 464)
	lower_area.add_child(_opponent_basket_container)

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


func _build_game_over_dialog() -> void:
	_game_over_dialog = AcceptDialog.new()
	_game_over_dialog.title = "游戏结束"
	_game_over_dialog.dialog_text = "无剩余空位，游戏结束"
	_game_over_dialog.exclusive = true
	_game_over_dialog.confirmed.connect(_on_back_pressed)
	add_child(_game_over_dialog)


func _build_prop_selection_dialog() -> void:
	_prop_selection_dialog = ConfirmationDialog.new()
	_prop_selection_dialog.title = "选择测试道具"
	_prop_selection_dialog.ok_button_text = "开始测试"
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
	_center_message_label.text = "请选择 2 个测试道具。"
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
	_selected_props.clear()
	_initial_selected_prop_ids.clear()
	for i in range(_prop_selection_checks.size()):
		if _prop_selection_checks[i].button_pressed:
			var prop := (PROP_DEFINITIONS[i] as Dictionary).duplicate()
			_selected_props.append(prop)
			_initial_selected_prop_ids.append(str(prop["id"]))
	if _selected_props.size() != 2:
		_show_prop_selection_dialog()
		return
	_refresh_prop_bar()
	_start_round_start_phase()


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


func _add_avatar(pos: Vector2, mirrored: bool) -> void:
	var head := PanelContainer.new()
	head.position = pos
	head.size = UiLayoutConfig.AVATAR_HEAD_SIZE
	head.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.WHITE, Color.WHITE, 0, 64))
	_design_root.add_child(head)

	var body := Polygon2D.new()
	body.color = Color.WHITE
	if mirrored:
		body.polygon = PackedVector2Array([Vector2(pos.x + 20, pos.y + 134), Vector2(pos.x + 90, pos.y + 134), Vector2(pos.x + 55, pos.y + 39)])
	else:
		body.polygon = PackedVector2Array([Vector2(pos.x + 20, pos.y + 134), Vector2(pos.x + 90, pos.y + 134), Vector2(pos.x + 55, pos.y + 39)])
	_design_root.add_child(body)


func _add_prop_slots(pos: Vector2) -> void:
	for i in range(3):
		var slot := PanelContainer.new()
		slot.position = pos + Vector2(i * 64, 0)
		slot.size = UiLayoutConfig.PROP_SLOT_SIZE
		slot.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.WHITE, Color.WHITE, 0, 32))
		_design_root.add_child(slot)


func _refresh_prop_bar() -> void:
	if _prop_item_layer == null:
		return
	_refresh_prop_layer(_prop_item_layer, _selected_props, true)
	_refresh_prop_layer(_opponent_prop_item_layer, _p2_props, false)


func _refresh_prop_layer(layer: Control, props: Array[Dictionary], interactive: bool) -> void:
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()

	for i in range(3):
		var prop_view: Variant = LocalPropViewScript.new()
		prop_view.position = Vector2(i * 64, 0)
		prop_view.size = UiLayoutConfig.PROP_SLOT_SIZE
		layer.add_child(prop_view)
		if i < props.size():
			var prop: Dictionary = props[i]
			var can_drag := interactive and not _game_over and not _prop_use_in_progress and (not _is_resolving or _phase == Phase.ROUND_START)
			prop_view.set_prop(str(prop["id"]), str(prop["label"]), i, can_drag)
		else:
			prop_view.clear_prop()


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


func _start_round_start_phase() -> void:
	if _game_over:
		return
	_phase = Phase.ROUND_START
	_is_resolving = true
	_phase_time_left = ROUND_DROP_DURATION + ROUND_START_DURATION + ROUND_UNLOCK_DURATION
	var new_card_slots: Array[int] = _refill_pool_to_full()
	_round_label.text = "PK %02d回合" % _round
	_update_timer_label()
	_center_message_label.text = "回合开始：公共牌池刷新中。"
	_public_pool_label.text = "公共牌池 %d" % _pool_card_count()
	_board_view.set_drop_enabled(false)
	_refresh_all(new_card_slots)
	_play_pool_lock_cover_in()
	await _wait_round_start_segment(ROUND_DROP_DURATION)

	_phase_time_left = ROUND_START_DURATION
	_update_timer_label()
	_center_message_label.text = "牌池锁定：观察牌面，暂时不能抢牌。"
	await _wait_round_start_segment(ROUND_START_DURATION)

	_phase_time_left = ROUND_UNLOCK_DURATION
	_update_timer_label()
	_center_message_label.text = "锁定解除中。"
	_play_pool_lock_cover_out()
	await _wait_round_start_segment(ROUND_UNLOCK_DURATION)
	_pool_lock_cover.visible = false
	_pool_lock_cover.position = POOL_COVER_OFFSCREEN_POSITION
	_is_resolving = false
	_start_claim_phase()


func _start_claim_phase() -> void:
	if _game_over:
		return
	_phase = Phase.CLAIM
	_phase_time_left = CLAIM_DURATION
	_update_timer_label()
	_center_message_label.text = "抢牌阶段：点击中间牌池，抢满 4 张。"
	_board_view.set_drop_enabled(false)
	_refresh_all()


func _start_place_phase(pool_move_map: Dictionary = {}) -> void:
	if _game_over:
		return
	_phase = Phase.PLACE
	_phase_time_left = PLACE_DURATION
	_update_timer_label()
	_center_message_label.text = "放置阶段：拖动左侧篮子卡牌到棋盘。"
	_board_view.set_drop_enabled(true)
	_refresh_all([], pool_move_map)


func _end_round() -> void:
	if _game_over:
		return
	_round += 1
	_start_round_start_phase()


func _on_phase_timer_finished() -> void:
	match _phase:
		Phase.ROUND_START:
			_start_claim_phase()
		Phase.CLAIM:
			_auto_fill_basket_from_pool()
			_start_place_phase()
		Phase.PLACE:
			await _auto_place_remaining_cards()


func _update_timer_label() -> void:
	_timer_label.text = _format_time(_phase_time_left)


func _format_time(seconds: float) -> String:
	var total_seconds: int = int(ceil(seconds))
	var minutes: int = int(total_seconds / 60)
	var secs: int = total_seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _ensure_pool_slots() -> void:
	while _pool_cards.size() < POOL_SIZE:
		_pool_cards.append(null)


func _refill_pool_to_full() -> Array[int]:
	_ensure_pool_slots()
	var new_card_slots: Array[int] = []
	for i in range(POOL_SIZE):
		if _pool_cards[i] == null:
			_pool_cards[i] = _draw_card()
			new_card_slots.append(i)
	return new_card_slots


func _pool_card_count() -> int:
	var count := 0
	for card in _pool_cards:
		if card != null:
			count += 1
	return count


func _get_occupied_pool_slots() -> Array[int]:
	_ensure_pool_slots()
	var occupied_slots: Array[int] = []
	for i in range(POOL_SIZE):
		if _pool_cards[i] != null:
			occupied_slots.append(i)
	return occupied_slots


func _remove_pool_card_with_gravity(slot_index: int) -> Dictionary:
	_ensure_pool_slots()
	if slot_index < 0 or slot_index >= POOL_SIZE or _pool_cards[slot_index] == null:
		return {}

	var claimed_card: PvpCardData = _pool_cards[slot_index]
	var column := slot_index % POOL_COLUMNS
	var row := int(slot_index / POOL_COLUMNS)
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
		"move_map": move_map,
	}


func _draw_card() -> PvpCardData:
	return GameBalanceConfigScript.roll_card(_rng, _round)


func _refresh_heat_bar() -> void:
	if _heat_left_fill == null or _heat_right_fill == null or _heat_center_marker == null:
		return
	var score_delta: float = float(_board_state.score - _p2_score)
	var swing_ratio: float = clampf(score_delta / HEAT_FULL_SWING_SCORE, -1.0, 1.0)
	var left_edge: float = HEAT_BAR_RECT.position.x
	var right_edge: float = HEAT_BAR_RECT.position.x + HEAT_BAR_RECT.size.x
	var center_x: float = left_edge + HEAT_BAR_RECT.size.x * (0.5 + swing_ratio * 0.5)
	var left_target_pos := HEAT_BAR_RECT.position
	var left_target_size := Vector2(maxf(center_x - left_edge, 0.0), HEAT_BAR_RECT.size.y)
	var right_target_pos := Vector2(center_x, HEAT_BAR_RECT.position.y)
	var right_target_size := Vector2(maxf(right_edge - center_x, 0.0), HEAT_BAR_RECT.size.y)
	var marker_target_pos := Vector2(center_x - 2.0, HEAT_BAR_RECT.position.y - 4.0)

	if _heat_tween != null and _heat_tween.is_running():
		_heat_tween.kill()
	_heat_tween = create_tween()
	_heat_tween.set_parallel(true)
	_heat_tween.tween_property(_heat_left_fill, "position", left_target_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_heat_tween.tween_property(_heat_left_fill, "size", left_target_size, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_heat_tween.tween_property(_heat_right_fill, "position", right_target_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_heat_tween.tween_property(_heat_right_fill, "size", right_target_size, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_heat_tween.tween_property(_heat_center_marker, "position", marker_target_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _check_comeback_bonus() -> void:
	var trigger_score: int = int(round(HEAT_FULL_SWING_SCORE * COMEBACK_TRIGGER_RATIO))
	var score_delta: int = int(_board_state.score) - _p2_score
	if score_delta >= trigger_score and not _p2_comeback_awarded:
		if _grant_comeback_prop("p2"):
			_p2_comeback_awarded = true
	elif score_delta <= -trigger_score and not _p1_comeback_awarded:
		if _grant_comeback_prop("p1"):
			_p1_comeback_awarded = true


func _grant_comeback_prop(side: String) -> bool:
	var props: Array[Dictionary] = _selected_props
	if side != "p1":
		props = _p2_props
	if props.size() >= 3:
		return false

	var excluded_ids: Array[String] = []
	if side == "p1":
		excluded_ids = _initial_selected_prop_ids
	var prop := _roll_comeback_prop(excluded_ids)
	if prop.is_empty():
		return false

	props.append(prop)
	if side == "p1":
		_selected_props = props
	else:
		_p2_props = props
	_refresh_prop_bar()
	_show_comeback_notice(side, prop)
	return true


func _roll_comeback_prop(excluded_ids: Array[String]) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for prop_data in PROP_DEFINITIONS:
		var prop: Dictionary = prop_data
		if not excluded_ids.has(str(prop["id"])):
			candidates.append(prop.duplicate())
	if candidates.is_empty():
		for prop_data in PROP_DEFINITIONS:
			var prop: Dictionary = prop_data
			candidates.append(prop.duplicate())
	if candidates.is_empty():
		return {}
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _show_comeback_notice(side: String, prop: Dictionary) -> void:
	var side_label := "P1" if side == "p1" else "P2"
	_comeback_notice_label.text = "%s 落后补偿：获得 %s" % [side_label, str(prop.get("label", ""))]
	_comeback_notice_label.visible = true
	_comeback_notice_label.modulate = Color(1, 1, 1, 0)
	var notice_tween := create_tween()
	notice_tween.tween_property(_comeback_notice_label, "modulate", Color(1, 1, 1, 1), 0.12)
	notice_tween.tween_interval(1.0)
	notice_tween.tween_property(_comeback_notice_label, "modulate", Color(1, 1, 1, 0), 0.35)
	notice_tween.tween_callback(func() -> void: _comeback_notice_label.visible = false)

	var layer := _prop_item_layer if side == "p1" else _opponent_prop_item_layer
	if layer != null:
		layer.modulate = Color(1.6, 1.35, 0.55, 1)
		var flash_tween := create_tween()
		flash_tween.tween_property(layer, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh_all(new_pool_slots: Array[int] = [], pool_move_map: Dictionary = {}) -> void:
	_round_label.text = "PK %02d回合" % _round
	_p1_score_label.text = str(_board_state.score)
	_p2_score_label.text = str(_p2_score)
	_refresh_heat_bar()
	_check_comeback_bonus()
	_board_view.refresh_board(_board_state.board)
	_public_pool_label.text = "公共牌池 %d" % _pool_card_count()
	_refresh_pool(new_pool_slots, pool_move_map)
	_refresh_basket()
	_refresh_prop_bar()
	_refresh_opponent_placeholders()


func _refresh_pool(new_slots: Array[int] = [], move_map: Dictionary = {}) -> void:
	_ensure_pool_slots()
	for child in _public_pool_cards_layer.get_children():
		child.queue_free()

	for i in range(POOL_SIZE):
		if _pool_cards[i] == null:
			continue
		var card_view := LocalCardView.new()
		var target_position: Vector2 = _get_pool_card_position(i)
		card_view.position = target_position
		card_view.size = Vector2(76, 98)
		card_view.set_card(_pool_cards[i], true)
		card_view.set_interaction(not _game_over and _phase == Phase.CLAIM, false, "test_pool", i)
		card_view.card_clicked.connect(_on_pool_card_clicked)
		_public_pool_cards_layer.add_child(card_view)

		if move_map.has(i):
			card_view.position = _get_pool_card_position(int(move_map[i]))
			var fall_tween := create_tween()
			fall_tween.tween_property(card_view, "position", target_position, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		elif i in new_slots:
			card_view.position = _get_pool_card_spawn_position(i, new_slots)
			var fall_tween := create_tween()
			fall_tween.tween_property(card_view, "position", target_position, ROUND_DROP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _get_pool_card_position(index: int) -> Vector2:
	return Vector2(56 + (index % POOL_COLUMNS) * 120, 20 + int(index / POOL_COLUMNS) * POOL_CARD_ROW_GAP)


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


func _play_pool_lock_cover_in() -> void:
	_pool_lock_cover.visible = true
	_pool_lock_cover.position = POOL_COVER_OFFSCREEN_POSITION
	var tween := create_tween()
	tween.tween_property(_pool_lock_cover, "position", POOL_COVER_POSITION, ROUND_DROP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_pool_lock_cover_out() -> void:
	var tween := create_tween()
	tween.tween_property(_pool_lock_cover, "position", POOL_COVER_OFFSCREEN_POSITION, ROUND_UNLOCK_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _wait_round_start_segment(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and not _game_over and is_inside_tree():
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		_phase_time_left = maxf(_phase_time_left - delta, 0.0)
		_update_timer_label()


func _refresh_basket() -> void:
	for child in _basket_container.get_children():
		child.queue_free()

	for i in range(_basket_cards.size()):
		var card_view := LocalCardView.new()
		card_view.position = Vector2(0, i * 120)
		card_view.size = Vector2(78, 104)
		card_view.set_card(_basket_cards[i], false)
		card_view.set_interaction(false, not _game_over and _phase == Phase.PLACE, "test_basket", i)
		_basket_container.add_child(card_view)


func _refresh_opponent_placeholders() -> void:
	for child in _opponent_basket_container.get_children():
		child.queue_free()
	for i in range(4):
		var card_view := LocalCardView.new()
		card_view.position = Vector2(0, i * 120)
		card_view.size = Vector2(78, 104)
		card_view.modulate = Color(1, 1, 1, 0.35)
		card_view.clear_card()
		_opponent_basket_container.add_child(card_view)


func _on_pool_card_clicked(card_view: LocalCardView) -> void:
	if _game_over or _phase != Phase.CLAIM or _basket_cards.size() >= BASKET_SIZE:
		return
	var pool_index: int = card_view.card_index
	var removal := _remove_pool_card_with_gravity(pool_index)
	if removal.is_empty():
		return
	var claimed_card: PvpCardData = removal["card"]
	_basket_cards.append(claimed_card.clone())
	var move_map: Dictionary = removal["move_map"]
	if _basket_cards.size() >= BASKET_SIZE:
		_start_place_phase(move_map)
	else:
		_refresh_all([], move_map)


func _on_board_card_dropped(card_index: int, cell: Vector2i) -> void:
	if _game_over or _phase != Phase.PLACE:
		return
	if card_index < 0 or card_index >= _basket_cards.size():
		return
	await _place_basket_card(card_index, cell, true)


func _on_board_prop_dropped(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	if _game_over or _prop_use_in_progress:
		return
	if _is_resolving and _phase != Phase.ROUND_START:
		return
	if prop_index < 0 or prop_index >= _selected_props.size():
		return
	if str(_selected_props[prop_index].get("id", "")) != prop_id:
		return
	await _use_prop_on_board(prop_id, prop_index, cell)


func _use_prop_on_board(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	var visual_board: Array = _clone_board(_board_state.board)
	var result: Dictionary = _board_state.apply_prop(prop_id, cell)
	if not bool(result.get("ok", false)):
		_center_message_label.text = str(result.get("message", "道具使用失败。"))
		return

	var was_resolving := _is_resolving
	_prop_use_in_progress = true
	_is_resolving = true
	_board_view.set_drop_enabled(false)
	_selected_props.remove_at(prop_index)
	_center_message_label.text = str(result.get("message", ""))
	_refresh_all()
	_board_view.refresh_board(visual_board)

	var chain_steps: Array = result.get("chain_steps", [])
	if not chain_steps.is_empty():
		await _board_view.play_chain_steps(chain_steps)
		_refresh_all()

	_is_resolving = was_resolving and _phase == Phase.ROUND_START
	_prop_use_in_progress = false
	_board_view.set_drop_enabled(_phase == Phase.PLACE and not _game_over)
	_refresh_prop_bar()


func _place_basket_card(card_index: int, cell: Vector2i, end_round_when_empty: bool) -> void:
	var visual_board: Array = _make_visual_board_before_drop(_basket_cards[card_index], cell)
	var result: Dictionary = _board_state.place_card(_basket_cards[card_index], cell)
	if not bool(result.get("ok", false)):
		_center_message_label.text = str(result.get("message", "放置失败。"))
		return

	_is_resolving = true
	_basket_cards.remove_at(card_index)
	_center_message_label.text = str(result.get("message", ""))
	_board_view.set_drop_enabled(false)
	_refresh_all()
	_board_view.refresh_board(visual_board)
	var chain_steps: Array = result.get("chain_steps", [])
	if not chain_steps.is_empty():
		await _board_view.play_chain_steps(chain_steps)
		_refresh_all()
	_is_resolving = false
	_board_view.set_drop_enabled(_phase == Phase.PLACE and not _game_over)
	if not _board_state.has_empty_cell():
		_show_game_over()
		return
	if end_round_when_empty and _basket_cards.is_empty():
		_center_message_label.text = "回合结束，公共牌池补充 4 张。"
		await get_tree().create_timer(0.4).timeout
		_end_round()


func _auto_fill_basket_from_pool() -> void:
	while _basket_cards.size() < BASKET_SIZE:
		var occupied_slots := _get_occupied_pool_slots()
		if occupied_slots.is_empty():
			break
		var pool_index: int = occupied_slots[_rng.randi_range(0, occupied_slots.size() - 1)]
		var removal := _remove_pool_card_with_gravity(pool_index)
		if removal.is_empty():
			break
		var claimed_card: PvpCardData = removal["card"]
		_basket_cards.append(claimed_card.clone())
	_center_message_label.text = "抢牌时间结束，系统已补足篮子。"
	_refresh_all()


func _auto_place_remaining_cards() -> void:
	if _game_over or _phase != Phase.PLACE:
		return
	_is_resolving = true
	_board_view.set_drop_enabled(false)
	_center_message_label.text = "放置时间结束，系统自动处理剩余卡牌。"

	while not _basket_cards.is_empty() and not _game_over:
		var target_cell: Vector2i = _find_first_empty_cell()
		if target_cell.x < 0:
			_show_game_over()
			break
		_is_resolving = false
		await _place_basket_card(0, target_cell, false)
		_is_resolving = true
		await get_tree().create_timer(0.16).timeout

	_is_resolving = false
	if not _game_over and _basket_cards.is_empty():
		await get_tree().create_timer(0.4).timeout
		_end_round()


func _find_first_empty_cell() -> Vector2i:
	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			if _board_state.board[y][x] == null:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _make_visual_board_before_drop(card: PvpCardData, cell: Vector2i) -> Array:
	var visual_board: Array = _clone_board(_board_state.board)
	if cell.x < 0 or cell.x >= UiLayoutConfig.BOARD_COLUMNS or cell.y < 0 or cell.y >= UiLayoutConfig.BOARD_ROWS:
		return visual_board
	if visual_board[cell.y][cell.x] != null:
		return visual_board

	var played: PvpCardData = card.clone()
	if cell.x == 0 or cell.y == 0:
		played.value += 1
	visual_board[cell.y][cell.x] = played
	return visual_board


func _clone_board(source_board: Array) -> Array:
	var cloned: Array = []
	for y in range(UiLayoutConfig.BOARD_ROWS):
		var row: Array = []
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			var card: PvpCardData = source_board[y][x]
			row.append(null if card == null else card.clone())
		cloned.append(row)
	return cloned


func _show_game_over() -> void:
	_game_over = true
	_is_resolving = false
	_board_view.set_drop_enabled(false)
	_center_message_label.text = "无剩余空位，游戏结束"
	_refresh_all()
	_game_over_dialog.dialog_text = "无剩余空位，游戏结束\n最终热度：%d" % _board_state.score
	_game_over_dialog.popup_centered(Vector2(420, 180))


func _make_label(text: String, font_size: int, alignment: HorizontalAlignment, color: Color = UiLayoutConfig.TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
