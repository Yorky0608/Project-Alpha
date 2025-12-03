extends Node

var title_screen = "res://ui/title.tscn"


func _on_button_agile_pressed() -> void:
	Character.character = preload("res://player/player_agile.tscn")
	get_tree().change_scene_to_file(title_screen)


func _on_button_attack_pressed() -> void:
	Character.character = preload("res://player/player_attack.tscn")
	get_tree().change_scene_to_file(title_screen)


func _on_button_deffense_pressed() -> void:
	Character.character = preload("res://player/player_deffense.tscn")
	get_tree().change_scene_to_file(title_screen)
