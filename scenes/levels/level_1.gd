extends Node2D

const LEVEL_WAVES = preload("res://scenes/levels/level_1_waves.gd")

var bullet_scene = preload("res://scenes/bullets/bullet.tscn")
var heat_ray_bullet_scene = preload("res://scenes/bullets/heat_ray.tscn")
var steam_bullet_scene = preload("res://scenes/bullets/steam.tscn")
func _ready() -> void:
	get_viewport().physics_object_picking = true
	get_viewport().physics_object_picking_sort = true

	Sound.play_music("Tower defense chill")

	$FadeCanvas/FadeTransition.show()
	$FadeCanvas/FadeTransition/fade_timer.start()
	$FadeCanvas/FadeTransition/AnimationPlayer.play("fade_out")

	var bg := Polygon2D.new()
	bg.color = Color("c976a9")
	bg.polygon = PackedVector2Array([
		Vector2(-6000, -6000), Vector2(6000, -6000),
		Vector2(6000, 6000), Vector2(-6000, 6000)
	])
	bg.z_index = -100
	add_child(bg)
	move_child(bg, 0)
	

	$Terrain.setup($Homebase, $SpawnPoints)
	$EnemySpawner.terrain = $Terrain

	$HUD.set_max_lives($Homebase.max_lives)
	$HUD.set_lives($Homebase.lives)
	$HUD.set_money($Wallet.money)
	$Wallet.changed.connect($HUD.set_money)
	$EnemySpawner.enemy_killed.connect($Wallet.add)
	$BuildController.setup($Wallet, $Towers, $Terrain)
	$BuildController.tower_placed.connect(_on_tower_placed)
	$Homebase.lives_changed.connect($HUD.set_lives)
	$Homebase.destroyed.connect(_on_homebase_destroyed)
	$EnemySpawner.wave_started.connect($HUD.show_wave_started)
	$EnemySpawner.all_waves_cleared.connect(func(): print("Level cleared!"))
	$EnemySpawner.all_waves_cleared.connect(_on_level_cleared)
	if $Bubble:
		$Bubble.wave_ready.connect(_on_wave_ready)
		$Bubble.hide()
		$Bubble.process_mode = Node.PROCESS_MODE_DISABLED
	if $Tutorial.should_run():
		$Tutorial.finished.connect(_begin_game, CONNECT_ONE_SHOT)
		$Tutorial.start($Homebase, $SpawnPoints, $BuildController, $Terrain, $Wallet)
	else:
		_begin_game()
	

func _begin_game() -> void:
	$Bubble.show()
	$Bubble.process_mode = Node.PROCESS_MODE_INHERIT
	
func _on_wave_ready():
	# Call your spawner
	$EnemySpawner.start(LEVEL_WAVES.WAVES)
	
func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet, target: Area2D, damage: int = 1, chains: int = 0):
	match bullet_enum:
		
		Data.Bullet.SINGLE:
			var bullet = bullet_scene.instantiate()
			bullet.setup(pos, angle, bullet_enum)
			bullet.damage = damage
			$Bullets.add_child(bullet)
			bullet.setup(pos, angle, bullet_enum)
			
		Data.Bullet.HEATRAY:
			var heatray = heat_ray_bullet_scene.instantiate()
			heatray.damage = damage
			heatray.chains = chains
			heatray.target_enemy = target
			$Bullets.add_child(heatray)
			heatray.setup(pos, target.global_position)
			
		Data.Bullet.STEAM:
			var steam = steam_bullet_scene.instantiate()
			steam.damage = damage
			$Bullets.add_child(steam)
			steam.setup(target.global_position)


func _on_tower_placed(tower: Tower) -> void:
	tower.shoot.connect(create_bullet)

func _on_homebase_destroyed() -> void:
	Sound.stop_music()
	Sound.play("defeat_game_over")
	$HUD.show_game_over()
	$EnemySpawner.stop()
	
func _on_level_cleared() -> void:
	# Don't count it as a win if the base fell on the very last enemy.
	if $Homebase.lives <= 0:
		return
	$VictoryScreen.show_victory("Lives remaining: %d" % $Homebase.lives)
