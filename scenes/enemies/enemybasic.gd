class_name Enemy extends Area2D

## Emitted when the enemy is killed (not when it reaches the base).
signal killed(reward: int)

@export var speed := 50.0
## How many lives the player loses when this enemy reaches the base.
@export var damage := 1
@export var max_health := 6
## Gold awarded to the player when this enemy is killed.
@export var reward := 6
## Seconds to dig through ONE +2 block.
@export var dig_time := 3.0
## How close (px) it walks up to a wall block before it starts digging.
@export var dig_reach := 22.0
## Where the health bar sits relative to the enemy's centre.
@export var health_bar_offset := Vector2(0, -26)

@export var squash_amount := 0.10   # how much it deforms
@onready var visual: Node2D = $KorriOrroSprite  # sprite or node at the feet
@export var base_duration := 0.5       # average cycle time
@export var duration_jitter := 0.15     # +/- 15% variation

@export var death_sound := "enemy_die_slime_2"

# click damage constants
@export var click_damage := 1
@export var click_radius := 28.0
@export var click_offset := Vector2(0, -4)

const CLICK_COOLDOWN := 1.0 # cool down between click
static var _next_click_ms := 0 # when the next click is allowed

const CRIT_CHANCE := 0.15
const CRIT_MULTIPLIER := 2

var target: Node2D
var terrain: TerrainGrid
var health: int
var health_bar: EnemyHealthBar
var dig_bar: EnemyHealthBar
var _tween: Tween
var _tween_death: Tween
var _tween_fade: Tween
var _cycle_duration: float
var _base_scale: Vector2

# --- pathing state ---
var _mode_version := -1                      # terrain version the dig/around decision was made for
var _through := false                        # true = following the "dig through" route
var _plan_cell := Vector2i(-9999, -9999)     # cell the current step was planned from
var _step := Vector2i(-1, -1)                # next cell to walk into
var _dig_cell := Vector2i(-1, -1)
var _dig_progress := 0.0

func _ready() -> void:
	new_enemy_init()
	add_to_group("enemies")
	health = max_health

	health_bar = EnemyHealthBar.new()
	health_bar.position = health_bar_offset
	add_child(health_bar)

	dig_bar = EnemyHealthBar.new()
	dig_bar.size = Vector2(36, 4)
	dig_bar.auto_hide = false
	dig_bar.flat_color = Color(0.85, 0.6, 0.25)
	dig_bar.position = health_bar_offset + Vector2(0, 7)
	add_child(dig_bar)
	_cycle_duration = base_duration * randf_range(1.0 - duration_jitter, 1.0 + duration_jitter)
	_base_scale = visual.scale          # remembers what you set in the editor
	_bounce_loop()
	_make_click_area()

func new_enemy_init() -> void:
	pass #By default does nothing, but sets things up for other enemy types

func setup(new_target: Node2D, new_terrain: TerrainGrid = null) -> void:
	target = new_target
	terrain = new_terrain

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if terrain == null:
		# No terrain in the level: just walk straight at the base.
		global_position = global_position.move_toward(target.global_position, speed * delta)
		return
	_move_with_terrain(delta)

func _move_with_terrain(delta: float) -> void:
	var cell := terrain.clamp_cell(terrain.world_to_cell(global_position))
	var current_speed := speed * terrain.speed_multiplier_at(global_position)

	# In the base's own cell (or with no usable route) head straight for the attack point.
	if not terrain.has_route() or cell == terrain.goal_cell:
		_stop_digging()
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		return

	# Terrain changed (player edit or a tunnel was dug): decide again whether
	# to go around or dig through.
	if _mode_version != terrain.version:
		_mode_version = terrain.version
		_through = terrain.should_dig(cell, speed, dig_time)
		_plan_cell = Vector2i(-9999, -9999)

	if cell != _plan_cell:
		_plan_cell = cell
		_step = terrain.get_step(cell, speed, dig_time, _through)

	if _step.x < 0:
		_stop_digging()
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		return

	if terrain.is_undug_wall(_step) and terrain.distance_to_cell(global_position, _step) <= dig_reach:
		_dig(delta)
		return

	_stop_digging()
	global_position = global_position.move_toward(terrain.cell_to_world(_step), current_speed * delta)

func _dig(delta: float) -> void:
	if _dig_cell != _step:
		_dig_cell = _step
		_dig_progress = 0.0
	_dig_progress += delta
	var total := maxf(dig_time, 0.01)
	dig_bar.visible = true
	dig_bar.set_ratio(_dig_progress / total)
	if _dig_progress >= total:
		var finished := _dig_cell
		_stop_digging()
		terrain.dig_tunnel(finished)

func _stop_digging() -> void:
	_dig_cell = Vector2i(-1, -1)
	_dig_progress = 0.0
	if dig_bar:
		dig_bar.visible = false

func hit(amount: int) -> void:
	if health <= 0:
		return
	var is_crit := randf() < CRIT_CHANCE
	if is_crit:
		amount *= CRIT_MULTIPLIER
	_show_damage(amount,is_crit)
	take_damage(amount)
	
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	$KorriOrroSprite.modulate = Color(1,0,0)
	health = max(health - amount, 0)
	health_bar.set_ratio(float(health) / max_health)
	await get_tree().create_timer(0.1)
	$KorriOrroSprite.modulate = Color(1,1,1)
	if health == 0:
		Sound.play(death_sound, 0.0, 0.1)
		killed.emit(reward)
		_death_animation()
		await _tween_fade.finished
		queue_free()

func _bounce_loop() -> void:
	_tween = create_tween().set_loops()
	_tween.tween_property(visual, "scale",
		_base_scale * Vector2(1.0 - squash_amount, 1.0 + squash_amount), _cycle_duration * 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(visual, "scale",
		_base_scale * Vector2(1.0 + squash_amount, 1.0 - squash_amount), _cycle_duration * 0.4)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(visual, "scale", _base_scale, _cycle_duration * 0.3)
	
func _on_area_entered(bullet: Area2D) -> void:
	Sound.play("enemy_hit_tower", -6.0, 0.15)
	hit(bullet.damage)
	if not bullet.has_node("Sparks"):
		bullet.queue_free()
		
func _show_damage(amount: int, is_crit:= false) -> void:
	var pos := global_position + health_bar_offset + Vector2(randf_range(-8, 8), -8)
	DamageNumber.spawn(get_parent(), pos, amount, is_crit)

func _make_click_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 1 << 19 # using layer 20 for only clicking
	area.collision_mask = 0
	area.monitoring = false
	area.input_pickable = true
	area.position = click_offset
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = click_radius
	shape.shape = circle
	area.add_child(shape)
	area.input_event.connect(_on_click_area_input_event)
	add_child(area)
	
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var now := Time.get_ticks_msec()
		if now < _next_click_ms: # click in cooldown
			return
		_next_click_ms = now + int(CLICK_COOLDOWN * 1000)
		Sound.play("enemy_hit_tower", -6.0, 0.15)
		hit(click_damage)
		
func _death_animation():
	remove_from_group("enemies")
	set_process(false)
	set_deferred("monitoring", false)  
	set_deferred("monitorable", false)
	health_bar.visible = false
	dig_bar.visible = false
	if _tween:
		_tween.kill()    
	_tween_death = create_tween()
	_tween_fade = create_tween()
	_tween_death.tween_property(visual,"scale",Vector2(_base_scale.x * 1.5, _base_scale.y * 0.2), 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	$DeathParticles.emitting = true
	_tween_fade.tween_interval(0.1)
	_tween_fade.tween_property(visual, "modulate:a", 0.0, 0.4)
