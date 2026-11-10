extends CanvasLayer
## Shown when the last wave has spawned and every enemy is gone.
## The UI is built in code. Add this script to a CanvasLayer node in the level.

## Seconds to wait after the last enemy goes before the screen appears.
@export var show_delay := 1.0

## Scene to load for "Next Level". Leave empty while there is only one level and the
## button stays hidden. Once we have a second level, drag its .tscn in here.
@export_file("*.tscn") var next_level_scene := ""

@export_file("*.tscn") var main_menu_scene := "res://scenes/levels/main_menu.tscn"

var _shown := false
var _stats: Label
var _next_button: Button
var _restart_button: Button

var _title: Label
var _message: Label

func _ready() -> void:
	add_to_group("end_screen") # tells the pause menu to stay out of the way
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	_build_ui()
	hide()

## Call this when the level is won. stats_text is an optional extra line,
## for example "Lives remaining: 12".
func show_victory(stats_text: String = "") -> void:
	if _shown:
		return
	_shown = true

	# Short pause so the last kill can be seen. This Timer stops if the game is
	# paused, so the screen can't pop up over the pause menu.
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(show_delay, 0.001)
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

	_stats.text = stats_text
	_stats.visible = stats_text != ""
	_next_button.visible = _has_next_level()
	show()
	get_tree().paused = true
	(_next_button if _next_button.visible else _restart_button).grab_focus()

func show_defeat(stats_text: String = "") -> void:
	if _shown:
		return
	_shown = true
	await get_tree().create_timer(2.0, false).timeout
	
	_title.text = "Defeat"
	_title.add_theme_color_override("font_color", Color(0.9, 0.25, 0.25))
	_message.text = "The slimes broke through the university!"
	_stats.text = stats_text
	_stats.visible = stats_text != ""
	_next_button.hide()
	_restart_button.text = "Try Again"
	show()
	_restart_button.grab_focus()
	
func _has_next_level() -> bool:
	return next_level_scene != "" and ResourceLoader.exists(next_level_scene)

func _on_next_pressed() -> void:
	get_tree().paused = false
	$/root/Level/FadeCanvas/FadeTransition.show()
	$/root/Level/FadeCanvas/FadeTransition/fade_timer.start()
	$/root/Level/FadeCanvas/FadeTransition/AnimationPlayer.play("fade_in")
	await get_tree().create_timer(1.0).timeout	
	get_tree().change_scene_to_file(next_level_scene)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	$/root/Level/FadeCanvas/FadeTransition.show()
	$/root/Level/FadeCanvas/FadeTransition/fade_timer.start()
	$/root/Level/FadeCanvas/FadeTransition/AnimationPlayer.play("fade_in")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if ResourceLoader.exists(main_menu_scene):
		$/root/Level/FadeCanvas/FadeTransition.show()
		$/root/Level/FadeCanvas/FadeTransition/fade_timer.start()
		$/root/Level/FadeCanvas/FadeTransition/AnimationPlayer.play("fade_in")
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		get_tree().quit()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.35, 0.35, 0.35, 0.6)
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
	_title = title
	title.text = "Victory!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 14)
	box.add_child(title)

	var message := Label.new()
	_message = message
	message.text = "Congratulations! You defended the base."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 36)
	message.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	message.add_theme_color_override("font_outline_color", Color.BLACK)
	message.add_theme_constant_override("outline_size", 8)
	box.add_child(message)

	_stats = Label.new()
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_font_size_override("font_size", 28)
	_stats.add_theme_color_override("font_outline_color", Color.BLACK)
	_stats.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	_stats.add_theme_constant_override("outline_size", 8)
	box.add_child(_stats)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	box.add_child(spacer)

	_next_button = _make_button(box, "Next Level", _on_next_pressed)
	_restart_button = _make_button(box, "Restart", _on_restart_pressed)
	_make_button(box, "Main Menu", _on_main_menu_pressed)

func _make_button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 64)
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_font_override("font", preload("res://scenes/ui/harrington_fixed.tres"))
	b.pressed.connect(_on_any_button_pressed)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _on_any_button_pressed() -> void:
	Sound.muted = false
	Sound.play("Button")
