extends Node2D


var basic_enemy_scene = preload("res://scenes/enemies/enemybasic.tscn")
var bullet_scene = preload("res://scenes/bullets/bullet.tscn")


func _ready() -> void:
	var path_follow = PathFollow2D.new()
	var enemy = basic_enemy_scene.instantiate()
	RenderingServer.set_default_clear_color('c976a9')
	enemy.setup(path_follow)
	path_follow.add_child(enemy)
	$Path2D.add_child(path_follow)
	$Towers/TowerBasic.connect("shoot", create_bullet)
	
func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet):
	var bullet = bullet_scene.instantiate()
	bullet.setup(pos, angle, bullet_enum)
	$Bullets.add_child(bullet)
