extends Enemy

var random = RandomNumberGenerator.new()
var little_slime_scene = preload("res://scenes/enemies/enemybasic.tscn")

func new_enemy_init() -> void:
	max_health = 40
	damage = 5
	speed = 40.0
	reward = 20

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_bar.set_ratio(float(health) / max_health)
	_show_damage(amount)
	if health == 0:
		Sound.play(death_sound, 0.0, 0.1)
		killed.emit(reward)	
		for i in range(3):
			call_deferred("split_slime")
		queue_free()
		
func split_slime():
	var little_slime = little_slime_scene.instantiate()
	var targetZone = Area2D.new()
	targetZone.position = Vector2(900, 68)
	little_slime.target = targetZone
	add_sibling(little_slime)
	little_slime.global_position = Vector2(global_position.x + random.randf_range(-20,20),global_position.y + random.randf_range(-20,20))
