extends Resource
class_name ChunkState

# ----------------------------
#  PERSISTENT CHUNK DATA
# ----------------------------

@export var chunk_id: String = ""

# Boss data
@export var boss_spawned: bool = false
@export var boss_dead: bool = false
@export var boss_scene: String = ""     # PackedScene path (string)
@export var boss_position: Vector2      # Last known position
@export var boss_hp: float = 0.0        # Remaining HP

# Items in this chunk
# Each entry: { "scene": String, "position": Vector2, "picked_up": bool }
@export var items: Array = []

# -------------------------------------
#  BOSS HELPERS
# -------------------------------------

func save_boss_state(scene_path: String, pos: Vector2, hp: float, dead: bool):
	boss_spawned = true
	boss_scene = scene_path
	boss_position = pos
	boss_hp = hp
	boss_dead = dead

func clear_boss_state():
	boss_spawned = false
	boss_dead = false
	boss_scene = ""
	boss_position = Vector2.ZERO
	boss_hp = 0

# -------------------------------------
#  ITEM HELPERS
# -------------------------------------

func add_item(scene_path: String, pos: Vector2, picked_up := false):
	items.append({
		"scene": scene_path,
		"position": pos,
		"picked_up": picked_up
	})

func update_item(index: int, picked_up: bool):
	if index >= 0 and index < items.size():
		items[index]["picked_up"] = picked_up
