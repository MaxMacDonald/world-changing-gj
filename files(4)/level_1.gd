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
	$EnemySpawner.all_waves_cleared.connect(_on_level_cleared)

	_start_game_flow()

## Runs the tutorial first (once per launch), then begins the level.
func _start_game_flow() -> void:
	if $Tutorial.should_run():
		$Tutorial.finished.connect(_begin_game, CONNECT_ONE_SHOT)
		$Tutorial.start($Homebase, $SpawnPoints, $BuildController, $Terrain, $Wallet)
	else:
		_begin_game()

## Everything that should wait for the tutorial goes here: start the waves
## (or show your starting bubble).
func _begin_game() -> void:
	$EnemySpawner.start(LEVEL_WAVES.WAVES)

func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet, damage: int = 1):
	var bullet = bullet_scene.instantiate()
	bullet.setup(pos, angle, bullet_enum)
	bullet.damage = damage
	$Bullets.add_child(bullet)

func _on_tower_placed(tower: Tower) -> void:
	tower.shoot.connect(create_bullet)

func _on_level_cleared() -> void:
	# Last wave has spawned and every enemy is gone. Don't count it as a win if the base fell.
	if $Homebase.lives <= 0:
		return
	$VictoryScreen.show_victory("Lives remaining: %d" % $Homebase.lives)

func _on_homebase_destroyed() -> void:
	$HUD.show_game_over()
	$EnemySpawner.stop()
