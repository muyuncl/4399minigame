extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/pvp_match_test.tscn")
	if scene == null:
		push_error("Expected PVP match test scene to load.")
		quit(1)
		return

	var root_node: Control = scene.instantiate()
	root.add_child(root_node)
	await process_frame
	await process_frame

	var phase_label: Label = root_node.get("_phase_label")
	var status_label: Label = root_node.get("_status_label")
	if phase_label == null or status_label == null:
		push_error("Expected PVP match test UI labels to exist.")
		quit(1)
		return

	print("PVP_MATCH_SMOKE_OK phase=%s status=%s" % [phase_label.text, status_label.text])
	root.remove_child(root_node)
	root_node.free()
	quit()
