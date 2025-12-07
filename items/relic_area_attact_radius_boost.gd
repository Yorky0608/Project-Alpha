extends Area2D

var attack_radius_boost = .30
@onready var player = get_node("/root/Main/Level/Entities/Player")
@onready var ui = player.get_tree().get_first_node_in_group("ui")



func _on_area_entered(area: Area2D) -> void:
	player.attack_radius *= attack_radius_boost
	queue_free()
