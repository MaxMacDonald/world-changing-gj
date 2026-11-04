extends Area2D

## Health removed from an enemy on hit. Editable per bullet scene in the inspector.
@export var damage := 1

var direction: Vector2
var speed := 200
var terrain: TerrainGrid

func _ready() -> void:
	terrain = get_tree().get_first_node_in_group("terrain") as TerrainGrid

func setup(pos, angle, bullet_enum):
	position = pos 
	direction = Vector2.DOWN.rotated(angle)
	rotation = angle
	
func _process(delta: float) -> void:
	var move := direction * speed * delta
	if terrain:
		# +2 terrain blocks projectiles.
		if terrain.segment_blocked(global_position, global_position + move):
			queue_free()
			return
		# Clean up bullets that have left the map instead of flying forever.
		if not terrain.world_rect().grow(300.0).has_point(global_position):
			queue_free()
			return
	position += move
