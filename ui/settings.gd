extends CanvasLayer

func save_keybinds():
	var file = FileAccess.open("user://keybinds.cfg", FileAccess.WRITE)
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			file.store_line("%s:%d" % [action, events[0].physical_keycode])
			
func _ready():
	if Character.character == Character.agile_class:
		$MenuBar/VBoxContainer/HBoxContainer5/Label.text = "Dash"
		$MenuBar/VBoxContainer/HBoxContainer5/LineEdit_Ability1.placeholder_text = "Shift"
		$MenuBar/VBoxContainer/HBoxContainer6/Label.text = "Dash Attack"
		$MenuBar/VBoxContainer/HBoxContainer6/LineEdit_Ability2.placeholder_text = "R"
	elif Character.character == Character.attack_class:
		$MenuBar/VBoxContainer/HBoxContainer5/Label.text = "Slash"
		$MenuBar/VBoxContainer/HBoxContainer5/LineEdit_Ability1.placeholder_text = "E"
		$MenuBar/VBoxContainer/HBoxContainer6/Label.text = "Slash Wave"
		$MenuBar/VBoxContainer/HBoxContainer6/LineEdit_Ability2.placeholder_text = "R"
	elif Character.character == Character.defense_class:
		$MenuBar/VBoxContainer/HBoxContainer5/Label.text = "Sheild Bash"
		$MenuBar/VBoxContainer/HBoxContainer5/LineEdit_Ability1.placeholder_text = "Shift"
		$MenuBar/VBoxContainer/HBoxContainer6/Label.text = "Block"
		$MenuBar/VBoxContainer/HBoxContainer6/LineEdit_Ability2.placeholder_text = "F"


func _on_button_pressed() -> void:
	$AnimationPlayer.play("invisible")
	var ui = get_node("/root/Main/Level/Entities/Player/UI")
	ui.ui_vis()
	var menu = get_parent().find_child("AnimationPlayer")
	menu.play("visible")
