extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/card_flow_test.tscn")
	var root_node: Control = scene.instantiate()
	root.add_child(root_node)
	await process_frame
	await process_frame

	var checks: Array = root_node.get("_prop_selection_checks")
	if checks.size() < 2:
		push_error("Expected prop selection checkboxes.")
		quit(1)
		return

	checks[0].button_pressed = true
	checks[1].button_pressed = true
	root_node.call("_on_prop_selection_confirmed")
	await process_frame

	var board_state: Variant = root_node.get("_board_state")
	board_state.score = 60
	root_node.call("_refresh_all")
	await process_frame
	var p2_props: Array = root_node.get("_p2_props")
	if p2_props.size() != 1:
		push_error("Expected P2 to receive a comeback prop when behind by 60.")
		quit(1)
		return

	board_state.score = 0
	root_node.set("_p2_score", 60)
	root_node.call("_refresh_all")
	await process_frame
	var p1_props: Array = root_node.get("_selected_props")
	if p1_props.size() != 3:
		push_error("Expected P1 to receive a comeback prop when behind by 60.")
		quit(1)
		return
	if str(p1_props[2].get("id", "")) in ["remove", "plus_one"]:
		push_error("Expected P1 comeback prop to prefer a prop not selected at game start.")
		quit(1)
		return

	print("HEAT_COMEBACK_SMOKE_OK p1_props=%d p2_props=%d" % [p1_props.size(), p2_props.size()])
	root.remove_child(root_node)
	root_node.free()
	quit()
