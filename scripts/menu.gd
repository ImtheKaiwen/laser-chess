extends Node2D

@onready var play_button = $Menu/MenuButtons/PlayButton
@onready var info_button = $Menu/MenuButtons/InfoButton
@onready var exit_button = $Menu/ExitButton

func _ready() -> void:
	pass





func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_info_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Info.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
