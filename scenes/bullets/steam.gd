extends Area2D
@export var damage = 1
var scald_time := 0.0

func scald (hit_enemy: Node2D) -> void:
	if scald_time > 0.0 and hit_enemy.has_method("apply_scald"):
		hit_enemy.apply_scald(scald_time)

func setup(end):
	global_position = end
	await get_tree().create_timer(0.1).timeout
	queue_free()
