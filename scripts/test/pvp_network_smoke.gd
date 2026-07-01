extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/pvp_network_test.tscn")
	if scene == null:
		push_error("Expected PVP network test scene to load.")
		quit(1)
		return

	var root_node: Control = scene.instantiate()
	root.add_child(root_node)
	await process_frame

	var status_label: Label = root_node.get("_status_label")
	if status_label == null or not status_label.text.contains("未连接"):
		push_error("Expected PVP network test scene to initialize disconnected.")
		quit(1)
		return

	print("PVP_NETWORK_SMOKE_OK status=%s" % status_label.text)
	root.remove_child(root_node)
	root_node.free()
	quit()
