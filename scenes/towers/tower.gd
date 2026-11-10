class_name Tower extends Node2D

var enemies: Array
## Set by TowerGhost so the placement preview stays completely inert.
var is_ghost := false

@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float, bullet_enum: Data.Bullet)

## Damage per bullet before upgrades.
@export var base_damage := 1

# Set by the BuildController from the tower catalog.
var upgrade_defs: Array = []
var upgrade_levels: Dictionary = {}   # stat -> number of levels bought
var invested := -1                    # gold spent on this tower (sell price); -1 = not known yet

# Current stats, recalculated by recompute_stats().
var damage := 1
var fire_rate_multiplier := 1.0
var range_multiplier := 1.0
var chain_count := 0
var explosion_radius := 0.0
var scald_duration := 0.0

var terrain: TerrainGrid
var _range_shape: CircleShape2D
var _base_range := 0.0
var _reload_timer: Timer
var _base_wait := 1.0


func _ready() -> void:
	damage = base_damage
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

	for child in get_children():
		if child is Timer:
			_reload_timer = child
			_base_wait = child.wait_time
			break


	terrain = get_tree().get_first_node_in_group("terrain") as TerrainGrid
	if terrain:
		terrain.terrain_changed.connect(update_range)
	update_range()

func get_upgrade_level(stat: String) -> int:
	return upgrade_levels.get(stat, 0)

## Recalculates damage, fire rate and range from the upgrades bought so far.
func recompute_stats() -> void:
	damage = base_damage
	fire_rate_multiplier = 1.0
	range_multiplier = 1.0
	chain_count = 0
	explosion_radius = 0.0
	for u: Dictionary in upgrade_defs:
		var level := get_upgrade_level(u.stat)
		match u.stat:
			"damage":
				damage += roundi(u.per_level * level)
			"fire_rate":
				fire_rate_multiplier += u.per_level * level
			"range":
				range_multiplier += u.per_level * level
			"chain":
				chain_count += roundi(u.per_level * level)
			"explosive":
				explosion_radius += u.per_level * level
			"scald":
				scald_duration += u.per_level * level
	if _reload_timer:
		_reload_timer.wait_time = _base_wait / fire_rate_multiplier
	update_range()

## Range depends on the terrain height under the tower (hills give a bonus).
func update_range() -> void:
	if _range_shape == null:
		return
	var mult := range_multiplier
	if terrain:
		mult *= terrain.range_multiplier_at(global_position)
	_range_shape.radius = _base_range * mult

func get_range() -> float:
	return _range_shape.radius if _range_shape else 0.0

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
