extends Area2D

@onready var anim = $AnimationPlayer
var slashing_wave_damage = 20

var direction = 1
var speed = 300

func start():
	await get_tree().process_frame
	scale.x = direction
	anim.play("slashing_wave")
	await anim.animation_finished
	queue_free()
	
func _process(delta):
	position.x += direction * speed * delta
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var node = area
		while node:
			if node.has_method("apply_damage"):
				node.apply_damage(slashing_wave_damage)
				break
			node = node.get_parent()
