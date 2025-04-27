@tool
extends Synchronizer

class_name MultiplayerClass

class PlayerPeer:
	var id: int
	var name: String

	func init(id: int, name: String) -> PlayerPeer:
		self.id = id
		self.name = name
		return self

var players = Parameter.new(self, {} as Dictionary[int, PlayerPeer])
var me: PlayerPeer = null

signal new_player_joined(player: PlayerPeer)

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server() -> void:
	var player = PlayerPeer.new().init(multiplayer.get_unique_id(), self.get_meta("player_name", ""))
	me = player
	new_player_added(me).rpc()

func new_player_added(player: PlayerPeer) -> FunctionRPC:
	return FunctionRPC.new(self, new_player_added, [player], func():
		new_player_joined.emit(player)
		if multiplayer.is_server():
			players.v[player.id] = player
			players.set_v(players.v)
	)

func host(port: int, player_name: String) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, 32)
	if err != OK:
		print("Cannot Host: {err}".format({"err": err}))
		return false
	peer.host.compress(ENetConnection.COMPRESS_NONE)
	multiplayer.multiplayer_peer = peer
	var player = PlayerPeer.new().init(multiplayer.get_unique_id(), player_name)
	me = player
	new_player_added(me).run()
	return true

func join(address: String, port: int, player_name: String) -> bool:
	self.set_meta("player_name", player_name)
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, port)
	if err != OK:
		print("Cannot Join: {err}".format({"err": err}))
		return false
	peer.host.compress(ENetConnection.COMPRESS_NONE)
	multiplayer.multiplayer_peer = peer
	return true
