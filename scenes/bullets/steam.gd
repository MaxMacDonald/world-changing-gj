extends Area2D
@export var damage = 1

func setup(end):
	global_position = end
	await get_tree().create_timer(0.1).timeout
	queue_free()
