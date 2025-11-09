extends CanvasLayer
@onready var health_bar = $Control/HealthBar
@onready var score_label = $Control/Score

var survival_time: float = 0.0
var timer_running: bool = true
var survived_time = 0

var current_score = 0

func _ready():
	var player = get_parent()
	# Initialize display
	update_score(current_score)
	update_health_bar(player.health)

func _process(delta):
	if timer_running:
		survival_time += delta
		$Control2/SurvivalTimeUpdate.text = format()

func update_score(value):
	current_score = value
	score_label.text = "Score: %s" % current_score

func update_health_bar(value):
	health_bar.value = value

func show_message(text):
	$Control3/Message.text = text
	$Control3/Message.show()
	await get_tree().create_timer(2).timeout
	$Control3/Message.hide()

func format():
	var minutes = floor(survival_time / 60)
	var seconds = fmod(survival_time, 60)
	return "%02d:%05.2f" % [minutes, seconds]

func stop_timer():
	timer_running = false

func ui_invis():
	$AnimationPlayer.play('invisible')

func ui_vis():
	$AnimationPlayer.play("visible")
