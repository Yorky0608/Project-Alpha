extends Node

var game_scene = "res://main.tscn"
var title_screen = "res://ui/title.tscn"

func restart():
	get_tree().change_scene_to_file(title_screen)
	
func next_level():
	get_tree().change_scene_to_file(game_scene)
