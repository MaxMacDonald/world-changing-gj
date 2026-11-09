extends Tower



func _process(delta: float) -> void:
	_prune_enemies()
	if enemies.size() > 0:
		$TurretPointer.look_at(enemies[0].global_position)
		$TurretPointer.rotation -= PI/2
		
func _on_relode_timer_timeout() -> void:
	if enemies:
		Sound.play("laser2", -4.0, 0.05)
		shoot.emit(position, $TurretPointer.rotation, Data.Bullet.HEATRAY, enemies[0], damage)

func _prune_enemies() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	
#
