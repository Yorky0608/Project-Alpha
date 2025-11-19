extends CanvasLayer

var dam_price = 500
var rad_price = 500
var run_price = 500
var health_price = 500
var dash_price = 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AbilitiesControl.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	
	var player = get_node("/root/Main/Level/Entities/Player")
	
	if ui.current_score < dam_price:
		$StatsControl/Container/Damage/Button.disabled = true
	else:
		$StatsControl/Container/Damage/Button.disabled = false
	
	if ui.current_score < rad_price:
		$StatsControl/Container/Attack/Button.disabled = true
	else:
		$StatsControl/Container/Attack/Button.disabled = false
	
	if ui.current_score < run_price:
		$StatsControl/Container/Speed/Button.disabled = true
	else:
		$StatsControl/Container/Speed/Button.disabled = false
	
	if ui.current_score < health_price:
		$StatsControl/Container/Health/Button.disabled = true
	else:
		$StatsControl/Container/Health/Button.disabled = false
	
	if ui.current_score < dash_price:
		$AbilitiesControl/Container/Dash/Button.disabled = true
	else:
		$AbilitiesControl/Container/Dash/Button.disabled = false
	
	ui.update_score(ui.current_score)


func _on_close_pressed() -> void:
	$AnimationPlayer.play("invisible")
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.ui_vis()
	var menu = get_parent().find_child("AnimationPlayer")
	menu.play("visible")

func _on_damage_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.damage += 1
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= dam_price


func _on_attack_radius_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.attack_radius += 5
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").shape.size.x = player.attack_radius
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").position.x += .5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= rad_price


func _on_run_speed_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.run_speed += 5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= run_price


func _on_health_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.health += 5
	player.max_health += 5
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= health_price
	ui.find_child("HealthBar").max_value = player.max_health
	ui.update_health_bar(player.health)

func _on_dash_time_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if not player.dash_ability:
		player.dash_ability = true
		var ui = get_node("/root/Main/Level/Entities/Player/UI")
		ui.current_score -= dash_price
		$Control/DashTime.text = "Reduce Cooldown : 0.1 SEC"
	else:
		var ability = get_node("/root/Main/Level/Entities/Player/AbilityCoolDown")
		ability.waittime -= 0.1
	
func _on_stats_button_pressed() -> void:
	$StatsControl.show()
	$AbilitiesControl.hide()
	
func _on_abilities_button_pressed() -> void:
	$AbilitiesControl.show()
	$StatsControl.hide()
