extends Node2D


var basic_enemy_scene = preload("res://scenes/enemies/enemybasic.tscn")

func _ready() -> void:
	var path_follow = PathFollow2D.new()
	var enemy = basic_enemy_scene.instantiate()
	enemy.setup(path_follow)
	path_follow.add_child(enemy)
	$Path2D.add_child(path_follow)
	
	
