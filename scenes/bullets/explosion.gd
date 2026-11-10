class_name Explosion extends Node2D

const DURATION := 0.35
var radius := 60.0
var _t := 0.0

static func spawn(where: Node, pos: Vector2, blast_radius: float) -> void:
	var boom := Explosion.new()
	boom.radius = blast_radius
	where.add_child(boom)
	boom.global_position = pos

func _ready() -> void:
	z_index = 40
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
	
func _set_progress(value: float) -> void:
	_t = value
	queue_redraw()
	
func _draw() -> void:
	var r := radius * (0.3 + 0.7 * _t)
	var fade := 1.0 - _t
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.45, 0.1, 0.8 * fade))
	draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.8, 0.25, 0.95 * fade))
	draw_circle(Vector2.ZERO, r * 0.3, Color(1.0, 1.0, 0.85, fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.55, 0.08, 0.1, fade), 6.0, true)
	
