extends Synchronizer

class_name ChatClass

@onready var players_list: VBoxContainer = %PlayersList
@onready var messanges_list: VBoxContainer = %Messanges
@onready var content_line_edit: LineEdit = %Content

const PLAYER_TAG = preload("res://player_tag.tscn")
const MESSAGE = preload("res://message.tscn")

class Message:
	var from: int = -1
	var content: String = ""

	func init(from: int, content: String) -> Message:
		self.from = from
		self.content = content
		return self

var players_tags: Dictionary[int, Node] = {}

func _ready() -> void:
	add_players(Multiplayer.players.v)
	Multiplayer.players.listen(add_players)

func add_players(players: Dictionary[int, Multiplayer.PlayerPeer]) -> void:
	for player_id in players:
		var player: MultiplayerClass.PlayerPeer = players[player_id]
		if player.id in players_tags:
			continue
		var player_tag = PLAYER_TAG.instantiate()
		player_tag.find_child("ID").text = str(player.id)
		player_tag.find_child("Name").text = player.name
		players_tags[player.id] = player_tag
		players_list.add_child(player_tag)

func add_message(who: Multiplayer.PlayerPeer, content: String) -> FunctionRPC:
	return FunctionRPC.new(self, add_message, [who, content], func():
		var message = MESSAGE.instantiate()
		message.find_child("ID").text = who.name + " - " + str(who.id)
		message.find_child("Message").text = str(content)
		messanges_list.add_child(message)
	)

func _on_send_button_up() -> void:
	add_message(Multiplayer.me, content_line_edit.text).rpc()
	content_line_edit.text = ""
