extends CanvasLayer
@onready var health_bar = $Control/HealthBar
@onready var score_label = $Control/Score

@onready var ability_bar_1 = $Control4/Ability_1/Ability_Bar_1
@onready var ability_bar_2 = $Control4/Ability_2/Ability_Bar_2

var survival_time: float = 0.0
var timer_running: bool = true
var survived_time = 0

var current_score = 0
var player

func _ready():
	player = get_parent()
	# Initialize display
	update_score(current_score)
	update_health_bar(player.health)

func _process(delta):
	if timer_running:
		survival_time += delta
		$Control2/SurvivalTimeUpdate.text = format()
	
	update_ability_bars()

func update_ability_bars():
	if not player or not player.has_method("get_ability_timers"):
		return

	var timers = player.get_ability_timers()

	# Ability 1
	var t1 = timers.get("ability1", null)
	if t1:
		ability_bar_1.max_value = t1.wait_time
		ability_bar_1.value = t1.wait_time - t1.time_left

	# Ability 2
	var t2 = timers.get("ability2", null)
	if t2 is Timer:
		ability_bar_2.max_value = t2.wait_time
		ability_bar_2.value = t2.wait_time - t2.time_left
	else:
		ability_bar_2.max_value = t2["max"]
		ability_bar_2.value = t2["value"]

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
	health_bar.hide()

func ui_vis():
	$AnimationPlayer.play("visible")
	health_bar.show()
