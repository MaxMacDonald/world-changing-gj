extends Area2D

## Health removed from an enemy on hit. Editable per bullet scene in the inspector.
@export var damage := 1

var direction: Vector2
var speed := 200
var terrain: TerrainGrid

# explosion
var explosion_radius := 0.0
var _exploded = false
const EXPLOSION_DAMAGE_FACTOR := 0.75 

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

func explode(hit_enemy: Node2D) -> void:
	if explosion_radius <= 0.0 or _exploded:
		return
	_exploded = true
	var center := hit_enemy.global_position
	Explosion.spawn(get_parent(), center, explosion_radius)
	Sound.play("explosion", 0.0, 0.1)
	var splash := maxi(1, roundi(damage * EXPLOSION_DAMAGE_FACTOR))
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == hit_enemy or not is_instance_valid(e) or e.is_queued_for_deletion() or e.health <= 0:
			continue
		if center.distance_to(e.global_position) <= explosion_radius:
			e.hit(splash)
