class_name EnemySpawner extends Node

signal wave_started(wave_number: int)
signal wave_finished(wave_number: int)
## Every wave has been spawned AND every enemy is gone.
signal all_waves_cleared
## An enemy was killed by the player; passes along its gold reward.
signal enemy_killed(reward: int)

## Add new enemy types here; the key is what you write in the wave data.
const ENEMY_SCENES := {
	"basic": preload("res://scenes/enemies/enemybasic.tscn"),
	"big_slime": preload("res://scenes/enemies/bigslime.tscn"),
	"armoured": preload("res://scenes/enemies/armouredslime.tscn"),
	"sword": preload("res://scenes/enemies/swordslime.tscn")
}

@export var homebase: Homebase
@export var spawn_points_root: Node
@export var enemy_container: Node
@export var terrain: TerrainGrid

var _groups_running := 0
var _enemies_alive := 0
var _stopped := false

func _ready() -> void:
	# Fallbacks in case the inspector references weren't assigned.
	if homebase == null:
		homebase = get_node_or_null("../Homebase") as Homebase
	if spawn_points_root == null:
		spawn_points_root = get_node_or_null("../SpawnPoints")
	if enemy_container == null:
		enemy_container = get_node_or_null("../Enemies")
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as TerrainGrid

	if homebase == null: push_error("EnemySpawner: no Homebase found")
	if spawn_points_root == null: push_error("EnemySpawner: no SpawnPoints node found")
	if enemy_container == null: push_error("EnemySpawner: no Enemies node found")

func start(waves: Array) -> void:
	_stopped = false
	_run_waves(waves)

func stop() -> void:
	_stopped = true

# If the level is restarted or left mid-wave, stop the wave loops cleanly.
func _exit_tree() -> void:
	_stopped = true

func _run_waves(waves: Array) -> void:
	for i in waves.size():
		var wave: Dictionary = waves[i]
		wave_started.emit(i + 1)

		# Every spawn group in the wave runs at the same time, each on its own delay/interval.
		for group in wave.get("spawns", []):
			_run_group(group)
		while _groups_running > 0:
			await get_tree().process_frame
			if _stopped: return

		if wave.get("wait_for_clear", false):
			while _enemies_alive > 0:
				await get_tree().process_frame
				if _stopped: return

		wave_finished.emit(i + 1)

		var pause: float = wave.get("time_after", 0.0)
		if pause > 0.0 and i < waves.size() - 1:
			await _wait(pause)
			if _stopped: return

	while _enemies_alive > 0:
		await get_tree().process_frame
		if _stopped: return
	all_waves_cleared.emit()

## Waits using a Timer node owned by this spawner. Unlike get_tree().create_timer()
## (which keeps running while the game is paused and outlives the scene), it pauses with
## the game and disappears with the spawner when the scene is restarted.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(seconds, 0.001)
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

func _run_group(group: Dictionary) -> void:
	_groups_running += 1
	var delay: float = group.get("delay", 0.0)
	var count: int = group.get("count", 1)
	var interval: float = group.get("interval", 1.0)

	if delay > 0.0:
		await _wait(delay)
	for n in count:
		if _stopped: break
		_spawn_enemy(group.get("enemy", "basic"), group.get("point"))
		if n < count - 1:
			await _wait(interval)
	_groups_running -= 1

func _spawn_enemy(enemy_id: String, point_def) -> void:
	if not ENEMY_SCENES.has(enemy_id):
		push_error("EnemySpawner: unknown enemy '%s'" % enemy_id)
		return

	# "point" can be one name or an array of names (one is picked at random per enemy).
	var point_name = point_def.pick_random() if point_def is Array else point_def
	var point := spawn_points_root.get_node_or_null(NodePath(str(point_name))) as SpawnPoint
	if point == null:
		push_error("EnemySpawner: no SpawnPoint named '%s'" % str(point_name))
		return

	var enemy: Enemy = ENEMY_SCENES[enemy_id].instantiate()
	enemy.setup(homebase.attack_point, terrain)
	enemy.killed.connect(func(reward: int): enemy_killed.emit(reward))
	enemy_container.add_child(enemy)
	enemy.global_position = point.get_spawn_position()

	_enemies_alive += 1
	enemy.tree_exited.connect(func(): _enemies_alive -= 1)
