extends Area2D

var health = 10
@onready var player = get_node("/root/Main/Level/Entities/Player")
@onready var ui = player.get_tree().get_first_node_in_group("ui")



func _on_area_entered(area: Area2D) -> void:
	if player.max_health > player.health:
		if (player.health + health) < player.max_health:
			player.health += health
			ui.update_health_bar(player.health)
		else:
			player.health = player.max_health
		queue_free()
