extends Node

var title_screen = "res://ui/title.tscn"

func _on_button_agile_pressed() -> void:
	Character.character = Character.agile_class
	get_tree().change_scene_to_file(title_screen)

func _on_button_attack_pressed() -> void:
	Character.character = Character.attack_class
	get_tree().change_scene_to_file(title_screen)

func _on_button_deffense_pressed() -> void:
	Character.character = Character.defense_class
	get_tree().change_scene_to_file(title_screen)
