extends Node2D

class_name LevelManager

## Chunk configuration - EDIT THESE TO MATCH YOUR GAME ##
const CHUNK_SCENES := [
	preload("res://levels/spawn_chunk.tscn"),
	preload("res://levels/chunk1.tscn"),
	preload("res://levels/chunk2.tscn"),
	preload("res://levels/chunk3.tscn"),
	preload("res://levels/chunk4.tscn"),
	preload("res://levels/chunk_5.tscn"),
	preload("res://levels/chunk_6.tscn"),
	preload("res://levels/chunk_7.tscn"),
	preload("res://levels/chunk_8.tscn"),
	preload("res://levels/chunk_9.tscn"),
	preload("res://levels/chunk_10.tscn"),
	preload("res://levels/chunk_11.tscn"),
	preload("res://levels/chunk_12.tscn"),
	preload("res://levels/chunk_13.tscn"),
	preload("res://levels/chunk_14.tscn"),
	preload("res://levels/chunk_15.tscn"),
	preload("res://levels/chunk_16.tscn"),
	preload("res://levels/chunk_17.tscn"),
	preload("res://levels/chunk_18.tscn"),
	preload("res://levels/chunk_19.tscn"),
	preload("res://levels/chunk_20.tscn"),
	# Add more chunks here as you create them
]

const BOSS_SCENES := [
	preload('res://levels/bosschunk1.tscn'),
	preload('res://levels/boss_chunk2.tscn'),
	preload('res://levels/boss_chunk_3.tscn'),
	preload('res://levels/boss_chunk_4.tscn'),
	preload('res://levels/boss_chunk_5.tscn'),
]

var boss_spawn_rate = 0.01  # 1% chance

const CHUNK_WIDTH = 1152  # Must match your chunk scene width
const GROUND_Y = 500      # Y-position where chunks will spawn
const LOAD_DISTANCE = 2   # Number of chunks to load ahead/behind player
const START_CHUNK_X = 0   # Initial chunk position

# How long to ignore repeated chunk-change events (seconds)
@export var chunk_change_cooldown := 0.12
# Small safety margin to wait after queue_free before trusting deletion is finished (seconds)
@export var unload_grace_time := 0.05

## Internal variables ##
var loaded_chunks = {}    # Dictionary tracking spawned chunks {x_index: chunk_instance}
var loading_indices = {}            # x_index -> true while spawn in progress
var last_chunk_update_time := -999.0
var chunk_update_lock := false

var spawn_marker_position: Vector2
var player_health = 20

const enemies = [
	preload("res://enemies/skelly.tscn"),
	preload("res://enemies/fire_spirit.tscn"),
	#preload("res://enemies/plent.tscn"),
	#preload("res://enemies/orc_berserk.tscn"),
	preload("res://enemies/orc_warrior.tscn"),
	preload("res://enemies/orc_shaman.tscn"),
	preload("res://enemies/jinn.tscn"),
	preload("res://enemies/dragon.tscn"),
	preload("res://enemies/demon.tscn"),
]

const enemy_weights = [
	0.8,  # skelly = 80%
	0.2,   # fire_spirit = 20%
	#0.4,
	#0.4,
	0.4,
	0.1,
	0.01,
	0.01,
	0.01,
]

@export var spawn_interval = 5.0
var spawn_timer = 0.0
var skeletons_spawned = 1
var spawn_margin = 100  # Pixels outside viewport
var current_death_y = 656

@export var max_skeletons = 20

var player_ref 
var player
var camera

func _ready():
	var player_instance = Character.character.instantiate()
	player_instance.name = "Player"
	$Entities.add_child(player_instance)

	
	player_ref = player_instance
	player = player_instance  # Adjust path to player
	camera = player_instance.get_node("Camera2D") # Assuming camera follows player
	
	if not player_ref.is_connected("chunk_changed", Callable(self, "_on_player_chunk_changed")):
		player_ref.connect("chunk_changed", Callable(self, "_on_player_chunk_changed"))

	# spawn initial area deterministically
	_spawn_chunk_safe(0, true)
	
	await get_tree().process_frame
	
	if spawn_marker_position:
		player_ref.position = spawn_marker_position
		
	update_player_chunk_based_on_player_position()

	spawn_timer = spawn_interval

func _process(delta):
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_skeletons()
		spawn_timer = spawn_interval
	
	_check_death_barrier()

func _check_death_barrier():
	if not player_ref:
		return
	
	# Kill player
	if player_ref.global_position.y > current_death_y:
		player_ref.change_state(player_ref.DEAD, player_ref.death_texture, "Death")
		_on_player_died()
	
	# Kill enemies
	for enemy in $Entities/Enemies.get_children():
		if enemy.global_position.y > current_death_y:
			enemy.queue_free()

var last_chunk_right_y: float = GROUND_Y  # Start height baseline

func _spawn_chunk_safe(x_index: int, is_spawn_chunk: bool = false) -> void:
	# guard: already present
	if loaded_chunks.has(x_index):
		# Already have a live chunk at index
		return

	# guard: already starting to load
	if loading_indices.has(x_index):
		return

	# mark as loading to prevent concurrent spawns at same index
	loading_indices[x_index] = true

	# choose chunk scene
	var chunk_scene : PackedScene
	if is_spawn_chunk:
		chunk_scene = CHUNK_SCENES[0]
	else:
		if randf() < boss_spawn_rate and BOSS_SCENES.size() > 0:
			chunk_scene = BOSS_SCENES[randi() % BOSS_SCENES.size()]
		else:
			# random chunk (avoid first spawn_chunk index)
			chunk_scene = CHUNK_SCENES[randi() % CHUNK_SCENES.size()]

	# instantiate chunk (synchronously)
	var new_chunk = chunk_scene.instantiate()
	# Reserve the spot in dictionary with a placeholder (so other callers see it exists)
	loaded_chunks[x_index] = new_chunk

	# Add child to scene immediately so its signals/ready run.
	$Chunks.add_child(new_chunk)
	
	await get_tree().process_frame

	# compute offset_y deterministically using the last valid neighbor to the left
	var offset_y := 0.0
	if loaded_chunks.has(x_index - 1):
		var prev_chunk = loaded_chunks[x_index - 1]
		if is_instance_valid(prev_chunk) and !prev_chunk.is_queued_for_deletion():
			# Use neighbor to align nicely
			offset_y = prev_chunk.get_right_y() - new_chunk.get_left_y()
		else:
			offset_y = 0.0
	else:
		offset_y = 0.0

	new_chunk.position = Vector2(x_index * CHUNK_WIDTH, offset_y)

	# register spawn marker if present (only for spawn chunk)
	if is_spawn_chunk:
		var marker = new_chunk.get_node_or_null("SpawnMarker")
		if marker:
			spawn_marker_position = marker.global_position
		else:
			spawn_marker_position = Vector2(x_index * CHUNK_WIDTH + 100, 230)

	# Update death line safely
	var chunk_death_y = new_chunk.get_death_y() if new_chunk.has_method("get_death_y") else 0
	if chunk_death_y > current_death_y:
		current_death_y = chunk_death_y

	# loading finished
	loading_indices.erase(x_index)
	
	return

func _on_player_chunk_changed(current_chunk_x: int):
	# Unload chunks outside loading distance
	await _unload_distant_chunks(current_chunk_x)
	
	# Load new chunks around player
	await _load_nearby_chunks(current_chunk_x)
	
func update_player_chunk_based_on_player_position():
	var px = int(floor(player.global_position.x / CHUNK_WIDTH))
	_on_player_chunk_changed(px)

func _load_nearby_chunks(center_x: int) -> void:
	for x in range(center_x - LOAD_DISTANCE, center_x + LOAD_DISTANCE + 1):
		if not _is_chunk_present_or_loading(x):
			await _spawn_chunk_safe(x)

func _unload_distant_chunks(center_x: int) -> void:
	var to_unload := []
	for x in loaded_chunks.keys():
		if abs(x - center_x) > LOAD_DISTANCE:
			to_unload.append(x)

	# Mark for safe unloading: queue_free but keep entry until actually freed
	for x in to_unload:
		var ch = loaded_chunks.get(x, null)
		if ch == null:
			continue
		# If already queued, skip
		if ch.is_queued_for_deletion():
			continue
		# Defer free (so physics frames finish). We still keep the dict entry until freed.
		ch.queue_free()

	# Purge any entries whose nodes have been removed already (safely)
	_cleanup_removed_chunks()

func _cleanup_removed_chunks() -> void:
	# Remove indices from dictionary that no longer have a valid node.
	var to_erase := []
	for x in loaded_chunks.keys():
		var ch = loaded_chunks[x]
		if !is_instance_valid(ch):
			to_erase.append(x)
	for x in to_erase:
		loaded_chunks.erase(x)

func _is_chunk_present_or_loading(x_index: int) -> bool:
	if loaded_chunks.has(x_index):
		var ch = loaded_chunks[x_index]

		# invalid OR queued → erase and allow spawning a fresh chunk
		if !is_instance_valid(ch) or ch.is_queued_for_deletion():
			loaded_chunks.erase(x_index)
			return false

		return true

	# still loading
	if loading_indices.has(x_index):
		return true

	return false

func _on_player_died():
	await get_tree().create_timer(1.0).timeout
	
	GameState.restart()

func spawn_skeletons():
	var alive_skeletons = 0
	# Count currently alive skeletons
	for enemy in $Entities/Enemies.get_children():
		if enemy.is_in_group("enemies"):
			alive_skeletons += 1
	
	if alive_skeletons >= max_skeletons:
		return

	skeletons_spawned += skeletons_spawned * 0.1
	var skeletons_to_spawn = floor(skeletons_spawned) # Scale difficulty

	for i in skeletons_to_spawn:
		var enemy_scene = _choose_weighted_enemy()
		var enemy_instance = enemy_scene.instantiate()

		$Entities/Enemies.add_child(enemy_instance)
		enemy_instance.global_position = _get_safe_spawn_position()

func _choose_weighted_enemy():
	var total_weight = 0.0
	for w in enemy_weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var total = 0.0

	for index in range(enemy_weights.size()):
		total += enemy_weights[index]
		if roll <= total:
			return enemies[index]

	# Fallback (should never happen)
	return enemies[0]

func _get_safe_spawn_position() -> Vector2:
	var viewport = get_viewport().get_visible_rect()
	var camera_rect = Rect2(
		camera.global_position - viewport.size / 2, 
		viewport.size
	)
	
	# 1. Spawn ABOVE the highest chunk in view
	var highest_chunk_y = _get_highest_chunk_y_in_view(camera_rect)
	var min_spawn_y = highest_chunk_y - 50  # 150px above highest chunk

	# 2. Spawn just outside view (left/right)
	var spawn_x
	if randf() > 0.5:  # 50% left, 50% right
		spawn_x = camera_rect.position.x - spawn_margin
	else:
		spawn_x = camera_rect.end.x + spawn_margin
	
	# Add slight Y variation
	var spawn_y = min_spawn_y - randf_range(0, 50)
	return Vector2(spawn_x, spawn_y)

func _get_highest_chunk_y_in_view(camera_rect: Rect2) -> float:
	return camera_rect.position.y - 200  # Fallback
