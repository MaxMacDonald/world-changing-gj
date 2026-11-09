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

var _base_offset: Vector2
var _base_modulate: Color
var _time_since_hit := INF

func _ready() -> void:
	super()
	lives = max_lives
	attack_point.area_entered.connect(_on_attack_point_area_entered)
	_base_offset = sprite.offset     
	_base_modulate = sprite.modulate


func _process(delta: float) -> void:
	if _time_since_hit > effect_duration:
		# Ensure we reset exactly once after the effect ends
		sprite.offset = _base_offset
		sprite.modulate = _base_modulate
		set_process(false)
		return
	_time_since_hit += delta
	var t := _time_since_hit
	var falloff := exp(-3.0 * t)

	sprite.offset.x = _base_offset.x + shake_amplitude * falloff * cos(t * 10.0)
	sprite.modulate = _base_modulate + Color(
		flash_color.r * falloff,
		flash_color.g * falloff,
		flash_color.b * falloff
	)
	set_process(true)

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
		
		
