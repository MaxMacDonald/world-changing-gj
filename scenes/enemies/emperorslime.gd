extends "res://scenes/enemies/bigslime.gd"

var big_slime_scene = preload("res://scenes/enemies/bigslime.tscn")

func new_enemy_init() -> void:
	max_health = 1500
	damage = 20
	speed = 10.0
	reward = 1000

func split_slime():
	var big_slime = big_slime_scene.instantiate()
	var targetZone = Area2D.new()
	targetZone.position = Vector2(900, 68)
	big_slime.target = targetZone
	add_sibling(big_slime)
	big_slime.global_position = Vector2(global_position.x + random.randf_range(-20,20),global_position.y + random.randf_range(-100,100))
