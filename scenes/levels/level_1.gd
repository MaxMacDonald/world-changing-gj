extends Node2D

const LEVEL_WAVES = preload("res://scenes/levels/level_1_waves.gd")

var bullet_scene = preload("res://scenes/bullets/bullet.tscn")

func _ready() -> void:
	RenderingServer.set_default_clear_color('c976a9')
	$Towers/TowerBasic.connect("shoot", create_bullet)

	$Terrain.setup($Homebase, $SpawnPoints)
	$EnemySpawner.terrain = $Terrain

	$HUD.set_lives($Homebase.lives)
	$HUD.set_money($Wallet.money)
	$Wallet.changed.connect($HUD.set_money)
	$EnemySpawner.enemy_killed.connect($Wallet.add)
	$BuildController.setup($Wallet, $Towers, $Terrain)
	$BuildController.tower_placed.connect(_on_tower_placed)
	$Homebase.lives_changed.connect($HUD.set_lives)
	$Homebase.destroyed.connect(_on_homebase_destroyed)
	$EnemySpawner.wave_started.connect(func(n): print("Wave ", n))
	$EnemySpawner.all_waves_cleared.connect(func(): print("Level cleared!"))

	$EnemySpawner.start(LEVEL_WAVES.WAVES)

func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet):
	var bullet = bullet_scene.instantiate()
	bullet.setup(pos, angle, bullet_enum)
	$Bullets.add_child(bullet)

func _on_tower_placed(tower: Tower) -> void:
	tower.shoot.connect(create_bullet)

func _on_homebase_destroyed() -> void:
	$HUD.show_game_over()
	$EnemySpawner.stop()
