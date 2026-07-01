extends Control

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 1

@export var page_title := "PVP 测试入口"
@export_multiline var help_text := "本地双开：第一个窗口创建房间，第二个窗口加入 127.0.0.1:7777。"
@export var default_join_address := "127.0.0.1"
@export var enter_match_button_text := "进入对战测试"
@export var show_lan_addresses := false

var _peer: ENetMultiplayerPeer
var _is_host := false
var _message_count := 0

var _status_label: Label
var _role_label: Label
var _local_ip_label: Label
var _ip_input: LineEdit
var _port_input: SpinBox
var _host_button: Button
var _join_button: Button
var _disconnect_button: Button
var _send_button: Button
var _enter_match_button: Button
var _log_label: RichTextLabel
var _preserve_connection_on_exit := false


func _ready() -> void:
	_build_ui()
	_connect_multiplayer_signals()
	_refresh_buttons()


func _exit_tree() -> void:
	if not _preserve_connection_on_exit:
		_disconnect_from_match()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.09, 0.09, 0.1)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 54)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 22)
	margin.add_child(root_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root_box.add_child(header)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var title := Label.new()
	title.text = page_title
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	_status_label = Label.new()
	_status_label.text = "未连接"
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	root_box.add_child(_status_label)

	_role_label = Label.new()
	_role_label.text = "本机角色：未分配"
	_role_label.add_theme_font_size_override("font_size", 20)
	_role_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	root_box.add_child(_role_label)

	if show_lan_addresses:
		_local_ip_label = Label.new()
		_local_ip_label.text = "本机局域网 IP：" + _get_lan_address_summary() + _get_platform_note()
		_local_ip_label.add_theme_font_size_override("font_size", 20)
		_local_ip_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.78))
		root_box.add_child(_local_ip_label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	root_box.add_child(controls)

	_host_button = Button.new()
	_host_button.text = "创建房间"
	_host_button.custom_minimum_size = Vector2(150, 48)
	_host_button.pressed.connect(_on_host_pressed)
	controls.add_child(_host_button)

	_join_button = Button.new()
	_join_button.text = "加入房间"
	_join_button.custom_minimum_size = Vector2(150, 48)
	_join_button.pressed.connect(_on_join_pressed)
	controls.add_child(_join_button)

	_disconnect_button = Button.new()
	_disconnect_button.text = "断开"
	_disconnect_button.custom_minimum_size = Vector2(110, 48)
	_disconnect_button.pressed.connect(_disconnect_from_match)
	controls.add_child(_disconnect_button)

	var address_row := HBoxContainer.new()
	address_row.add_theme_constant_override("separation", 12)
	root_box.add_child(address_row)

	var ip_label := _make_label("加入地址", 18)
	ip_label.custom_minimum_size = Vector2(86, 36)
	address_row.add_child(ip_label)

	_ip_input = LineEdit.new()
	_ip_input.text = default_join_address
	_ip_input.placeholder_text = "房主局域网 IP"
	_ip_input.custom_minimum_size = Vector2(260, 42)
	address_row.add_child(_ip_input)

	var port_label := _make_label("端口", 18)
	port_label.custom_minimum_size = Vector2(52, 36)
	address_row.add_child(port_label)

	_port_input = SpinBox.new()
	_port_input.min_value = 1024
	_port_input.max_value = 65535
	_port_input.step = 1
	_port_input.value = DEFAULT_PORT
	_port_input.custom_minimum_size = Vector2(130, 42)
	address_row.add_child(_port_input)

	var test_row := HBoxContainer.new()
	test_row.add_theme_constant_override("separation", 12)
	root_box.add_child(test_row)

	_send_button = Button.new()
	_send_button.text = "发送同步测试消息"
	_send_button.custom_minimum_size = Vector2(240, 48)
	_send_button.pressed.connect(_on_send_test_pressed)
	test_row.add_child(_send_button)

	_enter_match_button = Button.new()
	_enter_match_button.text = enter_match_button_text
	_enter_match_button.custom_minimum_size = Vector2(180, 48)
	_enter_match_button.pressed.connect(_on_enter_match_pressed)
	test_row.add_child(_enter_match_button)

	var hint := _make_label(help_text, 18)
	hint.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	test_row.add_child(hint)

	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = false
	_log_label.custom_minimum_size = Vector2(900, 560)
	_log_label.add_theme_font_size_override("normal_font_size", 18)
	root_box.add_child(_log_label)

	_append_log("PVP 网络测试页已就绪。")


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_host_pressed() -> void:
	_disconnect_from_match()
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(int(_port_input.value), MAX_CLIENTS)
	if error != OK:
		_append_log("创建房间失败，错误码：%s" % error)
		return

	multiplayer.multiplayer_peer = _peer
	_is_host = true
	_update_status("等待客户端加入")
	_append_log("已创建房间，端口 %d。" % int(_port_input.value))
	_append_log("另一窗口可加入 127.0.0.1:%d；另一台设备请输入本机局域网 IP。" % int(_port_input.value))
	if show_lan_addresses:
		_append_log("本机可尝试的局域网 IP：%s" % _get_lan_address_summary())
		_append_log("PC/安卓互通：两台设备需在同一 Wi-Fi，客户端输入房主设备的 IPv4 地址。")
	_refresh_buttons()


func _on_join_pressed() -> void:
	_disconnect_from_match()
	_peer = ENetMultiplayerPeer.new()
	var address := _ip_input.text.strip_edges()
	var error := _peer.create_client(address, int(_port_input.value))
	if error != OK:
		_append_log("加入房间失败，错误码：%s" % error)
		return

	multiplayer.multiplayer_peer = _peer
	_is_host = false
	_update_status("正在连接 %s:%d" % [address, int(_port_input.value)])
	_append_log("正在加入房间：%s:%d" % [address, int(_port_input.value)])
	_refresh_buttons()


func _disconnect_from_match() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null
	if _peer != null:
		_peer.close()
		_peer = null
	_is_host = false
	_update_status("未连接")
	_refresh_buttons()


func _on_send_test_pressed() -> void:
	if multiplayer.multiplayer_peer == null:
		_append_log("尚未连接，不能发送测试消息。")
		return
	_message_count += 1
	var role := "Host" if _is_host else "Client"
	_receive_test_message.rpc(multiplayer.get_unique_id(), "%s 测试消息 #%d" % [role, _message_count])


func _on_enter_match_pressed() -> void:
	if multiplayer.multiplayer_peer == null:
		_append_log("尚未连接，不能进入对战测试。")
		return
	_start_network_match.rpc()


@rpc("any_peer", "call_local", "reliable")
func _receive_test_message(sender_id: int, message: String) -> void:
	_append_log("收到同步消息 | peer=%d | %s" % [sender_id, message])


@rpc("any_peer", "call_local", "reliable")
func _start_network_match() -> void:
	_preserve_connection_on_exit = true
	get_tree().change_scene_to_file("res://scenes/pvp_match_test.tscn")


func _on_peer_connected(peer_id: int) -> void:
	_update_status("已连接")
	_append_log("Peer %d 已连接。" % peer_id)
	_refresh_buttons()


func _on_peer_disconnected(peer_id: int) -> void:
	_update_status("对方已断开")
	_append_log("Peer %d 已断开。" % peer_id)
	_refresh_buttons()


func _on_connected_to_server() -> void:
	_update_status("已连接到房主")
	_append_log("已连接到房主。")
	_refresh_buttons()


func _on_connection_failed() -> void:
	_update_status("连接失败")
	_append_log("连接失败。请检查 IP、端口和防火墙。")
	_refresh_buttons()


func _on_server_disconnected() -> void:
	_update_status("房主已断开")
	_append_log("房主已断开。")
	_refresh_buttons()


func _update_status(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = "状态：%s" % text
	var role := "Host / 房主" if _is_host else "Client / 加入者"
	var peer_id := 0
	if multiplayer.multiplayer_peer == null:
		role = "未分配"
	else:
		peer_id = multiplayer.get_unique_id()
	_role_label.text = "本机角色：%s | Peer ID：%d" % [role, peer_id]


func _refresh_buttons() -> void:
	if _host_button == null:
		return
	var connected := multiplayer.multiplayer_peer != null
	_host_button.disabled = connected
	_join_button.disabled = connected
	_disconnect_button.disabled = not connected
	_send_button.disabled = not connected
	_enter_match_button.disabled = not connected


func _append_log(text: String) -> void:
	if _log_label == null:
		return
	_log_label.append_text("[%s] %s\n" % [Time.get_time_string_from_system(), text])
	_log_label.scroll_to_line(_log_label.get_line_count())


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _get_lan_address_summary() -> String:
	var addresses := IP.get_local_addresses()
	var candidates: Array[String] = []
	for address in addresses:
		var value := str(address)
		if _is_lan_ipv4(value):
			candidates.append(value)
	if candidates.is_empty():
		return "未检测到，请在系统网络设置中查看 IPv4 地址"
	return ", ".join(candidates)


func _get_platform_note() -> String:
	if OS.has_feature("android"):
		return " | Android"
	if OS.has_feature("windows"):
		return " | Windows"
	return ""


func _is_lan_ipv4(address: String) -> bool:
	if address.contains(":"):
		return false
	if address.begins_with("127."):
		return false
	if address.begins_with("10."):
		return true
	if address.begins_with("192.168."):
		return true
	if address.begins_with("172."):
		var parts := address.split(".")
		if parts.size() >= 2:
			var second := int(parts[1])
			return second >= 16 and second <= 31
	return false


func _on_back_pressed() -> void:
	_disconnect_from_match()
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
