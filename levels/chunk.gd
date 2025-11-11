extends Node2D
class_name Chunk
@onready var left_edge = $LeftEdge
@onready var right_edge = $RightEdge

func get_left_y() -> float:
	if left_edge:
		return left_edge.global_position.y
	else:
		print("%s missing LeftEdge marker" % name)
		return global_position.y  # fallback

func get_right_y() -> float:
	if right_edge:
		return right_edge.global_position.y
	else:
		print("%s missing RightEdge marker" % name)
		return global_position.y  # fallback
