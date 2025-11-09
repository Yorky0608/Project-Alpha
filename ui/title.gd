extends Control
var  animation_finished = false

func _input(event):
	if event.is_action_pressed("ui_select") and animation_finished:
		GameState.next_level()


func _ready():
	$Control/Score.text = "High Score - " + str(Global.high_score)
	$Control/SurvivalTimeUpdate.text = "Highest Survived Time - " + format()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_finished = true

func format():
	var minutes = floor(Global.highest_time / 60)
	var seconds = fmod(Global.highest_time, 60)
	return "%02d:%05.2f" % [minutes, seconds]


func _on_exit_pressed() -> void:
	get_tree().quit()
