extends Area2D

var cooldown = .30
@onready var player = get_node("/root/Main/Level/Entities/Player")
@onready var ui = player.get_tree().get_first_node_in_group("ui")



func _on_area_entered(area: Area2D) -> void:
	if Character.character == Character.agile_class:
		player.get_node("DashCoolDown").wait_time /= cooldown 
	elif Character.character == Character.attack_class:
		player.get_node("SlashCoolDown").wait_time /= cooldown 
	elif Character.character == Character.defense_class:
		player.get_node("DashAttackCoolDown").wait_time /= cooldown 
	queue_free()
