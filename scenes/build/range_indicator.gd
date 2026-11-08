class_name RangeIndicator extends Node2D
## Shows a selected tower: a ring around the tower and its fire range.

var radius := 0.0
var marker_radius := 26.0

func _ready() -> void:
	z_index = 90
	hide()

func show_for(pos: Vector2, new_radius: float) -> void:
	global_position = pos
	if not is_equal_approx(new_radius, radius):
		radius = new_radius
		queue_redraw()
	if not visible:
		queue_redraw()
		show()

func _draw() -> void:
	if radius > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.12))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 2.0)
	draw_arc(Vector2.ZERO, marker_radius, 0.0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 3.0)
