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
		push_error("Expected prop selection dialog to create prop checkboxes.")
		quit(1)
		return

	checks[0].button_pressed = true
	checks[1].button_pressed = true
	root_node.call("_on_prop_selection_confirmed")
	await process_frame

	var selected_props: Array = root_node.get("_selected_props")
	if selected_props.size() != 2:
		push_error("Expected exactly two selected props after confirmation.")
		quit(1)
		return

	print("PROP_SELECTION_SMOKE_OK selected=%d" % selected_props.size())
	root.remove_child(root_node)
	root_node.free()
	quit()
