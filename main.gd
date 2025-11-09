extends Node

func _ready():
	var path = "res://levels/level.tscn"
	var level = load(path).instantiate()
	add_child(level)
	
	
