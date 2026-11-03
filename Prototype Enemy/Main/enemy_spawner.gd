extends Node2D

var enemy_scene = preload("res://Prototype Enemy/Mob/Mob.tscn")
var spawn_location = [Vector2(100,100), Vector2(1000,550)] #can be set to anything
@onready var endpoint: Marker2D = $"../Endpoint"

func _ready():
	$Timer.timeout.connect(spawn_enemy) #timer that spawns an enemy

			
func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.target = $"../Endpoint"
	
	add_child(enemy)
	enemy.global_position = spawn_location.pick_random() #spawns from any of the predetemined locations
	

	
	
