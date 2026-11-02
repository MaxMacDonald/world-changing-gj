extends Marker2D
var screen_size

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
func _on_randomise_endpoint_pressed() -> void: #just to change the position of the point the mobs move towards
	global_position.x = randf_range(0,screen_size[0])
	global_position.y = randf_range(0,screen_size[1])
