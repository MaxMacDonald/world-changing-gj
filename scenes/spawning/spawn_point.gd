class_name SpawnPoint extends Area2D
## Place these in the level and size their CollisionShape2D (rectangle or circle).
## Enemies spawn at a random spot inside the shape. With no shape, they spawn at the node's position.
## The NODE NAME is what you reference in the wave data (e.g. "SpawnLeft").

func _ready() -> void:
	# Purely a marker: don't let it interact with towers/enemies/bullets.
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false

func get_spawn_position() -> Vector2:
	for child in get_children():
		if child is CollisionShape2D and child.shape != null:
			var local := Vector2.ZERO
			if child.shape is RectangleShape2D:
				var half: Vector2 = child.shape.size / 2.0
				local = Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
			elif child.shape is CircleShape2D:
				var r: float = child.shape.radius * sqrt(randf())
				local = Vector2.from_angle(randf() * TAU) * r
			return child.global_transform * local
	return global_position
