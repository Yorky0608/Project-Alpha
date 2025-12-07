extends Node2D
class_name Chunk
@onready var left_edge = $LeftEdge
@onready var right_edge = $RightEdge
@onready var death_marker = $DeathMarker

func get_left_y() -> float:
	if left_edge:
		return left_edge.global_position.y
	else:
		return global_position.y  # fallback

func get_right_y() -> float:
	if right_edge:
		return right_edge.global_position.y
	else:
		return global_position.y  # fallback

func get_death_y() -> float:
	if death_marker and is_instance_valid(death_marker):
		return death_marker.global_position.y
	return -9999999.0  # fallback extreme value (very low)
