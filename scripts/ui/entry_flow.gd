extends Control

const LiveAccountScript := preload("res://scripts/live/live_account.gd")

@export var account_page_path: NodePath = ^"AccountPage"
@export var lobby_page_path: NodePath = ^"LobbyPage"
@export var skill_page_path: NodePath = ^"SkillPage"
@export var vs_page_path: NodePath = ^"VsPage"
@export var battle_page_path: NodePath = ^"BattlePage"
@export var settlement_page_path: NodePath = ^"SettlementPage"
@export var result_ranking_page_path: NodePath = ^"ResultRankingPage"
@export var account_name_input_path: NodePath = ^"AccountPage/AccountCard/NameInput"
@export var account_preview_avatar_path: NodePath = ^"AccountPage/AccountCard/PreviewAvatar"
@export var create_account_button_path: NodePath = ^"AccountPage/CreateAccountButton"
@export var avatar_choices_path: NodePath = ^"AccountPage/AccountCard/AvatarChoices"
@export var lobby_avatar_path: NodePath = ^"LobbyPage/LivePanel/AccountStrip/LobbyAvatar"
@export var lobby_name_path: NodePath = ^"LobbyPage/LivePanel/AccountStrip/LobbyName"
@export var lobby_id_path: NodePath = ^"LobbyPage/LivePanel/AccountStrip/LobbyId"
@export var lobby_heat_path: NodePath = ^"LobbyPage/LivePanel/AccountStrip/LobbyHeat"
@export var video_panel_path: NodePath = ^"LobbyPage/LivePanel/VideoPanel"
@export var video_title_path: NodePath = ^"LobbyPage/LivePanel/VideoPanel/VideoTitle"
@export var video_subtitle_path: NodePath = ^"LobbyPage/LivePanel/VideoPanel/VideoSubtitle"
@export var live_heat_path: NodePath = ^"LobbyPage/LivePanel/HeatLabel"
@export var start_button_path: NodePath = ^"LobbyPage/StartGameButton"
@export var rules_button_path: NodePath = ^"LobbyPage/RulesButton"
@export var ranking_button_path: NodePath = ^"LobbyPage/RankingButton"
@export var exit_button_path: NodePath = ^"LobbyPage/HeaderPanel/ExitButton"
@export var lobby_status_path: NodePath = ^"LobbyPage/LobbyStatusLabel"
@export var rules_modal_path: NodePath = ^"RulesModal"
@export var ranking_modal_path: NodePath = ^"RankingModal"
@export var rules_close_button_path: NodePath = ^"RulesModal/ModalPanel/CloseButton"
@export var ranking_close_button_path: NodePath = ^"RankingModal/ModalPanel/CloseButton"
@export var skill_player_avatar_path: NodePath = ^"SkillPage/PlayerCard/PlayerAvatar"
@export var skill_player_name_path: NodePath = ^"SkillPage/PlayerCard/PlayerName"
@export var skill_choices_path: NodePath = ^"SkillPage/PlayerCard/SkillChoices"
@export var skill_tip_path: NodePath = ^"SkillPage/SkillTip"
@export var skill_tip_title_path: NodePath = ^"SkillPage/SkillTip/TipTitle"
@export var skill_tip_effect_path: NodePath = ^"SkillPage/SkillTip/TipEffect"
@export var start_pk_button_path: NodePath = ^"SkillPage/StartPkButton"
@export var vs_player_card_path: NodePath = ^"VsPage/PlayerVsCard"
@export var vs_enemy_card_path: NodePath = ^"VsPage/EnemyVsCard"
@export var vs_label_path: NodePath = ^"VsPage/VsLabel"
@export var vs_player_avatar_path: NodePath = ^"VsPage/PlayerVsCard/PlayerAvatar"
@export var vs_enemy_avatar_path: NodePath = ^"VsPage/EnemyVsCard/EnemyAvatar"
@export var vs_player_name_path: NodePath = ^"VsPage/PlayerVsCard/PlayerName"
@export var vs_enemy_name_path: NodePath = ^"VsPage/EnemyVsCard/EnemyName"
@export var vs_player_skill_a_path: NodePath = ^"VsPage/PlayerVsCard/SkillA"
@export var vs_player_skill_b_path: NodePath = ^"VsPage/PlayerVsCard/SkillB"
@export var vs_enemy_skill_a_path: NodePath = ^"VsPage/EnemyVsCard/SkillA"
@export var vs_enemy_skill_b_path: NodePath = ^"VsPage/EnemyVsCard/SkillB"
@export var battle_end_button_path: NodePath = ^"BattlePage/EndButton"
@export var settlement_title_path: NodePath = ^"SettlementPage/WinBanner/WinTitle"
@export var settlement_player_name_path: NodePath = ^"SettlementPage/PlayerPanel/PlayerName"
@export var settlement_enemy_name_path: NodePath = ^"SettlementPage/EnemyPanel/EnemyName"
@export var settlement_player_heat_path: NodePath = ^"SettlementPage/PlayerPanel/HeatValue"
@export var settlement_enemy_heat_path: NodePath = ^"SettlementPage/EnemyPanel/HeatValue"
@export var settlement_player_progress_path: NodePath = ^"SettlementPage/PlayerPanel/ProgressBar/Fill"
@export var settlement_enemy_progress_path: NodePath = ^"SettlementPage/EnemyPanel/ProgressBar/Fill"
@export var settlement_continue_button_path: NodePath = ^"SettlementPage/ContinueButton"
@export var result_retry_button_path: NodePath = ^"ResultRankingPage/RetryButton"
@export var result_lobby_button_path: NodePath = ^"ResultRankingPage/LobbyButton"

var _used_ids := {}
var _selected_avatar_index := 0
var _current_account: RefCounted = null
var _avatar_buttons: Array[Button] = []
var _skill_buttons: Array[Button] = []
var _selected_skill_indices: Array[int] = []
var _vs_player_home := Vector2.ZERO
var _vs_enemy_home := Vector2.ZERO
var _vs_label_home := Vector2.ZERO
var _avatar_colors := [
	Color(1.0, 0.42, 0.42),
	Color(0.3, 0.67, 0.97),
	Color(1.0, 0.83, 0.23)
]
var _skill_icon_colors := [
	Color(0.86, 0.24, 0.28),
	Color(0.26, 0.54, 0.95),
	Color(0.29, 0.72, 0.42)
]
var _button_hover_color := Color(0.72, 0.9, 0.96)
var _button_pressed_color := Color(0.55, 0.82, 0.92)
var _skill_selected_color := Color(0.78, 0.91, 1.0)
var _skills := [
	{"name": "十方寂灭", "effect": "将连续发动十次攻击。"},
	{"name": "蓄力一击", "effect": "跳过本回合，下回合将发动一次牛逼的攻击。"},
	{"name": "观众共鸣", "effect": "本次 PK 开场获得额外热度加成。"}
]
var _enemy_config := {
	"name": "默认对手",
	"avatar_index": 1,
	"skills": ["蓄力一击", "观众共鸣"]
}
var _last_player_heat := 128
var _last_enemy_heat := 104
var _video_bands := [
	{"title": "唱见舞台", "subtitle": "随机频段 A / 临时直播画面", "color": Color(0.93, 0.78, 0.46)},
	{"title": "舞蹈练习室", "subtitle": "随机频段 B / 临时直播画面", "color": Color(0.55, 0.77, 0.92)},
	{"title": "聊天电台", "subtitle": "随机频段 C / 临时直播画面", "color": Color(0.66, 0.84, 0.64)}
]

@onready var _account_page: Control = get_node(account_page_path)
@onready var _lobby_page: Control = get_node(lobby_page_path)
@onready var _skill_page: Control = get_node(skill_page_path)
@onready var _vs_page: Control = get_node(vs_page_path)
@onready var _battle_page: Control = get_node(battle_page_path)
@onready var _settlement_page: Control = get_node(settlement_page_path)
@onready var _result_ranking_page: Control = get_node(result_ranking_page_path)
@onready var _name_input: LineEdit = get_node(account_name_input_path)
@onready var _preview_avatar: Panel = get_node(account_preview_avatar_path)
@onready var _create_account_button: Button = get_node(create_account_button_path)
@onready var _avatar_choices: Control = get_node(avatar_choices_path)
@onready var _lobby_avatar: Panel = get_node(lobby_avatar_path)
@onready var _lobby_name: Label = get_node(lobby_name_path)
@onready var _lobby_id: Label = get_node(lobby_id_path)
@onready var _lobby_heat: Label = get_node(lobby_heat_path)
@onready var _video_panel: Panel = get_node(video_panel_path)
@onready var _video_title: Label = get_node(video_title_path)
@onready var _video_subtitle: Label = get_node(video_subtitle_path)
@onready var _live_heat: Label = get_node(live_heat_path)
@onready var _start_button: Button = get_node(start_button_path)
@onready var _rules_button: Button = get_node(rules_button_path)
@onready var _ranking_button: Button = get_node(ranking_button_path)
@onready var _exit_button: Button = get_node(exit_button_path)
@onready var _lobby_status: Label = get_node(lobby_status_path)
@onready var _rules_modal: Control = get_node(rules_modal_path)
@onready var _ranking_modal: Control = get_node(ranking_modal_path)
@onready var _rules_close_button: Button = get_node(rules_close_button_path)
@onready var _ranking_close_button: Button = get_node(ranking_close_button_path)
@onready var _skill_player_avatar: Panel = get_node(skill_player_avatar_path)
@onready var _skill_player_name: Label = get_node(skill_player_name_path)
@onready var _skill_choices: Control = get_node(skill_choices_path)
@onready var _skill_tip: Control = get_node(skill_tip_path)
@onready var _skill_tip_title: Label = get_node(skill_tip_title_path)
@onready var _skill_tip_effect: Label = get_node(skill_tip_effect_path)
@onready var _start_pk_button: Button = get_node(start_pk_button_path)
@onready var _vs_player_card: Control = get_node(vs_player_card_path)
@onready var _vs_enemy_card: Control = get_node(vs_enemy_card_path)
@onready var _vs_label: Label = get_node(vs_label_path)
@onready var _vs_player_avatar: Panel = get_node(vs_player_avatar_path)
@onready var _vs_enemy_avatar: Panel = get_node(vs_enemy_avatar_path)
@onready var _vs_player_name: Label = get_node(vs_player_name_path)
@onready var _vs_enemy_name: Label = get_node(vs_enemy_name_path)
@onready var _vs_player_skill_a: Label = get_node(vs_player_skill_a_path)
@onready var _vs_player_skill_b: Label = get_node(vs_player_skill_b_path)
@onready var _vs_enemy_skill_a: Label = get_node(vs_enemy_skill_a_path)
@onready var _vs_enemy_skill_b: Label = get_node(vs_enemy_skill_b_path)
@onready var _battle_end_button: Button = get_node(battle_end_button_path)
@onready var _settlement_title: Label = get_node(settlement_title_path)
@onready var _settlement_player_name: Label = get_node(settlement_player_name_path)
@onready var _settlement_enemy_name: Label = get_node(settlement_enemy_name_path)
@onready var _settlement_player_heat: Label = get_node(settlement_player_heat_path)
@onready var _settlement_enemy_heat: Label = get_node(settlement_enemy_heat_path)
@onready var _settlement_player_progress: Panel = get_node(settlement_player_progress_path)
@onready var _settlement_enemy_progress: Panel = get_node(settlement_enemy_progress_path)
@onready var _settlement_continue_button: Button = get_node(settlement_continue_button_path)
@onready var _result_retry_button: Button = get_node(result_retry_button_path)
@onready var _result_lobby_button: Button = get_node(result_lobby_button_path)


func _ready() -> void:
	_cache_avatar_buttons()
	_cache_skill_buttons()
	_connect_signals()
	_apply_scene_styles()
	_configure_ranking_table()
	_configure_result_ranking_table()
	_setup_skill_buttons()
	_store_vs_home_positions()
	_select_avatar(0)
	_show_account_page()


func _cache_avatar_buttons() -> void:
	_avatar_buttons.clear()
	for child in _avatar_choices.get_children():
		var button := child as Button
		if button != null:
			_avatar_buttons.append(button)


func _cache_skill_buttons() -> void:
	_skill_buttons.clear()
	for child in _skill_choices.get_children():
		var button := child as Button
		if button != null:
			_skill_buttons.append(button)


func _connect_signals() -> void:
	for index in range(_avatar_buttons.size()):
		_avatar_buttons[index].pressed.connect(_select_avatar.bind(index))
	for index in range(_skill_buttons.size()):
		_skill_buttons[index].pressed.connect(_toggle_skill.bind(index))
		_skill_buttons[index].mouse_entered.connect(_show_skill_tip.bind(index))
		_skill_buttons[index].mouse_exited.connect(_hide_skill_tip)

	_create_account_button.pressed.connect(_on_create_account_pressed)
	_start_button.pressed.connect(_on_start_game_pressed)
	_start_pk_button.pressed.connect(_on_start_pk_pressed)
	_battle_end_button.pressed.connect(_show_settlement_page)
	_settlement_continue_button.pressed.connect(_show_result_ranking_page)
	_result_retry_button.pressed.connect(_restart_pk_flow)
	_result_lobby_button.pressed.connect(_show_lobby_page)
	_rules_button.pressed.connect(_show_rules_modal)
	_ranking_button.pressed.connect(_show_ranking_modal)
	_exit_button.pressed.connect(_on_exit_pressed)
	_rules_close_button.pressed.connect(_hide_modals)
	_ranking_close_button.pressed.connect(_hide_modals)


func _select_avatar(index: int) -> void:
	if index < 0 or index >= _avatar_buttons.size():
		return

	_selected_avatar_index = index
	for button_index in range(_avatar_buttons.size()):
		var button := _avatar_buttons[button_index]
		var avatar_color: Color = _avatar_colors[button_index % _avatar_colors.size()]
		var border_color := Color(0.08, 0.08, 0.08) if button_index == index else Color(0.55, 0.55, 0.55)
		var hover_border := Color(0.1, 0.45, 0.95)
		button.add_theme_stylebox_override("normal", _make_style(avatar_color, border_color, 4 if button_index == index else 2, 42))
		button.add_theme_stylebox_override("hover", _make_style(avatar_color.lightened(0.18), hover_border, 5, 42))
		button.add_theme_stylebox_override("pressed", _make_style(avatar_color.darkened(0.08), border_color, 4, 42))
		_apply_button_font_colors(button)
		button.scale = Vector2(1.06, 1.06) if button_index == index else Vector2.ONE

	_preview_avatar.add_theme_stylebox_override("panel", _make_style(_avatar_colors[index], Color(0.08, 0.08, 0.08), 4, 60))


func _setup_skill_buttons() -> void:
	for index in range(_skill_buttons.size()):
		if index >= _skills.size():
			continue
		var skill: Dictionary = _skills[index]
		var button := _skill_buttons[index]
		button.text = ""
		button.add_theme_font_size_override("font_size", 1)
		_set_child_label_text(button, "NameLabel", str(skill["name"]))
		_set_panel_style(button.get_node_or_null("IconCircle") as Panel, _skill_icon_colors[index % _skill_icon_colors.size()], Color(0.12, 0.12, 0.12), 3, 48)
	_update_skill_button_styles()
	_hide_skill_tip()


func _store_vs_home_positions() -> void:
	_vs_player_home = _vs_player_card.position
	_vs_enemy_home = _vs_enemy_card.position
	_vs_label_home = _vs_label.position


func _on_create_account_pressed() -> void:
	_current_account = LiveAccountScript.create(_name_input.text, _selected_avatar_index, _used_ids)
	_apply_lobby_account()
	_randomize_video_band()
	_show_lobby_page()


func _apply_lobby_account() -> void:
	if _current_account == null:
		return

	_lobby_avatar.add_theme_stylebox_override("panel", _make_style(_avatar_colors[_current_account.avatar_index], Color(0.08, 0.08, 0.08), 4, 48))
	_lobby_name.text = _current_account.display_name
	_lobby_id.text = "ID %s" % _current_account.account_id
	_lobby_heat.text = "热度 %d" % int(_current_account.heat)
	_live_heat.text = "👁 1.2w"
	_lobby_status.text = ""


func _apply_skill_page_account() -> void:
	if _current_account == null:
		return
	_skill_player_avatar.add_theme_stylebox_override("panel", _make_style(_avatar_colors[_current_account.avatar_index], Color(0.08, 0.08, 0.08), 4, 60))
	_skill_player_name.text = _current_account.display_name


func _randomize_video_band() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var band: Dictionary = _video_bands[rng.randi_range(0, _video_bands.size() - 1)]
	_video_panel.add_theme_stylebox_override("panel", _make_style(band["color"], Color(0.18, 0.18, 0.18), 4, 6))
	_video_title.text = str(band["title"])
	_video_subtitle.text = str(band["subtitle"])


func _on_start_game_pressed() -> void:
	_apply_skill_page_account()
	_selected_skill_indices.clear()
	_update_skill_button_styles()
	_show_skill_page()


func _toggle_skill(index: int) -> void:
	if index < 0 or index >= _skills.size():
		return
	if _selected_skill_indices.has(index):
		_selected_skill_indices.erase(index)
	elif _selected_skill_indices.size() < 2:
		_selected_skill_indices.append(index)
	_update_skill_button_styles()


func _update_skill_button_styles() -> void:
	for index in range(_skill_buttons.size()):
		var selected := _selected_skill_indices.has(index)
		var bg_color := _skill_selected_color if selected else Color(1.0, 1.0, 1.0, 0.0)
		var border_color := Color(0.1, 0.45, 0.95) if selected else Color(0.12, 0.12, 0.12)
		var border_width := 5 if selected else 3
		var button := _skill_buttons[index]
		button.add_theme_stylebox_override("normal", _make_style(bg_color, border_color, border_width, 8))
		button.add_theme_stylebox_override("hover", _make_style(_button_hover_color, border_color, border_width, 8))
		button.add_theme_stylebox_override("pressed", _make_style(_button_pressed_color, border_color, border_width, 8))
		_apply_button_font_colors(button)
		var icon_border := Color(0.1, 0.45, 0.95) if selected else Color(0.12, 0.12, 0.12)
		var icon_width := 5 if selected else 3
		_set_panel_style(button.get_node_or_null("IconCircle") as Panel, _skill_icon_colors[index % _skill_icon_colors.size()], icon_border, icon_width, 48)
	_start_pk_button.disabled = _selected_skill_indices.size() != 2


func _show_skill_tip(index: int) -> void:
	if index < 0 or index >= _skills.size():
		return
	var skill: Dictionary = _skills[index]
	_skill_tip_title.text = str(skill["name"])
	_skill_tip_effect.text = str(skill["effect"])
	var hovered_button := _skill_buttons[index]
	_skill_tip.global_position = hovered_button.global_position + Vector2(hovered_button.size.x + 18.0, 10.0)
	_skill_tip.visible = true


func _hide_skill_tip() -> void:
	_skill_tip.visible = false


func _on_start_pk_pressed() -> void:
	if _selected_skill_indices.size() != 2:
		return
	_prepare_vs_page()
	_show_vs_page()
	await _play_vs_intro()
	_show_battle_page()


func _restart_pk_flow() -> void:
	_apply_skill_page_account()
	_selected_skill_indices.clear()
	_update_skill_button_styles()
	_show_skill_page()


func _prepare_vs_page() -> void:
	var player_name := "P1 主播"
	var player_avatar_index := 0
	if _current_account != null:
		player_name = _current_account.display_name
		player_avatar_index = _current_account.avatar_index

	var first_skill := _get_selected_skill_name(0)
	var second_skill := _get_selected_skill_name(1)
	_vs_player_name.text = player_name
	_vs_player_avatar.add_theme_stylebox_override("panel", _make_style(_avatar_colors[player_avatar_index], Color(0.08, 0.08, 0.08), 4, 60))
	_set_vs_skill_visual("VsPage/PlayerVsCard/SkillIconA", _vs_player_skill_a, first_skill)
	_set_vs_skill_visual("VsPage/PlayerVsCard/SkillIconB", _vs_player_skill_b, second_skill)

	var enemy_avatar_index := int(_enemy_config["avatar_index"])
	var enemy_skills: Array = _enemy_config["skills"]
	_vs_enemy_name.text = str(_enemy_config["name"])
	_vs_enemy_avatar.add_theme_stylebox_override("panel", _make_style(_avatar_colors[enemy_avatar_index], Color(0.08, 0.08, 0.08), 4, 60))
	_set_vs_skill_visual("VsPage/EnemyVsCard/SkillIconA", _vs_enemy_skill_a, str(enemy_skills[0]))
	_set_vs_skill_visual("VsPage/EnemyVsCard/SkillIconB", _vs_enemy_skill_b, str(enemy_skills[1]))


func _prepare_settlement_page() -> void:
	var player_name := "P1 主播"
	if _current_account != null:
		player_name = _current_account.display_name
	_last_player_heat = 128
	_last_enemy_heat = 104

	_settlement_title.text = "%s WIN" % player_name
	_settlement_player_name.text = player_name
	_settlement_enemy_name.text = str(_enemy_config["name"])
	_settlement_player_heat.text = str(_last_player_heat)
	_settlement_enemy_heat.text = str(_last_enemy_heat)
	_set_panel_style(_settlement_player_progress, Color(1.0, 0.78, 0.22), Color(0.12, 0.12, 0.12), 0, 2)
	_set_panel_style(_settlement_enemy_progress, Color(1.0, 0.78, 0.22), Color(0.12, 0.12, 0.12), 0, 2)
	_set_progress_width(_settlement_player_progress, 356.0, 0.82)
	_set_progress_width(_settlement_enemy_progress, 356.0, 0.66)


func _set_progress_width(fill: Control, max_width: float, ratio: float) -> void:
	fill.size = Vector2(max_width * clampf(ratio, 0.0, 1.0), fill.size.y)


func _get_selected_skill_name(selected_slot: int) -> String:
	if selected_slot < 0 or selected_slot >= _selected_skill_indices.size():
		return "--"
	var skill_index := _selected_skill_indices[selected_slot]
	if skill_index < 0 or skill_index >= _skills.size():
		return "--"
	return str(_skills[skill_index]["name"])


func _set_vs_skill_visual(icon_path: NodePath, label: Label, skill_name: String) -> void:
	label.text = skill_name
	label.add_theme_color_override("font_color", Color.BLACK)
	var icon := get_node_or_null(icon_path) as Panel
	if icon == null:
		return
	var skill_index := _find_skill_index_by_name(skill_name)
	_set_panel_style(icon, _skill_icon_colors[skill_index % _skill_icon_colors.size()], Color(0.12, 0.12, 0.12), 3, 42)


func _find_skill_index_by_name(skill_name: String) -> int:
	for index in range(_skills.size()):
		if str(_skills[index]["name"]) == skill_name:
			return index
	return 0


func _play_vs_intro() -> void:
	_vs_player_card.position = Vector2(-640.0, _vs_player_home.y)
	_vs_enemy_card.position = Vector2(1920.0, _vs_enemy_home.y)
	_vs_label.position = _vs_label_home
	_vs_label.scale = Vector2(0.5, 0.5)
	_vs_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_vs_player_card, "position", _vs_player_home + Vector2(90.0, 0.0), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_vs_enemy_card, "position", _vs_enemy_home - Vector2(90.0, 0.0), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_vs_label, "modulate:a", 1.0, 0.45)
	tween.tween_property(_vs_label, "scale", Vector2(1.18, 1.18), 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	var bounce := create_tween()
	bounce.set_parallel(true)
	bounce.tween_property(_vs_player_card, "position", _vs_player_home - Vector2(24.0, 0.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.tween_property(_vs_enemy_card, "position", _vs_enemy_home + Vector2(24.0, 0.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.tween_property(_vs_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await bounce.finished

	await get_tree().create_timer(1.45).timeout
	_vs_player_card.position = _vs_player_home
	_vs_enemy_card.position = _vs_enemy_home
	_vs_label.position = _vs_label_home
	_vs_label.scale = Vector2.ONE
	_vs_label.modulate.a = 1.0


func _on_exit_pressed() -> void:
	get_tree().quit()


func _show_account_page() -> void:
	_account_page.visible = true
	_lobby_page.visible = false
	_skill_page.visible = false
	_vs_page.visible = false
	_battle_page.visible = false
	_settlement_page.visible = false
	_result_ranking_page.visible = false
	_hide_modals()


func _show_lobby_page() -> void:
	_account_page.visible = false
	_lobby_page.visible = true
	_skill_page.visible = false
	_vs_page.visible = false
	_battle_page.visible = false
	_settlement_page.visible = false
	_result_ranking_page.visible = false
	_hide_skill_tip()
	_hide_modals()


func _show_skill_page() -> void:
	_account_page.visible = false
	_lobby_page.visible = false
	_skill_page.visible = true
	_vs_page.visible = false
	_battle_page.visible = false
	_settlement_page.visible = false
	_result_ranking_page.visible = false
	_hide_modals()


func _show_vs_page() -> void:
	_account_page.visible = false
	_lobby_page.visible = false
	_skill_page.visible = false
	_vs_page.visible = true
	_battle_page.visible = false
	_settlement_page.visible = false
	_result_ranking_page.visible = false
	_hide_modals()


func _show_battle_page() -> void:
	_account_page.visible = false
	_lobby_page.visible = false
	_skill_page.visible = false
	_vs_page.visible = false
	_battle_page.visible = true
	_settlement_page.visible = false
	_result_ranking_page.visible = false
	_hide_modals()


func _show_settlement_page() -> void:
	_prepare_settlement_page()
	_account_page.visible = false
	_lobby_page.visible = false
	_skill_page.visible = false
	_vs_page.visible = false
	_battle_page.visible = false
	_settlement_page.visible = true
	_result_ranking_page.visible = false
	_hide_modals()


func _show_result_ranking_page() -> void:
	_configure_result_ranking_table()
	_account_page.visible = false
	_lobby_page.visible = false
	_skill_page.visible = false
	_vs_page.visible = false
	_battle_page.visible = false
	_settlement_page.visible = false
	_result_ranking_page.visible = true
	_hide_modals()


func _show_rules_modal() -> void:
	_rules_modal.visible = true
	_ranking_modal.visible = false


func _show_ranking_modal() -> void:
	_rules_modal.visible = false
	_ranking_modal.visible = true


func _hide_modals() -> void:
	_rules_modal.visible = false
	_ranking_modal.visible = false


func _configure_ranking_table() -> void:
	_configure_ranking_table_at("RankingModal/ModalPanel")


func _configure_result_ranking_table() -> void:
	_configure_ranking_table_at("ResultRankingPage/RankingPanel")


func _configure_ranking_table_at(root_path: String) -> void:
	_set_label_text_and_black("%s/HeaderRow/HeaderRank" % root_path, "排名")
	_set_label_text_and_black("%s/HeaderRow/HeaderName" % root_path, "昵称")
	_set_label_text_and_black("%s/HeaderRow/HeaderHeat" % root_path, "热度")
	_set_label_text_and_black("%s/HeaderRow/HeaderReward" % root_path, "结算奖励")

	var time_header := get_node_or_null("%s/HeaderRow/HeaderTime" % root_path) as Label
	if time_header != null:
		time_header.visible = false

	var rows := [
		{"rank": "#1", "name": "花火主播", "heat": 128, "reward": "+100粉丝"},
		{"rank": "#2", "name": "星光主播", "heat": 116, "reward": "+100粉丝"},
		{"rank": "#3", "name": "玩家甲", "heat": 109, "reward": "+100粉丝"},
		{"rank": "#4", "name": "--", "heat": "--", "reward": "--"},
		{"rank": "#5", "name": "--", "heat": "--", "reward": "--"},
		{"rank": "#6", "name": "--", "heat": "--", "reward": "--"}
	]
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var row_path := "%s/Row%d" % [root_path, index + 1]
		_set_label_text_and_black("%s/RankLabel" % row_path, str(row["rank"]))
		_set_label_text_and_black("%s/NameLabel" % row_path, str(row["name"]))
		_set_label_text_and_black("%s/HeatLabel" % row_path, str(row["heat"]))
		_set_label_text_and_black("%s/RewardLabel" % row_path, str(row["reward"]))


func _set_label_text_and_black(path: NodePath, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label == null:
		return
	label.text = text
	label.add_theme_color_override("font_color", Color.BLACK)


func _apply_scene_styles() -> void:
	for panel in get_tree().get_nodes_in_group("outlined_panels"):
		var typed_panel := panel as Panel
		if typed_panel != null:
			typed_panel.add_theme_stylebox_override("panel", _make_style(Color(0.96, 0.96, 0.96), Color(0.13, 0.13, 0.13), 3, 6))

	for button in get_tree().get_nodes_in_group("primary_buttons"):
		var typed_button := button as Button
		if typed_button != null:
			_apply_button_style(typed_button, Color(0.98, 0.98, 0.98), Color(0.12, 0.12, 0.12))

	for backdrop in get_tree().get_nodes_in_group("modal_backdrops"):
		var typed_backdrop := backdrop as ColorRect
		if typed_backdrop != null:
			typed_backdrop.color = Color(0.0, 0.0, 0.0, 0.32)


func _apply_button_style(button: Button, bg_color: Color, border_color: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_style(bg_color, border_color, 3, 8))
	button.add_theme_stylebox_override("hover", _make_style(_button_hover_color, border_color, 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(_button_pressed_color, border_color, 3, 8))
	_apply_button_font_colors(button)
	if not button.has_theme_font_size_override("font_size"):
		button.add_theme_font_size_override("font_size", 28)


func _apply_button_font_colors(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_color_override("font_focus_color", Color.BLACK)
	button.add_theme_color_override("font_disabled_color", Color(0.2, 0.2, 0.2))


func _set_child_label_text(parent: Node, child_name: String, text: String) -> void:
	var label := parent.get_node_or_null(child_name) as Label
	if label == null:
		return
	label.text = text
	label.add_theme_color_override("font_color", Color.BLACK)


func _set_panel_style(panel: Panel, bg_color: Color, border_color: Color, border_width: int, radius: int) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, border_width, radius))


func _make_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
