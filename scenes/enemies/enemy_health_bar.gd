class_name EnemyHealthBar extends Node2D
## Small bar drawn over an enemy's head. Hidden until the enemy takes damage.

@export var size := Vector2(36, 5)

var ratio := 1.0

func _ready() -> void:
	visible = false

func set_ratio(new_ratio: float) -> void:
	ratio = clampf(new_ratio, 0.0, 1.0)
	visible = ratio < 1.0
	queue_redraw()

func _draw() -> void:
	var back := Rect2(-size / 2.0, size)
	draw_rect(back, Color.BLACK)
	var fill := Rect2(back.position + Vector2.ONE, Vector2((size.x - 2.0) * ratio, size.y - 2.0))
	draw_rect(fill, Color.RED.lerp(Color.GREEN, ratio))
