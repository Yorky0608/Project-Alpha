extends Control
var  animation_finished = false

func _input(event):
	if event.is_action_pressed("ui_select") and animation_finished:
		GameState.next_level()


func _ready():
	$Control/Score.text = "High Score - " + str(Global.high_score)
	$Control/SurvivalTimeUpdate.text = "Highest Survived Time - " + format()

func _process(delta: float) -> void:
	if Character.character == null:
		$Control2/Message.text = "Please Select a Character"
		set_process_input(false)
	else:
		$Control2/Message.text = "Press Space to Play"
		set_process_input(true)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_finished = true

func format():
	var minutes = floor(Global.highest_time / 60)
	var seconds = fmod(Global.highest_time, 60)
	return "%02d:%05.2f" % [minutes, seconds]


func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_select_character_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/character_select_screen.tscn")
