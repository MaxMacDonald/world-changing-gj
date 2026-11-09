class_name DamageNumber extends Label

const RISE := 40.0
const DURATION := 0.8
const BOX_SIZE := Vector2(80, 40)

var is_crit := false

# render the damage number
static func spawn(where: Node, world_pos: Vector2, amount: int, crit := false) -> void:
	var number := DamageNumber.new()
	number.is_crit = crit
	number.text = str(amount) + ("!" if crit else "")
	where.add_child(number)
	number.global_position = world_pos - BOX_SIZE / 2
	number._animate()

# for text styling
func _ready() -> void:
	size = BOX_SIZE
	pivot_offset = BOX_SIZE / 2
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE # prevent blocking user from placing tower
	z_index = 100 # high priority
	if is_crit:
		add_theme_font_size_override("font_size", 40)
		add_theme_color_override("font_color", Color(1, 0.35, 0.6))
	else:
		add_theme_font_size_override("font_size", 28)
		add_theme_color_override("font_color", Color(1, 1, 1))
	add_theme_color_override("font_outline_color", Color(0.25, 0.02, 0.15))
	add_theme_constant_override("outline_size", 8)

# create animation for the number
func _animate() -> void:
	scale = Vector2(2.0, 2.0) if is_crit else Vector2(1.5, 1.5)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_property(self, "position:y", position.y - RISE, DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tween.chain().tween_callback(queue_free)
