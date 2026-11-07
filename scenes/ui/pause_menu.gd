extends CanvasLayer
## Pause menu. Esc pauses / resumes. The UI is built in code, so the only setup is
## adding this script to a CanvasLayer node in the level (see the notes in the chat).

## true  = "Quit" goes back to the main menu scene below
## false = "Quit" closes the game
@export var quit_to_main_menu := true
@export_file("*.tscn") var main_menu_scene := "res://scenes/levels/main_menu.tscn"

var _resume_button: Button

func _ready() -> void:
	# This node (and its buttons) must keep working while the rest of the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	# If Esc is needed to cancel something else first (placing a tower, terraform
	# mode, the radial menu), let that happen and don't pause yet.
	if not get_tree().paused:
		var builder := get_tree().get_first_node_in_group("build_controller")
		if builder and builder.has_method("is_busy") and builder.is_busy():
			return
	_set_paused(not get_tree().paused)
	get_viewport().set_input_as_handled()

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	visible = value
	if value:
		_resume_button.grab_focus() # keyboard / gamepad navigation

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	if quit_to_main_menu and ResourceLoader.exists(main_menu_scene):
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		get_tree().quit()

func _build_ui() -> void:
	# Dark overlay that also blocks clicks from reaching anything underneath.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	box.add_child(title)

	_resume_button = _make_button(box, "Resume", _on_resume_pressed)
	_make_button(box, "Restart", _on_restart_pressed)
	_make_button(box, "Quit to Main Menu" if quit_to_main_menu else "Quit", _on_quit_pressed)

func _make_button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 64)
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
