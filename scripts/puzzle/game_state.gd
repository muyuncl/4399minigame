class_name GameState
extends RefCounted

const BOARD_COLUMNS := 6
const BOARD_ROWS := 5
const HAND_SIZE := 5

var board: Array = []
var hand: Array = []
var score: int = 0
var game_over: bool = false
var last_message: String = ""

var _rng := RandomNumberGenerator.new()
var _normal_cards: Array = []
var _warehouse_data: Dictionary = {
	"label": "收纳",
	"short": "收",
	"color": "#76c26a"
}
var _value_min: int = 1
var _value_max: int = 5
var _warehouse_weight: float = 0.14


func start_new_game(config_path: String = "res://data/card_pool.json") -> void:
	_rng.randomize()
	_load_config(config_path)
	_clear_board()
	hand.clear()
	score = 0
	game_over = false
	last_message = "直播开始！把才艺卡拖到空格上。"
	_fill_hand()


func place_from_hand(hand_index: int, cell: Vector2i) -> Dictionary:
	# UI 只调用这个入口；所有放置、计分、补牌和结束判断都集中在规则层。
	if game_over:
		return {"ok": false, "message": "本局已经结束。"}
	if hand_index < 0 or hand_index >= hand.size():
		return {"ok": false, "message": "找不到这张手牌。"}
	if not _is_inside(cell):
		return {"ok": false, "message": "只能放在 6x5 棋盘内。"}
	if board[cell.y][cell.x] != null:
		return {"ok": false, "message": "这个格子已经有节目了。"}

	var played: CardData = hand[hand_index].clone()
	hand.remove_at(hand_index)

	var gained := 0
	var chain_steps := 0
	var animation_events := []

	if played.is_normal():
		# 最左列或最上排获得直播间首屏加成；左上角也只加 1 次。
		if cell.x == 0 or cell.y == 0:
			played.value += 1
		board[cell.y][cell.x] = played
		var resolve_result := _resolve_normal_chain_from([cell], cell)
		gained += int(resolve_result["gained"])
		chain_steps += int(resolve_result["steps"])
		animation_events.append_array(resolve_result["events"])
	else:
		var warehouse_result := _resolve_warehouse(cell, played.value)
		gained += int(warehouse_result["gained"])
		chain_steps += int(warehouse_result["steps"])
		animation_events.append_array(warehouse_result["events"])

	score += gained
	if hand.size() <= 1:
		_fill_hand()

	if not has_empty_cell():
		game_over = true

	last_message = _build_result_message(played, gained, chain_steps)
	if game_over:
		last_message = "直播间排满啦！最终热度：%d。" % score

	return {
		"ok": true,
		"gained": gained,
		"chains": chain_steps,
		"events": animation_events,
		"message": last_message,
		"game_over": game_over
	}


func has_empty_cell() -> bool:
	for y in range(BOARD_ROWS):
		for x in range(BOARD_COLUMNS):
			if board[y][x] == null:
				return true
	return false


func get_card(cell: Vector2i) -> CardData:
	if not _is_inside(cell):
		return null
	return board[cell.y][cell.x]


func restart() -> void:
	start_new_game()


func _load_config(config_path: String) -> void:
	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("找不到卡池配置，使用内置默认值：%s" % config_path)
		_use_default_config()
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("卡池配置不是有效 JSON 字典，使用内置默认值。")
		_use_default_config()
		return

	_normal_cards = data.get("normal_cards", [])
	_value_min = int(data.get("value_min", 1))
	_value_max = int(data.get("value_max", 5))
	_warehouse_weight = float(data.get("warehouse_weight", 0.14))
	_warehouse_data = data.get("warehouse", _warehouse_data)

	if _normal_cards.is_empty():
		_use_default_config()


func _use_default_config() -> void:
	_normal_cards = [
		{"type": "sing", "label": "唱歌", "short": "唱", "color": "#e65f73"},
		{"type": "dance", "label": "跳舞", "short": "舞", "color": "#42a5f5"},
		{"type": "chat", "label": "聊天", "short": "聊", "color": "#f4b84a"}
	]
	_value_min = 1
	_value_max = 5
	_warehouse_weight = 0.14
	_warehouse_data = {"label": "收纳", "short": "收", "color": "#76c26a"}


func _clear_board() -> void:
	board.clear()
	for _y in range(BOARD_ROWS):
		var row := []
		for _x in range(BOARD_COLUMNS):
			row.append(null)
		board.append(row)


func _fill_hand() -> void:
	while hand.size() < HAND_SIZE:
		hand.append(_draw_card())


func _draw_card() -> CardData:
	# 卡池参数放在 JSON 里，方便策划同学不改脚本也能调概率和颜色。
	var card_value := _rng.randi_range(_value_min, _value_max)
	if _rng.randf() < _warehouse_weight:
		return CardData.create_warehouse(
			str(_warehouse_data.get("label", "收纳")),
			str(_warehouse_data.get("short", "收")),
			str(_warehouse_data.get("color", "#76c26a")),
			card_value
		)

	var index := _rng.randi_range(0, _normal_cards.size() - 1)
	var data: Dictionary = _normal_cards[index]
	return CardData.create_normal(
		str(data.get("type", "talent")),
		str(data.get("label", "才艺")),
		str(data.get("short", "才")),
		str(data.get("color", "#ffffff")),
		card_value
	)


func _resolve_normal_chain_from(seed_cells: Array, origin_cell: Vector2i) -> Dictionary:
	# 连锁只从刚变化的卡继续，且必须撞上“本轮之前就在旁边”的同类型同数字卡。
	# 这样 3+3 只会掉到 2；如果旁边原本有 2，才继续带着那张 2 一起掉层。
	var total_gained := 0
	var steps := 0
	var events := []
	var frontier := seed_cells.duplicate()
	var previous_dropped := {}

	while true:
		var groups := _find_chain_groups_from(frontier, previous_dropped)
		if groups.is_empty():
			break
		var drop_result := _drop_groups(groups, origin_cell)
		total_gained += int(drop_result["gained"])
		events.append_array(drop_result["events"])
		frontier = drop_result["survivors"]
		previous_dropped = drop_result["dropped"]
		steps += 1

	return {"gained": total_gained, "steps": steps, "events": events}


func _find_chain_groups_from(seed_cells: Array, previous_dropped: Dictionary) -> Array:
	var checked := {}
	var groups := []

	for seed in seed_cells:
		var start: Vector2i = seed
		if checked.has(start):
			continue
		var card: CardData = get_card(start)
		if card == null or not card.is_normal():
			continue
		var group := _collect_same_normal_group(start)
		for cell: Vector2i in group:
			checked[cell] = true
		if group.size() >= 2 and _group_has_new_neighbor(group, previous_dropped):
			groups.append(group)

	return groups


func _group_has_new_neighbor(group: Array, previous_dropped: Dictionary) -> bool:
	if previous_dropped.is_empty():
		return true
	for cell: Vector2i in group:
		if not previous_dropped.has(cell):
			return true
	return false


func _collect_same_normal_group(start: Vector2i) -> Array[Vector2i]:
	var start_card: CardData = get_card(start)
	var group: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	var visited := {start: true}

	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		group.append(current)
		for next: Vector2i in _neighbors(current):
			if visited.has(next):
				continue
			var next_card: CardData = get_card(next)
			if next_card == null or not next_card.is_normal():
				continue
			if next_card.talent_type == start_card.talent_type and next_card.value == start_card.value:
				visited[next] = true
				stack.append(next)

	return group


func _resolve_warehouse(cell: Vector2i, target_value: int) -> Dictionary:
	# 收纳卡只看数字，不看才艺类型；自己不落到棋盘上，也不提供分数。
	var visited := {}
	var total_gained := 0
	var steps := 0
	var groups := []

	for next: Vector2i in _neighbors(cell):
		if visited.has(next):
			continue
		var card: CardData = get_card(next)
		if card == null or not card.is_normal() or card.value != target_value:
			continue
		var group := _collect_same_value_group(next, target_value)
		for group_cell: Vector2i in group:
			visited[group_cell] = true
		groups.append(group)

	if not groups.is_empty():
		var drop_result := _drop_groups(groups, cell)
		total_gained += int(drop_result["gained"])
		var events := []
		events.append_array(drop_result["events"])
		steps = 1
		var chain_result := _resolve_normal_chain_from_with_previous(drop_result["survivors"], drop_result["dropped"], cell)
		total_gained += int(chain_result["gained"])
		steps += int(chain_result["steps"])
		events.append_array(chain_result["events"])
		return {"gained": total_gained, "steps": steps, "events": events}

	return {"gained": total_gained, "steps": steps, "events": []}


func _collect_same_value_group(start: Vector2i, target_value: int) -> Array[Vector2i]:
	var group: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	var visited := {start: true}

	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		group.append(current)
		for next: Vector2i in _neighbors(current):
			if visited.has(next):
				continue
			var next_card: CardData = get_card(next)
			if next_card == null or not next_card.is_normal():
				continue
			if next_card.value == target_value:
				visited[next] = true
				stack.append(next)

	return group


func _drop_groups(groups: Array, origin_cell: Vector2i) -> Dictionary:
	# 掉层是最小结算单位：每张被影响的普通卡 +1 热度，数字到 0 就离场。
	var survivors: Array[Vector2i] = []
	var dropped := {}
	var gained := 0
	var events := []
	var ordered_cells := _ordered_unique_drop_cells(groups, origin_cell)

	for typed_cell: Vector2i in ordered_cells:
		if dropped.has(typed_cell):
			continue
		var card: CardData = get_card(typed_cell)
		if card == null:
			continue
		var from_value := card.value
		card.value -= 1
		dropped[typed_cell] = true
		gained += 1
		events.append({
			"cell": typed_cell,
			"from": from_value,
			"to": card.value,
			"removed": card.value <= 0
		})
		if card.value <= 0:
			board[typed_cell.y][typed_cell.x] = null
		else:
			survivors.append(typed_cell)

	return {
		"gained": gained,
		"survivors": survivors,
		"dropped": dropped,
		"events": events
	}


func _ordered_unique_drop_cells(groups: Array, origin_cell: Vector2i) -> Array[Vector2i]:
	var pending: Array[Vector2i] = []
	var seen := {}

	for group in groups:
		for cell in group:
			var typed_cell: Vector2i = cell
			if seen.has(typed_cell):
				continue
			seen[typed_cell] = true
			pending.append(typed_cell)

	var ordered: Array[Vector2i] = []
	while not pending.is_empty():
		var best_index: int = 0
		for i in range(1, pending.size()):
			if _is_drop_cell_before(pending[i], pending[best_index], origin_cell):
				best_index = i
		ordered.append(pending[best_index])
		pending.remove_at(best_index)

	return ordered


func _is_drop_cell_before(a: Vector2i, b: Vector2i, origin_cell: Vector2i) -> bool:
	var distance_a: int = abs(a.x - origin_cell.x) + abs(a.y - origin_cell.y)
	var distance_b: int = abs(b.x - origin_cell.x) + abs(b.y - origin_cell.y)
	if distance_a != distance_b:
		return distance_a < distance_b
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


func _resolve_normal_chain_from_with_previous(seed_cells: Array, previous_dropped: Dictionary, origin_cell: Vector2i) -> Dictionary:
	var total_gained := 0
	var steps := 0
	var events := []
	var frontier := seed_cells.duplicate()
	var dropped_last_step := previous_dropped.duplicate()

	while true:
		var groups := _find_chain_groups_from(frontier, dropped_last_step)
		if groups.is_empty():
			break
		var drop_result := _drop_groups(groups, origin_cell)
		total_gained += int(drop_result["gained"])
		events.append_array(drop_result["events"])
		frontier = drop_result["survivors"]
		dropped_last_step = drop_result["dropped"]
		steps += 1

	return {"gained": total_gained, "steps": steps, "events": events}


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	for offset: Vector2i in offsets:
		var next: Vector2i = cell + offset
		if _is_inside(next):
			result.append(next)
	return result


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < BOARD_COLUMNS and cell.y >= 0 and cell.y < BOARD_ROWS


func _build_result_message(card: CardData, gained: int, chain_steps: int) -> String:
	if gained <= 0:
		if card.is_warehouse():
			return "%s %d 没收进相同数字的才艺。" % [card.label, card.value]
		return "%s 入场，暂时没有连麦加热度。" % card.display_name()

	var chain_text := ""
	if chain_steps > 1:
		chain_text = "，连锁 %d 次" % chain_steps
	return "%s 触发结算，热度 +%d%s。" % [card.display_name(), gained, chain_text]
