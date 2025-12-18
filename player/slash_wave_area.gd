extends Area2D

@onready var anim = $AnimationPlayer
var slashing_wave_damage = 20

var direction = 1
var speed = 300

var hit_targets = {}

func start():
	await get_tree().process_frame
	scale.x = direction
	anim.play("slashing_wave")
	await anim.animation_finished
	queue_free()
	
func _process(delta):
	position.x += direction * speed * delta

func _try_damage(area: Area2D) -> void:
	if not area.is_in_group("enemy_hitbox"):
		return

	var node = area
	while node:
		if node.has_method("apply_damage"):
			if hit_targets.has(node):
				return  # already damaged

			hit_targets[node] = true
			node.apply_damage(slashing_wave_damage)
			return

		node = node.get_parent()


func _on_area_entered(area: Area2D) -> void:
	_try_damage(area)
