extends SceneTree

const PlayerBoardStateScript := preload("res://scripts/core/player_board_state.gd")


func _init() -> void:
	var state: Variant = PlayerBoardStateScript.new()
	state.reset()

	var card_a := PvpCardData.create("chat", "聊天", "聊", 2, Color.ORANGE)
	var card_b := PvpCardData.create("chat", "聊天", "聊", 2, Color.ORANGE)

	var first: Dictionary = state.place_card(card_a, Vector2i(1, 1))
	var second: Dictionary = state.place_card(card_b, Vector2i(2, 1))

	if not bool(first.get("ok", false)):
		push_error("First placement failed.")
		quit(1)
		return
	if not bool(second.get("ok", false)):
		push_error("Second placement failed.")
		quit(1)
		return
	if int(second.get("score", 0)) <= 0:
		push_error("Expected second placement to score.")
		quit(1)
		return
	var chain_steps: Array = second.get("chain_steps", [])
	if chain_steps.is_empty():
		push_error("Expected placement result to include chain step events.")
		quit(1)
		return
	if state.score <= 0:
		push_error("Expected total score to increase.")
		quit(1)
		return

	var wild_state: Variant = PlayerBoardStateScript.new()
	wild_state.reset()
	var normal_card := PvpCardData.create("game", "游戏", "游", 3, Color.BLUE)
	var wild_card := PvpCardData.create("wild", "万能", "万", 3, Color.GREEN)
	wild_state.place_card(normal_card, Vector2i(1, 1))
	var wild_result: Dictionary = wild_state.place_card(wild_card, Vector2i(2, 1))
	if int(wild_result.get("score", 0)) <= 0:
		push_error("Expected wild card to match same-value normal card.")
		quit(1)
		return
	if wild_state.board[1][2] != null:
		push_error("Expected matched wild card to disappear immediately.")
		quit(1)
		return
	if wild_state.board[1][1] == null or wild_state.board[1][1].value != 2:
		push_error("Expected normal card matched by wild card to drop by one value.")
		quit(1)
		return

	var solo_wild_state: Variant = PlayerBoardStateScript.new()
	solo_wild_state.reset()
	var solo_wild_card := PvpCardData.create("wild", "万能", "万", 4, Color.GREEN)
	var solo_wild_result: Dictionary = solo_wild_state.place_card(solo_wild_card, Vector2i(3, 3))
	if int(solo_wild_result.get("removed", 0)) != 1:
		push_error("Expected solo wild card to remove itself.")
		quit(1)
		return
	if solo_wild_state.board[3][3] != null:
		push_error("Expected solo wild card cell to be empty after resolving.")
		quit(1)
		return

	var prop_state: Variant = PlayerBoardStateScript.new()
	prop_state.reset()
	prop_state.board[1][1] = PvpCardData.create("chat", "聊天", "聊", 2, Color.ORANGE)
	var remove_prop_result: Dictionary = prop_state.apply_prop("remove", Vector2i(1, 1))
	if not bool(remove_prop_result.get("ok", false)) or prop_state.board[1][1] != null:
		push_error("Expected remove prop to clear target card.")
		quit(1)
		return

	prop_state.reset()
	prop_state.board[1][1] = PvpCardData.create("chat", "聊天", "聊", 3, Color.ORANGE)
	prop_state.board[2][1] = PvpCardData.create("chat", "聊天", "聊", 4, Color.ORANGE)
	var plus_prop_result: Dictionary = prop_state.apply_prop("plus_one", Vector2i(1, 1))
	if int(plus_prop_result.get("score", 0)) <= 0:
		push_error("Expected plus-one prop to trigger matching after value change.")
		quit(1)
		return

	prop_state.reset()
	prop_state.board[1][1] = PvpCardData.create("chat", "聊天", "聊", 1, Color.ORANGE)
	var minus_prop_result: Dictionary = prop_state.apply_prop("minus_one", Vector2i(1, 1))
	if not bool(minus_prop_result.get("ok", false)) or prop_state.board[1][1] != null:
		push_error("Expected minus-one prop to remove value-1 card.")
		quit(1)
		return

	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			wild_state.board[y][x] = PvpCardData.create("fill", "填充", "填", 9, Color.GRAY)
	if wild_state.has_empty_cell():
		push_error("Expected filled board to report no empty cells.")
		quit(1)
		return

	print("CARD_FLOW_SMOKE_OK score=%d second=%d wild=%d solo_wild=%d plus_prop=%d" % [state.score, int(second.get("score", 0)), int(wild_result.get("score", 0)), int(solo_wild_result.get("score", 0)), int(plus_prop_result.get("score", 0))])
	quit()
