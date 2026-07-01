extends Node

signal status_changed(message: String)
signal connection_ready()
signal remote_state_received(snapshot: Dictionary)
signal network_closed()

const DEFAULT_PORT := 42499
const MAX_CLIENTS := 1

var _peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var _remote_peer_id: int = 0
var _mode := "offline"
var _status := "离线"


func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(port: int = DEFAULT_PORT) -> bool:
    close_connection(false)
    _peer = ENetMultiplayerPeer.new()
    var error := _peer.create_server(port, MAX_CLIENTS)
    if error != OK:
        _set_status("开房失败：端口 %d 不可用。" % port)
        return false

    multiplayer.multiplayer_peer = _peer
    _mode = "host"
    _remote_peer_id = 0
    _set_status("开房中：等待同一局域网玩家加入。端口 %d，本机 IP：%s" % [port, get_local_ip_hint()])
    return true


func join_game(address: String, port: int = DEFAULT_PORT) -> bool:
    var cleaned_address := address.strip_edges()
    if cleaned_address.is_empty():
        _set_status("请输入房主的局域网 IP。")
        return false

    close_connection(false)
    _peer = ENetMultiplayerPeer.new()
    var error := _peer.create_client(cleaned_address, port)
    if error != OK:
        _set_status("加入失败：无法连接 %s:%d。" % [cleaned_address, port])
        return false

    multiplayer.multiplayer_peer = _peer
    _mode = "client"
    _remote_peer_id = 1
    _set_status("正在加入 %s:%d ..." % [cleaned_address, port])
    return true


func close_connection(emit_closed: bool = true) -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    _peer = ENetMultiplayerPeer.new()
    _remote_peer_id = 0
    _mode = "offline"
    _set_status("离线")
    if emit_closed:
        network_closed.emit()


func send_player_snapshot(snapshot: Dictionary) -> void:
    if _remote_peer_id <= 0:
        return
    rpc_id(_remote_peer_id, "_receive_player_snapshot", snapshot)


func has_remote_peer() -> bool:
    return _remote_peer_id > 0


func is_online() -> bool:
    return _mode != "offline"


func is_host() -> bool:
    return _mode == "host"


func is_client() -> bool:
    return _mode == "client"


func get_status() -> String:
    return _status


func get_local_ip_hint() -> String:
    var addresses := IP.get_local_addresses()
    var candidates: Array[String] = []
    for address in addresses:
        if not _is_useful_ipv4(address):
            continue
        candidates.append(address)
    if candidates.is_empty():
        return "127.0.0.1"
    return ", ".join(candidates)


func _is_useful_ipv4(address: String) -> bool:
    if address == "127.0.0.1" or address.begins_with("169.254."):
        return false
    if address.find(":") >= 0:
        return false
    return address.count(".") == 3


func _on_peer_connected(peer_id: int) -> void:
    if _mode != "host":
        return
    _remote_peer_id = peer_id
    _set_status("玩家已加入，同步已连接。")
    connection_ready.emit()


func _on_peer_disconnected(peer_id: int) -> void:
    if peer_id != _remote_peer_id:
        return
    _remote_peer_id = 0
    _set_status("对方已断开。")
    network_closed.emit()


func _on_connected_to_server() -> void:
    _remote_peer_id = 1
    _set_status("已加入房间，同步已连接。")
    connection_ready.emit()


func _on_connection_failed() -> void:
    close_connection(false)
    _set_status("连接失败：请确认 IP、端口和防火墙。")
    network_closed.emit()


func _on_server_disconnected() -> void:
    close_connection(false)
    _set_status("房主已断开。")
    network_closed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _receive_player_snapshot(snapshot: Dictionary) -> void:
    var sender_id := multiplayer.get_remote_sender_id()
    if _remote_peer_id <= 0:
        _remote_peer_id = sender_id
    remote_state_received.emit(snapshot)


func _set_status(message: String) -> void:
    _status = message
    status_changed.emit(message)
