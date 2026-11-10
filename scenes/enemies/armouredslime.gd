extends Enemy

func new_enemy_init() -> void:
	max_health = 20
	damage = 2
	reward = 10
	death_sound = "enemy_die_slime_armored"
	death_volume = -10.0
