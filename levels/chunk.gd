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

var chunk_state = Chunkmanager

func load_state():
	chunk_state = Chunkmanager.get_state(get_chunk_id())
	_load_boss()
	_load_items()

func save_state():
	if chunk_state == null:
		return

	_save_boss()
	_save_items()

# You must implement this. For example, name or position-based:
func get_chunk_id() -> String:
	return name  # or str(global_position.x)
	

# ====================================
#   BOSSES
# ====================================

func _load_boss():
	if $Entities/Bosses == null:
		return
	if chunk_state.boss_dead:
		return  # never respawn

	if not chunk_state.boss_spawned:
		return  # no boss saved

	var scene := load(chunk_state.boss_scene)
	var boss = scene.instantiate()
	$Entities/Bosses.add_child(boss)
	boss.global_position = chunk_state.boss_position

	if boss.has_method("set_hp"):
		boss.set_hp(chunk_state.boss_hp)

func _save_boss():
	if $Entities/Bosses == null:
		return
	var boss_nodes = $Entities/Bosses.get_children()
	if boss_nodes.size() == 0:
		return

	var boss = boss_nodes[0]

	var dead := false
	var hp := 100.0

	if boss.has_method("is_dead"):
		dead = boss.is_dead()

	if boss.has_method("get_hp"):
		hp = boss.get_hp()

	chunk_state.save_boss_state(
		boss.scene_file_path,
		boss.global_position,
		hp,
		dead
	)
	
	# ====================================
#   ITEMS
# ====================================

func _load_items():
	for item_data in chunk_state.items:
		if item_data["picked_up"]:
			continue

		var scene := load(item_data["scene"])
		var item = scene.instantiate()
		$Entities/Items.add_child(item)
		item.global_position = item_data["position"]

func _save_items():
	chunk_state.items.clear()

	for item in $Entities/Items.get_children():
		if not item.is_inside_tree():
			continue

		var picked := false
		if item.has_method("is_picked_up"):
			picked = item.is_picked_up()

		chunk_state.add_item(
			item.scene_file_path,
			item.global_position,
			picked
		)
