extends Tower

func _process(_delta: float) -> void:
	if enemies.size() > 0:
		$TurretPointer.look_at(enemies[0].global_position)
		$TurretPointer.rotation -= PI/2
		#Add tracking logic here if needed


func _on_relode_timer_timeout() -> void:
	if enemies:
		shoot.emit(position, $TurretPointer.rotation, Data.Bullet.SINGLE)
	
