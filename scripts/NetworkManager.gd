extends Node

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal connection_failed(msg)

enum { MODE_NONE, MODE_HOST, MODE_CLIENT }
var mode = MODE_NONE
var player_name = "Player"

func host_game(port: int = 8910, max_players: int = 4):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, max_players)
	if err != OK:
		connection_failed.emit("Failed to host: " + str(err))
		return false
	multiplayer.multiplayer_peer = peer
	mode = MODE_HOST
	print("Hosting on port ", port)
	return true

func join_game(ip: String, port: int = 8910):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		connection_failed.emit("Failed to join: " + str(err))
		return false
	multiplayer.multiplayer_peer = peer
	mode = MODE_CLIENT
	print("Joining ", ip, ":", port)
	return true

func disconnect_from_game():
	multiplayer.multiplayer_peer = null
	mode = MODE_NONE

@rpc("any_peer", "reliable")
func register_player(p_name: String):
	if mode != MODE_HOST: return
	var pid = multiplayer.get_remote_sender_id()
	player_connected.emit(pid)

@rpc("authority", "reliable")
func spawn_player(pid: int, pos: Vector2):
	pass  # MainGame handles this

@rpc("any_peer", "unreliable")
func sync_position(pid: int, pos: Vector2, dir: Vector2):
	pass  # MainGame handles remote player sync
