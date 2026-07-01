class_name UiLayoutConfig
extends RefCounted

const DESIGN_SIZE := Vector2(1920, 1080)

const BACKGROUND_COLOR := Color(0.86, 0.86, 0.86)
const PANEL_COLOR := Color(0.95, 0.95, 0.95)
const LINE_COLOR := Color(0.08, 0.08, 0.08)
const MUTED_LINE_COLOR := Color(0.44, 0.44, 0.44)
const BOARD_EMPTY_COLOR := Color(0.9, 0.9, 0.9)
const BOARD_BONUS_COLOR := Color(0.79, 0.79, 0.79)
const CARD_COLOR := Color(0.94, 0.94, 0.94)
const TEXT_COLOR := Color(0.04, 0.04, 0.04)
const P1_ACCENT := Color(0.24, 0.48, 0.95)
const P2_ACCENT := Color(0.95, 0.35, 0.35)

const TOP_BAR_RECT := Rect2(36, 28, 1848, 72)
const TOP_BAR_CENTER_SIZE := Vector2(210, 72)
const INFO_AREA_RECT := Rect2(0, 100, 1920, 250)
const TIMER_POSITION := Vector2(960, 210)

const LEFT_BOARD_RECT := Rect2(64, 480, 528, 552)
const RIGHT_BOARD_RECT := Rect2(1328, 480, 528, 552)
const BOARD_COLUMNS := 6
const BOARD_ROWS := 5
const BOARD_CELL_SIZE := Vector2(88, 110.4)

const BASKET_CARD_SIZE := Vector2(78, 104)
const P1_BASKET_RECT := Rect2(666, 562, 78, 464)
const P2_BASKET_RECT := Rect2(1194, 562, 78, 464)
const BASKET_GAP := 16

const PUBLIC_POOL_RECT := Rect2(808, 488, 304, 544)
const PUBLIC_POOL_CARD_SIZE := Vector2(76, 98)
const PUBLIC_POOL_COLUMNS := 2
const PUBLIC_POOL_ROWS := 5
const PUBLIC_POOL_GAP := Vector2(52, 18)

const AVATAR_HEAD_SIZE := Vector2(108, 108)
const PROP_SLOT_SIZE := Vector2(52, 52)
const START_BUTTON_SIZE := Vector2(360, 72)


static func make_panel_style(bg_color: Color = PANEL_COLOR, border_color: Color = LINE_COLOR, border_width: int = 3, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


static func make_plain_style(bg_color: Color, radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
