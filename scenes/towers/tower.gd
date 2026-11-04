class_name Tower extends Node2D

var enemies: Array
## Set by TowerGhost so the placement preview stays completely inert.
var is_ghost := false

@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float, bullet_enum: Data.Bullet)

var terrain: TerrainGrid
var _range_shape: CircleShape2D
var _base_range := 0.0

func _ready() -> void:
	if is_ghost:
		return
	add_to_group("towers")

	# The range shape is shared between every instance of the scene, so give this
	# tower its own copy before resizing it for hills.
	var shape_node := get_node_or_null("EnemyDetectionArea/CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		_range_shape = shape_node.shape.duplicate()
		shape_node.shape = _range_shape
		_base_range = _range_shape.radius

	terrain = get_tree().get_first_node_in_group("terrain") as TerrainGrid
	if terrain:
		terrain.terrain_changed.connect(update_range)
	update_range()

## Range depends on the terrain height under the tower (hills give a bonus).
func update_range() -> void:
	if _range_shape == null:
		return
	var mult := 1.0
	if terrain:
		mult = terrain.range_multiplier_at(global_position)
	_range_shape.radius = _base_range * mult

## First enemy in range that the tower can actually see (walls block line of sight).
func get_target() -> Node2D:
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		if terrain and terrain.segment_blocked(global_position, e.global_position):
			continue
		return e
	return null

## Enemies can die or be freed while in range, so drop any that are gone.
func _prune_enemies() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e))

func _on_enemy_detection_area_area_entered(area: Area2D) -> void:
	if area not in enemies:
		enemies.append(area)


func _on_enemy_detection_area_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area in enemies:
		enemies.erase(area)
