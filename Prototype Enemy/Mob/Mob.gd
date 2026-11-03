extends Area2D

@export var speed: float # speed at which it moves at - set in the inspector
@export var angular_speed: float # speed at which it rotates at - set in the inspector
var target: Marker2D #where the mob moves towards

func _process(delta: float) -> void:
	if target == null:
		return 
		
	rotation = rotate_toward(rotation,(target.global_position-global_position).angle()+PI/2,angular_speed*delta)
	var velocity = Vector2.UP.rotated(rotation) * speed
	global_position += velocity*delta 
	


		
