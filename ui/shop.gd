extends CanvasLayer

var dam_price = 500
var rad_price = 500
var run_price = 500
var health_price = 500
var dash_price = 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AbilitiesControl.visible = false
	
	if Character.character == Character.agile_class:
		show_agile_ability()
	elif Character.character == Character.attack_class:
		show_attack_ability()
	elif Character.character == Character.defense_class:
		show_defense_ability()

func show_agile_ability() -> void:
	$AbilitiesControl/AgileAbilityContainer.visible = true
	$AbilitiesControl/AttackAbilityContainer.visible = false
	$AbilitiesControl/DefenseAbilityContainer.visible = false

func show_attack_ability() -> void:
	$AbilitiesControl/AttackAbilityContainer.visible = true
	$AbilitiesControl/AgileAbilityContainer.visible = false
	$AbilitiesControl/DefenseAbilityContainer.visible = false

func show_defense_ability() -> void:
	$AbilitiesControl/DefenseAbilityContainer.visible = true
	$AbilitiesControl/AttackAbilityContainer.visible = false
	$AbilitiesControl/AgileAbilityContainer.visible = false
	
func validate_ability():
	var player = get_node("/root/Main/Level/Entities/Player")
	
	if Character.character == Character.agile_class:
		$AbilitiesControl/AgileAbilityContainer/DashSlash/Button.disabled = player.dash_attack_ability
	elif Character.character == Character.attack_class:
		$AbilitiesControl/AttackAbilityContainer/Slash/Button.disabled = player.slash_ability
		$AbilitiesControl/AttackAbilityContainer/SlashWave/Button.disabled = player.slash_wave_ability
	elif Character.character == Character.defense_class:
		$AbilitiesControl/DefenseAbilityContainer/ShieldBash/Button.disabled = player.dash_attack_ability
		
func validate_price(button, price : int) -> void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	button.disabled = price > ui.current_score

func update_score(price)->void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.current_score -= price

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	var player = get_node("/root/Main/Level/Entities/Player")
	
	ui.update_score(ui.current_score)
	
	# Stats Shop
	validate_price($StatsControl/Container/Damage/Button, dam_price)
	validate_price($StatsControl/Container/Attack/Button, rad_price)
	validate_price($StatsControl/Container/Speed/Button, run_price)
	validate_price($StatsControl/Container/Health/Button, health_price)
	
	#Abilities Shop
	validate_price($AbilitiesControl/AttackAbilityContainer/Slash/Button, dam_price)
	validate_price($AbilitiesControl/AttackAbilityContainer/SlashWave/Button, dam_price)
	
	validate_price($AbilitiesControl/AgileAbilityContainer/Dash/Button, dam_price)
	validate_price($AbilitiesControl/AgileAbilityContainer/DashSlash/Button, dam_price)
	
	validate_price($AbilitiesControl/DefenseAbilityContainer/Block/Button, dam_price)
	validate_price($AbilitiesControl/DefenseAbilityContainer/ShieldBash/Button, dam_price)
	
	validate_ability()

func _on_close_pressed() -> void:
	$AnimationPlayer.play("invisible")
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.ui_vis()
	var menu = get_parent().find_child("AnimationPlayer")
	menu.play("visible")

func _on_damage_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.damage += 1
	update_score(dam_price)

func _on_attack_radius_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.attack_radius += 5
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").shape.size.x = player.attack_radius
	player.find_child("AttackPivot").find_child("AttackArea").find_child("CollisionShape2D").position.x += .5
	update_score(rad_price)

func _on_run_speed_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.run_speed += 5
	update_score(run_price)

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
		update_score(dash_price)
		$Control/DashTime.text = "Reduce Cooldown : 0.1 SEC"
	else:
		var ability = get_node("/root/Main/Level/Entities/Player/AbilityCoolDown")
		ability.waittime -= 0.1

func _on_dash_slash_ability_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if not player.dash_attack_ability:
		player.dash_attack_ability = true
	update_score(dam_price)
	
func _on_slash_ability_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if not player.slash_ability:
		player.slash_ability = true
	update_score(dam_price)
	
func _on_slash_wave_ability_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if not player.slash_wave_ability:
		player.slash_wave_ability = true
	update_score(dam_price)
	
func _on_block_ability_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	player.max_block_points += 1;
	update_score(dam_price)

func _on_shield_bash_ability_pressed() -> void:
	var player = get_node("/root/Main/Level/Entities/Player")
	if not player.dash_attack_ability:
		player.dash_attack_ability = true
	update_score(dam_price)
	
func _on_stats_button_pressed() -> void:
	$StatsControl.show()
	$AbilitiesControl.hide()
	
func _on_abilities_button_pressed() -> void:
	$AbilitiesControl.show()
	$StatsControl.hide()
	
func show_abilities_control():
	$AbilitiesControl.show()
