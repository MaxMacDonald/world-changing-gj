extends Tower

@export var steam_length := 2

var emitting_steam = false
@onready var area := $EnemyDetectionArea/CollisionShape2D

func _ready() -> void:
	super()
	$DamageTick.stop()
	emit_steam()
		
func emit_steam():
	$Steam.emitting=true
	emitting_steam = true
	await get_tree().create_timer(1).timeout
	$DamageTick.start()

func _on_damage_tick_timeout() -> void:
	_prune_enemies()
	if not enemies.is_empty():
		Sound.play("steam_tower_attack", -6.0, 0.1)
	for enemy in enemies:
			shoot.emit(global_position,0.0,Data.Bullet.STEAM, enemy, maxi(damage, 1), 0, 0.0, scald_duration)
	
