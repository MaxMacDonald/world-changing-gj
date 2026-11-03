class_name Homebase extends Tower

signal lives_changed(lives: int)
signal destroyed

@export var max_lives := 20

var lives: int
@onready var attack_point: Area2D = $AttackPoint

func _ready() -> void:
	lives = max_lives
	attack_point.area_entered.connect(_on_attack_point_area_entered)

func _on_attack_point_area_entered(area: Area2D) -> void:
	if area is Enemy:
		take_damage(area.damage)
		area.queue_free()

func take_damage(amount: int) -> void:
	if lives <= 0:
		return
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)
	if lives == 0:
		destroyed.emit()
