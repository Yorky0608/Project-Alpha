extends Node
var high_score = 0
var highest_time = 0
var score_file = "user://hs.dat"
var time_file = "user://ht.dat"
var keybind_file = "user://keys.cfg"


func _ready():
	load_score()
	load_keybinds()

func load_score():
	if FileAccess.file_exists(score_file):
		var file = FileAccess.open(score_file,
			FileAccess.READ)
		high_score = file.get_var()
	else:
		high_score = 0
	
	if FileAccess.file_exists(time_file):
		var file = FileAccess.open(time_file,
			FileAccess.READ)
		highest_time = file.get_var()
	else:
		highest_time = 0

func save_score():
	var file = FileAccess.open(score_file, FileAccess.WRITE)
	file.store_var(high_score)

func save_time():
	var file = FileAccess.open(time_file, FileAccess.WRITE)
	file.store_var(highest_time)

func save_keybinds():
	var file = FileAccess.open(keybind_file, FileAccess.WRITE)

	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)

		# Only store the FIRST event per action (most games use 1 key)
		if events.size() > 0 and events[0] is InputEventKey:
			var key_event = events[0]
			var keycode = key_event.physical_keycode
			file.store_line("%s:%d" % [action, keycode])

func load_keybinds():
	if not FileAccess.file_exists(keybind_file):
		return

	var file = FileAccess.open(keybind_file, FileAccess.READ)

	while file.get_position() < file.get_length():
		var line = file.get_line().strip_edges()
		var parts = line.split(":")

		if parts.size() != 2:
			continue

		var action = parts[0]
		var keycode = parts[1].to_int()

		# Replace the keybind
		InputMap.action_erase_events(action)

		var ev = InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)
