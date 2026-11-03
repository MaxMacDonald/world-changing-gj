extends Tower

func _process(_delta: float) -> void:
	_prune_enemies()
	if enemies.size() > 0:
		$TurretPointer.look_at(enemies[0].global_position)
		$TurretPointer.rotation -= PI/2
		#Add tracking logic here if needed


func _on_relode_timer_timeout() -> void:
	_prune_enemies()
	if enemies:
		shoot.emit(position, $TurretPointer.rotation, Data.Bullet.SINGLE)

# Enemies can now die, so drop any that have been freed.
func _prune_enemies() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e))
