class_name PlayerBoardState
extends RefCounted

var board: Array = []
var score: int = 0
var removed_count: int = 0


func reset() -> void:
	score = 0
	removed_count = 0
	board.clear()
	for _y in range(UiLayoutConfig.BOARD_ROWS):
		var row: Array = []
		for _x in range(UiLayoutConfig.BOARD_COLUMNS):
			row.append(null)
		board.append(row)


func place_card(card: PvpCardData, cell: Vector2i) -> Dictionary:
	if not _is_inside(cell):
		return {"ok": false, "message": "不能放在棋盘外。"}
	if board[cell.y][cell.x] != null:
		return {"ok": false, "message": "这个格子已经有牌。"}

	var played: PvpCardData = card.clone()
	if cell.x == 0 or cell.y == 0:
		played.value += 1
	board[cell.y][cell.x] = played

	var resolve_result: Dictionary = _resolve_chains_from([cell], {})
	var gained: int = int(resolve_result["score"])
	score += gained
	removed_count += int(resolve_result["removed"])

	var message: String = "%s %d 入场。" % [played.label, played.value]
	if gained > 0:
		message = "结算 +%d 热度，连锁 %d 段。" % [gained, int(resolve_result["steps"])]

	return {
		"ok": true,
		"score": gained,
		"steps": int(resolve_result["steps"]),
		"removed": int(resolve_result["removed"]),
		"chain_steps": resolve_result["chain_steps"],
		"message": message
	}


func apply_prop(prop_id: String, cell: Vector2i) -> Dictionary:
	if not _is_inside(cell):
		return {"ok": false, "message": "不能作用在棋盘外。"}
	var target_card: PvpCardData = get_card(cell)
	if target_card == null:
		return {"ok": false, "message": "这个格子没有卡牌。"}

	var prop_events: Array = []
	var prop_removed := 0
	var gained := 0
	var steps := 0
	var message := ""

	match prop_id:
		"remove":
			prop_events.append(_make_prop_event(cell, target_card.value, 0, true))
			board[cell.y][cell.x] = null
			prop_removed = 1
			message = "道具 消：移除一张卡牌。"
		"plus_one":
			var from_value := target_card.value
			target_card.value += 1
			prop_events.append(_make_prop_event(cell, from_value, target_card.value, false))
			message = "道具 +1：目标卡牌数值 +1。"
		"minus_one":
			var from_value := target_card.value
			target_card.value -= 1
			var removed_by_prop := target_card.value <= 0
			prop_events.append(_make_prop_event(cell, from_value, max(target_card.value, 0), removed_by_prop))
			if removed_by_prop:
				board[cell.y][cell.x] = null
				prop_removed = 1
			message = "道具 -1：目标卡牌数值 -1。"
		_:
			return {"ok": false, "message": "未知道具。"}

	var chain_steps: Array = []
	if not prop_events.is_empty():
		chain_steps.append({
			"step": 1,
			"events": prop_events
		})

	if prop_id in ["plus_one", "minus_one"] and get_card(cell) != null:
		var resolve_result: Dictionary = _resolve_chains_from([cell], {})
		gained = int(resolve_result["score"])
		prop_removed += int(resolve_result["removed"])
		steps = int(resolve_result["steps"])
		var resolved_steps: Array = resolve_result["chain_steps"]
		for step_data in resolved_steps:
			var copied_step: Dictionary = step_data
			copied_step["step"] = int(copied_step.get("step", 0)) + 1
			chain_steps.append(copied_step)

	score += gained
	removed_count += prop_removed
	if gained > 0:
		message += " 结算 +%d 热度，连锁 %d 段。" % [gained, steps]

	return {
		"ok": true,
		"score": gained,
		"steps": steps,
		"removed": prop_removed,
		"chain_steps": chain_steps,
		"message": message
	}


func _make_prop_event(cell: Vector2i, from_value: int, to_value: int, removed: bool) -> Dictionary:
	return {
		"cell": cell,
		"from": from_value,
		"to": to_value,
		"removed": removed
	}


func has_empty_cell() -> bool:
	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			if board[y][x] == null:
				return true
	return false


func _resolve_chains_from(seed_cells: Array, previous_dropped: Dictionary) -> Dictionary:
	var frontier: Array = seed_cells.duplicate()
	var dropped_last_step: Dictionary = previous_dropped.duplicate()
	var total_score: int = 0
	var total_removed: int = 0
	var steps: int = 0
	var chain_steps: Array = []

	while true:
		var groups: Array = _find_groups(frontier, dropped_last_step)
		if groups.is_empty():
			break

		var drop_result: Dictionary = _drop_groups(groups)
		chain_steps.append({
			"step": steps + 1,
			"events": drop_result["events"]
		})
		total_score += int(drop_result["affected"]) * 10
		total_removed += int(drop_result["removed"])
		total_score += int(drop_result["removed"]) * 20
		frontier = drop_result["survivors"]
		dropped_last_step = drop_result["dropped"]
		steps += 1

	if steps > 1:
		total_score += (steps - 1) * 10

	return {
		"score": total_score,
		"removed": total_removed,
		"steps": steps,
		"chain_steps": chain_steps
	}


func _find_groups(seed_cells: Array, previous_dropped: Dictionary) -> Array:
	var checked: Dictionary = {}
	var groups: Array = []

	for seed_value in seed_cells:
		var seed: Vector2i = seed_value
		if checked.has(seed):
			continue
		var card: PvpCardData = get_card(seed)
		if card == null:
			continue
		var group: Array[Vector2i] = _collect_same_group(seed)
		for cell in group:
			checked[cell] = true
		if _is_resolvable_group(seed, group, previous_dropped):
			groups.append(group)

	return groups


func _is_resolvable_group(seed: Vector2i, group: Array[Vector2i], previous_dropped: Dictionary) -> bool:
	if group.size() >= 2:
		return _group_has_new_neighbor(group, previous_dropped)

	var seed_card: PvpCardData = get_card(seed)
	return seed_card != null and seed_card.is_wild() and previous_dropped.is_empty()


func _group_has_new_neighbor(group: Array[Vector2i], previous_dropped: Dictionary) -> bool:
	if previous_dropped.is_empty():
		return true
	for cell in group:
		if not previous_dropped.has(cell):
			return true
	return false


func _collect_same_group(start: Vector2i) -> Array[Vector2i]:
	var start_card: PvpCardData = get_card(start)
	var group: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}

	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		group.append(current)
		for next in _neighbors(current):
			if visited.has(next):
				continue
			var next_card: PvpCardData = get_card(next)
			if next_card == null:
				continue
			if _cards_match_for_group(start_card, next_card):
				visited[next] = true
				stack.append(next)

	return group


func _cards_match_for_group(a: PvpCardData, b: PvpCardData) -> bool:
	if a == null or b == null:
		return false
	if a.value != b.value:
		return false
	return a.type_id == b.type_id or a.is_wild() or b.is_wild()


func _drop_groups(groups: Array) -> Dictionary:
	var seen: Dictionary = {}
	var ordered_cells: Array[Vector2i] = []

	for group in groups:
		for cell_value in group:
			var cell: Vector2i = cell_value
			if seen.has(cell):
				continue
			seen[cell] = true
			ordered_cells.append(cell)

	var survivors: Array[Vector2i] = []
	var dropped: Dictionary = {}
	var removed: int = 0
	var affected: int = 0
	var events: Array = []

	for cell in ordered_cells:
		var card: PvpCardData = get_card(cell)
		if card == null:
			continue
		var from_value: int = card.value
		if card.is_wild():
			card.value = 0
		else:
			card.value -= 1
		dropped[cell] = true
		affected += 1
		events.append({
			"cell": cell,
			"from": from_value,
			"to": card.value,
			"removed": card.value <= 0
		})
		if card.value <= 0:
			board[cell.y][cell.x] = null
			removed += 1
		else:
			survivors.append(cell)

	return {
		"affected": affected,
		"removed": removed,
		"survivors": survivors,
		"dropped": dropped,
		"events": events
	}


func get_card(cell: Vector2i) -> PvpCardData:
	if not _is_inside(cell):
		return null
	return board[cell.y][cell.x]


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	for offset in offsets:
		var next: Vector2i = cell + offset
		if _is_inside(next):
			result.append(next)
	return result


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < UiLayoutConfig.BOARD_COLUMNS and cell.y >= 0 and cell.y < UiLayoutConfig.BOARD_ROWS
