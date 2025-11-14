extends Node2D

class_name LevelManager

## Chunk configuration - EDIT THESE TO MATCH YOUR GAME ##
const CHUNK_SCENES := [
	preload("res://levels/spawn_chunk.tscn"),
	preload("res://levels/chunk1.tscn"),
	preload("res://levels/chunk2.tscn"),
	preload("res://levels/chunk3.tscn"),
	preload("res://levels/chunk4.tscn"),
	# Add more chunks here as you create them
]

const BOSS_SCENES := [
	preload('res://levels/bosschunk1.tscn'),
]

var boss_spawn_rate = 0.01  # 1% chance

const CHUNK_WIDTH = 1152  # Must match your chunk scene width
const GROUND_Y = 500      # Y-position where chunks will spawn
const LOAD_DISTANCE = 2   # Number of chunks to load ahead/behind player
const START_CHUNK_X = 0   # Initial chunk position

## Internal variables ##
var loaded_chunks = {}    # Dictionary tracking spawned chunks {x_index: chunk_instance}
var player_ref: CharacterBody2D
var spawn_marker_position: Vector2
var player_health = 20

var skeleton_scene = preload("res://enemies/skelly.tscn")
var spawn_interval = 5.0
var spawn_timer = 0.0
var skeletons_spawned = 1
var spawn_margin = 100  # Pixels outside viewport

@onready var player = $Entities/Player  # Adjust path to player
@onready var camera = $Entities/Player/Camera2D  # Assuming camera follows player

func _ready():
	# Load spawn chunk first
	_spawn_chunk(0, true)
	
	# Position player at spawn marker
	player_ref = get_node_or_null("Entities/Player")
	if spawn_marker_position:
		player_ref.position = spawn_marker_position
	
	# Load initial chunks
	_on_player_chunk_changed(START_CHUNK_X)

	spawn_timer = spawn_interval

func _process(delta):
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_skeletons()
		spawn_timer = spawn_interval

var last_chunk_right_y: float = GROUND_Y  # Start height baseline

func _spawn_chunk(x_index: int, is_spawn_chunk: bool = false):
	var chunk_scene

	if is_spawn_chunk:
		# Always load the spawn chunk
		chunk_scene = CHUNK_SCENES[0]
	else:
		# Decide if this chunk should be a boss chunk
		if randf() < boss_spawn_rate:
			# Pick random boss chunk
			chunk_scene = BOSS_SCENES[randi() % BOSS_SCENES.size()]
			print("Spawning boss chunk at index:", x_index)
		else:
			# Pick normal gameplay chunk
			chunk_scene = CHUNK_SCENES[randi() % CHUNK_SCENES.size()]
	
	var new_chunk: Chunk = chunk_scene.instantiate()
	add_child(new_chunk)
	loaded_chunks[x_index] = new_chunk

	var offset_y := 0.0

	# Adjust Y based on previous chunk
	if not is_spawn_chunk and loaded_chunks.has(x_index - 1):
		var prev_chunk = loaded_chunks[x_index - 1]
		offset_y = prev_chunk.get_right_y() - new_chunk.get_left_y()
		last_chunk_right_y = prev_chunk.get_right_y()
	else:
		last_chunk_right_y = GROUND_Y

	new_chunk.position = Vector2(x_index * CHUNK_WIDTH, offset_y)

	# Handle spawn marker for starting chunk
	if is_spawn_chunk:
		var marker = new_chunk.get_node_or_null("SpawnMarker")
		if marker:
			spawn_marker_position = marker.global_position
		else:
			spawn_marker_position = Vector2(x_index * CHUNK_WIDTH + 100, 230)

func _on_player_chunk_changed(current_chunk_x: int):
	# Unload chunks outside loading distance
	_unload_distant_chunks(current_chunk_x)
	
	# Load new chunks around player
	_load_nearby_chunks(current_chunk_x)

func _load_nearby_chunks(center_x: int):
	# Load chunks in range [center-LOAD_DISTANCE, center+LOAD_DISTANCE]
	for x in range(center_x - LOAD_DISTANCE, center_x + LOAD_DISTANCE + 1):
		if not loaded_chunks.has(x):
			_spawn_chunk(x)

func _unload_distant_chunks(center_x: int):
	var chunks_to_unload := []
	
	# Find chunks outside loading distance
	for x in loaded_chunks:
		if abs(x - center_x) > LOAD_DISTANCE:
			chunks_to_unload.append(x)
	
	# Remove those chunks
	for x in chunks_to_unload:
		loaded_chunks[x].queue_free()
		loaded_chunks.erase(x)

func _on_player_died():
	await get_tree().create_timer(1.0).timeout
	
	GameState.restart()

func spawn_skeletons():
	# Count currently alive skeletons
	var alive_skeletons = 0
	for child in get_children():
		if child.is_in_group("enemies"):  # Make sure to add skeletons to this group when instantiating
			alive_skeletons += 1
	
	# Set a maximum limit (e.g., 20)
	var max_skeletons = 20
	if alive_skeletons >= max_skeletons:
		return

	skeletons_spawned += skeletons_spawned * 0.1
	var skeletons_to_spawn = floor(skeletons_spawned) # Scale difficulty

	for i in skeletons_to_spawn:
		var skeleton = skeleton_scene.instantiate()
		$Entities/Enemies.add_child(skeleton)
		skeleton.global_position = _get_safe_spawn_position()

func _get_safe_spawn_position() -> Vector2:
	var viewport = get_viewport().get_visible_rect()
	var camera_rect = Rect2(
		camera.global_position - viewport.size / 2, 
		viewport.size
	)
	
	# 1. Spawn ABOVE the highest chunk in view
	var highest_chunk_y = _get_highest_chunk_y_in_view(camera_rect)
	var min_spawn_y = highest_chunk_y - 150  # 150px above highest chunk

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
