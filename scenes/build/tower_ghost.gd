class_name TowerGhost extends Node2D
## A see-through, inactive copy of a tower that follows the mouse while placing.

var tower: Tower
var base_range := 0.0
var range_multiplier := 1.0

func setup(new_tower: Tower) -> void:
	tower = new_tower
	# Make it completely inert: no processing, no timers, no enemy detection,
	# and it doesn't register as a real tower.
	tower.is_ghost = true
	tower.process_mode = Node.PROCESS_MODE_DISABLED
	var area := tower.get_node_or_null("EnemyDetectionArea") as Area2D
	if area:
		area.monitoring = false
		area.monitorable = false
		var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is CircleShape2D:
			base_range = shape.shape.radius
	add_child(tower)
	z_index = 100
	set_valid(true)

func set_valid(valid: bool) -> void:
	modulate = Color(1, 1, 1, 0.65) if valid else Color(1, 0.3, 0.3, 0.65)

## Hills extend the tower's range; the preview shows the real range for the tile under the mouse.
func set_range_multiplier(mult: float) -> void:
	if is_equal_approx(mult, range_multiplier):
		return
	range_multiplier = mult
	queue_redraw()

func _draw() -> void:
	var radius := base_range * range_multiplier
	if radius > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.12))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 2.0)
