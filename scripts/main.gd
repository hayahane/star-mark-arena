class_name GameManager extends Node

const PLAYER := preload("res://characters/character.tscn")
const DEFAULT_ADDRESS = "localhost"

@export var colors: Array[Color]

@onready var _hud: Control = $Control
@onready var _arena: Node3D = $Arena

var address: String

var _peer = ENetMultiplayerPeer.new()
var _current_player: Character
var _player_count = -1;

func _on_host_pressed() -> void:
	_hud.hide()
	_peer.create_server(6666)
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(add_player)
	_current_player = add_player(multiplayer.get_unique_id())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_client_pressed() -> void:
	_hud.hide()
	_peer.create_client("localhost" if not address else address, 6666)
	multiplayer.multiplayer_peer = _peer
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func add_player(id: int) -> Character:
	var player := PLAYER.instantiate() as Character
	player.name = str(id)
	add_child(player)
	return player

@rpc
func set_player_count(id:int) -> void:
	_player_count += 1


func _on_line_edit_text_changed(new_text: String) -> void:
	address = new_text
