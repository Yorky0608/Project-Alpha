extends CharacterBody2D
class_name BossDragon  # optional

@export var tile_size := 64
@export var chunk_width := 1152

@export var wall_check_distance := 32
@export var ground_ahead_horiz := 48
@export var ground_ahead_vert := 72
@export var cliff_check_distance := 96

@export var stepup_max_height := 24
@export var jump_speed := -500
@export var gravity := 750
@export var speed := 100

@export var max_jump_height := 80
@export var max_jump_distance := 120

enum {CHASE, ATTACK, DEAD}
var state = CHASE

var level_bounds_left := 0.0
var level_bounds_right := 0.0

# find player by group (case sensitive)
@onready var player = get_tree().get_first_node_in_group("player")

@export var jump_check_distance = 10
@export var contact_damage = 10
@export var attack_damage = 40
@export var score_value = 1000
@export var health: int = 150

var dead = false
var player_in_attack_area := false

# Animation sets (keep your existing textures)
var walk_texture = preload("res://monsters1/PNG/Dragon/walk.png")
var walk_frames = 4
var walk_speed = 1.2

var death_texture = preload("res://monsters1/PNG/Dragon/death.png")
var death_frames = 6
var death_speed = 1

var attack_texture = preload("res://monsters1/PNG/Dragon/attack.png")
var attack_frames = 4
var attack_speed = 2

var fire_attack_texture = preload("res://monsters1/PNG/Dragon/fire_attack.png")
var fire_attack_frames = 4
var fire_attack_speed = 2

var hurt_texture = preload("res://monsters1/PNG/Dragon/hurt.png")
var hurt_frames = 2
var hurt_speed = 2

@onready var attack_area = $Pivot/AttackArea
@onready var attack_zone = $Pivot/AttackZone
@onready var floor_check = $Pivot/RayCast2D_FloorCheck
@onready var wall_check = $Pivot/RayCast2D_WallCheck
@onready var cliff_check = $Pivot/RayCast2D_Cliff
@onready var attack_timer = $AttackTimer

var drop_chance = 1

var hit = false

const items = [
	preload("res://items/relic_area_health_boost.tscn"),
	preload("res://items/relic_area_attact_boost.tscn"),
	preload("res://items/relic_area_speed_boost.tscn"),
	preload("res://items/relic_area_attact_radius_boost.tscn"),
	preload("res://items/relic_area_ability_1_boost.tscn"),
	preload("res://items/relic_area_ability_2_boost.tscn"),
]

# Patrol bounds (global x)
var chunk_left := 0.0
var chunk_right := 0.0
var chunk_node = null
var owning_chunk_search_attempts := 0
const MAX_OWNING_CHUNK_ATTEMPTS := 6

# Patrol state
var patrol_direction := 1    # 1 -> right, -1 -> left

func _ready():
	await get_tree().process_frame 
	_update_level_bounds()
	change_state(CHASE)

func _physics_process(delta):
	if dead or hit:
		await get_tree().create_timer(2).timeout
		queue_free()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movement logic depending on state
	match state:
		CHASE:
			do_chase(delta)
			if player_in_attack_area and attack_timer.is_stopped():
				change_state(ATTACK)
		ATTACK:
			velocity.x = 0
		DEAD:
			velocity.x = 0

	_check_out_of_bounds()

# =========================
# State Machine Functions
# =========================

func change_state(new_state):
	if state == new_state:
		return

	state = new_state
	match state:
		CHASE:
			start_chase()
		ATTACK:
			start_attack()
		DEAD:
			death()

# -------------------------
# Chase / Patrol (end-to-end)
# -------------------------
func start_chase():
	$Sprite2D.set_hframes(walk_frames)
	$AnimationPlayer.speed_scale = walk_speed
	$Sprite2D.texture = walk_texture
	$AnimationPlayer.play("walk")

func do_chase(delta):
	if not player:
		return
		
	var direction = sign(player.global_position.x - global_position.x)

	# Flip sprite to match direction
	$Sprite2D.flip_h = (patrol_direction < 0)
	$Pivot.scale.x = -1 if $Sprite2D.flip_h else 1
	var facing = $Pivot.scale.x

	# Raycasts updates (keep your existing obstacle logic)
	wall_check.force_raycast_update()
	floor_check.force_raycast_update()
	cliff_check.force_raycast_update()

	var wall_ahead = wall_check.is_colliding()
	var on_floor = is_on_floor()

	# If wall ahead on floor -> try to jump over or change direction
	if wall_ahead and on_floor:
		if can_jump_up_to_platform():
			velocity.y = jump_speed
		elif jump_when_blocked():
			velocity.y = jump_speed
		else:
			_flip_direction()
			velocity.x = 0

	# If no ground in front while on floor -> change direction
	if on_floor:
		# cast floor_check already present; if not colliding, turn
		var ground_ahead = floor_check.is_colliding()
		if not ground_ahead:
			_flip_direction()
			velocity.x = 0

	move_and_slide()

func _flip_direction():
	patrol_direction = -patrol_direction
	$Sprite2D.flip_h = (patrol_direction < 0)
	$Pivot.scale.x = -1 if $Sprite2D.flip_h else 1

func can_step_up() -> bool:
	# cast a short vertical test in front to see if we can step onto the tile (small ledge)
	# you can implement a short shape cast or small extra ray here; for now return false to be safe
	return false

func jump_when_blocked() -> bool:
	# whether this enemy type should try to jump over walls
	return true  # set per enemy type

func can_jump_over_gap() -> bool:
	# force ray updates
	$Pivot/RayCast2D_JumpFarCheck.force_raycast_update()
	$Pivot/RayCast2D_JumpDownCheck.force_raycast_update()

	var far_hit = $Pivot/RayCast2D_JumpFarCheck.get_collider() != null
	var down_hit = $Pivot/RayCast2D_JumpDownCheck.get_collider() != null

	# We want BOTH:
	# 1. Something roughly at jumpable forward distance
	# 2. Floor below that spot
	if far_hit and down_hit:
		return true
	return false

func can_jump_up_to_platform() -> bool:
	$Pivot/RayCast2D_JumpUpCheck.force_raycast_update()

	if $Pivot/RayCast2D_JumpUpCheck.is_colliding():
		return true
	return false

# -------------------------
# Attack
# -------------------------
func start_attack() -> void:
	if state != ATTACK:
		return
	velocity.x = 0

	$Sprite2D.set_hframes(attack_frames)
	$AnimationPlayer.speed_scale = attack_speed
	$Sprite2D.texture = attack_texture
	$AnimationPlayer.play("attack")
	await $AnimationPlayer.animation_finished

	$Pivot/Sprite2D2.visible = true
	$AnimationPlayer2.speed_scale = fire_attack_speed
	$AnimationPlayer2.play("fire_attack")
	await $AnimationPlayer2.animation_finished
	attack_zone.monitoring = false
	$Pivot/Sprite2D2.visible = false
	$AttackTimer.start()
	# Return to chase after attack
	change_state(CHASE)

# -------------------------
# Death
# -------------------------
func death():
	dead = true
	$Death.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$Pivot/HitBox/CollisionShape2D.set_deferred("disabled", true)
	$Pivot/AttackArea/CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.set_hframes(death_frames)
	$AnimationPlayer.speed_scale = death_speed
	$Sprite2D.texture = death_texture
	$AnimationPlayer.play("death")

	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_score(ui.current_score + score_value)

	drop_item()
	await $AnimationPlayer.animation_finished
	queue_free()

func drop_item():
	if randf() > drop_chance:
		return  # no drop

	var item = items[randi() % items.size()]
	item.instantiate()

	# Preferred spawn position (slightly above the corpse)
	item.global_position = global_position + Vector2(0, -10)

	# Find the Items folder inside Level
	var level = get_tree().get_first_node_in_group("level_manager")
	if level:
		var items_parent = level.get_node("Entities/Items")
		items_parent.add_child(item)

# =========================
# Utility
# =========================


func _update_raycasts():
	floor_check.force_raycast_update()
	wall_check.force_raycast_update()

func can_move_forward() -> bool:
	if wall_check.is_colliding():
		return false
	if not floor_check.is_colliding():
		return false
	return true

func apply_damage(amount: int):
	if dead:
		return
	hit = true
		
	if not $Sprite2D.flip_h:
		velocity.x = 100
		velocity.y = -100
	else:
		velocity.x = -100
		velocity.y = -100
	health -= amount
	if health <= 0:
		change_state(DEAD)
	else:
		$Sprite2D.set_hframes(hurt_frames)
		$AnimationPlayer.speed_scale = hurt_speed
		$Sprite2D.texture = hurt_texture
		$AnimationPlayer.play("hurt")
		# Wait for animation to finish
		await $AnimationPlayer.animation_finished
		hit = false

func _update_level_bounds():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		var loaded_chunks = level_manager.loaded_chunks
		if not loaded_chunks.is_empty():
			var min_x = loaded_chunks.keys().min() * level_manager.CHUNK_WIDTH
			var max_x = (loaded_chunks.keys().max() + 1) * level_manager.CHUNK_WIDTH
			level_bounds_left = min_x - level_manager.CHUNK_WIDTH
			level_bounds_right = max_x + level_manager.CHUNK_WIDTH

func _check_out_of_bounds():
	if global_position.x < level_bounds_left or global_position.x > level_bounds_right:
		queue_free()

# =========================
# Signals
# =========================
func _on_attack_zone_area_entered(area):
	if area.is_in_group("player"):
		var p = area.get_parent()
		p.take_damage(self, attack_damage)

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_in_attack_area = false
