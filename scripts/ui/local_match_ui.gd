extends Control

@onready var _design_root: Control = $DesignRoot


func _ready() -> void:
	_apply_static_styles()
	_fill_placeholder_cards()
	resized.connect(_apply_design_scale)
	_apply_design_scale()


func _apply_design_scale() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(
		viewport_size.x / UiLayoutConfig.DESIGN_SIZE.x,
		viewport_size.y / UiLayoutConfig.DESIGN_SIZE.y
	)
	_design_root.scale = Vector2(scale_factor, scale_factor)
	_design_root.position = (viewport_size - UiLayoutConfig.DESIGN_SIZE * scale_factor) * 0.5


func _apply_static_styles() -> void:
	_set_panel_style("DesignRoot/TopBar", Color.WHITE, UiLayoutConfig.LINE_COLOR, 4, 8)
	_set_panel_style("DesignRoot/TopBar/RoundBadge", Color.BLACK, Color.BLACK, 0, 0)
	_set_panel_style("DesignRoot/LowerArea/P1Area", Color(1, 1, 1, 0.18), UiLayoutConfig.LINE_COLOR, 3, 8)
	_set_panel_style("DesignRoot/LowerArea/P2Area", Color(1, 1, 1, 0.18), UiLayoutConfig.LINE_COLOR, 3, 8)
	_set_panel_style("DesignRoot/LowerArea/PublicPool", Color(1, 1, 1, 0.18), UiLayoutConfig.LINE_COLOR, 3, 8)

	for path in [
		"DesignRoot/PlayerInfo/P1AvatarHead",
		"DesignRoot/PlayerInfo/P2AvatarHead",
		"DesignRoot/PlayerInfo/P1PropSlots/Slot1",
		"DesignRoot/PlayerInfo/P1PropSlots/Slot2",
		"DesignRoot/PlayerInfo/P1PropSlots/Slot3",
		"DesignRoot/PlayerInfo/P2PropSlots/Slot1",
		"DesignRoot/PlayerInfo/P2PropSlots/Slot2",
		"DesignRoot/PlayerInfo/P2PropSlots/Slot3"
	]:
		_set_panel_style(path, Color.WHITE, Color.WHITE, 0, 64)


func _set_panel_style(path: NodePath, bg_color: Color, border_color: Color, border_width: int, radius: int) -> void:
	var panel := get_node_or_null(path) as PanelContainer
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", UiLayoutConfig.make_panel_style(bg_color, border_color, border_width, radius))


func _fill_placeholder_cards() -> void:
	var samples: Array[PvpCardData] = _make_sample_cards()
	_set_card_column("DesignRoot/LowerArea/P1Basket", samples, 0, false)
	_set_card_column("DesignRoot/LowerArea/P2Basket", samples, 1, false)
	_set_public_pool(samples)


func _set_card_column(path: NodePath, samples: Array[PvpCardData], offset: int, compact: bool) -> void:
	var column := get_node_or_null(path)
	if column == null:
		return

	var card_index: int = 0
	for child in column.get_children():
		var card_view := child as LocalCardView
		if card_view == null:
			continue
		card_view.set_card(samples[(card_index + offset) % samples.size()].clone(), compact)
		card_index += 1


func _set_public_pool(samples: Array[PvpCardData]) -> void:
	var pool := get_node_or_null("DesignRoot/LowerArea/PublicPool/Cards")
	if pool == null:
		return

	var card_index: int = 0
	for child in pool.get_children():
		var card_view := child as LocalCardView
		if card_view == null:
			continue
		card_view.set_card(samples[card_index % samples.size()].clone(), true)
		card_index += 1


func _make_sample_cards() -> Array[PvpCardData]:
	return [
		PvpCardData.create("game", "游戏", "游", 1, UiLayoutConfig.P1_ACCENT),
		PvpCardData.create("chat", "聊天", "聊", 2, Color(0.95, 0.62, 0.22)),
		PvpCardData.create("talent", "才艺", "艺", 3, Color(0.82, 0.34, 0.78)),
		PvpCardData.create("wild", "万能", "万", 4, Color(0.25, 0.65, 0.38)),
		PvpCardData.create("chat", "聊天", "聊", 5, UiLayoutConfig.P2_ACCENT)
	]
