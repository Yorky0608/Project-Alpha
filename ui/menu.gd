extends CanvasLayer

var paused = false

func _input(event):
	if event.is_action_pressed("menu"):  # ESC key by default
		toggle_pause()

func toggle_pause():
	paused = !paused
	if paused:
		$AnimationPlayer.play('visible')
	else:
		$AnimationPlayer.play('invisible')
		$Shop2/AnimationPlayer.play("invisible")
		var ui = get_node("/root/Main/Level/Entities/Player/UI")
		ui.ui_vis()
	get_tree().paused = paused

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if player.dead:
		set_process_input(false)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	GameState.restart()


func _on_shop_pressed() -> void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.ui_invis()
	$AnimationPlayer.play('invisible')
	$Shop2/AnimationPlayer.play("visible")


func _on_resume_pressed() -> void:
	toggle_pause()
