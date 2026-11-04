class_name EnemyHealthBar extends Node2D
## Small bar drawn over an enemy's head. Used for health (hidden until damaged)
## and for dig progress.

@export var size := Vector2(36, 5)

## If true the bar only shows while below full. Turn off to control `visible` yourself.
var auto_hide := true
## Set to a colour with alpha > 0 to use one solid colour instead of the red-to-green gradient.
var flat_color := Color(0, 0, 0, 0)
var ratio := 1.0

func _ready() -> void:
	visible = false

func set_ratio(new_ratio: float) -> void:
	ratio = clampf(new_ratio, 0.0, 1.0)
	if auto_hide:
		visible = ratio < 1.0
	queue_redraw()

func _draw() -> void:
	var back := Rect2(-size / 2.0, size)
	draw_rect(back, Color.BLACK)
	var fill := Rect2(back.position + Vector2.ONE, Vector2((size.x - 2.0) * ratio, size.y - 2.0))
	var color := flat_color if flat_color.a > 0.0 else Color.RED.lerp(Color.GREEN, ratio)
	draw_rect(fill, color)
