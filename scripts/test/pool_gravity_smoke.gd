extends SceneTree


func _init() -> void:
	var ui_script := load("res://scripts/ui/card_flow_test_ui.gd")
	var ui: Control = ui_script.new()
	var cards: Array[PvpCardData] = []

	for i in range(10):
		cards.append(PvpCardData.create("test", "测试", "测", i + 1, Color.WHITE))

	ui.set("_pool_cards", cards)

	var removal: Dictionary = ui.call("_remove_pool_card_with_gravity", 6)
	if removal.is_empty():
		push_error("Expected gravity removal to return claimed card data.")
		quit(1)
		return

	var claimed_card: PvpCardData = removal["card"]
	var pool: Array = ui.get("_pool_cards")

	if claimed_card.value != 7:
		push_error("Expected slot 6 card to be claimed.")
		quit(1)
		return
	if pool[0] != null:
		push_error("Expected top slot in claimed column to become empty.")
		quit(1)
		return
	if pool[2].value != 1 or pool[4].value != 3 or pool[6].value != 5:
		push_error("Expected cards above the claimed slot to fall down in the same column.")
		quit(1)
		return
	if pool[8].value != 9 or pool[1].value != 2:
		push_error("Expected cards below and in the other column to stay in place.")
		quit(1)
		return

	print("POOL_GRAVITY_SMOKE_OK claimed=%d slot2=%d slot4=%d slot6=%d" % [claimed_card.value, pool[2].value, pool[4].value, pool[6].value])
	ui.free()
	quit()
