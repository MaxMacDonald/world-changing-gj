extends Node2D

signal wave_ready

@export var required_hold_time: float = 1.0
@export var straining_duration: float = 0.3  # Time spent "strained" before pop
@export var burst_scale: float = 1.0        # Overshoot scale on burst
@export var strain_shake_amplitude: float = 2.0  # Shake amount during strain phase

var hold_time: float = 0.0
var is_holding: bool = false
var current_state: String = "idle"  # "idle", "charging", "straining", "bursting"
var strain_timer: float = 0.0

# Cache references
var _sprite: Sprite2D
var _label: Label

func _ready():
	_sprite = $BubbleSprite
	_label = $BubbleLabel
	
		
	# Reset visual state
	_reset_visuals()
	

func _reset_visuals():
	visible = true
	if _label:
		_label.text = "Hold space to start"
		_label.modulate.a = 1.0
		
		

func _input(event):
	# Only handle when bubble is visible
	if current_state == "idle":
		if event.is_action_pressed("ui_accept"):  # Spacebar
			is_holding = true
			current_state = "charging"
			_start_charge()
		
		elif event.is_action_released("ui_accept"):
			is_holding = false
	
	elif current_state == "charging":
		if event.is_action_released("ui_accept"):
			is_holding = false
			_cancel_charge()

func _process(delta):
	match current_state:
		"idle":
			pass
		
		"charging":
			if is_holding:
				_update_charge(delta)
			else:
				_cancel_charge()
		
		"straining":
			_handle_strain(delta)
		
		"bursting":
			# Burst animation completes, then signal
			await get_tree().create_timer(0.15).timeout
			complete_burst()
			queue_free()

func _start_charge():
	hold_time = 0.0
	if _label:
		_label.text = "Holding..."

func _update_charge(delta):
	hold_time += delta
	
	# Calculate progress (0.0 to 1.0)
	var progress = clamp(hold_time / required_hold_time, 0.0, 1.0)
	
	# Grow the bubble smoothly
	var target_scale = 1.0 + (progress * 0.5)  # Grows to 1.8x
	target_scale = lerpf(scale.x, target_scale, delta * 5.0)  # Smooth interpolation
	scale = Vector2.ONE * target_scale
	
	# Scale the label slightly less than the bubble (so text stays readable)
	if _label:
		_label.scale = Vector2.ONE * lerpf(1.0, 1.3, progress)
	
	# Threshold reached — enter strain phase
	if hold_time >= required_hold_time:
		current_state = "straining"
		strain_timer = straining_duration
		if _label:
			_label.text = "STRAINING!"

func _handle_strain(delta):
	strain_timer -= delta
	
	# Shake effect during strain
	var shake_offset = Vector2(
	randf_range(-strain_shake_amplitude, strain_shake_amplitude),
	randf_range(-strain_shake_amplitude, strain_shake_amplitude)
)
	position = position + shake_offset
	
	# Continue slight growth while straining
	var extra_grow = clamp((required_hold_time - strain_timer) / 0.1, 0.0, 0.2)
	scale = Vector2.ONE * (lerpf(1.0, 1.5, 1.0))
	
	if strain_timer <= 0.0:
		current_state = "bursting"
		_pop_effect()

func _cancel_charge():
	# Shrink back down
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(_reset_after_cancel)

func _reset_after_cancel():
	is_holding = false
	current_state = "idle"
	hold_time = 0.0
	if _label:
		_label.text = "Hold space to start"
	#position = Vector2.ZERO

func _pop_effect():
	# Quick scale overshoot
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * burst_scale, 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(_hide_bubble)

func _hide_bubble():
	visible = false

func complete_burst():
	emit_signal("wave_ready")  # Tell parent to start waves

func set_label_text(text: String):
	if _label:
		_label.text = text
