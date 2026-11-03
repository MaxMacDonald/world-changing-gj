class_name Enemy extends Area2D

@export var speed := 50.0
## How many lives the player loses when this enemy reaches the base.
@export var damage := 1
@export var max_health := 3
## Where the health bar sits relative to the enemy's centre.
@export var health_bar_offset := Vector2(0, -26)

var target: Node2D
var health: int
var health_bar: EnemyHealthBar

func _ready() -> void:
	health = max_health
	health_bar = EnemyHealthBar.new()
	health_bar.position = health_bar_offset
	add_child(health_bar)

func setup(new_target: Node2D) -> void:
	target = new_target

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	# Walk in a straight line toward the target (the homebase's AttackPoint).
	global_position = global_position.move_toward(target.global_position, speed * delta)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_bar.set_ratio(float(health) / max_health)
	if health == 0:
		queue_free()

func _on_area_entered(bullet: Area2D) -> void:
	take_damage(bullet.damage)
	bullet.queue_free()
