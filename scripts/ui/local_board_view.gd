class_name LocalBoardView
extends Control

const LocalBoardCellScript := preload("res://scripts/ui/local_board_cell.gd")

signal card_dropped(card_index: int, cell: Vector2i)
signal prop_dropped(prop_id: String, prop_index: int, cell: Vector2i)

var owner_label: String = "P1"
var drop_enabled: bool = false

var _cells: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_build_grid)
	_build_grid()


func _build_grid() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_cells.clear()

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(Color.TRANSPARENT, UiLayoutConfig.LINE_COLOR, 4, 0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)

	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			var cell: Variant = LocalBoardCellScript.new()
			var cell_size: Vector2 = size / Vector2(UiLayoutConfig.BOARD_COLUMNS, UiLayoutConfig.BOARD_ROWS)
			cell.position = Vector2(x * cell_size.x, y * cell_size.y)
			cell.size = cell_size
			cell.setup(Vector2i(x, y))
			cell.set_drop_enabled(drop_enabled)
			cell.card_dropped.connect(_on_cell_card_dropped)
			cell.prop_dropped.connect(_on_cell_prop_dropped)
			add_child(cell)
			_cells.append(cell)


func set_drop_enabled(enabled: bool) -> void:
	drop_enabled = enabled
	for cell in _cells:
		cell.set_drop_enabled(drop_enabled)


func refresh_board(board: Array) -> void:
	if _cells.is_empty():
		return
	for y in range(UiLayoutConfig.BOARD_ROWS):
		for x in range(UiLayoutConfig.BOARD_COLUMNS):
			var index: int = y * UiLayoutConfig.BOARD_COLUMNS + x
			_cells[index].set_card(board[y][x])


func play_chain_steps(chain_steps: Array) -> void:
	for step_data in chain_steps:
		var data: Dictionary = step_data
		var events: Array = data.get("events", [])
		if events.is_empty():
			continue
		for event in events:
			var event_data: Dictionary = event
			var cell_value: Variant = event_data.get("cell", Vector2i(-1, -1))
			var cell: Vector2i = cell_value
			var board_cell: Variant = get_board_cell(cell)
			if board_cell != null:
				board_cell.play_drop_event(event_data)
		await get_tree().create_timer(0.24).timeout


func get_board_cell(cell: Vector2i) -> Variant:
	if cell.x < 0 or cell.x >= UiLayoutConfig.BOARD_COLUMNS or cell.y < 0 or cell.y >= UiLayoutConfig.BOARD_ROWS:
		return null
	var index: int = cell.y * UiLayoutConfig.BOARD_COLUMNS + cell.x
	if index < 0 or index >= _cells.size():
		return null
	return _cells[index]


func _on_cell_card_dropped(card_index: int, cell: Vector2i) -> void:
	card_dropped.emit(card_index, cell)


func _on_cell_prop_dropped(prop_id: String, prop_index: int, cell: Vector2i) -> void:
	prop_dropped.emit(prop_id, prop_index, cell)
