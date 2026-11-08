extends Tower

func _process(_delta: float) -> void:
	_prune_enemies()
	_aim_at_target()

func _on_relode_timer_timeout() -> void:
	_prune_enemies()
	if _aim_at_target():
		shoot.emit(global_position, $TurretPointer.rotation, Data.Bullet.SINGLE, damage)

## Points the turret at the best visible enemy. Returns false if there isn't one.
func _aim_at_target() -> bool:
	var target := get_target()
	if target == null:
		return false
	$TurretPointer.look_at(target.global_position)
	$TurretPointer.rotation -= PI / 2
	return true
