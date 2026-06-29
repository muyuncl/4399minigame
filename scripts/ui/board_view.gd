class_name BoardView
extends GridContainer

signal card_dropped(hand_index: int, cell: Vector2i)

var _cells: Array = []


func _ready() -> void:
    columns = GameState.BOARD_COLUMNS
    add_theme_constant_override("h_separation", 0)
    add_theme_constant_override("v_separation", 0)


func build() -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    _cells.clear()
    columns = GameState.BOARD_COLUMNS

    for y in range(GameState.BOARD_ROWS):
        for x in range(GameState.BOARD_COLUMNS):
            var board_cell := BoardCell.new()
            board_cell.setup(Vector2i(x, y))
            board_cell.card_dropped.connect(_on_cell_dropped)
            add_child(board_cell)
            _cells.append(board_cell)


func refresh(state: GameState) -> void:
    if _cells.is_empty():
        build()

    refresh_board(state.board, not state.game_over)


func refresh_board(board: Array, can_drop: bool) -> void:
    for y in range(GameState.BOARD_ROWS):
        for x in range(GameState.BOARD_COLUMNS):
            var index := y * GameState.BOARD_COLUMNS + x
            var board_cell: BoardCell = _cells[index]
            board_cell.set_card(board[y][x])
            board_cell.set_drop_enabled(can_drop)


func play_drop_events(events: Array) -> void:
    for event in events:
        var cell_value: Variant = event.get("cell", Vector2i(-1, -1))
        var cell: Vector2i = cell_value
        var board_cell := get_board_cell(cell)
        if board_cell == null:
            continue
        await board_cell.play_drop_event(event)


func get_board_cell(cell: Vector2i) -> BoardCell:
    if cell.x < 0 or cell.x >= GameState.BOARD_COLUMNS or cell.y < 0 or cell.y >= GameState.BOARD_ROWS:
        return null
    var index := cell.y * GameState.BOARD_COLUMNS + cell.x
    if index < 0 or index >= _cells.size():
        return null
    return _cells[index] as BoardCell


func get_cell_at_global_position(global_position: Vector2) -> Vector2i:
    for board_cell in _cells:
        var typed_cell := board_cell as BoardCell
        if typed_cell == null:
            continue
        if typed_cell.get_global_rect().has_point(global_position):
            return typed_cell.cell
    return Vector2i(-1, -1)


func _on_cell_dropped(hand_index: int, cell: Vector2i) -> void:
    card_dropped.emit(hand_index, cell)
