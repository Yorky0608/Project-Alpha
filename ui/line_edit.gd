extends LineEdit

@export var action_name : String = ""   # e.g. "dash", "jump", "move_left"
var capturing := false
var just_focused := false


func _ready():
	set_process_unhandled_key_input(true)
	# Show the current key when menu opens
	text = get_current_key_name()
	_update_width()

func _update_width():
	if capturing:
		return
	# Base width padding (so text isn’t touching the border)
	var padding := 20

	# Measure the text's pixel width using the current font
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_width := font.get_string_size(text, font_size).x

	# Set the control’s width
	custom_minimum_size.x = text_width + padding


func _on_focus_entered():
	capturing = true
	editable  = false
	just_focused = true
	text = "Press any key..."
	_update_capture_width()

func _update_capture_width():
	var padding := 20
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_width := font.get_string_size("Press any key...", font_size).x

	custom_minimum_size.x = text_width + padding


func _unhandled_key_input(event):
	if not capturing:
		return

	accept_event()
	
	if event is InputEventKey and event.pressed:
		capturing = false
		editable = true
		# Clear old event
		InputMap.action_erase_events(action_name)

		# Add new keybind
		var new_event := InputEventKey.new()
		new_event.physical_keycode = event.physical_keycode
		InputMap.action_add_event(action_name, new_event)

		# Update UI text
		text = OS.get_keycode_string(event.physical_keycode)

		# Save automatically
		Global.save_keybinds()
		_update_width()
		release_focus()

func _gui_input(event):
	if not capturing:
		return

	# Mouse button binding
	if just_focused:
		if event is InputEventMouseButton and event.pressed:
			just_focused = false
			accept_event()
			return
		just_focused = false
		
	if event is InputEventMouseButton and event.pressed:
		capturing = false
		editable = true
		accept_event()

		InputMap.action_erase_events(action_name)

		var ev := InputEventMouseButton.new()
		ev.button_index = event.button_index
		InputMap.action_add_event(action_name, ev)

		text = "Mouse " + str(event.button_index)
		Global.save_keybinds()
		_update_width()
		release_focus()

func get_current_key_name():
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return ""

	var ev = events[0]

	if ev is InputEventKey:
		return OS.get_keycode_string(ev.physical_keycode)

	if ev is InputEventMouseButton:
		return "Mouse " + str(ev.button_index)

	return ""


func _on_focus_exited() -> void:
	capturing = false
	editable = true
