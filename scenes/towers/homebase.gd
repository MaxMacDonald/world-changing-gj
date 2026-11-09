class_name Homebase extends Tower

signal lives_changed(lives: int)
signal destroyed

@export var max_lives := 20

var lives: int

@onready var attack_point: Area2D = $AttackPoint
@onready var sprite: Sprite2D = $Sprite2D

@export var effect_duration := 3.0
@export var shake_amplitude := 30.0
@export var flash_color := Color(1.0, 0.0, 0.0)
@export var death_shake_amplitude := 60.0   # vs. 30.0 for normal hits
@export var fall_distance := 500.0
@export var fall_duration := 1.5

var _base_offset: Vector2
var _base_modulate: Color
var _time_since_hit := INF
var _dying := false
var _current_amplitude: float   # which amplitude _process should use


func _ready() -> void:
	super()
	lives = max_lives
	attack_point.area_entered.connect(_on_attack_point_area_entered)
	_base_offset = sprite.offset     
	_base_modulate = sprite.modulate
	destroyed.connect(_on_destroyed)
	_current_amplitude = shake_amplitude


func _process(delta: float) -> void:
	# While dying, shake continuously until the tween finishes
	if _dying:
		_apply_shake_and_flash(delta)
		return

	if _time_since_hit > effect_duration:
		sprite.offset = _base_offset
		sprite.modulate = _base_modulate
		set_process(false)
		return

	_time_since_hit += delta
	_apply_shake_and_flash(delta)

func _on_attack_point_area_entered(area: Area2D) -> void:
	if area is Enemy:
		take_damage(area.damage)
		area.queue_free()

func take_damage(amount: int) -> void:
	if lives <= 0:
		return
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)
	if lives > 0:
		Sound.play("Tower Hurting")
		_time_since_hit = 0.0
		set_process(true)

	if lives == 0:
		destroyed.emit()
		
		
func _on_destroyed() -> void:
	_dying = true
	_time_since_hit = 0.0
	_current_amplitude = death_shake_amplitude
	set_process(true)

	# Fall: use position so the whole node drops, not just the texture.
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y + fall_distance, fall_duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func():
		set_process(false)
		sprite.visible = false
	)
	
func _apply_shake_and_flash(delta: float) -> void:
	var t := _time_since_hit
	var falloff := exp(-3.0 * t)

	sprite.offset.x = _base_offset.x + _current_amplitude * falloff * cos(t * 10.0)
	sprite.modulate = _base_modulate.lerp(flash_color, falloff * 0.5)

	if not _dying:
		return  # falling case: keep t advancing for the next shake pulse
	_time_since_hit += delta
