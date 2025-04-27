extends Node

@onready var name_line_edit: LineEdit = %Name
@onready var address_line_edit: LineEdit = %Address
@onready var port_line_edit: LineEdit = %Port

func _on_host_button_up() -> void:
	if Multiplayer.host(int(port_line_edit.text), name_line_edit.text):
		get_tree().change_scene_to_file("res://chat.tscn")

func _on_join_button_up() -> void:
	if Multiplayer.join(address_line_edit.text, int(port_line_edit.text), name_line_edit.text):
		get_tree().change_scene_to_file("res://chat.tscn")
