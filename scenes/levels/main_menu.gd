extends Node2D

var button_type = null

func _ready() -> void:
	Sound.play_music("Tower defense chill")

func _on_start_pressed() -> void:
	Sound.play("Button")
	button_type = "start"
	$FadeTransition.show()
	$FadeTransition/fade_timer.start()
	$FadeTransition/AnimationPlayer.play("fade_in")

func _on_options_pressed() -> void:
	Sound.play("Button")
	button_type = "options"
	$FadeTransition.show()
	$FadeTransition/fade_timer.start()
	$FadeTransition/AnimationPlayer.play("fade_in")

func _on_quit_pressed() -> void:
	Sound.play("Button")
	await get_tree().create_timer(1.0) # 0.15 sec delay for the sound effect
	get_tree().quit()


func _on_fade_timer_timeout() -> void:#
	if button_type == "start":
		get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")
		
	elif button_type == "options":
		pass
